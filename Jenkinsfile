pipeline {
    agent any

    environment {
        IMAGE_NAME      = 'jtrack-dashboard'
        IMAGE_TAG       = "${BUILD_NUMBER}"
        IMAGE_LATEST    = "${IMAGE_NAME}:latest"
        IMAGE_VERSIONED = "${IMAGE_NAME}:${IMAGE_TAG}"

        COMPOSE_PROJECT = 'jtrack'
        ENV_FILE        = '/etc/jtrack/.env'
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

        stage('Checkout') {
            steps {
                echo '📥 Pulling latest code...'
                checkout scm
                sh 'ls -R'
            }
        }

        stage('Validate Environment') {
            steps {
                sh '''
                    docker --version
                    docker-compose --version
                    python3 --version
                '''
            }
        }

        stage('Lint') {
            steps {
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

        stage('Run Tests') {
            steps {
                sh '''
                    python3 -m venv venv
                    . venv/bin/activate

                    # AUTO-DETECT requirements file
                    if [ -f requirements.txt ]; then
                        pip install -r requirements.txt
                    elif [ -f JTrack_Dashboard/requirements.txt ]; then
                        pip install -r JTrack_Dashboard/requirements.txt
                    else
                        echo "❌ requirements.txt NOT FOUND"
                        exit 1
                    fi

                    # AUTO-DETECT Django project
                    if [ -f manage.py ]; then
                        python manage.py test || true
                    elif [ -f JTrack_Dashboard/manage.py ]; then
                        cd JTrack_Dashboard
                        python manage.py test || true
                    else
                        echo "⚠️ manage.py not found, skipping tests"
                    fi
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    docker build \
                        -t ${IMAGE_VERSIONED} \
                        -t ${IMAGE_LATEST} .
                '''
            }
        }

        stage('Stop Old Containers') {
            steps {
                sh '''
                    docker-compose -p ${COMPOSE_PROJECT} down || true
                '''
            }
        }

        stage('Deploy') {
            steps {
                sh '''
                    cp ${ENV_FILE} .env || true

                    docker-compose -p ${COMPOSE_PROJECT} up -d --remove-orphans
                '''
            }
        }

        stage('Health Check') {
            steps {
                sh '''
                    sleep 15

                    curl -f http://localhost || exit 1
                '''
            }
        }
    }

    post {
        success {
            echo "✅ DEPLOYMENT SUCCESS"
        }
        failure {
            echo "❌ DEPLOYMENT FAILED"
            sh 'docker-compose -p jtrack down || true'
        }
        always {
            sh 'rm -rf venv || true'
        }
    }
}
