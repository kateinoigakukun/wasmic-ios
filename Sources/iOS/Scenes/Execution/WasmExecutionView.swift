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
    enum Input {
        case wat(fileName: String, content: String)
    }

    enum State {
        case compiling
        case executing
        case failed(String)
        case result([WebAssembly.Value])
    }

    let input: Input
    private let pipelineQueue = DispatchQueue(
        label: "dev.katei.Wasmic.executor-pipeline",
        qos: .default
    )

    @Published var state: State?

    init(input: WasmExecutor.Input) {
        self.input = input
        self.state = nil
    }

    func startPipeline() {
        pipelineQueue.async { [weak self] in
            guard let self = self else { return }
            self.produceWasmBytes { bytes in
                do {
                    let input = "40"
                    let result = try input.withCString {
                        try WebAssembly.execute(wasmBytes: bytes, function: "fib", args: [$0])
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

    func produceWasmBytes(_ handler: @escaping ([UInt8]) -> Void) {
        switch self.input {
        case let .wat(fileName, content):
            WebAssembly.compileWat(fileName: fileName, content: content, handler: handler)
        }
    }
}
