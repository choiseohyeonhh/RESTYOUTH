import Foundation
import Testing
@testable import RestCore

@Suite("무사고 쉼")
struct StreakTests {
    let calc = calculator(trackingStart: date(2026, 11, 16))
    let sessions = [
        worked(date(2026, 11, 16, 9), date(2026, 11, 16, 18)),
        slept(date(2026, 11, 16, 23), date(2026, 11, 17, 7)),   // 잠은 기록을 끊지 않음
        worked(date(2026, 11, 18, 9), date(2026, 11, 18, 10)),
    ]

    @Test("현재 기록 = 마지막 일 끝난 뒤부터 지금까지")
    func current() {
        let now = date(2026, 11, 19, 10)
        #expect(calc.currentWorkFreeDuration(sessions: sessions, now: now) == 24 * hour)
    }

    @Test("일하는 중이면 0")
    func zeroWhileWorking() {
        let now = date(2026, 11, 19, 10)
        let working = sessions + [worked(date(2026, 11, 19, 9), nil)]
        #expect(calc.currentWorkFreeDuration(sessions: working, now: now) == 0)
    }

    @Test("역대 최고는 잠을 포함한 가장 긴 구간")
    func longest() {
        let now = date(2026, 11, 18, 20)
        let longest = calc.longestWorkFreeStretch(sessions: sessions, now: now)
        #expect(longest == DateInterval(start: date(2026, 11, 16, 18), end: date(2026, 11, 18, 9)))
    }

    @Test("기간을 주면 그 안으로 잘라서 봄")
    func longestInRange() {
        let now = date(2026, 11, 18, 20)
        let range = DateInterval(start: date(2026, 11, 17), end: date(2026, 11, 18))
        let longest = calc.longestWorkFreeStretch(in: range, sessions: sessions, now: now)
        #expect(longest?.duration == 24 * hour)
    }
}

@Suite("쉬었음 등급")
struct GradeTests {
    @Test("경계값", arguments: [
        (0.0, Grade.apprentice), (5.9, Grade.apprentice),
        (6.0, Grade.skilled), (8.9, Grade.skilled),
        (9.0, Grade.pro), (12.0, Grade.master), (14.0, Grade.national), (24.0, Grade.national),
    ])
    func thresholds(hours: Double, expected: Grade) {
        #expect(Grade.grade(forAverageRestHours: hours) == expected)
    }

    /// 매 평일 잠 0–8시, 일 9–17시 → 쉼 8시간
    func officeWeek() -> [SessionRecord] {
        (16...20).flatMap { day in
            [
                slept(date(2026, 11, day, 0), date(2026, 11, day, 8)),
                worked(date(2026, 11, day, 9), date(2026, 11, day, 17)),
            ]
        }
    }

    @Test("평일 평균 쉰 시간으로 등급 (주말 제외)")
    func gradedFromWeekdays() {
        let calc = calculator(trackingStart: date(2026, 11, 16))
        let week = seoulCalendar.week(containing: date(2026, 11, 16))
        let result = calc.evaluateGrade(week: week, sessions: officeWeek(), now: date(2026, 11, 23), minimumDays: 3)
        #expect(result == .graded(.skilled, averageRestHours: 8, countedDays: 5))
    }

    @Test("온전히 기록된 평일이 부족하면 심사 중")
    func pendingWhenTooFewDays() {
        // 수요일 낮에 설치 → 목, 금만 온전한 평일
        let calc = calculator(trackingStart: date(2026, 11, 18, 13))
        let week = seoulCalendar.week(containing: date(2026, 11, 16))
        let result = calc.evaluateGrade(week: week, sessions: [], now: date(2026, 11, 23), minimumDays: 3)
        #expect(result == .pending(countedDays: 2, requiredDays: 3))
    }

    @Test("지난주 확정 등급과 이번 주 예상 등급")
    func confirmedAndProjected() {
        let calc = calculator(trackingStart: date(2026, 11, 16))
        let now = date(2026, 11, 24, 12) // 다음 주 화요일 낮 → 이번 주 온전한 평일은 월요일 하루
        #expect(calc.confirmedGrade(sessions: officeWeek(), now: now).grade == .skilled)
        // 월요일에 아무것도 안 했으니 24시간 쉼
        #expect(calc.projectedGrade(sessions: officeWeek(), now: now) == .graded(.national, averageRestHours: 24, countedDays: 1))
    }
}

@Suite("버튼 규칙")
struct ToggleTests {
    let now = date(2026, 11, 16, 12)

    @Test("아무것도 없으면 시작")
    func startsWhenIdle() {
        #expect(SessionRules.toggle(.work, active: nil, now: now) == TogglePlan(kindToStart: .work))
    }

    @Test("같은 종류면 종료")
    func stopsSameKind() {
        let active = worked(date(2026, 11, 16, 9), nil)
        #expect(SessionRules.toggle(.work, active: active, now: now) == TogglePlan(activeToClose: active.id))
    }

    @Test("다른 종류면 끝내고 새로 시작")
    func switchesKind() {
        let active = worked(date(2026, 11, 16, 9), nil)
        #expect(SessionRules.toggle(.sleep, active: active, now: now)
                == TogglePlan(activeToClose: active.id, kindToStart: .sleep))
    }

    @Test("1분 미만이면 버림")
    func discardsTooShort() {
        let active = worked(now.addingTimeInterval(-30), nil)
        #expect(SessionRules.toggle(.work, active: active, now: now)
                == TogglePlan(activeToClose: active.id, discardClosed: true))
    }
}

@Suite("시간 표시")
struct DurationTextTests {
    @Test func hoursMinutes() {
        #expect(DurationText.hoursMinutes(0) == "0분")
        #expect(DurationText.hoursMinutes(22 * 60 + 59) == "22분")
        #expect(DurationText.hoursMinutes(3 * hour) == "3시간")
        #expect(DurationText.hoursMinutes(14 * hour + 22 * 60) == "14시간 22분")
    }

    @Test func clock() {
        #expect(DurationText.clock(42 * 60 + 10) == "00:42:10")
        #expect(DurationText.clock(25 * hour) == "25:00:00")
    }
}
