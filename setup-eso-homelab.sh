#!/bin/bash
# setup-eso-homelab.sh - Setup External Secrets Operator dla Homelaba

set -e

# Kolory dla output'u
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== External Secrets Operator Setup dla Homelaba ===${NC}\n"

# 1. Sprawdź czy gcloud jest zainstalowany
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}[ERROR] gcloud CLI nie jest zainstalowany${NC}"
    exit 1
fi

# 2. Sprawdź czy kubectl jest zainstalowany
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}[ERROR] kubectl nie jest zainstalowany${NC}"
    exit 1
fi

# 3. Pobierz aktualny projekt GCP
PROJECT_ID=$(gcloud config get-value project)
echo -e "${GREEN}[OK] Projekt GCP: ${PROJECT_ID}${NC}"

# 4. Sprawdź czy service account istnieje
echo -e "\n${BLUE}[1/6] Sprawdzam Google Service Account...${NC}"
if gcloud iam service-accounts describe eso-sa@${PROJECT_ID}.iam.gserviceaccount.com &> /dev/null; then
    echo -e "${GREEN}[OK] Service account 'eso-sa' już istnieje${NC}"
else
    echo -e "${BLUE}[!] Tworzę nowy service account 'eso-sa'...${NC}"
    gcloud iam service-accounts create eso-sa \
        --display-name="External Secrets Operator Service Account"
    echo -e "${GREEN}[OK] Service account utworzony${NC}"
fi

# 5. Przyznaj uprawnienia do Secret Manager
echo -e "\n${BLUE}[2/6] Przydzielam uprawnienia do Secret Manager...${NC}"
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:eso-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor" \
  --quiet
echo -e "${GREEN}[OK] Uprawnienia przydzielone${NC}"

# 6. Usuń stary klucz jeśli istnieje
echo -e "\n${BLUE}[3/6] Tworzę klucz dla service account...${NC}"
if [ -f "eso-key.json" ]; then
    rm -f eso-key.json
    echo -e "${BLUE}[!] Usunąłem stary klucz${NC}"
fi

# 7. Utwórz nowy klucz
gcloud iam service-accounts keys create eso-key.json \
  --iam-account=eso-sa@${PROJECT_ID}.iam.gserviceaccount.com
echo -e "${GREEN}[OK] Klucz utworzony: eso-key.json${NC}"

# 8. Utwórz Secret w Kubernetes
echo -e "\n${BLUE}[4/6] Tworzę Secret w Kubernetes...${NC}"
kubectl create namespace external-secrets --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic gcp-credentials \
  --from-file=secret-access-credentials=eso-key.json \
  -n external-secrets \
  --dry-run=client -o yaml | kubectl apply -f -
echo -e "${GREEN}[OK] Secret 'gcp-credentials' utworzony${NC}"

# 9. Utwórz sekrety dla demo aplikacji
echo -e "\n${BLUE}[5/6] Tworzę sekrety w Google Secret Manager...${NC}"

# Sprawdź czy sekrety już istnieją
if gcloud secrets describe demo-api-key &> /dev/null; then
    echo -e "${BLUE}[!] Secret 'demo-api-key' już istnieje${NC}"
else
    echo "your-secret-api-key-123" | gcloud secrets create demo-api-key --data-file=-
    echo -e "${GREEN}[OK] Secret 'demo-api-key' utworzony${NC}"
fi

if gcloud secrets describe demo-database-url &> /dev/null; then
    echo -e "${BLUE}[!] Secret 'demo-database-url' już istnieje${NC}"
else
    echo "postgresql://user:pass@localhost:5432/demo" | gcloud secrets create demo-database-url --data-file=-
    echo -e "${GREEN}[OK] Secret 'demo-database-url' utworzony${NC}"
fi

# 10. Podsumowanie
echo -e "\n${BLUE}[6/6] Podsumowanie${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "Projekt GCP: ${PROJECT_ID}"
echo -e "Service Account: eso-sa@${PROJECT_ID}.iam.gserviceaccount.com"
echo -e "Kubernetes Secret: gcp-credentials (external-secrets namespace)"
echo -e "Demo Sekrety:"
echo -e "  - demo-api-key"
echo -e "  - demo-database-url"
echo -e "${GREEN}========================================${NC}"

echo -e "\n${GREEN}[✓] Setup zakończony!${NC}\n"

echo -e "${BLUE}Następne kroki:${NC}"
echo -e "1. Deploy External Secrets Operator:"
echo -e "   ${BLUE}kubectl apply -k ./k8s/infra/ESO/${NC}"
echo -e ""
echo -e "2. Sprawdź status ESO:"
echo -e "   ${BLUE}kubectl get pods -n external-secrets${NC}"
echo -e ""
echo -e "3. Deploy demo aplikacji:"
echo -e "   ${BLUE}kubectl apply -k ./k8s/apps/demo2/${NC}"
echo -e ""
echo -e "4. Sprawdź czy External Secret został zsynchronizowany:"
echo -e "   ${BLUE}kubectl get externalsecrets -n demo2${NC}"
echo -e ""
echo -e "5. Przetestuj aplikację:"
echo -e "   ${BLUE}kubectl port-forward -n demo2 svc/demo-app 8080:80${NC}"
echo -e "   ${BLUE}curl http://localhost:8080/secrets${NC}"
echo -e ""
echo -e "${RED}⚠️  WAŻNE: Plik 'eso-key.json' zawiera wrażliwe dane!${NC}"
echo -e "${RED}   Dodaj go do .gitignore i nigdy nie commituj do Gita${NC}"
