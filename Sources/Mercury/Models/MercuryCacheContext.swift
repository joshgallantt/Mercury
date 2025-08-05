//
//  MercuryCacheContext.swift
//  Mercury
//
//  Created by Josh Gallant on 05/08/2025.
//


public enum MercuryCacheContext: Equatable {
    /// Uses the system's shared URLCache. Not isolated.
    case shared
    /// Each client instance owns its own URLCache (size in bytes).
    case clientIsolated(
        memorySize: Int = MercuryCacheContext.defaultMemorySize,
        diskSize: Int = MercuryCacheContext.defaultDiskSize
    )
}

public extension MercuryCacheContext {
    /// 4MB memory cache, 20MB disk cache. Tuned for typical REST usage.
    static let defaultMemorySize: Int = 4 * 1024 * 1024    // 4MB
    static let defaultDiskSize: Int = 20 * 1024 * 1024     // 20MB
}
