import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pivote/core/services/app_activity_service.dart';
import 'package:pivote/core/services/image_cache_helper.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/features/radio/data/models/radio.dart' as radio_model;
import 'package:pivote/features/radio/presentation/providers/audio_manager.dart';
import 'package:pivote/features/radio/presentation/providers/radio_provider.dart';
import 'package:pivote/shared/widgets/app_notifications.dart';
import 'package:pivote/shared/widgets/common/apple_pressable.dart';
import 'package:pivote/shared/widgets/common/loading_shimmer.dart';
import 'package:pivote/shared/widgets/common/pivote_loader.dart';
import 'package:pivote/shared/widgets/common/pivote_surfaces.dart';

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

    context.read<AudioManager>().addListener(_onAudioManagerChanged);
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
        backgroundColor: AppTheme.bg(context),
        body: PivoteAmbientBackdrop(
          intensity: isPlaying ? 1.55 : 0.9,
          child: SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Padding(
                  padding: hPad.add(const EdgeInsets.only(top: 6, bottom: 20)),
                  child: Column(
                    children: [
                      PivoteSubHeader(
                        title: 'Radio en vivo',
                        onBack: () {
                          audioManager.stop();
                          Navigator.pop(context);
                        },
                        trailing: PivoteIconButton(
                          icon: isFav
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          danger: isFav,
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
                                .min(c.maxWidth * 0.74, c.maxHeight * 0.42)
                                .clamp(150.0, 300.0);
                            return SingleChildScrollView(
                              physics: const ClampingScrollPhysics(),
                              child: ConstrainedBox(
                                constraints:
                                    BoxConstraints(minHeight: c.maxHeight),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(height: 12),
                                    _RadioArtwork(
                                      radio: activeRadio,
                                      size: logoSize,
                                      isPlaying: isPlaying,
                                    ),
                                    const SizedBox(height: 26),
                                    _RadioStatusChip(
                                      isPlaying: isPlaying,
                                      isLoading: isLoading,
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      activeRadio.name,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppFont.primary(
                                        fontSize: 25,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.65,
                                        height: 1.15,
                                        color: AppTheme.textPrimary(context),
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
                                          ),
                                        if ((activeRadio.category ?? '')
                                            .isNotEmpty)
                                          _MetaTag(text: activeRadio.category!),
                                      ],
                                    ),
                                    const SizedBox(height: 24),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      _RadioControlDock(
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
        ),
      ),
    );
  }
}

class _RadioArtwork extends StatelessWidget {
  final radio_model.Radio radio;
  final double size;
  final bool isPlaying;

  const _RadioArtwork({
    required this.radio,
    required this.size,
    required this.isPlaying,
  });

  @override
  Widget build(BuildContext context) {
    final pad = size * 0.065;
    final accent = AppTheme.accent(context);

    Widget fallback() => Icon(
          Icons.radio_rounded,
          size: size * 0.28,
          color: AppTheme.textTertiary(context),
        );

    return SizedBox(
      width: size,
      height: size,
      child: PivoteDiffusedCard(
        borderRadius: AppRadius.xxl,
        glowColor: accent,
        secondaryGlowColor: isPlaying ? AppTheme.danger(context) : null,
        glowAlignment: const Alignment(-0.8, -0.8),
        secondaryGlowAlignment: const Alignment(0.8, 0.8),
        glowOpacity: isPlaying ? 1.55 : 0.85,
        highlighted: isPlaying,
        padding: EdgeInsets.all(pad),
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
                    placeholder: (_, __) => PivoteShimmer(
                      child: PivoteShimmerBone(
                        width: size,
                        height: size,
                        borderRadius: AppRadius.xl,
                      ),
                    ),
                    errorWidget: (_, __, ___) => fallback(),
                  )
                : fallback(),
          ),
        ),
      ),
    );
  }
}

class _RadioStatusChip extends StatelessWidget {
  final bool isPlaying;
  final bool isLoading;

  const _RadioStatusChip({
    required this.isPlaying,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final live = isPlaying && !isLoading;
    final danger = AppTheme.danger(context);
    final label = isLoading
        ? 'CONECTANDO'
        : isPlaying
            ? 'EN VIVO'
            : 'EN PAUSA';

    return AnimatedContainer(
      duration: AppMotion.fast,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: live ? AppTheme.dangerDim(context) : AppTheme.surface1(context),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: live ? danger.withValues(alpha: 0.36) : AppTheme.border(context),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: live ? danger : AppTheme.textTertiary(context),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: AppFont.mono(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
              color: live ? danger : AppTheme.textTertiary(context),
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

  const _MetaTag({
    required this.text,
    this.mono = false,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.accent(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: highlight
            ? AppTheme.accentDim(context)
            : AppTheme.surface1(context),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: highlight
              ? accent.withValues(alpha: 0.34)
              : AppTheme.border(context),
        ),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: mono
            ? AppFont.mono(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: highlight ? accent : AppTheme.textSecondary(context),
              )
            : AppFont.primary(
                fontSize: 12.8,
                fontWeight: FontWeight.w600,
                color: highlight ? accent : AppTheme.textSecondary(context),
              ),
      ),
    );
  }
}

class _RadioControlDock extends StatelessWidget {
  final bool isPlaying;
  final bool isLoading;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onToggle;

  const _RadioControlDock({
    required this.isPlaying,
    required this.isLoading,
    required this.onPrev,
    required this.onNext,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.accent(context);
    final onAccent = AppTheme.onAccent(context);

    return PivoteGlassSurface(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Expanded(
            child: ApplePressable(
              scaleDownFactor: 0.95,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              onTap: onPrev,
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.surface2(context),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppTheme.border(context)),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.skip_previous_rounded,
                  size: 28,
                  color: AppTheme.textPrimary(context),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          ApplePressable(
            scaleDownFactor: 0.94,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            onTap: isLoading ? null : onToggle,
            child: Container(
              width: 86,
              height: 60,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: AppShadows.glow(accent, alpha: 0.30),
              ),
              alignment: Alignment.center,
              child: AnimatedSwitcher(
                duration: AppMotion.fast,
                child: isLoading
                    ? PivoteLoader(
                        key: const ValueKey('loading'),
                        size: 22,
                        strokeWidth: 2.5,
                        color: onAccent,
                      )
                    : Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        key: ValueKey(isPlaying),
                        size: 34,
                        color: onAccent,
                      ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ApplePressable(
              scaleDownFactor: 0.95,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              onTap: onNext,
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.surface2(context),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppTheme.border(context)),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.skip_next_rounded,
                  size: 28,
                  color: AppTheme.textPrimary(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
