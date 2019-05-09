#!/bin/bash


pgdata=${PGDATA:-/var/lib/postgresql/data}

sed -i -e '
s/^#fsync = on/fsync = off/;
s/^#synchronous_commit = on/synchronous_commit = off/;
' $pgdata/postgresql.conf
