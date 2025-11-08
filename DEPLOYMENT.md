# Deployment Guide - Event Management System

This guide provides detailed instructions for deploying the Event Management System on Kubernetes.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Environment Setup](#environment-setup)
3. [Building Docker Images](#building-docker-images)
4. [Deploying to Kubernetes](#deploying-to-kubernetes)
5. [Verification](#verification)
6. [Accessing the Application](#accessing-the-application)
7. [Monitoring and Maintenance](#monitoring-and-maintenance)
8. [Troubleshooting](#troubleshooting)
9. [Rollback Procedures](#rollback-procedures)
10. [Production Considerations](#production-considerations)

## Prerequisites

### Required Software

- **Kubernetes Cluster** (v1.19 or later)
  - Minikube (for local testing)
  - Kind (for local testing)
  - Cloud Provider (AWS EKS, GCP GKE, Azure AKS)
  
- **kubectl** (v1.19 or later)
  ```bash
  # Check version
  kubectl version --client
  ```

- **Helm** (v3.x)
  ```bash
  # Check version
  helm version
  ```

- **Docker** (v20.x or later)
  ```bash
  # Check version
  docker version
  ```

### Resource Requirements

**Minimum Cluster Resources:**
- CPU: 4 cores
- Memory: 8 GB RAM
- Storage: 20 GB
- Nodes: 2 (for high availability)

**Per Application Component:**
- Frontend Pod: 100m CPU, 128Mi Memory
- Backend Pod: 500m CPU, 512Mi Memory
- MySQL Pod: 250m CPU, 512Mi Memory
- PVC: 5Gi storage

## Environment Setup

### 1. Configure kubectl

Ensure kubectl is configured to access your cluster:

```bash
# View current context
kubectl config current-context

# View cluster info
kubectl cluster-info

# Check node status
kubectl get nodes
```

### 2. Install NGINX Ingress Controller

If not already installed:

```bash
# Install NGINX Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml

# Wait for the controller to be ready
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

# Verify installation
kubectl get pods -n ingress-nginx
```

### 3. Create Namespace (Optional)

```bash
# Create namespace
kubectl create namespace event-management

# Set as default namespace
kubectl config set-context --current --namespace=event-management
```

## Building Docker Images

### Option 1: Using Automated Script

```bash
# Build and deploy using the script
./deploy.sh --skip-push

# Or with custom registry
./deploy.sh --registry docker.io/yourusername
```

### Option 2: Manual Build

#### Build Backend Image

```bash
cd backend

# Build the image
docker build -t event-management-backend:v1 .

# Verify the build
docker images | grep event-management-backend
```

#### Build Frontend Image

```bash
cd frontend

# Build the image
docker build -t event-management-frontend:v1 .

# Verify the build
docker images | grep event-management-frontend
```

### Push to Registry (If Using Remote Cluster)

```bash
# Tag images
docker tag event-management-backend:v1 docker.io/yourusername/event-management-backend:v1
docker tag event-management-frontend:v1 docker.io/yourusername/event-management-frontend:v1

# Login to registry
docker login

# Push images
docker push docker.io/yourusername/event-management-backend:v1
docker push docker.io/yourusername/event-management-frontend:v1
```

### For Minikube

If using Minikube, you can use local images:

```bash
# Use Minikube's Docker daemon
eval $(minikube docker-env)

# Build images
docker build -t event-management-backend:v1 ./backend
docker build -t event-management-frontend:v1 ./frontend

# Verify images are in Minikube
minikube ssh docker images | grep event-management
```

## Deploying to Kubernetes

### 1. Configure Helm Values

Edit `helm-chart/values.yaml`:

```yaml
mysql:
  image: mysql:8.0
  storage: 5Gi
  rootPassword: root  # Change in production
  database: event

backend:
  image: event-management-backend:v1  # or your registry URL
  replicas: 2
  port: 8080
  nodePort: 30080

frontend:
  image: event-management-frontend:v1  # or your registry URL
  replicas: 2
  port: 80
  nodePort: 30081

ingress:
  enabled: true
  host: eventmanagement.local  # Change to your domain
```

### 2. Install with Helm

```bash
# Install the application
helm install event-management ./helm-chart

# Or install in specific namespace
helm install event-management ./helm-chart --namespace event-management --create-namespace
```

### 3. Verify Deployment

```bash
# Check all resources
kubectl get all

# Expected output:
# - 3 deployments (mysql, backend, frontend)
# - 3 services (mysql, backend, frontend)
# - Multiple pods (2+ backend, 2+ frontend, 1 mysql)
# - 2 HPAs (backend-hpa, frontend-hpa)
# - 1 ingress (event-management-ingress)
```

## Verification

### 1. Check Pods

```bash
# List all pods
kubectl get pods

# Check pod details
kubectl describe pod <pod-name>

# View pod logs
kubectl logs <pod-name>

# Follow logs
kubectl logs -f <pod-name>
```

Expected pod status: All pods should be in "Running" state.

### 2. Check Services

```bash
# List services
kubectl get svc

# Check service endpoints
kubectl get endpoints
```

### 3. Check Ingress

```bash
# List ingress
kubectl get ingress

# Describe ingress
kubectl describe ingress event-management-ingress
```

### 4. Check HPA

```bash
# List HPAs
kubectl get hpa

# Watch HPA in real-time
kubectl get hpa --watch
```

### 5. Check PVC

```bash
# List PVCs
kubectl get pvc

# Check PVC details
kubectl describe pvc mysql-pvc
```

## Accessing the Application

### Method 1: Using Ingress (Recommended)

1. **Get Ingress IP:**

```bash
# For cloud providers
kubectl get ingress event-management-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

# For on-premise or bare metal
kubectl get nodes -o wide
```

2. **Configure DNS or /etc/hosts:**

Add entry to `/etc/hosts`:

```bash
# Linux/Mac
sudo nano /etc/hosts

# Windows
notepad C:\Windows\System32\drivers\etc\hosts

# Add this line
<INGRESS-IP> eventmanagement.local
```

3. **Access Application:**

- Frontend: http://eventmanagement.local
- Backend API: http://eventmanagement.local/back2

### Method 2: Using NodePort

1. **Get Node IP:**

```bash
kubectl get nodes -o wide
```

2. **Access Application:**

- Frontend: http://<NODE-IP>:30081
- Backend: http://<NODE-IP>:30080

### Method 3: Using Port Forwarding (Development)

```bash
# Forward frontend port
kubectl port-forward svc/frontend 8081:80

# In another terminal, forward backend port
kubectl port-forward svc/backend 8080:8080

# Access at:
# Frontend: http://localhost:8081
# Backend: http://localhost:8080
```

### For Minikube

```bash
# Get Minikube IP
minikube ip

# Enable tunnel for LoadBalancer
minikube tunnel

# Access via service
minikube service frontend
```

## Monitoring and Maintenance

### View Logs

```bash
# Backend logs
kubectl logs -l app=backend -f

# Frontend logs
kubectl logs -l app=frontend -f

# MySQL logs
kubectl logs -l app=mysql -f

# All backend pod logs
kubectl logs -l app=backend --all-containers=true

# Logs from previous container (if pod restarted)
kubectl logs <pod-name> --previous
```

### Monitor Resources

```bash
# Pod resource usage
kubectl top pods

# Node resource usage
kubectl top nodes

# Watch pod status
kubectl get pods --watch

# HPA status
kubectl get hpa --watch
```

### Update Application

```bash
# Update Helm values
nano helm-chart/values.yaml

# Upgrade deployment
helm upgrade event-management ./helm-chart

# Check rollout status
kubectl rollout status deployment/backend
kubectl rollout status deployment/frontend
```

### Scale Manually

```bash
# Scale backend
kubectl scale deployment backend --replicas=5

# Scale frontend
kubectl scale deployment frontend --replicas=5

# Verify
kubectl get pods
```

## Troubleshooting

### Pods Not Starting

```bash
# Check pod events
kubectl describe pod <pod-name>

# Check pod logs
kubectl logs <pod-name>

# Check if image exists
kubectl get pods <pod-name> -o jsonpath='{.spec.containers[*].image}'
```

Common issues:
- Image pull errors: Check image name and registry access
- Resource constraints: Check node capacity
- Configuration errors: Check environment variables

### Backend Can't Connect to Database

```bash
# Check MySQL pod
kubectl get pods -l app=mysql
kubectl logs -l app=mysql

# Check if MySQL service is accessible
kubectl get svc mysql
kubectl get endpoints mysql

# Test connectivity from backend pod
kubectl exec -it <backend-pod> -- nc -zv mysql 3306

# Check MySQL readiness
kubectl exec -it <mysql-pod> -- mysqladmin ping -h localhost
```

### Frontend Can't Reach Backend

```bash
# Check nginx configuration
kubectl exec -it <frontend-pod> -- cat /etc/nginx/conf.d/nginx.conf

# Check backend service
kubectl get svc backend

# Test from frontend pod
kubectl exec -it <frontend-pod> -- wget -O- http://backend:8080
```

### Ingress Not Working

```bash
# Check Ingress Controller
kubectl get pods -n ingress-nginx
kubectl logs -n ingress-nginx <ingress-controller-pod>

# Check Ingress resource
kubectl describe ingress event-management-ingress

# Check if Ingress has an address
kubectl get ingress
```

### HPA Not Scaling

```bash
# Check Metrics Server
kubectl get deployment metrics-server -n kube-system

# If not installed, install it
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Check HPA status
kubectl describe hpa backend-hpa
kubectl describe hpa frontend-hpa

# Generate load to test
kubectl run -it --rm load-generator --image=busybox -- /bin/sh
# Inside pod: while true; do wget -q -O- http://backend:8080; done
```

## Rollback Procedures

### Helm Rollback

```bash
# List releases
helm list

# View release history
helm history event-management

# Rollback to previous version
helm rollback event-management

# Rollback to specific revision
helm rollback event-management <revision-number>
```

### Kubernetes Rollback

```bash
# View rollout history
kubectl rollout history deployment/backend

# Rollback to previous version
kubectl rollout undo deployment/backend

# Rollback to specific revision
kubectl rollout undo deployment/backend --to-revision=2

# Check rollout status
kubectl rollout status deployment/backend
```

## Production Considerations

### 1. Security Hardening

- **Use Kubernetes Secrets** for sensitive data:
  ```bash
  kubectl create secret generic mysql-secret \
    --from-literal=root-password=<strong-password>
  ```

- **Enable TLS** for Ingress:
  ```yaml
  spec:
    tls:
    - hosts:
      - eventmanagement.example.com
      secretName: tls-secret
  ```

- **Network Policies**: Restrict pod-to-pod communication
- **RBAC**: Implement role-based access control
- **Pod Security Policies**: Enforce security standards

### 2. Resource Limits

Add resource requests and limits:

```yaml
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi
```

### 3. Database Backup

```bash
# Backup MySQL data
kubectl exec <mysql-pod> -- mysqldump -u root -proot event > backup.sql

# Restore
kubectl exec -i <mysql-pod> -- mysql -u root -proot event < backup.sql
```

### 4. Monitoring Stack

Install Prometheus and Grafana:

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack
```

### 5. Logging Stack

Install ELK or EFK stack for centralized logging.

### 6. High Availability

- Use 3+ node cluster
- Enable pod anti-affinity
- Deploy across multiple availability zones
- Use external MySQL cluster (RDS, Cloud SQL)

### 7. CI/CD Integration

Integrate with:
- Jenkins
- GitLab CI/CD
- GitHub Actions
- ArgoCD for GitOps

### 8. Domain Configuration

Replace `eventmanagement.local` with actual domain:
- Configure DNS A record
- Obtain SSL/TLS certificate
- Update Ingress configuration

## Uninstall

```bash
# Uninstall Helm release
helm uninstall event-management

# Delete namespace (if created)
kubectl delete namespace event-management

# Remove PVC (if needed)
kubectl delete pvc mysql-pvc
```

## Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Helm Documentation](https://helm.sh/docs/)
- [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/)
- [Spring Boot Documentation](https://spring.io/projects/spring-boot)
- [React Documentation](https://react.dev/)

## Support

For issues and questions:
1. Check the logs: `kubectl logs <pod-name>`
2. Review troubleshooting section above
3. Check Kubernetes events: `kubectl get events`
4. Review ARCHITECTURE.md for system design
