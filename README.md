# KendyDigital Deploy

Server deploy directory: `/opt/kendy`.

Compose files in this project:

- `../docker-compose.yml`: local development from the project root, used by `python run.py docker`.
- `docker-compose.prod.yml`: production/deploy compose, used by `/opt/kendy/deploy.sh`.

Jenkins pipeline files:

- `../be/Jenkinsfile`: backend CI pipeline. It builds/tests backend and pushes the backend Docker image.
- `../fe/Jenkinsfile`: frontend CI pipeline. It builds/tests frontend and pushes the frontend Docker image.

Required Jenkins credentials:

- `dockerhub-credentials`: Username/password or token for Docker Hub.

Required files on every deploy machine:

- `docker-compose.prod.yml`
- `monitoring/`
- `.env`
- `deploy.sh`

The `.env` file is server-local secret/config and must not be committed.

Minimum `.env` values:

```env
BACKEND_IMAGE=registry.example.com/kendy/backend:latest
FRONTEND_IMAGE=registry.example.com/kendy/frontend:latest

POSTGRES_DB=kendy
POSTGRES_USER=postgres
POSTGRES_PASSWORD=change_me
DB_USERNAME=postgres
DB_PASSWORD=change_me
JPA_DDL_AUTO=validate

APP_REDIS_ENABLED=true

CORS_ALLOWED_ORIGINS=https://your-domain.com
FRONTEND_BASE_URL=https://your-domain.com
OAUTH2_SUCCESS_REDIRECT_URL=https://your-domain.com/oauth/callback
OAUTH2_FAILURE_REDIRECT_URL=https://your-domain.com/login

GOOGLE_CLIENT_ID=change_me
GOOGLE_CLIENT_SECRET=change_me
GITHUB_CLIENT_ID=change_me
GITHUB_CLIENT_SECRET=change_me

GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=change_me_strong_password
```

Deploy command used by Jenkins:

```sh
BACKEND_IMAGE=registry.example.com/kendy/backend:abc123 \
FRONTEND_IMAGE=registry.example.com/kendy/frontend:def456 \
APP_DIR=/opt/kendy \
/opt/kendy/deploy.sh
```

OAuth callback URLs:

- Google: `https://api.your-domain.com/login/oauth2/code/google`
- GitHub: `https://api.your-domain.com/login/oauth2/code/github`

## Two-laptop CI/CD without VPS

Use this when laptop A is for coding and laptop B is the deploy machine.

### Laptop B: deploy machine

Install Docker Desktop, Git, Jenkins, and an SSH server. Create the deploy folder:

```sh
sudo mkdir -p /opt/kendy
sudo chown -R "$USER":"$USER" /opt/kendy
```

Copy these files from this `deploy/` folder into `/opt/kendy`:

```text
/opt/kendy/.env
/opt/kendy/docker-compose.prod.yml
/opt/kendy/deploy.sh
/opt/kendy/monitoring/
```

Then run once:

```sh
chmod +x /opt/kendy/deploy.sh
docker compose -f /opt/kendy/docker-compose.prod.yml config
```

### Laptop A: code machine

Push frontend and backend code to your Git remote. Jenkins on laptop B should watch those repositories with webhook or polling.

With the current backend/frontend Jenkinsfiles, Jenkins job flow should be:

```text
backend push:
checkout backend repo
test backend
build backend image
push backend image

frontend push:
checkout frontend repo
install/build frontend
build frontend image
push frontend image
```

These Jenkinsfiles no longer SSH into the deploy machine and no longer manage `.env`.
After image push, deploy can be run separately on the machine that owns `.env` and Docker Compose.

If both laptops are in the same LAN, laptop A pushes to GitHub/GitLab, then the Git service calls Jenkins webhook on laptop B. If webhook cannot reach laptop B because it is behind NAT, use Jenkins polling every 1-5 minutes instead.

Local service URLs on laptop B:

```text
Frontend:   http://127.0.0.1:5173
Backend:    http://127.0.0.1:8080
Prometheus: http://127.0.0.1:9090
Grafana:    http://127.0.0.1:3000
```
