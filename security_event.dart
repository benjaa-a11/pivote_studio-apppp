import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:media_kit/media_kit.dart';
import 'package:pivote/core/theme/app_theme.dart';


// Helper function to build custom bottom sheet base
Widget _buildSheetWrapper({
  required BuildContext context,
  required String title,
  required Widget child,
}) {
  return Container(
    decoration: const BoxDecoration(
      color: AppTheme.darkBg2,
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
    child: SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    ),
  );
}

class SpeedSelectorSheet extends StatelessWidget {
  final double currentSpeed;
  final ValueChanged<double> onSpeedSelected;

  const SpeedSelectorSheet({
    super.key,
    required this.currentSpeed,
    required this.onSpeedSelected,
  });

  static const List<double> _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  Widget build(BuildContext context) {
    return _buildSheetWrapper(
      context: context,
      title: 'Velocidad de Reproducción',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: _speeds.map((speed) {
          final isSelected = speed == currentSpeed;
          return ChoiceChip(
            label: Text(
              speed == 1.0 ? 'Normal' : '${speed}x',
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.black : Colors.white70,
              ),
            ),
            selected: isSelected,
            selectedColor: AppTheme.darkAccent,
            backgroundColor: AppTheme.darkBg3,
            onSelected: (selected) {
              if (selected) {
                onSpeedSelected(speed);
                Navigator.pop(context);
              }
            },
            showCheckmark: false,
            side: BorderSide(
              color: isSelected ? AppTheme.darkAccent : AppTheme.darkBorder,
              width: 1.5,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          );
        }).toList(),
      ),
    );
  }
}

class SubtitleSelectorSheet extends StatelessWidget {
  final Tracks tracks;
  final SubtitleTrack selectedTrack;
  final ValueChanged<SubtitleTrack> onTrackSelected;

  const SubtitleSelectorSheet({
    super.key,
    required this.tracks,
    required this.selectedTrack,
    required this.onTrackSelected,
  });

  @override
  Widget build(BuildContext context) {
    final subTracks = tracks.subtitle;
    
    // We add an option for "No Subtitles"

    return _buildSheetWrapper(
      context: context,
      title: 'Subtítulos',
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.45,
        ),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: subTracks.length + 1,
          itemBuilder: (context, index) {
            final isNone = index == 0;
            final track = isNone ? SubtitleTrack.no() : subTracks[index - 1];
            
            // Check if selected
            bool isSelected;
            if (isNone) {
              isSelected = selectedTrack.id == 'no';
            } else {
              isSelected = selectedTrack.id == track.id;
            }

            String title = isNone ? 'Desactivados' : (track.title ?? track.language ?? 'Subtítulo $index');
            if (track.language != null && track.title != null) {
              title = '${track.title} [${track.language!.toUpperCase()}]';
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                  color: isSelected ? AppTheme.darkAccent.withValues(alpha: 0.5) : AppTheme.darkBorder,
                    width: 1.5,
                  ),
                ),
                tileColor: isSelected ? AppTheme.darkAccent.withValues(alpha: 0.1) : AppTheme.darkBg3,
                title: Text(
                  title,
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppTheme.darkAccent : Colors.white,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle_rounded, color: AppTheme.darkAccent)
                    : null,
                onTap: () {
                  onTrackSelected(track);
                  Navigator.pop(context);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class AudioTrackSelectorSheet extends StatelessWidget {
  final Tracks tracks;
  final AudioTrack selectedTrack;
  final ValueChanged<AudioTrack> onTrackSelected;

  const AudioTrackSelectorSheet({
    super.key,
    required this.tracks,
    required this.selectedTrack,
    required this.onTrackSelected,
  });

  @override
  Widget build(BuildContext context) {
    final audioTracks = tracks.audio;

    return _buildSheetWrapper(
      context: context,
      title: 'Idioma / Pista de Audio',
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.45,
        ),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: audioTracks.length,
          itemBuilder: (context, index) {
            final track = audioTracks[index];
            final isSelected = selectedTrack.id == track.id;

            String title = track.title ?? track.language ?? 'Pista de Audio ${index + 1}';
            if (track.language != null && track.title != null) {
              title = '${track.title} [${track.language!.toUpperCase()}]';
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected ? AppTheme.darkAccent.withValues(alpha: 0.5) : AppTheme.darkBorder,
                    width: 1.5,
                  ),
                ),
                tileColor: isSelected ? AppTheme.darkAccent.withValues(alpha: 0.1) : AppTheme.darkBg3,
                title: Text(
                  title,
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppTheme.darkAccent : Colors.white,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle_rounded, color: AppTheme.darkAccent)
                    : null,
                onTap: () {
                  onTrackSelected(track);
                  Navigator.pop(context);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
