import Foundation

/// 쉬었음 등급. 평일 하루 평균 쉰 시간(잠 제외)으로 정합니다.
public enum Grade: Int, CaseIterable, Comparable, Sendable {
    case apprentice = 1
    case skilled
    case pro
    case master
    case national

    public var title: String {
        switch self {
        case .apprentice: "견습 쉬었음러"
        case .skilled: "숙련 쉬었음러"
        case .pro: "프로 쉬었음러"
        case .master: "쉬었음 장인"
        case .national: "쉬었음 국가대표"
        }
    }

    public var badge: String {
        switch self {
        case .apprentice: "🌱"
        case .skilled: "🛋️"
        case .pro: "😎"
        case .master: "🧘"
        case .national: "🏅"
        }
    }

    public static func < (lhs: Grade, rhs: Grade) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    public static func grade(forAverageRestHours hours: Double) -> Grade {
        let passed = RestConstants.gradeThresholdHours.filter { hours >= $0 }.count
        return Grade(rawValue: passed + 1)!
    }
}

public enum GradeEvaluation: Equatable, Sendable {
    /// 온전히 기록된 평일이 부족해서 아직 판단할 수 없음
    case pending(countedDays: Int, requiredDays: Int)
    case graded(Grade, averageRestHours: Double, countedDays: Int)

    public var grade: Grade? {
        if case let .graded(grade, _, _) = self { return grade }
        return nil
    }
}
