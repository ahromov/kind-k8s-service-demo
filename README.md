# 🚀 Local Kubernetes (kind) Setup for Java Service — ALL IN ONE

ЦЕ **ОДИН MARKDOWN-ФАЙЛ**.  
ВСЕ ВСТАНОВЛЕННЯ — **В ОДНОМУ РОЗДІЛІ**.

---

## Вимоги

- Ubuntu 20.04+
- sudo
- Інтернет

---

## ### Встановити

```bash
# ===== SYSTEM UPDATE =====
sudo apt update

# ===== BASE TOOLS =====
sudo apt install -y \
  docker.io \
  curl \
  ca-certificates \
  gnupg \
  lsb-release

# ===== DOCKER =====
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $USER

# ===== kubectl =====
curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/kubectl

# ===== kind =====
curl -Lo kind https://kind.sigs.k8s.io/dl/v0.23.0/kind-linux-amd64
chmod +x kind
sudo mv kind /usr/local/bin/kind

# ===== Helm =====
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# ===== CHECK =====
docker --version
kubectl version --client
kind version
helm version

echo "DONE. Logout/login or run: newgrp docker"
