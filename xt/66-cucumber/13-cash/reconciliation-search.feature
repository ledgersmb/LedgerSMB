@weasel
Feature: Reconciliation Report Search
  As a LedgerSMB user I want to be able to search for reconciliation
  reports according to various attributes.

Background:
  Given a standard test company named "standard-recon-test"
    And a logged in admin user
    And reconciliation reports with these properties:
       | Account Number | Statement Date | Statement Balance | Approved | Submitted |
       | 1060           | 2018-01-01     | 1000.00           | no       | no        |
       | 1060           | 2018-02-01     | 1000.01           | no       | yes       |
       | 1060           | 2018-03-01     | 1000.02           | yes      | yes       |
       | 1065           | 2018-01-01     | 100.00            | no       | no        |

Scenario: Default search with no filter
 When I navigate the menu and select the item at "Cash & Banking > Reports > Reconciliation"
  Then I should see the Search Reconciliation Reports screen
  When I press "Search"
  Then I should see the Reconciliation Search Report screen
   And I expect the report to contain 4 rows
   And I expect the 'Account' report column to contain '1060 Checking Account' for Statement Date '2018-02-01'
   And I expect the 'Statement Balance' report column to contain '1000.01' for Statement Date '2018-02-01'
   And I expect the 'Approved' report column to contain '' for Statement Date '2018-02-01'
   And I expect the 'Submitted' report column to contain '✓' for Statement Date '2018-02-01'
   And I expect the 'Account' report column to contain '1060 Checking Account' for Statement Date '2018-03-01'
   And I expect the 'Statement Balance' report column to contain '1000.02' for Statement Date '2018-03-01'
   And I expect the 'Approved' report column to contain '✓' for Statement Date '2018-03-01'
   And I expect the 'Submitted' report column to contain '✓' for Statement Date '2018-03-01'
   And I expect the 'Statement Date' report column to contain '2018-01-01' for Account '1065 Petty Cash'
   And I expect the 'Statement Balance' report column to contain '100.00' for Account '1065 Petty Cash'
   And I expect the 'Approved' report column to contain '' for Account '1065 Petty Cash'
   And I expect the 'Submitted' report column to contain '' for Account '1065 Petty Cash'

Scenario: Filter by "Statement Date From"
 When I navigate the menu and select the item at "Cash & Banking > Reports > Reconciliation"
  Then I should see the Search Reconciliation Reports screen
  When I enter "2018-02-01" into "Statement Date From"
   And I press "Search"
  Then I should see the Reconciliation Search Report screen
   And I should see these headings:
       | Heading             | Contents               |
       | Report Name         | Reconciliation Reports |
       | Company             | standard-recon-test             |
       | From Date           | 2018-02-01             |
       | To Date             |                        |
       | From Amount         |                        |
       | To Amount           |                        |
   And I expect the report to contain 2 rows
   And I expect the 'Account' report column to contain '1060 Checking Account' for Statement Date '2018-02-01'
   And I expect the 'Account' report column to contain '1060 Checking Account' for Statement Date '2018-03-01'

Scenario: Filter by "Statement Date To"
 When I navigate the menu and select the item at "Cash & Banking > Reports > Reconciliation"
  Then I should see the Search Reconciliation Reports screen
  When I enter "2018-02-01" into "Statement Date To"
   And I press "Search"
  Then I should see the Reconciliation Search Report screen
   And I should see these headings:
       | Heading             | Contents               |
       | Report Name         | Reconciliation Reports |
       | Company             | standard-recon-test             |
       | From Date           |                        |
       | To Date             | 2018-02-01             |
       | From Amount         |                        |
       | To Amount           |                        |
   And I expect the report to contain 3 rows
   And I expect the 'Account' report column to contain '1060 Checking Account' for Statement Date '2018-02-01'

Scenario: Filter by "Amount From"
 When I navigate the menu and select the item at "Cash & Banking > Reports > Reconciliation"
  Then I should see the Search Reconciliation Reports screen
  When I enter "1000.01" into "Amount From"
   And I press "Search"
  Then I should see the Reconciliation Search Report screen
       | Heading             | Contents               |
       | Report Name         | Reconciliation Reports |
       | Company             | standard-recon-test             |
       | From Date           |                        |
       | To Date             |                        |
       | From Amount         | 1000.01                |
       | To Amount           |                        |
   And I expect the report to contain 2 rows
   And I expect the 'Account' report column to contain '1060 Checking Account' for Statement Date '2018-02-01'
   And I expect the 'Account' report column to contain '1060 Checking Account' for Statement Date '2018-03-01'

Scenario: Filter by "Amount To"
 When I navigate the menu and select the item at "Cash & Banking > Reports > Reconciliation"
  Then I should see the Search Reconciliation Reports screen
  When I enter "100.00" into "Amount To"
   And I press "Search"
  Then I should see the Reconciliation Search Report screen
       | Heading             | Contents               |
       | Report Name         | Reconciliation Reports |
       | Company             | standard-recon-test             |
       | From Date           |                        |
       | To Date             |                        |
       | From Amount         |                        |
       | To Amount           | 1000.01                |
   And I expect the report to contain 1 row
   And I expect the 'Account' report column to contain '1065 Petty Cash' for Statement Date '2018-01-01'

Scenario: Filter by "Account"
 When I navigate the menu and select the item at "Cash & Banking > Reports > Reconciliation"
  Then I should see the Search Reconciliation Reports screen
  When I select "1065 Petty Cash" from the drop down "Account"
   And I press "Search"
  Then I should see the Reconciliation Search Report screen
   And I expect the report to contain 1 row
   And I expect the 'Account' report column to contain '1065 Petty Cash' for Statement Date '2018-01-01'

Scenario: Filter by "Submission Status" is "Submitted"
 When I navigate the menu and select the item at "Cash & Banking > Reports > Reconciliation"
  Then I should see the Search Reconciliation Reports screen
  When I select "Submitted" from the drop down "Submission Status"
   And I press "Search"
  Then I should see the Reconciliation Search Report screen
   And I expect the report to contain 2 rows
   And I expect the 'Account' report column to contain '1060 Checking Account' for Statement Date '2018-02-01'
   And I expect the 'Account' report column to contain '1060 Checking Account' for Statement Date '2018-03-01'

Scenario: Filter by "Submission Status" is "Not Submitted"
 When I navigate the menu and select the item at "Cash & Banking > Reports > Reconciliation"
  Then I should see the Search Reconciliation Reports screen
  When I select "Not Submitted" from the drop down "Submission Status"
   And I press "Search"
  Then I should see the Reconciliation Search Report screen
   And I expect the report to contain 2 rows
   And I expect the 'Statement Date' report column to contain '2018-01-01' for Account '1060 Checking Account'
   And I expect the 'Statement Date' report column to contain '2018-01-01' for Account '1065 Petty Cash'

Scenario: Filter by "Approved Status" is "Approved"
 When I navigate the menu and select the item at "Cash & Banking > Reports > Reconciliation"
  Then I should see the Search Reconciliation Reports screen
  When I select "Approved" from the drop down "Approval Status"
   And I press "Search"
  Then I should see the Reconciliation Search Report screen
   And I expect the report to contain 1 row
   And I expect the 'Statement Date' report column to contain '2018-03-01' for Account '1060 Checking Account'

Scenario: Filter by "Approved Status" is "Not Approved"
 When I navigate the menu and select the item at "Cash & Banking > Reports > Reconciliation"
  Then I should see the Search Reconciliation Reports screen
  When I select "Not Approved" from the drop down "Approval Status"
   And I press "Search"
  Then I should see the Reconciliation Search Report screen
   And I expect the report to contain 3 rows
   And I expect the 'Statement Date' report column to contain '2018-01-01' for Statement Balance '100.00'
   And I expect the 'Statement Date' report column to contain '2018-01-01' for Statement Balance '1000.00'
   And I expect the 'Statement Date' report column to contain '2018-02-01' for Statement Balance '1000.01'

