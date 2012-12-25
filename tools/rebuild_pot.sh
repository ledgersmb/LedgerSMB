#!/usr/bin/bash

# EXTRACTING DB STRINGS
echo "select 'text(''' || label || ''')' FROM menu_node" | 
 psql -U postgres > tools/dbstrings

echo "select 'text(''' || class || ''')' FROM entity_class" | 
 psql -U postgres >> tools/dbstrings

echo "select 'text(''' || class || ''')' FROM batch_class" | 
 psql -U postgres >> tools/dbstrings

echo "select 'text(''' || class || ''')' FROM contact_class" | 
 psql -U postgres >> tools/dbstrings

echo "select 'text(''' || class || ''')' FROM location_class" | 
 psql -U postgres >> tools/dbstrings


# SETTING UP FILE LIST
find . -name '*.pl' | grep -v blib > tools/files
find . -name '*.html' | grep -v blib >> tools/files
find . -name '*.pm' | grep -v blib | grep -v Num2text | 
  grep -v LaTeX >> tools/files

# EXTRACT STRINGS AND MERGE WITH .POT

xgettext -f tools/files -ktext -o locale/LedgerSMB.pot 

xgettext -ktext -j -o locale/LedgerSMB.pot -a tools/dbstrings --language=perl
