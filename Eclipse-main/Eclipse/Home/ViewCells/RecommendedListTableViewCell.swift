import UIKit

class RecommendedListTableViewCell: UITableViewCell, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    private var books: [BookF] = []

    let listTitle: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.boldSystemFont(ofSize: 18)
        return label
    }()

    let listDesc: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .gray
        return label
    }()

    let bookCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.register(RecommendedBookCollectionViewCell.self, forCellWithReuseIdentifier: "recommendedBookCell")
        return cv
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
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
            listTitle.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            listTitle.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            listDesc.topAnchor.constraint(equalTo: listTitle.bottomAnchor, constant: 5),
            listDesc.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            listDesc.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            bookCollectionView.topAnchor.constraint(equalTo: listDesc.bottomAnchor, constant: 10),
            bookCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            bookCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
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

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return books.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "recommendedBookCell", for: indexPath) as! RecommendedBookCollectionViewCell
        let book = books[indexPath.item]
        cell.configure(with: book)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 120, height: 180) // Adjusted size for book cells
    }
}

