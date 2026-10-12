import Foundation
import Observation

@MainActor
@Observable
final class WorkoutDetailStore {
    var heartRate: [SensorReading] = []
    var power: [SensorReading] = []
    var cadence: [SensorReading] = []
    var routes: [[RoutePoint]] = []
    var errors: [String] = []
    var loading = false
    private let health = WorkoutDetailHealthService()

    func load(_ session: PerformanceSession) async {
        guard !loading else { return }
        loading = true
        defer { loading = false }
        heartRate = []; power = []; cadence = []; routes = []; errors = []
        if ProcessInfo.processInfo.arguments.contains("--ui-snapshot") {
            func readings(_ base: Double) -> [SensorReading] {
                (0..<30).map { i in SensorReading(id: UUID(), date: session.date.addingTimeInterval(Double(i) * 10), value: base + sin(Double(i) / 3) * base * 0.15, source: "Sample sensor") }
            }
            heartRate = readings(135)
            if session.kind == .cycling { power = readings(180); cadence = readings(80) }
            if session.kind.hasDistance {
                routes = [(0..<30).map { i in RoutePoint(latitude: 33.7 + Double(i) * 0.0001, longitude: -112.25 + sin(Double(i) / 10) * 0.003, date: session.date.addingTimeInterval(Double(i) * 10)) }]
            }
            return
        }
        do {
            try await health.authorize()
            guard let workout = try await health.workout(id: session.id) else {
                errors = ["This workout is no longer accessible in Apple Health."]; return
            }
            do { heartRate = try await health.readings(.heartRate, workout: workout) }
            catch { errors.append("Heart rate could not be loaded. Retry to request it again.") }
            if session.kind == .cycling {
                do { power = try await health.readings(.cyclingPower, workout: workout) }
                catch { errors.append("Cycling power could not be loaded.") }
                do { cadence = try await health.readings(.cyclingCadence, workout: workout) }
                catch { errors.append("Cycling cadence could not be loaded.") }
            }
            if session.kind.hasDistance {
                do { routes = try await health.routes(workout: workout) }
                catch { errors.append("Workout route could not be loaded.") }
            }
        } catch { errors = ["Could not read workout details: \(error.localizedDescription)"] }
    }
}

@MainActor
@Observable
final class StrengthLogStore {
    private(set) var sets: [StrengthSet] = []
    var error: String?
    private var fileURL: URL?
    private var snapshot = false
    func load(_ id: UUID) {
        sets = []; error = nil
        snapshot = ProcessInfo.processInfo.arguments.contains("--ui-snapshot")
        if snapshot { return }
        do {
            let directory = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("StrengthLogs", isDirectory: true)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            fileURL = directory.appendingPathComponent("\(id.uuidString).json")
            if let fileURL, FileManager.default.fileExists(atPath: fileURL.path) {
                sets = try JSONDecoder().decode([StrengthSet].self, from: Data(contentsOf: fileURL))
            }
        } catch { fileURL = nil; self.error = "Could not read saved sets. Existing data has not been changed." }
    }
    @discardableResult
    func save(_ next: [StrengthSet]) -> Bool {
        guard next.allSatisfy(\.isValid) else { error = "Enter an exercise, positive reps, and a nonnegative weight."; return false }
        do {
            if !snapshot {
                guard let fileURL else { error = "Storage is unavailable. Reopen this workout to retry."; return false }
                try JSONEncoder().encode(next).write(to: fileURL, options: [.atomic, .completeFileProtection])
            }
            sets = next; error = nil; return true
        } catch { self.error = "Sets could not be saved. Your previous entries are unchanged."; return false }
    }
}
