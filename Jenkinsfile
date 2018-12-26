pipeline {
    agent any
    stages {
        stage('Build and test Acquia images') {
            steps {
                script {
                    dir('drupal/acquia') { 
                        sh '../test/test.sh'
                    }
                }
            }
        }
    }
}