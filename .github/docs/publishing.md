# Publishing notes

Personal notes for uploading this overlay. The local Git repository uses
`main`; no GitHub remote has been configured yet.

## Contact and Git identity

The package maintainer is Isaac Martínez <isaac.martinez@upct.es>.
This contact can differ from the email used to author Git commits.

## Uploading to GitHub

Create an empty repository named `esparto-overlay` under the chosen account.
Review the staged files and your Git author identity before the first commit:

```sh
git status --short
git diff --cached
git var GIT_AUTHOR_IDENT
git commit -m 'Initial Esparto overlay'
git remote add origin 'git@github.com:YOUR_ACCOUNT/esparto-overlay.git'
git push -u origin main
```

Replace `YOUR_ACCOUNT` with the actual account. For later changes, stage the
intended files and use a commit message describing the change.
The machine-specific `esparto.conf`, QA environments and generated metadata
caches are excluded from Git.

## Optional public use

Once uploaded, the overlay can be added by URL:

```sh
sudo eselect repository add esparto git 'https://github.com/YOUR_ACCOUNT/esparto-overlay.git'
sudo emaint sync -r esparto
```

Listing the overlay with Gentoo and checking its indexing on Zugaina can be
considered later. Neither has been requested yet.

## Local checks

From the repository root, with Portage and `app-portage/pkgcheck` installed:

```sh
bash -n net-im/zapfast/zapfast-0.21.1.ebuild
ebuild net-im/zapfast/zapfast-0.21.1.ebuild manifest
pkgcheck scan --repo "$PWD" --exit error
```

The GitHub workflow runs syntax and QA checks, not package builds. Its QA tool
versions are pinned as a compatible set and should be reviewed together when
updating them. A real installation and functional checks are still needed
when changing a package.

A verified crate source bundle and an isolated ebuild candidate are prepared
locally. See [crate bundle notes](crate-bundles.md) for generation, validation
and the hosting step needed before switching the active ebuild.

## Packaging references

- https://devmanual.gentoo.org/general-concepts/overlay/
- https://devmanual.gentoo.org/ebuild-writing/misc-files/metadata/
- https://devmanual.gentoo.org/ebuild-writing/file-format/

ZapFast packaging is based on the source and `Cargo.lock` at
https://github.com/crmne/zapfast/tree/v0.21.1 and its
`packaging/arch/zapfast/PKGBUILD.in` recipe by Carmine Paolino.
