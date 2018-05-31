
DIST_VER=$(shell utils/install/build-id)
DIST_DIR=/tmp
ifeq ($(DIST_VER),travis)
DIST_DEPS=cached_dojo
else
DIST_DEPS=dojo
endif

.DEFAULT_GOAL := help

DEB_essential := cpanminus postgresql make gcc libdbd-pg-perl
DEB_essential += starman uglifyjs
DEB_perlmodules := libcgi-emulate-psgi-perl libcgi-simple-perl libconfig-inifiles-perl
DEB_perlmodules += libdbd-pg-perl libdbi-perl libdatetime-perl
DEB_perlmodules += libdatetime-format-strptime-perl libdigest-md5-perl
DEB_perlmodules += libfile-mimeinfo-perl libjson-xs-perl libjson-perl
DEB_perlmodules += liblocale-maketext-perl liblocale-maketext-lexicon-perl
DEB_perlmodules += liblog-log4perl-perl libmime-base64-perl libmime-lite-perl
DEB_perlmodules += libmath-bigint-gmp-perl libmoose-perl libnumber-format-perl
DEB_perlmodules += libpgobject-perl libpgobject-simple-perl libpgobject-simple-role-perl
DEB_perlmodules += libpgobject-util-dbmethod-perl libplack-perl libtemplate-perl
DEB_perlmodules += libnamespace-autoclean-perl libmoosex-nonmoose-perl
DEB_perlmodules += libxml-simple-perl
DEB_feature_PDF := libtemplate-plugin-latex-perl libtex-encode-perl
DEB_feature_PDF := texlive-latex-recommended
DEB_feature_PDF_utf8 := texlive-xetex
DEB_feature_OpenOffice := libopenoffice-oodoc-perl
DEB_feature_PGTAP := pgtap
DEB_feature_XLS :=

# Core packages provided by Fedora 24
RHEL_essential := perl-devel perl-CPAN perl-App-cpanminus
RHEL_essential += postgresql make gcc perl-DBD-Pg
RHEL_essential += perl-Starman
RHEL_essential += uglify-js
RHEL_perlmodules := perl-CGI-Emulate-PSGI perl-CGI-Simple perl-Config-IniFiles
RHEL_perlmodules += perl-DBD-Pg perl-DBI perl-DateTime perl-DateTime-Format-Strptime
RHEL_perlmodules += perl-Digest-MD5 perl-File-MimeInfo perl-JSON-XS
RHEL_perlmodules += perl-Locale-Maketext perl-Locale-Maketext-Lexicon
RHEL_perlmodules += perl-Log-Log4perl perl-MIME-Base64 perl-MIME-Lite perl-Math-BigInt-GMP
RHEL_perlmodules += perl-Moose perl-Number-Format perl-Plack perl-Template-Toolkit
RHEL_perlmodules += perl-namespace-autoclean perl-MooseX-NonMoose
RHEL_perlmodules += perl-XML-Simple
RHEL_perlmodules += perl-YAML perl-FCGI-ProcManager
RHEL_feature_PDF := perl-TeX-Encode texlive
RHEL_feature_PDF_utf8 :=
RHEL_feature_OpenOffice :=
RHEL_feature_XLS :=

FBSD_essential :=
FBSD_perlmodules :=
FBSD_feature_PDF :=
FBSD_feature_OpenOffice :=
FBSD_feature_XLS :=

APT_GET = sudo apt-get install
YUM = sudo yum install

# Lets try and work out what OS and DISTRO we are running on
# some usefull info here http://linuxmafia.com/faq/Admin/release-files.html
ifeq ($(OS),Windows_NT)
    OS := WIN32
    OSTYPE := WINDOWS
    $(error We currently don't support Windows via this makefile.)
else
    UNAME_S := $(shell uname -s)
    ifeq ($(UNAME_S),Linux)
        OS := LINUX
    endif
    ifeq ($(UNAME_S),FreeBSD)
        OS := FREEBSD
        OSTYPE := FREEBSD
    endif
    ifeq ($(UNAME_S),Darwin)
        OS := OSX
        OSTYPE := OSX
        OSDISTRO := DARWIN
    endif
    OSDISTRO := $(shell lsb_release -si | tr '[:lower:]' '[:upper:]')
    ifndef OSDISTRO
        UNAME_V := $(shell uname -v | tr '[:lower:]' '[:upper:]')
            ifneq (,$(findstring DEBIAN,$(UNAME_V)))
                OSDISTRO := DEBIAN
            endif
            ifneq (,$(findstring UBUNTU,$(UNAME_V)))
                OSDISTRO := UBUNTU
            endif
            ifneq (,$(findstring LINUXMINT,$(UNAME_V)))
                OSDISTRO := LINUXMINT
            endif
            ifneq (,$(findstring AMZN,$(UNAME_V)))
                OSDISTRO := AMAZONLINUX
            endif
        REDHAT_RELEASE_FILE := $(shell test -r /etc/redhat-release && cat /etc/redhat-release | tr '[:lower:]' '[:upper:]')
            ifneq (,$(findstring CENTOS,$(REDHAT_RELEASE_FILE)))
                OSDISTRO := CENTOS
            endif
            ifneq (,$(findstring FEDORA,$(REDHAT_RELEASE_FILE)))
                OSDISTRO := FEDORA
            endif
# the following are speculative, we need to confirm what is expected.
            ifneq (,$(findstring RHEL,$(REDHAT_RELEASE_FILE)))
                OSDISTRO := RHEL
            endif
            ifneq (,$(findstring REDHAT,$(REDHAT_RELEASE_FILE)))
                OSDISTRO := REDHAT
            endif
        SUSE_RELEASE_FILE := $(shell test -r /etc/suse-release && cat /etc/suse-release | tr '[:lower:]' '[:upper:]')
            ifneq (,$(findstring SUSE,$(SUSE_RELEASE_FILE)))
                OSDISTRO := SUSE
            endif
        MANDRAKE_RELEASE_FILE := $(shell test -r /etc/mandrake-release && cat /etc/mandrake-release | tr '[:lower:]' '[:upper:]')
            ifneq (,$(findstring MANDRAKE,$(MANDRAKE_RELEASE_FILE)))
                OSDISTRO := MANDRAKE
            endif
        OS_RELEASE_FILE := $(shell test -r /etc/os-release && cat /etc/os-release | tr '[:lower:]' '[:upper:]')
            ifneq (,$(findstring DEBIAN,$(OS_RELEASE_FILE)))
                OSDISTRO := DEBIAN
            endif
            ifneq (,$(findstring SUSE,$(OS_RELEASE_FILE)))
                OSDISTRO := SUSE
            endif
    endif
    ifneq (,$(filter DEBIAN UBUNTU LINUXMINT, $(OSDISTRO)))
        OSTYPE := DEBIAN
    endif
    ifneq (,$(filter SUSE, $(OSDISTRO)))
        OSTYPE := SUSE
    endif
    ifneq (,$(filter MANDRAKE, $(OSDISTRO)))
        OSTYPE := MANDRAKE
    endif
    ifneq (,$(filter GENTOO, $(OSDISTRO)))
        OSTYPE := GENTOO
    endif
# this filter is speculative, we need to confirm what is expected.
    ifneq (,$(filter REDHAT RHEL FEDORA CENTOS AMAZONLINUX, $(OSDISTRO)))
        OSTYPE := REDHAT
    endif
endif
    ifndef OSDISTRO
        $(warning We don't know what distro you are running so can't do anything special for it)
    endif
    ifndef OSTYPE
        $(warning We don't know what OSTYPE (eg: debian or redhat) you are running)
        $(warning Please report this on the mailing lists or IRC)
        $(warning http://ledgersmb.org/topics/support)
        $(warning OSTYPE   = $(OSTYPE))
        $(warning OSDISTRO = $(OSDISTRO))
        $(warning UNAME_V = $(UNAME_V))
        $(warning REDHAT_RELEASE_FILE = $(REDHAT_RELEASE_FILE))
        $(warning SUSE_RELEASE_FILE = $(SUSE_RELEASE_FILE))
        $(warning MANDRAKE_RELEASE_FILE = $(MANDRAKE_RELEASE_FILE))
        $(warning OS_RELEASE_FILE = $(OS_RELEASE_FILE))
        $(error exit)
    endif

ifeq ($(OSTYPE),DEBIAN)
OS_feature_PDF        := deb_feature_PDF
OS_feature_PDF_utf8   := deb_feature_PDF_utf8
OS_feature_OpenOffice := deb_feature_OpenOffice
OS_feature_XLS        := deb_feature_XLS
OS_feature_PGTAP      := deb_feature_PGTAP
endif
ifeq ($(OSTYPE),REDHAT)
OS_feature_PDF        := rhel_feature_PDF
OS_feature_PDF_utf8   := rhel_feature_PDF_utf8
OS_feature_OpenOffice := rhel_feature_OpenOffice
OS_feature_XLS        := rhel_feature_XLS
endif
ifeq ($(OSTYPE),FREEBSD)
OS_feature_PDF        := fbsd_feature_PDF
OS_feature_PDF_utf8   := fbsd_feature_PDF_utf8
OS_feature_OpenOffice := fbsd_feature_OpenOffice
OS_feature_XLS        := fbsd_feature_XLS
endif

# make help
#   Simple Help on installing LedgerSMB and use of this Makefile
#   This should always remain the first target
#   The first target is the default when make is run with no arguments
define HELP
Help on installing LedgerSMB can be found in
  - README.md
  - http://ledgersmb.org/topic/installing-ledgersmb-15

The easiest way to use this makefile to install LedgerSMB is simply to run
  make all_dependencies
  make feature_PDF_utf8 # this is optional and is a large additional download
                        # see discussion about XeLaTeX and UTF8 at
                        # http://ledgersmb.org

Help on using this Makefile
  The following make targets are available
    - help         : This help text
    - dojo         : Builds the minified dojo blob we serve to clients
    - cached_dojo  : Uses the cached minified dojo, or builds one
    - dojo_archive : Builds a cached minified dojo archive
    - blacklist    : Builds sql blacklist (required after adding functions)
    - submodules   : Initialises and updates our git submodules
    - test         : Runs tests
    - devtest      : Runs all tests including development/author tests
    - dist         : builds the release distribution archive
    - dependencies : Installs all dependencies including cpan ones. (except features)
                     Preferring system perl modules over cpan ones
                     It attempts to detect OS type if OSTYPE is not set
                     Valid OS types are
                        - debian
                        - redhat
                        - freebsd

    - debian  : installs all apt dependencies for a debian based system except deb_feature_*
    - redhat  : installs all apt dependencies for an rpm (redhat) based system except rhel_feature_*
    - freebsd : installs some known dependencies for a FreeBSD system

    - all_dependencies : same as dependencies but adds all features except feature_PDF_utf8

    - cpan                    : installs any remaining perl dependancies using cpanm

    - feature_PDF             : Install system and cpan packages for generating PDF/Postscript output
    - feature_PDF_utf8        : Install system and cpan packages for UTF8 ouput in PDF/Postscript output
    - feature_XLS             : Install system and cpan packages for generating XLS output
    - feature_OpenOffice      : Install system and cpan packages for generating OpenOffice output

    #############################################################
      The following targets would not normally be used manually
    #############################################################

    - all_debian  : same as debian but adds all features except deb_feature_PDF_utf8
    - all_redhat  : same as redhat but adds all features except rhel_feature_PDF_utf8
    - all_freebsd : same as freebsd but adds all features except fbsd_feature_PDF_utf8

    - deb_essential           : installs just the "can't do without these" dependencies
    - deb_perlmodules         : installs all known deb packaged perl modules we depend on
    - deb_feature_PDF         : installs deb packages for generating PDF/Postscript output
    - deb_feature_PDF_utf8    : Installs texlive-xetex to allow UTF8 ouput in PDF/Postscript output
    - deb_feature_OpenOffice  : Installs deb package for generating OpenOffice output
    - deb_feature_XLS         : Installs deb package for generating XLS output

    - rhel_essential          : installs just the "can't do without these" dependencies
    - rhel_perlmodules        : installs all known rpm packaged perl modules we depend on
    - rhel_feature_PDF        : installs rpm packages for generating PDF/Postscript output
    - rhel_feature_PDF_utf8   : Installs texlive-xetex (if available) to allow UTF8 ouput in PDF/Postscript output
    - rhel_feature_OpenOffice : Installs rpm package for generating OpenOffice output
    - rhel_feature_XLS        : Installs deb package for generating XLS output


endef
export HELP

help:
	@echo "$$HELP"
	$(warning OSTYPE   = $(OSTYPE))
	$(warning OSDISTRO = $(OSDISTRO))
	$(warning REDHAT_RELEASE_FILE = $(REDHAT_RELEASE_FILE))

# make dojo
#   builds dojo for production/release
SHELL := /bin/bash
HOMEDIR := ~/dojo_archive
SHA := $(shell find UI/js-src/lsmb UI/js-src/dojo UI/js-src/dijit -exec sha1sum {} + 2>&1 | sort | sha1sum | cut -d' ' -f 1)
ARCHIVE := $(HOMEDIR)/UI_js_$(SHA).tar
TEMP := $(HOMEDIR)/_UI_js_$(SHA).tar
FLAG := $(HOMEDIR)/building_UI_js_$(SHA)

dojo:
	rm -rf UI/js/;
	cd UI/js-src/lsmb/ \
		&& ../util/buildscripts/build.sh --profile lsmb.profile.js \
		| egrep -v 'warn\(224\).*A plugin dependency was encountered but there was no build-time plugin resolver. module: (dojo/request;|dojo/request/node;|dojo/request/registry;|dijit/Fieldset;|dijit/RadioMenuItem;|dijit/Tree;|dijit/form/_RadioButtonMixin;)';
	cd ../../..


dojo_archive: dojo
	#TODO: Protect for concurrent invocations
	mkdir -p $(HOMEDIR)
	touch $(FLAG)
	tar cf $(TEMP) UI/js
	mv $(TEMP) $(ARCHIVE)
	rm $(FLAG)

cached_dojo:
ifeq ($(wildcard $(ARCHIVE)),)
	$(MAKE) dojo_archive
endif
	tar xf $(ARCHIVE)


# make blacklist
blacklist:
	perl utils/test/makeblacklist.pl --regenerate

# make pod
#make submodules
#   Initialises and updates our git submodules
submodules:
	git submodule update --init --recursive

# make dist
#   builds release distribution archive
dist: $(DIST_DEPS)
	test -d $(DIST_DIR) || mkdir -p $(DIST_DIR)
	find . | grep -vE '^.$$|^\./\.|^\./UI/js-src/(dojo|dijit|util)/|\.(uncompressed|consoleStripped)\.js$$|.js.map$$' | tar czf $(DIST_DIR)/ledgersmb-$(DIST_VER).tar.gz --transform 's,^./,ledgersmb/,' --no-recursion --files-from -

clean:
	rm -rf inc META.yml MYMETA.yml MYMETA.json blib pm_to_blib

clean-libs:
	rm -rf $(shell utils/install/clean-libs)

# Genarate displayable documentation
pod:
	rm -rf UI/pod
	mkdir UI/pod
	utils/pod2projdocs.pl 2>&1 pod2projdocs.log

# make critic
# Little toy for code critique
# Make sure that aspell is installed for your locale (apt install aspell-fr, for example)
# Open UI/pod/critic_html/index.html with prefered browser
critic:
	test -d UI/pod || mkdir -p UI/pod
	./tools/critic_html/critichtml

# make dependencies
#   Installs all dependencies.
#   Preferring system perl modules over cpan ones
#   It attempts to detect OS type if OSTYPE is not set
#   Valid OS types are
#       - debian
#       - redhat
#       - freebsd
ifeq ($(OSTYPE),DEBIAN)
dependencies: debian
all_dependencies: all_debian
endif
ifeq ($(OSTYPE),REDHAT)
dependencies: redhat
all_dependencies: all_redhat
endif
ifeq ($(OSTYPE),FREEBSD)
dependencies: freebsd
all_dependencies: all_freebsd
endif
#OSDISTRO

#   make debian
#       installs all apt dependencies for a debian system
debian: deb_essential deb_perlmodules
#   make debian_all
#       installs all apt dependencies for a debian system Including all features except deb_feature_PDF_utf8
all_debian: debian deb_feature_PDF deb_feature_OpenOffice deb_feature_XLS
#   make deb_essential
#       installs just the "can't do without these" dependencies
deb_essential:
	$(APT_GET) $(DEB_essential)
#   make deb_perlmodules
#       installs all known deb packaged perl modules we depend on
deb_perlmodules:
	$(APT_GET) $(DEB_perlmodules)
#   make deb_feature_PDF
#       installs deb packages for generating PDF/Postscript output
deb_feature_PDF:
	$(APT_GET) $(DEB_feature_PDF)
#   make deb_feature_PDF_utf8
#       Installs texlive-xetex to allow UTF8 ouput in PDF/Postscript output
deb_feature_PDF_utf8: deb_feature_PDF
	$(APT_GET) $(DEB_feature_PDF_utf8)
#   make deb_feature_OpenOffice
#       Installs deb package for generating XLS output
deb_feature_XLS:
	$(APT_GET) $(DEB_feature_XLS)
#   make deb_feature_XLS
#       Installs deb package for generating OpenOffice output
deb_feature_OpenOffice:
	$(APT_GET) $(DEB_feature_OpenOffice)
#   make deb_feature_pgtab
#       Installs deb package for generating pgTap
deb_feature_PGTAP:
	$(APT_GET) $(DEB_feature_PGTAP)



#   make redhat
#       installs all apt dependencies for a RHEL, Fedora, CentOS system
redhat: rhel_essential rhel_perlmodules
#   make redhat_all
#       installs all apt dependencies for a RHEL, Fedora, CentOS system  Including all features except rhel_feature_PDF_utf8
all_redhat: redhat rhel_feature_PDF rhel_feature_OpenOffice
#   make rhel_essential
#       installs just the "can't do without these" dependencies
rhel_essential:
	$(YUM) $(RHEL_essential)
#   make rhel_perlmodules
#       installs all known rpm packaged perl modules we depend on
rhel_perlmodules:
	$(YUM) $(RHEL_perlmodules)
#   make rhel_feature_PDF
#       installs rpm packages for generating PDF/Postscript output
rhel_feature_PDF:
	$(YUM) $(RHEL_feature_PDF)
#   make rhel_feature_PDF_utf8
#       Installs texlive-xetex to allow UTF8 ouput in PDF/Postscript output
rhel_feature_PDF_utf8: rhel_feature_PDF
#	$(YUM) $(RHEL_feature_PDF_utf8)
#   make rhel_feature_XLS
#       Installs rpm package for generating XLS output
rhel_feature_XLS:
#	$(YUM) $(RHEL_feature_XLS)
#   make rhel_feature_OpenOffice
#       Installs rpm package for generating OpenOffice output
rhel_feature_OpenOffice:
#	$(YUM) $(RHEL_feature_OpenOffice)


#   make freebsd
#       installs some known dependencies for a FreeBSD system
freebsd:
	@echo "We currently don't do anything special on a freebsd system"
#   make freebsd_all
#       installs some known dependencies for a FreeBSD system
all_freebsd: freebsd
fbsd_feature_PDF:
fbsd_feature_PDF_utf8:
fbsd_feature_OpenOffice:
fbsd_feature_XLS:


#   make cpan
#       installs any remaining perl dependancies using cpanm
cpan:
ifeq (, $(shell which make))
	$(error "No make in $(PATH), please install make")
endif
ifeq (, $(shell which gcc))
	$(error "No gcc in $(PATH), please install gcc")
endif
	cpanm --quiet --notest --with-feature=starman --installdeps .


#   make feature_PDF
#       Install system and cpan packages for generating PDF/Postscript output
feature_PDF: $(OS_feature_PDF)
	cpanm --quiet --notest --with-feature=latex-pdf-ps --installdeps .

#   make feature_PDF_utf8
#       Install system and cpan packages for UTF8 ouput in PDF/Postscript output
feature_PDF_utf8: $(OS_feature_PDF_utf8) feature_PDF

#   make feature_OpenOffice
#       Install system and cpan packages for generating OpenOffice output
feature_OpenOffice: $(OS_feature_OpenOffice)
	cpanm --quiet --notest --with-feature=openoffice --installdeps .

#   make feature_XLS
#       Install system and cpan packages for generating XLS output
feature_XLS: $(OS_feature_XLS)
	cpanm --quiet --notest --with-feature=XLS --installdeps .


postgres_user:
	sudo createuser -S -d -r -l -P lsmb_dbadmin

test:
	prove -Ilib t/*.t

devtest:
	prove -Ilib t/*.t
	prove -Ilib xt/*.t

########
# todo list
########
# The next targets to add are likely
########
# - postgres_user
# - postgres_access
# - postgres_verify
# - postgres (depends on postgres_*)
#
# - starman (adds system user and systemd script)
#
# - letsencrypt
#
# - nginx
#
# - apache
# - httpd (defaults to nginx)
# Oh, and the first to add would be
# - configure (asks a couple of questions and generates ledgersmb.conf)

########
# I think the list of things to test would be something like....
########
# These tests should be run for each distro in a clean VM either on demand or as part of "release testing"
# - run DB tests
# - create an invoice
# - Run a test that verifies Dojo has loaded and is able to modify the DOM
# - generate PDF of invoice
# - generate XLS Doc of invoice
# - generate OpenOffice Doc of invoice
# - Use Mountebank to send an email of the invoice
