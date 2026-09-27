import Foundation

struct RunningWorkout: Identifiable, Hashable, Sendable {
    let id: UUID
    let startDate: Date
    let duration: TimeInterval
    let distanceMiles: Double

    var paceSecondsPerMile: TimeInterval? {
        guard distanceMiles > 0 else {
            return nil
        }

        return duration / distanceMiles
    }
}

struct RunningDistanceRecord: Identifiable, Hashable, Sendable {
    let targetMiles: Double
    let workout: RunningWorkout

    var id: Double { targetMiles }

    var title: String {
        if targetMiles == 1 {
            return "Best 1 Mile"
        }

        return "Best \(Int(targetMiles)) Miles"
    }
}
