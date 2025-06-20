@weasel
Feature: Reconciliation
  As a LedgerSMB user I want to be able to create a new bank reconciliation
  report, save it, review it and delete it.

Background:
  Given a standard test company
    And a logged in admin user

Scenario: Create new reconciliation report, update and save.
This scenario tests reconciling an account for the first time, where there
is no previous report from which to get an opening balance.
 Given the following GL transaction posted on 2017-11-01:
     | accno   |  debit_bc |  credit_bc  |
     | 1065    |   200.00  |             |
     | 1060    |           |   200.00    |
 And the following GL transaction posted on 2017-11-02:
     | accno   |  debit_bc |  credit_bc  |
     | 1060    |  1000.00  |             |
     | 2620    |           |  1000.00    |
  When I navigate the menu and select the item at "Cash & Banking > Reconciliation"
  Then I should see the New Reconciliation Report screen.
  When I select "1060 Checking Account" from the drop down "Account"
   And I enter "1000.00" into "Statement Balance"
   And I enter "2018-01-01" into "Statement Date"
   And I press "Create New Report"
  Then I should see the Reconciliation Report screen
   And I should see these Reconciliation Report headings:
       | Heading                     |              Contents |
       | Account                     | 1060 Checking Account |
       | Statement Date              |            2018-01-01 |
       | Beginning Statement Balance |                  0.00 |
       | Ending Statement Balance    |               1000.00 |
       | Variance                    |              -1000.00 |
       | Less Outstanding Checks     |               -800.00 |
       | Report Generated By         |            $$the user |
   And I expect the Cleared Transactions totals to be:
       | Books Debits | Books Credits |
       |         0.00 |          0.00 |
   And I expect the Outstanding Transactions totals to be:
       | Our Debits | Our Credits |
       |    1000.00 |      200.00 |
  When I press "Select All"
  Then I should see these Reconciliation Report headings:
       | Heading                     |              Contents |
       | Account                     | 1060 Checking Account |
       | Statement Date              |            2018-01-01 |
       | Beginning Statement Balance |                  0.00 |
       | Ending Statement Balance    |               1000.00 |
       | Variance                    |               -200.00 |
       | Less Outstanding Checks     |                  0.00 |
       | Report Generated By         |            $$the user |
   And I expect the Cleared Transactions totals to be:
       | Books Debits | Books Credits |
       |      1000.00 |        200.00 |
   And I expect the Outstanding Transactions section to be absent
  When I change the "Ending Statement Balance" to "800.00"
   And I update the page
  Then I should see these Reconciliation Report headings:
       | Heading                     |              Contents |
       | Account                     | 1060 Checking Account |
       | Statement Date              |            2018-01-01 |
       | Beginning Statement Balance |                  0.00 |
       | Ending Statement Balance    |                800.00 |
       | Variance                    |                  0.00 |
       | Less Outstanding Checks     |                  0.00 |
       | Report Generated By         |            $$the user |
  When I press "Save"
  Then I should see the Search Reconciliation Reports screen

Scenario: Search for reconciliation report and delete it,
 Given reconciliation reports with these properties:
       | Account Number | Statement Date | Statement Balance | Approved | Submitted |
       | 1060           | 2018-01-01     | 101.00            | no       | no        |
  When I navigate the menu and select the item at "Cash & Banking > Reports > Reconciliation"
  Then I should see the Search Reconciliation Reports screen
  When I press "Search"
  Then I should see the Reconciliation Search Report screen
   And I expect the report to contain 1 row
   And I expect the 'Account' report column to contain '1060 Checking Account' for Statement Date '2018-01-01'
   And I expect the 'Statement Balance' report column to contain '101.00' for Statement Date '2018-01-01'
   And I expect the 'Approved' report column to contain '' for Statement Date '2018-01-01'
   And I expect the 'Submitted' report column to contain '' for Statement Date '2018-01-01'
   And I expect the 'Entered By' report column to contain '$$the user' for Statement Date '2018-01-01'
   And I expect the 'Approved By' report column to contain '' for Statement Date '2018-01-01'
  When I click the "2018-01-01" link
  Then I should see the Reconciliation Report screen
  When I press "Delete"
  Then I should see the Search Reconciliation Reports screen
  When I press "Search"
  Then I should see the Reconciliation Search Report screen
   And I expect the report to contain 0 rows


Scenario: Update with new GL transaction on a new line
  Given an existing and empty reconciliation report
   When I open the reconciliation report
    And I enter a GL transaction with a balance of 100.00 into the reconciliation period
    And I update the screen
   Then I expect the reconciliation report to show one uncleared line

Scenario: Update with new AR transaction on a new line
  Given an existing and empty reconciliation report
   When I open the reconciliation report
    And I enter an AR payment with a balance of 100.00 into the reconciliation period
    And I update the screen
   Then I expect the reconciliation report to show one uncleared line

Scenario: Update with new GL transaction on an existing line
  Given an existing reconciliation report
    And a GL transaction with a balance of 100.00 into the reconciliation period
   When I open the reconciliation report
    And I mark all lines cleared
    And I enter a GL transaction with a balance of 50.00 into the reconciliation period
   Then I expect the reconciliation report to show one uncleared line

