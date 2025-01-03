# The files in this directory are sample configuration files

You should not modify any files directly in this directory.
Rather you should copy the ones you need into their correct locations and edit
the copies to match your installation

## Directories

* systemd
  Sample systemd service files to run ledgersmb on boot

* sysvinit
  Sample sysvinit service files to run ledgersmb on boot

* webserver
  Httpd & cache daemon configuration file examples

## Httpd & cache daemon configuration files

We don't directly serve LedgerSMB via the HTTP Daemon, rather we use the daemon
to reverse proxy to a plackup or starman instance.
This is done for security, flexibility and web acceleration.
ONLY one of these should be copied into the appropriate system configuration
directory and modified as explained within the file.
On debian systems it would be a sub-directory of `/etc/nginx/` or `/etc/apache/`

* `apache-vhost.conf`
Sample `apache` configuration file
* `lighttpd-vhost.conf`
Sample `lighttpd` configuration file
* `nginx-vhost.conf`
Sample `nginx` configuration file
* `default.vcl`
Sample `Varnish` configuration file

## LedgerSMB configuration files

The file `ledgersmb.yaml` should be copied into the ledgersmb install directory
unless the location is overridden with an environment variable.

## Other Files

* `README.md`
This readme file of course ;-)

