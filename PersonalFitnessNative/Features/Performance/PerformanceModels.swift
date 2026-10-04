import Foundation

enum ActivityKind: String, CaseIterable, Identifiable, Sendable {
    case running = "Running", walking = "Walking", hiking = "Hiking", cycling = "Cycling"
    case strength = "Strength", swimming = "Swimming", rowing = "Rowing", yoga = "Yoga"
    case pilates = "Pilates", hiit = "HIIT", badminton = "Badminton", other = "Other"
    var id: String { rawValue }
    var hasDistance: Bool { [.running, .walking, .hiking, .cycling, .swimming, .rowing].contains(self) }
    var icon: String {
        switch self {
        case .running: "figure.run"
        case .walking, .hiking: "figure.walk"
        case .cycling: "figure.outdoor.cycle"
        case .strength: "dumbbell.fill"
        case .swimming: "figure.pool.swim"
        case .rowing: "figure.rower"
        case .yoga, .pilates: "figure.yoga"
        default: "figure.mixed.cardio"
        }
    }
}

struct DistancePoint: Sendable {
    let seconds: Double
    let meters: Double
}

struct PerformanceSession: Identifiable, Sendable {
    let id: UUID
    let kind: ActivityKind
    let date: Date
    let duration: Double
    let distance: Double?
    let source: String
    let environment: String
    var points: [DistancePoint] = []
    var elevation: Double? = nil
}

struct Effort: Sendable {
    let seconds: Double
    let startSeconds: Double
    let endSeconds: Double
}

struct PerformanceRecord: Identifiable {
    let id: String
    let title: String
    let value: String
    let session: PerformanceSession
    let explanation: String
    var previous: String? = nil
    var effort: Effort? = nil
}

enum PerformanceMath {
    static let mile = 1609.344
    static func time(_ seconds: Double) -> String {
        let value = max(0, Int(seconds.rounded()))
        return value >= 3600 ? String(format: "%d:%02d:%02d", value / 3600, value / 60 % 60, value % 60) : String(format: "%d:%02d", value / 60, value % 60)
    }
    static func distance(_ meters: Double, kind: ActivityKind) -> String {
        [.swimming, .rowing].contains(kind) ? String(format: "%.0f m", meters) : String(format: "%.2f mi", meters / mile)
    }

    // Piecewise-linear distance interpolation. Evaluate both start and end breakpoints,
    // including the latest departure from a stationary plateau. Elapsed time includes pauses.
    static func fastest(_ points: [DistancePoint], meters: Double) -> Effort? {
        guard meters > 0, points.count >= 3 else { return nil }
        for index in points.indices {
            guard points[index].seconds.isFinite, points[index].meters.isFinite,
                  points[index].seconds >= 0, points[index].meters >= 0 else { return nil }
            if index > 0 {
                guard points[index].seconds > points[index - 1].seconds,
                      points[index].meters >= points[index - 1].meters,
                      points[index].seconds - points[index - 1].seconds <= 30 else { return nil }
            }
        }
        guard let first = points.first, let last = points.last, last.meters - first.meters >= meters else { return nil }
        func timestamp(_ distance: Double, departure: Bool) -> Double {
            var low = 0
            var high = points.count
            while low < high {
                let mid = (low + high) / 2
                if points[mid].meters < distance || (departure && points[mid].meters == distance) { low = mid + 1 } else { high = mid }
            }
            if departure && low > 0 && points[low - 1].meters == distance { return points[low - 1].seconds }
            if low == 0 { return points[0].seconds }
            if low == points.count { return last.seconds }
            let a = points[low - 1], b = points[low]
            return a.seconds + (distance - a.meters) / (b.meters - a.meters) * (b.seconds - a.seconds)
        }
        var best: Effort?
        for point in points {
            for start in [point.meters, point.meters - meters] where start >= first.meters && start + meters <= last.meters {
                let begin = timestamp(start, departure: true)
                let end = timestamp(start + meters, departure: false)
                if end > begin && end - begin < (best?.seconds ?? .infinity) {
                    best = Effort(seconds: end - begin, startSeconds: begin, endSeconds: end)
                }
            }
        }
        return best
    }

    static func records(_ sessions: [PerformanceSession], kind: ActivityKind) -> [PerformanceRecord] {
        let valid = sessions.filter { $0.kind == kind && $0.duration.isFinite && $0.duration > 0 }
        var result: [PerformanceRecord] = []
        func add(_ title: String, candidates: [(PerformanceSession, Double)], lower: Bool, format: (Double) -> String, note: String) {
            let ordered = candidates.filter { $0.1.isFinite && $0.1 > 0 }.sorted { lower ? $0.1 < $1.1 : $0.1 > $1.1 }
            guard let winner = ordered.first else { return }
            let previous = ordered.first { $0.0.date < winner.0.date }
            result.append(PerformanceRecord(id: title, title: title, value: format(winner.1), session: winner.0, explanation: note,
                previous: previous.map { "Previous best: \(format($0.1)) · \($0.0.date.formatted(date: .abbreviated, time: .omitted)). Change: \(format(abs(winner.1 - $0.1)))." }))
        }
        if kind.hasDistance {
            add("Longest distance", candidates: valid.compactMap { s in s.distance.map { (s, $0) } }, lower: false,
                format: { distance($0, kind: kind) }, note: "Greatest recorded distance in one session.")
        }
        add("Longest duration", candidates: valid.map { ($0, $0.duration) }, lower: false, format: time, note: "Longest recorded active workout duration; descriptive, not a score of fitness.")
        if [.hiking, .cycling, .running].contains(kind) {
            add("Most climbing", candidates: valid.compactMap { s in s.elevation.map { (s, $0) } }, lower: false,
                format: { String(format: "%.0f m", $0) }, note: "Recorded elevation ascended.")
        }
        if kind == .running {
            for target in 1...4 {
                add("Best whole run near \(target) mi", candidates: valid.compactMap { s in
                    guard let d = s.distance, abs(d / mile - Double(target)) <= 0.15 else { return nil }
                    return (s, s.duration)
                }, lower: true, format: time, note: "Complete runs within ±0.15 mile of the target, ranked by active duration. Actual distance is shown in session details. This is not an exact-distance segment record.")
                let efforts = valid.compactMap { s -> (PerformanceSession, Effort)? in
                    guard let e = fastest(s.points, meters: Double(target) * mile) else { return nil }; return (s, e)
                }.sorted { $0.1.seconds < $1.1.seconds }
                if let winner = efforts.first {
                    let previous = efforts.first { $0.0.date < winner.0.date }
                    result.append(PerformanceRecord(id: "segment-\(target)", title: "Fastest continuous \(target) mi", value: time(winner.1.seconds), session: winner.0,
                        explanation: "Estimated from recorded distance samples using interpolation; elapsed time includes pauses. Samples more than 30 seconds apart, overlapping samples, and incomplete distance coverage are excluded.",
                        previous: previous.map { "Previous best: \(time($0.1.seconds)). Improved by \(time($0.1.seconds - winner.1.seconds))." }, effort: winner.1))
                }
            }
        }
        return result
    }
}
