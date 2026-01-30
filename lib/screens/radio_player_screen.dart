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
    // Start playback when entering the screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AudioManager>().play(widget.station);
    });
  }

  @override
  void dispose() {
    // IMPORTANT: Stop the radio when leaving the player as per user request
    // We do this in a microtask or after pop to avoid state issues during build
    super.dispose();
  }

  void _handleBack(BuildContext context) {
    context.read<AudioManager>().stop();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final audioManager = context.watch<AudioManager>();

    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0a),
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
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Opacity(
          opacity: 0.5,
          child: IconButton(
            onPressed: () => _handleBack(context),
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
        Column(
          children: [
            Text(
              'RADIO EN VIVO',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.4),
                letterSpacing: 2.5,
              ),
            ),
          ],
        ),
        Opacity(
          opacity: 0.5,
          child: IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.more_horiz,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        // Squircle-like Logo
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(48),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(48),
              child: CachedNetworkImage(
                imageUrl: widget.station.logoUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Colors.white10),
                errorWidget: (context, url, error) =>
                    const Icon(Icons.radio, size: 80, color: Colors.white24),
              ),
            ),
          ),
        ),
        const SizedBox(height: 48),
        Text(
          widget.station.name,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: -1,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          widget.station.frequency,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Color(0xFF86868b),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildControls(BuildContext context, AudioManager audioManager) {
    return StreamBuilder<PlayerState>(
      stream: audioManager.playerStateStream,
      builder: (context, snapshot) {
        final isPlaying = snapshot.data?.playing ?? false;
        final isLoading =
            snapshot.data?.processingState == ProcessingState.loading;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  final prev = context
                      .read<RadioProvider>()
                      .getPreviousStation(widget.station);
                  if (prev != null) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RadioPlayerScreen(station: prev),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.skip_previous, size: 40),
                color: Colors.white,
              ),
              AppAnimations.scaleIn(
                duration: AppAnimations.fast,
                child: InkWell(
                  onTap: () {
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
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isLoading
                          ? const CircularProgressIndicator(
                              color: Color(0xFF0a0a0a))
                          : Icon(
                              isPlaying ? Icons.pause : Icons.play_arrow,
                              size: 48,
                              color: const Color(0xFF0a0a0a),
                            ),
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  final next = context
                      .read<RadioProvider>()
                      .getNextStation(widget.station);
                  if (next != null) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RadioPlayerScreen(station: next),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.skip_next, size: 40),
                color: Colors.white,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFooter() {
    return Container(
      width: 120,
      height: 6,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
