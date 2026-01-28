# Demo Aplikacja - Google Secret Manager Integration

Ta aplikacja demonstruje integrację **External Secrets Operator** z **Google Secret Manager**.

## Architektura

```
Google Cloud Console
    ↓
Google Secret Manager
    ↓
External Secrets Operator (ESO)
    ↓
Kubernetes Secret
    ↓
Demo App (Flask)
```

## Pliki Konfiguracji

### 1. **namespace.yaml**
- Definiuje namespace `demo2` dla aplikacji

### 2. **serviceaccount.yaml**
- Service Account z annotacją dla Google Workload Identity
- Pozwala podowi bezpiecznie pobierać sekrety z GCP

### 3. **external-secret.yaml**
- Konfiguracja External Secret
- Pobiera sekrety z Google Secret Manager:
  - `demo-api-key` → `API_KEY`
  - `demo-database-url` → `DATABASE_URL`
- Automatycznie tworzy Kubernetes Secret `demo-app-secret`
- Odświeża co 5 minut

### 4. **config-app.yaml**
- ConfigMap zawierający aplikację Flask
- Endpoints:
  - `GET /health` - sprawdzenie zdrowotności aplikacji
  - `GET /secrets` - pokazuje czy sekrety zostały załadowane
  - `GET /config` - wyświetla konfigurację aplikacji

### 5. **deployment.yaml**
- Deployment z 2 replikami
- Montuje kod aplikacji z ConfigMap
- Wstrzykuje sekrety z Kubernetes Secret
- Health checks (liveness i readiness probes)

### 6. **service.yaml**
- Service ClusterIP do dostępu do aplikacji
- Port 80 → 5000 (Flask)

## Wymagania przed Deployowaniem

### 1. Skonfiguruj Google Secret Manager

```bash
# Utwórz sekrety w Google Cloud Console
gcloud secrets create demo-api-key --data-file=- <<EOF
your-api-key-value
EOF

gcloud secrets create demo-database-url --data-file=- <<EOF
postgresql://user:pass@host:5432/db
EOF
```

### 2. Utwórz Key File i Secret w Kubernetes (dla Homelaba)

```bash
# Utwórz klucz dla Google Service Account
gcloud iam service-accounts keys create eso-key.json \
  --iam-account=eso-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com

# Utwórz Secret w Kubernetes z kluczem
kubectl create secret generic gcp-credentials \
  --from-file=secret-access-credentials=eso-key.json \
  -n external-secrets

# Sprawdź czy Secret został utworzony
kubectl get secrets -n external-secrets
```

### 3. (Alternatywa) Workload Identity - dla GKE z Workload Identity

Jeśli twój klaster GKE ma włączoną Workload Identity:

```bash
# Przyznaj uprawnienia do Secret Manager
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:eso-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"

# Skonfiguruj Workload Identity binding
gcloud iam service-accounts add-iam-policy-binding \
  eso-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:YOUR_PROJECT_ID.svc.id.goog[demo2/demo-app]"
```

### 4. Zaktualizuj pliki

- W `external-secret.yaml` zmień `projectID` na twój GCP Project ID

## Deploy

```bash
# Aplikuj konfigurację
kubectl apply -k ./k8s/apps/demo2/

# Sprawdź status
kubectl get pods -n demo2
kubectl get externalsecrets -n demo2
kubectl get secrets -n demo2

# Sprawdź logi
kubectl logs -n demo2 -l app=demo-app -f

# Test aplikacji
kubectl port-forward -n demo2 svc/demo-app 8080:80

# Endpoints:
# curl http://localhost:8080/health
# curl http://localhost:8080/config
# curl http://localhost:8080/secrets
```

## Troubleshooting

### Sekrety nie zostały załadowane

```bash
# Sprawdź status External Secret
kubectl describe externalsecrets -n demo2 gcp-demo-secret

# Sprawdź czy Secret został utworzony
kubectl get secrets -n demo2
kubectl describe secret demo-app-secret -n demo2
```

### Problemy z autoryzacją

```bash
# Sprawdź czy Workload Identity jest poprawnie skonfigurowana
kubectl describe sa demo-app -n demo2

# Sprawdź logi ESO
kubectl logs -n external-secrets -l app.kubernetes.io/name=external-secrets
```

## Bezpieczeństwo

- ✅ Sekrety nie są przechowywane w Gicie
- ✅ Workload Identity zamiast kluczy API
- ✅ Sekrety przechowywane w Google Secret Manager
- ✅ Automatyczne odświeżanie sekretów
- ✅ RBAC dla aplikacji
