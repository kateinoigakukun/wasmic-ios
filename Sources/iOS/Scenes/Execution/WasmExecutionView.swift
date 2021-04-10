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

    let bytes: [UInt8]
    private let pipelineQueue = DispatchQueue(
        label: "dev.katei.Wasmic.executor-pipeline",
        qos: .default
    )

    @Published var state: State?

    init(bytes: [UInt8]) {
        self.bytes = bytes
        self.state = nil
    }

    func startPipeline() {
        pipelineQueue.async { [weak self] in
            guard let self = self else { return }
            do {
                let input = "40"
                let result = try input.withCString {
                    try WebAssembly.execute(wasmBytes: self.bytes, function: "fib", args: [$0])
                }
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
