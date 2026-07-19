# Unofficial personal build of p4c (multi-arch: amd64 + arm64), Ubuntu 24.04.
#
# The version pin below is the single source of truth; the CI workflow derives
# the image tag <version>-noble from it. Tags are immutable: bump the ARG to
# publish a new tag, never rebuild an existing one.
ARG VERSION=1.2.5.15

# Only the BMv2 backend and p4test; protobuf/abseil are FetchContent-vendored
# by p4c's own build. python3 is needed by p4c's IR generator scripts.
FROM ubuntu:24.04 AS build
ARG VERSION
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl git cmake g++ make python3 flex bison \
      libgc-dev libfl-dev \
      libboost-dev libboost-graph-dev libboost-iostreams-dev \
 && rm -rf /var/lib/apt/lists/*
RUN git clone --depth 1 --branch "v${VERSION}" --recursive \
      https://github.com/p4lang/p4c /tmp/p4c \
 && cmake -S /tmp/p4c -B /tmp/p4c/build \
      -DCMAKE_BUILD_TYPE=Release \
      -DENABLE_BMV2=ON -DENABLE_P4TEST=ON \
      -DENABLE_EBPF=OFF -DENABLE_UBPF=OFF -DENABLE_DPDK=OFF \
      -DENABLE_P4TC=OFF -DENABLE_P4FMT=OFF -DENABLE_DOCS=OFF \
      -DENABLE_GTESTS=OFF \
 && cmake --build /tmp/p4c/build -j"$(nproc)" \
 && DESTDIR=/stage cmake --install /tmp/p4c/build
# Stage upstream license texts so the final image redistributes them alongside
# the binaries (p4c is REUSE-style: LICENSES/ holds every license in the tree).
RUN mkdir -p /stage/usr/local/share/doc/p4c \
 && cp -r /tmp/p4c/LICENSES /stage/usr/local/share/doc/p4c/

# Runtime dependencies are installed as -dev packages for simplicity (they
# pull the runtime libs; the extra headers cost some size, not correctness).
# cpp is p4c's preprocessor at runtime; python3 serves p4c helper scripts.
FROM ubuntu:24.04
LABEL org.opencontainers.image.source=https://github.com/qobilidop/p4lang-builds \
      org.opencontainers.image.licenses=Apache-2.0
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
      cpp python3 \
      libboost-iostreams-dev libboost-graph-dev libgc-dev libfl-dev \
 && rm -rf /var/lib/apt/lists/*
COPY --from=build /stage/usr/local /usr/local
RUN ldconfig \
 && p4test --version \
 && p4c-bm2-ss --version
