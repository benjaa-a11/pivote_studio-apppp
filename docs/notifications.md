# Notifications v2

La sección de notificaciones usa datos de fútbol en vivo ya disponibles en Pivote y noticias de fútbol mediante GNews.

## API key

No se guarda ninguna API key en el repositorio.

Para desarrollo local:

```bash
flutter run --dart-define=GNEWS_API_KEY=TU_API_KEY
```

Para un APK de producción, preferir un backend/proxy propio y mantener la clave exclusivamente en servidor. Si se compila con `GNEWS_API_KEY` vacío, Pivote sigue funcionando y muestra las notificaciones deportivas que tenga disponibles, pero no realiza consultas de noticias.

## Funciones

- Noticias reales ordenadas por fecha.
- Noticias con imagen, fuente y enlace externo.
- Partidos en vivo provenientes del `SoccerProvider` existente.
- Estado leído/no leído persistido localmente.
- Marcar todo como leído.
- Pull-to-refresh.
- Estados de carga, error y vacío.
- Compatibilidad con tema claro/oscuro.
