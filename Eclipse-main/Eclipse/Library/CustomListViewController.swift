import UIKit
import FirebaseFirestore
import FirebaseAuth

class CustomListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var tableView: UITableView!
    var allBooks: [BookF] = []
    var customList: List?
    private let db = Firestore.firestore()
    private var imageCache: [String: UIImage] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationBar()
        setupTableView()
        if let list = customList, !list.bookIDs.isEmpty {
            fetchBooksForList(list)
        }
    }
    
    private func setupNavigationBar() {
        // Set the navigation bar title
        navigationItem.title = customList?.title
        
        // Enable large titles
        navigationController?.navigationBar.prefersLargeTitles = true
        
        // Configure navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground // Use system background color
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label] // Use system label color for title
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label] // Use system label color for large title
        
        // Apply the appearance to the navigation bar
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        
        // Ensure the navigation bar is not translucent
        navigationController?.navigationBar.isTranslucent = false
    }
    
    private func setupTableView() {
        tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.estimatedRowHeight = 120
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(CustomBookTableViewCell.self, forCellReuseIdentifier: "CustomListBookCell")
        
        // Add long-press gesture recognizer
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        tableView.addGestureRecognizer(longPressGesture)
        
        view.addSubview(tableView)
        
        // Add Auto Layout constraints for the table view
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    @objc private func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        guard gestureRecognizer.state == .began else { return }
        
        // Get the location of the long press
        let location = gestureRecognizer.location(in: tableView)
        
        // Get the index path of the pressed cell
        if let indexPath = tableView.indexPathForRow(at: location) {
            let book = allBooks[indexPath.row]
            showRemoveBookActionSheet(for: book)
        }
    }
    
    private func showRemoveBookActionSheet(for book: BookF) {
        let actionSheet = UIAlertController(title: "Remove Book", message: "Are you sure you want to remove '\(book.title)' from this list?", preferredStyle: .actionSheet)
        
        // Add "Remove" action
        let removeAction = UIAlertAction(title: "Remove", style: .destructive) { [weak self] _ in
            self?.removeBookFromList(book)
        }
        
        // Add "Cancel" action
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        actionSheet.addAction(removeAction)
        actionSheet.addAction(cancelAction)
        
        // Present the action sheet
        present(actionSheet, animated: true, completion: nil)
    }
    
    private func removeBookFromList(_ book: BookF) {
        guard let userID = Auth.auth().currentUser?.uid,
              let listID = customList?.id else {
            print("User ID or list ID is missing.")
            return
        }
        
        // Reference to the user's custom list in Firestore
        let listRef = db.collection("users").document(userID).collection("customLists").document(listID)
        
        // Remove the book ID from the list's bookIDs array
        listRef.updateData([
            "bookIDs": FieldValue.arrayRemove([book.id])
        ]) { [weak self] error in
            if let error = error {
                print("Error removing book from list: \(error.localizedDescription)")
            } else {
                print("Book removed from list successfully.")
                // Remove the book from the local data source and reload the table view
                self?.allBooks.removeAll { $0.id == book.id }
                self?.tableView.reloadData()
            }
        }
    }
    
    private func fetchBooksForList(_ list: List) {
        let bookIDs = list.bookIDs
        allBooks.removeAll()
        tableView.reloadData()
        
        fetchBooksByIDs(bookIDs: bookIDs) { [weak self] result in
            switch result {
            case .success(let books):
                self?.allBooks = books
                self?.tableView.reloadData()
            case .failure(let error):
                print("Error fetching books: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - TableView DataSource and Delegate
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allBooks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "CustomListBookCell", for: indexPath) as? CustomBookTableViewCell else {
            return UITableViewCell()
        }
        
        let book = allBooks[indexPath.row]
        configureCell(cell, with: book)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedBook = allBooks[indexPath.row]
        let bookVC = BookViewController(book: selectedBook)
        navigationController?.pushViewController(bookVC, animated: true)
    }
    
    private func configureCell(_ cell: CustomBookTableViewCell, with book: BookF) {
        cell.titleLabel.text = book.title
        cell.authorLabel.text = book.authors?.joined(separator: ", ") ?? "Unknown Author"
        cell.descriptionLabel.text = book.description?.prefix(100).description ?? "No description available"
        
        if let thumbnailURL = book.imageLinks?.thumbnail {
            if let cachedImage = imageCache[thumbnailURL] {
                cell.bookImage.image = cachedImage
            } else {
                loadImage(from: thumbnailURL) { [weak self] image in
                    DispatchQueue.main.async {
                        cell.bookImage.image = image
                        self?.imageCache[thumbnailURL] = image
                    }
                }
            }
        } else {
            cell.bookImage.image = UIImage(systemName: "book")
        }
    }
    
    private func loadImage(from urlString: String, completion: @escaping (UIImage) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(UIImage(systemName: "book") ?? UIImage())
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let data = data, let image = UIImage(data: data) {
                completion(image)
            } else {
                completion(UIImage(systemName: "book") ?? UIImage())
            }
        }.resume()
    }
}
