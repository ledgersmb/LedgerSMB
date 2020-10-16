
-include Makefile.local

DIST_VER=$(shell git rev-parse --short HEAD)
DIST_DIR=/tmp
ifeq ($(DIST_VER),travis)
DIST_DEPS=cached_dojo
else
DIST_DEPS=dojo
endif

ifneq ($(origin CONTAINER),undefined)
DOCKER_CMD=docker exec -ti $(CONTAINER)
endif

PHERKIN_OPTS ?= --tags ~@wip $(PHERKIN_EXTRA_OPTS)



.DEFAULT_GOAL := help

# make help
#   Simple Help on installing LedgerSMB and use of this Makefile
#   This should always remain the first target
#   The first target is the default when make is run with no arguments
define HELP
Help on installing LedgerSMB can be found in
  - README.md
  - https://ledgersmb.org/installation

Help on using this Makefile
  The following make targets are available
    - help         : This help text
    - dist         : Builds the release distribution archive
    - dojo         : Builds the minified dojo blob we serve to clients
    - pod          : Builds POD documentation
    - test         : Runs tests (TESTS='t/')
    - devtest      : Runs all tests including development tests (TESTS='t/ xt/')
    - pherkin      : Runs all BDD tests with 'pherkin' (instead of 'prove')

    - blacklist    : Builds sql blacklist (required after adding functions)

The targets 'test', 'devtest' and 'pherkin' take a TESTS parameter which
can be used to specify a subset of tests to be run.

endef
export HELP

help:
	@echo "$$HELP"

# make dojo
#   builds dojo for production/release
SHELL := /bin/bash
HOMEDIR := ~/dojo_archive
SHA := $(shell find UI/js-src/lsmb node_modules/dojo node_modules/dojo-webpack-plugin node_modules/dijit package.json webpack.config.js -exec sha1sum {} + 2>&1 | sort | sha1sum | cut -d' ' -f 1)
ARCHIVE := $(HOMEDIR)/UI_js_$(SHA).tar
TEMP := $(HOMEDIR)/_UI_js_$(SHA).tar
FLAG := $(HOMEDIR)/building_UI_js_$(SHA)

dojo:
	$(DOCKER_CMD) rm -rf UI/js/*;
	$(DOCKER_CMD) npm install --save-dev;
	$(DOCKER_CMD) ./node_modules/webpack/bin/webpack.js -p

# TravisCI specific target -- need to find a way to get rid of it
dojo_archive: dojo
# TODO: Protect for concurrent invocations
	mkdir -p $(HOMEDIR)
	touch $(FLAG)
	tar cf $(TEMP) UI/js
	mv $(TEMP) $(ARCHIVE)
	rm $(FLAG)

# TravisCI specific target -- need to find a way to get rid of it
cached_dojo:
ifeq ($(wildcard $(ARCHIVE)),)
	$(MAKE) dojo_archive
endif
	tar xf $(ARCHIVE)


blacklist:
	$(DOCKER_CMD) perl -Ilib utils/test/makeblacklist.pl --regenerate

dist: $(DIST_DEPS)
	test -d $(DIST_DIR) || mkdir -p $(DIST_DIR)
	find . | grep -vE '^.$$|^\./\.|^\./node_modules/(dojo(-webpack-plugin)?|dijit|util)/|\.(uncompressed|consoleStripped)\.js$$|.js.map$$' | tar czf $(DIST_DIR)/ledgersmb-$(DIST_VER).tar.gz --transform 's,^./,ledgersmb/,' --no-recursion --files-from -

pod:
	rm -rf UI/pod
	mkdir UI/pod
	chmod 777 UI/pod
	$(DOCKER_CMD) utils/pod2projdocs.pl 2>&1 pod2projdocs.log

test: TESTS ?= t/
test:
	$(DOCKER_CMD) prove --time --recurse $(TESTS)

devtest: TESTS ?= t/ xt/
devtest:
	$(DOCKER_CMD) prove --time --recurse \
	                    --pgtap-option dbname=lsmbinstalltest \
	                    --pgtap-option username=postgres \
	                    --feature-option tags=~@wip \
	                    $(TESTS)

pherkin: TESTS ?= xt/
pherkin:
	$(DOCKER_CMD) pherkin $(PHERKIN_OPTS) $(TESTS)
