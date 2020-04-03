import Foundation

class ALKMyLinkPreviewCell: ALKLinkPreviewBaseCell {
    fileprivate var stateView: UIImageView = {
        let sv = UIImageView()
        sv.isUserInteractionEnabled = false
        sv.contentMode = .center
        return sv
    }()

    static var bubbleViewRightPadding: CGFloat = {
        /// For edge add extra 5
        guard ALKMessageStyle.sentBubble.style == .edge else {
            return ALKMessageStyle.sentBubble.widthPadding
        }
        return ALKMessageStyle.sentBubble.widthPadding + 5
    }()

    enum Padding {
        enum MessageView {
            static let top: CGFloat = 5.0
            static let bottom: CGFloat = 10.0
        }

        enum BubbleView {
            static let left: CGFloat = 95.0
            static let bottom: CGFloat = 8.0
            static let right: CGFloat = 10.0
        }

        enum StateView {
            static let height: CGFloat = 9.0
            static let width: CGFloat = 17.0
            static let right: CGFloat = 2.0
        }

        enum LinkView {
            static let top: CGFloat = 5.0
            static let left: CGFloat = 10.0
            static let right: CGFloat = 8.0
        }

        enum TimeLabel {
            static let left: CGFloat = 2.0
            static let bottom: CGFloat = 2.0
        }
    }

    override func setupViews() {
        super.setupViews()

        contentView.addViewsForAutolayout(views: [stateView])

        NSLayoutConstraint.activate([
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor),
            bubbleView.bottomAnchor.constraint(
                equalTo: contentView.bottomAnchor,
                constant: -Padding.BubbleView.bottom
            ),
            bubbleView.leadingAnchor.constraint(
                greaterThanOrEqualTo: contentView.leadingAnchor,
                constant: Padding.BubbleView.left
            ),
            bubbleView.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor,
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
            messageView.leadingAnchor.constraint(
                equalTo: bubbleView.leadingAnchor,
                constant: ALKMessageStyle.sentBubble.widthPadding
            ),
            messageView.trailingAnchor.constraint(
                equalTo: bubbleView.trailingAnchor,
                constant: -ALKMyMessageCell.bubbleViewRightPadding
            ),
            messageView.bottomAnchor.constraint(
                equalTo: bubbleView.bottomAnchor,
                constant: -Padding.MessageView.bottom
            ),
            stateView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor),
            stateView.trailingAnchor.constraint(
                equalTo: bubbleView.leadingAnchor,
                constant: -Padding.StateView.right
            ),

            timeLabel.trailingAnchor.constraint(
                equalTo: stateView.leadingAnchor,
                constant: -Padding.TimeLabel.left
            ),
            timeLabel.bottomAnchor.constraint(
                equalTo: bubbleView.bottomAnchor,
                constant: Padding.TimeLabel.bottom
            ),
        ])
    }

    open override func setupStyle() {
        super.setupStyle()
        messageView.setStyle(ALKMessageStyle.sentMessage)
        bubbleView.setStyle(ALKMessageStyle.sentBubble, isReceiverSide: false)
        setStatusStyle(statusView: stateView, ALKMessageStyle.messageStatus)
    }

    open override func update(viewModel: ALKMessageViewModel) {
        super.update(
            viewModel: viewModel,
            messageStyle: ALKMessageStyle.sentMessage,
            mentionStyle: ALKMessageStyle.sentMention
        )

        setStatusStyle(statusView: stateView, ALKMessageStyle.messageStatus)
        linkView.update(url: url)
    }

    class func rowHeigh(viewModel: ALKMessageViewModel,
                        width: CGFloat,
                        displayNames: ((Set<String>) -> ([String: String]?))?) -> CGFloat {
        /// Calculating messageHeight
        let leftSpacing = Padding.BubbleView.left + ALKMessageStyle.sentBubble.widthPadding
        let rightSpacing = Padding.BubbleView.right + bubbleViewRightPadding
        let messageWidth = width - (leftSpacing + rightSpacing)
        let messageHeight = super
            .messageHeight(
                viewModel: viewModel,
                width: messageWidth,
                font: ALKMessageStyle.sentMessage.font,
                mentionStyle: ALKMessageStyle.sentMention,
                displayNames: displayNames
            )
        let heightPadding = Padding.MessageView.top + Padding.MessageView.bottom + Padding.BubbleView.bottom + Padding.LinkView.top

        let totalHeight = messageHeight + heightPadding

        return totalHeight + ALKLinkView.CommonPadding.PreviewImageView.height + ALKLinkView.CommonPadding.TitleLabel.top
    }

    // MARK: - ChatMenuCell

    override func menuWillShow(_ sender: Any) {
        super.menuWillShow(sender)
        if ALKMessageStyle.sentBubble.style == .edge {
            bubbleView.image = bubbleView.imageBubble(
                for: ALKMessageStyle.sentBubble.style,
                isReceiverSide: false,
                showHangOverImage: true
            )
        }
    }

    override func menuWillHide(_ sender: Any) {
        super.menuWillHide(sender)
        if ALKMessageStyle.sentBubble.style == .edge {
            bubbleView.image = bubbleView.imageBubble(
                for: ALKMessageStyle.sentBubble.style,
                isReceiverSide: false,
                showHangOverImage: false
            )
        }
    }
}
