# catalog-items

The items shown in the catalog v2 are developed here. The pipeline pushes an OCI image (crossplane package) to the registry from where it will be consumed by the catalog. 

Manually build the Dockerfile like:
```bash
REGISTRY_PASSWORD=... docker buildx build --progress=plain --output type=local,dest=. --secret id=registry-password,env=REGISTRY_PASSWORD --build-arg DOCKER_REGISTRY=index.docker.io --build-arg DOCKER_USERNAME=... --build-arg IMAGE_VERSION=0.0.1 --build-arg CACHEBUST=$(date +%s) --build-arg REGISTRY_IMAGE=index.docker.io/platformplane/platform-catalog .
```

Manually build and push the Crossplane package:
```bash
cd package
echo $REGISTRY_PASSWORD | docker login -u $REGISTRY_USERNAME --password-stdin
crossplane xpkg push -f catalog-items.xpkg index.docker.io/platformplane/platform-catalog:0.0.1
```

The CACHEBUST is not really needed but useful when amending git commits or testing locally with the same version number.
