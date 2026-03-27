// ============================================================
//  Jenkinsfile — JTrack JDash CI/CD Pipeline
//
//  Flow:
//  GitHub Push → Checkout → Lint → Test → Build Docker Image
//  → Push to Registry (optional) → Deploy → Health Check
// ============================================================

pipeline {
    agent any

    // ── Pipeline-wide environment variables ──────────────────
    environment {
        // Docker image name (change to your Docker Hub: user/jtrack-dashboard)
        IMAGE_NAME       = 'jtrack-dashboard'
        IMAGE_TAG        = "${BUILD_NUMBER}"        // Unique tag per build
        IMAGE_LATEST     = "${IMAGE_NAME}:latest"
        IMAGE_VERSIONED  = "${IMAGE_NAME}:${IMAGE_TAG}"

        // Container & compose project name
        COMPOSE_PROJECT  = 'jtrack'
        WEB_CONTAINER    = 'jtrack-web'
        DB_CONTAINER     = 'jtrack-db'
        NGINX_CONTAINER  = 'jtrack-nginx'

        // Django settings used during test stage
        DJANGO_SETTINGS_MODULE = 'jdash.settings.test'

        // Path to your .env file on the Jenkins server
        ENV_FILE         = '/etc/jtrack/.env'
    }

    // ── Auto-trigger on GitHub push ──────────────────────────
    triggers {
        githubPush()
    }

    // ── Pipeline options ─────────────────────────────────────
    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 30, unit: 'MINUTES')
        disableConcurrentBuilds()
    }

    stages {

        // ── Stage 1: Checkout ────────────────────────────────
        stage('Checkout') {
            steps {
                echo '📥 Pulling latest JTrack code from GitHub...'
                checkout scm
                sh 'git log --oneline -5'   // Show last 5 commits for context
            }
        }

        // ── Stage 2: Validate Environment ────────────────────
        stage('Validate Environment') {
            steps {
                echo '🔍 Checking required tools...'
                sh '''
                    docker --version
                    docker compose version
                    python3 --version || python --version
                '''
                echo '✅ Environment OK'
            }
        }

        // ── Stage 3: Lint (Python code quality) ──────────────
        stage('Lint') {
            steps {
                echo '🔎 Running Python linter (flake8)...'
                sh '''
                    pip install flake8 --quiet
                    # Lint all Python files, ignore line-length & import warnings
                    flake8 . --count \
                             --max-line-length=120 \
                             --exclude=migrations,venv,staticfiles \
                             --statistics || true
                '''
            }
        }

        // ── Stage 4: Unit Tests ───────────────────────────────
        stage('Run Tests') {
            steps {
                echo '🧪 Setting up test environment and running Django tests...'
                sh '''
                    # Install dependencies in a lightweight venv
                    python3 -m venv venv
                    . venv/bin/activate
                    pip install -r requirements.txt --quiet

                    # Run Django unit tests with test settings (uses SQLite)
                    python manage.py test \
                        --settings=jdash.settings.test \
                        --verbosity=2 \
                        --keepdb
                '''
            }
            post {
                failure {
                    echo '❌ Tests failed! Fix errors before deploying.'
                }
                success {
                    echo '✅ All tests passed!'
                }
            }
        }

        // ── Stage 5: Build Docker Image ───────────────────────
        stage('Build Docker Image') {
            steps {
                echo "🐳 Building Docker image: ${IMAGE_VERSIONED}..."
                sh """
                    docker build \
                        --tag ${IMAGE_VERSIONED} \
                        --tag ${IMAGE_LATEST} \
                        --build-arg BUILD_NUMBER=${BUILD_NUMBER} \
                        --no-cache \
                        .
                """
                sh "docker images | grep ${IMAGE_NAME}"
            }
        }

        // ── Stage 6: Stop Running Containers ─────────────────
        stage('Stop Old Containers') {
            steps {
                echo '🛑 Stopping existing JTrack containers...'
                sh """
                    docker compose \
                        --project-name ${COMPOSE_PROJECT} \
                        down --remove-orphans || true
                """
                echo '✅ Old containers stopped.'
            }
        }

        // ── Stage 7: Deploy New Stack ─────────────────────────
        stage('Deploy') {
            steps {
                echo '🚀 Deploying JTrack JDash stack (DB + Web + Nginx)...'
                sh """
                    # Copy the production .env file
                    cp ${ENV_FILE} .env

                    # Set the image tag so docker-compose uses the new image
                    export IMAGE_TAG=${IMAGE_TAG}

                    # Start all services in detached mode
                    docker compose \
                        --project-name ${COMPOSE_PROJECT} \
                        up --detach \
                           --remove-orphans
                """
            }
        }

        // ── Stage 8: Health Check ─────────────────────────────
        stage('Health Check') {
            steps {
                echo '❤️  Waiting for JDash to start...'
                sh 'sleep 15'   // Give Django + Gunicorn time to boot

                sh '''
                    # Check Nginx is responding
                    curl -f http://localhost/health/ \
                        --max-time 10 \
                        --retry 5 \
                        --retry-delay 5 \
                        --retry-connrefused \
                        -s -o /dev/null \
                        -w "HTTP Status: %{http_code}\\n"
                '''
                echo '✅ JDash is live and healthy!'
            }
        }

        // ── Stage 9: Cleanup Old Images ───────────────────────
        stage('Cleanup') {
            steps {
                echo '🧹 Removing old Docker images to free disk space...'
                sh '''
                    docker image prune -f
                    # Keep only the last 3 versioned images
                    docker images jtrack-dashboard --format "{{.Tag}}" \
                        | sort -rn \
                        | tail -n +4 \
                        | xargs -I {} docker rmi jtrack-dashboard:{} || true
                '''
            }
        }
    }

    // ── Post-pipeline actions ─────────────────────────────────
    post {
        success {
            echo """
            ╔══════════════════════════════════════════╗
            ║   ✅  JTrack Deployment SUCCESSFUL!       ║
            ║   Build : #${BUILD_NUMBER}                ║
            ║   Image : ${IMAGE_VERSIONED}              ║
            ║   URL   : http://your-server-ip/          ║
            ╚══════════════════════════════════════════╝
            """
        }
        failure {
            echo """
            ╔══════════════════════════════════════════╗
            ║   ❌  JTrack Deployment FAILED!           ║
            ║   Build : #${BUILD_NUMBER}                ║
            ║   Check the console output above.        ║
            ╚══════════════════════════════════════════╝
            """
            // Optional: roll back to previous image
            sh """
                docker compose \
                    --project-name ${COMPOSE_PROJECT} \
                    down || true
            """
        }
        always {
            // Clean up the local venv created during tests
            sh 'rm -rf venv || true'
            echo "Pipeline finished at: ${new Date()}"
        }
    }
}
