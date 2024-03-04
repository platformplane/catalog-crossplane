# catalog-items

The items shown in the catalog v2 are developed here. The pipeline pushes an OCI image (crossplane package) to the registry from where it will be consumed by the catalog. 

Manually build the Dockerfile like:
```bash
REGISTRY_PASSWORD=glpat-... docker buildx build --progress=plain --output type=local,dest=. --secret id=registry-password,env=REGISTRY_PASSWORD --build-arg DOCKER_REGISTRY=registry.nimbusplane.io --build-arg IMAGE_NAME=to-delete --build-arg IMAGE_VERSION=0.0.1 --build-arg CACHEBUST=$(date +%s) --build-arg REGISTRY_IMAGE=registry.nimbusplane.io/common/lgt/platform/catalog-items .
```

The CACHEBUST is not really needed but useful when amending git commits or testing locally with the same version number.
