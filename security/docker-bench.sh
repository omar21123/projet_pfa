#!/bin/bash
echo "[*] Lancement de l'audit de sécurité Docker..."

sudo docker run --rm --net host --pid host --userns host --cap-add audit_control \
    -v /var/lib:/var/lib:ro \
    -v /var/run/docker.sock:/var/run/docker.sock:ro \
    docker/docker-bench-security

echo "[*] Audit terminé."
