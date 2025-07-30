import UIKit

class CreateCollectionViewController: UIViewController {
    
    // UI Elements
    var imageView: UIImageView!
    var descriptionTextField: UITextField!
    var nameTextField: UITextField!
    var privateSwitch: UISwitch!
    var privacyInfo: UILabel!
    var saveButton: UIBarButtonItem!
    var cancelButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up the view controller's UI components programmatically
        setupUI()
        
        // Set the navigation bar to be visible
        navigationController?.setNavigationBarHidden(false, animated: false)
        
        // Add gesture recognizer to dismiss keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
        
        // Configure privacy info label
        configurePrivacyInfoLabel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    private func setupUI() {
        // Initialize UI components
        imageView = UIImageView(image: UIImage(named: "create_list"))
        descriptionTextField = UITextField()
        nameTextField = UITextField()
        privateSwitch = UISwitch()
        privacyInfo = UILabel()
        saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveButtonTapped))
        cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonTapped))
        
        // Set properties for UI components
        descriptionTextField.placeholder = "Description"
        nameTextField.placeholder = "Collection Name"
        
        // Set up layout (you can use Auto Layout or manual frame-based positioning)
        setupLayout()
        
        // Set the navigation bar items
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = saveButton
    }
    
    private func setupLayout() {
        // Add views to the main view
        view.addSubview(imageView)
        view.addSubview(descriptionTextField)
        view.addSubview(nameTextField)
        view.addSubview(privateSwitch)
        view.addSubview(privacyInfo)
        
        // Set up Auto Layout constraints (using NSLayoutConstraint or NSLayoutAnchor)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        descriptionTextField.translatesAutoresizingMaskIntoConstraints = false
        nameTextField.translatesAutoresizingMaskIntoConstraints = false
        privateSwitch.translatesAutoresizingMaskIntoConstraints = false
        privacyInfo.translatesAutoresizingMaskIntoConstraints = false
        
        // Example constraints
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            descriptionTextField.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),
            descriptionTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            descriptionTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            nameTextField.topAnchor.constraint(equalTo: descriptionTextField.bottomAnchor, constant: 20),
            nameTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            nameTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            privateSwitch.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 20),
            privateSwitch.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            privacyInfo.topAnchor.constraint(equalTo: privateSwitch.bottomAnchor, constant: 10),
            privacyInfo.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            privacyInfo.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    private func configurePrivacyInfoLabel() {
        privacyInfo.numberOfLines = 0
        privacyInfo.lineBreakMode = .byWordWrapping
        privacyInfo.text = "Other users will not be able to see your lists."
    }
    
    @objc func saveButtonTapped() {
        guard let name = nameTextField.text, !name.isEmpty else {
            showAlert(title: "Error", message: "Collection name cannot be empty.")
            return
        }
        
        let description = descriptionTextField.text ?? ""
        let isPrivate = privateSwitch.isOn
        print("Name: \(name), Description: \(description), Private: \(isPrivate)")
        dismiss(animated: true, completion: nil)
    }

    @objc func cancelButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}



