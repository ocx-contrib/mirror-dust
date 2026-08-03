# mirror-dust

OCX mirror for [dust](https://github.com/bootandy/dust) — `du` + Rust, a more
intuitive disk-usage tree. One repository, one spec directory per package.

| Package | Spec | Publishes to | Announced as | Upstream SPDX |
|---|---|---|---|---|
| [dust](https://github.com/bootandy/dust) | [`dust/mirror.yml`](dust/mirror.yml) | `ghcr.io/ocx-contrib/dust/dust` | [`ocx.sh/dust/dust`](https://index.ocx.sh/dust/dust) | `Apache-2.0` |

Each upstream release is discovered, re-bundled, smoke-tested per
`(version, platform)` and only then pushed with cascade tags, after which the
result is announced into the OCX index.

> The crates.io **crate** is `du-dust` and upstream also builds
> `du-dust_<version>-1_<arch>.deb` sidecars — but the mirrored archives, the
> executable inside them and this package are all `dust`. The `.deb` files are
> not mirrored; the anchored `^dust-v…` asset regexes exclude them structurally.

## Layout

```
mirror-base.yml         repo-wide policy every spec inherits via `extends:`
dust/
├── mirror.yml          the spec — never at the repo root
├── metadata.json       bundle interface
├── CATALOG.md          → ocx package describe
├── logo.svg / logo.png describe assets, 512px PNG
└── tests/smoke.star    Starlark smoke test
```

`LICENSE` and `NOTICE.md` are shared at the root. The logo is **not** — it
lives beside the spec, because a repo-root `logo.*` sits in no workflow's
`paths:` filter, so replacing it would publish nothing until some unrelated
edit happened to fire.

⚠️ `extends:` is a **shallow** merge of top-level keys. A spec that restates
`platforms:` to change one runner drops every `containers:` entry with it, and
nothing reds — the legs simply stop existing, and every `os.features` claim
goes back to being asserted rather than verified. This repo is single-package,
so the measured `platforms:` matrix lives in `mirror-base.yml` and
`dust/mirror.yml` never restates it.

## Platforms

`dust` publishes **four** platform entries, and the two it does not publish are
upstream gaps rather than omissions here:

| OCX platform | Upstream asset | Notes |
|---|---|---|
| `linux/amd64` | `x86_64-unknown-linux-musl` | bare key — measured static |
| `linux/arm64` | `aarch64-unknown-linux-musl` | bare key — measured static |
| `darwin/amd64` | `x86_64-apple-darwin` | tested on `macos-14` via Rosetta 2 |
| `windows/amd64` | `x86_64-pc-windows-msvc` | |
| ~~`darwin/arm64`~~ | — | **upstream ships no Apple Silicon build** |
| ~~`windows/arm64`~~ | — | **upstream ships no ARM64 Windows build** |

Both gaps were re-verified by listing the full asset set of every in-range
release (`v1.2.2`, `v1.2.3`, `v1.2.4`): the only `*-apple-darwin` asset is
`x86_64-apple-darwin`, and the Windows assets are exactly
`{i686,x86_64}-pc-windows-{gnu,msvc}` — no `aarch64-*` of either kind, on any
release. Apple Silicon hosts therefore get the Intel slice under Rosetta 2.
Neither key is declared speculatively: a declared platform with no matching
asset does **not** quietly self-skip, it boots a real runner and reports
SUCCESS having tested nothing. Upstream's `armv7`, `i686`, `*-gnueabihf` and
`*-musleabi` assets have no OCX platform key at all — the arch enum is `amd64`
and `arm64` only — so they are out of scope silently.

### libc

Upstream ships **both** a `-gnu` and a `-musl` build for each Linux arch, so
the choice was measured, not inferred. Both musl binaries were byte-measured on
**both** arches at **both** ends of the version range (1.2.2 and 1.2.4) and are
fully static: no `PT_INTERP`, no `DT_NEEDED`, musl linked *in* rather than
linked *against*. `os.features` states what an artifact requires *of the host*,
so both Linux keys are **bare**: tagging them `+libc.musl` would be a false
requirement that hid the package from every glibc host it in fact runs on. The
`alpine:3.20` container leg in `mirror-base.yml` is what turns that claim into
evidence.

The gnu builds are genuinely dynamic (`libc.so.6`, `libgcc_s.so.1`, max symbol
`GLIBC_2.18` on both arches) and are deliberately not carried. Publishing them
alongside under `+libc.glibc` would resolve correctly, but the one behaviour
that actually differs between a static-musl and a gnu build is NSS/DNS
resolution — and dust reads the local filesystem, resolving no names. The
measurements themselves are recorded above the `assets:` block in
`dust/mirror.yml`.

## Editing

| File | Edit | Regenerate after |
|------|------|------------------|
| `mirror-base.yml`, `dust/mirror.yml` | hand | yes — see below |
| `dust/{metadata.json,CATALOG.md,logo.*}` | hand | — |
| `dust/tests/smoke.star` | hand | — |
| `.github/workflows/*.yml` | **generated — never hand-edit** | re-run when a spec changes |

```bash
ocx-mirror package pipeline generate ci --spec dust/mirror.yml
```

**Name every spec.** `--spec` *appends* rather than replaces, so a command
naming a subset silently stops rendering the rest while staying green — and the
drift guard reds on a generated workflow the current spec set no longer
produces.

`verify-generated.yml` exits 65 on drift. If a generated workflow is wrong, the
spec or the renderer template is wrong — fix it there and regenerate.

Run `direnv allow` once to put the pinned toolchain on `PATH`, and invoke
`ocx-mirror` directly — never `ocx run -- ocx-mirror`, which pins
`OCX_BINARY_PIN` to the bootstrap `ocx` and false-reds the nested push.

## The binaries claim

`dust/metadata.json` declares `binaries: ["dust"]` by hand, and
`dust/mirror.yml` sets `bin_scan: "off"` — forced, not preferred. Every archive
is a single `dust-v<version>-<triple>/` wrapper holding `dust` (`dust.exe` on
Windows) beside `LICENSE` and `README.md`, so after `strip_components: 1` the
bundle's only PATH entry is a bare `${installPath}` with no subdirectory to
scan. With nothing to inspect the scan would pass green whatever the archive
contained, so `auto` and `verify` both fail spec load at exit 65 rather than
offer a hollow check. The hand-written list is what the error message itself
directs, and it is short and stable — `dust` is the only mode-0755 entry; the
rest is 0644 data.

## Smoke test

`dust/tests/smoke.star` writes a four-file tree of exact, distinct sizes and
asserts dust's own measurements of it: the row **count**, each file's exact
byte figure, the size **ordering** (largest last), and that `--filter` narrows
the result to exactly one row. Presentation is pinned with `-c -b -P -s -w 100
-n 20 -o b -F -R --skip-total`, because dust's default output is colourised and
scales to terminal width — a plain-substring assertion against it would be
flaky by construction. Nothing asserts help or version prose; the version check
is a shape regex.

## Required secrets

| Secret | Use |
|--------|-----|
| `OCX_ANNOUNCE_TOKEN` | opens the index pull request from the `ocx-contrib/index` fork |
| `OCX_MIRROR_DISCORD_HOOK` | notify-stage Discord webhook URL |

(Inherited from the `ocx-contrib` org with visibility ALL. GHCR pushes use the
run's own `GITHUB_TOKEN` — no registry secret needed.)

## License

Apache-2.0 — see [`LICENSE`](LICENSE). Upstream assets are out of scope; the
package's redistribution license is recorded in [`NOTICE.md`](NOTICE.md).
