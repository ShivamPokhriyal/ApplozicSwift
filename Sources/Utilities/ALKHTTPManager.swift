//
//  ALKHTTPManager.swift
//  ApplozicSwift
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import Applozic
import Foundation

protocol ALKHTTPManagerUploadDelegate: AnyObject {
    func dataUploaded(task: ALKUploadTask)
    func dataUploadingFinished(task: ALKUploadTask)
}

protocol ALKHTTPManagerDownloadDelegate: AnyObject {
    func dataDownloaded(task: ALKDownloadTask)
    func dataDownloadingFinished(task: ALKDownloadTask)
}

struct ThumbnailIdentifier {
    static let prefix = "THUMBNAIL_"

    static func hasPrefix(in identifier: String) -> Bool {
        return identifier.hasPrefix(prefix)
    }

    static func addPrefix(to identifier: String) -> String {
        return prefix + identifier
    }

    static func removePrefix(from identifier: String) -> String {
        guard hasPrefix(in: identifier) else { return identifier }
        return String(identifier.dropFirst(prefix.count))
    }
}

class SessionQueue {
    
    public static let shared = SessionQueue()
    private var queue = [URLSession]()

    private init() { }

    public func getAllSessions() -> [URLSession] {
        return queue
    }

    public func addSession(_ session: URLSession) {
        queue.append(session)
    }

    public func containsSession(_ session: URLSession) -> Bool {
        return queue.contains(session)
    }

    public func removeSession(_ session: URLSession) {
        queue.remove(object: session)
    }

    public func containsSession(withIdentifier: String) -> Bool {
        for session in queue {
            let config = session.configuration
            guard let id = config.identifier else { continue }
            if id.contains(withIdentifier) {
                return true
            }
        }
        return false
    }

    public func cancelSession(withIdentifier: String) -> Bool {
        for session in queue {
            let config = session.configuration
            guard let id = config.identifier else { continue }
            if id.contains(withIdentifier) {
                session.invalidateAndCancel()
                return true
            }
        }
        return false
    }

}

class ALKHTTPManager: NSObject {
    static let semaphore = DispatchSemaphore(value: 2)
    static let shared = ALKHTTPManager()
    weak var downloadDelegate: ALKHTTPManagerDownloadDelegate?
    weak var uploadDelegate: ALKHTTPManagerUploadDelegate?
    var uploadCompleted: ((_ responseDict: Any?, _ task: ALKUploadTask) -> Void)?
    var downloadCompleted: ((_ task: ALKDownloadTask) -> Void)?

    var length: Int64 = 0
    var buffer: NSMutableData = NSMutableData()
    var session: URLSession?
    var uploadTask: ALKUploadTask?
    var downloadTask: ALKDownloadTask?

    struct Constants {
        static let thumbnailSuffix = "thumbnail_local"
        static let attachmentSuffix = "local"
        static let paramForS3Storage = "file"
        static let paramForDefaultStorage = "files[]"
    }

    func upload(image: UIImage, uploadURL: URL, completion: @escaping (_ imageLink: Data?) -> Void) {
        guard var request = ALRequestHandler.createPOSTRequest(withUrlString: uploadURL.path, paramString: nil) as URLRequest? else { return }

        let boundary = "------ApplogicBoundary4QuqLuM1cE5lMwCy"
        let contentType = String(format: "multipart/form-data; boundary=%@", boundary)
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        var body = Data()
        let fileParamConstant = "file"
        let imageData = image.pngData()

        if let data = imageData as Data? {
            print("data present")
            body.append(String(format: "--%@\r\n", boundary).data(using: .utf8)!)
            body.append(String(format: "Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", fileParamConstant, "imge_123_profile").data(using: .utf8)!)
            body.append(String(format: "Content-Type:%@\r\n\r\n", "image/jpeg").data(using: .utf8)!)
            body.append(data)
            body.append(String(format: "\r\n").data(using: .utf8)!)
        }

        body.append(String(format: "--%@--\r\n", boundary).data(using: .utf8)!)
        request.httpBody = body
        request.url = uploadURL

        let task = URLSession.shared.dataTask(with: request) {
            data, _, error in
            if error == nil {
                completion(data)
            } else {
                completion(nil)
            }
        }
        task.resume()
    }

    func downloadAttachment(task: ALKDownloadTask) {
        downloadTask = task
        guard let urlString = task.urlString, let fileName = task.fileName, let identifier = task.identifier else { return }
        guard !SessionQueue.shared.containsSession(withIdentifier: identifier) else {
            print("Downloading already in queue")
            return
        }
        let componentsArray = fileName.components(separatedBy: ".")
        let fileExtension = componentsArray.last
        let filePath = getFilePath(using: identifier, with: fileExtension!)
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]

        if NSData(contentsOfFile: documentsURL.appendingPathComponent(filePath).path) != nil, let downloadTask = self.downloadTask {
            downloadTask.filePath = filePath
            downloadTask.completed = true
            downloadTask.isDownloading = false
            downloadCompleted?(downloadTask)
            downloadDelegate?.dataDownloadingFinished(task: downloadTask)
        } else {
            DispatchQueue.global(qos: .default).async {
                let configuration = URLSessionConfiguration.background(withIdentifier: identifier)
                guard !urlString.isEmpty else { return }
                let serviceEnabled = ALApplozicSettings.isS3StorageServiceEnabled() || ALApplozicSettings.isGoogleCloudServiceEnabled()
                guard let urlRequest = serviceEnabled ? ALRequestHandler.createGETRequest(withUrlStringWithoutHeader: urlString, paramString: nil) :
                    ALRequestHandler.createGETRequest(withUrlString: urlString, paramString: nil) else { return }
                let session = URLSession(configuration: configuration, delegate:self, delegateQueue: nil)
                self.startSession(session, request: urlRequest as URLRequest)
            }
        }
    }

    /// Used to download image directly using the url in `task`.
    ///
    /// No headers are sent with the call.
    func downloadImage(task: ALKDownloadTask) {
        downloadTask = task
        guard let urlString = task.urlString, let fileName = task.fileName, let identifier = task.identifier else { return }
        guard !SessionQueue.shared.containsSession(withIdentifier: identifier) else {
            print("Image downloading already in queue")
            return
        }
        let componentsArray = fileName.components(separatedBy: ".")
        let fileExtension = componentsArray.last
        let filePath = getFilePath(using: identifier, with: fileExtension!)
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]

        if NSData(contentsOfFile: documentsURL.appendingPathComponent(filePath).path) != nil, let downloadTask = self.downloadTask {
            downloadTask.filePath = filePath
            downloadTask.completed = true
            downloadTask.isDownloading = false
            downloadCompleted?(downloadTask)
            downloadDelegate?.dataDownloadingFinished(task: downloadTask)
        } else {
            DispatchQueue.global(qos: .default).async {
                let configuration = URLSessionConfiguration.background(withIdentifier: identifier)
                guard !urlString.isEmpty, let url = URL(string: urlString) else { return }
                let session = URLSession(configuration: configuration, delegate:self, delegateQueue: nil)
                self.startSession(session, request: URLRequest(url: url))
            }
        }
    }

    func uploadAttachment(task: ALKUploadTask) {
        guard let identifier = task.identifier else { return }
        self.uploadTask = task
        let docDirPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let imageFilePath = task.filePath
        let filePath = docDirPath.appendingPathComponent(imageFilePath ?? "")

        guard var request = ALRequestHandler.createPOSTRequest(withUrlString: task.url?.description, paramString: nil) as URLRequest? else { return }
        if FileManager.default.fileExists(atPath: filePath.path) {
            DispatchQueue.global(qos: .default).async {
                let boundary = "------ApplogicBoundary4QuqLuM1cE5lMwCy"
                let contentType = String(format: "multipart/form-data; boundary=%@", boundary)
                request.setValue(contentType, forHTTPHeaderField: "Content-Type")
                var body = Data()
                let fileParamConstant = ALApplozicSettings.isS3StorageServiceEnabled() ? Constants.paramForS3Storage : Constants.paramForDefaultStorage
                let imageData = NSData(contentsOfFile: filePath.path)

                if let data = imageData as Data? {
                    print("data present")
                    body.append(String(format: "--%@\r\n", boundary).data(using: .utf8)!)
                    body.append(String(format: "Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", fileParamConstant,task.fileName ?? "").data(using: .utf8)!)
                    body.append(String(format: "Content-Type:%@\r\n\r\n", task.contentType ?? "").data(using: .utf8)!)
                    body.append(data)
                    body.append(String(format: "\r\n").data(using: .utf8)!)
                }

                body.append(String(format: "--%@--\r\n", boundary).data(using: .utf8)!)
                request.httpBody = body
                request.url = task.url

                guard !SessionQueue.shared.containsSession(withIdentifier: identifier) else {
                    print("Session upload already in queue")
                    return
                }
                let configuration = URLSessionConfiguration.background(withIdentifier: identifier)
                let session = URLSession(configuration: configuration, delegate:self, delegateQueue: nil)
                self.startSession(session, request: request)
            }
        }
    }

    private func startSession(_ session: URLSession, request: URLRequest) {
        SessionQueue.shared.addSession(session)
        ALKHTTPManager.semaphore.wait()
        guard SessionQueue.shared.containsSession(session) else {
            ALKHTTPManager.semaphore.signal()
            return
        }
        let task = session.dataTask(with: request)
        task.resume()
    }

    fileprivate func getFilePath(using identifier: String, with fileExtension: String) -> String {
        let format = ThumbnailIdentifier.hasPrefix(in: identifier) ? Constants.thumbnailSuffix : Constants.attachmentSuffix
        let key = ThumbnailIdentifier.removePrefix(from: identifier)
        return String(format: "%@_\(format).%@", key, fileExtension)
    }

    private func save(data: Data, to url: URL) -> String? {
        do {
            try data.write(to: url)
            return url.path
        } catch {
            print(error)
            return nil
        }
    }
}

extension ALKHTTPManager: URLSessionDataDelegate {
    func urlSession(_: URLSession, dataTask _: URLSessionDataTask, didReceive _: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Swift.Void) {
        completionHandler(URLSession.ResponseDisposition.allow)
    }

    func urlSession(_: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        if let downloadTask = downloadTask {
            buffer.append(data)
            DispatchQueue.main.async {
                downloadTask.isDownloading = true
                downloadTask.totalBytesDownloaded = Int64(self.buffer.length)
                self.downloadCompleted?(downloadTask)
                self.downloadDelegate?.dataDownloaded(task: downloadTask)
            }
        } else {
            guard let response = dataTask.response as? HTTPURLResponse, response.statusCode == 200 else {
                NSLog("UPLOAD ERROR: %@", dataTask.error.debugDescription)
                return
            }
            guard let uploadTask = self.uploadTask else { return }
            do {
                let responseDictionary = try JSONSerialization.jsonObject(with: data)
                print("success == \(responseDictionary)")

                DispatchQueue.main.async {
                    uploadTask.completed = true
                    self.uploadCompleted?(responseDictionary, uploadTask)
                    self.uploadDelegate?.dataUploadingFinished(task: uploadTask)
                }
            } catch {
                print(error)
                let responseString = String(data: data, encoding: .utf8)
                print("responseString = \(String(describing: responseString))")
                DispatchQueue.main.async {
                    uploadTask.uploadError = error
                    uploadTask.completed = true
                    self.uploadCompleted?(nil, uploadTask)
                    self.uploadDelegate?.dataUploadingFinished(task: uploadTask)
                }
            }
            ALKHTTPManager.semaphore.signal()
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        SessionQueue.shared.removeSession(session)
        ALKHTTPManager.semaphore.signal()
        guard let downloadTask = self.downloadTask, let fileName = downloadTask.fileName, let identifier = downloadTask.identifier else { return }
        guard error == nil else {
            DispatchQueue.main.async {
                downloadTask.filePath = ""
                downloadTask.completed = true
                downloadTask.downloadError = error
                downloadTask.isDownloading = false
                self.downloadCompleted?(downloadTask)
                self.downloadDelegate?.dataDownloadingFinished(task: downloadTask)
            }
            return
        }
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let componentsArray = fileName.components(separatedBy: ".")
        let fileExtension = componentsArray.last
        let filePath = getFilePath(using: identifier, with: fileExtension!)
        let url = documentsURL.appendingPathComponent(filePath)
        let path = url.path

        if let compressedData = compressData(buffer, for: identifier) {
            do {
                try compressedData.write(to: url, options: .atomic)
            } catch {
                print("Error while saving compressed data \(error.localizedDescription)")
                /// Try saving complete data now.
                buffer.write(toFile: path, atomically: true)
            }
        } else {
            /// This is needed since the attachment data is already downloaded and
            /// we failed/(don't want) to compress it.
            buffer.write(toFile: path, atomically: true)
        }
        DispatchQueue.main.async {
            downloadTask.filePath = filePath
            downloadTask.completed = true
            downloadTask.isDownloading = false
            self.downloadCompleted?(downloadTask)
            self.downloadDelegate?.dataDownloadingFinished(task: downloadTask)
        }
        buffer.resetBytes(in: NSRange(location: 0, length: buffer.length))
    }

    func urlSession(_: URLSession, task _: URLSessionTask, didSendBodyData _: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        length += totalBytesSent
        guard let uploadTask = self.uploadTask else { return }
        NSLog("Did send data: \(totalBytesSent) out of total: \(totalBytesExpectedToSend)")
        uploadTask.totalBytesUploaded = totalBytesSent
        uploadTask.totalBytesExpectedToUpload = totalBytesExpectedToSend
        DispatchQueue.main.async {
            self.uploadDelegate?.dataUploaded(task: uploadTask)
        }
    }

    private func compressData(_ data: NSData, for identifier: String) -> Data? {
        let messageKey = ThumbnailIdentifier.removePrefix(from: identifier)
        /// Compression is required only for image
        guard
            let message = ALMessageDBService().getMessageByKey(messageKey),
            message.fileMeta.contentType.contains("image")
            else {
                return nil
        }

        /// Compress data
        guard let compressedData = ALUtilityClass.compressImage(data as Data) else {
            return nil
        }
        return compressedData
    }

}
