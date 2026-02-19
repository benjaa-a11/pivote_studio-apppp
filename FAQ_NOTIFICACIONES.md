# ❓ Preguntas Frecuentes - Notificaciones y Google Sign-In

## 🔐 Google Sign-In

### ❓ ¿Por qué Google Sign-In no funciona?

**Respuesta:** El problema más común es que los certificados SHA-1 y SHA-256 no están configurados en Firebase Console.

**Solución:**
1. Ejecuta `get_sha.bat` (Windows) o `get_sha.sh` (Linux/Mac)
2. Copia los valores SHA-1 y SHA-256
3. Ve a Firebase Console → Configuración del proyecto → Tu app Android
4. Agrega ambas huellas digitales
5. Descarga el nuevo `google-services.json`
6. Reemplaza el archivo en `android/app/google-services.json`
7. Ejecuta: `flutter clean && flutter pub get && flutter run`

---

### ❓ ¿Qué es el error "ApiException 10"?

**Respuesta:** Este error significa que hay un problema de configuración entre tu app y Firebase.

**Causas comunes:**
- SHA-1/SHA-256 no están agregados en Firebase Console
- El `google-services.json` está desactualizado
- El package name no coincide

**Solución:**
1. Verifica que el package name sea: `com.example.pivote_studio`
2. Agrega SHA-1 y SHA-256 en Firebase Console
3. Descarga nuevo `google-services.json`
4. Limpia y reconstruye la app

---

### ❓ ¿Necesito configurar algo en Google Cloud Console?

**Respuesta:** No, si usas Firebase Console, la configuración se hace automáticamente. Firebase maneja la integración con Google Cloud.

---

### ❓ ¿Funciona Google Sign-In en el emulador?

**Respuesta:** Sí, pero necesitas:
- Emulador con Google Play Services
- Cuenta Google configurada en el emulador
- SHA-1 del emulador agregado en Firebase Console (diferente al del dispositivo físico)

---

### ❓ ¿Por qué no aparece el selector de cuentas de Google?

**Respuesta:** Puede ser por caché o configuración incorrecta.

**Solución:**
1. Desinstala completamente la app
2. Ejecuta: `flutter clean`
3. Reinstala la app
4. Si persiste, verifica SHA-1/SHA-256 en Firebase Console

---

## 🔔 Notificaciones

### ❓ ¿Por qué no recibo notificaciones?

**Respuesta:** Puede haber varias razones:

**Verifica:**
1. ✅ Notificaciones activadas en la app (Perfil → Notificaciones)
2. ✅ Permisos concedidos en configuración del dispositivo
3. ✅ Firebase Cloud Messaging habilitado en Firebase Console
4. ✅ Token FCM guardado en Firestore (verifica en Firebase Console)
5. ✅ App no está en modo "No molestar"

---

### ❓ ¿Qué es el token FCM?

**Respuesta:** Es un identificador único que Firebase genera para tu dispositivo. Se usa para enviar notificaciones específicamente a ese dispositivo.

**Características:**
- Se genera automáticamente al iniciar sesión
- Se guarda en Firestore en el campo `fcmToken`
- Puede cambiar con el tiempo (Firebase lo actualiza automáticamente)
- Es diferente para cada dispositivo

---

### ❓ ¿Las notificaciones funcionan con la app cerrada?

**Respuesta:** Sí, Firebase Cloud Messaging puede enviar notificaciones incluso cuando la app está completamente cerrada.

**Estados soportados:**
- ✅ Foreground (app abierta)
- ✅ Background (app en segundo plano)
- ✅ Terminated (app cerrada)

---

### ❓ ¿Cómo envío notificaciones a los usuarios?

**Respuesta:** Hay dos formas:

**1. Desde Firebase Console (Manual):**
- Firebase Console → Cloud Messaging
- "Send your first message"
- Configura y envía

**2. Desde un Backend (Automático):**
```javascript
// Ejemplo con Node.js
const admin = require('firebase-admin');

await admin.messaging().send({
  token: userFcmToken,
  notification: {
    title: 'Título',
    body: 'Mensaje',
  },
});
```

---

### ❓ ¿Por qué necesito dar permisos de notificaciones?

**Respuesta:** Desde Android 13 (API 33), los permisos de notificaciones son obligatorios por seguridad y privacidad del usuario.

**Proceso:**
1. Usuario activa notificaciones en la app
2. Sistema Android solicita permiso
3. Usuario acepta o rechaza
4. Si acepta, las notificaciones funcionan
5. Si rechaza, puede activarlas manualmente en Configuración

---

### ❓ ¿Puedo personalizar las notificaciones?

**Respuesta:** Sí, puedes personalizar:

**En el código:**
- Icono de notificación
- Color de notificación
- Sonido
- Vibración
- Prioridad

**En el mensaje:**
- Título
- Cuerpo
- Imagen
- Datos adicionales (para navegación)

---

### ❓ ¿Las notificaciones consumen mucha batería?

**Respuesta:** No, Firebase Cloud Messaging está optimizado para consumir muy poca batería. Usa la infraestructura de Google Play Services que ya está en el dispositivo.

---

### ❓ ¿Qué pasa si desinstalo y reinstalo la app?

**Respuesta:** 
- El token FCM cambia
- Se genera uno nuevo al iniciar sesión
- Se guarda automáticamente en Firestore
- Las notificaciones siguen funcionando

---

### ❓ ¿Puedo recibir notificaciones sin internet?

**Respuesta:** No, necesitas conexión a internet para recibir notificaciones push. Firebase Cloud Messaging requiere conectividad.

---

## 🔧 Configuración

### ❓ ¿Dónde está el archivo google-services.json?

**Respuesta:** Debe estar en: `android/app/google-services.json`

**Para descargarlo:**
1. Firebase Console → Configuración del proyecto
2. Scroll hasta "Tus apps"
3. Selecciona tu app Android
4. Click en "google-services.json"

---

### ❓ ¿Qué versiones de Android son compatibles?

**Respuesta:**
- **Mínimo:** Android 7.0 (API 24)
- **Target:** Android 14 (API 36)
- **Notificaciones con permisos:** Android 13+ (API 33+)

---

### ❓ ¿Necesito una cuenta de Google Cloud?

**Respuesta:** No directamente. Firebase maneja todo automáticamente. Sin embargo, Firebase está vinculado a Google Cloud, así que técnicamente estás usando Google Cloud a través de Firebase.

---

### ❓ ¿Cuánto cuesta Firebase Cloud Messaging?

**Respuesta:** Firebase Cloud Messaging es **completamente gratis**, sin límites de mensajes.

**Plan Spark (Gratis):**
- ✅ Notificaciones ilimitadas
- ✅ Todos los features de FCM
- ✅ Sin costo

---

## 🐛 Problemas Comunes

### ❓ Error: "Missing google-services.json"

**Solución:**
1. Descarga `google-services.json` de Firebase Console
2. Colócalo en: `android/app/google-services.json`
3. Ejecuta: `flutter clean && flutter pub get`

---

### ❓ Error: "Firebase not initialized"

**Solución:**
1. Verifica que `FirebaseService.initialize()` se llame en `main.dart`
2. Verifica que `google-services.json` esté en la ubicación correcta
3. Limpia y reconstruye: `flutter clean && flutter run`

---

### ❓ Error: "Permission denied" para notificaciones

**Solución:**
1. Ve a Configuración del dispositivo
2. Apps → Pivote → Notificaciones
3. Activa las notificaciones manualmente
4. Reinicia la app

---

### ❓ Las notificaciones llegan tarde

**Respuesta:** Esto puede ser por:
- Optimización de batería del dispositivo
- Restricciones de datos en segundo plano
- Configuración de "Ahorro de batería"

**Solución:**
1. Configuración → Batería → Optimización de batería
2. Busca "Pivote"
3. Selecciona "No optimizar"

---

### ❓ Error: "Token refresh failed"

**Solución:**
1. Verifica conexión a internet
2. Verifica que Google Play Services esté actualizado
3. Cierra sesión y vuelve a iniciar
4. El token se regenerará automáticamente

---

## 📱 Testing

### ❓ ¿Cómo pruebo las notificaciones?

**Respuesta:**

**Método 1 - Desde la app:**
1. Ir a Perfil → Notificaciones
2. Activar notificaciones
3. Click en "Enviar notificación de prueba"

**Método 2 - Desde Firebase Console:**
1. Firebase Console → Cloud Messaging
2. "Send test message"
3. Ingresa el token FCM (cópialo de Firestore)
4. Envía

---

### ❓ ¿Cómo veo los logs de notificaciones?

**Respuesta:**
```bash
# Ver todos los logs
flutter logs

# Filtrar logs de notificaciones
flutter logs | grep "🔔"

# Ver logs de Android
adb logcat | grep Firebase
```

---

### ❓ ¿Cómo verifico que el token se guardó en Firestore?

**Respuesta:**
1. Firebase Console → Firestore Database
2. Colección: `usuarios-pivote`
3. Busca tu documento de usuario
4. Verifica campos:
   - `fcmToken`: debe tener un valor largo
   - `fcmTokenUpdatedAt`: debe tener un timestamp reciente

---

## 🚀 Producción

### ❓ ¿Qué debo hacer antes de publicar en Play Store?

**Respuesta:**

**Google Sign-In:**
1. Genera keystore de release
2. Obtén SHA-1 y SHA-256 del keystore de release
3. Agrégalos en Firebase Console
4. Descarga nuevo `google-services.json`

**Notificaciones:**
1. Verifica que FCM esté habilitado
2. Prueba en dispositivos reales
3. Configura restricciones de API en Google Cloud Console (opcional)

---

### ❓ ¿Necesito diferentes configuraciones para debug y release?

**Respuesta:** Sí, necesitas agregar los SHA de ambos keystores en Firebase Console:
- SHA-1 y SHA-256 del keystore de debug
- SHA-1 y SHA-256 del keystore de release

Firebase permite múltiples huellas digitales para la misma app.

---

### ❓ ¿Cómo monitoreo las notificaciones en producción?

**Respuesta:**
- Firebase Console → Cloud Messaging → Estadísticas
- Puedes ver:
  - Mensajes enviados
  - Mensajes entregados
  - Mensajes abiertos
  - Tasa de conversión

---

## 📚 Recursos

### ❓ ¿Dónde puedo aprender más?

**Documentación oficial:**
- [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)
- [Google Sign-In Flutter](https://pub.dev/packages/google_sign_in)
- [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)

**Archivos del proyecto:**
- `GOOGLE_SIGNIN_SETUP.md` - Guía de configuración de Google Sign-In
- `ARQUITECTURA_NOTIFICACIONES.md` - Arquitectura del sistema
- `CHECKLIST_CONFIGURACION.md` - Checklist de configuración
- `COMANDOS_UTILES.md` - Comandos útiles

---

## 💡 Tips y Mejores Prácticas

### ❓ ¿Cuándo debo solicitar permisos de notificaciones?

**Respuesta:** 
- ❌ NO al abrir la app por primera vez
- ✅ SÍ cuando el usuario muestre interés (ej: en configuración)
- ✅ SÍ después de explicar el beneficio

**En esta app:**
- Se solicita cuando el usuario va a Perfil → Notificaciones
- Se explica qué notificaciones recibirá
- El usuario decide si activarlas

---

### ❓ ¿Debo guardar el token FCM en SharedPreferences?

**Respuesta:** No es necesario. El token se guarda en Firestore y Firebase lo maneja automáticamente. Si necesitas el token localmente, puedes obtenerlo con:
```dart
final token = await NotificationService.getToken();
```

---

### ❓ ¿Cómo manejo notificaciones cuando el usuario cierra sesión?

**Respuesta:** El servicio ya lo maneja:
```dart
// En auth_service.dart
static Future<void> logout() async {
  await _auth.signOut();
  await _googleSignIn.signOut();
  // El token se elimina automáticamente de Firestore
}
```

---

**Última actualización:** 2026-02-19  
**Versión:** 2.0.0

¿Tienes más preguntas? Revisa los otros documentos de configuración o consulta la documentación oficial de Firebase.
