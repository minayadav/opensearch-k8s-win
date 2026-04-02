# ArgoCD GitOps Deployment Guide

Complete guide for deploying OpenSearch on Kubernetes using ArgoCD GitOps methodology.

## 📋 Table of Contents

1. [Overview](#overview)
2. [Quick Start](#quick-start)
3. [Installation](#installation)
4. [Configuration](#configuration)
5. [Usage](#usage)
6. [Advanced Features](#advanced-features)
7. [Troubleshooting](#troubleshooting)

---

## 🎯 Overview

ArgoCD is a declarative, GitOps continuous delivery tool for Kubernetes. It automatically syncs your Kubernetes cluster state with configurations stored in Git.

### Benefits

- ✅ **GitOps**: Git as single source of truth
- ✅ **Automated Sync**: Automatic deployment on Git changes
- ✅ **Self-Healing**: Automatically corrects drift
- ✅ **Rollback**: Easy rollback to previous versions
- ✅ **Multi-Cluster**: Manage multiple clusters
- ✅ **RBAC**: Fine-grained access control

### Architecture

```
┌─────────────────┐
│  Git Repository │ ◄─── Developers commit changes
│  (Source Code)  │
└────────┬────────┘
         │
         │ ArgoCD monitors
         ▼
┌─────────────────┐
│     ArgoCD      │
│   (Controller)  │
└────────┬────────┘
         │
         │ Syncs to
         ▼
┌─────────────────┐
│   Kubernetes    │
│    Cluster      │
│  (OpenSearch)   │
└─────────────────┘
```

---

## 🚀 Quick Start

### Prerequisites

- Kubernetes cluster (v1.20+)
- kubectl configured
- Git repository with OpenSearch manifests

### 1. Install ArgoCD (Automated)

```powershell
# Run installation script
.\cicd\scripts\install-argocd.ps1

# Or manual installation
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### 2. Access ArgoCD UI

```powershell
# Get admin password
$ARGOCD_PASSWORD = kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }
Write-Host "Password: $ARGOCD_PASSWORD"

# Port-forward to access UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Open browser: https://localhost:8080
# Username: admin
# Password: (from above)
```

### 3. Deploy OpenSearch Application

```powershell
# Update the Git repository URL in opensearch-application.yaml
# Then apply the application
kubectl apply -f cicd/argocd/opensearch-application.yaml

# Watch deployment
kubectl get application opensearch -n argocd -w
```

---

## 📦 Installation

### Method 1: Automated Script (Recommended)

```powershell
# Basic installation
.\cicd\scripts\install-argocd.ps1

# Custom namespace
.\cicd\scripts\install-argocd.ps1 -Namespace my-argocd

# Skip UI opening
.\cicd\scripts\install-argocd.ps1 -SkipUI
```

### Method 2: Manual Installation

```powershell
# Create namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for pods to be ready
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# Get initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }
```

### Method 3: Using Helm

```powershell
# Add ArgoCD Helm repository
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# Install ArgoCD
helm install argocd argo/argo-cd -n argocd --create-namespace

# Get password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }
```

---

## ⚙️ Configuration

### Application Manifest Explained

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: opensearch
  namespace: argocd
spec:
  project: default
  
  # Source configuration
  source:
    repoURL: https://github.com/YOUR-USERNAME/opensearch-k8s-windows.git
    targetRevision: HEAD  # or specific branch/tag
    path: k8s-manifests
  
  # Destination configuration
  destination:
    server: https://kubernetes.default.svc
    namespace: opensearch
  
  # Sync policy
  syncPolicy:
    automated:
      prune: true      # Delete removed resources
      selfHeal: true   # Auto-sync on drift
    syncOptions:
      - CreateNamespace=true
```

### Sync Policy Options

#### 1. Manual Sync (Conservative)

```yaml
syncPolicy: {}  # No automated sync
```

**Use when**: Testing, production with strict change control

#### 2. Automated Sync (Recommended)

```yaml
syncPolicy:
  automated:
    prune: true
    selfHeal: true
```

**Use when**: Development, staging, mature production

#### 3. Automated with Safeguards

```yaml
syncPolicy:
  automated:
    prune: false      # Manual deletion required
    selfHeal: true
  syncOptions:
    - CreateNamespace=true
    - PruneLast=true  # Delete after new resources healthy
```

**Use when**: Production with safety requirements

### Repository Configuration

#### Public Repository

```yaml
source:
  repoURL: https://github.com/username/repo.git
  targetRevision: HEAD
  path: k8s-manifests
```

#### Private Repository (SSH)

```powershell
# Add SSH key to ArgoCD
kubectl create secret generic repo-ssh-key `
  --from-file=sshPrivateKey=$HOME/.ssh/id_rsa `
  -n argocd

# Label the secret
kubectl label secret repo-ssh-key `
  argocd.argoproj.io/secret-type=repository `
  -n argocd
```

```yaml
source:
  repoURL: git@github.com:username/repo.git
  targetRevision: HEAD
  path: k8s-manifests
```

#### Private Repository (HTTPS)

```powershell
# Create secret with credentials
kubectl create secret generic repo-https-creds `
  --from-literal=username=YOUR_USERNAME `
  --from-literal=password=YOUR_TOKEN `
  -n argocd

kubectl label secret repo-https-creds `
  argocd.argoproj.io/secret-type=repository `
  -n argocd
```

---

## 🎮 Usage

### Deploy Application

```powershell
# Apply application manifest
kubectl apply -f cicd/argocd/opensearch-application.yaml

# Verify application created
kubectl get application opensearch -n argocd
```

### Monitor Deployment

```powershell
# Watch application status
kubectl get application opensearch -n argocd -w

# View detailed status
kubectl describe application opensearch -n argocd

# Check sync status
kubectl get application opensearch -n argocd -o jsonpath='{.status.sync.status}'
```

### Manual Sync

```powershell
# Sync via kubectl
kubectl patch application opensearch -n argocd --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"HEAD"}}}'

# Or use ArgoCD CLI
argocd app sync opensearch
```

### Rollback

```powershell
# List history
argocd app history opensearch

# Rollback to specific revision
argocd app rollback opensearch <revision-id>
```

### Delete Application

```powershell
# Delete application (keeps resources)
kubectl delete application opensearch -n argocd

# Delete application and resources
kubectl patch application opensearch -n argocd -p '{"metadata":{"finalizers":null}}' --type merge
kubectl delete application opensearch -n argocd
```

---

## 🔧 Advanced Features

### 1. Multi-Environment Setup

Create separate applications for each environment:

```yaml
# dev-opensearch-application.yaml
metadata:
  name: opensearch-dev
spec:
  source:
    targetRevision: develop
    path: k8s-manifests/dev
  destination:
    namespace: opensearch-dev
```

```yaml
# prod-opensearch-application.yaml
metadata:
  name: opensearch-prod
spec:
  source:
    targetRevision: main
    path: k8s-manifests/prod
  destination:
    namespace: opensearch-prod
```

### 2. App of Apps Pattern

Manage multiple applications with a parent app:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: opensearch-stack
  namespace: argocd
spec:
  source:
    repoURL: https://github.com/username/repo.git
    path: argocd-apps
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### 3. Sync Waves

Control deployment order with annotations:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: opensearch
  annotations:
    argocd.argoproj.io/sync-wave: "0"  # Deploy first
---
apiVersion: v1
kind: ConfigMap
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "1"  # Deploy second
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "2"  # Deploy third
```

### 4. Health Checks

Custom health checks for resources:

```yaml
spec:
  ignoreDifferences:
    - group: apps
      kind: StatefulSet
      jsonPointers:
        - /spec/replicas  # Ignore replica count differences
```

### 5. Notifications

Configure Slack notifications:

```powershell
# Install ArgoCD notifications
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj-labs/argocd-notifications/stable/manifests/install.yaml

# Configure Slack webhook
kubectl create secret generic argocd-notifications-secret `
  --from-literal=slack-token=YOUR_SLACK_TOKEN `
  -n argocd
```

---

## 🔍 Troubleshooting

### Application Not Syncing

```powershell
# Check application status
kubectl describe application opensearch -n argocd

# View sync errors
kubectl get application opensearch -n argocd -o jsonpath='{.status.conditions}'

# Force refresh
argocd app get opensearch --refresh
```

### Out of Sync Status

```powershell
# View differences
argocd app diff opensearch

# Sync specific resource
argocd app sync opensearch --resource apps:StatefulSet:opensearch
```

### Connection Issues

```powershell
# Test repository connection
argocd repo list

# Add repository manually
argocd repo add https://github.com/username/repo.git
```

### Performance Issues

```powershell
# Increase controller replicas
kubectl scale deployment argocd-application-controller -n argocd --replicas=2

# Adjust resource limits
kubectl edit deployment argocd-application-controller -n argocd
```

---

## 📚 Additional Resources

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [GitOps Principles](https://www.gitops.tech/)
- [Best Practices](https://argo-cd.readthedocs.io/en/stable/user-guide/best_practices/)
- [ArgoCD Examples](https://github.com/argoproj/argocd-example-apps)

---

**Made with ❤️ for GitOps**