import UIKit

class CategoryCollectionViewCell: UICollectionViewCell {
    let categoryLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        categoryLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(categoryLabel)

        NSLayoutConstraint.activate([
            categoryLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            categoryLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])

        self.layer.cornerRadius = 10
        self.layer.masksToBounds = false
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = 0.2
        self.layer.shadowOffset = CGSize(width: 2, height: 2)
        self.layer.shadowRadius = 4
    }

    func configure(for category: String, isSelected: Bool) {
        categoryLabel.text = category

        let selectedColor = UIColor(red: 0.0, green: 92/255.0, blue: 120/255.0, alpha: 1.0)
        let unselectedColor = UIColor.white

        if isSelected {
            self.backgroundColor = selectedColor
            categoryLabel.textColor = UIColor.white
        } else {
            self.backgroundColor = unselectedColor
            categoryLabel.textColor = selectedColor
        }
    }
}
