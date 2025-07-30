import UIKit
import FirebaseAuth
import FirebaseFirestore

class GenrePreferencesViewController: UIViewController {
    
    let genres = [
        // Core Literary Genres
        ("Fiction", "book.fill"),
        ("Non-Fiction", "book.fill"),
        ("Fantasy", "sparkles"),
        ("Science Fiction", "antenna.radiowaves.left.and.right"),
        ("Cyberpunk", "cpu.fill"),
        ("Dystopian", "exclamationmark.triangle.fill"),
        ("Mystery", "magnifyingglass"),
        ("Thriller", "eye.fill"),
        ("Horror", "flame.fill"),
        ("Romance", "heart.fill"),
        ("Historical Fiction", "book.closed"),
        ("Adventure", "map.fill"),
        ("Young Adult", "person.2.fill"),
        ("New Adult", "person.fill.checkmark"),
        ("Children’s", "figure.child.circle"),
        ("Graphic Novel", "rectangle.compress.vertical"),
        ("Manga", "rectangle.expand.vertical"),
        ("Comics", "bubble.left.and.bubble.right.fill"),
        ("Classic Literature", "text.book.closed.fill"),
        
        // Thematic & Aesthetic Genres
        ("Slice of Life", "house.fill"),
        ("Light Academia", "sun.max"),
        ("Dark Academia", "book.circle.fill"),
        ("Cozy Fiction", "mug.fill"),
        ("Cottagecore", "leaf.fill"),
        ("Magical Realism", "wand.and.stars"),
        ("Mythology", "flame.circle"),
        ("Folklore", "scroll.fill"),
        ("Feminist Fiction", "venus"),
        ("Revolutionary Fiction", "flag.fill"),
        ("Environmental", "tree.fill"),
        ("LGBTQ+", "rainbow"),
        ("Spirituality", "hands.sparkles.fill"),
        
        // Travel & Exploration
        ("Travel", "airplane"),
        ("Road Trip", "car.fill"),
        ("Wanderlust", "globe.americas.fill"),
        
        // Non-Fiction & Special Interests
        ("Biography", "person.fill"),
        ("Memoir", "text.book.closed"),
        ("Self-Help", "person.3.fill"),
        ("Psychology", "brain.head.profile"),
        ("Philosophy", "lightbulb.fill"),
        ("Science", "atom"),
        ("Technology", "gear"),
        ("Political", "building.columns.fill"),
        ("History", "clock.arrow.circlepath"),
        ("True Crime", "exclamationmark.shield.fill"),
        ("Cookbooks", "fork.knife"),
        ("Humor", "face.smiling.fill"),
        ("Poetry", "textformat.size"),
        ("Music", "music.note"),
        ("Art & Design", "paintpalette.fill"),
        ("Fashion", "tshirt.fill"),
        ("Food Writing", "fork.knife.circle.fill"),
        ("Sports", "figure.walk"),
        
        // Subgenres & Niche Fiction
        ("Cozy Mystery", "house.fill"),
        ("Gothic Horror", "moon.fill"),
        ("Surrealist", "cloud.fill"),
        ("Alternate History", "clock.fill"),
        ("Space Opera", "rocket.fill"),
        ("Steampunk", "gearshape.fill"),
        ("Time Travel", "arrow.triangle.2.circlepath"),
        ("Post-Apocalyptic", "waveform.path.ecg"),
        ("Espionage", "eye.trianglebadge.exclamationmark.fill"),
        ("War & Military", "shield.lefthalf.filled"),
        ("Medical Fiction", "stethoscope"),
        ("Legal Thriller", "building.columns"),
        ("Metafiction", "ellipsis.rectangle.fill")
    ]

    var selectedGenres: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        let titleLabel = UILabel()
        titleLabel.text = "Selected Preferences"
        titleLabel.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        titleLabel.textColor = .black
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        let bubbleStackView = UIStackView()
        bubbleStackView.axis = .vertical
        bubbleStackView.spacing = 16
        bubbleStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bubbleStackView)
        
        var horizontalStackView = UIStackView()
        horizontalStackView.axis = .horizontal
        horizontalStackView.spacing = 16
        horizontalStackView.distribution = .fillEqually
        
        for (index, genre) in genres.enumerated() {
            let bubbleButton = createBubbleButton(for: genre)
            horizontalStackView.addArrangedSubview(bubbleButton)
            
            if (index + 1) % 2 == 0 || index == genres.count - 1 {
                bubbleStackView.addArrangedSubview(horizontalStackView)
                
                if index < genres.count - 1 {
                    horizontalStackView = UIStackView()
                    horizontalStackView.axis = .horizontal
                    horizontalStackView.spacing = 16
                    horizontalStackView.distribution = .fillEqually
                }
            }
        }

        let nextButton = UIButton()
        nextButton.setTitle("Next", for: .normal)
        nextButton.backgroundColor = UIColor(hex: "#005C78")
        nextButton.setTitleColor(.white, for: .normal)
        nextButton.layer.cornerRadius = 10
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
        
        view.addSubview(nextButton)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            
            bubbleStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            bubbleStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            bubbleStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            nextButton.topAnchor.constraint(equalTo: bubbleStackView.bottomAnchor, constant: 30),
            nextButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            nextButton.heightAnchor.constraint(equalToConstant: 50),
            nextButton.widthAnchor.constraint(equalToConstant: 200)
        ])
    }
    
    private func createBubbleButton(for genre: (String, String)) -> UIButton {
        let genreName = genre.0
        let symbolName = genre.1
        
        var configuration = UIButton.Configuration.plain()
        configuration.title = genreName
        configuration.image = UIImage(systemName: symbolName)
        
        configuration.baseForegroundColor = UIColor(hex: "#005C78")
        configuration.imagePadding = 8
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
        
        let titleAttributes = AttributeContainer([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16, weight: .regular)])
        configuration.attributedTitle = AttributedString(genreName, attributes: titleAttributes)
        configuration.background.backgroundColor = .white
        
        let button = UIButton(configuration: configuration, primaryAction: nil)
        
        button.layer.borderColor = UIColor(hex: "#005C78").cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 10
        button.translatesAutoresizingMaskIntoConstraints = false
        
        button.widthAnchor.constraint(equalToConstant: 140).isActive = true
        
        button.addTarget(self, action: #selector(bubbleTapped(_:)), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        return button
    }
    
    @objc private func bubbleTapped(_ sender: UIButton) {
        guard let configuration = sender.configuration,
              let genreName = configuration.title else {
            print("Button configuration or title is nil.")
            return
        }

        UIView.animate(withDuration: 0.2, animations: {
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.2, animations: {
                sender.transform = CGAffineTransform.identity
            })
        }

        if selectedGenres.contains(genreName) {
            selectedGenres.removeAll { $0 == genreName }
            sender.configuration?.background.backgroundColor = .white
            sender.configuration?.baseForegroundColor = UIColor(hex: "#005C78")
        } else {
            selectedGenres.append(genreName)
            sender.configuration?.background.backgroundColor = UIColor(hex: "#005C78")
            sender.configuration?.baseForegroundColor = .white
        }
    }
    
    @objc private func nextButtonTapped() {
        guard let user = Auth.auth().currentUser else {
            print("No authenticated user found.")
            return
        }

        let db = Firestore.firestore()
        let userRef = db.collection("users").document(user.uid).collection("userData").document("details")

        userRef.setData(["genrePreferences": selectedGenres], merge: true) { [weak self] error in
            if let error = error {
                print("Error saving preferences: \(error.localizedDescription)")
            } else {
                print("Genre preferences successfully saved.")
                let nextViewController = HomeViewController()
                nextViewController.modalPresentationStyle = .fullScreen
                self?.present(nextViewController, animated: true, completion: nil)
            }
        }
    }
}


