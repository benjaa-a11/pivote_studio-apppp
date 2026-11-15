import 'package:flutter/material.dart';

class SoccerMeta {
  final String version;
  final String generatedAt;
  final String timezone;
  final List<String> sources;

  const SoccerMeta({
    this.version = '',
    this.generatedAt = '',
    this.timezone = '',
    this.sources = const [],
  });

  factory SoccerMeta.fromJson(Map<String, dynamic> json) {
    return SoccerMeta(
      version: (json['version'] ?? '').toString(),
      generatedAt: (json['generatedAt'] ?? '').toString(),
      timezone: (json['timezone'] ?? '').toString(),
      sources: (json['sources'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}

class SoccerSummary {
  final int totalMatches;
  final int liveMatches;
  final int finishedMatches;
  final int upcomingMatches;
  final int leaguesCount;

  const SoccerSummary({
    this.totalMatches = 0,
    this.liveMatches = 0,
    this.finishedMatches = 0,
    this.upcomingMatches = 0,
    this.leaguesCount = 0,
  });

  factory SoccerSummary.fromJson(Map<String, dynamic> json) {
    return SoccerSummary(
      totalMatches: _toInt(json['totalMatches']),
      liveMatches: _toInt(json['liveMatches']),
      finishedMatches: _toInt(json['finishedMatches']),
      upcomingMatches: _toInt(json['upcomingMatches']),
      leaguesCount: _toInt(json['leaguesCount']),
    );
  }
}

class SoccerLeague {
  final String id;
  final String canonicalSlug;
  final String name;
  final String country;
  final String countryId;
  final String? countryFlag;
  final bool isInternational;
  final String? logoUrl;
  final String? espnLogoUrl;
  final String shortName;

  SoccerLeague({
    required this.id,
    this.canonicalSlug = '',
    required this.name,
    required this.country,
    this.countryId = '',
    this.countryFlag,
    this.isInternational = false,
    required this.shortName,
    this.logoUrl,
    this.espnLogoUrl,
  });

  factory SoccerLeague.fromJson(Map<String, dynamic> json) {
    final logos = json['logos'] as Map<String, dynamic>?;
    final primaryLogo = (json['logo'] ??
            json['logoUrl'] ??
            logos?['promiedos'] ??
            logos?['espn'])
        ?.toString();
    final name = (json['name'] ?? '').toString();

    return SoccerLeague(
      id: (json['id'] ?? '').toString(),
      canonicalSlug: (json['canonicalSlug'] ?? json['slug'] ?? '').toString(),
      name: name,
      country: (json['countryName'] ?? json['country'] ?? '').toString(),
      countryId: (json['countryId'] ?? '').toString(),
      countryFlag: json['countryFlag']?.toString(),
      isInternational: json['isInternational'] == true,
      shortName: (json['shortName'] ?? name).toString(),
      logoUrl: primaryLogo?.isNotEmpty == true ? primaryLogo : null,
      espnLogoUrl: logos?['espn']?.toString(),
    );
  }
}

class SoccerLeagueGroup {
  final SoccerLeague league;
  final int liveCount;
  final int matchesCount;
  final List<SoccerMatch> matches;

  const SoccerLeagueGroup({
    required this.league,
    required this.liveCount,
    required this.matchesCount,
    required this.matches,
  });

  factory SoccerLeagueGroup.fromJson(Map<String, dynamic> json) {
    final leagueJson = json['league'] as Map<String, dynamic>? ?? const {};
    final parsedMatches = (json['matches'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(SoccerMatch.fromJson)
            .toList() ??
        const <SoccerMatch>[];

    return SoccerLeagueGroup(
      league: SoccerLeague.fromJson(leagueJson),
      liveCount: _toInt(json['liveCount']),
      matchesCount: _toInt(json['matchesCount'], fallback: parsedMatches.length),
      matches: parsedMatches,
    );
  }
}

class SoccerTeam {
  final String id;
  final String name;
  final String shortName;
  final String abbreviation;
  final String? logoUrl;
  final String? espnLogoUrl;
  final String? countryFlag;
  final String? primaryColorHex;
  final String? secondaryColorHex;
  final String? textColorHex;
  final String form;
  final int score;
  final int redCards;
  final int yellowCards;
  final bool winner;

  SoccerTeam({
    required this.id,
    required this.name,
    required this.shortName,
    this.abbreviation = '',
    this.logoUrl,
    this.espnLogoUrl,
    this.countryFlag,
    this.primaryColorHex,
    this.secondaryColorHex,
    this.textColorHex,
    this.form = '',
    this.score = 0,
    this.redCards = 0,
    this.yellowCards = 0,
    this.winner = false,
  });

  Color? get primaryColor => _parseHexColor(primaryColorHex);
  Color? get secondaryColor => _parseHexColor(secondaryColorHex);
  Color? get textColor => _parseHexColor(textColorHex);

  Color primaryColorOr(Color fallback) => primaryColor ?? fallback;

  static Color? _parseHexColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
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
    final logos = json['logos'] as Map<String, dynamic>?;
    final primaryLogo = (json['logo'] ??
            json['logoUrl'] ??
            logos?['promiedosLarge'] ??
            logos?['promiedos'] ??
            logos?['espn'])
        ?.toString();
    final name = (json['name'] ?? '').toString();
    final shortName = (json['shortName'] ?? name).toString();

    return SoccerTeam(
      id: (json['id'] ?? '').toString(),
      name: name,
      shortName: shortName,
      abbreviation: (json['abbreviation'] ?? '').toString(),
      logoUrl: primaryLogo?.isNotEmpty == true ? primaryLogo : null,
      espnLogoUrl: logos?['espn']?.toString(),
      countryFlag: json['countryFlag']?.toString(),
      primaryColorHex: colors?['primary']?.toString(),
      secondaryColorHex: colors?['secondary']?.toString(),
      textColorHex: colors?['text']?.toString(),
      form: (json['form'] ?? '').toString(),
      score: _toInt(json['score']),
      redCards: _toInt(json['redCards']),
      yellowCards: _toInt(json['yellowCards']),
      winner: json['winner'] == true,
    );
  }
}

class SoccerMatchStatus {
  final String state;
  final String code;
  final String label;
  final String shortLabel;
  final int minute;
  final String minuteDisplay;
  final int period;
  final bool isLive;
  final bool isFinished;

  const SoccerMatchStatus({
    this.state = '',
    this.code = '',
    this.label = '',
    this.shortLabel = '',
    this.minute = 0,
    this.minuteDisplay = '',
    this.period = 0,
    this.isLive = false,
    this.isFinished = false,
  });

  factory SoccerMatchStatus.fromJson(Map<String, dynamic> json) {
    return SoccerMatchStatus(
      state: (json['state'] ?? '').toString(),
      code: (json['code'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      shortLabel: (json['shortLabel'] ?? '').toString(),
      minute: _toInt(json['minute']),
      minuteDisplay: (json['minuteDisplay'] ?? '').toString(),
      period: _toInt(json['period']),
      isLive: json['isLive'] == true,
      isFinished: json['isFinished'] == true,
    );
  }
}

class SoccerVenue {
  final String id;
  final String name;
  final String city;
  final String country;

  const SoccerVenue({
    this.id = '',
    this.name = '',
    this.city = '',
    this.country = '',
  });

  factory SoccerVenue.fromJson(Map<String, dynamic> json) {
    return SoccerVenue(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      country: (json['country'] ?? '').toString(),
    );
  }

  String get formatted {
    final parts = [
      if (name.isNotEmpty) name,
      if (city.isNotEmpty) city,
      if (country.isNotEmpty && country != city) country,
    ];
    return parts.join(' · ');
  }
}

class SoccerOdds {
  final String provider;
  final double? home;
  final double? draw;
  final double? away;

  const SoccerOdds({
    this.provider = '',
    this.home,
    this.draw,
    this.away,
  });

  bool get hasValues => home != null && draw != null && away != null;

  factory SoccerOdds.fromJson(Map<String, dynamic> json) {
    final ml = json['moneyline'] as Map<String, dynamic>?;
    return SoccerOdds(
      provider: (json['provider'] ?? '').toString(),
      home: _toDouble(ml?['home']),
      draw: _toDouble(ml?['draw']),
      away: _toDouble(ml?['away']),
    );
  }
}

class SoccerTVChannel {
  final String? id;
  final String name;
  final String slug;
  final String? logo;
  final String country;
  final String category;
  final bool mapped;

  SoccerTVChannel({
    required this.name,
    this.id,
    this.slug = '',
    this.logo,
    this.country = '',
    this.category = '',
    this.mapped = false,
  });

  bool get hasAppChannelId => id != null && id!.trim().isNotEmpty;

  factory SoccerTVChannel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id']?.toString().trim();
    return SoccerTVChannel(
      id: (rawId != null && rawId.isNotEmpty) ? rawId : null,
      name: (json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      logo: json['logo']?.toString(),
      country: (json['country'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      mapped: json['mapped'] == true,
    );
  }
}

class SoccerGoal {
  final String teamSide; // 'home' or 'away'
  final String teamId;
  final String playerName;
  final String playerShortName;
  final int time;
  final String timeToDisplay;
  final bool isPenalty;
  final bool isOwnGoal;

  SoccerGoal({
    this.teamSide = '',
    required this.teamId,
    this.playerName = '',
    required this.playerShortName,
    required this.time,
    required this.timeToDisplay,
    this.isPenalty = false,
    this.isOwnGoal = false,
  });

  factory SoccerGoal.fromJson(
    Map<String, dynamic> json, {
    String homeTeamId = '',
    String awayTeamId = '',
  }) {
    final side = (json['teamSide'] ?? '').toString();
    var teamId = (json['teamId'] ?? '').toString();
    if (teamId.isEmpty) {
      if (side == 'home') teamId = homeTeamId;
      if (side == 'away') teamId = awayTeamId;
    }

    final playerName = (json['playerName'] ?? '').toString();
    final shortName =
        (json['playerShortName'] ?? (playerName.isNotEmpty ? playerName : ''))
            .toString();
    final minute = _toInt(json['minute'] ?? json['time']);
    final minuteDisp =
        (json['minuteDisplay'] ?? json['timeToDisplay'] ?? "$minute'")
            .toString();

    return SoccerGoal(
      teamSide: side,
      teamId: teamId,
      playerName: playerName,
      playerShortName: shortName,
      time: minute,
      timeToDisplay: minuteDisp,
      isPenalty: json['isPenalty'] == true,
      isOwnGoal: json['isOwnGoal'] == true,
    );
  }
}

class SoccerCard {
  final String teamSide;
  final String teamId;
  final String cardType; // 'yellow' or 'red'
  final String playerName;
  final String playerShortName;
  final int time;
  final String timeToDisplay;

  SoccerCard({
    this.teamSide = '',
    required this.teamId,
    this.cardType = 'yellow',
    this.playerName = '',
    required this.playerShortName,
    required this.time,
    required this.timeToDisplay,
  });

  bool get isRed => cardType.toLowerCase() == 'red';

  factory SoccerCard.fromJson(
    Map<String, dynamic> json, {
    String homeTeamId = '',
    String awayTeamId = '',
    String fallbackType = 'yellow',
  }) {
    final side = (json['teamSide'] ?? '').toString();
    var teamId = (json['teamId'] ?? '').toString();
    if (teamId.isEmpty) {
      if (side == 'home') teamId = homeTeamId;
      if (side == 'away') teamId = awayTeamId;
    }

    final playerName = (json['playerName'] ?? '').toString();
    final shortName =
        (json['playerShortName'] ?? (playerName.isNotEmpty ? playerName : ''))
            .toString();
    final minute = _toInt(json['minute'] ?? json['time']);
    final minuteDisp =
        (json['minuteDisplay'] ?? json['timeToDisplay'] ?? "$minute'")
            .toString();

    return SoccerCard(
      teamSide: side,
      teamId: teamId,
      cardType: (json['cardType'] ?? fallbackType).toString(),
      playerName: playerName,
      playerShortName: shortName,
      time: minute,
      timeToDisplay: minuteDisp,
    );
  }
}

class SoccerMatch {
  final String id;
  final String canonicalKey;
  final String urlSlug;
  final String dateIso;
  final String dateLocalAr;
  final String timeLocalAr;
  final String stageRound;
  final String note;

  final SoccerLeague leagueData;
  final SoccerTeam homeTeamData;
  final SoccerTeam awayTeamData;
  final SoccerMatchStatus matchStatus;
  final SoccerVenue? venue;
  final SoccerOdds? odds;

  final List<SoccerTVChannel> tvChannels;
  final List<SoccerGoal> goals;
  final List<SoccerCard> cards;

  // Legacy-compatible fields derived from the new API
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
  final String stage;

  SoccerMatch({
    required this.id,
    this.canonicalKey = '',
    this.urlSlug = '',
    this.dateIso = '',
    this.dateLocalAr = '',
    this.timeLocalAr = '',
    this.stageRound = '',
    this.note = '',
    required this.leagueData,
    required this.homeTeamData,
    required this.awayTeamData,
    required this.matchStatus,
    this.venue,
    this.odds,
    required this.tvChannels,
    required this.goals,
    required this.cards,
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
    required this.stage,
  });

  List<SoccerCard> get yellowCards =>
      cards.where((c) => !c.isRed).toList(growable: false);

  List<SoccerCard> get redCards =>
      cards.where((c) => c.isRed).toList(growable: false);

  factory SoccerMatch.fromJson(Map<String, dynamic> json) {
    final leagueMap = json['league'] as Map<String, dynamic>? ?? const {};
    final homeMap = json['home'] as Map<String, dynamic>? ?? const {};
    final awayMap = json['away'] as Map<String, dynamic>? ?? const {};
    final statusMap = json['status'] is Map<String, dynamic>
        ? json['status'] as Map<String, dynamic>
        : const <String, dynamic>{};

    final league = SoccerLeague.fromJson(leagueMap);
    final home = SoccerTeam.fromJson(homeMap);
    final away = SoccerTeam.fromJson(awayMap);
    final st = SoccerMatchStatus.fromJson(statusMap);

    final homeId = home.id.isNotEmpty
        ? home.id
        : (json['homeTeamId'] ?? '').toString();
    final awayId = away.id.isNotEmpty
        ? away.id
        : (json['awayTeamId'] ?? '').toString();

    final parsedGoals = (json['goals'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map((g) => SoccerGoal.fromJson(
                  g,
                  homeTeamId: homeId,
                  awayTeamId: awayId,
                ))
            .toList() ??
        const <SoccerGoal>[];

    final parsedCards = <SoccerCard>[
      ...?((json['cards'] as List?)
          ?.whereType<Map<String, dynamic>>()
          .map((c) => SoccerCard.fromJson(
                c,
                homeTeamId: homeId,
                awayTeamId: awayId,
              ))),
      ...?((json['yellowCards'] as List?)
          ?.whereType<Map<String, dynamic>>()
          .map((c) => SoccerCard.fromJson(
                c,
                homeTeamId: homeId,
                awayTeamId: awayId,
                fallbackType: 'yellow',
              ))),
      ...?((json['redCards'] as List?)
          ?.whereType<Map<String, dynamic>>()
          .map((c) => SoccerCard.fromJson(
                c,
                homeTeamId: homeId,
                awayTeamId: awayId,
                fallbackType: 'red',
              ))),
    ];

    final rawBroadcasts = (json['broadcasts'] ?? json['tvChannels']) as List?;
    final broadcasts = rawBroadcasts
            ?.whereType<Map<String, dynamic>>()
            .map(SoccerTVChannel.fromJson)
            .toList() ??
        const <SoccerTVChannel>[];

    final dateLocalAr = (json['dateLocalAr'] ?? '').toString();
    final timeLocalAr = (json['timeLocalAr'] ?? '').toString();

    // Construir startTime compatible "dd-MM-yyyy HH:mm" si viene dateLocalAr
    String legacyStartTime = (json['startTime'] ?? '').toString();
    if (legacyStartTime.isEmpty && dateLocalAr.isNotEmpty) {
      final dp = dateLocalAr.split('-');
      if (dp.length == 3) {
        legacyStartTime =
            '${dp[2]}-${dp[1]}-${dp[0]} ${timeLocalAr.isNotEmpty ? timeLocalAr : '00:00'}';
      }
    }

    final displayMinute = st.minuteDisplay.isNotEmpty
        ? st.minuteDisplay
        : (st.shortLabel.isNotEmpty ? st.shortLabel : st.label);

    final statusLabel = st.isLive
        ? (st.label.isNotEmpty ? st.label : 'En vivo')
        : st.isFinished
            ? (st.label.isNotEmpty ? st.label : 'Finalizado')
            : (st.label.isNotEmpty ? st.label : 'Programado');

    final stageRound = (json['stageRound'] ?? json['stage'] ?? '').toString();

    return SoccerMatch(
      id: (json['id'] ?? '').toString(),
      canonicalKey: (json['canonicalKey'] ?? '').toString(),
      urlSlug: (json['urlSlug'] ?? '').toString(),
      dateIso: (json['dateIso'] ?? '').toString(),
      dateLocalAr: dateLocalAr,
      timeLocalAr: timeLocalAr,
      stageRound: stageRound,
      note: (json['note'] ?? '').toString(),
      leagueData: league,
      homeTeamData: home,
      awayTeamData: away,
      matchStatus: st,
      venue: json['venue'] is Map<String, dynamic>
          ? SoccerVenue.fromJson(json['venue'] as Map<String, dynamic>)
          : null,
      odds: json['odds'] is Map<String, dynamic>
          ? SoccerOdds.fromJson(json['odds'] as Map<String, dynamic>)
          : null,
      tvChannels: broadcasts,
      goals: parsedGoals,
      cards: parsedCards,
      homeTeam: home.name.isNotEmpty
          ? home.name
          : (json['homeTeam'] ?? '').toString(),
      awayTeam: away.name.isNotEmpty
          ? away.name
          : (json['awayTeam'] ?? '').toString(),
      homeTeamId: homeId,
      awayTeamId: awayId,
      leagueId: league.id.isNotEmpty
          ? league.id
          : (json['leagueId'] ?? '').toString(),
      score: json['score'] is List
          ? json['score'] as List
          : [home.score, away.score],
      time: displayMinute,
      timeStatus: displayMinute.isNotEmpty ? displayMinute : st.state,
      status: statusLabel,
      startTime: legacyStartTime,
      stage: stageRound,
    );
  }

  bool get isLive {
    if (matchStatus.isLive) return true;
    final state = matchStatus.state.toUpperCase();
    if (state == 'LIVE' || state == 'HT' || state == 'ET') return true;
    final ts = timeStatus.toLowerCase();
    return ts.contains('pt') ||
        ts.contains('st') ||
        ts.contains('et') ||
        ts.contains('entretiempo') ||
        time.contains("'");
  }

  bool get isHalfTime =>
      matchStatus.state.toUpperCase() == 'HT' ||
      matchStatus.shortLabel.toUpperCase() == 'MT' ||
      matchStatus.label.toLowerCase().contains('medio tiempo');

  bool get isFinished {
    if (matchStatus.isFinished) return true;
    final state = matchStatus.state.toUpperCase();
    if (state == 'FT' || state == 'FINISHED' || state == 'FINAL') return true;
    final s = status.toLowerCase();
    final ts = timeStatus.toLowerCase();
    return s.contains('finalizado') ||
        s.contains('terminado') ||
        ts.contains('finalizado') ||
        ts.contains('terminado');
  }

  bool get isScheduled {
    if (isLive || isFinished) return false;
    return true;
  }

  DateTime? get startDateTime {
    if (dateIso.isNotEmpty) {
      final parsed = DateTime.tryParse(dateIso);
      if (parsed != null) return parsed.toLocal();
    }
    try {
      final parts = startTime.split(' ');
      if (parts.length < 2) return null;
      final dateParts = parts[0].split('-');
      if (dateParts.length < 3) return null;
      final timeParts = parts[1].split(':');
      if (timeParts.length < 2) return null;
      return DateTime(
        int.parse(dateParts[2]),
        int.parse(dateParts[1]),
        int.parse(dateParts[0]),
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );
    } catch (_) {
      return null;
    }
  }

  DateTime? get kickoff => startDateTime;

  bool get isToday {
    final start = startDateTime;
    if (start == null) return true;
    final now = DateTime.now();
    return start.year == now.year &&
        start.month == now.month &&
        start.day == now.day;
  }

  bool get isAutoFinished {
    final start = startDateTime;
    if (start == null) return false;
    return DateTime.now().difference(start).inMinutes > 150;
  }

  bool get shouldRemoveFromHero {
    if (!isFinished) return false;
    final start = startDateTime;
    if (start != null) {
      return DateTime.now().difference(start).inMinutes > 120;
    }
    return false;
  }

  bool get isWatchable {
    if (isLive) return true;
    if (isFinished || isAutoFinished) return false;

    final start = startDateTime;
    if (start != null) {
      final diff = start.difference(DateTime.now());
      return diff.inMinutes <= 45;
    }
    return false;
  }

  double get elapsedPercent {
    if (isFinished) return 1.0;
    if (isHalfTime) return 0.50;
    if (matchStatus.minute > 0) {
      return (matchStatus.minute / 90.0).clamp(0.05, 1.0);
    }
    final match = RegExp(r'\d+').firstMatch(time);
    if (match != null) {
      final minute = int.tryParse(match.group(0) ?? '') ?? 0;
      return (minute / 90.0).clamp(0.05, 1.0);
    }
    return isLive ? 0.45 : 0.0;
  }

  String get formattedTime {
    if (timeLocalAr.isNotEmpty) return timeLocalAr;
    final start = startDateTime;
    if (start != null) {
      final hh = start.hour.toString().padLeft(2, '0');
      final mm = start.minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    }
    return '';
  }

  String get dayLabel {
    final start = startDateTime;
    if (start != null) {
      final now = DateTime.now();
      if (start.year == now.year &&
          start.month == now.month &&
          start.day == now.day) {
        return 'Hoy';
      }
      final dd = start.day.toString().padLeft(2, '0');
      final mm = start.month.toString().padLeft(2, '0');
      return '$dd/$mm';
    }
    return 'Hoy';
  }

  String getScorersSummary(String teamId) {
    final teamGoals = goals.where((g) => g.teamId == teamId).toList()
      ..sort((a, b) => a.time.compareTo(b.time));
    if (teamGoals.isEmpty) return '';

    final Map<String, List<String>> byPlayer = {};
    for (final g in teamGoals) {
      final name = g.playerShortName.isNotEmpty ? g.playerShortName : 'Gol';
      final suffix = g.isPenalty
          ? ' (P)'
          : g.isOwnGoal
              ? ' (e/c)'
              : '';
      final disp =
          '${g.timeToDisplay.isNotEmpty ? g.timeToDisplay : "${g.time}'"}$suffix';
      byPlayer.putIfAbsent(name, () => []).add(disp);
    }

    return byPlayer.entries
        .map((e) => '${e.key} ${e.value.join(' ')}')
        .join(' · ');
  }

  String get tvChannelsDisplay {
    final names = tvChannels
        .map((c) => c.name.trim())
        .where((n) => n.isNotEmpty)
        .toList();
    if (names.isEmpty) return '';
    return names.take(2).join(' · ');
  }
}

class SoccerData {
  final SoccerMeta meta;
  final String date;
  final SoccerSummary summary;
  final List<SoccerLeagueGroup> leagueGroups;
  final List<SoccerLeague> leagues;
  final List<SoccerTeam> teams;
  final List<SoccerMatch> matches;

  SoccerData({
    this.meta = const SoccerMeta(),
    this.date = '',
    this.summary = const SoccerSummary(),
    this.leagueGroups = const [],
    required this.leagues,
    required this.teams,
    required this.matches,
  });

  factory SoccerData.fromJson(Map<String, dynamic> rawJson) {
    final meta = rawJson['meta'] is Map<String, dynamic>
        ? SoccerMeta.fromJson(rawJson['meta'] as Map<String, dynamic>)
        : const SoccerMeta();

    final data = rawJson['data'] is Map<String, dynamic>
        ? rawJson['data'] as Map<String, dynamic>
        : rawJson;

    final summary = data['summary'] is Map<String, dynamic>
        ? SoccerSummary.fromJson(data['summary'] as Map<String, dynamic>)
        : const SoccerSummary();

    final groups = (data['leagues'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .where((e) => e.containsKey('league'))
            .map(SoccerLeagueGroup.fromJson)
            .toList() ??
        const <SoccerLeagueGroup>[];

    final matches = (data['matches'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(SoccerMatch.fromJson)
            .toList() ??
        groups.expand((g) => g.matches).toList();

    // Extraer ligas y equipos únicos para compatibilidad con MatchCard & búsqueda
    final leagueMap = <String, SoccerLeague>{};
    for (final g in groups) {
      if (g.league.id.isNotEmpty) {
        leagueMap[g.league.id] = g.league;
      }
    }
    for (final m in matches) {
      if (m.leagueData.id.isNotEmpty) {
        leagueMap.putIfAbsent(m.leagueData.id, () => m.leagueData);
      }
    }
    if (groups.isEmpty && data['leagues'] is List) {
      for (final l in (data['leagues'] as List).whereType<Map<String, dynamic>>()) {
        final parsed = SoccerLeague.fromJson(l);
        if (parsed.id.isNotEmpty) {
          leagueMap.putIfAbsent(parsed.id, () => parsed);
        }
      }
    }

    final teamMap = <String, SoccerTeam>{};
    for (final m in matches) {
      if (m.homeTeamData.id.isNotEmpty) {
        teamMap[m.homeTeamData.id] = m.homeTeamData;
      }
      if (m.awayTeamData.id.isNotEmpty) {
        teamMap[m.awayTeamData.id] = m.awayTeamData;
      }
    }
    if (data['teams'] is List) {
      for (final t in (data['teams'] as List).whereType<Map<String, dynamic>>()) {
        final parsed = SoccerTeam.fromJson(t);
        if (parsed.id.isNotEmpty) {
          teamMap.putIfAbsent(parsed.id, () => parsed);
        }
      }
    }

    return SoccerData(
      meta: meta,
      date: (data['date'] ?? '').toString(),
      summary: summary,
      leagueGroups: groups,
      leagues: leagueMap.values.toList(),
      teams: teamMap.values.toList(),
      matches: matches,
    );
  }
}

int _toInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

double? _toDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}
