#!/bin/bash
# Script d'automatisation pour Docker Bench Security

echo "[*] Lancement de l'audit de sécurité Docker..."

# Vérifier si docker-bench-security est présent localement ou le lancer via conteneur
docker run --net host --pid host --userns host --cap-add audit_control \
    -v /var:/var:ro \
    -v /etc:/etc:ro \
    -v /usr/bin/docker:/usr/bin/docker:ro \
    -v /var/run/docker.sock:/var/run/docker.sock:ro \
    --label docker_bench_security \
    docker/docker-bench-security

echo "[*] Audit terminé. Vérifiez les rapports ci-dessus."
