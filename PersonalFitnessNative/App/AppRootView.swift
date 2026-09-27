import SwiftUI

struct AppRootView: View {
    private enum AppTab: Hashable {
        case today
        case running
        case workouts
    }

    @State private var selectedTab: AppTab

    init() {
        let arguments = ProcessInfo.processInfo.arguments

        if arguments.contains("--snapshot-running") {
            _selectedTab = State(initialValue: .running)
        } else if arguments.contains("--snapshot-workouts") {
            _selectedTab = State(initialValue: .workouts)
        } else {
            _selectedTab = State(initialValue: .today)
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayStepsView()
                .tabItem {
                    Label("Today", systemImage: "figure.walk")
                }
                .tag(AppTab.today)

            RunningDashboardView()
                .tabItem {
                    Label("Running", systemImage: "figure.run")
                }
                .tag(AppTab.running)

            WorkoutLibraryView()
                .tabItem {
                    Label("Workouts", systemImage: "dumbbell.fill")
                }
                .tag(AppTab.workouts)
        }
    }
}

#Preview {
    AppRootView()
}
