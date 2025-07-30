import UIKit

class ResultsViewController: UIViewController {
    
    var recommendedBooks: [(String, Double)] = [] // (Title, Recommendation Score)
    private var bookDetails: [BookF] = []
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        return scrollView
    }()
    
    private let contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 0
        return stackView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupNavigationBar()
        setupUI()
        fetchBookDetails()
    }
    
    private func setupNavigationBar() {
        // Set the book title as the navigation item's title
        navigationItem.title = "Book Recommendations"
        
        // Add bookmark icon to the navigation bar
        let bookmarkButton = UIBarButtonItem(image: UIImage(systemName: "bookmark"), style: .plain, target: self, action: #selector(bookmarkButtonTapped))
        bookmarkButton.tintColor = .systemBlue
        navigationItem.rightBarButtonItem = bookmarkButton
    }
    
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentStackView)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Scroll View
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            // Content Stack View
            contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentStackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])
    }
    
    private func fetchBookDetails() {
        for book in recommendedBooks {
            let title = book.0
            let score = book.1
            
            fetchBookDetailsFromGoogleBooks(title: title) { result in
                switch result {
                case .success(let bookDetails):
                    DispatchQueue.main.async {
                        self.bookDetails.append(bookDetails)
                        self.addBookCard(bookDetails: bookDetails, score: score)
                    }
                case .failure(let error):
                    print("Error fetching book details: \(error)")
                }
            }
        }
    }
    
    private func addBookCard(bookDetails: BookF, score: Double) {
        let cardView = UIView()
        cardView.backgroundColor = .white
        
        let bookImageView = UIImageView()
        bookImageView.contentMode = .scaleAspectFill
        bookImageView.clipsToBounds = true
        bookImageView.layer.cornerRadius = 10
        
        let bookTitleLabel = UILabel()
        bookTitleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        bookTitleLabel.textAlignment = .center
        bookTitleLabel.numberOfLines = 2
        bookTitleLabel.textColor = .darkGray
        
        let bookAuthorLabel = UILabel()
        bookAuthorLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        bookAuthorLabel.textAlignment = .center
        bookAuthorLabel.textColor = .gray
        
        let bookDescriptionLabel = UILabel()
        bookDescriptionLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        bookDescriptionLabel.textAlignment = .center
        bookDescriptionLabel.textColor = .darkGray
        bookDescriptionLabel.numberOfLines = 0
        
        let ratingStack = UIStackView()
        ratingStack.axis = .horizontal
        ratingStack.spacing = 5
        ratingStack.alignment = .center
        
        // Populate UI elements with book details
        bookTitleLabel.text = bookDetails.title
        bookAuthorLabel.text = "By: \(bookDetails.authors?.joined(separator: ", ") ?? "Unknown")"
        bookDescriptionLabel.text = bookDetails.description ?? "No description available."
        
        let ratingLabel = UILabel()
        ratingLabel.text = "\(bookDetails.averageRating ?? 0)/5"
        ratingLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        ratingLabel.textColor = .black
        
        let starImageView = UIImageView(image: UIImage(systemName: "star.fill"))
        starImageView.tintColor = .systemYellow
        
        ratingStack.addArrangedSubview(ratingLabel)
        ratingStack.addArrangedSubview(starImageView)
        
        // Load book image
        if let thumbnail = bookDetails.imageLinks?.thumbnail, let imageURL = URL(string: thumbnail) {
            DispatchQueue.global().async {
                do {
                    let data = try Data(contentsOf: imageURL)
                    if let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            bookImageView.image = image
                        }
                    }
                } catch {
                    print("Error loading image: \(error.localizedDescription)")
                }
            }
        }
        
        // Add subviews to card
        cardView.addSubview(bookImageView)
        cardView.addSubview(bookTitleLabel)
        cardView.addSubview(bookAuthorLabel)
        cardView.addSubview(bookDescriptionLabel)
        cardView.addSubview(ratingStack)
        
        bookImageView.translatesAutoresizingMaskIntoConstraints = false
        bookTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        bookAuthorLabel.translatesAutoresizingMaskIntoConstraints = false
        bookDescriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        ratingStack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Book Image
            bookImageView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 20),
            bookImageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            bookImageView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            bookImageView.heightAnchor.constraint(equalTo: cardView.heightAnchor, multiplier: 0.5), // 50% of the card
            
            // Book Title
            bookTitleLabel.topAnchor.constraint(equalTo: bookImageView.bottomAnchor, constant: 20),
            bookTitleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            bookTitleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            
            // Author Label
            bookAuthorLabel.topAnchor.constraint(equalTo: bookTitleLabel.bottomAnchor, constant: 10),
            bookAuthorLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            bookAuthorLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            
            // Description Label
            bookDescriptionLabel.topAnchor.constraint(equalTo: bookAuthorLabel.bottomAnchor, constant: 20),
            bookDescriptionLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            bookDescriptionLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            
            // Rating Stack
            ratingStack.topAnchor.constraint(equalTo: bookDescriptionLabel.bottomAnchor, constant: 20),
            ratingStack.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            ratingStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -20)
        ])
        
        // Add card to stack view
        contentStackView.addArrangedSubview(cardView)
        
        // Set card width to match scroll view width
        cardView.widthAnchor.constraint(equalTo: scrollView.widthAnchor).isActive = true
    }
    
    @objc private func bookmarkButtonTapped() {
        let currentPage = Int(scrollView.contentOffset.x / scrollView.frame.width)
        guard currentPage < bookDetails.count else { return }
        
        let currentBook = bookDetails[currentPage]
        
        // Present AddToLibraryViewController as a popover
        let addToLibraryVC = AddToLibraryViewController()
        addToLibraryVC.book = currentBook
        let navController = UINavigationController(rootViewController: addToLibraryVC)
        navController.modalPresentationStyle = .formSheet
        present(navController, animated: true, completion: nil)
    }
    
    private func fetchBookDetailsFromGoogleBooks(title: String, completion: @escaping (Result<BookF, Error>) -> Void) {
        let query = title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://www.googleapis.com/books/v1/volumes?q=\(query)"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: -1, userInfo: nil)))
                return
            }
            
            do {
                // Decode the JSON response
                let json = try JSONDecoder().decode(GoogleBooksResponse.self, from: data)
                if let firstItem = json.items.first {
                    // Manually create a BookF object
                    let bookF = BookF(
                        id: firstItem.id, // Use the id from the root level
                        title: firstItem.volumeInfo.title,
                        subtitle: firstItem.volumeInfo.subtitle,
                        authors: firstItem.volumeInfo.authors,
                        description: firstItem.volumeInfo.description,
                        averageRating: firstItem.volumeInfo.averageRating,
                        ratingsCount: firstItem.volumeInfo.ratingsCount,
                        imageLinks: firstItem.volumeInfo.imageLinks,
                        previewLink: firstItem.volumeInfo.previewLink,
                        pageCount: firstItem.volumeInfo.pageCount
                    )
                    completion(.success(bookF))
                } else {
                    completion(.failure(NSError(domain: "No books found", code: -1, userInfo: nil)))
                }
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
}

// MARK: - Google Books API Response Models
struct GoogleBooksResponse: Codable {
    let items: [GoogleBookItem]
}

struct GoogleBookItem: Codable {
    let id: String
    let volumeInfo: VolumeInfo
}
