#!/bin/bash

# Event Management System - Quick Deploy Script
# This script helps you quickly deploy the application to a local Kubernetes cluster

set -e

echo "======================================"
echo "Event Management System Deployment"
echo "======================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl not found. Please install kubectl first."
    exit 1
fi
print_success "kubectl is installed"

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    print_error "Helm not found. Please install Helm first."
    exit 1
fi
print_success "Helm is installed"

# Check if connected to a Kubernetes cluster
if ! kubectl cluster-info &> /dev/null; then
    print_error "Cannot connect to Kubernetes cluster. Please check your kubeconfig."
    exit 1
fi
print_success "Connected to Kubernetes cluster"

echo ""
print_info "Checking for NGINX Ingress Controller..."

# Check if NGINX Ingress Controller is installed
if ! kubectl get namespace ingress-nginx &> /dev/null; then
    print_info "NGINX Ingress Controller not found. Installing..."
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml
    print_success "NGINX Ingress Controller installed"
    
    print_info "Waiting for Ingress Controller to be ready..."
    kubectl wait --namespace ingress-nginx \
        --for=condition=ready pod \
        --selector=app.kubernetes.io/component=controller \
        --timeout=120s
    print_success "NGINX Ingress Controller is ready"
else
    print_success "NGINX Ingress Controller is already installed"
fi

echo ""
print_info "Deploying Event Management System..."

# Deploy using Helm
if helm list | grep -q event-management; then
    print_info "Application already installed. Upgrading..."
    helm upgrade event-management ./helm-chart
    print_success "Application upgraded successfully"
else
    helm install event-management ./helm-chart
    print_success "Application installed successfully"
fi

echo ""
print_info "Waiting for pods to be ready..."

# Wait for MySQL to be ready
kubectl wait --for=condition=ready pod -l app=mysql --timeout=180s || true

# Wait for backend to be ready
kubectl wait --for=condition=ready pod -l app=backend --timeout=180s || true

# Wait for frontend to be ready
kubectl wait --for=condition=ready pod -l app=frontend --timeout=180s || true

echo ""
print_success "Deployment complete!"

echo ""
echo "======================================"
echo "Application Information"
echo "======================================"

# Get service information
echo ""
echo "Services:"
kubectl get svc | grep -E "NAME|mysql|backend|frontend"

echo ""
echo "Pods:"
kubectl get pods | grep -E "NAME|mysql|backend|frontend"

echo ""
echo "Ingress:"
kubectl get ingress

echo ""
echo "HPA (Auto-scaling):"
kubectl get hpa

echo ""
echo "======================================"
echo "Access Information"
echo "======================================"
echo ""

# Get Ingress IP
INGRESS_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
if [ -z "$INGRESS_IP" ]; then
    INGRESS_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.clusterIP}' 2>/dev/null)
fi

if [ -n "$INGRESS_IP" ]; then
    print_info "Add this to your /etc/hosts file:"
    echo "    $INGRESS_IP eventmanagement.local"
    echo ""
    print_info "Then access the application at:"
    echo "    http://eventmanagement.local"
else
    print_info "Could not determine Ingress IP automatically"
fi

echo ""
print_info "Alternative access via NodePort:"
echo "    Frontend: http://<node-ip>:30081"
echo "    Backend:  http://<node-ip>:30080"

echo ""
print_info "For port-forwarding (local development):"
echo "    kubectl port-forward svc/frontend 8081:80"
echo "    Then access at: http://localhost:8081"

echo ""
echo "======================================"
print_success "Deployment script completed!"
echo "======================================"
