FROM myoung34/github-runner:ubuntu-noble@sha256:c6c7bf984da87a6629f665444e0405b52daf839a68f364ee51c6ca48193ec42b

USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
      curl \
      unzip \
      ca-certificates \
      gnupg \
      python3 \
      python3-pip \
      build-essential \
    && apt-get install -y --only-upgrade ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Node 24.22.1+ fixes CVE-2026-111497 (Brotli decoder) and distrusts the compromised
# eMudhra intermediates; Node 20 is end-of-life and gets neither fix.
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/* \
    && node -e "const [a,b,c]=process.versions.node.split('.').map(Number); if (a!==24||b<22||(b===22&&c<1)) { console.error('node '+process.version+' < 24.22.1'); process.exit(1) }" \
    && node --version \
    && npm --version

ARG BUN_VERSION=1.4.4
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
