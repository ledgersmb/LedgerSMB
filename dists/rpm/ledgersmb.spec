Summary: LedgerSMB - Open Source accounting software
Name: ledger-smb
Version: 1.1.1d
Release: 1
License: GPL
URL: http://www.ledgersmb.org/
Group: Applications/Office
Source0: http://prdownloads.sourceforge.net/ledger-smb/%{name}-%{version}.tar.gz
BuildRoot: %{_tmppath}/%{name}-%{version}-root
BuildArch: noarch
Requires: perl >= 5.8, httpd, postgresql-server >= 8.1, perl-DBD-Pg, perl-DBI
BuildRequires: perl
AutoReqProv: no

%description
LedgerSMB is a double-entry accounting system written in perl.
LedgerSMB is a fork of sql-ledger offering better security and data integrity, 
and many advanced features.

SELinux should be disabled to use this RPM.

To finalize the installation:

Start PostgreSQL, let /var/lib/pgsql/data/pg_hba.conf start with
local   all         postgres                          ident sameuser
local   all         all                               md5
and restart PostgreSQL

Create databaseuser, create database and initialize it
su - postgres -c "createuser -d ledger-smb --no-createdb --no-createrole --no-superuser -P"
(remember the password!)
su - postgres -c "createdb ledger-smb"
su - postgres -c "createlang plpgsql ledger-smb"

Delete the "password" in %{_localstatedir}/lib/%{name}/users/members and
browse http://localhost/ledger-smb/admin.pl and set a ledger-smb master password.
In "Pg Database Administration" the "User" defaults to the database user "ledger-smb"
we just created - specify the password and "Create Dataset".
Set "Create Dataset" to the database "ledger-smb" we just created and continue.
In "Add User" specify the Dataset, User and password again for each user.

%prep
%setup -q -n ledger-smb

%build

# generate .conf from default with fixes
perl -p -e 's,^(\$ENV\{PATH\}),#\1,g' ledger-smb.conf.default > ledger-smb.conf

# fix location
perl -pi -e "s,/usr/local/ledger-smb,%{_datadir}/%{name},g" ledger-smb-httpd.conf

%install

# Most stuff is installed readonly in %{_datadir}/%{name}/
# Some parts are installed other places with other policies and symlinked in place

rm -rf $RPM_BUILD_ROOT
mkdir -p -m0755 $RPM_BUILD_ROOT%{_datadir}/%{name} # /usr/share/ledger-smb - primary and cgi directory
mkdir -p -m0755 $RPM_BUILD_ROOT%{_sysconfdir}/%{name} # /etc/ledger-smb - links to configs
mkdir -p -m0755 $RPM_BUILD_ROOT%{_localstatedir}/lib/%{name} # /var/lib/ledger-smb - data files, modified by cgi
mkdir -p -m0755 $RPM_BUILD_ROOT%{_localstatedir}/spool/%{name} # /var/spool/ledger-smb - spool files, modified by cgi

# rm setup.pl SL2LS.pl # FiXME - install somewhere else...

# the executable conf
mv ledger-smb.conf $RPM_BUILD_ROOT%{_localstatedir}/lib/%{name}/ledger-smb.conf

# link from /etc to our executable conf
ln -s ../..%{_localstatedir}/lib/%{name}/ledger-smb.conf \
 $RPM_BUILD_ROOT%{_sysconfdir}/ledger-smb/

# link from cgi stuff to our executable conf
ln -s ../../..%{_localstatedir}/lib/%{name}/ledger-smb.conf \
 $RPM_BUILD_ROOT%{_datadir}/%{name}/ledger-smb.conf

#FIXME
# menu.ini is pure configuration
mv menu.ini $RPM_BUILD_ROOT%{_sysconfdir}/ledger-smb/menu.ini
ln -s ../../..%{_sysconfdir}/ledger-smb/menu.ini \
  $RPM_BUILD_ROOT%{_datadir}/%{name}/menu.ini

# install forelevant parts in data / cgi directory
cp -rp *.pl favicon.ico index.html ledger-smb.gif ledger-smb.png ledger-smb_small.png menu.ini \
 bin LedgerSMB sql utils locale \
 $RPM_BUILD_ROOT%{_datadir}/%{name}/

# users - written by cgi
mkdir -p $RPM_BUILD_ROOT%{_localstatedir}/lib/%{name}/users
ln -s ../../..%{_localstatedir}/lib/%{name}/users \
  $RPM_BUILD_ROOT%{_datadir}/%{name}/users
cat << TAK > $RPM_BUILD_ROOT%{_localstatedir}/lib/%{name}/users/members
# LedgerSMB Accounting members
[root login]
password=
TAK

# css - written by cgi
mkdir -p $RPM_BUILD_ROOT%{_localstatedir}/lib/%{name}/css
ln -s ../../..%{_localstatedir}/lib/%{name}/css \
 $RPM_BUILD_ROOT%{_datadir}/%{name}/css
cp -rp css/* \
 $RPM_BUILD_ROOT%{_datadir}/%{name}/css

# templates - written by cgi
mkdir -p $RPM_BUILD_ROOT%{_localstatedir}/lib/%{name}/templates
ln -s ../../..%{_localstatedir}/lib/%{name}/templates \
 $RPM_BUILD_ROOT%{_datadir}/%{name}/templates
cp -rp templates/* \
 $RPM_BUILD_ROOT%{_datadir}/%{name}/templates

# spool - written by cgi
mkdir -p $RPM_BUILD_ROOT%{_localstatedir}/spool/%{name}
ln -s ../../..%{_localstatedir}/spool/%{name} \
 $RPM_BUILD_ROOT%{_datadir}/%{name}/spool

# install the apache config file
mkdir -p $RPM_BUILD_ROOT%{_sysconfdir}/httpd/conf.d
install -m 644 ledger-smb-httpd.conf \
 $RPM_BUILD_ROOT%{_sysconfdir}/httpd/conf.d/

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)

%{_datadir}/%{name}
%attr(0700, apache, apache) %config(noreplace) %{_localstatedir}/lib/%{name}
%attr(0700, apache, apache) %dir %{_localstatedir}/spool/%{name}

%attr(0640, root,   apache) %config(noreplace) %{_sysconfdir}/ledger-smb
%attr(0640, root,   apache) %config(noreplace) %{_sysconfdir}/httpd/conf.d/*.conf

%doc doc/*
%doc LICENSE README.sql-ledger TODO Changelog CONTRIBUTORS COPYRIGHT

%changelog
* Wed Oct 18 2006 Mads Kiilerich <mads@kiilerich.com> - 1.1.1d-1
- Initial version

