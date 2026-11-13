import Foundation
@testable import RestCore

/// 테스트는 항상 서울 시간으로 계산합니다.
let seoulCalendar = RestCalendar(timeZone: TimeZone(identifier: "Asia/Seoul")!)

/// 서울 시간 기준 날짜. 예: date(2026, 11, 16, 9) = 2026-11-16 09:00
func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0) -> Date {
    seoulCalendar.calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
}

func calculator(trackingStart: Date) -> RestCalculator {
    RestCalculator(trackingStart: trackingStart, restCalendar: seoulCalendar)
}

func worked(_ start: Date, _ end: Date?) -> SessionRecord {
    SessionRecord(kind: .work, start: start, end: end)
}

func slept(_ start: Date, _ end: Date?) -> SessionRecord {
    SessionRecord(kind: .sleep, start: start, end: end)
}

let hour: TimeInterval = 3600
