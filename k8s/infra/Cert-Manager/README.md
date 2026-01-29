# Cert Manager - Let's Encrypt TLS dla Production

Konfiguracja Cert Manager z automatycznym pobieraniem certyfikatów TLS z Let's Encrypt dla produkcji.

## Pliki Konfiguracji

### 1. **namespace.yaml**
- Definiuje namespace `cert-manager`

### 2. **helm-repository.yaml**
- HelmRepository Jetstack z chartami Cert Manager

### 3. **helm-release.yaml**
- HelmRelease instalujący Cert Manager v1.14.0
- Automatycznie instaluje CRDs
- 2 repliki dla wysokiej dostępności

### 4. **cluster-issuers.yaml**
Definiuje 3 ClusterIssuers:
- **letsencrypt-prod** - Production (rzeczywiste certyfikaty)
- **letsencrypt-staging** - Staging (do testowania)
- **selfsigned-issuer** - Self-Signed (backup)

### 5. **certificates.yaml**
Przykładowe Certificate resources dla Twojej aplikacji

## Wymagania

### 1. Email dla Let's Encrypt

Zaktualizuj email w `cluster-issuers.yaml`:
```yaml
email: your-email@example.com
```

### 2. Domeny

Zaktualizuj domeny w `certificates.yaml`:
```yaml
dnsNames:
- "your-domain.com"
- "*.your-domain.com"
```

### 3. Traefik Ingress Controller

Cert Manager wymaga Traefik do HTTP01 challenge. Sprawdź czy jest zainstalowany:
```bash
kubectl get ingress -A
```

## Deploy

```bash
# 1. Deploy Cert Manager z Flux
kubectl apply -f k8s/infra/Cert-Manager/

# LUB za pomocą kustomization w Flux:
flux create kustomization cert-manager \
  --source=flux-system \
  --path="./k8s/infra/Cert-Manager" \
  --prune=true \
  --interval=10m

# 2. Sprawdź czy Cert Manager się uruchomił
kubectl wait --for=condition=ready pod \
  -l app=cert-manager \
  -n cert-manager \
  --timeout=300s

# 3. Sprawdź ClusterIssuers
kubectl get clusterissuers

# 4. Sprawdź Certificates
kubectl get certificates -A

# 5. Sprawdź czy certyfikat został wygenerowany
kubectl describe certificate wildcard-tls
```

## Używanie Certyfikatów w Ingressie

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  tls:
  - hosts:
    - app.example.com
    secretName: app-tls-secret
  rules:
  - host: app.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-service
            port:
              number: 80
```

## Troubleshooting

### Certyfikat nie jest generowany

```bash
# Sprawdź status Certificate
kubectl describe certificate wildcard-tls

# Sprawdź logi Cert Manager
kubectl logs -n cert-manager -l app=cert-manager -f

# Sprawdź CertificateRequest
kubectl get certificaterequest -A
kubectl describe certificaterequest <name>
```

### Let's Encrypt Rate Limiting

Jeśli dostajesz błąd o rate limiting:
1. Czekaj 1 godzinę
2. Użyj staging issuer do testowania: `letsencrypt-staging`
3. Przenieś się na production gdy wszystko działa: `letsencrypt-prod`

### DNS Challenge zamiast HTTP01

Jeśli HTTP01 nie działa, możesz użyć DNS01 (wymaga integracji z DNS provider):
```yaml
solvers:
- dns01:
    cloudflare:
      email: your-email@example.com
      apiTokenSecretRef:
        name: cloudflare-api-token
        key: api-token
```

## Bezpieczeństwo

- ✅ Automatyczne odnawianie certyfikatów
- ✅ Production Let's Encrypt (zaufane certyfikaty)
- ✅ Self-signed backup
- ✅ 90 dni ważności certyfikatów
- ✅ Odnawianie 30 dni przed wygaśnięciem
