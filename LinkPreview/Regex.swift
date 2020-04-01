import Foundation

class Regex {
    static let imagePattern = "(.+?)\\.(gif|jpg|jpeg|png|bmp)$"
    static let videoTagPattern = "<video[^>]+src=\"([^\"]+)"
    static let imageTagPattern = "<img(.+?)src=\"([^\"](.+?))\"(.+?)[/]?>"
    static let titlePattern = "<title(.*?)>(.*?)</title>"
    static let metatagPattern = "<meta(.*?)>"
    static let metatagContentPattern = "content=(\"(.*?)\")|('(.*?)')"
    static let cannonicalUrlPattern = "([^\\+&#@%\\?=~_\\|!:,;]+)"
    static let rawTagPattern = "<[^>]+>"
    static let inlineStylePattern = "<style(.*?)>(.*?)</style>"
    static let inlineScriptPattern = "<script(.*?)>(.*?)</script>"
    static let linkPattern = "<link(.*?)>"
    static let scriptPattern = "<script(.*?)>"
    static let commentPattern = "<!--(.*?)-->"
    static let hrefPattern = ".*href=\"(.*?)\".*"
    static let pricePattern = "itemprop=\"price\" content=\"([^\"]*)\""

    // Check the regular expression
    static func isMatchFound(_ string: String, regex: String) -> Bool {
        return Regex.pregMatchFirst(string, pattern: regex) != nil
    }

    // Match first occurrency
    static func pregMatchFirst(_ string: String, pattern: String, index: Int = 0) -> String? {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
            let range = NSRange(string.startIndex ..< string.endIndex, in: string)
            guard let match = regex.firstMatch(in: string, options: [], range: range) else {
                return nil
            }
            let result: [String] = Regex.stringMatches([match], text: string, index: index)
            return result.isEmpty ? nil : result[0]
        } catch {
            return nil
        }
    }

    // Match all occurrencies
    static func pregMatchAll(_ string: String, pattern: String, index: Int = 0) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
            let range = NSRange(string.startIndex ..< string.endIndex, in: string)
            let matches = regex.matches(in: string, options: [], range: range)
            return !matches.isEmpty ? Regex.stringMatches(matches, text: string, index: index) : []
        } catch {
            return []
        }
    }

    // Extract matches from string
    static func stringMatches(_ results: [NSTextCheckingResult], text: String, index: Int = 0) -> [String] {
        return results.map {
            let range = $0.range(at: index)
            if text.count > range.location + range.length {
                return (text as NSString).substring(with: range)
            } else {
                return ""
            }
        }
    }

    // Return tag pattern
    // Creates this pattern :: <tagName ...>...</tagName>
    static func tagPattern(_ tag: String) -> String {
        return "<" + tag + "(.*?)>(.*?)</" + tag + ">"
    }
}
