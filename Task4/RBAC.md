# Task 4. Ролевой доступ к Kubernetes

## Ролевая модель

| Роль | Права роли | Группы пользователей |
| --- | --- | --- |
| `pd-viewer` | Только просмотр ресурсов в назначенном namespace: Pods, Deployments, StatefulSets, DaemonSets, Jobs, CronJobs, Services, Endpoints, ConfigMaps, Ingress, NetworkPolicy, HPA, PDB, Events и логи Pods. **Нет доступа к Secrets и нет прав на изменение ресурсов.** | Разработчики и инженеры продуктовых команд соответствующего домена: `propdevelopment:sales-viewers`, `propdevelopment:utilities-viewers`, `propdevelopment:finance-viewers`, `propdevelopment:data-viewers` |
| `pd-configurator` | Просмотр и изменение прикладных ресурсов в назначенном namespace: Deployments, StatefulSets, DaemonSets, Jobs, CronJobs, Services, ConfigMaps, Ingress, NetworkPolicy, HPA, PDB; просмотр Pods/Logs/Events. **Нет доступа к Secrets, RBAC, Nodes и управлению namespace.** | DevOps-инженеры и инженеры по эксплуатации соответствующего домена: `propdevelopment:sales-configurators`, `propdevelopment:utilities-configurators`, `propdevelopment:finance-configurators`, `propdevelopment:data-configurators` |
| `pd-security-auditor` | Кластерный read-only аудит: просмотр ресурсов, RBAC, NetworkPolicy и **Secrets**; просмотр логов и событий. Не может создавать, изменять или удалять ресурсы. | Специалист по ИБ / аудиторы: `propdevelopment:security-auditors` |
| `pd-cluster-admin` | Полное администрирование Kubernetes: все API groups, ресурсы и действия, включая Secrets, RBAC, namespaces и cluster-scoped ресурсы. | Ограниченная группа платформенных администраторов / старших DevOps: `propdevelopment:cluster-admins` |

## Разграничение по организационной структуре

Для доменов PropDevelopment создаются отдельные namespaces:

- `sales` — сервисы продаж;
- `utilities` — ЖКУ и сервисы собственников;
- `finance` — финансовые сервисы;
- `data` — DWH, BI и отчётность;
- `smart-home` — новый интеграционный контур «Умный дом».

`pd-viewer` и `pd-configurator` определены как `ClusterRole`, но выдаются через `RoleBinding` только в нужных namespaces. Это позволяет переиспользовать одну роль и одновременно изолировать продуктовые команды друг от друга.

Группа `propdevelopment:utilities-configurators` получает права конфигуратора также в `smart-home`, поскольку новые сервисы «Умный дом» относятся к функциям для собственников.

`pd-security-auditor` выдаётся через `ClusterRoleBinding`, так как ИБ должна иметь возможность проводить аудит всего кластера. Право чтения `Secrets` вынесено только в privileged-группы.

`pd-cluster-admin` также является кластерной ролью и должна назначаться минимальному количеству пользователей.

## Примеры пользователей

| Пользователь | Kubernetes group | Назначение |
| --- | --- | --- |
| `sales-dev` | `propdevelopment:sales-viewers` | Разработчик домена продаж, read-only |
| `utilities-devops` | `propdevelopment:utilities-configurators` | DevOps домена ЖКУ/Smart Home |
| `security-auditor` | `propdevelopment:security-auditors` | Специалист ИБ, кластерный аудит и просмотр Secrets |
| `platform-admin` | `propdevelopment:cluster-admins` | Полный администратор кластера |