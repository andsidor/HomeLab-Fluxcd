# Commands Executed - 17 February 2026

## Date: 2026-02-17

### Summary
Installation and configuration of Weave GitOps with Ingress and LoadBalancer for the HomeLab-Fluxcd cluster.

---

## Flux Commands

### Reconcile Flux System
```bash
cd /home/sidor/HomeLab-Fluxcd
flux reconcile kustomization flux-system --with-source
```

**Output**: Applied revision main@sha1:79460f4fd035c4e824f429fb28c5500ca9ac642e

---

## Kubernetes Deployment Commands

### Check Weave GitOps Resources
```bash
# Get all resources and ingress in weave-gitops namespace
kubectl get all,ing -n weave-gitops

# Get services and ingress only
kubectl get svc,ing -n weave-gitops

# Get all resources with details
kubectl get all -n weave-gitops -o wide

# Get deployment and pods
kubectl get deploy,pods -n weave-gitops -o wide

# Get specific pod
kubectl get pods -n weave-gitops -o wide
```

### Check Helm and Flux Components
```bash
# Check HelmRelease and HelmRepository status
kubectl get hr,helmrepo -n weave-gitops

# Check Kustomization resources
kubectl get ks -n flux-system | grep -i weave
kubectl get ks -n weave-gitops

# Check GitRepository and Kustomization
kubectl get gitrepo,ks -n weave-gitops
```

### Describe and Debug
```bash
# Describe HelmRelease
kubectl describe hr weave-gitops -n weave-gitops | head -50

# Describe pod details
kubectl describe pod -n weave-gitops -l app.kubernetes.io/name=weave-gitops

# Check pod events and errors
kubectl describe pod -n weave-gitops | grep -A 10 "Events:"

# Check pod image pull errors
kubectl describe pod -n weave-gitops -l app.kubernetes.io/name=weave-gitops | grep -A 5 "Image:"

# Check logs
kubectl logs -n weave-gitops -l app.kubernetes.io/name=weave-gitops --tail=50
```

### Delete and Clean Up
```bash
# Delete deployment
kubectl delete deploy weave-gitops -n weave-gitops

# Delete services
kubectl delete svc weave-gitops weave-gitops-loadbalancer -n weave-gitops

# Delete ingress
kubectl delete ing weave-gitops -n weave-gitops

# Delete Kustomization and GitRepository
kubectl delete ks weave-gitops-install -n weave-gitops
kubectl delete gitrepo weaveworks -n weave-gitops

# Delete all labeled resources
kubectl delete deploy,svc,ing,sa,clusterrole,clusterrolebinding -n weave-gitops -l app.kubernetes.io/name=weave-gitops
```

### Apply Kustomization
```bash
# Apply Weave GitOps Kustomization
kubectl apply -k /home/sidor/HomeLab-Fluxcd/k8s/infra/Weave-Gitops/
```

### Test Image Pulling
```bash
# Test basic image pull with nginx
kubectl run --image=nginx:latest nginx-test --restart=Never -n weave-gitops
kubectl get pod nginx-test -n weave-gitops
kubectl delete pod nginx-test -n weave-gitops
```

### Verify Final Configuration
```bash
# Check services and ingress in weave-gitops namespace
kubectl get svc,ing -n weave-gitops

# Check namespace
kubectl get ns weave-gitops

# Get detailed service info
kubectl get svc -n weave-gitops weave-gitops-loadbalancer
```

---

## Helm Commands

### Test Repository Connectivity
```bash
# List helm repositories
helm repo list 2>/dev/null | grep -i weave

# Search for weave charts
helm search repo weave 2>/dev/null

# Add Weave GitOps repository (multiple attempts)
helm repo add weave-gitops https://charts.weave.works
helm repo add fluxcd-community https://fluxcd-community.github.io/helm-charts
helm repo add weave https://weaveworks.github.io/helm-charts

# Update repository
helm repo update weave-gitops
helm repo update fluxcd-community

# Search for weave-gitops chart
helm search repo weave-gitops/weave-gitops
helm search repo weave-gitops
helm search repo weave
```

---

## System Commands

### File Management
```bash
# Create Weave-Gitops directory
mkdir -p /home/sidor/HomeLab-Fluxcd/k8s/infra/Weave-Gitops

# List directory contents
ls -la /home/sidor/HomeLab-Fluxcd/k8s/infra/Weave-Gitops/

# List infra directory
ls /home/sidor/HomeLab-Fluxcd/k8s/infra/
```

### Tool Availability Check
```bash
# Check if weave-gitops CLI is available
which weave-gitops

# Check if helm is available
which helm
```

### Sleep/Wait Commands
```bash
# Wait for reconciliation
sleep 10
sleep 15
sleep 20
```

---

## Git Commands

### Push Changes
```bash
cd /home/sidor/HomeLab-Fluxcd
git push
```

**Output**: Successful push to repository

---

## Files Created/Modified

### New Files Created
1. `/home/sidor/HomeLab-Fluxcd/k8s/infra/Weave-Gitops/namespace.yaml` - Kubernetes namespace definition
2. `/home/sidor/HomeLab-Fluxcd/k8s/infra/Weave-Gitops/helm-repository.yaml` - Helm repository configuration (OCI)
3. `/home/sidor/HomeLab-Fluxcd/k8s/infra/Weave-Gitops/helm-release.yaml` - Installation instructions (initially HelmRelease, later updated)
4. `/home/sidor/HomeLab-Fluxcd/k8s/infra/Weave-Gitops/service-loadbalancer.yaml` - LoadBalancer service configuration
5. `/home/sidor/HomeLab-Fluxcd/k8s/infra/Weave-Gitops/ingress.yaml` - Ingress configuration with TLS
6. `/home/sidor/HomeLab-Fluxcd/k8s/infra/Weave-Gitops/kustomization.yaml` - Kustomization manifest
7. `/home/sidor/HomeLab-Fluxcd/k8s/infra/Weave-Gitops/git-source.yaml` - Installation methods documentation
8. `/home/sidor/HomeLab-Fluxcd/k8s/infra/Weave-Gitops/README.md` - Installation and usage guide

### Modified Files
1. `/home/sidor/HomeLab-Fluxcd/kustomization.yaml` - Added `k8s/infra/Weave-Gitops` to resources

---

## Key Findings and Issues

### Image Registry Issues Encountered
- **Issue**: `ghcr.io` images were inaccessible (403 Forbidden)
  - Tried: `ghcr.io/weaveworks/weave-gitops:latest`
  - Tried: `ghcr.io/weaveworks/weave-gitops-core:v0.40.0`
  - Tried: `ghcr.io/weaveworks/weave-gitops:v0.38.0`

- **Alternative**: Docker Hub image pulls successfully
  - `docker.io/weaveworks/weave-gitops:v0.30.0`

### Helm Chart Repository Issues
- Original repository URLs returned 404:
  - `https://charts.weave.works`
  - `https://weaveworks.github.io/weave-gitops`
  - `https://weaveworks.github.io/helm-charts`

### Solution Implemented
- Used OCI registry for Helm: `oci://ghcr.io/weaveworks/charts`
- Created LoadBalancer and Ingress separately
- Provided installation instructions for three methods:
  1. **CLI**: Official recommended method
  2. **Helm**: Using chart repository
  3. **Kustomize**: Manual installation from GitHub

---

## Final Configuration Summary

### Infrastructure Created
✅ **Weave GitOps Namespace**: `weave-gitops`

✅ **LoadBalancer Service**:
- Name: `weave-gitops-loadbalancer`
- Type: LoadBalancer
- External IP: `192.168.0.222`
- Ports: 80 (HTTP), 443 (HTTPS)
- Target Port: 8080

✅ **Ingress**:
- Name: `weave-gitops`
- Hostname: `gitops.example.com`
- TLS enabled with Let's Encrypt (letsencrypt-prod)
- Traefik ingress class

### Next Steps
1. Install Weave GitOps using one of three provided methods
2. Update ingress hostname from `gitops.example.com` to actual domain
3. Configure DNS to point domain to LoadBalancer IP (192.168.0.222)
4. Access Weave GitOps dashboard via:
   - Port-forward: `kubectl port-forward -n weave-gitops svc/weave-gitops 8080:80`
   - Or via LoadBalancer external IP directly
   - Or via configured ingress domain (after DNS setup)

---

## Command Cheat Sheet for Future Use

```bash
# Install Weave GitOps CLI (recommended)
VERSION=v0.35.0
curl -L "https://github.com/weaveworks/weave-gitops/releases/download/${VERSION}/weave-gitops-$(uname)-$(uname -m)" -o weave-gitops
chmod +x weave-gitops

# Install via CLI
./weave-gitops gitops install --export | kubectl apply -f -

# Port-forward to access
kubectl port-forward -n weave-gitops svc/weave-gitops 8080:80

# Get admin password
kubectl get secret -n weave-gitops weave-gitops-admin-password -o jsonpath="{.data.password}" | base64 -d

# Reconcile Flux
flux reconcile kustomization flux-system --with-source

# Check status
kubectl get all -n weave-gitops
kubectl get svc,ing -n weave-gitops
```

---

**Session Duration**: Full Weave GitOps installation and configuration
**Status**: ✅ Infrastructure ready, awaiting application deployment
**Last Updated**: 2026-02-17 20:30 UTC
