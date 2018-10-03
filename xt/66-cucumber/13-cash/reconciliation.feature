@weasel
Feature: Reconciliation
  As a LedgerSMB user I want to be able to create a new bank reconciliation
  report.

Background:
  Given a standard test company
    And a logged in admin user

Scenario: Create new reconciliation report
  When I navigate the menu and select the item at "Cash > Reconciliation"
  Then I should see the New Reconciliation Report screen.
  When I select "1060 Checking Account" from the drop down "Account"
   And I enter "0.00" into "Statement Balance"
   And I enter "2018-01-01" into "To Date"
   And I press "Create New Report"
   And I wait for the page to load
  Then I should see the Reconciliation Report screen

