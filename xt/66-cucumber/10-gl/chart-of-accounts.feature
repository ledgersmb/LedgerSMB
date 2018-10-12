@one-db @weasel
Feature: Chart of Accounts
  As a LedgerSMB user I want to be able to view the chart of accounts
  and change the description of an account.

Background:
  Given a standard test company
    And a logged in admin user

Scenario: View the chart of accounts and change the description of an account
  When I navigate the menu and select the item at "General Journal > Chart of Accounts"
  Then I should see the Chart of Accounts screen
   And I expect the report to contain 78 rows
   And I expect the 'Description' report column to contain 'Checking Account' for Account Number '1060'
  When I click Account Number "1060"
  Then I should see the Account screen
  When I enter "Cheque Account" into "Description"
   And I press "Save"
  Then I should see the Account screen
  When I navigate the menu and select the item at "General Journal > Chart of Accounts"
  Then I should see the Chart of Accounts screen
   And I expect the report to contain 78 rows
   And I expect the 'Description' report column to contain 'Cheque Account' for Account Number '1060'

Scenario: View the chart of accounts and change the description of an account heading
  When I navigate the menu and select the item at "General Journal > Chart of Accounts"
  Then I should see the Chart of Accounts screen
   And I expect the report to contain 78 rows
   And I expect the 'Description' report column to contain 'CURRENT ASSETS' for Account Number '1000'
  When I click Account Number "1000"
  Then I should see the Account screen
  When I enter "Assets" into "Description"
   And I press "Save"
  Then I should see the Account screen
  When I navigate the menu and select the item at "General Journal > Chart of Accounts"
  Then I should see the Chart of Accounts screen
   And I expect the report to contain 78 rows
   And I expect the 'Description' report column to contain 'Assets' for Account Number '1000'
