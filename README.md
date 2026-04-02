# OpenSearch + Dashboards on Kubernetes for Windows

A production-ready local Kubernetes deployment of OpenSearch and OpenSearch Dashboards, optimized for Windows with Docker Desktop's 4GB memory constraint.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Resource Optimization](#resource-optimization)
- [Quick Start](#quick-start)
- [CI/CD Pipeline](#cicd-pipeline)
- [Deployment](#deployment)
- [Accessing Services](#accessing-services)
- [Monitoring](#monitoring)
- [Troubleshooting](#troubleshooting)
- [Cleanup](#cleanup)
- [Configuration Details](#configuration-details)

## 🎯 Overview

This project provides a complete Kubernetes setup for running OpenSearch and OpenSearch Dashboards locally on Windows, specifically optimized for Docker Desktop's 4GB memory limit.

### Key Features

- **Memory Optimized**: JVM heap limited to 256MB, total memory requests at 384Mi
- **Single-Node Cluster**: Simplified setup for local development
- **Persistent Storage**: Uses hostPath for data persistence
- **Security Disabled**: Simplified for local development (enable for production)
- **Windows Native**: Batch and PowerShell deployment scripts
- **NodePort Services**: Easy access via localhost

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                    │
│                                                           │
│  ┌────────────────────────────────────────────────────┐ │
│  │              Namespace: opensearch                  │ │
│  │                                                      │ │
│  │  ┌──────────────────┐      ┌───────────────────┐  │ │
│  │  │   StatefulSet    │      │    Deployment     │  │ │
│  │  │   OpenSearch     │◄─────┤    Dashboards     │  │ │
│  │  │                  │      │                   │  │ │
│  │  │  Memory: 384Mi   │      │  Memory: 256Mi    │  │ │
│  │  │  Heap: 256MB     │      │                   │  │ │
│  │  └────────┬─────────┘      └─────────┬─────────┘  │ │
│  │           │                           │             │ │
│  │           │                           │             │ │
│  │  ┌────────▼─────────┐      ┌─────────▼─────────┐  │ │
│  │  │  Service (9200)  │      │ Service (5601)    │  │ │
│  │  │  NodePort:30920  │      │ NodePort:30561    │  │ │
│  │  └──────────────────┘      └───────────────────┘  │ │
│  │                                                      │ │
│  │  ┌──────────────────────────────────────────────┐  │ │
│  │  │         PersistentVolume (hostPath)          │  │ │
│  │  │              /mnt/data/opensearch            │  │ │
│  │  └──────────────────────────────────────────────┘  │ │
│  └────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
         │                              │
         │ localhost:30920              │ localhost:30561
         ▼                              ▼
    OpenSearch API            OpenSearch Dashboards UI
```

## 📦 Prerequisites

### Required Software

1. **Docker Desktop for Windows** (with Kubernetes enabled)
   - Download: https://www.docker.com/products/docker-desktop
   - Minimum 4GB RAM allocated to Docker
   - Kubernetes enabled in settings

2. **kubectl** (Kubernetes CLI)
   - Download: https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/
   - Or install via Chocolatey: `choco install kubernetes-cli`

### Verify Installation

```powershell
# Check Docker Desktop is running
docker version

# Check Kubernetes is running
kubectl cluster-info

# Check kubectl version
kubectl version --client
```

## ⚡ Resource Optimization

This deployment is specifically optimized for 4GB Docker Desktop memory constraint:

### Memory Allocation

| Component | Memory Request | Memory Limit | Heap Size |
|-----------|---------------|--------------|-----------|
| OpenSearch | 384Mi | 512Mi | 256MB |
| Dashboards | 256Mi | 384Mi | N/A |
| **Total** | **640Mi** | **896Mi** | - |

### Optimizations Applied

1. **JVM Heap**: Limited to 256MB (normally 512MB-1GB)
2. **G1GC**: Optimized garbage collection for low memory
3. **Single-Node**: No cluster overhead
4. **Disabled Features**: ML, security plugins disabled
5. **Thread Pools**: Reduced queue sizes
6. **Metaspace**: Limited to 128MB

## 🚀 Quick Start

### Option 1: Using Batch Script (CMD)

```batch
cd opensearch-k8s-windows\scripts
deploy.bat
```

### Option 2: Using PowerShell Script

```powershell
cd opensearch-k8s-windows\scripts
.\deploy.ps1
```

### Option 3: Manual Deployment

```powershell
cd opensearch-k8s-windows

# Apply manifests in order
kubectl apply -f k8s-manifests\00-namespace.yaml
kubectl apply -f k8s-manifests\01-configmap.yaml
kubectl apply -f k8s-manifests\02-pvc.yaml
kubectl apply -f k8s-manifests\03-statefulset.yaml
kubectl apply -f k8s-manifests\04-deployment-dashboards.yaml
kubectl apply -f k8s-manifests\05-services.yaml
```

## 🚀 CI/CD Pipeline

This project includes comprehensive CI/CD pipeline implementations for automated deployment:

### Quick Start (15 Minutes)

Get your automated deployment running in just 15 minutes with ArgoCD:

```powershell
# Install ArgoCD
.\cicd\scripts\install-argocd.ps1

# Deploy OpenSearch application
kubectl apply -f cicd/argocd/opensearch-application.yaml
```

### Available CI/CD Tools

| Tool | Type | Setup Time | Best For |
|------|------|------------|----------|
| **[ArgoCD](cicd/argocd/README.md)** | GitOps | 15 min | ⭐ Production (Recommended) |
| **[GitHub Actions](cicd/examples/github-actions.md)** | CI/CD | 10 min | GitHub Projects |
| **[GitLab CI/CD](cicd/examples/.gitlab-ci.yml)** | CI/CD | 10 min | GitLab Projects |
| **[Jenkins](cicd/examples/Jenkinsfile)** | CI/CD | 30 min | Enterprise |
| **[Tekton](cicd/examples/tekton-pipeline.yaml)** | Cloud-Native | 45 min | Kubernetes-Native |

### Documentation

- **[Quick Start Guide](cicd/QUICKSTART.md)** - Get started in 15 minutes
- **[Complete CI/CD Guide](cicd/README.md)** - Comprehensive overview
- **[Best Practices](cicd/BEST-PRACTICES.md)** - Production-ready practices
- **[Troubleshooting](cicd/TROUBLESHOOTING.md)** - Common issues and solutions

### Features

- ✅ **Automated Deployment** - Push to Git, auto-deploy to Kubernetes
- ✅ **GitOps Ready** - ArgoCD for declarative deployments
- ✅ **Multi-Environment** - Dev, Staging, Production support
- ✅ **Self-Healing** - Automatic drift correction (ArgoCD)
- ✅ **Easy Rollback** - One-click rollback to previous versions
- ✅ **Security Scanning** - Built-in manifest validation

## 🌐 Accessing Services

After deployment (wait 2-3 minutes for pods to be ready):

### OpenSearch API
- **URL**: http://localhost:30920
- **Health Check**: http://localhost:30920/_cluster/health
- **Test Command**:
  ```powershell
  curl http://localhost:30920
  ```

### OpenSearch Dashboards
- **URL**: http://localhost:30561
- **Access**: Open in web browser
- **Default**: No authentication required (security disabled)

## 📊 Monitoring

### Check Pod Status

```powershell
# View all resources
kubectl get all -n opensearch

# Check pod status
kubectl get pods -n opensearch

# Detailed pod information
kubectl describe pod -n opensearch opensearch-0
```

### View Logs

```powershell
# OpenSearch logs
kubectl logs -n opensearch -l app=opensearch -f

# Dashboards logs
kubectl logs -n opensearch -l app=opensearch-dashboards -f

# Specific pod logs
kubectl logs -n opensearch opensearch-0 -f
```

### Resource Usage

```powershell
# Check resource consumption
kubectl top pods -n opensearch

# Check node resources
kubectl top nodes
```

## 🔧 Troubleshooting

### Pods Not Starting

**Issue**: Pods stuck in `Pending` or `CrashLoopBackOff`

**Solutions**:
```powershell
# Check pod events
kubectl describe pod -n opensearch opensearch-0

# Check logs for errors
kubectl logs -n opensearch opensearch-0

# Verify Docker Desktop has enough memory
# Settings > Resources > Memory (minimum 4GB)
```

### Memory Issues

**Issue**: Pods being OOMKilled (Out of Memory)

**Solutions**:
1. Increase Docker Desktop memory allocation
2. Reduce replica count (already at 1)
3. Check other running containers: `docker ps`

### Connection Refused

**Issue**: Cannot access services on localhost

**Solutions**:
```powershell
# Verify services are running
kubectl get svc -n opensearch

# Check if ports are exposed
kubectl get svc opensearch-external -n opensearch
kubectl get svc opensearch-dashboards-service -n opensearch

# Port forward as alternative
kubectl port-forward -n opensearch svc/opensearch-service 9200:9200
kubectl port-forward -n opensearch svc/opensearch-dashboards-service 5601:5601
```

### Persistent Volume Issues

**Issue**: PVC stuck in `Pending`

**Solutions**:
```powershell
# Check PV and PVC status
kubectl get pv,pvc -n opensearch

# Describe PVC for events
kubectl describe pvc -n opensearch opensearch-data-opensearch-0

# Ensure hostPath directory exists (Docker Desktop handles this)
```

### Slow Startup

**Issue**: Services taking too long to start

**Expected**: 2-3 minutes for full startup
- OpenSearch: ~90 seconds
- Dashboards: ~60 seconds (after OpenSearch is ready)

**Monitor**:
```powershell
# Watch pod status
kubectl get pods -n opensearch -w

# Check readiness probes
kubectl describe pod -n opensearch opensearch-0 | Select-String -Pattern "Readiness"
```

## 🧹 Cleanup

### Option 1: Using Batch Script

```batch
cd opensearch-k8s-windows\scripts
cleanup.bat
```

### Option 2: Using PowerShell Script

```powershell
cd opensearch-k8s-windows\scripts
.\cleanup.ps1
```

### Option 3: Manual Cleanup

```powershell
# Delete all resources
kubectl delete namespace opensearch

# Or delete individually (reverse order)
kubectl delete -f k8s-manifests\05-services.yaml
kubectl delete -f k8s-manifests\04-deployment-dashboards.yaml
kubectl delete -f k8s-manifests\03-statefulset.yaml
kubectl delete -f k8s-manifests\02-pvc.yaml
kubectl delete -f k8s-manifests\01-configmap.yaml
kubectl delete -f k8s-manifests\00-namespace.yaml
```

## ⚙️ Configuration Details

### Kubernetes Resources

#### Namespace
- **Name**: `opensearch`
- **Purpose**: Isolates OpenSearch resources

#### ConfigMaps
1. **opensearch-config**: OpenSearch configuration and JVM options
2. **opensearch-dashboards-config**: Dashboards configuration

#### StatefulSet (OpenSearch)
- **Replicas**: 1 (single-node cluster)
- **Image**: opensearchproject/opensearch:2.11.1
- **Storage**: 2Gi hostPath PVC
- **Ports**: 9200 (HTTP), 9300 (Transport)

#### Deployment (Dashboards)
- **Replicas**: 1
- **Image**: opensearchproject/opensearch-dashboards:2.11.1
- **Port**: 5601

#### Services
1. **opensearch-service**: ClusterIP (internal communication)
2. **opensearch-external**: NodePort 30920 (external access)
3. **opensearch-dashboards-service**: NodePort 30561 (external access)

### Environment Variables

#### OpenSearch
- `OPENSEARCH_JAVA_OPTS`: `-Xms256m -Xmx256m`
- `DISABLE_SECURITY_PLUGIN`: `true`
- `discovery.type`: `single-node`

#### Dashboards
- `OPENSEARCH_HOSTS`: `["http://opensearch-service:9200"]`
- `DISABLE_SECURITY_DASHBOARDS_PLUGIN`: `true`

### Resource Limits

```yaml
OpenSearch:
  requests:
    memory: 384Mi
    cpu: 250m
  limits:
    memory: 512Mi
    cpu: 500m

Dashboards:
  requests:
    memory: 256Mi
    cpu: 200m
  limits:
    memory: 384Mi
    cpu: 400m
```

## 📝 Notes

### Security Considerations

⚠️ **WARNING**: This setup has security disabled for local development convenience.

**For Production**:
1. Enable security plugin
2. Configure TLS/SSL
3. Set up authentication
4. Use secrets for credentials
5. Enable network policies

### Performance Tips

1. **Increase Docker Memory**: If possible, allocate 6-8GB for better performance
2. **SSD Storage**: Use SSD for Docker Desktop storage location
3. **Close Unused Apps**: Free up system resources
4. **Monitor Resources**: Use `kubectl top` to track usage

### Data Persistence

- Data is stored in hostPath volume: `/mnt/data/opensearch`
- Data persists across pod restarts
- Data is lost if PVC is deleted
- Backup important data before cleanup

## 🤝 Contributing

Feel free to submit issues, fork the repository, and create pull requests for any improvements.

## 📄 License

This project is provided as-is for educational and development purposes.

## 🔗 Useful Links

- [OpenSearch Documentation](https://opensearch.org/docs/latest/)
- [OpenSearch Dashboards](https://opensearch.org/docs/latest/dashboards/)
- [Kubernetes Documentation](https://kubernetes.io/docs/home/)
- [Docker Desktop](https://docs.docker.com/desktop/windows/)

## 📞 Support

For issues and questions:
1. Check the [Troubleshooting](#troubleshooting) section
2. Review OpenSearch logs: `kubectl logs -n opensearch -l app=opensearch`
3. Check Kubernetes events: `kubectl get events -n opensearch`

---

**Version**: 1.0.0  
**Last Updated**: April 2026  
**Tested On**: Windows 11, Docker Desktop 4.x, Kubernetes 1.28+