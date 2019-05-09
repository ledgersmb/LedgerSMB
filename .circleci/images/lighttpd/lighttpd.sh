#!/bin/bash

set | grep -i DOJO
lighttpd -D -f /etc/lighttpd/lighttpd.conf
