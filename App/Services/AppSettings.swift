import Foundation

/// 간단한 설정값 (3단계에서 위젯과 공유하기 위해 App Group으로 옮길 예정)
enum AppSettings {
    private static let installedAtKey = "installedAt"

    /// 처음 실행한 시각. 없으면 지금으로 저장합니다.
    static func installedAt(defaults: UserDefaults = .standard) -> Date {
        if let saved = defaults.object(forKey: installedAtKey) as? Date {
            return saved
        }
        let now = Date.now
        defaults.set(now, forKey: installedAtKey)
        return now
    }
}
