//
//  RunWasmFileIntentHandler.swift
//  WasmicIntents
//
//  Created by kateinoigakukun on 2021/04/10.
//

import UIKit
import Intents
import WasmicKit

final class RunWasmFileIntentHandler: NSObject, RunWasmFileIntentHandling {
    func handle(intent: RunWasmFileIntent, completion: @escaping (RunWasmFileIntentResponse) -> Void) {
        guard let fileName = intent.fileName,
              let functionName = intent.functionName else {
            completion(RunWasmFileIntentResponse(code: .failure, userActivity: nil))
            return
        }
        let arguments = intent.arguments ?? []

        do {
            let results = try WebAssembly.execute(
                wasmBytes: Array(fileName.data),
                function: functionName,
                args: arguments.map(\.description))
            let response = RunWasmFileIntentResponse()
            response.results = results.map { $0.asDouble }
            completion(.init(code: .success, userActivity: nil))
        } catch {
            completion(.init(code: .failure, userActivity: nil))
        }
    }
}

fileprivate extension WebAssembly.Value {
    var asDouble: Double {
        switch self {
        case .i32(let v): return Double(v)
        case .i64(let v): return Double(v)
        case .f32(let v): return Double(v)
        case .f64(let v): return Double(v)
        }
    }
}
