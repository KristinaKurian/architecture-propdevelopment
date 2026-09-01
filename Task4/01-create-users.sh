#!/usr/bin/env bash
set -euo pipefail

# Учебный скрипт для macOS + Minikube.
# Создаёт X.509 client certificates и kubeconfig contexts.

PROFILE="${MINIKUBE_PROFILE:-propdevelopment}"
OUTPUT_DIR="${OUTPUT_DIR:-./users}"
CERT_DAYS="${CERT_DAYS:-365}"

CA_CERT="${HOME}/.minikube/ca.crt"
CA_KEY="${HOME}/.minikube/ca.key"

for cmd in kubectl minikube openssl; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "$cmd не найден. Установите через Homebrew."
    exit 1
  fi
done

if ! minikube status -p "${PROFILE}" >/dev/null 2>&1; then
  echo "Minikube profile '${PROFILE}' не запущен."
  echo "Запустите: minikube start -p ${PROFILE} --driver=docker"
  exit 1
fi

if [[ ! -f "${CA_CERT}" || ! -f "${CA_KEY}" ]]; then
  echo "Не найдены CA-файлы Minikube: ${CA_CERT}, ${CA_KEY}"
  exit 1
fi

mkdir -p "${OUTPUT_DIR}"
chmod 700 "${OUTPUT_DIR}"
OPENSSL_BIN="$(command -v openssl)"

create_user() {
  local username="$1"
  local group="$2"
  local key="${OUTPUT_DIR}/${username}.key"
  local csr="${OUTPUT_DIR}/${username}.csr"
  local crt="${OUTPUT_DIR}/${username}.crt"
  local context="${username}@${PROFILE}"

  echo "Создаю ${username} -> ${group}"

  "${OPENSSL_BIN}" genrsa -out "${key}" 2048
  "${OPENSSL_BIN}" req -new -key "${key}" -out "${csr}" -subj "/CN=${username}/O=${group}"
  "${OPENSSL_BIN}" x509 -req -in "${csr}" -CA "${CA_CERT}" -CAkey "${CA_KEY}" -CAcreateserial -out "${crt}" -days "${CERT_DAYS}" -sha256

  chmod 600 "${key}" "${crt}"

  kubectl config set-credentials "${username}" \
    --client-certificate="${crt}" \
    --client-key="${key}" \
    --embed-certs=true >/dev/null

  kubectl config set-context "${context}" \
    --cluster="${PROFILE}" \
    --user="${username}" >/dev/null

  echo "  context: ${context}"
}

create_user "sales-dev"        "propdevelopment:sales-viewers"
create_user "utilities-devops" "propdevelopment:utilities-configurators"
create_user "security-auditor" "propdevelopment:security-auditors"
create_user "platform-admin"   "propdevelopment:cluster-admins"

rm -f "${OUTPUT_DIR}"/*.csr "${OUTPUT_DIR}"/*.srl 2>/dev/null || true

echo
echo "Пользователи созданы."
kubectl config get-contexts
