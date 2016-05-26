
DIST_VER=$(shell git log | head -1 | sed -e 's/commit \(.......\).*/\1/')
DIST_DIR=/tmp

# make dojo
#   builds dojo for production/release
dojo:
	rm -rf UI/js/
	cd UI/js-src/lsmb/ && ../util/buildscripts/build.sh --profile lsmb.profile.js

# make dist
#   builds release distribution archive
dist: dojo
	test -d $(DIST_DIR) || mkdir -p $(DIST_DIR)
	find . | grep -vE '^.$$|/\.git|^\./UI/js-src/(dojo|dijit|util)/|\.uncompressed\.js$$|.js.map$$' | tar czf $(DIST_DIR)/ledgersmb-$(DIST_VER).tar.gz --transform 's,^./,ledgersmb/,' --no-recursion --files-from -
