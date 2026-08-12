/// Shared enums, constants and configuration for the Pivote video player system.
/// Used by both the native M3U8 player and the WebView player.
///
/// @version 7.0 — Ultra-Performance IPTV Edition 2026
library player_enums;

/// Aspect ratio modes for the video player
enum AspectRatioType {
  auto,
  ratio16_9,
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
/// Aggressively tuned for ultra-fast IPTV channel loading.
class PlayerConfig {
  PlayerConfig._();

  // ── Retry & Failover ──────────────────────────────────
  /// Max retries on the same server before failover
  static const int maxRetriesPerServer = 3;

  /// Max consecutive errors across all servers before giving up
  static const int maxConsecutiveErrors = 5;

  // ── Timeouts (aggressive for fast channel zapping) ────
  /// Base timeout for server connection (10 s, was 18 s)
  static const Duration baseServerTimeout = Duration(seconds: 10);

  /// Max additional timeout added per server attempt
  static const int maxTimeoutExtensionSeconds = 6;

  /// Timeout for VideoPlayer.initialize() (15 s, was 30 s)
  static const Duration initializeTimeout = Duration(seconds: 15);

  /// Timeout for URL resolution HTTP requests (12 s — allows PHP page scraping)
  static const Duration urlResolveTimeout = Duration(seconds: 12);

  /// Max additional timeout per URL resolve retry
  static const int urlResolveTimeoutExtensionSeconds = 2;

  /// Max URL resolve retries
  static const int maxUrlResolveRetries = 2;

  // ── Watchdog & Health ─────────────────────────────────
  /// Interval for the health watchdog check (2 s, was 3 s)
  static const Duration watchdogInterval = Duration(seconds: 2);

  /// How many consecutive watchdog ticks of bad health before recovery
  static const int watchdogStallThreshold = 2;

  /// Grace period after initialization before watchdog activates (10 s, was 20 s)
  static const Duration watchdogGracePeriod = Duration(seconds: 10);

  /// Extended buffering threshold (watchdog ticks)
  static const int extendedBufferingThreshold = 4;

  // ── Loading ───────────────────────────────────────────
  /// Failsafe timer to hide loading overlay if stuck (15 s, was 30 s)
  static const Duration loadingFailsafeTimeout = Duration(seconds: 15);

  // ── Backoff (ultra-fast for IPTV) ─────────────────────
  /// Base delay for exponential backoff (ms) (100 ms, was 200 ms)
  static const int backoffBaseMs = 100;

  /// Max backoff delay (ms) (1500 ms, was 3000 ms)
  static const int backoffMaxMs = 1500;

  // ── Iframe / WebView ──────────────────────────────────
  /// Timeout for iframe page to load and start video (8 s, was 12 s)
  static const Duration iframeLoadTimeout = Duration(seconds: 8);

  /// Max retries inside iframe before fallback to next server
  static const int maxIframeRetries = 3;

  /// Quick retry delay for same-server retry (ms)
  static const int quickRetryDelayMs = 400;

  // ── Buffer Health ─────────────────────────────────────
  /// Seconds of buffer ahead considered "healthy"
  static const double healthyBufferSeconds = 3.0;

  /// Seconds of buffer below which we consider "critical"
  static const double criticalBufferSeconds = 0.5;

  // ── Orientation ───────────────────────────────────────
  /// Polling interval for orientation sync (300 ms, was 500 ms)
  static const Duration orientationCheckInterval = Duration(milliseconds: 300);

  // ── User Agent ────────────────────────────────────────
  static const String userAgent =
      'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36';
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
      case AspectRatioType.stretch:
        return 'Estirar';
    }
  }

  AspectRatioType get next {
    switch (this) {
      case AspectRatioType.auto:
        return AspectRatioType.ratio16_9;
      case AspectRatioType.ratio16_9:
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
