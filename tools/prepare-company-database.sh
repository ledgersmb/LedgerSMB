#!/bin/sh

set -x

# Script to explain the steps to take when installing LedgerSMB

# Default variable values section

owner=ledgersmb
pass=LEDGERSMBINITIAL
host=localhost
port=5432
srcdir=$PWD
dstdir=$PWD
coa=$srcdir/sql/coa/us/chart/General.sql
gifi=
pgsql_contrib_dir=ignore
ADMIN_FIRSTNAME='Default'
ADMIN_MIDDLENAME=NULL
ADMIN_LASTNAME='Admin'
ADMIN_USERNAME='admin'
ADMIN_PASSWORD='admin'


# Usage explanation section


usage () {
script_name=`basename $0`
cat <<USAGE
usage: $script_name [option1 .. optionN]

This script wants to be run as the root user. If you don't, you'll be
asked to enter the password of the 'postres' user

This script creates a 'ledgersmb' user on the specified PostgreSQL host,
if it does not exist.  Then it proceeds to load the LedgerSMB database
structure and content, loading Chart of Accounts data and GIFI data
as specified in the argument list.

After the database has been created, the script inserts a default user
'$ADMIN_USER' (password: '$ADMIN_PASSWORD'), with these initial values:

First name:  $ADMIN_FIRSTNAME  (NULL == none)
Middle name: $ADMIN_MIDDLENAME (NULL == none)
Last name:   $ADMIN_LASTNAME   (NULL == none)
Country:     'US'

This default user will be assigned all priviledges within the application.

Available options:
 --srcdir	The path where the sources for LedgerSMB are located
                [$srcdir]
 --dstdir	The path where the sources will be located when invoked
		from the webserver [$dstdir]
 --host		The PostgreSQL host to connect to (see 'man psql') [$host]
 --port		The PostgreSQL port to connect to (see 'man psql') [$port]
 --pgsql-contrib The directory where the tsearch2.sql, pg_trgm.sql and
                tablefunc.sql PostgeSQL are located [$pgslq_contrib_dir]
 --company	The name of the database to be created for the company [*]
 --owner	The name of the superuser which is to become owner of the
		company's database [$owner]
 --password	The password to be used to create the 'ledgersmb' user
		on the specified PostgreSQL server [$pass]
 --coa		The path locating the file to be
		used to load the Chart of Accounts data
 --gifi		The path locating the file to be
		used to load the GIFI data with the chart of accounts
 --progress     Echoes the commands executed by the script during setup
 --help		Shows this help screen

 * These arguments don't have a default, but are required
USAGE

}

# Extract options and setup variables
if ! options=$( getopt -u -l company:,coa:,gifi:,srcdir:,dstdir:,password:,host:,port:,help,progress,pgsql-contrib: '' "$@" )
then
  exit 1
fi

set -- $options
while test $# -gt 0 ;
do

  shift_args=2
  case "$1" in
    --)
        shift_args=1
        ;;
    --company)
	company_name=$2
#	break
	;;
    --coa)
        coa=$2
#	break
	;;
    --gifi)
	gifi=$2
#	break
	;;
    --srcdir)
	srcdir=$2
#	break
	;;
    --dstdir)
	dstdir=$2
#	break
	;;
    --password)
	pass=$2
#	break
	;;
    --host)
	host=$2
#	break
	;;
    --port)
	port=$2
#	break
	;;
    --pgsql-contrib)
        pgsql_contrib_dir=$2
#	break
	;;
    --progress)
        progress=yes
        shift_args=1
#	break
	;;
    --help)
	usage
	exit 0;;
  esac
  shift $shift_args
done

if test -z "$company_name"
then
  echo "missing or empty --company option"
  usage
  exit 1
fi

if test "$pgsql_contrib_dir" = "ignore"
then
  echo "missing argument --pgsql-contrib!"
  usage
  exit 1
fi

psql_args="-h $host -p $port -U $owner"
psql_cmd="psql $psql_args -d $company_name"


if test -n "$progress"
then
  # Use shell command-echoing to "report progress"
  set -x
fi

sed -e "s|WORKING_DIR|$dstdir|g" \
   $srcdir/ledgersmb-httpd.conf.template >$dstdir/ledgersmb-httpd.conf
cat <<EOF | su -c "psql -U postgres -d postgres "  postgres
CREATE ROLE $owner WITH SUPERUSER LOGIN NOINHERIT ENCRYPTED PASSWORD '$pass';
CREATE DATABASE $company_name WITH ENCODING = 'UNICODE' OWNER = $owner TEMPLATE = template0;
\\c $company_name
CREATE LANGUAGE plpgsql;
EOF

PGPASSWORD=$pass
export PGPASSWORD


#createdb $psql_args -O $owner -E UNICODE $company_name
#createlang $psql_args plpgsql $company_name


# Load the required PostgreSQL contribs, if a directory was specified
if ! test "x$pgsql_contrib_dir" = "xignored"
then
  for contrib in tsearch2.sql pg_trgm.sql tablefunc.sql
  do
    cat $pgsql_contrib_dir/$contrib | $psql_cmd
  done
fi

# Load the base file(s)
# -- Basic database structure
cat $srcdir/sql/Pg-database.sql | $psql_cmd
# -- Additional database structure
for module in `grep -v -E '^[[:space:]]*#' sql/modules/LOADORDER`
do
  cat $srcdir/sql/modules/$module | $psql_cmd
done
# -- Authorizations
sed -e "s/<?lsmb dbname ?>/$company_name/g" \
  $srcdir/sql/modules/Roles.sql | $psql_cmd


if test -n "$coa" ; then
  # Load a chart of accounts
  cat $coa | $psql_cmd
  if test -n "$gifi" ; then
    cat $gifi | $psql_cmd
  fi
fi

cat <<EOF | $psql_cmd
\\COPY language FROM stdin WITH DELIMITER '|'
`$srcdir/tools/generate-language-table-contents.pl $srcdir/locale/po`
EOF


cat <<CREATE_USER | $psql_cmd
SELECT admin__save_user(NULL,
                         person__save(NULL,
                                      3,
                                      '$ADMIN_FIRSTNAME',
                                      '$ADMIN_MIDDLENAME',
                                      '$ADMIN_LASTNAME',
                                      (SELECT id FROM country
                                       WHERE short_name = 'US')),
                         '$ADMIN_USERNAME',
                         '$ADMIN_PASSWORD');

SELECT admin__add_user_to_role('$ADMIN_USERNAME', rolname)
FROM pg_roles
WHERE rolname like 'lsmb_${company_name}_%';

CREATE_USER
