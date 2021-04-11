public struct SectionInfo: Equatable {
    public let startOffset: Int
    public let endOffset: Int
    public let type: SectionType
    public let size: Int
}

public struct TypeSection {
    public private(set) var signatures: [FuncSignature] = []

    init() {}

    public init(from input: inout InputByteStream) throws {
        let count = input.readVarUInt32()
        for _ in 0..<count {
            let header = input.readUInt8()
            assert(header == 0x60)
            let params = try input.readResultTypes()
            let results = try input.readResultTypes()
            signatures.append(FuncSignature(params: params, results: results))
        }
    }
    mutating func append(signature: FuncSignature) {
        signatures.append(signature)
    }
}

struct ExportSection {
    var exports: [Export] = []
    init() {}
    init(from input: inout InputByteStream) throws {
        let exportsCount = Int(input.readVarUInt32())
        for _ in 0..<exportsCount {
            let name = input.readString()
            let rawKind = input.readUInt8()
            guard let kind = ExternalKind(rawValue: rawKind) else {
                throw InputByteStream.Error.invalidValueType(rawKind)
            }
            let itemIndex = Int(input.readVarUInt32())
            exports.append(Export(kind: kind, name: name, index: itemIndex))
        }
    }
}

typealias ImportFuncReplacement = (index: Int, toTypeIndex: Int)

struct ImportSection {
    let funcImportCount: Int
    init() { self.funcImportCount = 0 }
    init(from input: inout InputByteStream) throws {
        let importCount = Int(input.readVarUInt32())
        var funcImportCount: Int = 0
        for _ in 0..<importCount {
            _ = input.readString()
            _ = input.readString()
            let rawKind = input.readUInt8()
            let kind = ExternalKind(rawValue: rawKind)
            switch kind {
            case .func:
                _ = input.readVarUInt32()
                funcImportCount += 1
            case .table:
                input.consumeTable()
            case .memory:
                input.consumeMemory()
            case .global:
                input.consumeGlobalHeader()
            default:
                throw InputByteStream.Error.invalidValueType(rawKind)
            }
        }
        self.funcImportCount = funcImportCount
    }
}

struct FunctionSection {
    var typeIndices: [Int] = []
    init() {}
    init(from input: inout InputByteStream) throws {
        let count = Int(input.readVarUInt32())
        for _ in 0..<count {
            let typeIndex = Int(input.readVarUInt32())
            typeIndices.append(typeIndex)
        }
    }
}

struct NameSection {
    var functionNames: [(index: Int, name: String)] = []
    init() {}
    init(from input: inout InputByteStream, section: SectionInfo) throws {
        while input.offset < section.endOffset {
            let subsectionType = input.readUInt8()
            let subsectionSize = Int(input.readVarUInt32())
            let subsectionEnd = input.offset + subsectionSize

            switch NameSectionSubsection(rawValue: subsectionType) {
            case .function:
                let namesCount = input.readVarUInt32()
                for _ in 0..<namesCount {
                    let funcIdx = Int(input.readVarUInt32())
                    let funcName = input.readString()
                    functionNames.append((funcIdx, funcName))
                }
            default:
                input.seek(subsectionEnd)
            }
        }
    }
}
