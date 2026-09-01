#!/usr/bin/env bash
set -euo pipefail

create_rolebinding() {
  local namespace="$1"
  local binding="$2"
  local role="$3"
  local group="$4"

  kubectl -n "${namespace}" create rolebinding "${binding}" \
    --clusterrole="${role}" \
    --group="${group}" \
    --dry-run=client -o yaml | kubectl apply -f -
}

create_rolebinding sales sales-viewers pd-viewer propdevelopment:sales-viewers
create_rolebinding sales sales-configurators pd-configurator propdevelopment:sales-configurators

create_rolebinding utilities utilities-viewers pd-viewer propdevelopment:utilities-viewers
create_rolebinding utilities utilities-configurators pd-configurator propdevelopment:utilities-configurators

create_rolebinding smart-home smart-home-viewers pd-viewer propdevelopment:utilities-viewers
create_rolebinding smart-home smart-home-configurators pd-configurator propdevelopment:utilities-configurators

create_rolebinding finance finance-viewers pd-viewer propdevelopment:finance-viewers
create_rolebinding finance finance-configurators pd-configurator propdevelopment:finance-configurators

create_rolebinding data data-viewers pd-viewer propdevelopment:data-viewers
create_rolebinding data data-configurators pd-configurator propdevelopment:data-configurators

kubectl create clusterrolebinding pd-security-auditors \
  --clusterrole=pd-security-auditor \
  --group=propdevelopment:security-auditors \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl create clusterrolebinding pd-cluster-admins \
  --clusterrole=pd-cluster-admin \
  --group=propdevelopment:cluster-admins \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Bindings созданы."
