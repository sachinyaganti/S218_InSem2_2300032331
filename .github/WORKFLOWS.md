# Quick Reference: GitHub Actions Workflows

## 🚀 Available Workflows

### 1. CI/CD Pipeline
**File**: `.github/workflows/ci-cd.yml`  
**Triggers**: Push to main/develop, Pull Requests  
**Purpose**: Automated build, test, and Docker image publishing

### 2. Kubernetes Deployment
**File**: `.github/workflows/deploy.yml`  
**Triggers**: Manual only  
**Purpose**: Deploy to Kubernetes environments

### 3. Release Management
**File**: `.github/workflows/release.yml`  
**Triggers**: Version tags (v*), Manual  
**Purpose**: Create releases and publish artifacts

## 📋 Common Tasks

### View Pipeline Status
🌐 https://sachinyaganti.github.io/S218_InSem2_2300032331/

### Trigger Manual Deployment
1. Go to Actions → Deploy to Kubernetes
2. Click "Run workflow"
3. Select environment and image tag
4. Confirm

### Create a Release
```bash
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0
```

### Pull Docker Images
```bash
# Backend
docker pull ghcr.io/sachinyaganti/event-management-backend:latest

# Frontend
docker pull ghcr.io/sachinyaganti/event-management-frontend:latest
```

## 🔍 Workflow Status Badges

Add to any markdown file:
```markdown
[![CI/CD](https://github.com/sachinyaganti/S218_InSem2_2300032331/actions/workflows/ci-cd.yml/badge.svg)](https://github.com/sachinyaganti/S218_InSem2_2300032331/actions/workflows/ci-cd.yml)
```

## 📚 Detailed Documentation
See [GITHUB_ACTIONS.md](GITHUB_ACTIONS.md) for complete documentation.
