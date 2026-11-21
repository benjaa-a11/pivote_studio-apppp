#!/usr/bin/env node
/**
 * ETAPA 5 - Inicializa el documento protegido `config/app` en Firestore
 * (solo legible por usuarios con `esActivo()` o `esAdmin()`).
 *
 * Uso:
 *   cd scripts
 *   npm run seed-config
 */

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import admin from 'firebase-admin';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const envPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
const localPath = path.join(__dirname, 'serviceAccountKey.json');
const keyPath = envPath && fs.existsSync(envPath) ? envPath : localPath;

if (!fs.existsSync(keyPath)) {
  console.error(`❌ Falta el archivo de credenciales Admin SDK en: ${localPath}`);
  process.exit(1);
}

const serviceAccount = JSON.parse(fs.readFileSync(keyPath, 'utf8'));
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

async function run() {
  const db = admin.firestore();
  const payload = {
    matchesApiUrl: 'https://apipro-pivo.provip.workers.dev/api/v1/matches',
    webProxyUrl: 'https://myproxy.canalesonline24.workers.dev/',
    newsBaseUrl: 'https://newsdata.io/api/1/latest',
    newsApiKey: 'pub_0ca293f34dec4079be9b27f81f5fe8e5',
    sendAuthTokenToWorkers: true,
    actualizadoEn: admin.firestore.FieldValue.serverTimestamp(),
  };

  await db.collection('config').doc('app').set(payload, { merge: true });
  console.log('✅ Documento `config/app` guardado en Firestore detrás de las Security Rules.');
}

run().catch((err) => {
  console.error('❌ Error creando config/app:', err.message);
  process.exit(1);
});
