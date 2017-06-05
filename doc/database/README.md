# ledgersmb-database-doc
Database documentation to assist LedgerSMB users and developers

######Copyright (c) 2006 - 2017 LedgerSMB Project



============================
How to generate doc
============================
You will need at least postgresql_autodoc and graphviz installed on your system.

The script found here will automatically build the docs and images, outputing them into /tmp/LedgerSMB-doc
- `utils/devel/regen_db_docs.sh`

regen_db_docs.sh takes 2 arguments
- --release      : only for use during the official release process.
- --statistics   : generates table statistics using the pgstattuple extension

regen_db_docs.sh will use these environment variables
- PGHOST
- PGUSER
- PGPORT
- PGDATABASE
- PGPASSWORD

It use a password from $PGPASSWORD, ~/.pgpass, or fallback to asking the user for a password.

Viewing the .svg or .svg.html versions of the images will likely provide the best user experience

============================
Alternatively you can generate the documentation manually with

  PostgreSQL Autodoc - 
  https://github.com/cbbrowne/autodoc

    postgresql_autodoc -d <databasename> -u postgres -f ledgersmb

  GraphViz - 
  http://graphviz.org/


  The ledgersmb.dot file from PostgreSQL Autodoc is a text output meant to 
  be processed by GraphViz (or a compatible program), to make a image of all the database tables in LedgerSMB.

  Use the dot utility from GraphViz, to export a SVG image (Scalable Vector Graphics) 
  
    dot -Tsvg <databasename>.dot -o <databasename>.svg
    
    You can open <databasename>.svg in many image viewers, or your web browser and zoom in our out on the image. 
 
  Use the dot utility from GraphViz, to export a PDF. NOTE: the PDF has a large number of elements, and will be slow to load, and may have limited zoom capabilities in some viewers
 
    dot -Tpdf <databasename>.dot -o <databasename>.pdf
  
  Use the dot utility from GraphViz, to export a PNG image:  NOTE: This is a large image, and while readable, the resolution is not great.

    dot -Tpng <databasename>.dot -o <databasename>.png
