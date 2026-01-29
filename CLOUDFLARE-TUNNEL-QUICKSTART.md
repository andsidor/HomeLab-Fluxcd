# Cloudflare Tunnel - Quick Start

## 🚀 Szybki Start

### 1. Utwórz Cloudflare Tunnel

```bash
# Idź do https://dash.cloudflare.com/
# Zero Trust → Networks → Tunnels → Create a tunnel
# Krok 1: Wybierz domenę
# Krok 2: Nazwij tunnel (np. "homelab")
# Krok 3: Skopiuj token tunnel'u
```

### 2. Uruchom skrypt setupu

```bash
cd ~/HomeLab-Fluxcd
./setup-cloudflare-tunnel.sh
```

Skrypt poprosi o:
- **Tunnel Token** - z kroku 1
- **Tunnel ID** - UUID tunelu
- **Account Tag** - z Account Settings
- **Domain** - domena (np. example.com)

### 3. Czekaj na uruchomienie

```bash
# Czekaj aż pody się uruchomią
kubectl get pods -n cloudflare -w

# Po ~1 minucie powinieneś zobaczyć:
# cloudflared-xxxxx    Running
# cloudflared-yyyyy    Running
```

### 4. Konfiguracja w Cloudflare Dashboard

1. Idź do **Zero Trust → Networks → Tunnels**
2. Wybierz swój tunnel
3. Kliknij **Configure**
4. W sekcji **Public Hostname** kliknij **Add a public hostname**
5. Wypełnij:
   - **Subdomain**: `app` lub `*` (wildcard)
   - **Domain**: `example.com`
   - **Type**: HTTP
   - **URL**: `traefik.kube-system:80`

### 5. Test

```bash
# Sprawdzaj logi
kubectl logs -n cloudflare -l app=cloudflared -f

# Powinno pokazać: "Tunnel running at..."
```

## 📊 Weryfikacja

```bash
# Status podów
kubectl get pods -n cloudflare

# Status External Secret
kubectl get externalsecrets -n cloudflare

# Secret załadowany
kubectl get secret -n cloudflare

# Describe secret (bez wartości!)
kubectl describe secret cloudflare-tunnel-secret -n cloudflare
```

## 🔐 Bezpieczeństwo

✅ Token przechowywany w Google Secret Manager
✅ Token nigdy w Gicie (eso-key.json w .gitignore)
✅ Workload Identity - brak kluczy API
✅ Automatyczne odświeżanie tokenów co 15 minut

## ⚙️ Zmiana konfiguracji

### Zmiana tokenu

```bash
# Pobierz nowy token z Cloudflare
# Zaktualizuj w Google Secret Manager
gcloud secrets versions add cloudflare-tunnel-token --data-file=- <<< "NEW_TOKEN"

# Secret w Kubernetes automatycznie się odświeży w ~15 minut
# cloudflared automatycznie się restartuje
```

### Zmiana domeny

```bash
# Edytuj k8s/infra/Cloudflare/serviceaccount.yaml
# Zmień hostname w ingress
vim k8s/infra/Cloudflare/serviceaccount.yaml

# Apply
kubectl apply -k k8s/infra/Cloudflare/
```

## 🐛 Troubleshooting

### Pod nie startuje

```bash
kubectl describe pod -n cloudflare -l app=cloudflared
kubectl logs -n cloudflare -l app=cloudflared
```

### Tunnel Down w Cloudflare Dashboard

```bash
# Sprawdzaj czy pod jest running
kubectl get pods -n cloudflare

# Sprawdzaj readiness
kubectl describe pod -n cloudflare -l app=cloudflared | grep -A 5 "Readiness"
```

### Secret nie załadowany

```bash
# Sprawdzaj External Secret
kubectl describe externalsecret cloudflare-tunnel -n cloudflare

# Sprawdzaj ESO logi
kubectl logs -n external-secrets -l app.kubernetes.io/name=external-secrets
```

### Brak połączenia do Traefika

```bash
# Sprawdzaj czy traefik jest dostępny
kubectl get svc -n kube-system traefik

# Test connectivity
kubectl run -it --rm debug --image=busybox -- wget -O- http://traefik.kube-system:80/
```

## 📝 Pliki

```
k8s/infra/Cloudflare/
├── namespace.yaml           # Namespace cloudflare
├── external-secret.yaml     # ESO - pobiera z Google SM
├── serviceaccount.yaml      # SA + ConfigMap
├── deployment.yaml          # cloudflared deployment + service
├── rbac.yaml               # Role i RoleBinding
├── kustomization.yaml      # Manifest bundle
└── README.md               # Dokumentacja
```

## 🌐 URL dostępu

Po skonfigurowaniu w Cloudflare Dashboard:

```
https://app.example.com → traefik.kube-system:80
https://subdomain.example.com → traefik.kube-system:80
```

Traefik będzie obsługiwać routing do aplikacji wg Ingress rules.

## 🔗 Architektura

```
Internet
   ↓
Cloudflare Network (DDoS protection, CDN, WAF)
   ↓
Cloudflare Tunnel (encrypted connection)
   ↓
cloudflared pod (Kubernetes)
   ↓
traefik (Ingress Controller)
   ↓
Your Services/Applications
```

## 📚 Zasoby

- [Cloudflare Tunnel Docs](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)
- [cloudflared GitHub](https://github.com/cloudflare/cloudflared)
- [Cloudflare Zero Trust](https://developers.cloudflare.com/cloudflare-one/)
