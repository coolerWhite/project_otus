# Project_Otus
### Finally project for OTUS

## Структура:

### beta:
    Попытка поднять K8s cluster, через создание ВМ + ansible
### crawler:

### docker:
    Dockerfile для сборки в GitlabCI
    Docker-compose для локального тестирования
### gitlab-ci:
    Поднятие Gitlab-CI для постоение CI/CD. Поднимается ВМ и устанавливается в Docker Gitlab. Для проекта использовался встроенный сервис YC, т.к возникли проблемы с подключение Runner для K8s ( исп. https://cloud.yandex.ru/docs/managed-gitlab/quickstart?from=int-console-help-center-or-nav )
### k8s:

### terraform:
    Поднимается Kubernetes cluster. Mascter Node - 1, Worker Node - 1, с autoscalling до 3. Также Key Management Service и Cloud Logging
    Содержимое:
    - main.tf
    - variables.tf
    - terraform.tfvars


## Как собрать все?

### Этап 1

Переходим в папку terraform. В terraform.tfvars подставляем свои значения. 
terraform apply --auto-approve
Поднимаем Gitlab-CI:    
1. перейти в папку gitlab-ci > terraform
2. terraform apply
3. IP ВМ вставляем в inventory.yml
4. переходим в gitlab-ci > ansible 
5. ansible-playbook install.yml
6. для получея пароля необходимо зайти на созданную ВМ по SSH и применить команду `docker exec -it id_docker_container grep 'Password:' /etc/gitlab/initial_root_password`

Альтернативный вариант: использовать приложеную инструкцию, для поднятия готового сервиса

Создаем сервисный аккаунт для GitLab в K8s
`kubectl apply -f /k8s/gitlab/gitlab-admin-service-account.yaml`

### Этап 2

Перейти в console.cloud.yandex.ru. Зайти в Managed Service for Kubernetes > Marrketplace, найти GitLab Runner. Подключить в соответствии с инструкцией (https://cloud.yandex.ru/docs/managed-gitlab/tutorials/gitlab-containers)

Для хранения созднанных образов необходим Container Registry ( тут использовался от Yandex ) 
В GitLab экспортируем search_engine_crawler и search_engine_ui
Для search_engine_ui переносим файлы из папки `docker/search_engine_ui`
Для search_engine_crawler переносим файлы из папки `docker/search_engine_crawler`

Dockerfile собираем контейнер
.gitlab-ci.yml настраиваем CI/CD

В .gitlab-ci.yml изменить адресс репозитория контейнеров
`--destination "REPO_NAME:${CI_COMMIT_SHORT_SHA}"`

### Этап 3

Разворачиваем RabbitMQ
`kubectl apply -f /k8s/rabbitmq/rabbit.yaml`

Для работы Rabbit переходим на Web интерфейс по IP Nod ( посмотрев какой порт прокинулся )
Логинимся стандартным логином паролем и создем очередь guest

Разворачиваем Mongodb
`kubectl apply -f /k8s/mongo/mongo.yaml`

### Этап 4

Переносим в GitLab содержимое /k8s/bot и /ui соответственно для автодеплоя
После чего собирается образ

Разворачиваем LoadBalancer для UI и получаем IP для подключения порт 80
`kubectl apply -f /k8s/ LoadBalancer.yaml`


### Этап 5
Проверяем, что все сделали для сборки
- [ ] подняли K8s cluster
- [ ] подняли GitLab
- [ ] установили GitLab Runner в K8s и настроили Runner в GitLab
- [ ] экспортировали приложение в GitLab
- [ ] перенесли Dockerfile и .gitlab-ci.yml в соответствующие репозитории
- [ ] развернут RabbitMQ
- [ ] развернут Mongodb
- [ ] перенесли k8s.yaml в соответствующие репозитории
- [ ] развернут LoadBalancer для UI
- [ ]
- [ ]


<!-- # k8s:

- ingress.yaml - создает балансировщик
- mongo-deploy.yaml - создаем под с монго и PersistentVolume
- mongo-service.yaml - создаем сервис с монго и объединяем ui+mongo
- остальные не используются т.к не заработало

# gitlab:

- **.gitlab-ci.yml - ci\cd для сборки**
- k8s.yaml - манифест создания пода с ui при любом изменении в репо

кластер развренут через terraform 1 master и до 3 worker-node
для хранения контейнеров используется Container Registry ( сервис от YC): развернут руками (потом напишу в terraform)
gitlab поднят руками т.к есть встроенный сервис (добавлю в терраформ (возможно))
на k8s cluster установлен gitlab-runner из маркетплэйса кластера и подключен к gitlab -->