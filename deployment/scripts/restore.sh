#!/bin/bash
set -e

if [ -z "$1" ]; then
    echo "[-] Erreur : Veuillez spécifier le chemin de l'archive de sauvegarde."
    echo "Usage : ./scripts/restore.sh ./backups/backup_YYYYMMDD_HHMMSS.tar.gz"
    exit 1
fi

ARCHIVE_PATH="$1"
TEMP_DIR="./backups/temp_restore"

if [ ! -f "$ARCHIVE_PATH" ]; then
    echo "[-] Erreur : L'archive $ARCHIVE_PATH est introuvable."
    exit 1
fi

echo "[+] Extraction de l'archive..."
mkdir -p "$TEMP_DIR"
tar -xzf "$ARCHIVE_PATH" -C "$TEMP_DIR"
EXTRACTED_FOLDER=$(ls -d "$TEMP_DIR"/backup_* | head -n 1)

# 1. Restauration de la base de données MySQL
if [ -f "$EXTRACTED_FOLDER/marketplace_db.sql" ]; then
    echo "[+] Restauration de la base de données MySQL..."
    docker exec -i mysql mysql -u root -proot marketplace_db < "$EXTRACTED_FOLDER/marketplace_db.sql"
else
    echo "[-] Aucun fichier SQL trouvé dans la sauvegarde."
fi

# Nettoyage
rm -rf "$TEMP_DIR"

echo "[+] Restauration terminée avec succès !"
