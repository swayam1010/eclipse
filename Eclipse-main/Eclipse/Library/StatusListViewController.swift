import UIKit
import Firebase
import FirebaseAuth
import SDWebImage

class StatusListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {

    private var allBooks: [BookF] = []
    private var filteredBooks: [BookF] = []
    private var statusList: StatusList?

    private let tableView = UITableView()
    
    private let noBooksLabel: UILabel = {
        let label = UILabel()
        label.text = "No books in this list."
        label.textAlignment = .center
        label.textColor = .gray
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    func setStatusList(_ list: StatusList) {
        self.statusList = list
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchBooks()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Set up the large title
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        navigationItem.title = statusList?.category ?? "Books"
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(BookTableViewCell.self, forCellReuseIdentifier: "BookCell")

        let stackView = UIStackView(arrangedSubviews: [tableView])
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)

        // Add the noBooksLabel to the view
        view.addSubview(noBooksLabel)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            noBooksLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            noBooksLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func fetchBooks() {
        guard let currentList = statusList else { return } // Ensure statusList is set
        let bookIDs = currentList.bookIDs
        
        // Fetch books only for the current list
        fetchBooksByIDs(bookIDs: bookIDs) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let books):
                self.allBooks = books
                self.filteredBooks = books
                self.tableView.reloadData()
                
                // Show/hide the noBooksLabel
                self.noBooksLabel.isHidden = !books.isEmpty
            case .failure(let error):
                print("Error fetching books: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - TableView Methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredBooks.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BookCell", for: indexPath) as! BookTableViewCell
        let book = filteredBooks[indexPath.row]
        cell.configure(with: book)
        
        // Handle the action button tap
        cell.actionButtonHandler = { [weak self] in
            self?.showActionSheet(for: book)
        }
        
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedBook = filteredBooks[indexPath.row]
        let bookVC = BookViewController(book: selectedBook)
        navigationController?.pushViewController(bookVC, animated: true)
    }

    // MARK: - SearchBar Methods
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filteredBooks = searchText.isEmpty ? allBooks : filterBooks(for: searchText)
        tableView.reloadData()
    }

    private func filterBooks(for searchText: String) -> [BookF] {
        return allBooks.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.authors?.joined(separator: ", ").localizedCaseInsensitiveContains(searchText) ?? false
        }
    }
    

    // MARK: - Action Sheet for Moving Books
    private func showActionSheet(for book: BookF) {
        guard let userID = Auth.auth().currentUser?.uid else { return }

        getCurrentStatus(for: book.id, userID: userID) { currentStatus in
            DispatchQueue.main.async {
                let actionSheet = UIAlertController(
                    title: "Manage Book",
                    message: "Current List: \(currentStatus)\nSelect a new list or delete the book.",
                    preferredStyle: .actionSheet
                )

                // Define status lists
                let lists: [Status] = [.wantToRead, .currentlyReading, .finished, .didNotFinish]

                // Filter out the current status and create actions
                for list in lists where list.rawValue != currentStatus {
                    let action = UIAlertAction(title: "Move to \(list.rawValue)", style: .default) { _ in
                        self.moveBook(book, to: list.rawValue)
                        
                    }
                    actionSheet.addAction(action)
                }

                // Add delete action
                let deleteAction = UIAlertAction(title: "Delete from Library", style: .destructive) { _ in
                    self.deleteBook(book)
                }
                actionSheet.addAction(deleteAction)

                // Add cancel action
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
                actionSheet.addAction(cancelAction)

                // Present the action sheet
                self.present(actionSheet, animated: true)
            }
        }
    }


    // MARK: - Move Book to Another List
    private func moveBook(_ book: BookF, to status: String) {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        getCurrentStatus(for: book.id, userID: userID) { currentStatus in
            Eclipse.moveBook(book.id, from: currentStatus, to: status, userID: userID) { error in
                if let error = error {
                    print("Error moving book: \(error.localizedDescription)")
                } else {
                    print("Book moved to \(status) list.")
                    self.fetchBooks() // Refresh the list
                }
            }
        }
    }

    // MARK: - Delete Book from Library
    private func deleteBook(_ book: BookF) {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        let alert = UIAlertController(title: "Delete Book", message: "Are you sure you want to delete '\(book.title)' from your library?", preferredStyle: .alert)
        
        let confirmAction = UIAlertAction(title: "Delete", style: .destructive) { _ in
            Eclipse.deleteBook(book.id, userID: userID) { error in
                if let error = error {
                    print("Error deleting book: \(error.localizedDescription)")
                } else {
                    print("Book deleted from library.")
                    self.fetchBooks() // Refresh the list
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(confirmAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
}
