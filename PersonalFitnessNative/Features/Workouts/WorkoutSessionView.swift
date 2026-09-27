import SwiftUI

struct WorkoutSessionView: View {
    let workout: WorkoutPlan

    @State private var completedExerciseIDs: Set<String> = []

    private var completedCount: Int {
        completedExerciseIDs.count
    }

    private var progress: Double {
        guard !workout.exercises.isEmpty else {
            return 0
        }

        return Double(completedCount) / Double(workout.exercises.count)
    }

    private var isComplete: Bool {
        completedCount == workout.exercises.count && !workout.exercises.isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                sessionHeader
                ProgressView(value: progress)
                    .tint(.accentColor)
                    .accessibilityLabel("Workout progress")
                    .accessibilityValue("\(completedCount) of \(workout.exercises.count) exercises complete")

                ForEach(workout.exercises) { exercise in
                    exerciseRow(exercise)
                }

                if isComplete {
                    completionCard
                }
            }
            .padding(20)
        }
        .navigationTitle(workout.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var sessionHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(workout.category.title, systemImage: workout.category.systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.tint)

            Text("\(completedCount) of \(workout.exercises.count) completed")
                .font(.title2.bold())

            Text("Tap an exercise when you finish it. Your progress updates automatically.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func exerciseRow(_ exercise: WorkoutExercise) -> some View {
        let isCompleted = completedExerciseIDs.contains(exercise.id)

        return Button {
            withAnimation(.smooth) {
                if isCompleted {
                    completedExerciseIDs.remove(exercise.id)
                } else {
                    completedExerciseIDs.insert(exercise.id)
                }
            }
        } label: {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isCompleted ? .tint : .secondary)

                VStack(alignment: .leading, spacing: 6) {
                    Text(exercise.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .strikethrough(isCompleted)

                    Text(exercise.target)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.tint)

                    Text(exercise.instruction)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 0)
            }
            .padding(16)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(exercise.name), \(exercise.target)")
        .accessibilityValue(isCompleted ? "Completed" : "Not completed")
        .accessibilityHint("Double tap to toggle completion")
    }

    private var completionCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 42))
                .foregroundStyle(.tint)

            Text("Workout Complete")
                .font(.title2.bold())

            Text("You completed every exercise in \(workout.title).")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(.tint.opacity(0.1), in: RoundedRectangle(cornerRadius: 24))
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        WorkoutSessionView(workout: WorkoutCatalog.workouts[0])
    }
}
