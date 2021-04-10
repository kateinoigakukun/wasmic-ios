//
//  WasmicWasmTests.swift
//  WasmicWasmTests
//
//  Created by kateinoigakukun on 2021/04/10.
//

import XCTest
@testable import WasmicWasm

class WasmExecutorTests: XCTestCase {
    func testExecute() throws {
        let fibWasm: [UInt8] = [
            0x00, 0x61, 0x73, 0x6d, 0x01, 0x00, 0x00, 0x00, 0x01, 0x06, 0x01, 0x60,
            0x01, 0x7f, 0x01, 0x7f, 0x03, 0x02, 0x01, 0x00, 0x07, 0x07, 0x01, 0x03,
            0x66, 0x69, 0x62, 0x00, 0x00, 0x0a, 0x1f, 0x01, 0x1d, 0x00, 0x20, 0x00,
            0x41, 0x02, 0x49, 0x04, 0x40, 0x20, 0x00, 0x0f, 0x0b, 0x20, 0x00, 0x41,
            0x02, 0x6b, 0x10, 0x00, 0x20, 0x00, 0x41, 0x01, 0x6b, 0x10, 0x00, 0x6a,
            0x0f, 0x0b
        ]
        let input = "20"
        let result = try input.withCString {
            try WebAssembly.execute(wasmBytes: fibWasm, function: "fib", args: [$0])
        }

        XCTAssertEqual(result, [.i32(6765)])
    }

    func testCompileWat() throws {
        let wat = """
        (module
          (func (export "add") (param i32 i32) (result i32)
            local.get 0
            local.get 1
            i32.add))
        """
        WebAssembly.compileWat(fileName: "main.wat", content: wat) { result in
            guard case let .success(bytes) = result else { XCTFail(); return }
            XCTAssertTrue(bytes.starts(with: [0x00, 0x61, 0x73, 0x6d]))
        }
    }

    func testCompileError() throws {
        let wat = """
        (module invalid)
        """
        WebAssembly.compileWat(fileName: "main.wat", content: wat) { result in
            guard case let .failure(errors) = result else { XCTFail(); return }
            XCTAssertEqual(errors.errors.count, 1)
            guard let error = errors.errors.first else { XCTFail(); return }
            XCTAssertEqual(error.level, .error)
            XCTAssertEqual(error.location.fileName, "main.wat")
            XCTAssertEqual(error.location.line, 1)
            XCTAssertEqual(error.location.firstColumn, 9)
            XCTAssertEqual(error.location.lastColumn, 16)
            XCTAssertEqual(error.message, "unexpected token \"invalid\", expected a module field.")
        }
    }
}
