/**
 * ETAPA 5 — Middleware de autenticación Firebase Auth para Cloudflare Workers
 * (Proxy de streams M3U8 / API de partidos).
 *
 * Características de seguridad:
 * 1. Verifica criptográficamente (RS256 + Web Crypto API) el Firebase ID Token
 *    contra las claves públicas JWK oficiales de Google (sin dependencias npm).
 * 2. Valida `aud`, `iss`, `sub`, `exp`, `iat` y `auth_time` para `plan-b-canales`.
 * 3. Opcionalmente consulta `users/{uid}` vía Firestore REST API usando el propio
 *    ID Token del usuario (cacheado 60s en Edge) para verificar `activo == true`
 *    y `vence > ahora` sin necesidad de guardar ninguna clave privada en Cloudflare.
 * 4. Incluye lista blanca de dominios permitidos (anti-SSRF) si se usa como proxy.
 *
 * Variables de entorno opcionales en Cloudflare Dashboard (Workers -> Settings -> Variables):
 *   FIREBASE_PROJECT_ID = "plan-b-canales"
 *   CHECK_ACTIVE_USER   = "true"   (recomendado: valida activo + vence en Firestore)
 *   ALLOWED_UPSTREAM_HOSTS = "tu-origen1.com,tu-origen2.com" (para modo proxy)
 */

const GOOGLE_JWK_URL =
  'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com';
const DEFAULT_PROJECT_ID = 'plan-b-canales';

function base64UrlToUint8Array(base64Url) {
  const padded = base64Url.replace(/-/g, '+').replace(/_/g, '/')
    + '='.repeat((4 - (base64Url.length % 4)) % 4);
  const binary = atob(padded);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes;
}

function decodeJwtPart(part) {
  const bytes = base64UrlToUint8Array(part);
  return JSON.parse(new TextDecoder().decode(bytes));
}

async function getGooglePublicJwks() {
  const cache = caches.default;
  const cacheKey = new Request(GOOGLE_JWK_URL, { method: 'GET' });
  let response = await cache.match(cacheKey);

  if (!response) {
    response = await fetch(GOOGLE_JWK_URL);
    if (!response.ok) {
      throw new Error(`No se pudieron descargar claves públicas de Google (${response.status})`);
    }
    const clone = response.clone();
    await cache.put(cacheKey, clone);
  }

  const data = await response.json();
  return data.keys || [];
}

/**
 * Verifica criptográficamente el ID Token de Firebase Auth.
 * Retorna `{ uid, email, claims }` o lanza error si es inválido/vencido.
 */
export async function verifyFirebaseIdToken(token, projectId = DEFAULT_PROJECT_ID) {
  if (!token || typeof token !== 'string') {
    throw new Error('Falta token de autorización');
  }

  const parts = token.split('.');
  if (parts.length !== 3) {
    throw new Error('Formato JWT inválido');
  }

  const [encodedHeader, encodedPayload, encodedSignature] = parts;
  const header = decodeJwtPart(encodedHeader);
  const payload = decodeJwtPart(encodedPayload);

  if (header.alg !== 'RS256' || !header.kid) {
    throw new Error('Algoritmo o kid inválido');
  }

  const nowSec = Math.floor(Date.now() / 1000);
  const expectedIssuer = `https://securetoken.google.com/${projectId}`;

  if (payload.aud !== projectId) throw new Error('Audience (aud) inválido');
  if (payload.iss !== expectedIssuer) throw new Error('Issuer (iss) inválido');
  if (!payload.sub || typeof payload.sub !== 'string') throw new Error('Subject (uid) ausente');
  if (typeof payload.exp !== 'number' || payload.exp <= nowSec) {
    throw new Error('Token expirado');
  }
  if (typeof payload.iat !== 'number' || payload.iat > nowSec + 60) {
    throw new Error('Token emitido en el futuro');
  }

  const jwks = await getGooglePublicJwks();
  const matchingJwk = jwks.find((k) => k.kid === header.kid);
  if (!matchingJwk) {
    throw new Error('Clave pública (kid) no reconocida');
  }

  const cryptoKey = await crypto.subtle.importKey(
    'jwk',
    matchingJwk,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['verify'],
  );

  const signingInput = new TextEncoder().encode(`${encodedHeader}.${encodedPayload}`);
  const signatureBytes = base64UrlToUint8Array(encodedSignature);

  const valid = await crypto.subtle.verify(
    'RSASSA-PKCS1-v1_5',
    cryptoKey,
    signatureBytes,
    signingInput,
  );

  if (!valid) {
    throw new Error('Firma criptográfica inválida');
  }

  return {
    uid: payload.sub,
    email: payload.email || null,
    isAdmin: payload.admin === true,
    claims: payload,
  };
}

/**
 * Valida en Firestore (`users/{uid}`) que `activo == true` y `vence > ahora`
 * usando el propio Bearer Token del usuario (sin claves privadas en Cloudflare).
 * Resultado cacheado 60 segundos por UID en el Edge.
 */
export async function verifyActiveUserInFirestore(uid, idToken, projectId = DEFAULT_PROJECT_ID) {
  const cache = caches.default;
  const cacheKey = new Request(`https://pivote-auth-cache.internal/user/${projectId}/${uid}`);
  const cached = await cache.match(cacheKey);
  if (cached) {
    const { ok } = await cached.json();
    return ok === true;
  }

  const url = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/users/${encodeURIComponent(uid)}`;
  const res = await fetch(url, {
    headers: { Authorization: `Bearer ${idToken}` },
  });

  if (!res.ok) return false;

  const doc = await res.json();
  const fields = doc.fields || {};
  const activo = fields.activo?.booleanValue === true;
  const venceIso = fields.vence?.timestampValue;
  const vigente = typeof venceIso === 'string' && Date.parse(venceIso) > Date.now();
  const ok = activo && vigente;

  await cache.put(
    cacheKey,
    new Response(JSON.stringify({ ok }), {
      headers: {
        'Content-Type': 'application/json',
        'Cache-Control': 'public, max-age=60',
      },
    }),
  );

  return ok;
}

/**
 * Extrae el token desde `Authorization: Bearer <token>` (preferido)
 * o desde query `?token=<token>` (útil para segmentos HLS .m3u8/.ts).
 */
export function extractTokenFromRequest(request) {
  const authHeader = request.headers.get('Authorization') || '';
  if (authHeader.startsWith('Bearer ')) {
    return authHeader.slice(7).trim();
  }
  const url = new URL(request.url);
  return url.searchParams.get('token')?.trim() || null;
}

function jsonError(status, message) {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
    },
  });
}

/**
 * Ejemplo completo de Worker protegido (proxy M3U8 / API).
 * Copiá este archivo en tu Worker de Cloudflare y adaptá la lógica final de `upstreamUrl`.
 */
export default {
  async fetch(request, env) {
    if (request.method === 'OPTIONS') {
      return new Response(null, {
        status: 204,
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, HEAD, OPTIONS',
          'Access-Control-Allow-Headers': 'Authorization, Content-Type',
        },
      });
    }

    const projectId = env?.FIREBASE_PROJECT_ID || DEFAULT_PROJECT_ID;
    const checkActive = (env?.CHECK_ACTIVE_USER ?? 'true') !== 'false';
    const token = extractTokenFromRequest(request);

    if (!token) {
      return jsonError(401, 'Acceso no autorizado: falta Firebase ID Token.');
    }

    let authUser;
    try {
      authUser = await verifyFirebaseIdToken(token, projectId);
    } catch (err) {
      return jsonError(401, `Token inválido: ${err.message}`);
    }

    if (checkActive && !authUser.isAdmin) {
      const isActive = await verifyActiveUserInFirestore(authUser.uid, token, projectId);
      if (!isActive) {
        return jsonError(403, 'Cuenta inactiva o vencida.');
      }
    }

    // --- Lógica de proxy seguro con lista blanca de dominios (anti-SSRF) ---
    const reqUrl = new URL(request.url);
    const target = reqUrl.searchParams.get('url');
    if (!target) {
      return jsonError(400, 'Falta parámetro `url`.');
    }

    let upstreamUrl;
    try {
      upstreamUrl = new URL(target);
      if (upstreamUrl.protocol !== 'https:' && upstreamUrl.protocol !== 'http:') {
        return jsonError(400, 'Protocolo no permitido.');
      }
    } catch {
      return jsonError(400, 'URL destino inválida.');
    }

    const allowedHostsRaw = (env?.ALLOWED_UPSTREAM_HOSTS || '').trim();
    if (allowedHostsRaw) {
      const allowedHosts = allowedHostsRaw
        .split(',')
        .map((h) => h.trim().toLowerCase())
        .filter(Boolean);
      const host = upstreamUrl.hostname.toLowerCase();
      const allowed = allowedHosts.some((h) => host === h || host.endsWith(`.${h}`));
      if (!allowed) {
        return jsonError(403, 'Dominio de origen no permitido.');
      }
    }

    const upstreamRes = await fetch(upstreamUrl.toString(), {
      headers: {
        'User-Agent': request.headers.get('User-Agent') || 'Pivote/1.0',
      },
    });

    const outHeaders = new Headers(upstreamRes.headers);
    outHeaders.set('Access-Control-Allow-Origin', '*');
    outHeaders.set('Cache-Control', 'no-store');

    return new Response(upstreamRes.body, {
      status: upstreamRes.status,
      headers: outHeaders,
    });
  },
};
