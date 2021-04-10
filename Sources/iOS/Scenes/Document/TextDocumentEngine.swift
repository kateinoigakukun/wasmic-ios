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
        case handleError([WebAssembly.CompilationError])
        case presentInvocationSelector([UInt8], [WebAssembly.Export], WebAssembly.Export)
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
                        self.outputHandler?(.handleError([]))
                        let exports: [WebAssembly.Export]
                        do {
                            exports = try WebAssembly.getExported(wasmBytes: bytes)
                        } catch {
                            print(error)
                            exports = []
                        }
                        if let first = exports.first {
                            self.outputHandler?(.presentInvocationSelector(bytes, exports, first))
                        }
                    case .failure(let errors):
                        self.outputHandler?(.handleError(errors.errors))
                    }
                }
            }
        }
    }
}
