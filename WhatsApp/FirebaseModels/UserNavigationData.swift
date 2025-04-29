//
//  UserNavigationData.swift
//  WhatsApp
//
//  Created by Abhinava Krishna on 25/04/25.
//

import Foundation


struct UserNavigationData: Hashable {
    
    static func == (lhs: UserNavigationData, rhs: UserNavigationData) -> Bool {
        return lhs.user == rhs.user && lhs.imageData == rhs.imageData
    }

    var user: FireUserModel
    var imageData: Data?
}
