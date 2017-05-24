
# BDD Tests

The category '66-cucumber' is a bit of a misnomer: these tests are
really browser based tests and we use the principles from BDD to
specify the test scripts and drive the browser engine.


# Test groups

Tests have been grouped by function:

```plain
  00-09 Basic operation and system configuration tests
  10-19 Accounting tests
  20-29 Quotation and orders
  30-39 Inventory and shipping
```

# Running the tests

The tests are integrated with the 'make test' test framework. However,
they can be run separately as well, using the 'pherkin' test runner
which comes with Test:BDD::Cucumber:

```sh
 $ PGUSER=postgres PGPASSWORD=password LSMB_BASE_URL="http://localhost:5000" \
     pherkin t/66-cucumber/*/
```

or when running just a single feature file:

```sh
 $ PGUSER=postgres PGPASSWORD=password LSMB_BASE_URL="http://localhost:5000" \
     pherkin t/66-cucumber/01-basic/closing.feature
```

In separate terminals, you need to run the following commands from the
root of the development tree for the above to work:

```sh
 $ starman tools/starman.psgi
 $ phantomjs --webdriver=4422
```

# Code structure

The code consists of the following components:

 * Feature files (*.feature), grouped by function into the directories
   numbered as defined above (e.g. `t/66-cucumber/01-basic/`)
 * Step files, which implement function specific steps, in a
   `step_definitions` subdirectory of each numbered directory
   (e.g. `01-basic/step_definitions/`)
 * `pherkin` extensions in `xt/lib/Pherkin/Extension` which implement
   * `LedgerSMB`: Steps which define application state (provides
     database handle access)
   * `PageObject`: Steps to access the browser UI, common to most
     test scripts
 * `PageObject`s (in `xt/lib/`)
   * implementing access to browser page
     functionality, deriving from `Weasel::Element`, thereby referring
     to their root DOM element
   * self-registering Weasel::WidgetHandler-s and Weasel::FindExpander-s,
     keeping DOM-tree knowledge local to the PageObject

# DOM tree mapping

The DOM tree's root element (`html`), maps to PageObject::Root, by
overriding Weasel::Session's `page_class` attribute.

The pages from setup.pl and the two pages from login.pl (the login page
and the single-page app) are identified through the 'id' attribute of the
`body` tag.

The single page app's DOM tree:

  * Weasel::Session's `page` attribute (PageObject::Root)
    * `body` attribute (PageObject::App)
      * `menu` attribute (PageObject::App::Menu)
      * `maindiv` attribute (PageObject::App::Main)
        * `content` attribute (PageObject::App::*)

The BDD scripts refer to the `body` attribute's value above as
"the page", while they refer to the `content` attribute's value as
"the screen".

# DOM tree changes

In-browser actions change the DOM tree, e.g. due to form submission
replacing the entire page or the `#maindiv` content referred to
by `body` and `content` respectively.

The `content` accessor compensates for DOM tree changes and stale
attribute values by testing 'staleness' before returning the value,
thereby reducing the window of opportunity for race conditions.

As far as timing is concerned: steps prior to the current one aren't
guaranteed to leave the expected value in the `content` attribute,
e.g. because the div hasn't fully loaded yet. Another reason could be
that steps were used which don't ensure (re)loading of the `content`
attribute.

## Expecting specific widgets as return values

When a specific widget is expected to be returned, the receiver should
use the session's wait_for() function to poll for the correct return
type. The default settings for wait_for make it poll for a number of
seconds.  A good example is the `Then 'I should see the <screen-name>
screen'` step in `xt/lib/Pherkin/Extensions/pageobject_steps/nav_steps.pl`.

Caching accessors, such as `content` above, should be resistent to the
'repeated accessing' pattern caused by this polling behaviour by validating
the validity (not being stale) of the return value and refreshing the
cache when staleness is detected.
