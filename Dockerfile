FROM myoung34/github-runner:latest@sha256:f30ed4ee4135be480768dc11340ff4b298abf7ee2a28534d95939c4a0613a26e

USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
      curl \
      unzip \
      ca-certificates \
      gnupg \
      python3 \
      python3-pip \
      build-essential \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/* \
    && node --version \
    && npm --version

ARG BUN_VERSION=1.3.14
RUN curl -fsSL https://bun.sh/install | BUN_INSTALL=/usr/local bash -s "bun-v${BUN_VERSION}" \
    && bun --version

ARG DOCKER_CLI_VERSION=27.3.1
RUN curl -fsSL "https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_CLI_VERSION}.tgz" \
      | tar -xz -C /usr/local/bin --strip-components=1 docker/docker \
    && docker --version

# Intentionally NOT switching to a non-root USER here.
# The base myoung34/github-runner image expects its entrypoint to run as root
# so it can perform user-dropping based on RUN_AS_ROOT itself. Locking the
# image to UID 1001 here breaks registration with:
#   "RUN_AS_ROOT env var is set to true but ... UID '1001'"
