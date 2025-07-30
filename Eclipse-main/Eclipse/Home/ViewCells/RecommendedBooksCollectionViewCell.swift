import UIKit

class RecommendedBookCollectionViewCell: UICollectionViewCell {
    let bookImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(systemName: "book.closed")
        return imageView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(bookImageView)
        
        NSLayoutConstraint.activate([
            bookImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            bookImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            bookImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            bookImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with book: BookF) {
        if let imageURLString = book.imageLinks?.thumbnail, let imageURL = URL(string: imageURLString) {
            downloadImage(from: imageURL) { [weak self] image in
                DispatchQueue.main.async {
                    self?.bookImageView.image = image ?? UIImage(systemName: "book.closed")
                }
            }
        } else {
            bookImageView.image = UIImage(systemName: "book.closed")
        }
    }
}
