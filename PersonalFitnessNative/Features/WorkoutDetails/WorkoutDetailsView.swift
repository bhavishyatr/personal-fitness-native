import SwiftUI
import Charts
import MapKit

struct WorkoutDetailsView: View {
    let session: PerformanceSession
    @State private var store = WorkoutDetailStore()
    var body: some View {
        List {
            Section {
                Text(session.date.formatted()).font(.headline)
                Text("Only samples linked to this workout are shown. Missing data and denied read access can both appear empty. Refresh after changing Apple Health permissions.").font(.footnote)
                if ProcessInfo.processInfo.arguments.contains("--ui-snapshot") { Text("Sample data — not your health data").foregroundStyle(.secondary) }
                if store.loading { ProgressView("Reading workout details…") }
                ForEach(store.errors, id: \.self) { Text($0).foregroundStyle(.secondary) }
                Button("Refresh details") { Task { await store.load(session) } }.disabled(store.loading)
            }
            SensorSection(title: "Heart rate", unit: "bpm", readings: store.heartRate, start: session.date, color: .red)
            if session.kind == .cycling {
                SensorSection(title: "Cycling power", unit: "W", readings: store.power, start: session.date, color: .orange)
                SensorSection(title: "Cycling cadence", unit: "rpm", readings: store.cadence, start: session.date, color: .purple)
            }
            if session.kind.hasDistance {
                Section("Recorded route") {
                    if store.routes.isEmpty {
                        Text("No accessible route. A route must have been recorded and shared with Apple Health.").foregroundStyle(.secondary)
                    } else {
                        Map {
                            ForEach(Array(store.routes.enumerated()), id: \.offset) { _, segment in
                                MapPolyline(coordinates: segment.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }).stroke(.blue, lineWidth: 4)
                            }
                        }.frame(height: 260).accessibilityLabel("Recorded workout route")
                        Text("\(store.routes.reduce(0) { $0 + $1.count }) recorded locations. Gaps over 60 seconds and inaccurate locations split the path. Route data is not used to recalculate distance or records.").font(.caption)
                    }
                }
            }
            if session.kind == .strength {
                NavigationLink("Exercise sets (manual)") { StrengthLogView(session: session) }.accessibilityIdentifier("strength-log")
            }
        }
        .navigationTitle("Workout details")
        .task(id: session.id) { await store.load(session) }
    }
}

private struct SensorSection: View {
    let title: String
    let unit: String
    let readings: [SensorReading]
    let start: Date
    let color: Color
    var body: some View {
        Section(title) {
            if readings.isEmpty {
                Text("No accessible \(title.lowercased()) samples for this workout.").foregroundStyle(.secondary)
            } else {
                let values = readings.map(\.value)
                LabeledContent("Recorded range", value: String(format: "%.0f–%.0f %@", values.min()!, values.max()!, unit))
                Chart(readings) { reading in
                    PointMark(x: .value("Minutes elapsed", reading.date.timeIntervalSince(start) / 60), y: .value(unit, reading.value))
                        .foregroundStyle(color).symbolSize(10)
                        .accessibilityLabel("\(reading.date.formatted(date: .omitted, time: .standard)), \(reading.value, specifier: "%.0f") \(unit), \(reading.source)")
                }.frame(height: 180).chartXAxisLabel("Minutes elapsed").chartYAxisLabel(unit)
                Text("\(readings.count) samples · \(Set(readings.map(\.source)).sorted().joined(separator: ", "))").font(.caption)
                Text("Dots show recorded sample values. Apple Health may combine measurements into interval averages. Gaps are not filled; this is not a whole-workout average or an instantaneous peak.").font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}

struct StrengthLogView: View {
    let session: PerformanceSession
    @State private var store = StrengthLogStore()
    @State private var editing: StrengthSet?
    var body: some View {
        List {
            Section {
                Text("Manual entries for this workout, saved on this device. These are not imported from or written to Apple Health and do not change performance records.").font(.footnote)
                Text("Weight is external load in kilograms. Use 0 for an unweighted/bodyweight set.").font(.caption)
                if let error = store.error { Text(error).foregroundStyle(.red) }
            }
            Section("Recorded sets") {
                if store.sets.isEmpty { Text("No sets entered yet.") }
                ForEach(Array(store.sets.enumerated()), id: \.element.id) { index, entry in
                    Button { editing = entry } label: {
                        VStack(alignment: .leading) {
                            Text("\(index + 1). \(entry.exercise)")
                            Text("\(entry.reps) reps · \(entry.kilograms, specifier: "%.1f") kg").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }.onDelete { offsets in
                    var next = store.sets; next.remove(atOffsets: offsets); store.save(next)
                }
                Button("Add set") { editing = StrengthSet(exercise: "", reps: 10, kilograms: 0) }.accessibilityIdentifier("add-strength-set")
            }
        }
        .navigationTitle("Exercise sets")
        .task(id: session.id) { store.load(session.id) }
        .sheet(item: $editing) { entry in
            StrengthSetEditor(entry: entry) { updated in
                var next = store.sets
                if let index = next.firstIndex(where: { $0.id == updated.id }) { next[index] = updated }
                else { next.append(updated) }
                return store.save(next)
            }
        }
    }
}

private struct StrengthSetEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State var entry: StrengthSet
    var save: (StrengthSet) -> Bool
    @State private var failed = false
    var body: some View {
        NavigationStack {
            Form {
                TextField("Exercise", text: $entry.exercise).accessibilityIdentifier("exercise-name")
                TextField("Reps", value: $entry.reps, format: .number).keyboardType(.numberPad).accessibilityIdentifier("exercise-reps")
                TextField("Weight (kg)", value: $entry.kilograms, format: .number).keyboardType(.decimalPad).accessibilityIdentifier("exercise-weight")
                if failed { Text("Unable to save. Close this form to see the storage error and retry.").foregroundStyle(.red) }
            }.navigationTitle("Edit set")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            entry.exercise = entry.exercise.trimmingCharacters(in: .whitespacesAndNewlines)
                            if save(entry) { dismiss() } else { failed = true }
                        }.disabled(!entry.isValid).accessibilityIdentifier("save-strength-set")
                    }
                }
        }
    }
}
