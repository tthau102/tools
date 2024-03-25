// git repository info
def gitRepository = 'https://github.com/trantrunghau0102/Obo-SpringBoot-Java.git'
def gitBranch = 'master'

// gitlab credentials
def gitlabCredential = 'jenkin_github'	

//docker hub credentials
def dockerhubCredential = "docker_hub_account"
def IMAGE_NAME = "hautt/obo-k8s"
def IMAGE_TAG = "${BUILD_NUMBER}"

def CICD_IP = "10.33.10.20"

pipeline {
	agent any
			
    stages {
        stage("Checkout SCM") {
            steps {
                script {
                    checkout scmGit(branches: [[name: '*/' + gitBranch]], extensions: [], userRemoteConfigs: [[credentialsId: gitlabCredential, url: gitRepository]])
                }
            }
        }

		stage('Build Docker Image') {
			steps {
				script {
                    app = docker.build("${IMAGE_NAME}:${IMAGE_TAG}")
				}
			}
		}

        stage('Push Docker Image') {
            steps {
                script {
                    docker.withRegistry('https://registry.hub.docker.com', dockerhubCredential) {
                        app.push()
                    }
                }
            }
        }

        stage('Deploy K8s') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'hautt_cicd', usernameVariable: 'USERNAME', passwordVariable: 'USERPASS')]) {
                    script {
						sh "sshpass -p '$USERPASS' ssh -o 'StrictHostKeyChecking=no' $USERNAME@$CICD_IP \" docker cp /home/hautt/.kube/config jenkins-server:/tmp/kubernetes_config\""
                        sh "kubectl apply -f app.yml --kubeconfig=//tmp/kubernetes_config"
					}
				}
            }
        }
    }
}	
