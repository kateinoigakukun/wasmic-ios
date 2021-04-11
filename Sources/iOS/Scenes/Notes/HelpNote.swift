//
//  HelpNote.swift
//  Wasmic
//
//  Created by kateinoigakukun on 2021/04/11.
//

import SwiftUI

final class HelpNoteViewController: UIHostingController<HelpNote> {
    init() {
        super.init(rootView: HelpNote())
        self.title = "Invocation"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close, target: self,
            action: #selector(self.dismissPresenting))
    }
    @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    @objc func dismissPresenting(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}

struct HelpNote: View {
    var body: some View {
        List {
            Section(header: Text("WebAssembly")) {
                Link(
                    destination: URL(string: "https://webassembly.org")!,
                    label: {
                        Text("WebAssembly Official")
                    })
                Link(
                    destination: URL(
                        string: "https://webassembly.github.io/spec/core/text/index.html")!,
                    label: {
                        Text("WebAssembly Specification")
                    })
            }
        }
        .listStyle(InsetGroupedListStyle())
    }

}

struct HelpNote_Previews: PreviewProvider {

    static var previews: some View {
        Group {
            HelpNote()
            HelpNote()
                .environment(\.colorScheme, ColorScheme.dark)
                .background(Color.black)
            HelpNote()
                .previewLayout(.fixed(width: 2532 / 3.0, height: 1170 / 3.0))
                .environment(\.horizontalSizeClass, .regular)
                .environment(\.verticalSizeClass, .compact)
        }
    }
}
