# GitHub Actions CI/CD Pipeline

Complete guide for deploying OpenSearch on Kubernetes using GitHub Actions.

## 📋 Overview

GitHub Actions provides CI/CD automation directly integrated with GitHub repositories. Perfect for projects hosted on GitHub.

### Benefits
- ✅ Native GitHub integration
- ✅ Free for public repositories
- ✅ Large marketplace of actions
- ✅ Easy to set up and use
- ✅ Matrix builds support

---

## 🚀 Quick Setup

### 1. Create Workflow File

Create `.github/workflows/deploy-opensearch.yml` in your repository:

```yaml
name: Deploy OpenSearch to Kubernetes

on:
  push:
    branches: [ main ]
    paths:
      - 'k8s-manifests/**'
      - '.github/workflows/deploy-opensearch.yml'
  pull_request:
    branches: [ main ]
  workflow_dispatch:

env:
  KUBE_NAMESPACE: opensearch

jobs:
  validate:
    name: Validate Manifests
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup kubectl
        uses: azure/setup-kubectl@v3
        with:
          version: 'latest'

      - name: Validate YAML syntax
        run: |
          for file in k8s-manifests/*.yaml; do
            echo "Validating $file"
            kubectl apply --dry-run=client -f "$file"
          done

      - name: Run kubeval
        run: |
          wget https://github.com/instrumenta/kubeval/releases/latest/download/kubeval-linux-amd64.tar.gz
          tar xf kubeval-linux-amd64.tar.gz
          for file in k8s-manifests/*.yaml; do
            ./kubeval "$file"
          done

  deploy:
    name: Deploy to Kubernetes
    runs-on: ubuntu-latest
    needs: validate
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup kubectl
        uses: azure/setup-kubectl@v3

      - name: Configure kubectl
        run: |
          mkdir -p $HOME/.kube
          echo "${{ secrets.KUBE_CONFIG }}" | base64 -d > $HOME/.kube/config

      - name: Deploy to Kubernetes
        run: |
          kubectl apply -f k8s-manifests/00-namespace.yaml
          kubectl apply -f k8s-manifests/01-configmap.yaml
          kubectl apply -f k8s-manifests/02-pvc.yaml
          kubectl apply -f k8s-manifests/03-statefulset.yaml
          kubectl apply -f k8s-manifests/04-deployment-dashboards.yaml
          kubectl apply -f k8s-manifests/05-services.yaml

      - name: Wait for deployment
        run: |
          kubectl wait --for=condition=ready pod -l app=opensearch -n ${{ env.KUBE_NAMESPACE }} --timeout=300s
          kubectl wait --for=condition=ready pod -l app=opensearch-dashboards -n ${{ env.KUBE_NAMESPACE }} --timeout=300s

      - name: Verify deployment
        run: |
          kubectl get pods -n ${{ env.KUBE_NAMESPACE }}
          kubectl get svc -n ${{ env.KUBE_NAMESPACE }}

      - name: Run health check
        run: |
          OPENSEARCH_IP=$(kubectl get svc opensearch-nodeport -n ${{ env.KUBE_NAMESPACE }} -o jsonpath='{.spec.clusterIP}')
          kubectl run curl-test --image=curlimages/curl:latest --rm -i --restart=Never -- \
            curl -k "http://$OPENSEARCH_IP:9200/_cluster/health"

  notify:
    name: Send Notification
    runs-on: ubuntu-latest
    needs: [validate, deploy]
    if: always()
    steps:
      - name: Send Slack notification
        if: always()
        uses: 8398a7/action-slack@v3
        with:
          status: ${{ job.status }}
          text: 'OpenSearch deployment ${{ job.status }}'
          webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

### 2. Configure Secrets

#### Add Kubernetes Config

```powershell
# Get your kubeconfig
$kubeconfig = Get-Content $HOME/.kube/config -Raw

# Encode to base64
$bytes = [System.Text.Encoding]::UTF8.GetBytes($kubeconfig)
$base64 = [Convert]::ToBase64String($bytes)

# Copy to clipboard
$base64 | Set-Clipboard
Write-Host "Kubeconfig copied to clipboard!"
```

Then in GitHub:
1. Go to repository **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret**
3. Name: `KUBE_CONFIG`
4. Value: Paste the base64 string
5. Click **Add secret**

#### Optional: Add Slack Webhook

1. Create Slack webhook: https://api.slack.com/messaging/webhooks
2. Add secret `SLACK_WEBHOOK` with webhook URL

### 3. Test the Workflow

```powershell
# Make a change to trigger workflow
git add .
git commit -m "Test GitHub Actions workflow"
git push origin main

# Or trigger manually from GitHub Actions tab
```

---

## 🔧 Advanced Configurations

### Multi-Environment Deployment

```yaml
name: Deploy to Multiple Environments

on:
  push:
    branches: [ main, develop ]

jobs:
  deploy-dev:
    if: github.ref == 'refs/heads/develop'
    runs-on: ubuntu-latest
    environment: development
    steps:
      - uses: actions/checkout@v4
      - name: Deploy to Dev
        run: |
          kubectl config use-context dev-cluster
          kubectl apply -f k8s-manifests/ -n opensearch-dev

  deploy-prod:
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment: production
    steps:
      - uses: actions/checkout@v4
      - name: Deploy to Production
        run: |
          kubectl config use-context prod-cluster
          kubectl apply -f k8s-manifests/ -n opensearch-prod
```

### Matrix Strategy for Multiple Clusters

```yaml
jobs:
  deploy:
    strategy:
      matrix:
        cluster: [dev, staging, prod]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Deploy to ${{ matrix.cluster }}
        env:
          KUBE_CONFIG: ${{ secrets[format('KUBE_CONFIG_{0}', matrix.cluster)] }}
        run: |
          echo "$KUBE_CONFIG" | base64 -d > $HOME/.kube/config
          kubectl apply -f k8s-manifests/ -n opensearch-${{ matrix.cluster }}
```

### Rollback on Failure

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Save current state
        run: |
          kubectl get all -n opensearch -o yaml > backup.yaml
      
      - name: Deploy new version
        id: deploy
        run: |
          kubectl apply -f k8s-manifests/
      
      - name: Rollback on failure
        if: failure() && steps.deploy.outcome == 'failure'
        run: |
          kubectl apply -f backup.yaml
```

### Canary Deployment

```yaml
jobs:
  canary-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Deploy canary (10%)
        run: |
          kubectl apply -f k8s-manifests/canary/
          kubectl scale deployment opensearch-canary --replicas=1 -n opensearch
      
      - name: Wait and monitor
        run: |
          sleep 300  # Wait 5 minutes
          # Check metrics, error rates, etc.
      
      - name: Promote to production
        run: |
          kubectl apply -f k8s-manifests/
          kubectl scale deployment opensearch --replicas=10 -n opensearch
```

---

## 📊 Monitoring and Reporting

### Add Status Badge

Add to your README.md:

```markdown
![Deploy Status](https://github.com/USERNAME/REPO/workflows/Deploy%20OpenSearch%20to%20Kubernetes/badge.svg)
```

### Deployment Summary

```yaml
- name: Create deployment summary
  run: |
    echo "## Deployment Summary" >> $GITHUB_STEP_SUMMARY
    echo "- **Namespace**: opensearch" >> $GITHUB_STEP_SUMMARY
    echo "- **Pods**: $(kubectl get pods -n opensearch --no-headers | wc -l)" >> $GITHUB_STEP_SUMMARY
    echo "- **Services**: $(kubectl get svc -n opensearch --no-headers | wc -l)" >> $GITHUB_STEP_SUMMARY
```

---

## 🔐 Security Best Practices

### 1. Use Environment Secrets

```yaml
jobs:
  deploy:
    environment: production
    steps:
      - name: Deploy
        env:
          KUBE_CONFIG: ${{ secrets.KUBE_CONFIG }}
```

### 2. Limit Workflow Permissions

```yaml
permissions:
  contents: read
  deployments: write
```

### 3. Use OIDC for Cloud Providers

```yaml
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::123456789012:role/GitHubActions
    aws-region: us-east-1
```

---

## 🐛 Troubleshooting

### Workflow Not Triggering

Check:
- Branch name matches trigger
- File paths match the `paths` filter
- Workflow file is in `.github/workflows/`

### kubectl Connection Issues

```yaml
- name: Debug kubectl
  run: |
    kubectl version
    kubectl cluster-info
    kubectl config view
```

### Secret Not Found

Verify secret name matches exactly (case-sensitive):
```yaml
${{ secrets.KUBE_CONFIG }}  # Correct
${{ secrets.kube_config }}  # Wrong
```

---

## 📚 Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Workflow Syntax](https://docs.github.com/en/actions/reference/workflow-syntax-for-github-actions)
- [Actions Marketplace](https://github.com/marketplace?type=actions)

---

**Made with ❤️ for GitHub Users**