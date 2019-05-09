#!/bin/bash

# Patch to log to stdout in a container
# See https://redmine.lighttpd.net/boards/2/topics/8382
exec 3>&1

set +x
/usr/sbin/lighttpd -D -f /etc/lighttpd/lighttpd.conf
