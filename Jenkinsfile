/*
 * ==============================================================
 * Phase 4: Jenkinsfile (Declarative Pipeline)
 *
 * This file lives IN your Git repo alongside your code.
 * Jenkins reads it and executes each stage in order.
 * If any stage fails, the pipeline stops and you get notified.
 *
 * PIPELINE FLOW:
 *   Checkout → Test → Build Docker Image → Push to Docker Hub
 * ==============================================================
 */

pipeline {
    // 'any' means this can run on any available Jenkins agent.
    // In production, you might specify a label like 'docker' to
    // ensure it runs on a node that has Docker installed.
    agent any

    // Environment variables available to ALL stages.
    // credentials('dockerhub-credentials') pulls the username/password
    // you stored in Jenkins Credentials Manager (set this up in Jenkins UI).
    environment {
        DOCKER_IMAGE = 'yourdockerhubusername/devops-pipeline-app'
        DOCKER_TAG   = "${BUILD_NUMBER}"  // Jenkins auto-increments this
        REGISTRY_CREDENTIALS = credentials('dockerhub-credentials')
    }

    stages {

        /*
         * STAGE 1: CHECKOUT
         * Pull the latest code from your Git repository.
         * If you configured a webhook, this triggers automatically on push.
         * If not, Jenkins can poll the repo on a schedule (less ideal).
         */
        stage('Checkout') {
            steps {
                // 'checkout scm' uses the repo URL configured in the Jenkins job.
                // It handles cloning, fetching, and checking out the right branch.
                checkout scm
                echo "✅ Code checked out successfully"
            }
        }

        /*
         * STAGE 2: TEST
         * Run unit tests BEFORE building the Docker image.
         * Why test first? If tests fail, there's no point wasting time
         * building and pushing an image that's broken.
         * This is a core CI principle: fail fast, fail early.
         */
        stage('Test') {
            steps {
                sh '''
                    echo "🧪 Setting up Python virtual environment..."
                    python3 -m venv .venv
                    . .venv/bin/activate
                    pip install -r requirements.txt

                    echo "🧪 Running unit tests..."
                    python -m pytest tests/ -v --tb=short
                '''
                echo "✅ All tests passed"
            }
        }

        /*
         * STAGE 3: BUILD
         * Build the Docker image using the Dockerfile.
         * We tag it with both the build number (for traceability)
         * and 'latest' (for convenience).
         *
         * TAGGING STRATEGY:
         *   :3   → You can always find the exact image from build #3
         *   :latest → Always points to the most recent successful build
         */
        stage('Build') {
            steps {
                sh '''
                    echo "🐳 Building Docker image..."
                    docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
                    docker build -t ${DOCKER_IMAGE}:latest .
                '''
                echo "✅ Docker image built: ${DOCKER_IMAGE}:${DOCKER_TAG}"
            }
        }

        /*
         * STAGE 4: PUSH
         * Push the image to Docker Hub (your container registry).
         * After this, anyone (or any server) can pull and run your app.
         *
         * SECURITY NOTE:
         * NEVER put your Docker Hub password in this file.
         * Store it in Jenkins → Manage Jenkins → Credentials.
         * The 'credentials()' function in the environment block
         * injects it securely at runtime.
         */
        stage('Push') {
            steps {
                sh '''
                    echo "📦 Logging into Docker Hub..."
                    echo $REGISTRY_CREDENTIALS_PSW | docker login -u $REGISTRY_CREDENTIALS_USR --password-stdin

                    echo "📦 Pushing image to Docker Hub..."
                    docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
                    docker push ${DOCKER_IMAGE}:latest
                '''
                echo "✅ Image pushed to Docker Hub"
            }
        }
    }

    /*
     * POST ACTIONS
     * These run after the pipeline completes, regardless of success or failure.
     * Great for cleanup, notifications, or logging.
     */
    post {
        always {
            // Clean up workspace to save disk space on the Jenkins server
            cleanWs()
            echo "🧹 Workspace cleaned"
        }
        success {
            echo "🎉 Pipeline completed successfully!"
            echo "📦 Image available at: ${DOCKER_IMAGE}:${DOCKER_TAG}"
        }
        failure {
            echo "❌ Pipeline failed. Check the logs above for errors."
            // In production, you'd add Slack/email notifications here:
            // slackSend channel: '#devops', message: "Build ${BUILD_NUMBER} failed!"
        }
    }
}
