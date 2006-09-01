To build and install the DBD::DB2 module, you need the following: 

*Perl 5.004_04 or later 
*DBI 0.93 or later 
*DB2 Application Development Client 
*A supported C compiler as documented under 
 'Supported Operating Systems' 
 at the DB2 Application Development Web page:

http://www-3.ibm.com/software/data/db2/udb/ad/index.html

Install Notes:

http://www.perl.com/CPAN-local/modules/by-module/DBD/DBD-DB2-0.76.readme

Module:

http://www.perl.com/CPAN-local/modules/by-module/DBD/DBD-DB2-0.76.tar.gz

Notes:
-----------------------------

LedgerSMB tested with IBM DB2 v7.2 and v8.1.
Compiled for use with DBI 1.18 for all testing.

DB2 Application Development Client used was with
the DB2 Personal Developer's Edition (PDE). All
databases and application code tested under RedHat
Linux 7.2 kernel 2.4.7-10.

ADDITIONAL NOTES: DB2 specific
------------------------------

1. DB2 installed under default owner, and group:
   db2inst1 and db2grp1.
   
2. LedgerSMB app owner (ledger) was added to DB2 group db2grp1
   thereby given SYSADM authority.
   
3. LedgerSMB app owner has same ENV variables as the db2inst1 user.
   This can be added, or have:
   . $DB_HOME/sqllib/db2profile  in the LedgerSMB app owner .(bash_)profile.
   
4. LedgerSMB app owner must have environment variable
   DB2INSTANCE set.
   
5. LedgerSMB app owner, now with SYSADM authority and PATH
   containing DB2's bin should run the following:
   
   prompt>:  db2set -all    # To view instance and registry variables 
   prompt>:  db2set DB2DBDFT=your_default_database_name i.e. LEDGER
   prompt>:  db2set DB2CLIINIPATH=set_to_usually $DB_HOME/sqllib/cfg
   
   Now, cd to the DB2CLIINIPATH directory and edit the db2cli.ini
   file.  Continuing with our use of LEDGER as the database that
   will be created and used, add:
   
   [LEDGER]
   AUTOCOMMIT=1
   LONGDATACOMPAT=1
   DBALIAS=LEDGER
   DEFERREDPREPARE=1
   
   If DEFERREDPREPARE=1 is the last line, add a blank line.  A blank
   line must be the last line.
   
6. Create the database, objects, and initialize by moving to the directory:
   /where_you_installed_SQL-Ledger/sql , and review the file
   DB2-sql-ledger.order.  The commands outlined are in the required order,
   create a database called LEDGER using default SMS tablespaces.  The
   last command-line creates the "Default" Chart-of-Accounts.  
   
   *Modify the files at will to: 
   	create a different named database (make sure you review the 
   	step where you -> db2set DB2DBDFT=your_default_database_name) 
   	
   	create DMS tablespaces
   	
   	different Chart-of-Accounts.  
   	
   If a 'gifi' sql script needs to be run, make sure the 
   "db2 -tvf" is used so the ';' are accepted as command terminators.
