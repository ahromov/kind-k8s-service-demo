#!/usr/bin/env bash
set -euo pipefail

# =========================
# CONFIG (міняй якщо треба)
# =========================
CLUSTER_NAME="${CLUSTER_NAME:-kind}"
IMAGE_NAME="${IMAGE_NAME:-my-service}"
IMAGE_TAG="${IMAGE_TAG:-1.0}"
DEPLOY_NAME="${DEPLOY_NAME:-my-service}"
HOST_NAME="${HOST_NAME:-localhost}"
HOST_HTTP_PORT="${HOST_HTTP_PORT:-80}"
HOST_HTTPS_PORT="${HOST_HTTPS_PORT:-18443}"

APP_YAML="${APP_YAML:-k8s/app.yaml}"
INGRESS_YAML="${INGRESS_YAML:-k8s/ingress.yaml}"

ACTION="${1:-up}"   # up | redeploy | delete

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
    --set controller.service.type=ClusterIP

  echo "==> Waiting for ingress controller..."
  kubectl wait -n ingress-nginx \
    --for=condition=ready pod \
    -l app.kubernetes.io/component=controller \
    --timeout=240s
}

build_image() {
  echo "==> Building app (maven) + docker image..."
  if [ -f "mvnw" ]; then
    ./mvnw -DskipTests clean package
  else
    need mvn
    mvn -DskipTests clean package
  fi
  docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" .
}

load_image_into_kind() {
  echo "==> Loading image into kind..."
  kind load docker-image "${IMAGE_NAME}:${IMAGE_TAG}" --name "${CLUSTER_NAME}"
}

apply_manifests() {
  test -f "${APP_YAML}" || { echo "❌ ${APP_YAML} not found"; exit 1; }
  test -f "${INGRESS_YAML}" || { echo "❌ ${INGRESS_YAML} not found"; exit 1; }

  # Optional secret file (not in git)
  SECRET_YAML="${SECRET_YAML:-k8s/secret.yaml}"
  if [ -f "${SECRET_YAML}" ]; then
    echo "==> Applying optional secret: ${SECRET_YAML}"
    kubectl apply -f "${SECRET_YAML}"
  else
    echo "==> Optional secret not found: ${SECRET_YAML}"
    echo "    If you need it, create it and re-run the script. Example:"
    echo "      kubectl create secret generic my-service-db-secret \\"
    echo "        --from-literal=SPRING_DATASOURCE_USERNAME=postgres \\"
    echo "        --from-literal=SPRING_DATASOURCE_PASSWORD=postgres"
    echo "    (Or create ${SECRET_YAML} and it will be applied automatically.)"
  fi

  echo "==> Applying manifests: ${APP_YAML}, ${INGRESS_YAML}"
  kubectl apply -f "${APP_YAML}"
  kubectl apply -f "${INGRESS_YAML}"

  echo "==> Waiting for rollout..."
  kubectl rollout status "deploy/${DEPLOY_NAME}" --timeout=240s || true
}

print_status() {
  echo
  echo "==> kind control-plane ports:"
  docker ps --format "table {{.Names}}\t{{.Ports}}" | grep kind-control-plane || true
  echo
  echo "==> Kubernetes status:"
  kubectl get pods,svc,ingress | cat
  echo
  echo "✅ DONE"
  echo "Open:"
  echo "  http://${HOST_NAME}:${HOST_HTTP_PORT}/api/swagger-ui/index.html"
  echo "Quick check:"
  echo "  curl -i -H \"Host: ${HOST_NAME}\" http://${HOST_NAME}:${HOST_HTTP_PORT}/api/swagger-ui/index.html"
}

# =========================
# MAIN
# =========================
need docker
need kind
need kubectl
need helm

case "${ACTION}" in
  up)
    echo "==> Creating kind config with port mappings (${HOST_HTTP_PORT}->80, ${HOST_HTTPS_PORT}->443)"

    echo "==> Recreating kind cluster '${CLUSTER_NAME}' (so port mappings are guaranteed)"
    kind delete cluster --name "${CLUSTER_NAME}" >/dev/null 2>&1 || true
    kind create cluster --name "${CLUSTER_NAME}" --config k8s/kind-ingress.yaml

    echo "==> Checking nodes..."
    kubectl get nodes

    install_ingress
    build_image
    load_image_into_kind
    apply_manifests
    print_status
    ;;
  redeploy)
    echo "==> Redeploy (no cluster recreate)..."
    build_image
    load_image_into_kind
    kubectl rollout restart "deploy/${DEPLOY_NAME}"
    kubectl rollout status "deploy/${DEPLOY_NAME}" --timeout=240s
    print_status
    ;;
  delete)
    echo "==> Deleting kind cluster '${CLUSTER_NAME}'"
    kind delete cluster --name "${CLUSTER_NAME}"
    ;;
  *)
    echo "Usage:"
    echo "  ./k8s-one.sh up        # recreate kind with port mappings + ingress + deploy"
    echo "  ./k8s-one.sh redeploy  # rebuild image + load + restart deployment"
    echo "  ./k8s-one.sh delete    # delete kind cluster"
    exit 1
    ;;
esac
