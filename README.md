
to understand (some parts of) ConnectionDetails: read <https://blog.crossplane.io/faq-2-claim-connection-details/>

## TODO
- get the nice secret name set by the user to set as binding again (or does that not make sense?)
- how to get secrets (like password) out of the connection details to combine it with the rest of the connection string to build the URI?
- static uri: =>  []byte(fmt.Sprintf("postgresql://%s:%s@%s:%s/%s", username, password, host, port, database))
- nice names
- folder structure supporting collaboration with third party composition providers
- set helm values more dynamically (via configmap?)
- common labels
- custom username, password?


```
# setup
helm repo add crossplane-stable https://charts.crossplane.io/stable
helm repo update
helm install crossplane crossplane-stable/crossplane --namespace crossplane-system --create-namespace

kubectl apply -f providers/helm-account.yaml
kubectl apply -f providers/helm.yaml
kubectl apply -f providers/helm-config.yaml

kubectl apply -f postgresqlserver/definition.yaml
kubectl apply -f postgresqlserver/composition.yaml

kubectl create ns test

kubectl apply -f examples/postgresqlserver.yaml -n test

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
