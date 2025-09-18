//
//  NetworkMonitor.swift.swift
//  Finance App
//
//  Created by Jas  on 7/25/25.
//

import Network
import Foundation

/// Monitors the device’s network status continuously.
final class NetworkMonitor {
    
    static let shared = NetworkMonitor()
    
    private let monitor = NWPathMonitor()
    private let queue   = DispatchQueue(label: "NetworkMonitor")
    
    /// True if the device currently has an internet connection.
    private(set) var isConnected: Bool = true
    
    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.isConnected = (path.status == .satisfied)
        }
        monitor.start(queue: queue)
    }
    
    deinit {
        monitor.cancel()
    }
}

