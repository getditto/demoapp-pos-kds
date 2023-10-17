///
//  User.swift
//  DittoPOS
//
//  Created by Eric Turner on 10/11/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import Foundation

struct User: Codable {
    let companyName: String
    let locationName: String
    var locationId: String {
        "\(companyName)-\(locationName)"
    }
}
