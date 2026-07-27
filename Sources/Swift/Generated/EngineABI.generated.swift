// AUTO-GENERATED from bindings/idl/engine.tjnidl.ts. DO NOT EDIT.
public enum TjnEngineABI {
    public static let version: UInt32 = 1
    public static let compatibleRevision: UInt32 = 1
}

public enum TjnEngineStatusCode: Int32, Sendable {
    case ok = 0
    case invalidArgument = 1
    case invalidState = 2
    case abiMismatch = 3
    case capacityExceeded = 4
    case invalidHandle = 5
    case staleHandle = 6
    case typeMismatch = 7
    case wrongSession = 8
    case unsupportedFeature = 9
    case surfaceUnavailable = 10
    case assetInvalid = 11
    case integrityMismatch = 12
    case cancelled = 13
    case timedOut = 14
    case bufferTooSmall = 15
    case queueOverflow = 16
    case outOfMemory = 17
    case contextLost = 18
    case `internal` = 19
    case noEvent = 20
    case wouldBlock = 21
}
