#!/usr/bin/env node
/**
 * Asigna o revoca el custom claim `{ admin: true }` usando Firebase Admin SDK.
 * NUNCA guardes roles de administrador como campo editable en Firestore.
 *
 * Uso:
 *   Asignar admin:  node set_admin_claim.mjs tu-email@gmail.com
 *   Revocar admin:  node set_admin_claim.mjs tu-email@gmail.com --revoke
 */

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import admin from 'firebase-admin';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const target = process.argv[2];
const revoke = process.argv.includes('--revoke');

if (!target || target.startsWith('--')) {
  console.error('Uso: node set_admin_claim.mjs <email-o-uid> [--revoke]');
  process.exit(1);
}

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
  const user = target.includes('@')
    ? await admin.auth().getUserByEmail(target.trim().toLowerCase())
    : await admin.auth().getUser(target.trim());

  const currentClaims = user.customClaims || {};
  const nextClaims = { ...currentClaims };

  if (revoke) {
    delete nextClaims.admin;
  } else {
    nextClaims.admin = true;
  }

  await admin.auth().setCustomUserClaims(user.uid, nextClaims);
  // Revocar refresh tokens para que el nuevo claim entre en efecto al refrescar sesión
  await admin.auth().revokeRefreshTokens(user.uid);

  const updated = await admin.auth().getUser(user.uid);
  console.log(`✅ Usuario: ${updated.email} (uid: ${updated.uid})`);
  console.log(`🔐 Custom claims actuales:`, updated.customClaims || {});
  console.log('ℹ️  El usuario debe cerrar sesión y volver a iniciar sesión (o forzar getIdToken(true)) para recibir el nuevo claim.');
}

run().catch((err) => {
  console.error('❌ Error actualizando custom claim:', err.message);
  process.exit(1);
});
