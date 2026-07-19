# p4lang-builds

Personal, **unofficial** multi-arch builds of [p4lang](https://github.com/p4lang)
projects that my own projects consume. Not affiliated with the P4 project;
not intended for anyone else's production use (but the recipes are honest —
read them).

Why this exists: as of 2026-07 there are no arm64 binaries of p4c or BMv2
anywhere (the p4lang apt repo is amd64-only and stops at Ubuntu 23.04), and
no packages at all for current Ubuntu. Source builds take ~50 minutes; my
projects shouldn't pay that on every cold start.

## Images

One image per p4lang project, independently versioned (mirrors upstream's
own repo/image split):

| Image | Contents |
|---|---|
| `ghcr.io/qobilidop/p4lang-builds/p4c` | p4c (`p4test`, `p4c-bm2-ss`), Ubuntu 24.04, amd64 + arm64 |
| `ghcr.io/qobilidop/p4lang-builds/bmv2` | BMv2 (`simple_switch`), Ubuntu 24.04, amd64 + arm64 |

Tags: `<version>-<ubuntu codename>`, e.g. `p4c:1.2.5.15-noble` and
`bmv2:1.15.4-noble`, plus a floating `latest` on each image.

**Tag immutability policy:** a published version tag is never rebuilt or
re-pushed (CI skips publishing when the tag already exists, so the two
images can be bumped independently). Consumers may pin tags and trust
them; pin by digest if you want belt and braces. New builds require
bumping the version `ARG` in the image's Dockerfile, which produces a
new tag.

## Use

Base on one image and graft the other (both are noble-based, so
`/usr/local` grafts cleanly):

```dockerfile
FROM ghcr.io/qobilidop/p4lang-builds/p4c:1.2.5.15-noble
COPY --from=ghcr.io/qobilidop/p4lang-builds/bmv2:1.15.4-noble /usr/local /usr/local
# plus the runtime libs listed in the final stage of bmv2/Dockerfile
RUN apt-get update && apt-get install -y --no-install-recommends \
      libgmp-dev libpcap-dev libjudy-dev libevent-dev libssl-dev \
      libxxhash-dev libjsoncpp-dev libthrift-dev \
      libboost-program-options-dev libboost-system-dev \
      libboost-filesystem-dev libboost-thread-dev \
 && rm -rf /var/lib/apt/lists/* && ldconfig
```

or graft either one alone onto any noble-based image the same way (its
runtime libs are listed in the final stage of its Dockerfile).

## License

The recipes in this repo are Apache-2.0 (see [LICENSE](LICENSE)). The
published images redistribute compiled p4c and BMv2 (both Apache-2.0);
each image carries the upstream license texts under
`/usr/local/share/doc/{p4c,bmv2}/`, plus Ubuntu packages which carry
theirs in `/usr/share/doc` as usual.

## Notes for future me

- Build knowledge encoded in the Dockerfiles: BMv2 needs thrift for its
  switch targets, plus xxhash/jsoncpp; p4c needs python3 and vendors its
  own protobuf/abseil via FetchContent.
- CI builds each image × arch natively (GitHub's free arm64 runners) and
  merges one manifest per image — no QEMU.
- If this proves useful, propose the equivalent upstream to p4lang; keep
  this repo as the personal backup either way.
