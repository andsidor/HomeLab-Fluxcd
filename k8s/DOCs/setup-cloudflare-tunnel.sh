#!/bin/bash
# setup-cloudflare-tunnel.sh - Setup Cloudflare Tunnel with Google Secret Manager (Token-based)

set -e

# Kolory
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}=== Cloudflare Tunnel Setup (Token Method) ===${NC}\n"

# Sprawdzenie zależności
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}[ERROR] gcloud CLI nie jest zainstalowany${NC}"
    exit 1
fi

if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}[ERROR] kubectl nie jest zainstalowany${NC}"
    exit 1
fi

# Pobierz projekt
PROJECT_ID=$(gcloud config get-value project)
echo -e "${GREEN}[OK] Projekt GCP: ${PROJECT_ID}${NC}\n"

# Pobierz dane od użytkownika
echo -e "${BLUE}Podaj dane Cloudflare Tunnel:${NC}"
echo -e "${YELLOW}(Instrukcja: https://dash.cloudflare.com → Zero Trust → Networks → Tunnels)${NC}\n"

read -p "Tunnel Token (token z Cloudflare Dashboard): " TUNNEL_TOKEN

if [ -z "$TUNNEL_TOKEN" ]; then
    echo -e "${RED}[ERROR] Token nie może być pusty${NC}"
    exit 1
fi

read -p "Domena główna (np. example.com): " DOMAIN

if [ -z "$DOMAIN" ]; then
    echo -e "${RED}[ERROR] Domena nie może być pusta${NC}"
    exit 1
fi

echo -e "\n${BLUE}[1/5] Tworzę sekrety w Google Secret Manager...${NC}"

# Utwórz lub aktualizuj token secret
echo "$TUNNEL_TOKEN" | gcloud secrets create cloudflare-tunnel-token \
  --data-file=- --replication-policy="automatic" 2>/dev/null || \
  echo "$TUNNEL_TOKEN" | gcloud secrets versions add cloudflare-tunnel-token --data-file=-
echo -e "${GREEN}[OK] cloudflare-tunnel-token${NC}"

echo -e "\n${BLUE}[2/5] Sprawdzam czy ESO jest zainstalowany...${NC}"
if kubectl get namespace external-secrets &> /dev/null; then
    echo -e "${GREEN}[OK] External Secrets Operator zainstalowany${NC}"
else
    echo -e "${RED}[ERROR] ESO nie zainstalowany - zainstaluj najpierw ESO${NC}"
    exit 1
fi

echo -e "\n${BLUE}[3/5] Sprawdzam ClusterSecretStore...${NC}"
if kubectl get clustersecretstores gcpsm-cluster-secret-store &> /dev/null; then
    echo -e "${GREEN}[OK] gcpsm-cluster-secret-store dostępny${NC}"
else
    echo -e "${RED}[ERROR] ClusterSecretStore nie znaleziony${NC}"
    exit 1
fi

echo -e "\n${BLUE}[4/5] Aktualizuję konfigurację...${NC}"
sed -i "s/hostname: .*/hostname: \"*.${DOMAIN}\"/g" k8s/infra/Cloudflare/serviceaccount.yaml
echo -e "${GREEN}[OK] Domena zaktualizowana: *.${DOMAIN}${NC}"

echo -e "\n${BLUE}[5/5] Deploywuję Cloudflare Tunnel...${NC}"
kubectl apply -k k8s/infra/Cloudflare/
echo -e "${GREEN}[OK] Manifest aplikowany${NC}"

echo -e "\n${GREEN}========================================${NC}"
echo -e "Projekt GCP: ${PROJECT_ID}"
echo -e "Token: ${TUNNEL_TOKEN:0:20}..."
echo -e "Domena: *.${DOMAIN}"
echo -e "Namespace: cloudflare"
echo -e "${GREEN}========================================${NC}"

echo -e "\n${GREEN}[✓] Setup zakończony!${NC}\n"

echo -e "${BLUE}Status (czekaj ~30 sekund):${NC}"
echo -e "${BLUE}kubectl get pods -n cloudflare${NC}\n"

echo -e "${BLUE}Następne kroki:${NC}"
echo -e "1. Czekaj aż pody się uruchomią:"
echo -e "   ${BLUE}kubectl get pods -n cloudflare -w${NC}"
echo -e ""
echo -e "2. Sprawdzaj External Secret:"
echo -e "   ${BLUE}kubectl describe externalsecret cloudflare-tunnel -n cloudflare${NC}"
echo -e ""
echo -e "3. Sprawdzaj Secret:"
echo -e "   ${BLUE}kubectl get secret cloudflare-tunnel-secret -n cloudflare${NC}"
echo -e ""
echo -e "4. Sprawdzaj logi:"
echo -e "   ${BLUE}kubectl logs -n cloudflare -l app=cloudflared -f${NC}"
echo -e ""
echo -e "5. W Cloudflare Dashboard - Zero Trust → Tunnels → Configure:"
echo -e "   - Public Hostname: *.${DOMAIN}"
echo -e "   - Type: HTTP"
echo -e "   - URL: http://traefik.kube-system:80"
echo -e ""
echo -e "${YELLOW}⚠️  Token odświeża się co 15 minut z Google Secret Manager${NC}"
