import Foundation

#if canImport(Combine)
import Combine
#endif

#if canImport(Network)
import Network
#endif

// MARK: - Models

public struct SpeedTestResult {
    public let totalDataSize: UInt64
    public let duration: TimeInterval
    public let speedMBps: Double
    public let performanceRating: PerformanceRating
    
    public init(totalDataSize: UInt64, duration: TimeInterval) {
        self.totalDataSize = totalDataSize
        self.duration = duration
        self.speedMBps = duration > 0 ? Double(totalDataSize) / 1_048_576.0 / duration : 0
        self.performanceRating = PerformanceRating.evaluate(speedMBps: self.speedMBps)
    }
}

public enum PerformanceRating {
    case excellent
    case good
    case average
    case slow
    case verySlow
    
    public static func evaluate(speedMBps: Double) -> PerformanceRating {
        switch speedMBps {
        case 100...:
            return .excellent
        case 80..<100:
            return .good
        case 50..<80:
            return .average
        case 10..<50:
            return .slow
        default:
            return .verySlow
        }
    }
    
    public var emoji: String {
        switch self {
        case .excellent: return "✅"
        case .good: return "⚡"
        case .average: return "⚠️"
        case .slow: return "🐌"
        case .verySlow: return "🚫"
        }
    }
}

public enum NetworkTestError: Error, LocalizedError {
    case connectionFailed
    case serverStartFailed
    case dataTransferFailed
    case invalidConfiguration
    
    public var errorDescription: String? {
        switch self {
        case .connectionFailed:
            return "Connection failed"
        case .serverStartFailed:
            return "Failed to start server"
        case .dataTransferFailed:
            return "Data transfer failed"
        case .invalidConfiguration:
            return "Invalid configuration"
        }
    }
}

// MARK: - Network Configuration

public struct NetworkTestConfiguration {
    public let port: UInt16
    public let dataSizeMB: Int
    public let chunkSizeMB: Int
    
    public static let `default` = NetworkTestConfiguration(
        port: 65432,
        dataSizeMB: 100,
        chunkSizeMB: 1
    )
    
    public init(port: UInt16 = 65432, dataSizeMB: Int = 100, chunkSizeMB: Int = 1) {
        self.port = port
        self.dataSizeMB = dataSizeMB
        self.chunkSizeMB = chunkSizeMB
    }
    
    public var totalDataSize: UInt64 {
        UInt64(dataSizeMB * 1_048_576)
    }
    
    public var chunkSize: UInt64 {
        UInt64(chunkSizeMB * 1_048_576)
    }
}

// MARK: - Progress Tracking

public struct TransferProgress {
    public let bytesTransferred: UInt64
    public let totalBytes: UInt64
    public let percentage: Double
    public let currentSpeedMBps: Double
    
    public init(bytesTransferred: UInt64, totalBytes: UInt64, duration: TimeInterval) {
        self.bytesTransferred = bytesTransferred
        self.totalBytes = totalBytes
        self.percentage = totalBytes > 0 ? Double(bytesTransferred) / Double(totalBytes) * 100 : 0
        self.currentSpeedMBps = duration > 0 ? Double(bytesTransferred) / 1_048_576.0 / duration : 0
    }
}