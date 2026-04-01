pipeline {
    agent any

    environment {
        IMAGE_NAME       = 'jtrack-dashboard'
        IMAGE_TAG        = "${BUILD_NUMBER}"
        IMAGE_LATEST     = "${IMAGE_NAME}:latest"
        IMAGE_VERSIONED  = "${IMAGE_NAME}:${IMAGE_TAG}"

        COMPOSE_PROJECT  = 'jtrack'

        DJANGO_SETTINGS_MODULE = 'jdash.settings.test'
        ENV_FILE         = '/etc/jtrack/.env'
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

        // ── Checkout ─────────────────────────────
        stage('Checkout') {
            steps {
                echo '📥 Pulling latest code from GitHub...'
                checkout scm
                sh 'git log --oneline -5'
            }
        }

        // ── Validate Environment ─────────────────
        stage('Validate Environment') {
            steps {
                echo '🔍 Checking required tools...'
                sh '''
                    docker --version
                    docker-compose --version
                    python3 --version || python --version
                '''
                echo '✅ Environment OK'
            }
        }

        // ── Lint ────────────────────────────────
       stage('Lint') {
    steps {
        echo '🔎 Running flake8...'
        sh '''
            python3 -m venv venv
            . venv/bin/activate

            pip install flake8 --quiet

            flake8 . --count \
                     --max-line-length=120 \
                     --exclude=migrations,venv,staticfiles \
                     --statistics || true
        '''
    }
}

        // ── Run Tests ───────────────────────────
    stage('Run Tests') {
    steps {
        echo '🧪 Running Django tests...'
        sh '''
            python3 -m venv venv
            . venv/bin/activate

            pip install -r JTrack_Dashboard/requirements.txt --quiet

            cd JTrack_Dashboard

            python manage.py test \
                --settings=jdash.settings.test \
                --verbosity=2 \
                --keepdb
        '''
    }
}

        // ── Build Docker Image ──────────────────
        stage('Build Docker Image') {
            steps {
                echo "🐳 Building Docker image: ${IMAGE_VERSIONED}"
                sh """
                    docker build \
                        -t ${IMAGE_VERSIONED} \
                        -t ${IMAGE_LATEST} \
                        --build-arg BUILD_NUMBER=${BUILD_NUMBER} \
                        .
                """
            }
        }

        // ── Stop Old Containers ────────────────
        stage('Stop Old Containers') {
            steps {
                echo '🛑 Stopping old containers...'
                sh """
                    docker-compose -p ${COMPOSE_PROJECT} down --remove-orphans || true
                """
            }
        }

        // ── Deploy ─────────────────────────────
        stage('Deploy') {
            steps {
                echo '🚀 Deploying application...'
                sh """
                    cp ${ENV_FILE} .env || true

                    export IMAGE_TAG=${IMAGE_TAG}

                    docker-compose -p ${COMPOSE_PROJECT} up -d --remove-orphans
                """
            }
        }

        // ── Health Check ───────────────────────
        stage('Health Check') {
            steps {
                echo '❤️ Checking application health...'
                sh 'sleep 20'

                sh '''
                    curl -f http://localhost/health/ \
                        --max-time 10 \
                        --retry 5 \
                        --retry-delay 5 \
                        --retry-connrefused \
                        -s -o /dev/null \
                        -w "HTTP Status: %{http_code}\\n"
                '''
            }
        }

        // ── Cleanup ────────────────────────────
        stage('Cleanup') {
            steps {
                echo '🧹 Cleaning old images...'
                sh '''
                    docker image prune -f

                    docker images jtrack-dashboard --format "{{.Tag}}" \
                        | sort -rn \
                        | tail -n +4 \
                        | xargs -I {} docker rmi jtrack-dashboard:{} || true
                '''
            }
        }
    }

    post {
        success {
            echo """
            ╔══════════════════════════════════════════╗
            ║   ✅  DEPLOYMENT SUCCESSFUL!              ║
            ║   Build : #${BUILD_NUMBER}               ║
            ║   Image : ${IMAGE_VERSIONED}             ║
            ╚══════════════════════════════════════════╝
            """
        }

        failure {
            echo """
            ╔══════════════════════════════════════════╗
            ║   ❌  DEPLOYMENT FAILED!                 ║
            ║   Build : #${BUILD_NUMBER}               ║
            ║   Check logs above                      ║
            ╚══════════════════════════════════════════╝
            """

            sh """
                docker-compose -p ${COMPOSE_PROJECT} down || true
            """
        }

        always {
            sh 'rm -rf venv || true'
            echo "Pipeline finished at: ${new Date()}"
        }
    }
}
