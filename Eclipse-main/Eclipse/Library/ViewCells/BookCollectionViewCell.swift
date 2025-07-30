import UIKit

class BookCollectionViewCell: UICollectionViewCell {
    
    private let coverImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 10
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 1.0
        imageView.layer.borderColor = UIColor.lightGray.cgColor
        imageView.backgroundColor = .systemGray6
        return imageView
    }()
    
    private var imageLoadTask: URLSessionDataTask?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupStyling()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        contentView.addSubview(coverImageView)
        
        NSLayoutConstraint.activate([
            coverImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            coverImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            coverImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            coverImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    private func setupStyling() {
        backgroundColor = .clear
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.2
        layer.shadowOffset = CGSize(width: 2, height: 2)
        layer.shadowRadius = 4
        layer.masksToBounds = false
        layer.cornerRadius = 10
        contentView.layer.cornerRadius = 10
        contentView.layer.masksToBounds = true
    }
    
    func configure(with book: BookF) {
        imageLoadTask?.cancel()
        imageLoadTask = nil
        coverImageView.image = nil
        
        if let imageUrlString = book.imageLinks?.thumbnail?.replacingOccurrences(of: "http://", with: "https://"),
           let imageUrl = URL(string: imageUrlString) {
            loadImage(from: imageUrl.absoluteString)
        }
    }
    
    private func loadImage(from urlString: String) {
        guard let url = URL(string: urlString) else { return }

        imageLoadTask = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                print("Image load error: \(error.localizedDescription)")
                return
            }
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Invalid HTTP response")
                return
            }

            guard let data = data, let image = UIImage(data: data) else {
                print("Failed to create image from data")
                return
            }

            DispatchQueue.main.async {
                UIView.transition(with: self.coverImageView,
                                  duration: 0.3,
                                  options: .transitionCrossDissolve,
                                  animations: {
                    self.coverImageView.image = image
                })
            }
        }

        imageLoadTask?.resume()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageLoadTask?.cancel()
        imageLoadTask = nil
        coverImageView.image = nil
    }
}
