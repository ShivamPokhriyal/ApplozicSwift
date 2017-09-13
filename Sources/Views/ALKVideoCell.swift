//
//  ALKVideoCell.swift
//  ApplozicSwift
//
//  Created by Mukesh Thawani on 10/07/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import UIKit
import Applozic
import AVKit

class ALKVideoCell: ALKChatBaseCell<ALKMessageViewModel> {

    enum state {
        case download
        case downloading(progress: Double, totalCount: Int64)
        case downloaded(filePath: String)
        case upload
    }

    var photoView: UIImageView = {
        let mv = UIImageView()
        mv.backgroundColor = .clear
        mv.contentMode = .scaleAspectFill
        mv.clipsToBounds = true
        mv.layer.cornerRadius = 12
        return mv
    }()

    var timeLabel: UILabel = {
        let lb = UILabel()
        return lb
    }()

    var fileSizeLabel: UILabel = {
        let lb = UILabel()
        return lb
    }()

    fileprivate var actionButton: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = .clear
        button.isHidden = true
        return button
    }()

    fileprivate var downloadButton: UIButton = {
        let button = UIButton(type: .custom)
        let image = UIImage(named: "DownloadiOS", in: Bundle.applozic, compatibleWith: nil)
        button.setImage(image, for: .normal)
        button.backgroundColor = UIColor.black
        return button
    }()

    fileprivate var playButton: UIButton = {
        let button = UIButton(type: .custom)
        let image = UIImage(named: "PLAY", in: Bundle.applozic, compatibleWith: nil)
        button.setImage(image, for: .normal)
        return button
    }()

    fileprivate var uploadButton: UIButton = {
        let button = UIButton(type: .custom)
        let image = UIImage(named: "UploadiOS2", in: Bundle.applozic, compatibleWith: nil)
        button.setImage(image, for: .normal)
        button.backgroundColor = UIColor.black
        return button
    }()

    var bubbleView: UIView = {
        let bv = UIView()
        bv.backgroundColor = .gray
        bv.layer.cornerRadius = 12
        bv.isUserInteractionEnabled = false
        return bv
    }()

    var progressView: KDCircularProgress = {
        let view = KDCircularProgress(frame: .zero)
        view.startAngle = -90
        view.clockwise = true
        return view
    }()

    var url: URL? = nil

    var uploadTapped:((Bool) ->())?
    var uploadCompleted: ((_ responseDict: Any?) ->())?

    class func topPadding() -> CGFloat {
        return 12
    }

    class func bottomPadding() -> CGFloat {
        return 16
    }

    override class func rowHeigh(viewModel: ALKMessageViewModel,width: CGFloat) -> CGFloat {

        let heigh: CGFloat

        if viewModel.ratio < 1 {
            heigh = viewModel.ratio == 0 ? (width*0.48) : ceil((width*0.48)/viewModel.ratio)
        } else {
            heigh = ceil((width*0.64)/viewModel.ratio)
        }

        return topPadding()+heigh+bottomPadding()
    }

    override func update(viewModel: ALKMessageViewModel) {

        self.viewModel = viewModel
        timeLabel.text = viewModel.time

        if viewModel.isMyMessage {
            if viewModel.isSent || viewModel.isAllRead || viewModel.isAllReceived {
                if let filePath = viewModel.filePath, !filePath.isEmpty {
                    updateView(for: state.downloaded(filePath: filePath))
                } else {
                    updateView(for: state.download)
                }
            } else {
                updateView(for: .upload)
            }
        } else {
            if let filePath = viewModel.filePath, !filePath.isEmpty {
                updateView(for: state.downloaded(filePath: filePath))
            } else {
                updateView(for: state.download)
            }
        }

    }

    func actionTapped(button: UIButton) {
        button.isEnabled = false

//        let storyboard = UIStoryboard.name(storyboard: UIStoryboard.Storyboard.previewImage, bundle: Bundle.applozic)
//
//        guard let imageUrl = url,
//            let nav = storyboard.instantiateInitialViewController() as? UINavigationController,
//            let vc = nav.viewControllers.first as? ALKPreviewImageViewController else {
//
//                button.isEnabled = true
//                return
//        }
//
//        vc.viewModel = ALKPreviewImageViewModel(imageUrl: imageUrl)
//        UIViewController.topViewController()?.present(nav, animated: true, completion: {
//            button.isEnabled = true
//        })
    }

    override func setupStyle() {
        super.setupStyle()

        timeLabel.setStyle(style: ALKMessageStyle.time)
        fileSizeLabel.setStyle(style: ALKMessageStyle.time)
    }

    override func setupViews() {
        super.setupViews()
        playButton.isHidden = true
        progressView.isHidden = true
        uploadButton.isHidden = true

        actionButton.addTarget(self, action: #selector(actionTapped), for: .touchUpInside)
        downloadButton.addTarget(self, action: #selector(ALKVideoCell.downloadButtonAction(_:)), for: UIControlEvents.touchUpInside)
        uploadButton.addTarget(self, action: #selector(ALKVideoCell.uploadButtonAction(_:)), for: .touchUpInside)
        playButton.addTarget(self, action: #selector(ALKVideoCell.playButtonAction(_:)), for: .touchUpInside)

        contentView.addViewsForAutolayout(views: [photoView,bubbleView, timeLabel,fileSizeLabel, downloadButton, playButton, progressView, uploadButton])
        contentView.bringSubview(toFront: photoView)
        contentView.bringSubview(toFront: actionButton)
        contentView.bringSubview(toFront: downloadButton)
        contentView.bringSubview(toFront: playButton)
        contentView.bringSubview(toFront: progressView)
        contentView.bringSubview(toFront: uploadButton)

        bubbleView.topAnchor.constraint(equalTo: photoView.topAnchor).isActive = true
        bubbleView.bottomAnchor.constraint(equalTo: photoView.bottomAnchor).isActive = true
        bubbleView.leftAnchor.constraint(equalTo: photoView.leftAnchor).isActive = true
        bubbleView.rightAnchor.constraint(equalTo: photoView.rightAnchor).isActive = true
        
//        actionButton.topAnchor.constraint(equalTo: photoView.topAnchor).isActive = true
//        actionButton.bottomAnchor.constraint(equalTo: photoView.bottomAnchor).isActive = true
//        actionButton.leftAnchor.constraint(equalTo: photoView.leftAnchor).isActive = true
//        actionButton.rightAnchor.constraint(equalTo: photoView.rightAnchor).isActive = true

        downloadButton.centerXAnchor.constraint(equalTo: photoView.centerXAnchor).isActive = true
        downloadButton.centerYAnchor.constraint(equalTo: photoView.centerYAnchor).isActive = true
        downloadButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        downloadButton.widthAnchor.constraint(equalToConstant: 50).isActive = true

        uploadButton.centerXAnchor.constraint(equalTo: photoView.centerXAnchor).isActive = true
        uploadButton.centerYAnchor.constraint(equalTo: photoView.centerYAnchor).isActive = true
        uploadButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        uploadButton.widthAnchor.constraint(equalToConstant: 50).isActive = true

        playButton.centerXAnchor.constraint(equalTo: photoView.centerXAnchor).isActive = true
        playButton.centerYAnchor.constraint(equalTo: photoView.centerYAnchor).isActive = true
        playButton.heightAnchor.constraint(equalToConstant: 60).isActive = true
        playButton.widthAnchor.constraint(equalToConstant: 60).isActive = true

        progressView.centerXAnchor.constraint(equalTo: photoView.centerXAnchor).isActive = true
        progressView.centerYAnchor.constraint(equalTo: photoView.centerYAnchor).isActive = true
        progressView.heightAnchor.constraint(equalToConstant: 60).isActive = true
        progressView.widthAnchor.constraint(equalToConstant: 60).isActive = true

        fileSizeLabel.topAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: 2).isActive = true
    }
    
    deinit {
        actionButton.removeTarget(self, action: #selector(actionTapped), for: .touchUpInside)
    }


    @objc private func downloadButtonAction(_ selector: UIButton) {
        guard ALDataNetworkConnection.checkDataNetworkAvailable(), let viewModel = self.viewModel else {
            let notificationView = ALNotificationView()
            notificationView.noDataConnectionNotificationView()
            return
        }
        let downloadManager = ALKDownloadManager()
        downloadManager.delegate = self
        downloadManager.downloadVideo(message: viewModel)
        
    }

    @objc private func playButtonAction(_ selector: UIButton) {
        let storyboard = UIStoryboard.name(storyboard: UIStoryboard.Storyboard.mediaViewer, bundle: Bundle.applozic)

        let nav = storyboard.instantiateInitialViewController() as? UINavigationController
        let vc = nav?.viewControllers.first as? ALKMediaViewerViewController
        let dbService = ALMessageDBService()
        guard let messages = dbService.getAllMessagesWithAttachment(forContact: viewModel?.contactId, andChannelKey: viewModel?.channelKey, onlyDownloadedAttachments: true) as? [ALMessage] else { return }

        let messageModels = messages.map { $0.messageModel }
        NSLog("Messages with attachment: ", messages )

        guard let viewModel = viewModel as? ALKMessageModel,
            let currentIndex = messageModels.index(of: viewModel) else { return }
        vc?.viewModel = ALKMediaViewerViewModel(messages: messageModels, currentIndex: currentIndex)
        UIViewController.topViewController()?.present(nav!, animated: true, completion: {
            self.playButton.isEnabled = true
        })
    }

    @objc private func uploadButtonAction(_ selector: UIButton) {
        uploadTapped?(true)
    }

    fileprivate func updateView(for state: state) {
        switch state {
        case .download:
            uploadButton.isHidden = true
            downloadButton.isHidden = false
            photoView.image = UIImage(named: "VIDEO", in: Bundle.applozic, compatibleWith: nil)
            playButton.isHidden = true
            progressView.isHidden = true
        case .downloaded(let filePath):
            uploadButton.isHidden = true
            downloadButton.isHidden = true
            progressView.isHidden = true
            viewModel?.filePath = filePath
            playButton.isHidden = false
            let docDirPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let path = docDirPath.appendingPathComponent(filePath)
            photoView.image = getThumbnail(filePath: path)
        case .downloading(let progress, var _):
            // show progress bar
            print("downloading")
            uploadButton.isHidden = true
            downloadButton.isHidden = true
            progressView.isHidden = false
            progressView.angle = progress
            photoView.image = UIImage(named: "VIDEO", in: Bundle.applozic, compatibleWith: nil)
        case .upload:
            downloadButton.isHidden = true
            progressView.isHidden = true
            playButton.isHidden = true
            photoView.image = UIImage(named: "VIDEO", in: Bundle.applozic, compatibleWith: nil)
            uploadButton.isHidden = false

        }
    }

    fileprivate func updateDbMessageWith(key: String, value: String, filePath: String) {
        let messageService = ALMessageDBService()
        let alHandler = ALDBHandler.sharedInstance()
        let dbMessage: DB_Message = messageService.getMessageByKey(key, value: value) as! DB_Message
        dbMessage.filePath = filePath
        do {
            try alHandler?.managedObjectContext.save()
        } catch {
            NSLog("Not saved due to error")
        }
    }

    private func getThumbnail(filePath: URL) -> UIImage? {
        do {
            let asset = AVURLAsset(url: filePath , options: nil)
            let imgGenerator = AVAssetImageGenerator(asset: asset)
            imgGenerator.appliesPreferredTrackTransform = true
            let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(0, 1), actualTime: nil)
            return UIImage(cgImage: cgImage)

        } catch let error {
            print("*** Error generating thumbnail: \(error.localizedDescription)")
            return nil
        }
    }

    fileprivate func convertToDegree(total: Int64, written: Int64) -> Double {
        let divergence = Double(total)/360.0
        let degree = Double(written)/divergence
        return degree

    }
}

extension ALKVideoCell: ALKDownloadManagerDelegate {
    func dataUpdated(countCompletion: Int64) {
        NSLog("VIDEO CELL DATA UPDATED AND FILEPATH IS: %@", viewModel?.filePath ?? "")
        let total = self.viewModel?.size ?? 0
        let progress = self.convertToDegree(total: total, written: countCompletion)
        self.updateView(for: .downloading(progress: progress, totalCount: total))
    }
    
    func dataFinished(path: String) {
        guard !path.isEmpty, let viewModel = self.viewModel else {
            updateView(for: .download)
            return
        }
        self.updateDbMessageWith(key: "key", value: viewModel.identifier, filePath: path)
        updateView(for: .downloaded(filePath: path))
    }

    func dataUploaded(responseDictionary: Any?) {
        NSLog("VIDEO CELL DATA UPLOADED FOR PATH: %@ AND DICT: %@", viewModel?.filePath ?? "", responseDictionary.debugDescription)
        if responseDictionary == nil {
            updateView(for: .upload)
        } else if let filePath = viewModel?.filePath {
            updateView(for: state.downloaded(filePath: filePath))
        }
        uploadCompleted?(responseDictionary)
    }
}
