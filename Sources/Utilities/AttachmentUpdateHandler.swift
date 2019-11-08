//
//  AttachmentUpdateHandler.swift
//  ApplozicSwift
//
//  Created by Shivam Pokhriyal on 18/09/19.
//

import Applozic

class AttachmentUpdateHandler: ALKHTTPManagerUploadDelegate, ALKHTTPManagerDownloadDelegate {
    var cellForTask: ((String?) -> ALKChatBaseCell<ALKMessageViewModel>?)?

    func dataUploaded(task: ALKUploadTask) {
        guard let cellForTask = cellForTask, let cell = cellForTask(task.identifier) else { return }
        let progress = task.totalBytesUploaded.degree(outOf: task.totalBytesExpectedToUpload)
        switch cell {
        case let view as ALKPhotoCell:
            view.updateView(for: .uploading(progress: progress))
        case let view as ALKVideoCell:
            view.updateView(for: .downloading(progress: progress, totalCount: task.totalBytesExpectedToUpload))
        default:
            print("Do nothing")
        }
    }

    func dataUploadingFinished(task: ALKUploadTask) {
        guard let cellForTask = cellForTask, let cell = cellForTask(task.identifier) else { return }
        if task.uploadError == nil, task.completed == true, task.filePath != nil {
            switch cell {
            case let view as ALKPhotoCell:
                view.updateView(for: .uploaded)
            case let view as ALKVideoCell:
                view.updateView(for: .downloaded(filePath: task.filePath ?? ""))
            default:
                print("Do nothing")
            }
        } else {
            switch cell {
            case let view as ALKPhotoCell:
                view.updateView(for: .upload(filePath: task.filePath ?? ""))
            case let view as ALKVideoCell:
                view.updateView(for: .upload)
            default:
                print("Do nothing")
            }
        }
    }

    func dataDownloaded(task: ALKDownloadTask) {
        guard let cellForTask = cellForTask, let cell = cellForTask(task.identifier) else { return }
        let progress = task.totalBytesDownloaded.degree(outOf: task.totalBytesExpectedToDownload)
        switch cell {
        case let view as ALKPhotoCell:
            // Return in case of thumbnail
            guard let identifier = task.identifier,
                !ThumbnailIdentifier.hasPrefix(in: identifier)
            else { return }
            view.updateView(for: .downloading(progress: progress))
        case let view as ALKVideoCell:
            view.updateView(for: .downloading(progress: progress, totalCount: task.totalBytesExpectedToDownload))
        default:
            print("Do nothing")
        }
    }

    func dataDownloadingFinished(task: ALKDownloadTask) {
        updateDBMessage(id: task.identifier, filePath: task.filePath)
        guard let cellForTask = cellForTask, let cell = cellForTask(task.identifier) else { return }
        /// Check if task is downloaded correctly otherwise return
        guard task.downloadError == nil,
            let filePath = task.filePath,
            let identifier = task.identifier
        else {
            switch cell {
            case let view as ALKPhotoCell:
                // Return in case of thumbnail
                guard let identifier = task.identifier,
                    !ThumbnailIdentifier.hasPrefix(in: identifier)
                else { return }
                view.updateView(for: .download)
            case let view as ALKVideoCell:
                view.updateView(for: .download)
            default:
                print("Do nothing")
            }
            return
        }

        guard !ThumbnailIdentifier.hasPrefix(in: identifier) else {
            if let cell = cell as? ALKPhotoCell {
                cell.setThumbnail(filePath)
            }
            return
        }
        switch cell {
        case let view as ALKPhotoCell:
            // Return in case of thumbnail
            guard let identifier = task.identifier,
                !ThumbnailIdentifier.hasPrefix(in: identifier)
            else { return }
            view.updateView(for: .downloaded(filePath: filePath))
        case let view as ALKVideoCell:
            view.updateView(for: .downloaded(filePath: filePath))
        default:
            print("Do nothing")
        }
    }

    func updateDBMessage(id: String?, filePath: String?) {
        guard let id = id, let filePath = filePath else { return }
        let dbService = ALMessageDBService()
        guard !ThumbnailIdentifier.hasPrefix(in: id) else {
            dbService.updateThumbnailPath(key: "key", value: id, filePath: filePath)
            return
        }
        dbService.updateDbMessageWith(key: "key", value: id, filePath: filePath)
    }
}
