# test locally e.g. in kind

```
# setup
helm repo add crossplane-stable https://charts.crossplane.io/stable
helm repo update
helm install crossplane crossplane-stable/crossplane --namespace crossplane-system --create-namespace # --set args='{"--enable-external-secret-stores"}' 


kubectl create secret docker-registry gitlab-nimbus-registry --docker-server=registry.nimbusplane.io --docker-username=platform --docker-password=glpat-x -n crossplane-system
kubectl patch serviceaccount crossplane -p '{"imagePullSecrets": [{"name": "gitlab-nimbus-registry"}]}' -n crossplane-system

# install dependencies like providers and configs, see [prerequisites](../prerequisites.md)

kubectl create ns test

kubectl get postgresqlservers catalog.cluster.local -n test   

kubectl get postgresqlserver postgresqlserver-sample -n test -o jsonpath='{.spec.resourceRef.name}' # gives you the according composite

kubectl get postgresqlservercomposite postgresqlserver-sample-8fz7t -o jsonpath='{.spec.writeConnectionSecretToRef.name}' # or .status.binding.name or .metadata.uid gives you the name of the corresponding secret 

kubectl get secret 50f606c7-743d-4392-a807-8a6a417b7bcf -n crossplane-system


# cycle
kubectl delete -f examples/dclconstellation.yaml -n test
kubectl delete -f package/dclconstellation/definition.yaml
kubectl delete -f package/dclconstellation/composition.yaml
kubectl apply -f package/dclconstellation/definition.yaml
kubectl apply -f package/dclconstellation/composition.yaml
kubectl apply -f examples/dclconstellation.yaml -n test

kubectl delete -f examples -n test
kubectl apply -f examples -n test

# connect to pg
kubectl run -n test -it --rm --image=postgres:latest postgres-client -- psql -h 10.96.193.248 -U postgres -d postgres --password

kubectl run -n default -it --rm --image=postgres:latest postgres-client -- psql -h postgresqlserver-sample.test -U postgres -d postgres --password jölkjlö

kubectl run my-postgresql-client --rm --tty -i --restart='Never' --namespace default --image docker.io/bitnami/postgresql:16.2.0-debian-12-r5 --env="PGPASSWORD=$POSTGRES_PASSWORD" \
      --command -- psql --host my-postgresql -U postgres -d postgres -p 5432
```



Outdated migration docu:
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