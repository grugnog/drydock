pipeline {
    agent any
    environment { 
        PREFIX = 'civicactions/drydock-'
        TAG = "${env.BRANCH_NAME}"
    }
    stages {
        stage('Code linting') {
            steps {
                script {
                    // Output environment for debugging
                    sh 'export'
                    // Check bash script formatting
                    sh 'find * -name *.sh -print0 | xargs -n1 -I "{}" -0 docker run -i -v "$(pwd)":/workdir -w /workdir unibeautify/beautysh --files "/workdir/{}"'
                    // Can't check exit code, so just test if files changed on disk
                    sh 'if ! git diff-index --quiet HEAD --; then echo "Bash not matching beautysh style"; exit 1; fi'
                    // Lint bash scripts using shellcheck
                    sh 'find * -name *.sh -print0 | xargs -n1 -I "{}" -0 docker run -i --rm -v "$PWD":/src  koalaman/shellcheck "/src/{}"'
                    // Lint Dockerfiles using hadolint
                    sh 'find * -name Dockerfile* -print0 | xargs -n1 -I "{}" -0 docker run -i --rm -v "$PWD":/src hadolint/hadolint hadolint "/src/{}"'
                    // Lint PHP using php-cs-fixer
                    sh 'docker run -i -v "$(pwd)":/workdir -w /workdir -e PHP_CS_FIXER_IGNORE_ENV=1 unibeautify/php-cs-fixer fix -v --dry-run --stop-on-violation --using-cache=no tools/getconfig.php'
                }
            }
        }
        stage('Run builds') {
            steps {
                script {
                    sh 'habitus -keep-all -f build-core.yml'
                    sh 'habitus -keep-all -f build-saas.yml'
                }
            }
        }
        stage('Run RHEL 7 builds') {
            agent { 
                label 'rhel-7-latest-docker'
            }
            steps {
                script {
                    sh 'curl -L --progress-bar -o /home/jenkins/habitus https://github.com/cloud66-oss/habitus/releases/download/1.0.3/habitus_linux_amd64 && chmod a+x /home/jenkins/habitus'
                    sh '/home/jenkins/habitus -keep-all -f build-rhel.yml'
                }
            }
        }
        stage('Test Acquia PHP 7.1 image') {
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
        stage('Test Acquia PHP 7.2 image') {
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
        stage('Test Pantheon PHP 7.1 image') {
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
        stage('Test Pantheon PHP 7.2 image') {
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
        stage('OpenSCAP Scans') {
            steps {
                script {
                    // TODO: Identify the images to scan by filtering Docker images by label.
                    sh 'docker run --rm -i -v /var/run/docker.sock:/var/run/docker.sock "${PREFIX}security-openscap7-centos:${TAG}" auto "${PREFIX}baseline7-centos-disa:${TAG}"'
                    sh 'docker run --rm -i -v /var/run/docker.sock:/var/run/docker.sock "${PREFIX}security-openscap7-centos:${TAG}" auto "${PREFIX}baseline7-centos-usgcb:${TAG}"'
                }
            }
        }
    }
}
