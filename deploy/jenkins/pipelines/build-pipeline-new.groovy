pipeline {
    environment {
        registryCredential = 'dockerhub-owllark'
        unitTestChanged = false
        cypressTestChanged = false
        appChanged = false
    }
    agent {
        kubernetes {
            inheritFrom "build-agent"
        }
    }
    
    stages {
       stage('Repository checkout') {
            steps {
                checkout scmGit(branches: [[name: 'development']], extensions: [], userRemoteConfigs: [[credentialsId: 'github-owllark', url: 'git@github.com:Owllark/igorbaran_devops_internship_practice.git']])            
            }
       }

        stage('Cloning Github repository to build agent') {
            steps {
                script {
                    container("build") {
                        git credentialsId: 'github-owllark', url: 'git@github.com:Owllark/igorbaran_devops_internship_practice.git', branch: 'development'
                        def changedFiles = sh(script: 'git diff --name-only HEAD^..HEAD', returnStdout: true).trim()
                        def changedFilesArray = changedFiles.split('\n')
                        unitTestChanged = changedFilesArray.any { it.startsWith('app/test/app.unittest') } || changedFilesArray.any { it == 'app/DockerfileUnitTest' }
                        cypressTestChanged = changedFilesArray.any { it.startsWith('app/test/cypresstest') } || changedFilesArray.any { it == 'app/DockerfileCypressTest' }
                        appChanged = changedFilesArray.any { it.startsWith('app/src/aspnetcoreapp') } || changedFilesArray.any { it == 'app/DockerfileApp' }
                        echo "Changed files in the last commit:"
                        echo changedFilesArray.join('\n')
                    }
                }
                
            }
        }

        stage('Building and pushing images') {
            steps {
                container("build") {
                    script {
                        if (unitTestChanged || cypressTestChanged || appChanged) {
                            withCredentials([usernamePassword(credentialsId: registryCredential,
                                                usernameVariable: 'USERNAME',
                                                passwordVariable: 'PASSWORD')]) {
                                    sh script:'''
                                        podman login -u ${USERNAME} -p ${PASSWORD} docker.io --tls-verify=false
                                        cd app/
                                    '''
                            }
                            if (unitTestChanged) {
                                echo "Building unit tests image..."
                                def imageName = "owllark/jenkins-agent-backend-test:$BUILD_NUMBER"
                                sh script:"""
                                        podman build -t ${imageName} -f DockerfileUnitTest .
                                        podman push ${imageName}
                                        podman rmi ${imageName}
                                    """
                            }
                            if (cypressTestChanged) {
                                echo "Building Cypress tests image..."
                                def imageName = "owllark/jenkins-agent-frontend-test:$BUILD_NUMBER"
                                sh script:"""
                                        podman build -t ${imageName} -f DockerfileCypressTest .
                                        podman push ${imageName}
                                        podman rmi ${imageName}
                                    """
                            }
                            if (appChanged) {
                                echo "Building application image..."
                                def imageName = "owllark/webapp:$BUILD_NUMBER"
                                sh script:"""
                                        podman build -t ${imageName} -f DockerfileApp .
                                        podman push ${imageName}
                                        podman rmi ${imageName}
                                    """
                            }
                        } else {
                            echo "No changes to build"
                        }
                    }
                }
            }
        }

        stage('Change image tag in deployment file, and push changes') {
                steps {
                    container("build") {
                        script {
                            def newImage = "owllark/webapp:$BUILD_NUMBER"
                            def deploymentFilePath = 'deploy/dev/deployment.yaml'

                            sh """
                                git config --global user.email "jenkins@gmail.com"
                                git config --global user.name "Jenkins"
                                git config --global --add safe.directory /home/jenkins/agent/workspace/ci_pipeline
                                git checkout -b staging
                                git merge origin/development
                            """
                            if (appChanged) {
                                sh """
                                    sed -i 's|image:.*|image: ${newImage}|' deploy/dev/deployment.yaml
                                    git add deploy/dev/deployment.yaml
                                    git commit -m 'Update deployment.yaml #$BUILD_NUMBER'
                                    git tag #$BUILD_NUMBER -- staging
                                """
                            } else {
                                sh """
                                    sed -i 's|image:.*|image: ${newImage}|' deploy/dev/deployment.yaml
                                    git add deploy/dev/deployment.yaml
                                    git commit -m 'Update #$BUILD_NUMBER'
                                    git tag #$BUILD_NUMBER -- staging
                                """
                            }

                            withCredentials([string(credentialsId: 'GITHUB_HOST_KEY', variable: 'GITHUB_HOST_KEY')]) {
                                sh 'mkdir -p ~/.ssh && echo "$GITHUB_HOST_KEY" >> ~/.ssh/known_hosts'
                            }
                            sshagent (credentials: ['github-owllark']) {
                                sh """
                                    git push -f origin -- staging
                                """
                            }
                        
                        }
                    }
                }
            }
    }
}


