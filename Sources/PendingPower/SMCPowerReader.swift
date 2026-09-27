import Foundation
import IOKit

// AppleSMC's PSTR key reports system rail power in watts. It is independent
// of IOReport's Energy Model, whose channels can disappear across OS updates.
final class SMCPowerReader {
    private var connection: io_connect_t = 0
    private static let key: UInt32 = 0x50535452 // PSTR
    private static let floatType: UInt32 = 0x666c7420 // "flt "

    init?() {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSMC"))
        guard service != 0 else { return nil }
        defer { IOObjectRelease(service) }
        guard IOServiceOpen(service, mach_task_self_, 0, &connection) == KERN_SUCCESS else { return nil }
    }

    deinit { IOServiceClose(connection) }

    func readWatts() -> Double? {
        var info = SMCParam()
        info.key = Self.key
        info.data8 = 9 // get key information
        guard let metadata = call(info), metadata.keyInfo.size == 4,
              metadata.keyInfo.type == Self.floatType else { return nil }

        var read = SMCParam()
        read.key = Self.key
        read.keyInfo.size = metadata.keyInfo.size
        read.data8 = 5 // read key
        guard let result = call(read) else { return nil }
        let value = withUnsafeBytes(of: result.bytes) { $0.load(as: Float.self) }
        let watts = Double(value)
        return watts.isFinite && watts > 0 ? watts : nil
    }

    private func call(_ input: SMCParam) -> SMCParam? {
        var input = input
        var output = SMCParam()
        var outputSize = MemoryLayout<SMCParam>.size
        guard MemoryLayout<SMCParam>.size == 80,
              MemoryLayout<SMCParam>.offset(of: \.data8) == 42,
              MemoryLayout<SMCParam>.offset(of: \.bytes) == 48,
              IOConnectCallStructMethod(connection, 2, &input, MemoryLayout<SMCParam>.size,
                                        &output, &outputSize) == KERN_SUCCESS,
              outputSize == 80, output.result == 0 else { return nil }
        return output
    }
}

private struct SMCVersion {
    var major: UInt8 = 0
    var minor: UInt8 = 0
    var build: UInt8 = 0
    var reserved: UInt8 = 0
    var release: UInt16 = 0
}

private struct SMCLimits {
    var version: UInt16 = 0
    var length: UInt16 = 0
    var cpu: UInt32 = 0
    var gpu: UInt32 = 0
    var memory: UInt32 = 0
}

private struct SMCKeyInfo {
    var size: UInt32 = 0
    var type: UInt32 = 0
    // AppleSMC's C struct pads the 8-bit attribute field to four bytes.
    var attributesAndPadding: UInt32 = 0
}

private struct SMCParam {
    var key: UInt32 = 0
    var version = SMCVersion()
    var limits = SMCLimits()
    var keyInfo = SMCKeyInfo()
    var result: UInt8 = 0
    var status: UInt8 = 0
    var data8: UInt8 = 0
    var data32: UInt32 = 0
    var bytes = (UInt64(0), UInt64(0), UInt64(0), UInt64(0))
}
