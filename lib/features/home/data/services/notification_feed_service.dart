import 'package:pivote/features/home/data/models/app_notification.dart';
import 'package:pivote/features/home/data/services/news_service.dart';
import 'package:pivote/features/soccer/data/models/soccer_models.dart';

class NotificationFeedService {
  static Future<List<AppNotification>> load({SoccerData? soccerData}) async {
    final results = <AppNotification>[];
    try { results.addAll(await NewsService.fetchFootballNews()); } catch (_) {}

    if (soccerData != null) {
      for (final match in soccerData.matches) {
        if (match.isLive) {
          final score = match.score.map((value) => value.toString()).join(' - ');
          results.add(AppNotification(id: 'match_${match.id}', title: '${match.homeTeam} vs ${match.awayTeam}', body: score.isEmpty ? 'Partido en vivo ahora' : 'En vivo · $score', source: 'Pivote Fútbol', publishedAt: DateTime.now(), type: AppNotificationType.match));
        }
        for (final goal in match.goals) {
          final team = goal.teamId == match.homeTeamId ? match.homeTeam : match.awayTeam;
          results.add(AppNotification(id: 'goal_${match.id}_${goal.time}_${goal.teamId}_${goal.playerShortName}', title: '¡Gol de $team!', body: '${goal.playerShortName} · ${goal.timeToDisplay}', source: 'Pivote Fútbol', publishedAt: DateTime.now(), type: AppNotificationType.goal));
        }
      }
    }
    results.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    return results;
  }
}
