#!/bin/bash
ConfiguredComment='# install script update_ssmtp.sh has configured ssmtp'
grep -qc "$ConfiguredComment" /etc/ssmtp.conf && {
    echo "smtp configured."
    exit
}

sed -i \
    -e "s/\(root=\).*\$/\1$SSMTP_ROOT/g" \
    -e "s/\(mailhub=\).*\$/\1$SSMTP_MAILHUB/g" \
    -e "s/\(hostname=\).*\$/\1$SSMTP_HOSTNAME/g" \
    /etc/ssmtp/ssmtp.conf
[ -z "$SSMTP_USE_STARTTLS" ] || echo "UseSTARTTLS=$SSMTP_USE_STARTTLS" >> /etc/ssmtp/ssmtp.conf
[ -z "$SSMTP_AUTH_USER" ] || echo "AuthUser=$SSMTP_AUTH_USER" >> /etc/ssmtp/ssmtp.conf
[ -z "$SSMTP_AUTH_PASS" ] || echo "AuthPass=$SSMTP_AUTH_PASS" >> /etc/ssmtp/ssmtp.conf
[ -z "$SSMTP_AUTH_METHOD" ] || echo "AuthMethod=$SSMTP_AUTH_METHOD" >> /etc/ssmtp/ssmtp.conf
[ -z "$SSMTP_FROMLINE_OVERRIDE" ] || echo "FromLineOverride=$SSMTP_FROMLINE_OVERRIDE" >> /etc/ssmtp/ssmtp.conf
echo "$ConfiguredComment" >> /etc/ssmtp/ssmtp.conf
