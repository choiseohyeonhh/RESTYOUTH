import SwiftUI
import SwiftData
import RestCore

struct MainView: View {
    let installedAt: Date

    @Environment(\.modelContext) private var context
    @Query(sort: \Session.startAt) private var sessions: [Session]

    @State private var toastMessage: String?
    @State private var tapCount = 0

    var body: some View {
        // 1초마다 다시 그려서 경과 시간과 바가 실시간으로 움직이게 합니다.
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            let now = timeline.date
            let records = sessions.map(\.record)
            let calc = RestCalculator(
                trackingStart: RestCalculator.trackingStart(installedAt: installedAt, sessions: records)
            )
            content(now: now, records: records, calc: calc)
        }
        .overlay(alignment: .bottom) { toast }
        .sensoryFeedback(.impact, trigger: tapCount)
    }

    // MARK: - 화면 구성

    @ViewBuilder
    private func content(now: Date, records: [SessionRecord], calc: RestCalculator) -> some View {
        let today = calc.restCalendar.day(containing: now)
        let status = calc.currentStatus(sessions: records, now: now)
        let breakdown = calc.breakdown(in: today, sessions: records, now: now)

        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Text(now.formatted(Self.dateFormat))
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text(statusText(status, now: now))
                    .font(.title2.bold())
                    .monospacedDigit()

                DayBar(segments: calc.segments(for: today, sessions: records, now: now), day: today)

                HStack {
                    stat("쉼", breakdown.rest, color: Theme.rest)
                    stat("일함", breakdown.work, color: Theme.work)
                    stat("잠", breakdown.sleep, color: Theme.sleep)
                }

                HStack(spacing: 12) {
                    toggleButton(.work, status: status)
                    toggleButton(.sleep, status: status)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(gradeText(calc: calc, records: records, now: now))
                        .font(.headline)
                    Text(streakText(calc: calc, records: records, now: now))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(24)
        }
    }

    private func stat(_ title: String, _ value: TimeInterval, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Circle().fill(color).frame(width: 8, height: 8)
                Text(title).font(.caption).foregroundStyle(.secondary)
            }
            Text(DurationText.hoursMinutes(value))
                .font(.body.weight(.semibold))
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func toggleButton(_ kind: SessionKind, status: CurrentStatus) -> some View {
        let isActive: Bool = switch (kind, status) {
        case (.work, .working), (.sleep, .sleeping): true
        default: false
        }
        let title: String = switch kind {
        case .work: isActive ? "일 끝" : "일했음"
        case .sleep: isActive ? "기상" : "잠잤음"
        }
        let icon: String = switch kind {
        case .work: isActive ? "checkmark.circle.fill" : "briefcase.fill"
        case .sleep: isActive ? "sun.max.fill" : "moon.zzz.fill"
        }

        return Button {
            let outcome = SessionActions.toggle(kind, in: context)
            tapCount += 1
            showToast(outcome.message)
        } label: {
            Label(title, systemImage: icon)
                .font(.title3.bold())
                .frame(maxWidth: .infinity, minHeight: 64)
        }
        .buttonStyle(.borderedProminent)
        .tint(kind == .work ? Theme.work : Theme.sleep)
    }

    @ViewBuilder
    private var toast: some View {
        if let toastMessage {
            Text(toastMessage)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.thinMaterial, in: Capsule())
                .padding(.bottom, 24)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    // MARK: - 문구

    private static let dateFormat = Date.FormatStyle(locale: Locale(identifier: "ko_KR"))
        .month().day().weekday(.abbreviated)

    private func statusText(_ status: CurrentStatus, now: Date) -> String {
        switch status {
        case .resting(let since):
            "쉬는 중 · \(DurationText.hoursMinutes(now.timeIntervalSince(since)))째"
        case .working(let since):
            "일하는 중 · \(DurationText.clock(now.timeIntervalSince(since)))"
        case .sleeping(let since):
            "자는 중 · \(DurationText.hoursMinutes(now.timeIntervalSince(since)))째"
        }
    }

    private func gradeText(calc: RestCalculator, records: [SessionRecord], now: Date) -> String {
        if let grade = calc.projectedGrade(sessions: records, now: now).grade {
            return "\(grade.badge) \(grade.title) (이번 주 예상)"
        }
        if let grade = calc.confirmedGrade(sessions: records, now: now).grade {
            return "\(grade.badge) \(grade.title) (지난주)"
        }
        return "📝 등급 심사 중 · 평일을 하루 온전히 보내면 나와요"
    }

    private func streakText(calc: RestCalculator, records: [SessionRecord], now: Date) -> String {
        let current = calc.currentWorkFreeDuration(sessions: records, now: now)
        guard current > 0 else { return "무사고 기록은 잠시 쉬어 가는 중이에요." }
        return "현재 \(DurationText.hoursMinutes(current))째 무사고 쉼"
    }

    // MARK: - 토스트

    private func showToast(_ message: String) {
        withAnimation { toastMessage = message }
        Task {
            try? await Task.sleep(for: .seconds(2.5))
            withAnimation {
                if toastMessage == message { toastMessage = nil }
            }
        }
    }
}

#Preview {
    MainView(installedAt: .now.addingTimeInterval(-3 * 86_400))
        .modelContainer(for: Session.self, inMemory: true)
}
