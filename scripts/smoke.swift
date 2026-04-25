import Foundation

// Quick smoke test: load IOReport via the same bridge the app uses,
// take two samples 1 second apart, print derived watts.
// Run from project root: swift scripts/smoke.swift Sources/PendingPower/IOReportBridge.swift Sources/PendingPower/PowerMonitor.swift

let monitor = PowerMonitor.make()
guard let m = monitor else {
    print("FAIL: PowerMonitor.make returned nil")
    exit(1)
}

var ticks = 0
m.onUpdate = { r in
    ticks += 1
    print(String(format: "tick %d  total=%.2fW  cpu=%.2f gpu=%.2f ane=%.2f other=%.2f",
                 ticks, r.total, r.cpu, r.gpu, r.ane, r.other))
    if ticks >= 3 { exit(0) }
}
m.start(interval: 1.0)
RunLoop.main.run()
