# Config files for systemd to start LedgerSMB on boot
You should not modify any files directly in this dir.
Rather you should copy the ones you need into their correct locations and edit the copies to match your installation

- README.md
This file of course ;-)

## Config Files
ONLY one of these should be copied into the appropriate system config dir and modified as explained within the file.
on debian systems it would be `/etc/systemd/system/`
- starman-ledgersmb.service
The recommended way to run the LedgerSMB service
Starman preforks and preloads a number of workers and all code. This is know to be a performance gain over other ways of running perl web applications
- plack-fcgi-ledgersmb.service
This file runs LedgerSMB under plack as an FCGI process, it's not tested as well as running under starman, and is believed to not perform as well either.


##NOTE:
LedgerSMB should be run under starman or another plack runner, BUT it should not be directly exposed to a network this way.
Instead it should be served behind a Reverse Proxy.
There are many httpd's that can act as a reverse proxy, including, but not limited to
- nginx
- apache
- varnish

