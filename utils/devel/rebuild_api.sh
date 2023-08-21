#!/bin/bash

# Find ledgerSMB root directory
gitDirName=`git rev-parse --show-toplevel 2>/dev/null`

# Allow finding openapi modules 
PATH="$gitDirName/UI/node_modules/.bin:$PATH"

# Build in a temporary directory
TMPDIR=$(mktemp -d)

set -x

pushd $TMPDIR

# Extract OpenAPI specs from the Perl sources
$gitDirName/openapi/extract_data_section.pl $gitDirName/lib/LedgerSMB/Routes/ERP/API.pm
mv API.yml _LedgerSMB.yml
echo -n '{"inputs": [{"inputFile": "_LedgerSMB.yml"}' > openapi-merge.json
grep -l __DATA__ $(find $gitDirName/lib/LedgerSMB/Routes/ERP/ -name '*.pm') | xargs $gitDirName/openapi/extract_data_section.pl
find . -name '[A-Z]*.yml' -exec echo -n ",{\"inputFile\": \"{}\"}" \; >> openapi-merge.json
echo '],"output": "API.yaml"}'  >> openapi-merge.json

# Merge them into openapi.yaml 
npx openapi-merge-cli --config openapi-merge.json

# Validate the resulting OpenAPI spec
cp $gitDirName/openapi/.redocly.yaml .
npx @redocly/cli lint API.yaml || exit

# Build the documentation
cp $gitDirName/openapi/LedgerSMB-api.html $gitDirName/doc/openapi/
npx @redocly/cli bundle API.yaml -o $gitDirName/doc/openapi/openapi.json

mv API.yaml $gitDirName/openapi/

popd

rm -r $TMPDIR
