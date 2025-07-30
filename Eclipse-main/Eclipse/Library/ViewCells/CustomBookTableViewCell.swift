import UIKit

protocol CustomBookTableViewCellDelegate: AnyObject {
    func didSelectBookmark(for book: BookF)
}

class CustomBookTableViewCell: UITableViewCell {

    var descriptionLabel: UILabel!
    var authorLabel: UILabel!
    var titleLabel: UILabel!
    var bookImage: UIImageView!
    var bookmarkButton: UIButton!

    weak var delegate: CustomBookTableViewCellDelegate?
    
    var book: BookF? {
        didSet {
            updateUI()
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        descriptionLabel = UILabel()
        authorLabel = UILabel()
        titleLabel = UILabel()
        bookImage = UIImageView()

        setupUI()

        addSubviews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        // Configure description label
        descriptionLabel.numberOfLines = 3
        descriptionLabel.lineBreakMode = .byTruncatingTail
        descriptionLabel.font = UIFont.systemFont(ofSize: 14)
        descriptionLabel.textColor = .darkGray

        // Configure book image
        bookImage.layer.cornerRadius = 8
        bookImage.layer.masksToBounds = true
        bookImage.contentMode = .scaleAspectFill

        // Style labels
        styleLabels()

        // Add shadow and corner radius to the cell's contentView
        contentView.layer.cornerRadius = 10
        contentView.layer.masksToBounds = false
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOpacity = 0.2
        contentView.layer.shadowOffset = CGSize(width: 2, height: 2)
        contentView.layer.shadowRadius = 4
        contentView.backgroundColor = .white
    }

    private func styleLabels() {
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        titleLabel.textColor = .black
        authorLabel.font = UIFont.systemFont(ofSize: 14)
        authorLabel.textColor = .gray
    }

    private func updateUI() {
        guard let book = book else { return }
        titleLabel.text = book.title
        authorLabel.text = book.authors?.joined(separator: ", ") ?? "Unknown Author"
        descriptionLabel.text = book.description?.htmlToPlainText ?? "No description available."

        // Load book image
        if let urlString = book.imageLinks?.thumbnail, let url = URL(string: urlString) {
            downloadImage(from: url) { [weak self] image in
                DispatchQueue.main.async {
                    self?.bookImage.image = image ?? UIImage(named: "placeholder")
                }
            }
        } else {
            bookImage.image = UIImage(named: "placeholder")
        }
    }

    private func downloadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print("Error downloading image: \(error.localizedDescription)")
                completion(nil)
                return
            }
            if let data = data, let image = UIImage(data: data) {
                completion(image)
            } else {
                completion(nil)
            }
        }.resume()
    }

    private func addSubviews() {
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(authorLabel)
        contentView.addSubview(titleLabel)
        contentView.addSubview(bookImage)
    }

    private func setupConstraints() {
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        authorLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        bookImage.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Book image constraints
            bookImage.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            bookImage.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            bookImage.widthAnchor.constraint(equalToConstant: 80),
            bookImage.heightAnchor.constraint(equalToConstant: 120),
            bookImage.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -16),

            // Title label constraints
            titleLabel.leadingAnchor.constraint(equalTo: bookImage.trailingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            titleLabel.topAnchor.constraint(equalTo: bookImage.topAnchor),

            // Author label constraints
            authorLabel.leadingAnchor.constraint(equalTo: bookImage.trailingAnchor, constant: 16),
            authorLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            authorLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),

            // Description label constraints
            descriptionLabel.leadingAnchor.constraint(equalTo: bookImage.trailingAnchor, constant: 16),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            descriptionLabel.topAnchor.constraint(equalTo: authorLabel.bottomAnchor, constant: 8),
            descriptionLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -16),
        ])
    }
}

extension String {
    var htmlToPlainText: String {
        guard let data = self.data(using: .utf8) else { return self }
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        guard let attributedString = try? NSAttributedString(data: data, options: options, documentAttributes: nil) else {
            return self
        }
        return attributedString.string
    }
}
