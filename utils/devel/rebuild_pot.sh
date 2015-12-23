#!/bin/sh


# EXTRACT STRINGS AND RECREATE POT
find . -name '*.pl' -o -name '*.pm' | \
  grep -v blib | grep -v LaTeX | \
  utils/devel/extract-perl > locale/LedgerSMB.pot

find UI/ templates/ -name '*.html' -o -name '*.tex' -o -name '*.csv' | \
   grep -v blib | grep -v dojo/ | \
   utils/devel/extract-template-translations >> locale/LedgerSMB.pot

utils/devel/extract-sql < sql/Pg-database.sql >> locale/LedgerSMB.pot

msguniq -s --width=80 -o locale/LedgerSMB.pot locale/LedgerSMB.pot

# Merge with .po files

for pofile in `find . -name '*.po'`
do
    msgmerge -s --width=80 --update $pofile locale/LedgerSMB.pot
done
