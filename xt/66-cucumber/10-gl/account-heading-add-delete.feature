@weasel
Feature: Add and delete new account heading
  As a LedgerSMB user I want to be able to add a new account heading and see
  that this new heading is listed in the chart of accounts. I then want to
  delete the newly created heading.

Background:
  Given a standard test company
    And a logged in admin user

Scenario: Add a new account
  When I navigate the menu and select the item at "General Journal > Chart of Accounts"
  Then I should see the Chart of Accounts screen
   And I expect the report to contain 78 rows
  When I press "Create Heading"
  Then I should see the Account screen
  When I enter "H0001" into "Account Number"
   And I enter "New Heading" into "Description"
   And I press "Save"
  Then I should see the Account screen

Scenario: Delete the account from the chart of accounts
  When I navigate the menu and select the item at "General Journal > Chart of Accounts"
  Then I should see the Chart of Accounts screen
   And I expect the report to contain 79 rows
   And I expect the 'Description' report column to contain 'New Heading' for Account Number 'H0001'
  When I click "[Delete]" for the row with Account Number "H0001"
   And I wait for the page to load
  Then I should see the Chart of Accounts screen
   And I expect the report to contain 78 rows
