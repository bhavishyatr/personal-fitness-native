import SwiftUI

struct WorkoutDetailView: View {
    let workout: WorkoutPlan

    private let focusColumns = [
        GridItem(.adaptive(minimum: 95), spacing: 10)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                hero
                metrics
                focusAreas
                equipment
                exerciseList
                startButton
            }
            .padding(20)
        }
        .navigationTitle(workout.category.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: workout.category.systemImage)
                .font(.system(size: 34, weight: .semibold))
                .frame(width: 72, height: 72)
                .background(.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 22))
                .foregroundStyle(.tint)

            Text(workout.title)
                .font(.largeTitle.bold())

            Text(workout.summary)
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    private var metrics: some View {
        HStack(spacing: 12) {
            metric(
                title: "Duration",
                value: "\(workout.durationMinutes) min",
                systemImage: "clock.fill"
            )

            metric(
                title: "Level",
                value: workout.difficulty.rawValue,
                systemImage: "chart.bar.fill"
            )

            metric(
                title: "Exercises",
                value: workout.exerciseCount.formatted(),
                systemImage: "list.bullet"
            )
        }
    }

    private func metric(
        title: String,
        value: String,
        systemImage: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: systemImage)
                .foregroundStyle(.tint)

            Text(value)
                .font(.subheadline.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
    }

    private var focusAreas: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Focus")
                .font(.title3.bold())

            LazyVGrid(columns: focusColumns, alignment: .leading, spacing: 10) {
                ForEach(workout.focusAreas, id: \.self) { area in
                    Text(area)
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(.tint.opacity(0.1), in: Capsule())
                        .foregroundStyle(.tint)
                }
            }
        }
    }

    private var equipment: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Equipment")
                .font(.title3.bold())

            Label(
                workout.equipmentText,
                systemImage: workout.equipment.isEmpty ? "checkmark.circle.fill" : "dumbbell"
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }

    private var exerciseList: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Workout")
                .font(.title3.bold())

            ForEach(Array(workout.exercises.enumerated()), id: \.element.id) { index, exercise in
                HStack(alignment: .top, spacing: 14) {
                    Text("\(index + 1)")
                        .font(.subheadline.bold())
                        .frame(width: 34, height: 34)
                        .background(.tint.opacity(0.12), in: Circle())
                        .foregroundStyle(.tint)

                    VStack(alignment: .leading, spacing: 5) {
                        Text(exercise.name)
                            .font(.headline)

                        Text(exercise.target)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.tint)

                        Text(exercise.instruction)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 0)
                }
                .padding(16)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
            }
        }
    }

    private var startButton: some View {
        NavigationLink {
            WorkoutSessionView(workout: workout)
        } label: {
            Label("Start Workout", systemImage: "play.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .accessibilityHint("Opens the guided exercise checklist")
    }
}

#Preview {
    NavigationStack {
        WorkoutDetailView(workout: WorkoutCatalog.workouts[0])
    }
}
