import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pivote/core/services/app_activity_service.dart';
import 'package:pivote/core/services/image_cache_helper.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/features/profile/presentation/widgets/profile_design_system.dart';
import 'package:pivote/features/radio/data/models/radio.dart' as radio_model;
import 'package:pivote/features/radio/presentation/providers/audio_manager.dart';
import 'package:pivote/features/radio/presentation/providers/radio_provider.dart';
import 'package:pivote/shared/widgets/app_notifications.dart';

class RadioPlayerScreen extends StatefulWidget {
  final radio_model.Radio radio;

  const RadioPlayerScreen({
    super.key,
    required this.radio,
  });

  @override
  State<RadioPlayerScreen> createState() => _RadioPlayerScreenState();
}

class _RadioPlayerScreenState extends State<RadioPlayerScreen> {
  @override
  void initState() {
    super.initState();

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
    final audioManager = context.read<AudioManager>();
    audioManager.removeListener(_onAudioManagerChanged);
    audioManager.stop();
    super.dispose();
  }

  void _goToNextRadio(
    RadioProvider provider,
    AudioManager audioManager,
    bool next,
  ) {
    final radios = provider.radios;
    if (radios.isEmpty) return;

    final currentIndex = radios.indexWhere(
      (r) => r.id == (audioManager.currentRadio?.id ?? widget.radio.id),
    );
    if (currentIndex == -1) return;

    int newIndex = next ? currentIndex + 1 : currentIndex - 1;
    if (newIndex >= radios.length) newIndex = 0;
    if (newIndex < 0) newIndex = radios.length - 1;

    HapticFeedback.selectionClick();
    audioManager.playRadio(radios[newIndex]);
  }


  @override
  Widget build(BuildContext context) {
    final palette = ProfilePalette.of(context);
    final audioManager = context.watch<AudioManager>();
    final radioProvider = context.watch<RadioProvider>();
    final hPad = AppResponsive.screenHorizontalPadding(context);

    final activeRadio = audioManager.currentRadio ?? widget.radio;
    final isPlaying = audioManager.isPlaying;
    final isLoading = audioManager.isLoading;
    final isFav = activeRadio.isFavorite;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        audioManager.stop();
      },
      child: Scaffold(
        backgroundColor: palette.bg,
        body: Stack(
          children: [
            // Resplandor ambiental lima (CSS: radial-gradient del body)
            if (palette.isDark)
              Positioned(
                top: -140,
                left: 0,
                right: 0,
                height: 460,
                child: IgnorePointer(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0.6, -0.3),
                        radius: 0.95,
                        colors: [
                          AppColors.accent
                              .withValues(alpha: isPlaying ? 0.14 : 0.07),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Padding(
                    padding: hPad.add(const EdgeInsets.only(top: 10, bottom: 20)),
                    child: Column(
                      children: [
                        ProfileSubHeader(
                          title: 'Radio en vivo',
                          onBack: () {
                            audioManager.stop();
                            Navigator.pop(context);
                          },
                          trailing: _FavButton(
                            isFav: isFav,
                            palette: palette,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              radioProvider.toggleFavorite(activeRadio);
                            },
                          ),
                        ),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, c) {
                              final logoSize = math
                                  .min(c.maxWidth * 0.78, c.maxHeight * 0.42)
                                  .clamp(150.0, 320.0);
                              return SingleChildScrollView(
                                physics: const ClampingScrollPhysics(),
                                child: ConstrainedBox(
                                  constraints:
                                      BoxConstraints(minHeight: c.maxHeight),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      const SizedBox(height: 16),
                                      _Artwork(
                                        radio: activeRadio,
                                        size: logoSize,
                                        isPlaying: isPlaying,
                                        palette: palette,
                                      ),
                                      const SizedBox(height: 28),
                                      _StatusChip(
                                        isPlaying: isPlaying,
                                        isLoading: isLoading,
                                        palette: palette,
                                      ),
                                      const SizedBox(height: 14),
                                      Text(
                                        activeRadio.name,
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppFont.primary(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -0.7,
                                          height: 1.15,
                                          color: palette.text,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Wrap(
                                        alignment: WrapAlignment.center,
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          if (activeRadio.frequency.isNotEmpty)
                                            _MetaTag(
                                              text: activeRadio.frequency,
                                              mono: true,
                                              highlight: true,
                                              palette: palette,
                                            ),
                                          if ((activeRadio.category ?? '')
                                              .isNotEmpty)
                                            _MetaTag(
                                              text: activeRadio.category!,
                                              palette: palette,
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 28),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        _ControlDock(
                          palette: palette,
                          isPlaying: isPlaying,
                          isLoading: isLoading,
                          onPrev: () =>
                              _goToNextRadio(radioProvider, audioManager, false),
                          onNext: () =>
                              _goToNextRadio(radioProvider, audioManager, true),
                          onToggle: () {
                            HapticFeedback.mediumImpact();
                            audioManager.playRadio(activeRadio);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavButton extends StatelessWidget {
  final bool isFav;
  final ProfilePalette palette;
  final VoidCallback onTap;

  const _FavButton({
    required this.isFav,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isFav ? AppColors.live.withValues(alpha: 0.14) : palette.card,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isFav
                ? AppColors.live.withValues(alpha: 0.40)
                : palette.border,
          ),
        ),
        alignment: Alignment.center,
        child: Icon(
          isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          size: 20,
          color: isFav ? AppColors.live : palette.text,
        ),
      ),
    );
  }
}

class _Artwork extends StatelessWidget {
  final radio_model.Radio radio;
  final double size;
  final bool isPlaying;
  final ProfilePalette palette;

  const _Artwork({
    required this.radio,
    required this.size,
    required this.isPlaying,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final pad = size * 0.06;
    Widget fallback() =>
        Icon(Icons.radio_rounded, size: size * 0.28, color: palette.muted);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      width: size,
      height: size,
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(
          color: isPlaying
              ? palette.accent.withValues(alpha: 0.45)
              : palette.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: palette.isDark ? 0.45 : 0.08),
            blurRadius: 32,
            spreadRadius: -8,
            offset: const Offset(0, 16),
          ),
          if (isPlaying && palette.isDark)
            BoxShadow(
              color: palette.accent.withValues(alpha: 0.12),
              blurRadius: 40,
              spreadRadius: -10,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xxl - pad),
        child: Hero(
          tag: 'radio_tile_logo_${radio.id}',
          child: radio.logoUrl.isNotEmpty
              ? CachedNetworkImage(
                  key: ValueKey<String>(radio.logoUrl),
                  cacheManager: ImageCacheHelper.logoCacheManager,
                  imageUrl: radio.logoUrl,
                  fit: BoxFit.cover,
                  memCacheWidth: 640,
                  fadeInDuration: const Duration(milliseconds: 180),
                  placeholder: (context, url) =>
                      ColoredBox(color: palette.iconBox),
                  errorWidget: (context, url, error) => fallback(),
                )
              : fallback(),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isPlaying;
  final bool isLoading;
  final ProfilePalette palette;

  const _StatusChip({
    required this.isPlaying,
    required this.isLoading,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final live = isPlaying && !isLoading;
    final label = isLoading
        ? 'CONECTANDO'
        : isPlaying
            ? 'EN VIVO'
            : 'EN PAUSA';
    final color = live
        ? (palette.isDark ? AppColors.liveTint : AppColors.live)
        : palette.muted;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: live ? AppColors.live.withValues(alpha: 0.14) : palette.card,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color:
              live ? AppColors.live.withValues(alpha: 0.35) : palette.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: live ? AppColors.live : palette.muted,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppFont.primary(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.9,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaTag extends StatelessWidget {
  final String text;
  final bool mono;
  final bool highlight;
  final ProfilePalette palette;

  const _MetaTag({
    required this.text,
    required this.palette,
    this.mono = false,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: highlight ? AppColors.accentBg : palette.card,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: highlight
              ? palette.accent.withValues(alpha: 0.30)
              : palette.border,
        ),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: (mono
                ? const TextStyle(fontFamily: 'monospace')
                : const TextStyle())
            .merge(
          AppFont.primary(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: highlight && palette.isDark ? palette.accent : palette.muted,
          ),
        ),
      ),
    );
  }
}

/// Panel inferior con los controles: contenedor redondeado, botones
/// cuadrados con esquinas suaves y play/pause en lima sólido.
class _ControlDock extends StatelessWidget {
  final ProfilePalette palette;
  final bool isPlaying;
  final bool isLoading;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onToggle;

  const _ControlDock({
    required this.palette,
    required this.isPlaying,
    required this.isLoading,
    required this.onPrev,
    required this.onNext,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: palette.border),
        boxShadow: palette.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: _SideButton(
              icon: Icons.skip_previous_rounded,
              label: 'Anterior',
              palette: palette,
              onTap: onPrev,
            ),
          ),
          const SizedBox(width: 12),
          _PlayButton(
            palette: palette,
            isPlaying: isPlaying,
            isLoading: isLoading,
            onTap: onToggle,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SideButton(
              icon: Icons.skip_next_rounded,
              label: 'Siguiente',
              palette: palette,
              onTap: onNext,
            ),
          ),
        ],
      ),
    );
  }
}

class _SideButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final ProfilePalette palette;
  final VoidCallback onTap;

  const _SideButton({
    required this.icon,
    required this.label,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: palette.iconBox,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: palette.border),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 30, color: palette.text),
          ),
        ),
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  final ProfilePalette palette;
  final bool isPlaying;
  final bool isLoading;
  final VoidCallback onTap;

  const _PlayButton({
    required this.palette,
    required this.isPlaying,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: isPlaying ? 'Pausar' : 'Reproducir',
      child: Material(
        color: palette.primaryBtnBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: SizedBox(
            width: 84,
            height: 64,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                child: isLoading
                    ? SizedBox(
                        key: const ValueKey('loading'),
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.6,
                          color: palette.primaryBtnText,
                        ),
                      )
                    : Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        key: ValueKey(isPlaying),
                        size: 36,
                        color: palette.primaryBtnText,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
