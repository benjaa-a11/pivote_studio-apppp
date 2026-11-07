import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pivote/core/services/app_activity_service.dart';
import 'package:pivote/core/services/image_cache_helper.dart';
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
  Timer? _sleepTimer;
  int _sleepMinutesRemaining = 0;

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
    _sleepTimer?.cancel();
    final audioManager = context.read<AudioManager>();
    audioManager.removeListener(_onAudioManagerChanged);
    audioManager.stop();
    super.dispose();
  }

  void _setSleepTimer(int minutes) {
    _sleepTimer?.cancel();
    if (minutes <= 0) {
      setState(() => _sleepMinutesRemaining = 0);
      AppNotifications.showInfo(context, 'Temporizador desactivado');
      return;
    }

    setState(() => _sleepMinutesRemaining = minutes);
    AppNotifications.showSuccess(
      context,
      'La radio se apagará en $minutes minutos',
    );

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
            context,
            'Temporizador completado: radio apagada',
          );
        }
      });
    });
  }

  void _showSleepTimerSheet(BuildContext context, ProfilePalette palette) {
    final options = [15, 30, 45, 60];
    showModalBottomSheet(
      context: context,
      backgroundColor: palette.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Temporizador de apagado',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: palette.text,
                  ),
                ),
                const SizedBox(height: 14),
                ProfileGroupCard(
                  children: [
                    for (final m in options)
                      ProfileGroupRow(
                        title: '$m minutos',
                        valueText: _sleepMinutesRemaining == m ? 'Activo' : null,
                        onTap: () {
                          Navigator.pop(sheetCtx);
                          _setSleepTimer(m);
                        },
                      ),
                    if (_sleepMinutesRemaining > 0)
                      ProfileGroupRow(
                        title: 'Desactivar temporizador',
                        isDanger: true,
                        onTap: () {
                          Navigator.pop(sheetCtx);
                          _setSleepTimer(0);
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
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
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

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
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: ListView(
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                10,
                topPad + 10,
                10,
                math.max(24, bottomPad + 22),
              ),
              children: [
                // ---------- Header (.hdr) ----------
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
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: palette.card,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: palette.border,
                          width: 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        isFav
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 19,
                        color: isFav ? const Color(0xFFEF4444) : palette.text,
                      ),
                    ),
                  ),
                ),

                // ---------- Tarjeta Principal de Emisora ----------
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  decoration: BoxDecoration(
                    color: palette.card,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: palette.border, width: 1),
                    boxShadow: palette.cardShadow,
                  ),
                  child: Column(
                    children: [
                      // Artwork frame
                      Container(
                        width: 210,
                        height: 210,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: palette.iconBox,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: palette.border, width: 1),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Hero(
                            tag: 'radio_tile_logo_${activeRadio.id}',
                            child: activeRadio.logoUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    key: ValueKey<String>(activeRadio.logoUrl),
                                    cacheManager:
                                        ImageCacheHelper.logoCacheManager,
                                    imageUrl: activeRadio.logoUrl,
                                    fit: BoxFit.cover,
                                    memCacheWidth: 420,
                                    placeholder: (context, url) => Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        color: palette.muted,
                                      ),
                                    ),
                                    errorWidget: (context, url, error) => Icon(
                                      Icons.radio_rounded,
                                      size: 56,
                                      color: palette.muted,
                                    ),
                                  )
                                : Icon(
                                    Icons.radio_rounded,
                                    size: 56,
                                    color: palette.muted,
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Station Name
                      Text(
                        activeRadio.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.4,
                          color: palette.text,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Live + Frequency Pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: palette.iconBox,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: palette.border, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isPlaying
                                    ? const Color(0xFF3FD1A0)
                                    : palette.muted,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 7),
                            Text(
                              [
                                isPlaying ? 'En vivo' : 'En pausa',
                                if (activeRadio.frequency.isNotEmpty)
                                  activeRadio.frequency,
                                if ((activeRadio.category ?? '').isNotEmpty)
                                  activeRadio.category!,
                              ].join(' · '),
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: palette.text,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Playback Controls (Previous, Play/Pause, Next)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _PlayerCircleButton(
                            size: 52,
                            icon: Icons.skip_previous_rounded,
                            iconSize: 26,
                            palette: palette,
                            onTap: () => _goToNextRadio(
                              radioProvider,
                              audioManager,
                              false,
                            ),
                          ),
                          const SizedBox(width: 18),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              audioManager.playRadio(activeRadio);
                            },
                            child: Container(
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                color: palette.primaryBtnBg,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: isLoading
                                  ? SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: palette.primaryBtnText,
                                      ),
                                    )
                                  : Icon(
                                      isPlaying
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                      size: 34,
                                      color: palette.primaryBtnText,
                                    ),
                            ),
                          ),
                          const SizedBox(width: 18),
                          _PlayerCircleButton(
                            size: 52,
                            icon: Icons.skip_next_rounded,
                            iconSize: 26,
                            palette: palette,
                            onTap: () => _goToNextRadio(
                              radioProvider,
                              audioManager,
                              true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ---------- Opciones de reproducción ----------
                const ProfileSectionTitle('Opciones'),
                ProfileGroupCard(
                  children: [
                    ProfileGroupRow(
                      title: 'Temporizador de apagado',
                      subtitle: _sleepMinutesRemaining > 0
                          ? 'Se apagará automáticamente en $_sleepMinutesRemaining min'
                          : 'Apagar la radio automáticamente',
                      valueText: _sleepMinutesRemaining > 0
                          ? '$_sleepMinutesRemaining min'
                          : 'Desactivado',
                      showChevron: true,
                      onTap: () => _showSleepTimerSheet(context, palette),
                    ),
                    ProfileGroupRow(
                      title: 'Emisora favorita',
                      subtitle: 'Acceso rápido desde Favoritos y Radio',
                      onTap: () => radioProvider.toggleFavorite(activeRadio),
                      trailing: ProfileSwitch(
                        value: isFav,
                        onChanged: (_) =>
                            radioProvider.toggleFavorite(activeRadio),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: palette.iconBox,
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
    );
  }
}
