FROM docker AS build

RUN apk add --no-cache ca-certificates curl git

# Crossplane CLI
RUN curl -sL https://raw.githubusercontent.com/crossplane/crossplane/master/install.sh | sh && \
    chmod +x crossplane && \
    mv crossplane /usr/local/bin/

COPY ./package /package

WORKDIR /package

ARG DOCKER_REGISTRY
ARG REGISTRY_IMAGE
ARG IMAGE_VERSION

# Sanity checks
RUN if [ -z "$DOCKER_REGISTRY" ]; then echo 'DOCKER_REGISTRY is not set, docker build must be called with --build-arg DOCKER_REGISTRY=$YOUR_REGISTRY' && exit 1; else echo "DOCKER_REGISTRY is set to $DOCKER_REGISTRY"; fi

RUN if [ -z "$REGISTRY_IMAGE" ]; then echo 'REGISTRY_IMAGE is not set, docker build must be called with --build-arg REGISTRY_IMAGE=$YOUR_REGISTRY_IMAGE' && exit 1; else echo "REGISTRY_IMAGE is set to $REGISTRY_IMAGE"; fi

RUN if [ -z "$IMAGE_VERSION" ]; then echo 'IMAGE_VERSION is not set, docker build must be called with --build-arg IMAGE_VERSION=$YOUR_IMAGE_VERSION' && exit 1; else echo "IMAGE_VERSION is set to $IMAGE_VERSION"; fi

RUN --mount=type=secret,id=registry-password \
    if [ ! -f /run/secrets/registry-password ]; then echo "Error: Docker build must be called with --secret id=registry-password,src=path/to/secret or --secret id=registry-password,env=ENV_VAR_WITH_SECRET" && exit 1; fi

# Build and push the xpkg
ARG CACHEBUST
RUN crossplane xpkg build -o catalog-items.xpkg

RUN --mount=type=secret,id=registry-password \
    cat /run/secrets/registry-password | docker login $DOCKER_REGISTRY --username platform --password-stdin

RUN crossplane xpkg push -f catalog-items.xpkg $REGISTRY_IMAGE:$IMAGE_VERSION
