# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop java-pkg-2 unpacker xdg

DESCRIPTION="FNMT certificate request generator"
HOMEPAGE="https://www.sede.fnmt.gob.es/descargas/descarga-software"
SRC_URI="https://descargas.cert.fnmt.es/Linux/${PN}_${PV}.amd64.deb"
S="${WORKDIR}"

LICENSE="FNMT-RCM"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="mirror bindist"

BDEPEND="app-arch/zstd"
RDEPEND="
	>=virtual/jre-21:*
	sys-apps/pcsc-lite
"

src_unpack() {
	unpack_deb "${A}"
}

src_prepare() {
	default
}

src_configure() { :; }
src_compile() { :; }

src_install() {
	# Preserve upstream's signed JARs; use Gentoo's JVM instead of the bundled JRE.
	java-pkg_dojar usr/lib/${PN}/*.jar
	java-pkg_dolauncher ${PN} --jar ${PN}.jar
	doicon usr/lib/${PN}/${PN}.png
	domenu "${FILESDIR}/${PN}.desktop"
	dodoc usr/share/doc/${PN}/copyright
}
