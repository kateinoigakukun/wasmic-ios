//
//  WasmExecutionView.swift
//  Wasmic
//
//  Created by kateinoigakukun on 2021/04/09.
//

import SwiftUI
import wabt
import wasm3

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
        case wat(filename: String, body: String)
    }

    enum Error: Swift.Error {
        case unexpected(String, M3Result?)
    }
    enum State {
        case compiling
        case executing
        case failed(String)
        case result(String)
    }

    let input: Input
    @Published var state: State?

    init(input: WasmExecutor.Input) {
        self.input = input
        self.state = nil
    }

    func startPipeline() {
        let bytes = produceWasmBytes()
        do {
            let result = try execute(wasmBytes: bytes)
            self.state = .result(result)
        } catch {
            // FIXME
            self.state = .failed(String(describing: error))
        }
    }

    func produceWasmBytes() -> [UInt8] {
        switch self.input {
        case let .wat(filename, body):
            var _wasmBytes: UnsafePointer<UInt8>?
            var _wasmBytesLength: Int = 0
            filename.withCString { filenamePtr in
                body.withCString { bodyPtr in
                    let bodyLength = strlen(bodyPtr)
                    wabt_c_api_compile_wat(
                        filenamePtr,
                        bodyPtr, bodyLength,
                        &_wasmBytes, &_wasmBytesLength)
                }
            }
            let wasmBytes = UnsafeBufferPointer(start: _wasmBytes, count: _wasmBytesLength)
            return Array(wasmBytes)
        }
    }

    func execute(wasmBytes: [UInt8]) throws -> String {
        guard let env = m3_NewEnvironment() else {
            throw Error.unexpected("m3_NewEnvironment failed", nil)
        }
        guard let runtime = m3_NewRuntime(env, 1024 * 8, nil) else {
            throw Error.unexpected("m3_NewRuntime failed", nil)
        }

        var module: IM3Module?
        if let result = m3_ParseModule(env, &module, wasmBytes, UInt32(wasmBytes.count)) {
            throw Error.unexpected("m3_ParseModule failed", result)
        }

        if let result = m3_LoadModule(runtime, module) {
            throw Error.unexpected("m3_LoadModule failed", result)
        }

        var fibFn: IM3Function?
        if let result = m3_FindFunction(&fibFn, runtime, "fib") {
            throw Error.unexpected("m3_FindFunction failed", result)
        }

        let input = "40"
        let execResult = input.withCString { inputPtr -> M3Result? in
            var argv = [inputPtr, nil]
            return argv.withUnsafeMutableBufferPointer { argv in
                m3_CallArgv(fibFn, 1, argv.baseAddress)
            }
        }
        if let result = execResult {
            throw Error.unexpected("m3_CallArgv failed", result)
        }
        var value: UInt32 = 0
        let returnResult = withUnsafeMutablePointer(to: &value) { value in
            m3_GetResultsVL(fibFn, getVaList([value]))
        }

        if let result = returnResult {
            throw Error.unexpected("m3_GetResultsVL failed", result)
        }
        return value.description
    }
}
