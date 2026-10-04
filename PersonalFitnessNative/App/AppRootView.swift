import SwiftUI

struct AppRootView: View {
    @State private var store = PerformanceStore()
    @State private var selectedTab: Int
    init() {
        let args = ProcessInfo.processInfo.arguments
        _selectedTab = State(initialValue: args.contains("--snapshot-running") ? 1 : args.contains("--snapshot-strength") ? 2 : args.contains("--snapshot-history") ? 3 : 0)
    }
    var body: some View {
        TabView(selection: $selectedTab) {
            PerformanceHome(store: store).tabItem { Label("Overview", systemImage: "chart.bar.fill") }.tag(0)
            NavigationStack { ActivityDashboard(store: store, kind: .running) }.tabItem { Label("Running", systemImage: "figure.run") }.tag(1)
            NavigationStack { ActivityDashboard(store: store, kind: .strength) }.tabItem { Label("Strength", systemImage: "dumbbell.fill") }.tag(2)
            PerformanceHistory(store: store).tabItem { Label("History", systemImage: "clock") }.tag(3)
        }
    }
}
