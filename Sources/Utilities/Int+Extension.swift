//
//  Int+Extension.swift
//  ApplozicSwift
//
//  Created by Shivam Pokhriyal on 31/07/19.
//

import Foundation

extension Int64 {
    func degree(outOf: Int64) -> Double {
        return Double( self * 360 / outOf )
    }
}
