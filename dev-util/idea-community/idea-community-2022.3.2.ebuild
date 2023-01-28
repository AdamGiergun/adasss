# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
inherit desktop wrapper

DESCRIPTION="A complete toolset for web, mobile and enterprise development"
HOMEPAGE="https://www.jetbrains.com/idea/"
SRC_URI="https://download.jetbrains.com/idea/ideaIC-${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="Apache-2.0 BSD BSD-2 CC0-1.0 CC-BY-2.5 CDDL-1.1
	codehaus-classworlds CPL-1.0 EPL-1.0 EPL-2.0
	GPL-2 GPL-2-with-classpath-exception ISC
	JDOM LGPL-2.1 LGPL-2.1+ LGPL-3-with-linking-exception MIT
	MPL-1.0 MPL-1.1 OFL ZLIB"

SLOT="0"
KEYWORDS="~amd64 ~arm64"

RDEPEND="${DEPEND}
	sys-libs/glibc
	media-libs/harfbuzz
	dev-java/jansi-native
	dev-libs/libdbusmenu"

BDEPEND="dev-util/patchelf"
RESTRICT="bindist mirror splitdebug strip"
S="${WORKDIR}/idea-IC-${PV}"

QA_PREBUILT="opt/${PN}/*"

# QA_PREBUILT="
#	opt/${PN}/bin/*
#	opt/${PN}/jbr/bin/*
#	opt/${PN}/jbr/lib/*
#	opt/${PN}/jre/lib/server/*
#	opt/${PN}/jre/lib/swiftshader/*
#	opt/${PN}/lib/pty4j-native/linux/x86/*
#	opt/${PN}/lib/pty4j-native/linux/x86-64/*
#	opt/${PN}/plugins/android/resources/native/linux/*
#	opt/${PN}/plugins/cwm-plugin/quiche-native/linux-x86-64/*
#	opt/${PN}/plugins/maven/lib/maven3/lib/jansi-native/linux32/*
#	opt/${PN}/plugins/maven/lib/maven3/lib/jansi-native/linux64/*
#	opt/${PN}/plugins/webp/lib/libwebp/linux/*
# "

src_unpack() {

	default_src_unpack
	if [ ! -d "$S" ]; then
		einfo "Renaming source directory to predictable name..."
		mv $(ls "${WORKDIR}") "idea-IC-${PV}" || die
	fi
}

src_prepare() {

	default_src_prepare

	rm -vf "${S}"/plugins/maven/lib/maven3/lib/jansi-native/*/libjansi*

#	?????????? what was/is the problem ??????????
#	rm LLDBFrontEnd after licensing questions with Gentoo License Team
#	rm -vf "${S}"/plugins/Kotlin/bin/linux/LLDBFrontend

#	?????????? why these ??????????
#	rm -vrf "${S}"/lib/pty4j-native/linux/ppc64le
#	rm -vf "${S}"/lib/pty4j-native/linux/mips64el/libpty.so
#	rm -vf "${S}"/plugins/cwm-plugin/quiche-native/linux-aarch64/libquiche.so

	sed -i \
		-e "\$a\\\\" \
		-e "\$a#-----------------------------------------------------------------------" \
		-e "\$a# Disable automatic updates as these are handled through Gentoo's" \
		-e "\$a# package manager. See bug #704494" \
		-e "\$a#-----------------------------------------------------------------------" \
		-e "\$aide.no.platform.update=Gentoo"  bin/idea.properties

	eapply_user
}

src_install() {
	local dir="/opt/${PN}"
	local dst="${D}${dir}"

	insinto "${dir}"
	doins -r *

	fperms 755 "${dir}"/bin/{format.sh,idea.sh,inspect.sh,ltedit.sh,restart.py,fsnotifier,repair}
	fperms -R 755 "${dir}"/jbr/bin
	fperms 755 "${dir}"/jbr/lib/{chrome-sandbox,jcef_helper,jexec,jspawnhelper}
	fperms -R 755 "${dir}"/plugins/Kotlin/kotlinc/bin
	fperms -R 755 "${dir}"/plugins/maven/lib/maven3/bin
	fperms 755 "${dir}"/plugins/terminal/jediterm-bash.in

	# bundled script is always lowercase, and doesn't have -ultimate, -professional suffix.
	local bundled_script_name="${PN%-*}.sh"
	make_wrapper "${PN}" "${dir}/bin/$bundled_script_name" || die

	local pngfile="$(find ${dst}/bin -maxdepth 1 -iname '*.png')"
	newicon $pngfile "${PN}.png" || die "we died"

	make_desktop_entry "${PN}" "IntelliJ Idea Community Edition" "${PN}" "Development;IDE;"

	newenvd - 99idea-community <<-EOF
		# Configuration file idea-community
		IDEA_JDK="${dir}/jbr"
	EOF

	# recommended by: https://confluence.jetbrains.com/display/IDEADEV/Inotify+Watches+Limit
	mkdir -p "${D}/etc/sysctl.d/" || die
	echo "fs.inotify.max_user_watches = 524288" > "${D}/etc/sysctl.d/30-idea-inotify-watches.conf" || die
}
