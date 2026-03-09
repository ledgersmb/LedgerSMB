#!/bin/bash

set -euo pipefail

# Allow finding openapi modules
PATH="$PWD/UI/node_modules/.bin:$PATH"

# Build in a temporary directory
TMPDIR=$(mktemp -d)

set -x

cp doc/openapi/redocly.yaml $TMPDIR
utils/devel/api_extract_data_section.pl $TMPDIR lib/LedgerSMB/Routes/ERP/API.pm
utils/devel/api_extract_data_section.pl $TMPDIR $(grep -l __DATA__ $(find lib/LedgerSMB/Routes/ERP/ -name '*.pm'))
utils/devel/merge-api-yaml $TMPDIR/*.yml > $TMPDIR/merged.yaml

# Validate and format the resulting OpenAPI spec
npx --yes @redocly/cli lint $TMPDIR/merged.yaml
npx --yes openapi-format $TMPDIR/merged.yaml -o doc/openapi/API.yaml

pushd doc/openapi
# Build the documentation
npx --yes @redocly/cli bundle API.yaml -o openapi.json
popd

rm -r $TMPDIR
rm -rf UI/openapi
mkdir UI/openapi
cp -r doc/openapi/LedgerSMB-api.html doc/openapi/openapi.json UI/openapi
