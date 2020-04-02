import Foundation
import Kingfisher

class ALKFriendLinkPreviewCell: ALKLinkPreviewBaseCell {
    private var avatarImageView: UIImageView = {
        let imv = UIImageView()
        imv.contentMode = .scaleAspectFill
        imv.clipsToBounds = true
        let layer = imv.layer
        layer.cornerRadius = 18.5
        layer.masksToBounds = true
        imv.isUserInteractionEnabled = true
        return imv
    }()

    private var nameLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.isOpaque = true
        return label
    }()

    struct Padding {
        struct NameLabel {
            static let top: CGFloat = 6.0
            static let left: CGFloat = 57.0
            static let right: CGFloat = 57.0
            static let height: CGFloat = 16.0
        }

        struct AvatarImage {
            static let top: CGFloat = 18.0
            static let left: CGFloat = 9.0
            static let width: CGFloat = 37.0
            static let height: CGFloat = 37.0
        }

        struct BubbleView {
            static let left: CGFloat = 5.0
            static let right: CGFloat = 95.0
            static let bottom: CGFloat = 5.0
        }

        struct MessageView {
            static let top: CGFloat = 5
            static let bottom: CGFloat = 10
        }

        struct LinkView {
            static let top: CGFloat = 5
            static let bottom: CGFloat = 5
            static let left: CGFloat = 5
            static let right: CGFloat = 5
        }

        struct TimeLabel {
            static let bottom: CGFloat = 2
            static let left: CGFloat = 10
        }
    }

    static let bubbleViewLeftPadding: CGFloat = {
        /// For edge add extra 5
        guard ALKMessageStyle.receivedBubble.style == .edge else {
            return ALKMessageStyle.receivedBubble.widthPadding
        }
        return ALKMessageStyle.receivedBubble.widthPadding + 5
    }()

    override func setupViews() {
        super.setupViews()

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(avatarTappedAction))
        avatarImageView.addGestureRecognizer(tapGesture)

        contentView.addViewsForAutolayout(views: [avatarImageView, nameLabel])
        contentView.bringSubviewToFront(messageView)

        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(
                equalTo: contentView.topAnchor,
                constant: Padding.NameLabel.top
            ),
            nameLabel.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor,
                constant: Padding.NameLabel.left
            ),
            nameLabel.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor,
                constant: -Padding.NameLabel.right
            ),
            nameLabel.heightAnchor.constraint(equalToConstant: Padding.NameLabel.height),

            avatarImageView.topAnchor.constraint(
                equalTo: contentView.topAnchor,
                constant: Padding.AvatarImage.top
            ),
            avatarImageView.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor,
                constant: Padding.AvatarImage.left
            ),
            avatarImageView.heightAnchor.constraint(equalToConstant: Padding.AvatarImage.height),
            avatarImageView.widthAnchor.constraint(equalToConstant: Padding.AvatarImage.width),

            bubbleView.topAnchor.constraint(equalTo: nameLabel.bottomAnchor),
            bubbleView.bottomAnchor.constraint(
                equalTo: contentView.bottomAnchor,
                constant: -Padding.BubbleView.bottom
            ),
            bubbleView.leadingAnchor.constraint(
                equalTo: avatarImageView.trailingAnchor,
                constant: Padding.BubbleView.left
            ),
            bubbleView.trailingAnchor.constraint(
                lessThanOrEqualTo: contentView.trailingAnchor,
                constant: -Padding.BubbleView.right
            ),
            linkView.topAnchor.constraint(
                equalTo: bubbleView.topAnchor,
                constant: Padding.LinkView.top
            ),
            linkView.leadingAnchor.constraint(
                equalTo: bubbleView.leadingAnchor,
                constant: Padding.LinkView.left
            ),
            linkView.trailingAnchor.constraint(
                equalTo: bubbleView.trailingAnchor,
                constant: -Padding.LinkView.right
            ),
            messageView.topAnchor.constraint(
                equalTo: linkView.bottomAnchor
            ),
            messageView.bottomAnchor.constraint(
                equalTo: bubbleView.bottomAnchor,
                constant: -Padding.MessageView.bottom
            ),
            messageView.trailingAnchor.constraint(
                equalTo: bubbleView.trailingAnchor,
                constant: -ALKMessageStyle.receivedBubble.widthPadding
            ),
            messageView.leadingAnchor.constraint(
                equalTo: bubbleView.leadingAnchor,
                constant: ALKFriendMessageCell.bubbleViewLeftPadding
            ),

            timeLabel.leadingAnchor.constraint(
                equalTo: bubbleView.trailingAnchor,
                constant: Padding.TimeLabel.left
            ),
            timeLabel.bottomAnchor.constraint(
                equalTo: bubbleView.bottomAnchor,
                constant: Padding.TimeLabel.bottom
            ),
        ])
    }

    override func setupStyle() {
        super.setupStyle()

        nameLabel.setStyle(ALKMessageStyle.displayName)
        messageView.setStyle(ALKMessageStyle.receivedMessage)
        bubbleView.setStyle(ALKMessageStyle.receivedBubble, isReceiverSide: true)
    }

    override func update(viewModel: ALKMessageViewModel) {
        super.update(
            viewModel: viewModel,
            messageStyle: ALKMessageStyle.receivedMessage,
            mentionStyle: ALKMessageStyle.receivedMention
        )

        let placeHolder = UIImage(named: "placeholder", in: Bundle.applozic, compatibleWith: nil)
        if let url = viewModel.avatarURL {
            let resource = ImageResource(downloadURL: url, cacheKey: url.absoluteString)
            avatarImageView.kf.setImage(with: resource, placeholder: placeHolder)
        } else {
            avatarImageView.image = placeHolder
        }

        nameLabel.text = viewModel.displayName

        linkView.update(url: url)
    }

    class func rowHeigh(
        viewModel: ALKMessageViewModel,
        width: CGFloat,
        displayNames: ((Set<String>) -> ([String: String]?))?
    ) -> CGFloat {
        let minimumHeight = Padding.AvatarImage.top + Padding.AvatarImage.height + 5
        /// Calculating available width for messageView
        let leftSpacing = Padding.AvatarImage.left + Padding.AvatarImage.width + Padding.BubbleView.left + bubbleViewLeftPadding
        let rightSpacing = Padding.BubbleView.right + ALKMessageStyle.receivedBubble.widthPadding
        let messageWidth = width - (leftSpacing + rightSpacing)

        /// Calculating messageHeight
        let messageHeight = super
            .messageHeight(
                viewModel: viewModel,
                width: messageWidth,
                font: ALKMessageStyle.receivedMessage.font,
                mentionStyle: ALKMessageStyle.receivedMention,
                displayNames: displayNames
            )
        let heightPadding = Padding.NameLabel.top + Padding.NameLabel.height + Padding.LinkView.top + Padding.MessageView.top + Padding.MessageView.bottom + Padding.BubbleView.bottom

        let totalHeight = max(messageHeight + heightPadding, minimumHeight)

        return totalHeight + ALKLinkView.CommonPadding.PreviewImageView.height + ALKLinkView.CommonPadding.TitleLabel.top
    }

    @objc private func avatarTappedAction() {
        avatarTapped?()
    }

    // MARK: - ChatMenuCell

    override func menuWillShow(_ sender: Any) {
        super.menuWillShow(sender)
        if ALKMessageStyle.receivedBubble.style == .edge {
            bubbleView.image = bubbleView.imageBubble(
                for: ALKMessageStyle.receivedBubble.style,
                isReceiverSide: true,
                showHangOverImage: true
            )
        }
    }

    override func menuWillHide(_ sender: Any) {
        super.menuWillHide(sender)
        if ALKMessageStyle.receivedBubble.style == .edge {
            bubbleView.image = bubbleView.imageBubble(
                for: ALKMessageStyle.receivedBubble.style,
                isReceiverSide: true,
                showHangOverImage: false
            )
        }
    }
}
