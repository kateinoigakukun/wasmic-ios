//
//  WasmExecutionView.swift
//  Wasmic
//
//  Created by kateinoigakukun on 2021/04/09.
//

import SwiftUI
import WasmicWasm

struct WasmExecutionView: View {
    @StateObject var executor: WasmExecutor

    var body: some View {
        Text(String(describing: executor.state))
            .onAppear {
                executor.startPipeline()
            }
    }
}

class WasmExecutor: ObservableObject {
    enum State {
        case compiling
        case executing
        case failed(String)
        case result([WebAssembly.Value])
    }

    let function: String
    let parameters: [String]
    let bytes: [UInt8]
    private let pipelineQueue = DispatchQueue(
        label: "dev.katei.Wasmic.executor-pipeline",
        qos: .default
    )

    @Published var state: State?

    init(
        function: String,
        parameters: [String],
        bytes: [UInt8]
    ) {
        self.function = function
        self.parameters = parameters
        self.bytes = bytes
        self.state = nil
    }

    func startPipeline() {
        pipelineQueue.async { [weak self] in
            guard let self = self else { return }
            do {
                let args = self.parameters.map { $0.copyCString() }
                defer { args.forEach { $0.deallocate() } }
                let result =
                    try WebAssembly.execute(wasmBytes: self.bytes, function: self.function, args: args)
                DispatchQueue.main.async {
                    self.state = .result(result)
                }
            } catch {
                DispatchQueue.main.async {
                    // FIXME
                    self.state = .failed(String(describing: error))
                }
            }
        }
    }
}

fileprivate extension String {
    func copyCString() -> UnsafePointer<CChar> {
        let cString = utf8CString
        let cStringCopy = UnsafeMutableBufferPointer<CChar>
            .allocate(capacity: cString.count)
        _ = cStringCopy.initialize(from: cString)
        return UnsafePointer(cStringCopy.baseAddress!)
    }
}
