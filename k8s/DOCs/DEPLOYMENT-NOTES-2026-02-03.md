# HomeLab FluxCD - Deployment Notes - 3 február 2026

## Summary
Successfully deployed Grafana and Prometheus monitoring stack with MetalLB load balancing support for the Kubernetes cluster.

## Deployments Completed

### 1. **Prometheus Stack** (`k8s/infra/Prometheus/`)
- **Chart**: kube-prometheus-stack v58.7.2
- **Components**:
  - Prometheus (metrics database)
  - AlertManager
  - Node Exporter (hardware metrics)
  - Kube State Metrics (Kubernetes metrics)
- **Storage**: emptyDir (no persistent storage - temporary)
- **Resources**:
  - Prometheus: 100m/512Mi requests, 500m/1024Mi limits
  - AlertManager: 50m/128Mi requests, 200m/256Mi limits

### 2. **Grafana** (`k8s/apps/grafana/`)
- **Chart**: grafana v7.3.12
- **Features**:
  - Prometheus datasource pre-configured
  - 2 pre-loaded dashboards (Kubernetes Cluster, Node Exporter)
  - Custom "Node CPU and Memory Monitoring" dashboard
  - LoadBalancer service (via MetalLB)
  - Traefik ingress (for DNS-based access)
- **Storage**: emptyDir (no persistence - lab environment)
- **Default Credentials**: admin/changeme ⚠️ (CHANGE IN PRODUCTION)
- **Access**:
  - LoadBalancer IP: `192.168.0.220`
  - Traefik Ingress: `grafana.lab.local`

### 3. **MetalLB** (`k8s/infra/MetalLB/`)
- **Version**: metallb-native
- **Mode**: L2 Advertisement
- **IP Pool**: `192.168.0.220-192.168.0.250`
- **Status**: ✅ Active, assigning external IPs

### 4. **Custom Dashboard**
- **File**: `k8s/apps/grafana/dashboard-configmap.yaml`
- **Panels**:
  - Node CPU Usage (per node, time series)
  - Node Memory Usage (per node, time series)
  - Cluster Average CPU Usage (gauge)
  - Cluster Average Memory Usage (gauge)
- **Thresholds**:
  - Green: < 50%
  - Yellow: 50-80%
  - Red: > 80%

## Issues Encountered & Resolved

### Issue 1: Grafana Pod Pending (PVC)
**Problem**: Grafana pod stuck in Pending state - no storage class available for PVC
```
0/3 nodes are available: pod has unbound immediate PersistentVolumeClaims
```

**Solution**: Disabled persistence in Helm values
- Changed from: `persistence.enabled: true` with 5Gi PVC
- Changed to: `persistence.enabled: false`
- Result: Pod successfully running

### Issue 2: LoadBalancer Service Not Appearing
**Problem**: MetalLB not deployed, LoadBalancer service showed `<pending>` external IP

**Solution**: 
1. Applied official MetalLB manifest directly:
   ```bash
   kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/main/config/manifests/metallb-native.yaml
   ```
2. Configured IP pool via ConfigMap
3. Result: LoadBalancer assigned IP `192.168.0.220`

### Issue 3: Plugin Error in Grafana
**Error Message**: "Failed to get list of plugins", plugin connection errors to Prometheus

**Root Cause**: Prometheus pod was pending due to PVC issue
- Grafana couldn't connect to Prometheus at `kube-prometheus-stack-prometheus.prometheus.svc.cluster.local:9090`
- Connection refused with `dial tcp 10.103.95.94:9090: connect: operation not permitted`

**Solution**:
1. Fixed Prometheus storage - changed from PVC to `emptyDir: {}` 
2. Updated HelmRelease and restarted Prometheus pod
3. Verified connectivity from Grafana: ✅
4. Restarted Grafana pod to clear plugin cache
5. Result: All plugins now loading successfully

## Current Status

| Component | Pod Status | Service | External Access |
|-----------|-----------|---------|-----------------|
| Prometheus | 2/2 Running ✅ | 10.103.95.94:9090 | Internal only |
| Grafana | 1/1 Running ✅ | LoadBalancer | 192.168.0.220:80 |
| AlertManager | 2/2 Running ✅ | 10.97.107.86:9093 | Internal only |
| Node Exporter | 3/3 Running ✅ | 10.105.252.248:9100 | Internal only |
| MetalLB | 1 controller + 3 speakers ✅ | Active | N/A |

## Commands for Verification

```bash
# Check all services
kubectl get svc -n prometheus
kubectl get svc -n grafana

# Access Grafana
# Option 1: Via LoadBalancer IP
http://192.168.0.220

# Option 2: Via port-forward
kubectl port-forward -n grafana svc/grafana 3000:3000
# Access: http://localhost:3000

# Check Prometheus
kubectl port-forward -n prometheus svc/kube-prometheus-stack-prometheus 9090:9090
# Access: http://localhost:9090

# View logs
kubectl logs -n grafana -f deployment/grafana
kubectl logs -n prometheus -f prometheus-kube-prometheus-stack-prometheus-0
```

## Important Notes

### ⚠️ Configuration Issues to Address

1. **Traefik Ingress TLS Certificate**: Certificate request failing for `grafana.lab.local`
   - Error: "Domain name does not end with a valid public suffix (TLD)"
   - Status: Using LoadBalancer IP as workaround
   - Fix needed: Use valid public domain or local CA

2. **Default Grafana Password**: Still set to `changeme`
   - Change command:
     ```bash
     kubectl exec -n grafana deploy/grafana -- grafana-cli admin reset-admin-password <newpassword>
     ```

3. **No Persistent Storage**
   - Grafana and Prometheus use emptyDir (data lost on pod restart)
   - Need: StorageClass implementation (e.g., local-path, NFS, or cloud storage)
   - Impact: Dashboards lost on restart, no metric history

### 📋 Next Steps

1. **Implement persistent storage**
   - Create local-path StorageClass
   - Update Prometheus and Grafana to use persistent volumes

2. **Set up valid TLS**
   - Use Cloudflare DNS with cert-manager
   - Update ingress hostname to valid domain

3. **Add more dashboards**
   - Pod resource usage
   - Network throughput
   - Cluster health overview

4. **Configure alerting**
   - Set up AlertManager routing
   - Create alert rules for critical metrics

5. **Enable Grafana authentication**
   - LDAP/OAuth2 integration
   - User management

## Git Commits Today

1. `Add Prometheus and Grafana deployments`
2. `Add Node CPU and Memory monitoring dashboard`
3. `Add MetalLB and Grafana LoadBalancer service`
4. `Disable Grafana persistence to fix pending pod`
5. `Disable Prometheus PVC for no storage class`

## Files Modified/Created

```
k8s/infra/Prometheus/
├── namespace.yaml
├── helm-repository.yaml
├── helm-release.yaml
├── ip-address-pool.yaml (MetalLB config)
├── kustomization.yaml
└── README.md

k8s/infra/MetalLB/
├── namespace.yaml
├── helm-repository.yaml
├── helm-release.yaml
├── ip-address-pool.yaml
├── kustomization.yaml
└── README.md

k8s/apps/grafana/
├── namespace.yaml
├── helm-repository.yaml
├── helm-release.yaml
├── dashboard-configmap.yaml (custom dashboard)
├── service-loadbalancer.yaml
├── kustomization.yaml
└── README.md

Root: kustomization.yaml (updated to include new deployments)
```

---
**Session End Time**: 2026-02-03 20:36 CET
**Status**: ✅ All core components deployed and operational
