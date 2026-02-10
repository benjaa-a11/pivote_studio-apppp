package com.example.pivote_studio

/**
 * Centralized configuration for ExoPlayer.
 * Professional-grade settings for optimal streaming performance.
 */
object PlayerConfig {
    
    // User Agent
    const val USER_AGENT = "PivoteStudio/2.0 (Android; Professional)"
    
    // Buffering Configuration (in milliseconds)
    object Buffering {
        const val MIN_BUFFER_MS = 3000          // 3 seconds minimum buffer
        const val MAX_BUFFER_MS = 30000         // 30 seconds maximum buffer
        const val BUFFER_FOR_PLAYBACK_MS = 1500 // 1.5 seconds to start playback
        const val BUFFER_FOR_REBUFFER_MS = 3000 // 3 seconds to resume after rebuffering
    }
    
    // Network Configuration
    object Network {
        const val CONNECT_TIMEOUT_MS = 15000    // 15 seconds connection timeout
        const val READ_TIMEOUT_MS = 15000       // 15 seconds read timeout
        const val ALLOW_CROSS_PROTOCOL = true   // Allow HTTP -> HTTPS redirects
    }
    
    // Watchdog Configuration
    object Watchdog {
        const val CHECK_INTERVAL_MS = 5000L     // Check every 5 seconds
        const val STALLED_THRESHOLD = 3         // Consider stalled after 3 checks (15s)
    }
    
    // Retry Configuration
    object Retry {
        const val MAX_RETRY_ATTEMPTS = 3        // Maximum retry attempts per server
        const val INITIAL_BACKOFF_MS = 500L     // Initial backoff delay
        const val MAX_BACKOFF_MS = 6000L        // Maximum backoff delay
        const val BACKOFF_MULTIPLIER = 2.0      // Exponential backoff multiplier
    }
    
    // Quality Selection Presets
    object Quality {
        const val AUTO = -1
        const val QUALITY_1080P = 1080
        const val QUALITY_720P = 720
        const val QUALITY_480P = 480
        const val QUALITY_360P = 360
        const val QUALITY_240P = 240
    }
    
    // DRM Configuration
    object Drm {
        const val ENABLE_UUID_SWAP_FALLBACK = true  // Try UUID swap if hex fails
        const val LICENSE_ACQUISITION_TIMEOUT_MS = 10000 // 10 seconds for license
    }
    
    // UI Configuration
    object UI {
        const val CONTROLLER_TIMEOUT_MS = 5000  // Hide controls after 5 seconds
        const val FADE_ANIMATION_MS = 300       // Fade animation duration
    }
}
