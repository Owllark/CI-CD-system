def getPreviousUnsuccessfullBuilds(passedBuilds, build) {
    if ((build != null) && (build.result != 'SUCCESS')) {
        passedBuilds.add(build)
        getPreviousUnsuccessfullBuilds(passedBuilds, build.getPreviousBuild())
    }
}

def getAffectedFilePaths() {

    def passedBuilds = [currentBuild]

    getPreviousUnsuccessfullBuilds(passedBuilds, currentBuild.getPreviousBuild());

    def affectedPaths  = []
    for (int x = 0; x < passedBuilds.size(); x++) {
        def currentBuild = passedBuilds[x];
        def changeLogSets = currentBuild.rawBuild.changeSets
        for (int i = 0; i < changeLogSets.size(); i++) {
            def entries = changeLogSets[i].items
            for (int j = 0; j < entries.length; j++) {
                def entry = entries[j]
                affectedPaths.addAll(entry.getAffectedPaths())
            }
        }
    }
    return affectedPaths.unique();
}

pipeline {
    environment {
        registryCredential = 'dockerhub-owllark'
        unitTestChanged = false
        cypressTestChanged = false
        appChanged = false
        manifestsChanged = false
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

      stage('Cloning Github repository') {
        steps {
            script {
                container("build") {
                    git credentialsId: 'github-owllark', url: 'git@github.com:Owllark/igorbaran_devops_internship_practice.git', branch: 'development'
                
                    def affectedFilePaths = getAffectedFilePaths()
                    unitTestChanged = affectedFilePaths.any { it.startsWith('app/test/app.unittest') } || affectedFilePaths.any { it == 'app/DockerfileUnitTest' }
                    cypressTestChanged = affectedFilePaths.any { it.startsWith('app/test/cypresstest') } || affectedFilePaths.any { it == 'app/DockerfileCypressTest' }
                    appChanged = affectedFilePaths.any { it.startsWith('app/src/aspnetcoreapp') } || affectedFilePaths.any { it == 'app/DockerfileApp' }
                    manifestsChanged = affectedFilePaths.any { it.startsWith('deploy/dev') }
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
                                    '''
                            }
                            if (unitTestChanged) {
                                echo "Building unit tests image..."
                                def imageName = "owllark/jenkins-agent-backend-test:latest"
                                sh script:"""
                                        cd app/
                                        podman build -t ${imageName} -f DockerfileUnitTest .
                                        podman push ${imageName}
                                        podman rmi ${imageName}
                                    """
                            }
                            if (cypressTestChanged) {
                                echo "Building Cypress tests image..."
                                def imageName = "owllark/jenkins-agent-frontend-test:latest"
                                sh script:"""
                                        cd app/
                                        podman build -t ${imageName} -f DockerfileCypressTest .
                                        podman push ${imageName}
                                        podman rmi ${imageName}
                                    """
                            }
                            if (appChanged) {
                                echo "Building application image..."
                                def imageName = "owllark/webapp:$BUILD_NUMBER"
                                sh script:"""
                                        cd app/
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

                            sh """
                                git config --global user.email "jenkins@gmail.com"
                                git config --global user.name "Jenkins"
                                git config --global --add safe.directory /home/jenkins/agent/workspace/build_pipeline
                                git checkout -b staging
                                git merge origin/development
                            """
                            if (appChanged) {
                                def newImage = "owllark/webapp:$BUILD_NUMBER"
                                def deploymentFilePath = 'deploy/dev/deployment.yaml'
                                sh """
                                    sed -i 's|image:.*|image: ${newImage}|' ${deploymentFilePath}
                                    git add ${deploymentFilePath}
                                    git commit -m 'Update deployment.yaml #$BUILD_NUMBER'
                                    git tag #$BUILD_NUMBER -- staging
                                """
                            } else {
                                sh """
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

