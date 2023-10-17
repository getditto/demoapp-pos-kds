//
//  ProfileScreen.swift
//  DittoChat
//
//  Created by Maximilian Alexander on 7/20/22.
//

import SwiftUI

struct ProfileScreen: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var vm = ProfileScreenViewModel()

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

#if DEBUG
struct ProfileScreen_Previews: PreviewProvider {
    static var previews: some View {
        ProfileScreen()
    }
}
#endif
