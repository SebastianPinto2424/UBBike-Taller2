#!/bin/sh
set -e

if [ ! -f .env.example ]; then
  echo "No se encontro .env.example. Ejecuta este script desde la raiz del proyecto."
  exit 1
fi

cp .env.example .env

HOST="${1:-}"
if [ -z "$HOST" ]; then
  echo ".env creado con los valores de .env.example (acceso por localhost)."
  echo "Uso con IP publica: ./preparar-env.sh <IP_O_HOST> [PUERTO_API] [PUERTO_WEB]"
  exit 0
fi

PUERTO_API="${2:-$(grep '^BACKEND_PORT=' .env | cut -d= -f2)}"
PUERTO_WEB="${3:-$(grep '^FRONTEND_PORT=' .env | cut -d= -f2)}"

sed -i "s|^PUBLIC_API_BASE_URL=.*|PUBLIC_API_BASE_URL=http://$HOST:$PUERTO_API|" .env
sed -i "s|^PUBLIC_WS_BASE_URL=.*|PUBLIC_WS_BASE_URL=ws://$HOST:$PUERTO_API|" .env
sed -i "s|^DOCKER_FRONTEND_URL=.*|DOCKER_FRONTEND_URL=http://$HOST:$PUERTO_WEB|" .env
sed -i "s|^DOCKER_CORS_ORIGINS=.*|DOCKER_CORS_ORIGINS=http://$HOST:$PUERTO_WEB,http://localhost:$PUERTO_WEB|" .env

echo ".env creado apuntando a $HOST (API :$PUERTO_API, web :$PUERTO_WEB)."
echo "La APK debe compilarse con --dart-define=API_BASE_URL=http://$HOST:$PUERTO_API"
grep -E '^(PUBLIC|DOCKER_)' .env
