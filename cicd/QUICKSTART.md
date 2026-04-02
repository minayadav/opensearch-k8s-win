# 🚀 CI/CD Quick Start Guide (15 Minutes)

Get your OpenSearch Kubernetes deployment automated with CI/CD in just 15 minutes!

## 📋 Prerequisites Checklist

Before starting, ensure you have:

- ✅ Kubernetes cluster running (Docker Desktop, Minikube, or cloud)
- ✅ kubectl installed and configured
- ✅ Git repository with OpenSearch manifests
- ✅ 15 minutes of your time

---

## ⚡ Option 1: ArgoCD GitOps (Recommended)

**Time: ~15 minutes | Difficulty: Easy | Best for: Production**

### Step 1: Install ArgoCD (5 minutes)

```powershell
# Run the automated installation script
.\cicd\scripts\install-argocd.ps1

# The script will:
# - Install ArgoCD in your cluster
# - Display admin credentials
# - Open the ArgoCD UI
# - Start port-forwarding
```

**Expected Output:**
```
============================================================
ArgoCD Credentials
============================================================
Username: admin
Password: <random-password>
============================================================
```

### Step 2: Update Git Repository URL (2 minutes)

Edit `cicd/argocd/opensearch-application.yaml`:

```yaml
spec:
  source:
    repoURL: https://github.com/YOUR-USERNAME/opensearch-k8s-win.git  # ← Change this
    targetRevision: HEAD
    path: k8s-manifests
```

### Step 3: Deploy OpenSearch Application (3 minutes)

```powershell
# Apply the ArgoCD application
kubectl apply -f cicd/argocd/opensearch-application.yaml

# Watch the deployment
kubectl get application opensearch -n argocd -w
```

### Step 4: Access ArgoCD UI (2 minutes)

1. Open browser: https://localhost:8080
2. Login with credentials from Step 1
3. Click on "opensearch" application
4. Watch the sync progress

### Step 5: Verify Deployment (3 minutes)

```powershell
# Check pods
kubectl get pods -n opensearch

# Check services
kubectl get svc -n opensearch

# Test OpenSearch
kubectl port-forward svc/opensearch-nodeport -n opensearch 9200:9200
# Open: http://localhost:9200
```

### ✅ Done! Your GitOps Pipeline is Ready

**What you get:**
- ✅ Automatic sync on Git changes
- ✅ Self-healing if cluster state drifts
- ✅ Easy rollback to previous versions
- ✅ Visual UI for monitoring

**Next Steps:**
- Make a change to k8s-manifests and push to Git
- Watch ArgoCD automatically sync the changes
- Explore the ArgoCD UI features

---

## ⚡ Option 2: GitHub Actions (10 minutes)

**Time: ~10 minutes | Difficulty: Easy | Best for: GitHub Projects**

### Step 1: Create Workflow File (2 minutes)

Create `.github/workflows/deploy-opensearch.yml`:

```yaml
name: Deploy OpenSearch

on:
  push:
    branches: [ main ]
    paths:
      - 'k8s-manifests/**'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup kubectl
        uses: azure/setup-kubectl@v3
      
      - name: Configure kubectl
        run: |
          mkdir -p $HOME/.kube
          echo "${{ secrets.KUBE_CONFIG }}" | base64 -d > $HOME/.kube/config
      
      - name: Deploy
        run: kubectl apply -f k8s-manifests/
      
      - name: Verify
        run: kubectl get pods -n opensearch
```

### Step 2: Add Kubernetes Config Secret (3 minutes)

```powershell
# Get kubeconfig and encode to base64
$kubeconfig = Get-Content $HOME/.kube/config -Raw
$bytes = [System.Text.Encoding]::UTF8.GetBytes($kubeconfig)
$base64 = [Convert]::ToBase64String($bytes)
$base64 | Set-Clipboard
Write-Host "Kubeconfig copied to clipboard!"
```

In GitHub:
1. Go to **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret**
3. Name: `KUBE_CONFIG`
4. Value: Paste from clipboard
5. Click **Add secret**

### Step 3: Commit and Push (2 minutes)

```powershell
git add .github/workflows/deploy-opensearch.yml
git commit -m "Add GitHub Actions workflow"
git push origin main
```

### Step 4: Monitor Deployment (3 minutes)

1. Go to GitHub repository
2. Click **Actions** tab
3. Watch the workflow run
4. Check deployment status

### ✅ Done! Your CI/CD Pipeline is Active

**What you get:**
- ✅ Automatic deployment on push to main
- ✅ Validation before deployment
- ✅ Deployment history in GitHub
- ✅ Status badges for README

---

## ⚡ Option 3: Direct Deployment (5 minutes)

**Time: ~5 minutes | Difficulty: Very Easy | Best for: Quick Testing**

### One Command Deployment

```powershell
# Deploy everything
kubectl apply -f k8s-manifests/

# Wait for pods
kubectl wait --for=condition=ready pod -l app=opensearch -n opensearch --timeout=300s

# Verify
kubectl get all -n opensearch
```

### ✅ Done! OpenSearch is Running

**What you get:**
- ✅ Quick deployment for testing
- ✅ No CI/CD setup required
- ✅ Manual control over deployments

**Upgrade to CI/CD later:**
- Follow Option 1 or 2 when ready for automation

---

## 🎯 Comparison: Which Option to Choose?

| Feature | ArgoCD | GitHub Actions | Direct |
|---------|--------|----------------|--------|
| **Setup Time** | 15 min | 10 min | 5 min |
| **Automation** | ✅ Full | ✅ Full | ❌ Manual |
| **GitOps** | ✅ Yes | ⚠️ Partial | ❌ No |
| **Self-Healing** | ✅ Yes | ❌ No | ❌ No |
| **Rollback** | ✅ Easy | ⚠️ Manual | ⚠️ Manual |
| **Multi-Cluster** | ✅ Yes | ⚠️ Complex | ❌ No |
| **UI** | ✅ Yes | ✅ GitHub | ❌ No |
| **Best For** | Production | GitHub repos | Testing |

### Recommendations:

- **Choose ArgoCD if:**
  - You want production-grade GitOps
  - You need self-healing capabilities
  - You manage multiple clusters
  - You want easy rollbacks

- **Choose GitHub Actions if:**
  - Your code is on GitHub
  - You want simple CI/CD
  - You're familiar with GitHub workflows
  - You need custom build steps

- **Choose Direct Deployment if:**
  - You're just testing
  - You want manual control
  - You'll set up CI/CD later

---

## 🔧 Post-Setup Tasks

### 1. Verify Everything Works

```powershell
# Check all pods are running
kubectl get pods -n opensearch

# Test OpenSearch API
kubectl port-forward svc/opensearch-nodeport -n opensearch 9200:9200
# Open: http://localhost:9200

# Test OpenSearch Dashboards
kubectl port-forward svc/opensearch-dashboards-nodeport -n opensearch 5601:5601
# Open: http://localhost:5601
```

### 2. Load Sample Data

```powershell
# Install dependencies
cd data-loader
pip install -r requirements.txt

# Load e-commerce data
python load_ecommerce_data.py
```

### 3. Configure Monitoring (Optional)

```powershell
# View logs
kubectl logs -n opensearch -l app=opensearch --tail=50

# Monitor resources
kubectl top pods -n opensearch
```

---

## 🐛 Quick Troubleshooting

### ArgoCD UI Not Accessible

```powershell
# Restart port-forward
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

### Pods Not Starting

```powershell
# Check pod status
kubectl describe pod -n opensearch <pod-name>

# View logs
kubectl logs -n opensearch <pod-name>
```

### GitHub Actions Failing

```powershell
# Verify secret is set correctly
# Go to Settings → Secrets → Actions
# Check KUBE_CONFIG exists

# Test kubectl locally
kubectl cluster-info
```

### Application Not Syncing (ArgoCD)

```powershell
# Force refresh
kubectl patch application opensearch -n argocd --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"HEAD"}}}'
```

---

## 📚 Next Steps

### Learn More:
- [Full CI/CD Guide](./README.md)
- [ArgoCD Deep Dive](./argocd/README.md)
- [GitHub Actions Guide](./examples/github-actions.md)
- [Best Practices](./BEST-PRACTICES.md)

### Explore Features:
- Set up multi-environment deployments
- Configure automated rollbacks
- Add monitoring and alerts
- Implement canary deployments

### Get Help:
- Check [Troubleshooting Guide](./TROUBLESHOOTING.md)
- Review [Architecture Documentation](../docs/ARCHITECTURE.md)
- Open an issue on GitHub

---

## ✅ Success Checklist

After completing this guide, you should have:

- [ ] CI/CD tool installed and configured
- [ ] OpenSearch deployed to Kubernetes
- [ ] Automatic deployment on Git changes (if using ArgoCD/GitHub Actions)
- [ ] Verified OpenSearch is accessible
- [ ] Sample data loaded (optional)
- [ ] Monitoring configured (optional)

---

**🎉 Congratulations! Your CI/CD pipeline is ready!**

**Time spent:** ~15 minutes  
**Value gained:** Automated, reliable deployments  
**Next:** Explore advanced features and best practices

---

**Made with ❤️ for DevOps Engineers**