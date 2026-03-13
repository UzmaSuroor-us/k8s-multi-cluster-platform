# GitHub Actions Setup Guide

## Prerequisites
- GitHub repository with your code
- Local kind clusters (dev and prod) running
- kubectl configured with access to both clusters

## Setup Steps

### 1. Create GitHub Repository Secrets

Go to your GitHub repository → Settings → Secrets and variables → Actions → New repository secret

#### Required Secrets:

**KUBECONFIG_DEV** - Base64 encoded kubeconfig for dev cluster
```bash
kubectl config view --context kind-dev-cluster --minify --flatten | base64 -w 0
```

**KUBECONFIG_PROD** - Base64 encoded kubeconfig for prod cluster
```bash
kubectl config view --context kind-prod-cluster --minify --flatten | base64 -w 0
```

### 2. Configure Production Environment Protection

1. Go to Settings → Environments → New environment
2. Name it `production`
3. Enable "Required reviewers" (optional but recommended)
4. Add deployment branch rules: only `main` branch

### 3. Push Code to GitHub

```bash
cd ~/k8s-platform-complete
git init
git add .
git commit -m "Initial commit with GitHub Actions CI/CD"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
git push -u origin main
```

## Workflows Overview

### 1. **CI - Build and Test** (`.github/workflows/ci.yml`)
- **Triggers**: Pull requests, pushes to develop branch
- **Actions**: Lint Helm charts, validate manifests, run tests in temporary cluster
- **Purpose**: Ensure code quality before merging

### 2. **Deploy to Dev** (`.github/workflows/deploy-dev.yml`)
- **Triggers**: Push to main branch, manual trigger
- **Actions**: Deploy to dev cluster, run smoke tests
- **Purpose**: Automatic deployment to dev environment

### 3. **Deploy to Production** (`.github/workflows/deploy-prod.yml`)
- **Triggers**: GitHub release, manual trigger with confirmation
- **Actions**: Deploy to prod with 3 replicas, smoke tests, auto-rollback on failure
- **Purpose**: Controlled production deployments

### 4. **Rollback** (`.github/workflows/rollback.yml`)
- **Triggers**: Manual only
- **Actions**: Rollback deployment to previous version
- **Purpose**: Quick recovery from bad deployments

### 5. **Deploy Monitoring** (`.github/workflows/monitoring.yml`)
- **Triggers**: Manual only
- **Actions**: Deploy Prometheus/Grafana stack
- **Purpose**: Setup monitoring infrastructure

## Usage Examples

### Deploy to Dev (Automatic)
```bash
git checkout main
git pull
# Make changes
git add .
git commit -m "Update feature X"
git push origin main
# Workflow automatically deploys to dev
```

### Deploy to Production (Manual)
1. Go to Actions → Deploy to Production → Run workflow
2. Enter image tag (e.g., `1.22`)
3. Type `deploy` to confirm
4. Click "Run workflow"

### Create Release (Automatic Prod Deploy)
```bash
git tag -a v1.22 -m "Release version 1.22"
git push origin v1.22
# Create release on GitHub - workflow automatically deploys to prod
```

### Rollback
1. Go to Actions → Rollback Deployment → Run workflow
2. Select environment (dev/prod)
3. Type `rollback` to confirm
4. Click "Run workflow"

## Workflow Status Badges

Add to your README.md:

```markdown
![CI](https://github.com/YOUR_USERNAME/YOUR_REPO/workflows/CI%20-%20Build%20and%20Test/badge.svg)
![Deploy Dev](https://github.com/YOUR_USERNAME/YOUR_REPO/workflows/Deploy%20to%20Dev/badge.svg)
![Deploy Prod](https://github.com/YOUR_USERNAME/YOUR_REPO/workflows/Deploy%20to%20Production/badge.svg)
```

## Local Testing with act

Test workflows locally before pushing:

```bash
# Install act
curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash

# Run CI workflow
act pull_request

# Run specific job
act -j lint-and-validate
```

## Troubleshooting

### Workflow fails with "context not found"
- Verify kubeconfig secrets are correctly base64 encoded
- Check context names match: `kind-dev-cluster` and `kind-prod-cluster`

### Deployment timeout
- Increase `--timeout` value in workflow
- Check cluster resources: `kubectl top nodes`

### Permission denied
- Ensure GitHub Actions has write permissions: Settings → Actions → General → Workflow permissions → Read and write

## Security Notes

- Never commit kubeconfig files directly
- Use GitHub Secrets for sensitive data
- Enable branch protection rules
- Require PR reviews before merging to main
- Use environment protection for production
