#!/bin/bash
#
# chart-load-test.sh [SQLDIR] [CHARTFILE]
#
# Attempts to load the charts and associated GIFI sets.  Expected output is
# discarded.  Normally run from the top-level LSMB directory to check charts in
# the directory 'sql', a chart directory or file can be given.  When passed a
# directory name, it checks all charts in that directory provided that a copy
# of Pg-database.sql is present.
#
# This test script requires that plpgsql have been loaded to template1 and that
# the running user has the ability to create and drop databases.  Additionally,
# this copy of chart-load-test.sh will not work with LedgerSMB < 1.3.
#
#######################################################################
# Copyright 2007, The LedgerSMB Core Team
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
#######################################################################

sqldir="${1:-sql}"
chart="$2"
db="charttest$$"

# Adjust before using
tsearch="/opt/pgsql813-ppc/share/contrib/tsearch2.sql"
tablefunc="/opt/pgsql813-ppc/share/contrib/tablefunc.sql"

if [ -f "$sqldir" ] ; then
	chart=`basename $sqldir`
	chartdir=`dirname $sqldir`
	sqldir="${chartdir/%\/*\/*\/*/}"
else
	chartdir="$sqldir"
fi
if [ ! -d "$sqldir" ] ; then
	echo "chart-load-test.sh: Directory '$sqldir' cannot be accessed" 1>&2
	exit 1
elif [ ! -f "${sqldir}/Pg-database.sql" ] ; then
	echo "chart-load-test.sh: Directory '$sqldir' does not contain Pg-database.sql" 1>&2
elif [ "$chart" -a ! -f "${chartdir}/$chart" ] ; then
	echo "chart-load-test.sh: Chart '$chart' cannot be accessed" 1>&2
	exit 1
fi

chartdir=${chartdir/#$sqldir/}
chartdir=${chartdir/#\//}
pushd $sqldir > /dev/null
( for i in `find "${chartdir:-.}" -name "${chart:-*.sql}" -path '*/chart/*' -print`; do
	createdb $db
	psql -f $tablefunc $db > /dev/null
	psql -f $tsearch $db > /dev/null
	psql -f Pg-database.sql $db > /dev/null
	sleep 3
	psql -f "$i" $db > /dev/null
	j="${i/chart/gifi}"
	if [ -x "$j" ] ; then
		psql -f "$j" $db > /dev/null
	fi
	sleep 3
	dropdb $db
done ) 2>&1 | grep -v 'NOTICE' | grep -v '^CREATE' |grep -v '^DROP'
popd > /dev/null
