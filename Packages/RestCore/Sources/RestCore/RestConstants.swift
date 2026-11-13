import Foundation

/// 매년 갱신해야 하는 숫자와 조정 가능한 기준값을 한곳에 모았습니다.
public enum RestConstants {

    // MARK: - 최저시급 (원)

    /// 연도별 최저시급. 새 연도 값이 고시되면 여기에 추가하세요.
    public static let minimumWageByYear: [Int: Int] = [
        2026: 10_320,
        // 2027: TODO — 2027년 최저시급 확인 후 입력
    ]

    /// 해당 연도 최저시급. 아직 입력하지 않은 연도는 가장 최근 연도 값을 씁니다.
    public static func minimumWage(forYear year: Int) -> Int {
        if let wage = minimumWageByYear[year] { return wage }
        let years = minimumWageByYear.keys.sorted()
        let fallbackYear = years.last(where: { $0 < year }) ?? years.first!
        return minimumWageByYear[fallbackYear]!
    }

    // MARK: - 날린 일당 근무창

    public struct HourRange: Sendable, Equatable {
        public let start: Int
        public let end: Int
    }

    /// 평일 09–12시, 13–18시 (점심 1시간 제외, 하루 8시간)
    public static let workWindows: [HourRange] = [
        HourRange(start: 9, end: 12),
        HourRange(start: 13, end: 18),
    ]

    // MARK: - 공휴일 ("yyyy-MM-dd")

    /// 대체공휴일·임시공휴일 포함. 주말에 겹친 날이 들어 있어도 문제없습니다.
    public static let holidays: Set<String> = [
        // 2026
        // TODO: 노동절(5/1)·제헌절(7/17)의 공휴일 지정 여부 확인
        "2026-01-01",
        "2026-02-16", "2026-02-17", "2026-02-18",   // 설날
        "2026-03-01", "2026-03-02",                 // 삼일절, 대체
        "2026-05-05",                               // 어린이날
        "2026-05-24", "2026-05-25",                 // 부처님오신날, 대체
        "2026-06-03",                               // 지방선거
        "2026-06-06",                               // 현충일
        "2026-08-15", "2026-08-17",                 // 광복절, 대체
        "2026-09-24", "2026-09-25", "2026-09-26",   // 추석
        "2026-10-03", "2026-10-05",                 // 개천절, 대체
        "2026-10-09",                               // 한글날
        "2026-12-25",                               // 성탄절

        // 2027 (잠정 — 정부 공고 후 반드시 확인)
        "2027-01-01",
        "2027-02-06", "2027-02-07", "2027-02-08", "2027-02-09", // 설날, 대체
        "2027-03-01",
        "2027-05-05",
        "2027-05-13",                               // 부처님오신날
        "2027-06-06",
        "2027-08-15", "2027-08-16",                 // 광복절, 대체
        "2027-09-14", "2027-09-15", "2027-09-16",   // 추석
        "2027-10-03", "2027-10-04",                 // 개천절, 대체
        "2027-10-09", "2027-10-11",                 // 한글날, 대체
        "2027-12-25", "2027-12-27",                 // 성탄절, 대체
    ]

    // MARK: - 등급

    /// 평일 하루 평균 쉰 시간(잠 제외) 경계값. 견습 | 숙련 | 프로 | 장인 | 국가대표
    public static let gradeThresholdHours: [Double] = [6, 9, 12, 14]

    /// 지난주 등급을 확정하려면 온전히 기록된 평일이 이만큼 있어야 합니다.
    public static let confirmedGradeMinimumDays = 3

    /// 이번 주 예상 등급은 하루만 있어도 보여 줍니다.
    public static let projectedGradeMinimumDays = 1

    // MARK: - 기록

    /// 이보다 짧은 세션은 실수로 보고 버립니다.
    public static let minimumSessionDuration: TimeInterval = 60
}
