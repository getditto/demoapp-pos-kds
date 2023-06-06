///
//  ContentView.swift
//  DittoBase
//
//  Created by Eric Turner on 6/6/23.
//
//  Copyright © 2023 ___ORGANIZATIONNAME___. All rights reserved.

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Hello, world!")
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
