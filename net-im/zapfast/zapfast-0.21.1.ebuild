# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

RUST_MIN_VER="1.98.0"

declare -A GIT_CRATES=(
	[cpal]="https://github.com/crmne/cpal;fcd8b6ebee9d822426fa8d6839cdd89af6e0d491;cpal-fcd8b6ebee9d822426fa8d6839cdd89af6e0d491"
	[ecolor]="https://github.com/crmne/egui;1cc61c8a83625855b08cb8fed912900cf3b01b70;egui-1cc61c8a83625855b08cb8fed912900cf3b01b70/crates/ecolor"
	[eframe]="https://github.com/crmne/egui;1cc61c8a83625855b08cb8fed912900cf3b01b70;egui-1cc61c8a83625855b08cb8fed912900cf3b01b70/crates/eframe"
	[egui]="https://github.com/crmne/egui;1cc61c8a83625855b08cb8fed912900cf3b01b70;egui-1cc61c8a83625855b08cb8fed912900cf3b01b70/crates/egui"
	[egui-wgpu]="https://github.com/crmne/egui;1cc61c8a83625855b08cb8fed912900cf3b01b70;egui-1cc61c8a83625855b08cb8fed912900cf3b01b70/crates/egui-wgpu"
	[egui-winit]="https://github.com/crmne/egui;1cc61c8a83625855b08cb8fed912900cf3b01b70;egui-1cc61c8a83625855b08cb8fed912900cf3b01b70/crates/egui-winit"
	[egui_extras]="https://github.com/crmne/egui;1cc61c8a83625855b08cb8fed912900cf3b01b70;egui-1cc61c8a83625855b08cb8fed912900cf3b01b70/crates/egui_extras"
	[egui_glow]="https://github.com/crmne/egui;1cc61c8a83625855b08cb8fed912900cf3b01b70;egui-1cc61c8a83625855b08cb8fed912900cf3b01b70/crates/egui_glow"
	[emath]="https://github.com/crmne/egui;1cc61c8a83625855b08cb8fed912900cf3b01b70;egui-1cc61c8a83625855b08cb8fed912900cf3b01b70/crates/emath"
	[epaint]="https://github.com/crmne/egui;1cc61c8a83625855b08cb8fed912900cf3b01b70;egui-1cc61c8a83625855b08cb8fed912900cf3b01b70/crates/epaint"
	[epaint_default_fonts]="https://github.com/crmne/egui;1cc61c8a83625855b08cb8fed912900cf3b01b70;egui-1cc61c8a83625855b08cb8fed912900cf3b01b70/crates/epaint_default_fonts"
	[fastframe-audio]="https://github.com/crmne/fastframe;8faf6f99ba782b22916a118c77d1a25d97d1414f;fastframe-8faf6f99ba782b22916a118c77d1a25d97d1414f/crates/fastframe-audio"
	[fastframe-autostart]="https://github.com/crmne/fastframe;8faf6f99ba782b22916a118c77d1a25d97d1414f;fastframe-8faf6f99ba782b22916a118c77d1a25d97d1414f/crates/fastframe-autostart"
	[fastframe-desktop]="https://github.com/crmne/fastframe;8faf6f99ba782b22916a118c77d1a25d97d1414f;fastframe-8faf6f99ba782b22916a118c77d1a25d97d1414f/crates/fastframe-desktop"
	[fastframe-dirs]="https://github.com/crmne/fastframe;8faf6f99ba782b22916a118c77d1a25d97d1414f;fastframe-8faf6f99ba782b22916a118c77d1a25d97d1414f/crates/fastframe-dirs"
	[fastframe-dock]="https://github.com/crmne/fastframe;8faf6f99ba782b22916a118c77d1a25d97d1414f;fastframe-8faf6f99ba782b22916a118c77d1a25d97d1414f/crates/fastframe-dock"
	[fastframe-emoji]="https://github.com/crmne/fastframe;8faf6f99ba782b22916a118c77d1a25d97d1414f;fastframe-8faf6f99ba782b22916a118c77d1a25d97d1414f/crates/fastframe-emoji"
	[fastframe-file]="https://github.com/crmne/fastframe;8faf6f99ba782b22916a118c77d1a25d97d1414f;fastframe-8faf6f99ba782b22916a118c77d1a25d97d1414f/crates/fastframe-file"
	[fastframe-fonts]="https://github.com/crmne/fastframe;8faf6f99ba782b22916a118c77d1a25d97d1414f;fastframe-8faf6f99ba782b22916a118c77d1a25d97d1414f/crates/fastframe-fonts"
	[fastframe-i18n]="https://github.com/crmne/fastframe;8faf6f99ba782b22916a118c77d1a25d97d1414f;fastframe-8faf6f99ba782b22916a118c77d1a25d97d1414f/crates/fastframe-i18n"
	[fastframe-icons]="https://github.com/crmne/fastframe;8faf6f99ba782b22916a118c77d1a25d97d1414f;fastframe-8faf6f99ba782b22916a118c77d1a25d97d1414f/crates/fastframe-icons"
	[fastframe-instance]="https://github.com/crmne/fastframe;8faf6f99ba782b22916a118c77d1a25d97d1414f;fastframe-8faf6f99ba782b22916a118c77d1a25d97d1414f/crates/fastframe-instance"
	[fastframe-log]="https://github.com/crmne/fastframe;8faf6f99ba782b22916a118c77d1a25d97d1414f;fastframe-8faf6f99ba782b22916a118c77d1a25d97d1414f/crates/fastframe-log"
	[fastframe-notifications]="https://github.com/crmne/fastframe;8faf6f99ba782b22916a118c77d1a25d97d1414f;fastframe-8faf6f99ba782b22916a118c77d1a25d97d1414f/crates/fastframe-notifications"
	[fastframe-power]="https://github.com/crmne/fastframe;8faf6f99ba782b22916a118c77d1a25d97d1414f;fastframe-8faf6f99ba782b22916a118c77d1a25d97d1414f/crates/fastframe-power"
	[fastframe-scroll]="https://github.com/crmne/fastframe;8faf6f99ba782b22916a118c77d1a25d97d1414f;fastframe-8faf6f99ba782b22916a118c77d1a25d97d1414f/crates/fastframe-scroll"
	[fastframe-shell]="https://github.com/crmne/fastframe;8faf6f99ba782b22916a118c77d1a25d97d1414f;fastframe-8faf6f99ba782b22916a118c77d1a25d97d1414f/crates/fastframe-shell"
	[fastframe-text]="https://github.com/crmne/fastframe;8faf6f99ba782b22916a118c77d1a25d97d1414f;fastframe-8faf6f99ba782b22916a118c77d1a25d97d1414f/crates/fastframe-text"
	[fastframe-theme]="https://github.com/crmne/fastframe;8faf6f99ba782b22916a118c77d1a25d97d1414f;fastframe-8faf6f99ba782b22916a118c77d1a25d97d1414f/crates/fastframe-theme"
	[fastframe-titlebar]="https://github.com/crmne/fastframe;8faf6f99ba782b22916a118c77d1a25d97d1414f;fastframe-8faf6f99ba782b22916a118c77d1a25d97d1414f/crates/fastframe-titlebar"
	[fastframe-tray]="https://github.com/crmne/fastframe;8faf6f99ba782b22916a118c77d1a25d97d1414f;fastframe-8faf6f99ba782b22916a118c77d1a25d97d1414f/crates/fastframe-tray"
	[fastframe-update]="https://github.com/crmne/fastframe;8faf6f99ba782b22916a118c77d1a25d97d1414f;fastframe-8faf6f99ba782b22916a118c77d1a25d97d1414f/crates/fastframe-update"
	[mp4]="https://github.com/crmne/mp4-rust;35560e94f5e871a2b2d88bfe964013b39af131e8;mp4-rust-35560e94f5e871a2b2d88bfe964013b39af131e8"
	[rodio]="https://github.com/crmne/rodio;742090d57a4c83b23bd990ba0dcf939d09dbeb94;rodio-742090d57a4c83b23bd990ba0dcf939d09dbeb94"
	[wacore]="https://github.com/crmne/whatsapp-rust;94f7c1376f8f6a77c55d85570a260600ad27de0b;whatsapp-rust-94f7c1376f8f6a77c55d85570a260600ad27de0b/wacore"
	[wacore-appstate]="https://github.com/crmne/whatsapp-rust;94f7c1376f8f6a77c55d85570a260600ad27de0b;whatsapp-rust-94f7c1376f8f6a77c55d85570a260600ad27de0b/wacore/appstate"
	[wacore-binary]="https://github.com/crmne/whatsapp-rust;94f7c1376f8f6a77c55d85570a260600ad27de0b;whatsapp-rust-94f7c1376f8f6a77c55d85570a260600ad27de0b/wacore/binary"
	[wacore-derive]="https://github.com/crmne/whatsapp-rust;94f7c1376f8f6a77c55d85570a260600ad27de0b;whatsapp-rust-94f7c1376f8f6a77c55d85570a260600ad27de0b/wacore/derive"
	[wacore-libsignal]="https://github.com/crmne/whatsapp-rust;94f7c1376f8f6a77c55d85570a260600ad27de0b;whatsapp-rust-94f7c1376f8f6a77c55d85570a260600ad27de0b/wacore/libsignal"
	[wacore-noise]="https://github.com/crmne/whatsapp-rust;94f7c1376f8f6a77c55d85570a260600ad27de0b;whatsapp-rust-94f7c1376f8f6a77c55d85570a260600ad27de0b/wacore/noise"
	[waproto]="https://github.com/crmne/whatsapp-rust;94f7c1376f8f6a77c55d85570a260600ad27de0b;whatsapp-rust-94f7c1376f8f6a77c55d85570a260600ad27de0b/waproto"
	[whatsapp-rust]="https://github.com/crmne/whatsapp-rust;94f7c1376f8f6a77c55d85570a260600ad27de0b;whatsapp-rust-94f7c1376f8f6a77c55d85570a260600ad27de0b"
	[whatsapp-rust-sqlite-storage]="https://github.com/crmne/whatsapp-rust;94f7c1376f8f6a77c55d85570a260600ad27de0b;whatsapp-rust-94f7c1376f8f6a77c55d85570a260600ad27de0b/storages/sqlite-storage"
	[whatsapp-rust-tokio-transport]="https://github.com/crmne/whatsapp-rust;94f7c1376f8f6a77c55d85570a260600ad27de0b;whatsapp-rust-94f7c1376f8f6a77c55d85570a260600ad27de0b/transports/tokio-transport"
	[whatsapp-rust-ureq-http-client]="https://github.com/crmne/whatsapp-rust;94f7c1376f8f6a77c55d85570a260600ad27de0b;whatsapp-rust-94f7c1376f8f6a77c55d85570a260600ad27de0b/http_clients/ureq-client"
	[dpi]="https://github.com/crmne/winit;59ebfb727b8c83fcd28f8ca59c3733e32b4b4e9b;winit-59ebfb727b8c83fcd28f8ca59c3733e32b4b4e9b/dpi"
	[winit]="https://github.com/crmne/winit;59ebfb727b8c83fcd28f8ca59c3733e32b4b4e9b;winit-59ebfb727b8c83fcd28f8ca59c3733e32b4b4e9b"
)

inherit cargo desktop xdg

DESCRIPTION="Native WhatsApp desktop client built with Rust and egui"
HOMEPAGE="https://github.com/crmne/zapfast https://zapfast.rocks"
SRC_URI="
	https://github.com/crmne/zapfast/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
	https://github.com/Isaac-Martinez-Forte/esparto-overlay/releases/download/sources-${P}/${P}-crates.tar.xz
	${CARGO_CRATE_URIS}
"

# Application, bundled assets and statically linked Rust dependencies.
LICENSE="
	0BSD Apache-2.0 Apache-2.0-with-LLVM-exceptions BSD BSD-2 CC0-1.0
	CDLA-Permissive-2.0 GPL-2 ISC MIT MIT-0 MPL-2.0 OFL-1.1
	UbuntuFontLicense-1.0 Unicode-3.0 Unlicense ZLIB
"
SLOT="0"
KEYWORDS="~amd64"
IUSE="test"
RESTRICT="!test? ( test )"

RDEPEND="
	media-libs/alsa-lib
	media-libs/libglvnd
	media-libs/libwebp:=
	media-libs/opus
	media-video/pipewire:=
	x11-libs/libX11
	x11-libs/libxcb
	x11-libs/libXcursor
	x11-libs/libXi
	x11-libs/libXrandr
	x11-libs/libxkbcommon[X]
	dev-libs/wayland
"
DEPEND="${RDEPEND}"
BDEPEND="
	dev-build/cmake
	dev-lang/perl
	llvm-core/clang
	virtual/pkgconfig
	test? ( media-fonts/liberation-fonts )
"

src_prepare() {
	default
	# Upstream's crates.io patches otherwise try to resolve their Git sources
	# before Cargo applies the Git overrides generated by cargo.eclass.
	local crate uri commit crate_dir
	local git_ref='git = "[^"]+", (rev|tag) = "[^"]+"'
	for crate in "${!GIT_CRATES[@]}"; do
		IFS=';' read -r uri commit crate_dir <<< "${GIT_CRATES[${crate}]}"
		sed -i -E "/^${crate} = \{ git = /s~${git_ref}~path = \"${WORKDIR}/${crate_dir}\"~" \
			Cargo.toml || die
	done
}

src_configure() {
	cargo_src_configure --bin zapfast
}

src_test() {
	cargo_src_test --features demo --all-targets
}

src_install() {
	dobin "$(cargo_target_dir)/zapfast"
	domenu packaging/applications/zapfast.desktop
	doicon -s scalable packaging/icons/zapfast.svg
	dodoc README.md THIRD-PARTY-NOTICES.md
	dodoc -r assets/sounds
	insinto /usr/share/zapfast/omarchy
	doins contrib/omarchy/zapfast.json.tpl
	exeinto /usr/share/zapfast/omarchy
	doexe contrib/omarchy/zapfast-theme
}

pkg_postinst() {
	xdg_pkg_postinst
	elog "A Secret Service provider is recommended for storing encryption keys."
	elog "Install xdg-desktop-portal and a desktop backend for attachment dialogs."
}
