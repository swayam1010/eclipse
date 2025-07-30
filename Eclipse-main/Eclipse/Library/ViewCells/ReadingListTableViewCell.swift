import UIKit

class ReadingListTableViewCell: UITableViewCell {
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18)
        label.textColor = .gray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let privacyIndicator: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .gray
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    let bookImagesStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 4
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // Add subviews
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(privacyIndicator)
        contentView.addSubview(bookImagesStackView)
        
        // Set constraints
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            subtitleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            
            privacyIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            privacyIndicator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            privacyIndicator.widthAnchor.constraint(equalToConstant: 20),
            privacyIndicator.heightAnchor.constraint(equalToConstant: 20),
            
            bookImagesStackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            bookImagesStackView.trailingAnchor.constraint(equalTo: privacyIndicator.leadingAnchor, constant: -16),
            bookImagesStackView.widthAnchor.constraint(equalToConstant: 80),
            bookImagesStackView.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    func configure(with bookImages: [UIImage?]) {
        // Clear existing images
        bookImagesStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Add new images
        for image in bookImages {
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFill
            imageView.layer.cornerRadius = 4
            imageView.clipsToBounds = true
            bookImagesStackView.addArrangedSubview(imageView)
        }
    }
}
