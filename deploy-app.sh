#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="${CLUSTER_NAME:-kind}"
IMAGE_NAME="${IMAGE_NAME:-my-service}"
IMAGE_TAG="${IMAGE_TAG:-1.0}"
DEPLOY_NAME="${DEPLOY_NAME:-my-service}"
HOST_NAME="${HOST_NAME:-localhost}"
HOST_HTTP_PORT="${HOST_HTTP_PORT:-80}"
APP_YAML="${APP_YAML:-app/app.yaml}"
CONFIGMAP_YAML="${CONFIGMAP_YAML:-app/configmap.yaml}"
SERVICE_YAML="${SERVICE_YAML:-app/service.yaml}"
INGRESS_YAML="${INGRESS_YAML:-app/ingress.yaml}"
SECRET_YAML="${SECRET_YAML:-app/secret.yaml}"
INGRESS_NAMESPACE="${INGRESS_NAMESPACE:-ingress-nginx}"
INGRESS_DEPLOYMENT="${INGRESS_DEPLOYMENT:-ingress-nginx-controller}"

need() { command -v "$1" >/dev/null 2>&1 || { echo "❌ Missing: $1"; exit 1; }; }

need docker
need kind
need kubectl

kind get clusters | grep -qx "${CLUSTER_NAME}" || {
  echo "❌ kind cluster '${CLUSTER_NAME}' not found. Run ./k8s-one.sh up first."
  exit 1
}

test -f "${APP_YAML}" || { echo "❌ ${APP_YAML} not found"; exit 1; }
test -f "${CONFIGMAP_YAML}" || { echo "❌ ${CONFIGMAP_YAML} not found"; exit 1; }
test -f "${SERVICE_YAML}" || { echo "❌ ${SERVICE_YAML} not found"; exit 1; }
test -f "${INGRESS_YAML}" || { echo "❌ ${INGRESS_YAML} not found"; exit 1; }

echo "==> Building application..."
if [ -f mvnw ]; then
  ./mvnw -DskipTests clean package
else
  need mvn
  mvn -DskipTests clean package
fi

echo "==> Building Docker image ${IMAGE_NAME}:${IMAGE_TAG}..."
docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" .

echo "==> Loading image into kind cluster '${CLUSTER_NAME}'..."
kind load docker-image "${IMAGE_NAME}:${IMAGE_TAG}" --name "${CLUSTER_NAME}"

if [ -f "${SECRET_YAML}" ]; then
  echo "==> Applying optional secret: ${SECRET_YAML}"
  kubectl apply -f "${SECRET_YAML}"
fi

echo "==> Applying manifests..."
kubectl apply -f "${CONFIGMAP_YAML}"
kubectl apply -f "${SERVICE_YAML}"
kubectl apply -f "${APP_YAML}"

if ! kubectl get deployment "${INGRESS_DEPLOYMENT}" \
  --namespace "${INGRESS_NAMESPACE}" >/dev/null 2>&1; then
  echo "❌ Ingress controller not found. Run ./k8s-one.sh up first."
  exit 1
fi

echo "==> Waiting for ingress controller..."
kubectl rollout status "deployment/${INGRESS_DEPLOYMENT}" \
  --namespace "${INGRESS_NAMESPACE}" \
  --timeout=300s

echo "==> Applying ingress..."
kubectl apply -f "${INGRESS_YAML}"

echo "==> Restarting deployment..."
kubectl rollout restart "deployment/${DEPLOY_NAME}"
kubectl rollout status "deployment/${DEPLOY_NAME}" --timeout=240s

echo
kubectl get pods,svc,ingress
echo
echo "✅ Application deployed"
echo "Open: http://${HOST_NAME}:${HOST_HTTP_PORT}/api/swagger-ui/index.html"