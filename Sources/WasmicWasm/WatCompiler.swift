//
//  WatCompiler.swift
//  WasmicWasm
//
//  Created by kateinoigakukun on 2021/04/10.
//

@_implementationOnly import wabt

extension WebAssembly {
    public static func compileWat(fileName: String, content: String, handler: @escaping ([UInt8]) -> Void) {
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
}
