#!/bin/bash

# Allow finding openapi modules
PATH="$PWD/UI/node_modules/.bin:$PATH"

# Build in a temporary directory
TMPDIR=$(mktemp -d)

set -x

cp doc/openapi/redocly.yaml $TMPDIR
utils/devel/api_extract_data_section.pl $TMPDIR lib/LedgerSMB/Routes/ERP/API.pm
utils/devel/api_extract_data_section.pl $TMPDIR $(grep -l __DATA__ $(find lib/LedgerSMB/Routes/ERP/ -name '*.pm'))

pushd $TMPDIR

# Extract OpenAPI specs from the Perl sources
mv API.yml _LedgerSMB.yml
echo -n '{"inputs": [{"inputFile": "_LedgerSMB.yml"}' > openapi-merge.json
find . -name '[A-Z]*.yml' -exec echo -n ",{\"inputFile\": \"{}\"}" \; >> openapi-merge.json
echo '],"output": "API.yaml"}'  >> openapi-merge.json

# Merge them into openapi.yaml
npx --yes openapi-merge-cli --config openapi-merge.json

# Validate the resulting OpenAPI spec
npx --yes @redocly/cli lint API.yaml || exit
# Build the documentation
npx --yes @redocly/cli bundle $TMPDIR/API.yaml -o openapi.json

popd

mv $TMPDIR/API.yaml doc/openapi/
mv $TMPDIR/openapi.json doc/openapi/

rm -r $TMPDIR
rm -r UI/openapi
cp -r doc/openapi UI/
