//
//  WelcomeNote.swift
//  Wasmic
//
//  Created by kateinoigakukun on 2021/04/11.
//

import SwiftUI
import UIKit

final class WelcomeNoteViewController: UIHostingController<WelcomeNote> {
    let completion: () -> Void
    init(completion: @escaping () -> Void) {
        self.completion = completion
        super.init(rootView: WelcomeNote(dismiss: nil))
        rootView.dismiss = {
            self.dismiss(animated: true, completion: nil)
        }
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        completion()
    }
    @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct WelcomeNote: View {
    var dismiss: (() -> Void)?

    var body: some View {
        ScrollView {
            VStack {
                Spacer().frame(minHeight: 0, idealHeight: 54)
                Text("welcome.title")
                    .font(.title)
                    .bold()
                    .padding([.top, .bottom], 24)

                Row(
                    icon: Image(systemName: "globe"),
                    title: Text("welcome.run-and-learn.title"),
                    caption: Text("welcome.run-and-learn.caption"))

                Row(
                    icon: Image(systemName: "bolt.fill"),
                    title: Text("welcome.automate-things.title"),
                    caption: Text("welcome.automate-things.caption"))

                Row(
                    icon: Image(systemName: "gearshape.2"),
                    title: Text("welcome.wasi-compatible.title"),
                    caption: Text("welcome.wasi-compatible.caption"))

                PrimaryButton(
                    action: { self.dismiss?() },
                    label: {
                        Text("welcome.continue")
                    }
                )
                .padding()
                Spacer()
            }
        }
    }

    struct Row: View {
        let icon: Image
        let title: Text
        let caption: Text
        var body: some View {
            HStack {
                Group {
                    icon
                        .resizable()
                        .foregroundColor(Color(.systemIndigo))
                        .foregroundColor(.blue)
                        .aspectRatio(nil, contentMode: .fit)
                        .frame(width: 36)
                }
                .frame(width: 64, height: 64)

                VStack {
                    HStack {
                        title
                            .font(.headline)
                        Spacer()
                    }
                    Spacer().frame(height: 8)
                    HStack {
                        caption
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Spacer()
                    }
                }
            }
            .padding()
        }
    }
}

struct WelcomeNote_Previews: PreviewProvider {

    static var previews: some View {
        Group {
            WelcomeNote(dismiss: nil)
            WelcomeNote(dismiss: nil)
                .environment(\.colorScheme, ColorScheme.dark)
                .background(Color.black)
            WelcomeNote(dismiss: nil)
                .previewLayout(.fixed(width: 2532 / 3.0, height: 1170 / 3.0))
                .environment(\.horizontalSizeClass, .regular)
                .environment(\.verticalSizeClass, .compact)
        }
    }
}
