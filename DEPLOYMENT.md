# Deployment Guide

This guide provides detailed step-by-step instructions for deploying the Event Management System on a Kubernetes cluster.

## Environment Setup

### 1. Kubernetes Cluster Setup

You can use any of the following Kubernetes environments:

#### Option A: Minikube (Local Development)
```bash
# Install Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Start Minikube
minikube start --cpus=4 --memory=8192

# Enable required addons
minikube addons enable ingress
minikube addons enable metrics-server
```

#### Option B: Kind (Kubernetes in Docker)
```bash
# Install Kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# Create cluster
kind create cluster --config=- <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
EOF
```

#### Option C: Cloud Provider (AWS EKS, GCP GKE, Azure AKS)
Follow your cloud provider's documentation for Kubernetes cluster setup.

### 2. Install Required Tools

```bash
# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Verify installations
kubectl version --client
helm version
```

## Building Docker Images

### 1. Build Backend Image

```bash
cd backend

# Build the image
docker build -t event-management-backend:v1 .

# Test the image locally (optional)
docker run -p 8080:8080 event-management-backend:v1
```

### 2. Build Frontend Image

```bash
cd frontend

# Build the image
docker build -t event-management-frontend:v1 .

# Test the image locally (optional)
docker run -p 80:80 event-management-frontend:v1
```

### 3. Push Images to Registry

If using a remote Kubernetes cluster:

```bash
# Login to your registry
docker login <your-registry>

# Tag images
docker tag event-management-backend:v1 <your-registry>/event-management-backend:v1
docker tag event-management-frontend:v1 <your-registry>/event-management-frontend:v1

# Push images
docker push <your-registry>/event-management-backend:v1
docker push <your-registry>/event-management-frontend:v1
```

For Minikube, load images directly:
```bash
minikube image load event-management-backend:v1
minikube image load event-management-frontend:v1
```

For Kind, load images directly:
```bash
kind load docker-image event-management-backend:v1
kind load docker-image event-management-frontend:v1
```

## Installing NGINX Ingress Controller

### For Standard Kubernetes Cluster
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml
```

### For Minikube
```bash
minikube addons enable ingress
```

### For Kind
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/kind/deploy.yaml
```

### Verify Installation
```bash
kubectl get pods -n ingress-nginx
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s
```

## Deploying the Application

### 1. Update Configuration

Edit `helm-chart/values.yaml`:

```yaml
backend:
  image: event-management-backend:v1  # or <your-registry>/event-management-backend:v1
  
frontend:
  image: event-management-frontend:v1  # or <your-registry>/event-management-frontend:v1
```

### 2. Install with Helm

```bash
# Create namespace (optional)
kubectl create namespace event-management

# Install the Helm chart
helm install event-management ./helm-chart --namespace event-management

# Or install in default namespace
helm install event-management ./helm-chart
```

### 3. Monitor Deployment

```bash
# Watch pod creation
kubectl get pods -w

# Check deployment status
kubectl rollout status deployment/backend
kubectl rollout status deployment/frontend
kubectl rollout status deployment/mysql

# Verify all services
kubectl get svc
kubectl get ingress
```

## Accessing the Application

### Method 1: Via Ingress (Recommended)

#### For Minikube:
```bash
# Get Minikube IP
minikube ip

# Add to /etc/hosts
echo "$(minikube ip) eventmanagement.local" | sudo tee -a /etc/hosts

# Access application
open http://eventmanagement.local
```

#### For Kind or Other Clusters:
```bash
# Get Ingress Controller IP
kubectl get svc -n ingress-nginx

# Add to /etc/hosts
echo "<ingress-ip> eventmanagement.local" | sudo tee -a /etc/hosts

# Access application
open http://eventmanagement.local
```

### Method 2: Via NodePort

```bash
# Get node IP
kubectl get nodes -o wide

# Access services
# Frontend: http://<node-ip>:30081
# Backend: http://<node-ip>:30080

# For Minikube
minikube service frontend --url
minikube service backend --url
```

### Method 3: Via Port Forwarding (Development)

```bash
# Forward frontend port
kubectl port-forward svc/frontend 8081:80

# Forward backend port (in another terminal)
kubectl port-forward svc/backend 8080:8080

# Access at:
# Frontend: http://localhost:8081
# Backend: http://localhost:8080
```

## Verification

### 1. Check All Resources

```bash
kubectl get all
```

Expected output should show:
- 1 MySQL pod (Running)
- 2+ Backend pods (Running)
- 2+ Frontend pods (Running)
- Services for all components
- Ingress resource
- HPA resources

### 2. Test Database Connection

```bash
# Connect to MySQL pod
kubectl exec -it deployment/mysql -- mysql -uroot -proot eventmanagement

# Run a test query
SHOW TABLES;
exit
```

### 3. Check HPA Status

```bash
kubectl get hpa

# Should show:
# - backend-hpa
# - frontend-hpa
```

### 4. Test Auto-scaling

Generate some load to test auto-scaling:
```bash
# Install hey (HTTP load generator)
go install github.com/rakyll/hey@latest

# Generate load on backend
hey -z 2m -c 50 http://eventmanagement.local/api

# Watch HPA scale
kubectl get hpa -w
```

## Troubleshooting

### Pods in Pending State

```bash
# Check events
kubectl get events --sort-by=.metadata.creationTimestamp

# Check PVC status
kubectl get pvc

# Describe pod
kubectl describe pod <pod-name>
```

### Image Pull Errors

```bash
# For Minikube/Kind, ensure images are loaded
minikube image ls | grep event-management
# or
docker exec -it kind-control-plane crictl images | grep event-management

# Check image pull policy
kubectl describe pod <pod-name> | grep -A5 "Image"
```

### Database Connection Issues

```bash
# Check MySQL logs
kubectl logs deployment/mysql

# Verify backend environment variables
kubectl describe deployment/backend | grep -A10 "Environment"

# Check if MySQL is ready
kubectl exec -it deployment/mysql -- mysqladmin ping -h localhost -uroot -proot
```

### Ingress Not Working

```bash
# Check Ingress Controller logs
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller

# Describe ingress
kubectl describe ingress event-management-ingress

# Verify DNS/hosts entry
ping eventmanagement.local
```

## Cleanup

```bash
# Uninstall Helm release
helm uninstall event-management

# Delete namespace (if used)
kubectl delete namespace event-management

# For Minikube
minikube delete

# For Kind
kind delete cluster
```

## CI/CD Automation

This project includes fully automated CI/CD pipelines using GitHub Actions. See [GITHUB_ACTIONS.md](GITHUB_ACTIONS.md) for complete details.

### Quick Start with GitHub Actions

**Automated Builds**: Every push to main/develop automatically:
- Builds backend and frontend applications
- Creates Docker images
- Pushes to GitHub Container Registry
- Updates deployment dashboard

**View Pipeline Status**: Visit the [Pipeline Dashboard](https://sachinyaganti.github.io/S218_InSem2_2300032331/)

**Manual Deployment**:
1. Go to **Actions** > **Deploy to Kubernetes**
2. Select environment and image tag
3. Click **Run workflow**

**Create Release**:
```bash
git tag -a v1.0.0 -m "Release 1.0.0"
git push origin v1.0.0
```

See [GITHUB_ACTIONS.md](GITHUB_ACTIONS.md) for detailed workflow documentation.

## Next Steps

- ✅ ~~Configure CI/CD pipelines~~ (Completed - see [GITHUB_ACTIONS.md](GITHUB_ACTIONS.md))
- Configure SSL/TLS for HTTPS
- Set up monitoring with Prometheus/Grafana
- Implement backup strategies for MySQL
- Set up logging with ELK/EFK stack
