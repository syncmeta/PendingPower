import Foundation

// Quick smoke test: sample the same IOReport and SMC sources as the app.
// Compile this file as main.swift together with the three monitor source files.

let monitor = PowerMonitor.make()
guard let m = monitor else {
    print("FAIL: PowerMonitor.make returned nil")
    exit(1)
}

var ticks = 0
m.onUpdate = { r in
    ticks += 1
    let total = r.total.map { String(format: "%.2fW", $0) } ?? "unavailable"
    print(String(format: "tick %d  total=%@  cpu=%.2f gpu=%.2f ane=%.2f other=%.2f breakdown=%@",
                 ticks, total, r.cpu, r.gpu, r.ane, r.other,
                 r.breakdownAvailable ? "available" : "unavailable"))
    if ticks >= 3 { exit(0) }
}
m.start(interval: 1.0)
RunLoop.main.run()
