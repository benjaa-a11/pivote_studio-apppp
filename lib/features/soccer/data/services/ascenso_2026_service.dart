import 'dart:convert';

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

class AscensoFixtureItem {
  final String title;
  final String subtitle;
  final String? status;
  final String? score;

  const AscensoFixtureItem({
    required this.title,
    required this.subtitle,
    this.status,
    this.score,
  });
}

class Ascenso2026Snapshot {
  final String title;
  final String? updatedLabel;
  final List<AscensoFixtureItem> matches;
  final List<String> sections;

  const Ascenso2026Snapshot({
    required this.title,
    required this.updatedLabel,
    required this.matches,
    required this.sections,
  });
}

class Ascenso2026Service {
  static const String publicUrl =
      'https://copafacil.com/-ndrde5sdllc0nexjb9u@9szj';

  static final Uri _uri = Uri.parse(publicUrl);

  static Future<Ascenso2026Snapshot> fetch() async {
    final response = await http.get(_uri, headers: const {
      'Accept': 'text/html,application/xhtml+xml',
      'Accept-Language': 'es-AR,es;q=0.9',
      'User-Agent': 'Pivote/5.0 (Android; Flutter)',
      'Cache-Control': 'no-cache',
    }).timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) {
      throw Exception('Copa Fácil respondió ${response.statusCode}.');
    }

    final document = html_parser.parse(utf8.decode(response.bodyBytes));
    return _parse(document);
  }

  static Ascenso2026Snapshot _parse(Document document) {
    final title = _firstNonEmpty([
          document.querySelector('meta[property="og:title"]')?.attributes['content'],
          document.querySelector('title')?.text,
        ]) ??
        'Ascenso 2026';

    final updated = _firstNonEmpty([
      document.querySelector('[datetime]')?.text,
      document.querySelector('time')?.text,
    ]);

    final sections = <String>{};
    for (final node in document.querySelectorAll('h1, h2, h3, h4')) {
      final text = _clean(node.text);
      if (text.length >= 3 && text.length <= 80) {
        sections.add(text);
      }
    }

    final matches = <AscensoFixtureItem>[];

    for (final row in document.querySelectorAll('table tr')) {
      final cells = row
          .querySelectorAll('th, td')
          .map((cell) => _clean(cell.text))
          .where((text) => text.isNotEmpty)
          .toList();

      if (cells.length < 2) continue;

      final combined = cells.join(' · ');
      final score = RegExp(r'\b\d{1,2}\s*[-:]\s*\d{1,2}\b')
          .firstMatch(combined)
          ?.group(0);
      final status = _detectStatus(combined);

      // Avoid menus, sponsor tables and generic site content.
      final looksLikeMatch =
          score != null ||
          RegExp(r'\b\d{1,2}:\d{2}\b').hasMatch(combined) ||
          status != null ||
          (cells.length >= 3 && combined.toLowerCase().contains('vs'));

      if (!looksLikeMatch) continue;

      final titleText = cells.take(2).join(' vs ');
      final subtitle = cells.length > 2 ? cells.skip(2).take(2).join(' · ') : '';

      matches.add(AscensoFixtureItem(
        title: titleText,
        subtitle: subtitle,
        status: status,
        score: score,
      ));
    }

    if (matches.isEmpty) {
      // Some public tournament pages don't use semantic tables. Fall back to
      // short text blocks that contain a score or kickoff time.
      for (final node in document.querySelectorAll('body *')) {
        if (node.children.isNotEmpty) continue;
        final text = _clean(node.text);
        if (text.length < 8 || text.length > 180) continue;

        final score = RegExp(r'\b\d{1,2}\s*[-:]\s*\d{1,2}\b')
            .firstMatch(text)
            ?.group(0);
        final hasTime = RegExp(r'\b\d{1,2}:\d{2}\b').hasMatch(text);
        final status = _detectStatus(text);
        if (score == null && !hasTime && status == null) continue;

        matches.add(AscensoFixtureItem(
          title: text,
          subtitle: '',
          status: status,
          score: score,
        ));
        if (matches.length >= 40) break;
      }
    }

    final unique = <String, AscensoFixtureItem>{};
    for (final item in matches) {
      unique['${item.title}|${item.subtitle}|${item.score}'] = item;
    }

    return Ascenso2026Snapshot(
      title: title.trim().isEmpty ? 'Ascenso 2026' : title.trim(),
      updatedLabel: updated,
      matches: unique.values.take(60).toList(),
      sections: sections.take(12).toList(),
    );
  }

  static String _clean(String value) =>
      value.replaceAll(RegExp(r'\s+'), ' ').trim();

  static String? _firstNonEmpty(Iterable<String?> values) {
    for (final value in values) {
      final cleaned = value?.trim();
      if (cleaned != null && cleaned.isNotEmpty) return cleaned;
    }
    return null;
  }

  static String? _detectStatus(String text) {
    final lower = text.toLowerCase();
    for (final value in const [
      'en vivo',
      'ao vivo',
      'live',
      'finalizado',
      'final',
      'fim de jogo',
      'programado',
      'próximo',
      'proximo',
      'suspendido',
      'aplazado',
    ]) {
      if (lower.contains(value)) return value.toUpperCase();
    }
    return null;
  }
}
