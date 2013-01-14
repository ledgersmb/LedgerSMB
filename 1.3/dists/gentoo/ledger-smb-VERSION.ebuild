# Copyright 1999-2006 The LedgerSMB Team
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit depend.apache webapp eutils

DESCRIPTION="LedgerSMB"
HOMEPAGE="http://ledger-smb.sourceforge.net/"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.gz"
#SRC_URI="http://eva.a.jjayr.com/lsmb-package/${P}.tar.gz"

# don't use the gentoo mirrors yet, we're not there.
RESTRICT='mirror'

LICENSE="GPL-2"
KEYWORDS="x86 ppc"

# no use flag for now
IUSE=""

DEPEND=""
RDEPEND="
	>=dev-db/postgresql-8
	>=dev-lang/perl-5.8
	dev-perl/DBI
	net-www/apache
"
S=${WORKDIR}/${PN}

src_unpack() {
	unpack ${A}
}

src_install() {
	webapp_src_preinst

	webapp_server_configfile apache ${S}/dists/gentoo/ledger-smb-httpd-gentoo.conf

	cp -R ${S}/* ${D}/${MY_HTDOCSDIR}

	# LedgerSMB needs to write to the users directory
	webapp_serverowned -R ${MY_HTDOCSDIR}/users/
	webapp_serverowned -R ${MY_HTDOCSDIR}/spool/
	webapp_postinst_txt en ${S}/dists/gentoo/post-install.txt

	webapp_src_install
}
