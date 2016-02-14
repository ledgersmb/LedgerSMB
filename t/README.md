

Test file number allocation
===========================

````plain
00 - 09: General base checks
10 - 39: Module checks, no LSMB database required
     40: Set up test LSMB database
     41: Addons setup.  Addons should use 41.x notation where x is the run
         needed to properly install.
42 - 59: Operational checks, LSMB database required
60 - 88: Interface checks
     89: Clean up test LSMB database
90 - 99: Packaging checks
````

Special notes on specific test cases:

43-dbtest.t
-----------
This runs defined test cases from sql/modules/test/.  If new
scripts are added, they must be listed in this script as well.

62-api.t
--------
Runs on the database non-destructively, by rolling back commits.
Uses request hashes defined in t/data/62-request-data.


ENVIRONMENT VARIABLES USED
==========================

Environment variables are used to provide inputs for tests >= 40.

For database tests (40 - 89)
----------------------------

````plain
LSMB_TEST_DB        enables this set of tests
PGUSER              username for logging in in PostgreSQL
PGPASSWORD          password for above username
LSMB_NEW_DB         database to test against (will be created in test 40)
PGDATABASE          database to test against, if LSMB_NEW_DB not provided
````

### Admin user creation

For the interface checks (60-88), at least an admin user is required to log
into the application.

````plain
LSMB_ADMIN_USERNAME username for admin user
LSMB_ADMIN_PASSWORD password for admin user
LSMB_ADMIN_FNAME    Admin's first name
LSMB_ADMIN_LNAME    Admin's last name
LSMB_COUNTRY_CODE   Country code for administrator and for loading chart of
                    accounts
````

### Chart of accounts loading

When a new company is being created,

````plain
LSMB_LOAD_COA       name of the Chart of Accounts file, not including extension
LSMB_LOAD_GIFI      name of the GIFI file, not including extension
LSMB_COUNTRY_CODE   Country code for administrator and for loading chart of
                    accounts
````


For database cleanup test (89)
------------------------------

If the variable LSMB_INSTALL_DB is set, the database will NOT be removed after
test cases are run.  Should be used with the `admin user creation` and
`chart of accounts loading` variables.

