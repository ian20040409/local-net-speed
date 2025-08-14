import SwiftUI
import LocalNetSpeedCore

@main
struct LocalNetSpeedWatchApp: App {
    var body: some Scene {
        WindowGroup {
            watchOSContentView()
        }
        
        #if watchOS
        // Watch Complications (if supported)
        WKNotificationScene(controller: NotificationController.self, category: "speed_test")
        #endif
    }
}

struct watchOSContentView: View {
    @StateObject private var client = NetworkSpeedClient()
    @StateObject private var discovery = NetworkDiscovery()
    @State private var serverIP = ""
    @State private var showingServerInput = false
    @State private var showingResults = false
    
    var body: some View {
        NavigationView {
            TabView {
                // Main Tab - Client Only (watchOS is primarily client-only)
                watchOSMainView(
                    client: client,
                    discovery: discovery,
                    serverIP: $serverIP,
                    showingServerInput: $showingServerInput,
                    showingResults: $showingResults
                )
                .tabItem {
                    Image(systemName: "network")
                    Text("測試")
                }
                
                // Quick Connect Tab
                watchOSQuickConnectView(
                    client: client,
                    serverIP: $serverIP
                )
                .tabItem {
                    Image(systemName: "bolt.fill")
                    Text("快速")
                }
                
                // Results Tab
                if let result = client.lastResult {
                    watchOSResultView(result: result)
                        .tabItem {
                            Image(systemName: "chart.bar.fill")
                            Text("結果")
                        }
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            .navigationTitle("網路測試")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            discovery.startDiscovery()
        }
        .onDisappear {
            client.disconnect()
            discovery.stopDiscovery()
        }
    }
}

struct watchOSMainView: View {
    @ObservedObject var client: NetworkSpeedClient
    @ObservedObject var discovery: NetworkDiscovery
    @Binding var serverIP: String
    @Binding var showingServerInput: Bool
    @Binding var showingResults: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                // Status Indicator
                Circle()
                    .fill(client.isConnected ? Color.green : Color.gray)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                
                Text(client.isConnected ? "已連線" : "未連線")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Server IP Display/Input
                VStack(spacing: 8) {
                    Text("伺服器")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button(serverIP.isEmpty ? "設定 IP" : serverIP) {
                        showingServerInput = true
                    }
                    .font(.system(size: 12, design: .monospaced))
                    .lineLimit(1)
                    .truncationMode(.middle)
                }
                
                // Quick Actions
                if client.isTransferring {
                    VStack(spacing: 10) {
                        if let progress = client.currentProgress {
                            // Simplified progress for watch
                            ProgressView(value: progress.percentage, total: 100)
                                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                .scaleEffect(0.8)
                            
                            Text("\(progress.percentage, specifier: "%.0f")%")
                                .font(.caption)
                                .fontWeight(.bold)
                            
                            Text("\(progress.currentSpeedMBps, specifier: "%.1f") MB/s")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        
                        Button("停止") {
                            client.disconnect()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                } else {
                    Button("開始測試") {
                        guard !serverIP.isEmpty else {
                            showingServerInput = true
                            return
                        }
                        
                        Task {
                            try? await client.connectAndSendData(to: serverIP)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(serverIP.isEmpty)
                }
                
                // Discovered Servers (Compact)
                if !discovery.discoveredServers.isEmpty {
                    VStack(spacing: 5) {
                        Text("發現的伺服器")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        ForEach(discovery.discoveredServers.prefix(2), id: \.self) { server in
                            Button(server) {
                                serverIP = server
                            }
                            .font(.system(size: 10, design: .monospaced))
                            .buttonStyle(.bordered)
                            .controlSize(.mini)
                        }
                        
                        if discovery.discoveredServers.count > 2 {
                            Text("還有 \(discovery.discoveredServers.count - 2) 個...")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                if let error = client.errorMessage {
                    Text("錯誤")
                        .foregroundColor(.red)
                        .font(.caption2)
                }
            }
            .padding(.vertical)
        }
        .sheet(isPresented: $showingServerInput) {
            watchOSServerInputView(serverIP: $serverIP, discovery: discovery)
        }
    }
}

struct watchOSQuickConnectView: View {
    @ObservedObject var client: NetworkSpeedClient
    @Binding var serverIP: String
    
    // Predefined quick connect options for watch
    private let quickServers = [
        "192.168.1.1",
        "192.168.1.100",
        "192.168.0.1",
        "10.0.0.1"
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("快速連線")
                    .font(.headline)
                    .padding(.bottom, 5)
                
                ForEach(quickServers, id: \.self) { server in
                    Button(server) {
                        serverIP = server
                        Task {
                            try? await client.connectAndSendData(to: server)
                        }
                    }
                    .font(.system(size: 11, design: .monospaced))
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .frame(maxWidth: .infinity)
                }
                
                if client.isTransferring {
                    VStack(spacing: 8) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            .scaleEffect(0.7)
                        
                        Text("測試中...")
                            .font(.caption2)
                        
                        Button("停止") {
                            client.disconnect()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.mini)
                    }
                    .padding(.top)
                }
            }
            .padding(.vertical)
        }
    }
}

struct watchOSServerInputView: View {
    @Binding var serverIP: String
    @ObservedObject var discovery: NetworkDiscovery
    @Environment(\.dismiss) private var dismiss
    
    @State private var inputText = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 15) {
                    Text("設定伺服器")
                        .font(.headline)
                    
                    // Simplified text input for watch
                    TextField("IP 位址", text: $inputText)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numbersAndPunctuation)
                        .autocapitalization(.none)
                        .font(.system(size: 12, design: .monospaced))
                    
                    Button("確定") {
                        serverIP = inputText
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(inputText.isEmpty)
                    
                    // Discovered servers
                    if !discovery.discoveredServers.isEmpty {
                        VStack(spacing: 8) {
                            Text("發現的伺服器")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            ForEach(discovery.discoveredServers, id: \.self) { server in
                                Button(server) {
                                    serverIP = server
                                    dismiss()
                                }
                                .font(.system(size: 10, design: .monospaced))
                                .buttonStyle(.bordered)
                                .controlSize(.mini)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("伺服器設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            inputText = serverIP
        }
    }
}

struct watchOSResultView: View {
    let result: SpeedTestResult
    
    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                Text("測試結果")
                    .font(.headline)
                
                // Performance indicator with large emoji
                VStack(spacing: 8) {
                    Text(result.performanceRating.emoji)
                        .font(.system(size: 40))
                    
                    Text(PerformanceDisplayHelper.title(for: result.performanceRating))
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                // Key metrics
                VStack(spacing: 10) {
                    HStack {
                        Text("速度:")
                        Spacer()
                        Text("\(result.speedMBps, specifier: "%.1f") MB/s")
                            .fontWeight(.bold)
                    }
                    .font(.caption)
                    
                    HStack {
                        Text("資料:")
                        Spacer()
                        Text("\(Double(result.totalDataSize) / 1_048_576.0, specifier: "%.0f") MB")
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    
                    HStack {
                        Text("耗時:")
                        Spacer()
                        Text("\(result.duration, specifier: "%.1f") 秒")
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
                
                // Performance percentage
                let percentage = (result.speedMBps / 125.0) * 100
                VStack(spacing: 5) {
                    Text("Gigabit 效能")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    ProgressView(value: min(percentage, 100), total: 100)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    
                    Text("\(percentage, specifier: "%.0f")%")
                        .font(.caption2)
                        .fontWeight(.bold)
                }
            }
            .padding(.vertical)
        }
    }
}

// MARK: - Watch Complications Support

#if watchOS
import ClockKit

class ComplicationController: NSObject, CLKComplicationDataSource {
    func getSupportedTimeTravelDirections(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimeTravelDirections) -> Void) {
        handler([])
    }
    
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        let template = CLKComplicationTemplateGraphicCircularOpenGaugeSimpleText()
        template.centerTextProvider = CLKSimpleTextProvider(text: "網路")
        template.bottomTextProvider = CLKSimpleTextProvider(text: "測試")
        
        let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
        handler(entry)
    }
    
    func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
        let descriptor = CLKComplicationDescriptor(
            identifier: "NetworkSpeedTest",
            displayName: "網路速度測試",
            supportedFamilies: [.graphicCircular, .graphicCorner]
        )
        handler([descriptor])
    }
}

// Notification Controller for watch notifications
class NotificationController: WKUserNotificationInterfaceController {
    override init() {
        super.init()
    }
    
    override func willActivate() {
        super.willActivate()
    }
    
    override func didDeactivate() {
        super.didDeactivate()
    }
    
    override func didReceive(_ notification: UNNotification) {
        // Handle network speed test notifications
    }
}
#endif