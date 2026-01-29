# Certificates - TLS Certificates dla aplikacji

Folder zawierający Certificate resources, które tworzą certyfikaty TLS dla aplikacji.

**WAŻNE:** Ten folder zawiera Certificates które muszą być aplikowane DOPIERO PO zainstalowaniu Cert Manager!

## Zasoby

- **certificates.yaml** - Certificate resources dla:
  - `wildcard-tls` - wildcard certyfikat dla domeny
  - `app-tls` - certyfikat dla aplikacji demo2

## Deploy

```bash
# 1. Najpierw zainstaluj Cert Manager:
kubectl apply -k ./k8s/infra/Cert-Manager/

# 2. Czekaj aż Cert Manager się uruchomi:
kubectl wait --for=condition=ready pod \
  -l app=cert-manager \
  -n cert-manager \
  --timeout=300s

# 3. Dopiero potem zainstaluj Certificates:
kubectl apply -k ./k8s/infra/Certificates/

# 4. Sprawdzaj status:
kubectl get certificates -A
kubectl describe certificate wildcard-tls
```

## Zmiana Domen

Zaktualizuj dnsNames w certificates.yaml:
```yaml
dnsNames:
- "your-domain.com"
- "*.your-domain.com"
```

## Troubleshooting

```bash
# Sprawdź status Certificate
kubectl describe certificate wildcard-tls

# Sprawdź czy Secret został utworzony
kubectl get secret wildcard-tls-secret

# Sprawdź logi Cert Manager
kubectl logs -n cert-manager -l app=cert-manager -f
```
