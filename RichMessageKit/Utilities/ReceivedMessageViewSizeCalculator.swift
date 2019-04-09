//
//  ReceivedMessageViewSizeCalculator.swift
//  RichMessageKit
//
//  Created by Shivam Pokhriyal on 26/01/19.
//

import Foundation

class ReceivedMessageViewSizeCalculator {

    func rowHeight(messageModel: MessageModel, maxWidth: CGFloat, padding: Padding) -> CGFloat {
        guard let message = messageModel.message else {
            return 0
        }
        let config = ReceivedMessageView.Config.self
        let minimumHeight = config.ProfileImage.height + padding.top + padding.bottom + config.ProfileImage.topPadding + config.DisplayName.height
        let totalWidthPadding = padding.left + padding.right + config.TimeLabel.leftPadding + config.MessageView.leftPadding

        let timeLabelWidth = messageModel.time.rectWithConstrainedWidth(config.TimeLabel.maxWidth, font: MessageTheme.receivedMessage.time.font).width.rounded(.up)

        let messageWidth = maxWidth - (totalWidthPadding + config.ProfileImage.width + timeLabelWidth)
        let messageHeight = MessageBubbleSizeCalculator().rowHeight(text: message,
                                                       font: MessageTheme.receivedMessage.message.font,
                                                       maxWidth: messageWidth,
                                                       padding: MessageTheme.receivedMessage.bubble.padding)
        let totalHeightPadding = padding.top + padding.bottom + config.MessageView.topPadding + config.MessageView.bottomPadding
        let calculatedHeight = messageHeight + totalHeightPadding + config.DisplayName.height
        return max(calculatedHeight, minimumHeight)
    }

}
