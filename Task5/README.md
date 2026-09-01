# Task5 — управление трафиком внутри Kubernetes

## Сервисы

В namespace `task5` развёрнуты четыре nginx-сервиса:

- `front-end-app` — `role=front-end`
- `back-end-api-app` — `role=back-end-api`
- `admin-front-end-app` — `role=admin-front-end`
- `admin-back-end-api-app` — `role=admin-back-end-api`

Разрешены только пары:

- `front-end` ↔ `back-end-api`
- `admin-front-end` ↔ `admin-back-end-api`

Трафик между обычным и административным контурами запрещён.

## Запуск Minikube на Mac

NetworkPolicy требует CNI, который умеет применять сетевые политики. Для Minikube используем Calico:

```bash
minikube delete -p propdevelopment
minikube start -p propdevelopment --driver=docker --cni=calico
kubectl config use-context propdevelopment
```

Проверка:

```bash
kubectl get pods -n kube-system
```

## Развернуть сервисы

```bash
kubectl apply -f services.yaml
kubectl get pods -n task5 --show-labels
kubectl get svc -n task5
```

## Применить сетевые политики

```bash
kubectl apply -f non-admin-api-allow.yaml
kubectl get networkpolicy -n task5
```

Ожидаемые политики:

```text
default-deny-all
allow-dns
non-admin-api-allow
admin-api-allow
```

## Проверка разрешённого трафика

```bash
kubectl exec -n task5 front-end-app --   wget -qO- --timeout=2 http://back-end-api-app
```

Должен вернуться HTML nginx.

```bash
kubectl exec -n task5 back-end-api-app --   wget -qO- --timeout=2 http://front-end-app
```

Должен вернуться HTML nginx.

```bash
kubectl exec -n task5 admin-front-end-app --   wget -qO- --timeout=2 http://admin-back-end-api-app
```

Должен вернуться HTML nginx.

```bash
kubectl exec -n task5 admin-back-end-api-app --   wget -qO- --timeout=2 http://admin-front-end-app
```

Должен вернуться HTML nginx.

## Проверка запрещённого трафика

```bash
kubectl exec -n task5 front-end-app --   wget -qO- --timeout=2 http://admin-back-end-api-app
```

Ожидается timeout / ошибка.

```bash
kubectl exec -n task5 admin-front-end-app --   wget -qO- --timeout=2 http://back-end-api-app
```

Ожидается timeout / ошибка.

## Зачем нужны три типа политик

`default-deny-all` запрещает ingress и egress для всех Pods namespace.

`non-admin-api-allow` разрешает TCP/80 только внутри пары:

```text
front-end ↔ back-end-api
```

`admin-api-allow` разрешает TCP/80 только внутри пары:

```text
admin-front-end ↔ admin-back-end-api
```

`allow-dns` разрешает egress в CoreDNS. Без этого после `default-deny-all` сервисы не смогут обращаться друг к другу по Kubernetes DNS-именам.

## Матрица доступа

| Source | Destination | Доступ |
|---|---|---|
| `front-end` | `back-end-api` | ✅ |
| `back-end-api` | `front-end` | ✅ |
| `admin-front-end` | `admin-back-end-api` | ✅ |
| `admin-back-end-api` | `admin-front-end` | ✅ |
| `front-end` | `admin-back-end-api` | ❌ |
| `admin-front-end` | `back-end-api` | ❌ |
| обычный контур | административный контур | ❌ |
