# Unofficial personal build of BMv2 (behavioral-model) (multi-arch: amd64 +
# arm64), Ubuntu 24.04.
#
# The version pin below is the single source of truth; the CI workflow derives
# the image tag <version>-noble from it. Tags are immutable: bump the ARG to
# publish a new tag, never rebuild an existing one.
ARG VERSION=1.15.4

# Thrift is required: the switch targets (simple_switch) only build with it.
FROM ubuntu:24.04 AS build
ARG VERSION
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl g++ make automake autoconf libtool pkg-config \
      libgmp-dev libpcap-dev libjudy-dev libevent-dev libssl-dev \
      libxxhash-dev libjsoncpp-dev libthrift-dev thrift-compiler \
      libboost-dev libboost-program-options-dev libboost-system-dev \
      libboost-filesystem-dev libboost-thread-dev \
 && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL "https://github.com/p4lang/behavioral-model/archive/refs/tags/${VERSION}.tar.gz" | tar xz -C /tmp \
 && cd "/tmp/behavioral-model-${VERSION}" \
 && ./autogen.sh \
 && ./configure --without-nanomsg --disable-logging-macros \
 && make -j"$(nproc)" \
 && make install DESTDIR=/stage

# Runtime dependencies are installed as -dev packages for simplicity (they
# pull the runtime libs; the extra headers cost some size, not correctness).
FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
      libgmp-dev libpcap-dev libjudy-dev libevent-dev libssl-dev \
      libxxhash-dev libjsoncpp-dev libthrift-dev \
      libboost-program-options-dev libboost-system-dev \
      libboost-filesystem-dev libboost-thread-dev \
 && rm -rf /var/lib/apt/lists/*
COPY --from=build /stage/usr/local /usr/local
RUN ldconfig \
 && simple_switch --help >/dev/null 2>&1
