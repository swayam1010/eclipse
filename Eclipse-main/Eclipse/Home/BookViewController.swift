import UIKit
import FirebaseFirestore
import FirebaseAuth

class BookViewController: UIViewController {
    private let book: BookF
    private let db = Firestore.firestore()
    private var isBookAdded: Bool = false

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let bookImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        iv.layer.cornerRadius = 12
        iv.clipsToBounds = true
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let descriptionTextView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.font = .systemFont(ofSize: 16)
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.textColor = .darkGray
        textView.backgroundColor = .clear
        return textView
    }()

    private let rentButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Rent", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(hex: "005C78")
        button.layer.cornerRadius = 8
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 24, bottom: 12, right: 24)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let bookmarkButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "bookmark"), for: .normal)
        button.tintColor = .systemBlue
        return button
    }()

    init(book: BookF) {
        self.book = book
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureUI()
        checkIfBookIsAdded()

        rentButton.addTarget(self, action: #selector(navigateToRentersNearby), for: .touchUpInside)
        bookmarkButton.addTarget(self, action: #selector(bookmarkButtonTapped), for: .touchUpInside)
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        navigationItem.title = book.title
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(customView: bookmarkButton)
        ]

        // Add scrollView to the main view
        view.addSubview(scrollView)

        // Add contentView to the scrollView
        scrollView.addSubview(contentView)

        // Add UI components to the contentView
        contentView.addSubview(bookImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(descriptionTextView)
        contentView.addSubview(rentButton)

        // Constraints for scrollView and contentView
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        // Constraints for UI components inside contentView
        NSLayoutConstraint.activate([
            bookImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            bookImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            bookImageView.widthAnchor.constraint(equalToConstant: 200),
            bookImageView.heightAnchor.constraint(equalToConstant: 300),

            titleLabel.topAnchor.constraint(equalTo: bookImageView.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            descriptionTextView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            descriptionTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            descriptionTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            rentButton.topAnchor.constraint(equalTo: descriptionTextView.bottomAnchor, constant: 20),
            rentButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            rentButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }

    private func configureUI() {
        titleLabel.text = book.title

        if let htmlDescription = book.description {
            descriptionTextView.attributedText = convertHTMLToAttributedString(html: htmlDescription)
        } else {
            descriptionTextView.text = "No description available."
        }

        if let imageUrl = book.imageLinks?.thumbnail, let url = URL(string: imageUrl) {
            downloadImage(from: url) { [weak self] image in
                DispatchQueue.main.async {
                    self?.bookImageView.image = image ?? UIImage(systemName: "book.fill")
                }
            }
        } else {
            bookImageView.image = UIImage(systemName: "book.fill")
        }
    }

    private func convertHTMLToAttributedString(html: String) -> NSAttributedString {
        guard let data = html.data(using: .utf8) else {
            return NSAttributedString(string: "No description available.", attributes: [
                .font: UIFont.systemFont(ofSize: 16) // SF Pro font with size 15
            ])
        }

        do {
            let attributedString = try NSMutableAttributedString(
                data: data,
                options: [
                    .documentType: NSAttributedString.DocumentType.html,
                    .characterEncoding: String.Encoding.utf8.rawValue
                ],
                documentAttributes: nil
            )

            // Apply font to the whole attributed string
            let fullRange = NSRange(location: 0, length: attributedString.length)
            attributedString.addAttributes([
                .font: UIFont.systemFont(ofSize: 16) // SF Pro font with size 15
            ], range: fullRange)

            return attributedString
        } catch {
            return NSAttributedString(string: "No description available.", attributes: [
                .font: UIFont.systemFont(ofSize: 16) // SF Pro font with size 15
            ])
        }
    }

    
    private func checkIfBookIsAdded() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        db.collection("renters").document(userID).getDocument { [weak self] document, error in
            if let data = document?.data(), let rentedBooks = data["rentedBooks"] as? [[String: Any]] {
                self?.isBookAdded = rentedBooks.contains { $0["id"] as? String == self?.book.id }
            }
        }
    }

    @objc private func navigateToRentersNearby() {
        // Navigation code here
    }

    @objc private func bookmarkButtonTapped() {
        let addToLibraryVC = AddToLibraryViewController()
        addToLibraryVC.book = book

        let navController = UINavigationController(rootViewController: addToLibraryVC)
        navController.modalPresentationStyle = .formSheet
        present(navController, animated: true, completion: nil)
    }
}
