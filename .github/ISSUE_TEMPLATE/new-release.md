---
name: New release
about: Tracking the progress on preparing a new release branch
---


# Release check list

## At branch time (pre-beta)

* [ ] Create stabilization branch
* [ ] Create a new transifex resource for branch translation
  * [ ] Make sure that `slug` and `name` both contain LedgerSMB-XX
  * [ ] Make sure that the auto-update URL is set
* [ ] Update the .tx/config section name `[ledgersmb.LedgerSMB]` -> `[ledgersmb.LedgerSMB-XX]`
* [ ] Update the version number of the 'master' branch:
  * [ ] sql/Pg-database.sql
  * [ ] package.json
  * [ ] In setup.pm, add support to create databases of the version that 'master' becomes
  * [ ] In LedgerSMB.pm, increase the $VERSION variable
  * [ ] In bin/ledgersmb-server.psgi adjust the version-check regex
  * [ ] In locale/LedgerSMB.pot, adjust the Project-Id
  * [ ] In t/data/Is_LSMB_running.html, increase the version text
  * [ ] Update README.md reference to `docker-compose` file (both on the branch and on master)
  * [ ] Create a new docker-compose branch
* [ ] Add the new version to renovate.json baseBranches

## General preparation

* [ ] Create the .0 release milestone
* [ ] Assign the known issues to the release milestone
* [ ] Make an announcement on the users, development and announcement lists for translators to become aware of the imminent release
* [ ] Notify package maintainers of upcoming release
  * [ ] Docker image
  * [ ] Debian package
  * [ ] (others??)
* [ ] Create one or more RC releases
* [ ] Fix blocking findings
* [ ] Update maintenance branch README.md
  * [ ] Point coverage badge to maintenance branch
  * [ ] Point CI badge to maintenance branch
  * [ ] Remove pointer to "current stable" branches
* [ ] Update the [system requirements listing](https://ledgersmb.org/content/system-requirements)
* [ ] Update [list of supported Perl versions](https://ledgersmb.org/faq/which-versions-perl-does-ledgersmb-support)
* [ ] Update [list of supported PostgreSQL versions](https://ledgersmb.org/faq/installation/what-versions-postgresql-does-ledgersmb-support)
* [ ] Add a taxonomy term to the `Release` taxonomy for the current and upcoming releases
* [ ] Copy/Update documentation; add 'Draft' topic!!
  * [ ] [Preparing LedgerSMB XXX for first use](https://ledgersmb.org/content/preparing-ledgersmb-17-first-use)
  * [ ] Create [installation documentation](https://ledgersmb.org/content/installing-ledgersmb-17) on ledgersmb.org
  * [ ] Create [upgrade documentation](https://ledgersmb.org/content/upgrade-ledgersmb-17-16-or-15) on ledgersmb.org
  * [ ] https://ledgersmb.org/content/documentation
  * [ ] https://ledgersmb.org/content/using-docker-develop-ledgersmb
* [ ] Update https://ledgersmb.org/system-requirements to include the new release - check requirements table.
* [ ] Create [release notes](https://ledgersmb.org/content/16-release-notes) on ledgersmb.org (mark 'Draft'!)
* [ ] Review installation instructions on ledgersmb.org
  * [ ] Including https://ledgersmb.org/content/installing-ledgersmb
* [ ] Review README.md

## Release steps

* [ ] Update Docker image README.md
  * [ ] Docker README listing available tags (on all branches!)
* [ ] Change ledgersmb-docker default branch to the new stable release branch (this causes the 'latest' tag in docker to move to the new branch!)
* [ ] Set the release date of the minor series in Changelog
* [ ] Execute the final release procedure as with a regular (patch) release (but use a different release announcement text)

## Post release steps:

* [ ] Add/update the release date
  * [ ] On the supported items page: https://ledgersmb.org/faq/which-versions-do-you-support
* [ ] Include the new release on the ledgersmb.org front page
* [ ] Update https://ledgersmb.org/content/download to include the new release (and remove the old!)
      Update: "current stable release line is X.X."  Update download, install, update url, "Docker Images" and 
      "Keeping up with the latest developments" sections.
* [ ] Remove the 'draft' topic from:
  * [ ] [Preparing LedgerSMB XXX for first use](https://ledgersmb.org/content/preparing-ledgersmb-17-first-use)
  * [ ] [installation documentation](https://ledgersmb.org/content/installing-ledgersmb-17) on ledgersmb.org
  * [ ] [upgrade documentation](https://ledgersmb.org/content/upgrade-ledgersmb-17-16-or-15) on ledgersmb.org
  * [ ] https://ledgersmb.org/content/documentation
  * [ ] https://ledgersmb.org/content/using-docker-develop-ledgersmb
  * [ ] the release notes
* [ ] Update the roadmap on ledgersmb.org
* [ ] Update listing of available tags on Docker Hub (edit the image description directly on the docker hub repository page)
* [ ] Update the version number of the 'master' branch:
  * [ ] Update README.md reference to 'prepare for first use'
* [ ] Update ledgersmb/.github repository README.md docker compose file branch reference
* [ ] Update the wikipedia page to include the new release (and remove the old!)
* [ ] Update the screenshots
  * [ ] ledgersmb.org
  * [ ] [Preparing LedgerSMB XXX for first use](https://ledgersmb.org/content/preparing-ledgersmb-17-first-use)

