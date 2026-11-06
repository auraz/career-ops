# career-ops container
# Base: Playwright image with Chromium preinstalled (matches playwright@1.65.0 in package.json).
# Host kernels that block Playwright's chromium installer (e.g. Ubuntu 26.04) work fine here
# because the browser ships in the image and runs under the image's userland.

FROM mcr.microsoft.com/playwright:v1.65.0-noble@sha256:6e3fb709361521eb27161606e6da6d2674e5e89fa16516cb37d6fdd91372273d

ENV DEBIAN_FRONTEND=noninteractive \
    NODE_ENV=development \
    PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=0 \
    PLAYWRIGHT_BROWSERS_PATH=/ms-playwright \
    PATH=/usr/local/go/bin:$PATH

# Optional: Go toolchain for the dashboard TUI (./dashboard).
# Small footprint, keeps full feature parity with the README setup.
# Must be >= the `go` line in dashboard/go.mod (checked by tests/go-floor.test.mjs), or
# `go build` fetches a newer toolchain over the network and fails offline.
# Bumping GO_VERSION means updating both checksums too, from the
# linux-amd64 and linux-arm64 archives listed at https://go.dev/dl/.
ARG GO_VERSION=1.27.3
ARG GO_SHA256_AMD64=65efbc80fdc1fa2cd2631cad5b481777a68e8725f34e89f50fc6ac714e379b40
ARG GO_SHA256_ARM64=a06e99309dbcbdca1a8ccd2282c3ee146e55930886e26b4f1193269587165f49
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates curl git tini latexmk texlive-latex-recommended texlive-latex-extra texlive-fonts-recommended texlive-xetex; \
    arch="$(dpkg --print-architecture)"; \
    case "$arch" in \
      amd64)  go_arch=amd64; go_sha256="$GO_SHA256_AMD64" ;; \
      arm64)  go_arch=arm64; go_sha256="$GO_SHA256_ARM64" ;; \
      *) echo "unsupported arch: $arch" >&2; exit 1 ;; \
    esac; \
    curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-${go_arch}.tar.gz" -o /tmp/go.tgz; \
    echo "${go_sha256}  /tmp/go.tgz" | sha256sum -c -; \
    tar -C /usr/local -xzf /tmp/go.tgz; \
    rm /tmp/go.tgz; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Prime npm deps in a layer so rebuilds stay fast.
# Pin playwright to the version that matches the base image's bundled chromium.
COPY package.json package-lock.json* ./
RUN npm install --no-audit --no-fund \
 && npm install --no-audit --no-fund --save-exact playwright@1.65.0

# The rest of the project is bind-mounted at runtime via docker compose,
# so we don't COPY sources here — keeps the image generic and lets local
# edits show up instantly inside the container.

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["bash"]
