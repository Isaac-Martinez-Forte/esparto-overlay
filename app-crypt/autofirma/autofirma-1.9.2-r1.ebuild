# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11..15} )

inherit desktop java-pkg-2 python-single-r1 xdg

DESCRIPTION="Spanish government electronic signature client built from source"
HOMEPAGE="https://github.com/ctt-gob-es/clienteafirma"
JWS_COMMIT="8c5766a293c2dd3e0d035c0e0d70f88f57235fa8"
SRC_URI="
	https://github.com/ctt-gob-es/clienteafirma/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
	https://github.com/TooTallNate/Java-WebSocket/archive/${JWS_COMMIT}.tar.gz -> java-websocket-${JWS_COMMIT}.tar.gz
	https://github.com/ctt-gob-es/clienteafirma/commit/05d433f6d5439263c5cf58bbd1391e06d5fc6bea.patch
		-> ${P}-firefox-profiles.patch
	https://github.com/ctt-gob-es/clienteafirma/commit/cb08ba7960dab42d0965cfce8c763fe354232f14.patch
		-> ${P}-nss-secret-keys.patch
	https://github.com/Isaac-Martinez-Forte/esparto-overlay/releases/download/sources-autofirma-${PV}/${P}-maven-deps.tar.xz
"
S="${WORKDIR}/clienteafirma-${PV}"

LICENSE="GPL-2+ EUPL-1.1 Apache-2.0 BSD BSD-2 MIT LGPL-2.1+ MPL-1.1"
SLOT="0"
KEYWORDS="~amd64"
IUSE="test"
RESTRICT="!test? ( test )"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

DEPEND="virtual/jdk:17"
BDEPEND="
	${PYTHON_DEPS}
	dev-java/maven-bin:3.9
	test? ( dev-libs/openssl )
"
RDEPEND="
	${PYTHON_DEPS}
	>=dev-libs/openssl-3.0.0
	!app-crypt/autofirma-bin
	virtual/jre:17
	dev-libs/nss[utils]
	x11-misc/xdg-utils
"

PATCHES=(
	"${DISTDIR}/${P}-firefox-profiles.patch"
	"${DISTDIR}/${P}-nss-secret-keys.patch"
)

pkg_setup() {
	java-pkg-2_pkg_setup
	python-single-r1_pkg_setup
}

src_prepare() {
	default
}

src_configure() {
	# Ignore personal/global Maven settings and use the unpacked repository.
	cat > "${T}/maven-settings.xml" <<- _EOF_ || die
	<settings xmlns="http://maven.apache.org/SETTINGS/1.2.0"/>
	_EOF_
}

src_compile() {
	local mvn=(
		mvn-3.9 --offline --batch-mode --no-transfer-progress
		--settings "${T}/maven-settings.xml"
		--global-settings "${T}/maven-settings.xml"
		"-Dmaven.repo.local=${WORKDIR}/maven-repository"
		-Dmaven.test.skip=true
	)
	"${mvn[@]}" -f "${WORKDIR}/Java-WebSocket-${JWS_COMMIT}/pom.xml" \
		clean install || die "Java-WebSocket source build failed"
	# Explicitly include core modules and align their version with the reactor.
	# Otherwise upstream's install profile consumes previously built 1.9 JARs.
	"${mvn[@]}" -Penv-dev,env-install -Denv=install \
		"-Dclienteafirma.version=${PV}" \
		-pl afirma-simple,afirma-ui-simple-configurator -am \
		clean install || die "AutoFirma source build failed"
}

src_test() {
	"${PYTHON}" "${FILESDIR}/autofirma-browser-test.py" || die
	bash "${FILESDIR}/autofirma-smoke-test.sh" \
		"${S}/afirma-simple/target/autofirma.jar" "${T}/smoke-test" || die
}

src_install() {
	java-pkg_dojar afirma-simple/target/autofirma.jar
	java-pkg_dojar afirma-ui-simple-configurator/target/autofirmaConfigurador.jar
	python_newscript "${FILESDIR}/autofirma-browser-setup" autofirma-browser-setup
	sed "s|@EPREFIX@|${EPREFIX}|g" "${FILESDIR}/autofirma-launcher-pre" \
		> "${T}/autofirma-launcher-pre" || die
	java-pkg_dolauncher autofirma --jar autofirma.jar -pre "${T}/autofirma-launcher-pre" \
		--java_args "-Djdk.tls.maxHandshakeMessageSize=65536"
	java-pkg_dolauncher autofirma-configurator --jar autofirmaConfigurador.jar \
		--pkg_args "-jnlp"
	domenu "${FILESDIR}/autofirma.desktop"
	local installer="afirma-simple-installer/linux/instalador_deb/src"
	newicon "${installer}/usr/share/AutoFirma/AutoFirma.svg" autofirma.svg
	dodoc README.md
	dodoc -r license
}

pkg_postinst() {
	xdg_pkg_postinst
	elog "Launch AutoFirma as your normal desktop user. Browser communication is"
	elog "configured automatically at launch for existing Firefox/NSS profiles."
	elog "If a browser blocks certificate updates, close it and launch AutoFirma again."
}
