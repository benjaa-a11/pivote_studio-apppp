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

  SoccerTeam({
    required this.id,
    required this.name,
    required this.shortName,
    this.logoUrl,
  });

  factory SoccerTeam.fromJson(Map<String, dynamic> json) {
    return SoccerTeam(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      shortName: json['shortName'] ?? '',
      logoUrl: json['logoUrl'] as String?,
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
  final List<String> tvChannels;
  final String stage;
  final List<SoccerGoal> goals;
  final Map<String, dynamic>? statistics;
  final String? detailsApiUrl;

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
    this.statistics,
    this.detailsApiUrl,
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
      tvChannels: List<String>.from(json['tvChannels'] ?? []),
      stage: json['stage'] ?? '',
      goals: (json['goals'] as List?)
              ?.map((g) => SoccerGoal.fromJson(g))
              .toList() ??
          [],
      statistics: json['statistics'] as Map<String, dynamic>?,
      detailsApiUrl: json['detailsApiUrl'] as String?,
    );
  }

  // Statistics helpers
  double get possessionHome => _getStatValue('possession', true).toDouble();
  double get possessionAway => _getStatValue('possession', false).toDouble();

  int get shotsHome => _getStatValue('shots', true).toInt();
  int get shotsAway => _getStatValue('shots', false).toInt();

  int get shotsOnTargetHome => _getStatValue('shotsOnTarget', true).toInt();
  int get shotsOnTargetAway => _getStatValue('shotsOnTarget', false).toInt();

  int get cornersHome => _getStatValue('corners', true).toInt();
  int get cornersAway => _getStatValue('corners', false).toInt();

  int get foulsHome => _getStatValue('fouls', true).toInt();
  int get foulsAway => _getStatValue('fouls', false).toInt();

  int get yellowCardsHome => _getStatValue('yellowCards', true).toInt();
  int get yellowCardsAway => _getStatValue('yellowCards', false).toInt();

  num _getStatValue(String key, bool isHome) {
    if (statistics == null || statistics![key] == null) {
      if (key == 'possession') return 50;
      return 0;
    }
    final stat = statistics![key];
    return isHome ? (stat['home'] ?? 0) : (stat['away'] ?? 0);
  }

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

class MatchDetailData {
  final String lastUpdated;
  final MatchInfo matchInfo;
  final MatchLineups lineups;
  final List<TimelineEvent> timeline;
  final MatchStats stats;
  final HeadToHead headToHead;
  final List<int> recentFormHome;
  final List<int> recentFormAway;
  final Standings? standings;

  MatchDetailData({
    required this.lastUpdated,
    required this.matchInfo,
    required this.lineups,
    required this.timeline,
    required this.stats,
    required this.headToHead,
    required this.recentFormHome,
    required this.recentFormAway,
    this.standings,
  });

  factory MatchDetailData.fromJson(Map<String, dynamic> json) {
    return MatchDetailData(
      lastUpdated: json['lastUpdated'] ?? '',
      matchInfo: MatchInfo.fromJson(json['matchInfo'] ?? {}),
      lineups: MatchLineups.fromJson(json['lineups'] ?? {}),
      timeline: (json['timeline'] as List?)
              ?.map((e) => TimelineEvent.fromJson(e))
              .toList() ??
          [],
      stats: MatchStats.fromJson(json['stats'] ?? {}),
      headToHead: HeadToHead.fromJson(json['headToHead'] ?? {}),
      recentFormHome: List<int>.from(json['recentForm']?['home'] ?? []),
      recentFormAway: List<int>.from(json['recentForm']?['away'] ?? []),
      standings: json['standings'] != null
          ? Standings.fromJson(json['standings'])
          : null,
    );
  }
}

class MatchInfo {
  final String id;
  final String status;
  final String statusShortName;
  final String stage;
  final String? winner;
  final Map<String, MatchTeamInfo> teams;
  final Map<String, int> score;
  final MatchVenue venue;
  final MatchLeague league;
  final String startTime;
  final String gameTimeStatusToDisplay;

  MatchInfo({
    required this.id,
    required this.status,
    required this.statusShortName,
    required this.stage,
    this.winner,
    required this.teams,
    required this.score,
    required this.venue,
    required this.league,
    required this.startTime,
    required this.gameTimeStatusToDisplay,
  });

  factory MatchInfo.fromJson(Map<String, dynamic> json) {
    final teamsMap = (json['teams'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(key, MatchTeamInfo.fromJson(value)),
        ) ??
        {};
    final scoreMap = (json['score'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(key, value as int),
        ) ??
        {};

    return MatchInfo(
      id: json['id'] ?? '',
      status: json['status'] ?? '',
      statusShortName: json['statusShortName'] ?? '',
      stage: json['stage'] ?? '',
      winner: json['winner'],
      teams: teamsMap,
      score: scoreMap,
      venue: MatchVenue.fromJson(json['venue'] ?? {}),
      league: MatchLeague.fromJson(json['league'] ?? {}),
      startTime: json['startTime'] ?? '',
      gameTimeStatusToDisplay: json['gameTimeStatusToDisplay'] ?? '',
    );
  }
}

class MatchTeamInfo {
  final String name;
  final String shortName;
  final String id;
  final String? urlName;
  final String? countryId;
  final Map<String, String>? colors;

  MatchTeamInfo({
    required this.name,
    required this.shortName,
    required this.id,
    this.urlName,
    this.countryId,
    this.colors,
  });

  factory MatchTeamInfo.fromJson(Map<String, dynamic> json) {
    return MatchTeamInfo(
      name: json['name'] ?? '',
      shortName: json['shortName'] ?? '',
      id: json['id'] ?? '',
      urlName: json['urlName'],
      countryId: json['countryId'],
      colors: (json['colors'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
    );
  }
}

class MatchVenue {
  final String? stadiumName;
  final int? capacity;
  final String? referee;
  final List<String> broadcasters;

  MatchVenue({
    this.stadiumName,
    this.capacity,
    this.referee,
    required this.broadcasters,
  });

  factory MatchVenue.fromJson(Map<String, dynamic> json) {
    return MatchVenue(
      stadiumName: json['stadiumName'],
      capacity: json['capacity'],
      referee: json['referee'],
      broadcasters: List<String>.from(json['broadcasters'] ?? []),
    );
  }
}

class MatchLeague {
  final String name;
  final String id;
  final String? urlName;
  final String? countryName;

  MatchLeague({
    required this.name,
    required this.id,
    this.urlName,
    this.countryName,
  });

  factory MatchLeague.fromJson(Map<String, dynamic> json) {
    return MatchLeague(
      name: json['name'] ?? '',
      id: json['id'] ?? '',
      urlName: json['urlName'],
      countryName: json['countryName'],
    );
  }
}

class MatchLineups {
  final TeamLineup home;
  final TeamLineup away;

  MatchLineups({required this.home, required this.away});

  factory MatchLineups.fromJson(Map<String, dynamic> json) {
    return MatchLineups(
      home: TeamLineup.fromJson(json['home'] ?? {}),
      away: TeamLineup.fromJson(json['away'] ?? {}),
    );
  }
}

class TeamLineup {
  final String? formation;
  final List<Player> starting;
  final List<Player> bench;
  final List<Player> missing;
  final List<Staff> staff;
  final String status;

  TeamLineup({
    this.formation,
    required this.starting,
    required this.bench,
    required this.missing,
    required this.staff,
    required this.status,
  });

  factory TeamLineup.fromJson(Map<String, dynamic> json) {
    return TeamLineup(
      formation: json['formation'],
      starting: (json['starting'] as List?)
              ?.map((p) => Player.fromJson(p))
              .toList() ??
          [],
      bench:
          (json['bench'] as List?)?.map((p) => Player.fromJson(p)).toList() ??
              [],
      missing:
          (json['missing'] as List?)?.map((p) => Player.fromJson(p)).toList() ??
              [],
      staff: (json['staff'] as List?)?.map((s) => Staff.fromJson(s)).toList() ??
          [],
      status: json['status'] ?? '',
    );
  }
}

class Player {
  final String name;
  final String shortName;
  final int? jerseyNumber;
  final String? position;
  final String? formationPosition;
  final bool? isCaptain;
  final bool? isSubstituted;
  final int? substitutionTime;
  final Map<String, dynamic>? events;
  final int? age;
  final String? height;
  final String? reason; // For missing players

  Player({
    required this.name,
    required this.shortName,
    this.jerseyNumber,
    this.position,
    this.formationPosition,
    this.isCaptain,
    this.isSubstituted,
    this.substitutionTime,
    this.events,
    this.age,
    this.height,
    this.reason,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      name: json['name'] ?? '',
      shortName: json['shortName'] ?? '',
      jerseyNumber: json['jerseyNumber'],
      position: json['position'],
      formationPosition: json['formationPosition'],
      isCaptain: json['isCaptain'],
      isSubstituted: json['isSubstituted'],
      substitutionTime: json['substitutionTime'],
      events: json['events'],
      age: json['age'],
      height: json['height']?.toString(),
      reason: json['reason'],
    );
  }
}

class Staff {
  final String name;
  final String shortName;
  final String position;

  Staff({
    required this.name,
    required this.shortName,
    required this.position,
  });

  factory Staff.fromJson(Map<String, dynamic> json) {
    return Staff(
      name: json['name'] ?? '',
      shortName: json['shortName'] ?? '',
      position: json['position'] ?? '',
    );
  }
}

class TimelineEvent {
  final int minute;
  final String displayTime;
  final String team;
  final String type;
  final String? player;
  final String? playerIn;
  final String? playerOut;
  final String? detail;
  final List<String>? texts;

  TimelineEvent({
    required this.minute,
    required this.displayTime,
    required this.team,
    required this.type,
    this.player,
    this.playerIn,
    this.playerOut,
    this.detail,
    this.texts,
  });

  factory TimelineEvent.fromJson(Map<String, dynamic> json) {
    return TimelineEvent(
      minute: json['minute'] ?? 0,
      displayTime: json['displayTime'] ?? '',
      team: json['team'] ?? '',
      type: json['type'] ?? '',
      player: json['player'],
      playerIn: json['playerIn'],
      playerOut: json['playerOut'],
      detail: json['detail'],
      texts: (json['texts'] as List?)?.map((t) => t.toString()).toList(),
    );
  }
}

class MatchStats {
  final List<StatRawItem> raw;

  MatchStats({required this.raw});

  factory MatchStats.fromJson(Map<String, dynamic> json) {
    return MatchStats(
      raw: (json['raw'] as List?)
              ?.map((i) => StatRawItem.fromJson(i))
              .toList() ??
          [],
    );
  }
}

class StatRawItem {
  final String name;
  final List<String> values;
  final List<double> percentages;

  StatRawItem({
    required this.name,
    required this.values,
    required this.percentages,
  });

  factory StatRawItem.fromJson(Map<String, dynamic> json) {
    return StatRawItem(
      name: json['name'] ?? '',
      values: List<String>.from(json['values'] ?? []),
      percentages: (json['percentages'] as List?)
              ?.map((p) => (p as num).toDouble())
              .toList() ??
          [],
    );
  }
}

class HeadToHead {
  final H2HSummary summary;
  final List<H2HGame> games;

  HeadToHead({required this.summary, required this.games});

  factory HeadToHead.fromJson(Map<String, dynamic> json) {
    return HeadToHead(
      summary: H2HSummary.fromJson(json['summary'] ?? {}),
      games:
          (json['games'] as List?)?.map((g) => H2HGame.fromJson(g)).toList() ??
              [],
    );
  }
}

class H2HSummary {
  final int homeWins;
  final int awayWins;
  final int draws;
  final int totalGames;

  H2HSummary({
    required this.homeWins,
    required this.awayWins,
    required this.draws,
    required this.totalGames,
  });

  factory H2HSummary.fromJson(Map<String, dynamic> json) {
    return H2HSummary(
      homeWins: json['homeWins'] ?? 0,
      awayWins: json['awayWins'] ?? 0,
      draws: json['draws'] ?? 0,
      totalGames: json['totalGames'] ?? 0,
    );
  }
}

class H2HGame {
  final String date;
  final String homeTeam;
  final String awayTeam;
  final String score;
  final String? winner;
  final String? leagueName;

  H2HGame({
    required this.date,
    required this.homeTeam,
    required this.awayTeam,
    required this.score,
    this.winner,
    this.leagueName,
  });

  factory H2HGame.fromJson(Map<String, dynamic> json) {
    return H2HGame(
      date: json['date'] ?? '',
      homeTeam: json['homeTeam'] ?? '',
      awayTeam: json['awayTeam'] ?? '',
      score: json['score'] ?? '',
      winner: json['winner'],
      leagueName: json['league']?['name'],
    );
  }
}

class Standings {
  final String title;
  final List<StandingRow> rows;

  Standings({required this.title, required this.rows});

  factory Standings.fromJson(Map<String, dynamic> json) {
    return Standings(
      title: json['title'] ?? '',
      rows: (json['rows'] as List?)
              ?.map((r) => StandingRow.fromJson(r))
              .toList() ??
          [],
    );
  }
}

class StandingRow {
  final int num;
  final String teamName;
  final String? teamShortName;
  final Map<String, String> values;

  StandingRow({
    required this.num,
    required this.teamName,
    this.teamShortName,
    required this.values,
  });

  factory StandingRow.fromJson(Map<String, dynamic> json) {
    final valuesMap = <String, String>{};
    if (json['values'] is List) {
      for (var v in (json['values'] as List)) {
        valuesMap[v['key']] = v['value'].toString();
      }
    }

    return StandingRow(
      num: json['num'] ?? 0,
      teamName: json['entity']?['object']?['name'] ?? '',
      teamShortName: json['entity']?['object']?['short_name'],
      values: valuesMap,
    );
  }
}
