// git repository info
def gitRepository = 'https://github.com/trantrunghau0102/Obo-SpringBoot-Java.git'
def gitBranch = 'master'

// gitlab credentials
def gitlabCredential = 'jenkin_github'	

//docker hub credentials
def dockerhubCredential = "docker_hub_account"
def IMAGE_NAME = 
def IMAGE_TAG = "${RELEASE}-${BUILD_NUMBER}"

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
	}

	stage('Build Docker-image') {
		steps {
			script {
				app = docker.build("hautt/obo-k8s")
			}
		}
	}
	stage('Push Docker Image') {
		steps {
			script {
				docker.withRegistry('https://registry.hub.docker.com', dockerhubCredential) {
					app.push("${env.BUILD_NUMBER}")
					app.push("latest")
				}
			}
		}
	}
}	
