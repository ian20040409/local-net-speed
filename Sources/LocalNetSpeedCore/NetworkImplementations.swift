import Foundation

#if canImport(Combine)
import Combine
#endif

#if canImport(Network)
import Network
#endif

// MARK: - Mock Implementations for Non-Apple Platforms

#if !canImport(Network)
// Mock implementations for testing on non-Apple platforms
public struct MockNWListener {
    public init() {}
    public func start() {}
    public func cancel() {}
}

public struct MockNWConnection {
    public init() {}
    public func start() {}
    public func cancel() {}
    public func send(content: Data, completion: @escaping (Error?) -> Void) {
        completion(nil)
    }
}

public struct MockNWBrowser {
    public init() {}
    public func start() {}
    public func cancel() {}
}
#endif

// MARK: - Server Implementation

public class NetworkSpeedServer {
    #if canImport(Combine)
    @Published public var isRunning = false
    @Published public var currentProgress: TransferProgress?
    @Published public var lastResult: SpeedTestResult?
    @Published public var connectionAddress: String?
    @Published public var errorMessage: String?
    #else
    public var isRunning = false
    public var currentProgress: TransferProgress?
    public var lastResult: SpeedTestResult?
    public var connectionAddress: String?
    public var errorMessage: String?
    #endif
    
    #if canImport(Network)
    private var listener: NWListener?
    private var connection: NWConnection?
    #else
    private var listener: MockNWListener?
    private var connection: MockNWConnection?
    #endif
    
    private let configuration: NetworkTestConfiguration
    private var startTime: Date?
    private var receivedBytes: UInt64 = 0
    
    public init(configuration: NetworkTestConfiguration = .default) {
        self.configuration = configuration
    }
    
    public func startServer() async throws {
        #if canImport(Network)
        // Real implementation for Apple platforms
        guard !isRunning else { return }
        
        let parameters = NWParameters.tcp
        parameters.allowLocalEndpointReuse = true
        
        listener = try NWListener(using: parameters, on: NWEndpoint.Port(integerLiteral: configuration.port))
        
        listener?.newConnectionHandler = { [weak self] connection in
            Task { @MainActor in
                await self?.handleNewConnection(connection)
            }
        }
        
        listener?.stateUpdateHandler = { [weak self] state in
            Task { @MainActor in
                switch state {
                case .ready:
                    self?.isRunning = true
                    self?.errorMessage = nil
                    self?.connectionAddress = self?.getLocalIPAddress()
                case .failed(let error):
                    self?.isRunning = false
                    self?.errorMessage = error.localizedDescription
                case .cancelled:
                    self?.isRunning = false
                default:
                    break
                }
            }
        }
        
        listener?.start(queue: .global(qos: .userInitiated))
        #else
        // Mock implementation for testing
        isRunning = true
        connectionAddress = "127.0.0.1"
        #endif
    }
    
    public func stopServer() {
        #if canImport(Network)
        listener?.cancel()
        connection?.cancel()
        listener = nil
        connection = nil
        #else
        listener?.cancel()
        connection?.cancel()
        listener = nil
        connection = nil
        #endif
        isRunning = false
        currentProgress = nil
        connectionAddress = nil
    }
    
    #if canImport(Network)
    @MainActor
    private func handleNewConnection(_ connection: NWConnection) async {
        self.connection = connection
        self.receivedBytes = 0
        self.startTime = Date()
        
        connection.stateUpdateHandler = { [weak self] state in
            Task { @MainActor in
                switch state {
                case .ready:
                    await self?.startReceivingData()
                case .failed(let error):
                    self?.errorMessage = error.localizedDescription
                case .cancelled:
                    await self?.finishReceiving()
                default:
                    break
                }
            }
        }
        
        connection.start(queue: .global(qos: .userInitiated))
    }
    
    @MainActor
    private func startReceivingData() async {
        guard let connection = connection else { return }
        
        let receiveCompletion: (Data?, NWConnection.ContentContext?, Bool, NWError?) -> Void = { [weak self] data, _, isComplete, error in
            Task { @MainActor in
                if let data = data {
                    self?.receivedBytes += UInt64(data.count)
                    
                    if let startTime = self?.startTime {
                        let duration = Date().timeIntervalSince(startTime)
                        self?.currentProgress = TransferProgress(
                            bytesTransferred: self?.receivedBytes ?? 0,
                            totalBytes: self?.configuration.totalDataSize ?? 0,
                            duration: duration
                        )
                    }
                }
                
                if isComplete {
                    await self?.finishReceiving()
                } else if error == nil {
                    connection.receive(minimumIncompleteLength: 1, maximumLength: Int(self?.configuration.chunkSize ?? 1_048_576), completion: receiveCompletion)
                } else {
                    self?.errorMessage = error?.localizedDescription
                }
            }
        }
        
        connection.receive(minimumIncompleteLength: 1, maximumLength: Int(configuration.chunkSize), completion: receiveCompletion)
    }
    
    @MainActor
    private func finishReceiving() async {
        guard let startTime = startTime else { return }
        
        let duration = Date().timeIntervalSince(startTime)
        lastResult = SpeedTestResult(totalDataSize: receivedBytes, duration: duration)
        currentProgress = nil
        
        connection?.cancel()
        connection = nil
    }
    
    private func getLocalIPAddress() -> String? {
        // Simplified implementation - can be expanded for real network detection
        return "127.0.0.1"
    }
    #endif
}

// MARK: - Client Implementation

public class NetworkSpeedClient {
    #if canImport(Combine)
    @Published public var isConnected = false
    @Published public var isTransferring = false
    @Published public var currentProgress: TransferProgress?
    @Published public var lastResult: SpeedTestResult?
    @Published public var errorMessage: String?
    #else
    public var isConnected = false
    public var isTransferring = false
    public var currentProgress: TransferProgress?
    public var lastResult: SpeedTestResult?
    public var errorMessage: String?
    #endif
    
    #if canImport(Network)
    private var connection: NWConnection?
    #else
    private var connection: MockNWConnection?
    #endif
    
    private let configuration: NetworkTestConfiguration
    private var startTime: Date?
    private var sentBytes: UInt64 = 0
    
    public init(configuration: NetworkTestConfiguration = .default) {
        self.configuration = configuration
    }
    
    public func connectAndSendData(to serverIP: String) async throws {
        #if canImport(Network)
        guard !isConnected && !isTransferring else { return }
        
        let endpoint = NWEndpoint.hostPort(
            host: NWEndpoint.Host(serverIP),
            port: NWEndpoint.Port(integerLiteral: configuration.port)
        )
        
        connection = NWConnection(to: endpoint, using: .tcp)
        
        return try await withCheckedThrowingContinuation { continuation in
            var hasResumed = false
            
            connection?.stateUpdateHandler = { [weak self] state in
                Task { @MainActor in
                    switch state {
                    case .ready:
                        self?.isConnected = true
                        self?.errorMessage = nil
                        if !hasResumed {
                            hasResumed = true
                            continuation.resume()
                        }
                        await self?.startSendingData()
                    case .failed(let error):
                        self?.isConnected = false
                        self?.errorMessage = error.localizedDescription
                        if !hasResumed {
                            hasResumed = true
                            continuation.resume(throwing: NetworkTestError.connectionFailed)
                        }
                    case .cancelled:
                        self?.isConnected = false
                        self?.isTransferring = false
                    default:
                        break
                    }
                }
            }
            
            connection?.start(queue: .global(qos: .userInitiated))
        }
        #else
        // Mock implementation for testing
        isConnected = true
        await mockSendData()
        #endif
    }
    
    public func disconnect() {
        #if canImport(Network)
        connection?.cancel()
        connection = nil
        #else
        connection?.cancel()
        connection = nil
        #endif
        isConnected = false
        isTransferring = false
        currentProgress = nil
    }
    
    #if !canImport(Network)
    private func mockSendData() async {
        isTransferring = true
        sentBytes = 0
        startTime = Date()
        
        let totalSize = configuration.totalDataSize
        let duration = 2.0 // Mock 2 second transfer
        
        lastResult = SpeedTestResult(totalDataSize: totalSize, duration: duration)
        isTransferring = false
        isConnected = false
    }
    #endif
    
    #if canImport(Network)
    @MainActor
    private func startSendingData() async {
        guard let connection = connection, isConnected else { return }
        
        isTransferring = true
        sentBytes = 0
        startTime = Date()
        
        let totalSize = configuration.totalDataSize
        let chunkSize = configuration.chunkSize
        
        while sentBytes < totalSize && isTransferring {
            let remainingBytes = totalSize - sentBytes
            let currentChunkSize = min(chunkSize, remainingBytes)
            let data = Data(repeating: 0x58, count: Int(currentChunkSize))
            
            do {
                try await sendChunk(connection: connection, data: data)
                sentBytes += currentChunkSize
                
                if let startTime = startTime {
                    let duration = Date().timeIntervalSince(startTime)
                    currentProgress = TransferProgress(
                        bytesTransferred: sentBytes,
                        totalBytes: totalSize,
                        duration: duration
                    )
                }
            } catch {
                errorMessage = error.localizedDescription
                isTransferring = false
                return
            }
        }
        
        await finishSending()
    }
    
    private func sendChunk(connection: NWConnection, data: Data) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            connection.send(content: data, completion: .contentProcessed { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            })
        }
    }
    
    @MainActor
    private func finishSending() async {
        guard let startTime = startTime else { return }
        
        let duration = Date().timeIntervalSince(startTime)
        lastResult = SpeedTestResult(totalDataSize: sentBytes, duration: duration)
        
        isTransferring = false
        currentProgress = nil
        
        connection?.cancel()
        connection = nil
        isConnected = false
    }
    #endif
}

// MARK: - Network Discovery

public class NetworkDiscovery {
    #if canImport(Combine)
    @Published public var discoveredServers: [String] = []
    #else
    public var discoveredServers: [String] = []
    #endif
    
    #if canImport(Network)
    private var browser: NWBrowser?
    #else
    private var browser: MockNWBrowser?
    #endif
    
    public init() {}
    
    public func startDiscovery() {
        #if canImport(Network)
        let parameters = NWParameters()
        parameters.includePeerToPeer = true
        
        browser = NWBrowser(for: .bonjour(type: "_localnetspeed._tcp", domain: nil), using: parameters)
        
        browser?.browseResultsChangedHandler = { [weak self] results, changes in
            Task { @MainActor in
                self?.discoveredServers = results.compactMap { result in
                    if case .hostPort(let host, _) = result.endpoint {
                        return "\(host)"
                    }
                    return nil
                }
            }
        }
        
        browser?.start(queue: .global(qos: .utility))
        #else
        // Mock some discovered servers for testing
        discoveredServers = ["192.168.1.1", "192.168.1.100"]
        #endif
    }
    
    public func stopDiscovery() {
        #if canImport(Network)
        browser?.cancel()
        browser = nil
        #else
        browser?.cancel()
        browser = nil
        #endif
        discoveredServers.removeAll()
    }
    
    deinit {
        stopDiscovery()
    }
}

#if canImport(Combine)
extension NetworkSpeedServer: ObservableObject {}
extension NetworkSpeedClient: ObservableObject {}
extension NetworkDiscovery: ObservableObject {}
#endif