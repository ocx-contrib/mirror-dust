# NOTICE

This repository packages and redistributes upstream software published by the
[dust](https://github.com/bootandy/dust) project. The Apache-2.0 license in
[`LICENSE`](LICENSE) covers the OCX pipeline files authored here. It does
**not** cover any upstream-derived asset — each package's redistributed bytes
carry their own license, recorded below.

The package logo in `dust/logo.svg` is an **original mark authored for this
mirror**, not an upstream trademark: bootandy/dust publishes no logo (its
`media/` directory holds a terminal screenshot only). It is used for catalog
identification and implies no endorsement.

| Package | GHCR path | Upstream SPDX |
|---|---|---|
| `dust` | `ghcr.io/ocx-contrib/dust/dust` | `Apache-2.0` |

---

## `dust`

Upstream: <https://github.com/bootandy/dust>
Published to `ghcr.io/ocx-contrib/dust/dust`.

| Component | SPDX | Holder |
|---|---|---|
| dust (`dust`) | **Apache-2.0** | Andrew Boot (`bootandy`) |

The upstream `LICENSE` file is the stock Apache License 2.0 text; its appendix
reads verbatim `Copyright [2023] [andrew boot]`, and `Cargo.toml` declares
`license = "Apache-2.0"` with authors `bootandy <bootandy@gmail.com>` and
`nebkor <code@ardent.nebcorp.com>`.

Apache-2.0 §4 grants redistribution of the Work and Derivative Works in source
or **Object** form, so redistribution of the compiled binary is permitted
provided recipients receive a copy of the License and the retained attribution
notices. That condition is satisfied structurally: upstream ships `LICENSE`
inside every release archive, and this mirror republishes each archive
byte-for-byte, so the license text travels with the binary in the OCX bundle.
The published binaries statically link third-party Rust crates under permissive
licenses, enumerated in the `Cargo.lock` in the upstream source tree.

Note on naming: the crates.io **crate** is `du-dust` and upstream's Debian
sidecar assets are `du-dust_<version>-1_<arch>.deb`, but the mirrored archives,
the executable inside them, and this package are all named `dust`. The `.deb`
sidecars are not mirrored.

No modifications are made to any upstream artifact in this repository; they are
republished byte-for-byte inside an OCX bundle.
