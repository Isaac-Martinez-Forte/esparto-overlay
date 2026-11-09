# Esparto

My personal Gentoo overlay for packages I use and miss in the repositories
available to me, or want to package differently. For now, it is a small,
experimental collection maintained for my own use.

- Repository name: `esparto`.
- Git repository: `esparto-overlay`.
- Master repository: `gentoo`.
- Maintainer: Isaac Martínez <isaac.martinez@upct.es>.

## Packages

| Package | Version | Architecture | Build |
| --- | --- | --- | --- |
| `net-im/zapfast` | `0.21.1` | `~amd64` | From source, Rust >= 1.98 |
| `app-crypt/autofirma` | `1.9.2` | `~amd64` | From source, JDK 17 and offline Maven |
| `app-crypt/configuradorfnmt` | `5.1.2` | `~amd64` | Official prebuilt JARs, Java >= 21 |

ZapFast's Git dependencies are pinned to the commits in the release's
`Cargo.lock`. The 813 registry crates are grouped in a verified source archive hosted in
[GitHub Releases](https://github.com/Isaac-Martinez-Forte/esparto-overlay/releases/tag/sources-zapfast-0.21.1).
Portage downloads nine source files in total, and `cargo.eclass` builds offline.

## Adding the overlay

For a new installation:

```sh
sudo eselect repository add esparto git https://github.com/Isaac-Martinez-Forte/esparto-overlay.git
sudo emaint sync -r esparto
```

This is a personal overlay, not currently listed with Gentoo. If you already
have a local checkout registered as `esparto`, use that existing configuration.

## Using a local checkout

Run this from the root of your checkout:

```sh
printf '[esparto]\nlocation = %s\nmasters = gentoo\nauto-sync = no\n' "$PWD" |
  sudo tee /etc/portage/repos.conf/esparto.conf
```

If `package.accept_keywords` is a directory:

```sh
printf '%s\n' '=net-im/zapfast-0.21.1::esparto ~amd64' |
  sudo tee /etc/portage/package.accept_keywords/zapfast
sudo emerge --ask --verbose '=net-im/zapfast-0.21.1::esparto'
```

If it is a file, add the same keyword entry to that file instead. An
[example repository configuration](.github/examples/repos.conf/esparto.conf)
is also included.

For ZapFast, a Secret Service provider and `xdg-desktop-portal` with a backend
for your desktop are recommended. X11 and Wayland support are built together.
Optional Omarchy integration is installed under `/usr/share/zapfast/omarchy`.

For AutoFirma installation and browser setup, see the
[AutoFirma notes](.github/docs/autofirma.md). For Configurador FNMT and its
`fnmtcr://` browser handler, see the
[Configurador FNMT notes](.github/docs/configuradorfnmt.md).

See the [validation notes](.github/docs/validation.md) for what has been tested
and the remaining limitations.

## Why Esparto?

Esparto is a plant fibre traditionally used to weave baskets, mats, ropes and
other everyday objects. My grandmother taught me to weave simple things with
it; the more intricate pieces took much more practice. The name is a small
nod to that memory.

## License

The ebuilds are distributed under GPL-2, as stated in their headers and
[LICENSE](LICENSE). Packaged software has its own licenses, declared in each
ebuild's `LICENSE` variable.
