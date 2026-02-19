# ✅ Checklist de Configuración - Pivote App

## 📋 Antes de Ejecutar la App

### 1. Google Sign-In Configuration

- [ ] **Obtener SHA-1 y SHA-256**
  ```bash
  # Windows
  get_sha.bat
  
  # Linux/Mac
  ./get_sha.sh
  ```

- [ ] **Agregar SHA-1 a Firebase Console**
  - Ir a: Firebase Console → Configuración del proyecto → Tu app Android
  - Agregar huella digital SHA-1

- [ ] **Agregar SHA-256 a Firebase Console**
  - Agregar huella digital SHA-256 en el mismo lugar

- [ ] **Descargar nuevo google-services.json**
  - Descargar desde Firebase Console
  - Reemplazar: `android/app/google-services.json`

- [ ] **Habilitar Google Sign-In en Firebase**
  - Ir a: Firebase Console → Authentication → Sign-in method
  - Habilitar "Google"
  - Configurar correo de soporte

### 2. Firebase Cloud Messaging

- [ ] **Verificar que FCM esté habilitado**
  - Firebase Console → Cloud Messaging
  - Debe estar activo por defecto

- [ ] **Verificar google-services.json actualizado**
  - Debe contener configuración de messaging
  - Verificar que `project_id` sea correcto: `plan-b-canales`

### 3. Dependencias

- [ ] **Instalar dependencias de Flutter**
  ```bash
  flutter pub get
  ```

- [ ] **Verificar versiones en pubspec.yaml**
  - `firebase_messaging: ^14.7.10`
  - `flutter_local_notifications: ^17.0.0`
  - `permission_handler: ^11.3.0`
  - `google_sign_in: ^6.2.1`

### 4. Configuración Android

- [ ] **Verificar AndroidManifest.xml**
  - Permisos de notificaciones agregados
  - Servicio de Firebase Messaging configurado
  - Metadata de notificaciones configurado

- [ ] **Verificar build.gradle.kts**
  - Firebase BOM: `33.1.2`
  - Firebase Messaging agregado
  - Google Play Services Auth: `21.0.0`

- [ ] **Verificar colors.xml**
  - Archivo existe en: `android/app/src/main/res/values/colors.xml`
  - Color de notificación definido

### 5. Código Flutter

- [ ] **Verificar main.dart**
  - NotificationService importado
  - Background handler configurado
  - NotificationService.initialize() llamado

- [ ] **Verificar auth_service.dart**
  - NotificationService importado
  - Inicialización en signUp
  - Inicialización en signInWithGoogle

- [ ] **Verificar profile_screen.dart**
  - Sección de notificaciones agregada
  - NotificationsSettingsScreen importado

---

## 🧪 Testing

### Después de Configurar

- [ ] **Limpiar proyecto**
  ```bash
  flutter clean
  flutter pub get
  ```

- [ ] **Limpiar Gradle**
  ```bash
  cd android
  ./gradlew clean  # o gradlew.bat clean
  cd ..
  ```

- [ ] **Ejecutar app**
  ```bash
  flutter run
  ```

### Probar Google Sign-In

- [ ] **Abrir app en dispositivo/emulador**
- [ ] **Ir a pantalla de login**
- [ ] **Click en "Continuar con Google"**
- [ ] **Verificar que aparece selector de cuentas**
- [ ] **Seleccionar cuenta**
- [ ] **Verificar que inicia sesión correctamente**
- [ ] **Verificar logs en consola**
  - Debe mostrar: `✅ Firebase sign-in successful`

### Probar Notificaciones

- [ ] **Iniciar sesión en la app**
- [ ] **Ir a Perfil → Notificaciones**
- [ ] **Activar toggle de notificaciones**
- [ ] **Aceptar permisos cuando se soliciten**
- [ ] **Verificar que el toggle queda activado**
- [ ] **Click en "Enviar notificación de prueba"**
- [ ] **Verificar que llega la notificación**
- [ ] **Verificar logs en consola**
  - Debe mostrar: `✅ FCM token saved to Firestore`

### Verificar en Firebase Console

- [ ] **Ir a Firestore Database**
- [ ] **Abrir colección: `usuarios-pivote`**
- [ ] **Seleccionar tu usuario**
- [ ] **Verificar campos:**
  - `fcmToken` (debe tener un valor largo)
  - `fcmTokenUpdatedAt` (debe tener timestamp)

---

## 🐛 Solución de Problemas

### Si Google Sign-In falla:

1. [ ] Verificar que SHA-1 y SHA-256 estén en Firebase Console
2. [ ] Descargar nuevo google-services.json
3. [ ] Limpiar proyecto: `flutter clean`
4. [ ] Desinstalar app del dispositivo
5. [ ] Reinstalar: `flutter run`

### Si Notificaciones no funcionan:

1. [ ] Verificar permisos en configuración del dispositivo
2. [ ] Verificar que FCM esté habilitado en Firebase Console
3. [ ] Verificar logs para ver si hay errores
4. [ ] Reinstalar app: `flutter run --uninstall-first`

### Si hay errores de compilación:

1. [ ] Limpiar Flutter: `flutter clean`
2. [ ] Limpiar Gradle: `cd android && ./gradlew clean`
3. [ ] Eliminar carpetas:
   - `android/.gradle`
   - `android/build`
   - `build`
4. [ ] Reinstalar dependencias: `flutter pub get`
5. [ ] Ejecutar: `flutter run`

---

## 📱 Verificación en Dispositivo Real

### Android 13+ (Recomendado para testing completo)

- [ ] **Permisos de notificaciones**
  - Se solicitan automáticamente
  - Verificar en: Configuración → Apps → Pivote → Notificaciones

- [ ] **Google Sign-In**
  - Debe mostrar selector de cuentas
  - Debe funcionar sin errores

- [ ] **Notificaciones Push**
  - Deben llegar en foreground
  - Deben llegar en background
  - Deben abrir la app al hacer tap

### Emulador Android

- [ ] **Configurar Google Play Services**
  - Usar emulador con Play Store
  - Iniciar sesión con cuenta Google

- [ ] **Probar funcionalidades**
  - Google Sign-In puede tener limitaciones
  - Notificaciones funcionan normalmente

---

## 🎯 Checklist Final

Antes de considerar la configuración completa:

- [ ] Google Sign-In funciona correctamente
- [ ] Notificaciones se pueden activar/desactivar
- [ ] Token FCM se guarda en Firestore
- [ ] Notificación de prueba funciona
- [ ] No hay errores en los logs
- [ ] La app no crashea al iniciar sesión
- [ ] La app no crashea al activar notificaciones
- [ ] El diseño de la pantalla de notificaciones se ve bien
- [ ] Los colores y tema se adaptan correctamente

---

## 📝 Notas Importantes

- **SHA-1/SHA-256**: Son específicos para cada keystore. Si cambias el keystore (debug/release), necesitas agregar nuevos SHA.
- **Token FCM**: Se genera automáticamente, no necesitas hacer nada manualmente.
- **Permisos**: En Android 13+, los permisos de notificaciones son obligatorios.
- **Testing**: Prueba en un dispositivo real para mejores resultados.

---

## ✨ Después de Completar

Una vez que todo funcione:

1. [ ] Hacer commit de los cambios
2. [ ] Documentar cualquier problema encontrado
3. [ ] Actualizar README.md si es necesario
4. [ ] Considerar hacer un build de release para testing

---

**Fecha:** 2026-02-19  
**Versión:** 2.0.0  
**Estado:** ⏳ Pendiente de configuración
