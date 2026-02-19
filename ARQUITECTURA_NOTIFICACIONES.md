# 🏗️ Arquitectura del Sistema de Notificaciones

## 📊 Diagrama de Flujo

```
┌─────────────────────────────────────────────────────────────────┐
│                         USUARIO                                  │
│                                                                  │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐     │
│  │   Registro   │    │    Login     │    │   Perfil     │     │
│  │  (Email/Pwd) │    │   (Google)   │    │ Notificaciones│     │
│  └──────┬───────┘    └──────┬───────┘    └──────┬───────┘     │
│         │                   │                    │              │
└─────────┼───────────────────┼────────────────────┼──────────────┘
          │                   │                    │
          ▼                   ▼                    ▼
┌─────────────────────────────────────────────────────────────────┐
│                    AUTH SERVICE                                  │
│                                                                  │
│  • signUp()                                                     │
│  • signInWithGoogle()                                           │
│  • signIn()                                                     │
│  │                                                               │
│  └──► NotificationService.initialize() ◄────────────────────────┤
│                                                                  │
└─────────────────────────────┬───────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│              NOTIFICATION SERVICE                                │
│                                                                  │
│  ┌──────────────────────────────────────────────────────┐      │
│  │  initialize()                                         │      │
│  │  • Request permissions                                │      │
│  │  • Initialize local notifications                     │      │
│  │  • Get FCM token                                      │      │
│  │  • Save token to Firestore                            │      │
│  │  • Setup message handlers                             │      │
│  └──────────────────────────────────────────────────────┘      │
│                                                                  │
│  ┌──────────────────────────────────────────────────────┐      │
│  │  Message Handlers                                     │      │
│  │  • onMessage (foreground)                             │      │
│  │  • onMessageOpenedApp (background)                    │      │
│  │  • onBackgroundMessage (terminated)                   │      │
│  └──────────────────────────────────────────────────────┘      │
│                                                                  │
└─────────────┬────────────────────────────┬───────────────────────┘
              │                            │
              ▼                            ▼
┌──────────────────────┐      ┌──────────────────────────┐
│   FIREBASE CLOUD     │      │   FLUTTER LOCAL          │
│   MESSAGING (FCM)    │      │   NOTIFICATIONS          │
│                      │      │                          │
│  • Token generation  │      │  • Show notifications    │
│  • Message delivery  │      │  • Notification channels │
│  • Token refresh     │      │  • Tap handling          │
└──────────┬───────────┘      └──────────┬───────────────┘
           │                             │
           ▼                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                      FIRESTORE                                   │
│                                                                  │
│  Collection: usuarios-pivote                                    │
│  Document: {userId}                                             │
│  {                                                              │
│    name: "Juan",                                                │
│    email: "juan@example.com",                                   │
│    fcmToken: "eXaMpLeToKeN...",                                 │
│    fcmTokenUpdatedAt: Timestamp,                                │
│    notificationsDisabled: false                                 │
│  }                                                              │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔄 Flujo de Inicialización

### 1. Usuario se Registra/Inicia Sesión

```dart
// auth_service.dart
static Future<void> signUp(...) async {
  // 1. Crear usuario en Firebase Auth
  final userCredential = await _auth.createUserWithEmailAndPassword(...);
  
  // 2. Crear documento en Firestore
  await _createOrUpdateUserDocument(...);
  
  // 3. Inicializar notificaciones
  await NotificationService.initialize();
}
```

### 2. NotificationService se Inicializa

```dart
// notification_service.dart
static Future<void> initialize() async {
  // 1. Solicitar permisos
  final settings = await _messaging.requestPermission(...);
  
  // 2. Inicializar notificaciones locales
  await _initializeLocalNotifications();
  
  // 3. Obtener token FCM
  final token = await getToken();
  
  // 4. Guardar token en Firestore
  await _saveTokenToFirestore(token);
  
  // 5. Configurar handlers
  FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
}
```

### 3. Token se Guarda en Firestore

```dart
static Future<void> _saveTokenToFirestore(String token) async {
  final user = FirebaseAuth.instance.currentUser;
  
  await _firestore.collection('usuarios-pivote').doc(user.uid).update({
    'fcmToken': token,
    'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
  });
}
```

---

## 📱 Flujo de Notificaciones

### Notificación en Foreground (App Abierta)

```
Firebase Cloud Messaging
         │
         ▼
FirebaseMessaging.onMessage
         │
         ▼
_handleForegroundMessage()
         │
         ▼
FlutterLocalNotifications.show()
         │
         ▼
Usuario ve notificación
```

### Notificación en Background (App en Segundo Plano)

```
Firebase Cloud Messaging
         │
         ▼
Sistema Android muestra notificación
         │
         ▼
Usuario hace tap
         │
         ▼
FirebaseMessaging.onMessageOpenedApp
         │
         ▼
_handleNotificationTap()
         │
         ▼
App navega a contenido específico
```

### Notificación con App Cerrada (Terminated)

```
Firebase Cloud Messaging
         │
         ▼
Sistema Android muestra notificación
         │
         ▼
Usuario hace tap
         │
         ▼
App se abre
         │
         ▼
_firebaseMessagingBackgroundHandler()
         │
         ▼
getInitialMessage()
         │
         ▼
_handleNotificationTap()
```

---

## 🎨 Estructura de Archivos

```
lib/
├── core/
│   └── services/
│       └── notification_service.dart       # Servicio principal de notificaciones
│
├── features/
│   ├── auth/
│   │   └── data/
│   │       └── services/
│   │           └── auth_service.dart       # Inicializa notificaciones al login
│   │
│   └── profile/
│       └── presentation/
│           └── screens/
│               ├── profile_screen.dart     # Muestra opción de notificaciones
│               └── notifications_settings_screen.dart  # Configuración
│
└── main.dart                               # Inicializa background handler

android/
├── app/
│   ├── src/main/
│   │   ├── AndroidManifest.xml            # Permisos y servicios
│   │   └── res/values/
│   │       └── colors.xml                 # Color de notificaciones
│   │
│   ├── build.gradle.kts                   # Dependencias de Firebase
│   └── google-services.json               # Configuración de Firebase
```

---

## 🔐 Seguridad y Permisos

### Android 13+ (API 33+)

```xml
<!-- AndroidManifest.xml -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.VIBRATE" />
```

### Solicitud de Permisos en Runtime

```dart
// notification_service.dart
static Future<bool> requestPermission() async {
  // 1. Permiso del sistema (Android 13+)
  if (await Permission.notification.isDenied) {
    final status = await Permission.notification.request();
    if (status.isDenied) return false;
  }
  
  // 2. Permiso de Firebase Messaging
  final settings = await _messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  
  return settings.authorizationStatus == AuthorizationStatus.authorized;
}
```

---

## 📊 Datos en Firestore

### Estructura del Documento de Usuario

```javascript
{
  // Datos básicos
  "uid": "abc123...",
  "name": "Juan",
  "lastName": "Pérez",
  "email": "juan@example.com",
  "photoUrl": "https://...",
  
  // Notificaciones
  "fcmToken": "eXaMpLeToKeN1234567890...",
  "fcmTokenUpdatedAt": Timestamp(2026, 2, 19, 10, 30, 0),
  "notificationsDisabled": false,
  
  // Otros
  "favorites": [],
  "createdAt": Timestamp(...),
  "updatedAt": Timestamp(...)
}
```

---

## 🎯 Casos de Uso

### 1. Usuario Activa Notificaciones

```
Usuario → Toggle ON
    ↓
NotificationService.requestPermission()
    ↓
Sistema solicita permiso
    ↓
Usuario acepta
    ↓
NotificationService.initialize()
    ↓
Token guardado en Firestore
    ↓
Notificaciones activadas ✅
```

### 2. Usuario Desactiva Notificaciones

```
Usuario → Toggle OFF
    ↓
NotificationService.disableNotifications()
    ↓
Token eliminado de Firestore
    ↓
Campo "notificationsDisabled" = true
    ↓
Notificaciones desactivadas ✅
```

### 3. Token FCM se Actualiza

```
Firebase detecta cambio
    ↓
onTokenRefresh event
    ↓
_saveTokenToFirestore(newToken)
    ↓
Firestore actualizado con nuevo token
    ↓
fcmTokenUpdatedAt actualizado ✅
```

---

## 🚀 Envío de Notificaciones

### Desde Firebase Console

1. Firebase Console → Cloud Messaging
2. "Send your first message"
3. Configurar:
   - Título
   - Mensaje
   - Imagen (opcional)
   - Target: App específica
4. Enviar

### Desde Backend (Futuro)

```javascript
// Node.js example
const admin = require('firebase-admin');

// Obtener token del usuario desde Firestore
const userDoc = await admin.firestore()
  .collection('usuarios-pivote')
  .doc(userId)
  .get();

const fcmToken = userDoc.data().fcmToken;

// Enviar notificación
await admin.messaging().send({
  token: fcmToken,
  notification: {
    title: 'Nuevo canal disponible',
    body: 'ESPN 2 ahora disponible en Pivote',
  },
  data: {
    channelId: '123',
    action: 'open_channel',
  },
});
```

---

## 🔄 Ciclo de Vida del Token

```
Usuario inicia sesión
    ↓
Token generado
    ↓
Token guardado en Firestore
    ↓
Token válido (días/semanas)
    ↓
Token expira o cambia
    ↓
onTokenRefresh event
    ↓
Nuevo token guardado
    ↓
Ciclo continúa...
```

---

## 📈 Métricas y Monitoreo

### Logs Importantes

```dart
// Inicialización exitosa
debugPrint('✅ Notification Service initialized successfully');

// Token obtenido
debugPrint('🔔 FCM Token obtained: ${token.substring(0, 20)}...');

// Token guardado
debugPrint('✅ FCM token saved to Firestore');

// Mensaje recibido
debugPrint('🔔 Foreground message received: ${message.messageId}');

// Error
debugPrint('❌ Error initializing Notification Service: $e');
```

### Verificación en Firebase Console

- **Cloud Messaging**: Ver estadísticas de envío
- **Firestore**: Verificar tokens guardados
- **Authentication**: Ver usuarios activos

---

## 🎨 UI/UX

### Pantalla de Configuración

```
┌─────────────────────────────────┐
│  ← Notificaciones               │
├─────────────────────────────────┤
│                                 │
│         🔔                      │
│                                 │
│  ┌───────────────────────────┐ │
│  │ 🔔 Notificaciones Push    │ │
│  │ Recibirás notificaciones  │ │
│  │                    [ON]   │ │
│  └───────────────────────────┘ │
│                                 │
│  ¿Qué notificaciones recibirás? │
│                                 │
│  📺 Nuevos canales              │
│  ⚽ Partidos en vivo             │
│  🔄 Actualizaciones              │
│                                 │
│  [Enviar notificación de prueba]│
│                                 │
└─────────────────────────────────┘
```

---

**Versión:** 2.0.0  
**Última actualización:** 2026-02-19
