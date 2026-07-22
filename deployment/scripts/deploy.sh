#!/bin/bash
set -e

echo "[+] Lancement du déploiement de la production..."

# 1. Mise à jour du code source (si exécuté depuis un runner ou hook)
# git pull origin main

# 2. Construction et déploiement de la stack principale
echo "[+] Construction et démarrage des conteneurs applicatifs..."
docker compose -f docker-compose.yml build --no-cache
docker compose -f docker-compose.yml up -d --remove-orphans

# 3. Démarrage du serveur mail et du monitoring
echo "[+] Démarrage du serveur mail et de la stack de monitoring..."
docker compose -f docker-compose.mail.yml up -d --remove-orphans
docker compose -f docker-compose.monitor.yml up -d --remove-orphans

# 4. Exécution des migrations de base de données Laravel
echo "[+] Exécution des migrations de la base de données..."
docker exec laravel php artisan migrate --force
docker exec laravel php artisan config:cache
docker exec laravel php artisan route:cache

echo "[+] Déploiement terminé avec succès !"
