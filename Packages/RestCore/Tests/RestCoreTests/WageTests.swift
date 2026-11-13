import Foundation
import Testing
@testable import RestCore

@Suite("날린 일당")
struct WageTests {
    let calc = calculator(trackingStart: date(2026, 11, 1))

    @Test("평일 하루 전부 쉼 = 8시간 × 10,320원")
    func fullWeekday() {
        let day = seoulCalendar.day(containing: date(2026, 11, 16)) // 월
        let result = calc.lostWage(in: day, sessions: [], now: date(2026, 11, 17))
        #expect(result.lostSeconds == 8 * hour)
        #expect(result.won == 82_560)
    }

    @Test("평일 5일 전부 쉼 = 412,800원 (주말은 0)")
    func fullWeek() {
        let week = seoulCalendar.week(containing: date(2026, 11, 18))
        let result = calc.lostWage(in: week, sessions: [], now: date(2026, 11, 30))
        #expect(result.lostSeconds == 40 * hour)
        #expect(result.won == 412_800)
    }

    @Test("일한 시간은 빼고, 낮잠은 날린 일당에 포함")
    func workSubtractedSleepIncluded() {
        let day = seoulCalendar.day(containing: date(2026, 11, 16))
        let sessions = [
            worked(date(2026, 11, 16, 10), date(2026, 11, 16, 11)),
            slept(date(2026, 11, 16, 14), date(2026, 11, 16, 16)),
            worked(date(2026, 11, 16, 12), date(2026, 11, 16, 13)), // 점심시간 근무는 근무창 밖
        ]
        let result = calc.lostWage(in: day, sessions: sessions, now: date(2026, 11, 17))
        #expect(result.lostSeconds == 7 * hour)
    }

    @Test("공휴일은 제외 (2026-12-25 금)")
    func holidayExcluded() {
        let day = seoulCalendar.day(containing: date(2026, 12, 25))
        #expect(calc.lostWage(in: day, sessions: [], now: date(2026, 12, 26)) == .zero)
    }

    @Test("지금 이후와 기록 시작 전은 제외")
    func clippedToTrackedTime() {
        let calc = calculator(trackingStart: date(2026, 11, 16, 10))
        let day = seoulCalendar.day(containing: date(2026, 11, 16))
        let result = calc.lostWage(in: day, sessions: [], now: date(2026, 11, 16, 14))
        #expect(result.lostSeconds == 3 * hour) // 10–12, 13–14
    }

    @Test("미입력 연도는 최근 연도 최저시급 사용")
    func wageFallback() {
        #expect(RestConstants.minimumWage(forYear: 2026) == 10_320)
        #expect(RestConstants.minimumWage(forYear: 2030) == RestConstants.minimumWageByYear[RestConstants.minimumWageByYear.keys.max()!])
    }
}
