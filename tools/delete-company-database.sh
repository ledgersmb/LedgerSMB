#!/bin/sh

cmd="select rolname FROM pg_roles WHERE rolname LIKE 'lsmb_${1}__%';"
company_roles=`su -c "psql -U postgres -t -c \"$cmd\"" postgres`

su -c "dropdb -U postgres $1" postgres

for role in $company_roles
do
  su -c "dropuser -U postgres \"$role\"" postgres
done

if test -n "$2"
then
  su -c "dropuser -U postgres \"$2\"" postgres
fi
