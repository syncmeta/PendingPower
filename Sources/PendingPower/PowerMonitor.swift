import Foundation
import AppKit

struct PowerReading {
    var cpu: Double = 0
    var gpu: Double = 0
    var ane: Double = 0
    var other: Double = 0
    var system: Double?
    var breakdownAvailable = false
    var total: Double? { system ?? (breakdownAvailable ? cpu + gpu + ane + other : nil) }
}

final class PowerMonitor {
    private let bridge: IOReportBridge
    private let systemPower = SMCPowerReader()
    private let sub: IOReportSubscriptionRef
    private let subbed: CFMutableDictionary
    private var lastSample: CFDictionary
    private var lastSampleTime: CFAbsoluteTime
    private var validBreakdownStreak = 0
    private var timer: Timer?

    var onUpdate: ((PowerReading) -> Void)?

    static func make() -> PowerMonitor? {
        guard let bridge = IOReportBridge.shared else {
            NSLog("PendingPower: failed to load libIOReport.dylib")
            return nil
        }
        guard let channels = bridge.copyChannels(group: "Energy Model") else {
            NSLog("PendingPower: IOReportCopyChannelsInGroup(Energy Model) returned nil")
            return nil
        }
        guard let (sub, subbed) = bridge.createSubscription(channels: channels) else {
            NSLog("PendingPower: IOReportCreateSubscription failed")
            return nil
        }
        guard let firstSample = bridge.createSamples(sub, subbed: subbed) else {
            NSLog("PendingPower: IOReportCreateSamples failed")
            return nil
        }
        return PowerMonitor(bridge: bridge, sub: sub, subbed: subbed, firstSample: firstSample)
    }

    private init(bridge: IOReportBridge, sub: IOReportSubscriptionRef, subbed: CFMutableDictionary, firstSample: CFDictionary) {
        self.bridge = bridge
        self.sub = sub
        self.subbed = subbed
        self.lastSample = firstSample
        self.lastSampleTime = CFAbsoluteTimeGetCurrent()
    }

    func start(interval: TimeInterval = 1.0) {
        stop()
        let t = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        guard let now = bridge.createSamples(sub, subbed: subbed) else { return }
        let nowTime = CFAbsoluteTimeGetCurrent()
        let dt = max(nowTime - lastSampleTime, 0.001)

        guard let delta = bridge.createSamplesDelta(prev: lastSample, current: now) else {
            lastSample = now
            lastSampleTime = nowTime
            return
        }

        lastSample = now
        lastSampleTime = nowTime

        var reading = PowerReading()
        var hasActiveEnergyCounters = false

        // The delta dictionary nests channel arrays. IOReportIterate walks each
        // channel sample, and the per-channel integer is energy accumulated
        // during the delta interval, in the unit reported by GetUnitLabel.
        bridge.iterate(samples: delta) { [bridge] ch in
            let energy = Int64(bridge.simpleIntegerValue(ch))
            let unit = bridge.channelUnit(ch) ?? ""
            let joules = Self.energyToJoules(value: Double(energy), unit: unit)
            let watts = joules / dt

            let name = (bridge.channelName(ch) ?? "").lowercased()
            let subgroup = (bridge.channelSubGroup(ch) ?? "").lowercased()
            let bucket = name + " " + subgroup

            // A working Energy Model has changing mJ SoC counters. On some
            // macOS versions every one of them stays at zero while the nJ GPU
            // counter still changes; that is not a valid component breakdown.
            if unit.lowercased().contains("mj") && energy > 0 {
                hasActiveEnergyCounters = true
            }

            if bucket.contains("ane") {
                reading.ane += watts
            } else if bucket.contains("gpu") {
                reading.gpu += watts
            } else if bucket.contains("cpu") {
                reading.cpu += watts
            } else {
                reading.other += watts
            }
            return 0 // kIOReportIterOk — continue
        }

        // Energy counters can briefly produce small negative deltas at sample
        // boundaries; clamp to zero so the UI never flashes negative numbers.
        reading.cpu = max(reading.cpu, 0)
        reading.gpu = max(reading.gpu, 0)
        reading.ane = max(reading.ane, 0)
        reading.other = max(reading.other, 0)
        reading.system = systemPower?.readWatts()
        validBreakdownStreak = hasActiveEnergyCounters ? min(validBreakdownStreak + 1, 3) : 0
        reading.breakdownAvailable = validBreakdownStreak == 3

        let snapshot = reading
        DispatchQueue.main.async { [weak self] in
            self?.onUpdate?(snapshot)
        }
    }

    private static func energyToJoules(value: Double, unit: String) -> Double {
        // Unit labels seen in the wild: "nJ", "uJ", "mJ", "J", and odd
        // "ENERGY (nJ)" wrappers on some macOS versions.
        let u = unit.lowercased()
        if u.contains("nj") { return value * 1e-9 }
        if u.contains("uj") || u.contains("μj") { return value * 1e-6 }
        if u.contains("mj") { return value * 1e-3 }
        if u.contains("j") { return value }
        return value * 1e-9 // sane default for Apple Silicon energy counters
    }
}
