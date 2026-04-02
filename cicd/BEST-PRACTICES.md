# CI/CD Best Practices for OpenSearch Kubernetes Deployment

Comprehensive guide to production-ready CI/CD practices for OpenSearch on Kubernetes.

## 📋 Table of Contents

1. [GitOps Principles](#gitops-principles)
2. [Security Best Practices](#security-best-practices)
3. [Deployment Strategies](#deployment-strategies)
4. [Testing Strategy](#testing-strategy)
5. [Monitoring & Observability](#monitoring--observability)
6. [Disaster Recovery](#disaster-recovery)
7. [Performance Optimization](#performance-optimization)

---

## 🔄 GitOps Principles

### 1. Git as Single Source of Truth

**DO:**
```yaml
# Store all configurations in Git
k8s-manifests/
├── 00-namespace.yaml
├── 01-configmap.yaml
├── 02-pvc.yaml
├── 03-statefulset.yaml
├── 04-deployment-dashboards.yaml
└── 05-services.yaml
```

**DON'T:**
```powershell
# Avoid manual kubectl commands in production
kubectl edit deployment opensearch  # ❌ Changes not tracked
kubectl scale statefulset opensearch --replicas=5  # ❌ Not in Git
```

### 2. Declarative Configuration

**DO:**
```yaml
# Use declarative YAML
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: opensearch
spec:
  replicas: 3
  # ... full specification
```

**DON'T:**
```powershell
# Avoid imperative commands
kubectl create deployment opensearch --image=opensearch:latest  # ❌
```

### 3. Immutable Infrastructure

**DO:**
```yaml
# Version everything
spec:
  containers:
  - name: opensearch
    image: opensearchproject/opensearch:2.11.0  # ✅ Specific version
```

**DON'T:**
```yaml
# Avoid mutable tags
spec:
  containers:
  - name: opensearch
    image: opensearchproject/opensearch:latest  # ❌ Unpredictable
```

### 4. Environment Separation

```
Repository Structure:
├── k8s-manifests/
│   ├── base/              # Common configs
│   ├── overlays/
│   │   ├── dev/          # Development
│   │   ├── staging/      # Staging
│   │   └── prod/         # Production
```

---

## 🔐 Security Best Practices

### 1. Secret Management

**DO: Use Kubernetes Secrets**
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: opensearch-credentials
type: Opaque
stringData:
  admin-password: "changeme"  # ✅ In cluster only
```

**DO: Use External Secret Managers**
```yaml
# Using External Secrets Operator
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: opensearch-credentials
spec:
  secretStoreRef:
    name: aws-secrets-manager
  target:
    name: opensearch-credentials
  data:
  - secretKey: admin-password
    remoteRef:
      key: opensearch/admin-password
```

**DON'T: Commit Secrets to Git**
```yaml
# ❌ NEVER do this
apiVersion: v1
kind: Secret
metadata:
  name: opensearch-credentials
stringData:
  admin-password: "MySecretPassword123"  # ❌ Exposed in Git
```

### 2. RBAC Configuration

**Principle of Least Privilege:**
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: opensearch-deployer
  namespace: opensearch
rules:
- apiGroups: ["apps"]
  resources: ["statefulsets", "deployments"]
  verbs: ["get", "list", "watch", "create", "update", "patch"]
- apiGroups: [""]
  resources: ["services", "configmaps"]
  verbs: ["get", "list", "watch", "create", "update", "patch"]
# No delete permissions for safety
```

### 3. Image Security

**DO:**
```yaml
# Use specific versions and scan images
spec:
  containers:
  - name: opensearch
    image: opensearchproject/opensearch:2.11.0@sha256:abc123...  # ✅ Digest pinning
    imagePullPolicy: IfNotPresent
    securityContext:
      runAsNonRoot: true
      runAsUser: 1000
      readOnlyRootFilesystem: true
```

**Scan Images:**
```powershell
# Use Trivy for vulnerability scanning
trivy image opensearchproject/opensearch:2.11.0
```

### 4. Network Policies

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: opensearch-network-policy
  namespace: opensearch
spec:
  podSelector:
    matchLabels:
      app: opensearch
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: opensearch
    ports:
    - protocol: TCP
      port: 9200
    - protocol: TCP
      port: 9300
```

---

## 🚀 Deployment Strategies

### 1. Rolling Update (Default)

**Best for:** Most deployments, minimal risk

```yaml
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1        # Max pods above desired count
      maxUnavailable: 0  # Ensure availability
```

**Pros:**
- ✅ Zero downtime
- ✅ Gradual rollout
- ✅ Easy rollback

**Cons:**
- ⚠️ Mixed versions during rollout
- ⚠️ Slower than recreate

### 2. Blue-Green Deployment

**Best for:** Critical updates, instant rollback needed

```yaml
# Blue (current)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: opensearch-blue
  labels:
    version: blue
spec:
  replicas: 3
  selector:
    matchLabels:
      app: opensearch
      version: blue

---
# Green (new)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: opensearch-green
  labels:
    version: green
spec:
  replicas: 3
  selector:
    matchLabels:
      app: opensearch
      version: green

---
# Service switches between blue and green
apiVersion: v1
kind: Service
metadata:
  name: opensearch
spec:
  selector:
    app: opensearch
    version: blue  # Switch to 'green' when ready
```

**Pros:**
- ✅ Instant rollback
- ✅ No mixed versions
- ✅ Full testing before switch

**Cons:**
- ⚠️ Requires 2x resources
- ⚠️ More complex

### 3. Canary Deployment

**Best for:** High-risk changes, gradual validation

```yaml
# Main deployment (90%)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: opensearch-stable
spec:
  replicas: 9

---
# Canary deployment (10%)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: opensearch-canary
spec:
  replicas: 1
  template:
    metadata:
      labels:
        version: canary
```

**Deployment Process:**
```powershell
# 1. Deploy canary (10%)
kubectl apply -f opensearch-canary.yaml

# 2. Monitor metrics for 30 minutes
# Check error rates, latency, etc.

# 3. If successful, increase canary
kubectl scale deployment opensearch-canary --replicas=3  # 30%

# 4. Continue monitoring

# 5. Full rollout
kubectl scale deployment opensearch-canary --replicas=10
kubectl scale deployment opensearch-stable --replicas=0
```

**Pros:**
- ✅ Risk mitigation
- ✅ Real traffic testing
- ✅ Gradual rollout

**Cons:**
- ⚠️ Complex monitoring
- ⚠️ Longer deployment time

---

## 🧪 Testing Strategy

### Testing Pyramid

```
        ┌─────────────┐
        │  E2E Tests  │  (Few, Slow, Expensive)
        ├─────────────┤
        │ Integration │  (Some, Medium)
        ├─────────────┤
        │ Unit Tests  │  (Many, Fast, Cheap)
        └─────────────┘
```

### 1. Pre-Deployment Validation

```yaml
# GitHub Actions example
jobs:
  validate:
    steps:
      - name: YAML Syntax Check
        run: |
          for file in k8s-manifests/*.yaml; do
            kubectl apply --dry-run=client -f "$file"
          done
      
      - name: Kubeval Validation
        run: |
          kubeval k8s-manifests/*.yaml
      
      - name: Security Scan
        run: |
          kubesec scan k8s-manifests/*.yaml
```

### 2. Smoke Tests

```powershell
# Post-deployment smoke tests
function Test-OpenSearchHealth {
    $response = Invoke-WebRequest -Uri "http://localhost:9200/_cluster/health" -UseBasicParsing
    $health = $response.Content | ConvertFrom-Json
    
    if ($health.status -ne "green") {
        throw "Cluster health is $($health.status)"
    }
    
    Write-Host "✅ Cluster health: $($health.status)"
}

# Run after deployment
Test-OpenSearchHealth
```

### 3. Integration Tests

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: opensearch-integration-test
spec:
  template:
    spec:
      containers:
      - name: test
        image: curlimages/curl:latest
        command:
        - /bin/sh
        - -c
        - |
          # Test cluster health
          curl -f http://opensearch:9200/_cluster/health || exit 1
          
          # Test index creation
          curl -X PUT http://opensearch:9200/test-index || exit 1
          
          # Test document indexing
          curl -X POST http://opensearch:9200/test-index/_doc \
            -H 'Content-Type: application/json' \
            -d '{"test": "data"}' || exit 1
          
          # Cleanup
          curl -X DELETE http://opensearch:9200/test-index
      restartPolicy: Never
```

---

## 📊 Monitoring & Observability

### 1. Health Checks

```yaml
spec:
  containers:
  - name: opensearch
    livenessProbe:
      httpGet:
        path: /_cluster/health
        port: 9200
      initialDelaySeconds: 60
      periodSeconds: 10
      timeoutSeconds: 5
      failureThreshold: 3
    
    readinessProbe:
      httpGet:
        path: /_cluster/health
        port: 9200
      initialDelaySeconds: 30
      periodSeconds: 5
      timeoutSeconds: 3
      successThreshold: 1
```

### 2. Logging Strategy

```yaml
# Structured logging
spec:
  containers:
  - name: opensearch
    env:
    - name: OPENSEARCH_JAVA_OPTS
      value: "-Xms512m -Xmx512m"
    - name: LOG_LEVEL
      value: "INFO"  # DEBUG for troubleshooting
```

**Centralized Logging:**
```powershell
# View logs from all pods
kubectl logs -n opensearch -l app=opensearch --tail=100 -f

# Export logs
kubectl logs -n opensearch -l app=opensearch --since=1h > opensearch-logs.txt
```

### 3. Metrics Collection

```yaml
# Prometheus ServiceMonitor
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: opensearch
  namespace: opensearch
spec:
  selector:
    matchLabels:
      app: opensearch
  endpoints:
  - port: metrics
    interval: 30s
```

### 4. Alerting Rules

```yaml
# PrometheusRule example
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: opensearch-alerts
spec:
  groups:
  - name: opensearch
    rules:
    - alert: OpenSearchClusterRed
      expr: opensearch_cluster_health_status{color="red"} == 1
      for: 5m
      annotations:
        summary: "OpenSearch cluster is RED"
    
    - alert: OpenSearchHighMemory
      expr: opensearch_jvm_mem_heap_used_percent > 90
      for: 10m
      annotations:
        summary: "OpenSearch memory usage > 90%"
```

---

## 💾 Disaster Recovery

### 1. Backup Strategy

```yaml
# Snapshot repository configuration
apiVersion: batch/v1
kind: CronJob
metadata:
  name: opensearch-backup
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: curlimages/curl:latest
            command:
            - /bin/sh
            - -c
            - |
              # Create snapshot
              curl -X PUT "http://opensearch:9200/_snapshot/backup/snapshot_$(date +%Y%m%d)" \
                -H 'Content-Type: application/json' \
                -d '{"indices": "*", "include_global_state": true}'
          restartPolicy: OnFailure
```

### 2. Restore Procedure

```powershell
# List available snapshots
kubectl exec -it opensearch-0 -n opensearch -- \
  curl -X GET "http://localhost:9200/_snapshot/backup/_all"

# Restore from snapshot
kubectl exec -it opensearch-0 -n opensearch -- \
  curl -X POST "http://localhost:9200/_snapshot/backup/snapshot_20260402/_restore" \
  -H 'Content-Type: application/json' \
  -d '{"indices": "*", "include_global_state": true}'
```

### 3. Configuration Backup

```powershell
# Backup all Kubernetes resources
kubectl get all,configmap,secret,pvc -n opensearch -o yaml > opensearch-backup.yaml

# Store in version control or secure location
git add opensearch-backup.yaml
git commit -m "Backup: $(Get-Date -Format 'yyyy-MM-dd')"
```

---

## ⚡ Performance Optimization

### 1. Resource Limits

```yaml
spec:
  containers:
  - name: opensearch
    resources:
      requests:
        memory: "2Gi"
        cpu: "1000m"
      limits:
        memory: "4Gi"
        cpu: "2000m"
```

### 2. Pod Disruption Budget

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: opensearch-pdb
  namespace: opensearch
spec:
  minAvailable: 2  # Ensure at least 2 pods always available
  selector:
    matchLabels:
      app: opensearch
```

### 3. Horizontal Pod Autoscaling

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: opensearch-hpa
  namespace: opensearch
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: StatefulSet
    name: opensearch
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

---

## 📝 Documentation Standards

### 1. README Requirements

Every deployment should have:
- Purpose and overview
- Prerequisites
- Installation steps
- Configuration options
- Troubleshooting guide
- Contact information

### 2. Change Management

```markdown
## Changelog

### [2.11.0] - 2026-04-02
#### Added
- ArgoCD GitOps deployment
- Automated backup CronJob

#### Changed
- Updated OpenSearch to 2.11.0
- Increased memory limits

#### Fixed
- Pod disruption budget configuration
```

### 3. Runbooks

Create runbooks for common scenarios:
- Deployment procedure
- Rollback procedure
- Scaling procedure
- Disaster recovery
- Troubleshooting steps

---

## ✅ Checklist for Production

Before going to production, ensure:

- [ ] All secrets are managed securely (not in Git)
- [ ] RBAC is configured with least privilege
- [ ] Resource limits are set appropriately
- [ ] Health checks are configured
- [ ] Monitoring and alerting are set up
- [ ] Backup strategy is implemented
- [ ] Disaster recovery plan is documented
- [ ] Pod disruption budgets are configured
- [ ] Network policies are in place
- [ ] Images are scanned for vulnerabilities
- [ ] Testing strategy is implemented
- [ ] Documentation is complete
- [ ] Runbooks are created
- [ ] Team is trained on procedures

---

**Made with ❤️ for Production Excellence**