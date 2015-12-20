#!/bin/sh


# SETTING UP FILE LIST
find . -name '*.pl' | grep -v blib > tools/files
find . -name '*.html' | grep -v blib >> tools/files
find . -name '*.tex' | grep -v blib >> tools/files
find . -name '*.csv' | grep -v blib >> tools/files
find . -name '*.pm' | grep -v blib | grep -v Num2text | \
  grep -v LaTeX >> tools/files

# EXTRACT STRINGS AND MERGE WITH .POT

xgettext -f tools/files -ktext -o locale/LedgerSMB.pot
find UI/ -name '*.html' | grep -v dojo/ | \
   utils/devel/extract-template-translations > locale/templates.pot
msgmerge locale/LedgerSMB.pot locale/templates.pot -o locale/LedgerSMB.pot-tmp
utils/devel/extract-sql < sql/Pg-database.sql > locale/sql.pot
msgmerge locale/LedgerSMB.pot-tmp locale/sql.pot -o locale/LedgerSMB.pot
xgettext -ktext -j -o locale/LedgerSMB.pot --language=perl

# Merge with .po files

for pofile in `find . -name '*.po'`
do
    msgmerge --width=80 --update $pofile locale/LedgerSMB.pot
done
