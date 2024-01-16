pipeline {
    environment {
        registry = 'owllark/webapp'
        registryCredential = 'dockerhub-owllark'
    }
    agent {
        kubernetes {
            label "build"
            cloud "kubernetes"
            yaml '''
apiVersion: v1
kind: Pod
metadata:
  namespace: "jenkins"
spec:
  containers:
    - name: build
      imagePullPolicy: Always
      image: owllark/jenkins-agent-build:latest
      command:
        - cat
      tty: true
      securityContext:
        privileged: true
      volumeMounts:
        - mountPath: /var/lib/containers
          name: podman-volume
        - mountPath: /dev/shm
          name: devshm-volume
        - mountPath: /var/run
          name: varrun-volume
        - mountPath: /tmp
          name: tmp-volume
  restartPolicy: Never
  volumes:
    - name: podman-volume
      emptyDir: {}
    - emptyDir:
        medium: Memory
      name: devshm-volume
    - emptyDir: {}
      name: varrun-volume
    - emptyDir: {}
      name: tmp-volume
'''
        }
    }
    
    stages {
       stage('Repository checkout') {
            steps {
                checkout scmGit(branches: [[name: '**']], extensions: [], userRemoteConfigs: [[credentialsId: 'github-owllark', name: 'igorbaran_devops_internship_practice', refspec: 'refs/heads/master:refs/remotes/origin/release', url: 'git@github.com:Owllark/igorbaran_devops_internship_practice.git']])            }
       }
        stage('Unit tests') {
          agent {
            kubernetes {
                label "backend-test"
                cloud "kubernetes"
                yaml '''
apiVersion: v1
kind: Pod
metadata:
  namespace: "jenkins"
spec:
  containers:
    - name: backend-test
      image: owllark/jenkins-agent-backend-test:latest
      command:
        - cat
      tty: true
    '''
            }
        }
            steps {
                container("backend-test") {
                  git credentialsId: 'github-owllark', url: 'git@github.com:Owllark/igorbaran_devops_internship_practice.git', branch: 'main'
                  sh script:'''
                      cd app/
                      dotnet test
                    '''
                }
            }
        }
        stage('Cloning Github repository to build agent') {
            steps {
                container("build") {
                    git credentialsId: 'github-owllark', url: 'git@github.com:Owllark/igorbaran_devops_internship_practice.git', branch: 'release'
                }
            }
        }
        stage('Building image') {
            steps {
                container("build") {
                    script {
                        withCredentials([usernamePassword(credentialsId: registryCredential,
                                               usernameVariable: 'USERNAME',
                                               passwordVariable: 'PASSWORD')]) {
                          sh script:'''
                              cd app/src/aspnetcoreapp/
                              podman login -u ${USERNAME} -p ${PASSWORD} docker.io --tls-verify=false
                              podman build -t ${registry}:$BUILD_NUMBER .
                            '''
                        }
                    }
                }
            }
        }

        stage('Push image') {
            steps {
                container("build") {
                    script {
                        sh script:'''
                            podman push ${registry}:$BUILD_NUMBER
                          '''
                    }
                }
            }
        }

        stage('E2E tests') {
          agent {
            kubernetes {
                label "frontend-test"
                cloud "kubernetes"
                yaml """
apiVersion: v1
kind: Pod
metadata:
  name: test-pod
  namespace: jenkins
spec:
  containers:
  - name: frontend-test
    image: owllark/jenkins-agent-frontend-test:latest
    command:
      - cat
    tty: true
  - name: test-container
    image: ${registry}:$BUILD_NUMBER
    ports:
    - containerPort: 8080
  imagePullSecrets:
  - name: dockerhub-secret
    """
            }
        }
            steps {
                container("frontend-test") {
                  
                  
                  git credentialsId: 'github-owllark', url: 'git@github.com:Owllark/igorbaran_devops_internship_practice.git', branch: 'release'
                  sh script:'''
                      cd app/test/cypresstest
                      npm install cypress --save-dev
                      npx cypress run --browser chromium
                    '''
                }
            }
        }


        stage('Change image tag in deployment file, and push changes') {
            steps {
                container("build") {
                    script {
                        def newImage = "${registry}:$BUILD_NUMBER"
                        def deploymentFilePath = 'deploy/dev/deployment.yaml'

                        sh """
                            git config --global user.email "jenkins@gmail.com"
                            git config --global user.name "Jenkins"
                            git config --global --add safe.directory /home/jenkins/agent/workspace/ci_pipeline
                            git checkout -b deploy
                            git merge release
                            sed -i 's|image:.*|image: ${newImage}|' deploy/dev/deployment.yaml
                            git add deploy/dev/deployment.yaml
                            git commit -m 'Update deployment.yaml #$BUILD_NUMBER'
                            git tag #$BUILD_NUMBER -- deploy
                        """

                        withCredentials([string(credentialsId: 'GITHUB_HOST_KEY', variable: 'GITHUB_HOST_KEY')]) {
                            sh 'mkdir -p ~/.ssh && echo "$GITHUB_HOST_KEY" >> ~/.ssh/known_hosts'
                        }
                        sshagent (credentials: ['github-owllark']) {
                            sh """
                                git checkout -- deploy
                                git push -f origin -- deploy
                            """
                        }
                    
                    }
                }
            }
        }

        stage('Cleaning up') {
            steps {
                container("build") {
                    script {
                        sh script:'''
                            podman rmi ${registry}:$BUILD_NUMBER
                          '''
                    }
                }
            }
        }

    }
}


