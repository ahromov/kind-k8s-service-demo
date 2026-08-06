# 🚀 Local Kubernetes (kind) Setup for Java Service

## Вимоги

- Docker
- kubectl
- kind
- Helm
- JDK і Maven/Maven Wrapper

## Встановлення інструментів на Ubuntu

```bash
sudo apt update
sudo apt install -y docker.io curl ca-certificates gnupg lsb-release

sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $USER

curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/kubectl

curl -Lo kind https://kind.sigs.k8s.io/dl/v0.23.0/kind-linux-amd64
chmod +x kind
sudo mv kind /usr/local/bin/kind

curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

docker --version
kubectl version --client
kind version
helm version
```

Після додавання користувача до групи Docker перезайди в систему або виконай `newgrp docker`.

## Запуск локального середовища

Компоненти запускаються окремо: PostgreSQL, kind-кластер та застосунок.

### 1. Запустити PostgreSQL у Docker

```bash
docker compose -f docker/mysql-docker-compose.yml up -d
docker compose -f docker/mysql-docker-compose.yml ps
```

> Назва файла залишена `mysql-docker-compose.yml`, але всередині запускається PostgreSQL.

Зупинити БД:

```bash
docker compose -f docker/mysql-docker-compose.yml down
```

### 2. Створити kind-кластер та встановити ingress-nginx

```bash
chmod +x k8s-one.sh deploy-app.sh
./k8s-one.sh up
```

`k8s-one.sh` виконує лише:

- створення kind-кластера;
- port mappings `80 → 80` і `18443 → 443`;
- встановлення `ingress-nginx`.

Видалити кластер:

```bash
./k8s-one.sh delete
```

### 3. Зібрати й задеплоїти застосунок

```bash
./deploy-app.sh
```

Скрипт виконує Maven build, створює Docker image, завантажує його в kind, застосовує Kubernetes-маніфести й очікує завершення rollout.

Після змін у коді для повторного деплою достатньо знову виконати:

```bash
./deploy-app.sh
```

## Підключення застосунку в kind до PostgreSQL у Docker Desktop

У Kubernetes Deployment використовуй:

```yaml
env:
  - name: SPRING_DATASOURCE_URL
    value: jdbc:postgresql://host.docker.internal:5432/demo_db
  - name: SPRING_DATASOURCE_USERNAME
    value: demo_user
  - name: SPRING_DATASOURCE_PASSWORD
    value: demo_password
```

`localhost` усередині Pod вказує на сам Pod, тому для БД на Docker Desktop потрібен `host.docker.internal`.

## Перевірка

```bash
kubectl get nodes
kubectl get pods,svc,ingress
kubectl logs deployment/my-service --tail=200
```

Swagger UI:

```text
http://localhost/api/swagger-ui/index.html
```
