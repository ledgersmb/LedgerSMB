---
name: EOL release
about: Tracking of steps to execute when marking a release branch End-of-Life
---


* [ ] Remove the transifex resource (`LedgerSMB-XX`) for the EOL-ed branch
* [ ] Update the supported items page: https://ledgersmb.org/faq/which-versions-do-you-support
* [ ] Update Docker image README.md
  * [ ] Docker README listing available tags (on all branches!)
* [ ] Update [list of supported Perl versions](https://ledgersmb.org/faq/which-versions-perl-does-ledgersmb-support)
* [ ] Update [list of supported PostgreSQL versions](https://ledgersmb.org/faq/installation/what-versions-postgresql-does-ledgersmb-support)
* [ ] Mark ledgersmb.org items linked to the specific version number as obsolete  
      unless they're relevant for more recent versions too
* [ ] Update the release on the ledgersmb.org front page
