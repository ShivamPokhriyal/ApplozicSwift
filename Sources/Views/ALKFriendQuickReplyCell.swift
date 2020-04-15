//
//  ALKFriendQuickReplyCell.swift
//  ApplozicSwift
//
//  Created by apple on 15/04/20.
//

import Foundation
import Kingfisher

public class ALKFriendQuickReplyCell: ALKChatBaseCell<ALKMessageViewModel> {
    var timeLabel: UILabel = {
        let lb = UILabel()
        lb.isOpaque = true
        return lb
    }()

    var bubbleView: UIImageView = {
        let bv = UIImageView()
        bv.clipsToBounds = true
        bv.isUserInteractionEnabled = false
        bv.isOpaque = true
        return bv
    }()

    var avatarImageView: UIImageView = {
        let imv = UIImageView()
        imv.contentMode = .scaleAspectFill
        imv.clipsToBounds = true
        let layer = imv.layer
        layer.cornerRadius = 18.5
        layer.masksToBounds = true
        imv.isUserInteractionEnabled = true
        return imv
    }()

    var nameLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.isOpaque = true
        return label
    }()

    enum Padding {
        enum NameLabel {
            static let top: CGFloat = 6
            static let leading: CGFloat = 57
            static let trailing: CGFloat = 57
            static let height: CGFloat = 16
        }

        enum TimeLabel {
            static let leading: CGFloat = 10
            static let bottom: CGFloat = 2
        }

        enum AvatarImageView {
            static let top: CGFloat = 18
            static let leading: CGFloat = 9
            static let height: CGFloat = 37
        }
    }

    var quickReplyView = SuggestedReplyView()
    var quickReplySelected: ((_ index: Int, _ title: String) -> Void)?
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupConstraints()
        quickReplyView.delegate = self
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setupStyle() {
        super.setupStyle()
        nameLabel.setStyle(ALKMessageStyle.displayName)
        timeLabel.setStyle(ALKMessageStyle.time)
    }

    public func update(viewModel: ALKMessageViewModel, maxWidth: CGFloat) {
        super.update(viewModel: viewModel)
        let placeHolder = UIImage(named: "placeholder", in: Bundle.applozic, compatibleWith: nil)
        if let url = viewModel.avatarURL {
            let resource = ImageResource(downloadURL: url, cacheKey: url.absoluteString)
            avatarImageView.kf.setImage(with: resource, placeholder: placeHolder)
        } else {
            avatarImageView.image = placeHolder
        }
        nameLabel.text = viewModel.displayName
        timeLabel.text = viewModel.time

        guard let suggestedReplies = viewModel.suggestedReply() else {
            quickReplyView.isHidden = true
            return
        }
        let quickReplyViewWidth = maxWidth -
            (ChatCellPadding.ReceivedMessage.QuickReply.left + ChatCellPadding.ReceivedMessage.Message.right)
        quickReplyView.update(model: suggestedReplies, maxWidth: quickReplyViewWidth)
    }

    public class func rowHeight(viewModel: ALKMessageViewModel, maxWidth: CGFloat) -> CGFloat {
        let minimumHeight: CGFloat = 60 // 55 is avatar image... + padding
        let height: CGFloat = 30 // 6 + 16 + 4 + 2 + 2
        guard let suggestedReplies = viewModel.suggestedReply() else {
            return minimumHeight
        }
        let quickReplyViewWidth = maxWidth -
            (ChatCellPadding.ReceivedMessage.QuickReply.left + ChatCellPadding.ReceivedMessage.Message.right)
        return height
            + SuggestedReplyView.rowHeight(model: suggestedReplies, maxWidth: quickReplyViewWidth)
            + ChatCellPadding.ReceivedMessage.QuickReply.top
            + ChatCellPadding.ReceivedMessage.QuickReply.bottom
    }

    private func setupConstraints() {
        contentView.addViewsForAutolayout(views: [avatarImageView, nameLabel, quickReplyView, timeLabel])
        bringSubviewToFront(avatarImageView)
        bringSubviewToFront(nameLabel)
        bringSubviewToFront(timeLabel)

        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: topAnchor, constant: Padding.NameLabel.top),
            nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Padding.NameLabel.leading),
            nameLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Padding.NameLabel.trailing),
            nameLabel.heightAnchor.constraint(equalToConstant: Padding.NameLabel.height),

            avatarImageView.topAnchor.constraint(equalTo: topAnchor, constant: Padding.AvatarImageView.top),
            avatarImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Padding.AvatarImageView.leading),
            avatarImageView.heightAnchor.constraint(equalToConstant: Padding.AvatarImageView.height),
            avatarImageView.widthAnchor.constraint(equalTo: avatarImageView.heightAnchor),
            quickReplyView.topAnchor.constraint(
                equalTo: nameLabel.bottomAnchor,
                constant: ChatCellPadding.ReceivedMessage.QuickReply.top
            ),
            quickReplyView.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor,
                constant: ChatCellPadding.ReceivedMessage.QuickReply.left
            ),
            quickReplyView.trailingAnchor.constraint(
                lessThanOrEqualTo: contentView.trailingAnchor,
                constant: -ChatCellPadding.ReceivedMessage.Message.right
            ),
            quickReplyView.bottomAnchor.constraint(
                equalTo: contentView.bottomAnchor,
                constant: -ChatCellPadding.ReceivedMessage.QuickReply.bottom
            ),
            timeLabel.leadingAnchor.constraint(equalTo: quickReplyView.trailingAnchor),
            timeLabel.bottomAnchor.constraint(equalTo: quickReplyView.bottomAnchor),
        ])
    }
}

extension ALKFriendQuickReplyCell: Tappable {
    public func didTap(index: Int?, title: String) {
        guard let quickReplySelected = quickReplySelected, let index = index else { return }
        quickReplySelected(index, title)
    }
}
