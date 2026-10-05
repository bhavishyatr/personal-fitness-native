import SwiftUI
import Charts

struct InsightsHome: View {
    @Bindable var store: PerformanceStore
    var body: some View {
        NavigationStack {
            if ProcessInfo.processInfo.arguments.contains("--snapshot-calendar") {
                ConsistencyCalendar(store: store)
            } else if ProcessInfo.processInfo.arguments.contains("--snapshot-recap") {
                MonthlyRecap(store: store)
            } else if ProcessInfo.processInfo.arguments.contains("--snapshot-duplicates") {
                DataQualityView(store: store)
            } else if ProcessInfo.processInfo.arguments.contains("--snapshot-records") {
                RecordDirectory(store: store)
            } else {
                List {
                    Section("Explore your history") {
                        NavigationLink("Records & top performances") { RecordDirectory(store: store) }.accessibilityIdentifier("records-link")
                        NavigationLink("Monthly recap") { MonthlyRecap(store: store) }.accessibilityIdentifier("recap-link")
                        NavigationLink("Activity calendar") { ConsistencyCalendar(store: store) }.accessibilityIdentifier("calendar-link")
                        NavigationLink("Data quality & exclusions") { DataQualityView(store: store) }.accessibilityIdentifier("quality-link")
                    }
                    Section("Personal highlights") {
                        Text("Based on included workouts. Tap a highlight to inspect its evidence.").font(.caption).foregroundStyle(.secondary)
                        ForEach(Array(events.prefix(10)), id: \.key) { event in
                            NavigationLink { SeriesDetail(series: event.series) } label: {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text("\(event.series.kind.rawValue) · \(event.series.title)").font(.headline)
                                    Text(event.entry.record.value).foregroundStyle(.tint)
                                    Text("\(event.series.environment) · \(event.entry.record.session.date.formatted(date: .abbreviated, time: .omitted))").font(.caption)
                                    Text(event.baseline ? "First recorded benchmark" : "New recorded best").font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                        if events.isEmpty { Text("No record highlights in accessible history yet.") }
                    }
                    HealthStatus(store: store)
                }.navigationTitle("Insights")
            }
        }.task { await store.refresh() }.refreshable { await store.refresh(force: true) }
    }
    private var events: [HighlightEvent] {
        store.recordSeries.flatMap { series in
            series.progression.enumerated().map { index, entry in HighlightEvent(series: series, entry: entry, baseline: index == 0) }
        }.sorted { $0.entry.record.session.date > $1.entry.record.session.date }
    }
}
private struct HighlightEvent {
    let series: RecordSeries
    let entry: RankedPerformance
    let baseline: Bool
    var key: String { "\(series.id)|\(entry.id)" }
}

struct RecordDirectory: View {
    @Bindable var store: PerformanceStore
    @State private var kind = "All"
    var body: some View {
        List {
            Picker("Workout type", selection: $kind) {
                Text("All").tag("All")
                ForEach(ActivityKind.allCases) { Text($0.rawValue).tag($0.rawValue) }
            }
            ForEach(store.recordSeries.filter { kind == "All" || $0.kind.rawValue == kind }) { series in
                NavigationLink { SeriesDetail(series: series) } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(series.kind.rawValue) · \(series.title)").font(.headline)
                        Text("\(series.environment) · \(series.entries.count) performances").font(.caption).foregroundStyle(.secondary)
                        if let winner = series.ranking.first { Text(winner.record.value).foregroundStyle(.tint) }
                    }
                }.accessibilityIdentifier("series-\(series.kind.rawValue)-\(series.metricID)-\(series.environment)")
            }
            if store.recordSeries.isEmpty { Text("No record data available yet.") }
        }.navigationTitle("Records")
    }
}

struct SeriesDetail: View {
    @Environment(PerformanceStore.self) private var store
    let series: RecordSeries
    // Re-resolve after exclusions so an open record page cannot display stale rankings.
    private var current: RecordSeries? { store.recordSeries.first { $0.id == series.id } }
    var body: some View {
        List {
            Section {
                Text(series.title).font(.title2.bold())
                Text("\(series.kind.rawValue) · \(series.environment)").foregroundStyle(.secondary)
                Text("Included recorded workouts only. Ties retain the earlier benchmark. Each workout contributes one best result to this metric.").font(.footnote)
            }
            if let current {
                Section("Record progression") {
                    Chart(current.progression) { entry in
                        PointMark(x: .value("Date", entry.record.session.date), y: .value("Value", chartValue(entry)))
                        LineMark(x: .value("Date", entry.record.session.date), y: .value("Value", chartValue(entry)))
                    }.frame(height: 170).accessibilityLabel("Record progression for \(series.title)")
                    Text(chartUnit).font(.caption).foregroundStyle(.secondary)
                    ForEach(current.progression) { entry in
                        NavigationLink { RecordDetail(record: entry.record) } label: {
                            LabeledContent(entry.record.session.date.formatted(date: .abbreviated, time: .omitted), value: entry.record.value)
                        }
                    }
                }
                Section("Top 10 performances") {
                    ForEach(Array(current.ranking.prefix(10).enumerated()), id: \.element.id) { index, entry in
                        NavigationLink { RecordDetail(record: entry.record) } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(index + 1). \(entry.record.value)").font(.headline)
                                Text("\(entry.record.session.date.formatted(date: .abbreviated, time: .omitted)) · \(entry.record.session.source)").font(.caption)
                            }
                        }
                    }
                }
            } else { Text("All performances for this metric are excluded or unavailable.") }
        }.navigationTitle("Performance history")
    }
    private var chartUnit: String {
        if series.metricID == "Longest distance" { return [.swimming, .rowing].contains(series.kind) ? "Meters" : "Miles" }
        return series.metricID == "Most climbing" ? "Meters ascended" : "Minutes · elapsed for continuous efforts, active for whole workouts"
    }
    private func chartValue(_ entry: RankedPerformance) -> Double {
        if series.metricID == "Longest distance" { return entry.score / ([.swimming, .rowing].contains(series.kind) ? 1 : PerformanceMath.mile) }
        return series.metricID == "Most climbing" ? entry.score : entry.score / 60
    }
}

struct MonthNavigation: View {
    @Binding var month: Date
    var body: some View {
        HStack {
            Button { change(-1) } label: { Image(systemName: "chevron.left") }.accessibilityLabel("Previous month")
            Spacer()
            Text(month.formatted(.dateTime.month(.wide).year())).font(.headline)
            Spacer()
            Button { change(1) } label: { Image(systemName: "chevron.right") }.accessibilityLabel("Next month")
        }
    }
    private func change(_ count: Int) { month = Calendar.current.date(byAdding: .month, value: count, to: Calendar.current.dateInterval(of: .month, for: month)!.start)! }
}

struct MonthlyRecap: View {
    @Bindable var store: PerformanceStore
    @State private var month = Date()
    private var summary: MonthSummary { InsightMath.month(month, sessions: store.sessions, series: store.recordSeries) }
    var body: some View {
        List {
            Section {
                MonthNavigation(month: $month)
                Text("Current month is to date; comparison is with the previous full calendar month. Excluded sessions are omitted.").font(.caption).foregroundStyle(.secondary)
                LabeledContent("Sessions", value: "\(summary.sessions.count)")
                LabeledContent("Active days", value: "\(summary.activeDays)")
                LabeledContent("Active workout time", value: PerformanceMath.time(summary.duration))
                LabeledContent("New record improvements", value: "\(summary.recordEvents.count)")
                LabeledContent("Previous month sessions", value: "\(summary.previousSessions.count)")
            }
            Section("By workout type") {
                ForEach(ActivityKind.allCases.filter { kind in summary.sessions.contains { $0.kind == kind } }) { kind in
                    let items = summary.sessions.filter { $0.kind == kind }
                    NavigationLink { RecapEvidence(title: kind.rawValue, sessions: items) } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("\(kind.rawValue) · \(items.count) sessions", systemImage: kind.icon)
                            Text(PerformanceMath.time(items.reduce(0) { $0 + $1.duration })).font(.caption)
                            if kind.hasDistance {
                                Text(PerformanceMath.distance(items.compactMap(\.distance).reduce(0, +), kind: kind)).font(.caption)
                            }
                        }
                    }
                }
            }
            Section("Record highlights") {
                ForEach(Array(summary.recordEvents.enumerated()), id: \.offset) { _, event in
                    NavigationLink { SeriesDetail(series: event.0) } label: {
                        Text("\(event.0.kind.rawValue) · \(event.0.title): \(event.1.record.value)")
                    }
                }
                if summary.recordEvents.isEmpty { Text("No new recorded bests this month. First benchmarks are not counted as improvements.") }
            }
            Section("Supporting workouts") { ForEach(summary.sessions) { SessionLink(session: $0) } }
        }.navigationTitle("Monthly recap")
    }
}
struct RecapEvidence: View {
    let title: String
    let sessions: [PerformanceSession]
    var body: some View { List { ForEach(sessions) { SessionLink(session: $0) } }.navigationTitle(title) }
}

struct ConsistencyCalendar: View {
    @Bindable var store: PerformanceStore
    @State private var month = Date()
    @State private var kind = "All"
    @State private var selectedDay: Date?
    private var calendar: Calendar { .current }
    private var monthStart: Date { calendar.dateInterval(of: .month, for: month)!.start }
    private var items: [PerformanceSession] {
        let end = calendar.date(byAdding: .month, value: 1, to: monthStart)!
        return store.sessions.filter { $0.date >= monthStart && $0.date < end && (kind == "All" || $0.kind.rawValue == kind) }
    }
    var body: some View {
        List {
            Section {
                MonthNavigation(month: $month).onChange(of: month) { _, _ in selectedDay = nil }
                Picker("Workout type", selection: $kind) {
                    Text("All").tag("All")
                    ForEach(ActivityKind.allCases) { Text($0.rawValue).tag($0.rawValue) }
                }
                Text("\(Set(items.map { calendar.startOfDay(for: $0.date) }).count) active days · \(items.count) sessions").font(.subheadline)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                    ForEach(0..<7, id: \.self) { i in
                        Text(calendar.veryShortStandaloneWeekdaySymbols[(calendar.firstWeekday - 1 + i) % 7]).font(.caption).foregroundStyle(.secondary)
                    }
                    ForEach(0..<cellCount, id: \.self) { index in
                        if index < offset { Color.clear.frame(height: 42) }
                        else {
                            let day = calendar.date(byAdding: .day, value: index - offset, to: monthStart)!
                            let count = items.filter { calendar.isDate($0.date, inSameDayAs: day) }.count
                            Button { selectedDay = day } label: {
                                VStack(spacing: 3) {
                                    Text("\(index - offset + 1)")
                                    Circle().fill(count > 0 ? Color.accentColor : Color.clear).frame(width: 5, height: 5)
                                }.frame(maxWidth: .infinity, minHeight: 42)
                                .background(selectedDay.map { calendar.isDate($0, inSameDayAs: day) } == true ? Color.accentColor.opacity(0.15) : Color.clear, in: RoundedRectangle(cornerRadius: 8))
                            }.buttonStyle(.plain).accessibilityLabel("\(day.formatted(date: .complete, time: .omitted)), \(count) workouts")
                        }
                    }
                }
                Text("Dot = recorded activity. Rest days are shown without judgment. Excluded sessions are omitted.").font(.caption).foregroundStyle(.secondary)
            }
            Section(selectedDay?.formatted(date: .complete, time: .omitted) ?? "Workouts this month") {
                let visible = items.filter { session in selectedDay.map { calendar.isDate(session.date, inSameDayAs: $0) } ?? true }
                ForEach(visible) { SessionLink(session: $0) }
                if visible.isEmpty { Text("No included workouts for this selection.") }
            }
        }.navigationTitle("Activity calendar")
    }
    private var offset: Int { (calendar.component(.weekday, from: monthStart) - calendar.firstWeekday + 7) % 7 }
    private var cellCount: Int { offset + calendar.range(of: .day, in: .month, for: monthStart)!.count }
}

struct DataQualityView: View {
    @Bindable var store: PerformanceStore
    private var pairs: [DuplicatePair] { InsightMath.duplicates(store.allSessions) }
    var body: some View {
        List {
            Section {
                Text("Review possible duplicates").font(.headline)
                Text("Suggestions compare activity, environment, start times within 60 seconds, and duration/distance within 2% (minimum tolerance: 5 seconds / 10 meters). They are not proof of duplication. Nothing is excluded automatically.").font(.footnote).foregroundStyle(.secondary)
                Text("Exclusions apply to records, charts, recaps and calendar. Original sessions remain in History and Apple Health. Restore them at any time.").font(.footnote)
            }
            Section("Possible duplicate pairs · \(pairs.count)") {
                ForEach(pairs) { pair in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(pair.first.kind.rawValue).font(.headline)
                        SessionLink(session: pair.first)
                        ExclusionControl(store: store, session: pair.first)
                        SessionLink(session: pair.second)
                        ExclusionControl(store: store, session: pair.second)
                    }
                }
                if pairs.isEmpty { Text("No possible duplicates found with these rules.") }
            }
            Section("Excluded sessions") {
                let excluded = store.allSessions.filter { store.isExcluded($0.id) }
                ForEach(excluded) { session in
                    SessionLink(session: session)
                    ExclusionControl(store: store, session: session)
                }
                if excluded.isEmpty { Text("No sessions excluded.") }
            }
        }.navigationTitle("Data quality")
    }
}
struct ExclusionControl: View {
    @Bindable var store: PerformanceStore
    let session: PerformanceSession
    var body: some View {
        Toggle("Include in performance analytics", isOn: Binding(get: { !store.isExcluded(session.id) }, set: { store.setExcluded(!$0, id: session.id) }))
            .accessibilityIdentifier("include-\(session.id)")
    }
}
