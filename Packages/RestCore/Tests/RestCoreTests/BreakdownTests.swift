import Foundation
import Testing
@testable import RestCore

@Suite("쉼 / 일함 / 잠 계산")
struct BreakdownTests {
    // 2026-11-16은 월요일
    let calc = calculator(trackingStart: date(2026, 11, 1))

    @Test("기록하지 않은 시간은 전부 쉼")
    func everythingIsRestByDefault() {
        let day = seoulCalendar.day(containing: date(2026, 11, 16))
        let result = calc.breakdown(in: day, sessions: [], now: date(2026, 11, 17))
        #expect(result == TimeBreakdown(rest: 24 * hour))
    }

    @Test("쉼 = 경과 − 일함 − 잠")
    func restIsElapsedMinusWorkAndSleep() {
        let day = seoulCalendar.day(containing: date(2026, 11, 16))
        let sessions = [
            slept(date(2026, 11, 16, 0), date(2026, 11, 16, 7)),
            worked(date(2026, 11, 16, 10), date(2026, 11, 16, 12)),
        ]
        let result = calc.breakdown(in: day, sessions: sessions, now: date(2026, 11, 16, 18))
        #expect(result.sleep == 7 * hour)
        #expect(result.work == 2 * hour)
        #expect(result.rest == 9 * hour) // 18시간 경과 − 2 − 7
    }

    @Test("진행 중인 세션은 지금까지로 계산")
    func activeSessionCountsUntilNow() {
        let day = seoulCalendar.day(containing: date(2026, 11, 16))
        let sessions = [worked(date(2026, 11, 16, 9), nil)]
        let result = calc.breakdown(in: day, sessions: sessions, now: date(2026, 11, 16, 11, 30))
        #expect(result.work == 2.5 * hour)
        #expect(result.rest == 9 * hour)
    }

    @Test("설치 전 시간은 계산하지 않음")
    func ignoresTimeBeforeTracking() {
        let calc = calculator(trackingStart: date(2026, 11, 16, 15))
        let day = seoulCalendar.day(containing: date(2026, 11, 16))
        let result = calc.breakdown(in: day, sessions: [], now: date(2026, 11, 16, 18))
        #expect(result == TimeBreakdown(rest: 3 * hour))
    }

    @Test("자정을 넘는 잠은 날짜별로 나뉨")
    func splitsAcrossMidnight() {
        let sessions = [slept(date(2026, 11, 16, 23), date(2026, 11, 17, 7))]
        let now = date(2026, 11, 18)
        let monday = calc.breakdown(in: seoulCalendar.day(containing: date(2026, 11, 16)), sessions: sessions, now: now)
        let tuesday = calc.breakdown(in: seoulCalendar.day(containing: date(2026, 11, 17)), sessions: sessions, now: now)
        #expect(monday.sleep == 1 * hour)
        #expect(tuesday.sleep == 7 * hour)
    }

    @Test("기록 시작은 설치 시각과 가장 이른 세션 중 이른 쪽")
    func trackingStartMovesEarlier() {
        let installed = date(2026, 11, 16, 12)
        #expect(RestCalculator.trackingStart(installedAt: installed, sessions: []) == installed)
        let earlier = worked(date(2026, 11, 15, 9), date(2026, 11, 15, 10))
        #expect(RestCalculator.trackingStart(installedAt: installed, sessions: [earlier]) == date(2026, 11, 15, 9))
    }

    @Test("현재 상태")
    func currentStatus() {
        let now = date(2026, 11, 16, 20)
        #expect(calc.currentStatus(sessions: [], now: now) == .resting(since: date(2026, 11, 1)))

        let ended = [worked(date(2026, 11, 16, 9), date(2026, 11, 16, 18))]
        #expect(calc.currentStatus(sessions: ended, now: now) == .resting(since: date(2026, 11, 16, 18)))

        let working = ended + [worked(date(2026, 11, 16, 19), nil)]
        #expect(calc.currentStatus(sessions: working, now: now) == .working(since: date(2026, 11, 16, 19)))

        let sleeping = [slept(date(2026, 11, 16, 19), nil)]
        #expect(calc.currentStatus(sessions: sleeping, now: now) == .sleeping(since: date(2026, 11, 16, 19)))
    }
}

@Suite("24시간 바")
struct SegmentTests {
    @Test("설치 전 · 쉼 · 잠 · 일함 · 미래 순서")
    func segmentsInOrder() {
        let calc = calculator(trackingStart: date(2026, 11, 16, 2))
        let day = seoulCalendar.day(containing: date(2026, 11, 16))
        let sessions = [
            slept(date(2026, 11, 16, 3), date(2026, 11, 16, 8)),
            worked(date(2026, 11, 16, 9), date(2026, 11, 16, 12)),
        ]
        let segments = calc.segments(for: day, sessions: sessions, now: date(2026, 11, 16, 15))

        #expect(segments.map(\.state) == [.untracked, .rest, .sleep, .rest, .work, .rest, .future])
        #expect(segments.map(\.interval.duration) == [2, 1, 5, 1, 3, 3, 9].map { $0 * hour })
        #expect(segments.first?.interval.start == day.start)
        #expect(segments.last?.interval.end == day.end)
    }

    @Test("하루가 끝났으면 미래 칸이 없음")
    func noFutureForPastDay() {
        let calc = calculator(trackingStart: date(2026, 11, 1))
        let day = seoulCalendar.day(containing: date(2026, 11, 16))
        let segments = calc.segments(for: day, sessions: [], now: date(2026, 11, 20))
        #expect(segments == [TimelineSegment(state: .rest, interval: day)])
    }

    @Test("진행 중인 세션은 지금에서 끊김")
    func activeSessionStopsAtNow() {
        let calc = calculator(trackingStart: date(2026, 11, 1))
        let day = seoulCalendar.day(containing: date(2026, 11, 16))
        let segments = calc.segments(for: day, sessions: [worked(date(2026, 11, 16, 10), nil)], now: date(2026, 11, 16, 11))
        #expect(segments.map(\.state) == [.rest, .work, .future])
        #expect(segments[1].interval.duration == 1 * hour)
    }
}
