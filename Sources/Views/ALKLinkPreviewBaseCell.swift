import Applozic
import Foundation

class ALKLinkPreviewBaseCell: ALKChatBaseCell<ALKMessageViewModel> {
    public var url: String?
    /// Dummy view required to calculate height for normal text.
    fileprivate static var dummyMessageView: ALKTextView = {
        let textView = ALKTextView(frame: .zero)
        textView.isUserInteractionEnabled = true
        textView.isSelectable = true
        textView.isEditable = false
        textView.dataDetectorTypes = .link
        textView.linkTextAttributes = [.foregroundColor: UIColor.blue,
                                       .underlineStyle: NSUnderlineStyle.single.rawValue]
        textView.isScrollEnabled = false
        textView.delaysContentTouches = false
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.contentInset = .zero
        return textView
    }()

    let messageView: ALKTextView = {
        let textView = ALKTextView(frame: .zero)
        textView.isUserInteractionEnabled = true
        textView.isSelectable = true
        textView.isEditable = false
        textView.dataDetectorTypes = .link
        textView.linkTextAttributes = [.foregroundColor: UIColor.blue,
                                       .underlineStyle: NSUnderlineStyle.single.rawValue]
        textView.isScrollEnabled = false
        textView.delaysContentTouches = false
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.contentInset = .zero
        return textView
    }()

    var timeLabel: UILabel = {
        let lb = UILabel()
        lb.isOpaque = true
        return lb
    }()

    var bubbleView: ALKImageView = {
        let bv = ALKImageView()
        bv.clipsToBounds = true
        bv.isUserInteractionEnabled = true
        bv.isOpaque = true
        return bv
    }()

    let linkView = ALKLinkView()
    var displayNames: ((Set<String>) -> ([String: String]?))?

    func update(
        viewModel: ALKMessageViewModel,
        messageStyle: Style,
        mentionStyle: Style
    ) {
        linkView.setLocalizedStringFileName(localizedStringFileName)
        self.viewModel = viewModel
        timeLabel.text = viewModel.time
        resetTextView(messageStyle)
        guard viewModel.message != nil else { return }

        switch viewModel.messageType {
        case .text:
            setMessageText(viewModel: viewModel, mentionStyle: mentionStyle)
            return
        default:
            print("😱😱😱Shouldn't come here.😱😱😱")
            return
        }
    }

    override func setupViews() {
        super.setupViews()
        linkView.isUserInteractionEnabled = true
        contentView.addViewsForAutolayout(views:
            [messageView, linkView,
             bubbleView,
             timeLabel])
        contentView.bringSubviewToFront(linkView)
        contentView.bringSubviewToFront(messageView)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(openUrl))
        linkView.frontView.addGestureRecognizer(tapGesture)
        bubbleView.addGestureRecognizer(longPressGesture)
    }

    override func setupStyle() {
        super.setupStyle()
        timeLabel.setStyle(ALKMessageStyle.time)
    }

    /// This  required cuz textView won't clear its attributes.
    /// See this: https://stackoverflow.com/q/21731207/6671572
    private func resetTextView(_ style: Style) {
        messageView.attributedText = nil
        messageView.text = nil
        messageView.typingAttributes = [:]
        messageView.setStyle(style)
    }

    private func setMessageText(
        viewModel: ALKMessageViewModel,
        mentionStyle: Style
    ) {
        if let attributedText = viewModel
            .attributedTextWithMentions(
                defaultAttributes: messageView.typingAttributes,
                mentionAttributes: mentionStyle.toAttributes,
                displayNames: displayNames
            ) {
            messageView.attributedText = attributedText
        } else {
            messageView.text = viewModel.message
        }
    }

    class func messageHeight(viewModel: ALKMessageViewModel,
                             width: CGFloat,
                             font: UIFont,
                             mentionStyle: Style,
                             displayNames: ((Set<String>) -> ([String: String]?))?) -> CGFloat {
        dummyMessageView.font = font
        /// Check if message is nil
        guard let message = viewModel.message else {
            return 0
        }
        switch viewModel.messageType {
        case .text:
            if let attributedText = viewModel
                .attributedTextWithMentions(
                    defaultAttributes: dummyMessageView.typingAttributes,
                    mentionAttributes: mentionStyle.toAttributes,
                    displayNames: displayNames
                ) {
                return TextViewSizeCalculator.height(dummyMessageView, attributedText: attributedText, maxWidth: width)
            }
            return TextViewSizeCalculator.height(dummyMessageView, text: message, maxWidth: width)
        default:
            print("😱😱😱Shouldn't come here.😱😱😱")
            return 0
        }
    }

    @objc private func openUrl() {
        let pushAssistant = ALPushAssist()
        guard let topVC = pushAssistant.topViewController,
            let stringURL = url, let openURL = URL(string: stringURL) else { return }
        let vc = ALKWebViewController(htmlString: nil, url: openURL, title: "")
        topVC.navigationController?.pushViewController(vc, animated: true)
    }
}

extension ALKLinkPreviewBaseCell: ALKCopyMenuItemProtocol, ALKReplyMenuItemProtocol, ALKReportMessageMenuItemProtocol {
    func menuCopy(_: Any) {
        UIPasteboard.general.string = viewModel?.message ?? ""
    }

    func menuReply(_: Any) {
        menuAction?(.reply)
    }

    func menuReport(_: Any) {
        menuAction?(.reportMessage)
    }
}
