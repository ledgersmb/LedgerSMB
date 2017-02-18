# ledgersmb-database-doc
Database documentation to assist LedgerSMB users and developers

######Copyright (c) 2006 - 2017 LedgerSMB Project



============================
How to generate doc
============================

    You can generate your own documentation with 

    PostgreSQL Autodoc
    https://github.com/cbbrowne/autodoc

    postgresql_autodoc -d <dbname> -u postgres -f ledgersmb

    GraphViz
    http://graphviz.org/


    The .dot file from PostgreSQL Autodoc is a text output meant to 
    be processed by GraphViz (or a compatible program). 

    Use the dot utility from GraphViz, to export a PNG image:

    dot -Tpng <databasename>.dot -o <databasename>.png

    
