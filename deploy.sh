#!/bin/bash

# Event Management System Deployment Script
# This script automates the deployment of the Event Management System on Kubernetes

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
NAMESPACE="default"
REGISTRY=""
SKIP_BUILD=false
SKIP_PUSH=false

# Function to print colored messages
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
    -n, --namespace NAMESPACE     Kubernetes namespace (default: default)
    -r, --registry REGISTRY       Docker registry URL (e.g., docker.io/username)
    -s, --skip-build              Skip building Docker images
    -p, --skip-push               Skip pushing images to registry
    -h, --help                    Show this help message

Examples:
    # Deploy locally without pushing to registry
    $0 --skip-push

    # Deploy with custom registry
    $0 --registry docker.io/myusername

    # Deploy to custom namespace
    $0 --namespace production --registry docker.io/myusername

EOF
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        -r|--registry)
            REGISTRY="$2"
            shift 2
            ;;
        -s|--skip-build)
            SKIP_BUILD=true
            shift
            ;;
        -p|--skip-push)
            SKIP_PUSH=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            print_error "Unknown option: $1"
            usage
            ;;
    esac
done

# Set image names
if [ -n "$REGISTRY" ]; then
    BACKEND_IMAGE="${REGISTRY}/event-management-backend:v1"
    FRONTEND_IMAGE="${REGISTRY}/event-management-frontend:v1"
else
    BACKEND_IMAGE="event-management-backend:v1"
    FRONTEND_IMAGE="event-management-frontend:v1"
fi

print_info "Starting Event Management System deployment..."
print_info "Namespace: $NAMESPACE"
print_info "Backend Image: $BACKEND_IMAGE"
print_info "Frontend Image: $FRONTEND_IMAGE"

# Check prerequisites
print_info "Checking prerequisites..."

if ! command -v kubectl &> /dev/null; then
    print_error "kubectl not found. Please install kubectl first."
    exit 1
fi

if ! command -v helm &> /dev/null; then
    print_error "helm not found. Please install helm first."
    exit 1
fi

if ! command -v docker &> /dev/null && [ "$SKIP_BUILD" = false ]; then
    print_error "docker not found. Please install docker or use --skip-build flag."
    exit 1
fi

# Check if kubectl can connect to cluster
if ! kubectl cluster-info &> /dev/null; then
    print_error "Cannot connect to Kubernetes cluster. Please configure kubectl."
    exit 1
fi

print_info "All prerequisites satisfied."

# Build Docker images
if [ "$SKIP_BUILD" = false ]; then
    print_info "Building Docker images..."
    
    print_info "Building backend image..."
    docker build -t "$BACKEND_IMAGE" ./backend
    
    print_info "Building frontend image..."
    docker build -t "$FRONTEND_IMAGE" ./frontend
    
    print_info "Docker images built successfully."
else
    print_warn "Skipping Docker image build."
fi

# Push images to registry
if [ "$SKIP_PUSH" = false ] && [ -n "$REGISTRY" ]; then
    print_info "Pushing images to registry..."
    
    docker push "$BACKEND_IMAGE"
    docker push "$FRONTEND_IMAGE"
    
    print_info "Images pushed successfully."
elif [ "$SKIP_PUSH" = false ] && [ -z "$REGISTRY" ]; then
    print_warn "No registry specified. Skipping push. Images will be used from local Docker."
else
    print_warn "Skipping image push to registry."
fi

# Create namespace if it doesn't exist
if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
    print_info "Creating namespace: $NAMESPACE"
    kubectl create namespace "$NAMESPACE"
fi

# Check if NGINX Ingress Controller is installed
print_info "Checking for NGINX Ingress Controller..."
if ! kubectl get namespace ingress-nginx &> /dev/null; then
    print_warn "NGINX Ingress Controller not found."
    read -p "Do you want to install NGINX Ingress Controller? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Installing NGINX Ingress Controller..."
        kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml
        print_info "Waiting for Ingress Controller to be ready..."
        kubectl wait --namespace ingress-nginx \
          --for=condition=ready pod \
          --selector=app.kubernetes.io/component=controller \
          --timeout=120s
    else
        print_warn "Skipping NGINX Ingress Controller installation. Ingress may not work."
    fi
else
    print_info "NGINX Ingress Controller already installed."
fi

# Update Helm values with image names
print_info "Updating Helm values..."
sed -i.bak "s|image: .*event-management-backend.*|image: $BACKEND_IMAGE|" helm-chart/values.yaml
sed -i.bak "s|image: .*event-management-frontend.*|image: $FRONTEND_IMAGE|" helm-chart/values.yaml
rm -f helm-chart/values.yaml.bak

# Deploy with Helm
print_info "Deploying application with Helm..."
if helm list -n "$NAMESPACE" | grep -q event-management; then
    print_info "Upgrading existing deployment..."
    helm upgrade event-management ./helm-chart --namespace "$NAMESPACE"
else
    print_info "Installing new deployment..."
    helm install event-management ./helm-chart --namespace "$NAMESPACE"
fi

# Wait for deployments to be ready
print_info "Waiting for deployments to be ready..."
kubectl wait --for=condition=available --timeout=300s \
    deployment/mysql deployment/backend deployment/frontend \
    -n "$NAMESPACE" || true

# Get deployment status
print_info "Deployment Status:"
kubectl get all -n "$NAMESPACE"

# Get Ingress information
print_info "Ingress Information:"
kubectl get ingress -n "$NAMESPACE"

# Get service information
INGRESS_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
if [ -z "$INGRESS_IP" ]; then
    INGRESS_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
fi

if [ -z "$INGRESS_IP" ]; then
    INGRESS_IP="<pending or not available>"
fi

print_info "========================"
print_info "Deployment Complete!"
print_info "========================"
echo ""
print_info "Access the application:"
print_info "  Ingress URL: http://eventmanagement.local"
print_info "  Ingress IP: $INGRESS_IP"
echo ""
print_info "If using Ingress, add this to /etc/hosts:"
print_info "  $INGRESS_IP eventmanagement.local"
echo ""
print_info "Or access via NodePort:"
FRONTEND_NODEPORT=$(kubectl get svc frontend -n "$NAMESPACE" -o jsonpath='{.spec.ports[0].nodePort}')
BACKEND_NODEPORT=$(kubectl get svc backend -n "$NAMESPACE" -o jsonpath='{.spec.ports[0].nodePort}')
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}' 2>/dev/null || kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
print_info "  Frontend: http://$NODE_IP:$FRONTEND_NODEPORT"
print_info "  Backend: http://$NODE_IP:$BACKEND_NODEPORT"
echo ""
print_info "Useful commands:"
print_info "  kubectl get pods -n $NAMESPACE"
print_info "  kubectl get svc -n $NAMESPACE"
print_info "  kubectl logs -l app=backend -n $NAMESPACE"
print_info "  kubectl logs -l app=frontend -n $NAMESPACE"
print_info "  helm uninstall event-management -n $NAMESPACE"
