import UIKit
import FirebaseAuth

class LibraryViewController: UIViewController {

    // MARK: - Properties
    private let segmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["All Books", "Reading List"])
        control.selectedSegmentIndex = 0
        control.addTarget(self, action: #selector(segmentDidChange(_:)), for: .valueChanged)
        return control
    }()

    private lazy var allBooksVC = AllBooksViewController()
    private lazy var readingListVC = ReadingListViewController()
    private var currentVC: UIViewController?

    // UI Components for Not Logged In State
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.text = "Welcome to the Library! Please log in or sign up to explore books and manage your reading list."
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()

    private let loginSignupButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Login / Signup", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(hex: "#005c78")
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(loginSignupButtonTapped), for: .touchUpInside)
        button.isHidden = true
        return button
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Library"
        view.backgroundColor = .systemBackground
        setupLayout()
        checkUserLoginStatus()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        checkUserLoginStatus()
    }

    // MARK: - UI Setup
    private func setupLayout() {
        // Add segmented control
        view.addSubview(segmentedControl)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            segmentedControl.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])

        // Add message label
        view.addSubview(messageLabel)
        messageLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            messageLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            messageLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            messageLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            messageLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)
        ])

        // Add login/signup button
        view.addSubview(loginSignupButton)
        loginSignupButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            loginSignupButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 20),
            loginSignupButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loginSignupButton.widthAnchor.constraint(equalToConstant: 200),
            loginSignupButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    // MARK: - Login State Handling
    private func checkUserLoginStatus() {
        if Auth.auth().currentUser != nil {
            // User is logged in
            segmentedControl.isHidden = false
            messageLabel.isHidden = true
            loginSignupButton.isHidden = true

            // Show the appropriate view controller based on the selected segment
            let selectedVC = segmentedControl.selectedSegmentIndex == 0 ? allBooksVC : readingListVC
            showViewController(selectedVC)
        } else {
            // User is not logged in
            segmentedControl.isHidden = true
            messageLabel.isHidden = false
            loginSignupButton.isHidden = false

            // Remove any currently displayed view controller
            if let currentVC = currentVC {
                currentVC.willMove(toParent: nil)
                currentVC.view.removeFromSuperview()
                currentVC.removeFromParent()
                self.currentVC = nil
            }
        }
    }

    // MARK: - Actions
    @objc private func segmentDidChange(_ sender: UISegmentedControl) {
        let newVC = sender.selectedSegmentIndex == 0 ? allBooksVC : readingListVC
        showViewController(newVC)
    }

    @objc private func loginSignupButtonTapped() {
        let loginVC = LoginViewController()
        navigationController?.pushViewController(loginVC, animated: true)
    }

    // MARK: - View Controller Management
    private func showViewController(_ newVC: UIViewController) {
        if let currentVC = currentVC {
            currentVC.willMove(toParent: nil)
            currentVC.view.removeFromSuperview()
            currentVC.removeFromParent()
        }

        addChild(newVC)
        newVC.view.frame = view.bounds
        newVC.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(newVC.view)
        view.sendSubviewToBack(newVC.view)

        NSLayoutConstraint.activate([
            newVC.view.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 16),
            newVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            newVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            newVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        newVC.didMove(toParent: self)
        currentVC = newVC
    }
}
