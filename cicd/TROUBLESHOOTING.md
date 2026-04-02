# CI/CD Troubleshooting Guide

Comprehensive troubleshooting guide for OpenSearch Kubernetes CI/CD deployments.

## 📋 Table of Contents

1. [ArgoCD Issues](#argocd-issues)
2. [GitHub Actions Issues](#github-actions-issues)
3. [Kubernetes Issues](#kubernetes-issues)
4. [OpenSearch Issues](#opensearch-issues)
5. [Network Issues](#network-issues)
6. [Performance Issues](#performance-issues)

---

## 🔧 ArgoCD Issues

### Issue: Application Not Syncing

**Symptoms:**
- Application shows "OutOfSync" status
- Changes in Git not reflected in cluster

**Diagnosis:**
```powershell
# Check application status
kubectl get application opensearch -n argocd

# View detailed status
kubectl describe application opensearch -n argocd

# Check sync status
kubectl get application opensearch -n argocd -o jsonpath='{.status.sync.status}'
```

**Solutions:**

1. **Force Refresh:**
```powershell
# Refresh application
kubectl patch application opensearch -n argocd --type merge -p '{"metadata":{"annotations":{"argocd.argoproj.io/refresh":"hard"}}}'
```

2. **Manual Sync:**
```powershell
# Trigger manual sync
kubectl patch application opensearch -n argocd --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"HEAD"}}}'
```

3. **Check Repository Connection:**
```powershell
# Verify repository is accessible
kubectl get secret -n argocd | grep repo

# Test repository connection
argocd repo list
```

### Issue: ArgoCD UI Not Accessible

**Symptoms:**
- Cannot access https://localhost:8080
- Connection refused or timeout

**Solutions:**

1. **Check ArgoCD Pods:**
```powershell
# Verify all pods are running
kubectl get pods -n argocd

# Check specific pod
kubectl describe pod argocd-server-xxx -n argocd
```

2. **Restart Port-Forward:**
```powershell
# Kill existing port-forward
Get-Process | Where-Object {$_.ProcessName -eq "kubectl" -and $_.CommandLine -like "*port-forward*argocd*"} | Stop-Process -Force

# Start new port-forward
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

3. **Check Service:**
```powershell
# Verify service exists
kubectl get svc argocd-server -n argocd

# Check service endpoints
kubectl get endpoints argocd-server -n argocd
```

### Issue: Authentication Failed

**Symptoms:**
- Cannot login to ArgoCD UI
- "Invalid username or password" error

**Solutions:**

1. **Reset Admin Password:**
```powershell
# Get current password
$ARGOCD_PASSWORD = kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }
Write-Host "Password: $ARGOCD_PASSWORD"
```

2. **Reset Password (if needed):**
```powershell
# Delete the secret to reset
kubectl -n argocd delete secret argocd-initial-admin-secret

# Restart ArgoCD server
kubectl -n argocd delete pod -l app.kubernetes.io/name=argocd-server

# Wait for new pod and get new password
Start-Sleep -Seconds 30
$ARGOCD_PASSWORD = kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }
Write-Host "New Password: $ARGOCD_PASSWORD"
```

### Issue: Sync Fails with Errors

**Symptoms:**
- Application shows "SyncFailed" status
- Error messages in sync operation

**Diagnosis:**
```powershell
# View sync errors
kubectl get application opensearch -n argocd -o jsonpath='{.status.conditions}'

# Check operation state
kubectl get application opensearch -n argocd -o jsonpath='{.status.operationState}'
```

**Solutions:**

1. **Check Resource Conflicts:**
```powershell
# View differences
argocd app diff opensearch

# Check for existing resources
kubectl get all -n opensearch
```

2. **Prune Old Resources:**
```powershell
# Enable auto-prune
kubectl patch application opensearch -n argocd --type merge -p '{"spec":{"syncPolicy":{"automated":{"prune":true}}}}'
```

3. **Check RBAC Permissions:**
```powershell
# Verify ArgoCD has permissions
kubectl auth can-i create deployment --as=system:serviceaccount:argocd:argocd-application-controller -n opensearch
```

---

## 🐙 GitHub Actions Issues

### Issue: Workflow Not Triggering

**Symptoms:**
- Push to main branch doesn't trigger workflow
- No workflow runs visible in Actions tab

**Solutions:**

1. **Check Workflow File Location:**
```powershell
# Verify file is in correct location
Test-Path .github/workflows/deploy-opensearch.yml
```

2. **Validate YAML Syntax:**
```powershell
# Use yamllint or online validator
# Check for indentation errors
```

3. **Check Branch Name:**
```yaml
# Ensure branch name matches
on:
  push:
    branches: [ main ]  # Must match your branch name
```

4. **Check Path Filters:**
```yaml
on:
  push:
    paths:
      - 'k8s-manifests/**'  # Only triggers if these files change
```

### Issue: kubectl Connection Failed

**Symptoms:**
- "Unable to connect to the server" error
- "The connection to the server was refused"

**Solutions:**

1. **Verify KUBE_CONFIG Secret:**
```powershell
# Check secret exists in GitHub
# Settings → Secrets → Actions → KUBE_CONFIG

# Verify base64 encoding is correct
$kubeconfig = Get-Content $HOME/.kube/config -Raw
$bytes = [System.Text.Encoding]::UTF8.GetBytes($kubeconfig)
$base64 = [Convert]::ToBase64String($bytes)
Write-Host $base64
```

2. **Test Locally:**
```powershell
# Decode and test
$base64 = "YOUR_BASE64_STRING"
$bytes = [Convert]::FromBase64String($base64)
$kubeconfig = [System.Text.Encoding]::UTF8.GetString($bytes)
$kubeconfig | Out-File -FilePath test-kubeconfig.yaml
$env:KUBECONFIG = "test-kubeconfig.yaml"
kubectl cluster-info
```

3. **Check Cluster Accessibility:**
```yaml
# Add debug step in workflow
- name: Debug kubectl
  run: |
    kubectl version --client
    kubectl cluster-info
    kubectl config view
```

### Issue: Deployment Timeout

**Symptoms:**
- Workflow times out waiting for pods
- "context deadline exceeded" error

**Solutions:**

1. **Increase Timeout:**
```yaml
- name: Wait for deployment
  run: |
    kubectl wait --for=condition=ready pod -l app=opensearch \
      -n opensearch --timeout=600s  # Increase from 300s
```

2. **Check Pod Status:**
```yaml
- name: Debug pods
  if: failure()
  run: |
    kubectl get pods -n opensearch
    kubectl describe pods -n opensearch
    kubectl logs -n opensearch -l app=opensearch --tail=50
```

---

## ☸️ Kubernetes Issues

### Issue: Pods Not Starting

**Symptoms:**
- Pods stuck in "Pending" or "CrashLoopBackOff"
- Pods show "ImagePullBackOff"

**Diagnosis:**
```powershell
# Check pod status
kubectl get pods -n opensearch

# Describe pod for events
kubectl describe pod opensearch-0 -n opensearch

# Check logs
kubectl logs opensearch-0 -n opensearch
```

**Solutions:**

1. **Insufficient Resources:**
```powershell
# Check node resources
kubectl top nodes

# Check pod resource requests
kubectl describe pod opensearch-0 -n opensearch | Select-String -Pattern "Requests"

# Solution: Reduce resource requests or add nodes
```

2. **Image Pull Issues:**
```powershell
# Check image name
kubectl get pod opensearch-0 -n opensearch -o jsonpath='{.spec.containers[0].image}'

# Test image pull manually
docker pull opensearchproject/opensearch:2.11.0

# Solution: Verify image exists and is accessible
```

3. **PVC Binding Issues:**
```powershell
# Check PVC status
kubectl get pvc -n opensearch

# Check PV availability
kubectl get pv

# Solution: Ensure storage class exists
kubectl get storageclass
```

### Issue: Service Not Accessible

**Symptoms:**
- Cannot connect to OpenSearch service
- Connection timeout or refused

**Diagnosis:**
```powershell
# Check service
kubectl get svc -n opensearch

# Check endpoints
kubectl get endpoints opensearch-nodeport -n opensearch

# Test from within cluster
kubectl run curl-test --image=curlimages/curl:latest --rm -i --restart=Never -- \
  curl -v http://opensearch-nodeport.opensearch:9200
```

**Solutions:**

1. **Check Service Selector:**
```powershell
# Verify service selector matches pod labels
kubectl get svc opensearch-nodeport -n opensearch -o yaml | Select-String -Pattern "selector"
kubectl get pods -n opensearch --show-labels
```

2. **Check Port Configuration:**
```powershell
# Verify ports are correct
kubectl get svc opensearch-nodeport -n opensearch -o jsonpath='{.spec.ports}'
```

3. **Test Port-Forward:**
```powershell
# Bypass service and test pod directly
kubectl port-forward pod/opensearch-0 -n opensearch 9200:9200
# Test: http://localhost:9200
```

### Issue: StatefulSet Not Updating

**Symptoms:**
- Changes to StatefulSet not applied
- Pods not recreated with new configuration

**Solutions:**

1. **Check Update Strategy:**
```powershell
# View update strategy
kubectl get statefulset opensearch -n opensearch -o jsonpath='{.spec.updateStrategy}'
```

2. **Force Update:**
```powershell
# Delete pods one by one
kubectl delete pod opensearch-0 -n opensearch
# Wait for pod to be ready
kubectl wait --for=condition=ready pod/opensearch-0 -n opensearch --timeout=300s
# Repeat for other pods
```

3. **Rolling Restart:**
```powershell
# Restart all pods
kubectl rollout restart statefulset opensearch -n opensearch
```

---

## 🔍 OpenSearch Issues

### Issue: Cluster Health Red

**Symptoms:**
- Cluster health shows "red" status
- Some indices unavailable

**Diagnosis:**
```powershell
# Check cluster health
kubectl exec -it opensearch-0 -n opensearch -- \
  curl -X GET "http://localhost:9200/_cluster/health?pretty"

# Check node status
kubectl exec -it opensearch-0 -n opensearch -- \
  curl -X GET "http://localhost:9200/_cat/nodes?v"

# Check shard allocation
kubectl exec -it opensearch-0 -n opensearch -- \
  curl -X GET "http://localhost:9200/_cat/shards?v"
```

**Solutions:**

1. **Unassigned Shards:**
```powershell
# Retry shard allocation
kubectl exec -it opensearch-0 -n opensearch -- \
  curl -X POST "http://localhost:9200/_cluster/reroute?retry_failed=true"
```

2. **Increase Replica Count:**
```powershell
# Reduce replica count if not enough nodes
kubectl exec -it opensearch-0 -n opensearch -- \
  curl -X PUT "http://localhost:9200/_settings" \
  -H 'Content-Type: application/json' \
  -d '{"index":{"number_of_replicas":1}}'
```

### Issue: Out of Memory

**Symptoms:**
- Pods restarting frequently
- "OutOfMemory" errors in logs

**Diagnosis:**
```powershell
# Check memory usage
kubectl top pods -n opensearch

# Check JVM heap usage
kubectl exec -it opensearch-0 -n opensearch -- \
  curl -X GET "http://localhost:9200/_nodes/stats/jvm?pretty"
```

**Solutions:**

1. **Increase Memory Limits:**
```yaml
spec:
  containers:
  - name: opensearch
    resources:
      limits:
        memory: "4Gi"  # Increase from 2Gi
      requests:
        memory: "2Gi"
```

2. **Adjust JVM Heap:**
```yaml
env:
- name: OPENSEARCH_JAVA_OPTS
  value: "-Xms2g -Xmx2g"  # Increase heap size
```

### Issue: Slow Query Performance

**Symptoms:**
- Queries taking too long
- High CPU usage

**Diagnosis:**
```powershell
# Check slow queries
kubectl exec -it opensearch-0 -n opensearch -- \
  curl -X GET "http://localhost:9200/_nodes/stats/indices/search?pretty"

# Check thread pool
kubectl exec -it opensearch-0 -n opensearch -- \
  curl -X GET "http://localhost:9200/_cat/thread_pool?v"
```

**Solutions:**

1. **Optimize Indices:**
```powershell
# Force merge indices
kubectl exec -it opensearch-0 -n opensearch -- \
  curl -X POST "http://localhost:9200/_forcemerge?max_num_segments=1"
```

2. **Increase Resources:**
```yaml
resources:
  limits:
    cpu: "2000m"  # Increase CPU
```

---

## 🌐 Network Issues

### Issue: DNS Resolution Failed

**Symptoms:**
- "no such host" errors
- Cannot resolve service names

**Diagnosis:**
```powershell
# Test DNS from pod
kubectl exec -it opensearch-0 -n opensearch -- nslookup opensearch-nodeport.opensearch.svc.cluster.local

# Check CoreDNS
kubectl get pods -n kube-system -l k8s-app=kube-dns
```

**Solutions:**

1. **Restart CoreDNS:**
```powershell
kubectl rollout restart deployment coredns -n kube-system
```

2. **Check DNS Config:**
```powershell
kubectl get configmap coredns -n kube-system -o yaml
```

### Issue: Network Policy Blocking Traffic

**Symptoms:**
- Connections timing out
- "Connection refused" from within cluster

**Diagnosis:**
```powershell
# Check network policies
kubectl get networkpolicy -n opensearch

# Describe policy
kubectl describe networkpolicy -n opensearch
```

**Solutions:**

1. **Temporarily Disable:**
```powershell
# Delete network policy for testing
kubectl delete networkpolicy opensearch-network-policy -n opensearch
```

2. **Update Policy:**
```yaml
# Allow traffic from specific namespace
spec:
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: allowed-namespace
```

---

## ⚡ Performance Issues

### Issue: High Latency

**Symptoms:**
- Slow response times
- Timeouts

**Diagnosis:**
```powershell
# Check pod resources
kubectl top pods -n opensearch

# Check node resources
kubectl top nodes

# Check OpenSearch stats
kubectl exec -it opensearch-0 -n opensearch -- \
  curl -X GET "http://localhost:9200/_nodes/stats?pretty"
```

**Solutions:**

1. **Scale Horizontally:**
```powershell
# Increase replicas
kubectl scale statefulset opensearch -n opensearch --replicas=5
```

2. **Optimize Queries:**
```powershell
# Enable slow log
kubectl exec -it opensearch-0 -n opensearch -- \
  curl -X PUT "http://localhost:9200/_cluster/settings" \
  -H 'Content-Type: application/json' \
  -d '{"transient":{"logger.index.search.slowlog":"DEBUG"}}'
```

---

## 🆘 Emergency Procedures

### Complete Cluster Failure

```powershell
# 1. Check all components
kubectl get all -n opensearch
kubectl get all -n argocd

# 2. Check events
kubectl get events -n opensearch --sort-by='.lastTimestamp'

# 3. Collect logs
kubectl logs -n opensearch -l app=opensearch --tail=100 > opensearch-logs.txt

# 4. Restore from backup
kubectl apply -f opensearch-backup.yaml

# 5. Verify restoration
kubectl get pods -n opensearch -w
```

### Rollback Deployment

```powershell
# Using ArgoCD
argocd app history opensearch
argocd app rollback opensearch <revision-id>

# Using kubectl
kubectl rollout undo statefulset opensearch -n opensearch
kubectl rollout status statefulset opensearch -n opensearch
```

---

## 📞 Getting Help

### Collect Debug Information

```powershell
# Create debug bundle
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$debugDir = "opensearch-debug-$timestamp"
New-Item -ItemType Directory -Path $debugDir

# Collect information
kubectl get all -n opensearch -o yaml > "$debugDir/resources.yaml"
kubectl describe pods -n opensearch > "$debugDir/pods-describe.txt"
kubectl logs -n opensearch -l app=opensearch --tail=500 > "$debugDir/logs.txt"
kubectl get events -n opensearch --sort-by='.lastTimestamp' > "$debugDir/events.txt"
kubectl top pods -n opensearch > "$debugDir/resources-usage.txt"

# Compress
Compress-Archive -Path $debugDir -DestinationPath "$debugDir.zip"
Write-Host "Debug bundle created: $debugDir.zip"
```

### Support Channels

- GitHub Issues: [Repository Issues](https://github.com/YOUR-REPO/issues)
- OpenSearch Forum: https://forum.opensearch.org/
- Kubernetes Slack: https://kubernetes.slack.com/
- ArgoCD Slack: https://argoproj.github.io/community/join-slack/

---

**Made with ❤️ for Troubleshooting Success**