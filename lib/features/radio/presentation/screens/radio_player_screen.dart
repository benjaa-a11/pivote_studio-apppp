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
import 'package:pivote/shared/widgets/common/pivote_loader.dart';

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

    final subtitleParts = <String>[
      if (activeRadio.frequency.isNotEmpty) activeRadio.frequency,
      if ((activeRadio.category ?? '').isNotEmpty) activeRadio.category!,
    ];

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        audioManager.stop();
      },
      child: Scaffold(
        backgroundColor: palette.bg,
        body: Stack(
          children: [
            // Sutil resplandor ambiental de fondo (estilo CSS --acc mesh)
            if (palette.isDark)
              Positioned(
                top: -120,
                left: 0,
                right: 0,
                height: 420,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.2),
                        radius: 0.9,
                        colors: [
                          AppColors.accent
                              .withValues(alpha: isPlaying ? 0.22 : 0.12),
                          AppColors.violet.withValues(alpha: 0.06),
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
                    padding: hPad.add(const EdgeInsets.only(top: 10, bottom: 24)),
                    child: Column(
                      children: [
                        // Barra superior con botón volver y corazón arriba a la derecha
                        ProfileSubHeader(
                          title: 'Radio en vivo',
                          onBack: () {
                            audioManager.stop();
                            Navigator.pop(context);
                          },
                          trailing: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              radioProvider.toggleFavorite(activeRadio);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: isFav
                                    ? AppColors.live.withValues(alpha: 0.14)
                                    : palette.card,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.sm),
                                border: Border.all(
                                  color: isFav
                                      ? AppColors.live.withValues(alpha: 0.40)
                                      : palette.border,
                                  width: 1,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                isFav
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                size: 20,
                                color: isFav ? AppColors.live : palette.text,
                              ),
                            ),
                          ),
                        ),

                        const Spacer(flex: 2),

                        // Carátula de la emisora
                        Container(
                          width: 224,
                          height: 224,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: palette.card,
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(color: palette.border, width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: palette.isDark ? 0.50 : 0.08,
                                ),
                                blurRadius: 36,
                                spreadRadius: -8,
                                offset: const Offset(0, 18),
                              ),
                              if (isPlaying)
                                BoxShadow(
                                  color: palette.accent.withValues(alpha: 0.18),
                                  blurRadius: 42,
                                  spreadRadius: -10,
                                  offset: const Offset(0, 12),
                                ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: Hero(
                              tag: 'radio_tile_logo_${activeRadio.id}',
                              child: activeRadio.logoUrl.isNotEmpty
                                  ? CachedNetworkImage(
                                      key: ValueKey<String>(activeRadio.logoUrl),
                                      cacheManager:
                                          ImageCacheHelper.logoCacheManager,
                                      imageUrl: activeRadio.logoUrl,
                                      fit: BoxFit.cover,
                                      memCacheWidth: 460,
                                      placeholder: (context, url) => Center(
                                        child: PivoteLoader(
                                          size: 26,
                                          strokeWidth: 2.4,
                                          color: palette.muted,
                                        ),
                                      ),
                                      errorWidget: (context, url, error) => Icon(
                                        Icons.radio_rounded,
                                        size: 64,
                                        color: palette.muted,
                                      ),
                                    )
                                  : Icon(
                                      Icons.radio_rounded,
                                      size: 64,
                                      color: palette.muted,
                                    ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Estado EN VIVO / EN PAUSA
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isPlaying
                                ? AppColors.live.withValues(alpha: 0.14)
                                : palette.card,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(
                              color: isPlaying
                                  ? AppColors.live.withValues(alpha: 0.35)
                                  : palette.border,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: isPlaying
                                      ? AppColors.live
                                      : palette.muted,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 7),
                              Text(
                                isPlaying ? 'EN VIVO' : 'EN PAUSA',
                                style: AppFont.primary(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: isPlaying
                                      ? (palette.isDark
                                          ? AppColors.liveTint
                                          : AppColors.live)
                                      : palette.muted,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Nombre de la emisora
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            activeRadio.name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppFont.primary(
                              fontSize: 25,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6,
                              height: 1.18,
                              color: palette.text,
                            ),
                          ),
                        ),

                        if (subtitleParts.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            subtitleParts.join(' · '),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppFont.primary(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: palette.muted,
                            ),
                          ),
                        ],

                        const Spacer(flex: 2),

                        // Controles de reproducción limpios
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _PlayerCircleButton(
                              size: 56,
                              icon: Icons.skip_previous_rounded,
                              iconSize: 28,
                              palette: palette,
                              onTap: () => _goToNextRadio(
                                radioProvider,
                                audioManager,
                                false,
                              ),
                            ),
                            const SizedBox(width: 24),
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                audioManager.playRadio(activeRadio);
                              },
                              child: Container(
                                width: 76,
                                height: 76,
                                decoration: BoxDecoration(
                                  gradient: AppGradients.buttonPrimary,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: palette.accent
                                          .withValues(alpha: 0.45),
                                      blurRadius: 26,
                                      spreadRadius: -2,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: isLoading
                                    ? const PivoteLoader(
                                        size: 26,
                                        strokeWidth: 2.6,
                                        color: Colors.white,
                                      )
                                    : Icon(
                                        isPlaying
                                            ? Icons.pause_rounded
                                            : Icons.play_arrow_rounded,
                                        size: 38,
                                        color: Colors.white,
                                      ),
                              ),
                            ),
                            const SizedBox(width: 24),
                            _PlayerCircleButton(
                              size: 56,
                              icon: Icons.skip_next_rounded,
                              iconSize: 28,
                              palette: palette,
                              onTap: () => _goToNextRadio(
                                radioProvider,
                                audioManager,
                                true,
                              ),
                            ),
                          ],
                        ),

                        const Spacer(flex: 3),
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

class _PlayerCircleButton extends StatelessWidget {
  final double size;
  final IconData icon;
  final double iconSize;
  final ProfilePalette palette;
  final VoidCallback onTap;

  const _PlayerCircleButton({
    required this.size,
    required this.icon,
    required this.iconSize,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: palette.card,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: palette.border, width: 1),
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: iconSize,
            color: palette.text,
          ),
        ),
      ),
    );
  }
}
