#!/bin/bash

# Make sure all PO exist in UI/src/locales
for b in `find locale/po -name "*.po" -exec basename {} .po \; | sort`; do
    [ ! -f "UI/src/locales/$b.json" ] && echo "{}" >UI/src/locales/$b.json
done

set -x

# Extract Vue strings and make a pot file
cp UI/src/locales/en.json /tmp/en.json
npx vue-i18n-extract-translations -v "./UI/src/**/*.?(js|vue)" -l "/tmp/" --def-locale "en" \
    --key "i18n" --keep-unused > /dev/null
npx i18next-conv --quiet --pot --project LedgerSMB --language "en" -b /tmp/en.json -s /tmp/en.json --target /tmp/en.po
./utils/devel/extract-vue-template-translations-references.pl < /tmp/en.po

