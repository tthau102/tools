# SpringBoot-MySQL-K8s Pipeline

A complete CI/CD pipeline for Spring Boot applications with MySQL, automating the build, test, and deployment process using Docker, Kubernetes, and Jenkins.

![CI/CD Pipeline](https://img.shields.io/badge/CI%2FCD-Jenkins-blue)
![Kubernetes](https://img.shields.io/badge/Deployment-Kubernetes-blue)
![Spring Boot](https://img.shields.io/badge/Framework-Spring%20Boot-green)

## Overview

This project demonstrates a modern CI/CD workflow for a Spring Boot web application with:

- Automated builds triggered by code changes in GitHub
- Docker containerization
- Kubernetes deployment orchestration
- Helm charts for Kubernetes configuration management
- Jenkins pipeline automation

## Architecture

```
GitHub → Jenkins → Docker Hub → Kubernetes Cluster
```

- **Application**: Java-based Spring Boot web app
- **Database**: MySQL
- **Containerization**: Docker
- **Orchestration**: Kubernetes
- **CI/CD**: Jenkins
- **Package Management**: Helm

## Quick Start

### Local Development

```bash
# Clone the repository
git clone https://github.com/trantrunghau0102/SpringBoot-Pipeline.git
cd SpringBoot-Pipeline

# Build the application
./mvnw clean package

# Run locally
./mvnw spring-boot:run
```

### Docker Deployment

```bash
# Build the image
docker build -t hautt/obo-app:latest .

# Run container
docker run -p 8080:8080 -e DB_HOST=your-db-host hautt/obo-app:latest
```

### Kubernetes Deployment

```bash
# Deploy with Helm
helm upgrade --install obo-app ./helm-chart --set image.tag=latest

# Or use kubectl directly
kubectl apply -f kubernetes/app.yml
```

## CI/CD Pipeline

The Jenkins pipeline automatically:

1. Builds the Java application when code is pushed to GitHub
2. Creates and pushes Docker images to Docker Hub
3. Updates Kubernetes deployments with the new image

```
Build → Test → Dockerize → Push → Deploy
```

## Project Structure

```
.
├── Dockerfile             # Docker image definition
├── Jenkinsfile            # CI/CD pipeline definition
├── helm-chart/            # Kubernetes Helm chart
├── kubernetes/            # K8s manifests
├── pom.xml                # Maven configuration
└── src/                   # Java source code
```

## Configuration

Environment variables:
- `DB_HOST`: MySQL database hostname
- `DB_USERNAME`: Database username
- `DB_PASSWORD`: Database password

## Contributing

1. Fork the repository
2. Create your feature branch: `git checkout -b feature/my-feature`
3. Commit your changes: `git commit -am 'Add my feature'`
4. Push to the branch: `git push origin feature/my-feature`
5. Submit a pull request

## Contact

Tran Trung Hau - [trunghautran0102@gmail.com](mailto:trunghautran0102@gmail.com)

Project Link: [https://github.com/trantrunghau0102/SpringBoot-Pipeline](https://github.com/trantrunghau0102/SpringBoot-Pipeline)
