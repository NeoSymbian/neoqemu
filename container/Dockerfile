# SPDX-License-Identifier: Apache-2.0
# NeoQEMU: qemu-system-aarch64 (qemu/, upstream QEMU + our fixes) and the virt run tools, for Linux hosts.
# Build from the repository root: docker build -f container/Dockerfile -t neoqemu .
# NeoSymbian/build's toolchain image copies /opt/neoqemu from this image (its bin/ goes on PATH).

FROM debian:trixie-slim AS build
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential ca-certificates git ninja-build pkg-config python3 python3-venv \
        libglib2.0-dev libpixman-1-dev libfdt-dev zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*
COPY qemu /src/qemu
RUN mkdir /src/build && cd /src/build \
    && ../qemu/configure --prefix=/opt/neoqemu --target-list=aarch64-softmmu \
        --disable-docs --disable-tools --disable-gtk --disable-sdl --disable-opengl --enable-vnc \
        --disable-guest-agent \
    && ninja \
    && ninja install \
    && rm -rf /opt/neoqemu/share/qemu/*.fd /opt/neoqemu/share/qemu/edk2-*
COPY tools/run-qemu.sh tools/ui-qemu.py /opt/neoqemu/bin/

FROM debian:trixie-slim
RUN apt-get update && apt-get install -y --no-install-recommends \
        libglib2.0-0t64 libpixman-1-0 libfdt1 zlib1g python3 \
    && rm -rf /var/lib/apt/lists/*
COPY --from=build /opt/neoqemu /opt/neoqemu
ENV PATH=/opt/neoqemu/bin:$PATH
# the virt machine run-qemu.sh starts, with every device it adds, and the runner's own checks
RUN qemu-system-aarch64 --version \
    && for d in ramfb virtio-tablet-device virtio-keyboard-device virtio-blk-device; do \
         qemu-system-aarch64 -M virt -device help | grep -q "\"$d\"" || { echo "no $d"; exit 1; }; done \
    && sh -n /opt/neoqemu/bin/run-qemu.sh && python3 -I /opt/neoqemu/bin/ui-qemu.py selftest
WORKDIR /work
