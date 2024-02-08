
pipeline {
    agent {
        kubernetes {
            inheritFrom "default"
        }
    }
    stages{
       stage ('Clone staging branch') {
           steps {
               git credentialsId: 'github-owllark', url: 'git@github.com:Owllark/igorbaran_devops_internship_practice.git', branch: 'staging'
           }
       }

        stage('Unit tests') {
          agent {
            kubernetes {
                inheritFrom "backend-test-agent"
            }
        }
            steps {
                script {
                    container("backend-test") {

                        catchError(buildResult: 'SUCCESS', stageResult: 'SUCCESS') {
                            sh """
                                dotnet test /testing/test/app.unittest --results-directory /testing/TestResults --logger "trx;LogFileName=test-results.trx"
                            """
                        }
                    }
                }
                script {
                    container("backend-test") {
                        sh """
                            ls -la $WORKSPACE
                            cp /testing/TestResults/test-results.trx $WORKSPACE
                        """
                    } 
                }
                
            }
            post {
                always {
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

                        catchError(buildResult: 'SUCCESS', stageResult: 'SUCCESS') {
                            sh """
                                cd /testing
                                npx cypress run --browser chromium
                            """
                        }
                    }
                }
                script {
                    container("frontend-test") {
                        sh """
                            cp -r /testing/reports $WORKSPACE
                            cp /testing/test-result.xml $WORKSPACE
                        """
                    } 
                }
            }
            post {
                always {
                     publishHTML([allowMissing: false,
                                  alwaysLinkToLastBuild: false,
                                  keepAll: true,
                                  reportDir: 'reports',
                                  reportFiles: 'report.html',
                                  reportName: 'Cypress Report',
                                  reportTitles: 'Cypress e2e tests',
                                  useWrapperFileDirectly: true])
                     junit stdioRetention: '', testResults: 'test-result.xml'
                }
            }
        }
        
        stage('Push changes to release branch') {
            when {
                expression { currentBuild.resultIsBetterOrEqualTo('SUCCESS') }
            }
                steps {
                    script {
                        
                        withCredentials([string(credentialsId: 'GITHUB_HOST_KEY', variable: 'GITHUB_HOST_KEY')]) {
                            sh 'mkdir -p ~/.ssh && echo "$GITHUB_HOST_KEY" >> ~/.ssh/known_hosts'
                        }
    
                        sh """
                            git config --global user.email "jenkins@gmail.com"
                            git config --global user.name "Jenkins"
                            git config --global --add safe.directory /home/jenkins/agent/workspace/ci_pipeline
                        """
                        sh """
                            git checkout -b release origin/release
                            git merge origin/staging
                        """
                        sshagent (credentials: ['github-owllark']) {
                            sh """
                                git push -f origin -- release
                            """
                        }
                    }
                }
            }
    }
}




