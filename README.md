# Event Management System - Kubernetes Deployment

A cloud-native Event Management System Fullstack Application deployed on Kubernetes using Helm and Ingress. This application helps organize and participate in events, handles event planning, ticket booking, and e-notifications.

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
│   ├── src/                     # Spring Boot source code
│   ├── pom.xml                  # Maven configuration
│   └── Dockerfile               # Backend Dockerfile
├── frontend/
│   ├── src/                     # React/Vite source code
│   ├── package.json             # NPM configuration
│   ├── nginx.conf               # Nginx configuration
│   └── Dockerfile               # Frontend Dockerfile
├── helm-chart/
│   ├── Chart.yaml               # Helm chart metadata
│   ├── values.yaml              # Configuration values
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
- **Backend API**: http://eventmanagement.local/back2

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
| `mysql.database` | Database name | `event` |
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

## Application Details

### Backend Configuration

The backend is a Spring Boot application that:
- Runs on port 8080 inside the container
- Uses Tomcat as the application server
- Connects to MySQL database on port 3306
- Deployed as WAR file at `/back2` context path
- Uses Java 17 runtime

### Frontend Configuration

The frontend is a React/Vite application that:
- Runs on port 80 inside the container
- Uses Nginx as the web server
- Proxies backend requests to `/back2` path
- Built using Node.js 18
- Serves static files from Nginx

### Database Configuration

MySQL database:
- Uses persistent volume for data storage
- Automatically creates `event` database on startup
- Root password: `root` (configurable in values.yaml)
- Includes readiness probe to ensure database is ready before backend starts

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

Check if init containers are waiting:
```bash
kubectl describe pod <backend-pod-name>
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

### Frontend Not Connecting to Backend

Check if backend service is accessible:
```bash
kubectl get svc backend
kubectl port-forward svc/backend 8080:8080
```

Check nginx configuration in frontend pod:
```bash
kubectl exec -it <frontend-pod> -- cat /etc/nginx/conf.d/nginx.conf
```

## Development

### Local Development

Backend:
```bash
cd backend
./mvnw spring-boot:run
```

Frontend:
```bash
cd frontend
npm install
npm run dev
```

### Building Images Locally

```bash
# Build backend
docker build -t event-management-backend:v1 ./backend

# Build frontend
docker build -t event-management-frontend:v1 ./frontend
```

## References

- Event Management System Source: https://github.com/suneethabulla/Event-Management-System
- Helm Chart Template Reference: https://github.com/srithars/Helm-Chart-Template

## License

This project is for educational purposes as part of HCL Technologies cloud-native modernization program.
