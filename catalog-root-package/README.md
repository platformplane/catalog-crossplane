```
crossplane xpkg build # --package-root=catalog-root-package/ --examples-root=./examples --ignore=PATH1,...

helm registry login registry.nimbusplane.io --username hara --password-stdin
#crossplane xpkg login --username=platform --username--domain=registry.nimbusplane.io

crossplane xpkg push registry.nimbusplane.io/demo/demo-ops/catalog-crossplane-b29f08f17924:v1.0.1 --package-files=catalog-crossplane-b29f08f17924.xpkg

crossplane xpkg install configuration upbound/provider-aws-eks:v0.41.0 --wait=1m
crossplane xpkg install provider upbound/provider-aws-eks:v0.41.0 --wait=1m
```