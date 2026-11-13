import Foundation

// MARK: - 결과 타입

public struct TimeBreakdown: Sendable, Equatable {
    public var rest: TimeInterval
    public var work: TimeInterval
    public var sleep: TimeInterval

    public init(rest: TimeInterval = 0, work: TimeInterval = 0, sleep: TimeInterval = 0) {
        self.rest = rest
        self.work = work
        self.sleep = sleep
    }

    public static let zero = TimeBreakdown()

    public var tracked: TimeInterval { rest + work + sleep }
}

/// 24시간 바의 한 칸
public enum TimelineState: Sendable, Equatable {
    case rest
    case work
    case sleep
    /// 설치 전이라 기록이 없는 시간
    case untracked
    /// 아직 오지 않은 시간
    case future
}

public struct TimelineSegment: Sendable, Equatable {
    public var state: TimelineState
    public var interval: DateInterval

    public init(state: TimelineState, interval: DateInterval) {
        self.state = state
        self.interval = interval
    }
}

public enum CurrentStatus: Sendable, Equatable {
    case resting(since: Date)
    case working(since: Date)
    case sleeping(since: Date)
}

public struct LostWage: Sendable, Equatable {
    /// 근무창 중 일하지 않은 시간(초)
    public var lostSeconds: TimeInterval
    /// 날린 일당(원, 원 단위 미만 버림)
    public var won: Int

    public static let zero = LostWage(lostSeconds: 0, won: 0)
}

// MARK: - 계산기

/// 모든 수치는 세션 기록에서 그때그때 계산합니다 (PRD 4장).
public struct RestCalculator: Sendable {
    public let restCalendar: RestCalendar
    /// 이 시각 이전은 '기록 없음'. 보통 설치 시각이고, 그보다 이른 세션을 넣으면 앞당겨집니다.
    public let trackingStart: Date

    public init(trackingStart: Date, restCalendar: RestCalendar = RestCalendar()) {
        self.trackingStart = trackingStart
        self.restCalendar = restCalendar
    }

    public static func trackingStart(installedAt: Date, sessions: [SessionRecord]) -> Date {
        guard let earliest = sessions.map(\.start).min() else { return installedAt }
        return min(earliest, installedAt)
    }

    /// 구간 중 실제로 계산 대상인 부분: [max(시작, 기록 시작), min(끝, 지금))
    func trackedPart(of range: DateInterval, now: Date) -> DateInterval? {
        let start = max(range.start, trackingStart)
        let end = min(range.end, now)
        guard end > start else { return nil }
        return DateInterval(start: start, end: end)
    }

    // MARK: 쉼 / 일함 / 잠

    public func breakdown(in range: DateInterval, sessions: [SessionRecord], now: Date) -> TimeBreakdown {
        guard let tracked = trackedPart(of: range, now: now) else { return .zero }
        var work: TimeInterval = 0
        var sleep: TimeInterval = 0
        for session in sessions {
            guard let interval = session.interval(now: now) else { continue }
            let overlap = interval.overlapDuration(with: tracked)
            switch session.kind {
            case .work: work += overlap
            case .sleep: sleep += overlap
            }
        }
        let rest = max(0, tracked.duration - work - sleep)
        return TimeBreakdown(rest: rest, work: work, sleep: sleep)
    }

    // MARK: 24시간 바

    public func segments(for range: DateInterval, sessions: [SessionRecord], now: Date) -> [TimelineSegment] {
        func clamp(_ date: Date) -> Date { min(max(date, range.start), range.end) }

        let nowPoint = clamp(now)
        let trackedStart = min(clamp(trackingStart), nowPoint)

        var result: [TimelineSegment] = []
        func append(_ state: TimelineState, _ start: Date, _ end: Date) {
            guard end > start else { return }
            if let last = result.last, last.state == state, last.interval.end == start {
                result[result.count - 1].interval = DateInterval(start: last.interval.start, end: end)
            } else {
                result.append(TimelineSegment(state: state, interval: DateInterval(start: start, end: end)))
            }
        }

        append(.untracked, range.start, trackedStart)

        if nowPoint > trackedStart {
            let tracked = DateInterval(start: trackedStart, end: nowPoint)
            let clipped = sessions
                .compactMap { session -> (SessionKind, DateInterval)? in
                    guard let clip = session.interval(now: now)?.clipped(to: tracked) else { return nil }
                    return (session.kind, clip)
                }
                .sorted { $0.1.start < $1.1.start }

            var cursor = trackedStart
            for (kind, interval) in clipped {
                append(.rest, cursor, interval.start)
                append(kind == .work ? .work : .sleep, max(cursor, interval.start), interval.end)
                cursor = max(cursor, interval.end)
            }
            append(.rest, cursor, nowPoint)
        }

        append(.future, nowPoint, range.end)
        return result
    }

    // MARK: 현재 상태

    public func currentStatus(sessions: [SessionRecord], now: Date) -> CurrentStatus {
        if let active = sessions.first(where: \.isActive) {
            switch active.kind {
            case .work: return .working(since: active.start)
            case .sleep: return .sleeping(since: active.start)
            }
        }
        let lastEnd = sessions.compactMap(\.end).filter { $0 <= now }.max()
        return .resting(since: lastEnd ?? trackingStart)
    }

    // MARK: 무사고 쉼 (일하지 않은 연속 시간, 잠 포함)

    /// 일하지 않은 연속 구간들 (기록 시작 ~ 지금)
    func workFreeStretches(sessions: [SessionRecord], now: Date) -> [DateInterval] {
        let works = sessions
            .filter { $0.kind == .work }
            .compactMap { $0.interval(now: now) }
            .sorted { $0.start < $1.start }

        var stretches: [DateInterval] = []
        var cursor = trackingStart
        for work in works {
            if work.start > cursor {
                stretches.append(DateInterval(start: cursor, end: work.start))
            }
            cursor = max(cursor, work.end)
        }
        if now > cursor {
            stretches.append(DateInterval(start: cursor, end: now))
        }
        return stretches
    }

    /// 지금 이어지고 있는 무사고 쉼. 일하는 중이면 0.
    public func currentWorkFreeDuration(sessions: [SessionRecord], now: Date) -> TimeInterval {
        if sessions.contains(where: { $0.isActive && $0.kind == .work }) { return 0 }
        guard let last = workFreeStretches(sessions: sessions, now: now).last, last.end == now else { return 0 }
        return last.duration
    }

    /// 가장 긴 무사고 쉼. `range`를 주면 그 안으로 잘라서 봅니다.
    public func longestWorkFreeStretch(in range: DateInterval? = nil, sessions: [SessionRecord], now: Date) -> DateInterval? {
        workFreeStretches(sessions: sessions, now: now)
            .compactMap { stretch -> DateInterval? in
                guard let range else { return stretch }
                return stretch.clipped(to: range)
            }
            .max { $0.duration < $1.duration }
    }

    // MARK: 날린 일당

    public func lostWage(in range: DateInterval, sessions: [SessionRecord], now: Date) -> LostWage {
        guard let tracked = trackedPart(of: range, now: now) else { return .zero }
        let works = sessions
            .filter { $0.kind == .work }
            .compactMap { $0.interval(now: now) }

        var secondsByYear: [Int: TimeInterval] = [:]
        for day in restCalendar.days(in: tracked) where restCalendar.isBusinessDay(day.start) {
            for window in RestConstants.workWindows {
                let windowInterval = DateInterval(
                    start: restCalendar.date(on: day, hour: window.start),
                    end: restCalendar.date(on: day, hour: window.end)
                )
                guard let part = windowInterval.clipped(to: tracked) else { continue }
                let worked = works.reduce(0) { $0 + $1.overlapDuration(with: part) }
                let lost = max(0, part.duration - worked)
                secondsByYear[restCalendar.year(of: day.start), default: 0] += lost
            }
        }

        let totalSeconds = secondsByYear.values.reduce(0, +)
        let won = secondsByYear.reduce(0) { sum, entry in
            let wage = Double(RestConstants.minimumWage(forYear: entry.key))
            return sum + Int((entry.value * wage / 3600).rounded(.down))
        }
        return LostWage(lostSeconds: totalSeconds, won: won)
    }

    // MARK: 등급

    /// `week` 안의 평일(공휴일 제외) 중 온전히 기록이 끝난 날들의 평균 쉰 시간으로 등급을 매깁니다.
    public func evaluateGrade(week: DateInterval, sessions: [SessionRecord], now: Date, minimumDays: Int) -> GradeEvaluation {
        var totalRest: TimeInterval = 0
        var counted = 0
        for day in restCalendar.days(in: week) where restCalendar.isBusinessDay(day.start) {
            // 설치 당일처럼 일부만 기록된 날, 아직 안 끝난 날은 제외
            guard day.start >= trackingStart, day.end <= now else { continue }
            totalRest += breakdown(in: day, sessions: sessions, now: now).rest
            counted += 1
        }
        let required = max(1, minimumDays)
        guard counted >= required else {
            return .pending(countedDays: counted, requiredDays: required)
        }
        let averageHours = totalRest / Double(counted) / 3600
        return .graded(Grade.grade(forAverageRestHours: averageHours), averageRestHours: averageHours, countedDays: counted)
    }

    /// 지난주 확정 등급
    public func confirmedGrade(sessions: [SessionRecord], now: Date) -> GradeEvaluation {
        let thisWeek = restCalendar.week(containing: now)
        let lastWeek = restCalendar.week(containing: thisWeek.start.addingTimeInterval(-1))
        return evaluateGrade(week: lastWeek, sessions: sessions, now: now,
                             minimumDays: RestConstants.confirmedGradeMinimumDays)
    }

    /// 이번 주 예상 등급
    public func projectedGrade(sessions: [SessionRecord], now: Date) -> GradeEvaluation {
        evaluateGrade(week: restCalendar.week(containing: now), sessions: sessions, now: now,
                      minimumDays: RestConstants.projectedGradeMinimumDays)
    }
}
