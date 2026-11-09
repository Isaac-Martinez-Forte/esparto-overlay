# Configurador FNMT

`app-crypt/configuradorfnmt-5.1.2` packages the official FNMT Java application.
The [official download page](https://www.sede.fnmt.gob.es/descargas/descarga-software)
provides a 5.1.2 DEB, while its RPM and Gentoo's existing package are at 5.0.3.
The [AUR package](https://aur.archlinux.org/packages/configuradorfnmt) also uses
that DEB.

## Packaging

This is proprietary, prebuilt software: no published application sources were
identified. The ebuild extracts four unmodified official JARs, the icon and the
copyright notice from the DEB. It downloads directly from FNMT; `mirror` and
`bindist` are restricted under the existing Gentoo `FNMT-RCM` license.

The bundled JRE and Debian maintainer scripts are not installed. Gentoo's
Java launcher selects a compatible runtime (Java 21 or later), independently
of the global Java selection. Java 21 is both the upstream bundled runtime
and the minimum required by the application's base class files.

The desktop entry registers `x-scheme-handler/fnmtcr` through the usual Gentoo
XDG integration. The browser may ask permission to open Configurador FNMT.
No Firefox preferences or personal certificate stores are edited on installation.
This is separate from AutoFirma; both applications can be installed together.

## Installation from the local overlay

With the checkout already registered as `esparto`:

```sh
sudo emerge --ask --verbose '=app-crypt/configuradorfnmt-5.1.2::esparto'
```

If Portage requests keyword or license acceptance, review its proposed changes.
The package uses `~amd64` and `FNMT-RCM`; the repository qualifier selects this
ebuild over Gentoo's older version.

If your desktop does not choose the handler automatically, run this as your
normal desktop user after installation:

```sh
xdg-mime default configuradorfnmt.desktop x-scheme-handler/fnmtcr
xdg-mime query default x-scheme-handler/fnmtcr
```

The second command should print `configuradorfnmt.desktop`.
Starting `configuradorfnmt` without a request URL displays the About dialog.
The application handles certificate workflows launched by the FNMT website.

## Local validation

- Portage extraction, preparation and staged installation completed.
- All four installed JARs match the official DEB byte for byte.
- Java 25 loaded and verified the main class using `--dry-run -Xverify:all`;
  the main method was not executed.
- The desktop entry passes `desktop-file-validate`.
- The package passes `pkgcheck` without findings.
- The user installed the package successfully and confirmed that running
  `configuradorfnmt` displays the About dialog.
- The installed `fnmtcr` MIME association resolves to `configuradorfnmt.desktop`.

An actual browser certificate request has not been tested. The checks above
do not request or renew a certificate and do not prove that FNMT's online
workflow succeeds.
