import SwiftUI

struct WorkoutLibraryView: View {
    @State private var selectedCategory: WorkoutCategory?

    private var filteredWorkouts: [WorkoutPlan] {
        guard let selectedCategory else {
            return WorkoutCatalog.workouts
        }

        return WorkoutCatalog.workouts.filter { $0.category == selectedCategory }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    intro
                    categoryPicker

                    Text(selectedCategory?.title ?? "All Workouts")
                        .font(.title2.bold())

                    ForEach(filteredWorkouts) { workout in
                        NavigationLink(value: workout) {
                            WorkoutCard(workout: workout)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)
            }
            .navigationTitle("Workouts")
            .navigationDestination(for: WorkoutPlan.self) { workout in
                WorkoutDetailView(workout: workout)
            }
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Choose how you want to move")
                .font(.title.bold())

            Text("Every workout screen is generated from the workout plan, so duration, difficulty, focus areas, equipment, and exercises change automatically.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var categoryPicker: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 10) {
                categoryButton(
                    title: "All",
                    systemImage: "square.grid.2x2.fill",
                    category: nil
                )

                ForEach(WorkoutCategory.allCases) { category in
                    categoryButton(
                        title: category.title,
                        systemImage: category.systemImage,
                        category: category
                    )
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    private func categoryButton(
        title: String,
        systemImage: String,
        category: WorkoutCategory?
    ) -> some View {
        let isSelected = selectedCategory == category

        return Button {
            withAnimation(.smooth) {
                selectedCategory = category
            }
        } label: {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.thinMaterial),
                    in: Capsule()
                )
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct WorkoutCard: View {
    let workout: WorkoutPlan

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: workout.category.systemImage)
                .font(.title2)
                .frame(width: 48, height: 48)
                .background(.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
                .foregroundStyle(.tint)

            VStack(alignment: .leading, spacing: 7) {
                Text(workout.title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                HStack(spacing: 10) {
                    Label("\(workout.durationMinutes) min", systemImage: "clock")
                    Text(workout.difficulty.rawValue)
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                Text("\(workout.exerciseCount) exercises · \(workout.equipmentText)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22))
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    WorkoutLibraryView()
}
