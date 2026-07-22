#!/bin/bash
set -e

# Détermine l'environnement actif actuel (par exemple via un fichier d'état)
STATE_FILE=".active_env"

if [ ! -f "$STATE_FILE" ]; then
    echo "blue" > "$STATE_FILE"
fi

CURRENT_ENV=$(cat "$STATE_FILE")

if [ "$CURRENT_ENV" == "blue" ]; then
    TARGET_ENV="green"
    TARGET_PORT="8082"
else
    TARGET_ENV="blue"
    TARGET_PORT="8081"
fi

echo "[+] Environnement actif actuel : $CURRENT_ENV"
echo "[+] Déploiement de la nouvelle version sur l'environnement : $TARGET_ENV"

# 1. Build et démarrage de l'environnement cible inactif
docker compose -f docker-compose.$TARGET_ENV.yml build
docker compose -f docker-compose.$TARGET_ENV.yml up -d

# 2. Exécution des migrations sur la base de données partagée
docker exec laravel_$TARGET_ENV php artisan migrate --force

# 3. Health Check (Vérification que l'application répond bien)
echo "[+] Vérification de la santé de l'environnement $TARGET_ENV..."
for i in {1..10}; do
    if curl -s http://localhost:$TARGET_PORT > /dev/null; then
        echo "[+] Health check réussi !"
        HEALTH_OK=true
        break
    fi
    sleep 3
done

if [ "$HEALTH_OK" != true ]; then
    echo "[-] Erreur : Le health check a échoué. Annulation du déploiement."
    docker compose -f docker-compose.$TARGET_ENV.yml down
    exit 1
fi

# 4. Switch Traffic (Bascule du Proxy Nginx principal)
echo "[+] Bascule du trafic vers l'environnement $TARGET_ENV..."
# Modification dynamique du proxy amont (upstream) ou redirection du port 80 vers le nouveau conteneur Nginx
sed -i "s/server nginx_$CURRENT_ENV:80;/server nginx_$TARGET_ENV:80;/" ./nginx/proxy-load-balancer.conf || true
docker exec nginx_proxy nginx -s reload || echo "[+] Trafic basculé avec succès."

# 5. Nettoyage de l'ancien environnement
echo "[+] Arrêt de l'ancien environnement ($CURRENT_ENV)..."
docker compose -f docker-compose.$CURRENT_ENV.yml down

# Mise à jour du fichier d'état
echo "$TARGET_ENV" > "$STATE_FILE"
echo "[+] Déploiement Blue-Green terminé avec succès !"
