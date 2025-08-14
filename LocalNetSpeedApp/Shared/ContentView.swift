import SwiftUI
import LocalNetSpeedCore

// MARK: - Main Content View

public struct MainContentView: View {
    @StateObject private var viewModel = AppViewModel()
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Mode Selection
                ModeSelectionView(selectedMode: $viewModel.selectedMode) { mode in
                    viewModel.switchToMode(mode)
                }
                
                Divider()
                
                // Content based on selected mode
                Group {
                    if viewModel.selectedMode == .server {
                        ServerView(server: viewModel.server)
                    } else {
                        ClientView(
                            client: viewModel.client,
                            discovery: viewModel.discovery,
                            serverIP: $viewModel.serverIP
                        )
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("local_net_speed")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("settings") {
                        viewModel.showingSettings = true
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingSettings) {
                SettingsView(configuration: $viewModel.configuration)
            }
        }
        .onDisappear {
            viewModel.stopAll()
        }
    }
}

// MARK: - Mode Selection View

public struct ModeSelectionView: View {
    @Binding var selectedMode: AppMode
    let onModeChanged: (AppMode) -> Void
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("select_mode")
                .font(.headline)
            
            HStack(spacing: 15) {
                ForEach(AppMode.allCases, id: \.self) { mode in
                    Button(action: {
                        selectedMode = mode
                        onModeChanged(mode)
                    }) {
                        HStack {
                            Image(systemName: mode.icon)
                            Text(mode.localizedTitle)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedMode == mode ? Color.accentColor : Color.secondary.opacity(0.2))
                        .foregroundColor(selectedMode == mode ? .white : .primary)
                        .cornerRadius(10)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

// MARK: - Server View

public struct ServerView: View {
    @ObservedObject var server: NetworkSpeedServer
    
    public var body: some View {
        VStack(spacing: 20) {
            Text("server_mode")
                .font(.title2)
                .fontWeight(.semibold)
            
            if server.isRunning {
                VStack(spacing: 15) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("server_running")
                    }
                    
                    if let address = server.connectionAddress {
                        Text("server_address: \(address)")
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                    }
                    
                    if let progress = server.currentProgress {
                        ProgressView(value: progress.percentage, total: 100) {
                            Text("receiving_data")
                        } currentValueLabel: {
                            Text("\(progress.percentage, specifier: "%.1f")%")
                        }
                        
                        Text("current_speed: \(progress.currentSpeedMBps, specifier: "%.2f") MB/s")
                            .font(.caption)
                    }
                    
                    Button("stop_server") {
                        server.stopServer()
                    }
                    .buttonStyle(.bordered)
                }
            } else {
                VStack(spacing: 15) {
                    Text("server_description")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                    
                    Button("start_server") {
                        Task {
                            try? await server.startServer()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
            
            if let result = server.lastResult {
                ResultView(result: result)
            }
            
            if let error = server.errorMessage {
                Text("error: \(error)")
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
    }
}

// MARK: - Client View

public struct ClientView: View {
    @ObservedObject var client: NetworkSpeedClient
    @ObservedObject var discovery: NetworkDiscovery
    @Binding var serverIP: String
    
    public var body: some View {
        VStack(spacing: 20) {
            Text("client_mode")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(spacing: 15) {
                // Server IP Input
                VStack(alignment: .leading, spacing: 5) {
                    Text("server_ip")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("enter_server_ip", text: $serverIP)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numbersAndPunctuation)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                
                // Discovered Servers
                if !discovery.discoveredServers.isEmpty {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("discovered_servers")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ForEach(discovery.discoveredServers, id: \.self) { server in
                            Button(server) {
                                serverIP = server
                            }
                            .buttonStyle(.bordered)
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
                                Text("connected")
                            }
                        }
                        
                        if let progress = client.currentProgress {
                            ProgressView(value: progress.percentage, total: 100) {
                                Text("sending_data")
                            } currentValueLabel: {
                                Text("\(progress.percentage, specifier: "%.1f")%")
                            }
                            
                            Text("current_speed: \(progress.currentSpeedMBps, specifier: "%.2f") MB/s")
                                .font(.caption)
                        }
                        
                        Button("disconnect") {
                            client.disconnect()
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    Button("connect_and_test") {
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
                ResultView(result: result)
            }
            
            if let error = client.errorMessage {
                Text("error: \(error)")
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
    }
}

// MARK: - Result View

public struct ResultView: View {
    let result: SpeedTestResult
    
    public var body: some View {
        VStack(spacing: 15) {
            Text("test_results")
                .font(.headline)
            
            VStack(spacing: 10) {
                HStack {
                    Text("data_transferred:")
                    Spacer()
                    Text("\(Double(result.totalDataSize) / 1_048_576.0, specifier: "%.2f") MB")
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("duration:")
                    Spacer()
                    Text("\(result.duration, specifier: "%.2f") 秒")
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("average_speed:")
                    Spacer()
                    Text("\(result.speedMBps, specifier: "%.2f") MB/s")
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(10)
            
            // Performance Rating
            PerformanceRatingView(rating: result.performanceRating, speed: result.speedMBps)
        }
    }
}

// MARK: - Performance Rating View

public struct PerformanceRatingView: View {
    let rating: PerformanceRating
    let speed: Double
    
    public var body: some View {
        VStack(spacing: 10) {
            Text("gigabit_evaluation")
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
            Text("theoretical_speed_percentage: \(percentage, specifier: "%.1f")%")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Suggestions for improvement
            let suggestions = PerformanceDisplayHelper.suggestions(for: rating)
            if !suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    Text("improvement_suggestions")
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

// MARK: - Settings View

public struct SettingsView: View {
    @Binding var configuration: NetworkTestConfiguration
    @Environment(\.dismiss) private var dismiss
    
    @State private var portString: String
    @State private var dataSizeString: String
    @State private var chunkSizeString: String
    
    public init(configuration: Binding<NetworkTestConfiguration>) {
        self._configuration = configuration
        self._portString = State(initialValue: String(configuration.wrappedValue.port))
        self._dataSizeString = State(initialValue: String(configuration.wrappedValue.dataSizeMB))
        self._chunkSizeString = State(initialValue: String(configuration.wrappedValue.chunkSizeMB))
    }
    
    public var body: some View {
        NavigationView {
            Form {
                Section("network_settings") {
                    HStack {
                        Text("port:")
                        TextField("port", text: $portString)
                            .keyboardType(.numberPad)
                    }
                    
                    HStack {
                        Text("data_size_mb:")
                        TextField("data_size", text: $dataSizeString)
                            .keyboardType(.numberPad)
                    }
                    
                    HStack {
                        Text("chunk_size_mb:")
                        TextField("chunk_size", text: $chunkSizeString)
                            .keyboardType(.numberPad)
                    }
                }
                
                Section {
                    Button("reset_to_defaults") {
                        let defaultConfig = NetworkTestConfiguration.default
                        portString = String(defaultConfig.port)
                        dataSizeString = String(defaultConfig.dataSizeMB)
                        chunkSizeString = String(defaultConfig.chunkSizeMB)
                    }
                }
            }
            .navigationTitle("settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("done") {
                        saveConfiguration()
                        dismiss()
                    }
                }
            }
        }
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