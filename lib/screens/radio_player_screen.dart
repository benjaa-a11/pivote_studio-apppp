import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:just_audio/just_audio.dart';
import '../models/radio.dart' as model;
import '../providers/audio_manager.dart';
import '../providers/radio_provider.dart';
import '../config/app_animations.dart';

class RadioPlayerScreen extends StatefulWidget {
  final model.Radio station;

  const RadioPlayerScreen({super.key, required this.station});

  @override
  State<RadioPlayerScreen> createState() => _RadioPlayerScreenState();
}

class _RadioPlayerScreenState extends State<RadioPlayerScreen> {
  @override
  void initState() {
    super.initState();
    // Start playback when entering the screen ONLY if it's not already playing this station
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final audioManager = context.read<AudioManager>();
      if (audioManager.currentStation?.id != widget.station.id) {
        audioManager.play(widget.station);
      }
    });
  }

  @override
  void dispose() {
    // ⚠️ CRÍTICO: Detener la radio al salir del player
    // Esto es lo que solicitaste específicamente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final audioManager = context.read<AudioManager>();
      audioManager.stop();
    });
    super.dispose();
  }

  void _handleBack(BuildContext context) {
    // El audio se detendrá automáticamente en dispose()
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final audioManager = context.watch<AudioManager>();
    final theme = Theme.of(context);

    return PopScope(
      // Detener el audio cuando se use el botón de retroceso del sistema
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          audioManager.stop();
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              children: [
                _buildHeader(context),
                const Spacer(),
                _buildMainContent(),
                const Spacer(),
                _buildControls(context, audioManager),
                const SizedBox(height: 48),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Opacity(
          opacity: 0.5,
          child: IconButton(
            onPressed: () => _handleBack(context),
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: theme.colorScheme.onSurface,
              size: 28,
            ),
          ),
        ),
        Column(
          children: [
            Text(
              'RADIO EN VIVO',
              style: theme.textTheme.labelLarge?.copyWith(
                fontSize: 11,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                letterSpacing: 2.5,
              ),
            ),
          ],
        ),
        Opacity(
          opacity: 0.5,
          child: IconButton(
            onPressed: () {
              // Opciones adicionales si las necesitas
            },
            icon: Icon(
              Icons.more_horiz,
              color: theme.colorScheme.onSurface,
              size: 32,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final audioManager = context.watch<AudioManager>();

    return Column(
      children: [
        // Logo con animación sutil cuando está reproduciendo
        AspectRatio(
          aspectRatio: 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(48),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.5)
                      : Colors.black.withValues(alpha: 0.15),
                  blurRadius: audioManager.isPlaying ? 50 : 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(48),
              child: CachedNetworkImage(
                imageUrl: widget.station.logoUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                  child: Icon(
                    Icons.radio,
                    size: 80,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 48),
        Text(
          widget.station.name,
          style: theme.textTheme.displayMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          widget.station.frequency,
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 18,
          ),
          textAlign: TextAlign.center,
        ),
        // Estado de reconexión
        if (audioManager.isReconnecting) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Reconectando...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
        // Indicador de streaming en vivo
        if (audioManager.isPlaying && !audioManager.isReconnecting) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'EN VIVO',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildControls(BuildContext context, AudioManager audioManager) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return StreamBuilder<PlayerState>(
      stream: audioManager.playerStateStream,
      builder: (context, snapshot) {
        final isPlaying = snapshot.data?.playing ?? false;
        final isLoading =
            snapshot.data?.processingState == ProcessingState.loading ||
                snapshot.data?.processingState == ProcessingState.buffering;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Botón anterior
              IconButton(
                onPressed: () {
                  final prev = context
                      .read<RadioProvider>()
                      .getPreviousStation(widget.station);
                  if (prev != null) {
                    final navigator = Navigator.of(context);
                    audioManager.stop().then((_) {
                      if (!mounted) return;
                      navigator.pushReplacement(
                        MaterialPageRoute(
                          builder: (context) =>
                              RadioPlayerScreen(station: prev),
                        ),
                      );
                    });
                  }
                },
                icon: const Icon(Icons.skip_previous, size: 40),
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              // Botón play/pause principal
              AppAnimations.scaleIn(
                duration: AppAnimations.fast,
                child: InkWell(
                  onTap: isLoading
                      ? null
                      : () {
                          if (isPlaying) {
                            audioManager.pause();
                          } else {
                            audioManager.resume();
                          }
                        },
                  borderRadius: BorderRadius.circular(40),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Center(
                      child: isLoading
                          ? CircularProgressIndicator(
                              color: isDark ? Colors.white : Colors.white,
                              strokeWidth: 3,
                            )
                          : Icon(
                              isPlaying ? Icons.pause : Icons.play_arrow,
                              size: 48,
                              color: isDark ? Colors.white : Colors.white,
                            ),
                    ),
                  ),
                ),
              ),
              // Botón siguiente
              IconButton(
                onPressed: () {
                  final next = context
                      .read<RadioProvider>()
                      .getNextStation(widget.station);
                  if (next != null) {
                    final navigator = Navigator.of(context);
                    audioManager.stop().then((_) {
                      if (!mounted) return;
                      navigator.pushReplacement(
                        MaterialPageRoute(
                          builder: (context) =>
                              RadioPlayerScreen(station: next),
                        ),
                      );
                    });
                  }
                },
                icon: const Icon(Icons.skip_next, size: 40),
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFooter() {
    final theme = Theme.of(context);

    return Container(
      width: 120,
      height: 6,
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
