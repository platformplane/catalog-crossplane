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
kubectl apply -f ./examples/postgresql.yaml
kubectl exec -it postgresql-sample-0 -- psql -U postgres -d postgres # get password from secret U5CPgBZPPB
CREATE TABLE test_table (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100)
);
INSERT INTO test_table (name) VALUES ('Test Name');
SELECT * FROM test_table;
quit

# delete old catalog and postgresql CRD
kubectl delete -f ./docs/catalogv1.yaml
kubectl edit postgresqls.catalog.cluster.local postgresql-sample # remove the finalizer
kubectl delete -f ./examples/postgresql.yaml
kubectl delete crd postgresqls.catalog.cluster.local

# remove helm charts (without PVCs)
helm uninstall postgresql-sample

# install crossplane config with new CRDs
kubectl apply -f package/postgresql/definition.yaml
kubectl apply -f package/postgresql/composition.yaml
kubectl apply -f ./examples/postgresql.yaml
kubectl exec -it postgresql-sample-0 -- psql -U postgres -d postgres # new secret generated but the old is still valid :( -> we would also need to patch that if possible
SELECT * FROM test_table;
quit

# kubectl apply -f docs/helm-import.yaml # does not work, statefulset patch fails (no diff in spec)
# kubectl delete statefulset postgresql-sample
# helm upgrade --install postgresql

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
