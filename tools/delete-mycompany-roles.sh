#!/bin/sh
RC=0;
MY_COMPANY=$1;
[ -n "$MY_COMPANY" ] || { echo "parm 1 MY_COMPANY missing!";exit 1;}
LIKE_ARG="'lsmb_$MY_COMPANY%'";
CMD="select '\"'||rolname||'\"'||'@' FROM pg_roles WHERE rolname LIKE $LIKE_ARG;";
echo "MY_COMPANY=$MY_COMPANY LIKE_ARG=$LIKE_ARG CMD=$CMD";
company_roles=`sudo -u postgres psql -q -t -c "$CMD"`;
#echo "company_roles=$company_roles";
OLDIFS=$IFS
IFS=@
for role in $company_roles
do
  #echo "role=$role"
  role1=$(echo $role|tr '\n' ' ')
  #echo "role1=$role1"
  cmd_drop="drop user $role1;"
  #echo "cmd_drop=$cmd_drop"
  #echo $cmd | psql template1
  RC=`sudo -u postgres psql -q -t -c "$cmd_drop"`
  echo "cmd_drop=$cmd_drop RC=$RC \$?=$?";
done
