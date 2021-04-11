//
//  ShortcutsNote.swift
//  Wasmic
//
//  Created by kateinoigakukun on 2021/04/11.
//

import SwiftUI
import UIKit

final class ShortcutsNoteViewController: UIHostingController<ShortcutsNote> {
    init(openShortcutsApp: @escaping () -> Void) {
        super.init(rootView: ShortcutsNote(openShortcutsApp: openShortcutsApp))
    }
    @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct ShortcutsNote: View {
    let openShortcutsApp: () -> Void
    var body: some View {
        VStack {
            Spacer().frame(minHeight: 0, maxHeight: 64)
            Text("shortcuts-note.title")
                .font(.title)
                .bold()
                .padding([.top, .bottom], 30)
            Image(systemName: "bolt.fill")
                .resizable()
                .foregroundColor(.blue)
                .aspectRatio(nil, contentMode: .fit)
                .frame(width: 40)
                .scaledToFill()
                .padding()

            VStack {
                Text("shortcuts-note.headline")
                    .bold().font(.headline)

                Spacer().frame(height: 16)
                Text("shortcuts-note.subheadline")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Spacer().frame(height: 16)

                Text("shortcuts-note.footnote")
                    .font(.footnote)
            }
            .multilineTextAlignment(.center)
            .padding([.leading, .trailing])

            PrimaryButton(
                action: openShortcutsApp,
                label: { Text("shortcuts-note.open-shortcuts") }
            )
            .padding()
            Spacer()
        }
    }
}

struct ShortcutsNote_Previews: PreviewProvider {

    static var previews: some View {
        Group {
            ShortcutsNote(openShortcutsApp: {})
            ShortcutsNote(openShortcutsApp: {})
                .environment(\.colorScheme, ColorScheme.dark)
                .background(Color.black)
            ShortcutsNote(openShortcutsApp: {})
                .previewLayout(.fixed(width: 2532 / 3.0, height: 1170 / 3.0))
                .environment(\.horizontalSizeClass, .regular)
                .environment(\.verticalSizeClass, .compact)
        }
    }
}
