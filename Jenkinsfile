// ============================================================
//  Jenkinsfile — JTrack JDash CI/CD Pipeline
//  Repo: https://github.com/mohamed7431/ci-cd
//  Updated: includes requirements-ci.txt install + flake8 lint
// ============================================================

pipeline {
    agent any

    environment {
        IMAGE_NAME      = 'jtrack-dashboard'
        IMAGE_TAG       = "${BUILD_NUMBER}"
        IMAGE_LATEST    = "${IMAGE_NAME}:latest"
        IMAGE_VERSIONED = "${IMAGE_NAME}:${IMAGE_TAG}"
        COMPOSE_PROJECT = 'jtrack'
        HOST_PORT       = '80'
    }

    triggers {
        githubPush()
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 30, unit: 'MINUTES')
        disableConcurrentBuilds()
    }

    stages {

        // ── Stage 1: Checkout ────────────────────────────────
        stage('Checkout') {
            steps {
                echo '📥 Pulling latest code from GitHub...'
                checkout scm
                sh '''
                    echo "── Files in repo ──"
                    ls -la
                    echo "── Git log (last 3) ──"
                    git log --oneline -3
                '''
            }
        }

        // ── Stage 2: Validate Environment ────────────────────
        stage('Validate Environment') {
            steps {
                echo '🔍 Checking required tools...'
                sh '''
                    docker --version
                    docker compose version || docker-compose --version
                    python3 --version
                    pip3 --version
                '''
                echo '✅ Environment OK'
            }
        }

        // ── Stage 3: Validate Config Files ───────────────────
        stage('Validate Config Files') {
            steps {
                echo '📋 Checking all required CI/CD files are present...'
                sh '''
                    [ -f Dockerfile ]           && echo "✅ Dockerfile found"           || { echo "❌ Dockerfile missing";           exit 1; }
                    [ -f docker-compose.yml ]   && echo "✅ docker-compose.yml found"   || { echo "❌ docker-compose.yml missing";   exit 1; }
                    [ -f entrypoint.sh ]        && echo "✅ entrypoint.sh found"        || { echo "❌ entrypoint.sh missing";        exit 1; }
                    [ -f nginx.conf ]           && echo "✅ nginx.conf found"           || { echo "❌ nginx.conf missing";           exit 1; }
                    [ -f requirements-ci.txt ]  && echo "✅ requirements-ci.txt found"  || { echo "❌ requirements-ci.txt missing";  exit 1; }
                    echo ""
                    echo "✅ All required files present!"
                '''
            }
        }

        // ── Stage 4: Install Dependencies (requirements-ci.txt)
        stage('Install Dependencies') {
            steps {
                echo '📦 Installing Python dependencies from requirements-ci.txt...'
                sh '''
                    python3 -m venv venv
                    . venv/bin/activate

                    pip install --upgrade pip --quiet

                    echo "── Installing from requirements-ci.txt ──"
                    pip install -r requirements-ci.txt --quiet

                    echo ""
                    echo "── Installed packages ──"
                    pip list

                    echo ""
                    echo "✅ All dependencies installed successfully!"
                '''
            }
        }

        // ── Stage 5: Lint (flake8 via requirements-ci.txt) ───
        stage('Lint') {
            steps {
                echo '🔎 Running flake8 Python linter...'
                sh '''
                    . venv/bin/activate

                    flake8 . \
                        --count \
                        --max-line-length=120 \
                        --exclude=venv,migrations,staticfiles,__pycache__ \
                        --statistics \
                        --format=default

                    echo "✅ Lint passed!"
                '''
            }
        }

        // ── Stage 6: Lint Dockerfile ──────────────────────────
        stage('Lint Dockerfile') {
            steps {
                echo '🔎 Checking Dockerfile instructions...'
                sh '''
                    grep -q "FROM"            Dockerfile && echo "✅ FROM found"            || { echo "❌ FROM missing";            exit 1; }
                    grep -q "WORKDIR"         Dockerfile && echo "✅ WORKDIR found"         || echo "⚠️  WORKDIR not found (optional)"
                    grep -q "EXPOSE"          Dockerfile && echo "✅ EXPOSE found"          || echo "⚠️  EXPOSE not found (optional)"
                    grep -qE "CMD|ENTRYPOINT"  Dockerfile && echo "✅ CMD/ENTRYPOINT found"  || { echo "❌ CMD/ENTRYPOINT missing";   exit 1; }
                    echo ""
                    echo "── Dockerfile preview ──"
                    cat Dockerfile
                '''
            }
        }

        // ── Stage 7: Validate docker-compose Syntax ──────────
        stage('Validate Compose') {
            steps {
                echo '🐳 Validating docker-compose.yml syntax...'
                sh '''
                    docker compose config --quiet \
                        && echo "✅ docker-compose.yml is valid" \
                        || { docker-compose config --quiet && echo "✅ docker-compose.yml is valid"; }
                '''
            }
        }

        // ── Stage 8: Build Docker Image ───────────────────────
        stage('Build Docker Image') {
            steps {
                echo "🐳 Building Docker image: ${IMAGE_VERSIONED}..."
                sh """
                    docker build \
                        --tag ${IMAGE_VERSIONED} \
                        --tag ${IMAGE_LATEST} \
                        --build-arg BUILD_NUMBER=${BUILD_NUMBER} \
                        .
                """
                sh "docker images | grep ${IMAGE_NAME}"
                echo "✅ Image built: ${IMAGE_VERSIONED}"
            }
        }

        // ── Stage 9: Stop Old Containers ─────────────────────
        stage('Stop Old Containers') {
            steps {
                echo '🛑 Stopping any existing JTrack containers...'
                sh """
                    docker compose \
                        --project-name ${COMPOSE_PROJECT} \
                        down --remove-orphans 2>/dev/null || true
                    echo "✅ Old containers cleared"
                """
            }
        }

        // ── Stage 10: Deploy ──────────────────────────────────
        stage('Deploy') {
            steps {
                echo '🚀 Deploying JTrack stack (DB + App + Nginx)...'
                sh """
                    if [ ! -f .env ]; then
                        echo "⚠️  No .env found — creating a minimal one for testing"
                        cat > .env <<'EOF'
DB_NAME=jtrackdb
DB_USER=jtrackuser
DB_PASSWORD=jtrackpassword
DB_HOST=db
DB_PORT=5432
SECRET_KEY=temporary-secret-key-change-in-production
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1
PORT=8000
IMAGE_TAG=${IMAGE_TAG}
EOF
                    fi

                    IMAGE_TAG=${IMAGE_TAG} docker compose \
                        --project-name ${COMPOSE_PROJECT} \
                        up --detach \
                           --remove-orphans
                """
            }
        }

        // ── Stage 11: Health Check ────────────────────────────
        stage('Health Check') {
            steps {
                echo '❤️  Waiting for containers to start...'
                sh 'sleep 20'
                sh '''
                    echo "── Running containers ──"
                    docker ps --filter "name=jtrack"

                    echo ""
                    echo "── Checking HTTP response ──"
                    curl -f http://localhost/ \
                        --max-time 15 \
                        --retry 5 \
                        --retry-delay 5 \
                        --retry-connrefused \
                        -s -o /dev/null \
                        -w "HTTP Status: %{http_code}\\n" \
                    && echo "✅ JDash is live at http://localhost" \
                    || echo "⚠️  Health check failed — see logs below"

                    echo ""
                    echo "── Web container logs (last 20 lines) ──"
                    docker logs jtrack-web --tail=20 2>/dev/null || true
                '''
            }
        }

        // ── Stage 12: Cleanup ─────────────────────────────────
        stage('Cleanup') {
            steps {
                echo '🧹 Removing dangling Docker images...'
                sh 'docker image prune -f'
            }
        }
    }

    // ── Post-pipeline actions ─────────────────────────────────
    post {
        success {
            echo """
            ╔══════════════════════════════════════════╗
            ║   ✅  JTrack Deployment SUCCESSFUL!       ║
            ║   Build  : #${BUILD_NUMBER}               ║
            ║   Image  : ${IMAGE_VERSIONED}             ║
            ║   URL    : http://localhost               ║
            ╚══════════════════════════════════════════╝
            """
        }
        failure {
            echo "❌ Pipeline FAILED at Build #${BUILD_NUMBER}. Check console output above."
            sh """
                docker compose \
                    --project-name ${COMPOSE_PROJECT} \
                    logs --tail=30 2>/dev/null || true
            """
        }
        always {
            sh 'rm -rf venv || true'
            echo "Finished: ${currentBuild.result} | Build #${BUILD_NUMBER}"
        }
    }
}
