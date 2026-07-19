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

| Image | Contents |
|---|---|
| `ghcr.io/qobilidop/p4lang-builds/toolchain` | p4c (`p4test`, `p4c-bm2-ss`) + BMv2 (`simple_switch`), Ubuntu 24.04, amd64 + arm64 |

Tags: `<p4c-version>-<bmv2-version>-<ubuntu codename>`, e.g.
`1.2.5.15-1.15.4-noble`, plus a floating `latest`.

**Tag immutability policy:** a published version tag is never rebuilt or
re-pushed (CI enforces this). Consumers may pin tags and trust them; pin by
digest if you want belt and braces. New builds require bumping the version
`ARG`s in the Dockerfile, which produces a new tag.

## Use

```dockerfile
FROM ghcr.io/qobilidop/p4lang-builds/toolchain:1.2.5.15-1.15.4-noble
```

or graft onto another noble-based image:

```dockerfile
COPY --from=ghcr.io/qobilidop/p4lang-builds/toolchain:1.2.5.15-1.15.4-noble /usr/local /usr/local
# plus the runtime libs listed in the final stage of this repo's Dockerfile
```

## Notes for future me

- Build knowledge encoded in the Dockerfile: BMv2 needs thrift for its
  switch targets, plus xxhash/jsoncpp; p4c needs python3 and vendors its
  own protobuf/abseil via FetchContent.
- CI builds each arch natively (GitHub's free arm64 runners) and merges
  one manifest — no QEMU.
- If this proves useful, propose the equivalent upstream to p4lang; keep
  this repo as the personal backup either way.
