@weasel
Feature: Exchange rates
  As a LedgerSMB user, I want to be able to view the default exchange
  rates, update them and delete unwanted ones.

Background:
  Given a standard test company
    And a logged in admin user

Scenario: View the available exchange rates
 Given the following exchange rates:
     | currency | rate type    | valid from | rate |
     | EUR      | Default rate | 2020-01-01 | 1.1  |
     | CAD      | Default rate | 2020-01-02 | 0.8  |
  When I navigate the menu and select the item at "System > Currency > Edit rates"
  Then I should see the Edit rates screen
   And I should see the title "Available exchange rates"
   And I expect the report to contain 2 rows
   And I expect the 'Currency' report column to contain 'EUR' for Valid From '2020-01-01'
   And I expect the 'Rate Type' report column to contain 'Default rate' for Valid From '2020-01-01'
   And I expect the 'Rate' report column to contain '1.1' for Valid From '2020-01-01'
   And I expect the 'Currency' report column to contain 'CAD' for Valid From '2020-01-02'
   And I expect the 'Rate Type' report column to contain 'Default rate' for Valid From '2020-01-02'
   And I expect the 'Rate' report column to contain '0.8' for Valid From '2020-01-02'

Scenario: Add an exchange rate
  When I navigate the menu and select the item at "System > Currency > Edit rates"
  Then I should see the Edit rates screen
   And I expect the report to contain 0 rows
  When I select "EUR" from the drop down "Currency"
   And I select "Default rate" from the drop down "Rate type"
   And I enter "2020-01-01" into "Valid from"
   And I enter "1.1" into "Rate"
   And I press "Add"
  Then I should see the Edit rates screen
   And I expect the report to contain 1 row
   And I expect the 'Currency' report column to contain 'EUR' for Valid From '2020-01-01'
   And I expect the 'Rate Type' report column to contain 'Default rate' for Valid From '2020-01-01'
   And I expect the 'Rate' report column to contain '1.1' for Valid From '2020-01-01'

Scenario: Update an exchange rate
 Given the following exchange rate:
     | currency | rate type    | valid from | rate |
     | EUR      | Default rate | 2020-01-01 | 1.1  |
  When I navigate the menu and select the item at "System > Currency > Edit rates"
  Then I should see the Edit rates screen
   And I should see the title "Available exchange rates"
   And I expect the report to contain 1 row
  When I select "EUR" from the drop down "Currency"
   And I select "Default rate" from the drop down "Rate type"
   And I enter "2020-01-01" into "Valid from"
   And I enter "1.2" into "Rate"
   And I press "Add"
  Then I should see the Edit rates screen
   And I expect the report to contain 1 row
   And I expect the 'Currency' report column to contain 'EUR' for Valid From '2020-01-01'
   And I expect the 'Rate Type' report column to contain 'Default rate' for Valid From '2020-01-01'
   And I expect the 'Rate' report column to contain '1.2' for Valid From '2020-01-01'

Scenario: Delete an exchange rate
 Given the following exchange rates:
     | currency | rate type    | valid from | rate |
     | EUR      | Default rate | 2020-01-01 | 1.1  |
  When I navigate the menu and select the item at "System > Currency > Edit rates"
  Then I should see the Edit rates screen
   And I expect the report to contain 1 row
  When I click "[delete]" for the row with Valid From "2020-01-01"
  Then I should see the Edit rates screen
   And I expect the report to contain 0 rows

