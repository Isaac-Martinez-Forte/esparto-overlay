# Publishing notes

Esparto is hosted at https://github.com/Isaac-Martinez-Forte/esparto-overlay.
The Git branch is `main`; `origin` uses the owner's SSH URL.
This remains a personal overlay. No listing with Gentoo or Zugaina has been
requested.

## Contact and Git identity

The package maintainer is Isaac Martínez <isaac.martinez@upct.es>.
This contact can differ from the email used to author Git commits.

## Updating the overlay

Review and commit the intended source changes, then push `main`:

```sh
git status --short
git diff
git add PATHS_TO_CHANGED_FILES
git diff --cached
git commit -m 'Describe the package change'
git push origin main
```

`PATHS_TO_CHANGED_FILES` is a placeholder. The machine-specific `esparto.conf`,
QA environments, generated metadata and source archives are excluded from Git.
The GitHub workflow checks syntax and package quality; it does not compile
packages. Real build and functional checks remain part of package maintenance.

## Dependency source releases

For each new ZapFast dependency bundle:

1. Review the upstream source archive and `Cargo.lock`.
2. Generate the bundle locally with `.github/scripts/bundle-crates.py`.
3. Record the source and bundle SHA-256 values in
   `.github/source-bundles/zapfast-VERSION.json`, following the existing entry.
4. Add release notes in `.github/releases/sources-zapfast-VERSION.md`.
5. Commit and push the configuration and scripts before pushing an annotated
   `sources-zapfast-VERSION` tag.

The tag starts the `Publish crate sources` workflow. It verifies the upstream
archive, downloads crates and verifies their lockfile checksums, regenerates the
bundle and checks that its SHA-256 matches the reviewed local archive. Only
then does it publish a source-only Release with the archive and `SHA256SUMS`.
The workflow uses GitHub's built-in token; no personal access token is needed.

After publication, test the public asset URL with Portage before updating
`SRC_URI` and regenerating the package `Manifest`. Keep published assets
immutable and retain those referenced by existing ebuilds.

See [crate bundle notes](crate-bundles.md) for source format and local validation.

## Local QA

From the repository root, with Portage and `app-portage/pkgcheck` installed:

```sh
bash -n net-im/zapfast/zapfast-0.21.1.ebuild
ebuild net-im/zapfast/zapfast-0.21.1.ebuild manifest
pkgcheck scan --repo "$PWD" --exit error
```

## Packaging references

- https://devmanual.gentoo.org/general-concepts/overlay/
- https://devmanual.gentoo.org/ebuild-writing/misc-files/metadata/
- https://devmanual.gentoo.org/ebuild-writing/file-format/

ZapFast packaging is based on the source and `Cargo.lock` at
https://github.com/crmne/zapfast/tree/v0.21.1 and its
`packaging/arch/zapfast/PKGBUILD.in` recipe by Carmine Paolino.

## AutoFirma dependency releases

AutoFirma uses a separate `sources-autofirma-VERSION` tag and the
`Publish Maven dependencies` workflow. It rebuilds an offline Maven repository
from the reviewed `.github/maven-bundles/` inventory, verifies its checksum and
publishes the archive. See [AutoFirma maintenance notes](autofirma.md).
