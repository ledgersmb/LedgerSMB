@weasel
Feature: GL Search
  As a LedgerSMB user I want to be able to search for GL transactions,
  filtering results according to various attributes.

Background:
  Given a standard test company
    And a logged in admin user
    And the following GL transaction posted on 2025-01-01:
     | accno | debit_bc | credit_bc  |
     |  1065 |  5000.00 |            |
     |  1060 |          |   5000.00  |

Scenario: Default search with no filter
 When I navigate the menu and select the item at "General Journal > Search"
  Then I should see the GL search screen
  When I press "Continue"
  Then I should see the GL report screen
   And I should see these headings:
       | Heading             | Contents               |
       | Report Name         | General Ledger Report  |
       | Start Date          |                        |
       | End Date            |                        |
   And I expect the report to contain 2 rows
   And I expect the 'Debits' report column to contain '5000.00' for Account Number '1065'
   And I expect the 'Credits' report column to contain '0' for Account Number '1065'
   And I expect the 'Debits' report column to contain '0' for Account Number '1060'
   And I expect the 'Credits' report column to contain '5000.00' for Account Number '1060'
   And I expect the 'Debits' report column to contain '5000.00' for Account Number ''
   And I expect the 'Credits' report column to contain '5000.00' for Account Number ''

