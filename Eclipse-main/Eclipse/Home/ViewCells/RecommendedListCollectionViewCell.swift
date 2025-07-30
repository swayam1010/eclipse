import UIKit

class RecommendedListCollectionViewCell: UICollectionViewCell, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    private var books: [BookF] = []

    let listTitle: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.boldSystemFont(ofSize: 20)
        return label
    }()

    let listDesc: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.font = UIFont.systemFont(ofSize: 18)
        label.textColor = .gray
        return label
    }()

    let bookCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.isPagingEnabled = true
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.register(RecommendedBookCollectionViewCell.self, forCellWithReuseIdentifier: "recommendedBookCell")
        return cv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        contentView.addSubview(listTitle)
        contentView.addSubview(listDesc)
        contentView.addSubview(bookCollectionView)

        NSLayoutConstraint.activate([
            listTitle.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            listTitle.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            listTitle.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            listDesc.topAnchor.constraint(equalTo: listTitle.bottomAnchor, constant: 2),
            listDesc.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            listDesc.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            bookCollectionView.topAnchor.constraint(equalTo: listDesc.bottomAnchor, constant: 10),
            bookCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            bookCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            bookCollectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            bookCollectionView.heightAnchor.constraint(equalToConstant: 200)
        ])

        bookCollectionView.dataSource = self
        bookCollectionView.delegate = self
    }

    func configure(with recommendedList: RecommendedList, books: [BookF]) {
        listTitle.text = recommendedList.title
        listDesc.text = recommendedList.subtitle
        self.books = books
        bookCollectionView.reloadData()
    }

    // MARK: - CollectionView DataSource and Delegate

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return books.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "recommendedBookCell", for: indexPath) as! RecommendedBookCollectionViewCell
        let book = books[indexPath.item]
        cell.configure(with: book)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedBook = books[indexPath.item] // Get the selected book
        let bookVC = BookViewController(book: selectedBook) // Pass the book to the view controller
        if let parentVC = findParentViewController() {
            parentVC.navigationController?.pushViewController(bookVC, animated: true)
        }
    }

    // Helper function to find the parent view controller
    private func findParentViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while let nextResponder = responder?.next {
            if let viewController = nextResponder as? UIViewController {
                return viewController
            }
            responder = nextResponder
        }
        return nil
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 120, height: 180) // Adjusted size for book cells
    }
}

