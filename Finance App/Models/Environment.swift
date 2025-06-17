//
//  Environment.swift
//  Finance App
//
//  Created by Jas  on 6/16/25.
//

import Foundation


enum Environment {/// Holds base URLs for different build targets
    #if targetEnvironment(simulator)
    static let baseURL = "http://127.0.0.1:5050"/// Use localhost when running in Simulator
    #else
    static let baseURL = "https://your-ngrok-url.ngrok.io"/// Use ngrok (or your HTTPS tunnel) on a real device
    #endif
}

