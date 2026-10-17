import Foundation

struct SensorReading: Identifiable, Sendable {
    let id: UUID
    let date: Date
    let value: Double
    let source: String
}

struct RoutePoint: Sendable {
    let latitude: Double
    let longitude: Double
    let date: Date
}

struct StrengthSet: Identifiable, Codable, Equatable, Sendable {
    var id = UUID()
    var exercise: String
    var reps: Int
    var kilograms: Double
    var isValid: Bool {
        !exercise.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && reps > 0 && reps <= 10000 && kilograms.isFinite && kilograms >= 0 && kilograms <= 10000
    }
}
