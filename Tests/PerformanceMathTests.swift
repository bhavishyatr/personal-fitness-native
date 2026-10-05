import Foundation

@main
struct PerformanceMathTests {
    static func main() {
        func check(_ condition: Bool, _ message: String) { precondition(condition, message) }
        // The fastest mile is inside a longer workout, not the full workout duration.
        let points = (0...300).map { i in DistancePoint(seconds: Double(i) * 10, meters: Double(i) * 20) }
        let effort = PerformanceMath.fastest(points, meters: 1609.344)!
        check(abs(effort.seconds - 804.672) < 0.001, "Exact target must interpolate")
        check(PerformanceMath.fastest(points, meters: 7000) == nil, "Too short must not create record")
        check(PerformanceMath.fastest([DistancePoint(seconds: 0, meters: 0), DistancePoint(seconds: 40, meters: 100), DistancePoint(seconds: 50, meters: 200)], meters: 100) == nil, "Coarse samples rejected")
        check(PerformanceMath.fastest([DistancePoint(seconds: 0, meters: 0), DistancePoint(seconds: 10, meters: 100), DistancePoint(seconds: 20, meters: 90)], meters: 50) == nil, "Decreasing distance rejected")
        let pause = [DistancePoint(seconds: 0, meters: 0), DistancePoint(seconds: 10, meters: 100), DistancePoint(seconds: 30, meters: 100), DistancePoint(seconds: 40, meters: 200)]
        check(PerformanceMath.fastest(pause, meters: 200)?.seconds == 40, "Pause inside effort counts")
        check(PerformanceMath.fastest(pause, meters: 100)?.seconds == 10, "Departure after pause allowed")
        let now = Date()
        let strength = PerformanceSession(id: UUID(), kind: .strength, date: now, duration: 1800, distance: 1000, source: "Test", environment: "Indoor")
        let strengthRecords = PerformanceMath.records([strength], kind: .strength)
        check(!strengthRecords.contains { $0.title.contains("distance") || $0.title.contains("mi") }, "Strength must not show distance records")
        let longRun = PerformanceSession(id: UUID(), kind: .running, date: now, duration: 3000, distance: 6000, source: "Test", environment: "Outdoor", points: points)
        let runRecords = PerformanceMath.records([longRun], kind: .running)
        check(runRecords.contains { $0.title == "Fastest continuous 1 mi" }, "Long run contributes a mile effort")
        check(!runRecords.contains { $0.title == "Best whole run near 1 mi" }, "Long run is not a whole mile run")
        check(PerformanceMath.records([], kind: .running).isEmpty, "No fabricated records")
        let old = now.addingTimeInterval(-86400 * 40)
        let first = PerformanceSession(id: UUID(), kind: .running, date: old, duration: 600, distance: PerformanceMath.mile, source: "Test", environment: "Outdoor")
        let improved = PerformanceSession(id: UUID(), kind: .running, date: now, duration: 500, distance: PerformanceMath.mile, source: "Test", environment: "Outdoor")
        let tie = PerformanceSession(id: UUID(), kind: .running, date: now.addingTimeInterval(10), duration: 500, distance: PerformanceMath.mile, source: "Second source", environment: "Outdoor")
        let indoor = PerformanceSession(id: UUID(), kind: .running, date: now, duration: 400, distance: PerformanceMath.mile, source: "Test", environment: "Indoor")
        let all = [first, improved, tie, indoor]
        let series = InsightMath.series(all)
        let mileSeries = series.first { $0.metricID == "Best whole run near 1 mi" && $0.environment == "Outdoor" }!
        check(mileSeries.ranking.first?.id == improved.id, "Rank ties by earlier performance")
        check(mileSeries.progression.count == 2, "Ties must not create record improvements")
        check(mileSeries.progression.last?.score == 500, "Lower time is better")
        check(InsightMath.duplicates(all).count == 1, "Only matching near-time sessions are duplicate candidates")
        let excluded = InsightMath.eligible(all, excluding: [improved.id, tie.id])
        let remaining = InsightMath.series(excluded).first { $0.metricID == "Best whole run near 1 mi" && $0.environment == "Outdoor" }!
        check(remaining.ranking.first?.id == first.id, "Exclusion recalculates winner")
        let recap = InsightMath.month(now, sessions: all, series: series)
        check(recap.sessions.count == 3, "Calendar-month session boundaries")
        check(recap.recordEvents.contains { $0.0.metricID == "Best whole run near 1 mi" && $0.1.id == improved.id }, "Recap includes new improvements")
        check(!recap.recordEvents.contains { $0.1.id == indoor.id }, "First benchmark is not a new improvement")
        let duplicateNoDistance = PerformanceSession(id: UUID(), kind: .running, date: now, duration: 500, distance: nil, source: "Test", environment: "Outdoor")
        check(InsightMath.duplicates([improved, duplicateNoDistance]).isEmpty, "Missing distance is insufficient duplicate evidence")
        check(InsightMath.series([strength]).allSatisfy { $0.metricID != "Longest distance" }, "Strength ranking excludes distance")
        print("Performance analytics and insights checks passed")
    }
}
