import UIKit
import FirebaseFirestore
import FirebaseAuth

class RentBookViewController: UIViewController {
    private let book: RentersBook
    private let db = Firestore.firestore()
    
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
    
    private let authorsLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.textAlignment = .center
        label.numberOfLines = 1
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
    
    private let priceLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textAlignment = .center
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let rentButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Rent Book", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(hex: "005C78")
        button.layer.cornerRadius = 8
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 24, bottom: 12, right: 24)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    init(book: RentersBook) {
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
        
        rentButton.addTarget(self, action: #selector(rentBookTapped), for: .touchUpInside)
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        navigationItem.title = book.title
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(bookImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(authorsLabel)
        contentView.addSubview(descriptionTextView)
        contentView.addSubview(priceLabel)
        contentView.addSubview(rentButton)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            bookImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            bookImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            bookImageView.widthAnchor.constraint(equalToConstant: 200),
            bookImageView.heightAnchor.constraint(equalToConstant: 300),
            
            titleLabel.topAnchor.constraint(equalTo: bookImageView.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            authorsLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            authorsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            authorsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            descriptionTextView.topAnchor.constraint(equalTo: authorsLabel.bottomAnchor, constant: 16),
            descriptionTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            descriptionTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            priceLabel.topAnchor.constraint(equalTo: descriptionTextView.bottomAnchor, constant: 16),
            priceLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            rentButton.topAnchor.constraint(equalTo: priceLabel.bottomAnchor, constant: 20),
            rentButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            rentButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    private func configureUI() {
        titleLabel.text = book.title
        authorsLabel.text = "by " + book.authors.joined(separator: ", ")
        descriptionTextView.text = book.description
        priceLabel.text = String(format: "₹%.2f", book.price)
        
        if let url = URL(string: book.imageURL) {
            downloadImage(from: url) { [weak self] image in
                DispatchQueue.main.async {
                    self?.bookImageView.image = image ?? UIImage(systemName: "book.fill")
                }
            }
        } else {
            bookImageView.image = UIImage(systemName: "book.fill")
        }
    }
    
    @objc private func rentBookTapped() {
        // Rent book logic here
    }
}

