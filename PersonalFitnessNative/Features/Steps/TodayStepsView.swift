import SwiftUI

struct TodayStepsView: View {
    @State private var store: StepStore

    private let dailyGoal = 10_000

    init(store: StepStore = StepStore()) {
        _store = State(initialValue: store)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    header
                    stepCard

                    if let message = store.message {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(20)
            }
            .navigationTitle("Personal Fitness")
            .refreshable {
                await store.refresh()
            }
            .task {
                await store.refresh()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("TODAY")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                .font(.title2.weight(.semibold))
        }
    }

    private var stepCard: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(.quaternary, lineWidth: 18)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        .tint,
                        style: StrokeStyle(lineWidth: 18, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.smooth, value: progress)

                VStack(spacing: 4) {
                    if store.isLoading && store.steps == 0 {
                        ProgressView()
                            .controlSize(.large)
                    } else {
                        Text(store.steps.formatted())
                            .font(.system(size: 46, weight: .bold, design: .rounded))
                            .contentTransition(.numericText())

                        Text("steps")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(width: 230, height: 230)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Today's steps")
            .accessibilityValue("\(store.steps) steps")

            HStack {
                Label("Goal", systemImage: "flag.fill")
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(dailyGoal.formatted()) steps")
                    .fontWeight(.semibold)
            }
        }
        .padding(24)
        .background(.thinMaterial, in: .rect(cornerRadius: 28))
    }

    private var progress: Double {
        min(Double(store.steps) / Double(dailyGoal), 1)
    }
}

#Preview {
    TodayStepsView(store: .preview)
}
