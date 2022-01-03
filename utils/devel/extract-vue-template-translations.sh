#!/bin/bash

# Make sure all PO exist in UI/src/locales
for b in `find locale/po -name "*.po" -exec basename {} .po \; | sort`; do
    [ ! -f "UI/src/locales/$b.json" ] && echo "{}" >UI/src/locales/$b.json
done

set -x

# Extract Vue strings and make a pot file
cp UI/src/locales/en.json /tmp/en.json
npx vue-i18n-extract-translations -v "./UI/src/**/*.?(js|vue)" -l "/tmp/" --def-locale "en" \
    --key "i18n" --keep-unused >> /dev/null
i18next-conv --quiet --language "en" --source /tmp/en.json --target /tmp/en.po
./utils/devel/extract-vue-template-translations-references.pl < /tmp/en.po > /tmp/_en.po
msgfilter  --sort-output --width=80 \
    --input=/tmp/_en.po --output-file=/tmp/en.pot true

# Freshen locale/LedgerSMB.pot
msgcat --output-file=/tmp/LedgerSMB.pot --sort-output --add-location \
        --width=80 locale/LedgerSMB.pot /tmp/en.pot \
    || exit 1

mv /tmp/LedgerSMB.pot locale/LedgerSMB.pot
rm /tmp/*.{po,pot,json}
