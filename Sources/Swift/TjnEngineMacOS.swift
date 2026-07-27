#if os(macOS)
import Foundation
import TjnEngineCore

public struct TjnMacEngineError: Error, CustomStringConvertible {
    public let status: TjnStatus
    public var description: String {
        String(cString: tjn_status_name(status))
    }
}

@MainActor
public final class TjnMacEngine {
    private var handle: TjnEngineHandle = 0

    public init(eventCapacity: UInt32 = 256, memoryBudgetBytes: UInt64 = 512 << 20) throws {
        var configuration = TjnEngineConfig()
        configuration.struct_size = UInt32(MemoryLayout<TjnEngineConfig>.size)
        configuration.struct_version = TJN_ENGINE_STRUCT_VERSION
        configuration.abi_version = TJN_ENGINE_ABI_VERSION
        configuration.event_capacity = eventCapacity
        configuration.memory_budget_bytes = memoryBudgetBytes
        let status = tjn_engine_create(&configuration, &handle)
        guard status == TJN_STATUS_OK else {
            throw TjnMacEngineError(status: status)
        }
    }

    public var state: TjnEngineState {
        get throws {
            var value = TjnEngineState(TJN_ENGINE_STATE_DETACHED)
            let status = tjn_engine_get_state(handle, &value)
            guard status == TJN_STATUS_OK else {
                throw TjnMacEngineError(status: status)
            }
            return value
        }
    }

    public func release() {
        guard handle != 0 else { return }
        _ = tjn_engine_destroy(handle)
        handle = 0
    }

    deinit {
        if handle != 0 {
            _ = tjn_engine_destroy(handle)
        }
    }
}
#endif
