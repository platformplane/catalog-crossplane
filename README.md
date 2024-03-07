# catalog-items

The items shown in the catalog v2 are developed here. The pipeline pushes an OCI image (crossplane package) to the registry from where it will be consumed by the catalog. 

Manually build and push the Crossplane package:
```bash
cd package
echo $REGISTRY_PASSWORD | docker login -u $REGISTRY_USERNAME --password-stdin
crossplane xpkg push -f catalog-items.xpkg index.docker.io/platformplane/platform-catalog:0.0.1
```
