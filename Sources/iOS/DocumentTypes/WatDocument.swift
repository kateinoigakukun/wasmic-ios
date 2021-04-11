//
//  WatDocument.swift
//  Wasmic
//
//  Created by kateinoigakukun on 2021/04/09.
//

import Foundation

class WatDocument: TextDocument {
    init() {
        let tempDir = FileManager.default.temporaryDirectory
        let url = tempDir.appendingPathComponent("main.wat")

        super.init(fileURL: url)
        text = """
            (module
                (export "_start" (func $_start))
                (func $_start (result i32)
                    (i32.const 0)
                )
            )
            """
    }
}
