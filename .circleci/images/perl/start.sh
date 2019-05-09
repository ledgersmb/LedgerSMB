#!/bin/bash -x

update_ssmtp.sh

if [[ ! -f ledgersmb.conf ]]; then
  cp doc/conf/ledgersmb.conf.default ledgersmb.conf
  sed -i \
    -e "s/\(cache_templates = \).*\$/cache_templates = 1/g" \
    -e "s/\(host = \).*\$/\1$POSTGRES_HOST/g" \
    -e "s/\(port = \).*\$/\1$POSTGRES_PORT/g" \
    -e "s/\(default_db = \).*\$/\1$DEFAULT_DB/g" \
    -e "s%\(sendmail   = \).*%#\1/usr/sbin/ssmtp%g" \
    -e "s/# \(smtphost = \).*\$/\1mailhog:1025/g" \
    -e "s/# \(backup_email_from = \).*\$/\1lsmb-backups@example.com/g" \
    ledgersmb.conf
fi
