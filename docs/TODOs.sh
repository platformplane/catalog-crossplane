TODOs

old v1 list: https://github.com/platformplane/catalog-operator/blob/95a60704fe4cb6d6781cbc869fd331c023ea9722/internal/controller/redisserver_controller.go

Testing:
Demo: curl demo:80

ElasticSearch: curl http://elastic:9200/_cluster/health?pretty
- pvc not deleted (possible via chart? via crossplane? otherwise e.g. use existingvolume and create it as part of composition?)

Kafka: 
create file client.properties:
security.protocol=SASL_PLAINTEXT
sasl.mechanism=SCRAM-SHA-256
sasl.jaas.config=org.apache.kafka.common.security.scram.ScramLoginModule required \
    username="user" \
    password="$(kubectl get secret kafka-user-passwords --namespace test -o jsonpath='{.data.client-passwords}' | base64 -d | cut -d , -f 1)";
kubectl run kafka-kafka-client --restart='Never' --image docker.io/bitnami/kafka:3.7.0-debian-12-r0 --namespace test --command -- sleep infinity
kubectl cp --namespace test ./client.properties kafka-kafka-client:/tmp/client.properties
kubectl exec --tty -i kafka-kafka-client --namespace test -- bash
kafka-console-producer.sh \
            --producer.config /tmp/client.properties \
            --broker-list kafka-controller-0.kafka-controller-headless.test.svc.cluster.local:9092 \
            --topic test
kafka-console-consumer.sh \
            --consumer.config /tmp/client.properties \
            --bootstrap-server kafka-controller-0.kafka-controller-headless.test.svc.cluster.local:9092 \
            --topic test --from-beginning


- controller.replicaCount auf 1 (statt default 3) setzen? Latest version geht sonst nicht, evtl. sowieso einfacher? Oder letzte Version nehmen, bei der es mit 3 noch ging?
- PVCs bleiben

MariaDB: kubectl exec -it maria-0 -n test -- mysql -u root -p db
- PVC bleibt

MS SQL:
- mssql is not part of console anymore? but commands shown in UI (never was there, create it, see teams)
- PVC bleibt

Minio: 
mc alias set myminio http://minio:9000 admin mT8cbUPOlD
mc mb myminio/bucket
mc ls myminio

MongoDB:

Postgres: 

RabbitMQ:

Redis: redis-cli -h redis-master -p 6379 -a bLaesXrA1V
- console redis client geht nicht (not authenticated)
console redis client
v crossplane-test
v default/redisserver-sample
^[[17;1RSET key cal
                                                                                                                     ^
 [18;118RINFO
127.0.0.1:6379> INFO
NOAUTH Authentication required.

Allgemein:
- console info zeigt öfters nichts / nicht alles an
- wollen wir den "Server" Suffix in den Namen behalten, z.B. "PostgreSQLServer" oder nur "PostgreSQL"?


dcl-constellation


# Migration Simulation Kind:
kind create cluster --name migration

# install crossplane
helm repo add crossplane-stable https://charts.crossplane.io/stable
helm repo update
helm install crossplane crossplane-stable/crossplane --namespace crossplane-system --create-namespace # --set args='{"--enable-beta-management-policies"}'
kubectl apply -f docs/providers/helm-account.yaml
kubectl apply -f docs/providers/helm.yaml
kubectl apply -f docs/providers/helm-config.yaml

# argocd
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# postgres v1
kubectl apply -f ./docs/catalogv1.yaml
kubectl apply -f ./examples/postgresqlserver.yaml
kubectl exec -it postgresqlserver-sample-0 -- psql -U postgres -d postgres # get password from secret U5CPgBZPPB
CREATE TABLE test_table (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100)
);
INSERT INTO test_table (name) VALUES ('Test Name');
SELECT * FROM test_table;
quit

# delete old catalog and postgresqlserver CRD
kubectl delete -f ./docs/catalogv1.yaml
kubectl edit postgresqlservers.catalog.cluster.local postgresqlserver-sample # remove the finalizer
kubectl delete -f ./examples/postgresqlserver.yaml
kubectl delete crd postgresqlservers.catalog.cluster.local

# remove helm charts (without PVCs)
helm uninstall postgresqlserver-sample

# install crossplane config with new CRDs
kubectl apply -f package/postgresqlserver/definition.yaml
kubectl apply -f package/postgresqlserver/composition.yaml
kubectl apply -f ./examples/postgresqlserver.yaml
kubectl exec -it postgresqlserver-sample-0 -- psql -U postgres -d postgres # new secret generated but the old is still valid :( -> we would also need to patch that if possible
SELECT * FROM test_table;
quit

# kubectl apply -f docs/helm-import.yaml # does not work, statefulset patch fails (no diff in spec)
# kubectl delete statefulset postgresqlserver-sample
# helm upgrade --install postgresqlserver

kind delete cluster --name migration


Upgrade Crossplane and providers


| Kind | Count | 
|---------------------|-------| 
| KafkaServer | 30 | 
| PostgreSQLServer | 36 | 
| DCLConstellation | 3 | 
| MinIOServer | 3 | 
| RedisServer | 1 | 
| TykServer | 1 |

1. Preserve data but let ArgoCD redeploy helm charts (Migration script needed, copying and patching secrets, etc.)
2. Change apiVersion (not catalog.cluster.local/v1 anymore for catalogv2 items)
  - Advantages: 
    - no migration needed
    - we can go to the latest chart versions
    - we can have different api groups for different catalog item origins (platformplane.io, nimbusplane.io, etc.)

3. Inform teams and let it break
