//
//  LinkPreviewFailure.swift
//  ApplozicSwift
//
//  Created by Shivam Pokhriyal on 17/03/20.
//

import Foundation

enum LinkPreviewFailure: Error {
    case noURLFound
    case invalidURL
    case cannotBeOpened
    case parseError
}
