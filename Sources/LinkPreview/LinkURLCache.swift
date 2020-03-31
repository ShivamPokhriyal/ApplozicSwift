//
//  URLCache.swift
//  ApplozicSwift
//
//  Created by Shivam Pokhriyal on 17/03/20.
//

import Foundation

class LinkURLCache {
    private static let cache = NSCache<NSString, LinkPreview>()
    
    static func getLink(for url: String) -> LinkPreview? {
        return cache.object(forKey: url as NSString)
    }
    
    static func addLink(_ link: LinkPreview, for url: String) {
        cache.setObject(link, forKey: url as NSString)
    }
}
