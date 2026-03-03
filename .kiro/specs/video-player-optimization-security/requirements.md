# Documento de Requisitos: Optimización y Seguridad del Reproductor de Video

## Introducción

Este documento define los requisitos para optimizar el rendimiento del reproductor de video de streaming en vivo y mejorar la seguridad general de la aplicación Flutter Pivote. El sistema actual utiliza dos tipos de reproductores: uno nativo para streams M3U8/HLS y uno basado en WebView para streams DASH/Iframe. Se han identificado problemas de rendimiento en la carga inicial y pausas automáticas inesperadas en el reproductor WebView que afectan la experiencia del usuario.

## Glosario

- **Video_Player_System**: Sistema completo de reproducción de video que incluye el reproductor nativo y el reproductor WebView
- **Native_Player**: Reproductor nativo de Flutter que maneja streams M3U8/HLS usando el paquete video_player
- **WebView_Player**: Reproductor basado en WebView (PivoProPlayer) que maneja streams DASH, Iframe y externos
- **Stream_Resolution**: Proceso de resolución de URL que determina la URL final del stream de video
- **Initial_Load_Time**: Tiempo transcurrido desde que el usuario selecciona un canal hasta que el video comienza a reproducirse
- **Auto_Pause**: Pausa automática no solicitada del video durante la reproducción
- **Retry_Attempt**: Intento de reconexión cuando falla la carga inicial o durante la reproducción
- **Security_Layer**: Capa de seguridad que protege la aplicación contra vulnerabilidades y accesos no autorizados
- **Buffer_Health**: Métrica que indica la cantidad de contenido de video precargado disponible para reproducción
- **Watchdog**: Mecanismo de monitoreo que detecta y recupera streams estancados o con problemas

## Requisitos

### Requisito 1: Optimización de Carga Inicial del Reproductor M3U8

**User Story:** Como usuario, quiero que los canales de video comiencen a reproducirse más rápido, para que pueda disfrutar del contenido sin esperas prolongadas.

#### Acceptance Criteria

1. WHEN el usuario selecciona un canal M3U8, THE Native_Player SHALL iniciar la resolución de URL en paralelo con la inicialización del reproductor
2. WHEN la URL del stream es claramente identificable como M3U8 directa, THE Stream_Resolution SHALL omitir el proceso de resolución HTTP
3. WHEN se detecta un patrón de CDN conocido en la URL, THE Stream_Resolution SHALL omitir las verificaciones HEAD/GET adicionales
4. THE Native_Player SHALL cachear las URLs resueltas exitosamente por un período de 5 minutos para evitar resoluciones repetidas
5. WHEN ocurre el primer intento de conexión, THE Native_Player SHALL usar un timeout reducido de 8 segundos en lugar de 18 segundos
6. WHEN el primer intento falla rápidamente (menos de 3 segundos), THE Native_Player SHALL reintentar inmediatamente sin backoff delay
7. THE Initial_Load_Time SHALL ser menor a 5 segundos en el 80% de los casos con conexión estable

### Requisito 2: Eliminación de Pausas Automáticas en WebView Player

**User Story:** Como usuario, quiero que el video en WebView se reproduzca continuamente sin pausas inesperadas, para que pueda ver el contenido sin interrupciones.

#### Acceptance Criteria

1. WHEN el WebView_Player carga una página, THE WebView_Player SHALL configurar la política de autoplay para permitir reproducción automática
2. WHEN el video se pausa automáticamente sin intervención del usuario, THE WebView_Player SHALL detectar el evento de pausa y reiniciar la reproducción automáticamente
3. WHEN la aplicación regresa del background, THE WebView_Player SHALL verificar el estado de reproducción y reanudar si estaba reproduciendo previamente
4. THE WebView_Player SHALL implementar un listener de eventos de pausa del elemento de video HTML
5. WHEN se detecta una pausa no solicitada, THE WebView_Player SHALL registrar el evento en logs para diagnóstico
6. THE WebView_Player SHALL mantener un flag de "reproducción intencional" para distinguir pausas del usuario de pausas automáticas
7. WHEN ocurre una pausa automática, THE WebView_Player SHALL intentar reanudar la reproducción dentro de 500ms

### Requisito 3: Mejora de Comunicación JavaScript-Flutter en WebView

**User Story:** Como desarrollador, quiero una comunicación bidireccional robusta entre el WebView y Flutter, para que pueda controlar y monitorear el reproductor de manera confiable.

#### Acceptance Criteria

1. THE WebView_Player SHALL implementar un canal de comunicación bidireccional usando JavaScriptChannel
2. WHEN el video HTML cambia de estado, THE WebView_Player SHALL enviar eventos de estado a Flutter cada 1 segundo
3. THE WebView_Player SHALL exponer métodos JavaScript para play, pause, mute, unmute y seek
4. WHEN Flutter invoca un comando JavaScript, THE WebView_Player SHALL confirmar la ejecución mediante un evento de respuesta
5. THE WebView_Player SHALL implementar un heartbeat cada 2 segundos para verificar que el WebView está respondiendo
6. WHEN el heartbeat falla 3 veces consecutivas, THE WebView_Player SHALL reiniciar el WebView
7. THE WebView_Player SHALL enviar eventos de error detallados incluyendo código de error y mensaje descriptivo

### Requisito 4: Seguridad de Comunicación de Red

**User Story:** Como usuario, quiero que mis datos de streaming estén protegidos, para que mi privacidad y seguridad estén garantizadas.

#### Acceptance Criteria

1. THE Video_Player_System SHALL validar todos los certificados SSL/TLS para conexiones HTTPS
2. WHEN un certificado SSL es inválido o ha expirado, THE Video_Player_System SHALL rechazar la conexión y mostrar un error al usuario
3. THE Video_Player_System SHALL implementar certificate pinning para dominios de streaming conocidos y confiables
4. THE Video_Player_System SHALL usar TLS 1.2 o superior para todas las conexiones HTTPS
5. WHEN se detecta un downgrade attack de HTTPS a HTTP, THE Video_Player_System SHALL bloquear la conexión
6. THE Video_Player_System SHALL sanitizar todas las URLs antes de realizar solicitudes HTTP
7. THE Video_Player_System SHALL implementar rate limiting de 10 solicitudes por segundo por dominio para prevenir ataques de denegación de servicio

### Requisito 5: Protección contra Inyección de Código en WebView

**User Story:** Como usuario, quiero que la aplicación esté protegida contra código malicioso, para que mi dispositivo y datos estén seguros.

#### Acceptance Criteria

1. THE WebView_Player SHALL implementar Content Security Policy (CSP) restrictiva que solo permita scripts de dominios confiables
2. THE WebView_Player SHALL deshabilitar el acceso a archivos locales mediante setAllowFileAccess(false)
3. THE WebView_Player SHALL validar y sanitizar todos los mensajes recibidos desde JavaScript antes de procesarlos
4. WHEN se recibe un mensaje JavaScript con formato inválido, THE WebView_Player SHALL descartar el mensaje y registrar el intento
5. THE WebView_Player SHALL implementar una whitelist de comandos JavaScript permitidos
6. WHEN se intenta ejecutar un comando JavaScript no autorizado, THE WebView_Player SHALL bloquear la ejecución y registrar el evento
7. THE WebView_Player SHALL usar un sandbox aislado para la ejecución de contenido web

### Requisito 6: Validación y Sanitización de URLs de Streaming

**User Story:** Como usuario, quiero que la aplicación solo cargue contenido de fuentes legítimas, para evitar contenido malicioso o inapropiado.

#### Acceptance Criteria

1. THE Video_Player_System SHALL validar que todas las URLs de streaming usen protocolos permitidos (http, https, rtmp, rtmps)
2. WHEN una URL contiene caracteres especiales o codificación sospechosa, THE Video_Player_System SHALL decodificar y validar la URL
3. THE Video_Player_System SHALL implementar una blacklist de dominios conocidos por distribuir malware
4. WHEN una URL coincide con la blacklist, THE Video_Player_System SHALL rechazar la carga y notificar al usuario
5. THE Video_Player_System SHALL validar que las URLs M3U8 no contengan scripts embebidos o payloads maliciosos
6. THE Video_Player_System SHALL limitar la longitud máxima de URLs a 2048 caracteres
7. WHEN una URL excede el límite de longitud, THE Video_Player_System SHALL rechazar la URL y registrar el evento

### Requisito 7: Gestión Segura de Credenciales y Tokens

**User Story:** Como usuario, quiero que mis credenciales de autenticación estén protegidas, para que nadie pueda acceder a mi cuenta sin autorización.

#### Acceptance Criteria

1. THE Security_Layer SHALL almacenar todos los tokens de autenticación usando encriptación AES-256
2. THE Security_Layer SHALL usar el keystore del sistema operativo para almacenar claves de encriptación
3. WHEN la aplicación se cierra, THE Security_Layer SHALL limpiar todos los tokens de la memoria
4. THE Security_Layer SHALL implementar rotación automática de tokens cada 24 horas
5. WHEN un token expira, THE Security_Layer SHALL solicitar renovación automática sin intervención del usuario
6. THE Security_Layer SHALL implementar detección de root/jailbreak y advertir al usuario sobre riesgos de seguridad
7. WHEN se detecta un dispositivo comprometido, THE Security_Layer SHALL deshabilitar el almacenamiento de credenciales en el dispositivo

### Requisito 8: Monitoreo y Logging de Seguridad

**User Story:** Como desarrollador, quiero registrar eventos de seguridad relevantes, para poder identificar y responder a amenazas potenciales.

#### Acceptance Criteria

1. THE Security_Layer SHALL registrar todos los intentos de conexión fallidos con timestamp y razón del fallo
2. THE Security_Layer SHALL registrar todos los eventos de validación de certificados SSL
3. WHEN se detecta un intento de inyección de código, THE Security_Layer SHALL registrar el evento con detalles completos
4. THE Security_Layer SHALL implementar niveles de logging (DEBUG, INFO, WARNING, ERROR, CRITICAL)
5. THE Security_Layer SHALL rotar logs automáticamente cuando excedan 10MB de tamaño
6. THE Security_Layer SHALL enviar eventos críticos de seguridad a un servicio de analytics remoto
7. WHEN ocurren 5 eventos de seguridad críticos en 1 minuto, THE Security_Layer SHALL notificar al usuario y sugerir acciones correctivas

### Requisito 9: Optimización de Rendimiento del Buffer

**User Story:** Como usuario, quiero que el video se reproduzca sin interrupciones de buffering, para disfrutar de una experiencia de visualización fluida.

#### Acceptance Criteria

1. THE Native_Player SHALL configurar un buffer mínimo de 3 segundos antes de iniciar la reproducción
2. THE Native_Player SHALL mantener un buffer objetivo de 10 segundos durante la reproducción
3. WHEN el Buffer_Health cae por debajo de 2 segundos, THE Native_Player SHALL aumentar la prioridad de descarga de segmentos
4. THE Native_Player SHALL implementar buffer adaptativo que ajusta el tamaño según la velocidad de conexión detectada
5. WHEN la velocidad de conexión es mayor a 5 Mbps, THE Native_Player SHALL aumentar el buffer objetivo a 15 segundos
6. THE Watchdog SHALL verificar el Buffer_Health cada 2 segundos en lugar de cada 3 segundos
7. WHEN el buffer está saludable por más de 30 segundos, THE Watchdog SHALL reducir la frecuencia de verificación a cada 5 segundos para ahorrar recursos

### Requisito 10: Modernización de la Interfaz de Usuario del Reproductor

**User Story:** Como usuario, quiero una interfaz de reproductor moderna y profesional, para tener una experiencia visual atractiva y fácil de usar.

#### Acceptance Criteria

1. THE Video_Player_System SHALL implementar controles de video con animaciones fluidas de fade-in/fade-out
2. THE Video_Player_System SHALL mostrar indicadores de buffer con diseño circular moderno y porcentaje de progreso
3. THE Video_Player_System SHALL implementar gestos táctiles: doble tap para play/pause, deslizar para ajustar volumen y brillo
4. THE Video_Player_System SHALL mostrar información de calidad de stream (resolución, bitrate) en un overlay discreto
5. THE Video_Player_System SHALL implementar modo picture-in-picture para Android 8.0 y superior
6. THE Video_Player_System SHALL usar iconos modernos y consistentes con Material Design 3
7. THE Video_Player_System SHALL implementar tema oscuro optimizado para visualización de video con contraste mejorado

### Requisito 11: Telemetría y Diagnóstico de Rendimiento

**User Story:** Como desarrollador, quiero recopilar métricas de rendimiento del reproductor, para identificar y resolver problemas de manera proactiva.

#### Acceptance Criteria

1. THE Video_Player_System SHALL registrar el Initial_Load_Time para cada reproducción de canal
2. THE Video_Player_System SHALL registrar la cantidad de Retry_Attempts por sesión de reproducción
3. THE Video_Player_System SHALL registrar eventos de buffering con duración y frecuencia
4. THE Video_Player_System SHALL calcular y registrar el tiempo total de reproducción exitosa vs tiempo de buffering
5. THE Video_Player_System SHALL enviar métricas agregadas a Firebase Analytics cada 5 minutos
6. THE Video_Player_System SHALL registrar la tasa de éxito de resolución de URLs (exitosas vs fallidas)
7. WHEN la tasa de fallo de un servidor específico excede el 50%, THE Video_Player_System SHALL marcar el servidor como problemático y reducir su prioridad

### Requisito 12: Recuperación Inteligente de Errores

**User Story:** Como usuario, quiero que la aplicación se recupere automáticamente de errores de conexión, para minimizar las interrupciones en mi experiencia de visualización.

#### Acceptance Criteria

1. WHEN ocurre un error de red temporal, THE Video_Player_System SHALL reintentar automáticamente sin mostrar error al usuario
2. THE Video_Player_System SHALL implementar backoff exponencial con jitter aleatorio para evitar thundering herd
3. WHEN todos los servidores de un canal fallan, THE Video_Player_System SHALL esperar 30 segundos y reintentar desde el primer servidor
4. THE Video_Player_System SHALL mantener estadísticas de confiabilidad por servidor y priorizar servidores más confiables
5. WHEN un servidor falla consistentemente, THE Video_Player_System SHALL mover ese servidor al final de la lista de prioridad
6. THE Video_Player_System SHALL implementar circuit breaker: después de 5 fallos consecutivos, pausar intentos por 60 segundos
7. WHEN la conexión a internet se restaura después de una desconexión, THE Video_Player_System SHALL reanudar automáticamente la reproducción
