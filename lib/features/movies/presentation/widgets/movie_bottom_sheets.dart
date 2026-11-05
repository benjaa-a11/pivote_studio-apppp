import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:media_kit/media_kit.dart';
import 'package:pivote/core/theme/app_theme.dart';

/// Shared, theme-aware base for all movie playback option sheets.
Widget _buildSheetWrapper({
  required BuildContext context,
  required String title,
  required Widget child,
}) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final bottomInset = MediaQuery.of(context).viewInsets.bottom;

  return Container(
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.86,
    ),
    decoration: BoxDecoration(
      color: theme.cardColor,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      border: Border(
        top: BorderSide(
          color: theme.dividerColor.withValues(alpha: isDark ? 0.6 : 0.8),
        ),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.08),
          blurRadius: 26,
          offset: const Offset(0, -5),
        ),
      ],
    ),
    padding: EdgeInsets.fromLTRB(20, 10, 20, 20 + bottomInset),
    child: SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.35,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Cerrar',
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    ),
  );
}

Widget _selectorOption({
  required BuildContext context,
  required String title,
  String? subtitle,
  required bool selected,
  required VoidCallback onTap,
  IconData? icon,
}) {
  final theme = Theme.of(context);
  final accent = theme.colorScheme.primary;
  final isDark = theme.brightness == Brightness.dark;

  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Material(
      color: selected
          ? accent.withValues(alpha: isDark ? 0.15 : 0.09)
          : theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? accent.withValues(alpha: 0.62)
                  : theme.dividerColor.withValues(alpha: 0.45),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: selected ? accent : theme.colorScheme.onSurfaceVariant, size: 20),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                        color: selected ? accent : theme.colorScheme.onSurface,
                      ),
                    ),
                    if (subtitle != null && subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: 20,
                color: selected ? accent : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
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
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return _buildSheetWrapper(
      context: context,
      title: 'Velocidad de reproducción',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: _speeds.map((speed) {
          final isSelected = speed == currentSpeed;
          return ChoiceChip(
            label: Text(
              speed == 1.0 ? 'Normal' : '${speed}x',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: isSelected
                    ? (isDark ? AppTheme.darkBg : Colors.white)
                    : theme.colorScheme.onSurface,
              ),
            ),
            selected: isSelected,
            selectedColor: accent,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            onSelected: (selected) {
              if (!selected) return;
              onSpeedSelected(speed);
              Navigator.of(context).maybePop();
            },
            showCheckmark: false,
            side: BorderSide(
              color: isSelected ? accent : theme.dividerColor,
              width: isSelected ? 1.4 : 1,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
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
    final subtitleTracks = tracks.subtitle;
    final options = <SubtitleTrack>[SubtitleTrack.no(), ...subtitleTracks];

    return _buildSheetWrapper(
      context: context,
      title: 'Subtítulos',
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.48,
        ),
        child: ListView.separated(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: options.length,
          separatorBuilder: (_, __) => const SizedBox(height: 2),
          itemBuilder: (context, index) {
            final track = options[index];
            final isNone = index == 0;
            final isSelected = selectedTrack.id == track.id;
            var title = isNone
                ? 'Subtítulos desactivados'
                : (track.title ?? track.language ?? 'Subtítulo $index');
            if (!isNone && track.language != null && track.title != null) {
              title = '${track.title} · ${track.language!.toUpperCase()}';
            }

            return _selectorOption(
              context: context,
              title: title,
              subtitle: isNone ? 'Ver sin subtítulos' : null,
              icon: isNone ? Icons.subtitles_off_rounded : Icons.subtitles_rounded,
              selected: isSelected,
              onTap: () {
                onTrackSelected(track);
                Navigator.of(context).maybePop();
              },
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
      title: 'Idioma y pista de audio',
      child: audioTracks.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.headphones_rounded, size: 34, color: Theme.of(context).hintColor),
                  const SizedBox(height: 10),
                  Text(
                    'No hay pistas de audio alternativas.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ],
              ),
            )
          : ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.48,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: audioTracks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 2),
                itemBuilder: (context, index) {
                  final track = audioTracks[index];
                  final isSelected = selectedTrack.id == track.id;
                  final title = track.title ?? track.language ?? 'Pista de audio ${index + 1}';
                  final subtitle = track.language != null && track.title != null
                      ? track.language!.toUpperCase()
                      : null;

                  return _selectorOption(
                    context: context,
                    title: title,
                    subtitle: subtitle,
                    icon: Icons.graphic_eq_rounded,
                    selected: isSelected,
                    onTap: () {
                      onTrackSelected(track);
                      Navigator.of(context).maybePop();
                    },
                  );
                },
              ),
            ),
    );
  }
}
