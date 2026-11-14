import CoreMotion
import Foundation

enum StepCounterError: LocalizedError {
    case unavailable
    case noData
    case timedOut
    case invalidCallback

    var errorDescription: String? {
        switch self {
        case .unavailable:
            return "此 iPhone 不支援步數計算。"
        case .noData:
            return "iPhone 沒有回傳步數資料，請確認「設定 > 隱私權與安全性 > 動作與健身」已允許 FlyPin Companion。"
        case .timedOut:
            return "iPhone 步數讀取逾時（15 秒）。請確認動作與健身權限後再試一次。"
        case .invalidCallback:
            return "無法建立 FlyPin 網頁回傳連結。"
        }
    }
}

private final class StepQueryGate: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<Int, Error>?

    init(_ continuation: CheckedContinuation<Int, Error>) {
        self.continuation = continuation
    }

    func finish(_ result: Result<Int, Error>) {
        lock.lock()
        let pending = continuation
        continuation = nil
        lock.unlock()

        pending?.resume(with: result)
    }
}

enum StepCounterService {
    // Keep one manager alive for the entire query. A temporary CMPedometer
    // instance can be released before Core Motion delivers its callback.
    private static let pedometer = CMPedometer()

    static func queryTodaySteps() async throws -> Int {
        guard CMPedometer.isStepCountingAvailable() else {
            throw StepCounterError.unavailable
        }

        let startOfDay = Calendar.current.startOfDay(for: Date())
        let end = Date()

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Int, Error>) in
            let gate = StepQueryGate(continuation)

            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 15) {
                gate.finish(.failure(StepCounterError.timedOut))
            }

            pedometer.queryPedometerData(from: startOfDay, to: end) { data, error in
                if let error {
                    gate.finish(.failure(error))
                    return
                }
                guard let data else {
                    gate.finish(.failure(StepCounterError.noData))
                    return
                }
                gate.finish(.success(data.numberOfSteps.intValue))
            }
        }
    }
}
