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
        print("Performance analytics checks passed")
    }
}
