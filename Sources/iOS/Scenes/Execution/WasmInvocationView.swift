//
//  WasmInvocationView.swift
//  Wasmic
//
//  Created by kateinoigakukun on 2021/04/10.
//

import SwiftUI
import WasmicWasm

class WasmInvocationViewController: UIHostingController<WasmInvocationView> {
    init(bytes: [UInt8], exports: [WebAssembly.Export], selected: WebAssembly.Export, isWASI: Bool) {
        super.init(rootView: WasmInvocationView(bytes: bytes, exports: exports, selected: selected, isWASI: isWASI))
        self.title = "Invocation"
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(
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

struct WasmInvocationView: View {
    @State var exports: [WebAssembly.Export]
    @State var selected: WebAssembly.Export
    @State var wasmArguments: [String] = []
    @State var wasiArguments: [String] = []
    @State var isExecuting: Bool = false
    @State var runAsWASI: Bool

    let bytes: [UInt8]
    let isWASI: Bool

    init(bytes: [UInt8], exports: [WebAssembly.Export],
         selected: WebAssembly.Export, isWASI: Bool) {
        self.bytes = bytes
        self._exports = State(initialValue: exports)
        self._selected = State(initialValue: selected)
        self._wasmArguments = State(
            initialValue: Array(repeating: "", count: selected.signature.params.count))
        self._runAsWASI = State(initialValue: isWASI)
        self.isWASI = isWASI
    }

    struct _TextField: View {
        let titleKey: String
        let items: Binding<[String]>
        let index: Int

        var body: some View {
            TextField(
                titleKey,
                text: Binding(
                    get: {
                        if items.wrappedValue.indices.contains(index) {
                            return items.wrappedValue[index]
                        } else {
                            return ""
                        }
                    },
                    set: { newValue in
                        if items.wrappedValue.indices.contains(index) {
                            items.wrappedValue[index] = newValue
                        }
                    }
                )
            )
        }
    }

    var body: some View {
        Form {
            Section {
                if isWASI {
                    Toggle(isOn: $runAsWASI) { Text("WASI Application") }
                }
                if !runAsWASI {
                    functionSelector
                }
            }

            if runAsWASI {
                wasiLevelArguments
            } else {
                wasmLevelArguments
            }
            Section {
                Button("Run") { isExecuting = true }
                    .disabled(wasmArguments.contains(where: \.isEmpty))
            }
        }
        .sheet(
            isPresented: $isExecuting,
            content: { () -> AnyView in
                let executor = WasmExecutor(
                    function: selected.name, arguments: wasmArguments,
                    bytes: bytes, runAsWASI: runAsWASI)
                return AnyView(
                    WasmExecutionView(executor: executor)
                        .background(Color.black)
                        .edgesIgnoringSafeArea([.bottom, .leading, .trailing]))
            }
        )
    }

    var functionSelector: some View {
        Picker(
            selection: Binding(
                get: { selected },
                set: { newSelection in
                    self.selected = newSelection
                    self.wasmArguments = Array(
                        repeating: "", count: newSelection.signature.params.count)
                }
            ),
            label: Text("Function"),
            content: {
                ForEach(exports, id: \.self) { export in
                    Text(export.name)
                }
            }
        )
    }

    @ViewBuilder
    var wasmLevelArguments: some View {
        if selected.signature.params.count == wasmArguments.count, !wasmArguments.isEmpty {
            Section {
                ForEach(wasmArguments.indices, id: \.self) { idx in
                    let param = selected.signature.params[idx]
                    TextField(
                        "Argument #\(idx) (\(String(describing: param)))",
                        text: $wasmArguments[idx]
                    )
                    .keyboardType(.numberPad)
                }
            }
        }
    }

    var wasiLevelArguments: some View {
        Section {
            List {
                ForEach(wasiArguments.indices, id: \.self) { idx in
                    _TextField(
                        titleKey: "Argument #\(idx)",
                        items: $wasiArguments,
                        index: idx
                    )
                }
                .onDelete(perform: { indexSet in
                    wasiArguments.remove(atOffsets: indexSet)
                })
            }
            Button(action: { wasiArguments.append("") }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add new argument")
                }
            }
        }
    }
}

struct WasmInvocationView_Previews: PreviewProvider {
    static let fibWasm: [UInt8] = [
        0x00, 0x61, 0x73, 0x6d, 0x01, 0x00, 0x00, 0x00, 0x01, 0x06, 0x01, 0x60,
        0x01, 0x7f, 0x01, 0x7f, 0x03, 0x02, 0x01, 0x00, 0x07, 0x07, 0x01, 0x03,
        0x66, 0x69, 0x62, 0x00, 0x00, 0x0a, 0x1f, 0x01, 0x1d, 0x00, 0x20, 0x00,
        0x41, 0x02, 0x49, 0x04, 0x40, 0x20, 0x00, 0x0f, 0x0b, 0x20, 0x00, 0x41,
        0x02, 0x6b, 0x10, 0x00, 0x20, 0x00, 0x41, 0x01, 0x6b, 0x10, 0x00, 0x6a,
        0x0f, 0x0b,
    ]
    static let exports = [
        WebAssembly.Export(
            name: "foo", signature: FuncSignature(params: [.i32, .f32], results: [])),
        WebAssembly.Export(name: "bar", signature: FuncSignature(params: [.i32], results: [])),
        WebAssembly.Export(
            name: "fizz", signature: FuncSignature(params: [.i64, .i32, .i32], results: [])),
    ]
    static var previews: some View {
        WasmInvocationView(bytes: fibWasm, exports: exports, selected: exports.first!, isWASI: false)
    }
}
