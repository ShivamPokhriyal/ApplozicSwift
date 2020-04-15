//
//  ALKMyQuickReplyCell.swift
//  ApplozicSwift
//
//  Created by apple on 15/04/20.
//

import Foundation
import Kingfisher

public class ALKMyQuickReplyCell: ALKChatBaseCell<ALKMessageViewModel> {
    enum Padding {
        enum StateView {
            static let bottom: CGFloat = 1
            static let right: CGFloat = 2
        }

        enum TimeLabel {
            static let right: CGFloat = 2
            static let bottom: CGFloat = 2
        }
    }

    var timeLabel: UILabel = {
        let lb = UILabel()
        lb.isOpaque = true
        return lb
    }()

    var stateView: UIImageView = {
        let sv = UIImageView()
        sv.isUserInteractionEnabled = false
        sv.contentMode = .center
        return sv
    }()

    var quickReplyView = SuggestedReplyView()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupConstraints()
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setupStyle() {
        super.setupStyle()
        timeLabel.setStyle(ALKMessageStyle.time)
    }

    public func update(viewModel: ALKMessageViewModel, maxWidth: CGFloat) {
        // Set time
        timeLabel.text = viewModel.time
        setStatusStyle(statusView: stateView, ALKMessageStyle.messageStatus)
        guard let suggestedReply = viewModel.suggestedReply() else {
            quickReplyView.isHidden = true
            return
        }
        let quickReplyViewWidth = maxWidth -
            (ChatCellPadding.SentMessage.QuickReply.left + ChatCellPadding.SentMessage.QuickReply.right)
        quickReplyView.update(model: suggestedReply, maxWidth: quickReplyViewWidth)
    }

    public class func rowHeight(viewModel: ALKMessageViewModel, maxWidth: CGFloat) -> CGFloat {
        var height: CGFloat = 10 // Padding
        height += 20 // (6 + 4) + 10 for extra padding
        guard let suggestedReplies = viewModel.suggestedReply() else {
            return height
        }
        let quickReplyViewWidth = maxWidth -
            (ChatCellPadding.SentMessage.QuickReply.left + ChatCellPadding.SentMessage.QuickReply.right)
        return height
            + SuggestedReplyView.rowHeight(model: suggestedReplies, maxWidth: quickReplyViewWidth)
            + ChatCellPadding.SentMessage.QuickReply.top
            + ChatCellPadding.SentMessage.QuickReply.bottom
    }

    private func setupConstraints() {
        contentView.addViewsForAutolayout(views: [stateView, timeLabel, quickReplyView])
        bringSubviewToFront(stateView)
        bringSubviewToFront(timeLabel)

        NSLayoutConstraint.activate([
            quickReplyView.topAnchor.constraint(
                equalTo: contentView.topAnchor,
                constant: ChatCellPadding.SentMessage.QuickReply.top
            ),
            quickReplyView.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor,
                constant: -ChatCellPadding.SentMessage.QuickReply.right
            ),
            quickReplyView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: ChatCellPadding.SentMessage.QuickReply.left),
            quickReplyView.bottomAnchor.constraint(
                equalTo: timeLabel.topAnchor,
                constant: -ChatCellPadding.SentMessage.QuickReply.bottom
            ),

            stateView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -1 * Padding.StateView.bottom),
            stateView.trailingAnchor.constraint(equalTo: quickReplyView.trailingAnchor, constant: -1 * Padding.StateView.right),
            stateView.heightAnchor.constraint(equalToConstant: 9.0),
            stateView.widthAnchor.constraint(equalToConstant: 9),
            timeLabel.trailingAnchor.constraint(equalTo: stateView.leadingAnchor, constant: -1 * Padding.TimeLabel.right),
            timeLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: Padding.TimeLabel.bottom),

        ])
    }
}
