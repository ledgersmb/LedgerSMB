#!/bin/sh

date_now=`date --utc "+%F %R%z"`
version_now=`perl -MLedgerSMB -e 'print \$LedgerSMB::VERSION'`

cat - > locale/LedgerSMB.pot <<EOF
msgid ""
msgstr ""
"Project-Id-Version: LedgerSMB $version_now\n"
"Report-Msgid-Bugs-To: ledger-smb-devel@lists.sourceforge.net\n"
"POT-Creation-Date: $date_now\n"
"MIME-Version: 1.0\n"
"Content-Type: text/plain; charset=UTF-8\n"
"Content-Transfer-Encoding: 8bit\n"

EOF

# EXTRACT STRINGS AND CREATE POT
find . -name '*.pl' -o -name '*.pm' | \
  grep -v blib | grep -v LaTeX | sort | \
  utils/devel/extract-perl >> locale/LedgerSMB.pot

find UI/ templates/ t/data/ \
     -name '*.html' -o -name '*.tex' -o -name '*.csv' | \
   grep -v blib | grep -v dojo/ | sort | \
   utils/devel/extract-template-translations >> locale/LedgerSMB.pot

utils/devel/extract-sql < sql/Pg-database.sql >> locale/LedgerSMB.pot

msguniq -s --width=80 -o locale/LedgerSMB.pot locale/LedgerSMB.pot

# Merge with .po files

for pofile in `find . -name '*.po'`
do
    msgmerge -s --width=80 --update $pofile locale/LedgerSMB.pot
done
