//
//  IntentHandler.swift
//  WasmicIntents
//
//  Created by kateinoigakukun on 2021/04/10.
//

import Intents
import WasmicKit

class IntentHandler: INExtension {

    override func handler(for intent: INIntent) -> Any {
        guard intent is RunWasmFileIntent else {
            fatalError("Unhandled intent type: \(intent)")
        }
        return 1
    }
}
