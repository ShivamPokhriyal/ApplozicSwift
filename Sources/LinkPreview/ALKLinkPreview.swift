import Foundation

public class ALKLinkPreview: NSObject, URLSessionDelegate {
    enum TextMinimumLength {
        static let title: Int = 15
        static let decription: Int = 100
    }

    private let workBckQueue: DispatchQueue
    private let responseMainQueue: DispatchQueue

    public init(workBckQueue: DispatchQueue = DispatchQueue.global(qos: .background),
                responseMainQueue: DispatchQueue = DispatchQueue.main) {
        self.workBckQueue = workBckQueue
        self.responseMainQueue = responseMainQueue
    }

    public func makePreview(from text: String, _ completion: @escaping (Result<LinkPreviewMeta, LinkPreviewFailure>) -> Void) {
        guard let url = ALKLinkPreview.extractURL(from: text) else {
            responseMainQueue.async {
                completion(.failure(.noURLFound))
            }
            return
        }

        workBckQueue.async {
            guard let url = url.scheme == "http" || url.scheme == "https" ? url : URL(string: "http://\(url)") else {
                self.responseMainQueue.async {
                    completion(.failure(.invalidURL))
                }
                return
            }

            let request = URLRequest(url: url)
            let session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
            session.dataTask(with: request) { [weak self] data, response, error in

                guard let weakSelf = self, error == nil else {
                    self?.responseMainQueue.async {
                        completion(.failure(.cannotBeOpened))
                    }
                    return
                }

                var linkPreview: LinkPreviewMeta?

                if let data = data, let urlResponse = response,
                    let encoding = urlResponse.textEncodingName,
                    let source = NSString(data: data, encoding: CFStringConvertEncodingToNSStringEncoding(CFStringConvertIANACharSetNameToEncoding(encoding as CFString))) {
                    linkPreview = weakSelf.parseHtml(text: source as String, baseUrl: url.absoluteString)

                } else {
                    guard let data = data, response != nil else {
                        return
                    }
                    let htmlString = String(data: data, encoding: .utf8)
                    linkPreview = weakSelf.parseHtml(text: htmlString, baseUrl: weakSelf.extractBaseUrl(url.absoluteString))
                }
                guard let linkPreviewData = linkPreview else {
                    completion(.failure(.noURLFound))
                    return
                }
                if let url = linkPreviewData.url?.absoluteString {
                    LinkURLCache.addLink(linkPreviewData, for: url)
                }
                weakSelf.responseMainQueue.async {
                    completion(.success(linkPreviewData))
                }

            }.resume()
        }
    }

    // MARK: - Private helpers

    private func cleanUnwantedTags(from html: String) -> String {
        return html.deleteTagByPattern(Regex.inlineStylePattern)
            .deleteTagByPattern(Regex.inlineScriptPattern)
            .deleteTagByPattern(Regex.scriptPattern)
            .deleteTagByPattern(Regex.commentPattern)
    }

    private func parseHtml(text: String?, baseUrl: String) -> LinkPreviewMeta? {
        guard let text = text else { return nil }
        let cleanHtml = cleanUnwantedTags(from: text)
        var result = LinkPreviewMeta()
        result.icon = parseIcon(in: text, baseUrl: baseUrl)
        result.url = URL(string: baseUrl)
        var linkFreeHtml = cleanHtml.deleteTagByPattern(Regex.linkPattern)

        parseMetaTags(in: &linkFreeHtml, result: &result)
        parseTitle(&linkFreeHtml, result: &result)
        parseDescription(linkFreeHtml, result: &result)
        return result
    }

    private func parseMetaTags(in text: inout String, result: inout LinkPreviewMeta) {
        let tags = Regex.pregMatchAll(text, pattern: Regex.metatagPattern, index: 1)

        let possibleTags: [String] = [
            LinkPreviewMeta.Key.title.rawValue,
            LinkPreviewMeta.Key.description.rawValue,
            LinkPreviewMeta.Key.image.rawValue,
        ]
        for metatag in tags {
            for tag in possibleTags {
                if metatag.range(of: "property=\"og:\(tag)") != nil ||
                    metatag.range(of: "property='og:\(tag)") != nil ||
                    metatag.range(of: "name=\"twitter:\(tag)") != nil ||
                    metatag.range(of: "name='twitter:\(tag)") != nil ||
                    metatag.range(of: "name=\"\(tag)") != nil ||
                    metatag.range(of: "name='\(tag)") != nil ||
                    metatag.range(of: "itemprop=\"\(tag)") != nil ||
                    metatag.range(of: "itemprop='\(tag)") != nil {
                    if let key = LinkPreviewMeta.Key(rawValue: tag),
                        result.value(for: key) == nil {
                        if let value = Regex.pregMatchFirst(metatag, pattern: Regex.metatagContentPattern, index: 2) {
                            let value = value.decodedHtml.extendedTrim
                            if tag == "image" {
                                if let urlString = result.url?.absoluteString {
                                    let value = handleImagePrefixAndSuffix(value, baseUrl: urlString)
                                    if Regex.isMatchFound(value, regex: Regex.imagePattern) { result.set(value, for: key) }
                                }
                            } else {
                                result.set(value, for: key)
                            }
                        }
                    }
                }
            }
        }
    }

    private func parseIcon(in text: String, baseUrl: String) -> String? {
        let links = Regex.pregMatchAll(text, pattern: Regex.linkPattern, index: 1)
        let filters = [
            { (link: String) -> Bool in link.range(of: "apple-touch") != nil },
            { (link: String) -> Bool in link.range(of: "shortcut") != nil },
            { (link: String) -> Bool in link.range(of: "icon") != nil },
        ]
        for filter in filters {
            guard let link = links.filter(filter).first else { continue }
            if let matches = Regex.pregMatchFirst(link, pattern: Regex.hrefPattern, index: 1) {
                return handleImagePrefixAndSuffix(matches, baseUrl: baseUrl)
            }
        }
        return nil
    }

    private func parseTitle(_ htmlCode: inout String, result: inout LinkPreviewMeta) {
        let title = result.title
        if title == nil || title?.isEmpty ?? true {
            if let value = Regex.pregMatchFirst(htmlCode, pattern: Regex.titlePattern, index: 2) {
                if value.isEmpty {
                    let data: String = getTagData(htmlCode, minimum: TextMinimumLength.title)
                    if !data.isEmpty {
                        result.title = data.decodedHtml.extendedTrim
                        htmlCode = htmlCode.replace(data, with: "")
                    }
                } else {
                    result.title = value.decodedHtml.extendedTrim
                }
            }
        }
    }

    private func parseDescription(_ htmlCode: String, result: inout LinkPreviewMeta) {
        let description = result.description

        if description == nil || description?.isEmpty ?? true {
            let value: String = getTagData(htmlCode, minimum: TextMinimumLength.decription)
            if !value.isEmpty {
                result.description = value.decodedHtml.extendedTrim
            }
        }
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
    class func extractURL(from text: String?) -> URL? {
        guard let message = text else {
            return nil
        }
        do {
            let detector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
            let range = NSRange(location: 0, length: message.utf16.count)
            let matches = detector.matches(in: message, options: [], range: range)
            return matches.compactMap { $0.url }.first
        } catch {
            return nil
        }
    }

    private func getTagData(_ content: String, minimum: Int) -> String {
        let paragraphTagData = getTagContent("p", content: content, minimum: minimum)

        if !paragraphTagData.isEmpty {
            return paragraphTagData
        } else {
            let devTagData = getTagContent("div", content: content, minimum: minimum)
            if !devTagData.isEmpty {
                return devTagData
            } else {
                let spanTagData = getTagContent("span", content: content, minimum: minimum)
                if !spanTagData.isEmpty {
                    return spanTagData
                }
            }
        }
        return ""
    }

    private func getTagContent(_ tag: String, content: String, minimum: Int) -> String {
        let pattern = Regex.tagPattern(tag)

        let index = 2
        let rawMatches = Regex.pregMatchAll(content, pattern: pattern, index: index)

        let matches = rawMatches.filter { $0.extendedTrim.deleteTagByPattern(Regex.rawTagPattern).count >= minimum }
        var result = !matches.isEmpty ? matches[0] : ""

        if result.isEmpty {
            if let match = Regex.pregMatchFirst(content, pattern: pattern, index: 2) {
                result = match.extendedTrim.deleteTagByPattern(Regex.rawTagPattern)
            }
        }
        return result
    }
}

extension String {
    func deleteTagByPattern(_ pattern: String) -> String {
        return replacingOccurrences(of: pattern, with: "", options: .regularExpression, range: nil)
    }

    var extendedTrim: String {
        let components = self.components(separatedBy: CharacterSet.whitespacesAndNewlines)
        return components.filter { !$0.isEmpty }.joined(separator: " ").trim()
    }

    var decodedHtml: String {
        let encodedData = data(using: String.Encoding.utf8)!
        let attributedOptions: [NSAttributedString.DocumentReadingOptionKey: Any] =
            [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: NSNumber(value: String.Encoding.utf8.rawValue),
            ]
        do {
            let attributedString = try NSAttributedString(data: encodedData, options: attributedOptions, documentAttributes: nil)
            return attributedString.string

        } catch _ {
            return self
        }
    }

    func replace(_ search: String, with: String) -> String {
        let replaced: String = replacingOccurrences(of: search, with: with)
        return replaced.isEmpty ? self : replaced
    }
}
