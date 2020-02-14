@weasel
Feature: Add and delete new account
  As a LedgerSMB user I want to be able to add a new account and see that
  this new account is listed in the chart of accounts. I then want to delete
  the newly created account.

Background:
  Given a standard test company
    And a logged in admin user

Scenario: Add a new account
  When I navigate the menu and select the item at "General Journal > Chart of Accounts"
  Then I should see the Chart of Accounts screen
   And I expect the report to contain 78 rows
  When I press "Create Account"
   And I wait for the page to load
  Then I should see the Account screen
  When I enter "T0001" into "Account Number"
   And I enter "New Account" into "Description"
   And I press "Save"
   And I wait for the page to load
  Then I should see the Account screen
  When I navigate the menu and select the item at "General Journal > Chart of Accounts"
  Then I should see the Chart of Accounts screen
   And I expect the report to contain 79 rows

Scenario: Delete the account from the chart of accounts
 Given a gl account with these properties:
    | Property       | Value                |
    | Account Number | T0001                |
    | Description    | New Account          |
    | Category       | A                    |
    | Heading        | 1000--CURRENT ASSETS |
  When I navigate the menu and select the item at "General Journal > Chart of Accounts"
  Then I should see the Chart of Accounts screen
   And I expect the report to contain 79 rows
   And I expect the 'Description' report column to contain 'New Account' for Account Number 'T0001'
  When I click "[Delete]" for the row with Account Number "T0001"
   And I wait for the page to load
  Then I should see the Chart of Accounts screen
   And I expect the report to contain 78 rows
