# Unofficial personal builds of p4lang projects (multi-arch: amd64 + arm64).
# One combined "toolchain" image: p4c + BMv2 (behavioral-model) on Ubuntu 24.04.
#
# Version pins below are the single source of truth; the CI workflow derives
# the image tag <p4c>-<bmv2>-noble from them. Tags are immutable: bump the
# ARGs to publish a new tag, never rebuild an existing one.
ARG BMV2_VERSION=1.15.4
ARG P4C_VERSION=1.2.5.15

# --- BMv2 (behavioral-model) -------------------------------------------------
# Thrift is required: the switch targets (simple_switch) only build with it.
FROM ubuntu:24.04 AS bmv2-build
ARG BMV2_VERSION
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl g++ make automake autoconf libtool pkg-config \
      libgmp-dev libpcap-dev libjudy-dev libevent-dev libssl-dev \
      libxxhash-dev libjsoncpp-dev libthrift-dev thrift-compiler \
      libboost-dev libboost-program-options-dev libboost-system-dev \
      libboost-filesystem-dev libboost-thread-dev \
 && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL "https://github.com/p4lang/behavioral-model/archive/refs/tags/${BMV2_VERSION}.tar.gz" | tar xz -C /tmp \
 && cd "/tmp/behavioral-model-${BMV2_VERSION}" \
 && ./autogen.sh \
 && ./configure --without-nanomsg --disable-logging-macros \
 && make -j"$(nproc)" \
 && make install DESTDIR=/stage

# --- p4c ---------------------------------------------------------------------
# Only the BMv2 backend and p4test; protobuf/abseil are FetchContent-vendored
# by p4c's own build. python3 is needed by p4c's IR generator scripts.
FROM ubuntu:24.04 AS p4c-build
ARG P4C_VERSION
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl git cmake g++ make python3 flex bison \
      libgc-dev libfl-dev \
      libboost-dev libboost-graph-dev libboost-iostreams-dev \
 && rm -rf /var/lib/apt/lists/*
RUN git clone --depth 1 --branch "v${P4C_VERSION}" --recursive \
      https://github.com/p4lang/p4c /tmp/p4c \
 && cmake -S /tmp/p4c -B /tmp/p4c/build \
      -DCMAKE_BUILD_TYPE=Release \
      -DENABLE_BMV2=ON -DENABLE_P4TEST=ON \
      -DENABLE_EBPF=OFF -DENABLE_UBPF=OFF -DENABLE_DPDK=OFF \
      -DENABLE_P4TC=OFF -DENABLE_P4FMT=OFF -DENABLE_DOCS=OFF \
      -DENABLE_GTESTS=OFF \
 && cmake --build /tmp/p4c/build -j"$(nproc)" \
 && DESTDIR=/stage cmake --install /tmp/p4c/build

# --- Final image -------------------------------------------------------------
# Runtime dependencies are installed as -dev packages for simplicity (they
# pull the runtime libs; the extra headers cost some size, not correctness).
# cpp is p4c's preprocessor at runtime; python3 serves p4c helper scripts.
FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
      cpp python3 \
      libgmp-dev libpcap-dev libjudy-dev libevent-dev libssl-dev \
      libxxhash-dev libjsoncpp-dev libthrift-dev \
      libboost-program-options-dev libboost-system-dev \
      libboost-filesystem-dev libboost-thread-dev \
      libboost-iostreams-dev libboost-graph-dev libgc-dev libfl-dev \
 && rm -rf /var/lib/apt/lists/*
COPY --from=bmv2-build /stage/usr/local /usr/local
COPY --from=p4c-build /stage/usr/local /usr/local
RUN ldconfig \
 && p4test --version \
 && p4c-bm2-ss --version \
 && simple_switch --help >/dev/null 2>&1
