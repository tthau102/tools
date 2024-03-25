// git repository info
def gitRepository = 'http://gitlab.prod.viettq.com/viettq/nodejs-demo-k8s.git'
def gitBranch = 'master'

// gitlab credentials
def gitlabCredential = 'jenkin_github'	

pipeline {
	agent any
			
    stages {
        stage("Checkout SCM") {
            steps {
                script {
                    checkout scmGit(branches: [[name: '*/master']], extensions: [], userRemoteConfigs: [[credentialsId: gitlabCredential, url: 'https://github.com/trantrunghau0102/Obo-SpringBoot-Java.git']])
                }
            }
        }
	}
}	
