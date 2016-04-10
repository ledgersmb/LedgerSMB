
BDD Tests
=========

The category '66-cucumber' is a bit of a misnomer: these tests are
really browser based tests and we use the principles from BDD to
specify the test scripts and drive the browser engine.


Test groups
===========

Tests have been grouped by function:

00-09 Basic operation and system configuration tests
10-19 Accounting tests
20-29 Quotation and orders
30-39 Inventory and shipping


Running the tests
=================

The tests are integrated with the 'make test' test framework. However,
they can be run separately as well, using the 'pherkin' test runner
which comes with Test:BDD::Cucumber:

 $ PGUSER=postgres PGPASSWORD=password LSMB_BASE_URL="http://localhost:5000" \
     pherkin t/66-cucumber/

In separate terminals, you need to run the following commands from the
root of the development tree for the above to work:

 $ starman tools/starman.psgi
 $ phantomjs --webdriver=4422

