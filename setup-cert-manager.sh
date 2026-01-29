#!/bin/bash
# setup-cert-manager.sh - Setup Cert Manager z Let's Encrypt Production

set -e

# Kolory
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}=== Cert Manager Setup ===${NC}\n"

# Sprawdź czy kubectl jest dostępny
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}[ERROR] kubectl nie jest zainstalowany${NC}"
    exit 1
fi

# Pobierz informacje
read -p "Podaj email dla Let's Encrypt: " EMAIL
read -p "Podaj domenę główną (np. example.com): " DOMAIN
read -p "Podaj wildcard domenę (np. *.example.com): [opcjonalne] " WILDCARD

if [ -z "$WILDCARD" ]; then
    WILDCARD="*.$DOMAIN"
fi

echo -e "\n${BLUE}[1/5] Sprawdzam czy Traefik jest zainstalowany...${NC}"
if kubectl get deployment -n kube-system traefik &> /dev/null || kubectl get deployment -A -l app=traefik &> /dev/null; then
    echo -e "${GREEN}[OK] Traefik znaleziony${NC}"
else
    echo -e "${RED}[WARNING] Traefik nie znaleziony - Cert Manager potrzebuje Traefika do HTTP01 challenge${NC}"
fi

echo -e "\n${BLUE}[2/5] Aktualizuję email w ClusterIssuers...${NC}"
sed -i "s/admin@example.com/$EMAIL/g" k8s/infra/Cert-Manager/cluster-issuers.yaml
echo -e "${GREEN}[OK] Email zaktualizowany: $EMAIL${NC}"

echo -e "\n${BLUE}[3/5] Aktualizuję domeny w Certificates...${NC}"
sed -i "s/example\.com/$DOMAIN/g" k8s/infra/Cert-Manager/certificates.yaml
echo -e "${GREEN}[OK] Domeny zaktualizowane${NC}"

echo -e "\n${BLUE}[4/5] Deploywuję Cert Manager...${NC}"
kubectl apply -k k8s/infra/Cert-Manager/
echo -e "${GREEN}[OK] Manifest aplikowany${NC}"

echo -e "\n${BLUE}[5/5] Czekam na uruchomienie Cert Manager (max 5 minut)...${NC}"
kubectl wait --for=condition=ready pod \
  -l app=cert-manager \
  -n cert-manager \
  --timeout=300s 2>/dev/null || echo -e "${YELLOW}[!] Timeout - sprawdź manualnie: kubectl get pods -n cert-manager${NC}"

echo -e "\n${GREEN}========================================${NC}"
echo -e "Email: $EMAIL"
echo -e "Domena: $DOMAIN"
echo -e "Wildcard: $WILDCARD"
echo -e "${GREEN}========================================${NC}"

echo -e "\n${GREEN}[✓] Setup zakończony!${NC}\n"

echo -e "${BLUE}Status ClusterIssuers:${NC}"
kubectl get clusterissuers

echo -e "\n${BLUE}Status Certificates:${NC}"
kubectl get certificates -A

echo -e "\n${BLUE}Następne kroki:${NC}"
echo -e "1. Sprawdź czy certyfikat jest gotowy:"
echo -e "   ${BLUE}kubectl describe certificate wildcard-tls${NC}"
echo -e ""
echo -e "2. Sprawdź logi Cert Manager:"
echo -e "   ${BLUE}kubectl logs -n cert-manager -l app=cert-manager -f${NC}"
echo -e ""
echo -e "3. Użyj secret w Ingressie:"
echo -e "   ${BLUE}secretName: wildcard-tls-secret${NC}"
