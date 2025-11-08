# GitHub Actions CI/CD Guide

This guide explains how to use the GitHub Actions workflows configured for the Event Management System.

## Overview

The project includes three automated workflows:

1. **CI/CD Pipeline** (`ci-cd.yml`) - Automated build, test, and deployment tracking
2. **Kubernetes Deployment** (`deploy.yml`) - Manual deployment to Kubernetes environments
3. **Release Management** (`release.yml`) - Automated release creation and artifact publishing

## 🔄 CI/CD Pipeline Workflow

### Trigger Events
- **Automatic**: Runs on every push to `main` or `develop` branches
- **Automatic**: Runs on pull requests targeting `main` or `develop`
- **Manual**: Can be triggered manually from the Actions tab

### What It Does

1. **Backend Build**
   - Sets up Java 17 and Maven
   - Clones the Event Management System backend source
   - Compiles and packages the Spring Boot application
   - Runs unit tests
   - Uploads build artifacts
   - Builds and pushes Docker image to GitHub Container Registry (on push to main/develop)

2. **Frontend Build**
   - Sets up Node.js 18
   - Clones the Event Management System frontend source
   - Installs dependencies with npm
   - Builds the React/Vite application
   - Runs tests
   - Uploads build artifacts
   - Builds and pushes Docker image to GitHub Container Registry (on push to main/develop)

3. **Helm Chart Validation**
   - Validates Helm chart syntax
   - Ensures Kubernetes manifests are correctly formatted

4. **GitHub Pages Deployment**
   - Generates a beautiful dashboard showing build status
   - Displays project information and links
   - Updates automatically on every successful build
   - Accessible at: https://sachinyaganti.github.io/S218_InSem2_2300032331/

### Docker Images

Images are published to GitHub Container Registry:
- `ghcr.io/sachinyaganti/event-management-backend:latest`
- `ghcr.io/sachinyaganti/event-management-backend:<commit-sha>`
- `ghcr.io/sachinyaganti/event-management-frontend:latest`
- `ghcr.io/sachinyaganti/event-management-frontend:<commit-sha>`

### Viewing Results

1. Go to the **Actions** tab in GitHub
2. Select the **CI/CD Pipeline** workflow
3. Click on a specific run to see detailed logs
4. View the [Pipeline Dashboard](https://sachinyaganti.github.io/S218_InSem2_2300032331/) for summary

## 🚀 Kubernetes Deployment Workflow

### Trigger Events
- **Manual Only**: Must be triggered manually from the Actions tab

### How to Deploy

1. Navigate to **Actions** > **Deploy to Kubernetes**
2. Click **Run workflow**
3. Select:
   - **Environment**: `staging` or `production`
   - **Image Tag**: Docker image tag to deploy (default: `latest`)
4. Click **Run workflow**

### What It Does

1. Checks out the repository
2. Configures Helm and kubectl
3. Updates Helm values with selected image tag
4. Deploys to Kubernetes using Helm
5. Verifies deployment status
6. Runs health checks on pods
7. Generates deployment summary

### Prerequisites

To use this workflow, you need to:
1. Set up Kubernetes cluster credentials as GitHub secrets
2. Configure the workflow with your cluster details
3. Ensure the cluster has NGINX Ingress Controller installed

### Configuration

Update the workflow file (`.github/workflows/deploy.yml`) with your cluster credentials:

```yaml
- name: Configure kubectl
  run: |
    kubectl config set-cluster my-cluster --server=${{ secrets.K8S_SERVER }}
    kubectl config set-credentials my-user --token=${{ secrets.K8S_TOKEN }}
    kubectl config set-context my-context --cluster=my-cluster --user=my-user
    kubectl config use-context my-context
```

Required GitHub Secrets:
- `K8S_SERVER`: Kubernetes API server URL
- `K8S_TOKEN`: Authentication token for Kubernetes

## 📦 Release Workflow

### Trigger Events
- **Automatic**: Runs when a version tag is pushed (e.g., `v1.0.0`)
- **Manual**: Can be triggered manually from the Actions tab

### How to Create a Release

```bash
# Create and push a version tag
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0
```

### What It Does

1. Builds backend and frontend applications
2. Creates Docker images tagged with version number
3. Pushes images to GitHub Container Registry with version tags
4. Packages Helm chart with version number
5. Generates release notes
6. Creates a GitHub Release with:
   - Release notes
   - Packaged Helm chart
   - Installation instructions
   - Links to Docker images

### Version Tags

The workflow supports semantic versioning:
- `v1.0.0` - Major release
- `v1.1.0` - Minor release
- `v1.1.1` - Patch release

### Published Artifacts

- Docker images: `ghcr.io/sachinyaganti/event-management-backend:v1.0.0`
- Docker images: `ghcr.io/sachinyaganti/event-management-frontend:v1.0.0`
- Helm chart: `event-management-1.0.0.tgz`

## 🔐 Secrets Configuration

### GitHub Container Registry

No additional secrets needed! The workflows use `GITHUB_TOKEN` which is automatically provided by GitHub Actions.

### Kubernetes Deployment (Optional)

If you want to use the deployment workflow, add these secrets:

1. Go to **Settings** > **Secrets and variables** > **Actions**
2. Click **New repository secret**
3. Add:
   - `K8S_SERVER`: Your Kubernetes API server URL
   - `K8S_TOKEN`: Authentication token with deployment permissions

### Environment Secrets (Optional)

For environment-specific deployments:

1. Go to **Settings** > **Environments**
2. Create environments: `staging` and `production`
3. Add environment-specific secrets if needed

## 📊 Monitoring and Troubleshooting

### Viewing Workflow Logs

1. Go to **Actions** tab
2. Select the workflow run
3. Click on individual jobs to see logs
4. Expand steps to see detailed output

### Common Issues

#### Failed Build
- Check the build logs for compilation errors
- Ensure dependencies are properly specified
- Verify source repository is accessible

#### Docker Push Failed
- Verify GitHub Container Registry permissions
- Check if `GITHUB_TOKEN` has `packages: write` permission

#### Deployment Failed
- Verify Kubernetes credentials are correct
- Check if cluster is accessible
- Ensure namespace exists and has proper permissions

### Debugging Tips

1. **Enable Debug Logging**:
   - Go to **Settings** > **Secrets**
   - Add `ACTIONS_STEP_DEBUG` with value `true`

2. **Re-run Failed Jobs**:
   - Click on the failed workflow run
   - Click **Re-run failed jobs**

3. **Manual Testing**:
   - Use the workflow dispatch trigger to test with specific parameters

## 🎯 Best Practices

### Development Workflow

1. **Feature Development**:
   ```bash
   git checkout -b feature/my-feature
   # Make changes
   git commit -m "Add my feature"
   git push origin feature/my-feature
   ```

2. **Create Pull Request**:
   - CI pipeline runs automatically
   - Review build status in PR checks
   - Merge only if all checks pass

3. **Release Process**:
   ```bash
   git checkout main
   git pull
   git tag -a v1.1.0 -m "Release 1.1.0"
   git push origin v1.1.0
   ```

### Deployment Strategy

1. **Staging First**:
   - Deploy to staging environment
   - Test thoroughly
   - Verify all features work

2. **Production Deployment**:
   - Use the same image tag tested in staging
   - Deploy during low-traffic periods
   - Monitor closely after deployment

3. **Rollback Plan**:
   - Keep previous version tag available
   - Use deployment workflow to redeploy previous version if needed

## 📚 Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GitHub Container Registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

## 🆘 Getting Help

If you encounter issues:

1. Check the [Actions tab](https://github.com/sachinyaganti/S218_InSem2_2300032331/actions) for detailed logs
2. Review the [Pipeline Dashboard](https://sachinyaganti.github.io/S218_InSem2_2300032331/)
3. Check workflow files in `.github/workflows/` directory
4. Review this documentation for configuration examples
