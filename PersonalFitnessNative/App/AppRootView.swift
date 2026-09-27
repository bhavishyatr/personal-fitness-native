import SwiftUI

struct AppRootView: View {
    var body: some View {
        TabView {
            TodayStepsView()
                .tabItem {
                    Label("Today", systemImage: "figure.walk")
                }

            RunningDashboardView()
                .tabItem {
                    Label("Running", systemImage: "figure.run")
                }

            WorkoutLibraryView()
                .tabItem {
                    Label("Workouts", systemImage: "dumbbell.fill")
                }
        }
    }
}

#Preview {
    AppRootView()
}
