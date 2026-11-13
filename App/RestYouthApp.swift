import SwiftUI
import SwiftData

@main
struct RestYouthApp: App {
    /// 처음 실행한 시각. 이 시각부터 '쉼'이 쌓이기 시작합니다.
    private let installedAt = AppSettings.installedAt()

    var body: some Scene {
        WindowGroup {
            MainView(installedAt: installedAt)
        }
        .modelContainer(for: Session.self)
    }
}
