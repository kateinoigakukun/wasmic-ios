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

func compileWat(fileName: String, content: String, handler: @escaping ([UInt8]) -> Void) {
    class Context {
        let handler: ([UInt8]) -> Void
        init(handler: @escaping ([UInt8]) -> Void) {
            self.handler = handler
        }
    }

    let ctx = Unmanaged.passRetained(Context(handler: handler)).toOpaque()
    fileName.withCString { filenamePtr in
        content.withCString { bodyPtr in
            let bodyLength = strlen(bodyPtr)
            wabt_c_api_compile_wat(
                filenamePtr,
                bodyPtr, bodyLength, ctx) { ctx, bytes, length in
                let ctx = Unmanaged<Context>.fromOpaque(ctx!).takeRetainedValue()
                let buffer = UnsafeBufferPointer(start: bytes, count: length)
                let bytes = Array(buffer)
                ctx.handler(bytes)
            }
        }
    }
}

class WasmExecutor: ObservableObject {
    enum Input {
        case wat(fileName: String, content: String)
    }

    enum WasmValue {
        case i32(Int32)
        case i64(Int64)
        case f32(Float32)
        case f64(Float64)
    }

    enum Error: Swift.Error {
        case unexpected(String, M3Result?)
    }

    enum State {
        case compiling
        case executing
        case failed(String)
        case result([WasmValue])
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
                        try self.execute(wasmBytes: bytes, args: [$0])
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
            compileWat(fileName: fileName, content: content, handler: handler)
        }
    }

    func execute(wasmBytes: [UInt8], args: [UnsafePointer<CChar>]) throws -> [WasmValue] {
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

        var argv = args + [nil]
        let execResult = argv.withUnsafeMutableBufferPointer { argv in
            m3_CallArgv(fibFn, 1, argv.baseAddress)
        }
        if let result = execResult {
            throw Error.unexpected("m3_CallArgv failed", result)
        }

        let returnCount = m3_GetRetCount(fibFn)
        guard returnCount > 0 else { return [] }

        let returnsBuffer = [UInt64](repeating: 0, count: Int(returnCount))
        let returnResult = returnsBuffer.withUnsafeBufferPointer { returnsBuffer -> M3Result? in
            let ptr = returnsBuffer.baseAddress!
            var returnsPtrs = (0..<Int(returnCount)).map {
                Optional(UnsafeRawPointer(ptr.advanced(by: $0)))
            }
            return returnsPtrs.withUnsafeMutableBufferPointer { returnsPtrs in
                m3_GetResults(fibFn, returnCount, returnsPtrs.baseAddress)
            }
        }

        if let result = returnResult {
            throw Error.unexpected("m3_GetResults failed", result)
        }

        let constructors = (0..<returnCount).lazy.map { i -> ((UInt64) throws -> WasmValue) in
            let constructor: ((UInt64) -> (WasmValue, String))
            let type = m3_GetRetType(fibFn, i)
            switch type {
            case c_m3Type_i32: constructor = {
                (.i32(Int32(bitPattern: UInt32($0))), "i32")
            }
            case c_m3Type_i64: constructor = {
                (.i64(Int64(bitPattern: $0)), "i64")
            }
            case c_m3Type_f32: constructor = {
                (.f32(Float32(bitPattern: UInt32($0))), "f32")
            }
            case c_m3Type_f64: constructor = {
                (.f64(Float64(bitPattern: $0)), "f64")
            }
            default:
                return { _ in throw Error.unexpected("unsupported type: \(type)", nil) }
            }
            return {
                let (value, _) = constructor($0)
                return value
            }
        }
        
        return try returnsBuffer.withUnsafeBufferPointer { returnsBuffer -> [WasmValue] in
            let ptr = returnsBuffer.baseAddress!
            return try constructors.enumerated().map { offset, constructor in
                let value = ptr.advanced(by: offset).pointee
                return try constructor(value)
            }
            
        }
    }
}
