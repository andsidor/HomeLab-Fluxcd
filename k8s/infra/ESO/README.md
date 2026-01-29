# External Secrets Operator - Google Secret Manager Integration

Ten folder zawiera konfigurację External Secrets Operator (ESO) do integracji z Google Secret Manager.

## 📋 Zawartość

- **namespace.yaml** - Namespace dla External Secrets Operator
- **helm-repository.yaml** - Helm repository dla ESO
- **helm-release.yaml** - Helm release z ESO
- **secret-store.yaml** - ClusterSecretStore dla Google Secret Manager
- **external-secret-example.yaml** - Przykłady ExternalSecret zasobów
- **kustomization.yaml** - Kustomization dla Flux CD

## 🚀 Instalacja

### 1. Konfiguracja Google Cloud (wstępnie)

Użyj skryptu `setup-eso-homelab.sh` z głównego katalogu:

```bash
bash setup-eso-homelab.sh
```

Ten skrypt:
- Tworzy Google Service Account (`eso-sa`)
- Przydziela uprawnienia do Secret Manager
- Generuje klucz dostępu (`eso-key.json`)
- Tworzy Kubernetes Secret z poświadczeniami
- Tworzy demo sekrety w Google Secret Manager

### 2. Aktualizacja konfiguracji

Przed deploymentem zaktualizuj [secret-store.yaml](secret-store.yaml):

```yaml
projectID: "twój-gcp-projekt-id"  # Zmień na swój Project ID
```

### 3. Deploy z Flux CD

```bash
flux create source git external-secrets \
  --url=https://github.com/tu/repo \
  --branch=main \
  --path=k8s/infra/ESO \
  --namespace=flux-system
```

Lub bezpośrednio z kubectl:

```bash
kubectl apply -k ./k8s/infra/ESO/
```

## 📖 Użycie

### Przykład 1: Prostego sekretu API

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: my-api-key
  namespace: default
spec:
  refreshInterval: 15m
  secretStoreRef:
    name: gcpsm-cluster-secret-store
    kind: ClusterSecretStore
  target:
    name: my-api-key
    creationPolicy: Owner
  data:
    - secretKey: api-key
      remoteRef:
        key: my-gcp-secret-name
```

### Przykład 2: Wielu sekretów

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: db-credentials
  namespace: default
spec:
  refreshInterval: 15m
  secretStoreRef:
    name: gcpsm-cluster-secret-store
    kind: ClusterSecretStore
  target:
    name: db-credentials
    creationPolicy: Owner
  data:
    - secretKey: username
      remoteRef:
        key: db-username
    - secretKey: password
      remoteRef:
        key: db-password
    - secretKey: host
      remoteRef:
        key: db-host
```

### Przykład 3: JSON sekretu

Jeśli masz JSON w Google Secret Manager:

```json
{
  "username": "user",
  "password": "pass",
  "host": "db.example.com"
}
```

Możesz go rozpakować:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: db-config
  namespace: default
spec:
  refreshInterval: 15m
  secretStoreRef:
    name: gcpsm-cluster-secret-store
    kind: ClusterSecretStore
  target:
    name: db-config
    creationPolicy: Owner
    template:
      engineVersion: v2
      data:
        config.json: |
          {
            "username": "{{ .dbUsername }}",
            "password": "{{ .dbPassword }}",
            "host": "{{ .dbHost }}"
          }
  dataFrom:
    - extract:
        key: db-config-json
```

## ✅ Weryfikacja

### Sprawdzenie statusu ESO

```bash
# Sprawdzenie pod'ów
kubectl get pods -n external-secrets

# Sprawdzenie logów
kubectl logs -n external-secrets -l app.kubernetes.io/name=external-secrets

# Sprawdzenie SecretStore
kubectl get secretstore -A
kubectl describe secretstore gcpsm-cluster-secret-store
```

### Sprawdzenie ExternalSecret

```bash
# Lista wszystkich ExternalSecrets
kubectl get externalsecrets -A

# Szczegóły konkretnego ExternalSecret
kubectl describe externalsecret demo-api-key -n default

# Sprawdzenie czy Secret został utworzony
kubectl get secrets -n default demo-api-key
kubectl describe secret demo-api-key -n default
```

### Debugging

Jeśli ExternalSecret nie synchronizuje się:

```bash
# Sprawdź logi operatora
kubectl logs -n external-secrets -l app.kubernetes.io/name=external-secrets -f

# Sprawdź status synchronizacji
kubectl get externalsecrets -n default -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.conditions[?(@.type=="Ready")].status}{"\n"}{end}'

# Sprawdź konkrety błąd
kubectl describe externalsecret demo-api-key -n default
```

## 🔐 Bezpieczeństwo

### Poświadczenia GCP

1. **Nigdy nie commituj `eso-key.json`** do Git'a
   ```bash
   echo "eso-key.json" >> .gitignore
   ```

2. **Ogranicz uprawnienia Service Account**
   ```bash
   # Uprawnienia powinny być ograniczone do:
   # - roles/secretmanager.secretAccessor
   ```

3. **Rotacja kluczy**
   ```bash
   # Usuń stary klucz
   gcloud iam service-accounts keys delete KEY_ID \
     --iam-account=eso-sa@PROJECT_ID.iam.gserviceaccount.com

   # Utwórz nowy klucz
   gcloud iam service-accounts keys create eso-key.json \
     --iam-account=eso-sa@PROJECT_ID.iam.gserviceaccount.com

   # Zaktualizuj Secret w Kubernetes
   kubectl create secret generic gcp-credentials \
     --from-file=secret-access-credentials=eso-key.json \
     -n external-secrets \
     --dry-run=client -o yaml | kubectl apply -f -
   ```

### RBAC dla ExternalSecrets

Ogranicze dostęp do ExternalSecrets dla konkretnych użytkowników:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: read-externalsecrets
  namespace: default
rules:
  - apiGroups: ["external-secrets.io"]
    resources: ["externalsecrets"]
    verbs: ["get", "list", "watch"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-externalsecrets
  namespace: default
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: read-externalsecrets
subjects:
  - kind: ServiceAccount
    name: my-app
    namespace: default
```

## 📝 Notatki

- **RefreshInterval** - Czas między synchronizacjami (domyślnie 15m)
- **CreationPolicy** - Jak traktować istniejące Sekrety:
  - `Owner` - ESO będzie właścicielem i moze je usunąć
  - `Orphan` - ESO nie będzie właścicielem
- **EngineVersion** - Wersja template'u (v2 jest zalecana)

## 🔗 Dokumentacja

- [External Secrets Operator](https://external-secrets.io/)
- [Google Secret Manager Provider](https://external-secrets.io/latest/provider/google-secrets-manager/)
- [ExternalSecret Specification](https://external-secrets.io/latest/api/externalsecret/)

## 🐛 Troubleshooting

### Secret nie synchronizuje się

1. Sprawdź czy SecretStore jest `Ready`
2. Sprawdź czy sekrety istnieją w Google Secret Manager
3. Sprawdź czy Service Account ma uprawnienia
4. Sprawdź logi operatora

### Permission Denied błędy

```bash
# Sprawdzenie uprawnień Service Account
gcloud projects get-iam-policy PROJECT_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:eso-sa@*"
```

### Timeout błędy

Zwiększ timeout w ExternalSecret:

```yaml
spec:
  secretStoreRef:
    name: gcpsm-cluster-secret-store
    kind: ClusterSecretStore
  target:
    name: my-secret
    creationPolicy: Owner
  refreshInterval: 30m  # Zwiększ interwał
```
