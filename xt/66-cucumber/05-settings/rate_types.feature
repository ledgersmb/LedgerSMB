@weasel
Feature: Rate types
  As a LedgerSMB user, I want to be able to view the available exchange
  rate types and delete unused exchange rate types. I should not be able
  to delete the company's default exchanage rate type, or those currencies
  which are being used and the interface should indicate these conditions.

Background:
  Given a standard test company
    And a logged in admin user

Scenario: View the available exchange rate types
  When I navigate the menu and select the item at "System > Currency > Edit rate types"
  Then I should see the Edit rate types screen
   And I should see the title "Defined exchange rate types"
   And I expect the report to contain 1 row

Scenario: Used exchange rate types identified
 Given the following exchange rate type:
     | description |
     | Test        |
 Given the following exchange rate:
     | currency | rate type    | valid from | rate |
     | EUR      | Test         | 2020-01-01 | 1.1  |
  When I navigate the menu and select the item at "System > Currency > Edit rate types"
  Then I should see the Edit rate types screen
   And I expect the report to contain 2 rows
   And I expect the '' report column to contain 'system type' for Description 'Default rate'
   And I expect the '' report column to contain 'in use' for Description 'Test'

Scenario: Add and delete an exchange rate type
  When I navigate the menu and select the item at "System > Currency > Edit rate types"
  Then I should see the Edit rate types screen
   And I expect the report to contain 1 row
  When I enter "Test" as the description for a new rate type
   And I press "Add"
  Then I should see the Edit rate types screen
   And I expect the report to contain 2 rows
  When I click "[delete]" for the row with Description "Test"
  Then I should see the Edit rate types screen
   And I expect the report to contain 1 row

