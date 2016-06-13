
DIST_VER=$(shell git log | head -1 | sed -e 's/commit \(.......\).*/\1/')
DIST_DIR=/tmp

# make dojo
#   builds dojo for production/release
dojo:
	rm -rf UI/js/;
	cd UI/js-src/lsmb/ \
            && ../util/buildscripts/build.sh --profile lsmb.profile.js \
            | egrep -v 'warn\(224\).*A plugin dependency was encountered but there was no build-time plugin resolver. module: (dojo/request;|dojo/request/node;|dojo/request/registry;|dijit/Fieldset;|dijit/RadioMenuItem;|dijit/Tree;|dijit/form/_RadioButtonMixin;)';
	git checkout -- UI/js/README;
	@echo "\n\nDon't forget to set ledgersmb.conf dojo_built=1\n";

pod:
	rm -rf UI/pod
	mkdir UI/pod
	utils/pod2projdocs.pl 2>&1 pod2projdocs.log

# Little toy for code critique
# Make sure that aspell is installed for your locale (apt install aspell-fr, for example)
# Open UI/pod/critic_html/index.html with prefered browser
critic:
	test -d UI/pod || mkdir -p UI/pod
	./tools/critic_html/critichtml

# make dist
#   builds release distribution archive
dist: dojo
	test -d $(DIST_DIR) || mkdir -p $(DIST_DIR)
	find . | grep -vE '^.$$|/\.git|^\./UI/js-src/(dojo|dijit|util)/|\.uncompressed\.js$$|.js.map$$' | tar czf $(DIST_DIR)/ledgersmb-$(DIST_VER).tar.gz --transform 's,^./,ledgersmb/,' --no-recursion --files-from -
