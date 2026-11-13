import SwiftUI
import RestCore

/// 24시간 진행 바
struct DayBar: View {
    let segments: [TimelineSegment]
    let day: DateInterval

    var body: some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
                        Rectangle()
                            .fill(segment.state.color)
                            .frame(width: geo.size.width * segment.interval.duration / day.duration)
                            .offset(x: geo.size.width * segment.interval.start.timeIntervalSince(day.start) / day.duration)
                    }
                }
            }
            .frame(height: 28)
            .clipShape(Capsule())

            HStack {
                ForEach([0, 6, 12, 18, 24], id: \.self) { hour in
                    Text("\(hour)")
                    if hour != 24 { Spacer() }
                }
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("오늘 24시간 진행 바")
    }
}
