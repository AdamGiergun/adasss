# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop wrapper

RESTRICT="bindist mirror strip splitdebug"

QA_PREBUILT="
	opt/${PN}/bin/*
	opt/${PN}/jbr/bin/*
	opt/${PN}/jbr/lib/*
	opt/${PN}/jre/lib/server/*
	opt/${PN}/jre/lib/swiftshader/*
	opt/${PN}/lib/pty4j-native/linux/x86/*
	opt/${PN}/lib/pty4j-native/linux/x86-64/*
	opt/${PN}/plugins/android/resources/native/linux/*
	opt/${PN}/plugins/cwm-plugin/quiche-native/linux-x86-64/*
	opt/${PN}/plugins/maven/lib/maven3/lib/jansi-native/linux32/*
	opt/${PN}/plugins/maven/lib/maven3/lib/jansi-native/linux64/*
	opt/${PN}/plugins/webp/lib/libwebp/linux/*
"

SLOT="0"

MY_PV="$(ver_cut 1-3)"
MY_PB="$(ver_cut 4-6)"
MY_PN="idea"

SRC_URI="https://download-cdn.jetbrains.com/idea/${MY_PN}IC-${MY_PV}.tar.gz"

DESCRIPTION="A complete toolset for web, mobile and enterprise development"

HOMEPAGE="https://www.jetbrains.com/idea/"

LICENSE="Apache-2.0 BSD BSD-2 CC0-1.0 CC-BY-2.5 CDDL-1.1
	codehaus-classworlds CPL-1.0 EPL-1.0 EPL-2.0
	GPL-2 GPL-2-with-classpath-exception ISC
	JDOM LGPL-2.1 LGPL-2.1+ LGPL-3-with-linking-exception MIT
	MPL-1.0 MPL-1.1 OFL ZLIB"

KEYWORDS="~amd64 ~x86"

RDEPEND="${DEPEND}
	sys-libs/glibc
	media-libs/harfbuzz
	dev-java/jansi-native
	dev-libs/libdbusmenu"

BDEPEND="dev-util/patchelf"

S="${WORKDIR}/${MY_PN}-IC-${MY_PB}"

src_unpack() {
	default_src_unpack
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

	eapply_user
}

src_install() {
	local dir="/opt/${PN}"

	insinto "${dir}"
	doins -r *

	fperms 755 "${dir}"/bin/{format.sh,idea.sh,inspect.sh,ltedit.sh,restart.py,fsnotifier,repair}
	fperms -R 755 "${dir}"/jbr/bin
	fperms 755 "${dir}"/jbr/lib/{chrome-sandbox,jcef_helper,jexec,jspawnhelper}
	fperms -R 755 "${dir}"/plugins/Kotlin/bin/linux
	fperms -R 755 "${dir}"/plugins/Kotlin/kotlinc/bin
	fperms -R 755 "${dir}"/plugins/Kotlin/scripts
	fperms -R 755 "${dir}"/plugins/maven/lib/maven3/bin
	fperms 755 "${dir}"/plugins/terminal/jediterm-bash.in
	fperms -R 755 "${dir}"/plugins/wsl-fs-helper/bin

	make_wrapper "${PN}" "${dir}/bin/${MY_PN}.sh"
	newicon "bin/${MY_PN}.png" "${PN}.png"
	make_desktop_entry "${PN}" "IntelliJ Idea Community" "${PN}" "Development;IDE;"

	# recommended by: https://confluence.jetbrains.com/display/IDEADEV/Inotify+Watches+Limit
	mkdir -p "${D}/etc/sysctl.d/" || die
	echo "fs.inotify.max_user_watches = 524288" > "${D}/etc/sysctl.d/30-idea-inotify-watches.conf" || die
}
