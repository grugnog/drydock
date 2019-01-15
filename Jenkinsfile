pipeline {
    agent any
    stages {
        stage('Code linting') {
            steps {
                script {
                    // Lint bash scripts using shellcheck
                    sh 'find * -name *.sh -print0 | xargs -n1 -I "{}" -0 docker run -i --rm -v "$PWD":/src  koalaman/shellcheck "/src/{}"'
                    // Lint Dockerfiles using hadolint
                    sh 'find * -name Dockerfile* -print0 | xargs -n1 -I "{}" -0 docker run -i --rm -v "$PWD":/src hadolint/hadolint hadolint "/src/{}"'
                }
            }
        }
        stage('Run parallel builds and tests') {
            parallel {
                stage('Build and test Acquia PHP 7.1 image') {
                    steps {
                        script {
                            dir('drupal/acquia') { 
                                withEnv(['VERSION=7.1']) {
                                    sh '../test/test.sh'
                                }
                            }
                        }
                    }
                }
                stage('Build and test Acquia PHP 7.2 image') {
                    steps {
                        script {
                            dir('drupal/acquia') { 
                                withEnv(['VERSION=7.2']) {
                                    sh '../test/test.sh'
                                }
                            }
                        }
                    }
                }
                stage('Build and test Pantheon PHP 7.1 image') {
                    steps {
                        script {
                            dir('drupal/pantheon') { 
                                withEnv(['VERSION=7.1']) {
                                    sh '../test/test.sh'
                                }
                            }
                        }
                    }
                }
                stage('Build and test Pantheon PHP 7.2 image') {
                    steps {
                        script {
                            dir('drupal/pantheon') { 
                                withEnv(['VERSION=7.2']) {
                                    sh '../test/test.sh'
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
