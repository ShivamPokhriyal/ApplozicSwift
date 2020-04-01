import Foundation

class LinkURLCache {
    private static let cache = NSCache<NSString, LinkPreviewResponse>()

    static func getLink(for url: String) -> LinkPreviewResponse? {
        return cache.object(forKey: url as NSString)
    }

    static func addLink(_ link: LinkPreviewResponse, for url: String) {
        cache.setObject(link, forKey: url as NSString)
    }
}
