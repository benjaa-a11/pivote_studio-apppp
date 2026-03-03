import 'dart:convert';
import 'dart:io';

/// Represents a single program slot in the channel guide.
class ChannelProgramSlot {
  final String title;
  final String time;

  ChannelProgramSlot({
    required this.title,
    required this.time,
  });
}

/// Professional EPG (Electronic Program Guide) service for channels.
///
/// Fetches and parses the programming grid from the external provider using
/// a proxy URL. Each channel is identified by a `guid` which can be either
/// a numeric channel number (e.g. "10") or a channel name (e.g. "TELEFE").
class EpgService {
  static const String _baseUrl =
      'https://myproxy.canalesonline24.workers.dev/?url=https://www.telered.com.ar/layout/grillaTVupd.php';

  /// Fetch the program guide for a channel.
  ///
  /// [guid] can be the numeric code ("10") or channel name ("TELEFE").
  /// [start] is the reference time; the remote API expects an hour parameter.
  static Future<List<ChannelProgramSlot>> fetchGuide({
    required String guid,
    required DateTime start,
  }) async {
    // Use local hour (0-23) for the `prti` parameter.
    final startHour = start.hour;
    final uri = Uri.parse(
        '$_baseUrl?prti=$startHour&prtf=24&chlf=0&chlt=0&wn=0&pack=D');

    HttpClient? httpClient;
    try {
      httpClient = HttpClient()
        ..connectionTimeout = const Duration(seconds: 10)
        ..idleTimeout = const Duration(seconds: 10)
        ..badCertificateCallback = (cert, host, port) => true;

      final request = await httpClient.getUrl(uri);
      request.headers.set('User-Agent',
          'Pivote/1.0 (+https://pivote.app)'); // simple, non-identifying UA
      request.headers.set('Accept', 'text/html,application/xhtml+xml,*/*');

      final response = await request.close();
      if (response.statusCode != 200) {
        throw HttpException(
            'Guide server responded with ${response.statusCode}');
      }

      final body = await response.transform(const Utf8Decoder()).join();
      return _parseGuide(body, guid);
    } catch (e) {
      // Propagate so UI can show a clear error message.
      throw Exception('No se pudo cargar la programación: $e');
    } finally {
      try {
        httpClient?.close(force: true);
      } catch (_) {}
    }
  }

  /// Parse the remote text/HTML into program slots for a specific channel.
  static List<ChannelProgramSlot> _parseGuide(String raw, String guid) {
    // Normalize line breaks and trim.
    final text = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final lines = text.split('\n').map((l) => l.trim()).toList();

    final channels = <_ParsedChannel>[];
    String? currentNumber;
    String? currentName;
    final currentPrograms = <String>[];

    bool _isChannelNumber(String line) =>
        RegExp(r'^\d+$').hasMatch(line.trim());

    void _flushChannel() {
      if (currentNumber == null && currentName == null) return;
      channels.add(_ParsedChannel(
        number: currentNumber,
        name: currentName,
        programLines: List<String>.from(currentPrograms),
      ));
      currentNumber = null;
      currentName = null;
      currentPrograms.clear();
    }

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.isEmpty) continue;

      if (_isChannelNumber(line)) {
        // New channel block.
        _flushChannel();
        currentNumber = line;
        // Next line should be channel name if available.
        if (i + 1 < lines.length &&
            !_isChannelNumber(lines[i + 1]) &&
            !lines[i + 1].toLowerCase().contains('ver más')) {
          currentName = lines[i + 1];
        }
        // Skip "XVer más" line if present.
        continue;
      }

      // Skip "XVer más" or bullets.
      if (line.toLowerCase().contains('ver más')) {
        continue;
      }

      // Program line.
      if (currentNumber != null || currentName != null) {
        currentPrograms.add(line);
      }
    }
    _flushChannel();

    if (channels.isEmpty) return const [];

    final normalizedGuid = guid.trim().toLowerCase();
    _ParsedChannel? match;

    // 1) Exact numeric match.
    if (RegExp(r'^\d+$').hasMatch(normalizedGuid)) {
      match = channels.firstWhere(
        (c) => c.number != null && c.number == normalizedGuid,
        orElse: () => _ParsedChannel.empty,
      );
      if (match == _ParsedChannel.empty) match = null;
    }

    // 2) Fallback: match by name (case-insensitive contains).
    match ??= channels.firstWhere(
      (c) =>
          c.name != null &&
          c.name!.toLowerCase().contains(normalizedGuid.toLowerCase()),
      orElse: () => _ParsedChannel.empty,
    );
    if (match == _ParsedChannel.empty) return const [];

    return match.programLines
        .map((line) {
          // Expect format: "<Title> HH:MMhs"
          final parts = line.split(' ');
          if (parts.length < 2) {
            return ChannelProgramSlot(title: line, time: '');
          }
          final last = parts.last;
          if (last.endsWith('hs')) {
            final time = last;
            final title = parts.sublist(0, parts.length - 1).join(' ').trim();
            return ChannelProgramSlot(title: title, time: time);
          }
          return ChannelProgramSlot(title: line, time: '');
        })
        .where((slot) => slot.title.isNotEmpty)
        .toList();
  }
}

class _ParsedChannel {
  final String? number;
  final String? name;
  final List<String> programLines;

  _ParsedChannel({
    required this.number,
    required this.name,
    required this.programLines,
  });

  static final empty =
      _ParsedChannel(number: null, name: null, programLines: const []);
}

