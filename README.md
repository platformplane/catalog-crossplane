# catalog-items

The items shown in the catalog v2 are developed here.

Reference to old catalog v1 controllers: [here](https://github.com/platformplane/catalog-operator/blob/95a60704fe4cb6d6781cbc869fd331c023ea9722/internal/controller)

![catalogv1ui](catalogv1ui.png)

## Repo Overview

- [package](./package/) This is the "root" folder for the Crossplane package that we build here, it consists of:
  - [configuration.yaml](./package/configuration.yaml) This yaml file (kind: Configuration) specifies that this is a Crossplane package, on which version of Crossplane it depends and which CRDs it provides.
  - [<catalog-item>](./package/redis/) For every catalog item, there is a subfolder containing the Crossplane composition and definition files.
- [Dockerfile](Dockerfile) The Dockerfile uses the Crossplane CLI to build and push the Crossplane configuration package (OCI image) to a registry (may be useful for local testing).
- [.github/workflows](./.github/workflows/build-publish-images.yaml) The GitHub pipeline calculates a version number and builds the Crossplane package on every commit.

## Update Strategy of Catalog Items

We assume that minor versions can be updated without breaking changes. This means that the `spec.forProvider.chart.version` field in the Crossplane configuration can be updated within the same minor version (anyways, read the release notes to be sure). Note that this field only specifies the default version (if no version is specified in the claim, there is a patch in every configuration with a map transformation). Most of the times, therefore, you need to update the versions in the map patch in the composition file. Applying the latest Crossplane configuration will replace the Helm release with the new version and therefore cause downtime and potentially issues for the customers!

For more thoughts, see [here](https://teams.microsoft.com/l/message/19:8bb1df955bf04679b4f55fe9a1609cb8@thread.tacv2/1712520692322?tenantId=ccce7f5e-a35f-4bc3-8e63-b2215e7d14f9&groupId=8c054c7f-925b-4071-9dd2-adfdc9fa7fe0&parentMessageId=1712520692322&teamName=Platform%20Plane&channelName=Platform&createdTime=1712520692322).

Updating a minor version may be a two-step process where you do not update the version in all (three) places but instead first add the new version in the second map:
  
  ```yaml
              - type: ToCompositeFieldPath
                fromFieldPath: "spec.forProvider.chart.version"
                toFieldPath: "spec.version"
                transforms:
                  - type: map
                    map:
                      "21.1.0": "8" # add this as new version
                      "20.0.4": "8" # keep this line so you do not get an error saying it can't find this version in the map until all charts are updated to 21.1.0
  ```

## Create the Crossplane package locally

### Via Dockerfile (no need to install Crossplane CLI)

Manually build the Dockerfile like (adjust the URLs to match Docker Hub if needed, not sure whether it works with Docker Hub though as I never successfully tested that):

```bash
REGISTRY_PASSWORD=glpat-... docker buildx build --progress=plain --secret id=registry-password,env=REGISTRY_PASSWORD --build-arg DOCKER_REGISTRY=registry.nimbusplane.io --build-arg IMAGE_VERSION=0.0.1 --build-arg CACHEBUST=$(date +%s) --build-arg REGISTRY_IMAGE=registry.nimbusplane.io/common/lgt/platform/catalog-items .
```

The CACHEBUST is not really needed but useful when amending git commits or testing locally with the same version number.

### Via Crossplane CLI

```bash
cd package
echo $REGISTRY_PASSWORD | docker login -u $REGISTRY_USERNAME --password-stdin
crossplane xpkg build --package-file catalog-items.xpkg
crossplane xpkg push --package-files catalog-items.xpkg index.docker.io/platformplane/platform-catalog:0.0.1
```

## Catalog Integration

The Crossplane operator runs in the Platform space and watches the ConfigMap `crossplane` in the namespace `platformplane` which contains a list of Crossplane packages to be installed. This allows us to combine catalog items from different source (e.g. some "simple common" items from the platformplane Docker Hub, and some Nimbus or LGT DEV specific items from their respective registries).

```yaml
apiVersion: v1
kind: ConfigMap
data:
  packages.yaml: |
    - name: platform-catalog
      package: index.docker.io/platformplane/platform-catalog:0.1.0-rc.9
    - name: catalog-items-nimbus
      package: registry.nimbusplane.io/common/lgt/platform/catalog-items:0.1.0-rc.2
```

Please note that removing an entry from this list will not remove the Crossplane definitions (along with the CRDs and CRs). In case you want to remove all resources of a specific package (inlcuding all instances!), you need to delete the configuration package from `configurations.pkg.crossplane.io`.

If the packages are to be fetched from private registries, Crossplane needs package pull secrets (similar to ImagePullSecrets) to be able to pull the packages. This is done by the platform (gitlab-operator). It creates the secret `default-registry` in the `crossplane-system` namespace similar to:

```bash
kubectl create secret docker-registry default-registry --docker-server=registry.nimbusplane.io --docker-username=spacename --docker-password=glpat-... -n crossplane-system
```

Furthermore, it adds the username and password again to the data section of this secret so that helm.crossplane.io/v1beta1 resources can reference it in their spec.forProvider.chart.pullSecretRef section.

The secret will look like this in the cluster:

```yaml
apiVersion: v1
kind: Secret
type: kubernetes.io/dockerconfigjson
data:
  username: Y29tbW9u
  password: Z2xw...
  .dockerconfigjson: >-
    eyJhdX.....
```

The encoded part is basically a docker config.json file:
  
```json
{
  "auths": {
    "registry.nimbusplane.io": {
      "username": "spacename",
      "password": "glpat-...",
      "auth": "..."
    }
  }
}
```

In order that the catalog actually shows your items, you need to make sure the Crossplane compositions and definitions are in the correct API group and version. Furthermore, the definition will need some specific annotations (e.g. containing an encoded .svc catalog item, description, etc.) to be shown in the catalog. Please refer to the existing items in the `package` folder for examples.

## How to add a new catalog item

- create a new subfolder in the `package` folder to develop your catalog item
- add your Crossplane composition and definition files
- verify that the pipeline builds the Crossplane package successfully
- use e.g. lgtdev.com to test your catalog item
  - add the package to the `crossplane` ConfigMap in the `platformplane` namespace
  - create a secret in the `crossplane-system` namespace to allow Crossplane to pull the package from the registry (if not anyways there already)
  - restart the Crossplane operator pod (in the platformplane namespace) (probably not needed!?)
  - check the catalog v2 UI for your new item
  - create a new instance of your catalog item via the UI
- iterate until you are happy
- if everything works, create a merge request, assign it to a Nimbus team member and ask for a review
- merge the merge request after it got approved
- if wanted, tag the merge commit with a version number (e.g. `0.0.1`)
- coordinate the release with the Nimbus team who has to update the `crossplane` ConfigMap in the `platformplane` namespace on Nimbus so that other developers can use it

## How to debug e.g. a new helm-based catalog item

See [here](https://docs.crossplane.io/latest/guides/troubleshoot-crossplane/)

- does the claim exist and what is its state? Describe it to see the status.
  ```yaml
  kubectl get dclconstellations
  kubectl describe dclconstellations sample-dclconstellation
  ```
- what is the state of the corresponding composite?
  ```yaml
  kubectl get dclconstellationcomposite
  kubectl get dclconstellationcomposite dclconstellation-sample-hx5hk -o jsonpath='{.status.conditions}'
  ```
- what is the state of the managed resource (in this case the helm release)?
  ```yaml
  kubectl get releases
  kubectl get release dclconstellation-sample-hx5hk-n5r6r -o jsonpath='{.status.conditions}'
  ```
- what is the status of the pkg.crossplane.io configurations?
  ```yaml
  kubectl get configurations
  kubectl get configuration catalog-items-lgtdev -o jsonpath='{.status.conditions}'
  ```
- what is the status of the pkg.crossplane.io providers?
  ```yaml
  kubectl get providers
  kubectl get providers provider-helm -o jsonpath='{.status.conditions}'
  ```

## Useful commands to test items

### Elasticsearch

```bash
curl http://elasticsearch-sample:9200/_cluster/health?pretty
curl -X PUT "http://elasticsearch-sample:9200/my-index"
curl -X GET "http://elasticsearch-sample:9200/_cat/indices?v"
```

### Kafka

```bash
code client.properties
# paste the following content
security.protocol=SASL_PLAINTEXT
sasl.mechanism=SCRAM-SHA-256
sasl.jaas.config=org.apache.kafka.common.security.scram.ScramLoginModule required \
    username="user" \
    password="$(kubectl get secret kafka-user-passwords --namespace test -o jsonpath='{.data.client-passwords}' | base64 -d | cut -d , -f 1)";
# save the file and run the following commands
kubectl run kafka-kafka-client --restart='Never' --image docker.io/bitnami/kafka:3.7.0-debian-12-r0 --namespace test --command -- sleep infinity
kubectl cp --namespace test ./client.properties kafka-kafka-client:/tmp/client.properties
kubectl exec --tty -i kafka-kafka-client --namespace test -- bash
kafka-console-producer.sh \
            --producer.config /tmp/client.properties \
            --broker-list kafka-sample-controller-0.kafka-sample-controller-headless.test.svc.cluster.local:9092 \
            --topic test
kafka-console-consumer.sh \
            --consumer.config /tmp/client.properties \
            --bootstrap-server kafka-sample-controller-0.kafka-sample-controller-headless.test.svc.cluster.local:9092 \
            --topic test --from-beginning
```

### MariaDB

```bash
kubectl exec -it maria-0 -n test -- mysql -u root -p db
```

### MinIO

```bash
mc alias set myminio http://minio-sample:9000 admin kPUMn2JZTc
mc mb myminio/bucket
mc ls myminio
```

### MsSql

```bash
kubectl run -n test -it --rm --image=mcr.microsoft.com/mssql-tools bash
sqlcmd -S mssql-sample -U sa
```

### Redis

```bash
redis-cli -h redis-master -p 6379 -a bLaesXrA1V
```

### PostgreSQL

```bash
kubectl run -n test -it --rm --image=postgres:latest postgres-client -- psql -h 10.96.193.248 -U postgres -d postgres --password
```

## Known issues

- console intregration does not offer all options shown in UI and sometimes does not seem to show all connection information
- Several charts (elastic, kafka, mariadb, MsSql which is plain yaml) do not provide the `persistentVolumeClaimRetentionPolicy` parameter which is needed to remove the PVCs when the Helm release is deleted. Therefore, the crossplane operator removes them manually after the catalog item removal. Alternatively, we could create our own PCV with Crossplane as part of the composition and reference that as existingClaim in the Helm release:

```yaml
  resources:
    - name: pvc
      base:
        apiVersion: kubernetes.crossplane.io/v1alpha2
        kind: Object
        spec:
          providerConfigRef:
            name: provider-kubernetes
          forProvider:
            manifest:
              apiVersion: v1
              kind: PersistentVolumeClaim
              metadata:
                name: tbd-name
                namespace: tbd-namespace
                labels:
                  catalog.cluster.local/kind: tbd-kind
                  catalog.cluster.local/name: tbd-name
              spec:
                accessModes:
                  - ReadWriteOnce
                resources:
                  requests:
                    storage: 8Gi

      patches:
        - type: FromCompositeFieldPath
          fromFieldPath: "spec.claimRef.name"
          toFieldPath: "spec.forProvider.manifest.metadata.name"

        - type: FromCompositeFieldPath
          fromFieldPath: "spec.claimRef.namespace"
          toFieldPath: "spec.forProvider.manifest.metadata.namespace"

        - type: FromCompositeFieldPath
          fromFieldPath: "spec.claimRef.kind"
          toFieldPath: "spec.forProvider.manifest.metadata.labels['catalog.cluster.local/kind']"

        - type: FromCompositeFieldPath
          fromFieldPath: "spec.claimRef.name"
          toFieldPath: "spec.forProvider.manifest.metadata.labels['catalog.cluster.local/name']"

        - type: FromCompositeFieldPath
          fromFieldPath: "spec.size"
          toFieldPath: "spec.forProvider.manifest.spec.resources.requests.storage"

    - name: helm-release
      base:
      ...
        spec:
          forProvider:
            values:
              master:
                persistence:
                  existingClaim: tbd
      ...            
      patches:
        - type: FromCompositeFieldPath
          fromFieldPath: "spec.claimRef.name"
          toFieldPath: "spec.forProvider.values.master.persistence.existingClaim"
```

### Redis

- `consoel redis client` is not authenticating correctly, see error message when calling e.g. `INFO` command

## Work with functions

Read the article about [Composition Funcitons](https://docs.crossplane.io/latest/concepts/composition-functions/) and the [function-go-tempalting Readme](https://github.com/crossplane-contrib/function-go-templating). Sometimes, also the [Composition Functions design doc](https://github.com/stevendborrelli/crossplane/blob/master/design/design-doc-composition-functions.md) is useful. Regarding the templating syntax, use the [Go Helm template functions doc](https://helm.sh/docs/chart_template_guide/function_list).

```bash	
crossplane beta render examples/mssql-2022.yaml package/mssql/composition.yaml docs/functions.yaml > out.yaml
```

Debugging to see which keys are available: print this stuff you look for as connectiondetails:
  
  ```yaml
  resources1: {{- range $key, $value := .observed.resources.info.resource.status.atProvider.manifest.data.resourcegroup -}}{{- if $value -}}{{- printf "%s," $key -}}{{- end -}}{{- end -}}
  ```

  Then an error including the keys is shown in the managed resource status.

## Azure Storage Account Items (e.g. BlobStorage)

IF you want to add e.g. queue storage, copy paste blob storage and adjust it slightly, see table [here](https://learn.microsoft.com/en-us/azure/private-link/availability#storage)

In order not to expose the storage accoutns publicly, public access is disabled and they are exposed via private endpoint, see [here](https://learn.microsoft.com/en-us/azure/private-link/tutorial-private-endpoint-storage-portal?tabs=dynamic-ip)

## Further improvements

- delete bindings when deleting the claim
- add OracleDB and SQLServer catalog item
- Parameter configurable via UI (enums are already in CRDs)
  - Show "danger" emoji at spec.version saying that this will break the application and migration has to be done potentially
  - can we have nice display names for the parameters? 
- Make the crossplane operator watching the `crossplane` ConfigMap in the `platformplane` namespace (not copying the file on startup using that value until the pod is killed)
- add dependabot to the repo
- try out what happens when the platformplane does not install providers but instead let crossplane install them based on the dependencies in the configurations (the provider configs etc. will probably be needed anyways, with some default name references)
This could help making updating providers easier (just update the version number in the configuration.yaml and crossplane will install them automatically?)
