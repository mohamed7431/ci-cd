# 🏥 JTrack JDash — CI/CD Pipeline (Docker + Jenkins)

CI/CD setup for **JTrack JDash** — the Django-based digital health study dashboard.  
Push to GitHub → Jenkins auto-triggers → Builds Docker image → Deploys full stack.

---

## 📁 Files Overview

```
jtrack-cicd/
├── Dockerfile              ← Multi-stage build (Python 3.11 + Gunicorn)
├── entrypoint.sh           ← Waits for DB, runs migrations, starts Gunicorn
├── docker-compose.yml      ← Full stack: PostgreSQL + Django + Nginx
├── nginx/
│   └── nginx.conf          ← Nginx reverse proxy config
├── Jenkinsfile             ← 9-stage CI/CD pipeline
├── .env.example            ← Environment variable template
└── README.md
```

---

## 🏗️ Architecture

```
Browser → Nginx (port 80)
               ↓
          Gunicorn (port 8000)    ← Django JDash App
               ↓
          PostgreSQL (port 5432)  ← Study data
```

---

## ⚙️ Setup Instructions

### Step 1 — Clone JTrack Dashboard & add these CI/CD files

```bash
git clone https://github.com/Biomarker-Development-at-INM7/JTrack-dashboard.git
cd JTrack-dashboard

# Copy all files from this repo into your JTrack folder
cp Dockerfile entrypoint.sh docker-compose.yml Jenkinsfile .env.example ./
cp -r nginx ./
```

### Step 2 — Create your .env file

```bash
cp .env.example .env
# Edit .env with your real values:
nano .env
```

**Important fields to set:**
```env
SECRET_KEY=<generate with: python -c "import secrets; print(secrets.token_hex(50))">
DB_PASSWORD=<strong-password>
ALLOWED_HOSTS=localhost,your-server-ip
```

> ⚠️ Add `.env` to your `.gitignore` — never commit secrets!

### Step 3 — Test locally with Docker

```bash
docker compose up --build
```

Open: **http://localhost**

### Step 4 — Set up Jenkins

```bash
# Run Jenkins in Docker
docker run -d \
  --name jenkins \
  --restart unless-stopped \
  -p 8090:8080 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  jenkins/jenkins:lts

# Get initial password
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

Open Jenkins: **http://localhost:8090**

### Step 5 — Store .env on Jenkins server

```bash
sudo mkdir -p /etc/jtrack
sudo cp .env /etc/jtrack/.env
sudo chmod 600 /etc/jtrack/.env
```

### Step 6 — Create Jenkins Pipeline Job

1. New Item → **Pipeline**
2. Pipeline Definition: `Pipeline script from SCM`
3. SCM: `Git` → your GitHub repo URL
4. Branch: `*/main`
5. Script Path: `Jenkinsfile`
6. Build Triggers: ✅ **GitHub hook trigger for GITScm polling**

### Step 7 — Add GitHub Webhook

GitHub Repo → Settings → Webhooks → Add webhook:
- URL: `http://YOUR_JENKINS_IP:8090/github-webhook/`
- Content type: `application/json`
- Event: `Just the push event`

---

## 🔄 CI/CD Pipeline Stages

| Stage | What it does |
|-------|-------------|
| **Checkout** | Pulls latest code from GitHub |
| **Validate Environment** | Checks Docker, Python are available |
| **Lint** | Runs flake8 on Python code |
| **Run Tests** | Runs `python manage.py test` with test settings |
| **Build Docker Image** | Builds multi-stage Docker image |
| **Stop Old Containers** | Tears down the running stack |
| **Deploy** | Starts DB + Django + Nginx via docker compose |
| **Health Check** | Verifies `/health/` endpoint responds |
| **Cleanup** | Removes dangling images |

---

## 🧪 Trigger the Pipeline

```bash
# Make any change to JTrack code, e.g.:
echo "# updated" >> README.md
git add . && git commit -m "trigger pipeline"
git push origin main
```

Watch Jenkins auto-build and deploy → **http://your-server/**

---

## 🛠️ Useful Commands

```bash
# View all running containers
docker compose ps

# View Django app logs
docker logs -f jtrack-web

# View Nginx logs
docker logs -f jtrack-nginx

# Run Django management commands inside container
docker exec -it jtrack-web python manage.py createsuperuser
docker exec -it jtrack-web python manage.py shell

# Stop everything
docker compose down

# Stop and remove volumes (⚠️ deletes database!)
docker compose down -v
```

---

## 🔒 Security Notes

- Never commit `.env` to GitHub
- Use strong `SECRET_KEY` and `DB_PASSWORD`
- Set `DEBUG=False` in production
- Restrict `ALLOWED_HOSTS` to your server IP/domain
- Consider adding HTTPS with Let's Encrypt (certbot)
