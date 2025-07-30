import UIKit
import FirebaseFirestore

class HomeViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    var selectedCategoryIndex: Int = 0
    var recommendedLists: [RecommendedList] = []
    var booksByList: [String: [BookF]] = [:]

    let categories = ["Fiction", "Historical", "Mystery", "Thriller", "Romance"]
    
    private let swipeToFindView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 10
        view.clipsToBounds = true
        let gradientLayer = RadialGradientLayer(center: CGPoint(x: UIScreen.main.bounds.width / 2, y: 60),
                                                radius: UIScreen.main.bounds.width / 2,
                                                colors: [UIColor(hex: "#005C78", alpha: 0.6).cgColor, UIColor(hex: "#1C5983", alpha: 0.94).cgColor])
        gradientLayer.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width - 20, height: 220)
        gradientLayer.cornerRadius = 10
        view.layer.insertSublayer(gradientLayer, at: 0)

        return view
    }()


    private let swipeLabel: UILabel = {
        let label = UILabel()
        label.text = "Swipe to Find Books"
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let swipeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Start Swiping", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.backgroundColor = .white
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(openSwipeView), for: .touchUpInside)
        return button
    }()

    let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.isPagingEnabled = true
        cv.showsHorizontalScrollIndicator = false
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.register(CategoryCollectionViewCell.self, forCellWithReuseIdentifier: "categoryCell")
        return cv
    }()

    let recommendedListCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.register(RecommendedListCollectionViewCell.self, forCellWithReuseIdentifier: "recommendedListCell")
        return cv
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Home"
        navigationItem.largeTitleDisplayMode = .always
        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = .white
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadRecommendedLists()
    }

    private func setupUI() {
        view.addSubview(collectionView)
        view.addSubview(recommendedListCollectionView)
        view.addSubview(swipeToFindView)

        collectionView.dataSource = self
        collectionView.delegate = self

        recommendedListCollectionView.dataSource = self
        recommendedListCollectionView.delegate = self

        swipeToFindView.addSubview(swipeLabel)
        swipeToFindView.addSubview(swipeButton)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            collectionView.heightAnchor.constraint(equalToConstant: 50),

            swipeToFindView.topAnchor.constraint(equalTo: collectionView.bottomAnchor, constant: 10),
            swipeToFindView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            swipeToFindView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            swipeToFindView.heightAnchor.constraint(equalToConstant: 220),

            swipeLabel.topAnchor.constraint(equalTo: swipeToFindView.topAnchor, constant: 20),
            swipeLabel.leadingAnchor.constraint(equalTo: swipeToFindView.leadingAnchor, constant: 10),
            swipeLabel.trailingAnchor.constraint(equalTo: swipeToFindView.trailingAnchor, constant: -10),

            swipeButton.topAnchor.constraint(equalTo: swipeLabel.bottomAnchor, constant: 15),
            swipeButton.centerXAnchor.constraint(equalTo: swipeToFindView.centerXAnchor),
            swipeButton.widthAnchor.constraint(equalToConstant: 160),
            swipeButton.heightAnchor.constraint(equalToConstant: 40),

            recommendedListCollectionView.topAnchor.constraint(equalTo: swipeToFindView.bottomAnchor, constant: 10),
            recommendedListCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            recommendedListCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            recommendedListCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func loadRecommendedLists() {
        fetchRecommendedLists { [weak self] fetchedLists, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Error fetching recommended lists: \(error.localizedDescription)")
                return
            }
            
            self.recommendedLists = fetchedLists
            self.fetchBooksForLists()
        }
    }

    private func fetchBooksForLists() {
        let dispatchGroup = DispatchGroup()
        var fetchedBooksByList: [String: [BookF]] = [:]

        for list in recommendedLists {
            dispatchGroup.enter()
            
            fetchBooksByIDs(bookIDs: list.books) { result in
                defer { dispatchGroup.leave() }

                switch result {
                case .success(let books):
                    DispatchQueue.main.async {
                        fetchedBooksByList[list.title] = books
                    }
                case .failure(let error):
                    print("❌ Failed to fetch books for list \(list.title): \(error.localizedDescription)")
                }
            }
        }

        dispatchGroup.notify(queue: .main) {
            self.booksByList = fetchedBooksByList
            self.recommendedListCollectionView.reloadData()
        }
    }
    
    @objc private func openSwipeView() {
        let swipeVC = SwipeViewController()
        navigationController?.pushViewController(swipeVC, animated: true)
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collectionView == self.collectionView ? categories.count : recommendedLists.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == self.collectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "categoryCell", for: indexPath) as! CategoryCollectionViewCell
            cell.configure(for: categories[indexPath.item], isSelected: indexPath.item == selectedCategoryIndex)
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "recommendedListCell", for: indexPath) as! RecommendedListCollectionViewCell
            let recommendedList = recommendedLists[indexPath.item]
            let books = booksByList[recommendedList.title] ?? []
            cell.configure(with: recommendedList, books: books)
            return cell
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView == self.collectionView ? CGSize(width: 100, height: 40) : CGSize(width: collectionView.frame.width, height: 300)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            if collectionView == self.collectionView {
                selectedCategoryIndex = indexPath.item
                collectionView.reloadData()
                let selectedCategory = categories[indexPath.item]
                let bookListVC = BookListViewController()
                bookListVC.selectedGenre = selectedCategory
                bookListVC.title = selectedCategory
                navigationController?.pushViewController(bookListVC, animated: true)
            }
        }
}
