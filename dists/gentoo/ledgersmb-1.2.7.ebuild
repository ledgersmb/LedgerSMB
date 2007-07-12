# Copyright 1999-2006 The LedgerSMB Team
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit depend.apache webapp eutils

DESCRIPTION="LedgerSMB"
HOMEPAGE="http://ledger-smb.sourceforge.net/"
SRC_URI="mirror://sourceforge/ledger-smb/${P}.tar.gz"
#SRC_URI="http://eva.a.jjayr.com/lsmb-package/${P}.tar.gz"

# don't use the gentoo mirrors yet, we're not there.
RESTRICT='mirror'

LICENSE="GPL-2"
KEYWORDS="x86 ppc"

# no use flag for now
IUSE=""

DEPEND=""
RDEPEND=">=dev-db/postgresql-8
	>=dev-lang/perl-5.8
	dev-perl/DBI
	net-www/apache
	>=dev-perl/Class-MethodMaker-2.08
	>=dev-perl/Log-Agent-0.307
	>=dev-perl/Shell-EnvImporter-1.04
	>=app-portage/g-cpan-0.15_rc3
	>=perl-core/i18n-langtags-0.35
	>=dev-perl/HTML-Tagset-3.10
	>=perl-gcpan/Class-Std-0.0.8
	>=perl-gcpan/Net-TCLink-3.4
	>=dev-perl/Parse-RecDescent-1.94
	>=dev-perl/MIME-Lite-3.01
	>=perl-gcpan/Config-Std-0.0.4
	>=perl-core/locale-maketext-1.10
	>=dev-perl/HTML-Parser-3.56
	>=virtual/perl-locale-maketext-1.10
	>=dev-perl/locale-maketext-lexicon-0.62"

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
