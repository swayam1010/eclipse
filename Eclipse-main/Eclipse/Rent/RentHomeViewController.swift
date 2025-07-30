import UIKit
import FirebaseFirestore
import FirebaseAuth

class RentHomeViewController: UIViewController {

    private var renters: [Renter] = []
    private var currentlyRentedBooks: [RentersBook] = []

    // MARK: - UI Components
    private let scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.showsVerticalScrollIndicator = false
        return scroll
    }()

    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let searchContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Rent your next read..."
        searchBar.searchBarStyle = .minimal
        searchBar.searchTextField.backgroundColor = .secondarySystemBackground
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        return searchBar
    }()

    private let currentlyRentedLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Currently Rented"
        label.font = .systemFont(ofSize: 25, weight: .medium)
        return label
    }()

    private let seeMoreButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("See more", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        let chevronImage = UIImage(systemName: "chevron.right")
        button.setImage(chevronImage, for: .normal)
        button.tintColor = .systemBlue
        button.semanticContentAttribute = .forceRightToLeft
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: -8)
        return button
    }()

    private let currentlyRentedCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 15
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.showsHorizontalScrollIndicator = false
        cv.backgroundColor = .clear
        return cv
    }()

    private let rentersLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Top Renters in your Area"
        label.font = .systemFont(ofSize: 25, weight: .medium)
        return label
    }()

    private let rentersCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 15
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.showsHorizontalScrollIndicator = false
        cv.backgroundColor = .clear
        return cv
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCollectionViews()
        fetchRenters()
        fetchCurrentlyRentedBooks()
    }

    private func setupUI() {
        view.backgroundColor = .white

        // Add scrollView and contentView
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        // Add subviews to contentView
        let views = [
            searchContainer, currentlyRentedLabel, seeMoreButton,
            currentlyRentedCollectionView, rentersLabel, rentersCollectionView
        ]
        for view in views {
            contentView.addSubview(view)
        }

        // Add searchBar to searchContainer
        searchContainer.addSubview(searchBar)

        // Setup constraints
        setupConstraints()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // ScrollView constraints
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // ContentView constraints
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            // SearchContainer constraints
            searchContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            searchContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            searchContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            searchContainer.heightAnchor.constraint(equalToConstant: 50),

            // SearchBar constraints
            searchBar.leadingAnchor.constraint(equalTo: searchContainer.leadingAnchor, constant: 8),
            searchBar.centerYAnchor.constraint(equalTo: searchContainer.centerYAnchor),
            searchBar.trailingAnchor.constraint(equalTo: searchContainer.trailingAnchor, constant: -8),

            // CurrentlyRentedLabel constraints
            currentlyRentedLabel.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 30),
            currentlyRentedLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            // SeeMoreButton constraints
            seeMoreButton.centerYAnchor.constraint(equalTo: currentlyRentedLabel.centerYAnchor),
            seeMoreButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // CurrentlyRentedCollectionView constraints
            currentlyRentedCollectionView.topAnchor.constraint(equalTo: currentlyRentedLabel.bottomAnchor, constant: 20),
            currentlyRentedCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            currentlyRentedCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            currentlyRentedCollectionView.heightAnchor.constraint(equalToConstant: 200),

            // RentersLabel constraints
            rentersLabel.topAnchor.constraint(equalTo: currentlyRentedCollectionView.bottomAnchor, constant: 30),
            rentersLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            // RentersCollectionView constraints
            rentersCollectionView.topAnchor.constraint(equalTo: rentersLabel.bottomAnchor, constant: 20),
            rentersCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            rentersCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            rentersCollectionView.heightAnchor.constraint(equalToConstant: 140),
            rentersCollectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20) // Ensure contentView expands
        ])

        // Add target for seeMoreButton
        seeMoreButton.addTarget(self, action: #selector(seeMoreButtonTapped), for: .touchUpInside)
    }

    private func setupCollectionViews() {
        // Set delegates and data sources
        currentlyRentedCollectionView.delegate = self
        currentlyRentedCollectionView.dataSource = self
        rentersCollectionView.delegate = self
        rentersCollectionView.dataSource = self

        // Enable interaction
        currentlyRentedCollectionView.isUserInteractionEnabled = true
        rentersCollectionView.isUserInteractionEnabled = true

        // Register cells
        currentlyRentedCollectionView.register(BooksCell.self, forCellWithReuseIdentifier: "BooksCell")
        rentersCollectionView.register(RenterCell.self, forCellWithReuseIdentifier: "RenterCell")
    }

    private func fetchRenters() {
        Eclipse.fetchRenters { [weak self] result in
            switch result {
            case .success(let renters):
                self?.renters = renters
                DispatchQueue.main.async {
                    self?.rentersCollectionView.reloadData()
                }
            case .failure(let error):
                print("Error fetching renters: \(error.localizedDescription)")
            }
        }
    }

    private func fetchCurrentlyRentedBooks() {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("Error: No authenticated user found.")
            return
        }

        Eclipse.fetchCurrentlyRentedBooks(for: userID) { [weak self] result in
            switch result {
            case .success(let rentedBooks):
                self?.currentlyRentedBooks = rentedBooks
                DispatchQueue.main.async {
                    self?.currentlyRentedCollectionView.reloadData()
                }
            case .failure(let error):
                print("Error fetching rented books: \(error.localizedDescription)")
            }
        }
    }

    @objc private func seeMoreButtonTapped() {
        let bookManagementVC = BorrowedBooksViewController()
        navigationController?.pushViewController(bookManagementVC, animated: true)
    }
}

// MARK: - UICollectionView Extensions
extension RentHomeViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch collectionView {
        case currentlyRentedCollectionView:
            return currentlyRentedBooks.count
        case rentersCollectionView:
            return renters.count
        default:
            return 0
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch collectionView {
        case currentlyRentedCollectionView:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BooksCell", for: indexPath) as! BooksCell
            let book = currentlyRentedBooks[indexPath.item]
            cell.configure(with: book)
            return cell
        case rentersCollectionView:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RenterCell", for: indexPath) as! RenterCell
            let renter = renters[indexPath.item]
            cell.configure(name: renter.name, image: UIImage(named: "profile")!)
            return cell
        default:
            return UICollectionViewCell()
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("Cell tapped at section: \(indexPath.section), item: \(indexPath.item)")

        switch collectionView {
        case currentlyRentedCollectionView:
            let book = currentlyRentedBooks[indexPath.item]
            print("Currently Rented Book Selected: \(book.title)")
        case rentersCollectionView:
            let renter = renters[indexPath.item]
            print("Renter Selected: \(renter.id), Rating: \(String(describing: renter.rating))")
            let profileVC = RentersProfileViewController(renterID: renter.id, renterRating: renter.rating!)
            navigationController?.pushViewController(profileVC, animated: true)
        default:
            break
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch collectionView {
        case currentlyRentedCollectionView:
            return CGSize(width: 140, height: 200)
        case rentersCollectionView:
            return CGSize(width: 100, height: 140)
        default:
            return CGSize.zero
        }
    }
}

//
//import UIKit
//import FirebaseFirestore
//import FirebaseAuth
//
//class RentHomeViewController: UIViewController {
//
//    private var renters: [Renter] = []
//    private var currentlyRentedBooks: [RentersBook] = []
//
//    // MARK: - UI Components
//    private let scrollView: UIScrollView = {
//        let scroll = UIScrollView()
//        scroll.translatesAutoresizingMaskIntoConstraints = false
//        scroll.showsVerticalScrollIndicator = false
//        return scroll
//    }()
//
//    private let contentView: UIView = {
//        let view = UIView()
//        view.translatesAutoresizingMaskIntoConstraints = false
//        return view
//    }()
//
//    private let searchContainer: UIView = {
//        let view = UIView()
//        view.backgroundColor = .systemBackground
//        view.translatesAutoresizingMaskIntoConstraints = false
//        return view
//    }()
//
//    private lazy var searchBar: UISearchBar = {
//        let searchBar = UISearchBar()
//        searchBar.placeholder = "Rent your next read..."
//        searchBar.searchBarStyle = .minimal
//        searchBar.searchTextField.backgroundColor = .secondarySystemBackground
//        searchBar.translatesAutoresizingMaskIntoConstraints = false
//        return searchBar
//    }()
//
//    private let titleLabel: UILabel = {
//        let label = UILabel()
//        label.translatesAutoresizingMaskIntoConstraints = false
//        label.text = "Rent from your\nCommunity"
//        label.numberOfLines = 2
//        label.font = .systemFont(ofSize: 30, weight: .bold)
//        return label
//    }()
//
//    private let currentlyRentedLabel: UILabel = {
//        let label = UILabel()
//        label.translatesAutoresizingMaskIntoConstraints = false
//        label.text = "Currently Rented"
//        label.font = .systemFont(ofSize: 20, weight: .medium)
//        return label
//    }()
//
//    private let seeMoreButton: UIButton = {
//        let button = UIButton()
//        button.translatesAutoresizingMaskIntoConstraints = false
//        button.setTitle("See more", for: .normal)
//        button.setTitleColor(.systemBlue, for: .normal)
//        let chevronImage = UIImage(systemName: "chevron.right")
//        button.setImage(chevronImage, for: .normal)
//        button.tintColor = .systemBlue
//        button.semanticContentAttribute = .forceRightToLeft
//        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: -8)
//        return button
//    }()
//
//    private let currentlyRentedCollectionView: UICollectionView = {
//        let layout = UICollectionViewFlowLayout()
//        layout.scrollDirection = .horizontal
//        layout.minimumInteritemSpacing = 15
//        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
//        cv.translatesAutoresizingMaskIntoConstraints = false
//        cv.showsHorizontalScrollIndicator = false
//        cv.backgroundColor = .clear
//        return cv
//    }()
//
//    private let rentersLabel: UILabel = {
//        let label = UILabel()
//        label.translatesAutoresizingMaskIntoConstraints = false
//        label.text = "Top Renters in your Area"
//        label.font = .systemFont(ofSize: 25, weight: .medium)
//        return label
//    }()
//
//    private let rentersCollectionView: UICollectionView = {
//        let layout = UICollectionViewFlowLayout()
//        layout.scrollDirection = .horizontal
//        layout.minimumLineSpacing = 15
//        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
//        cv.translatesAutoresizingMaskIntoConstraints = false
//        cv.showsHorizontalScrollIndicator = false
//        cv.backgroundColor = .clear
//        return cv
//    }()
//
//    // MARK: - Login/Signup UI Components
//    private let loginStackView: UIStackView = {
//        let stack = UIStackView()
//        stack.translatesAutoresizingMaskIntoConstraints = false
//        stack.axis = .vertical
//        stack.spacing = 20
//        stack.alignment = .center
//        stack.isHidden = true
//        return stack
//    }()
//
//    private let loginMessageLabel: UILabel = {
//        let label = UILabel()
//        label.text = "Please log in or sign up to rent books."
//        label.font = .systemFont(ofSize: 16, weight: .medium)
//        label.textColor = .secondaryLabel
//        label.textAlignment = .center
//        label.numberOfLines = 0
//        return label
//    }()
//
//    private let loginSignupButton: UIButton = {
//        let button = UIButton(type: .system)
//        button.setTitle("Login / Signup", for: .normal)
//        button.setTitleColor(.white, for: .normal)
//        button.backgroundColor = .systemBlue
//        button.layer.cornerRadius = 8
//        button.addTarget(self, action: #selector(loginSignupButtonTapped), for: .touchUpInside)
//        button.widthAnchor.constraint(equalToConstant: 200).isActive = true
//        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
//        return button
//    }()
//
//    private let noBooksMessageLabel: UILabel = {
//        let label = UILabel()
//        label.translatesAutoresizingMaskIntoConstraints = false
//        label.text = "You haven't rented any books yet. Start renting now!"
//        label.font = .systemFont(ofSize: 16, weight: .medium)
//        label.textColor = .secondaryLabel
//        label.textAlignment = .center
//        label.numberOfLines = 0
//        label.isHidden = true
//        return label
//    }()
//
//    // MARK: - Lifecycle
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        setupUI()
//        setupCollectionViews()
//        checkUserLoginStatus()
//    }
//
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        checkUserLoginStatus()
//        
//        // Fetch renters with a completion handler
//        fetchRenters { [weak self] result in
//            switch result {
//            case .success(let renters):
//                self?.renters = renters
//                DispatchQueue.main.async {
//                    self?.rentersCollectionView.reloadData()
//                }
//            case .failure(let error):
//                print("Error fetching renters: \(error.localizedDescription)")
//            }
//        }
//        
//        // Fetch currently rented books
//        fetchCurrentlyRentedBooks()
//    }
//
//    // MARK: - UI Setup
//    private func setupUI() {
//        view.backgroundColor = .white
//
//        // Add scrollView and contentView
//        view.addSubview(scrollView)
//        scrollView.addSubview(contentView)
//
//        // Add subviews to contentView
//        let views = [
//            searchContainer, titleLabel, currentlyRentedLabel, seeMoreButton,
//            currentlyRentedCollectionView, rentersLabel, rentersCollectionView,
//            loginStackView, noBooksMessageLabel
//        ]
//        for view in views {
//            contentView.addSubview(view)
//        }
//
//        // Add login components to stack view
//        loginStackView.addArrangedSubview(loginMessageLabel)
//        loginStackView.addArrangedSubview(loginSignupButton)
//
//        // Add searchBar to searchContainer
//        searchContainer.addSubview(searchBar)
//
//        // Setup constraints
//        setupConstraints()
//    }
//
//    private func setupConstraints() {
//        NSLayoutConstraint.activate([
//            // ScrollView constraints
//            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
//            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//
//            // ContentView constraints
//            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
//            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
//            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
//            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
//            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
//
//            // SearchContainer constraints
//            searchContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
//            searchContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
//            searchContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
//            searchContainer.heightAnchor.constraint(equalToConstant: 50),
//
//            // SearchBar constraints
//            searchBar.leadingAnchor.constraint(equalTo: searchContainer.leadingAnchor, constant: 8),
//            searchBar.centerYAnchor.constraint(equalTo: searchContainer.centerYAnchor),
//            searchBar.trailingAnchor.constraint(equalTo: searchContainer.trailingAnchor, constant: -8),
//
//            // TitleLabel constraints
//            titleLabel.topAnchor.constraint(equalTo: searchContainer.bottomAnchor, constant: 30),
//            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
//
//            // CurrentlyRentedLabel constraints
//            currentlyRentedLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
//            currentlyRentedLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
//
//            // SeeMoreButton constraints
//            seeMoreButton.centerYAnchor.constraint(equalTo: currentlyRentedLabel.centerYAnchor),
//            seeMoreButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
//
//            // CurrentlyRentedCollectionView constraints
//            currentlyRentedCollectionView.topAnchor.constraint(equalTo: currentlyRentedLabel.bottomAnchor, constant: 20),
//            currentlyRentedCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
//            currentlyRentedCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
//            currentlyRentedCollectionView.heightAnchor.constraint(equalToConstant: 200),
//
//            // RentersLabel constraints
//            rentersLabel.topAnchor.constraint(equalTo: currentlyRentedCollectionView.bottomAnchor, constant: 30),
//            rentersLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
//
//            // RentersCollectionView constraints
//            rentersCollectionView.topAnchor.constraint(equalTo: rentersLabel.bottomAnchor, constant: 20),
//            rentersCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
//            rentersCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
//            rentersCollectionView.heightAnchor.constraint(equalToConstant: 140),
//            rentersCollectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
//
//            // LoginStackView constraints
//            loginStackView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
//            loginStackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
//            loginStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
//            loginStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
//
//            // NoBooksMessageLabel constraints
//            noBooksMessageLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
//            noBooksMessageLabel.topAnchor.constraint(equalTo: currentlyRentedLabel.bottomAnchor, constant: 20),
//            noBooksMessageLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
//            noBooksMessageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
//        ])
//
//        // Add target for seeMoreButton
//        seeMoreButton.addTarget(self, action: #selector(seeMoreButtonTapped), for: .touchUpInside)
//    }
//
//    private func setupCollectionViews() {
//        // Set delegates and data sources
//        currentlyRentedCollectionView.delegate = self
//        currentlyRentedCollectionView.dataSource = self
//        rentersCollectionView.delegate = self
//        rentersCollectionView.dataSource = self
//
//        // Register cells
//        currentlyRentedCollectionView.register(BooksCell.self, forCellWithReuseIdentifier: "BooksCell")
//        rentersCollectionView.register(RenterCell.self, forCellWithReuseIdentifier: "RenterCell")
//    }
//
//    // MARK: - Login State Handling
//    private func checkUserLoginStatus() {
//        if Auth.auth().currentUser != nil {
//            // User is logged in
//            loginStackView.isHidden = true
//            currentlyRentedLabel.isHidden = false
//            seeMoreButton.isHidden = false
//            currentlyRentedCollectionView.isHidden = false
//            fetchCurrentlyRentedBooks()
//        } else {
//            // User is not logged in
//            loginStackView.isHidden = false
//            currentlyRentedLabel.isHidden = true
//            seeMoreButton.isHidden = true
//            currentlyRentedCollectionView.isHidden = true
//            noBooksMessageLabel.isHidden = true
//        }
//    }
//
//    private func fetchCurrentlyRentedBooks() {
//        guard let userID = Auth.auth().currentUser?.uid else {
//            print("Error: No authenticated user found.")
//            return
//        }
//
//        Eclipse.fetchCurrentlyRentedBooks(for: userID) { [weak self] result in
//            switch result {
//            case .success(let rentedBooks):
//                self?.currentlyRentedBooks = rentedBooks
//                DispatchQueue.main.async {
//                    self?.currentlyRentedCollectionView.reloadData()
//                    self?.noBooksMessageLabel.isHidden = !rentedBooks.isEmpty
//                    self?.currentlyRentedCollectionView.isHidden = rentedBooks.isEmpty
//                }
//            case .failure(let error):
//                print("Error fetching rented books: \(error.localizedDescription)")
//            }
//        }
//    }
//
//    @objc private func loginSignupButtonTapped() {
//        let loginVC = LoginViewController()
//        navigationController?.pushViewController(loginVC, animated: true)
//    }
//
//    @objc private func seeMoreButtonTapped() {
//        let bookManagementVC = BorrowedBooksViewController()
//        navigationController?.pushViewController(bookManagementVC, animated: true)
//    }
//}
//
//// MARK: - UICollectionView Extensions
//extension RentHomeViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
//    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        switch collectionView {
//        case currentlyRentedCollectionView:
//            return currentlyRentedBooks.count
//        case rentersCollectionView:
//            return renters.count
//        default:
//            return 0
//        }
//    }
//
//    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        switch collectionView {
//        case currentlyRentedCollectionView:
//            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BooksCell", for: indexPath) as! BooksCell
//            let book = currentlyRentedBooks[indexPath.item]
//            cell.configure(with: book)
//            return cell
//        case rentersCollectionView:
//            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RenterCell", for: indexPath) as! RenterCell
//            let renter = renters[indexPath.item]
//            cell.configure(name: renter.name, image: UIImage(named: "profile")!)
//            return cell
//        default:
//            return UICollectionViewCell()
//        }
//    }
//
//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        switch collectionView {
//        case currentlyRentedCollectionView:
//            let book = currentlyRentedBooks[indexPath.item]
//            print("Currently Rented Book Selected: \(book.title)")
//        case rentersCollectionView:
//            let renter = renters[indexPath.item]
//            print("Renter Selected: \(renter.id), Rating: \(String(describing: renter.rating))")
//            let profileVC = RentersProfileViewController(renterID: renter.id, renterRating: renter.rating!)
//            navigationController?.pushViewController(profileVC, animated: true)
//        default:
//            break
//        }
//    }
//
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//        switch collectionView {
//        case currentlyRentedCollectionView:
//            return CGSize(width: 140, height: 200)
//        case rentersCollectionView:
//            return CGSize(width: 100, height: 140)
//        default:
//            return CGSize.zero
//        }
//    }
//}
