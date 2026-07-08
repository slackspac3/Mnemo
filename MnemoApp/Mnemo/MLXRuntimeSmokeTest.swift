import Foundation

#if DEBUG
#if canImport(MLX)
import MLX
#endif

struct MLXRuntimeSmokeTestResult: Equatable, Sendable {
    let isLinked: Bool
    let operationSucceeded: Bool
    let resultPreview: String
    let errorMessage: String?
    let durationMs: Double
}

enum MLXRuntimeSmokeTest {
    static let launchArgument = "--run-mlx-runtime-smoke"

    static var shouldRunFromLaunchArguments: Bool {
        ProcessInfo.processInfo.arguments.contains(launchArgument)
    }

    static func run() -> MLXRuntimeSmokeTestResult {
        #if canImport(MLX)
        #if targetEnvironment(simulator)
        return MLXRuntimeSmokeTestResult(
            isLinked: true,
            operationSucceeded: false,
            resultPreview: "MLX linked; simulator runtime smoke skipped",
            errorMessage: "MLX runtime operation is guarded off on Simulator after a libc++ assertion during validation. Run on a signed physical iPhone DEBUG build.",
            durationMs: 0
        )
        #else
        let startedAt = Date()
        let lhs = MLXArray(1.0)
        let rhs = MLXArray(2.0)
        let sum = lhs + rhs
        sum.eval()

        let value = sum.item(Float.self)
        let succeeded = abs(value - 3.0) < 0.0001

        return MLXRuntimeSmokeTestResult(
            isLinked: true,
            operationSucceeded: succeeded,
            resultPreview: "1 + 2 = \(value)",
            errorMessage: succeeded ? nil : "Unexpected MLX result \(value)",
            durationMs: Date().timeIntervalSince(startedAt) * 1_000
        )
        #endif
        #else
        return MLXRuntimeSmokeTestResult(
            isLinked: false,
            operationSucceeded: false,
            resultPreview: "MLX not linked",
            errorMessage: "MLX module is not available in this build.",
            durationMs: 0
        )
        #endif
    }
}
#endif
