#!/bin/bash

set -x

detect_version () {
    sed -ne "/^our \$VERSION/ { s/^our \$VERSION = '\\(.*\\)';\$/\\1/ p }" lib/LedgerSMB.pm
}

date_now=`date --utc "+%F %R%z"`
version_now=`detect_version`

if test "q$version_now" = "q" ;
then
   echo "Version detection failed!"
   exit 1
fi

cat - > locale/LedgerSMB.pot <<EOF
msgid ""
msgstr ""
"Project-Id-Version: LedgerSMB $version_now\n"
"Report-Msgid-Bugs-To: devel@lists.ledgersmb.org\n"
"POT-Creation-Date: $date_now\n"
"MIME-Version: 1.0\n"
"Content-Type: text/plain; charset=UTF-8\n"
"Content-Transfer-Encoding: 8bit\n"

EOF

# EXTRACT STRINGS AND CREATE POT
find . \
     \( -path ./devel \
        -o -path ./xt/lib \
        -o -path ./xt/66-cucumber \
        -o -path ./sql \
        -o -path ./b \
        -o -path ./UI/pod \
        -o -path ./UI/node_modules \
        -o -path ./utils/devel \
        -o -path './.*' \) -prune \
     -o \(  -name '*.pl' -o -name '*.pm' \) -not -name '*LaTeX*' -print | \
  sort | \
  utils/devel/extract-perl >> locale/LedgerSMB.pot

find UI/ templates/ t/data/ \
     -path UI/node_modules -prune \
     -o -name '*.html' \
     -o -name '*.tex' \
     -o -name '*.csv' | \
   grep -v 'UI/\(js\|pod\)/' | sort | \
   utils/devel/extract-template-translations >> locale/LedgerSMB.pot

utils/devel/extract-sql < sql/Pg-database.sql >> locale/LedgerSMB.pot

utils/devel/extract-vue-template-translations.sh >> locale/LedgerSMB.pot

utils/devel/extract-menu-translations >> locale/LedgerSMB.pot

msgcat --sort-output --width=80 --output-file=locale/LedgerSMB.pot <(msguniq locale/LedgerSMB.pot) \
  || exit 1

# Merge with .po files

for pofile in `find ./locale -name '*.po' | sort`
do
    msgcat --sort-output --width=80 --output-file=$pofile \
           <(msgmerge --quiet \
                      --no-fuzzy-matching \
                      $pofile locale/LedgerSMB.pot) \
      || (echo "failed $pofile" ;  exit 1)
done

# Extract Vue strings which came back from Transifex
for json in `find UI/src/locales/ -name "*.json" -exec basename {} .json \; | sort`; do
    # Convert updated locale/po/, keeping Vue added data and only non-empty strings
    npx --yes i18next-conv --quiet --skipUntranslated --language "$json" \
        --source locale/po/$json.po --target UI/src/locales/$json.json
done
