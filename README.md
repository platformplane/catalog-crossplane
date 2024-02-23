
```
# setup
helm repo add crossplane-stable https://charts.crossplane.io/stable
helm repo update
helm install crossplane crossplane-stable/crossplane --namespace crossplane-system --create-namespace # --set args='{"--enable-external-secret-stores"}' 

kubectl apply -f providers/helm-account.yaml
# wait a bit
kubectl apply -f providers/helm.yaml
# wait a bit more
kubectl apply -f providers/helm-config.yaml

kubectl apply -f postgresqlserver/definition.yaml
kubectl apply -f postgresqlserver/composition.yaml

kubectl create ns test

kubectl apply -f examples/postgresqlserver.yaml -n test

kubectl get postgresqlservers catalog.cluster.local -n test   

kubectl get postgresqlserver postgresqlserver-sample -n test -o jsonpath='{.spec.resourceRef.name}' # gives you the according composite

kubectl get postgresqlservercomposite postgresqlserver-sample-8fz7t -o jsonpath='{.metadata.uid}' # or .status.binding.name or .spec.writeConnectionSecretToRef.name gives you the name of the corresponding secret 

kubectl get secret 50f606c7-743d-4392-a807-8a6a417b7bcf -n crossplane-system


# cycle
kubectl delete -f examples/postgresqlserver.yaml -n test
kubectl delete -f postgresqlserver/definition.yaml
kubectl delete -f postgresqlserver/composition.yaml
kubectl apply -f postgresqlserver/definition.yaml
kubectl apply -f postgresqlserver/composition.yaml
kubectl apply -f examples/postgresqlserver.yaml -n test


# connect to pg
kubectl run -n test -it --rm --image=postgres:latest postgres-client -- psql -h 10.96.193.248 -U postgres -d postgres --password

kubectl run -n default -it --rm --image=postgres:latest postgres-client -- psql -h postgresqlserver-sample-5n5z7-6nkz9.test -U postgres -d postgres --password
```


## TODO
- folder structure supporting collaboration with third party composition providers
- custom username, password? secret darf nicht im claim sein, da man es in Argo sieht
- build package



