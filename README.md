# Event Management System - Kubernetes Deployment

[![CI/CD Pipeline](https://github.com/sachinyaganti/S218_InSem2_2300032331/actions/workflows/ci-cd.yml/badge.svg)](https://github.com/sachinyaganti/S218_InSem2_2300032331/actions/workflows/ci-cd.yml)
[![Release](https://github.com/sachinyaganti/S218_InSem2_2300032331/actions/workflows/release.yml/badge.svg)](https://github.com/sachinyaganti/S218_InSem2_2300032331/actions/workflows/release.yml)
[![Deploy](https://github.com/sachinyaganti/S218_InSem2_2300032331/actions/workflows/deploy.yml/badge.svg)](https://github.com/sachinyaganti/S218_InSem2_2300032331/actions/workflows/deploy.yml)

A cloud-native Event Management System Fullstack Application deployed on Kubernetes using Helm and Ingress. This application helps organize and participate in events, handles event planning, ticket booking, and e-notifications.

📊 **[View Pipeline Dashboard](https://sachinyaganti.github.io/S218_InSem2_2300032331/)** - Track builds and deployments on GitHub Pages

## Architecture

The application consists of three main components:

1. **Frontend**: React/Vite application served via Nginx
2. **Backend**: Spring Boot application running on Tomcat
3. **Database**: MySQL 8.0 for data persistence

## Prerequisites

- Kubernetes cluster (v1.19+)
- Helm 3.x
- kubectl configured to connect to your cluster
- Docker (for building custom images)
- NGINX Ingress Controller installed in the cluster

## Project Structure

```
.
├── backend/
│   └── Dockerfile              # Backend Dockerfile
├── frontend/
│   ├── Dockerfile              # Frontend Dockerfile
│   └── nginx.conf              # Nginx configuration
├── helm-chart/
│   ├── Chart.yaml              # Helm chart metadata
│   ├── values.yaml             # Configuration values
│   └── templates/
│       ├── backend-deployment.yaml
│       ├── frontend-deployment.yaml
│       ├── mysql-deployment.yaml
│       ├── services.yaml
│       ├── ingress.yaml
│       ├── pvc.yaml
│       └── hpa.yaml
└── README.md
```

## Features

### Scalability
- **Horizontal Pod Autoscaling (HPA)**: Automatically scales frontend and backend based on CPU utilization
  - Backend: 2-5 replicas (scales at 60% CPU)
  - Frontend: 2-5 replicas (scales at 60% CPU)

### High Availability
- Multiple replicas for frontend and backend services
- MySQL with persistent storage for data durability
- Health checks and readiness probes

### Automation
- Helm-based deployment for easy management
- Init containers to ensure proper service startup order
- Automated database initialization

## Quick Start

### Step 1: Build Docker Images

You can either build the images locally or use pre-built images.

#### Build Locally:

```bash
# Build backend image
cd backend
docker build -t event-management-backend:v1 .

# Build frontend image
cd ../frontend
docker build -t event-management-frontend:v1 .
```

#### Push to Registry (Optional):

```bash
# Tag and push to your registry
docker tag event-management-backend:v1 <your-registry>/event-management-backend:v1
docker tag event-management-frontend:v1 <your-registry>/event-management-frontend:v1

docker push <your-registry>/event-management-backend:v1
docker push <your-registry>/event-management-frontend:v1
```

### Step 2: Install NGINX Ingress Controller

If not already installed:

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml
```

### Step 3: Configure values.yaml

Edit `helm-chart/values.yaml` to update the Docker image references:

```yaml
backend:
  image: <your-registry>/event-management-backend:v1
  
frontend:
  image: <your-registry>/event-management-frontend:v1
```

### Step 4: Deploy with Helm

```bash
# Install the application
helm install event-management ./helm-chart

# Or upgrade if already installed
helm upgrade event-management ./helm-chart
```

### Step 5: Configure DNS/Hosts

Add the following entry to your `/etc/hosts` file (or configure DNS):

```
<ingress-controller-ip> eventmanagement.local
```

To get the Ingress Controller IP:

```bash
kubectl get svc -n ingress-nginx
```

### Step 6: Access the Application

Open your browser and navigate to:
- **Frontend**: http://eventmanagement.local
- **Backend API**: http://eventmanagement.local/api

Or access via NodePort:
- **Frontend**: http://<node-ip>:30081
- **Backend**: http://<node-ip>:30080

## Configuration

### values.yaml Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `mysql.image` | MySQL Docker image | `mysql:8.0` |
| `mysql.storage` | Persistent storage size | `5Gi` |
| `mysql.rootPassword` | MySQL root password | `root` |
| `mysql.database` | Database name | `eventmanagement` |
| `backend.image` | Backend Docker image | `event-management-backend:v1` |
| `backend.replicas` | Number of backend replicas | `2` |
| `backend.port` | Backend service port | `8080` |
| `backend.nodePort` | Backend NodePort | `30080` |
| `frontend.image` | Frontend Docker image | `event-management-frontend:v1` |
| `frontend.replicas` | Number of frontend replicas | `2` |
| `frontend.port` | Frontend service port | `80` |
| `frontend.nodePort` | Frontend NodePort | `30081` |
| `ingress.enabled` | Enable Ingress | `true` |
| `ingress.host` | Ingress hostname | `eventmanagement.local` |
| `autoscaling.*.enabled` | Enable HPA | `true` |
| `autoscaling.*.minReplicas` | Minimum replicas | `2` |
| `autoscaling.*.maxReplicas` | Maximum replicas | `5` |
| `autoscaling.*.targetCPUUtilizationPercentage` | CPU threshold | `60` |

## Useful Commands

### Check Deployment Status

```bash
# Check all resources
kubectl get all

# Check pods
kubectl get pods

# Check services
kubectl get svc

# Check ingress
kubectl get ingress

# Check HPA status
kubectl get hpa
```

### View Logs

```bash
# Backend logs
kubectl logs -l app=backend -f

# Frontend logs
kubectl logs -l app=frontend -f

# MySQL logs
kubectl logs -l app=mysql -f
```

### Scale Manually

```bash
# Scale backend
kubectl scale deployment backend --replicas=3

# Scale frontend
kubectl scale deployment frontend --replicas=3
```

### Uninstall

```bash
helm uninstall event-management
```

## Troubleshooting

### Pods Not Starting

Check pod status and logs:
```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

### Database Connection Issues

Verify MySQL is ready:
```bash
kubectl get pods -l app=mysql
kubectl logs -l app=mysql
```

### Ingress Not Working

Check Ingress Controller:
```bash
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx
```

Verify Ingress configuration:
```bash
kubectl describe ingress event-management-ingress
```

## CI/CD Pipeline

This project includes a comprehensive GitHub Actions CI/CD pipeline for automated builds and deployments.

### 🔄 Automated Workflows

#### 1. CI/CD Pipeline (`ci-cd.yml`)
Triggers on every push and pull request to main/develop branches:
- **Backend Build**: Compiles Java/Spring Boot application with Maven
- **Frontend Build**: Builds React/Vite application with npm
- **Docker Images**: Builds and pushes container images to GitHub Container Registry
- **Helm Lint**: Validates Kubernetes deployment configurations
- **GitHub Pages**: Deploys pipeline dashboard for tracking builds

#### 2. Deployment Workflow (`deploy.yml`)
Manual deployment workflow for staging/production:
- Supports environment-specific deployments
- Configurable image tags
- Automated health checks and verification
- Deployment summary in workflow output

#### 3. Release Workflow (`release.yml`)
Automated release creation on version tags:
- Builds and tags Docker images with version numbers
- Packages Helm charts
- Creates GitHub releases with release notes
- Publishes artifacts

### 📊 Pipeline Dashboard

Visit the **[CI/CD Dashboard](https://sachinyaganti.github.io/S218_InSem2_2300032331/)** to view:
- Real-time build status
- Deployment information
- Container registry links
- Project documentation

### 🚀 Triggering Workflows

**Automatic Triggers:**
```bash
# Push to main/develop triggers CI/CD pipeline
git push origin main

# Creating a tag triggers release workflow
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0
```

**Manual Triggers:**
- Navigate to **Actions** tab in GitHub
- Select the workflow (Deploy to Kubernetes or Release)
- Click "Run workflow"
- Select environment/options and confirm

### 🐳 Container Images

Images are automatically published to GitHub Container Registry:
- Backend: `ghcr.io/sachinyaganti/event-management-backend`
- Frontend: `ghcr.io/sachinyaganti/event-management-frontend`

Tags: `latest`, `<commit-sha>`, `<version>`

### 🛠️ Development Workflow

1. Create a feature branch
2. Make changes and commit
3. Push to GitHub - CI pipeline runs automatically
4. Create Pull Request - CI validates changes
5. Merge to main - Images are built and published
6. Tag for release - Release workflow creates artifacts

## References

- Event Management System Source: https://github.com/suneethabulla/Event-Management-System
- Helm Chart Template Reference: https://github.com/srithars/Helm-Chart-Template

## License

This project is for educational purposes as part of HCL Technologies cloud-native modernization program.
