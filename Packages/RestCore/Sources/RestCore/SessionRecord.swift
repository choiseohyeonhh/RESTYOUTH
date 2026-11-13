import Foundation

/// 기록할 수 있는 상태. '쉼'은 기본값이라 기록하지 않습니다.
public enum SessionKind: String, Codable, Sendable, CaseIterable {
    case work
    case sleep
}

/// 일함 또는 잠 한 구간. 저장 방식(SwiftData)과 무관한 순수 값 타입입니다.
public struct SessionRecord: Sendable, Equatable, Identifiable {
    public var id: UUID
    public var kind: SessionKind
    public var start: Date
    /// nil이면 진행 중
    public var end: Date?

    public init(id: UUID = UUID(), kind: SessionKind, start: Date, end: Date? = nil) {
        self.id = id
        self.kind = kind
        self.start = start
        self.end = end
    }

    public var isActive: Bool { end == nil }

    /// 세션이 차지하는 구간. 진행 중이면 `now`까지로 봅니다. 길이가 0 이하면 nil.
    public func interval(now: Date) -> DateInterval? {
        let end = self.end ?? now
        guard end > start else { return nil }
        return DateInterval(start: start, end: end)
    }
}

extension DateInterval {
    /// 두 구간이 겹치는 길이(초). 안 겹치면 0.
    func overlapDuration(with other: DateInterval) -> TimeInterval {
        let start = Swift.max(self.start, other.start)
        let end = Swift.min(self.end, other.end)
        return Swift.max(0, end.timeIntervalSince(start))
    }

    /// `other` 안으로 잘라 낸 구간. 겹치는 부분이 없으면 nil.
    func clipped(to other: DateInterval) -> DateInterval? {
        let start = Swift.max(self.start, other.start)
        let end = Swift.min(self.end, other.end)
        guard end > start else { return nil }
        return DateInterval(start: start, end: end)
    }
}
