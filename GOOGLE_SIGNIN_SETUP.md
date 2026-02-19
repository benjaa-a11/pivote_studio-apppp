# Configuración de Google Sign-In para Pivote

## ⚠️ IMPORTANTE: Pasos para que funcione Google Sign-In

### 1. Obtener el SHA-1 y SHA-256 de tu aplicación

Ejecuta este comando en la terminal desde la raíz del proyecto:

```bash
cd android
./gradlew signingReport
```

O en Windows:
```bash
cd android
gradlew.bat signingReport
```

Busca en la salida las líneas que dicen:
- `SHA1: XX:XX:XX:...`
- `SHA-256: XX:XX:XX:...`

Copia ambos valores.

### 2. Agregar SHA-1 y SHA-256 a Firebase Console

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Selecciona tu proyecto: **plan-b-canales**
3. Ve a **Configuración del proyecto** (ícono de engranaje)
4. Desplázate hasta la sección **Tus apps**
5. Selecciona tu app Android: `com.example.pivote_studio`
6. En la sección **Huellas digitales de certificado SHA**, haz clic en **Agregar huella digital**
7. Pega el SHA-1 y guarda
8. Repite el proceso para agregar el SHA-256

### 3. Descargar el nuevo google-services.json

1. Después de agregar los SHA, descarga el nuevo archivo `google-services.json`
2. Reemplaza el archivo existente en: `android/app/google-services.json`

### 4. Habilitar Google Sign-In en Firebase

1. En Firebase Console, ve a **Authentication** → **Sign-in method**
2. Habilita **Google** como proveedor de inicio de sesión
3. Configura el correo de soporte del proyecto

### 5. Verificar la configuración en Firebase Console

Asegúrate de que en Firebase Console → Authentication → Sign-in method:
- ✅ Google esté habilitado
- ✅ El OAuth client ID esté configurado correctamente

### 6. Limpiar y reconstruir la app

```bash
flutter clean
flutter pub get
cd android
./gradlew clean
cd ..
flutter run
```

## 🔧 Solución de problemas comunes

### Error: ApiException 10 (DEVELOPER_ERROR)

**Causa**: Los SHA-1/SHA-256 no están configurados o no coinciden.

**Solución**:
1. Verifica que agregaste AMBOS SHA-1 y SHA-256 en Firebase Console
2. Descarga el nuevo `google-services.json`
3. Limpia y reconstruye la app

### Error: PlatformException (sign_in_failed)

**Causa**: El OAuth client ID no está configurado correctamente.

**Solución**:
1. Verifica que el `client_id` en `google-services.json` coincida con el de Firebase Console
2. Asegúrate de que el package name sea exactamente: `com.example.pivote_studio`

### El selector de cuentas no aparece

**Causa**: Google Sign-In está en caché.

**Solución**:
1. Desinstala completamente la app del dispositivo
2. Limpia el caché: `flutter clean`
3. Reinstala la app

## 📱 Configuración de notificaciones

Las notificaciones push ya están configuradas en el proyecto. Para que funcionen:

1. Asegúrate de que Firebase Cloud Messaging esté habilitado en tu proyecto
2. Las notificaciones se inicializan automáticamente al iniciar sesión
3. El token FCM se guarda en Firestore en el campo `fcmToken` del usuario
4. Los usuarios pueden gestionar las notificaciones desde: **Perfil → Notificaciones**

## 🔐 Seguridad

- El archivo `google-services.json` contiene información sensible
- Asegúrate de que esté en `.gitignore` (ya está configurado)
- Nunca compartas tus claves API públicamente
- Para producción, configura restricciones de API en Google Cloud Console

## 📝 Notas adicionales

- El proyecto usa `google_sign_in: ^6.2.1`
- Firebase BOM version: `33.1.2`
- Las notificaciones requieren Android 13+ para permisos explícitos
- El token FCM se actualiza automáticamente cuando cambia
