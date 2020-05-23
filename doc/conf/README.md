# The files in this directory are sample configuration files

You should not modify any files directly in this directory.
Rather you should copy the ones you need into their correct locations and edit
the copies to match your installation

## Directories

* systemd
This directory provides sample systemd service files to run ledgersmb on boot

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

One of these should be copied into the ledgersmb install directory unless the
location is overridden with an environment variable.

* `ledgersmb.conf.default`
a "normal" configuration, it uses the bundled built `Dojo` and is the preferred configuration
* `ledgersmb.conf.unbuilt-dojo`

If installing using a tarball or system package, this file should only be used.

If local changes to any of our `Dojo`, `Javascript`, or `HTML` resources are made.

However if running from a git or other source install, then you will either need
to run with unbuilt-dojo (`src`) or pull in our submodules and build our `Dojo` target.

__WARNING:__ Running with unbuilt `Dojo` will have a noticeable performance
reduction in most cases.

## Other Files

* `README.md`
This readme file of course ;-)

## Testing infrastructure files

These files are not for normal use,
they are intended for use on the `travis-ci` testing servers

* `ledgersmb.conf.travis-ci`
`ledgersmb.conf` file configured for running tests on `travis`
* `nginx-travis.conf`
httpd configuration file configured for running tests on `travis`
