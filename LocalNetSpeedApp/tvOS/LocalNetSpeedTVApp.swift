import SwiftUI
import LocalNetSpeedCore

@main
struct LocalNetSpeedTVApp: App {
    var body: some Scene {
        WindowGroup {
            tvOSContentView()
        }
    }
}

struct tvOSContentView: View {
    @StateObject private var viewModel = AppViewModel()
    @FocusState private var focusedField: FocusableField?
    
    enum FocusableField {
        case serverMode
        case clientMode
        case serverIP
        case connectButton
        case serverPreset(String)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                // Title with large text for TV
                Text("網路速度測試")
                    .font(.system(size: 60, weight: .bold))
                    .foregroundColor(.primary)
                
                // Mode Selection - Optimized for TV Remote
                VStack(spacing: 30) {
                    Text("選擇模式")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 60) {
                        ForEach(AppMode.allCases, id: \.self) { mode in
                            Button(action: {
                                viewModel.switchToMode(mode)
                            }) {
                                VStack(spacing: 20) {
                                    Image(systemName: mode.icon)
                                        .font(.system(size: 80))
                                    
                                    Text(mode.localizedTitle)
                                        .font(.system(size: 32, weight: .medium))
                                }
                                .frame(width: 300, height: 250)
                                .background(viewModel.selectedMode == mode ? Color.accentColor : Color.secondary.opacity(0.2))
                                .foregroundColor(viewModel.selectedMode == mode ? .white : .primary)
                                .cornerRadius(20)
                            }
                            .buttonStyle(TVButtonStyle())
                            .focused($focusedField, equals: mode == .server ? .serverMode : .clientMode)
                        }
                    }
                }
                
                Divider()
                    .padding(.horizontal, 100)
                
                // Content based on selected mode
                Group {
                    if viewModel.selectedMode == .server {
                        tvOSServerView(server: viewModel.server)
                    } else {
                        tvOSClientView(
                            client: viewModel.client,
                            discovery: viewModel.discovery,
                            serverIP: $viewModel.serverIP,
                            focusedField: $focusedField
                        )
                    }
                }
                
                Spacer()
            }
            .padding(60)
            .background(Color.black)
        }
        .onAppear {
            focusedField = .serverMode
        }
        .onDisappear {
            viewModel.stopAll()
        }
    }
}

struct tvOSServerView: View {
    @ObservedObject var server: NetworkSpeedServer
    
    var body: some View {
        VStack(spacing: 40) {
            if server.isRunning {
                VStack(spacing: 30) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 50))
                        Text("伺服器正在運行")
                            .font(.system(size: 40, weight: .medium))
                    }
                    
                    if let address = server.connectionAddress {
                        VStack(spacing: 20) {
                            Text("伺服器地址")
                                .font(.system(size: 28))
                                .foregroundColor(.secondary)
                            
                            Text(address)
                                .font(.system(size: 48, weight: .bold, design: .monospaced))
                                .foregroundColor(.blue)
                                .padding(30)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(15)
                        }
                    }
                    
                    if let progress = server.currentProgress {
                        VStack(spacing: 20) {
                            Text("正在接收資料...")
                                .font(.system(size: 32))
                            
                            ProgressView(value: progress.percentage, total: 100)
                                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                                .frame(height: 20)
                                .scaleEffect(1.5)
                            
                            Text("\(progress.percentage, specifier: "%.1f")%")
                                .font(.system(size: 36, weight: .bold))
                            
                            Text("目前速度: \(progress.currentSpeedMBps, specifier: "%.2f") MB/s")
                                .font(.system(size: 28))
                                .foregroundColor(.secondary)
                        }
                        .padding(40)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(20)
                    }
                    
                    Button("停止伺服器") {
                        server.stopServer()
                    }
                    .buttonStyle(TVProminentButtonStyle())
                    .font(.system(size: 28, weight: .medium))
                }
            } else {
                VStack(spacing: 40) {
                    Text("啟動伺服器等待客戶端連線")
                        .font(.system(size: 36))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 100)
                    
                    Button("啟動伺服器") {
                        Task {
                            try? await server.startServer()
                        }
                    }
                    .buttonStyle(TVProminentButtonStyle())
                    .font(.system(size: 32, weight: .medium))
                }
            }
            
            if let result = server.lastResult {
                tvOSResultView(result: result)
            }
            
            if let error = server.errorMessage {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 50))
                    
                    Text("錯誤: \(error)")
                        .foregroundColor(.red)
                        .font(.system(size: 28))
                        .multilineTextAlignment(.center)
                }
                .padding(40)
                .background(Color.red.opacity(0.1))
                .cornerRadius(20)
            }
        }
    }
}

struct tvOSClientView: View {
    @ObservedObject var client: NetworkSpeedClient
    @ObservedObject var discovery: NetworkDiscovery
    @Binding var serverIP: String
    @FocusState.Binding var focusedField: tvOSContentView.FocusableField?
    
    // Predefined server IPs for easy selection on TV
    private let presetServers = [
        "192.168.1.1",
        "192.168.1.100",
        "192.168.1.101",
        "192.168.1.102",
        "192.168.0.1",
        "192.168.0.100",
        "10.0.0.1",
        "10.0.0.100"
    ]
    
    var body: some View {
        VStack(spacing: 40) {
            if client.isConnected || client.isTransferring {
                VStack(spacing: 30) {
                    if client.isConnected {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 50))
                            Text("已連線")
                                .font(.system(size: 40, weight: .medium))
                        }
                    }
                    
                    if let progress = client.currentProgress {
                        VStack(spacing: 20) {
                            Text("正在發送資料...")
                                .font(.system(size: 32))
                            
                            ProgressView(value: progress.percentage, total: 100)
                                .progressViewStyle(LinearProgressViewStyle(tint: .green))
                                .frame(height: 20)
                                .scaleEffect(1.5)
                            
                            Text("\(progress.percentage, specifier: "%.1f")%")
                                .font(.system(size: 36, weight: .bold))
                            
                            Text("目前速度: \(progress.currentSpeedMBps, specifier: "%.2f") MB/s")
                                .font(.system(size: 28))
                                .foregroundColor(.secondary)
                        }
                        .padding(40)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(20)
                    }
                    
                    Button("中斷連線") {
                        client.disconnect()
                    }
                    .buttonStyle(TVButtonStyle())
                    .font(.system(size: 28, weight: .medium))
                }
            } else {
                VStack(spacing: 40) {
                    // Server IP Selection - Optimized for TV Remote
                    VStack(spacing: 30) {
                        Text("選擇伺服器 IP")
                            .font(.system(size: 36, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        // Current IP Display
                        if !serverIP.isEmpty {
                            VStack(spacing: 15) {
                                Text("選定的伺服器:")
                                    .font(.system(size: 24))
                                    .foregroundColor(.secondary)
                                
                                Text(serverIP)
                                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                                    .foregroundColor(.blue)
                                    .padding(20)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(10)
                            }
                        }
                        
                        // Preset Servers Grid
                        Text("預設伺服器:")
                            .font(.system(size: 28))
                            .foregroundColor(.secondary)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 20) {
                            ForEach(presetServers, id: \.self) { preset in
                                Button(preset) {
                                    serverIP = preset
                                }
                                .font(.system(size: 24, weight: .medium, design: .monospaced))
                                .frame(width: 200, height: 80)
                                .background(serverIP == preset ? Color.accentColor : Color.secondary.opacity(0.2))
                                .foregroundColor(serverIP == preset ? .white : .primary)
                                .cornerRadius(10)
                                .buttonStyle(TVButtonStyle())
                                .focused($focusedField, equals: .serverPreset(preset))
                            }
                        }
                        
                        // Discovered Servers
                        if !discovery.discoveredServers.isEmpty {
                            VStack(spacing: 20) {
                                Text("發現的伺服器:")
                                    .font(.system(size: 28))
                                    .foregroundColor(.secondary)
                                
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 20) {
                                    ForEach(discovery.discoveredServers, id: \.self) { server in
                                        Button(server) {
                                            serverIP = server
                                        }
                                        .font(.system(size: 24, weight: .medium, design: .monospaced))
                                        .frame(width: 250, height: 80)
                                        .background(Color.green.opacity(0.2))
                                        .foregroundColor(.primary)
                                        .cornerRadius(10)
                                        .buttonStyle(TVButtonStyle())
                                    }
                                }
                            }
                        }
                    }
                    
                    // Connect Button
                    Button("連線並測試") {
                        Task {
                            try? await client.connectAndSendData(to: serverIP)
                        }
                    }
                    .buttonStyle(TVProminentButtonStyle())
                    .font(.system(size: 32, weight: .medium))
                    .disabled(serverIP.isEmpty)
                    .focused($focusedField, equals: .connectButton)
                }
            }
            
            if let result = client.lastResult {
                tvOSResultView(result: result)
            }
            
            if let error = client.errorMessage {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 50))
                    
                    Text("錯誤: \(error)")
                        .foregroundColor(.red)
                        .font(.system(size: 28))
                        .multilineTextAlignment(.center)
                }
                .padding(40)
                .background(Color.red.opacity(0.1))
                .cornerRadius(20)
            }
        }
    }
}

struct tvOSResultView: View {
    let result: SpeedTestResult
    
    var body: some View {
        VStack(spacing: 30) {
            Text("測試結果")
                .font(.system(size: 44, weight: .bold))
            
            VStack(spacing: 25) {
                HStack {
                    Text("資料傳輸量:")
                        .font(.system(size: 28))
                    Spacer()
                    Text("\(Double(result.totalDataSize) / 1_048_576.0, specifier: "%.2f") MB")
                        .font(.system(size: 28, weight: .bold))
                }
                
                HStack {
                    Text("耗時:")
                        .font(.system(size: 28))
                    Spacer()
                    Text("\(result.duration, specifier: "%.2f") 秒")
                        .font(.system(size: 28, weight: .bold))
                }
                
                HStack {
                    Text("平均速度:")
                        .font(.system(size: 28))
                    Spacer()
                    Text("\(result.speedMBps, specifier: "%.2f") MB/s")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.blue)
                }
            }
            .padding(40)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(20)
            
            // Performance Rating - Simplified for TV
            tvOSPerformanceRatingView(rating: result.performanceRating, speed: result.speedMBps)
        }
        .padding(40)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(25)
    }
}

struct tvOSPerformanceRatingView: View {
    let rating: PerformanceRating
    let speed: Double
    
    var body: some View {
        VStack(spacing: 25) {
            Text("效能評估")
                .font(.system(size: 36, weight: .bold))
            
            HStack(spacing: 20) {
                Text(rating.emoji)
                    .font(.system(size: 60))
                
                Text(PerformanceDisplayHelper.title(for: rating))
                    .font(.system(size: 40, weight: .bold))
            }
            
            Text(PerformanceDisplayHelper.message(for: rating))
                .font(.system(size: 28))
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 40)
            
            let percentage = (speed / 125.0) * 100
            Text("達到理論速度的: \(percentage, specifier: "%.1f")%")
                .font(.system(size: 24))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Custom Button Styles for tvOS

struct TVButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct TVProminentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 60)
            .padding(.vertical, 20)
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(15)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}