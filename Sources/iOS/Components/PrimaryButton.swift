//
//  PrimaryButton.swift
//  Wasmic
//
//  Created by kateinoigakukun on 2021/04/11.
//

import SwiftUI

public struct PrimaryButton<Content: View>: View {
    let action: () -> Void
    let createLabel: () -> Content
    let color: Color

    public init(
        action: @escaping () -> Void,
        label: @escaping () -> Content,
        color: Color = .blue
    ) {
        self.action = action
        createLabel = label
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
        RoundedRectangle(cornerRadius: 8, style: .circular)
            .fill(color)
    }
}
