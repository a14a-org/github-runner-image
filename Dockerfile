FROM myoung34/github-runner:latest

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

RUN curl -fsSL https://bun.sh/install | BUN_INSTALL=/usr/local bash \
    && bun --version

ARG DOCKER_CLI_VERSION=27.3.1
RUN curl -fsSL "https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_CLI_VERSION}.tgz" \
      | tar -xz -C /usr/local/bin --strip-components=1 docker/docker \
    && docker --version

USER runner
