# OpenSearch Kubernetes Architecture

## Overview

This document provides detailed information about the Kubernetes architecture for OpenSearch and OpenSearch Dashboards deployment on Windows.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Windows Host System                          │
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                    Docker Desktop (4GB RAM)                  │   │
│  │                                                               │   │
│  │  ┌─────────────────────────────────────────────────────┐    │   │
│  │  │              Kubernetes Cluster                      │    │   │
│  │  │                                                       │    │   │
│  │  │  ┌─────────────────────────────────────────────┐    │    │   │
│  │  │  │      Namespace: opensearch                   │    │    │   │
│  │  │  │                                               │    │    │   │
│  │  │  │  ┌────────────────────────────────────┐     │    │    │   │
│  │  │  │  │     ConfigMaps                     │     │    │    │   │
│  │  │  │  │  - opensearch-config               │     │    │    │   │
│  │  │  │  │  - opensearch-dashboards-config    │     │    │    │   │
│  │  │  │  └────────────────────────────────────┘     │    │    │   │
│  │  │  │                                               │    │    │   │
│  │  │  │  ┌────────────────────────────────────┐     │    │    │   │
│  │  │  │  │   StatefulSet: opensearch          │     │    │    │   │
│  │  │  │  │   Replicas: 1                      │     │    │    │   │
│  │  │  │  │   ┌──────────────────────────┐     │     │    │    │   │
│  │  │  │  │   │  Pod: opensearch-0       │     │     │    │    │   │
│  │  │  │  │   │  Image: opensearch:2.11.1│     │     │    │    │   │
│  │  │  │  │   │  Memory: 384Mi/512Mi     │     │     │    │    │   │
│  │  │  │  │   │  CPU: 250m/500m          │     │     │    │    │   │
│  │  │  │  │   │  JVM Heap: 256MB         │     │     │    │    │   │
│  │  │  │  │   │  Ports: 9200, 9300       │     │     │    │    │   │
│  │  │  │  │   └──────────┬───────────────┘     │     │    │    │   │
│  │  │  │  │              │                      │     │    │    │   │
│  │  │  │  │              ▼                      │     │    │    │   │
│  │  │  │  │   ┌──────────────────────────┐     │     │    │    │   │
│  │  │  │  │   │  PVC: opensearch-data    │     │     │    │    │   │
│  │  │  │  │   │  Size: 2Gi               │     │     │    │    │   │
│  │  │  │  │   │  StorageClass: hostpath  │     │     │    │    │   │
│  │  │  │  │   └──────────────────────────┘     │     │    │    │   │
│  │  │  │  └────────────────────────────────────┘     │    │    │   │
│  │  │  │                                               │    │    │   │
│  │  │  │  ┌────────────────────────────────────┐     │    │    │   │
│  │  │  │  │   Deployment: dashboards           │     │    │    │   │
│  │  │  │  │   Replicas: 1                      │     │    │    │   │
│  │  │  │  │   ┌──────────────────────────┐     │     │    │    │   │
│  │  │  │  │   │  Pod: dashboards-xxx     │     │     │    │    │   │
│  │  │  │  │   │  Image: dashboards:2.11.1│     │     │    │    │   │
│  │  │  │  │   │  Memory: 256Mi/384Mi     │     │     │    │    │   │
│  │  │  │  │   │  CPU: 200m/400m          │     │     │    │    │   │
│  │  │  │  │   │  Port: 5601              │     │     │    │    │   │
│  │  │  │  │   └──────────────────────────┘     │     │    │    │   │
│  │  │  │  └────────────────────────────────────┘     │    │    │   │
│  │  │  │                                               │    │    │   │
│  │  │  │  ┌────────────────────────────────────┐     │    │    │   │
│  │  │  │  │   Services                         │     │    │    │   │
│  │  │  │  │                                     │     │    │    │   │
│  │  │  │  │   opensearch-service (ClusterIP)   │     │    │    │   │
│  │  │  │  │   └─> 9200, 9300                   │     │    │    │   │
│  │  │  │  │                                     │     │    │    │   │
│  │  │  │  │   opensearch-external (NodePort)   │     │    │    │   │
│  │  │  │  │   └─> 30920 → 9200                 │     │    │    │   │
│  │  │  │  │                                     │     │    │    │   │
│  │  │  │  │   dashboards-service (NodePort)    │     │    │    │   │
│  │  │  │  │   └─> 30561 → 5601                 │     │    │    │   │
│  │  │  │  └────────────────────────────────────┘     │    │    │   │
│  │  │  └─────────────────────────────────────────────┘    │    │   │
│  │  └─────────────────────────────────────────────────────┘    │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                       │
│  localhost:30920 ◄──────────────────────────────────────────────┐  │
│  localhost:30561 ◄──────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

## Components

### 1. Namespace

**Resource**: `00-namespace.yaml`

- **Name**: `opensearch`
- **Purpose**: Logical isolation of OpenSearch resources
- **Labels**: 
  - `name: opensearch`
  - `environment: local`

### 2. ConfigMaps

**Resource**: `01-configmap.yaml`

#### opensearch-config
Contains two configuration files:

**opensearch.yml**:
- Cluster name: `opensearch-cluster`
- Discovery type: `single-node` (no cluster formation overhead)
- Security: Disabled for local development
- ML features: Disabled to save memory
- Thread pools: Optimized for low memory

**jvm.options**:
- Heap size: `-Xms256m -Xmx256m`
- GC: G1GC with optimized settings
- Metaspace: Limited to 128MB
- GC logging enabled

#### opensearch-dashboards-config
Contains dashboard configuration:

**opensearch_dashboards.yml**:
- Server host: `0.0.0.0`
- OpenSearch connection: `http://opensearch-service:9200`
- Security: Disabled
- Logging: Quiet mode for reduced overhead

### 3. Persistent Storage

**Resource**: `02-pvc.yaml`

#### PersistentVolume
- **Name**: `opensearch-pv`
- **Capacity**: 2Gi
- **Access Mode**: ReadWriteOnce
- **Storage Class**: hostpath
- **Path**: `/mnt/data/opensearch`
- **Reclaim Policy**: Retain

#### PersistentVolumeClaim
- **Name**: `opensearch-data`
- **Request**: 2Gi
- **Access Mode**: ReadWriteOnce
- **Storage Class**: hostpath

### 4. StatefulSet (OpenSearch)

**Resource**: `03-statefulset.yaml`

#### Specifications
- **Replicas**: 1
- **Service Name**: `opensearch-service`
- **Image**: `opensearchproject/opensearch:2.11.1`

#### Init Containers
1. **increase-vm-max-map**: Sets `vm.max_map_count=262144`
2. **increase-fd-ulimit**: Increases file descriptor limit

#### Main Container
**Resource Requests**:
- Memory: 384Mi
- CPU: 250m

**Resource Limits**:
- Memory: 512Mi
- CPU: 500m

**Ports**:
- 9200: HTTP API
- 9300: Transport (cluster communication)

**Environment Variables**:
- `OPENSEARCH_JAVA_OPTS`: `-Xms256m -Xmx256m`
- `DISABLE_SECURITY_PLUGIN`: `true`
- `discovery.type`: `single-node`

**Volume Mounts**:
- Data: `/usr/share/opensearch/data`
- Config: `/usr/share/opensearch/config/opensearch.yml`
- JVM Options: `/usr/share/opensearch/config/jvm.options`

**Probes**:
- **Liveness**: TCP check on port 9200
  - Initial delay: 60s
  - Period: 10s
- **Readiness**: HTTP GET `/_cluster/health`
  - Initial delay: 30s
  - Period: 10s

### 5. Deployment (Dashboards)

**Resource**: `04-deployment-dashboards.yaml`

#### Specifications
- **Replicas**: 1
- **Image**: `opensearchproject/opensearch-dashboards:2.11.1`

#### Container
**Resource Requests**:
- Memory: 256Mi
- CPU: 200m

**Resource Limits**:
- Memory: 384Mi
- CPU: 400m

**Port**:
- 5601: HTTP UI

**Environment Variables**:
- `OPENSEARCH_HOSTS`: `["http://opensearch-service:9200"]`
- `DISABLE_SECURITY_DASHBOARDS_PLUGIN`: `true`

**Volume Mounts**:
- Config: `/usr/share/opensearch-dashboards/config/opensearch_dashboards.yml`

**Probes**:
- **Liveness**: HTTP GET `/api/status`
  - Initial delay: 60s
  - Period: 10s
- **Readiness**: HTTP GET `/api/status`
  - Initial delay: 30s
  - Period: 10s

### 6. Services

**Resource**: `05-services.yaml`

#### opensearch-service (ClusterIP)
- **Type**: ClusterIP (Headless)
- **Ports**: 9200 (HTTP), 9300 (Transport)
- **Purpose**: Internal cluster communication
- **ClusterIP**: None (headless service)

#### opensearch-external (NodePort)
- **Type**: NodePort
- **Port**: 9200
- **NodePort**: 30920
- **Purpose**: External API access

#### opensearch-dashboards-service (NodePort)
- **Type**: NodePort
- **Port**: 5601
- **NodePort**: 30561
- **Purpose**: External UI access

## Resource Allocation

### Total Memory Usage

| Component | Request | Limit | Actual Usage (Typical) |
|-----------|---------|-------|------------------------|
| OpenSearch | 384Mi | 512Mi | ~350-400Mi |
| Dashboards | 256Mi | 384Mi | ~200-250Mi |
| **Total** | **640Mi** | **896Mi** | **~550-650Mi** |

### Memory Breakdown (OpenSearch)

```
Total Container Memory: 384Mi
├── JVM Heap: 256MB (67%)
├── Metaspace: ~64MB (17%)
├── Direct Memory: ~32MB (8%)
└── Native Memory: ~32MB (8%)
```

### CPU Allocation

| Component | Request | Limit | Usage Pattern |
|-----------|---------|-------|---------------|
| OpenSearch | 250m | 500m | Burst during indexing |
| Dashboards | 200m | 400m | Steady state |

## Network Flow

### Internal Communication
```
Dashboards Pod → opensearch-service:9200 → OpenSearch Pod
```

### External Access
```
Browser → localhost:30561 → NodePort Service → Dashboards Pod
Client → localhost:30920 → NodePort Service → OpenSearch Pod
```

## Storage Architecture

### Data Persistence
```
OpenSearch Pod
    ↓
PVC (opensearch-data-opensearch-0)
    ↓
PV (opensearch-pv)
    ↓
HostPath (/mnt/data/opensearch)
    ↓
Docker Desktop Volume
    ↓
Windows Host Filesystem
```

### Storage Characteristics
- **Type**: hostPath (local storage)
- **Size**: 2Gi
- **Access**: ReadWriteOnce
- **Persistence**: Survives pod restarts
- **Backup**: Manual (data in Docker Desktop volume)

## Optimization Strategies

### 1. Memory Optimization
- **JVM Heap**: 256MB (50% of container memory)
- **G1GC**: Optimized for low-latency, small heap
- **Metaspace**: Limited to 128MB
- **Thread Pools**: Reduced queue sizes

### 2. CPU Optimization
- **Requests**: Conservative (250m/200m)
- **Limits**: Allow bursting (500m/400m)
- **Single Node**: No cluster coordination overhead

### 3. Storage Optimization
- **Size**: 2Gi (sufficient for local development)
- **Type**: hostPath (fastest for local)
- **Reclaim**: Retain (data preserved)

### 4. Network Optimization
- **Headless Service**: Direct pod communication
- **NodePort**: Simple external access
- **No Ingress**: Reduced complexity

## Scaling Considerations

### Current Setup (Single Node)
- **Pros**: 
  - Minimal memory footprint
  - No cluster overhead
  - Simple configuration
  - Fast startup

- **Cons**:
  - No high availability
  - No horizontal scaling
  - Single point of failure

### Multi-Node Scaling (Future)
To scale to multiple nodes:

1. **Increase Docker Memory**: 8GB minimum
2. **Update StatefulSet**: Set replicas to 3
3. **Change Discovery**: Use `zen` discovery
4. **Add Master Nodes**: Configure master-eligible nodes
5. **Update Resources**: Increase memory/CPU per pod

## Security Considerations

### Current State (Development)
- ✗ Security plugin disabled
- ✗ No authentication
- ✗ No TLS/SSL
- ✗ No network policies
- ✗ Privileged init containers

### Production Recommendations
- ✓ Enable security plugin
- ✓ Configure authentication (LDAP/SAML)
- ✓ Enable TLS for all communication
- ✓ Implement network policies
- ✓ Use secrets for credentials
- ✓ Remove privileged containers
- ✓ Enable audit logging

## Monitoring and Observability

### Built-in Monitoring
- **Liveness Probes**: Detect pod failures
- **Readiness Probes**: Control traffic routing
- **Resource Limits**: Prevent resource exhaustion

### Additional Monitoring (Optional)
- **Metrics Server**: `kubectl top pods`
- **Prometheus**: Scrape OpenSearch metrics
- **Grafana**: Visualize metrics
- **ELK Stack**: Centralized logging

## Troubleshooting Architecture

### Common Issues

1. **Pod Pending**
   - Check: PVC binding
   - Check: Resource availability
   - Check: Node capacity

2. **Pod CrashLoopBackOff**
   - Check: Init container logs
   - Check: Memory limits
   - Check: Configuration errors

3. **Service Unreachable**
   - Check: Pod readiness
   - Check: Service endpoints
   - Check: NodePort availability

## Performance Tuning

### JVM Tuning
```
-Xms256m -Xmx256m              # Fixed heap size
-XX:+UseG1GC                   # G1 garbage collector
-XX:G1ReservePercent=25        # Reserve 25% for G1
-XX:InitiatingHeapOccupancyPercent=30  # GC threshold
-XX:MaxMetaspaceSize=128m      # Limit metaspace
```

### OpenSearch Tuning
```yaml
thread_pool.write.queue_size: 200    # Reduce write queue
thread_pool.search.queue_size: 500   # Reduce search queue
node.ml: false                        # Disable ML
bootstrap.memory_lock: false          # Don't lock memory
```

## Deployment Workflow

```
1. Create Namespace
   ↓
2. Apply ConfigMaps
   ↓
3. Create PV/PVC
   ↓
4. Deploy StatefulSet (OpenSearch)
   ↓
   Wait for OpenSearch Ready
   ↓
5. Deploy Dashboards
   ↓
6. Create Services
   ↓
7. Verify Deployment
```

## Cleanup Workflow

```
1. Delete Services
   ↓
2. Delete Dashboards Deployment
   ↓
3. Delete OpenSearch StatefulSet
   ↓
4. Delete PVC (data preserved if Retain)
   ↓
5. Delete ConfigMaps
   ↓
6. Delete Namespace
```

---

**Document Version**: 1.0  
**Last Updated**: April 2026  
**Architecture Version**: Single-Node Development