
-include Makefile.local

DIST_VER=$(shell git rev-parse --short HEAD)
DIST_DIR=/tmp

ifeq ($(CI),true)
	NPM_COMMAND=ci
else
	NPM_COMMAND=install
endif

ifeq ($(DIST_VER),travis)
DIST_DEPS=cached_dojo dbdocs
else
DIST_DEPS=dojo dbdocs
endif

ifeq ("$(wildcard /.dockerenv)","")
ifneq ($(origin CONTAINER),undefined)
DOCKER_CMD=docker exec -ti $(CONTAINER)
endif
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
    - dojo         : Builds the minified dojo blob we serve to clients (legacy)
    - js           : Builds the minified dojo blob we serve to clients
    - devdojo      : Builds JS assets with Vue debugger enabled (legacy)
    - jsdev        : Builds JS assets with Vue debugger enabled
    - jslint       : Runs 'eslint' on the JS code (FIX=1 reformats)
    - dbdocs       : Builds the PDF, SVG and PNG schema documentation
                     (without rebuilding the inputs)
    - pod          : Builds POD documentation
    - api          : Builds API documentation
    - pot          : Builds LedgerSMB.pot translation lexicon
    - readme       : Builds the README.md
    - test         : Runs tests (TESTS='t/')
    - serve        : Runs the 'webpack serve' command
    - devtest      : Runs all tests including development tests (TESTS='t/ xt/')
	- jstest	   : Runs all UI tests (TESTS='UI/tests')
    - pherkin      : Runs all BDD tests with 'pherkin' (instead of 'prove')

    - blacklist    : Builds sql blacklist (required after adding functions)

The targets 'test', 'devtest', 'jstest' and 'pherkin' take a TESTS parameter
which can be used to specify a subset of tests to be run.

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

dbdocs:
	$(DOCKER_CMD) dot -Tsvg doc/database/ledgersmb.dot -o doc/database/ledgersmb.svg
	$(DOCKER_CMD) dot -Tpdf doc/database/ledgersmb.dot -o doc/database/ledgersmb.pdf

npm_install:
	$(DOCKER_CMD) npm $(NPM_COMMAND) --no-save

dojo: npm_install
	$(DOCKER_CMD) npm run build

devdojo: npm_install
	$(DOCKER_CMD) npm run build:dev

js: npm_install
	$(DOCKER_CMD) npm run build

jsdev: npm_install
	$(DOCKER_CMD) npm run build:dev

jslint:
ifneq ($(origin FIX),undefined)
	$(DOCKER_CMD) npm run lint:js:fix
else
	$(DOCKER_CMD) npm run lint:js
endif

readme: npm_install
	$(DOCKER_CMD) npm run readme

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
	$(DOCKER_CMD) perl -Ilib -Iold/lib utils/devel/makeblacklist.pl --regenerate

dist: $(DIST_DEPS)
	test -d $(DIST_DIR) || mkdir -p $(DIST_DIR)
	find . | grep -vE '^.$$|^\./\.|^\./node_modules/|\.(uncompressed|consoleStripped)\.js$$|.js.map$$' | tar czf $(DIST_DIR)/ledgersmb-$(DIST_VER).tar.gz --transform 's,^./,ledgersmb/,' --no-recursion --files-from -

pod:
	rm -rf UI/pod
	mkdir UI/pod
	chmod 777 UI/pod
	$(DOCKER_CMD) utils/devel/pod2projdocs.pl 2>&1 pod2projdocs.log

api:
	rm -rf UI/openapi
	mkdir UI/openapi
	chmod 777 UI/openapi
	$(DOCKER_CMD) utils/devel/rebuild_api.sh 2>&1 rebuild_api.log

pot:
	chmod 666 locale/LedgerSMB.pot locale/po/*.po
	chmod 777 locale/po
	$(DOCKER_CMD) utils/devel/rebuild_pot.sh

test: TESTS ?= t/
test:
	$(DOCKER_CMD) prove --time --recurse $(TESTS)

devtest: TESTS ?= t/ xt/
devtest:
ifneq ($(origin DOCKER_CMD),undefined)
#       if there's a docker container, jump into it and run from there
	$(DOCKER_CMD) make devtest TESTS="$(TESTS)"
else
#        the 'dropdb' command may fail, hence the prefix minus-sign
	-PERL5OPT="" dropdb --if-exists lsmb_test
	-PERL5OPT="" dropdb --if-exists lsmb_test_db_coa
	-mkdir -p logs/screens
	perl -Ilib bin/ledgersmb-admin create \
            $${PGUSER:-postgres}@$${PGHOST:-localhost}/$${PGDATABASE:-lsmb_test}#xyz
	PGOPTIONS="-c search_path=xyz" yath test --no-color --retry=2 \
            --pgtap-dbname=lsmb_test --pgtap-username=postgres \
            --pgtap-psql=.circleci/psql-wrap \
            --Feature-tags=~@wip \
            --Feature-tags=~@extended \
            $(TESTS)
endif

jstest: TESTS ?= tests
jstest: api
ifneq ($(origin DOCKER_CMD),undefined)
#       if there's a docker container, jump into it and run from there
	$(DOCKER_CMD) make jstest
else
	# Test API answer
	./node_modules/.bin/jest $(TESTS)
endif

serve:
ifneq ($(origin DOCKER_CMD),undefined)
#       if there's a docker container, jump into it and run from there
	$(DOCKER_CMD) make serve
else
	npx webpack serve
endif

pherkin: TESTS ?= xt/
pherkin:
	$(DOCKER_CMD) pherkin $(PHERKIN_OPTS) $(TESTS)

docker-run:
	$(DOCKER_CMD) bash

docker-restart:
ifneq ($(origin CONTAINER),undefined)
	docker restart $(CONTAINER)
else
	echo No idea which container to restart...
endif
