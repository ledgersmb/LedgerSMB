# Tools to assist LedgerSMB developers

<!-- markdownlint-disable MD001 -->
<!-- markdownlint-disable MD018 -->
###### Copyright (c) 2015 ledgersmb.org

    Licensed under the GPLv2 a copy of which can be found in /LICENSE

    For more information about any of these files, Read The Source Luke

## extract_mimes.sh

    Searches /usr/share/mime for freedesktop.xml files and builds a list of sql
    statements for populating the mime_types table

## extract-perl

    Scans various Perl files for translatable strings

## extract-sql

    Scans various SQL files for translatable strings

## extract-template-translations

    Scans various Template files for translatable strings

## generate-language-table-contents.pl

    Scans the locale directory and read in the LANGUAGE files

## rebuild_pot.sh

    Rebuilds the language file

## regen_db_docs.sh

    This is a utility which will run through PostgreSQL system tables and returns
    HTML, DOT, and several styles of XML which describe the database.

    As a result, documentation about a project can be generated quickly and be
    automatically updatable, yet have a quite professional look

## wc-pot-file

    A script to generate some stats on our currently translateable strings.

    usage:
        wc-pot-file -h
        wc-pot-file [-v] filename.pot
        -h  : show this help
        -v  : Verbose. Print word count and string for EVERY string
