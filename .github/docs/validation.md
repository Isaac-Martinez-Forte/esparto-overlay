# ZapFast validation

## Local checks, 9 November 2026

- Production build completed on Gentoo amd64 with Rust 1.98.1.
- `src_install` completed in a staging directory using user ownership.
- The resulting binary reports `zapfast 0.21.1` with `--version`;
  `--help` works and all libraries listed by `ldd` resolve.
- `desktop-file-validate` reports no warnings.
- The full repository scan with the QA tools selected for CI reports no
  errors. `pkgcheck` reports `TooManyCrates` for ZapFast's 813 crates.
  A hosted dependency source archive remains a possible improvement.

The subsequent installation through `emerge` also completed: `/usr/bin/zapfast`
reports version 0.21.1 and Portage records repository `esparto`. The graphical
interface, WhatsApp account linking and upstream test suite have not been tested.

A [crate source bundle](crate-bundles.md) has also been prepared and tested in
an isolated repository. The active ebuild still uses individual crate downloads
until the bundle has a stable hosting URL.

Local build files and logs are excluded from the repository. The build check
disabled ccache because its global directory was not writable by the test
user. Packaging currently retains upstream's bundled SQLCipher/OpenSSL build;
using system libraries could be investigated later.
