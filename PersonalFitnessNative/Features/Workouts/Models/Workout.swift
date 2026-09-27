import Foundation

enum WorkoutCategory: String, CaseIterable, Identifiable, Hashable, Sendable {
    case strength
    case hiit
    case cardio
    case core
    case yoga
    case mobility

    var id: String { rawValue }

    var title: String {
        switch self {
        case .strength: "Strength"
        case .hiit: "HIIT"
        case .cardio: "Cardio"
        case .core: "Core"
        case .yoga: "Yoga"
        case .mobility: "Mobility"
        }
    }

    var systemImage: String {
        switch self {
        case .strength: "dumbbell.fill"
        case .hiit: "bolt.heart.fill"
        case .cardio: "figure.run"
        case .core: "circle.grid.cross.fill"
        case .yoga: "leaf.fill"
        case .mobility: "figure.walk.motion"
        }
    }
}

enum WorkoutDifficulty: String, Hashable, Sendable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
}

struct WorkoutExercise: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let target: String
    let instruction: String
}

struct WorkoutPlan: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let summary: String
    let category: WorkoutCategory
    let durationMinutes: Int
    let difficulty: WorkoutDifficulty
    let equipment: [String]
    let focusAreas: [String]
    let exercises: [WorkoutExercise]

    var exerciseCount: Int {
        exercises.count
    }

    var equipmentText: String {
        equipment.isEmpty ? "No equipment" : equipment.joined(separator: ", ")
    }
}
