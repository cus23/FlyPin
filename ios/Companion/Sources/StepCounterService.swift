import CoreMotion
import Foundation

enum StepCounterError: LocalizedError {
    case unavailable
    case noData
    case invalidCallback

    var errorDescription: String? {
        switch self {
        case .unavailable:
            return "此 iPhone 不支援步數計算。"
        case .noData:
            return "目前無法取得步數資料，請稍後再試。"
        case .invalidCallback:
            return "無法建立 FlyPin 網頁回傳連結。"
        }
    }
}

enum StepCounterService {
    static func queryTodaySteps() async throws -> Int {
        guard CMPedometer.isStepCountingAvailable() else {
            throw StepCounterError.unavailable
        }

        let startOfDay = Calendar.current.startOfDay(for: Date())
        let end = Date()

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Int, Error>) in
            CMPedometer().queryPedometerData(from: startOfDay, to: end) { data, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let data else {
                    continuation.resume(throwing: StepCounterError.noData)
                    return
                }
                continuation.resume(returning: data.numberOfSteps.intValue)
            }
        }
    }
}
