//
//  ALContact+Extension.swift
//  
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import Foundation
import Applozic

extension ALContact: ALKContactProtocol {
    var friendUUID: String? {
        return self.userId
    }

    var friendDisplayImgURL: URL? {
        guard let imageUrl = self.contactImageUrl, let url = URL(string: imageUrl) else {
        return nil
        }
        return url
    }

    var friendProfileName: String? {
        if let name = getDisplayName(), !name.isEmpty {
            return name
        } else {
            return userId
        }
    }

    var friendMood: String? {
        return nil
    }
}
