# Plan de Implementación: Optimización y Seguridad del Reproductor de Video

## Resumen

Este plan implementa un sistema completo de optimización y seguridad para el reproductor de video de la aplicación Flutter Pivote. El sistema incluye 8 componentes principales: OptimizedURLResolver, WebViewAutoplayManager, JavaScriptBridge, SecurityLayer, AdaptiveBufferManager, PlayerWatchdog, IntelligentRetryManager y TelemetryCollector.

El plan está estructurado para construir incrementalmente desde los componentes base hasta la integración completa, con validación mediante property-based testing de las 61 propiedades de corrección definidas en el diseño.

## Tareas

- [x] 1. Configurar estructura base y modelos de datos
  - Crear directorio `lib/features/video_player/` con subdirectorios: `data/models/`, `domain/`, `presentation/`
  - Implementar modelos de datos: `StreamURL`, `PlayerState`, `BufferState`, `VideoQuality`, `SecurityEvent`, `RetryAttempt`, `TelemetryEvent`
  - Crear enums: `StreamType`, `PlaybackStatus`, `SecurityEventType`, `SecurityLevel`, `TelemetryEventType`
  - _Requisitos: 1.1, 2.1, 4.1, 9.1, 11.1_

- [ ] 2. Implementar OptimizedURLResolver con caché inteligente
  - [x] 2.1 Crear clase `URLCache` con TTL de 5 minutos
    - Implementar métodos `put()`, `get()`, `clear()` con gestión de expiración
    - _Requisitos: 1.4_
  
  - [x] 2.2 Escribir property test para caché de URLs
    - **Property 3: URL Resolution Caching Round-Trip**
    - **Valida: Requisitos 1.4**
  
  - [x] 2.3 Crear clase `CDNPatternDetector`
    - Implementar detección de patrones CDN conocidos (Cloudflare, Akamai, AWS CloudFront)
    - _Requisitos: 1.3_
  
  - [x] 2.4 Escribir property test para detección de CDN
    - **Property 2: Known CDN Patterns Skip Verification**
    - **Valida: Requisitos 1.3**
  
  - [x] 2.5 Implementar clase `OptimizedURLResolver`
    - Método `isDirectM3U8URL()` para detectar URLs M3U8 directas
    - Método `resolveStreamURL()` con timeout de 8 segundos
    - Integrar caché y detección de CDN
    - _Requisitos: 1.1, 1.2, 1.3, 1.4, 1.5_
  
  - [~] 2.6 Escribir property tests para OptimizedURLResolver
    - **Property 1: Direct M3U8 URLs Skip Resolution**
    - **Property 4: First Connection Timeout Limit**
    - **Valida: Requisitos 1.2, 1.5**
  
  - [~] 2.7 Escribir unit tests para OptimizedURLResolver
    - Test detección de URLs M3U8 directas con extensión .m3u8
    - Test detección de patrones CDN específicos
    - Test expiración de caché después de 5 minutos
    - Test timeout de 8 segundos en primer intento
    - _Requisitos: 1.2, 1.3, 1.4, 1.5_

- [~] 3. Checkpoint - Verificar resolución de URLs
  - Asegurar que todos los tests pasen, preguntar al usuario si surgen dudas.

- [ ] 4. Implementar IntelligentRetryManager con circuit breaker
  - [~] 4.1 Crear clases `ServerStats` y `CircuitBreaker`
    - Implementar tracking de éxitos/fallos por servidor
    - Implementar lógica de circuit breaker con threshold de 5 fallos
    - _Requisitos: 12.4, 12.5, 12.6_
  
  - [~] 4.2 Implementar clase `IntelligentRetryManager`
    - Método `calculateBackoff()` con backoff exponencial y jitter aleatorio
    - Método `attemptConnection()` con estrategia de reintentos
    - Método `getMostReliableServer()` basado en estadísticas
    - Lógica de reintento inmediato para fallos rápidos (< 3 segundos)
    - _Requisitos: 1.6, 12.1, 12.2, 12.3, 12.4, 12.5, 12.6_
  
  - [~] 4.3 Escribir property tests para IntelligentRetryManager
    - **Property 5: Fast Failure Immediate Retry**
    - **Property 56: Exponential Backoff with Jitter**
    - **Property 60: Circuit Breaker Activation**
    - **Valida: Requisitos 1.6, 12.2, 12.6**
  
  - [~] 4.4 Escribir unit tests para IntelligentRetryManager
    - Test backoff exponencial con valores específicos
    - Test circuit breaker se abre después de 5 fallos consecutivos
    - Test priorización de servidores confiables
    - Test espera de 30s cuando todos los servidores fallan
    - _Requisitos: 12.2, 12.3, 12.4, 12.6_

- [ ] 5. Implementar SecurityLayer completa
  - [~] 5.1 Crear clase `URLSanitizer`
    - Validar protocolos permitidos (http, https, rtmp, rtmps)
    - Validar longitud máxima de 2048 caracteres
    - Implementar blacklist de dominios maliciosos
    - Decodificar y validar caracteres especiales
    - Detectar scripts embebidos en URLs M3U8
    - _Requisitos: 4.6, 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.7_
  
  - [~] 5.2 Escribir property tests para URLSanitizer
    - **Property 20: URL Sanitization Before Use**
    - **Property 25: Protocol Validation**
    - **Property 29: URL Length Limit Enforcement**
    - **Valida: Requisitos 4.6, 6.1, 6.6, 6.7**
  
  - [~] 5.3 Crear clase `SSLValidator`
    - Validar certificados SSL/TLS
    - Implementar certificate pinning para dominios conocidos
    - Verificar versión TLS 1.2 o superior
    - Detectar downgrade attacks de HTTPS a HTTP
    - _Requisitos: 4.1, 4.2, 4.3, 4.4, 4.5_
  
  - [~] 5.4 Escribir property tests para SSLValidator
    - **Property 15: SSL Certificate Validation**
    - **Property 17: Certificate Pinning Enforcement**
    - **Property 18: TLS Version Enforcement**
    - **Valida: Requisitos 4.1, 4.3, 4.4**
  
  - [~] 5.5 Crear clase `CSPManager`
    - Generar Content Security Policy restrictiva
    - Configurar whitelist de dominios confiables
    - Deshabilitar acceso a archivos locales
    - _Requisitos: 5.1, 5.2_
  
  - [~] 5.6 Crear clase `TokenManager` con encriptación AES-256
    - Usar FlutterSecureStorage para almacenar tokens
    - Implementar encriptación/desencriptación AES-256
    - Implementar rotación automática cada 24 horas
    - Implementar limpieza de memoria al cerrar app
    - Detectar dispositivos comprometidos (root/jailbreak)
    - _Requisitos: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6, 7.7_
  
  - [~] 5.7 Escribir property tests para TokenManager
    - **Property 30: Token Encryption Round-Trip**
    - **Property 32: Token Rotation Schedule**
    - **Valida: Requisitos 7.1, 7.4**
  
  - [~] 5.8 Implementar clase `SecurityLayer` principal
    - Integrar URLSanitizer, SSLValidator, CSPManager, TokenManager
    - Implementar rate limiting de 10 req/s por dominio
    - Validar mensajes JavaScript con whitelist de comandos
    - _Requisitos: 4.7, 5.3, 5.4, 5.5, 5.6_
  
  - [~] 5.9 Escribir property tests para SecurityLayer
    - **Property 21: Rate Limiting Per Domain**
    - **Property 22: JavaScript Message Validation**
    - **Property 24: JavaScript Command Whitelist Enforcement**
    - **Valida: Requisitos 4.7, 5.3, 5.5**
  
  - [~] 5.10 Escribir unit tests para SecurityLayer
    - Test validación de certificados SSL válidos e inválidos
    - Test certificate pinning para dominios específicos
    - Test rechazo de certificados expirados
    - Test sanitización de URLs con caracteres especiales
    - Test rate limiting con múltiples solicitudes
    - Test validación de mensajes JavaScript válidos e inválidos
    - Test whitelist de comandos permitidos
    - Test blacklist de dominios maliciosos
    - _Requisitos: 4.1, 4.2, 4.3, 4.6, 4.7, 5.3, 5.5, 6.3_

- [~] 6. Checkpoint - Verificar seguridad
  - Asegurar que todos los tests de seguridad pasen, preguntar al usuario si surgen dudas.

- [ ] 7. Implementar SecurityLogger para eventos de seguridad
  - [~] 7.1 Crear clase `SecurityLogger`
    - Implementar niveles de logging (DEBUG, INFO, WARNING, ERROR, CRITICAL)
    - Registrar intentos de conexión fallidos con timestamp
    - Registrar validaciones de certificados SSL
    - Registrar intentos de inyección de código
    - Implementar rotación de logs cuando excedan 10MB
    - Enviar eventos críticos a analytics remoto
    - Notificar al usuario cuando ocurran 5 eventos críticos en 1 minuto
    - _Requisitos: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6, 8.7_
  
  - [~] 7.2 Escribir property tests para SecurityLogger
    - **Property 35: Failed Connection Logging**
    - **Property 38: Log Rotation on Size Limit**
    - **Property 40: Critical Event Threshold Notification**
    - **Valida: Requisitos 8.1, 8.5, 8.7**
  
  - [~] 7.3 Escribir unit tests para SecurityLogger
    - Test registro de intentos de conexión fallidos
    - Test registro de validaciones SSL
    - Test registro de intentos de inyección
    - Test rotación de logs al exceder 10MB
    - Test envío de eventos críticos a analytics
    - Test notificación al usuario con 5 eventos críticos en 1 minuto
    - _Requisitos: 8.1, 8.2, 8.3, 8.5, 8.6, 8.7_

- [ ] 8. Implementar AdaptiveBufferManager
  - [~] 8.1 Crear clase `NetworkSpeedDetector`
    - Detectar velocidad de conexión en Mbps
    - _Requisitos: 9.4, 9.5_
  
  - [~] 8.2 Implementar clase `AdaptiveBufferManager`
    - Configurar buffer mínimo de 3 segundos antes de reproducción
    - Mantener buffer objetivo de 10 segundos durante reproducción
    - Ajustar buffer según velocidad de red (15s para > 5 Mbps)
    - Aumentar prioridad de descarga cuando buffer < 2 segundos
    - Método `getMetrics()` para obtener estado del buffer
    - _Requisitos: 9.1, 9.2, 9.3, 9.4, 9.5_
  
  - [~] 8.3 Escribir property tests para AdaptiveBufferManager
    - **Property 41: Minimum Buffer Before Playback**
    - **Property 42: Target Buffer During Playback**
    - **Property 43: Low Buffer Priority Boost**
    - **Property 45: High Speed Buffer Increase**
    - **Valida: Requisitos 9.1, 9.2, 9.3, 9.5**
  
  - [~] 8.4 Escribir unit tests para AdaptiveBufferManager
    - Test buffer mínimo de 3 segundos antes de iniciar
    - Test buffer objetivo de 10 segundos durante reproducción
    - Test ajuste de buffer según velocidad de red
    - Test boost de prioridad cuando buffer < 2 segundos
    - _Requisitos: 9.1, 9.2, 9.3, 9.4_

- [ ] 9. Implementar PlayerWatchdog
  - [~] 9.1 Crear clase `PlayerWatchdog`
    - Verificar buffer health cada 2 segundos
    - Reducir frecuencia a 5 segundos cuando buffer saludable por > 30s
    - Detectar streams estancados
    - Implementar recuperación de streams estancados
    - _Requisitos: 9.6, 9.7_
  
  - [~] 9.2 Escribir property tests para PlayerWatchdog
    - **Property 46: Watchdog Check Frequency**
    - **Property 47: Healthy Buffer Check Frequency Reduction**
    - **Valida: Requisitos 9.6, 9.7**
  
  - [~] 9.3 Escribir unit tests para PlayerWatchdog
    - Test verificación cada 2 segundos por defecto
    - Test reducción a 5 segundos con buffer saludable
    - Test detección de streams estancados
    - _Requisitos: 9.6, 9.7_

- [~] 10. Checkpoint - Verificar buffer y watchdog
  - Asegurar que todos los tests de buffer pasen, preguntar al usuario si surgen dudas.

- [ ] 11. Implementar WebViewAutoplayManager
  - [~] 11.1 Crear clase `WebViewAutoplayManager`
    - Configurar políticas de autoplay en WebView
    - Detectar pausas automáticas vs pausas del usuario
    - Programar reanudación automática dentro de 500ms
    - Manejar retorno desde background
    - Mantener flag `_intentionalPlayback` para distinguir pausas
    - _Requisitos: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7_
  
  - [~] 11.2 Escribir property tests para WebViewAutoplayManager
    - **Property 6: Automatic Pause Detection and Recovery**
    - **Property 7: Background Resume Preservation**
    - **Property 9: Auto-Resume Time Limit**
    - **Valida: Requisitos 2.2, 2.3, 2.7**
  
  - [~] 11.3 Escribir unit tests para WebViewAutoplayManager
    - Test configuración de autoplay policy
    - Test detección de pausas automáticas
    - Test reanudación dentro de 500ms
    - Test manejo de retorno desde background
    - Test logging de pausas no solicitadas
    - _Requisitos: 2.1, 2.2, 2.3, 2.5, 2.7_

- [ ] 12. Implementar JavaScriptBridge
  - [~] 12.1 Crear clase `JavaScriptBridge`
    - Inicializar canal de comunicación bidireccional con JavaScriptChannel
    - Enviar comandos al reproductor (play, pause, mute, unmute, seek)
    - Recibir eventos de estado cada 1 segundo
    - Implementar heartbeat cada 2 segundos
    - Reiniciar WebView después de 3 heartbeats fallidos
    - Enviar eventos de error detallados con código y mensaje
    - _Requisitos: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7_
  
  - [~] 12.2 Escribir property tests para JavaScriptBridge
    - **Property 10: State Event Frequency**
    - **Property 11: JavaScript Command Confirmation Round-Trip**
    - **Property 12: Heartbeat Frequency**
    - **Property 13: Heartbeat Failure Recovery**
    - **Valida: Requisitos 3.2, 3.4, 3.5, 3.6**
  
  - [~] 12.3 Escribir unit tests para JavaScriptBridge
    - Test envío de comandos play, pause, mute, unmute, seek
    - Test recepción de eventos de estado
    - Test heartbeat cada 2 segundos
    - Test reinicio después de 3 heartbeats fallidos
    - Test eventos de error con código y mensaje
    - _Requisitos: 3.2, 3.3, 3.4, 3.5, 3.6, 3.7_

- [ ] 13. Implementar TelemetryCollector
  - [~] 13.1 Crear clase `TelemetryCollector`
    - Registrar tiempo de carga inicial por canal
    - Registrar cantidad de reintentos por sesión
    - Registrar eventos de buffering con duración y frecuencia
    - Calcular tiempo de reproducción vs tiempo de buffering
    - Enviar métricas agregadas a Firebase Analytics cada 5 minutos
    - Registrar tasa de éxito de resolución de URLs
    - Marcar servidores como problemáticos si tasa de fallo > 50%
    - _Requisitos: 11.1, 11.2, 11.3, 11.4, 11.5, 11.6, 11.7_
  
  - [~] 13.2 Escribir property tests para TelemetryCollector
    - **Property 48: Initial Load Time Telemetry**
    - **Property 52: Metrics Flush Frequency**
    - **Property 54: Problematic Server Detection**
    - **Valida: Requisitos 11.1, 11.5, 11.7**
  
  - [~] 13.3 Escribir unit tests para TelemetryCollector
    - Test registro de tiempo de carga inicial
    - Test registro de reintentos
    - Test registro de eventos de buffering
    - Test cálculo de calidad de reproducción
    - Test envío de métricas cada 5 minutos
    - Test marcado de servidores problemáticos
    - _Requisitos: 11.1, 11.2, 11.3, 11.4, 11.5, 11.7_

- [~] 14. Checkpoint - Verificar WebView y telemetría
  - Asegurar que todos los tests de WebView y telemetría pasen, preguntar al usuario si surgen dudas.

- [ ] 15. Implementar Error Handlers
  - [~] 15.1 Crear clases de error handlers
    - Implementar `NetworkErrorHandler` con reintentos automáticos
    - Implementar `SecurityErrorHandler` con bloqueo y logging
    - Implementar `PlaybackErrorHandler` con recuperación automática
    - Implementar `WebViewErrorHandler` con reinicio de WebView
    - Implementar `ErrorMessageProvider` con mensajes en español
    - _Requisitos: 12.1, 12.7_
  
  - [~] 15.2 Escribir property tests para error handlers
    - **Property 55: Temporary Network Error Silent Retry**
    - **Property 61: Network Restoration Auto-Resume**
    - **Valida: Requisitos 12.1, 12.7**
  
  - [~] 15.3 Escribir unit tests para error handlers
    - Test reintento automático para errores temporales
    - Test cambio a servidor alternativo en timeout
    - Test bloqueo de conexión en errores de seguridad
    - Test recuperación de buffer underrun
    - Test recuperación de stream estancado
    - Test reinicio de WebView en crash
    - _Requisitos: 12.1_

- [ ] 16. Implementar NativePlayerController optimizado
  - [~] 16.1 Crear clase `NativePlayerController`
    - Integrar OptimizedURLResolver para resolución paralela
    - Integrar IntelligentRetryManager para reintentos
    - Integrar AdaptiveBufferManager para gestión de buffer
    - Integrar PlayerWatchdog para monitoreo
    - Integrar SecurityLayer para validación
    - Integrar TelemetryCollector para métricas
    - Implementar inicialización paralela de resolución y reproductor
    - _Requisitos: 1.1, 1.7_
  
  - [~] 16.2 Escribir integration tests para NativePlayerController
    - Test flujo completo de reproducción M3U8 en < 5 segundos
    - Test recuperación de error de red con cambio de servidor
    - Test caché de URLs entre reproducciones
    - _Requisitos: 1.7_

- [ ] 17. Implementar WebViewPlayerController optimizado
  - [~] 17.1 Crear clase `WebViewPlayerController`
    - Integrar WebViewAutoplayManager para prevenir pausas
    - Integrar JavaScriptBridge para comunicación bidireccional
    - Integrar SecurityLayer con CSP y validación
    - Integrar TelemetryCollector para métricas
    - Configurar WebView con políticas de seguridad
    - _Requisitos: 2.1, 3.1, 5.1, 5.2_
  
  - [~] 17.2 Escribir integration tests para WebViewPlayerController
    - Test flujo completo de reproducción WebView sin pausas automáticas
    - Test comunicación bidireccional JavaScript-Flutter
    - Test recuperación de WebView crash
    - _Requisitos: 2.2, 3.4_

- [~] 18. Checkpoint - Verificar controllers
  - Asegurar que todos los tests de integración pasen, preguntar al usuario si surgen dudas.

- [ ] 19. Implementar UI moderna del reproductor
  - [~] 19.1 Crear widgets de controles de video
    - Implementar controles con animaciones fade-in/fade-out
    - Implementar indicadores de buffer circulares con porcentaje
    - Implementar gestos táctiles (doble tap, deslizar)
    - Mostrar información de calidad de stream (resolución, bitrate)
    - Implementar modo picture-in-picture para Android 8.0+
    - Usar iconos Material Design 3
    - Implementar tema oscuro optimizado
    - _Requisitos: 10.1, 10.2, 10.3, 10.4, 10.5, 10.6, 10.7_
  
  - [~] 19.2 Escribir widget tests para UI
    - Test animaciones de controles
    - Test gestos táctiles
    - Test indicadores de buffer
    - Test modo picture-in-picture
    - _Requisitos: 10.1, 10.2, 10.3, 10.5_

- [ ] 20. Crear generadores de datos para property tests
  - [~] 20.1 Implementar clase `TestDataGenerators`
    - Generador de URLs M3U8 aleatorias
    - Generador de URLs con longitud específica
    - Generador de StreamURL aleatorios
    - Generador de PlayerState aleatorios
    - Generador de BufferState aleatorios
    - Generador de VideoQuality aleatorios
    - _Testing support_
  
  - [~] 20.2 Crear mocks para testing
    - MockHTTPClient
    - MockWebViewController
    - MockFirebaseAnalytics
    - MockSecureStorage
    - _Testing support_

- [ ] 21. Integración final y wiring
  - [~] 21.1 Conectar todos los componentes
    - Integrar NativePlayerController en la UI
    - Integrar WebViewPlayerController en la UI
    - Configurar dependency injection para todos los componentes
    - Configurar Firebase Analytics
    - Configurar FlutterSecureStorage
    - _Requisitos: Todos_
  
  - [~] 21.2 Configurar CI/CD para tests
    - Crear workflow de GitHub Actions para ejecutar tests
    - Configurar reporte de cobertura
    - Configurar ejecución de property tests con 100 iteraciones
    - _Testing support_
  
  - [~] 21.3 Escribir tests end-to-end
    - Test flujo completo: selección de canal → reproducción → cambio de canal
    - Test flujo de recuperación: error de red → reconexión → reanudación
    - Test flujo de seguridad: URL maliciosa → bloqueo → notificación
    - _Requisitos: 1.7, 12.1, 4.2_

- [~] 22. Checkpoint final - Verificar sistema completo
  - Ejecutar todos los tests (unit, property, integration, e2e)
  - Verificar cobertura de código > 80%
  - Verificar que las 61 propiedades tienen property tests
  - Asegurar que todos los tests pasen, preguntar al usuario si surgen dudas.

## Notas

- Las tareas marcadas con `*` son opcionales y pueden omitirse para un MVP más rápido
- Cada tarea referencia los requisitos específicos que implementa para trazabilidad
- Los checkpoints aseguran validación incremental del sistema
- Los property tests validan las 61 propiedades de corrección universales
- Los unit tests validan casos específicos y condiciones de error
- Los integration tests validan flujos completos de usuario
- El sistema está diseñado en Dart/Flutter para la aplicación Pivote
- La implementación sigue una arquitectura modular con separación de responsabilidades
- Todos los componentes tienen telemetría y logging para diagnóstico proactivo
