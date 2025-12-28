//
//  NetworkMonitor.swift.swift
//  Finance App
//
//  Created by Jas  on 7/25/25.
//

import Network
import Foundation

final class NetworkMonitor {

    static let shared = NetworkMonitor()

    static let statusDidChangeNotification = Notification.Name("NetworkMonitorStatusDidChange")

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    private(set) var isConnected: Bool = true {
        didSet {
            guard oldValue != isConnected else { return }
            DispatchQueue.main.async {
                self.onStatusChange?(self.isConnected)
                NotificationCenter.default.post(
                    name: NetworkMonitor.statusDidChangeNotification,
                    object: self,
                    userInfo: ["isConnected": self.isConnected]
                )
            }
        }
    }

    var onStatusChange: ((Bool) -> Void)?

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.isConnected = (path.status == .satisfied)
        }
        monitor.start(queue: queue)
    }

    deinit { monitor.cancel() }
}


