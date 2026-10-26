import 'dart:async';
import 'package:flutter/material.dart';
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
import 'package:pivote/shared/widgets/common/apple_pressable.dart';

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
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  Timer? _sleepTimer;
  int _sleepMinutesRemaining = 0;

  @override
  void initState() {
    super.initState();

    // Pulse controller for live ambient waves
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1400),
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

    if (audioManager.status == AudioManagerStatus.error &&
        audioManager.errorMessage != null) {
      AppNotifications.showError(context, audioManager.errorMessage!);
    }
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    final audioManager = context.read<AudioManager>();
    audioManager.removeListener(_onAudioManagerChanged);
    // Apagar la radio automáticamente al salir de la pantalla
    audioManager.stop();
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

  void _showSleepTimerSheet(
      BuildContext context, ThemeData theme, bool isDark) {
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
                      color: isDark
                          ? AppTheme.darkAccent
                          : theme.colorScheme.primary,
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
                          ? (isDark
                              ? AppTheme.darkAccent
                              : theme.colorScheme.primary)
                          : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    title: Text(
                      '$m minutos',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14.5,
                        fontWeight:
                            isCurrent ? FontWeight.w800 : FontWeight.w600,
                        color: isCurrent
                            ? (isDark
                                ? AppTheme.darkAccent
                                : theme.colorScheme.primary)
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

  void _goToNextRadio(
      RadioProvider provider, AudioManager audioManager, bool next) {
    final radios = provider.radios;
    if (radios.isEmpty) return;

    final currentIndex = radios.indexWhere(
        (r) => r.id == (audioManager.currentRadio?.id ?? widget.radio.id));
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
    final isDark = theme.isDark;
    final audioManager = context.watch<AudioManager>();
    final radioProvider = context.watch<RadioProvider>();

    final activeRadio = audioManager.currentRadio ?? widget.radio;
    final isPlaying = audioManager.isPlaying;
    final isLoading = audioManager.isLoading;
    final isFav = activeRadio.isFavorite;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        // Apagar la radio automáticamente al salir de la pantalla
        audioManager.stop();
      },
      child: Scaffold(
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
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 24,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Top Bar
                          _buildTopBar(context, theme, isDark, activeRadio,
                              isFav, radioProvider, audioManager),

                          // Center Rounded Square Artwork & Station Info
                          _buildCenterArtwork(
                              theme, isDark, activeRadio, isPlaying),

                          // Bottom Controls Section (Prev, Play/Pause, Next)
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
      ),
    );
  }

  // ─── Background Glow ───
  Widget _buildGlowingBackground(ThemeData theme, bool isDark) {
    final primaryColor =
        isDark ? AppTheme.darkAccent : theme.colorScheme.primary;

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
    AudioManager audioManager,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Back Button with ApplePressable
        ApplePressable(
          scaleDownFactor: 0.90,
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            audioManager.stop();
            Navigator.pop(context);
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkBg2 : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
              ),
              boxShadow: AppShadows.appleDepth(context, elevation: 0.5),
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
            ApplePressable(
              scaleDownFactor: 0.90,
              borderRadius: BorderRadius.circular(14),
              onTap: () => _showSleepTimerSheet(context, theme, isDark),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkBg2 : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _sleepMinutesRemaining > 0
                        ? (isDark
                            ? AppTheme.darkAccent
                            : theme.colorScheme.primary)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.06)),
                  ),
                  boxShadow: AppShadows.appleDepth(context, elevation: 0.5),
                ),
                child: Icon(
                  Icons.timer_outlined,
                  size: 20,
                  color: _sleepMinutesRemaining > 0
                      ? (isDark
                          ? AppTheme.darkAccent
                          : theme.colorScheme.primary)
                      : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ApplePressable(
              scaleDownFactor: 0.90,
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                radioProvider.toggleFavorite(radio);
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkBg2 : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
                  ),
                  boxShadow: AppShadows.appleDepth(context, elevation: 0.5),
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
          ],
        ),
      ],
    );
  }

  // ─── Center Square Artwork (No Rotation, Rounded Corners) ───
  Widget _buildCenterArtwork(
    ThemeData theme,
    bool isDark,
    radio_model.Radio radio,
    bool isPlaying,
  ) {
    final primaryColor =
        isDark ? AppTheme.darkAccent : theme.colorScheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final pulseVal = isPlaying ? _pulseController.value * 8 : 0.0;
            return Container(
              width: 230,
              height: 230,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color:
                        primaryColor.withValues(alpha: isPlaying ? 0.28 : 0.06),
                    blurRadius: 26 + pulseVal,
                    spreadRadius: 1 + pulseVal * 0.3,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: child,
            );
          },
          child: Container(
            width: 230,
            height: 230,
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkBg2 : Colors.white,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : primaryColor.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Hero(
                tag: 'radio_tile_logo_${radio.id}',
                child: radio.logoUrl.isNotEmpty
                    ? CachedNetworkImage(
                        key: ValueKey<String>(radio.logoUrl),
                        cacheManager: ImageCacheHelper.logoCacheManager,
                        imageUrl: radio.logoUrl,
                        fit: BoxFit.cover,
                        memCacheWidth: 460,
                        placeholder: (context, url) => Container(
                          color:
                              isDark ? AppTheme.darkBg2 : Colors.grey.shade100,
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: primaryColor,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color:
                              isDark ? AppTheme.darkBg2 : Colors.grey.shade100,
                          child: Icon(
                            Icons.radio_rounded,
                            size: 64,
                            color: primaryColor,
                          ),
                        ),
                      )
                    : Container(
                        color: isDark ? AppTheme.darkBg2 : Colors.grey.shade100,
                        child: Icon(
                          Icons.radio_rounded,
                          size: 64,
                          color: primaryColor,
                        ),
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Station Name & Frequency
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
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
                  color:
                      isDark ? AppTheme.darkAccent : theme.colorScheme.primary,
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
      ],
    );
  }

  // ─── Controls Section (Cohesive Buttons: Prev, Play/Pause, Next) ───
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
    final primaryColor =
        isDark ? AppTheme.darkAccent : theme.colorScheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Previous Station with ApplePressable
            ApplePressable(
              scaleDownFactor: 0.90,
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                _goToNextRadio(radioProvider, audioManager, false);
              },
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkBg2 : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
                    width: 1.2,
                  ),
                  boxShadow: AppShadows.appleDepth(context, elevation: 0.6),
                ),
                child: Center(
                  child: Icon(
                    Icons.skip_previous_rounded,
                    size: 28,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),

            // Main Play/Pause Button with ApplePressable
            ApplePressable(
              scaleDownFactor: 0.92,
              borderRadius: BorderRadius.circular(22),
              onTap: () {
                audioManager.playRadio(radio);
              },
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.38),
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
            const SizedBox(width: 20),

            // Next Station with ApplePressable
            ApplePressable(
              scaleDownFactor: 0.90,
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                _goToNextRadio(radioProvider, audioManager, true);
              },
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkBg2 : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
                    width: 1.2,
                  ),
                  boxShadow: AppShadows.appleDepth(context, elevation: 0.6),
                ),
                child: Center(
                  child: Icon(
                    Icons.skip_next_rounded,
                    size: 28,
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
