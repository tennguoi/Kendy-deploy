#!/usr/bin/env sh
set -eu

APP_DIR="${APP_DIR:-/home/minh/kendy}"
ENV_FILE="$APP_DIR/.env"
COMPOSE_FILE="$APP_DIR/docker-compose.prod.yml"

if [ ! -d "$APP_DIR" ]; then
  echo "Lỗi: Không tìm thấy thư mục: $APP_DIR" >&2
  exit 1
fi

if [ ! -f "$ENV_FILE" ]; then
  echo "Lỗi: Không tìm thấy file: $ENV_FILE" >&2
  exit 1
fi

# Tự động điều chỉnh quyền đọc/ghi cho .env nếu user hiện tại có quyền sở hữu
chmod 664 "$ENV_FILE" 2>/dev/null || chmod +r "$ENV_FILE" 2>/dev/null || true

if [ ! -r "$ENV_FILE" ]; then
  echo "Lỗi: Không có quyền đọc file $ENV_FILE (Permission denied)." >&2
  echo "Vui lòng chạy trên máy chủ: chmod 664 $ENV_FILE" >&2
  exit 1
fi

if [ ! -f "$COMPOSE_FILE" ]; then
  echo "Lỗi: Không tìm thấy file: $COMPOSE_FILE" >&2
  exit 1
fi

cd "$APP_DIR"

if [ -n "${BACKEND_IMAGE:-}" ]; then
  if [ -w "$ENV_FILE" ]; then
    if grep -q "^BACKEND_IMAGE=" "$ENV_FILE"; then
      sed -i "s|^BACKEND_IMAGE=.*|BACKEND_IMAGE=$BACKEND_IMAGE|" "$ENV_FILE"
    else
      printf "\nBACKEND_IMAGE=%s\n" "$BACKEND_IMAGE" >> "$ENV_FILE"
    fi
  else
    echo "Cảnh báo: Không có quyền ghi vào $ENV_FILE, dùng BACKEND_IMAGE từ biến môi trường." >&2
  fi
  export BACKEND_IMAGE
fi

if [ -n "${FRONTEND_IMAGE:-}" ]; then
  if [ -w "$ENV_FILE" ]; then
    if grep -q "^FRONTEND_IMAGE=" "$ENV_FILE"; then
      sed -i "s|^FRONTEND_IMAGE=.*|FRONTEND_IMAGE=$FRONTEND_IMAGE|" "$ENV_FILE"
    else
      printf "\nFRONTEND_IMAGE=%s\n" "$FRONTEND_IMAGE" >> "$ENV_FILE"
    fi
  else
    echo "Cảnh báo: Không có quyền ghi vào $ENV_FILE, dùng FRONTEND_IMAGE từ biến môi trường." >&2
  fi
  export FRONTEND_IMAGE
fi   

# Kiểm tra .env/env đã có đủ image cho mọi service trước khi chạy compose.
# Thiếu biến nào, compose sẽ báo lỗi khó hiểu:
# "service ... has neither an image nor a build context specified"
if ! grep -q "^BACKEND_IMAGE=.\+" "$ENV_FILE" && [ -z "${BACKEND_IMAGE:-}" ]; then
  echo "Lỗi: Thiếu BACKEND_IMAGE. Truyền biến BACKEND_IMAGE=... hoặc thêm dòng vào $ENV_FILE." >&2
  exit 1
fi

if ! grep -q "^FRONTEND_IMAGE=.\+" "$ENV_FILE" && [ -z "${FRONTEND_IMAGE:-}" ]; then
  echo "Lỗi: Thiếu FRONTEND_IMAGE. Truyền biến FRONTEND_IMAGE=... hoặc thêm dòng vào $ENV_FILE." >&2
  exit 1
fi

docker compose -f "$COMPOSE_FILE" pull
docker compose -f "$COMPOSE_FILE" up -d --remove-orphans
docker compose -f "$COMPOSE_FILE" ps
