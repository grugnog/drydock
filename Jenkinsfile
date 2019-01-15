pipeline {
    agent any
    stages {
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