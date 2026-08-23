import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pivote/shared/widgets/app_notifications.dart';
import 'package:pivote/features/radio/data/models/radio.dart' as radio_model;
import 'package:pivote/features/radio/presentation/providers/audio_manager.dart';
import 'package:pivote/features/radio/presentation/providers/radio_provider.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/core/services/image_cache_helper.dart';
import 'package:pivote/core/services/app_activity_service.dart';

class RadioPlayerScreen extends StatefulWidget {
  final radio_model.Radio radio;

  const RadioPlayerScreen({
    super.key,
    required this.radio,
  });

  @override
  State<RadioPlayerScreen> createState() => _RadioPlayerScreenState();
}

class _RadioPlayerScreenState extends State<RadioPlayerScreen>
    with TickerProviderStateMixin {
  late AnimationController _rotateController;
  late AnimationController _pulseController;
  Timer? _sleepTimer;
  int _sleepMinutesRemaining = 0;

  @override
  void initState() {
    super.initState();

    // Disc rotation controller
    _rotateController = AnimationController(
      duration: const Duration(seconds: 18),
      vsync: this,
    );

    // Pulse controller for live equalizer waves
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    // Play radio on open if not already playing this radio
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final audioManager = context.read<AudioManager>();
      if (audioManager.currentRadio?.id != widget.radio.id) {
        audioManager.playRadio(widget.radio);
      }
      try {
        Provider.of<AppActivityService>(context, listen: false)
            .trackRadioListen();
      } catch (e) {
        debugPrint('Error tracking radio listen: $e');
      }

      if (audioManager.isPlaying) {
        _rotateController.repeat();
      }
    });

    _setupManagerListener();
  }

  void _setupManagerListener() {
    final audioManager = context.read<AudioManager>();
    audioManager.addListener(_onAudioManagerChanged);
  }

  void _onAudioManagerChanged() {
    if (!mounted) return;
    final audioManager = context.read<AudioManager>();

    if (audioManager.isPlaying) {
      if (!_rotateController.isAnimating) {
        _rotateController.repeat();
      }
    } else {
      if (_rotateController.isAnimating) {
        _rotateController.stop();
      }
    }

    if (audioManager.status == AudioManagerStatus.error &&
        audioManager.errorMessage != null) {
      AppNotifications.showError(context, audioManager.errorMessage!);
    }
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    context.read<AudioManager>().removeListener(_onAudioManagerChanged);
    _rotateController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _setSleepTimer(int minutes) {
    _sleepTimer?.cancel();
    if (minutes <= 0) {
      setState(() => _sleepMinutesRemaining = 0);
      AppNotifications.showSuccess(context, 'Temporizador cancelado');
      return;
    }

    setState(() => _sleepMinutesRemaining = minutes);
    AppNotifications.showSuccess(
        context, 'Radio se apagará en $minutes minutos');

    _sleepTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _sleepMinutesRemaining--;
        if (_sleepMinutesRemaining <= 0) {
          timer.cancel();
          context.read<AudioManager>().stop();
          AppNotifications.showSuccess(
              context, 'Temporizador completado: Radio apagada');
        }
      });
    });
  }

  void _showSleepTimerSheet(BuildContext context, ThemeData theme, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.darkBg2 : theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final options = [15, 30, 45, 60];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 20,
                      color: isDark ? AppTheme.darkAccent : theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Temporizador de Apagado',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...options.map((m) {
                  final isCurrent = _sleepMinutesRemaining == m;
                  return ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    leading: Icon(
                      Icons.alarm_rounded,
                      color: isCurrent
                          ? (isDark ? AppTheme.darkAccent : theme.colorScheme.primary)
                          : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    title: Text(
                      '$m minutos',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14.5,
                        fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                        color: isCurrent
                            ? (isDark ? AppTheme.darkAccent : theme.colorScheme.primary)
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    trailing: isCurrent
                        ? Icon(
                            Icons.check_circle_rounded,
                            color: isDark
                                ? AppTheme.darkAccent
                                : theme.colorScheme.primary,
                          )
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      _setSleepTimer(m);
                    },
                  );
                }),
                if (_sleepMinutesRemaining > 0)
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    leading: Icon(
                      Icons.timer_off_rounded,
                      color: theme.colorScheme.error,
                    ),
                    title: Text(
                      'Desactivar temporizador',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.error,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _setSleepTimer(0);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _goToNextRadio(RadioProvider provider, AudioManager audioManager, bool next) {
    final radios = provider.radios;
    if (radios.isEmpty) return;

    final currentIndex = radios.indexWhere((r) => r.id == (audioManager.currentRadio?.id ?? widget.radio.id));
    if (currentIndex == -1) return;

    int newIndex = next ? currentIndex + 1 : currentIndex - 1;
    if (newIndex >= radios.length) newIndex = 0;
    if (newIndex < 0) newIndex = radios.length - 1;

    final targetRadio = radios[newIndex];
    audioManager.playRadio(targetRadio);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final audioManager = context.watch<AudioManager>();
    final radioProvider = context.watch<RadioProvider>();

    final activeRadio = audioManager.currentRadio ?? widget.radio;
    final isPlaying = audioManager.isPlaying;
    final isLoading = audioManager.isLoading;
    final isFav = activeRadio.isFavorite;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Dynamic Glowing Radial Background
          _buildGlowingBackground(theme, isDark),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 24,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Top Bar
                        _buildTopBar(context, theme, isDark, activeRadio, isFav, radioProvider),

                        // Center Vinyl Disc & Visualizer
                        _buildCenterDisc(theme, isDark, activeRadio, isPlaying),

                        // Bottom Controls Section
                        _buildControlsSection(
                          context,
                          theme,
                          isDark,
                          activeRadio,
                          audioManager,
                          radioProvider,
                          isPlaying,
                          isLoading,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── Background Glow ───
  Widget _buildGlowingBackground(ThemeData theme, bool isDark) {
    final primaryColor = isDark ? AppTheme.darkAccent : theme.colorScheme.primary;

    return Stack(
      children: [
        Container(color: theme.scaffoldBackgroundColor),
        Positioned(
          top: -100,
          left: -80,
          child: Container(
            width: 360,
            height: 360,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  primaryColor.withValues(alpha: isDark ? 0.16 : 0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -100,
          right: -80,
          child: Container(
            width: 380,
            height: 380,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  primaryColor.withValues(alpha: isDark ? 0.14 : 0.06),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Top Bar ───
  Widget _buildTopBar(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    radio_model.Radio radio,
    bool isFav,
    RadioProvider radioProvider,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Back Button (keeps background radio playing)
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.darkBg2
                    : theme.colorScheme.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : theme.colorScheme.primary.withValues(alpha: 0.12),
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.arrow_back_rounded,
                  size: 20,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),

        // Live Header Badge / Sleep Timer Badge
        Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.darkAccent.withValues(alpha: 0.15)
                    : theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? AppTheme.darkAccent.withValues(alpha: 0.4)
                      : theme.colorScheme.primary.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTheme.darkAccent
                          : theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'EN VIVO',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      color: isDark
                          ? AppTheme.darkAccent
                          : theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            if (_sleepMinutesRemaining > 0) ...[
              const SizedBox(height: 4),
              Text(
                'Apagado en $_sleepMinutesRemaining m',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ],
        ),

        // Actions: Sleep Timer & Favorite
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showSleepTimerSheet(context, theme, isDark),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.darkBg2
                        : theme.colorScheme.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _sleepMinutesRemaining > 0
                          ? (isDark ? AppTheme.darkAccent : theme.colorScheme.primary)
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : theme.colorScheme.primary.withValues(alpha: 0.12)),
                    ),
                  ),
                  child: Icon(
                    Icons.timer_outlined,
                    size: 20,
                    color: _sleepMinutesRemaining > 0
                        ? (isDark ? AppTheme.darkAccent : theme.colorScheme.primary)
                        : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  radioProvider.toggleFavorite(radio);
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.darkBg2
                        : theme.colorScheme.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : theme.colorScheme.primary.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Icon(
                    isFav
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 20,
                    color: isFav
                        ? const Color(0xFFEF4444)
                        : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Vinyl Disc Center ───
  Widget _buildCenterDisc(
    ThemeData theme,
    bool isDark,
    radio_model.Radio radio,
    bool isPlaying,
  ) {
    return Column(
      children: [
        const SizedBox(height: 24),
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final pulseVal = isPlaying ? _pulseController.value * 12 : 0.0;
            return Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? AppTheme.darkAccent : theme.colorScheme.primary)
                        .withValues(alpha: isPlaying ? 0.25 : 0.05),
                    blurRadius: 30 + pulseVal,
                    spreadRadius: 2 + pulseVal * 0.4,
                  ),
                ],
              ),
              child: child,
            );
          },
          child: AnimatedBuilder(
            animation: _rotateController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotateController.value * 2 * math.pi,
                child: child,
              );
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Vinyl Disc Rim
                Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        isDark ? const Color(0xFF1E1E24) : const Color(0xFF333333),
                        isDark ? const Color(0xFF0F0F12) : const Color(0xFF1A1A1A),
                      ],
                    ),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : Colors.black.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                ),

                // Vinyl Grooves
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06),
                      width: 1.5,
                    ),
                  ),
                ),
                Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.04),
                      width: 1.5,
                    ),
                  ),
                ),

                // Center Station Logo
                Hero(
                  tag: 'radio_tile_logo_${radio.id}',
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? AppTheme.darkAccent
                            : theme.colorScheme.primary,
                        width: 2.5,
                      ),
                    ),
                    child: ClipOval(
                      child: radio.logoUrl.isNotEmpty
                          ? CachedNetworkImage(
                              key: ValueKey<String>(radio.logoUrl),
                              cacheManager: ImageCacheHelper.logoCacheManager,
                              imageUrl: radio.logoUrl,
                              fit: BoxFit.cover,
                              memCacheWidth: 260,
                            )
                          : Container(
                              color: isDark ? AppTheme.darkBg2 : Colors.white,
                              child: Icon(
                                Icons.radio_rounded,
                                size: 48,
                                color: isDark
                                    ? AppTheme.darkAccent
                                    : theme.colorScheme.primary,
                              ),
                            ),
                    ),
                  ),
                ),

                // Center Pin Hole
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkBg : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),

        // Station Name & Frequency
        Text(
          radio.name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (radio.frequency.isNotEmpty) ...[
              Text(
                radio.frequency,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppTheme.darkAccent : theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              radio.category ?? 'Radio Online',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // HD Quality Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.high_quality_rounded,
                size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 5),
              Text(
                'STREAMING AAC / MP3 • HD AUDIO',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Controls Section (Volume + Playback) ───
  Widget _buildControlsSection(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    radio_model.Radio radio,
    AudioManager audioManager,
    RadioProvider radioProvider,
    bool isPlaying,
    bool isLoading,
  ) {
    return Column(
      children: [
        const SizedBox(height: 20),

        // Interactive Volume Slider
        StreamBuilder<double>(
          stream: audioManager.volumeStream,
          initialData: audioManager.volume,
          builder: (context, snapshot) {
            final volume = snapshot.data ?? 1.0;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      volume == 0
                          ? Icons.volume_off_rounded
                          : Icons.volume_down_rounded,
                      size: 20,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    onPressed: () {
                      audioManager.setVolume(volume == 0 ? 0.8 : 0.0);
                    },
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 7),
                        overlayShape:
                            const RoundSliderOverlayShape(overlayRadius: 14),
                        activeTrackColor: isDark
                            ? AppTheme.darkAccent
                            : theme.colorScheme.primary,
                        inactiveTrackColor: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.1),
                        thumbColor: isDark
                            ? AppTheme.darkAccent
                            : theme.colorScheme.primary,
                      ),
                      child: Slider(
                        value: volume.clamp(0.0, 1.0),
                        onChanged: (val) => audioManager.setVolume(val),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.volume_up_rounded,
                      size: 20,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    onPressed: () {
                      audioManager.setVolume(1.0);
                    },
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 12),

        // Prev, Play/Pause, Next Controls Row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Previous Station
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  _goToNextRadio(radioProvider, audioManager, false);
                },
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.04),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.skip_previous_rounded,
                    size: 26,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 24),

            // Big Main Play/Pause Button with Glow
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  audioManager.playRadio(radio);
                },
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.darkAccent
                        : theme.colorScheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isDark
                                ? AppTheme.darkAccent
                                : theme.colorScheme.primary)
                            .withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: isLoading
                        ? SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: isDark ? Colors.black : Colors.white,
                            ),
                          )
                        : Icon(
                            isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            size: 38,
                            color: isDark ? Colors.black : Colors.white,
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 24),

            // Next Station
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  _goToNextRadio(radioProvider, audioManager, true);
                },
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.04),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.skip_next_rounded,
                    size: 26,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
