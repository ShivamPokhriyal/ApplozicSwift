import Foundation

public class LinkPreviewResponse {
    public var title: String?
    public var description: String?
    public var image: String?
    public var icon: String?
    public var url: URL?
}

extension LinkPreviewResponse {
    enum Key: String {
        case url
        case title
        case description
        case image
        case icon
    }

    func set(_ value: Any, for key: Key) {
        switch key {
        case Key.url:
            if let value = value as? URL { url = value }
        case Key.title:
            if let value = value as? String { title = value }
        case Key.description:
            if let value = value as? String { description = value }
        case Key.image:
            if let value = value as? String { image = value }
        case Key.icon:
            if let value = value as? String { icon = value }
        }
    }

    func value(for key: Key) -> Any? {
        switch key {
        case Key.url:
            return url
        case Key.title:
            return title
        case Key.description:
            return description
        case Key.image:
            return image
        case Key.icon:
            return icon
        }
    }
}
