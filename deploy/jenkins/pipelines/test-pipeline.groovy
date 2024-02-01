
pipeline {
    environment {
        registry = 'owllark/webapp'
        registryCredential = 'dockerhub-owllark'
        testsPassed = true
    }
    agent any
    stages{
       stage('Testing') {
            parallel {
                stage('Unit tests') {
                  agent {
                    kubernetes {
                        inheritFrom "backend-test-agent"
                    }
                }
                    steps {
                        script {
                            container("backend-test") {
                                sh """
                                    cp /reports/test-results.trx ${WORKSPACE}
                                    cp /reports/test_output ${WORKSPACE}
                                """
                                def cypressOutput = sh(script: 'cat test_output', returnStdout: true).trim()
                                if (cypressOutput.contains("Passed!")) {
                                        echo "All tests passed."
                                    } else {
                                        echo "Some tests failed. Setting build status to UNSTABLE."
                                        currentBuild.result = 'UNSTABLE'
                                        testsPassed = false
                                    }
                                sh """
                                    rm -r /reports/*
                                """
                            }
                        }
                    }
                    post {
                        success {
                            mstest testResultsFile:"test-results.trx", keepLongStdio: true
                        }
                        unstable {
                            mstest testResultsFile:"test-results.trx", keepLongStdio: true
                        }
                    }
                }
        
                stage('E2E tests') {
                  agent {
                    kubernetes {
                        inheritFrom "frontend-test-agent"
                    }
                  }
                    steps {
                        script {
                              container("frontend-test") {
                              sh """
                                cp -r /reports ${WORKSPACE}
                              """
                              def cypressOutput = sh(script: 'cat reports/test_output', returnStdout: true).trim()
                              if (cypressOutput.contains("All specs passed")) {
                                    echo "All tests passed."
                                } else {
                                    echo "Some tests failed. Setting build status to UNSTABLE."
                                    currentBuild.result = 'UNSTABLE'
                                    testsPassed = false
                                }
                             sh """
                                rm -r /reports/*
                             """
                            }
                        }
                    }
                    post {
                        success {
                             publishHTML([allowMissing: false,
                                          alwaysLinkToLastBuild: false,
                                          keepAll: true,
                                          reportDir: 'reports',
                                          reportFiles: 'report.html',
                                          reportName: 'Cypress Report',
                                          reportTitles: 'Cypress e2e tests',
                                          useWrapperFileDirectly: true])
                        }
                        unstable {
                             publishHTML([allowMissing: false,
                                          alwaysLinkToLastBuild: false,
                                          keepAll: true,
                                          reportDir: 'reports',
                                          reportFiles: 'report.html',
                                          reportName: 'Cypress Report',
                                          reportTitles: 'Cypress e2e tests',
                                          useWrapperFileDirectly: true])
                        }
                    }
                }
            }
        }
        stage('Push changes to release branch') {
            agent {
                kubernetes {
                    inheritFrom "build-agent"
                }
            }
                steps {
                    container("build") {
                        script {
                            if (testsPassed) {
                                git credentialsId: 'github-owllark', url: 'git@github.com:Owllark/igorbaran_devops_internship_practice.git', branch: 'staging'

                                def newImage = "${registry}:$BUILD_NUMBER"
                                def deploymentFilePath = 'deploy/dev/deployment.yaml'
                                
                                withCredentials([string(credentialsId: 'GITHUB_HOST_KEY', variable: 'GITHUB_HOST_KEY')]) {
                                    sh 'mkdir -p ~/.ssh && echo "$GITHUB_HOST_KEY" >> ~/.ssh/known_hosts'
                                }

                                sh """
                                    git config --global user.email "jenkins@gmail.com"
                                    git config --global user.name "Jenkins"
                                    git config --global --add safe.directory /home/jenkins/agent/workspace/ci_pipeline
                                """
                                sh """
                                    git checkout -b release
                                    git merge staging
                                """
                                sshagent (credentials: ['github-owllark']) {
                                    sh """
                                        git push -f origin -- release
                                    """
                                }
                            } else {
                                echo "Cannot push - some tests failed"
                            }
                            
                        
                        }
                    }
                }
            }
    }
}




