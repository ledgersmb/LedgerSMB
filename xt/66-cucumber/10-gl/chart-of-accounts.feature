@weasel
Feature: Chart of Accounts
  As a LedgerSMB user I want to be able to view the chart of accounts
  and change the description of an account and a heading. I want to be able
  to use an existing account as the basis for creating a new account.

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
   And I expect the "Description" field to contain "Checking Account"
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
   And I expect the "Description" field to contain "CURRENT ASSETS"
  When I enter "Assets" into "Description"
   And I press "Save"
  Then I should see the Account screen
  When I navigate the menu and select the item at "General Journal > Chart of Accounts"
  Then I should see the Chart of Accounts screen
   And I expect the report to contain 78 rows
   And I expect the 'Description' report column to contain 'Assets' for Account Number '1000'

Scenario: Create a new account based on an existing account
  When I navigate the menu and select the item at "General Journal > Chart of Accounts"
  Then I should see the Chart of Accounts screen
   And I expect the report to contain 78 rows
  When I click Account Number "1060"
  Then I should see the Account screen
  When I select the "Account" tab
   And I enter "TEST-1" into "Account Number"
   And I enter "New Account" into "Description"
   And I press "Save as new"
  Then I should see the Account screen
  When I navigate the menu and select the item at "General Journal > Chart of Accounts"
  Then I should see the Chart of Accounts screen
   And I expect the report to contain 79 rows
   And I expect the 'Description' report column to contain 'New Account' for Account Number 'TEST-1'

Scenario: Create a new heading based on an existing heading
  When I navigate the menu and select the item at "General Journal > Chart of Accounts"
  Then I should see the Chart of Accounts screen
   And I expect the report to contain 79 rows
  When I click Account Number "1000"
  Then I should see the Account screen
  When I select the "Heading" tab
   And I enter "TEST-2" into "Account Number"
   And I enter "New Heading" into "Description"
   And I press "Save as new"
  Then I should see the Account screen
  When I navigate the menu and select the item at "General Journal > Chart of Accounts"
  Then I should see the Chart of Accounts screen
   And I expect the report to contain 80 rows
   And I expect the 'Description' report column to contain 'New Heading' for Account Number 'TEST-2'

