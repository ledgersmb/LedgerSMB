
# make dojo
#   builds dojo for production/release
dojo:
	rm -rf UI/js/
	cd UI/js-src/lsmb/ && ../util/buildscripts/build.sh --profile lsmb.profile.js
