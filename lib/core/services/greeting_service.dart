/// Service to provide professional and culturally relevant (Argentine soccer-themed)
/// greetings throughout the application.
class GreetingService {
  static const List<String> _suffixes = [
    'crack',
    'genio',
    'figura',
    'maestro',
    'ídolo',
    'fenómeno',
    'campeón',
    'fiera',
    'máquina',
  ];

  static const List<String> _soccerPhrases = [
    'Hoy se alienta fuerte.',
    'La redonda no se mancha.',
    'Alineación confirmada.',
    'Todo listo para el partido.',
    'A dejarlo todo en la cancha.',
    'Seguí la pasión de cerca.',
    'Gritalo como si fuera una final.',
    'El fútbol es nuestra pasión.',
    'Pivote: donde vive la emoción.',
  ];

  static const Map<int, String> _dayMessages = {
    DateTime.monday: 'Arrancá la semana con todo.',
    DateTime.tuesday: 'Seguimos a paso firme.',
    DateTime.wednesday: 'Mitad de semana, dale que falta poco.',
    DateTime.thursday: 'Casi llegamos al fin de semana.',
    DateTime.friday: '¡Llegó el viernes! Se viene lo bueno.',
    DateTime.saturday: 'Sábado de fútbol y amigos.',
    DateTime.sunday: 'Domingo de asado y pasión.',
  };

  /// Returns a dynamic greeting based on the current time and Argentine flair.
  /// Example: "¡Buenos días, crack!"
  static String getGreeting() {
    final now = DateTime.now();
    final hour = now.hour;
    String base;

    if (hour >= 6 && hour < 12) {
      base = '¡Buenos días';
    } else if (hour >= 12 && hour < 20) {
      base = '¡Buenas tardes';
    } else {
      base = '¡Buenas noches';
    }

    // Deterministic suffix based on day of month and hour
    final index = (now.day + now.hour) % _suffixes.length;
    final suffix = _suffixes[index];
    return '$base, $suffix!';
  }

  /// Returns a dynamic subtitle/motto based on the day or soccer culture.
  static String getSubtitle() {
    final now = DateTime.now();

    // Use day of year to alternate between day message and soccer phrase
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;

    if (dayOfYear % 2 == 0) {
      return _dayMessages[now.weekday] ??
          _soccerPhrases[dayOfYear % _soccerPhrases.length];
    }

    return _soccerPhrases[dayOfYear % _soccerPhrases.length];
  }

  /// Helper to get formatted date in Spanish
  static String getFormattedDate() {
    final now = DateTime.now();
    final months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];

    final days = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo'
    ];

    return '${days[now.weekday - 1]}, ${now.day} de ${months[now.month - 1]}';
  }
}
