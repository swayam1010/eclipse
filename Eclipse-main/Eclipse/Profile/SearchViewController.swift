import UIKit

class SearchViewController: UIViewController {
    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search Books"
        searchBar.searchBarStyle = .minimal
        return searchBar
    }()
    
    private let resultsTableView: UITableView = {
        let tableView = UITableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SearchCell")
        return tableView
    }()
    
    private var searchResults: [BookF] = []
    private var timer: Timer?
    private let maxSearchResults = 10
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Search Books"
        navigationController?.navigationBar.prefersLargeTitles = true
        setupUI()
        setupDelegates()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        view.addSubview(searchBar)
        view.addSubview(resultsTableView)
        
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        resultsTableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            resultsTableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 10),
            resultsTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            resultsTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            resultsTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupDelegates() {
        searchBar.delegate = self
        resultsTableView.delegate = self
        resultsTableView.dataSource = self
    }
    
    private func fetchBooks(query: String) {
        let urlString = "https://www.googleapis.com/books/v1/volumes?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] (data, _, error) in
            guard let self = self, let data = data, error == nil else { return }
            
            do {
                let response = try JSONDecoder().decode(BookResponse.self, from: data)
                let books = response.items?.prefix(self.maxSearchResults).compactMap { BookAdapter.adapt($0) } ?? []
                DispatchQueue.main.async {
                    self.searchResults = books
                    self.resultsTableView.reloadData()
                }
            } catch {}
        }.resume()
    }
}

extension SearchViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        timer?.invalidate()
        guard !searchText.isEmpty else {
            searchResults.removeAll()
            resultsTableView.reloadData()
            return
        }
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            self?.fetchBooks(query: searchText)
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchResults.removeAll()
        resultsTableView.reloadData()
        searchBar.resignFirstResponder()
    }
}

extension SearchViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchCell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        let book = searchResults[indexPath.row]
        content.text = book.title
        content.secondaryText = book.authors?.joined(separator: ", ") ?? "Unknown Author"
        
        if let thumbnail = book.imageLinks?.thumbnail,
           let url = URL(string: thumbnail) {
            DispatchQueue.global().async {
                if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                    let resizedImage = UIGraphicsImageRenderer(size: CGSize(width: 40, height: 60)).image { _ in
                        image.draw(in: CGRect(origin: .zero, size: CGSize(width: 40, height: 60)))
                    }
                    DispatchQueue.main.async {
                        content.image = resizedImage
                        cell.contentConfiguration = content
                    }
                }
            }
        }
        
        cell.contentConfiguration = content
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedBook = searchResults[indexPath.row]
        let bookVC = ProfileBookViewController(book: selectedBook)
        navigationController?.pushViewController(bookVC, animated: true)
    }
}
