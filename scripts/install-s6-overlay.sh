#!/bin/bash -e

S6_OVERLAY_ARCH=x86_64
if [[ "${TARGETARCH}" == "amd64" ]]; then
    S6_OVERLAY_ARCH="x86_64"
elif [[ "${TARGETARCH}" == "arm64" ]]; then
    S6_OVERLAY_ARCH="aarch64"
elif [[ "${TARGETARCH}" == "arm/v6" ]]; then
    S6_OVERLAY_ARCH="armhf"
elif [[ "${TARGETARCH}" == "arm/v7" || "${TARGETARCH}" == "arm" ]]; then
    S6_OVERLAY_ARCH="arm"
fi

echo Building with TARGETARCH=${TARGETARCH} and S6_OVERLAY_ARCH=${S6_OVERLAY_ARCH}

wget -qO- "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz" | tar -C / -Jxpf -
wget -qO- "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${S6_OVERLAY_ARCH}.tar.xz" | tar -C / -Jxpf -
wget -qO- "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-symlinks-noarch.tar.xz" | tar -C / -Jxpf -
wget -qO- "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-symlinks-arch.tar.xz" | tar -C / -Jxpf -
