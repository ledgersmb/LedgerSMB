@weasel
Feature: Currency
  As a LedgerSMB user, I want to be able to view the available currencies,
  add further currencies, and delete unused currencies. I should not be
  able to delete the company's default currencies, or those currencies
  which are being used in the company's accounts.

Background:
  Given a standard test company
    And a logged in admin user

Scenario: View the available currencies
 Given the following exchange rate:
     | currency | rate type    | valid from | rate |
     | EUR      | Default rate | 2020-01-01 | 1.1  |
  When I navigate the menu and select the item at "System > Currency > Edit currencies"
  Then I should see the Edit currencies screen
   And I should see the title "Defined currencies"
   And I expect the report to contain 3 rows
   And I expect the '' report column to contain 'default' for ID 'USD'
   And I expect the '' report column to contain 'in use' for ID 'EUR'
   And I expect the 'Description' report column to contain 'USD' for ID 'USD'
   And I expect the 'Description' report column to contain 'EUR' for ID 'EUR'
   And I expect the 'Description' report column to contain 'CAD' for ID 'CAD'

Scenario: Add a currency
  When I navigate the menu and select the item at "System > Currency > Edit currencies"
  Then I should see the Edit currencies screen
  When I enter "SEK" as the id for a new currency
   And I enter "Swedish Krona" as the description for a new currency
   And I press "Add"
  Then I should see the Edit currencies screen
   And I expect the report to contain 4 rows
   And I expect the 'Description' report column to contain 'Swedish Krona' for ID 'SEK'

Scenario: Delete a currency
  When I navigate the menu and select the item at "System > Currency > Edit currencies"
  Then I should see the Edit currencies screen
   And I expect the report to contain 3 rows
  When I click "[delete]" for the row with ID "CAD"
  Then I should see the Edit currencies screen
   And I expect the report to contain 2 rows

Scenario: Delete a currency containing query string characters
 Given the following currency:
     | currency | description    |
     | &&?      | test currency  |
  When I navigate the menu and select the item at "System > Currency > Edit currencies"
  Then I should see the Edit currencies screen
   And I expect the report to contain 4 rows
  When I click "[delete]" for the row with ID "&&?"
  Then I should see the Edit currencies screen
   And I expect the report to contain 3 rows

Scenario: Delete a currency with less than three characters
 Given the following currency:
     | currency | description    |
     | A        | test currency  |
  When I navigate the menu and select the item at "System > Currency > Edit currencies"
  Then I should see the Edit currencies screen
   And I expect the report to contain 4 rows
  When I click "[delete]" for the row with ID "A"
  Then I should see the Edit currencies screen
   And I expect the report to contain 3 rows

