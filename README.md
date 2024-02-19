
```
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



kubectl delete -f examples/postgresqlserver.yaml -n test
kubectl delete -f postgresqlserver/definition.yaml
kubectl delete -f postgresqlserver/composition.yaml

kubectl apply -f postgresqlserver/definition.yaml
kubectl apply -f postgresqlserver/composition.yaml

kubectl create ns test

kubectl apply -f examples/postgresqlserver.yaml -n test


```

## TODO
- nice names
- static host: => DNS NAME (servicename + namespace)
- static uri: =>  []byte(fmt.Sprintf("postgresql://%s:%s@%s:%s/%s", username, password, host, port, database))
- folder structure supporting collaboration with third party composition providers
- set values more dynamically (via configmap?)
- common labels
- custom username, password?

kubectl run -n test  -it --rm --image=postgres:latest postgres-client -- psql -h 10.96.193.248 -U postgres -d postgres --password

kubectl run -n default  -it --rm --image=postgres:latest postgres-client -- psql -h postgresqlserver-sample-lfv27-n6hmw.test -U postgres -d postgres --password