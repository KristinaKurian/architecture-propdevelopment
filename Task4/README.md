# Task4 — запуск на macOS

## 1. Установка

Если Docker Desktop не установлен:

```bash
brew install --cask docker
open -a Docker
```

Установить инструменты:

```bash
brew install minikube kubectl openssl
```

## 2. Поднять пустой Minikube

```bash
minikube start -p propdevelopment --driver=docker
kubectl config use-context propdevelopment
kubectl get nodes
```

## 3. Выполнить скрипты

```bash
cd Task4
chmod +x 01-create-users.sh 02-create-roles.sh 03-bind-users-to-roles.sh
./01-create-users.sh
./02-create-roles.sh
./03-bind-users-to-roles.sh
```

## 4. Проверить RBAC

### Viewer

```bash
kubectl auth can-i get pods \
  --as=sales-dev \
  --as-group=propdevelopment:sales-viewers \
  -n sales

kubectl auth can-i create deployments \
  --as=sales-dev \
  --as-group=propdevelopment:sales-viewers \
  -n sales

kubectl auth can-i get secrets \
  --as=sales-dev \
  --as-group=propdevelopment:sales-viewers \
  -n sales
```

Ожидается:

```text
yes
no
no
```

### Configurator

```bash
kubectl auth can-i create deployments \
  --as=utilities-devops \
  --as-group=propdevelopment:utilities-configurators \
  -n utilities

kubectl auth can-i create deployments \
  --as=utilities-devops \
  --as-group=propdevelopment:utilities-configurators \
  -n smart-home

kubectl auth can-i get secrets \
  --as=utilities-devops \
  --as-group=propdevelopment:utilities-configurators \
  -n utilities
```

Ожидается:

```text
yes
yes
no
```

### Security auditor

```bash
kubectl auth can-i get secrets \
  --as=security-auditor \
  --as-group=propdevelopment:security-auditors \
  -A

kubectl auth can-i delete secrets \
  --as=security-auditor \
  --as-group=propdevelopment:security-auditors \
  -n finance
```

Ожидается:

```text
yes
no
```

### Cluster admin

```bash
kubectl auth can-i '*' '*' \
  --as=platform-admin \
  --as-group=propdevelopment:cluster-admins
```

Ожидается `yes`.
