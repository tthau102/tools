pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                archiveArtifacts artifacts: '*'
            }
        }
        stage('Build Docker-image') {
            steps {
                script {
                    app = docker.build("hautt/web-app")
                }
            }
        }
        stage('Push Docker Image') {
            steps {
                script {
                    docker.withRegistry('https://registry.hub.docker.com', 'jenkins_dockerhub_tth_login') {
                        app.push("${env.BUILD_NUMBER}")
                        app.push("latest")
                    }
                }
            }
        }
        stage('Deploy Docker to Development') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'tth_webserver_login', usernameVariable: 'USERNAME', passwordVariable: 'USERPASS')]) {
                    script {
                        sh "sshpass -p '$USERPASS' ssh -o 'StrictHostKeyChecking=no' $USERNAME@$dev_ip \" docker pull hautt/web-app:${env.BUILD_NUMBER}\""
                        try {
                            sh "sshpass -p '$USERPASS' ssh -o 'StrictHostKeyChecking=no' $USERNAME@$dev_ip \" docker stop web-app\""
                            sh "sshpass -p '$USERPASS' ssh -o 'StrictHostKeyChecking=no' $USERNAME@$dev_ip \" docker rm web-app\""
                        } catch (error) {
                            echo 'catch error: $err'
                        }
                        sh "sshpass -p '$USERPASS' ssh -o 'StrictHostKeyChecking=no' $USERNAME@$dev_ip \" docker run --restart always --name web-app -p 8080:80 -d hautt/web-app:${env.BUILD_NUMBER}\""
                    }
                }
            }
        }
        stage('Deploy Docker to Production') {
            steps {
                input 'Do you want to deploy to production ?'
                milestone(1)
                withCredentials([usernamePassword(credentialsId: 'tth_webserver_login', usernameVariable: 'USERNAME', passwordVariable: 'USERPASS')]) {
                    script {
                        sh "sshpass -p '$USERPASS' ssh -o 'StrictHostKeyChecking=no' $USERNAME@$prod_ip \" docker pull hautt/web-app:${env.BUILD_NUMBER}\""
                        try {
                            sh "sshpass -p '$USERPASS' ssh -o 'StrictHostKeyChecking=no' $USERNAME@$prod_ip \" docker stop web-app\""
                            sh "sshpass -p '$USERPASS' ssh -o 'StrictHostKeyChecking=no' $USERNAME@$prod_ip \" docker rm web-app\""
                        } catch (error) {
                            echo 'catch error: $err'
                        }
                        sh "sshpass -p '$USERPASS' ssh -o 'StrictHostKeyChecking=no' $USERNAME@$prod_ip \" docker run --restart always --name web-app -p 8080:80 -d hautt/web-app:${env.BUILD_NUMBER}\""
                    }
                }
            }
        }
    }
}
