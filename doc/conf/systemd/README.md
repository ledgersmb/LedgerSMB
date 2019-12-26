# Config files for systemd to start LedgerSMB on boot
You should not modify any files directly in this dir.
Rather you should copy the ones you need into their correct locations and edit the copies to match your installation

- README.md
This file of course ;-)

## Config Files
ONLY one of these should be copied into the appropriate system config dir and modified as explained within the file.
on debian systems it would be `/etc/systemd/system/`
- ledgersmb_starman.service
The recommended way to run the LedgerSMB service
Starman preforks and preloads a number of workers and all code. This is know to be a performance gain over other ways of running perl web applications
- ledgersmb-development_plackup.service
A development profile that runs LedgerSMB directly under plackup instead of starman, it WILL be slower, as it neither preloads, nor preforks.
It also monitors most files for changes allowing development without constant reloading of the service.
If the appropriate dependencies are installed, it will also enable a debugger pane that can be accessed from your browser.
- ledgersmb_plackup.service
A legacy file that can be expected to be removed. __DON"T USE IT__
- ledgersmb_plack-fcgi.service
This file runs LedgerSMB under plack as an FCGI process, it's not tested as well as running under starman, and is believed to not perform as well either.


##NOTE:
LedgerSMB should be run under starman or another plack runner, BUT it should not be directly exposed to a network this way.
Instead it should be served behind a Reverse Proxy.
There are many httpd's that can act as a reverse proxy, including, but not limited to
- nginx
- apache
- varnish

