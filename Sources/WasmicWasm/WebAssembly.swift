//
//  WebAssembly.swift
//  WasmicWasm
//
//  Created by kateinoigakukun on 2021/04/10.
//

@_implementationOnly import wabt
@_implementationOnly import wasm3

public struct WebAssembly {

    enum Error: Swift.Error {
        case unexpected(String, M3Result?)
    }

    public enum Value: Equatable {
        case i32(Int32)
        case i64(Int64)
        case f32(Float32)
        case f64(Float64)
    }

    public static func execute(wasmBytes: [UInt8], function: String, args: [UnsafePointer<CChar>])
        throws -> [Value]
    {
        guard let env = m3_NewEnvironment() else {
            throw Error.unexpected("m3_NewEnvironment failed", nil)
        }
        defer { m3_FreeEnvironment(env) }
        guard let runtime = m3_NewRuntime(env, 1024 * 8, nil) else {
            throw Error.unexpected("m3_NewRuntime failed", nil)
        }
        defer { m3_FreeRuntime(runtime) }

        var module: IM3Module?
        if let result = m3_ParseModule(env, &module, wasmBytes, UInt32(wasmBytes.count)) {
            throw Error.unexpected("m3_ParseModule failed", result)
        }

        if let result = m3_LoadModule(runtime, module) {
            throw Error.unexpected("m3_LoadModule failed", result)
        }

        var wasmFn: IM3Function?
        if let result = m3_FindFunction(&wasmFn, runtime, function) {
            throw Error.unexpected("m3_FindFunction failed", result)
        }

        var argv = args + [nil]
        let execResult = argv.withUnsafeMutableBufferPointer { argv in
            m3_CallArgv(wasmFn, UInt32(args.count), argv.baseAddress)
        }
        if let result = execResult {
            throw Error.unexpected("m3_CallArgv failed", result)
        }

        let returnCount = m3_GetRetCount(wasmFn)
        guard returnCount > 0 else { return [] }

        let returnsBuffer = [UInt64](repeating: 0, count: Int(returnCount))
        let returnResult = returnsBuffer.withUnsafeBufferPointer { returnsBuffer -> M3Result? in
            let ptr = returnsBuffer.baseAddress!
            var returnsPtrs = (0..<Int(returnCount)).map {
                Optional(UnsafeRawPointer(ptr.advanced(by: $0)))
            }
            return returnsPtrs.withUnsafeMutableBufferPointer { returnsPtrs in
                m3_GetResults(wasmFn, returnCount, returnsPtrs.baseAddress)
            }
        }

        if let result = returnResult {
            throw Error.unexpected("m3_GetResults failed", result)
        }

        let constructors = (0..<returnCount).lazy.map { i -> ((UInt64) throws -> Value) in
            let constructor: ((UInt64) -> (Value, String))
            let type = m3_GetRetType(wasmFn, i)
            switch type {
            case c_m3Type_i32:
                constructor = {
                    (.i32(Int32(bitPattern: UInt32($0))), "i32")
                }
            case c_m3Type_i64:
                constructor = {
                    (.i64(Int64(bitPattern: $0)), "i64")
                }
            case c_m3Type_f32:
                constructor = {
                    (.f32(Float32(bitPattern: UInt32($0))), "f32")
                }
            case c_m3Type_f64:
                constructor = {
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

        return try returnsBuffer.withUnsafeBufferPointer { returnsBuffer -> [Value] in
            let ptr = returnsBuffer.baseAddress!
            return try constructors.enumerated().map { offset, constructor in
                let value = ptr.advanced(by: offset).pointee
                return try constructor(value)
            }

        }
    }
}
