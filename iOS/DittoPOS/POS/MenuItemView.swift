///
//  MenuItemView.swift
//  DittoPOS
//
//  Created by Eric Turner on 6/16/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import SwiftUI

struct MenuItemView: View {
//    @Environment(\.colorScheme) private var colorScheme
    @State var titleScale: Double
    let item: MenuItem
    let length: CGFloat
    private let factor = 0.24
    
    init(_ item: MenuItem, length: CGFloat) {
        self.item = item
        self.length = length
        self._titleScale = .init(initialValue: length * factor)
    }
    
    var body: some View {
        VStack {
            Image(item.imageName)
                .resizable()
                
            ScalingText(item.title, scaleFactor: $titleScale)
        }
        .lineLimit(1)
        .onRotate { _ in
            titleScale = length * factor
        }
    }
}

struct ScalingText: View {
    @ScaledMetric var scale: CGFloat = 0.5
    @Binding var factor: Double
    let text: String
    
    init(_ text: String, scaleFactor: Binding<Double>) {
        self.text = text
        self._factor = scaleFactor
    }
    
    var body: some View {
        Text(text)
            .font(.system(size: factor * scale))
//            .foregroundColor(colorScheme == .dark ? .white : .black)
    }
}

struct MenuItemView_Previews: PreviewProvider {
    static var previews: some View {
        MenuItemView(MenuItem.demoItems.first!, length: 80)
    }
}
