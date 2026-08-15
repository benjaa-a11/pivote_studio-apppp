import 'dart:convert';

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

class AscensoFixtureItem {
  final String title;
  final String subtitle;
  final String? status;
  final String? score;
  final String? date;
  final String? venue;

  const AscensoFixtureItem({
    required this.title,
    required this.subtitle,
    this.status,
    this.score,
    this.date,
    this.venue,
  });
}

class AscensoStandingItem {
  final int position;
  final String team;
  final int played;
  final int wins;
  final int draws;
  final int losses;
  final int goalsFor;
  final int goalsAgainst;
  final int points;

  const AscensoStandingItem({
    required this.position,
    required this.team,
    this.played = 0,
    this.wins = 0,
    this.draws = 0,
    this.losses = 0,
    this.goalsFor = 0,
    this.goalsAgainst = 0,
    this.points = 0,
  });

  int get goalDifference => goalsFor - goalsAgainst;
}

class AscensoRankingItem {
  final int position;
  final String name;
  final String team;
  final String value;

  const AscensoRankingItem({
    required this.position,
    required this.name,
    required this.team,
    required this.value,
  });
}

class Ascenso2026Snapshot {
  final String title;
  final String? updatedLabel;
  final List<AscensoFixtureItem> matches;
  final List<AscensoStandingItem> standings;
  final List<AscensoRankingItem> rankings;
  final List<String> sections;

  const Ascenso2026Snapshot({
    required this.title,
    required this.updatedLabel,
    required this.matches,
    required this.standings,
    required this.rankings,
    required this.sections,
  });
}

class Ascenso2026Service {
  static const String publicUrl =
      'https://copafacil.com/-ndrde5sdllc0nexjb9u@9szj';

  static final Uri _uri = Uri.parse(publicUrl);

  static Future<Ascenso2026Snapshot> fetch() async {
    final response = await http.get(_uri, headers: const {
      'Accept': 'text/html,application/xhtml+xml,application/json',
      'Accept-Language': 'es-AR,es;q=0.9',
      'User-Agent': 'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 Chrome/151.0 Mobile Safari/537.36',
      'Cache-Control': 'no-cache',
    }).timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) {
      throw Exception('Copa Fácil respondió ${response.statusCode}.');
    }

    final body = utf8.decode(response.bodyBytes);
    final trimmed = body.trimLeft();

    if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
      try {
        final json = jsonDecode(trimmed);
        return _parseJson(json);
      } catch (_) {
        // Continue with HTML parsing. Some pages include non-JSON wrappers.
      }
    }

    final document = html_parser.parse(body);
    return _parseHtml(document);
  }

  static Ascenso2026Snapshot _parseHtml(Document document) {
    final title = _firstNonEmpty([
          document.querySelector('meta[property="og:title"]')?.attributes['content'],
          document.querySelector('h1')?.text,
          document.querySelector('title')?.text,
        ]) ??
        'Ascenso 2026';

    final updated = _firstNonEmpty([
      document.querySelector('[datetime]')?.text,
      document.querySelector('time')?.text,
    ]);

    final sections = <String>{};
    for (final node in document.querySelectorAll('h1, h2, h3, h4, nav a, [role="tab"]')) {
      final text = _clean(node.text);
      if (text.length >= 3 && text.length <= 80) sections.add(text);
    }

    final matches = <AscensoFixtureItem>[];
    final standings = <AscensoStandingItem>[];
    final rankings = <AscensoRankingItem>[];

    for (final row in document.querySelectorAll('table tr')) {
      final cells = row
          .querySelectorAll('th, td')
          .map((cell) => _clean(cell.text))
          .where((text) => text.isNotEmpty)
          .toList();
      if (cells.length < 2) continue;
      _classifyCells(cells, matches, standings, rankings);
    }

    final scripts = document.querySelectorAll('script');
    for (final script in scripts) {
      final source = script.text.trim();
      if (source.length < 40) continue;
      final candidates = _extractJsonCandidates(source);
      for (final candidate in candidates) {
        try {
          final decoded = jsonDecode(candidate);
          _walkJson(decoded, matches, standings, rankings, sections);
        } catch (_) {
          // Ignore unrelated scripts.
        }
      }
    }

    if (matches.isEmpty) {
      for (final node in document.querySelectorAll('body *')) {
        if (node.children.isNotEmpty) continue;
        final text = _clean(node.text);
        if (text.length < 8 || text.length > 180) continue;
        final score = _scoreFrom(text);
        final hasTime = RegExp(r'\b\d{1,2}:\d{2}\b').hasMatch(text);
        final status = _detectStatus(text);
        if (score == null && !hasTime && status == null) continue;
        matches.add(AscensoFixtureItem(
          title: text,
          subtitle: '',
          status: status,
          score: score,
        ));
        if (matches.length >= 80) break;
      }
    }

    return _snapshot(
      title: title.trim().isEmpty ? 'Ascenso 2026' : title.trim(),
      updated: updated,
      matches: matches,
      standings: standings,
      rankings: rankings,
      sections: sections,
    );
  }

  static Ascenso2026Snapshot _parseJson(dynamic decoded) {
    final matches = <AscensoFixtureItem>[];
    final standings = <AscensoStandingItem>[];
    final rankings = <AscensoRankingItem>[];
    final sections = <String>{};
    _walkJson(decoded, matches, standings, rankings, sections);

    return _snapshot(
      title: _findString(decoded, ['title', 'name', 'eventName', 'championshipName']) ?? 'Ascenso 2026',
      updated: _findString(decoded, ['updatedAt', 'updated_at', 'lastUpdated', 'lastUpdate']),
      matches: matches,
      standings: standings,
      rankings: rankings,
      sections: sections,
    );
  }

  static Ascenso2026Snapshot _snapshot({
    required String title,
    required String? updated,
    required List<AscensoFixtureItem> matches,
    required List<AscensoStandingItem> standings,
    required List<AscensoRankingItem> rankings,
    required Set<String> sections,
  }) {
    final matchMap = <String, AscensoFixtureItem>{};
    for (final item in matches) {
      matchMap['${item.title}|${item.subtitle}|${item.score}|${item.date}'] = item;
    }

    final standingMap = <String, AscensoStandingItem>{};
    for (final item in standings) standingMap[item.team] = item;

    final rankingMap = <String, AscensoRankingItem>{};
    for (final item in rankings) rankingMap['${item.name}|${item.team}|${item.value}'] = item;

    return Ascenso2026Snapshot(
      title: title,
      updatedLabel: updated,
      matches: matchMap.values.take(100).toList(),
      standings: standingMap.values.toList()..sort((a, b) => a.position.compareTo(b.position)),
      rankings: rankingMap.values.take(60).toList()..sort((a, b) => a.position.compareTo(b.position)),
      sections: sections.take(20).toList(),
    );
  }

  static void _walkJson(
    dynamic node,
    List<AscensoFixtureItem> matches,
    List<AscensoStandingItem> standings,
    List<AscensoRankingItem> rankings,
    Set<String> sections,
  ) {
    if (node is List) {
      for (final item in node) _walkJson(item, matches, standings, rankings, sections);
      return;
    }
    if (node is! Map) return;

    final map = Map<String, dynamic>.from(node);
    final keyText = map.keys.join(' ').toLowerCase();
    final valuesText = map.values.whereType<String>().join(' ').toLowerCase();

    final match = _matchFromMap(map);
    if (match != null) matches.add(match);

    final standing = _standingFromMap(map);
    if (standing != null) standings.add(standing);

    final ranking = _rankingFromMap(map);
    if (ranking != null) rankings.add(ranking);

    if (keyText.contains('category') || keyText.contains('stage') || keyText.contains('group') || keyText.contains('phase')) {
      final label = _findString(map, ['name', 'title', 'label', 'description']);
      if (label != null && label.length >= 3 && label.length <= 80) sections.add(label);
    }

    for (final value in map.values) {
      _walkJson(value, matches, standings, rankings, sections);
    }
  }

  static AscensoFixtureItem? _matchFromMap(Map<String, dynamic> map) {
    final home = _findString(map, ['homeTeam', 'home', 'teamA', 'team1', 'localTeam', 'mandante']);
    final away = _findString(map, ['awayTeam', 'away', 'teamB', 'team2', 'visitorTeam', 'visitante']);
    if (home == null || away == null || home == away) return null;

    final score = _findString(map, ['score', 'result', 'placar', 'resultado']) ?? _pairScore(map);
    final status = _findString(map, ['status', 'state', 'timeStatus', 'gameStatus']);
    final date = _findString(map, ['date', 'startTime', 'datetime', 'matchDate', 'scheduledAt']);
    final venue = _findString(map, ['venue', 'field', 'stadium', 'location', 'cancha']);

    return AscensoFixtureItem(
      title: '$home vs $away',
      subtitle: _clean([date, venue].whereType<String>().where((e) => e.isNotEmpty).join(' · ')),
      status: status,
      score: score,
      date: date,
      venue: venue,
    );
  }

  static AscensoStandingItem? _standingFromMap(Map<String, dynamic> map) {
    final team = _findString(map, ['team', 'teamName', 'name', 'club', 'equipo']);
    if (team == null || team.length < 2) return null;

    final hasTableSignal = map.keys.any((key) {
      final k = key.toLowerCase();
      return k.contains('points') || k.contains('pontos') || k.contains('pts') || k.contains('wins') || k.contains('played');
    });
    if (!hasTableSignal) return null;

    return AscensoStandingItem(
      position: _findInt(map, ['position', 'pos', 'rank', 'place']) ?? 0,
      team: team,
      played: _findInt(map, ['played', 'pj', 'games', 'matches']) ?? 0,
      wins: _findInt(map, ['wins', 'won', 'victories', 'v']) ?? 0,
      draws: _findInt(map, ['draws', 'ties', 'empates', 'e']) ?? 0,
      losses: _findInt(map, ['losses', 'defeats', 'derrotas', 'd']) ?? 0,
      goalsFor: _findInt(map, ['goalsFor', 'gf', 'goals_scored', 'favor']) ?? 0,
      goalsAgainst: _findInt(map, ['goalsAgainst', 'ga', 'goals_conceded', 'contra']) ?? 0,
      points: _findInt(map, ['points', 'pontos', 'pts']) ?? 0,
    );
  }

  static AscensoRankingItem? _rankingFromMap(Map<String, dynamic> map) {
    final name = _findString(map, ['player', 'playerName', 'athlete', 'athleteName', 'name']);
    final team = _findString(map, ['team', 'teamName', 'club', 'equipo']) ?? '';
    final value = _findString(map, ['goals', 'score', 'value', 'total', 'points', 'pontos']);
    if (name == null || value == null || team.isEmpty) return null;
    final looksLikeRanking = map.keys.any((key) {
      final k = key.toLowerCase();
      return k.contains('goal') || k.contains('scorer') || k.contains('ranking') || k.contains('points');
    });
    if (!looksLikeRanking) return null;

    return AscensoRankingItem(
      position: _findInt(map, ['position', 'pos', 'rank', 'place']) ?? 0,
      name: name,
      team: team,
      value: value,
    );
  }

  static void _classifyCells(
    List<String> cells,
    List<AscensoFixtureItem> matches,
    List<AscensoStandingItem> standings,
    List<AscensoRankingItem> rankings,
  ) {
    final combined = cells.join(' · ');
    final score = _scoreFrom(combined);
    final status = _detectStatus(combined);

    if (score != null || RegExp(r'\b\d{1,2}:\d{2}\b').hasMatch(combined) || status != null) {
      matches.add(AscensoFixtureItem(
        title: cells.take(2).join(' vs '),
        subtitle: cells.length > 2 ? cells.skip(2).take(3).join(' · ') : '',
        score: score,
        status: status,
      ));
      return;
    }

    if (cells.length >= 5 && cells[0].length <= 3 && _toInt(cells[0]) != null) {
      final numeric = cells.map(_toInt).toList();
      standings.add(AscensoStandingItem(
        position: numeric[0] ?? 0,
        team: cells[1],
        played: numeric.length > 2 ? numeric[2] ?? 0 : 0,
        wins: numeric.length > 3 ? numeric[3] ?? 0 : 0,
        draws: numeric.length > 4 ? numeric[4] ?? 0 : 0,
        losses: numeric.length > 5 ? numeric[5] ?? 0 : 0,
        goalsFor: numeric.length > 6 ? numeric[6] ?? 0 : 0,
        goalsAgainst: numeric.length > 7 ? numeric[7] ?? 0 : 0,
        points: numeric.length > 8 ? numeric[8] ?? 0 : 0,
      ));
    }
  }

  static List<String> _extractJsonCandidates(String source) {
    final candidates = <String>[];
    final patterns = [
      RegExp(r'<script[^>]+type=["\']application/json["\'][^>]*>(.*?)</script>', dotAll: true, caseSensitive: false),
      RegExp(r'__NEXT_DATA__[^>]*>(.*?)</script>', dotAll: true, caseSensitive: false),
    ];

    for (final pattern in patterns) {
      for (final match in pattern.allMatches(source)) {
        final value = match.group(1)?.trim();
        if (value != null && value.isNotEmpty) candidates.add(value);
      }
    }

    final open = source.indexOf('{');
    final close = source.lastIndexOf('}');
    if (open >= 0 && close > open) {
      final candidate = source.substring(open, close + 1).trim();
      if (candidate.length > 80) candidates.add(candidate);
    }
    return candidates;
  }

  static String? _pairScore(Map<String, dynamic> map) {
    final home = _findInt(map, ['homeScore', 'homeGoals', 'scoreHome', 'localScore']);
    final away = _findInt(map, ['awayScore', 'awayGoals', 'scoreAway', 'visitorScore']);
    if (home == null || away == null) return null;
    return '$home - $away';
  }

  static String? _scoreFrom(String value) => RegExp(r'\b\d{1,2}\s*[-:]\s*\d{1,2}\b').firstMatch(value)?.group(0);

  static String _clean(String value) => value.replaceAll(RegExp(r'\s+'), ' ').trim();

  static String? _firstNonEmpty(Iterable<String?> values) {
    for (final value in values) {
      final cleaned = value?.trim();
      if (cleaned != null && cleaned.isNotEmpty) return cleaned;
    }
    return null;
  }

  static String? _findString(dynamic node, List<String> keys) {
    if (node is! Map) return null;
    final lookup = <String, dynamic>{};
    for (final entry in node.entries) lookup[entry.key.toString().toLowerCase()] = entry.value;
    for (final key in keys) {
      final value = lookup[key.toLowerCase()];
      if (value is String && value.trim().isNotEmpty) return value.trim();
      if (value is num) return value.toString();
    }
    return null;
  }

  static int? _findInt(Map<String, dynamic> map, List<String> keys) {
    final value = _findString(map, keys);
    return _toInt(value);
  }

  static int? _toInt(String? value) {
    if (value == null) return null;
    return int.tryParse(value.replaceAll(RegExp(r'[^0-9-]'), ''));
  }

  static String? _detectStatus(String text) {
    final lower = text.toLowerCase();
    for (final value in const [
      'en vivo', 'ao vivo', 'live', 'finalizado', 'final', 'fim de jogo',
      'programado', 'próximo', 'proximo', 'suspendido', 'aplazado',
    ]) {
      if (lower.contains(value)) return value.toUpperCase();
    }
    return null;
  }
}
