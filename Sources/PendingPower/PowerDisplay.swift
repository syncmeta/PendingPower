import Foundation

enum PowerDisplay {
    static func format(_ watts: Double) -> String {
        guard watts.isFinite else { return "— W" }
        let magnitude = abs(watts)
        // Choose precision after rounding so 9.999 and 99.99 don't gain a digit.
        if (magnitude * 100).rounded() / 100 < 10 {
            return String(format: "%.2f W", watts)
        } else if (magnitude * 10).rounded() / 10 < 100 {
            return String(format: "%.1f W", watts)
        } else {
            return String(format: "%.0f W", watts)
        }
    }
}
