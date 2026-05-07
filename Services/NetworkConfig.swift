//
//  NetworkConfig.swift
//  AquaGuard
//
//  Centralized network configuration.
//  Manages base URLs for REST API and WebSocket connections
//  across development (LAN IP) and production (Render) environments.
//

import Foundation

enum NetworkConfig {

    // MARK: - Environment Toggle

    /// Set to `true` to use the deployed Render backend.
    /// Set to `false` to use the local Docker backend.
    static let useProduction = true

    // MARK: - Production URLs (Render)

    private static let productionHost = "aquaguard-api.onrender.com"

    // MARK: - Base URLs

    /// REST API base URL (no trailing slash)
    static var apiBaseURL: String {
        if useProduction {
            return "https://\(productionHost)/api"
        }
        #if DEBUG
        return "http://\(devHost):5001/api"
        #else
        return "https://\(productionHost)/api"
        #endif
    }

    /// WebSocket URL for real-time tracking
    static var wsBaseURL: String {
        if useProduction {
            return "wss://\(productionHost)"
        }
        #if DEBUG
        return "ws://\(devHost):5001"
        #else
        return "wss://\(productionHost)"
        #endif
    }

    // MARK: - Development Host

    /// LAN IP of the machine running the backend.
    /// For Simulator: "localhost" works fine.
    /// For physical device: use your Mac's LAN IP (e.g. "192.168.1.100").
    private static var devHost: String {
        #if targetEnvironment(simulator)
        return "localhost"
        #else
        // TODO: Change this to your Mac's LAN IP if it changes
        return "192.168.1.74"
        #endif
    }

    // MARK: - Timeouts

    /// Default timeout for API requests (seconds)
    static let requestTimeout: TimeInterval = 30

    /// Upload timeout for multipart requests (seconds)
    static let uploadTimeout: TimeInterval = 60
}
