# CI/CD Pipeline for OpenSearch Kubernetes Deployment

Complete CI/CD implementation guide for deploying OpenSearch on Kubernetes using 5 popular tools.

## 📋 Table of Contents

1. [Quick Start (15 Minutes)](#quick-start-15-minutes)
2. [CI/CD Tools Overview](#cicd-tools-overview)
3. [Implementation Guides](#implementation-guides)
4. [Best Practices](#best-practices)
5. [Troubleshooting](#troubleshooting)

---

## 🚀 Quick Start (15 Minutes)

### Prerequisites
- Kubernetes cluster running (Docker Desktop/Minikube/Cloud)
- kubectl configured and working
- Git repository with OpenSearch manifests

### Recommended: ArgoCD GitOps Deployment

```powershell
# 1. Install ArgoCD (2 min)
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 2. Wait for ArgoCD pods (3 min)
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# 3. Get admin password (1 min)
$ARGOCD_PASSWORD = kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }
Write-Host "ArgoCD Password: $ARGOCD_PASSWORD"

# 4. Access ArgoCD UI (1 min)
kubectl port-forward svc/argocd-server -n argocd 8080:443

# 5. Deploy OpenSearch (2 min)
kubectl apply -f cicd/argocd/opensearch-application.yaml

# 6. Monitor deployment (5 min)
kubectl get pods -n opensearch -w
```

**Access ArgoCD**: https://localhost:8080 (admin / password from step 3)

---

## 🔧 CI/CD Tools Overview

| Tool | Type | Complexity | Best For | Setup Time |
|------|------|------------|----------|------------|
| **GitHub Actions** | CI/CD | ⭐ Low | GitHub repos | 10 min |
| **GitLab CI/CD** | CI/CD | ⭐ Low | GitLab repos | 10 min |
| **Jenkins** | CI/CD | ⭐⭐ Medium | Enterprise | 30 min |
| **ArgoCD** | GitOps | ⭐ Low | Production | 15 min |
| **Tekton** | Cloud-Native | ⭐⭐⭐ High | K8s-native | 45 min |

### When to Use Each

- **GitHub Actions**: Simple workflows, GitHub-hosted projects
- **GitLab CI/CD**: GitLab users, integrated DevOps platform
- **Jenkins**: Complex pipelines, existing Jenkins infrastructure
- **ArgoCD**: ✅ **Recommended** - Production GitOps, auto-sync, easy rollbacks
- **Tekton**: Kubernetes-native pipelines, cloud-native apps

---

## 📚 Implementation Guides

### Detailed Guides Available:

1. **[GitHub Actions](./examples/github-actions.md)** - Automated deployment on push
2. **[GitLab CI/CD](./examples/gitlab-ci.md)** - GitLab integrated pipelines
3. **[Jenkins](./examples/jenkins.md)** - Traditional CI/CD server
4. **[ArgoCD](./argocd/README.md)** - GitOps continuous delivery ⭐ Recommended
5. **[Tekton](./examples/tekton.md)** - Kubernetes-native pipelines

### Quick Links:
- [ArgoCD Installation Script](./scripts/install-argocd.ps1)
- [ArgoCD Application Manifest](./argocd/opensearch-application.yaml)
- [Best Practices Guide](./BEST-PRACTICES.md)
- [Troubleshooting Guide](./TROUBLESHOOTING.md)

---

## 🎯 Best Practices

### 1. GitOps Principles (ArgoCD)
- ✅ Store all configs in Git (single source of truth)
- ✅ Use declarative configurations
- ✅ Enable auto-sync with caution (test in dev first)
- ✅ Implement proper RBAC and access controls

### 2. Security
- 🔒 Never commit secrets to Git
- 🔒 Use Kubernetes Secrets or external secret managers
- 🔒 Implement RBAC for CI/CD tools
- 🔒 Scan container images for vulnerabilities
- 🔒 Use private registries for production

### 3. Testing Strategy
```
┌─────────────┐
│ Unit Tests  │ (Fast, isolated)
├─────────────┤
│ Integration │ (Component interaction)
├─────────────┤
│ E2E Tests   │ (Full workflow)
├─────────────┤
│ Smoke Tests │ (Post-deployment)
└─────────────┘
```

### 4. Deployment Strategy
- **Blue-Green**: Zero downtime, instant rollback
- **Canary**: Gradual rollout, risk mitigation
- **Rolling**: Default Kubernetes strategy

### 5. Monitoring & Observability
- Monitor deployment status
- Set up alerts for failures
- Track deployment metrics
- Implement health checks

---

## 🔍 Troubleshooting

### Common Issues

#### 1. ArgoCD Application Not Syncing
```powershell
# Check application status
kubectl get application opensearch -n argocd

# View sync status
kubectl describe application opensearch -n argocd

# Force sync
kubectl patch application opensearch -n argocd --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"HEAD"}}}'
```

#### 2. Pods Not Starting
```powershell
# Check pod status
kubectl get pods -n opensearch

# View pod logs
kubectl logs -n opensearch <pod-name>

# Describe pod for events
kubectl describe pod -n opensearch <pod-name>
```

#### 3. Service Not Accessible
```powershell
# Check services
kubectl get svc -n opensearch

# Test internal connectivity
kubectl run curl-test --image=curlimages/curl:latest --rm -i --restart=Never -- curl -k http://opensearch-nodeport.opensearch:9200
```

#### 4. ArgoCD UI Not Accessible
```powershell
# Check ArgoCD pods
kubectl get pods -n argocd

# Restart port-forward
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

#### 5. Authentication Issues
```powershell
# Reset ArgoCD admin password
kubectl -n argocd patch secret argocd-secret -p '{"stringData": {"admin.password": ""}}'
kubectl -n argocd delete pod -l app.kubernetes.io/name=argocd-server
```

### Debug Commands

```powershell
# View all resources in namespace
kubectl get all -n opensearch

# Check events
kubectl get events -n opensearch --sort-by='.lastTimestamp'

# View logs from all pods
kubectl logs -n opensearch -l app=opensearch --tail=50

# Execute command in pod
kubectl exec -it -n opensearch <pod-name> -- /bin/bash

# Check resource usage
kubectl top pods -n opensearch
```

---

## 📖 Additional Resources

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Kubernetes Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)
- [GitOps Principles](https://www.gitops.tech/)
- [OpenSearch Documentation](https://opensearch.org/docs/)

---

## 🤝 Contributing

Improvements and suggestions are welcome! Please:
1. Test changes in a dev environment
2. Update documentation
3. Follow existing patterns
4. Submit pull requests

---

## 📝 License

This project is part of the OpenSearch Kubernetes deployment guide.

---

**Made with ❤️ for DevOps Engineers**