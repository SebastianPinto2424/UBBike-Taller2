import { readFileSync } from 'node:fs';
import { App, cert, getApps, initializeApp } from 'firebase-admin/app';
import { entorno } from './entorno';

let appFirebase: App | null = null;
let yaSeIntento = false;

export const obtenerFirebase = (): App | null => {
  if (appFirebase) {
    return appFirebase;
  }

  if (yaSeIntento) {
    return null;
  }

  yaSeIntento = true;

  const ruta = entorno.firebase.credencialesPath;

  if (!ruta) {
    console.log('[firebase] FIREBASE_CREDENTIALS_PATH no configurado: push deshabilitado');
    return null;
  }

  try {
    const credencial = JSON.parse(readFileSync(ruta, 'utf-8'));
    appFirebase =
      getApps().length > 0 ? getApps()[0] : initializeApp({ credential: cert(credencial) });
    console.log('[firebase] Admin SDK inicializado: push habilitado');
    return appFirebase;
  } catch (error) {
    console.error('[firebase] No se pudo inicializar Admin SDK; push deshabilitado', error);
    return null;
  }
};

export const firebaseHabilitado = (): boolean => obtenerFirebase() !== null;
