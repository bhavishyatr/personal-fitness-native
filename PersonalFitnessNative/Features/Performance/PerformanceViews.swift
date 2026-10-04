import SwiftUI
import Charts

struct PerformanceHome: View {
    @Bindable var store: PerformanceStore
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Your performance").font(.largeTitle.bold())
                    Text("Your recorded activity, personal bests, and changes over time.").foregroundStyle(.secondary)
                    LabeledContent("Recorded sessions", value: "\(store.sessions.count)")
                    LabeledContent("Active workout time", value: PerformanceMath.time(store.sessions.reduce(0) { $0 + $1.duration }))
                    if ProcessInfo.processInfo.arguments.contains("--ui-snapshot") { Text("Preview · Sample data").font(.caption).foregroundStyle(.orange) }
                }
                Section("Workout dashboards") {
                    ForEach(ActivityKind.allCases) { kind in
                        NavigationLink {
                            ActivityDashboard(store: store, kind: kind)
                        } label: {
                            HStack {
                                Label(kind.rawValue, systemImage: kind.icon)
                                Spacer()
                                Text("\(store.sessions.filter { $0.kind == kind }.count)").foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                Section("Recent activity") {
                    ForEach(Array(store.sessions.prefix(5))) { session in SessionLink(session: session) }
                }
                HealthStatus(store: store)
            }
            .navigationTitle("Overview")
            .refreshable { await store.refresh(force: true) }
            .task { await store.refresh() }
        }
    }
}

enum PerformancePeriod: String, CaseIterable, Identifiable {
    case month = "30 days", year = "Year", all = "All time", custom = "Custom"
    var id: String { rawValue }
    var days: Int? { switch self { case .month: 30; case .year: 365; case .all, .custom: nil } }
}

struct ActivityDashboard: View {
    @Bindable var store: PerformanceStore
    let kind: ActivityKind
    @State private var period: PerformancePeriod = .all
    @State private var environment = "All"
    @State private var startDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
    @State private var endDate = Date()
    private var all: [PerformanceSession] { store.sessions.filter { $0.kind == kind && (environment == "All" || $0.environment == environment) } }
    private var sessions: [PerformanceSession] {
        if period == .custom {
            let start = Calendar.current.startOfDay(for: startDate)
            let end = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: endDate))!
            return all.filter { $0.date >= start && $0.date < end }
        }
        guard let days = period.days, let start = Calendar.current.date(byAdding: .day, value: -days, to: Date()) else { return all }
        return all.filter { $0.date >= start }
    }
    // Separate contexts so indoor and outdoor performances never compete for records.
    private var records: [PerformanceRecord] {
        ["Outdoor", "Indoor", "Unspecified"].flatMap { context in
            PerformanceMath.records(sessions.filter { $0.environment == context }, kind: kind)
        }
    }
    var body: some View {
        List {
            Section {
                Picker("Period", selection: $period) { ForEach(PerformancePeriod.allCases) { Text($0.rawValue).tag($0) } }.pickerStyle(.segmented)
                if period == .custom {
                    DatePicker("From", selection: $startDate, in: ...endDate, displayedComponents: .date)
                    DatePicker("Through", selection: $endDate, in: startDate...Date(), displayedComponents: .date)
                }
                Picker("Environment", selection: $environment) { ForEach(["All", "Outdoor", "Indoor", "Unspecified"], id: \.self) { Text($0).tag($0) } }
                LabeledContent("Sessions", value: "\(sessions.count)")
                LabeledContent("Total active time", value: PerformanceMath.time(sessions.reduce(0) { $0 + $1.duration }))
                if kind.hasDistance {
                    LabeledContent("Recorded distance", value: PerformanceMath.distance(sessions.compactMap(\.distance).reduce(0, +), kind: kind))
                }
            }
            Section("Performance highlights") {
                if let record = records.filter({ $0.previous != nil }).sorted(by: { $0.session.date > $1.session.date }).first {
                    NavigationLink { RecordDetail(record: record) } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("\(record.title): \(record.value)").font(.headline)
                            Text("\(record.session.environment) · \(record.session.date.formatted(date: .abbreviated, time: .omitted))").font(.caption)
                            Text(record.previous ?? "").font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                }
                Text(comparison).font(.subheadline)
            }
            Section("Best recorded · \(period.rawValue)") {
                ForEach(records, id: \.uniqueKey) { record in
                    NavigationLink { RecordDetail(record: record) } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(record.title).font(.headline)
                            Text(record.value).font(.title2.bold()).foregroundStyle(.tint)
                            Text("\(record.session.environment) · \(record.session.date.formatted(date: .abbreviated, time: .omitted))").font(.caption).foregroundStyle(.secondary)
                        }.padding(.vertical, 4).accessibilityElement(children: .combine)
                    }
                }
                if records.isEmpty { Text("No records available for this selection.") }
            }
            Section("Activity over time") {
                Chart(weekly, id: \.date) { point in
                    BarMark(x: .value("Week", point.date, unit: .weekOfYear), y: .value("Minutes", point.minutes))
                }.frame(height: 160).accessibilityLabel("Weekly workout minutes for \(kind.rawValue)")
                Text("Recorded active minutes per week").font(.caption).foregroundStyle(.secondary)
                if kind.hasDistance {
                    Chart(weekly, id: \.date) { point in
                        BarMark(x: .value("Week", point.date, unit: .weekOfYear), y: .value("Distance", point.meters / distanceUnit))
                    }.frame(height: 140).accessibilityLabel("Weekly recorded distance")
                    Text("Recorded distance per week (\(distanceUnit == 1 ? "meters" : "miles"))").font(.caption).foregroundStyle(.secondary)
                }
            }
            Section("Data coverage") {
                Text(coverage).font(.footnote).foregroundStyle(.secondary)
                if kind == .running {
                    Text("\(sessions.filter { !$0.points.isEmpty }.count) of \(sessions.count) runs have usable detailed distance samples. Continuous efforts are estimated; whole-run records use active duration.").font(.footnote)
                }
            }
            Section("Session history") { ForEach(sessions) { SessionLink(session: $0) } }
            HealthStatus(store: store)
        }
        .navigationTitle(kind.rawValue)
        .refreshable { await store.refresh(force: true) }
        .task { await store.refresh() }
    }
    private var comparison: String {
        let now = Date()
        let start = now.addingTimeInterval(-30 * 86400)
        let previousStart = now.addingTimeInterval(-60 * 86400)
        let current = all.filter { $0.date >= start && $0.date <= now }.count
        let previous = all.filter { $0.date >= previousStart && $0.date < start }.count
        return "Last 30 days: \(current) sessions. Previous 30 days: \(previous). Based on accessible recorded history."
    }
    private var weekly: [WeekMinutes] {
        let grouped = Dictionary(grouping: sessions) { Calendar.current.dateInterval(of: .weekOfYear, for: $0.date)?.start ?? $0.date }
        return grouped.map { WeekMinutes(date: $0.key, minutes: $0.value.reduce(0) { $0 + $1.duration / 60 }, meters: $0.value.compactMap(\.distance).reduce(0, +)) }.sorted { $0.date < $1.date }
    }
    private var distanceUnit: Double { [.swimming, .rowing].contains(kind) ? 1 : PerformanceMath.mile }
    private var coverage: String {
        switch kind {
        case .strength: "Exercise-level weights, reps, sets, and equipment are not available from this app's workout import. Lifting records need those details; only recorded session activity is shown."
        case .running: "Continuous 1–4 mile efforts require detailed distance samples. Missing, overlapping, coarse, or incomplete samples do not produce segment records. Tap a record for its calculation and original workout."
        case .cycling: "Indoor and outdoor records are separate. Power and cadence records require detailed sensor data and are not imported yet."
        case .swimming: "Distance and duration are shown. Stroke and pool/open-water classification are not imported yet, so speed records are withheld."
        case .rowing: "Distance and duration are shown when recorded. Exact-distance effort and power records require detailed samples not imported yet."
        case .yoga, .pilates: "Frequency and duration describe activity. Longer sessions are not automatically better performance."
        default: "Metrics reflect available workout data. Calories and higher heart rate are not treated as personal bests."
        }
    }
}
private struct WeekMinutes { let date: Date; let minutes: Double; let meters: Double }
private extension PerformanceRecord { var uniqueKey: String { "\(id)-\(session.environment)" } }

struct PerformanceHistory: View {
    @Bindable var store: PerformanceStore
    @State private var search = ""
    @State private var kindFilter = "All"
    private var filtered: [PerformanceSession] {
        store.sessions.filter { (kindFilter == "All" || $0.kind.rawValue == kindFilter) && (search.isEmpty || $0.kind.rawValue.localizedCaseInsensitiveContains(search) || $0.source.localizedCaseInsensitiveContains(search)) }
    }
    var body: some View {
        NavigationStack {
            List {
                Picker("Workout type", selection: $kindFilter) {
                    Text("All").tag("All")
                    ForEach(ActivityKind.allCases) { Text($0.rawValue).tag($0.rawValue) }
                }
                NavigationLink("Compare two sessions") { SessionComparison(sessions: store.sessions) }
                ForEach(filtered) { SessionLink(session: $0) }
                HealthStatus(store: store)
            }
            .navigationTitle("History")
            .searchable(text: $search, prompt: "Workout type or source")
            .refreshable { await store.refresh(force: true) }
            .task { await store.refresh() }
        }
    }
}
struct SessionLink: View {
    let session: PerformanceSession
    var body: some View {
        NavigationLink { SessionDetail(session: session) } label: {
            VStack(alignment: .leading, spacing: 4) {
                Label(session.kind.rawValue, systemImage: session.kind.icon).font(.headline)
                Text("\(session.date.formatted(date: .abbreviated, time: .shortened)) · \(PerformanceMath.time(session.duration))").font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}
struct SessionDetail: View {
    let session: PerformanceSession
    var body: some View {
        List {
            LabeledContent("Date", value: session.date.formatted())
            LabeledContent("Active duration", value: PerformanceMath.time(session.duration))
            if session.kind.hasDistance, let distance = session.distance {
                LabeledContent("Actual distance", value: PerformanceMath.distance(distance, kind: session.kind))
                if distance > 0 {
                    let unit = [.swimming, .rowing].contains(session.kind) ? 100.0 : PerformanceMath.mile
                    LabeledContent("Average active pace", value: "\(PerformanceMath.time(session.duration / distance * unit)) /\(unit == 100 ? "100 m" : "mi")")
                }
            }
            LabeledContent("Environment", value: session.environment)
            LabeledContent("Source", value: session.source)
            if let elevation = session.elevation { LabeledContent("Elevation ascended", value: String(format: "%.0f m", elevation)) }
        }.navigationTitle(session.kind.rawValue)
    }
}
struct RecordDetail: View {
    let record: PerformanceRecord
    var body: some View {
        List {
            Section {
                Text(record.title).font(.title2.bold())
                Text(record.value).font(.largeTitle.bold()).foregroundStyle(.tint)
                Text(record.explanation)
                if let previous = record.previous { Text(previous) }
                if let effort = record.effort {
                    LabeledContent("Segment begins", value: "\(PerformanceMath.time(effort.startSeconds)) after start")
                    LabeledContent("Segment ends", value: "\(PerformanceMath.time(effort.endSeconds)) after start")
                }
            }
            Section("Source workout") { SessionLink(session: record.session) }
        }.navigationTitle("Record details")
    }
}
struct HealthStatus: View {
    @Bindable var store: PerformanceStore
    var body: some View {
        Section {
            if store.loading { ProgressView("Reading workout history…") }
            if let message = store.message { Text(message).foregroundStyle(.secondary) }
            if !store.loading && store.sessions.isEmpty {
                Text("No accessible workouts. Check Apple Health read access and recorded workouts, then pull to refresh. Denied access and missing data can both appear empty.")
            }
        }
    }
}

struct SessionComparison: View {
    let sessions: [PerformanceSession]
    @State private var firstID: UUID?
    @State private var secondID: UUID?
    private var first: PerformanceSession? { sessions.first { $0.id == firstID } }
    private var second: PerformanceSession? { sessions.first { $0.id == secondID } }
    private var candidates: [PerformanceSession] {
        guard let first else { return [] }
        return sessions.filter { $0.id != first.id && $0.kind == first.kind && $0.environment == first.environment }
    }
    var body: some View {
        List {
            Picker("First session", selection: $firstID) {
                Text("Choose session").tag(Optional<UUID>.none)
                ForEach(sessions) { Text(label($0)).tag(Optional($0.id)) }
            }.onChange(of: firstID) { _, _ in secondID = nil }
            if let first {
                Picker("Second session", selection: $secondID) {
                    Text("Choose session").tag(Optional<UUID>.none)
                    ForEach(candidates) { Text(label($0)).tag(Optional($0.id)) }
                }
                Text("Comparisons use the same workout type and recorded environment. Route, conditions and equipment may differ.").font(.footnote).foregroundStyle(.secondary)
                if let second {
                    Section("Active duration") {
                        LabeledContent("First", value: PerformanceMath.time(first.duration))
                        LabeledContent("Second", value: PerformanceMath.time(second.duration))
                        LabeledContent("Difference", value: PerformanceMath.time(abs(first.duration - second.duration)))
                    }
                    if first.kind.hasDistance, let a = first.distance, let b = second.distance {
                        Section("Recorded distance") {
                            LabeledContent("First", value: PerformanceMath.distance(a, kind: first.kind))
                            LabeledContent("Second", value: PerformanceMath.distance(b, kind: first.kind))
                        }
                    }
                    Section("Original sessions") { SessionLink(session: first); SessionLink(session: second) }
                } else if candidates.isEmpty { Text("No other session with matching workout type and environment.") }
            }
        }.navigationTitle("Compare sessions")
    }
    private func label(_ session: PerformanceSession) -> String {
        "\(session.kind.rawValue) · \(session.date.formatted(date: .abbreviated, time: .shortened)) · \(PerformanceMath.time(session.duration))"
    }
}
