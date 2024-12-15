---
name: EOL release
about: Tracking of steps to execute when marking a release branch End-of-Life
---

* [ ] Add ` (End of Life)` to the 'Changelog for X.YY Series' entry in Changelog
* [ ] Remove the release branch from `renovate.json` in the root of the master branch 
* [ ] Remove the transifex resource (`LedgerSMB-XX`) for the EOL-ed branch
* [ ] Update the supported items page: https://ledgersmb.org/faq/which-versions-do-you-support
* [ ] Remove the old stable references from the downloads page: https://ledgersmb.org/content/download
* [ ] Update Docker image README.md
  * [ ] Docker README listing available tags (on all branches!)
* [ ] Update [list of supported Perl versions](https://ledgersmb.org/faq/which-versions-perl-does-ledgersmb-support)
* [ ] Update [list of supported PostgreSQL versions](https://ledgersmb.org/faq/installation/what-versions-postgresql-does-ledgersmb-support)
* [ ] Mark ledgersmb.org items linked to the specific version number as obsolete  
      unless they're relevant for more recent versions too
* [ ] Update the "Current Versions" section on the ledgersmb.org front page
* [ ] Send EOL notice to the mailing list, using the following mail template:

----

To all users of LedgerSMB 1.9, this is a notice that the community support for 1.9 expires on September 24th. As of 2023-09-24, there will be no more releases for 1.9, which has had 30 patch releases over its 2-year period of community support.

Users running versions older than 1.10 are encouraged to upgrade to 1.10 which will receive community support until 2024-10-08. If the remaining period of community support is too short on 1.10, please note that we're currently working toward a 1.11 release which is expected to appear over the coming weeks. 1.11 will - like its predecessors 1.9 and 1.10 - receive 2 years of community support.

If it is not possible to upgrade to 1.10 or 1.11, please note that although community support has expired, commercial support may be available for these older versions from vendors. Please consult the Commercial Support page on the LedgerSMB project webpage (https://ledgersmb.org/content/commercial-support).

----
