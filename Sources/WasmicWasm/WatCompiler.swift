//
//  WatCompiler.swift
//  WasmicWasm
//
//  Created by kateinoigakukun on 2021/04/10.
//

@_implementationOnly import wabt

extension WebAssembly {
    public struct TextLocation: Equatable {
        public let fileName: String
        public let line: Int
        public let firstColumn: Int
        public let lastColumn: Int

        internal static func copying(cLoc: wabt_c_api_text_location) -> TextLocation {
            return TextLocation(
                fileName: String(cString: cLoc.filename),
                line: Int(cLoc.line),
                firstColumn: Int(cLoc.first_column),
                lastColumn: Int(cLoc.last_column))
        }
    }
    public struct CompilationError: Swift.Error, Equatable {
        public enum Level: Equatable {
            case warning, error

            internal init(cErrorLevel: wabt_c_api_error_level) {
                switch cErrorLevel {
                case .error: self = .error
                case .warning: self = .warning
                }
            }
        }
        public let level: Level
        public let location: TextLocation
        public let message: String

        internal static func copying(cError: wabt_c_api_error) -> CompilationError {
            CompilationError(
                level: Level(cErrorLevel: cError.level),
                location: TextLocation.copying(cLoc: cError.loc),
                message: String(cString: cError.message))
        }
    }

    public struct CompilationErrors: Swift.Error {
        public let errors: [CompilationError]
    }

    public static func compileWat(
        fileName: String, content: String,
        handler: @escaping (Result<[UInt8], CompilationErrors>) -> Void
    ) {
        class Context {
            let handler: (Result<[UInt8], CompilationErrors>) -> Void
            init(handler: @escaping (Result<[UInt8], CompilationErrors>) -> Void) {
                self.handler = handler
            }
        }

        let ctx = Unmanaged.passRetained(Context(handler: handler)).toOpaque()
        fileName.withCString { filenamePtr in
            content.withCString { bodyPtr in
                let bodyLength = strlen(bodyPtr)
                wabt_c_api_compile_wat(
                    filenamePtr,
                    bodyPtr, bodyLength, ctx,
                    { ctx, bytes, length in
                        let ctx = Unmanaged<Context>.fromOpaque(ctx!).takeRetainedValue()
                        let buffer = UnsafeBufferPointer(start: bytes, count: length)
                        let bytes = Array(buffer)
                        ctx.handler(.success(bytes))
                    },
                    { ctx, errors, length in
                        let ctx = Unmanaged<Context>.fromOpaque(ctx!).takeRetainedValue()
                        let buffer = UnsafeBufferPointer(start: errors, count: length)
                        let errors = buffer.map(CompilationError.copying(cError:))
                        ctx.handler(.failure(CompilationErrors(errors: errors)))
                    }
                )
            }
        }
    }
}
