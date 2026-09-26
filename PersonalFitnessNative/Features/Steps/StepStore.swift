import Foundation
import Observation

@MainActor
@Observable
final class StepStore {
    private let healthKit: HealthKitClient

    var steps: Int
    var isLoading = false
    var message: String?

    init(
        healthKit: HealthKitClient = HealthKitClient(),
        steps: Int = 0
    ) {
        self.healthKit = healthKit
        self.steps = steps
    }

    func refresh() async {
        if ProcessInfo.processInfo.arguments.contains("--ui-snapshot") {
            steps = 6_842
            isLoading = false
            message = nil
            return
        }

        isLoading = true
        message = nil
        defer { isLoading = false }

        do {
            try await healthKit.requestStepAuthorization()
            steps = try await healthKit.todayStepCount()
        } catch {
            steps = 0
            message = error.localizedDescription
        }
    }

    static var preview: StepStore {
        StepStore(steps: 6_842)
    }
}
