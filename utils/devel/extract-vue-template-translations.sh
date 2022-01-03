#!/bin/bash

# Make sure all PO exist in UI/src/locales
for a in locale/po/*.po; do
    b=$(basename "${a%.*}");
    touch UI/src/locales/$b.json
done

# Extract Vue strings
for a in UI/src/locales/*.json; do
    b=$(basename "${a%.*}");
    cp $a /tmp/$b.json

    # Extract Vue strings in a temporary file, convert to PO and add to current locale/po
    npx vue-i18n-extract-translations -v "./UI/src/**/*.?(js|vue)" -l "/tmp/" --def-locale "$b" \
        --key "i18n" --keep-unused --fill "" >> /dev/null
    i18next-conv --quiet -l "$b" -s /tmp/$b.json -t /tmp/$b.po
    xgettext -o /tmp/_$b.po locale/po/$b.po /tmp/$b.po
    mv /tmp/_$b.po locale/po/$b.po

    # Convert updated locale/po/, keeping Vue added data
    i18next-conv --quiet -l "$b" -s locale/po/$b.po -t /tmp/$b.json;

    rm /tmp/$b.{po,json}
done
