# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit depend.apache webapp eutils

DESCRIPTION="LedgerSMB is an Open source web-based accounting application for Small and Medium buisnesses."
HOMEPAGE="http://www.ledgersmb.org/"
#SRC_URI="mirror://sourceforge/${PN}/${P}.tar.gz"
#SRC_URI="http://downloads.sourceforge.net/ledger-smb/${P}.tar.gz"
SRC_URI="http://downloads.sourceforge.net/ledger-smb/ledger-smb-1.2.0rc4.tar.gz"

# don't use the gentoo mirrors yet, we're not there.
RESTRICT='mirror'

LICENSE="GPL-2"
KEYWORDS="~x86 ~ppc "

# no use flag for now
IUSE=""

DEPEND=""
RDEPEND="
	>=dev-db/postgresql-8
	>=dev-lang/perl-5.8
	dev-perl/DBI
	net-www/apache
	>=virtual/perl-locale-maketext-1.10
	>=dev-perl/locale-maketext-lexicon-0.62
	>=dev-perl/DBD-Pg-1.49
	dev-perl/MIME-Lite
	dev-perl/Parse-RecDescent
	dev-perl/HTML-Parser
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
