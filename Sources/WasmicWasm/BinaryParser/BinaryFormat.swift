let magic: [UInt8] = [0x00, 0x61, 0x73, 0x6D]
let version: [UInt8] = [0x01, 0x00, 0x00, 0x00]

let LIMITS_HAS_MAX_FLAG: UInt8 = 0x1
let LIMITS_IS_SHARED_FLAG: UInt8 = 0x2

public enum SectionType: UInt8 {
    case custom = 0
    case type = 1
    case `import` = 2
    case function = 3
    case table = 4
    case memory = 5
    case global = 6
    case export = 7
    case start = 8
    case elem = 9
    case code = 10
    case data = 11
    case dataCount = 12
}

public enum ValueType: UInt8, Equatable {
    case i32 = 0x7F
    case i64 = 0x7E
    case f32 = 0x7D
    case f64 = 0x7C
}

enum ExternalKind: UInt8, Equatable {
    case `func` = 0
    case table = 1
    case memory = 2
    case global = 3
    case except = 4
}

enum ConstOpcode: UInt8 {
    case i32Const = 0x41
    case i64Const = 0x42
    case f32Const = 0x43
    case f64Const = 0x44
}


public struct FuncSignature: Equatable, Hashable {
    public let params: [ValueType]
    public let results: [ValueType]

    public init(params: [ValueType], results: [ValueType]) {
        self.params = params
        self.results = results
    }
}

enum NameSectionSubsection: UInt8 {
    case function = 1
}



class Export {
    let kind: ExternalKind
    let name: String
    let index: Int

    init(kind: ExternalKind, name: String, index: Int) {
        self.kind = kind
        self.name = name
        self.index = index
    }
}
