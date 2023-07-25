# project_otus
Finally project for OTUS
# k8s:

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
на k8s cluster установлен gitlab-runner из маркетплэйса кластера и подключен к gitlab