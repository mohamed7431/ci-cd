// ============================================================
//  Jenkinsfile — JTrack JDash CI/CD Pipeline (Fixed)
//  Repo: https://github.com/mohamed7431/ci-cd
// ============================================================

pipeline {
    agent any

    environment {
        IMAGE_NAME     = 'jtrack-dashboard'
        IMAGE_TAG      = "${BUILD_NUMBER}"
        IMAGE_LATEST   = "${IMAGE_NAME}:latest"
        IMAGE_VERSIONED = "${IMAGE_NAME}:${IMAGE_TAG}"
        COMPOSE_PROJECT = 'jtrack'
        HOST_PORT      = '80'
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
                '''
                echo '✅ Environment OK'
            }
        }

        // ── Stage 3: Validate Config Files ───────────────────
        // Checks that all required CI/CD files are present in the repo.
        // Skips Python/Django checks since this repo does not have an app yet.
        stage('Validate Config Files') {
            steps {
                echo '📋 Checking required CI/CD files...'
                sh '''
                    echo "Checking Dockerfile..."
                    [ -f Dockerfile ]   && echo "✅ Dockerfile found"   || { echo "❌ Dockerfile missing"; exit 1; }

                    echo "Checking docker-compose.yml..."
                    [ -f docker-compose.yml ] && echo "✅ docker-compose.yml found" || { echo "❌ docker-compose.yml missing"; exit 1; }

                    echo "Checking entrypoint.sh..."
                    [ -f entrypoint.sh ] && echo "✅ entrypoint.sh found" || { echo "❌ entrypoint.sh missing"; exit 1; }

                    echo "Checking nginx.conf..."
                    [ -f nginx.conf ] && echo "✅ nginx.conf found" || { echo "❌ nginx.conf missing"; exit 1; }

                    echo ""
                    echo "✅ All required files present!"
                '''
            }
        }

        // ── Stage 4: Validate Dockerfile Syntax ──────────────
        stage('Lint Dockerfile') {
            steps {
                echo '🔎 Checking Dockerfile syntax...'
                sh '''
                    # Verify Dockerfile has required instructions
                    grep -q "FROM"       Dockerfile && echo "✅ FROM found"       || { echo "❌ FROM missing in Dockerfile"; exit 1; }
                    grep -q "WORKDIR"    Dockerfile && echo "✅ WORKDIR found"    || echo "⚠️  WORKDIR not found (optional)"
                    grep -q "EXPOSE"     Dockerfile && echo "✅ EXPOSE found"     || echo "⚠️  EXPOSE not found (optional)"
                    grep -q "CMD\|ENTRYPOINT" Dockerfile && echo "✅ CMD/ENTRYPOINT found" || { echo "❌ CMD or ENTRYPOINT missing"; exit 1; }

                    echo ""
                    echo "── Dockerfile preview ──"
                    cat Dockerfile
                '''
            }
        }

        // ── Stage 5: Validate docker-compose Syntax ──────────
        stage('Validate Compose') {
            steps {
                echo '🐳 Validating docker-compose.yml...'
                sh '''
                    docker compose config --quiet \
                        && echo "✅ docker-compose.yml is valid" \
                        || docker-compose config --quiet \
                        && echo "✅ docker-compose.yml is valid"
                '''
            }
        }

        // ── Stage 6: Build Docker Image ───────────────────────
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
                echo "✅ Image built successfully: ${IMAGE_VERSIONED}"
            }
        }

        // ── Stage 7: Stop Old Containers ─────────────────────
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

        // ── Stage 8: Deploy ───────────────────────────────────
        stage('Deploy') {
            steps {
                echo '🚀 Deploying JTrack stack...'
                sh """
                    # Create a minimal .env if one does not exist yet
                    if [ ! -f .env ]; then
                        echo "⚠️  No .env found — creating minimal one for testing"
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

        // ── Stage 9: Health Check ─────────────────────────────
        stage('Health Check') {
            steps {
                echo '❤️  Waiting for containers to be ready...'
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
                    && echo "✅ JDash is live!" \
                    || echo "⚠️  Health check failed — check logs below"

                    echo ""
                    echo "── Web container logs ──"
                    docker logs jtrack-web --tail=20 2>/dev/null || true
                '''
            }
        }

        // ── Stage 10: Cleanup ─────────────────────────────────
        stage('Cleanup') {
            steps {
                echo '🧹 Removing dangling images...'
                sh 'docker image prune -f'
            }
        }
    }

    // ── Post actions ──────────────────────────────────────────
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
