import HealthKit
import Foundation

enum StepCounterError: LocalizedError {
    case unavailable
    case noData
    case invalidCallback
    case timedOut

    var errorDescription: String? {
        switch self {
        case .unavailable:
            return "此 iPhone 無法使用 Apple 健康資料。"
        case .noData:
            return "Apple 健康沒有回傳今日步數。請確認已允許 FlyPin Companion 讀取「步數」資料。"
        case .invalidCallback:
            return "無法建立 FlyPin 網頁回傳連結。"
        case .timedOut:
            return "Apple 健康讀取逾時，請稍後再試。"
        }
    }
}

private final class HealthQueryGate: @unchecked Sendable {
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
    private static let healthStore = HKHealthStore()

    static func queryTodaySteps() async throws -> Int {
        guard HKHealthStore.isHealthDataAvailable(),
              let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            throw StepCounterError.unavailable
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            healthStore.requestAuthorization(toShare: [], read: [stepType]) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if success {
                    continuation.resume(returning: ())
                } else {
                    continuation.resume(throwing: StepCounterError.noData)
                }
            }
        }

        let start = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Int, Error>) in
            let gate = HealthQueryGate(continuation)
            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 20) {
                gate.finish(.failure(StepCounterError.timedOut))
            }

            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error {
                    gate.finish(.failure(error))
                    return
                }
                guard let quantity = statistics?.sumQuantity() else {
                    gate.finish(.failure(StepCounterError.noData))
                    return
                }
                gate.finish(.success(Int(quantity.doubleValue(for: .count()).rounded())))
            }
            healthStore.execute(query)
        }
    }
}
