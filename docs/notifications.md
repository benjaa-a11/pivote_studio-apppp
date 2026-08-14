# Notifications v2

La sección de notificaciones usa datos de fútbol en vivo ya disponibles en Pivote y noticias de fútbol mediante GNews.

## API key de GNews

La clave no se guarda en el repositorio ni se configura mediante `--dart-define`.

Pivote la obtiene en tiempo de ejecución desde Firestore:

- Colección: `api`
- Documento: `gnews`
- Campo: `apikey`

El valor del campo debe ser un `String` con la API key de GNews.

Si el documento o campo no existe, o la lectura falla, Pivote no realiza consultas a GNews y mantiene disponibles las notificaciones deportivas que tenga cargadas.

> Importante: al leer la clave desde Firestore directamente desde una app cliente, la clave sigue pudiendo ser recuperada por un cliente autorizado. Para ocultarla realmente, la consulta a GNews debería pasar por un backend/proxy seguro.

## Funciones

- Noticias reales ordenadas por fecha.
- Noticias con imagen, fuente y enlace externo.
- Partidos en vivo provenientes del `SoccerProvider` existente.
- Estado leído/no leído persistido localmente.
- Marcar todo como leído.
- Pull-to-refresh.
- Estados de carga, error y vacío.
- Compatibilidad con tema claro/oscuro.
