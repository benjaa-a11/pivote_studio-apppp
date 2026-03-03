/// Shared enums, constants and configuration for the Pivote video player system.
/// Used by both the native M3U8 player and the WebView player.
///
/// @version 5.0 — Professional Edition 2026
library player_enums;

/// Aspect ratio modes for the video player
enum AspectRatioType {
  auto,
  ratio16_9,
  ratio4_3,
  stretch,
}

/// Player lifecycle state machine
/// ```
/// IDLE → CONNECTING → RESOLVING_URL → INITIALIZING → BUFFERING → PLAYING
///                                                        ↓
///                                                    ERROR → RETRYING → CONNECTING
/// ```
enum PlayerState {
  idle,
  connecting,
  resolvingUrl,
  initializing,
  buffering,
  playing,
  error,
  retrying,
}

// ═══════════════════════════════════════════════════════════
// Player Configuration Constants
// ═══════════════════════════════════════════════════════════

/// Configuration constants for the video player engine.
/// Tuned for unstable live TV streams with saturated servers.
class PlayerConfig {
  PlayerConfig._();

  // ── Retry & Failover ──────────────────────────────────
  /// Max retries on the same server before failover
  static const int maxRetriesPerServer = 4;

  /// Max consecutive errors across all servers before giving up
  static const int maxConsecutiveErrors = 6;

  // ── Timeouts ──────────────────────────────────────────
  /// Base timeout for server connection (increases per attempt)
  static const Duration baseServerTimeout = Duration(seconds: 25);

  /// Max additional timeout added per server attempt
  static const int maxTimeoutExtensionSeconds = 10;

  /// Timeout for VideoPlayer.initialize()
  static const Duration initializeTimeout = Duration(seconds: 30);

  /// Timeout for URL resolution HTTP requests
  static const Duration urlResolveTimeout = Duration(seconds: 4);

  /// Max additional timeout per URL resolve retry
  static const int urlResolveTimeoutExtensionSeconds = 3;

  /// Max URL resolve retries
  static const int maxUrlResolveRetries = 2;

  // ── Watchdog & Health ─────────────────────────────────
  /// Interval for the health watchdog check
  static const Duration watchdogInterval = Duration(seconds: 5);

  /// How many consecutive watchdog ticks of bad health before recovery
  static const int watchdogStallThreshold = 3;

  /// Grace period after initialization before watchdog activates
  static const Duration watchdogGracePeriod = Duration(seconds: 20);

  /// Extended buffering threshold (watchdog ticks)
  static const int extendedBufferingThreshold = 7;

  // ── Loading ───────────────────────────────────────────
  /// Failsafe timer to hide loading overlay if stuck
  static const Duration loadingFailsafeTimeout = Duration(seconds: 40);

  // ── Backoff ───────────────────────────────────────────
  /// Base delay for exponential backoff (ms)
  static const int backoffBaseMs = 200;

  /// Max backoff delay (ms)
  static const int backoffMaxMs = 3000;

  // ── Iframe / WebView ──────────────────────────────────
  /// Timeout for iframe page to load and start video
  static const Duration iframeLoadTimeout = Duration(seconds: 20);

  /// Max retries inside iframe before fallback to next server
  static const int maxIframeRetries = 2;

  /// Quick retry delay for same-server retry (ms)
  static const int quickRetryDelayMs = 500;

  // ── Buffer Health ─────────────────────────────────────
  /// Seconds of buffer ahead considered "healthy"
  static const double healthyBufferSeconds = 5.0;

  /// Seconds of buffer below which we consider "critical"
  static const double criticalBufferSeconds = 1.0;

  // ── Orientation ───────────────────────────────────────
  /// Polling interval for orientation sync
  static const Duration orientationCheckInterval = Duration(milliseconds: 500);

  // ── User Agent ────────────────────────────────────────
  static const String userAgent =
      'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/121.0.0.0 Mobile Safari/537.36';
}

// ═══════════════════════════════════════════════════════════
// Helper Extensions
// ═══════════════════════════════════════════════════════════

extension AspectRatioTypeExtension on AspectRatioType {
  String get label {
    switch (this) {
      case AspectRatioType.auto:
        return 'Auto';
      case AspectRatioType.ratio16_9:
        return '16:9';
      case AspectRatioType.ratio4_3:
        return '4:3';
      case AspectRatioType.stretch:
        return 'Estirar';
    }
  }

  AspectRatioType get next {
    switch (this) {
      case AspectRatioType.auto:
        return AspectRatioType.ratio16_9;
      case AspectRatioType.ratio16_9:
        return AspectRatioType.ratio4_3;
      case AspectRatioType.ratio4_3:
        return AspectRatioType.stretch;
      case AspectRatioType.stretch:
        return AspectRatioType.auto;
    }
  }
}

extension PlayerStateExtension on PlayerState {
  /// User-facing message for this state
  String get displayMessage {
    switch (this) {
      case PlayerState.idle:
        return 'Preparando...';
      case PlayerState.connecting:
        return 'Buscando servidor...';
      case PlayerState.resolvingUrl:
        return 'Resolviendo enlace...';
      case PlayerState.initializing:
        return 'Preparando transmisión...';
      case PlayerState.buffering:
        return 'Cargando...';
      case PlayerState.playing:
        return 'En vivo';
      case PlayerState.error:
        return 'Error de conexión';
      case PlayerState.retrying:
        return 'Reintentando...';
    }
  }

  bool get isLoading =>
      this == PlayerState.connecting ||
      this == PlayerState.resolvingUrl ||
      this == PlayerState.initializing ||
      this == PlayerState.retrying;

  bool get isActive =>
      this == PlayerState.playing || this == PlayerState.buffering;
}
