import UIKit
import FirebaseFirestore
import FirebaseAuth

class AddToLibraryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var book: BookF?
    
    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return tableView
    }()
    
    private let addListButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Add New Custom List", for: .normal)
        button.addTarget(self, action: #selector(addCustomListTapped), for: .touchUpInside)
        return button
    }()
    
    var statusLists: [Status] = [.wantToRead, .currentlyReading, .finished, .didNotFinish]
    var customLists: [String: List] = [:]
    
    var selectedStatus: Status?
    var selectedCustomLists: Set<String> = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        fetchCustomLists()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        view.addSubview(tableView)
        view.addSubview(addListButton)
        
        tableView.dataSource = self
        tableView.delegate = self
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: addListButton.topAnchor, constant: -10),
            
            addListButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            addListButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            addListButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupNavigationBar() {
        navigationItem.title = "Add to Library"
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelButtonTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(saveButtonTapped))
    }
    
    private func fetchCustomLists() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(userID).collection("customLists").getDocuments { [weak self] (snapshot, error) in
            if let error = error { return }
            
            if let snapshot = snapshot {
                self?.customLists = [:]
                for document in snapshot.documents {
                    let listName = document.documentID
                    if let list = List.from(document: document) {
                        self?.customLists[listName] = list
                    }
                }
                self?.tableView.reloadData()
            }
        }
    }

    private func createNewCustomList(named listName: String) {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let newList = List(
            id: UUID().uuidString,
            title: listName,
            bookIDs: [],
            isPrivate: false,
            createdAt: Date()
        )
        
        db.collection("users").document(userID).collection("customLists").document(newList.id).setData(newList.toDictionary()) { [weak self] error in
            if let error = error {
                print("Error creating custom list: \(error.localizedDescription)")
                return
            }
            self?.fetchCustomLists()
        }
    }


    
    @objc private func addCustomListTapped() {
        let alertController = UIAlertController(title: "New Custom List", message: "Enter the name of your new list.", preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = "List name"
        }
        
        let createAction = UIAlertAction(title: "Create", style: .default) { [weak self] _ in
            guard let listName = alertController.textFields?.first?.text, !listName.isEmpty else { return }
            self?.createNewCustomList(named: listName)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alertController.addAction(createAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true)
    }
    
    
    @objc private func saveButtonTapped() {
        saveToUserBookmarks()
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func cancelButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    private func saveToUserBookmarks() {
        guard let userID = Auth.auth().currentUser?.uid, let book = book else {
            print("❌ Failed: User ID or book is nil")
            return
        }
        
        let db = Firestore.firestore()
        
        // Save to predefined status list
        if let selectedStatus = selectedStatus {
            let listRef = db.collection("users").document(userID).collection("lists").document(selectedStatus.rawValue)
            
            // Use `setData` with `merge: true` to create or update the document
            listRef.setData([
                "bookIDs": FieldValue.arrayUnion([book.id]), // Add the book ID to the array
                "title": selectedStatus.rawValue, // Ensure the title is set
                "timestamp": FieldValue.serverTimestamp() // Add a timestamp
            ], merge: true) { error in
                if let error = error {
                    print("❌ Failed to save to status list \(selectedStatus.rawValue): \(error.localizedDescription)")
                } else {
                    print("✅ Successfully saved to status list: \(selectedStatus.rawValue)")
                }
            }
        }
        
        // Save to selected custom lists
        for customListName in selectedCustomLists {
            let customListRef = db.collection("users").document(userID).collection("customLists").document(customListName)
            
            // Use `setData` with `merge: true` to create or update the document
            customListRef.setData([
                "bookIDs": FieldValue.arrayUnion([book.id]), // Add the book ID to the array
                "timestamp": FieldValue.serverTimestamp() // Add a timestamp
            ], merge: true) { error in
                if let error = error {
                    print("❌ Failed to save to custom list \(customListName): \(error.localizedDescription)")
                } else {
                    print("✅ Successfully saved to custom list: \(customListName)")
                }
            }
        }
    }


    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? statusLists.count : customLists.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "Status Lists" : "Collections"
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            selectedStatus = statusLists[indexPath.row]
        } else {
            let customListID = Array(customLists.keys)[indexPath.row] // Get document ID
            if selectedCustomLists.contains(customListID) {
                selectedCustomLists.remove(customListID)
            } else {
                selectedCustomLists.insert(customListID)
            }
        }
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        if indexPath.section == 0 {
            let status = statusLists[indexPath.row]
            cell.textLabel?.text = status.rawValue
            cell.accessoryType = selectedStatus == status ? .checkmark : .none
        } else {
            let customListKeys = Array(customLists.keys)
            let customListID = customListKeys[indexPath.row] // Get document ID
            if let customList = customLists[customListID] {
                let customListName = customList.title
                cell.textLabel?.text = customListName
                cell.accessoryType = selectedCustomLists.contains(customListID) ? .checkmark : .none // Use document ID
            }
        }
        
        return cell
    }
}



