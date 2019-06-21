//
//  ALKEmailCell.swift
//  ApplozicSwift
//
//  Created by Shivam Pokhriyal on 13/03/19.
//

import UIKit

class ALKEmailView: UIView {

    struct Height {
        static let emailView: CGFloat = 20
    }

    fileprivate var emailImage: UIImageView = {
        let sv = UIImageView()
        sv.image = UIImage(named: "alk_replied_icon",
                           in: Bundle.applozic,
                           compatibleWith: nil)
        sv.isUserInteractionEnabled = false
        sv.contentMode = .center
        return sv
    }()

    private var emailLabel: UILabel = {
        let label = UILabel()
        label.text = "via email"
        label.numberOfLines = 1
        label.font = UIFont(name: "Helvetica", size: 12)
        label.isOpaque = true
        return label
    }()

    private var emailTopView = UIView(frame: .zero)

    fileprivate var htmlLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
//        label.font = UIFont(name: "Helvetica", size: 12)
        label.isOpaque = true
        return label
    }()

    fileprivate lazy var emailViewHeight = emailTopView.heightAnchor.constraint(equalToConstant: 0)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(text: String, type: ALKMessageType) {
        switch type {
        case .html:
            hideEmailView(true)
        case .email:
            hideEmailView(false)
        default:
            print("😱😱😱Shouldn't come here.😱😱😱")
            return
        }
        DispatchQueue.global().async {
            let attributedText = ALKEmailView.attributedStringFrom(text)
            DispatchQueue.main.async {
                self.htmlLabel.attributedText = attributedText
            }
        }
    }

    class func height(text: String, maxWidth: CGFloat, type: ALKMessageType) -> CGFloat {
        let extraHeight: CGFloat = (type == .html) ? 0 : Height.emailView
        guard let attributedText = ALKEmailView.attributedStringFrom(text) else {
            return extraHeight
        }
        return attributedText.heightWithConstrainedWidth(maxWidth) + extraHeight
    }

    // MARK: - Private helper methods

    private class func attributedStringFrom(_ text: String) -> NSAttributedString? {

        guard let htmlText = text.data(using: .utf8, allowLossyConversion: false) else {
            print("🤯🤯🤯Could not create UTF8 formatted data from \(text)")
            return nil
        }
        do {
            return try NSAttributedString(
                data: htmlText,
                options: [
                    .documentType: NSAttributedString.DocumentType.html,
                    .characterEncoding: String.Encoding.utf8.rawValue],
                documentAttributes: nil)
        } catch {
            print("Error \(error) while creating attributed string")
            return nil
        }
    }

    private func setupConstraints() {
        self.backgroundColor = .white
        self.addViewsForAutolayout(views: [emailImage, emailLabel, emailTopView, htmlLabel])

        NSLayoutConstraint.activate ([
            emailTopView.topAnchor.constraint(equalTo: self.topAnchor),
            emailTopView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            emailTopView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            emailViewHeight,

            emailImage.topAnchor.constraint(equalTo: emailTopView.topAnchor),
            emailImage.leadingAnchor.constraint(equalTo: emailTopView.leadingAnchor),
            emailImage.heightAnchor.constraint(equalToConstant: Height.emailView),
            emailImage.widthAnchor.constraint(equalToConstant: Height.emailView),

            emailLabel.topAnchor.constraint(equalTo: emailTopView.topAnchor),
            emailLabel.trailingAnchor.constraint(equalTo: emailTopView.trailingAnchor),
            emailLabel.leadingAnchor.constraint(equalTo: emailImage.trailingAnchor),
            emailLabel.heightAnchor.constraint(equalToConstant: Height.emailView),

            htmlLabel.topAnchor.constraint(equalTo: emailTopView.bottomAnchor),
            htmlLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            htmlLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            htmlLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor)
            ])
    }

    private func hideEmailView(_ hide: Bool) {
        emailImage.isHidden = hide
        emailLabel.isHidden = hide
        emailViewHeight.constant = hide ? 0 : Height.emailView
    }

}
