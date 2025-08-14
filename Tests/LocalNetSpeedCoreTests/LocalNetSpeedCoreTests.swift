import XCTest
@testable import LocalNetSpeedCore

final class LocalNetSpeedCoreTests: XCTestCase {
    
    func testNetworkTestConfiguration() {
        let config = NetworkTestConfiguration.default
        XCTAssertEqual(config.port, 65432)
        XCTAssertEqual(config.dataSizeMB, 100)
        XCTAssertEqual(config.chunkSizeMB, 1)
        XCTAssertEqual(config.totalDataSize, 104_857_600) // 100 MB
        XCTAssertEqual(config.chunkSize, 1_048_576) // 1 MB
    }
    
    func testCustomConfiguration() {
        let config = NetworkTestConfiguration(port: 8080, dataSizeMB: 50, chunkSizeMB: 2)
        XCTAssertEqual(config.port, 8080)
        XCTAssertEqual(config.dataSizeMB, 50)
        XCTAssertEqual(config.chunkSizeMB, 2)
        XCTAssertEqual(config.totalDataSize, 52_428_800) // 50 MB
        XCTAssertEqual(config.chunkSize, 2_097_152) // 2 MB
    }
    
    func testSpeedTestResult() {
        let result = SpeedTestResult(totalDataSize: 104_857_600, duration: 10.0)
        XCTAssertEqual(result.speedMBps, 10.0, accuracy: 0.1)
        XCTAssertEqual(result.performanceRating, .slow)
    }
    
    func testPerformanceRating() {
        XCTAssertEqual(PerformanceRating.evaluate(speedMBps: 150), .excellent)
        XCTAssertEqual(PerformanceRating.evaluate(speedMBps: 90), .good)
        XCTAssertEqual(PerformanceRating.evaluate(speedMBps: 60), .average)
        XCTAssertEqual(PerformanceRating.evaluate(speedMBps: 20), .slow)
        XCTAssertEqual(PerformanceRating.evaluate(speedMBps: 5), .verySlow)
    }
    
    func testTransferProgress() {
        let progress = TransferProgress(bytesTransferred: 50_000_000, totalBytes: 100_000_000, duration: 5.0)
        XCTAssertEqual(progress.percentage, 50.0, accuracy: 0.1)
        XCTAssertEqual(progress.currentSpeedMBps, 9.5, accuracy: 0.1)
    }
    
    func testNetworkSpeedServerInitialization() {
        let server = NetworkSpeedServer()
        XCTAssertFalse(server.isRunning)
        XCTAssertNil(server.currentProgress)
        XCTAssertNil(server.lastResult)
        XCTAssertNil(server.connectionAddress)
        XCTAssertNil(server.errorMessage)
    }
    
    func testNetworkSpeedClientInitialization() {
        let client = NetworkSpeedClient()
        XCTAssertFalse(client.isConnected)
        XCTAssertFalse(client.isTransferring)
        XCTAssertNil(client.currentProgress)
        XCTAssertNil(client.lastResult)
        XCTAssertNil(client.errorMessage)
    }
    
    func testNetworkDiscoveryInitialization() {
        let discovery = NetworkDiscovery()
        XCTAssertTrue(discovery.discoveredServers.isEmpty)
    }
}