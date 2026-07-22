#!/bin/bash
set -e

BACKUP_DIR="./backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_PATH="$BACKUP_DIR/backup_$TIMESTAMP"

mkdir -p "$BACKUP_PATH"

echo "[+] Création de la sauvegarde (Timestamp: $TIMESTAMP)..."

# 1. Sauvegarde de la base de données MySQL
echo "[+] Export de la base de données MySQL..."
docker exec mysql mysqldump -u root -proot marketplace_db > "$BACKUP_PATH/marketplace_db.sql"

# 2. Sauvegarde des fichiers de configuration et d'environnement
echo "[+] Copie des fichiers de configuration..."
cp docker-compose.yml "$BACKUP_PATH/"
cp docker-compose.mail.yml "$BACKUP_PATH/"
cp mailserver.env "$BACKUP_PATH/" 2>/dev/null || true

# 3. Compression de l'archive
echo "[+] Compression de l'archive de sauvegarde..."
tar -czf "$BACKUP_DIR/backup_$TIMESTAMP.tar.gz" -C "$BACKUP_DIR" "backup_$TIMESTAMP"
rm -rf "$BACKUP_PATH"

echo "[+] Sauvegarde réussie : $BACKUP_DIR/backup_$TIMESTAMP.tar.gz"
