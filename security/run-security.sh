#!/bin/bash
set -e

echo "======================================================"
echo "[*] Lancement de la suite d'audits de sécurité DevSecOps"
echo "======================================================"

# 1. Test Gitleaks (Recherche de secrets dans le code source)
echo -e "\n[+] 1. Exécution de Gitleaks (Secrets & Tokens)..."
# On pointe vers le dossier racine du projet (.. depuis le dossier security)
if gitleaks detect --config gitleaks.toml --source ../ -v; then
    echo "[✔] Gitleaks : Aucun secret détecté."
else
    echo "[!] Gitleaks : Attention, des correspondances ou secrets potentiels ont été trouvés."
fi

# 2. Test Trivy (Analyse des vulnérabilités et fichiers de config)
echo -e "\n[+] 2. Exécution de Trivy (Vulnérabilités & Configurations)..."
if trivy fs --config trivy.yaml ../ ; then
    echo "[✔] Trivy : Analyse terminée."
else
    echo "[!] Trivy : Des alertes de niveau CRITICAL ou HIGH ont été détectées."
fi

# 3. Test Docker Bench Security (Sécurité de l'hôte et de Docker)
echo -e "\n[+] 3. Exécution de Docker Bench Security..."
if bash docker-bench.sh ; then
    echo "[✔] Docker Bench : Audit terminé."
else
    echo "[!] Docker Bench : Des recommandations de sécurité Docker nécessitent votre attention."
fi

echo -e "\n======================================================"
echo "[*] Tous les audits de sécurité sont terminés avec succès !"
echo "======================================================"
