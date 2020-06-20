
DIST_VER=$(shell git rev-parse --short HEAD)
DIST_DIR=/tmp
ifeq ($(DIST_VER),travis)
DIST_DEPS=cached_dojo
else
DIST_DEPS=dojo
endif

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
    - dojo         : Builds the minified dojo blob we serve to clients
    - cached_dojo  : Uses the cached minified dojo, or builds one
    - dojo_archive : Builds a cached minified dojo archive
    - blacklist    : Builds sql blacklist (required after adding functions)
    - submodules   : Initialises and updates our git submodules
    - pod          : Builds POD documentation
    - test         : Runs tests
    - devtest      : Runs all tests including development/author tests
    - dist         : builds the release distribution archive


endef
export HELP

help:
	@echo "$$HELP"
	$(warning OSTYPE   = $(OSTYPE))
	$(warning OSDISTRO = $(OSDISTRO))
	$(warning REDHAT_RELEASE_FILE = $(REDHAT_RELEASE_FILE))

# make dojo
#   builds dojo for production/release
SHELL := /bin/bash
HOMEDIR := ~/dojo_archive
SHA := $(shell find UI/js-src/lsmb UI/js-src/dojo UI/js-src/dijit -exec sha1sum {} + 2>&1 | sort | sha1sum | cut -d' ' -f 1)
ARCHIVE := $(HOMEDIR)/UI_js_$(SHA).tar
TEMP := $(HOMEDIR)/_UI_js_$(SHA).tar
FLAG := $(HOMEDIR)/building_UI_js_$(SHA)

dojo:
	rm -rf UI/js/*;
	npm install --save-dev;
	./node_modules/webpack/bin/webpack.js -p

dojo_archive: dojo
	#TODO: Protect for concurrent invocations
	mkdir -p $(HOMEDIR)
	touch $(FLAG)
	tar cf $(TEMP) UI/js
	mv $(TEMP) $(ARCHIVE)
	rm $(FLAG)

cached_dojo:
ifeq ($(wildcard $(ARCHIVE)),)
	$(MAKE) dojo_archive
endif
	tar xf $(ARCHIVE)


# make blacklist
blacklist:
	perl utils/test/makeblacklist.pl --regenerate

# make pod
#make submodules
#   Initialises and updates our git submodules
submodules:
	git submodule update --init --recursive

# make dist
#   builds release distribution archive
dist: $(DIST_DEPS)
	test -d $(DIST_DIR) || mkdir -p $(DIST_DIR)
	find . | grep -vE '^.$$|^\./\.|^\./UI/js-src/(dojo|dijit|util)/|\.(uncompressed|consoleStripped)\.js$$|.js.map$$' | tar czf $(DIST_DIR)/ledgersmb-$(DIST_VER).tar.gz --transform 's,^./,ledgersmb/,' --no-recursion --files-from -

# Genarate displayable documentation
pod:
	rm -rf UI/pod
	mkdir UI/pod
	utils/pod2projdocs.pl 2>&1 pod2projdocs.log

test:
	prove -Ilib t/*.t

devtest:
	prove -Ilib t/*.t
	prove -Ilib xt/*.t
