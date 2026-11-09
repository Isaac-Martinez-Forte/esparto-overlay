# Crate source bundles

ZapFast 0.21.1 has 813 registry crates and dependencies from seven Git
snapshots. Grouping the registry sources into one archive reduces Portage's
source file count from 821 to 9: the application, the crate bundle, and seven
Git archives. This reduces download overhead, not the amount of code to build.

The active ebuild still uses individual crates until a stable public URL for
the bundle is available. Nothing has been uploaded. The isolated candidate
and generated archives are under `.qa/crate-tarball/`, excluded from Git.

## Generate the bundle

With Python 3.11 or newer, `xz`, the upstream `Cargo.lock`, and the cached
`.crate` files:

```sh
python3 .github/scripts/bundle-crates.py \
  --lock /path/to/zapfast-0.21.1/Cargo.lock \
  --distdir /path/to/distfiles \
  --output .qa/artifacts/zapfast-0.21.1-crates.tar.xz
```

The tool verifies every archive against its SHA-256 in `Cargo.lock` before
writing output. It preserves source files, licenses and executable bits,
normalizes archive metadata, and adds Cargo's package checksum metadata.
It does not fetch dependencies or change versions. Output is arranged under
`cargo_home/gentoo`, as expected by `cargo.eclass`.

Existing output is never overwritten. To check reproducibility, generate a
second archive under another filename and compare its SHA-256.

## Prepare an ebuild candidate

Once a stable URL has been chosen, create a separate candidate:

```sh
python3 .github/scripts/prepare-bundled-ebuild.py \
  --ebuild net-im/zapfast/zapfast-0.21.1.ebuild \
  --archive-uri https://YOUR_HOST/zapfast-0.21.1-crates.tar.xz \
  --output .qa/candidate/zapfast-0.21.1.ebuild
```

`YOUR_HOST` is a placeholder. The tool removes the registry `CRATES` list,
adds the bundle to `SRC_URI`, and retains the pinned `GIT_CRATES`, licenses
and build phases. Review the candidate before using it in the overlay.
Regenerate its `Manifest` and validate it in a separate repository.

A GitHub Release asset is one possible hosting location when the repository
is eventually published. The generated archive belongs in source hosting,
not in Git or the package's `files/` directory. Keep release assets immutable;
use a new filename if their contents change.

## Local validation, 9 November 2026

The bundle contains all 813 registry crates, totalling 145,683,388 bytes as
individual `.crate` downloads. The generated archive is 105,541,020 bytes
(about 101 MiB), roughly 28% smaller.

Portage fetched the bundle from a loopback-only HTTP server, verified the
candidate Manifest, and completed unpack, prepare and configure. Cargo
resolved the candidate's dependency graph offline. The archive's extracted
41,674 source files were compared with those used by the original successful
build, and the resolved lockfiles match. Two independent bundle generations
produced byte-identical archives. The bundled candidate passes `pkgcheck`
without warnings, including no `TooManyCrates` warning.
This validates source preparation; a full build of the bundled candidate has
not been repeated.

References:

- https://github.com/gentoo/pycargoebuild (crate tarball support).
- Gentoo's `cargo.eclass` and `app-antivirus/clamav` ebuilds (crate bundles
  alongside separately pinned Git dependencies).

Verified archive SHA-256:

```text
b8144a79aea1ebeccdb287706bd5c1920d75fc6d0c7029668821f32c37b1ae00
```
