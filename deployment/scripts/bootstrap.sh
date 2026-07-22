#!/bin/bash
set -e

echo "[+] Initialisation de l'environnement de production PFA..."

# Création des réseaux externes nécessaires aux configurations Docker Compose
echo "[+] Création des réseaux Docker..."
docker network create devsecops-net || true
docker network create monitoring-net || true
docker network create mail-net || true

# Création des dossiers persistants pour les services
echo "[+] Création des arborescences de données..."
mkdir -p mailserver/mail-data mailserver/mail-state mailserver/mail-logs mailserver/config
mkdir -p prometheus

# Attribution des permissions appropriées
chmod -R 755 mailserver/

echo "[+] Bootstrap terminé avec succès !"
