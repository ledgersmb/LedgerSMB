# RPM spec written for and tested on CentOS 4 and CentOS 5 
Summary: LedgerSMB - Open Source accounting software
Name: ledgersmb
Version: 1.5.0-dev
Release: 1
License: GPL
URL: http://www.ledgersmb.org/
Group: Applications/Productivity
Source0: %{name}-%{version}.tar.gz
BuildRoot: %{_tmppath}/%{name}-%{version}-root
BuildArch: noarch
Requires: perl >= 5.8, httpd, postgresql >= 8.1, tetex-latex
Requires: perl-DBD-Pg >= 2.0 , perl-DBI >= 1.48
Requires: perl-version, perl-Smart-Comments
Requires: perl-HTML-Parser, perl-Template-Toolkit, 
Requires: perl-Error, perl-CGI-Simple
Requires: perl-File-MimeInfo, perl-IO-stringy
Requires: perl-MIME-Lite, perl-Class-Std >= 0.0.8
Requires: perl-Locale-Maketext-Lexicon >= 0.62
Requires: perl-IO-String 
Requires: perl-Math-BigInt-GMP
Requires: perl-Log-Log4perl perl-DateTime perl-DateTime-Format-Strptime
Requires: perl-Config-IniFiles perl-Moose perl-Number-Format
Requires: dojo
BuildRequires: perl
# avoid bogus autodetection of perl modules:
AutoReqProv: no


%description
LedgerSMB is a double-entry accounting system written in perl.
LedgerSMB is a fork of sql-ledger offering better security and data integrity,
and many advanced features.

This package does not work in SELinux restricted mode.  However audit2allow can
be used to ensure that it will work.  Start with permissive mode, and then once
issues are corrected, you can turn the mode back to restricted.

To finalize the ledgersmb installation:

Enable local password autentication in PosgreSQL, leaving ident login for the
postgres user:
- Start PostgreSQL to create database instance (service postgres start)
- Let /var/lib/pgsql/data/pg_hba.conf start with:
local   all         postgres                          ident sameuser
local   all         all                               md5
host    all         all         127.0.0.1/32          md5
- Restart PostgreSQL to apply changes (service postgresql restart)

- log in via psql, ALTER USER postgres WITH PASSWORD 'yada';

- reload your Apache config (service httpd reload)

Visit http://localhost/ledgersmb/setup.pl with username postgres and password 
'yada' and create an application database.  This will also walk you through 
creating an initial admin user.

Also note, this does NOT provide the LaTeX template extensions which are 
technically optional but frequently used.  To use these you will need to install
texlive packages from yum and Template::Latex from cpan.

%prep
%setup -q -n ledgersmb

chmod 0644 $(find . -type f)
chmod 0755 $(find . -type d)
chmod +x *.pl
chmod -x custom.pl # FIXME: Config???
chmod +x utils/*/*.pl utils/devel/find-use utils/pos/pos-hardware-client-startup-script


%build

cat << TAK > rpm-ledgersmb-httpd.conf
Alias /ledgersmb/doc/LedgerSMB-manual.pdf %{_docdir}/%{name}-%{version}/LedgerSMB-manual.pdf
<Files %{_docdir}/%{name}-%{version}/LedgerSMB-manual.pdf>
</Files>

TAK

cat << 'HTTPDCONF' > fix-ledgersmb-httpd-conf-template.pl
LINE: while (defined($_ = <ARGV>)) {
    s[/ledgersmb WORKING_DIR/][/ledgersmb %{_datadir}/%{name}/]g;
    s[Directory WORKING_DIR>][Directory %{_datadir}/%{name}>]g;
    s[Directory WORKING_DIR/users>][Directory %{_datadir}/%{name}/users>]g;
    s[Directory WORKING_DIR/bin>][Directory %{_datadir}/%{name}/bin>]g;
    s[Directory WORKING_DIR/utils>][Directory %{_datadir}/%{name}/utils>]g;
    s[Directory WORKING_DIR/spool>][Directory %{_localstatedir}/spool/%{name}>]g;
    s[Directory WORKING_DIR/templates>][Directory %{_localstatedir}/lib/%{name}/templates>]g;
    s[Directory WORKING_DIR/LedgerSMB>][Directory %{_localstatedir}/lib/%{name}/LedgerSMB>]g;
}
continue {
    print $_;
}

HTTPDCONF

perl fix-ledgersmb-httpd-conf-template.pl ledgersmb-httpd.conf.template >> rpm-ledgersmb-httpd.conf


%install

rm -rf $RPM_BUILD_ROOT
mkdir -p -m0755 $RPM_BUILD_ROOT%{_datadir}/%{name} # /usr/lib/ledgersmb - readonly code and cgi directory
mkdir -p -m0750 $RPM_BUILD_ROOT%{_sysconfdir}/%{name} # /etc/ledgersmb - configs
mkdir -p -m0750 $RPM_BUILD_ROOT%{_localstatedir}/lib/%{name} # /var/lib/ledgersmb - data files, modified by cgi
mkdir -p -m0750 $RPM_BUILD_ROOT%{_localstatedir}/spool/%{name} # /var/spool/ledgersmb - spool files, modified by cgi

cp -rp . $RPM_BUILD_ROOT%{_datadir}/%{name}/
rm -rf  $RPM_BUILD_ROOT%{_datadir}/%{name}/css $RPM_BUILD_ROOT%{_datadir}/%{name}/ledgersmb.conf  $RPM_BUILD_ROOT%{_datadir}/%{name}/spool  $RPM_BUILD_ROOT%{_datadir}/%{name}/templates

# the conf, placed in etc, symlinked back in place
mv ledgersmb.conf.default $RPM_BUILD_ROOT%{_sysconfdir}/ledgersmb/ledgersmb.conf
ln -s ../../..%{_sysconfdir}/ledgersmb/ledgersmb.conf \
  $RPM_BUILD_ROOT%{_datadir}/%{name}/ledgersmb.conf

# install relevant parts in data/cgi directory
rm -rf $RPM_BUILD_ROOT%{_datadir}/%{name}/locale/legacy

# css - written to by cgi
mkdir -p -m0750 $RPM_BUILD_ROOT%{_localstatedir}/lib/%{name}/css
ln -s ../../..%{_localstatedir}/lib/%{name}/css \
  $RPM_BUILD_ROOT%{_datadir}/%{name}/css
cp -rp css/* \
  $RPM_BUILD_ROOT%{_datadir}/%{name}/css

# templates - written to by cgi
mkdir -p -m0750 $RPM_BUILD_ROOT%{_localstatedir}/lib/%{name}/templates
ln -s ../../..%{_localstatedir}/lib/%{name}/templates \
  $RPM_BUILD_ROOT%{_datadir}/%{name}/templates
cp -rp templates/* \
  $RPM_BUILD_ROOT%{_datadir}/%{name}/templates

# spool - written to by cgi
mkdir -p $RPM_BUILD_ROOT%{_localstatedir}/spool/%{name}
ln -s ../../..%{_localstatedir}/spool/%{name} \
  $RPM_BUILD_ROOT%{_datadir}/%{name}/spool

# apache config file
mkdir -p $RPM_BUILD_ROOT%{_sysconfdir}/httpd/conf.d
install -m 644 rpm-ledgersmb-httpd.conf \
  $RPM_BUILD_ROOT%{_sysconfdir}/httpd/conf.d/ledgersmb.conf

ln -s /usr/share/dojo $RPM_BUILD_ROOT%{_datadir}/%{name}/UI/lib/dojo

%clean
rm -rf $RPM_BUILD_ROOT


%files
%defattr(-,root,root)

%{_datadir}/%{name}

%attr(-, apache, apache) %config(noreplace) %{_localstatedir}/lib/%{name}
%attr(-, apache, apache) %dir %{_localstatedir}/spool/%{name}

%attr(0750, root, apache) %dir %{_sysconfdir}/%{name}
%attr(0640, root, apache) %config(noreplace) %{_sysconfdir}/%{name}/*

%config(noreplace) %{_sysconfdir}/httpd/conf.d/*.conf

%doc doc/{COPYRIGHT,faq.html,LedgerSMB-manual.pdf,release_notes}
%doc Changelog CONTRIBUTORS INSTALL LICENSE README.translations UPGRADE


%changelog
# ToDo: SELinux, pos.conf.pl.template, reload of httpd config

* Fri Dec 08 2012 Håvard Sørli <havard@anix.no> - 1.3.25
- fix missing ledgersmb-httpd.conf.template 
- add fix-ledgersmb-httpd-conf-template.pl

* Mon Dec 31 2007 Christopher Murtagh <cmurtagh@ledgersmb.org> - 1.2.11
- updating to 1.2.11
- removing users directory

* Wed Jun 13 2007 David Fetter <david@fetter.org> 1.25-2
- Updated to 1.25
- Use perl-* RPM packages rather than bundling them

* Fri Nov 10 2006 Mads Kiilerich <mads@kiilerich.com> - 1.2-alpha
- Updating towards 1.2

* Wed Oct 18 2006 Mads Kiilerich <mads@kiilerich.com> - 1.1.1d-1
- Initial version
