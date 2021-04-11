//
//  PrimaryButton.swift
//  Wasmic
//
//  Created by kateinoigakukun on 2021/04/11.
//

import SwiftUI

public struct PrimaryButton<Content: View>: View {
    @Environment(\.isEnabled) private var isEnabled
    let action: () -> Void
    let createLabel: () -> Content
    let color: Color

    public init(
        action: @escaping () -> Void,
        label: @escaping () -> Content,
        color: Color = Color(.systemIndigo)
    ) {
        self.action = action
        self.createLabel = label
        self.color = color
    }

    public var body: some View {
        Button(action: action, label: { label })
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .background(background)
    }

    var label: some View {
        self.createLabel()
            .frame(maxWidth: 320, alignment: .center)
    }

    var background: some View {
        RoundedRectangle(cornerRadius: 14, style: .circular)
            .fill(isEnabled ? color : Color.gray)
    }
}

struct PrimaryButton_Previews: PreviewProvider {
    static var previews: some View {
        PrimaryButton(action: {}, label: { Text("Hello") })
            .background(Color.black)
    }
}
