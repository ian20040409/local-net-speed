// Re-export all public types
@_exported import Foundation

#if canImport(Combine)
@_exported import Combine
#endif

#if canImport(Network)
@_exported import Network
#endif

// Make all types easily accessible
public typealias LocalNetSpeedServer = NetworkSpeedServer
public typealias LocalNetSpeedClient = NetworkSpeedClient