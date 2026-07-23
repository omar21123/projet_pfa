pipeline {
    agent any

    environment {
        DEV_NETWORK  = "devsecops-net"
        MAIL_NETWORK = "mail-net"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Lint & Static Analysis') {
            parallel {
                stage('PHPStan (Backend)') {
                    steps {
                        dir('backend') {
                            sh 'composer install --no-interaction --prefer-dist'
                            sh './vendor/bin/phpstan analyse --error-format=jenkins || true'
                        }
                    }
                }
                stage('ESLint (Frontend)') {
                    steps {
                        dir('frontend') {
                            sh 'npm install'
                            sh 'npx eslint . --max-warnings=0 || true'
                        }
                    }
                }
            }
        }

        stage('PHPUnit Tests') {
            steps {
                dir('backend') {
                    sh './vendor/bin/phpunit --log-junit junit.xml'
                }
                junit 'backend/junit.xml'
            }
        }

        stage('OWASP Dependency Check') {
            steps {
                dependencyCheck additionalArguments: '--format HTML --format XML', odcInstallation: 'Default'
                dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
            }
        }

        stage('Build Docker Images') {
            steps {
                script {
                    echo "Construction des images Docker..."
                    sh 'docker compose -f docker-compose.yml build'
                }
            }
        }

        stage('Security Scan (Trivy)') {
            steps {
                script {
                    echo "Scan de l'image backend avec Trivy..."
                    sh "docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:0.53.0 image --exit-code 0 --severity HIGH,CRITICAL prpjet_pfa-backend"
                }
            }
        }

        stage('Deploy Staging') {
            steps {
                script {
                    echo "Création des réseaux Docker s'ils n'existent pas..."
                    sh "docker network create ${env.DEV_NETWORK} || true"
                    sh "docker network create ${env.MAIL_NETWORK} || true"

                    echo "Déploiement de la stack principale..."
                    sh 'docker compose -f docker-compose.yml up -d --remove-orphans'

                    echo "Déploiement du serveur mail..."
                    sh 'docker compose -f docker-compose.mail.yml up -d --remove-orphans'

                    echo "Exécution des migrations de la base de données..."
                    sh 'docker exec laravel php artisan migrate --force || true'
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
        success {
            echo "Pipeline exécuté avec succès !"
        }
        failure {
            echo "Le pipeline a échoué."
        }
    }
}
