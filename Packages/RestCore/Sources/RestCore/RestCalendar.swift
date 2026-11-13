import Foundation

/// 날짜 경계(자정), 주 시작(월요일), 평일·공휴일 판단을 담당합니다.
public struct RestCalendar: Sendable {
    public let calendar: Calendar

    public init(timeZone: TimeZone = .current) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        calendar.locale = Locale(identifier: "ko_KR")
        calendar.firstWeekday = 2 // 월요일 시작
        self.calendar = calendar
    }

    public func day(containing date: Date) -> DateInterval {
        calendar.dateInterval(of: .day, for: date)!
    }

    /// 월요일 00:00부터 다음 월요일 00:00까지
    public func week(containing date: Date) -> DateInterval {
        calendar.dateInterval(of: .weekOfYear, for: date)!
    }

    public func month(containing date: Date) -> DateInterval {
        calendar.dateInterval(of: .month, for: date)!
    }

    /// `range`와 조금이라도 겹치는 모든 날(하루 단위 구간)
    public func days(in range: DateInterval) -> [DateInterval] {
        var result: [DateInterval] = []
        var cursor = day(containing: range.start)
        while cursor.start < range.end {
            result.append(cursor)
            cursor = day(containing: cursor.end)
        }
        return result
    }

    /// 그날 `hour`시 정각
    public func date(on day: DateInterval, hour: Int) -> Date {
        calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day.start)!
    }

    public func isWeekday(_ date: Date) -> Bool {
        let weekday = calendar.component(.weekday, from: date) // 1 = 일요일, 7 = 토요일
        return weekday != 1 && weekday != 7
    }

    public func isHoliday(_ date: Date) -> Bool {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        let key = String(format: "%04d-%02d-%02d", c.year!, c.month!, c.day!)
        return RestConstants.holidays.contains(key)
    }

    /// 공휴일이 아닌 평일
    public func isBusinessDay(_ date: Date) -> Bool {
        isWeekday(date) && !isHoliday(date)
    }

    public func year(of date: Date) -> Int {
        calendar.component(.year, from: date)
    }
}
