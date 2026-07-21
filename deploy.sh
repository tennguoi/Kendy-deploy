#!/usr/bin/env sh
set -eu

APP_DIR="${APP_DIR:-/Kendy-deploy}"
ENV_FILE="$APP_DIR/.env"
COMPOSE_FILE="$APP_DIR/docker-compose.prod.yml"

if [ ! -f "$ENV_FILE" ]; then
  echo "Missing $ENV_FILE" >&2
  exit 1
fi

if [ ! -f "$COMPOSE_FILE" ]; then
  echo "Missing $COMPOSE_FILE" >&2
  exit 1
fi

cd "$APP_DIR"

if [ "${BACKEND_IMAGE:-}" ]; then
  if grep -q "^BACKEND_IMAGE=" "$ENV_FILE"; then
    sed -i "s|^BACKEND_IMAGE=.*|BACKEND_IMAGE=$BACKEND_IMAGE|" "$ENV_FILE"
  else
    printf "\nBACKEND_IMAGE=%s\n" "$BACKEND_IMAGE" >> "$ENV_FILE"
  fi
fi

if [ "${FRONTEND_IMAGE:-}" ]; then
  if grep -q "^FRONTEND_IMAGE=" "$ENV_FILE"; then
    sed -i "s|^FRONTEND_IMAGE=.*|FRONTEND_IMAGE=$FRONTEND_IMAGE|" "$ENV_FILE"
  else
    printf "\nFRONTEND_IMAGE=%s\n" "$FRONTEND_IMAGE" >> "$ENV_FILE"
  fi
fi

docker compose -f "$COMPOSE_FILE" pull
docker compose -f "$COMPOSE_FILE" up -d --remove-orphans
docker compose -f "$COMPOSE_FILE" ps
