	// git repository info
	def gitRepository = 'http://gitlab.prod.viettq.com/viettq/nodejs-demo-k8s.git'
	def gitBranch = 'master'

	// gitlab credentials
	def gitlabCredential = 'jenkin_gitlab'	

	pipeline {
		agent any
				
		stages {		
			stage('Checkout project') 
			{
			  steps 
			  {
				echo "checkout project"
				git branch: gitBranch,
				   url: gitRepository
				sh "git reset --hard"				
			  }
			}
		}
	}
