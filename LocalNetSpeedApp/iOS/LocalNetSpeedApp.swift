import SwiftUI
import LocalNetSpeedCore

@main
struct LocalNetSpeedApp: App {
    var body: some Scene {
        WindowGroup {
            iOSContentView()
        }
    }
}

struct iOSContentView: View {
    @StateObject private var viewModel = AppViewModel()
    @State private var showingActivityView = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Mode Selection with iOS styling
                ModeSelectionView(selectedMode: $viewModel.selectedMode) { mode in
                    viewModel.switchToMode(mode)
                    
                    // Haptic feedback for iOS
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                }
                
                Divider()
                
                // Content based on selected mode
                Group {
                    if viewModel.selectedMode == .server {
                        iOSServerView(server: viewModel.server)
                    } else {
                        iOSClientView(
                            client: viewModel.client,
                            discovery: viewModel.discovery,
                            serverIP: $viewModel.serverIP,
                            showingActivityView: $showingActivityView
                        )
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("網路速度測試")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("設定") {
                        viewModel.showingSettings = true
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingSettings) {
                SettingsView(configuration: $viewModel.configuration)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onDisappear {
            viewModel.stopAll()
        }
    }
}

struct iOSServerView: View {
    @ObservedObject var server: NetworkSpeedServer
    @State private var showingShareSheet = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("伺服器模式")
                .font(.title2)
                .fontWeight(.semibold)
            
            if server.isRunning {
                VStack(spacing: 15) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("伺服器正在運行")
                    }
                    
                    if let address = server.connectionAddress {
                        VStack(spacing: 10) {
                            Text("伺服器地址:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Text(address)
                                    .font(.system(.title3, design: .monospaced))
                                    .textSelection(.enabled)
                                
                                Button(action: {
                                    showingShareSheet = true
                                }) {
                                    Image(systemName: "square.and.arrow.up")
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                    }
                    
                    if let progress = server.currentProgress {
                        VStack(spacing: 10) {
                            ProgressView(value: progress.percentage, total: 100) {
                                Text("正在接收資料...")
                            } currentValueLabel: {
                                Text("\(progress.percentage, specifier: "%.1f")%")
                            }
                            
                            Text("目前速度: \(progress.currentSpeedMBps, specifier: "%.2f") MB/s")
                                .font(.caption)
                        }
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(10)
                    }
                    
                    Button("停止伺服器") {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        server.stopServer()
                    }
                    .buttonStyle(.bordered)
                }
            } else {
                VStack(spacing: 15) {
                    Text("啟動伺服器等待客戶端連線，並測量接收速度")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding()
                    
                    Button("啟動伺服器") {
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                        
                        Task {
                            try? await server.startServer()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
            
            if let result = server.lastResult {
                iOSResultView(result: result)
            }
            
            if let error = server.errorMessage {
                Text("錯誤: \(error)")
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let address = server.connectionAddress {
                ActivityView(activityItems: [address])
            }
        }
    }
}

struct iOSClientView: View {
    @ObservedObject var client: NetworkSpeedClient
    @ObservedObject var discovery: NetworkDiscovery
    @Binding var serverIP: String
    @Binding var showingActivityView: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Text("客戶端模式")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(spacing: 15) {
                // Server IP Input with iOS styling
                VStack(alignment: .leading, spacing: 5) {
                    Text("伺服器 IP 位址")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("輸入伺服器 IP", text: $serverIP)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numbersAndPunctuation)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                
                // Discovered Servers with iOS styling
                if !discovery.discoveredServers.isEmpty {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("發現的伺服器")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(discovery.discoveredServers, id: \.self) { server in
                                    Button(server) {
                                        let impact = UIImpactFeedbackGenerator(style: .light)
                                        impact.impactOccurred()
                                        serverIP = server
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                // Connection Status and Controls
                if client.isConnected || client.isTransferring {
                    VStack(spacing: 10) {
                        if client.isConnected {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("已連線")
                            }
                        }
                        
                        if let progress = client.currentProgress {
                            VStack(spacing: 10) {
                                ProgressView(value: progress.percentage, total: 100) {
                                    Text("正在發送資料...")
                                } currentValueLabel: {
                                    Text("\(progress.percentage, specifier: "%.1f")%")
                                }
                                
                                Text("目前速度: \(progress.currentSpeedMBps, specifier: "%.2f") MB/s")
                                    .font(.caption)
                            }
                            .padding()
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(10)
                        }
                        
                        Button("中斷連線") {
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred()
                            client.disconnect()
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    Button("連線並測試") {
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                        
                        Task {
                            try? await client.connectAndSendData(to: serverIP)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(serverIP.isEmpty)
                }
            }
            
            if let result = client.lastResult {
                iOSResultView(result: result, showingActivityView: $showingActivityView)
            }
            
            if let error = client.errorMessage {
                Text("錯誤: \(error)")
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            }
        }
    }
}

struct iOSResultView: View {
    let result: SpeedTestResult
    @Binding var showingActivityView: Bool
    
    init(result: SpeedTestResult, showingActivityView: Binding<Bool> = .constant(false)) {
        self.result = result
        self._showingActivityView = showingActivityView
    }
    
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Text("測試結果")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    showingActivityView = true
                }) {
                    Image(systemName: "square.and.arrow.up")
                }
                .buttonStyle(.bordered)
            }
            
            VStack(spacing: 10) {
                HStack {
                    Text("資料傳輸量:")
                    Spacer()
                    Text("\(Double(result.totalDataSize) / 1_048_576.0, specifier: "%.2f") MB")
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("耗時:")
                    Spacer()
                    Text("\(result.duration, specifier: "%.2f") 秒")
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("平均速度:")
                    Spacer()
                    Text("\(result.speedMBps, specifier: "%.2f") MB/s")
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(10)
            
            // Performance Rating with iOS styling
            iOSPerformanceRatingView(rating: result.performanceRating, speed: result.speedMBps)
        }
        .sheet(isPresented: $showingActivityView) {
            ActivityView(activityItems: [formatResultForSharing(result)])
        }
    }
    
    private func formatResultForSharing(_ result: SpeedTestResult) -> String {
        let rating = PerformanceDisplayHelper.title(for: result.performanceRating)
        return """
        網路速度測試結果
        
        資料傳輸量: \(Double(result.totalDataSize) / 1_048_576.0, specifier: "%.2f") MB
        耗時: \(result.duration, specifier: "%.2f") 秒
        平均速度: \(result.speedMBps, specifier: "%.2f") MB/s
        效能評級: \(result.performanceRating.emoji) \(rating)
        
        理論速度達成率: \((result.speedMBps / 125.0) * 100, specifier: "%.1f")%
        """
    }
}

struct iOSPerformanceRatingView: View {
    let rating: PerformanceRating
    let speed: Double
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Gigabit 乙太網路效能評估")
                .font(.headline)
            
            HStack {
                Text("\(rating.emoji) \(PerformanceDisplayHelper.title(for: rating))")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            
            Text(PerformanceDisplayHelper.message(for: rating))
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            let percentage = (speed / 125.0) * 100
            Text("達到理論速度的: \(percentage, specifier: "%.1f")%")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Suggestions for improvement
            let suggestions = PerformanceDisplayHelper.suggestions(for: rating)
            if !suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    Text("效能改善建議")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ForEach(suggestions, id: \.self) { suggestion in
                        Text("• \(suggestion)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Activity View (Share Sheet)

struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}