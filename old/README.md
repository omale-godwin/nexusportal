# Production Docker Compose Stack

## Services

| Service | URL | Notes |
|---|---|---|
| **Traefik** (proxy) | `traefik.yourdomain.com` | Dashboard, TLS termination |
| **FlowiseAI** | `flowise.yourdomain.com` | LLM workflow builder |
| **OpenCTI** (OpenClaw) | `opencti.yourdomain.com` | Threat intelligence platform |
| **Directus CMS** | `cms.yourdomain.com` | Headless CMS → managed MySQL |
| **Metabase 1** | `metabase1.yourdomain.com` | Operations dashboard |
| **Metabase 2** | `metabase2.yourdomain.com` | Analytics / client-facing |

---

## Prerequisites

- Docker Engine 26+ and Docker Compose v2.x
- DNS A records pointing all subdomains to your server IP
- Ports **80** and **443** open in your firewall
- Managed **MongoDB** connection strings (2 separate databases)
- Managed **MySQL** connection details (for Directus)
- Optional: managed **PostgreSQL** for FlowiseAI app DB

---

## Quick Start

### 1. Clone / copy files to your server

```bash
mkdir -p /opt/stack && cd /opt/stack
# place docker-compose.yml, .env.example, Makefile here
```

### 2. Configure environment

```bash
cp .env.example .env
nano .env   # Fill in ALL values — see inline comments
```

Generate secrets quickly:
```bash
# 32-char hex secret
openssl rand -hex 32

# UUID (for OpenCTI token)
python3 -c "import uuid; print(uuid.uuid4())"

# Traefik htpasswd credentials
htpasswd -nb admin yourpassword
# Escape each $ as $$ in the .env file
```

### 3. Validate and launch

```bash
make validate   # check config is valid
make up         # start everything
make ps         # verify health
```

---

## MongoDB Setup for Metabase

Each Metabase instance needs its **own database** on your managed MongoDB cluster.

Create two databases (e.g. via Atlas UI or mongosh):
```
metabase_ops        → used by METABASE1_MONGODB_URI
metabase_analytics  → used by METABASE2_MONGODB_URI
```

Metabase stores its app state (questions, dashboards, users) in MongoDB — these are completely separate and isolated between instances.

---

## Directus + Managed MySQL

Directus will run migrations automatically on first start. Ensure:
- The MySQL user has `CREATE`, `ALTER`, `DROP`, `INDEX`, `INSERT`, `UPDATE`, `DELETE`, `SELECT` privileges on the target database.
- SSL is enabled on the managed MySQL instance (`DB_SSL__REJECT_UNAUTHORIZED=true` is set).

---

## Volume Overview

| Volume | Service | Purpose |
|---|---|---|
| `flowise_data` | FlowiseAI | API keys, credentials, logs |
| `flowise_uploads` | FlowiseAI | Uploaded files |
| `opencti_data` | OpenCTI | App data |
| `elasticsearch_data` | OpenCTI | Search index |
| `minio_data` | OpenCTI | File objects |
| `rabbitmq_data` | OpenCTI | Message queue persistence |
| `redis_data` | OpenCTI | Cache / pubsub |
| `directus_uploads` | Directus | Media uploads |
| `directus_extensions` | Directus | Custom extensions |
| `directus_templates` | Directus | Email templates |
| `metabase1_data` | Metabase 1 | Local app data |
| `metabase1_plugins` | Metabase 1 | JDBC drivers / plugins |
| `metabase2_data` | Metabase 2 | Local app data |
| `metabase2_plugins` | Metabase 2 | JDBC drivers / plugins |

---

## Backups

```bash
make backup    # Creates timestamped .tar.gz for each volume in ./backups/
```

Schedule daily backups with cron:
```cron
0 2 * * * cd /opt/stack && make backup >> /var/log/stack-backup.log 2>&1
```

---

## Updating Services

```bash
make update    # pulls latest images and recreates all containers
```

To update a single service (e.g. Directus):
```bash
docker compose pull directus
docker compose up -d --no-deps directus
```

---

## Security Checklist

- [ ] All `.env` values are strong, unique secrets
- [ ] `.env` file is **not** committed to git (add to `.gitignore`)
- [ ] Firewall blocks all ports except 80, 443, and SSH
- [ ] Traefik dashboard requires HTTP Basic Auth
- [ ] All `secure-headers` middleware applied via Traefik labels
- [ ] MongoDB Atlas IP whitelist contains only your server IP
- [ ] MySQL managed DB IP whitelist contains only your server IP
- [ ] Elasticsearch not exposed to public network
- [ ] RabbitMQ management port not exposed publicly
- [ ] Regular backups scheduled and tested

---

## Troubleshooting

```bash
# Check all container health
make ps

# View logs for a specific service
make logs-flowise
make logs-opencti
make logs-directus
make logs-metabase1
make logs-traefik

# Restart a single service
docker compose restart directus

# Check Traefik routing
docker compose logs traefik | grep -i error
```
