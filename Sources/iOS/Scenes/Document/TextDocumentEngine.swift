//
//  TextDocumentEngine.swift
//  Wasmic
//
//  Created by kateinoigakukun on 2021/04/10.
//

import Foundation
import WasmicWasm

final class TextDocumentEngine {
    private let pipelineQueue = DispatchQueue(
        label: "dev.katei.Wasmic.compile-pipeline",
        qos: .default
    )

    enum Output {
        case isCompiling(Bool)
        case handleCompilationError([WebAssembly.CompilationError])
        case handleBinaryParsingError(Error)
        case presentInvocationSelector([UInt8], [WebAssembly.Export], WebAssembly.Export, isWASI: Bool)
    }

    var outputHandler: ((Output) -> Void)?

    func compile(fileName: String, watContent: String) {
        pipelineQueue.async { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.outputHandler?(.isCompiling(true))
            }

            WebAssembly.compileWat(
                fileName: fileName, content: watContent
            ) { result in
                DispatchQueue.main.async {
                    self.outputHandler?(.isCompiling(false))
                    switch result {
                    case .success(let bytes):
                        self.outputHandler?(.handleCompilationError([]))
                        do {
                            let exports = try WebAssembly.getExported(wasmBytes: bytes)
                            if let first = exports.functions.first {
                                self.outputHandler?(
                                    .presentInvocationSelector(
                                        bytes, exports.functions, first, isWASI: exports.isWASI))
                            } else {
                                // TODO: Report no-exported function error
                            }
                        } catch {
                            self.outputHandler?(.handleBinaryParsingError(error))
                        }
                    case .failure(let errors):
                        self.outputHandler?(.handleCompilationError(errors.errors))
                    }
                }
            }
        }
    }
}
