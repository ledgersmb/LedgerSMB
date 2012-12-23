#!/bin/sh

# Copyright (c) 2012, The LedgerSMB Core Team
# All rights reserved. 
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met: 
#
# Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer. 
#
# Redistributions in binary form must reproduce the above copyright notice, this
# list of conditions and the following disclaimer in the documentation and/or
# other materials provided with the distribution. 
#
# THIS SOFTWARE IS PROVIDED BY THE LEDGERSMB CORE TEAM AND CONTRIBUTORS "AS
# IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL LEDGERSMB CORE TEAM OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
# This is the configure_apache.sh which serves as a command line tool
# for creating Apache configuration for varios distributions. 
#

# Default variable values section
IFS=" "
CWD=$(dirname "$(readlink -fn "$0")")
script_name=`basename $0`
apacheuserlist="nobody apache www-data httpd _www www _apache2"
apacheconfpathlist="$CWD \
/etc/httpd/conf.d \
/etc/httpd \
/etc/apache2 \
/etc/apache2/conf.d \
/etc/conf.d/apache2 \
/usr/local/etc/httpd/conf.d \
/usr/local/etc/apache2/conf.d/ \
/usr/local/etc/apache22 \
/usr/local/apache2/conf/extra" 

echo "---------------------------------------------------------------"
echo "Default installation layouts for Apache HTTPD on various"
echo "operating systems and distributions."
echo "http://wiki.apache.org/httpd/DistrosDefaultLayout" 
echo "---------------------------------------------------------------"

if [ -f $CWD/ledgersmb-httpd.conf ]; then
  echo "$CWD/ledgersmb-httpd.conf exists"
  echo "Exit $script_name"
  exit 0
else
  sed -e "s|WORKING_DIR|$CWD|" $CWD/ledgersmb-httpd.conf.template > $CWD/ledgersmb-httpd.conf
fi


echo "Searching for apache user ..." 

for i in $apacheuserlist; do
   if id $i ; then
      echo "User $i available on this system"
      apacheuser=$i
   fi
done

username="apache"
username=${apacheuser:-$username}
read -p "Which user does your web server run as? [$username] " REPLY 

echo "chown ${REPLY:-$username} spool templates css"
chown -v ${REPLY:-$username} $CWD/spool $CWD/templates $CWD/css

echo "Searching for possible apache config location ...." 

for p in $apacheconfpathlist; do
   if [ ! -e "$p" ] ; then
      echo 1>&2 "'$p' does not exist or is not accessible by you"
   else
      # the pathname exists and is accessible; test readability:
      if [ ! -r "$p" ] ; then
         echo 1>&2 "'$p' is not readable by you"
      else 
       echo $p
       apacheconfpath="$p"
      fi
   fi
done

echo $apachconfpath

location="/etc/httpd/conf.d"
location=${apacheconfpath:-$location}
read -p "Where do we copy the ledgersmb-httpd.conf file to? [$location] " REPLY
apacheconf=${REPLY:-$location}/ledgersmb-httpd.conf

if [ ! -e "$apacheconf" ] ; then
   echo 1>&2 "copy to: '$apacheconf'"
   cp ledgersmb-httpd.conf $apacheconf
   newconfig=true
else
   # the pathname exists and is accessible; test readability:
   if [ ! -r "$apacheconf" ] ; then
      echo 1>&2 "'$apacheconf' is not readable by you"
   else
      echo "[$apacheconf] already exists"
      yesno="N"
      read -p "Okay to overwrite? (Y/N) [$yesno] " REPLY
      if [ "$REPLY" != "y" ] && [ "$REPLY" != "Y" ] ; then
        echo "Exit $script_name"
        exit 0
      else
        echo  "cp ledgersmb-httpd.conf $apacheconf"
        newconfig=true
     fi
   fi
fi

if newconfig=true ; then 
   echo "---------------------------------------------------------------"
   echo "If your distribution do not load extra config files from conf.d"
   echo "you have to add the following line to your httpd.conf\n"
   echo "Include $apacheconf \n"
   echo "Please restart your web server for the changes to take effect."
   echo " \n"
   echo "Default config only allow connetion from http://localhost / http://127.0.0.1 \n"
fi

exit 0
