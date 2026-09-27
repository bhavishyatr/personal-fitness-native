import SwiftUI

struct RunningDashboardView: View {
    @State private var store: RunningStore

    private let distanceTargets = [1.0, 2.0, 3.0, 4.0]
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    init(store: RunningStore = RunningStore()) {
        _store = State(initialValue: store)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header

                    if store.isLoading && store.workouts.isEmpty {
                        loadingCard
                    } else {
                        distanceRecords
                        runRecords
                    }

                    if let message = store.message {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    qualificationNote
                }
                .padding(20)
            }
            .navigationTitle("Running")
            .refreshable {
                await store.refresh()
            }
            .task {
                await store.refresh()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("RUNNING RECORDS", systemImage: "figure.run")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tint)

            Text("Your best runs")
                .font(.largeTitle.bold())

            Text(
                store.workouts.isEmpty
                    ? "Running workouts from Apple Health will appear here."
                    : "\(store.workouts.count) running workouts analyzed"
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }

    private var loadingCard: some View {
        HStack(spacing: 12) {
            ProgressView()
            Text("Reading running workouts from Apple Health…")
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    private var distanceRecords: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Distance Bests")
                .font(.title2.bold())

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(distanceTargets, id: \.self) { target in
                    distanceRecordCard(
                        targetMiles: target,
                        record: store.bestRun(near: target)
                    )
                }
            }
        }
    }

    private func distanceRecordCard(
        targetMiles: Double,
        record: RunningDistanceRecord?
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(
                targetMiles == 1
                    ? "1 Mile"
                    : "\(Int(targetMiles)) Miles",
                systemImage: "medal.fill"
            )
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.tint)

            if let record {
                Text(durationText(record.workout.duration))
                    .font(.title2.bold())
                    .monospacedDigit()

                Text(paceText(record.workout))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(
                    "\(mileageText(record.workout.distanceMiles)) · \(dateText(record.workout.startDate))"
                )
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .lineLimit(2)
            } else {
                Text("No record")
                    .font(.title3.bold())

                Text("Complete a run near this distance.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 132, alignment: .topLeading)
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .accessibilityElement(children: .combine)
    }

    private var runRecords: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Run Records")
                .font(.title2.bold())

            recordRow(
                title: "Longest Run",
                systemImage: "arrow.right",
                workout: store.longestRun,
                primaryValue: store.longestRun.map {
                    mileageText($0.distanceMiles)
                },
                secondaryValue: store.longestRun.map {
                    "\(durationText($0.duration)) · \(paceText($0))"
                }
            )

            recordRow(
                title: "Shortest Run",
                systemImage: "arrow.left",
                workout: store.shortestRun,
                primaryValue: store.shortestRun.map {
                    mileageText($0.distanceMiles)
                },
                secondaryValue: store.shortestRun.map {
                    "\(durationText($0.duration)) · \(paceText($0))"
                }
            )

            recordRow(
                title: "Fastest Run",
                systemImage: "hare.fill",
                workout: store.fastestRun,
                primaryValue: store.fastestRun.map {
                    paceText($0)
                },
                secondaryValue: store.fastestRun.map {
                    "\(mileageText($0.distanceMiles)) · \(durationText($0.duration))"
                }
            )
        }
    }

    private func recordRow(
        title: String,
        systemImage: String,
        workout: RunningWorkout?,
        primaryValue: String?,
        secondaryValue: String?
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.title3)
                .frame(width: 44, height: 44)
                .background(.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
                .foregroundStyle(.tint)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                if let primaryValue {
                    Text(primaryValue)
                        .font(.title3.bold())
                        .monospacedDigit()
                } else {
                    Text("No running data")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                if let secondaryValue {
                    Text(secondaryValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let workout {
                    Text(dateText(workout.startDate))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .accessibilityElement(children: .combine)
    }

    private var qualificationNote: some View {
        Text(
            "Best 1, 2, 3, and 4 mile records use completed running workouts within ±0.15 mile of the target distance. Fastest Run means the lowest average minutes-per-mile pace."
        )
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    private func durationText(_ duration: TimeInterval) -> String {
        let totalSeconds = max(0, Int(duration.rounded()))
        let hours = totalSeconds / 3_600
        let minutes = (totalSeconds % 3_600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }

        return String(format: "%d:%02d", minutes, seconds)
    }

    private func paceText(_ workout: RunningWorkout) -> String {
        guard let pace = workout.paceSecondsPerMile else {
            return "Pace unavailable"
        }

        return "\(durationText(pace)) /mi"
    }

    private func mileageText(_ miles: Double) -> String {
        String(format: "%.2f mi", miles)
    }

    private func dateText(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .omitted)
    }
}

#Preview {
    RunningDashboardView(store: .preview)
}
