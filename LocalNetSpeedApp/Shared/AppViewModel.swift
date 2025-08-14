import SwiftUI
import LocalNetSpeedCore

// MARK: - Main App View Model

@MainActor
public class AppViewModel: ObservableObject {
    @Published var selectedMode: AppMode = .client
    @Published var serverIP: String = ""
    @Published var showingSettings = false
    @Published var configuration = NetworkTestConfiguration.default
    
    let server = NetworkSpeedServer()
    let client = NetworkSpeedClient()
    let discovery = NetworkDiscovery()
    
    public init() {}
    
    func switchToMode(_ mode: AppMode) {
        selectedMode = mode
        
        // Clean up previous mode
        server.stopServer()
        client.disconnect()
        
        if mode == .client {
            discovery.startDiscovery()
        } else {
            discovery.stopDiscovery()
        }
    }
    
    func startServer() async {
        do {
            try await server.startServer()
        } catch {
            // Handle error in UI
        }
    }
    
    func connectAndTest() async {
        guard !serverIP.isEmpty else { return }
        
        do {
            try await client.connectAndSendData(to: serverIP)
        } catch {
            // Handle error in UI
        }
    }
    
    func stopAll() {
        server.stopServer()
        client.disconnect()
        discovery.stopDiscovery()
    }
}

// MARK: - App Mode

public enum AppMode: String, CaseIterable {
    case server = "server"
    case client = "client"
    
    var localizedTitle: String {
        switch self {
        case .server:
            return NSLocalizedString("app.mode.server", value: "伺服器端", comment: "Server mode")
        case .client:
            return NSLocalizedString("app.mode.client", value: "客戶端", comment: "Client mode")
        }
    }
    
    var icon: String {
        switch self {
        case .server:
            return "server.rack"
        case .client:
            return "network"
        }
    }
}

// MARK: - Performance Display Helper

public struct PerformanceDisplayHelper {
    public static func title(for rating: PerformanceRating) -> String {
        switch rating {
        case .excellent:
            return NSLocalizedString("performance.excellent", value: "優秀", comment: "Excellent performance")
        case .good:
            return NSLocalizedString("performance.good", value: "良好", comment: "Good performance")
        case .average:
            return NSLocalizedString("performance.average", value: "一般", comment: "Average performance")
        case .slow:
            return NSLocalizedString("performance.slow", value: "偏慢", comment: "Slow performance")
        case .verySlow:
            return NSLocalizedString("performance.very_slow", value: "很慢", comment: "Very slow performance")
        }
    }
    
    public static func message(for rating: PerformanceRating) -> String {
        switch rating {
        case .excellent:
            return NSLocalizedString("performance.excellent.message", value: "恭喜！您的網路已達到 Gigabit 等級效能", comment: "Excellent performance message")
        case .good:
            return NSLocalizedString("performance.good.message", value: "接近 Gigabit 效能，但仍有提升空間", comment: "Good performance message")
        case .average:
            return NSLocalizedString("performance.average.message", value: "網路速度一般，建議檢查網路設備或連線品質", comment: "Average performance message")
        case .slow:
            return NSLocalizedString("performance.slow.message", value: "網路速度偏慢，可能未使用 Gigabit 設備", comment: "Slow performance message")
        case .verySlow:
            return NSLocalizedString("performance.very_slow.message", value: "網路速度很慢，建議檢查網路連線問題", comment: "Very slow performance message")
        }
    }
    
    public static func suggestions(for rating: PerformanceRating) -> [String] {
        guard rating != .excellent else { return [] }
        
        return [
            NSLocalizedString("suggestion.cable", value: "確認使用 Cat5e 或更高等級的網路線", comment: "Cable suggestion"),
            NSLocalizedString("suggestion.switch", value: "檢查網路交換器是否支援 Gigabit", comment: "Switch suggestion"),
            NSLocalizedString("suggestion.nic", value: "確認網路卡設定為 1000 Mbps 全雙工", comment: "NIC suggestion"),
            NSLocalizedString("suggestion.programs", value: "關閉不必要的網路程式和服務", comment: "Programs suggestion"),
            NSLocalizedString("suggestion.interference", value: "檢查是否有網路瓶頸或干擾", comment: "Interference suggestion")
        ]
    }
}