//
//  CustomLocation.swift
//  DittoChat
//
//  Created by Maximilian Alexander on 7/20/22.
//

import Combine
import SwiftUI

@MainActor class CustomLocationVM: ObservableObject {
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
        DittoService.shared.saveCustomLocation(
            company: companyName.trimmingCharacters(in: .whitespacesAndNewlines),
            location: locationName.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
}

struct CustomLocationScreen: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var vm = CustomLocationVM()

    var body: some View {
        NavigationView {
            Form {
                Section("Company Name") {
                    TextField("company", text: $vm.companyName)
                }
                Section("Location Name") {
                    TextField("location", text: $vm.locationName)
                }
            }
            .autocorrectionDisabled()
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        vm.saveChanges()
                        dismiss()
                    } label: {
                        Text("Save")
                    }
                    .disabled(vm.saveButtonDisabled)
                }
            }
            .interactiveDismissDisabled(true)
        }
    }
}

struct CustomLocationScreen_Previews: PreviewProvider {
    static var previews: some View {
        CustomLocationScreen()
    }
}
