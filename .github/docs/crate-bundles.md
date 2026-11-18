# Crate source bundles

## ZapFast 0.21.3 update

The update uses 808 checksum-verified registry crates and seven pinned Git
snapshots from upstream's Cargo.lock. Fastframe moves to 0.17.1, and the
egui, winit and whatsapp-rust snapshots also change. Rust >= 1.98 remains
required. The SQLCipher source update is covered by MIT, BSD and public-domain
licenses; its bundled public-domain notices are reflected in the ebuild.
The registry source archive is 103,610,244 bytes. SHA-256:

```text
0e8262a3bc680579e05bbbdf0e2f27a7b98b737290706c10d52a0839e40c06b5
```

Two independent local bundle generations and a run of the release builder
with freshly downloaded crates produced identical archives. All 47 Git package
paths were verified against the pinned source snapshots. The candidate overlay
passes pkgcheck without warnings.

The source release specification and notes are prepared locally. The public
archive must be published and its download verified before updating main.
Local validation on 18 November 2026 completed a full offline release build
and staged installation. The staged binary reports `zapfast 0.21.3`; `--help`,
shared-library resolution and desktop entry validation pass. The optional
test suite and an authenticated WhatsApp session were not run.

## ZapFast 0.21.2 update

The new ebuild pins seven Git snapshots and 816 registry crates from
`v0.21.2/Cargo.lock`. Portage still needs nine source files in total. Fastframe
moves to 0.16.1 and the WhatsApp Rust dependencies move to the upstream
`oxidezap/whatsapp-rust` repository at the locked commit. Rust >= 1.98 remains
required.

The registry archive was generated twice from checksum-verified `.crate`
files; both outputs are byte-identical. Size: 106,312,484 bytes. SHA-256:

```text
534d60997c95b335d626c35cdfa651eb049d76fe7a0aa865e4a2f009212dd6ee
```

Local validation on 15 November 2026 completed a full offline release build
and staged installation using the bundled sources. The staged binary reports
`zapfast 0.21.2`; `--help`, shared-library resolution and desktop entry
validation pass. The candidate overlay passes `pkgcheck` without warnings.
The optional test suite and an authenticated WhatsApp session were not run.

The release specification and source-only release notes are prepared for
`sources-zapfast-0.21.2`. Its public asset must be published and fetched
successfully before this update is advertised as available online. The
previous release asset remains unchanged for the 0.21.1 ebuild.

## Previous bundle: ZapFast 0.21.1

ZapFast 0.21.1 has 813 registry crates and dependencies from seven Git
snapshots. Grouping the registry sources into one archive reduces Portage's
source file count from 821 to 9: the application, the crate bundle, and seven
Git archives. This reduces download overhead, not the amount of code to build.

The active ebuild uses the archive published in the
[dependency source Release](https://github.com/Isaac-Martinez-Forte/esparto-overlay/releases/tag/sources-zapfast-0.21.1).
GitHub Actions regenerated it and verified its SHA-256 against the locally
reviewed archive before publishing. Local test files and archives under `.qa/`
are excluded from Git.

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

For a future version, create a separate candidate using its published asset URL:

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

Bundles are hosted as GitHub Release assets. The generated archive belongs in source hosting,
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
The public GitHub asset was also downloaded by Portage into a fresh distfiles
directory and checked against the reviewed hash. Unpack, prepare and configure
completed, and Cargo resolved the same dependency graph offline. This validates
source preparation; a full build with the bundled sources has not been repeated.

The [publishing workflow](publishing.md#dependency-source-releases) regenerates
reviewed archives from versioned specifications.

References:

- https://github.com/gentoo/pycargoebuild (crate tarball support).
- Gentoo's `cargo.eclass` and `app-antivirus/clamav` ebuilds (crate bundles
  alongside separately pinned Git dependencies).

Verified archive SHA-256:

```text
b8144a79aea1ebeccdb287706bd5c1920d75fc6d0c7029668821f32c37b1ae00
```
