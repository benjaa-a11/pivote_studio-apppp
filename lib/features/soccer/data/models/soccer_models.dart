import 'package:flutter/material.dart';

class SoccerLeague {
  final String id;
  final String name;
  final String country;
  final String? logoUrl;
  final String shortName;

  SoccerLeague({
    required this.id,
    required this.name,
    required this.country,
    required this.shortName,
    this.logoUrl,
  });

  factory SoccerLeague.fromJson(Map<String, dynamic> json) {
    return SoccerLeague(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      country: json['country'] ?? '',
      shortName: json['shortName'] ?? '',
      logoUrl: json['logoUrl'] as String?,
    );
  }
}

class SoccerTeam {
  final String id;
  final String name;
  final String shortName;
  final String? logoUrl;
  final String? primaryColorHex;
  final String? textColorHex;

  SoccerTeam({
    required this.id,
    required this.name,
    required this.shortName,
    this.logoUrl,
    this.primaryColorHex,
    this.textColorHex,
  });

  Color? get primaryColor {
    if (primaryColorHex == null || primaryColorHex!.isEmpty) return null;
    return _parseHexColor(primaryColorHex!);
  }

  Color? get textColor {
    if (textColorHex == null || textColorHex!.isEmpty) return null;
    return _parseHexColor(textColorHex!);
  }

  Color primaryColorOr(Color fallback) {
    return primaryColor ?? fallback;
  }

  static Color? _parseHexColor(String hex) {
    try {
      String cleanHex = hex.replaceAll('#', '').trim();
      if (cleanHex.length == 3) {
        cleanHex = cleanHex.split('').map((c) => '$c$c').join('');
      }
      if (cleanHex.length == 6) {
        cleanHex = 'FF$cleanHex';
      }
      if (cleanHex.length == 8) {
        return Color(int.parse('0x$cleanHex'));
      }
    } catch (_) {}
    return null;
  }

  factory SoccerTeam.fromJson(Map<String, dynamic> json) {
    final colors = json['colors'] as Map<String, dynamic>?;
    return SoccerTeam(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      shortName: json['shortName'] ?? '',
      logoUrl: json['logoUrl'] as String?,
      primaryColorHex: colors?['primary'] as String?,
      textColorHex: colors?['text'] as String?,
    );
  }
}

class SoccerMatch {
  final String id;
  final String homeTeam;
  final String awayTeam;
  final String homeTeamId;
  final String awayTeamId;
  final String leagueId;
  final List<dynamic> score;
  final String time;
  final String timeStatus;
  final String status;
  final String startTime;
  final List<SoccerTVChannel> tvChannels;
  final String stage;
  final List<SoccerGoal> goals;
  final List<SoccerCard> yellowCards;
  final List<SoccerCard> redCards;

  SoccerMatch({
    required this.id,
    required this.homeTeam,
    required this.awayTeam,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.leagueId,
    required this.score,
    required this.time,
    required this.timeStatus,
    required this.status,
    required this.startTime,
    required this.tvChannels,
    required this.stage,
    required this.goals,
    required this.yellowCards,
    required this.redCards,
  });

  factory SoccerMatch.fromJson(Map<String, dynamic> json) {
    return SoccerMatch(
      id: json['id'] ?? '',
      homeTeam: json['homeTeam'] ?? '',
      awayTeam: json['awayTeam'] ?? '',
      homeTeamId: json['homeTeamId'] ?? '',
      awayTeamId: json['awayTeamId'] ?? '',
      leagueId: json['leagueId'] ?? '',
      score: json['score'] ?? [],
      time: json['time'] ?? '',
      timeStatus: json['timeStatus'] ?? '',
      status: json['status'] ?? '',
      startTime: json['startTime'] ?? '',
      tvChannels: (json['tvChannels'] as List?)
              ?.map((c) => SoccerTVChannel.fromJson(c))
              .toList() ??
          [],
      stage: json['stage'] ?? '',
      goals: (json['goals'] as List?)
              ?.map((g) => SoccerGoal.fromJson(g))
              .toList() ??
          [],
      yellowCards: (json['yellowCards'] as List?)
              ?.map((c) => SoccerCard.fromJson(c))
              .toList() ??
          [],
      redCards: (json['redCards'] as List?)
              ?.map((c) => SoccerCard.fromJson(c))
              .toList() ??
          [],
    );
  }

  // Statistics helpers removed as they are not in the main API

  bool get isLive {
    final ts = timeStatus.toLowerCase();
    return ts.contains('pt') ||
        ts.contains('st') ||
        ts.contains('et') ||
        ts.contains('entretiempo') ||
        time.contains("'");
  }

  bool get isFinished {
    final s = status.toLowerCase();
    final ts = timeStatus.toLowerCase();
    return s.contains('finalizado') ||
        s.contains('terminado') ||
        ts.contains('finalizado') ||
        ts.contains('terminado');
  }

  bool get isScheduled {
    final ts = timeStatus.toLowerCase();
    return ts.contains('prog') ||
        ts.contains('programado') ||
        status.toLowerCase().contains('próximo') ||
        status.toLowerCase().contains('proximo');
  }

  DateTime? get startDateTime {
    try {
      // Formato esperado: "dd-MM-yyyy HH:mm"
      final parts = startTime.split(' ');
      if (parts.length < 2) return null;

      final dateParts = parts[0].split('-');
      if (dateParts.length < 3) return null;

      final timeParts = parts[1].split(':');
      if (timeParts.length < 2) return null;

      return DateTime(
        int.parse(dateParts[2]), // year
        int.parse(dateParts[1]), // month
        int.parse(dateParts[0]), // day
        int.parse(timeParts[0]), // hour
        int.parse(timeParts[1]), // minute
      );
    } catch (e) {
      return null;
    }
  }

  bool get isAutoFinished {
    final start = startDateTime;
    if (start == null) return false;

    final now = DateTime.now();
    // Expirar 2 horas y media después del inicio como fallback (150 minutos)
    return now.difference(start).inMinutes > 150;
  }

  /// Indica si el partido debe ser removido del Hero (10 minutos después de terminar)
  bool get shouldRemoveFromHero {
    if (!isFinished) return false;

    // Si ha pasado más de 10 minutos desde que se estima que terminó el partido
    // Asumiendo que un partido dura aprox 110 minutos (incl. ET)
    final start = startDateTime;
    if (start != null) {
      final now = DateTime.now();
      return now.difference(start).inMinutes >
          120; // 110m de partido + 10m de cortesía
    }

    return false;
  }

  bool get isWatchable {
    if (isLive) return true;
    if (isFinished || isAutoFinished) return false;

    final start = startDateTime;
    if (start != null) {
      final now = DateTime.now();
      final diff = start.difference(now);
      // Habilitar cuando falten 45 minutos o menos para el inicio
      return diff.inMinutes <= 45;
    }

    return false;
  }

  /// Minuto transcurrido estimado (0.0 a 1.0) para la barra de progreso
  double get elapsedPercent {
    if (isFinished) return 1.0;
    final ts = timeStatus.toLowerCase();
    if (ts.contains('entretiempo') ||
        ts.contains('et') ||
        ts.contains('descanso')) {
      return 0.50;
    }
    final match = RegExp(r'\d+').firstMatch(ts.isNotEmpty ? ts : time);
    if (match != null) {
      final minute = int.tryParse(match.group(0) ?? '') ?? 0;
      return (minute / 90.0).clamp(0.05, 1.0);
    }
    return isLive ? 0.45 : 0.0;
  }

  /// Hora en formato HH:mm
  String get formattedTime {
    try {
      final parts = startTime.split(' ');
      if (parts.length > 1) return parts[1];
    } catch (_) {}
    return startTime;
  }

  /// Etiqueta de día: 'Hoy' o 'dd/MM'
  String get dayLabel {
    try {
      final parts = startTime.split(' ');
      if (parts.isNotEmpty) {
        final dParts = parts[0].split('-');
        if (dParts.length >= 3) {
          final now = DateTime.now();
          final isToday = now.day == int.tryParse(dParts[0]) &&
              now.month == int.tryParse(dParts[1]) &&
              now.year == int.tryParse(dParts[2]);
          if (isToday) return 'Hoy';
          return '${dParts[0]}/${dParts[1]}';
        }
      }
    } catch (_) {}
    return 'Hoy';
  }

  /// Resumen formateado de goleadores para un equipo (ej: "Cavani 34' 68'")
  String getScorersSummary(String teamId) {
    final teamGoals = goals.where((g) => g.teamId == teamId).toList()
      ..sort((a, b) => a.time.compareTo(b.time));
    if (teamGoals.isEmpty) return '';

    final Map<String, List<String>> byPlayer = {};
    for (final g in teamGoals) {
      final name = g.playerShortName.isNotEmpty ? g.playerShortName : 'Gol';
      final disp = g.timeToDisplay.isNotEmpty ? g.timeToDisplay : "${g.time}'";
      byPlayer.putIfAbsent(name, () => []).add(disp);
    }

    return byPlayer.entries
        .map((e) => '${e.key} ${e.value.join(' ')}')
        .join(' · ');
  }

  /// Nombres de canales para mostrar en el footer del hero
  String get tvChannelsDisplay {
    final names = tvChannels
        .map((c) => c.name.trim())
        .where((n) => n.isNotEmpty)
        .toList();
    if (names.isEmpty) return '';
    return names.take(2).join(' · ');
  }
}

class SoccerTVChannel {
  final String name;
  final String? id;

  SoccerTVChannel({
    required this.name,
    this.id,
  });

  factory SoccerTVChannel.fromJson(Map<String, dynamic> json) {
    return SoccerTVChannel(
      name: json['name'] ?? '',
      id: json['id'] as String?,
    );
  }
}

class SoccerData {
  final List<SoccerLeague> leagues;
  final List<SoccerTeam> teams;
  final List<SoccerMatch> matches;

  SoccerData({
    required this.leagues,
    required this.teams,
    required this.matches,
  });

  factory SoccerData.fromJson(Map<String, dynamic> json) {
    return SoccerData(
      leagues: (json['leagues'] as List?)
              ?.map((l) => SoccerLeague.fromJson(l))
              .toList() ??
          [],
      teams: (json['teams'] as List?)
              ?.map((t) => SoccerTeam.fromJson(t))
              .toList() ??
          [],
      matches: (json['matches'] as List?)
              ?.map((m) => SoccerMatch.fromJson(m))
              .toList() ??
          [],
    );
  }
}

class SoccerGoal {
  final String teamId;
  final String playerShortName;
  final int time;
  final String timeToDisplay;

  SoccerGoal({
    required this.teamId,
    required this.playerShortName,
    required this.time,
    required this.timeToDisplay,
  });

  factory SoccerGoal.fromJson(Map<String, dynamic> json) {
    return SoccerGoal(
      teamId: json['teamId'] ?? '',
      playerShortName: json['playerShortName'] ?? '',
      time: json['time'] ?? 0,
      timeToDisplay: json['timeToDisplay'] ?? '',
    );
  }
}

class SoccerCard {
  final String teamId;
  final String playerShortName;
  final int time;
  final String timeToDisplay;

  SoccerCard({
    required this.teamId,
    required this.playerShortName,
    required this.time,
    required this.timeToDisplay,
  });

  factory SoccerCard.fromJson(Map<String, dynamic> json) {
    return SoccerCard(
      teamId: json['teamId'] ?? '',
      playerShortName: json['playerShortName'] ?? '',
      time: json['time'] ?? 0,
      timeToDisplay: json['timeToDisplay'] ?? '',
    );
  }
}
