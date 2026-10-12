import Foundation

@main
struct WorkoutDetailTests {
    static func main() throws {
        let bodyweight = StrengthSet(exercise: "Squat", reps: 10, kilograms: 0)
        precondition(bodyweight.isValid)
        precondition(!StrengthSet(exercise: "  ", reps: 10, kilograms: 10).isValid)
        precondition(!StrengthSet(exercise: "Squat", reps: 0, kilograms: 10).isValid)
        precondition(!StrengthSet(exercise: "Squat", reps: 10, kilograms: -.infinity).isValid)
        precondition(!StrengthSet(exercise: "Squat", reps: 10, kilograms: .nan).isValid)
        precondition(!StrengthSet(exercise: "Squat", reps: 10, kilograms: -1).isValid)
        let encoded = try JSONEncoder().encode([bodyweight])
        let restored = try JSONDecoder().decode([StrengthSet].self, from: encoded)
        precondition(restored == [bodyweight], "Preserve set IDs and values across storage")
        print("Workout detail validation passed")
    }
}
