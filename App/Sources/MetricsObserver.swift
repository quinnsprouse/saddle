import MetricKit
import os

nonisolated final class MetricsObserver: NSObject, MXMetricManagerSubscriber, Sendable {
    private static let shared = MetricsObserver()

    private let logger = Logger(subsystem: "App", category: "MetricKit")

    static func start() {
        MXMetricManager.shared.add(shared)
    }

    func didReceive(_ payloads: [MXMetricPayload]) {
        for payload in payloads {
            logger.notice("Metric payload: \(payload.jsonRepresentation().count, privacy: .public) bytes")
        }
    }

    func didReceive(_ payloads: [MXDiagnosticPayload]) {
        for payload in payloads {
            logger.error("Diagnostic payload: \(payload.jsonRepresentation().count, privacy: .public) bytes")
        }
    }
}
