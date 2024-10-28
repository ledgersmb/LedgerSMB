#!/bin/bash

# Make sure all PO exist in UI/src/locales
for b in `find locale/po -name "*.po" -exec basename {} .po \; | sort`; do
    [ ! -f "UI/src/locales/$b.json" ] && echo "{}" >UI/src/locales/$b.json
done

set -x

# Extract Vue strings and make a pot file
pushd UI/ >/dev/null
cp src/locales/en.json /tmp/en.json
npx --yes vue-i18n-extract-translations -v "./src/**/*.?(js|vue)" -l "/tmp/" --def-locale "en" \
    --key "i18n" --keep-unused > /dev/null
npx --yes i18next-conv --quiet --pot --project LedgerSMB --language "en" -b /tmp/en.json -s /tmp/en.json --target /tmp/en.po
popd >/dev/null
./utils/devel/extract-vue-template-translations-references.pl < /tmp/en.po

