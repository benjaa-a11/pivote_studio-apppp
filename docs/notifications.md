# Notifications v2

La sección de notificaciones combina actividad futbolística de Pivote con noticias reales de fútbol y funciona completamente dentro de la app.

## NewsData.io

La fuente de noticias es `https://newsdata.io/api/1/latest` usando la consulta gratuita proporcionada para fútbol y noticias de Argentina.

La integración consume los campos estructurados de la API como `results`, `article_id`, `title`, `description`, `content`, `pubDate`, `image_url` y `source_name`. NewsData documenta estos campos en su objeto de respuesta. citeturn818952search0turn818952search4

Las noticias no abren páginas web externas. Al tocar una noticia, Pivote la marca como leída y muestra el contenido disponible en un panel interno.

## Funciones

- Noticias reales ordenadas por fecha.
- Imágenes de las noticias cuando la API las proporciona.
- Detalle de la noticia dentro de Pivote.
- Partidos en vivo provenientes del `SoccerProvider` existente.
- Estado leído/no leído persistido localmente.
- Marcar todo como leído.
- Pull-to-refresh manual.
- Estados de carga, error y vacío.
- Compatibilidad con tema claro/oscuro.
- Sin `url_launcher` para noticias.

> La clave pública incluida en la URL de NewsData queda accesible en el cliente Android. Para una protección real de secretos, la consulta debería realizarse desde un backend/proxy.