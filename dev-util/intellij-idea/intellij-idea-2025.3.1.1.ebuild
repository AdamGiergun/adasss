# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
inherit check-reqs desktop wrapper

MY_PV=idea-$(ver_cut 1-4)

DESCRIPTION="A complete toolset for web, mobile and enterprise development"

HOMEPAGE="https://www.jetbrains.com/idea/"

SRC_URI="
	amd64? ( https://download.jetbrains.com/idea/${MY_PV}.tar.gz -> ${P}.tar.gz )
	arm64? ( https://download.jetbrains.com/idea/${MY_PV}-aarch64.tar.gz -> ${P}-aarch64.tar.gz )
"

S="${WORKDIR}/idea-IC-${PV}"
LICENSE="Apache-2.0 BSD BSD-2 CC0-1.0 CC-BY-2.5 CDDL-1.1
	codehaus-classworlds CPL-1.0 EPL-1.0 EPL-2.0
	GPL-2 GPL-2-with-classpath-exception ISC
	JDOM LGPL-2.1 LGPL-2.1+ LGPL-3-with-linking-exception MIT
	MPL-1.0 MPL-1.1 OFL-1.1 ZLIB"

SLOT="0"
KEYWORDS="~amd64 ~arm64"
IUSE="bundled-xvfb experimental professional wayland"
REQUIRED_USE="experimental? ( wayland )
	professional? ( || ( bundled-xvfb !bundled-xvfb ) )
	bundled-xvfb? ( professional )"

DEPEND=">=virtual/jdk-17:*"

RDEPEND="${DEPEND}
	professional? ( bundled-xvfb? (
			dev-libs/libpcre2
			sys-libs/pam
			sys-process/audit
		)
		!bundled-xvfb? (
			x11-base/xorg-server[xvfb]
		)
	)
	sys-libs/glibc
	media-libs/harfbuzz
	dev-java/jansi-native
	virtual/zlib:=
	x11-libs/libX11
	x11-libs/libXrender
	media-libs/freetype
	x11-libs/libXext
	dev-libs/wayland
	x11-libs/libXi
	x11-libs/libXtst
	x11-libs/libXcomposite
	x11-libs/libXdamage
	x11-libs/libXrandr
	media-libs/alsa-lib
	app-accessibility/at-spi2-core
	x11-libs/cairo
	net-print/cups
	x11-libs/libdrm
	media-libs/mesa
	dev-libs/nspr
	dev-libs/nss
	dev-libs/libdbusmenu
	x11-libs/libxkbcommon
	x11-libs/libXcursor
	x11-libs/pango"

RESTRICT="bindist mirror splitdebug strip"

QA_PREBUILT="opt/${PN}/*"

BDEPEND="dev-util/patchelf"

pkg_pretend() {
	CHECKREQS_DISK_BUILD="4G"
	check-reqs_pkg_pretend
}

pkg_setup() {
	CHECKREQS_DISK_BUILD="4G"
	check-reqs_pkg_pretend
}

src_unpack() {

	default_src_unpack
	if [ ! -d "$S" ]; then
		einfo "Renaming source directory to predictable name..."
		mv $(ls "${WORKDIR}") "idea-IC-${PV}" || die
	fi
}

src_prepare() {

	default_src_prepare

	sed -i \
		-e "\$a\\\\" \
		-e "\$a#-----------------------------------------------------------------------" \
		-e "\$a# Disable automatic updates as these are handled through Gentoo's" \
		-e "\$a# package manager. See bug #704494" \
		-e "\$a#-----------------------------------------------------------------------" \
		-e "\$aide.no.platform.update=Gentoo"  bin/idea.properties

	patchelf --set-rpath '$ORIGIN' "jbr/lib/libjcef.so" || die
	patchelf --set-rpath '$ORIGIN' "jbr/lib/libcef.so" || die
	patchelf --set-rpath '$ORIGIN' "jbr/lib/jcef_helper" || die

	if use bundled-xvfb; then
		patchelf --set-rpath '$ORIGIN/../lib' "${S}"/plugins/remote-dev-server/selfcontained/bin/{Xvfb,xkbcomp} || die
		patchelf --set-rpath '$ORIGIN' "${S}"/plugins/remote-dev-server/selfcontained/lib/lib*.so* || die
	else
		rm -vr "${S}"/plugins/remote-dev-server/selfcontained || die
		sed '/export REMOTE_DEV_SERVER_IS_NATIVE_LAUNCHER/a export REMOTE_DEV_SERVER_USE_SELF_CONTAINED_LIBS=1' \
		  -i bin/remote-dev-server.sh || die
	fi

	if ! use elibc_musl; then
		rm plugins/platform-ijent-impl/ijent-aarch64-unknown-linux-musl-release
	fi

	eapply_user
}

src_install() {
	local dir="/opt/${PN}"
	local dst="${D}${dir}"

	insinto "${dir}"
	doins -r *

	fperms 755 "${dir}"/bin/{format.sh,idea.sh,inspect.sh,jetbrains_client.sh,ltedit.sh,fsnotifier,idea,restarter}
	fperms -R 755 "${dir}"/jbr/bin
	fperms 755 "${dir}"/jbr/lib/{chrome-sandbox,jcef_helper,jexec,jspawnhelper}
	fperms -R 755 "${dir}"/plugins/Kotlin/kotlinc/bin
	fperms -R 755 "${dir}"/plugins/maven/lib/maven3/bin

	# bundled script is always lowercase, and doesn't have -ultimate, -professional suffix.
	local bundled_script_name="${PN#*-}.sh"

	make_wrapper "${PN}" "${dir}/bin/$bundled_script_name" || die

	local pngfile="$(find ${dst}/bin -maxdepth 1 -iname '*.png')"
	newicon $pngfile "${PN}.png" || die "we died"

	if use experimental; then
		make_desktop_entry "/opt/intellij-idea/bin/idea -Dawt.toolkit.name=WLToolkit" \
			"IntelliJ IDEA" "${PN}" "Development;IDE;"

		ewarn "You have enabled the experimental USE flag."
		ewarn "This is a Wayland support preview. Expect instability."
	else
		make_desktop_entry "/opt/intellij-idea/bin/idea" \
			"IntelliJ IDEA" "${PN}" "Development;IDE;"
	fi

	newenvd - 99idea-community <<-EOF
		# Configuration file idea-community
		IDEA_JDK="${dir}/jbr"
	EOF

	# recommended by: https://confluence.jetbrains.com/display/IDEADEV/Inotify+Watches+Limit
	mkdir -p "${D}/etc/sysctl.d/" || die
	echo "fs.inotify.max_user_watches = 524288" > "${D}/etc/sysctl.d/30-idea-inotify-watches.conf" || die
}

pkg_postrm() {
	elog "Idea Community data files were not removed."
	elog "If there will be no other applications using them anymore"
	elog "remove manually following folders:"
	elog ""
	elog "		~/.config/JetBrains/IdeaIC*/"
	elog "		~/.local/share/JetBrains/IdeaIC*/"
	elog ""
	elog "Also, if there will be no other applications using Gradle, remove:"
	elog ""
	elog "		~/.gradle/"
}
