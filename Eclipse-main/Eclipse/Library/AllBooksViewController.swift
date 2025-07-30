import UIKit
import FirebaseAuth

class AllBooksViewController: UIViewController {

    private let gridCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .systemBackground
        return collectionView
    }()

    private var displayedBooks: [BookF] = [] {
        didSet {
            DispatchQueue.main.async {
                self.gridCollectionView.reloadData()
                self.noBooksLabel.isHidden = !self.displayedBooks.isEmpty
            }
        }
    }

    private let noBooksLabel: UILabel = {
        let label = UILabel()
        label.text = "Bookmark books to add them to your library"
        label.textAlignment = .center
        label.textColor = .gray
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupCollectionViews()
        setupNoBooksLabel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        fetchBooks()
    }

    private func setupCollectionViews() {
        view.addSubview(gridCollectionView)
        
        NSLayoutConstraint.activate([
            gridCollectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            gridCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gridCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gridCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        gridCollectionView.register(BookCollectionViewCell.self, forCellWithReuseIdentifier: "BookCell")
        gridCollectionView.dataSource = self
        gridCollectionView.delegate = self
    }

    private func setupNoBooksLabel() {
        view.addSubview(noBooksLabel)
        
        NSLayoutConstraint.activate([
            noBooksLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            noBooksLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            noBooksLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            noBooksLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }

    private func fetchBooks() {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No user logged in.")
            return
        }

        fetchAllBookIds(userID: userID) { [weak self] result in
            switch result {
            case .success(let bookIds):
                if bookIds.isEmpty {
                    DispatchQueue.main.async {
                        self?.displayedBooks = []
                        self?.noBooksLabel.isHidden = false
                    }
                } else {
                    self?.fetchBooksByIDs(bookIDs: Array(bookIds))
                }
            case .failure(let error):
                print("Error fetching book IDs: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.displayedBooks = []
                    self?.noBooksLabel.isHidden = false
                }
            }
        }
    }

    private func fetchBooksByIDs(bookIDs: [String]) {
        Eclipse.fetchBooksByIDs(bookIDs: bookIDs) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let books):
                    self?.displayedBooks = books
                    self?.noBooksLabel.isHidden = !books.isEmpty
                case .failure(let error):
                    print("Error fetching books: \(error.localizedDescription)")
                    self?.displayedBooks = []
                    self?.noBooksLabel.isHidden = false
                }
            }
        }
    }

}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout
extension AllBooksViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return displayedBooks.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BookCell", for: indexPath) as? BookCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        let book = displayedBooks[indexPath.item]
        cell.configure(with: book)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.frame.width - 30) / 2
        return CGSize(width: width, height: 250)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedBook = displayedBooks[indexPath.item]
        let bookDetailVC = BookViewController(book: selectedBook)
        navigationController?.pushViewController(bookDetailVC, animated: true)
    }
}

