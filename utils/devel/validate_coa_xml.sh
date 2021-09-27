#!/bin/bash

# Use xmllint to validate the XML and its format.

# This script fails if either the xml fails validation or the reformatted text is
# different than the source file.

# This script is expected to run from LedgerSMB/utils/devel directory.

# xmllint can be used to reformt and replace the source file.
# Instead of piping the xmllint standard output (which has been reformatted) 
# to diff, write the output to your file.

# This is a development tool and should not be needed in production.

wdir=$(pwd)
if [[ $wdir =~ .*/utils/devel$ ]]; then
  for entry in ../../locale/coa/*/*.xml
  do
    xmllint --pretty 1  --schema ../../doc/company-setup/configuration.xsd $entry | diff - $entry
    # Note that PIPESTATUS only works for bash, it fails on zsh, which requires pipestatus (lowercase)
    # and is indexed starting at 1. PIPESTATUS also does not work on ksh at all.
    status=( "${PIPESTATUS[@]}" )
      if [ "${status[0]}" -ne 0 ]; then
        >&2 echo "${entry} Failed to validate, xmllint exit code: ${status[0]}"
        exit "${status[0]}"
      elif [ "${status[1]}" -ne 0 ]; then
        >&2 echo "${entry} Format failed to match expected format, diff exit code: ${status[1]}"
        exit "${status[1]}"
      fi
  done
else
  echo "This script must be executed from the 'LedgerSMB/utils/devel' directory."
  exit 1
fi
