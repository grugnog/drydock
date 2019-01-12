pipeline {
    agent any
    stages {
        stage('Build and test Acquia images') {
            steps {
                script {
                    dir('drupal/acquia') { 
                        withEnv(['VERSION=7.1']) {
                            sh '../test/test.sh'
                        }
                        withEnv(['VERSION=7.2']) {
                            sh '../test/test.sh'
                        }
                    }
                }
            }
        }
    }
}