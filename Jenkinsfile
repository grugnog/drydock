pipeline {
    agent none
    stages {
        stage('Build and test Acquia images') {
            agent any
            steps {
                script {
                    dir 'drupal/acquia'
                    sh '../test/test.sh'
                }
            }
        }
    }
}