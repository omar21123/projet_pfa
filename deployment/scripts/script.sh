#!/usr/bin/env bash
###############################################################################
# souk_api_test.sh
#
# Script de test / seed pour l'API "Souk" (Swagger fourni).
# Il gère automatiquement :
#   - création de comptes clients (mobile + web)   x N
#   - création de comptes vendeurs (web)           x N
#   - login / refresh / logout
#   - création de catégories                       x N
#   - listing / activation / désactivation de catégories
#   - actions admin sur les vendeurs (verify / approve / reject / reset)
#   - endpoints divers (countries, test, health)
#
# Dépendances : curl, jq
#   Ubuntu/Debian : sudo apt-get install -y curl jq
#
# Utilisation :
#   chmod +x souk_api_test.sh
#   BASE_URL="https://api.example.com" ADMIN_TOKEN="xxx" ./souk_api_test.sh
#
# Toutes les variables ci-dessous peuvent être surchargées via l'environnement
# avant de lancer le script, ou en éditant directement le fichier.
###############################################################################

set -uo pipefail

# ----------------------------------------------------------------------------
# CONFIGURATION
# ----------------------------------------------------------------------------
BASE_URL="${BASE_URL:-http://localhost:8000}"      # <-- adapte l'URL de ton API
COUNT="${COUNT:-20}"                                # nombre d'éléments créés par boucle
ADMIN_TOKEN="${ADMIN_TOKEN:-}"                       # token d'un admin déjà existant
                                                      # (requis pour /api/admin/*)
OUT_DIR="./souk_api_run_$(date +%Y%m%d_%H%M%S)"
LOG_FILE="${OUT_DIR}/run.log"

mkdir -p "${OUT_DIR}"

# Stockage des identifiants générés (pour réutilisation dans le script)
CUSTOMER_TOKENS_FILE="${OUT_DIR}/customer_tokens.txt"
VENDOR_TOKENS_FILE="${OUT_DIR}/vendor_tokens.txt"
VENDOR_IDS_FILE="${OUT_DIR}/vendor_ids.txt"
CATEGORY_IDS_FILE="${OUT_DIR}/category_ids.txt"

: > "${CUSTOMER_TOKENS_FILE}"
: > "${VENDOR_TOKENS_FILE}"
: > "${VENDOR_IDS_FILE}"
: > "${CATEGORY_IDS_FILE}"

# ----------------------------------------------------------------------------
# UTILITAIRES
# ----------------------------------------------------------------------------
log() {
    echo -e "$(date '+%H:%M:%S') | $*" | tee -a "${LOG_FILE}"
}

check_deps() {
    for bin in curl jq; do
        if ! command -v "${bin}" >/dev/null 2>&1; then
            echo "ERREUR: '${bin}' est requis mais introuvable. Installe-le puis relance." >&2
            exit 1
        fi
    done
}

# api_call METHOD PATH JSON_BODY [TOKEN] [EXTRA_CURL_ARGS...]
# Écrit la réponse dans stdout, le code HTTP dans la variable globale HTTP_CODE
api_call() {
    local method="$1"
    local path="$2"
    local body="${3:-}"
    local token="${4:-}"
    shift 4 2>/dev/null || shift $#

    local -a headers=(-H "Content-Type: application/json" -H "Accept: application/json")
    if [[ -n "${token}" ]]; then
        headers+=(-H "Authorization: Bearer ${token}")
    fi

    local resp
    if [[ -n "${body}" ]]; then
        resp=$(curl -sS -w '\n%{http_code}' -X "${method}" "${BASE_URL}${path}" \
            "${headers[@]}" -d "${body}" "$@")
    else
        resp=$(curl -sS -w '\n%{http_code}' -X "${method}" "${BASE_URL}${path}" \
            "${headers[@]}" "$@")
    fi

    HTTP_CODE=$(echo "${resp}" | tail -n1)
    RESP_BODY=$(echo "${resp}" | sed '$d')
    echo "${RESP_BODY}"
}

rand_suffix() {
    # génère un suffixe court unique (timestamp + random)
    echo "$(date +%s%N)_${RANDOM}"
}

# ----------------------------------------------------------------------------
# 0. HEALTH CHECK & TEST ROUTE
# ----------------------------------------------------------------------------
step0_health() {
    log "=== [0] Health check & route de test ==="

    api_call GET "/health" >/dev/null
    log "GET /health -> HTTP ${HTTP_CODE}"

    api_call GET "/api/test" >/dev/null
    log "GET /api/test -> HTTP ${HTTP_CODE}"
}

# ----------------------------------------------------------------------------
# 1. COUNTRIES
# ----------------------------------------------------------------------------
step1_countries() {
    log "=== [1] Récupération des pays ==="
    local resp
    resp=$(api_call GET "/api/countries")
    log "GET /api/countries -> HTTP ${HTTP_CODE}"
    echo "${resp}" > "${OUT_DIR}/countries.json"
}

# ----------------------------------------------------------------------------
# 2. CRÉATION DE COMPTES CLIENTS (mobile) x COUNT
# ----------------------------------------------------------------------------
step2_register_customers() {
    log "=== [2] Création de ${COUNT} comptes clients (mobile) ==="
    for i in $(seq 1 "${COUNT}"); do
        local suffix email body resp token
        suffix=$(rand_suffix)
        email="customer_${suffix}@example.com"
        body=$(jq -n \
            --arg fn "Client${i}" \
            --arg ln "Test" \
            --arg em "${email}" \
            --arg pw "Password123!" \
            --arg ph "+21260000${i}00" \
            --arg bd "1995-01-01" \
            '{first_name:$fn,last_name:$ln,email:$em,password:$pw,phone_number:$ph,birth_date:$bd,gender:1}')

        resp=$(api_call POST "/api/auth/mobile/register" "${body}")
        if [[ "${HTTP_CODE}" == "201" ]]; then
            token=$(echo "${resp}" | jq -r '.access_token // empty')
            echo "${email}:${token}" >> "${CUSTOMER_TOKENS_FILE}"
            log "  [OK] Client ${i}/${COUNT} créé (${email})"
        else
            log "  [FAIL] Client ${i}/${COUNT} -> HTTP ${HTTP_CODE} : $(echo "${resp}" | jq -c '.' 2>/dev/null || echo "${resp}")"
        fi
    done
}

# ----------------------------------------------------------------------------
# 3. CRÉATION DE COMPTES VENDEURS (web) x COUNT
# ----------------------------------------------------------------------------
step3_register_vendors() {
    log "=== [3] Création de ${COUNT} comptes vendeurs (web) ==="
    for i in $(seq 1 "${COUNT}"); do
        local suffix email body resp token
        suffix=$(rand_suffix)
        email="vendor_${suffix}@example.com"
        body=$(jq -n \
            --arg fn "Vendeur${i}" \
            --arg ln "Test" \
            --arg em "${email}" \
            --arg pw "Password123!" \
            --arg ph "+21261111${i}00" \
            --arg bd "1990-06-15" \
            --arg sn "Boutique ${i}" \
            --arg desc "Boutique de test numéro ${i}" \
            '{first_name:$fn,last_name:$ln,email:$em,password:$pw,phone_number:$ph,birth_date:$bd,gender:1,store_name:$sn,description:$desc}')

        resp=$(api_call POST "/api/auth/web/vendor/register" "${body}")
        if [[ "${HTTP_CODE}" == "201" ]]; then
            token=$(echo "${resp}" | jq -r '.access_token // empty')
            echo "${email}:${token}" >> "${VENDOR_TOKENS_FILE}"
            log "  [OK] Vendeur ${i}/${COUNT} créé (${email})"
        else
            log "  [FAIL] Vendeur ${i}/${COUNT} -> HTTP ${HTTP_CODE} : $(echo "${resp}" | jq -c '.' 2>/dev/null || echo "${resp}")"
        fi
    done
}

# ----------------------------------------------------------------------------
# 4. LOGIN / REFRESH / LOGOUT (mobile) sur le premier client créé
# ----------------------------------------------------------------------------
step4_login_refresh_logout_demo() {
    log "=== [4] Démo login / refresh / logout (mobile) ==="
    local first_line email
    first_line=$(head -n1 "${CUSTOMER_TOKENS_FILE}" 2>/dev/null || true)
    if [[ -z "${first_line}" ]]; then
        log "  Aucun client disponible pour la démo, étape ignorée."
        return
    fi
    email=$(echo "${first_line}" | cut -d: -f1)

    local body resp access refresh
    body=$(jq -n --arg em "${email}" --arg pw "Password123!" '{email:$em,password:$pw}')
    resp=$(api_call POST "/api/auth/mobile/login" "${body}")
    log "  POST /api/auth/mobile/login -> HTTP ${HTTP_CODE}"
    access=$(echo "${resp}" | jq -r '.access_token // empty')
    refresh=$(echo "${resp}" | jq -r '.Refresh_token // empty')

    if [[ -n "${refresh}" ]]; then
        body=$(jq -n --arg rt "${refresh}" '{refresh_token:$rt}')
        resp=$(api_call POST "/api/auth/mobile/refresh" "${body}")
        log "  POST /api/auth/mobile/refresh -> HTTP ${HTTP_CODE}"
        refresh=$(echo "${resp}" | jq -r '.refresh_token // empty')

        body=$(jq -n --arg rt "${refresh}" '{refresh_token:$rt}')
        resp=$(api_call POST "/api/auth/mobile/logout" "${body}")
        log "  POST /api/auth/mobile/logout -> HTTP ${HTTP_CODE}"
    fi
}

# ----------------------------------------------------------------------------
# 5. CRÉATION DE CATÉGORIES x COUNT (+ listing / activation / désactivation)
# ----------------------------------------------------------------------------
step5_categories() {
    log "=== [5] Création de ${COUNT} catégories ==="
    local admin_hdr=()
    if [[ -n "${ADMIN_TOKEN}" ]]; then
        admin_hdr=("${ADMIN_TOKEN}")
    fi

    for i in $(seq 1 "${COUNT}"); do
        local suffix body resp id
        suffix=$(rand_suffix)
        body=$(jq -n --arg n "Categorie ${i} ${suffix}" '{Name:$n}')
        resp=$(api_call POST "/api/categories/create" "${body}" "${ADMIN_TOKEN}")
        if [[ "${HTTP_CODE}" == "201" ]]; then
            id=$(echo "${resp}" | jq -r '.data.ID // .data.id // .id // empty' 2>/dev/null)
            [[ -n "${id}" ]] && echo "${id}" >> "${CATEGORY_IDS_FILE}"
            log "  [OK] Catégorie ${i}/${COUNT} créée (id=${id:-inconnu})"
        else
            log "  [FAIL] Catégorie ${i}/${COUNT} -> HTTP ${HTTP_CODE} : $(echo "${resp}" | jq -c '.' 2>/dev/null || echo "${resp}")"
        fi
    done

    log "--- Listing des catégories racines ---"
    api_call GET "/api/categories?page=1&perPage=50" "" "${ADMIN_TOKEN}" >/dev/null
    log "GET /api/categories -> HTTP ${HTTP_CODE}"

    local first_id
    first_id=$(head -n1 "${CATEGORY_IDS_FILE}" 2>/dev/null || true)
    if [[ -n "${first_id}" ]]; then
        api_call GET "/api/categories/${first_id}/children" "" "${ADMIN_TOKEN}" >/dev/null
        log "GET /api/categories/${first_id}/children -> HTTP ${HTTP_CODE}"

        api_call PUT "/api/categories/${first_id}/deactivate-subtree" "" "${ADMIN_TOKEN}" >/dev/null
        log "PUT /api/categories/${first_id}/deactivate-subtree -> HTTP ${HTTP_CODE}"

        api_call PUT "/api/categories/${first_id}/activate" "" "${ADMIN_TOKEN}" >/dev/null
        log "PUT /api/categories/${first_id}/activate -> HTTP ${HTTP_CODE}"
    fi
}

# ----------------------------------------------------------------------------
# 6. ADMIN : enregistrement d'un nouvel admin (nécessite ADMIN_TOKEN)
# ----------------------------------------------------------------------------
step6_admin_register() {
    log "=== [6] Création d'un nouvel administrateur ==="
    if [[ -z "${ADMIN_TOKEN}" ]]; then
        log "  ADMIN_TOKEN non fourni -> étape ignorée (authentification admin requise)."
        return
    fi
    local suffix body resp
    suffix=$(rand_suffix)
    body=$(jq -n \
        --arg fn "Admin" --arg ln "Nouveau" \
        --arg em "admin_${suffix}@example.com" \
        --arg pw "Secret123*" \
        --arg ph "+33600000000" \
        --arg bd "1990-04-12" \
        --arg cin "AB${suffix:0:6}" \
        --arg emp "EMP-${suffix:0:6}" \
        --arg pos "Support Manager" \
        --arg hd "2026-07-12 09:00:00" \
        '{first_name:$fn,last_name:$ln,email:$em,password:$pw,phone_number:$ph,birth_date:$bd,gender:1,cin:$cin,employee_number:$emp,position:$pos,hire_date:$hd}')

    resp=$(api_call POST "/api/admin/register" "${body}" "${ADMIN_TOKEN}")
    log "POST /api/admin/register -> HTTP ${HTTP_CODE} : $(echo "${resp}" | jq -c '.' 2>/dev/null || echo "${resp}")"
}

# ----------------------------------------------------------------------------
# 7. ADMIN : gestion des vendeurs (liste + verify/approve/reject/reset)
# ----------------------------------------------------------------------------
step7_admin_vendors() {
    log "=== [7] Gestion admin des vendeurs ==="
    if [[ -z "${ADMIN_TOKEN}" ]]; then
        log "  ADMIN_TOKEN non fourni -> étape ignorée (authentification admin requise)."
        return
    fi

    local resp ids
    resp=$(api_call GET "/api/admin/vendors?page=1&page_size=${COUNT}" "" "${ADMIN_TOKEN}")
    log "GET /api/admin/vendors -> HTTP ${HTTP_CODE}"
    echo "${resp}" > "${OUT_DIR}/admin_vendors_list.json"

    # Tente d'extraire des IDs de vendeurs depuis la réponse (structure suppose data.items[].id ou data[].id)
    ids=$(echo "${resp}" | jq -r '[.data.items[]?.id, .data[]?.id] | flatten | unique | .[]' 2>/dev/null)
    if [[ -n "${ids}" ]]; then
        echo "${ids}" > "${VENDOR_IDS_FILE}"
    fi

    if [[ ! -s "${VENDOR_IDS_FILE}" ]]; then
        log "  Impossible de déterminer automatiquement les vendorProfileId depuis la réponse."
        log "  -> Renseigne manuellement ${VENDOR_IDS_FILE} (un id par ligne) puis relance step7 seule si besoin."
        return
    fi

    local n=0
    while IFS= read -r vid; do
        [[ -z "${vid}" ]] && continue
        n=$((n+1))
        [[ "${n}" -gt "${COUNT}" ]] && break

        api_call POST "/api/admin/vendors/${vid}/verify-identity" \
            '{"verification_notes":"Vérifié automatiquement par script"}' "${ADMIN_TOKEN}" >/dev/null
        log "  vendor ${vid} : verify-identity -> HTTP ${HTTP_CODE}"

        api_call POST "/api/admin/vendors/${vid}/approve" \
            '{"verification_notes":"Approuvé automatiquement par script"}' "${ADMIN_TOKEN}" >/dev/null
        log "  vendor ${vid} : approve -> HTTP ${HTTP_CODE}"
    done < "${VENDOR_IDS_FILE}"
}

# ----------------------------------------------------------------------------
# MAIN
# ----------------------------------------------------------------------------
main() {
    check_deps
    log "Démarrage du script — BASE_URL=${BASE_URL}  COUNT=${COUNT}"
    log "Résultats et logs stockés dans : ${OUT_DIR}"

    step0_health
    step1_countries
    step2_register_customers
    step3_register_vendors
    step4_login_refresh_logout_demo
    step5_categories
    step6_admin_register
    step7_admin_vendors

    log "=== Terminé ==="
    log "Comptes clients : ${CUSTOMER_TOKENS_FILE}"
    log "Comptes vendeurs : ${VENDOR_TOKENS_FILE}"
    log "Catégories créées : ${CATEGORY_IDS_FILE}"
}

main "$@"
