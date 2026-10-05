import Foundation

struct RankedPerformance: Identifiable {
    let record: PerformanceRecord
    let score: Double
    var id: UUID { record.session.id }
}

struct RecordSeries: Identifiable {
    let kind: ActivityKind
    let environment: String
    let metricID: String
    let title: String
    let lowerIsBetter: Bool
    let entries: [RankedPerformance]
    var id: String { "\(kind.rawValue)|\(environment)|\(metricID)" }
    var ranking: [RankedPerformance] {
        entries.sorted {
            if $0.score == $1.score { return earlier($0, $1) }
            return lowerIsBetter ? $0.score < $1.score : $0.score > $1.score
        }
    }
    var progression: [RankedPerformance] {
        var result: [RankedPerformance] = []
        for entry in entries.sorted(by: earlier) {
            guard let best = result.last else { result.append(entry); continue }
            if lowerIsBetter ? entry.score < best.score : entry.score > best.score { result.append(entry) }
        }
        return result
    }
    private func earlier(_ a: RankedPerformance, _ b: RankedPerformance) -> Bool {
        if a.record.session.date == b.record.session.date { return a.id.uuidString < b.id.uuidString }
        return a.record.session.date < b.record.session.date
    }
}

struct DuplicatePair: Identifiable {
    let first: PerformanceSession
    let second: PerformanceSession
    var id: String { "\(first.id)|\(second.id)" }
}

struct MonthSummary {
    let start: Date
    let end: Date
    let sessions: [PerformanceSession]
    let previousSessions: [PerformanceSession]
    let recordEvents: [(RecordSeries, RankedPerformance)]
    var activeDays: Int { Set(sessions.map { Calendar.current.startOfDay(for: $0.date) }).count }
    var duration: Double { sessions.reduce(0) { $0 + $1.duration } }
}

enum InsightMath {
    static func series(_ sessions: [PerformanceSession]) -> [RecordSeries] {
        var groups: [String: [RankedPerformance]] = [:]
        for session in sessions {
            for record in PerformanceMath.records([session], kind: session.kind) {
                let score: Double
                switch record.id {
                case "Longest distance": score = session.distance ?? 0
                case "Most climbing": score = session.elevation ?? 0
                default: score = record.effort?.seconds ?? session.duration
                }
                guard score.isFinite, score > 0 else { continue }
                let key = "\(session.kind.rawValue)|\(session.environment)|\(record.id)"
                groups[key, default: []].append(RankedPerformance(record: record, score: score))
            }
        }
        return groups.values.compactMap { entries in
            guard let first = entries.first else { return nil }
            let record = first.record
            return RecordSeries(kind: record.session.kind, environment: record.session.environment,
                metricID: record.id, title: record.title,
                lowerIsBetter: record.id.hasPrefix("segment-") || record.id.hasPrefix("Best whole"), entries: entries)
        }.sorted { $0.id < $1.id }
    }

    static func eligible(_ sessions: [PerformanceSession], excluding ids: Set<UUID>) -> [PerformanceSession] {
        sessions.filter { !ids.contains($0.id) }
    }

    // Suggestions only. A nearby start, same activity/environment, and matching
    // duration/distance are evidence to review, not proof of duplication.
    static func duplicates(_ sessions: [PerformanceSession]) -> [DuplicatePair] {
        let sorted = sessions.sorted { $0.date < $1.date }
        var result: [DuplicatePair] = []
        for i in sorted.indices {
            var j = i + 1
            while j < sorted.count && sorted[j].date.timeIntervalSince(sorted[i].date) <= 60 {
                let a = sorted[i], b = sorted[j]
                defer { j += 1 }
                guard a.id != b.id, a.kind == b.kind, a.kind != .other, a.environment == b.environment,
                      a.duration > 0, b.duration > 0,
                      abs(a.duration - b.duration) <= max(5, min(a.duration, b.duration) * 0.02) else { continue }
                if a.kind.hasDistance {
                    guard let ad = a.distance, let bd = b.distance, ad > 0, bd > 0,
                          abs(ad - bd) <= max(10, min(ad, bd) * 0.02) else { continue }
                }
                result.append(DuplicatePair(first: a, second: b))
            }
        }
        return result
    }

    static func month(_ date: Date, sessions: [PerformanceSession], series: [RecordSeries], calendar: Calendar = .current) -> MonthSummary {
        let interval = calendar.dateInterval(of: .month, for: date)!
        let previousStart = calendar.date(byAdding: .month, value: -1, to: interval.start)!
        let included = sessions.filter { $0.date >= interval.start && $0.date < interval.end }
        let previous = sessions.filter { $0.date >= previousStart && $0.date < interval.start }
        let events = series.flatMap { series in
            // First entry establishes a baseline; subsequent improvements are new records.
            series.progression.dropFirst().filter { $0.record.session.date >= interval.start && $0.record.session.date < interval.end }.map { (series, $0) }
        }.sorted { $0.1.record.session.date > $1.1.record.session.date }
        return MonthSummary(start: interval.start, end: interval.end, sessions: included, previousSessions: previous, recordEvents: events)
    }
}
