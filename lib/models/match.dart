import 'package:cloud_firestore/cloud_firestore.dart';

class Match {
  final String id;
  final String teamAId;
  final String teamBId;
  final String tournamentId;
  final DateTime startTime;
  final String date;
  final List<String> channelIds;

  Match({
    required this.id,
    required this.teamAId,
    required this.teamBId,
    required this.tournamentId,
    required this.startTime,
    required this.date,
    required this.channelIds,
  });

  /// Verifica si el botón "Ver Partido" debe estar habilitado
  /// Se habilita 30 minutos antes del inicio
  bool get isWatchable {
    final now = DateTime.now();
    final thirtyMinutesBefore = startTime.subtract(const Duration(minutes: 30));
    return now.isAfter(thirtyMinutesBefore) && !isFinished;
  }

  /// Verifica si el partido está en vivo
  /// Un partido está en vivo desde su hora de inicio hasta 2.5 horas después
  bool get isLive {
    final now = DateTime.now();
    final endTime = startTime.add(const Duration(hours: 2, minutes: 30));
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  /// Verifica si el partido ha finalizado
  /// Un partido finaliza 2 horas y 30 minutos después del inicio
  bool get isFinished {
    final now = DateTime.now();
    final endTime = startTime.add(const Duration(hours: 2, minutes: 30));
    return now.isAfter(endTime);
  }

  /// Verifica si el partido es de hoy
  bool get isToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final matchDay = DateTime(startTime.year, startTime.month, startTime.day);
    return today == matchDay;
  }

  /// Tiempo restante formateado
  String get timeUntilStart {
    final now = DateTime.now();
    final difference = startTime.difference(now);
    
    if (isLive) {
      return 'En vivo';
    } else if (isFinished) {
      return 'Finalizado';
    } else if (difference.isNegative) {
      return 'Próximamente';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ${difference.inMinutes % 60}m';
    } else {
      return '${difference.inDays}d';
    }
  }

  /// Estado del partido para mostrar en la UI
  String get status {
    if (isLive) {
      return 'EN VIVO';
    } else if (isFinished) {
      return 'FINALIZADO';
    } else if (isWatchable) {
      return 'DISPONIBLE';
    } else {
      return 'PRÓXIMAMENTE';
    }
  }

  factory Match.fromJson(Map<String, dynamic> json) {
    List<String> channels = [];
    if (json['channels'] is List) {
      channels = List<String>.from(json['channels']);
    }

    return Match(
      id: json['id'] ?? '',
      teamAId: json['team1'] ?? '',
      teamBId: json['team2'] ?? '',
      tournamentId: json['tournamentId'] ?? '',
      startTime: (json['time'] as Timestamp).toDate(),
      date: json['dates'] ?? '', // Changed from 'date' to 'dates'
      channelIds: channels,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'team1': teamAId,
      'team2': teamBId,
      'tournamentId': tournamentId,
      'time': Timestamp.fromDate(startTime),
      'date': date,
      'channels': channelIds,
    };
  }

  @override
  String toString() {
    return 'Match(id: $id, startTime: $startTime, status: $status)';
  }
}