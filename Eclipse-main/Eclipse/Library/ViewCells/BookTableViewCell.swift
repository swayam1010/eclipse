//
//  BookTableViewCell.swift
//  Eclipse
//
//  Created by user@87 on 07/03/25.
//

import Foundation
import UIKit

class BookTableViewCell: UITableViewCell {
    
    private let bookImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let authorLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = .gray
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "ellipsis.circle"), for: .normal)
        button.tintColor = .gray
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    var actionButtonHandler: (() -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(bookImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(authorLabel)
        contentView.addSubview(actionButton)

        NSLayoutConstraint.activate([
            bookImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            bookImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            bookImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            bookImageView.widthAnchor.constraint(equalToConstant: 50),
            bookImageView.heightAnchor.constraint(equalToConstant: 70),
            
            titleLabel.leadingAnchor.constraint(equalTo: bookImageView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: actionButton.leadingAnchor, constant: -10),
            titleLabel.topAnchor.constraint(equalTo: bookImageView.topAnchor),
            
            authorLabel.leadingAnchor.constraint(equalTo: bookImageView.trailingAnchor, constant: 12),
            authorLabel.trailingAnchor.constraint(equalTo: actionButton.leadingAnchor, constant: -10),
            authorLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            
            actionButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            actionButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            actionButton.widthAnchor.constraint(equalToConstant: 30),
            actionButton.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        actionButton.addTarget(self, action: #selector(didTapActionButton), for: .touchUpInside)
    }
    
    @objc private func didTapActionButton() {
        actionButtonHandler?()
    }
    
    func configure(with book: BookF) {
        titleLabel.text = book.title
        authorLabel.text = book.authors?.joined(separator: ", ") ?? "Unknown Author"
        
        if let imageUrl = book.imageLinks?.thumbnail {
            bookImageView.sd_setImage(with: URL(string: imageUrl), placeholderImage: UIImage(systemName: "book.fill"))
        } else {
            bookImageView.image = UIImage(systemName: "book.fill")
        }
    }
}
