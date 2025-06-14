@weasel
Feature: Search AP transactions by date
  As a LedgerSMB user I want to be able to search for AP transactions
  according to date parameters and display the results.

Background:
  Given a standard test company
    And a logged in admin user
    And a vendor "Vendor A"
    And a vendor "Vendor B"
    And unpaid AP transactions with these values:
       | Vendor   | Date       | Invoice Number | Amount |
       | Vendor A | 2024-12-01 | INV100         | 100.00 |
       | Vendor A | 2025-01-01 | INV101         | 100.01 |
       | Vendor A | 2025-03-31 | INV102         | 100.02 |
       | Vendor B | 2025-04-01 | INV103         | 100.03 |

Scenario: Search by date, specifying start and end date
  When I navigate the menu and select the item at "Accounts Payable > Search"
  Then I should see the AP search screen
  When I enter "2025-01-01" into "From"
   And I enter "2025-03-31" into "To"
   And I press "Continue"
  Then I should see the Search AP Report screen
   And I should see a heading "Report Name" displaying "Search AP"
   And I expect the report to contain 2 rows
   And I expect the 'Date' report column to contain '2025-01-01' for Invoice 'INV101'
   And I expect the 'Vendor' report column to contain 'Vendor A' for Invoice 'INV101'
   And I expect the 'Total' report column to contain '100.01' for Invoice 'INV101'
   And I expect the 'Paid' report column to contain '0.00' for Invoice 'INV101'
   And I expect the 'Due' report column to contain '100.01' for Invoice 'INV101'
   And I expect the 'Date' report column to contain '2025-03-31' for Invoice 'INV102'

Scenario: Search by date, specifying only start date
  When I navigate the menu and select the item at "Accounts Payable > Search"
  Then I should see the AP search screen
  When I enter "2025-03-31" into "From"
   And I press "Continue"
  Then I should see the Search AP Report screen
   And I expect the report to contain 2 rows
   And I expect the 'Date' report column to contain '2025-03-31' for Invoice 'INV102'
   And I expect the 'Vendor' report column to contain 'Vendor A' for Invoice 'INV102'
   And I expect the 'Date' report column to contain '2025-04-01' for Invoice 'INV103'
   And I expect the 'Vendor' report column to contain 'Vendor B' for Invoice 'INV103'

Scenario: Search by date, specifying only end date
  When I navigate the menu and select the item at "Accounts Payable > Search"
  Then I should see the AP search screen
  When I enter "2025-01-01" into "To"
   And I press "Continue"
  Then I should see the Search AP Report screen
   And I expect the report to contain 2 rows
   And I expect the 'Date' report column to contain '2024-12-01' for Invoice 'INV100'
   And I expect the 'Date' report column to contain '2025-01-01' for Invoice 'INV101'

Scenario: Search by date, specifying month period
  When I navigate the menu and select the item at "Accounts Payable > Search"
  Then I should see the AP search screen
  When I select "March" from the drop down "From Month"
   And I select "2025" from the drop down "From Year"
   And I select 'Month' as the period
   And I press "Continue"
  Then I should see the Search AP Report screen
   And I expect the report to contain 1 row
   And I expect the 'Date' report column to contain '2025-03-31' for Invoice 'INV102'

Scenario: Search by date, specifying quarter period
  When I navigate the menu and select the item at "Accounts Payable > Search"
  Then I should see the AP search screen
  When I select "January" from the drop down "From Month"
   And I select "2025" from the drop down "From Year"
   And I select 'Quarter' as the period
   And I press "Continue"
  Then I should see the Search AP Report screen
   And I expect the report to contain 2 rows
   And I expect the 'Date' report column to contain '2025-01-01' for Invoice 'INV101'
   And I expect the 'Date' report column to contain '2025-03-31' for Invoice 'INV102'

Scenario: Search by date, specifying year period
  When I navigate the menu and select the item at "Accounts Payable > Search"
  Then I should see the AP search screen
  When I select "February" from the drop down "From Month"
   And I select "2024" from the drop down "From Year"
   And I select 'Year' as the period
   And I press "Continue"
  Then I should see the Search AP Report screen
   And I expect the report to contain 2 rows
   And I expect the 'Date' report column to contain '2024-12-01' for Invoice 'INV100'
   And I expect the 'Date' report column to contain '2025-01-01' for Invoice 'INV101'

Scenario: Search by date, specifying current period
  When I navigate the menu and select the item at "Accounts Payable > Search"
  Then I should see the AP search screen
  When I select "February" from the drop down "From Month"
   And I select "2025" from the drop down "From Year"
   And I select 'Current' as the period
   And I press "Continue"
  Then I should see the Search AP Report screen
   And I expect the report to contain 2 rows
   And I expect the 'Date' report column to contain '2025-03-31' for Invoice 'INV102'
   And I expect the 'Date' report column to contain '2025-04-01' for Invoice 'INV103'

Scenario: Search by invoice number
  When I navigate the menu and select the item at "Accounts Payable > Search"
  Then I should see the AP search screen
  When I enter "INV101" into "Invoice Number"
   And I press "Continue"
  Then I should see the Search AP Report screen
   And I expect the report to contain 1 row
   And I expect the 'Date' report column to contain '2025-01-01' for Invoice 'INV101'

Scenario: Search by vendor
  When I navigate the menu and select the item at "Accounts Payable > Search"
  Then I should see the AP search screen
  When I enter "Vendor B" into "Vendor"
   And I press "Continue"
  Then I should see the Search AP Report screen
   And I expect the report to contain 1 row
   And I expect the 'Date' report column to contain '2025-04-01' for Invoice 'INV103'

