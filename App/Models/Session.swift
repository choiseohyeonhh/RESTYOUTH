import Foundation
import SwiftData
import RestCore

/// 일함 또는 잠 한 구간 (SwiftData 저장용)
///
/// 나중에 iCloud 동기화를 켤 수 있도록 모든 속성에 기본값을 두고,
/// `@Attribute(.unique)`는 쓰지 않습니다.
@Model
final class Session {
    var id: UUID = UUID()
    var kindRaw: String = SessionKind.work.rawValue
    var startAt: Date = Date.now
    /// nil이면 진행 중
    var endAt: Date? = nil
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now

    init(kind: SessionKind, startAt: Date, endAt: Date? = nil) {
        self.id = UUID()
        self.kindRaw = kind.rawValue
        self.startAt = startAt
        self.endAt = endAt
        self.createdAt = .now
        self.updatedAt = .now
    }

    var kind: SessionKind {
        get { SessionKind(rawValue: kindRaw) ?? .work }
        set { kindRaw = newValue.rawValue }
    }

    /// 계산 로직(RestCore)에 넘길 값
    var record: SessionRecord {
        SessionRecord(id: id, kind: kind, start: startAt, end: endAt)
    }
}
