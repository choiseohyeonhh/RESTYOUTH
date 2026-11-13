import SwiftUI
import RestCore

/// 상태별 색 (가안 — 비주얼 방향이 정해지면 여기만 바꾸면 됩니다)
enum Theme {
    static let rest = Color(red: 0.55, green: 0.80, blue: 0.35)   // 연두
    static let work = Color(red: 0.56, green: 0.58, blue: 0.62)   // 회색
    static let sleep = Color(red: 0.30, green: 0.32, blue: 0.70)  // 남색
    static let untracked = Color.gray.opacity(0.25)
    static let future = Color.gray.opacity(0.12)
}

extension TimelineState {
    var color: Color {
        switch self {
        case .rest: Theme.rest
        case .work: Theme.work
        case .sleep: Theme.sleep
        case .untracked: Theme.untracked
        case .future: Theme.future
        }
    }
}
