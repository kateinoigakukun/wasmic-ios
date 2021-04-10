//
//  TextDocumentEngine.swift
//  Wasmic
//
//  Created by kateinoigakukun on 2021/04/10.
//

import WasmicWasm
import Foundation

final class TextDocumentEngine {
    private let pipelineQueue = DispatchQueue(
        label: "dev.katei.Wasmic.executor-pipeline",
        qos: .default
    )

    enum Output {
        case isCompiling(Bool)
        case handleError([WebAssembly.CompilationError])
    }

    var outputHandler: ((Output) -> Void)?

    func compile(fileName: String, watContent: String,
                 execute: @escaping ([UInt8]) -> Void) {
        pipelineQueue.async { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.outputHandler?(.isCompiling(true))
            }

            WebAssembly.compileWat(
                fileName: fileName, content: watContent) { result in
                DispatchQueue.main.async {
                    self.outputHandler?(.isCompiling(false))
                    switch result {
                    case .success(let bytes):
                        self.outputHandler?(.handleError([]))
                        execute(bytes)
                    case .failure(let errors):
                        self.outputHandler?(.handleError(errors.errors))
                    }
                }
            }
        }
    }
}
