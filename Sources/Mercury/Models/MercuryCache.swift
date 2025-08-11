//
//  MercuryCache.swift
//  Mercury
//
//  Created by Josh Gallant on 05/08/2025.
//

import Foundation

/// Represents the caching strategy used by Mercury networking clients.
///
/// - Note: The default values are optimized for general usage, but can be adjusted to fit specific application needs.
public enum MercuryCache: Equatable, Sendable {
    /// Uses the system's shared `URLCache` instance.
    ///
    /// - Important: The cache is global and shared across the process, not isolated to the Mercury client.
    case shared

    /// Creates a unique `URLCache` instance for each client.
    ///
    /// - Parameters:
    ///   - memorySize: The maximum number of bytes the in-memory cache can hold. Defaults to `MercuryCache.defaultMemorySize` (4MB).
    ///   - diskSize: The maximum number of bytes the on-disk cache can hold. Defaults to `MercuryCache.defaultDiskSize` (10MB).
    ///
    /// - Note: Use this for clients requiring cache isolation or custom cache sizing.
    case isolated(
        memorySize: Int = MercuryCache.defaultMemorySize,
        diskSize: Int = MercuryCache.defaultDiskSize
    )
}

public extension MercuryCache {
    /// The default memory cache size, in bytes (4MB).
    static let defaultMemorySize: Int = 4 * 1024 * 1024

    /// The default disk cache size, in bytes (10MB).
    static let defaultDiskSize: Int = 10 * 1024 * 1024
}
