import AppKit

// Run with PowerDisplay.swift to check rounding boundaries without reading SMC.
@main
enum CheckPowerDisplay {
    static func main() {
        let cases: [(Double, String)] = [
            (0, "0.00 W"), (8.34, "8.34 W"), (9.994, "9.99 W"),
            (9.996, "10.0 W"), (9.999, "10.0 W"), (10, "10.0 W"),
            (99.94, "99.9 W"), (99.96, "100 W"), (99.99, "100 W"),
            (100, "100 W"), (147, "147 W"), (1000, "1000 W"),
            (-9.999, "-10.0 W"), (-99.99, "-100 W"),
            (.nan, "— W"), (.infinity, "— W"),
        ]
        for (watts, expected) in cases {
            let actual = PowerDisplay.format(watts)
            precondition(actual == expected, "\(watts): expected \(expected), got \(actual)")
        }
        // Sweep both transitions to catch any format that gains an extra digit.
        for step in 99000...100100 {
            let display = PowerDisplay.format(Double(step) / 10000)
            precondition(!display.hasPrefix("10.00"), display)
        }
        for step in 999000...1000100 {
            let display = PowerDisplay.format(Double(step) / 10000)
            precondition(!display.hasPrefix("100.0"), display)
        }
        print("Power display checks passed (16 cases and both rounding transitions).")
    }
}
