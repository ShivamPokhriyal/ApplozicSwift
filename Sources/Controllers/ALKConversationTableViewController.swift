//
//  ALKConversationTableViewController.swift
//  ApplozicSwift
//
//  Created by Shivam Pokhriyal on 24/12/18.
//

import UIKit

/// A delegate used to notify the receiver of the events in `ALKConversationTableViewController`
public protocol ALKConversationTableViewDelegate: class {

    /// Tells the delegate a menu item is selected.
    ///
    /// - Parameters:
    ///   - action: MenuAction that has been selected.
    ///   - message: Message object associated with the action.
    func menuItemSelected(action: ALKChatBaseCell<ALKMessageViewModel>.MenuActionType,
                          message: ALKMessageViewModel)


    /// Tells the delegate avatar image of message is tapped.
    ///
    /// - Parameters:
    ///   - messageVM: Current message object of tableview cell.
    ///   - indexPath: Indexpath of current tableview cell.
    func messageAvatarViewDidTap(messageVM: ALKMessageViewModel, indexPath: IndexPath)


    /// Tells the delegate to update chatBar of current cell
    ///
    /// - Parameter cell: Current tableview cell.
    func updateChatCell(_ cell: ALKChatBaseCell<ALKMessageViewModel>)


    /// Tells the delegate to download attachment at indexPath
    ///
    /// - Parameters:
    ///   - view: TableView cell where attachment is present.
    ///   - indexPath: IndexPath of tableview cell.
    func attachmentViewDidTapDownload(view: UIView, indexPath: IndexPath)


    /// Tells the delegate to upload attachment at indexPath
    ///
    /// - Parameters:
    ///   - view: TableView cell where attachment is present.
    ///   - indexPath: indexPath of tableview cell.
    func attachmentViewDidTapUpload(view: UIView, indexPath: IndexPath)


    /// Tells the delegate response of attachment upload at indexPath
    ///
    /// - Parameters:
    ///   - response: Response of attachment upload process.
    ///   - indexPath: IndexPath of tableView cell.
    func attachmentUploadDidCompleteWith(response: Any?, indexPath: IndexPath)


    /// Tells the delegate that generic list button is selected.
    ///
    /// - Parameters:
    ///   - tag: Tag of selected button
    ///   - title: Title of selected button
    ///   - template: Generic list template
    func genericListButtonTapped(tag: Int, title: String, template: [ALKGenericListTemplate])


    /// Tells the delegate that generic card button is selected.
    ///
    /// - Parameters:
    ///   - tag: Tag of selected button.
    ///   - title: Title of selected button.
    ///   - card: Current generic card
    ///   - template: Current generic card template.
    func genericCardButtonTapped(tag: Int, title: String, card: ALKGenericCard, template: ALKGenericCardTemplate)


    /// Tells the delegate that audio play button is pressed.
    ///
    /// - Parameter identifier: Identifier of audio cell.
    func playAudioPress(identifier: String)


    /// Tells the delegate to display location
    ///
    /// - Parameter location: location to be displayed
    func displayLocation(location: ALKLocationPreviewViewModel)


    /// Tells the delegate that quick reply cell is selected.
    ///
    /// - Parameters:
    ///   - tag: Tag of quick reply cell.
    ///   - title: Title of quick reply.
    func quickReplyCellTapped(tag: Int, title: String)
}

public class ALKConversationTableViewController: UITableViewController {

    /// Public variables
    public var viewModel: ALKConversationViewModelProtocol
    public var localizationFileName: String
    public var configuration: ALKConfiguration
    public var contentOffsetDictionary: Dictionary<AnyHashable,AnyObject>!
    public weak var delegate: ALKConversationTableViewDelegate?

    //Internal variables
    var viewDidScroll: (() -> ())?
    var viewWillBeginDecelerating: (() -> ())?

    //MARK: - Initializers
    init(viewModel: ALKConversationViewModelProtocol, configuration: ALKConfiguration, delegate: ALKConversationTableViewDelegate) {
        self.viewModel = viewModel
        self.configuration = configuration
        self.localizationFileName = configuration.localizedStringFileName
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        contentOffsetDictionary = Dictionary<NSObject,AnyObject>()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        prepareTableView()
    }

    //MARK: - UITableViewDataSource methods
    public override func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections()
    }

    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRowsInSection(section)
    }

    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard var message = viewModel.messageFor(indexPath: indexPath) else {
            return UITableViewCell()
        }
        print("Cell updated at row: ", indexPath.row, "and type is: ", message.messageType)

        guard !message.isReplyMessage else {
            // Get reply cell and return
            if message.isMyMessage {
                let cell: ALKMyMessageCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
                self.configureCell(cell, with: message, at: indexPath)
                cell.replyViewAction = {[weak self] in
                    self?.scrollTo(message: message)
                }
                return cell

            } else {
                let cell: ALKFriendMessageCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
                self.configureCell(cell, with: message, at: indexPath)
                cell.replyViewAction = {[weak self] in
                    self?.scrollTo(message: message)
                }
                return cell
            }
        }
        switch message.messageType {
        case .text, .html:
            if message.isMyMessage {
                let cell: ALKMyMessageCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
                self.configureCell(cell, with: message, at: indexPath)
                return cell
            } else {
                let cell: ALKFriendMessageCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
                self.configureCell(cell, with: message, at: indexPath)
                return cell
            }
        case .photo:
            if message.isMyMessage {
                // Right now ratio is fixed to 1.77
                if message.ratio < 1 {
                    print("image messsage called")
                    let cell: ALKMyPhotoPortalCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
                    self.configureCell(cell, with: message, at: indexPath)
                    // Set the value to nil so that previous image gets removed before reuse
                    cell.photoView.image = nil
                    cell.uploadTapped = {[weak self]
                        value in
                        // upload
                        self?.delegate?.attachmentViewDidTapUpload(view: cell, indexPath: indexPath)
                    }
                    cell.uploadCompleted = {[weak self]
                        responseDict in
                        self?.delegate?.attachmentUploadDidCompleteWith(response: responseDict, indexPath: indexPath)
                    }
                    cell.downloadTapped = {[weak self]
                        value in
                        self?.delegate?.attachmentViewDidTapDownload(view: cell, indexPath: indexPath)
                    }
                    return cell
                } else {
                    let cell: ALKMyPhotoLandscapeCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
                    self.configureCell(cell, with: message, at: indexPath)
                    cell.uploadCompleted = {[weak self]
                        responseDict in
                        self?.delegate?.attachmentUploadDidCompleteWith(response: responseDict, indexPath: indexPath)
                    }
                    return cell
                }
            } else {
                if message.ratio < 1 {

                    let cell: ALKFriendPhotoPortalCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
                    self.configureCell(cell, with: message, at: indexPath)
                    cell.downloadTapped = {[weak self]
                        value in
                        self?.delegate?.attachmentViewDidTapDownload(view: cell, indexPath: indexPath)
                    }
                    return cell

                } else {
                    let cell: ALKFriendPhotoLandscapeCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
                    self.configureCell(cell, with: message, at: indexPath)
                    return cell
                }
            }
        case .voice:
            print("voice cell loaded with url", message.filePath as Any)
            print("current voice state: ", message.voiceCurrentState, "row", indexPath.row, message.voiceTotalDuration, message.voiceData as Any)
            print("voice identifier: ", message.identifier, "and row: ", indexPath.row)

            if message.isMyMessage {
                let cell: ALKMyVoiceCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
                self.configureCell(cell, with: message, at: indexPath)
                cell.buttonAction = {[weak self] identifier in
                    self?.delegate?.playAudioPress(identifier: identifier)
                }
                cell.downloadTapped = {[weak self] value in
                    self?.delegate?.attachmentViewDidTapDownload(view: cell, indexPath: indexPath)
                }
                return cell
            } else {
                let cell: ALKFriendVoiceCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
                self.configureCell(cell, with: message, at: indexPath)
                cell.downloadTapped = {[weak self] value in
                    self?.delegate?.attachmentViewDidTapDownload(view: cell, indexPath: indexPath)
                }
                cell.buttonAction = {[weak self] identifier in
                    self?.delegate?.playAudioPress(identifier: identifier)
                }
                return cell
            }
        case .location:
            if message.isMyMessage {
                let cell: ALKMyLocationCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
                self.configureCell(cell, with: message, at: indexPath)
                cell.displayLocation = {[weak self] location in
                    self?.delegate?.displayLocation(location: location)
                }
                return cell
            } else {
                let cell: ALKFriendLocationCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
                self.configureCell(cell, with: message, at: indexPath)
                cell.displayLocation = {[weak self] location in
                    self?.delegate?.displayLocation(location: location)
                }
                return cell
            }
        case .information:
            let cell: ALKInformationCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
            cell.setConfiguration(configuration: configuration)
            cell.update(viewModel: message)
            return cell
        case .video:
            if message.isMyMessage {
                let cell: ALKMyVideoCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
                self.configureCell(cell, with: message, at: indexPath)
                cell.uploadTapped = {[weak self]
                    value in
                    // upload
                    self?.delegate?.attachmentViewDidTapUpload(view: cell, indexPath: indexPath)
                }
                cell.uploadCompleted = {[weak self]
                    responseDict in
                    self?.delegate?.attachmentUploadDidCompleteWith(response: responseDict, indexPath: indexPath)
                }
                cell.downloadTapped = {[weak self]
                    value in
                    self?.delegate?.attachmentViewDidTapDownload(view: cell, indexPath: indexPath)
                }
                return cell
            } else {
                let cell: ALKFriendVideoCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
                self.configureCell(cell, with: message, at: indexPath)
                cell.downloadTapped = {[weak self]
                    value in
                    self?.delegate?.attachmentViewDidTapDownload(view: cell, indexPath: indexPath)
                }
                return cell
            }
        case .genericCard:
            if message.isMyMessage {
                let cell: ALKMyGenericCardCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
                self.configureCell(cell, with: message, at: indexPath)
                cell.register(cell: ALKGenericCardCell.self)
                return cell
            } else {
                let cell: ALKFriendGenericCardCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
                self.configureCell(cell, with: message, at: indexPath)
                cell.register(cell: ALKGenericCardCell.self)
                return cell
            }
        case .genericList:
            if message.isMyMessage {
                let cell: ALKMyGenericListCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
                self.configureCell(cell, with: message, at: indexPath)
                guard let template = viewModel.genericTemplateFor(message: message) as? [ALKGenericListTemplate] else { return UITableViewCell() }
                cell.buttonSelected = {[unowned self] tag, title in
                    self.delegate?.genericListButtonTapped(tag: tag, title: title, template: template)
                }
                return cell
            } else {
                let cell: ALKFriendGenericListCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
                self.configureCell(cell, with: message, at: indexPath)
                guard let template = viewModel.genericTemplateFor(message: message) as? [ALKGenericListTemplate] else { return UITableViewCell() }
                cell.buttonSelected = {[unowned self] tag, title in
                    self.delegate?.genericListButtonTapped(tag: tag, title: title, template: template)
                }
                return cell
            }
        case .quickReply:
            if message.isMyMessage {
                let cell: ALKMyMessageQuickReplyCell  = tableView.dequeueReusableCell(forIndexPath: indexPath)
                self.configureCell(cell, with: message, at: indexPath)
                cell.register(cell: ALQuickReplyCollectionViewCell.self)
                return cell

            } else {
                let cell: ALKFriendMessageQuickReplyCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
                self.configureCell(cell, with: message, at: indexPath)
                cell.register(cell: ALQuickReplyCollectionViewCell.self)
                return cell
            }

        }
    }

    //MARK: - UITableViewDelegate methods
    public override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return viewModel.heightFor(indexPath: indexPath, cellFrame: self.view.frame)
    }

    public override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let heightForHeaderInSection: CGFloat = 40.0

        guard let message1 = viewModel.messageFor(indexPath: IndexPath(row: 0, section: section)) else {
            return 0.0
        }

        // If it is the first section then no need to check the difference,
        // just show the start date. (message list is not empty)
        if section == 0 {
            return heightForHeaderInSection
        }

        // Get previous message
        guard let message2 = viewModel.messageFor(indexPath: IndexPath(row: 0, section: section - 1)) else {
            return 0.0
        }
        let date1 = message1.date
        let date2 = message2.date
        switch Calendar.current.compare(date1, to: date2, toGranularity: .day) {
            case .orderedDescending:
                // There is a day difference between current message and the previous message.
                return heightForHeaderInSection
            default:
                return 0.0
        }
    }

    public override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let message = viewModel.messageFor(indexPath: IndexPath(row: 0, section: section)) else {
            return nil
        }
        // Get message creation date
        let date = message.date

        let dateView = ALKDateSectionHeaderView.instanceFromNib()
        dateView.backgroundColor = UIColor.clear
        dateView.dateView.backgroundColor = configuration.conversationViewCustomCellBackgroundColor
        dateView.dateLabel.backgroundColor = configuration.conversationViewCustomCellBackgroundColor
        dateView.dateLabel.textColor = configuration.conversationViewCustomCellTextColor

        // Set date text
        dateView.setupDate(withDateFormat: date.stringCompareCurrentDate())
        return dateView
    }

    public override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let message = viewModel.messageFor(indexPath: indexPath), message.metadata != nil else {
            return
        }
        if(message.messageType == ALKMessageType.quickReply){
            if message.isMyMessage {
                guard let cell =  cell as? ALKMyMessageQuickReplyCell  else {
                    return
                }
                cell.setCollectionViewDataSourceDelegate(dataSourceDelegate: self, indexPath: indexPath)
                let index = cell.collectionView.tag
                let value = contentOffsetDictionary[index]
                let horizontalOffset = CGFloat(value != nil ? value!.floatValue : 0)
                cell.collectionView.setContentOffset(CGPoint(x: horizontalOffset, y: 0), animated: false)
            } else {
                guard let cell =  cell as? ALKFriendMessageQuickReplyCell else {
                    return
                }
                cell.setCollectionViewDataSourceDelegate(dataSourceDelegate: self, indexPath: indexPath)
                let index = cell.collectionView.tag
                let value = contentOffsetDictionary[index]
                let horizontalOffset = CGFloat(value != nil ? value!.floatValue : 0)
                cell.collectionView.setContentOffset(CGPoint(x: horizontalOffset, y: 0), animated: false)
            }
        } else if message.messageType == .genericCard {
            if message.isMyMessage {
                guard let cell =  cell as? ALKMyGenericCardCell else {
                    return
                }
                cell.setCollectionViewDataSourceDelegate(dataSourceDelegate: self, indexPath: indexPath)
                let index = cell.collectionView.tag
                cell.collectionView.setContentOffset(CGPoint(x: collectionViewOffsetFromIndex(index), y: 0), animated: false)
            }else{
                guard let cell =  cell as? ALKFriendGenericCardCell else {
                    return
                }
                cell.setCollectionViewDataSourceDelegate(dataSourceDelegate: self, indexPath: indexPath)
                let index = cell.collectionView.tag
                cell.collectionView.setContentOffset(CGPoint(x: collectionViewOffsetFromIndex(index), y: 0), animated: false)
            }
        }
    }

    //MARK: - ScrollView delegate methods
    public override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (scrollView is UICollectionView) {
            let horizontalOffset = scrollView.contentOffset.x
            let collectionView = scrollView as! UICollectionView
            contentOffsetDictionary[collectionView.tag] = horizontalOffset as AnyObject
        }
        guard let viewDidScroll = viewDidScroll else {
            return
        }
        viewDidScroll()
    }

    public override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if (decelerate) {return}
        configurePaginationWindow()
    }

    public override func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        guard let viewWillBeginDecelerating = viewWillBeginDecelerating else {
            return
        }
        viewWillBeginDecelerating()
    }

    public override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        configurePaginationWindow()
    }

    public override func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        configurePaginationWindow()
    }

    //MARK: - Private methods
    private func prepareTableView() {

        tableView.separatorStyle   = .none
        tableView.allowsSelection  = false
        tableView.clipsToBounds    = true
        tableView.keyboardDismissMode = UIScrollViewKeyboardDismissMode.onDrag
        tableView.accessibilityIdentifier = "InnerChatScreenTableView"

        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsSelection = false
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        tableView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

        tableView.sectionHeaderHeight = 0.0
        tableView.sectionFooterHeight = 0.0
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: tableView.bounds.size.width, height: 0.1))
        tableView.tableFooterView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: tableView.bounds.size.width, height: 8))

        self.automaticallyAdjustsScrollViewInsets = false

        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentBehavior.never
        }
        tableView.estimatedRowHeight = 0

        tableView.register(ALKMyMessageCell.self)
        tableView.register(ALKFriendMessageCell.self)
        tableView.register(ALKMyPhotoPortalCell.self)
        tableView.register(ALKMyPhotoLandscapeCell.self)
        tableView.register(ALKFriendPhotoPortalCell.self)
        tableView.register(ALKFriendPhotoLandscapeCell.self)
        tableView.register(ALKMyVoiceCell.self)
        tableView.register(ALKFriendVoiceCell.self)
        tableView.register(ALKInformationCell.self)
        tableView.register(ALKMyLocationCell.self)
        tableView.register(ALKFriendLocationCell.self)
        tableView.register(ALKMyVideoCell.self)
        tableView.register(ALKFriendVideoCell.self)
        tableView.register(ALKMyGenericListCell.self)
        tableView.register(ALKFriendGenericListCell.self)
        tableView.register(ALKFriendMessageQuickReplyCell.self)
        tableView.register(ALKMyMessageQuickReplyCell.self)
        tableView.register(ALKMyGenericCardCell.self)
        tableView.register(ALKFriendGenericCardCell.self)
    }

    private func configureCell(_ cell: ALKChatBaseCell<ALKMessageViewModel>, with message: ALKMessageViewModel, at indexPath: IndexPath) {
        cell.setLocalizedStringFileName(localizationFileName)
        cell.update(viewModel: message)
        delegate?.updateChatCell(cell)
        cell.menuAction = {[weak self] action in
            self?.delegate?.menuItemSelected(action: action, message: message)
        }
        guard !message.isMyMessage else {
            return
        }
        cell.avatarTapped = {[weak self] in
            guard let currentModel = cell.viewModel else {return}
            self?.delegate?.messageAvatarViewDidTap(messageVM: currentModel, indexPath: indexPath)
        }
    }

    private func collectionViewOffsetFromIndex(_ index: Int) -> CGFloat {
        let value = contentOffsetDictionary[index]
        let horizontalOffset = CGFloat(value != nil ? value!.floatValue : 0)
        return horizontalOffset
    }

    private func configurePaginationWindow() {
        if (self.tableView.frame.equalTo(CGRect.zero)) {return}
        if (self.tableView.isDragging) {return}
        if (self.tableView.isDecelerating) {return}
        let topOffset = -self.tableView.contentInset.top
        let distanceFromTop = self.tableView.contentOffset.y - topOffset
        let minimumDistanceFromTopToTriggerLoadingMore: CGFloat = 200
        let nearTop = distanceFromTop <= minimumDistanceFromTopToTriggerLoadingMore
        if (!nearTop) {return}

        self.viewModel.loadMoreMessages()
    }

    private func scrollTo(message: ALKMessageViewModel) {
        guard let indexPath = viewModel.indexpathForReplyMessage(message) else {
            return
        }
        tableView.scrollToRow(at: indexPath, at: .top, animated: true)
    }

}

//MARK: - UICollectionView delegates and datasource methods
extension ALKConversationTableViewController: UICollectionViewDataSource,UICollectionViewDelegate, UICollectionViewDelegateFlowLayout{

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let message = viewModel.messageFor(indexPath: IndexPath(row: 0, section: collectionView.tag)),
            let metadata = message.metadata
            else {
                return 0
        }
        if(message.messageType == ALKMessageType.quickReply){
            let payload = metadata["payload"] as! String?
            let data = payload?.data
            do {
                if let jsonArray = try JSONSerialization.jsonObject(with: data!, options : .allowFragments) as? [Dictionary<String,Any>]{
                    let filteredCustomReqList = jsonArray;
                    return  filteredCustomReqList.count;
                }
            } catch let error as NSError {
                print(error)
            }
        }else{
            guard let collectionView = collectionView as? ALKIndexedCollectionView,
                let message = viewModel.messageFor(indexPath: IndexPath(row: 0, section: collectionView.tag)),
                let template = viewModel.genericTemplateFor(message: message) as? ALKGenericCardTemplate
                else {return 0}
            return template.cards.count
        }
        return 0
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard
            let collectionView = collectionView as? ALKIndexedCollectionView,
            let message = viewModel.messageFor(indexPath: IndexPath(row: 0, section: collectionView.tag))
        else {
            return UICollectionViewCell()
        }

        if(message.messageType == ALKMessageType.quickReply){
            guard let dictionary = viewModel.quickReplyDictionary(message: message, indexRow: indexPath.row) else {
                return  UICollectionViewCell()
            }
            let cell: ALQuickReplyCollectionViewCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
            cell.update(data: dictionary)
            cell.buttonSelected = {[weak self] tag, title in
                self?.delegate?.quickReplyCellTapped(tag: tag, title: title)
            }
            return cell
        } else {
            guard
                let template = viewModel.genericTemplateFor(message: message) as? ALKGenericCardTemplate,
                template.cards.count > indexPath.row
                else {
                    return UICollectionViewCell()
            }
            let cell: ALKGenericCardCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
            let card = template.cards[indexPath.row]
            cell.update(card: card)
            cell.buttonSelected = {[weak self] tag, title in
                self?.delegate?.genericCardButtonTapped(tag: tag, title: title, card: card, template: template)
            }
            return cell
        }
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        guard let message = viewModel.messageFor(indexPath: IndexPath(row: 0, section: collectionView.tag)) else {
            return CGSize(width: 0, height: 0)
        }
        if(message.messageType == ALKMessageType.quickReply){
            guard let dictionary = viewModel.quickReplyDictionary(message: message, indexRow: indexPath.row) else {
                return  CGSize(width: self.view.frame.width-50, height: 350)
            }
            return viewModel.sizeForQuickReplyItemAt(row: indexPath.row, withData: dictionary)
        } else if message.messageType == .genericCard {

            let width = self.view.frame.width - 100 // - 100 to ensure the card appears in the screen
            let height = ALKGenericCardCollectionView.rowHeightFor(message: message) - 40 // Extra padding for top and bottom
            return CGSize(width: width, height: height)
        }
        return CGSize(width: self.view.frame.width-50, height: 350)
    }
}
