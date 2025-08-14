import SwiftUI
import LocalNetSpeedCore

@main
struct LocalNetSpeedMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var viewModel = AppViewModel()
    
    var body: some Scene {
        WindowGroup {
            macOSContentView()
                .environmentObject(viewModel)
        }
        .windowStyle(DefaultWindowStyle())
        .windowToolbarStyle(UnifiedWindowToolbarStyle())
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("新建連線") {
                    // Create new window
                }
                .keyboardShortcut("n")
            }
            
            CommandGroup(after: .newItem) {
                Button("啟動伺服器") {
                    viewModel.switchToMode(.server)
                    Task {
                        await viewModel.startServer()
                    }
                }
                .keyboardShortcut("s")
                
                Button("客戶端模式") {
                    viewModel.switchToMode(.client)
                }
                .keyboardShortcut("c")
            }
        }
        
        MenuBarExtra("網路速度", systemImage: "network") {
            MenuBarView()
                .environmentObject(viewModel)
        }
        .menuBarExtraStyle(.window)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Configure app for macOS
        NSApp.setActivationPolicy(.regular)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false // Keep running in menu bar
    }
}

struct macOSContentView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var showingInspector = false
    
    var body: some View {
        HSplitView {
            // Sidebar
            VStack(spacing: 20) {
                Text("網路速度測試")
                    .font(.title)
                    .fontWeight(.bold)
                
                // Mode Selection for macOS
                VStack(spacing: 10) {
                    ForEach(AppMode.allCases, id: \.self) { mode in
                        Button(action: {
                            viewModel.switchToMode(mode)
                        }) {
                            HStack {
                                Image(systemName: mode.icon)
                                Text(mode.localizedTitle)
                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.selectedMode == mode ? Color.accentColor : Color.clear)
                            .foregroundColor(viewModel.selectedMode == mode ? .white : .primary)
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                Spacer()
                
                // Quick Actions
                VStack(spacing: 10) {
                    Text("快速動作")
                        .font(.headline)
                    
                    Button("設定") {
                        viewModel.showingSettings = true
                    }
                    .buttonStyle(.bordered)
                    
                    Button("檢視器") {
                        showingInspector.toggle()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
            .frame(minWidth: 250, maxWidth: 300)
            .background(Color.secondary.opacity(0.1))
            
            // Main Content
            VStack(spacing: 20) {
                if viewModel.selectedMode == .server {
                    macOSServerView(server: viewModel.server)
                } else {
                    macOSClientView(
                        client: viewModel.client,
                        discovery: viewModel.discovery,
                        serverIP: $viewModel.serverIP
                    )
                }
                
                Spacer()
            }
            .padding()
            .frame(minWidth: 500)
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: {
                    NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
                }) {
                    Label("Toggle Sidebar", systemImage: "sidebar.left")
                }
            }
            
            ToolbarItem(placement: .primaryAction) {
                Button("Inspector") {
                    showingInspector.toggle()
                }
            }
        }
        .inspector(isPresented: $showingInspector) {
            InspectorView()
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $viewModel.showingSettings) {
            macOSSettingsView(configuration: $viewModel.configuration)
        }
        .onDisappear {
            viewModel.stopAll()
        }
    }
}

struct macOSServerView: View {
    @ObservedObject var server: NetworkSpeedServer
    
    var body: some View {
        VStack(spacing: 20) {
            Text("伺服器模式")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            if server.isRunning {
                VStack(spacing: 20) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title2)
                        Text("伺服器正在運行")
                            .font(.title3)
                    }
                    
                    if let address = server.connectionAddress {
                        GroupBox("伺服器資訊") {
                            VStack(spacing: 10) {
                                HStack {
                                    Text("IP 位址:")
                                        .fontWeight(.medium)
                                    Spacer()
                                    Text(address)
                                        .font(.system(.body, design: .monospaced))
                                        .textSelection(.enabled)
                                    
                                    Button("複製") {
                                        NSPasteboard.general.clearContents()
                                        NSPasteboard.general.setString(address, forType: .string)
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                }
                                
                                HStack {
                                    Text("連接埠:")
                                        .fontWeight(.medium)
                                    Spacer()
                                    Text("65432")
                                        .font(.system(.body, design: .monospaced))
                                }
                            }
                            .padding()
                        }
                    }
                    
                    if let progress = server.currentProgress {
                        GroupBox("傳輸進度") {
                            VStack(spacing: 15) {
                                ProgressView(value: progress.percentage, total: 100) {
                                    Text("正在接收資料...")
                                } currentValueLabel: {
                                    Text("\(progress.percentage, specifier: "%.1f")%")
                                }
                                
                                HStack {
                                    Text("目前速度:")
                                    Spacer()
                                    Text("\(progress.currentSpeedMBps, specifier: "%.2f") MB/s")
                                        .fontWeight(.semibold)
                                }
                                
                                HStack {
                                    Text("已接收:")
                                    Spacer()
                                    Text("\(Double(progress.bytesTransferred) / 1_048_576.0, specifier: "%.1f") MB")
                                }
                            }
                            .padding()
                        }
                    }
                    
                    Button("停止伺服器") {
                        server.stopServer()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
            } else {
                VStack(spacing: 20) {
                    Text("啟動伺服器等待客戶端連線，並測量接收速度")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .font(.title3)
                    
                    Button("啟動伺服器") {
                        Task {
                            try? await server.startServer()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
            
            if let result = server.lastResult {
                macOSResultView(result: result)
            }
            
            if let error = server.errorMessage {
                GroupBox {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text("錯誤: \(error)")
                            .foregroundColor(.red)
                    }
                    .padding()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct macOSClientView: View {
    @ObservedObject var client: NetworkSpeedClient
    @ObservedObject var discovery: NetworkDiscovery
    @Binding var serverIP: String
    
    var body: some View {
        VStack(spacing: 20) {
            Text("客戶端模式")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            GroupBox("連線設定") {
                VStack(spacing: 15) {
                    HStack {
                        Text("伺服器 IP:")
                            .fontWeight(.medium)
                            .frame(width: 100, alignment: .leading)
                        
                        TextField("輸入伺服器 IP", text: $serverIP)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    if !discovery.discoveredServers.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("發現的伺服器:")
                                .fontWeight(.medium)
                            
                            LazyVGrid(columns: [
                                GridItem(.adaptive(minimum: 150))
                            ], spacing: 10) {
                                ForEach(discovery.discoveredServers, id: \.self) { server in
                                    Button(server) {
                                        serverIP = server
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            
            if client.isConnected || client.isTransferring {
                GroupBox("連線狀態") {
                    VStack(spacing: 15) {
                        if client.isConnected {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("已連線至 \(serverIP)")
                            }
                        }
                        
                        if let progress = client.currentProgress {
                            VStack(spacing: 10) {
                                ProgressView(value: progress.percentage, total: 100) {
                                    Text("正在發送資料...")
                                } currentValueLabel: {
                                    Text("\(progress.percentage, specifier: "%.1f")%")
                                }
                                
                                HStack {
                                    Text("目前速度:")
                                    Spacer()
                                    Text("\(progress.currentSpeedMBps, specifier: "%.2f") MB/s")
                                        .fontWeight(.semibold)
                                }
                                
                                HStack {
                                    Text("已發送:")
                                    Spacer()
                                    Text("\(Double(progress.bytesTransferred) / 1_048_576.0, specifier: "%.1f") MB")
                                }
                            }
                        }
                        
                        Button("中斷連線") {
                            client.disconnect()
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                }
            } else {
                Button("連線並測試") {
                    Task {
                        try? await client.connectAndSendData(to: serverIP)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(serverIP.isEmpty)
            }
            
            if let result = client.lastResult {
                macOSResultView(result: result)
            }
            
            if let error = client.errorMessage {
                GroupBox {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text("錯誤: \(error)")
                            .foregroundColor(.red)
                    }
                    .padding()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct macOSResultView: View {
    let result: SpeedTestResult
    
    var body: some View {
        GroupBox("測試結果") {
            VStack(spacing: 15) {
                Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 10) {
                    GridRow {
                        Text("資料傳輸量:")
                            .fontWeight(.medium)
                        Text("\(Double(result.totalDataSize) / 1_048_576.0, specifier: "%.2f") MB")
                            .fontWeight(.semibold)
                    }
                    
                    GridRow {
                        Text("耗時:")
                            .fontWeight(.medium)
                        Text("\(result.duration, specifier: "%.2f") 秒")
                            .fontWeight(.semibold)
                    }
                    
                    GridRow {
                        Text("平均速度:")
                            .fontWeight(.medium)
                        Text("\(result.speedMBps, specifier: "%.2f") MB/s")
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                }
                
                Divider()
                
                // Performance Rating
                macOSPerformanceRatingView(rating: result.performanceRating, speed: result.speedMBps)
                
                HStack {
                    Button("複製結果") {
                        let resultText = formatResultForCopying(result)
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(resultText, forType: .string)
                    }
                    .buttonStyle(.bordered)
                    
                    Button("匯出報告") {
                        exportResult(result)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
        }
    }
    
    private func formatResultForCopying(_ result: SpeedTestResult) -> String {
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
    
    private func exportResult(_ result: SpeedTestResult) {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.plainText]
        savePanel.nameFieldStringValue = "network_speed_test_\(Date().timeIntervalSince1970).txt"
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                let content = formatResultForCopying(result)
                try? content.write(to: url, atomically: true, encoding: .utf8)
            }
        }
    }
}

struct macOSPerformanceRatingView: View {
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
                DisclosureGroup("效能改善建議") {
                    VStack(alignment: .leading, spacing: 5) {
                        ForEach(suggestions, id: \.self) { suggestion in
                            Text("• \(suggestion)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
}

struct MenuBarView: View {
    @EnvironmentObject var viewModel: AppViewModel
    
    var body: some View {
        VStack(spacing: 10) {
            Text("網路速度測試")
                .font(.headline)
            
            Divider()
            
            Button("啟動伺服器") {
                viewModel.switchToMode(.server)
                Task {
                    await viewModel.startServer()
                }
            }
            
            Button("客戶端模式") {
                viewModel.switchToMode(.client)
            }
            
            Divider()
            
            Button("退出") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding()
    }
}

struct InspectorView: View {
    @EnvironmentObject var viewModel: AppViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Text("檢視器")
                .font(.headline)
            
            GroupBox("連線資訊") {
                VStack(alignment: .leading, spacing: 10) {
                    if viewModel.selectedMode == .server {
                        Text("模式: 伺服器")
                        if let address = viewModel.server.connectionAddress {
                            Text("位址: \(address)")
                        }
                        Text("狀態: \(viewModel.server.isRunning ? "運行中" : "停止")")
                    } else {
                        Text("模式: 客戶端")
                        Text("伺服器: \(viewModel.serverIP.isEmpty ? "未設定" : viewModel.serverIP)")
                        Text("狀態: \(viewModel.client.isConnected ? "已連線" : "未連線")")
                    }
                }
                .font(.caption)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            
            GroupBox("發現的伺服器") {
                if viewModel.discovery.discoveredServers.isEmpty {
                    Text("無")
                        .foregroundColor(.secondary)
                } else {
                    VStack(alignment: .leading, spacing: 5) {
                        ForEach(viewModel.discovery.discoveredServers, id: \.self) { server in
                            Text(server)
                                .font(.caption)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
            
            Spacer()
        }
        .padding()
        .frame(width: 250)
    }
}

struct macOSSettingsView: View {
    @Binding var configuration: NetworkTestConfiguration
    @Environment(\.dismiss) private var dismiss
    
    @State private var portString: String
    @State private var dataSizeString: String
    @State private var chunkSizeString: String
    
    init(configuration: Binding<NetworkTestConfiguration>) {
        self._configuration = configuration
        self._portString = State(initialValue: String(configuration.wrappedValue.port))
        self._dataSizeString = State(initialValue: String(configuration.wrappedValue.dataSizeMB))
        self._chunkSizeString = State(initialValue: String(configuration.wrappedValue.chunkSizeMB))
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("設定")
                .font(.title)
                .fontWeight(.bold)
            
            Form {
                Section("網路設定") {
                    HStack {
                        Text("連接埠:")
                            .frame(width: 100, alignment: .leading)
                        TextField("埠號", text: $portString)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    HStack {
                        Text("資料大小 (MB):")
                            .frame(width: 100, alignment: .leading)
                        TextField("資料大小", text: $dataSizeString)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    HStack {
                        Text("區塊大小 (MB):")
                            .frame(width: 100, alignment: .leading)
                        TextField("區塊大小", text: $chunkSizeString)
                            .textFieldStyle(.roundedBorder)
                    }
                }
            }
            .formStyle(.grouped)
            
            HStack {
                Button("重設為預設值") {
                    let defaultConfig = NetworkTestConfiguration.default
                    portString = String(defaultConfig.port)
                    dataSizeString = String(defaultConfig.dataSizeMB)
                    chunkSizeString = String(defaultConfig.chunkSizeMB)
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("取消") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Button("儲存") {
                    saveConfiguration()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 400, height: 300)
    }
    
    private func saveConfiguration() {
        let port = UInt16(portString) ?? NetworkTestConfiguration.default.port
        let dataSize = Int(dataSizeString) ?? NetworkTestConfiguration.default.dataSizeMB
        let chunkSize = Int(chunkSizeString) ?? NetworkTestConfiguration.default.chunkSizeMB
        
        configuration = NetworkTestConfiguration(
            port: port,
            dataSizeMB: dataSize,
            chunkSizeMB: chunkSize
        )
    }
}