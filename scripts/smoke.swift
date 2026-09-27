import Foundation

// Compile as main.swift together with SMCPowerReader.swift to probe PSTR.
guard let reader = SMCPowerReader() else {
    print("FAIL: AppleSMC unavailable")
    exit(1)
}

for sample in 1...3 {
    guard let watts = reader.readWatts() else {
        print("FAIL: PSTR unavailable")
        exit(1)
    }
    print(String(format: "sample %d  system=%.2f W", sample, watts))
    if sample < 3 { Thread.sleep(forTimeInterval: 1) }
}
