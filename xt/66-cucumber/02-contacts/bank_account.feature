@weasel
Feature: Add Entity
  As a LedgerSMB user I want to add a bank account to an entity, edit that
  bank account, then delete it.

Background:
  Given a standard test company
    And a logged in admin user

Scenario: Create a company and add a bank account to it, edit the account, then delete it.
  When I navigate the menu and select the item at "Contacts > Add Entity"
  Then I should see the Edit Contact screen
   And I expect the "Company" tab to be selected
  When I enter "Company A" into "Name"
   And I select "Germany" from the drop down "Country"
   And I press "Save"
   And I select the "Bank Accounts" tab
  Then I expect the "Bank Accounts" tab to be selected
  When I enter "DEUTDEFF500" into the "BIC/SWIFT Code" field
   And I enter "DE89370400440532013000" into the "Account Number" field
   And I enter "A remark" into the "Remark" field
   And I press "Save"
  Then I expect the Bank Accounts table to contain 1 row
   And I expect the 'BIC/SWIFT Code' column to contain 'DEUTDEFF500' for Account Number 'DE89370400440532013000'
   And I expect the 'Remark'         column to contain 'A remark'    for Account Number 'DE89370400440532013000'
  When I click "DE89370400440532013000" for the row with Account Number "DE89370400440532013000"
  Then I expect the "BIC/SWIFT Code" field to contain "DEUTDEFF500"
   And I expect the "Account Number" field to contain "DE89370400440532013000"
   And I expect the "Remark" field to contain "A remark"
  When I click "[Delete]" for the row with Account Number "DE89370400440532013000"
  Then I expect the Bank Accounts table to contain 0 rows
