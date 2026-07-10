#!/bin/sh
set -e

if [ ! -f .env.example ]; then
  echo "No se encontro .env.example. Ejecuta este script desde la raiz del proyecto."
  exit 1
fi

cp .env.example .env
echo ".env creado desde .env.example."

if [ -f backend/secrets/firebase-admin.json ]; then
  sed -i "s|^FIREBASE_CREDENTIALS_PATH=.*|FIREBASE_CREDENTIALS_PATH=/app/secrets/firebase-admin.json|" .env
  echo "Notificaciones push habilitadas (se encontro backend/secrets/firebase-admin.json)."
else
  echo "Sin backend/secrets/firebase-admin.json: las notificaciones push quedan desactivadas."
fi

if [ -n "${SMTP_USER:-}" ] && [ -n "${SMTP_PASSWORD:-}" ]; then
  sed -i "s|^SMTP_HOST=.*|SMTP_HOST=${SMTP_HOST:-smtp.gmail.com}|" .env
  sed -i "s|^SMTP_USER=.*|SMTP_USER=$SMTP_USER|" .env
  sed -i "s|^SMTP_PASSWORD=.*|SMTP_PASSWORD=$SMTP_PASSWORD|" .env
  sed -i "s|^MAIL_FROM=.*|MAIL_FROM=\"UBBike <$SMTP_USER>\"|" .env
  echo "Correo configurado con la cuenta $SMTP_USER."
else
  echo "Sin SMTP_USER/SMTP_PASSWORD: el envio de correos queda desactivado."
fi

HOST="${1:-}"
if [ -z "$HOST" ]; then
  echo "Acceso publico: localhost (sin IP indicada)."
  echo "Uso: [SMTP_USER=... SMTP_PASSWORD=...] ./preparar-env.sh <IP_O_HOST> [PUERTO_API] [PUERTO_WEB]"
  exit 0
fi

PUERTO_API="${2:-$(grep '^BACKEND_PORT=' .env | cut -d= -f2)}"
PUERTO_WEB="${3:-$(grep '^FRONTEND_PORT=' .env | cut -d= -f2)}"

sed -i "s|^PUBLIC_API_BASE_URL=.*|PUBLIC_API_BASE_URL=http://$HOST:$PUERTO_API|" .env
sed -i "s|^PUBLIC_WS_BASE_URL=.*|PUBLIC_WS_BASE_URL=ws://$HOST:$PUERTO_API|" .env
sed -i "s|^DOCKER_FRONTEND_URL=.*|DOCKER_FRONTEND_URL=http://$HOST:$PUERTO_WEB|" .env
sed -i "s|^DOCKER_CORS_ORIGINS=.*|DOCKER_CORS_ORIGINS=http://$HOST:$PUERTO_WEB,http://localhost:$PUERTO_WEB|" .env

echo "URLs publicas apuntando a $HOST (API :$PUERTO_API, web :$PUERTO_WEB)."
echo "La APK debe compilarse con --dart-define=API_BASE_URL=http://$HOST:$PUERTO_API"
grep -E '^(PUBLIC|DOCKER_)' .env
