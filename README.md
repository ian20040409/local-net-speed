# LocalNetSpeed - Multi-Platform Network Speed Testing App

A comprehensive network speed testing application for iOS, macOS, tvOS, and watchOS platforms, built with SwiftUI and the Network framework.

## Features

### Core Functionality
- **Server Mode**: Listen for connections and measure receive speed
- **Client Mode**: Connect to servers and measure send speed
- **Real-time Progress**: Live speed monitoring during transfers
- **Gigabit Performance Evaluation**: Comprehensive speed analysis with Chinese feedback
- **Network Discovery**: Automatic discovery of local servers

### Platform-Specific Features

#### iOS
- Native iOS UI with haptic feedback
- Share sheets for results
- Support for iPhone and iPad layouts
- Background operation support

#### macOS
- Menu bar integration
- Window management and dock support
- Inspector panel for connection details
- Export functionality for test reports
- Mouse/trackpad optimized interface

#### tvOS
- Remote control navigation
- Large UI elements for TV viewing
- Preset server selection
- Focus-based navigation system
- Simplified input methods

#### watchOS
- Client-only mode optimized for watch constraints
- Complications support for quick access
- Digital Crown integration
- Simplified speed display
- Quick connect functionality

## Architecture

### Core Components
- **LocalNetSpeedCore**: Shared Swift package containing:
  - Network communication logic using Network framework
  - Speed calculation and performance evaluation
  - Progress tracking and error handling
  - Cross-platform compatibility layer

### Platform-Specific Apps
- **iOS App**: Full-featured mobile application
- **macOS App**: Desktop application with menu bar integration
- **tvOS App**: TV-optimized interface with remote control support
- **watchOS App**: Simplified watch interface with complications

## Technical Requirements

### Platforms
- **iOS**: 16.0+
- **macOS**: 13.0+ (Ventura)
- **tvOS**: 16.0+
- **watchOS**: 9.0+

### Dependencies
- Swift 5.9+
- SwiftUI
- Network framework
- Combine framework

## Localization

The app is fully localized in Traditional Chinese with support for:
- All UI text and labels
- Performance evaluation messages
- Error messages and suggestions
- Platform-specific terminology

## Network Configuration

### Default Settings
- **Port**: 65432
- **Data Size**: 100 MB
- **Chunk Size**: 1 MB
- **Timeout**: 30 seconds

### Customizable Options
- Port number
- Transfer data size
- Chunk size for transfers
- Network discovery settings

## Performance Evaluation

The app provides comprehensive Gigabit Ethernet performance evaluation:

### Rating System
- **優秀 (Excellent)** ✅: ≥100 MB/s
- **良好 (Good)** ⚡: 80-99 MB/s
- **一般 (Average)** ⚠️: 50-79 MB/s
- **偏慢 (Slow)** 🐌: 10-49 MB/s
- **很慢 (Very Slow)** 🚫: <10 MB/s

### Improvement Suggestions
The app provides specific suggestions for network optimization:
- Cable quality recommendations
- Switch configuration advice
- Network card settings
- Interference detection guidance

## Security and Privacy

### Network Permissions
- Uses minimal required network permissions
- Local network access only
- No external data transmission
- Optional network discovery

### Data Handling
- No personal data collection
- Local processing only
- Temporary test data only
- Secure network communication

## Build Configuration

### Shared Package
```swift
// Package.swift
platforms: [
    .iOS(.v16),
    .macOS(.v13), 
    .tvOS(.v16),
    .watchOS(.v9)
]
```

### Conditional Compilation
Platform-specific features use conditional compilation:
```swift
#if os(iOS)
// iOS-specific code
#elseif os(macOS)
// macOS-specific code
#elseif os(tvOS)
// tvOS-specific code
#elseif os(watchOS)
// watchOS-specific code
#endif
```

## Usage

### Server Mode
1. Launch the app on the server device
2. Select "伺服器端" (Server Mode)
3. Tap "啟動伺服器" (Start Server)
4. Note the displayed IP address
5. Wait for client connections

### Client Mode
1. Launch the app on the client device
2. Select "客戶端" (Client Mode)
3. Enter the server IP address or select from discovered servers
4. Tap "連線並測試" (Connect and Test)
5. View real-time progress and final results

### Results Interpretation
- Speed results are displayed in MB/s
- Performance rating provides context for the speed
- Suggestions help optimize network performance
- Results can be shared or exported (platform-dependent)

## Testing

The project includes comprehensive unit tests:
- Core networking functionality
- Speed calculation accuracy
- Performance rating evaluation
- Configuration management
- Error handling

Run tests with:
```bash
swift test
```

## Contributing

This project maintains Chinese localization and follows Apple's Human Interface Guidelines for each platform. When contributing:

1. Test on all supported platforms
2. Maintain Chinese localization
3. Follow platform-specific design patterns
4. Include appropriate unit tests
5. Ensure network security best practices

## License

This project respects the original Python implementation while providing a complete rewrite in Swift for Apple platforms.

## Compatibility

### Network Compatibility
- Compatible with the original Python implementation
- Same port and protocol usage
- Cross-platform testing supported
- Maintains measurement accuracy

### Future Enhancements
- Additional network protocols
- Enhanced discovery mechanisms
- Cloud sync for results
- Advanced analytics and reporting