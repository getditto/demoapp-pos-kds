//
//  ProfileScreenViewModel.swift
//  DittoPOS
//
//  Created by Eric Turner on 10/11/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import Combine
import Foundation
/*
class ProfileScreenViewModel: ObservableObject {
    @Published var companyName: String = ""
    @Published var locationName: String = ""
    @Published var saveButtonDisabled = false
    
    init() {
        $companyName.combineLatest($locationName)
            .map { companyName, locationName -> Bool in
                return companyName.isEmpty || locationName.isEmpty
            }
            .assign(to: &$saveButtonDisabled)
    }

    func saveChanges() {
        DittoService.shared.saveUser(
            company: companyName.trimmingCharacters(in: .whitespacesAndNewlines),
            location: locationName.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
}
*/
