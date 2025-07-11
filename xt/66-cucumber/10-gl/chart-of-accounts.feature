@weasel
Feature: Chart of Accounts
  As a LedgerSMB user I want to be able to view the chart of accounts
  and change the properties of an account and a heading. I want to be able
  to use an existing account as the basis for creating a new account.

Background:
  Given a standard test company
    And a logged in admin user

Scenario: View the chart of accounts and change every property of an account
 Given GIFI entries with these properties:
       | GIFI  | Description |
       | 1234  | Test GIFI   |
       | 1235  | Test GIFI 2 |
   And Custom Flags with these properties:
       | Description    | Summary |
       | Custom-Flag 1  | no      |
       | Custom-Flag 2  | no      |
       | Custom Summary | yes     |
  When I navigate the menu and select the item at "General Journal > Chart of Accounts"
  Then I should see the Chart of Accounts screen
   And I expect the report to contain 78 rows
   And I expect the 'Description' report column to contain 'Allowance for doubtful accounts' for Account Number '1205'
  When I click Account Number "1205"
  Then I should see the Account screen
   And I expect the "Description" field to contain "Allowance for doubtful accounts"
   And I expect "1000--CURRENT ASSETS" to be selected for "Heading"
   And I expect "Asset" to be selected for "Account Type"
   And I expect to see 0 selected checkboxes in "Options"
   And I expect to see 0 selected checkboxes in "Include in drop-down menus"
  When I enter "Chairs" into "Description"
   And I select "1000--CURRENT ASSETS" from the drop down "Heading"
   And I select "1234--Test GIFI" from the drop down "GIFI"
   And I select "Equity" from the drop down "Account Type"
   And I select every checkbox in "Options"
   And I select every checkbox in "Custom Flags"
   And I select every checkbox in "Include in drop-down menus"
   And I save the page
  Then I should see the Account screen
   And I expect the "Obsolete" checkbox to be selected
   And I expect the "Description" field to contain "Chairs"
   And I expect "1000--CURRENT ASSETS" to be selected for "Heading"
   And I expect "1234--Test GIFI" to be selected for "GIFI"
   And I expect "Equity" to be selected for "Account Type"
   And I expect to see 4 selected checkboxes in "Options"
   And I expect to see 2 selected checkboxes in "Custom Flags"
   And I expect to see 22 selected checkboxes in "Include in drop-down menus"
  When I select "Custom Summary" from the drop down "Summary account for"
   And I deselect every checkbox in "Custom Flags"
   And I deselect every checkbox in "Include in drop-down menus"
   And I save the page
  Then I expect to see 0 selected checkboxes in "Include in drop-down menus"
  Then I expect to see 0 selected checkboxes in "Custom Flags"
   And I expect "Custom Summary" to be selected for "Summary account for"
  When I select "Inventory" from the drop down "Summary account for"
   And I save the page
  Then I expect "Inventory" to be selected for "Summary account for"
  When I navigate the menu and select the item at "General Journal > Chart of Accounts"
  Then I should see the Chart of Accounts screen
   And I expect the report to contain 78 rows
   And I expect the 'Description' report column to contain 'Chairs' for Account Number '1205'

Scenario: View the chart of accounts and change the description of an account heading
  When I navigate the menu and select the item at "General Journal > Chart of Accounts"
  Then I should see the Chart of Accounts screen
   And I expect the report to contain 78 rows
   And I expect the 'Description' report column to contain 'CURRENT ASSETS' for Account Number '1000'
  When I click Account Number "1000"
  Then I should see the Account screen
   And I expect the "Description" field to contain "CURRENT ASSETS"
  When I enter "Assets" into "Description"
   And I save the page
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
   And I save the page as new
  Then I should see the Account screen
  When I navigate the menu and select the item at "General Journal > Chart of Accounts"
  Then I should see the Chart of Accounts screen
   And I expect the report to contain 79 rows
   And I expect the 'Description' report column to contain 'New Account' for Account Number 'TEST-1'

Scenario: Create a new heading based on an existing heading
  When I navigate the menu and select the item at "General Journal > Chart of Accounts"
  Then I should see the Chart of Accounts screen
   And I expect the report to contain 78 rows
  When I click Account Number "1000"
  Then I should see the Account screen
  When I select the "Heading" tab
   And I enter "TEST-2" into "Account Number"
   And I enter "New Heading" into "Description"
   And I save the page as new
  Then I should see the Account screen
  When I navigate the menu and select the item at "General Journal > Chart of Accounts"
  Then I should see the Chart of Accounts screen
   And I expect the report to contain 79 rows
   And I expect the 'Description' report column to contain 'New Heading' for Account Number 'TEST-2'

