#!/bin/bash

set -x

PATH="/srv/ledgersmb/node_modules/.bin:${PATH}"

pushd /srv/ledgersmb/openapi

# Extract OpenAPI specs from the Perkl sources
grep -il OpenAPI: ../lib/LedgerSMB/Routes/ERP/API/*.pm | xargs ./extract_data_section.pl

# Merge them into openapi.yaml 
openapi-merge-cli

# Validate the resulting OpenAPI spec
openapi-generator-cli validate --input-spec openapi.yaml || exit
npx @redocly/cli lint openapi.yaml || exit

# Build the documentation
snippet-enricher-cli --input=openapi.yaml > /tmp/openapi-with-examples.json
redoc-cli build /tmp/openapi-with-examples.json -o ../UI/pod/LedgerSMB-api.html 
rm /tmp/openapi-with-examples.json [A-Z]*.yaml

popd
