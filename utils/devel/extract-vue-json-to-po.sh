#!/bin/bash

json=${1:-en}

# Freshen locale/LedgerSMB.pot
utils/devel/extract-vue-template-translations.sh

# Pull in locally translated text
pushd UI/ >/dev/null
i18next-conv -y --quiet --language "$json" --source src/locales/$json.json --target /tmp/$json.po
popd >/dev/null
./utils/devel/extract-vue-template-translations-references.pl < /tmp/$json.po > /tmp/_$json.po
msgcat --output-file=locale/po/$json.po --sort-output locale/po/$json.po /tmp/_$json.po \
    --add-location \
    || exit 1
rm /tmp/*.po
