# ledgersmb-database-doc
Database documentation to assist LedgerSMB users and developers

######Copyright (c) 2006 - 2017 LedgerSMB Project



============================
How to generate doc
============================

You can generate your own documentation with 

  PostgreSQL Autodoc - 
  https://github.com/cbbrowne/autodoc

    postgresql_autodoc -d <databasename> -u postgres -f ledgersmb

  GraphViz - 
  http://graphviz.org/


  The ledgersmb.dot file from PostgreSQL Autodoc is a text output meant to 
  be processed by GraphViz (or a compatible program), to make a image of all the database tables in LedgerSMB.

  Use the dot utility from GraphViz, to export a SVG image (Scalable Vector Graphics) 
  
    dot -Tsvg <databasename>.dot -o <databasename>-svg.xml
    
    You can open <databasename>-svg.xml in your web browser and zoom in our out on the image. 
 
  Use the dot utility from GraphViz, to export a SVG image (Scalable Vector Graphics) 
 
    dot -Tpdf <databasename>.dot -o <databasename>.pdf
  
  Use the dot utility from GraphViz, to export a PNG image:

    dot -Tpng <databasename>.dot -o <databasename>.png
