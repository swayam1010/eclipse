import UIKit
import CoreML

class SwipeViewController: UIViewController {
    
    private var books: [BookF] = [] // List of books from Google Books API
    private var likedBooks: [String: Double] = [:] // Stores liked books
    private var dislikedBooks: [String] = [] // Stores disliked books
    private var swipeCount = 0 // Tracks number of swipes
    private let maxSwipesBeforeRecommendation = 5 // Change to 7 if needed
    private var currentIndex = 0 // Tracks current book being displayed
    
    private var bookRecommender: BookRecommender? // ML Model Wrapper
    
    // UI Elements
    private let cardView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 15
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.2
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 6
        return view
    }()
    
    private let bookImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 10
        return imageView
    }()
    
    private let bookTitleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.numberOfLines = 2
        label.textColor = .darkGray
        return label
    }()
    
    private let bookAuthorLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.textColor = .gray
        return label
    }()
    
    private let bookDescriptionTextView: UITextView = {
        let textView = UITextView()
        textView.textAlignment = .center
        textView.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        textView.textColor = .darkGray
        textView.isEditable = false
        textView.isScrollEnabled = true
        textView.showsVerticalScrollIndicator = true
        textView.backgroundColor = .clear
        return textView
    }()
    
    private let bookRatingLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .systemYellow
        return label
    }()
    
    private let likeImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "hand.thumbsup.fill"))
        imageView.tintColor = .green
        imageView.alpha = 0
        return imageView
    }()
    
    private let dislikeImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "hand.thumbsdown.fill"))
        imageView.tintColor = .red
        imageView.alpha = 0
        return imageView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        // Set up navigation bar with large title
        setupNavigationBar()
        
        // Show genre selection pop-up
        showGenreSelection()
        
        // Initialize the BookRecommender
        bookRecommender = BookRecommender()
    }
    
    // MARK: - Navigation Bar Setup
    private func setupNavigationBar() {
        // Set large title
        navigationItem.title = "Swipe"
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    // MARK: - Genre Selection Pop-up
    private func showGenreSelection() {
        let alert = UIAlertController(title: "Select Genre", message: "Choose a genre to start swiping", preferredStyle: .alert)
        
        // Add genre options
        let genres = ["Fiction", "History", "Mystery", "Science Fiction", "Romance", "Thriller", "Biography"]
        for genre in genres {
            alert.addAction(UIAlertAction(title: genre, style: .default, handler: { _ in
                self.fetchTopBooks(for: genre)
                self.setupUI()
                self.setupGestures()
            }))
        }
        
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.addSubview(cardView)
        cardView.addSubview(bookImageView)
        cardView.addSubview(bookTitleLabel)
        cardView.addSubview(bookAuthorLabel)
        cardView.addSubview(bookDescriptionTextView)
        cardView.addSubview(bookRatingLabel)
        cardView.addSubview(likeImageView)
        cardView.addSubview(dislikeImageView)
        
        cardView.translatesAutoresizingMaskIntoConstraints = false
        bookImageView.translatesAutoresizingMaskIntoConstraints = false
        bookTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        bookAuthorLabel.translatesAutoresizingMaskIntoConstraints = false
        bookDescriptionTextView.translatesAutoresizingMaskIntoConstraints = false
        bookRatingLabel.translatesAutoresizingMaskIntoConstraints = false
        likeImageView.translatesAutoresizingMaskIntoConstraints = false
        dislikeImageView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Card View (full screen with padding)
            cardView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            cardView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            
            // Book Image
            bookImageView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 20),
            bookImageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            bookImageView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            bookImageView.heightAnchor.constraint(equalTo: cardView.heightAnchor, multiplier: 0.5), // 50% of the card
            
            // Book Title
            bookTitleLabel.topAnchor.constraint(equalTo: bookImageView.bottomAnchor, constant: 20),
            bookTitleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 10),
            bookTitleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -10),
            
            // Author Label
            bookAuthorLabel.topAnchor.constraint(equalTo: bookTitleLabel.bottomAnchor, constant: 10),
            bookAuthorLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 10),
            bookAuthorLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -10),
            
            // Description TextView
            bookDescriptionTextView.topAnchor.constraint(equalTo: bookAuthorLabel.bottomAnchor, constant: 20),
            bookDescriptionTextView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 10),
            bookDescriptionTextView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -10),
            bookDescriptionTextView.bottomAnchor.constraint(equalTo: bookRatingLabel.topAnchor, constant: -20),
            
            // Rating Label
            bookRatingLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -20),
            bookRatingLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 10),
            bookRatingLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -10),
            
            // Like/Dislike Icons
            likeImageView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            likeImageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            likeImageView.widthAnchor.constraint(equalToConstant: 80),
            likeImageView.heightAnchor.constraint(equalToConstant: 80),
            
            dislikeImageView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            dislikeImageView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            dislikeImageView.widthAnchor.constraint(equalToConstant: 80),
            dislikeImageView.heightAnchor.constraint(equalToConstant: 80)
        ])
    }
    
    private func setupGestures() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        cardView.addGestureRecognizer(panGesture)
    }
    
    // MARK: - Fetch Bestselling Books
    private func fetchTopBooks(for genre: String) {
        fetchBooks(query: genre) { result in
            switch result {
            case .success(let fetchedBooks):
                self.books = Array(fetchedBooks.prefix(7)) // Fetch only 7 books
                DispatchQueue.main.async {
                    self.displayBook()
                }
            case .failure(let error):
                print("Error fetching books: \(error)")
            }
        }
    }
    
    // MARK: - Display Current Book
    private func displayBook() {
        guard currentIndex < books.count else { return }
        
        let book = books[currentIndex]
        bookTitleLabel.text = book.title
        bookAuthorLabel.text = "By: \(book.authors?.joined(separator: ", ") ?? "Unknown")"
        bookDescriptionTextView.text = book.description ?? "No description available."
        bookRatingLabel.text = "Rating: \(book.averageRating ?? 0)/5"
        
        if let thumbnail = book.imageLinks?.thumbnail, let imageURL = URL(string: thumbnail) {
            DispatchQueue.global().async {
                do {
                    let data = try Data(contentsOf: imageURL)
                    if let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            self.bookImageView.image = image
                        }
                    }
                } catch {
                    print("Error loading image: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Handle Pan Gesture (Swipe)
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let card = gesture.view else { return }
        let translation = gesture.translation(in: view)
        
        switch gesture.state {
        case .changed:
            // Restrict movement to horizontal only
            card.center = CGPoint(x: view.center.x + translation.x, y: view.center.y)
            
            // Show like/dislike icons based on swipe direction
            if translation.x > 0 {
                likeImageView.alpha = abs(translation.x) / view.frame.width
                dislikeImageView.alpha = 0
            } else {
                dislikeImageView.alpha = abs(translation.x) / view.frame.width
                likeImageView.alpha = 0
            }
            
            // Rotate the card slightly
            let rotationAngle = (translation.x / view.frame.width) * 0.4
            card.transform = CGAffineTransform(rotationAngle: rotationAngle)
            
        case .ended:
            if translation.x > 100 {
                // Swiped right (like)
                likeBook()
                animateCardSwipe(to: CGPoint(x: view.frame.width + card.frame.width, y: card.center.y))
            } else if translation.x < -100 {
                // Swiped left (dislike)
                dislikeBook()
                animateCardSwipe(to: CGPoint(x: -card.frame.width, y: card.center.y))
            } else {
                // Reset card position
                UIView.animate(withDuration: 0.3) {
                    card.center = self.view.center
                    card.transform = .identity
                    self.likeImageView.alpha = 0
                    self.dislikeImageView.alpha = 0
                }
            }
            
        default:
            break
        }
    }
    
    private func likeBook() {
        let currentBook = books[currentIndex]
        likedBooks[currentBook.id] = 1.0
        swipeCount += 1
        currentIndex += 1
        checkForRecommendations()
    }
    
    private func dislikeBook() {
        let currentBook = books[currentIndex]
        dislikedBooks.append(currentBook.id)
        swipeCount += 1
        currentIndex += 1
        checkForRecommendations()
    }
    
    private func checkForRecommendations() {
        if swipeCount >= maxSwipesBeforeRecommendation {
            getRecommendations()
            swipeCount = 0
            currentIndex = 0
        } else {
            displayBook()
        }
    }
    
    private func animateCardSwipe(to point: CGPoint) {
        UIView.animate(withDuration: 0.3, animations: {
            self.cardView.center = point
        }) { _ in
            self.cardView.center = self.view.center
            self.cardView.transform = .identity
            self.likeImageView.alpha = 0
            self.dislikeImageView.alpha = 0
            self.displayBook()
        }
    }
    
    private func getRecommendations() {
        guard let recommender = bookRecommender else { return }
        
        print("Liked Books: \(likedBooks)")
        print("Disliked Books: \(dislikedBooks)")
        
        // Fetch titles for liked and disliked books
        let allBookIDs = Array(likedBooks.keys) + dislikedBooks
        fetchTitles(for: allBookIDs) { titleMap in
            // Map likedBooks to use titles instead of IDs
            var likedBooksWithTitles: [String: Double] = [:]
            for (bookID, score) in self.likedBooks {
                if let title = titleMap[bookID] {
                    likedBooksWithTitles[title] = score
                }
            }
            
            // Map dislikedBooks to use titles instead of IDs
            let dislikedBooksWithTitles = self.dislikedBooks.compactMap { titleMap[$0] }
            
            // Get recommendations using titles
            let recommendedBooks = recommender.recommendBooks(
                items: likedBooksWithTitles,
                numResults: 3,
                restrict: nil,
                exclude: dislikedBooksWithTitles
            )
            
            print("Recommended Books: \(recommendedBooks)")
            
            // Reset liked and disliked books for the next cycle
            self.likedBooks = [:]
            self.dislikedBooks = []
            
            // Pass recommended books to ResultsViewController
            let resultsVC = ResultsViewController()
            resultsVC.recommendedBooks = recommendedBooks
            self.navigationController?.pushViewController(resultsVC, animated: true)
        }
    }

    private func fetchTitles(for bookIDs: [String], completion: @escaping ([String: String]) -> Void) {
        var titleMap: [String: String] = [:]
        let dispatchGroup = DispatchGroup()
        
        for bookID in bookIDs {
            dispatchGroup.enter()
            fetchBookDetails(bookID: bookID) { title in
                if let title = title {
                    titleMap[bookID] = title
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(titleMap)
        }
    }

    private func fetchBookDetails(bookID: String, completion: @escaping (String?) -> Void) {
        let urlString = "https://www.googleapis.com/books/v1/volumes/\(bookID)"
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Error fetching book details: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let volumeInfo = json["volumeInfo"] as? [String: Any],
                   let title = volumeInfo["title"] as? String {
                    completion(title)
                } else {
                    completion(nil)
                }
            } catch {
                print("Error parsing book details: \(error.localizedDescription)")
                completion(nil)
            }
        }
        task.resume()
    }
}
