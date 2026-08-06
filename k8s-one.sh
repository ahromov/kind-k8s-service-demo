#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="${CLUSTER_NAME:-kind}"
HOST_HTTP_PORT="${HOST_HTTP_PORT:-80}"
HOST_HTTPS_PORT="${HOST_HTTPS_PORT:-18443}"
ACTION="${1:-up}" # up | delete

need() { command -v "$1" >/dev/null 2>&1 || { echo "❌ Missing: $1"; exit 1; }; }

install_ingress() {
  echo "==> Installing/Upgrading ingress-nginx..."
  helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx >/dev/null 2>&1 || true
  helm repo update >/dev/null

  helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
    -n ingress-nginx --create-namespace \
    --set controller.hostPort.enabled=true \
    --set controller.hostPort.ports.http=80 \
    --set controller.hostPort.ports.https=443 \
    --set controller.service.type=ClusterIP \
    --set controller.progressDeadlineSeconds=600

  echo "==> Waiting for ingress controller..."
  kubectl wait -n ingress-nginx \
    --for=condition=ready pod \
    -l app.kubernetes.io/component=controller \
    --timeout=240s
}

need docker
need kind
need kubectl
need helm

case "${ACTION}" in
  up)
    test -f k8s/kind-ingress.yaml || { echo "❌ k8s/kind-ingress.yaml not found"; exit 1; }
    echo "==> Creating kind config with port mappings (${HOST_HTTP_PORT}->80, ${HOST_HTTPS_PORT}->443)"
    echo "==> Recreating kind cluster '${CLUSTER_NAME}'"
    kind delete cluster --name "${CLUSTER_NAME}" >/dev/null 2>&1 || true
    kind create cluster --name "${CLUSTER_NAME}" --config k8s/kind-ingress.yaml

    echo "==> Waiting for node..."
    kubectl wait --for=condition=Ready node --all --timeout=120s
    install_ingress

    echo
    kubectl get nodes
    kubectl get pods,svc -n ingress-nginx
    echo
    echo "✅ Cluster and ingress are ready"
    echo "Deploy the application separately: ./deploy-app.sh"
    ;;
  delete)
    echo "==> Deleting kind cluster '${CLUSTER_NAME}'"
    kind delete cluster --name "${CLUSTER_NAME}"
    ;;
  *)
    echo "Usage:"
    echo "  ./k8s-one.sh up      # recreate kind + install ingress"
    echo "  ./k8s-one.sh delete  # delete kind cluster"
    exit 1
    ;;
esac
