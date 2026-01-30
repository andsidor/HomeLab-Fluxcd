#!/bin/bash
# setup-cloudflare-tunnel.sh - Setup Cloudflare Tunnel with External Secrets Operator

set -e

# Kolory dla output'u
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Cloudflare Tunnel Setup ===${NC}\n"

# 1. Sprawdzić czy cloudflared jest zainstalowany
if ! command -v cloudflared &> /dev/null; then
    echo -e "${YELLOW}[!] cloudflared nie jest zainstalowany${NC}"
    echo -e "${BLUE}Instaluję cloudflared...${NC}"
    
    if command -v apt-get &> /dev/null; then
        curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
        sudo dpkg -i cloudflared.deb
        rm cloudflared.deb
    elif command -v brew &> /dev/null; then
        brew install cloudflare/cloudflare/cloudflared
    else
        echo -e "${RED}[ERROR] Nie mogę zainstalować cloudflared${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}[OK] cloudflared zainstalowany${NC}"

# 2. Sprawdzić czy kubectl jest zainstalowany
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}[ERROR] kubectl nie jest zainstalowany${NC}"
    exit 1
fi

echo -e "${GREEN}[OK] kubectl zainstalowany${NC}"

# 3. Sprawdzić czy gcloud jest zainstalowany
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}[ERROR] gcloud CLI nie jest zainstalowany${NC}"
    exit 1
fi

echo -e "${GREEN}[OK] gcloud zainstalowany${NC}"

# 4. Ustawić projekt GCP
PROJECT_ID=$(gcloud config get-value project 2>/dev/null || echo "")
if [ -z "$PROJECT_ID" ]; then
    echo -e "${RED}[ERROR] Brak ustawionego projektu GCP${NC}"
    exit 1
fi

echo -e "${GREEN}[OK] Projekt GCP: ${PROJECT_ID}${NC}"

# 4.5 Sprawdzić czy Cloudflare jest uwierzytelniony
echo -e "\n${BLUE}[0.5/4] Sprawdzam uwierzytelnienie Cloudflare...${NC}"
CERT_FILE="$HOME/.cloudflared/cert.pem"

if [ ! -f "$CERT_FILE" ]; then
    echo -e "${YELLOW}[!] Brak certyfikatu Cloudflare - potrzebna uwierzytelnianie${NC}"
    echo -e "${BLUE}[!] Otwórz przeglądarkę i zaloguj się na Cloudflare...${NC}"
    cloudflared login
    
    if [ ! -f "$CERT_FILE" ]; then
        echo -e "${RED}[ERROR] Nie udało się uzyskać certyfikatu${NC}"
        exit 1
    fi
    echo -e "${GREEN}[OK] Certyfikat Cloudflare pobrano${NC}"
else
    echo -e "${GREEN}[OK] Certyfikat Cloudflare istnieje${NC}"
fi

# 5. Tworzy tunelu Cloudflare
echo -e "\n${BLUE}[1/4] Tworzę Cloudflare Tunnel...${NC}"

TUNNEL_NAME="homelab-tunnel"
CREDENTIALS_FILE="$HOME/.cloudflared/${TUNNEL_NAME}.json"

# Sprawdzić czy tunel już istnieje
if [ -f "$CREDENTIALS_FILE" ]; then
    echo -e "${YELLOW}[!] Plik poświadczeń już istnieje: $CREDENTIALS_FILE${NC}"
    read -p "Czy chcesz go zastąpić? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}[!] Używam istniejącego tunelu${NC}"
    else
        cloudflared tunnel delete $TUNNEL_NAME --force 2>/dev/null || true
        cloudflared tunnel create $TUNNEL_NAME
    fi
else
    echo -e "${BLUE}[!] Tworzę nowy tunel...${NC}"
    cloudflared tunnel create $TUNNEL_NAME
fi

echo -e "${GREEN}[OK] Tunel Cloudflare: $TUNNEL_NAME${NC}"

# 6. Pobrać token tunelu
if [ -f "$CREDENTIALS_FILE" ]; then
    TUNNEL_ID=$(cat $CREDENTIALS_FILE | jq -r '.TunnelID')
    ACCOUNT_ID=$(cat $CREDENTIALS_FILE | jq -r '.AccountTag')
    echo -e "${GREEN}[OK] Tunnel ID: ${TUNNEL_ID}${NC}"
    echo -e "${GREEN}[OK] Account ID: ${ACCOUNT_ID}${NC}"
else
    echo -e "${RED}[ERROR] Nie mogę znaleźć pliku poświadczeń${NC}"
    exit 1
fi

# 7. Zapisać credentials do Google Secret Manager
echo -e "\n${BLUE}[2/4] Zapisuję credentials do Google Secret Manager...${NC}"

SECRET_NAME="cloudflare-tunnel-credentials"

# Sprawdzić czy secret już istnieje
if gcloud secrets describe $SECRET_NAME --project=$PROJECT_ID &> /dev/null; then
    echo -e "${YELLOW}[!] Secret '$SECRET_NAME' już istnieje, aktualizuję...${NC}"
    cat $CREDENTIALS_FILE | gcloud secrets versions add $SECRET_NAME \
        --data-file=- \
        --project=$PROJECT_ID
else
    echo -e "${BLUE}[!] Tworzę nowy secret...${NC}"
    cat $CREDENTIALS_FILE | gcloud secrets create $SECRET_NAME \
        --data-file=- \
        --project=$PROJECT_ID
fi

echo -e "${GREEN}[OK] Credentials zapisane w Google Secret Manager${NC}"

# 8. Zapisać Token do osobnego sekretu
echo -e "\n${BLUE}[3/4] Zapisuję Token do Google Secret Manager...${NC}"

# Pobrać token z certyfikatu Cloudflare
TOKEN_FILE="$HOME/.cloudflared/cert.pem"
if [ -f "$TOKEN_FILE" ]; then
    SECRET_TOKEN_NAME="cloudflare-tunnel-token"
    if gcloud secrets describe $SECRET_TOKEN_NAME --project=$PROJECT_ID &> /dev/null; then
        cat $TOKEN_FILE | gcloud secrets versions add $SECRET_TOKEN_NAME \
            --data-file=- \
            --project=$PROJECT_ID
    else
        cat $TOKEN_FILE | gcloud secrets create $SECRET_TOKEN_NAME \
            --data-file=- \
            --project=$PROJECT_ID
    fi
    echo -e "${GREEN}[OK] Token zapisany w Google Secret Manager${NC}"
else
    echo -e "${YELLOW}[!] Brak pliku tokenu: $TOKEN_FILE${NC}"
fi

# 9. Podsumowanie
echo -e "\n${BLUE}[4/4] Podsumowanie${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "Tunel Cloudflare: ${TUNNEL_NAME}"
echo -e "Tunnel ID: ${TUNNEL_ID}"
echo -e "Account ID: ${ACCOUNT_ID}"
echo -e "Projekt GCP: ${PROJECT_ID}"
echo -e "Secret Manager:"
echo -e "  - cloudflare-tunnel-credentials"
echo -e "  - cloudflare-tunnel-token"
echo -e "${GREEN}========================================${NC}"

echo -e "\n${GREEN}[✓] Setup zakończony!${NC}\n"

echo -e "${BLUE}Następne kroki:${NC}"
echo -e "1. Deploy Cloudflare Tunnel w Kubernetes:"
echo -e "   ${BLUE}kubectl apply -k ./k8s/infra/Cloudflare/${NC}"
echo -e ""
echo -e "2. Sprawdzić status tunelu:"
echo -e "   ${BLUE}kubectl get pods -n cloudflare${NC}"
echo -e ""
echo -e "3. Sprawdzić logi:"
echo -e "   ${BLUE}kubectl logs -n cloudflare -l app=cloudflare-tunnel -f${NC}"
echo -e ""
echo -e "4. Konfiguracja w Cloudflare Dashboard:"
echo -e "   ${BLUE}https://dash.cloudflare.com/${NC}"
echo -e ""
echo -e "${RED}⚠️  WAŻNE:${NC}"
echo -e "${RED}   Pliki ~/.cloudflared/*.json zawierają wrażliwe dane!${NC}"
echo -e "${RED}   Nigdy nie commituj ich do Gita${NC}"
