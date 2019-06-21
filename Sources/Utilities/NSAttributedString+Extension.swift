//
//  NSAttributedString+Extension.swift
//  ApplozicSwift
//
//  Created by Shivam Pokhriyal on 21/06/19.
//

import Foundation

extension NSAttributedString {

    func heightWithConstrainedWidth(_ width: CGFloat) -> CGFloat {
        let size = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = boundingRect(
            with: size,
            options: .usesLineFragmentOrigin,
            context: nil)
        return ceil(boundingBox.height)
    }

}
