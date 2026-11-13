import Foundation
import SwiftData
import RestCore

enum ToggleOutcome: Equatable {
    case started(SessionKind)
    case stopped(SessionKind)
    /// 1분이 안 돼서 기록하지 않음
    case cancelled

    var message: String {
        switch self {
        case .started(.work): "기록 개시. 쉬었음 관리공단이 놀라고 있습니다."
        case .started(.sleep): "잘 자요. 잠도 기록하고 있을게요."
        case .stopped(.work): "수고했어요. 다시 쉼 모드로 돌아갑니다."
        case .stopped(.sleep): "좋은 아침이에요. 다시 쉼 모드예요."
        case .cancelled: "1분이 안 돼서 기록하지 않았어요."
        }
    }
}

@MainActor
enum SessionActions {
    /// '일했음' / '잠잤음' 버튼을 눌렀을 때. 규칙은 RestCore의 `SessionRules`에 있습니다.
    @discardableResult
    static func toggle(_ kind: SessionKind, in context: ModelContext, now: Date = .now) -> ToggleOutcome {
        let descriptor = FetchDescriptor<Session>(predicate: #Predicate<Session> { $0.endAt == nil })
        let active = (try? context.fetch(descriptor))?.first

        let plan = SessionRules.toggle(kind, active: active?.record, now: now)

        if let active, plan.activeToClose != nil {
            if plan.discardClosed {
                context.delete(active)
            } else {
                active.endAt = now
                active.updatedAt = now
            }
        }
        if let kindToStart = plan.kindToStart {
            context.insert(Session(kind: kindToStart, startAt: now))
        }
        try? context.save()

        if let kindToStart = plan.kindToStart { return .started(kindToStart) }
        if plan.discardClosed { return .cancelled }
        return .stopped(active?.kind ?? kind)
    }
}
