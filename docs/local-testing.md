# test ocally e.g. in kind

```
# setup
helm repo add crossplane-stable https://charts.crossplane.io/stable
helm repo update
helm install crossplane crossplane-stable/crossplane --namespace crossplane-system --create-namespace # --set args='{"--enable-external-secret-stores"}' 

kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=crossplane --namespace crossplane-system --timeout=120s

kubectl create secret docker-registry gitlab-nimbus-registry --docker-server=registry.nimbusplane.io --docker-username=platform --docker-password=glpat-x -n crossplane-system
kubectl patch serviceaccount crossplane -p '{"imagePullSecrets": [{"name": "gitlab-nimbus-registry"}]}' -n crossplane-system

kubectl apply -f providers/kubernetes.yaml
kubectl apply -f providers/helm-account.yaml
# wait a bit
kubectl apply -f providers/helm.yaml
kubectl apply -f providers/helm-config.yaml

kubectl apply -f postgresqlserver/definition.yaml
kubectl apply -f postgresqlserver/composition.yaml

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



