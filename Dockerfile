FROM myoung34/github-runner:ubuntu-noble@sha256:e09280adbe952fd4bc11e23ed54d6037b83beb10ad9860f588eca40440861cfe

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
