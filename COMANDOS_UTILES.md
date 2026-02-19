# 🛠️ Comandos Útiles - Pivote App

## 📦 Instalación y Configuración

### Instalar dependencias
```bash
flutter pub get
```

### Limpiar proyecto
```bash
flutter clean
flutter pub get
```

### Limpiar caché de Gradle (Android)
```bash
cd android
./gradlew clean
# Windows: gradlew.bat clean
cd ..
```

---

## 🔐 Google Sign-In

### Obtener SHA-1 y SHA-256

**Windows:**
```bash
get_sha.bat
```

**Linux/Mac:**
```bash
chmod +x get_sha.sh
./get_sha.sh
```

**Manual:**
```bash
cd android
./gradlew signingReport
# Windows: gradlew.bat signingReport
```

Busca las líneas que contienen:
- `SHA1: XX:XX:XX:...`
- `SHA-256: XX:XX:XX:...`

---

## 🚀 Ejecutar la App

### Modo Debug
```bash
flutter run
```

### Modo Release
```bash
flutter run --release
```

### Seleccionar dispositivo específico
```bash
# Listar dispositivos
flutter devices

# Ejecutar en dispositivo específico
flutter run -d <device-id>
```

---

## 🔔 Notificaciones - Testing

### Verificar configuración de Firebase
```bash
# Verificar que google-services.json esté actualizado
cat android/app/google-services.json | grep "project_id"
```

### Logs de notificaciones
```bash
# Ver logs en tiempo real
flutter logs

# Filtrar logs de notificaciones
flutter logs | grep "🔔"
```

### Enviar notificación de prueba desde Firebase Console
1. Ve a Firebase Console → Cloud Messaging
2. Click en "Send your first message"
3. Ingresa título y mensaje
4. Selecciona tu app
5. Envía la notificación

---

## 🐛 Debugging

### Ver logs detallados
```bash
flutter run --verbose
```

### Ver logs de Android
```bash
# Logs completos
adb logcat

# Filtrar por Flutter
adb logcat | grep flutter

# Filtrar por Firebase
adb logcat | grep Firebase
```

### Limpiar datos de la app en el dispositivo
```bash
adb shell pm clear com.example.pivote_studio
```

---

## 📱 Build

### Build APK Debug
```bash
flutter build apk --debug
```

### Build APK Release
```bash
flutter build apk --release
```

### Build App Bundle (para Play Store)
```bash
flutter build appbundle --release
```

### Ubicación de los builds
- APK Debug: `build/app/outputs/flutter-apk/app-debug.apk`
- APK Release: `build/app/outputs/flutter-apk/app-release.apk`
- App Bundle: `build/app/outputs/bundle/release/app-release.aab`

---

## 🔍 Análisis de Código

### Analizar código
```bash
flutter analyze
```

### Formatear código
```bash
flutter format .
```

### Verificar dependencias desactualizadas
```bash
flutter pub outdated
```

---

## 🧪 Testing

### Ejecutar tests
```bash
flutter test
```

### Ejecutar tests con cobertura
```bash
flutter test --coverage
```

---

## 📊 Firebase

### Verificar conexión con Firebase
```bash
# Instalar FlutterFire CLI
dart pub global activate flutterfire_cli

# Configurar Firebase
flutterfire configure
```

### Ver usuarios en Firestore (desde Firebase Console)
1. Firebase Console → Firestore Database
2. Colección: `usuarios-pivote`
3. Verificar campos: `fcmToken`, `fcmTokenUpdatedAt`

---

## 🔧 Solución de Problemas Comunes

### Error: "Gradle build failed"
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

### Error: "Google Sign-In failed"
```bash
# 1. Obtener SHA-1 y SHA-256
get_sha.bat  # o get_sha.sh

# 2. Agregar a Firebase Console
# 3. Descargar nuevo google-services.json
# 4. Limpiar y reconstruir
flutter clean
flutter pub get
flutter run
```

### Error: "Notifications not working"
```bash
# Verificar permisos
adb shell dumpsys package com.example.pivote_studio | grep permission

# Reinstalar app
flutter clean
flutter run --uninstall-first
```

### Error: "Firebase not initialized"
```bash
# Verificar que google-services.json esté en la ubicación correcta
ls android/app/google-services.json

# Si no existe, descargarlo de Firebase Console
```

---

## 📝 Comandos de Git

### Verificar cambios
```bash
git status
```

### Agregar cambios
```bash
git add .
```

### Commit
```bash
git commit -m "feat: implementar notificaciones push y corregir Google Sign-In"
```

### Push
```bash
git push origin main
```

---

## 🔐 Keystore (para Release)

### Generar keystore
```bash
keytool -genkey -v -keystore ~/pivote-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias pivote
```

### Ver información del keystore
```bash
keytool -list -v -keystore ~/pivote-release-key.jks
```

---

## 📱 Instalación Manual

### Instalar APK en dispositivo
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

### Desinstalar app
```bash
adb uninstall com.example.pivote_studio
```

---

## 🎯 Comandos Rápidos

### Desarrollo rápido (limpiar + ejecutar)
```bash
flutter clean && flutter pub get && flutter run
```

### Build release completo
```bash
flutter clean && flutter pub get && flutter build apk --release
```

### Ver tamaño del APK
```bash
# Windows
dir build\app\outputs\flutter-apk\app-release.apk

# Linux/Mac
ls -lh build/app/outputs/flutter-apk/app-release.apk
```

---

## 📚 Recursos Útiles

- [Flutter Docs](https://docs.flutter.dev/)
- [Firebase Console](https://console.firebase.google.com/)
- [Google Cloud Console](https://console.cloud.google.com/)
- [Firebase Cloud Messaging Docs](https://firebase.google.com/docs/cloud-messaging)
- [Google Sign-In Docs](https://pub.dev/packages/google_sign_in)

---

**Tip:** Guarda este archivo como referencia rápida para comandos comunes durante el desarrollo.
