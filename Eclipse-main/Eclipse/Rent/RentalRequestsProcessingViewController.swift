//
//  RentalRequestsProcessingViewController.swift
//  Eclipse
//
//  Created by user@87 on 20/02/25.
//

//import UIKit
//
//class RentalRequestsAcceptViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
//    
//    private let tableView = UITableView()
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        view.backgroundColor = .white
//        setupNavigationBar()
//
//        tableView.dataSource = self
//        tableView.delegate = self
//        tableView.register(RequestTableViewCell.self, forCellReuseIdentifier: "RequestTableViewCell")
//        tableView.translatesAutoresizingMaskIntoConstraints = false
//        tableView.rowHeight = 120
//        view.addSubview(tableView)
//
//        NSLayoutConstraint.activate([
//            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
//            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
//        ])
//    }
//    
//    private func setupNavigationBar() {
//        let titleLabel = UILabel()
//        titleLabel.text = "Rent Requests"
//        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
//        titleLabel.textAlignment = .center
//        
//        navigationItem.titleView = titleLabel
//        navigationItem.leftItemsSupplementBackButton = true
//        navigationItem.largeTitleDisplayMode = .never
//    }
//
//    
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return requests.count
//    }
//    
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        guard let cell = tableView.dequeueReusableCell(withIdentifier: "RequestTableViewCell", for: indexPath) as? RequestTableViewCell else {
//            return UITableViewCell()
//        }
//        let request = requests[indexPath.row]
//        cell.configure(with: request, status: request.status)
//        cell.profileButton.addTarget(self, action: #selector(profileButtonTapped), for: .touchUpInside)
//        return cell
//    }
//        
//    @objc private func profileButtonTapped() {
//
//
//        let backButton = UIBarButtonItem()
//        backButton.image = UIImage(systemName: "chevron.left")
//        backButton.tintColor = UIColor.black
//
//    }
//}
