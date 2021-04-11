//
//  WebAssembly.swift
//  WasmicWasm
//
//  Created by kateinoigakukun on 2021/04/10.
//

@_implementationOnly import CWasmicWASI
@_implementationOnly import wabt
@_implementationOnly import wasm3

public struct WebAssembly {

    enum Error: Swift.Error, CustomStringConvertible {
        case unexpected(String, M3Result?)

        var description: String {
            switch self {
            case .unexpected(let message, nil):
                return message
            case .unexpected(let message, let result?):
                return message + " '" + String(cString: result) + "'"
            }
        }
    }

    public enum Value: Equatable {
        case i32(Int32)
        case i64(Int64)
        case f32(Float32)
        case f64(Float64)
    }

    public static func startWasiApp(
        wasmBytes: [UInt8], args: [String],
        stdout: (String) -> Void,
        stderr: (String) -> Void
    ) throws -> Int {
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

        if let result = m3_LinkWASI(module) {
            throw Error.unexpected("m3_LinkWASI failed", result)
        }
        guard let context = wasmic_GetWasiContext() else {
            throw Error.unexpected("m3_GetWasiContext failed", nil)
        }

        var wasmFn: IM3Function?
        if let result = m3_FindFunction(&wasmFn, runtime, "_start") {
            throw Error.unexpected("m3_FindFunction failed", result)
        }

        return withoutActuallyEscaping(stdout) { stdout -> Int in
            withoutActuallyEscaping(stderr) { stderr -> Int in
                var userContext = WASIUserContext(stdout: stdout, stderr: stderr)
                context.pointee.writev = {
                    (
                        userCtxRawPtr: UnsafeMutableRawPointer?, fd: Int32,
                        iovs: UnsafePointer<iovec>?, iovs_len: Int32
                    ) -> Int in
                    guard
                        let userCtxPtr = userCtxRawPtr?.assumingMemoryBound(
                            to: WASIUserContext.self)
                    else {
                        return -1
                    }
                    return userCtxPtr.pointee.writev(fd: fd, iovs: iovs, iovs_len: iovs_len)
                }

                context.pointee.parent.argc = u32(args.count)
                let args = args.map { $0.copyCString() }
                defer { args.forEach { $0.deallocate() } }
                let argv = args + [nil]
                argv.withUnsafeBufferPointer { argv in
                    context.pointee.parent.argv = argv.baseAddress!
                    withUnsafeMutablePointer(to: &userContext) { userContextPtr in
                        context.pointee.user_context = UnsafeMutableRawPointer(userContextPtr)
                        m3_CallArgv(wasmFn, 0, nil)
                    }
                }
                return Int(context.pointee.parent.exit_code)
            }
        }
    }

    private struct WASIUserContext {
        let stdout: (String) -> Void
        let stderr: (String) -> Void

        func write(fd: Int32, iov: iovec) -> Int {
            let output = String(
                decodingCString: iov.iov_base.assumingMemoryBound(to: UInt8.self),
                as: UTF8.self)
            switch fd {
            case 1: stdout(output)
            case 2: stderr(output)
            default: break
            }
            return iov.iov_len
        }

        func writev(fd: Int32, iovs: UnsafePointer<iovec>?, iovs_len: Int32) -> Int {
            switch fd {
            case 1, 2:
                var written = 0
                let iovs = UnsafeBufferPointer(start: iovs, count: Int(iovs_len))
                for iov in iovs {
                    var localWritten = 0
                    while localWritten < iov.iov_len {
                        localWritten += write(fd: fd, iov: iov)
                    }
                    written += localWritten
                }
                return written
            default:
                return Darwin.writev(fd, iovs, iovs_len)
            }
        }
    }

    public static func execute(wasmBytes: [UInt8], function: String, args: [String])
        throws -> [Value]
    {
        let args = args.map { $0.copyCString() }
        defer { args.forEach { $0.deallocate() } }
        return try execute(wasmBytes: wasmBytes, function: function, args: args)
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

extension WebAssembly.Value: CustomStringConvertible {
    public var description: String {
        switch self {
        case .i32(let v): return "i32(\(v))"
        case .i64(let v): return "i64(\(v))"
        case .f32(let v): return "f32(\(v))"
        case .f64(let v): return "f64(\(v))"
        }
    }
}

extension String {
    fileprivate func copyCString() -> UnsafePointer<CChar> {
        let cString = utf8CString
        let cStringCopy = UnsafeMutableBufferPointer<CChar>
            .allocate(capacity: cString.count)
        _ = cStringCopy.initialize(from: cString)
        return UnsafePointer(cStringCopy.baseAddress!)
    }

}
