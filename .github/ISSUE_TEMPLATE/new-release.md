---
name: New release
about: Tracking the progress on preparing a new release branch
---

# Release check list 

> Work in progress. Difference between major and minor release should be tagged

When working toward a non-patch release, it's practical to use an issue to track the progress of the release. Copying the following check list as an initial proposal helps structure the process. A good time to start with this check list is after branching the stable branch off of `master` as that marks the last phase of stabilization.


# At branch time (pre-beta)

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
  * [ ] In bin/ledgersmb-server.psgi adjust the version-check regex and the cookie name in the `__DATA__` section
  * [ ] In locale/LedgerSMB.pot, adjust the Project-Id
  * [ ] In t/data/Is_LSMB_running.html, increase the version text
  * [ ] Update the supported items page: https://ledgersmb.org/faq/which-versions-do-you-support
  * [ ] Update README.md reference to `docker-compose` file (both on the branch and on master)
  * [ ] Create a new docker-compose branch
  * [ ] Update the cookie's version number in the default config files `doc/conf/ledgersmb.yaml.*`
  * [ ] Add the new version to renovate.json baseBranches

# General preparation

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
* [ ] Update Docker image README.md
  * [ ] Docker README listing available tags (on all branches!)
* [ ] Update the [system requirements listing](https://ledgersmb.org/content/system-requirements)
* [ ] Update [list of supported Perl versions](https://ledgersmb.org/faq/which-versions-perl-does-ledgersmb-support)
* [ ] Update [list of supported PostgreSQL versions](https://ledgersmb.org/faq/installation/what-versions-postgresql-does-ledgersmb-support)
* [ ] Add a taxonomy term to the `Release` taxonomy for the current and upcoming releases
* [ ] Copy/Update documentation
  * [ ] [Preparing LedgerSMB XXX for first use](https://ledgersmb.org/content/preparing-ledgersmb-17-first-use)
  * [ ] Create [installation documentation](https://ledgersmb.org/content/installing-ledgersmb-17) on ledgersmb.org
  * [ ] Create [upgrade documentation](https://ledgersmb.org/content/upgrade-ledgersmb-17-16-or-15) on ledgersmb.org
  * [ ] https://ledgersmb.org/content/documentation
  * [ ] https://ledgersmb.org/content/using-docker-develop-ledgersmb
* [ ] Create [release notes](https://ledgersmb.org/content/16-release-notes) on ledgersmb.org

# Just before release

* [ ] Change ledgersmb-docker default branch to the new stable release branch (this causes the 'latest' tag in docker to move to the new branch!)
* [ ] Include the new release on the ledgersmb.org front page
* [ ] Update the roadmap on ledgersmb.org
* [ ] Review installation instructions on ledgersmb.org
  * [ ] Including https://ledgersmb.org/content/installing-ledgersmb
* [ ] Review README.md
* [ ] Add/update the release date
  * [ ] Update the release date of the minor series in Changelog
  * [ ] On the supported items page: https://ledgersmb.org/faq/which-versions-do-you-support
* [ ] Remove the 'draft' topic from:
  * [ ] [Preparing LedgerSMB XXX for first use](https://ledgersmb.org/content/preparing-ledgersmb-17-first-use)
  * [ ] Create [installation documentation](https://ledgersmb.org/content/installing-ledgersmb-17) on ledgersmb.org
  * [ ] Create [upgrade documentation](https://ledgersmb.org/content/upgrade-ledgersmb-17-16-or-15) on ledgersmb.org
  * [ ] https://ledgersmb.org/content/documentation
  * [ ] https://ledgersmb.org/content/using-docker-develop-ledgersmb
  * [ ] the release notes

# Last step:

* [ ] Update listing of available tags on Docker Hub (edit the image description directly on the docker hub repository page)
* [ ] Execute the final release procedure as with a regular (patch) release (but use a different release announcement text)
* [ ] Update https://ledgersmb.org/content/download to include the new release (and remove the old!)
      Update: "current stable release line is X.X."  Update download, install, update url, "Docker Images" and 
      "Keeping up with the latest developments" sections.
* [ ] Update https://ledgersmb.org/system-requirements to include the new release - check requirements table.
* [ ] Update the wikipedia page to include the new release (and remove the old!)

# Post release steps:

* [ ] Remove "Draft" status from 1.9 related items on ledgersmb.org
* [ ] Update the version number of the 'master' branch:
  * [ ] Update README.md reference to 'prepare for first use'
* [ ] Update the screenshots
  * [ ] ledgersmb.org

