#!/usr/bin/env node
/**
 * ETAPA 0 - Migración interactiva de usuarios existentes hacia `users/{uid}`.
 *
 * Qué hace:
 * 1. Recorre todos los usuarios de Firebase Auth (con paginación completa).
 * 2. También inspecciona la colección legada `usuarios` en Firestore para:
 *    - Fusionar datos existentes (favoritos, foto, token FCM, estadísticas) sin perder nada.
 *    - Detectar usuarios que solo existían en el auth custom (`usuarios`) y aún no están en Firebase Auth.
 * 3. Permite elegir interactivamente a qué usuarios marcar `activo: true` o `activo: false`,
 *    su `plan`, fecha de vencimiento (`vence`) y `maxDispositivos` (default: 1).
 * 4. Crea/actualiza `users/{uid}` y `users/{uid}/datos/preferencias`.
 *
 * Uso:
 *   1) Colocá tu llave de cuenta de servicio en `scripts/serviceAccountKey.json`
 *      (o definí la variable de entorno GOOGLE_APPLICATION_CREDENTIALS).
 *   2) Simulacro sin escribir nada:  node migrate_users.mjs --dry-run
 *   3) Ejecución real:               node migrate_users.mjs
 */

import fs from 'node:fs';
import path from 'node:path';
import readline from 'node:readline/promises';
import { stdin as input, stdout as output } from 'node:process';
import { fileURLToPath } from 'node:url';
import admin from 'firebase-admin';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const DRY_RUN = process.argv.includes('--dry-run');

function initFirebaseAdmin() {
  const envPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  const localPath = path.join(__dirname, 'serviceAccountKey.json');
  const keyPath = envPath && fs.existsSync(envPath) ? envPath : localPath;

  if (!fs.existsSync(keyPath)) {
    console.error('\n❌ No se encontró la credencial de Firebase Admin SDK.');
    console.error(`   Guardá el JSON de la cuenta de servicio en: ${localPath}`);
    console.error('   (Firebase Console -> Configuración del proyecto -> Cuentas de servicio -> Generar nueva clave privada)\n');
    process.exit(1);
  }

  const serviceAccount = JSON.parse(fs.readFileSync(keyPath, 'utf8'));
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
  console.log(`✅ Firebase Admin inicializado para proyecto: ${serviceAccount.project_id}`);
}

async function listAllAuthUsers() {
  const users = [];
  let nextPageToken;
  do {
    const result = await admin.auth().listUsers(1000, nextPageToken);
    users.push(...result.users);
    nextPageToken = result.pageToken;
  } while (nextPageToken);
  return users;
}

async function listLegacyFirestoreUsers(db) {
  const snapshot = await db.collection('usuarios').get();
  const byUid = new Map();
  const byEmail = new Map();
  for (const doc of snapshot.docs) {
    const data = doc.data();
    const record = { docId: doc.id, ...data };
    byUid.set(doc.id, record);
    if (data.uid) byUid.set(String(data.uid), record);
    if (data.email) byEmail.set(String(data.email).trim().toLowerCase(), record);
  }
  return { docs: snapshot.docs.map((d) => ({ docId: d.id, ...d.data() })), byUid, byEmail };
}

function splitDisplayName(displayName = '') {
  const parts = displayName.trim().split(/\s+/).filter(Boolean);
  if (parts.length === 0) return { nombre: '', apellido: '' };
  if (parts.length === 1) return { nombre: parts[0], apellido: '' };
  return { nombre: parts[0], apellido: parts.slice(1).join(' ') };
}

function parseExpirationInput(raw, fallbackDays = 30) {
  const trimmed = (raw || '').trim();
  if (!trimmed) {
    return admin.firestore.Timestamp.fromDate(
      new Date(Date.now() + fallbackDays * 24 * 60 * 60 * 1000),
    );
  }
  // Si es número entero -> sumar días desde hoy
  if (/^\d+$/.test(trimmed)) {
    const days = parseInt(trimmed, 10);
    return admin.firestore.Timestamp.fromDate(
      new Date(Date.now() + days * 24 * 60 * 60 * 1000),
    );
  }
  // Si es fecha ISO YYYY-MM-DD -> fin de ese día UTC
  const parsed = new Date(`${trimmed}T23:59:59.000Z`);
  if (!Number.isNaN(parsed.getTime())) {
    return admin.firestore.Timestamp.fromDate(parsed);
  }
  console.log(`⚠️  Fecha "${trimmed}" inválida, usando +${fallbackDays} días.`);
  return admin.firestore.Timestamp.fromDate(
    new Date(Date.now() + fallbackDays * 24 * 60 * 60 * 1000),
  );
}

function toTimestampOrNow(value) {
  if (!value) return admin.firestore.Timestamp.now();
  if (value instanceof admin.firestore.Timestamp) return value;
  const parsed = new Date(value);
  if (!Number.isNaN(parsed.getTime())) {
    return admin.firestore.Timestamp.fromDate(parsed);
  }
  return admin.firestore.Timestamp.now();
}

async function main() {
  initFirebaseAdmin();
  const db = admin.firestore();
  const rl = readline.createInterface({ input, output });

  try {
    console.log(DRY_RUN
      ? '\n🧪 MODO SIMULACRO (--dry-run): NO se modificará Firebase Auth ni Firestore.\n'
      : '\n🚀 MODO REAL: los cambios se aplicarán en Firebase.\n');

    console.log('🔎 Leyendo usuarios de Firebase Auth...');
    const authUsers = await listAllAuthUsers();

    console.log('🔎 Leyendo colección legada `usuarios` en Firestore...');
    const legacy = await listLegacyFirestoreUsers(db);

    const existingUsersSnap = await db.collection('users').get();
    const existingUsersMap = new Map(
      existingUsersSnap.docs.map((d) => [d.id, d.data()]),
    );

    const authEmails = new Set(
      authUsers.map((u) => (u.email || '').trim().toLowerCase()).filter(Boolean),
    );
    const authUids = new Set(authUsers.map((u) => u.uid));

    // Construir lista unificada de candidatos
    const candidates = [];

    for (const authUser of authUsers) {
      const email = (authUser.email || '').trim().toLowerCase();
      const legacyDoc = legacy.byUid.get(authUser.uid) || legacy.byEmail.get(email) || null;
      const fromDisplay = splitDisplayName(authUser.displayName || '');
      candidates.push({
        source: legacyDoc ? 'Auth + usuarios' : 'Firebase Auth',
        needsAuthCreation: false,
        uid: authUser.uid,
        email,
        nombre: legacyDoc?.name || fromDisplay.nombre || '',
        apellido: legacyDoc?.lastName || fromDisplay.apellido || '',
        photoUrl: legacyDoc?.photoUrl || authUser.photoURL || null,
        fcmToken: legacyDoc?.fcmToken || null,
        legacyPlan: legacyDoc?.isVip || legacyDoc?.userType === 'vip' ? 'vip' : 'standard',
        legacySuspended: Boolean(legacyDoc?.isSuspended || authUser.disabled),
        creadoEn: authUser.metadata?.creationTime || legacyDoc?.createdAt || null,
        legacyData: legacyDoc,
        alreadyInUsers: existingUsersMap.has(authUser.uid),
      });
    }

    // Detectar usuarios que existen SOLO en la colección legada `usuarios`
    const legacyOnly = legacy.docs.filter((doc) => {
      const uid = String(doc.uid || doc.docId);
      const email = String(doc.email || '').trim().toLowerCase();
      return !authUids.has(uid) && (!email || !authEmails.has(email));
    });

    if (legacyOnly.length > 0) {
      console.log(`\n⚠️  Se detectaron ${legacyOnly.length} usuario(s) que existen SOLO en Firestore 'usuarios' (auth custom anterior) y NO en Firebase Auth.`);
      console.log('   Nota de seguridad: las contraseñas anteriores usaban SHA256(salt:password) y no son');
      console.log('   importables directamente; al crearlos en Firebase Auth se generará un enlace');
      console.log('   de restablecimiento de clave para cada uno.');
      const includeLegacy = (await rl.question('¿Incluir también estos usuarios legados para crearlos en Firebase Auth + `users`? (s/N): '))
        .trim()
        .toLowerCase();

      if (includeLegacy === 's' || includeLegacy === 'si' || includeLegacy === 'y') {
        for (const doc of legacyOnly) {
          const uid = String(doc.uid || doc.docId);
          const email = String(doc.email || '').trim().toLowerCase();
          if (!email) continue;
          candidates.push({
            source: 'Solo usuarios (legacy)',
            needsAuthCreation: true,
            uid,
            email,
            nombre: doc.name || '',
            apellido: doc.lastName || '',
            photoUrl: doc.photoUrl || null,
            fcmToken: doc.fcmToken || null,
            legacyPlan: doc.isVip || doc.userType === 'vip' ? 'vip' : 'standard',
            legacySuspended: Boolean(doc.isSuspended),
            creadoEn: doc.createdAt || null,
            legacyData: doc,
            alreadyInUsers: existingUsersMap.has(uid),
          });
        }
      }
    }

    if (candidates.length === 0) {
      console.log('\nℹ️  No hay usuarios para migrar. Podés pasar a la ETAPA 1.');
      return;
    }

    console.log(`\n📋 Usuarios encontrados (${candidates.length}):`);
    candidates.forEach((u, idx) => {
      const fullName = `${u.nombre} ${u.apellido}`.trim() || '(sin nombre)';
      const badge = u.alreadyInUsers ? ' [ya existe en users]' : '';
      const susp = u.legacySuspended ? ' [suspendido]' : '';
      console.log(`  ${idx + 1}. ${u.email || '(sin email)'} — ${fullName} | origen: ${u.source}${badge}${susp}`);
    });

    console.log('\nElegí cómo asignar `activo` a estos usuarios:');
    console.log('  [1] Elegir uno por uno (recomendado)');
    console.log('  [2] Marcar TODOS como activo=true y elegir excepciones');
    console.log('  [3] Marcar TODOS como activo=false y elegir a cuáles activar');
    const mode = (await rl.question('\nOpción (1/2/3) [1]: ')).trim() || '1';

    const defaultDaysRaw = await rl.question(
      'Vigencia por defecto para usuarios activos (días o fecha YYYY-MM-DD) [30]: ',
    );
    const defaultVence = parseExpirationInput(defaultDaysRaw, 30);

    const decisions = [];

    if (mode === '2' || mode === '3') {
      const baseActive = mode === '2';
      const promptMsg = baseActive
        ? 'Números separados por coma para dejar INACTIVOS (Enter = ninguno): '
        : 'Números separados por coma para marcar ACTIVOS (Enter = ninguno): ';
      const exceptionsRaw = await rl.question(promptMsg);
      const exceptionSet = new Set(
        exceptionsRaw
          .split(',')
          .map((s) => parseInt(s.trim(), 10))
          .filter((n) => !Number.isNaN(n) && n >= 1 && n <= candidates.length),
      );

      for (let i = 0; i < candidates.length; i++) {
        const u = candidates[i];
        const isException = exceptionSet.has(i + 1);
        const activo = baseActive ? !isException : isException;
        decisions.push({
          candidate: u,
          activo,
          plan: u.legacyPlan,
          vence: defaultVence,
          maxDispositivos: 1,
        });
      }
    } else {
      for (let i = 0; i < candidates.length; i++) {
        const u = candidates[i];
        const fullName = `${u.nombre} ${u.apellido}`.trim() || '(sin nombre)';
        console.log(`\n─── [${i + 1}/${candidates.length}] ${u.email} (${fullName}) | ${u.source} ───`);
        const activeAns = (await rl.question(
          `  ¿Marcar activo=true? (s/n) [${u.legacySuspended ? 'n' : 's'}]: `,
        ))
          .trim()
          .toLowerCase();
        const activo = activeAns === ''
          ? !u.legacySuspended
          : activeAns === 's' || activeAns === 'si' || activeAns === 'y';

        const planAns = (await rl.question(`  Plan (standard/vip) [${u.legacyPlan}]: `))
          .trim()
          .toLowerCase();
        const plan = planAns === 'vip' || planAns === 'standard' ? planAns : u.legacyPlan;

        const venceAns = await rl.question(
          '  Vencimiento (días o YYYY-MM-DD, Enter = por defecto): ',
        );
        const vence = venceAns.trim() ? parseExpirationInput(venceAns, 30) : defaultVence;

        const maxDevAns = (await rl.question('  maxDispositivos [1]: ')).trim();
        const maxDispositivos = /^\d+$/.test(maxDevAns) && parseInt(maxDevAns, 10) >= 1
          ? parseInt(maxDevAns, 10)
          : 1;

        decisions.push({ candidate: u, activo, plan, vence, maxDispositivos });
      }
    }

    console.log('\n════════════════ RESUMEN A APLICAR ════════════════');
    for (const d of decisions) {
      const venceStr = d.vence.toDate().toISOString().slice(0, 10);
      console.log(
        `  • ${d.candidate.email} | activo=${d.activo} | plan=${d.plan} | vence=${venceStr} | maxDisp=${d.maxDispositivos}${d.candidate.needsAuthCreation ? ' | +Crear en Auth' : ''}`,
      );
    }

    if (DRY_RUN) {
      console.log('\n🧪 Fin del simulacro (--dry-run). No se escribió nada.');
      return;
    }

    const confirm = (await rl.question('\n¿Confirmar y ejecutar migración en Firebase? (escribí SI): '))
      .trim()
      .toUpperCase();
    if (confirm !== 'SI') {
      console.log('❌ Operación cancelada.');
      return;
    }

    const resetLinks = [];
    let migratedCount = 0;

    for (const d of decisions) {
      const u = d.candidate;
      let finalUid = u.uid;

      // 1. Si solo existía en Firestore `usuarios`, crear en Firebase Auth preservando UID
      if (u.needsAuthCreation) {
        try {
          const validHttpPhoto =
            typeof u.photoUrl === 'string' && /^https?:\/\//i.test(u.photoUrl)
              ? u.photoUrl
              : undefined;
          const created = await admin.auth().createUser({
            uid: u.uid,
            email: u.email,
            displayName: `${u.nombre} ${u.apellido}`.trim() || undefined,
            photoURL: validHttpPhoto,
            // Mantener habilitado en Auth: el bloqueo real lo controlan `users/{uid}.activo` + Firestore Rules,
            // así la app puede mostrar "Cuenta pendiente / vencida" y al activarlo desde tu panel entra al instante.
            disabled: false,
          });
          finalUid = created.uid;
          const resetLink = await admin.auth().generatePasswordResetLink(u.email);
          resetLinks.push({ uid: finalUid, email: u.email, resetLink });
          console.log(`  🔐 Creado en Firebase Auth: ${u.email} (${finalUid})`);
        } catch (err) {
          if (err?.code === 'auth/email-already-exists') {
            const existing = await admin.auth().getUserByEmail(u.email);
            finalUid = existing.uid;
            console.log(`  ℹ️  Ya existía en Auth con uid=${finalUid}, usando ese UID.`);
          } else {
            console.error(`  ❌ Error creando en Auth a ${u.email}:`, err.message);
            continue;
          }
        }
      }

      // 2. Crear / actualizar documento principal de control de acceso `users/{uid}`
      const userDocRef = db.collection('users').doc(finalUid);
      const existingDoc = await userDocRef.get();
      const existingData = existingDoc.exists ? existingDoc.data() : {};

      const safePhotoUrl =
        typeof u.photoUrl === 'string' && /^https?:\/\//i.test(u.photoUrl)
          ? u.photoUrl
          : existingData?.photoUrl || null;

      const userPayload = {
        uid: finalUid,
        email: u.email,
        nombre: u.nombre || existingData?.nombre || '',
        apellido: u.apellido || existingData?.apellido || '',
        photoUrl: safePhotoUrl,
        activo: d.activo,
        plan: d.plan,
        vence: d.vence,
        deviceId: existingData?.deviceId ?? null,
        maxDispositivos: d.maxDispositivos,
        fcmToken: u.fcmToken || existingData?.fcmToken || null,
        creadoEn: existingData?.creadoEn || toTimestampOrNow(u.creadoEn),
        actualizadoEn: admin.firestore.FieldValue.serverTimestamp(),
      };

      await userDocRef.set(userPayload, { merge: true });

      // 3. Migrar preferencias y datos UX persistentes a `users/{uid}/datos/preferencias`
      const legacyDoc = u.legacyData;
      const prefsRef = userDocRef.collection('datos').doc('preferencias');
      const existingPrefs = await prefsRef.get();

      const legacyFavChannels = Array.isArray(legacyDoc?.favorites)
        ? legacyDoc.favorites.map(String)
        : [];
      const currentFavChannels = Array.isArray(existingPrefs.data()?.favoriteChannels)
        ? existingPrefs.data().favoriteChannels.map(String)
        : [];
      const mergedFavChannels = Array.from(new Set([...currentFavChannels, ...legacyFavChannels]));

      const prefsPayload = {
        photoUrl: safePhotoUrl || existingPrefs.data()?.photoUrl || null,
        fcmToken: u.fcmToken || existingPrefs.data()?.fcmToken || null,
        favoriteChannels: mergedFavChannels,
        favoriteRadios: Array.isArray(existingPrefs.data()?.favoriteRadios)
          ? existingPrefs.data().favoriteRadios
          : [],
        viewingHistory: existingPrefs.data()?.viewingHistory || {},
        totalActiveSeconds: Math.max(
          Number(existingPrefs.data()?.totalActiveSeconds || 0),
          Number(legacyDoc?.totalActiveSeconds || 0),
        ),
        sessionCount: Math.max(
          Number(existingPrefs.data()?.sessionCount || 0),
          Number(legacyDoc?.sessionCount || 0),
        ),
        channelsWatched: Math.max(
          Number(existingPrefs.data()?.channelsWatched || 0),
          Number(legacyDoc?.channelsWatched || 0),
        ),
        radiosListened: Math.max(
          Number(existingPrefs.data()?.radiosListened || 0),
          Number(legacyDoc?.radiosListened || 0),
        ),
        matchesViewed: Math.max(
          Number(existingPrefs.data()?.matchesViewed || 0),
          Number(legacyDoc?.matchesViewed || 0),
        ),
        firstActiveDate:
          existingPrefs.data()?.firstActiveDate || legacyDoc?.firstActiveDate || null,
        actualizadoEn: admin.firestore.FieldValue.serverTimestamp(),
      };

      await prefsRef.set(prefsPayload, { merge: true });
      migratedCount++;
      console.log(`  ✅ Migrado users/${finalUid} (${u.email}) -> activo=${d.activo}`);
    }

    if (resetLinks.length > 0) {
      const linksOutPath = path.join(__dirname, 'migration-reset-links.json');
      fs.writeFileSync(linksOutPath, JSON.stringify(resetLinks, null, 2), 'utf8');
      console.log(`\n🔑 Se guardaron ${resetLinks.length} enlaces de restablecimiento de clave en:`);
      console.log(`   ${linksOutPath} (ignorado por Git; envíaselos a esos usuarios para su primer ingreso).`);
    }

    console.log(`\n🎉 Migración finalizada: ${migratedCount}/${decisions.length} usuarios procesados.`);
  } finally {
    rl.close();
  }
}

main().catch((err) => {
  console.error('\n❌ Error fatal durante la migración:', err);
  process.exit(1);
});
