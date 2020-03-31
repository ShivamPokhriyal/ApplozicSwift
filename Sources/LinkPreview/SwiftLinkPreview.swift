//
//  SwiftLinkPreview.swift
//  ApplozicSwift
//
//  Created by Shivam Pokhriyal on 17/03/20.
//

import Foundation

class SwiftLinkPreview: NSObject, URLSessionDelegate {

    private let workBckQueue: DispatchQueue
    private let responseMainQueue: DispatchQueue

    init(workBckQueue: DispatchQueue = DispatchQueue.global(qos: .background),
         responseMainQueue: DispatchQueue = DispatchQueue.main) {
        self.workBckQueue = workBckQueue
        self.responseMainQueue = responseMainQueue
    }

    func makePreview(from text: String, _ completion: @escaping (Result<LinkPreview, LinkPreviewFailure>) -> Void) {
        guard let url = extractURL(from: text) else { 
            completion(.failure(.noURLFound))
            return
        }
        workBckQueue.async {
            guard let url = url.scheme == "http" || url.scheme == "https" ? url : URL(string: "http://\(url)") else { 
                completion(.failure(.invalidURL))
                return
            }
            let request = URLRequest(url: url)
            let session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
            session.dataTask(with: request) { [weak self] data, response, error in
                guard let weakSelf = self, error == nil, let data = data, let response = response else {
                    completion(.failure(.cannotBeOpened))
                    return
                }
                let htmlString = String(data: data, encoding: .utf8)
                weakSelf.parseHtml(text: htmlString, baseUrl: weakSelf.extractBaseUrl(url.absoluteString))
            }
        }
    }
    
    //MARK:- Private helpers
    
    private func cleanUnwantedTags(from html: String) -> String {
        return html.deleteTagByPattern(Regex.inlineStylePattern)
            .deleteTagByPattern(Regex.inlineScriptPattern)
            .deleteTagByPattern(Regex.scriptPattern)
            .deleteTagByPattern(Regex.commentPattern)
    }
    
    private func parseHtml(text: String?, baseUrl: String) {
        guard let text = text else { return }
        let cleanHtml = cleanUnwantedTags(from: text)
        let result = LinkPreview()
        result.icon = parseIcon(in: text, baseUrl: baseUrl)
        result.url = URL(string: baseUrl)
        let linkFreeHtml = cleanHtml.deleteTagByPattern(Regex.linkPattern)
        
    }
    
    private func parseMetaTags(in text: String, result: inout LinkPreview) {
        let tags = Regex.pregMatchAll(text, pattern: Regex.metatagPattern, index: 1)
    }
    
    private func parseIcon(in text: String, baseUrl: String) -> String? {
        let links = Regex.pregMatchAll(text, pattern: Regex.linkPattern, index: 1)
        let filters = [
        { (link: String) -> Bool in link.range(of: "apple-touch") != nil },
        { (link: String) -> Bool in link.range(of: "shortcut") != nil },
        { (link: String) -> Bool in link.range(of: "icon") != nil }
        ]
        for filter in filters {
            guard let link = links.filter(filter).first else { continue }
            if let matches = Regex.pregMatchFirst(link, pattern: Regex.hrefPattern, index: 1) {
                return handleImagePrefixAndSuffix(matches, baseUrl: baseUrl)
            }
        }
        return nil
    }
    
    private func handleImagePrefixAndSuffix(_ image: String, baseUrl: String) -> String {
        var url = image
        if let index = image.firstIndex(of: "?") {
            url = String(image[..<index])
        }
        guard !url.starts(with: "http") else { return url }
        if url.starts(with: "//") {
            return "http:" + url
        } else if url.starts(with: "/") { 
            return "http://" + baseUrl + url
        } else {
            return url
        }
    }
    
    /// Returns the base url to the given url.
    /// The following examples show how it works.
    ///     let url = "http://www.github.com/Applozic/ApplozicSwift"
    ///     // Returns "www.github.com"
    private func extractBaseUrl(_ url: String) -> String {
        let finalUrl = url.replacingOccurrences(of: "http://", with: "")
            .replacingOccurrences(of: "https://", with: "")
        return String(finalUrl.split(separator: "/", maxSplits: 1, omittingEmptySubsequences: true)[0])
    }
    
    /// Returns the very first url encountered in the text. 
    /// - Parameter text: text from which url is to be search
    private func extractURL(from text: String) -> URL? {
        do {
            let detector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
            let range = NSRange(location: 0, length: text.utf16.count)
            let matches = detector.matches(in: text, options: [], range: range)
            return matches.compactMap { $0.url }.first
        } catch {
            return nil
        }
    }
}

extension String {
    func deleteTagByPattern(_ pattern: String) -> String {
        return self.replacingOccurrences(of: pattern, with: "", options: .regularExpression, range: nil)
    }
}
