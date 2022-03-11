
# LedgerSMB

Small and Medium business accounting and ERP


[![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/795/badge)](https://bestpractices.coreinfrastructure.org/projects/795)
[![CI](https://github.com/ledgersmb/LedgerSMB/actions/workflows/main.yml/badge.svg)](https://github.com/ledgersmb/LedgerSMB/actions/workflows/main.yml)
[![Lgtm total alerts](https://img.shields.io/lgtm/alerts/g/ledgersmb/LedgerSMB.svg?logo=lgtm&logoWidth=18)](https://lgtm.com/projects/g/ledgersmb/LedgerSMB/alerts/)
[![GPLv2 Licence](https://badges.frapsoft.com/os/gpl/gpl.png?v=103)](https://opensource.org/licenses/GPL-2.0/)
[![Coverage Status](https://coveralls.io/repos/github/ledgersmb/LedgerSMB/badge.svg?branch=master)](https://coveralls.io/github/ledgersmb/LedgerSMB?branch=master)
[![Docker](https://img.shields.io/docker/pulls/ledgersmb/ledgersmb.svg)](https://hub.docker.com/r/ledgersmb/ledgersmb/)
[![Language grade: JavaScript](https://img.shields.io/lgtm/grade/javascript/g/ledgersmb/LedgerSMB.svg?logo=lgtm&logoWidth=18)](https://lgtm.com/projects/g/ledgersmb/LedgerSMB/context:javascript)
[![Mentioned in Awesome <awesome-selfhosted>](https://awesome.re/mentioned-badge.svg)](https://github.com/Kickball/awesome-selfhosted#enterprise-resource-planning)
[![pull requests](https://www.oselvar.com/api/badge?label=pull+requests&csvUrl=https%3A%2F%2Fraw.githubusercontent.com%2Fledgersmb%2Fledgersmb-oselvar%2Fmain%2Fdata%2Fledgersmb%2FLedgerSMB%2FpullRequests.csv)](https://www.oselvar.com/github/ledgersmb/ledgersmb-oselvar/main/ledgersmb/LedgerSMB "3rd quartile cycle time")
[![issues](https://www.oselvar.com/api/badge?label=issues&csvUrl=https%3A%2F%2Fraw.githubusercontent.com%2Fledgersmb%2Fledgersmb-oselvar%2Fmain%2Fdata%2Fledgersmb%2FLedgerSMB%2Fissues.csv)](https://www.oselvar.com/github/ledgersmb/ledgersmb-oselvar/main/ledgersmb/LedgerSMB "3rd quartile cycle time")



# DESCRIPTION

LedgerSMB is a free web-based double-entry accounting system, featuring
quotation, ordering, invoicing, projects, timecards, inventory management,
shipping and more ...

Directly send orders and invoices from the built-in e-mail function to your
customers or RFQs (request for quotation) to your vendors with PDF attachments,
from anywhere in the world with the browser-based UI.

With its data stored in the enterprise-strength `PostgreSQL` open source
database system, the system is known to operate smoothly for businesses with
thousands of transactions per week.

Customer visible output is fully customizable in templates, allowing easy and
fast customization. Supported output formats are PDF, CSV, HTML, ODF and more.


# System requirements

Note that these are the system requirements for LedgerSMB 1.10.0-dev, the current
development version. Please check the system requirements for [the 1.8 old stable
version](https://github.com/ledgersmb/LedgerSMB/tree/1.8#system-requirements)
and [the 1.9 version](https://github.com/ledgersmb/LedgerSMB/tree/1.9#system-requirements).

## Server

* `Perl 5.32+`
* `PostgreSQL 13+`
* Web server (e.g. `nginx`, `Apache`, `lighttpd`, `Varnish`)

The web server is only required for production installs;
for evaluation purposes a simpler setup can be used, as detailed
below.

## Client

The tables below show the browsers currently supported, their earliest date
and a range of versions.


### Desktop

| Browser Name        | Earliest | Versions                                    |
| ------------------- |:--------:|:------------------------------------------- |
| Chrome              | 2017-09  | 61-81, 83-99                                |
| Edge                | 2017-10  | 16-18, 79-81, 83-98                         |
| Firefox             | 2018-05  | 60-97                                       |
| Opera               | 2017-09  | 48-58, 60, 62-83                            |
| Safari              | 2017-09  | 11, 11.1, 12, 12.1, 13, 13.1, 14, 14.1,     |
|                     |          | 15, 15.1, 15.2-15.3                         |

### Mobile

| Browser Name        | Earliest | Versions                                    |
| ------------------- |:--------:|:------------------------------------------- |
| Chrome for Android  | 2022-02  | 98                                          |
| Firefox for Android | 2022-01  | 96                                          |
| Android Browser     | 2022-02  | 98                                          |
| Safari on iOS       | 2017-09  | 11.0-11.4, 12.0-12.5, 13.0-13.7,            |
|                     |          | 14.0-14.8, 15.0-15.3                        |
| Opera Mobile        | 2021-02  | 64                                          |
| Samsung Internet    | 2018-12  | 8.2, 9.2, 10.1, 11.1-11.2, 12.0, 13.0,      |
|                     |          | 14.0, 15.0, 16.0                            |


**Note**: Earliest dates and versions come from http://caniuse.com. Only the most
recent data is available for Mobile browsers other than Safari, because they
are pushed out to the devices as soon as they are releases, so the number of
devices running old browsers is negligible.

# Quick start

For from-tarball installation instructions, see https://ledgersmb.org/content/installing-ledgersmb-19

## Installation

This instruction assumes you have [Docker](https://docs.docker.com/get-docker/)
installed as well as [docker-compose](https://github.com/docker/compose#where-to-get-docker-compose).

```bash
 $ wget https://raw.githubusercontent.com/ledgersmb/ledgersmb-docker/1.9/docker-compose.yml
 $ docker-compose up -d
```

This creates both the LedgerSMB image and a database image with a persistent
database. Note that this setup is **not** sufficient for production purposes
because it lacks secure connections to protect your users' passwords.

## Next steps

The system is installed and should be available for evaluation through

* `http://localhost:5762/setup.pl`  
  Creation and privileged management of company databases
* `http://localhost:5762/login.pl`  
  Normal login for the application

The system is ready for [preparation for first
use](https://ledgersmb.org/content/preparing-ledgersmb-19-first-use).


**NOTE:** This setup does not use a webserver like nginx or Apache. Setups which
do include one will yield a faster user experience due to (much) faster page
load times and web request responses. For production setups, please consider
adding a webserver to the installation.

# Project information

Web site: [https://ledgersmb.org/](https://ledgersmb.org)

Repository: [https://github.com/ledgersmb/LedgerSMB](https://github.com/ledgersmb/LedgerSMB)

Security vulnerability reports: [https://ledgersmb.org/contact/security_report](https://ledgersmb.org/contact/security_report)

Live chat:

* Matrix: [#ledgersmb:matrix.org](https://app.element.io/#/room/#ledgersmb:matrix.org)


Mailing lists:

* [Announcements](https://lists.ledgersmb.org/postorius/lists/announce.lists.ledgersmb.org/)
* [User Discussion](https://lists.ledgersmb.org/postorius/lists/users.lists.ledgersmb.org/)
* [Developer Discussion](https://lists.ledgersmb.org/postorius/lists/devel.lists.ledgersmb.org/)

Mailing list archives: [https://archive.ledgersmb.org](https://archive.ledgersmb.org)


## Project contributors

Source code contributors can be found in the project's `Git` commit history
as well as in the CONTRIBUTORS file in the repository root.

Translation contributions can be found in the project's `Git` commit history
as well as in the `Transifex` project Timeline.


# Copyright

```plain
Copyright (c) 2006 - 2021 The LedgerSMB Project contributors
Copyright (c) 1999 - 2006 DWS Systems Inc (under the name SQL Ledger)
```

# License

[`GPLv2`](https://opensource.org/licenses/GPL-2.0)
