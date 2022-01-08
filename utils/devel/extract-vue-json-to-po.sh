#!/bin/bash

json=${1:-en}

# Freshen locale/LedgerSMB.pot
utils/devel/extract-vue-template-translations.sh

# Pull in locally translated text
i18next-conv --quiet --language "$json" --source UI/src/locales/$json.json --target /tmp/$json.po
./utils/devel/extract-vue-template-translations-references.pl < /tmp/$json.po > /tmp/_$json.po
msgcat --output-file=locale/po/$json.po --sort-output locale/po/$json.po /tmp/_$json.po \
    --add-location \
    || exit 1
rm /tmp/*.po
