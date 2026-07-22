#!/bin/bash
set -e

DOMAINS=("votre-domaine.com" "www.votre-domaine.com")
EMAIL="admin@votre-domaine.com"
DATA_PATH="./nginx/certbot"
RSA_KEY_SIZE=4096

if [ -d "$DATA_PATH" ]; then
    read -p "Des certificats existants ont été trouvés. Voulez-vous les remplacer ? (y/N) " decision
    if [ "$decision" != "Y" ] && [ "$decision" != "y" ]; then
        exit
    fi
fi

echo "[+] Téléchargement des paramètres TLS recommandés..."
mkdir -p "$DATA_PATH/conf"
curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf > "$DATA_PATH/conf/options-ssl-nginx.conf"
curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot/certbot/ssl-dhparams.pem > "$DATA_PATH/conf/ssl-dhparams.pem"

echo "[+] Génération d'un certificat factice pour démarrer Nginx..."
path="/etc/letsencrypt/live/${DOMAINS[0]}"
mkdir -p "$DATA_PATH/conf/live/${DOMAINS[0]}"
docker run --rm --entrypoint "\
  openssl req -x509 -nodes -newkey rsa:$RSA_KEY_SIZE -days 1\
    -keyout '$path/privkey.pem' \
    -out '$path/fullchain.pem' \
    -subj '/CN=localhost'" "$DATA_PATH/conf"

echo "[+] Démarrage de Nginx..."
docker compose -f docker-compose.yml up -d nginx

echo "[+] Suppression du certificat factice..."
docker run --rm --entrypoint "\
  rm -Rf /etc/letsencrypt/live/${DOMAINS[0]} && \
  rm -Rf /etc/letsencrypt/archive/${DOMAINS[0]} && \
  rm -Rf /etc/letsencrypt/renewal/${DOMAINS[0]}.conf" certbot/certbot

echo "[+] Demande du vrai certificat Let's Encrypt..."
DOMAIN_ARGS=""
for domain in "${DOMAINS[@]}"; do
  DOMAIN_ARGS="$DOMAIN_ARGS -d $domain"
done

docker run --rm -it \
  -v "$DATA_PATH/conf:/etc/letsencrypt" \
  -v "$DATA_PATH/www:/var/www/certbot" \
  certbot/certbot certonly --webroot -w /var/www/certbot \
    --email "$EMAIL" \
    $DOMAIN_ARGS \
    --rsa-key-size "$RSA_KEY_SIZE" \
    --agree-tos \
    --force-renewal

echo "[+] Redémarrage de Nginx pour appliquer les certificats..."
docker compose -f docker-compose.yml restart nginx
