import Foundation

/// 버튼을 눌렀을 때 무엇을 해야 하는지
public struct TogglePlan: Sendable, Equatable {
    /// 끝내야 할 진행 중 세션
    public var activeToClose: UUID?
    /// 끝낸 세션이 1분 미만이라 기록하지 않고 버림
    public var discardClosed: Bool
    /// 새로 시작할 종류
    public var kindToStart: SessionKind?

    public init(activeToClose: UUID? = nil, discardClosed: Bool = false, kindToStart: SessionKind? = nil) {
        self.activeToClose = activeToClose
        self.discardClosed = discardClosed
        self.kindToStart = kindToStart
    }
}

public enum SessionRules {
    /// '일했음' / '잠잤음' 버튼 규칙 (PRD 3장, 결정 8)
    /// - 진행 중인 게 없으면: 시작
    /// - 같은 종류가 진행 중이면: 종료
    /// - 다른 종류가 진행 중이면: 그걸 끝내고 새로 시작
    /// - 끝내는 세션이 1분 미만이면: 버림
    public static func toggle(_ kind: SessionKind, active: SessionRecord?, now: Date) -> TogglePlan {
        guard let active else {
            return TogglePlan(kindToStart: kind)
        }
        let tooShort = now.timeIntervalSince(active.start) < RestConstants.minimumSessionDuration
        return TogglePlan(
            activeToClose: active.id,
            discardClosed: tooShort,
            kindToStart: active.kind == kind ? nil : kind
        )
    }
}
