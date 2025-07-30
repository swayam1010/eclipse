import UIKit
import FirebaseFirestore
import FirebaseAuth

struct StatusList {
    var category: String
    var bookIDs: [String]
    
    static func from(document: DocumentSnapshot, category: String) -> StatusList? {
        guard let data = document.data(), let bookIDs = data["bookIDs"] as? [String] else { return nil }
        return StatusList(category: category, bookIDs: bookIDs)
    }
}

class ReadingListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private let tableView = UITableView()
    
    var statusLists: [StatusList] = []
    private var customLists: [List] = []
    private var bookImageCache: [String: UIImage] = [:] // Caching book images
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCreateCollectionButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchData()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Reading Lists"
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(ReadingListTableViewCell.self, forCellReuseIdentifier: "ReadingListCell")
        
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func fetchData() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        let dispatchGroup = DispatchGroup()
        
        // Fetch status lists
        dispatchGroup.enter()
        fetchStatusLists(userID: userID) { [weak self] result in
            defer { dispatchGroup.leave() }
            switch result {
            case .success(let lists):
                self?.statusLists = lists.map { StatusList(category: $0.title, bookIDs: $0.bookIDs) }
            case .failure(let error):
                print("Error fetching status lists: \(error.localizedDescription)")
            }
        }
        
        // Fetch custom lists
        dispatchGroup.enter()
        fetchCustomLists(userID: userID) { [weak self] result in
            defer { dispatchGroup.leave() }
            switch result {
            case .success(let lists):
                self?.customLists = lists
            case .failure(let error):
                print("Error fetching custom lists: \(error.localizedDescription)")
            }
        }
        
        dispatchGroup.notify(queue: .main) { [weak self] in
            self?.tableView.reloadData()
        }
    }
    
    private func setupCreateCollectionButton() {
        let createButton = UIBarButtonItem(title: "Create Collection", style: .plain, target: self, action: #selector(createNewCollectionTapped))
        navigationItem.rightBarButtonItem = createButton
    }
    
    @objc private func createNewCollectionTapped() {
        let createVC = CreateCollectionViewController()
        let navController = UINavigationController(rootViewController: createVC)
        navController.modalPresentationStyle = .formSheet
        present(navController, animated: true)
    }
    
    // MARK: - TableView DataSource and Delegate
    
    func numberOfSections(in tableView: UITableView) -> Int { return 2 }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? statusLists.count : customLists.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "Status Lists" : "Collections"
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ReadingListCell", for: indexPath) as? ReadingListTableViewCell else {
            return UITableViewCell()
        }
        
        if indexPath.section == 0 {
            configure(cell, with: statusLists[indexPath.row])
        } else {
            configure(cell, with: customLists[indexPath.row])
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 0 {
            let statusList = statusLists[indexPath.row]
            let vc = StatusListViewController()
            vc.setStatusList(statusList)  // Use the setter method
            navigationController?.pushViewController(vc, animated: true)
        } else {
            let selectedList = customLists[indexPath.row]
            let vc = CustomListViewController()
            vc.customList = selectedList
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    // MARK: - Swipe to Delete Custom Lists
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 1 // Only allow editing for custom lists
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let list = customLists[indexPath.row]
            deleteCustomList(list)
        }
    }
    
    private func deleteCustomList(_ list: List) {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        let listRef = db.collection("users").document(userID).collection("customLists").document(list.id)
        
        listRef.delete { [weak self] error in
            if let error = error {
                print("Error deleting list: \(error.localizedDescription)")
            } else {
                print("List deleted successfully.")
                self?.customLists.removeAll { $0.id == list.id }
                self?.tableView.reloadData()
            }
        }
    }
    
    // MARK: - Configure Cells
    
    private func configure(_ cell: ReadingListTableViewCell, with list: StatusList) {
        cell.titleLabel.text = list.category
        cell.subtitleLabel.text = "\(list.bookIDs.count) books"
        loadBookImages(for: cell, with: list.bookIDs)
    }
    
    private func configure(_ cell: ReadingListTableViewCell, with list: List) {
        cell.titleLabel.text = list.title
        cell.subtitleLabel.text = "\(list.bookIDs.count) books"
        cell.privacyIndicator.image = list.isPrivate ? UIImage(systemName: "lock.fill") : UIImage(systemName: "network")
        loadBookImages(for: cell, with: list.bookIDs)
    }
    
    private func loadBookImages(for cell: ReadingListTableViewCell, with bookIDs: [String]) {
        // Fetch the first 3 books
        fetchBooksByIDs(bookIDs: Array(bookIDs.prefix(3))) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let books):
                    let images = books.compactMap { self?.bookImageCache[$0.id] }
                    cell.configure(with: images)
                case .failure:
                    cell.configure(with: []) // Show no images if fetching fails
                }
            }
        }
    }
}
