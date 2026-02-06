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

  bool get isWatchable {
    return isLive || (isScheduled && tvChannels.any((c) => c.id != null));
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
