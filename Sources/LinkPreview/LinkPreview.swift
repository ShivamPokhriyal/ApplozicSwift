//
//  LinkPreview.swift
//  ApplozicSwift
//
//  Created by Shivam Pokhriyal on 17/03/20.
//

import Foundation

//😢 Have to make it a class, since NSCache doesn't allow storing structs.
class LinkPreview {
    var title: String?
    var description: String?
    var image: String?
    var icon: String?
    var url: URL?
}
