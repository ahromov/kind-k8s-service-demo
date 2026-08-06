#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="${CLUSTER_NAME:-kind}"
HOST_HTTP_PORT="${HOST_HTTP_PORT:-80}"
HOST_HTTPS_PORT="${HOST_HTTPS_PORT:-18443}"
ACTION="${1:-up}" # up | delete
NODE_COUNT="${2:-${NODE_COUNT:-1}}" # total: 1 control-plane + workers

need() { command -v "$1" >/dev/null 2>&1 || { echo "❌ Missing: $1"; exit 1; }; }

create_kind_config() {
  local config_file="$1"
  local worker_count=$((NODE_COUNT - 1))

  {
    echo "kind: Cluster"
    echo "apiVersion: kind.x-k8s.io/v1alpha4"
    echo "nodes:"
    echo "  - role: control-plane"
    echo "    kubeadmConfigPatches:"
    echo "      - |"
    echo "        kind: InitConfiguration"
    echo "        nodeRegistration:"
    echo "          kubeletExtraArgs:"
    echo '            node-labels: "ingress-ready=true"'
    echo "    extraPortMappings:"
    echo "      - containerPort: 80"
    echo "        hostPort: ${HOST_HTTP_PORT}"
    echo "        protocol: TCP"
    echo "      - containerPort: 443"
    echo "        hostPort: ${HOST_HTTPS_PORT}"
    echo "        protocol: TCP"

    for ((i = 1; i <= worker_count; i++)); do
      echo "  - role: worker"
    done
  } >"${config_file}"
}

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
    --set-string controller.nodeSelector.ingress-ready=true \
    --set controller.tolerations[0].key=node-role.kubernetes.io/control-plane \
    --set controller.tolerations[0].operator=Exists \
    --set controller.tolerations[0].effect=NoSchedule \
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
    if ! [[ "${NODE_COUNT}" =~ ^[1-9][0-9]*$ ]]; then
      echo "❌ Node count must be a positive integer: ${NODE_COUNT}"
      exit 1
    fi

    KIND_CONFIG="$(mktemp)"
    trap 'rm -f "${KIND_CONFIG}"' EXIT
    create_kind_config "${KIND_CONFIG}"

    echo "==> Creating kind config with port mappings (${HOST_HTTP_PORT}->80, ${HOST_HTTPS_PORT}->443)"
    echo "==> Recreating kind cluster '${CLUSTER_NAME}' with ${NODE_COUNT} node(s)"
    kind delete cluster --name "${CLUSTER_NAME}" >/dev/null 2>&1 || true
    kind create cluster --name "${CLUSTER_NAME}" --config "${KIND_CONFIG}"

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
    echo "  ./k8s-one.sh up [nodes]  # recreate kind + install ingress (default: 1)"
    echo "  ./k8s-one.sh delete      # delete kind cluster"
    echo
    echo "Examples:"
    echo "  ./k8s-one.sh up 3"
    echo "  NODE_COUNT=3 ./k8s-one.sh up"
    exit 1
    ;;
esac
