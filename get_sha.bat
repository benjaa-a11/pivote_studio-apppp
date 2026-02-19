@echo off
REM Script para obtener SHA-1 y SHA-256 para Google Sign-In en Windows

echo ==========================================
echo Obteniendo SHA-1 y SHA-256 para Debug
echo ==========================================
echo.

cd android

REM Para debug keystore
echo Debug Keystore:
gradlew.bat signingReport | findstr "SHA"

echo.
echo ==========================================
echo Copia estos valores y agregalos a Firebase Console
echo ==========================================
echo.
echo Pasos siguientes:
echo 1. Ve a Firebase Console - Configuracion del proyecto
echo 2. Selecciona tu app Android
echo 3. Agrega las huellas digitales SHA-1 y SHA-256
echo 4. Descarga el nuevo google-services.json
echo 5. Reemplaza android/app/google-services.json
echo.

pause
