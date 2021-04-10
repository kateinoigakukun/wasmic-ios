//
//  WasmInvocationView.swift
//  Wasmic
//
//  Created by kateinoigakukun on 2021/04/10.
//

import SwiftUI
import WasmicWasm

struct WasmInvocationView: View {
    @State var exports: [WebAssembly.Export]
    @State var selected: WebAssembly.Export
    @State var parameters: [String] = []
    @State var isExecuting: Bool = false
    @Environment(\.presentationMode) var presentationMode
    let bytes: [UInt8]

    init(bytes: [UInt8], exports: [WebAssembly.Export], selected: WebAssembly.Export) {
        self.bytes = bytes
        self._exports = State(initialValue: exports)
        self._selected = State(initialValue: selected)
        self._parameters = State(
            initialValue: Array(repeating: "", count: selected.signature.params.count))
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    Picker(
                        selection: Binding(
                            get: { selected },
                            set: { newSelection in
                                self.selected = newSelection
                                self.parameters = Array(
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
                if selected.signature.params.count == parameters.count {
                    Section {
                        ForEach(0..<parameters.count, id: \.self) { idx in
                            let param = selected.signature.params[idx]
                            HStack {
                                TextField(
                                    "Parameter #\(idx) (\(String(describing: param)))",
                                    text: $parameters[idx]
                                )
                                .keyboardType(.numberPad)
                            }
                        }
                    }
                    Section {
                        Button("Run") { isExecuting = true }
                            .disabled(parameters.contains(where: \.isEmpty))
                    }
                }
            }
            .sheet(
                isPresented: $isExecuting,
                content: { () -> WasmExecutionView in
                    let executor = WasmExecutor(
                        function: selected.name, parameters: parameters, bytes: bytes)
                    return WasmExecutionView(executor: executor)
                }
            )
            .navigationBarItems(
                trailing: Button(
                    "Done",
                    action: {
                        presentationMode.wrappedValue.dismiss()
                    })
            )
            .navigationTitle("Invocation")
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
        WasmInvocationView(bytes: fibWasm, exports: exports, selected: exports.first!)
    }
}
