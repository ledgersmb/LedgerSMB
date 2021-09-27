#!/bin/sh

# Use xmllint to validate the XML and its format.

# This script fails if either the xml fails validation or the reformatted text is
# different than the source file.

# xmllint can be used to reformt and replace the source file.
# Instead of piping the standard output of xmllint to diff, use it to write 
# the reformatted file.

# This script is expected to run from LedgerSMB/utils/devel directory.

# This is a development tool, not suited for general administration of the software.

for entry in ../../locale/coa/*/*.xml
do
	xmllint --pretty 1  --schema ../../doc/company-setup/configuration.xsd $entry | diff - $entry
	status=( "${PIPESTATUS[@]}" )
    if [ "${status[0]}" -ne 0 ]; then
        >&2 echo "${entry} Failed to validate, xmllint exit code: ${status[0]}"
        exit "${status[0]}"
    elif [ "${status[1]}" -ne 0 ]; then
        >&2 echo "${entry} Format failed to match expected format, diff exit code: ${status[1]}"
        exit "${status[1]}"
    fi
done
