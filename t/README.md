
# Running the tests

```sh
 prove
```

will run tests, depending on the installed features and environment
variables. See below for info on setting environment variables.

To run the '66' tests, the following works with the right `PostgreSQL`,
`PhantomJS` and `Starman` configurations:

```sh
 $ PGUSER=postgres PGPASSWORD=password \
     LSMB_BASE_URL=http://localhost:5762 \
     PSGI_BASE_URL=http://localhost:5762 \
     prove -r t/ xt/
```

Note that the '66' tests may be run at a much smaller granularity
as documented in the [specific `README` file](../xt/66-cucumber/README.md).

# Test summary

```plain
00 - 09: General base checks
10 - 39: Module checks, no LSMB database required
     40: Set up test LSMB database
     41: Addons setup.  Addons should use 41.x notation where x is the run
         needed to properly install.
42 - 59: Operational checks, LSMB database required
60 - 88: Interface checks
     89: Clean up test LSMB database
90 - 99: Packaging checks
```

# ENVIRONMENT VARIABLES

Environment variables are used to provide inputs for tests >= 40.

## For database tests (40 - 89)

```plain
LSMB_TEST_DB        enables this set of tests
PGUSER              username for logging in in PostgreSQL
PGPASSWORD          password for above username
LSMB_NEW_DB         database to test against (will be created in test 40)
PGDATABASE          database to test against, if LSMB_NEW_DB not provided
LSMB_INSTALL_DB     if set, database will NOT be removed after tests are run
LSMB_BASE_URL       address used for requests to lsmb (may be a proxy)
PSGI_BASE_URL       address used to test if plack/starman server is running
```

### Admin user creation

For the interface checks (60-88), at least an admin user is required to log
into the application.

```plain
LSMB_ADMIN_USERNAME username for admin user
LSMB_ADMIN_PASSWORD password for admin user
LSMB_ADMIN_FNAME    Admin's first name
LSMB_ADMIN_LNAME    Admin's last name
LSMB_COUNTRY_CODE   Country code for administrator and for loading chart of
                    accounts
```

### Chart of accounts loading

When a new company is being created,

```plain
LSMB_LOAD_COA       name of the Chart of Accounts file, not including extension
LSMB_LOAD_GIFI      name of the GIFI file, not including extension
LSMB_COUNTRY_CODE   Country code for administrator and for loading chart of
                    accounts
```

## For database cleanup test (89)

If the variable `LSMB_INSTALL_DB` is set, the database will _NOT_ be removed after
test cases are run.  Should be used with the `admin user creation` and
`chart of accounts loading` variables.
