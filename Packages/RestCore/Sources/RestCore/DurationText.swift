import Foundation

public enum DurationText {
    /// "14시간 22분", "3시간", "22분", "0분"
    public static func hoursMinutes(_ interval: TimeInterval) -> String {
        let totalMinutes = max(0, Int(interval)) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours == 0 { return "\(minutes)분" }
        if minutes == 0 { return "\(hours)시간" }
        return "\(hours)시간 \(minutes)분"
    }

    /// "00:42:10"
    public static func clock(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval))
        return String(format: "%02d:%02d:%02d", total / 3600, (total % 3600) / 60, total % 60)
    }
}
