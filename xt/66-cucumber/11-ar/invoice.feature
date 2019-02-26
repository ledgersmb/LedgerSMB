@weasel
Feature: AR transaction document handling
  As a LedgerSMB user, I want to be able to create transactions,
  save them and post them, with or without separation of duties
  and search for them.


Background:
   Given a standard test company
     And a logged in admin
     And a customer "Customer 1"
     And a customer "Customer 2"
     And a service "s1"
     And a part "p1"

@wip
Scenario: Creation of a new sales invoice
   Given the following company configuration settings:
       | setting          | value    |
       | Max per dropdown | 99999    |
    When I open the sales invoice entry screen
    Then I expect to see an invoice with 1 empty line
     And I expect to see these invoice header fields and values
       | name            | value    |
       | Invoice Created | $$today |
       | Invoice Date    | $$today |
       | Due Date        |          |
       | Record in       | 1200--Accounts Receivables |
       | Currency        | USD      |
       | Description     |          |
       | Shipping Point  |          |
       | Ship via        |          |
       | Invoice Number  |          |
       | Order Number    |          |
       | PO Number       |          |
    When I select customer "Customer 2"
     And I add an invoice line with part "p1"
    Then I expect to see an invoice with these lines:
      | Item | part | description | Qty | Unit | OH | Price | Disc | Extended | TaxForm | Delivery | Notes | Serial No. |
      | 1    | p1   | part 1      | 0   |      |    | 0.00  |    0 | 0.00     |         |          |       |            |
     And I expect to see an invoice with these document properties:
      | name            | value      |
      | Invoice Created | <today>    |
      | Due Date        | <today>    |
      | Order Number    |            |
      | PO Number       |            |
      | Invoice Number  |            |
      | Description     |            |
      | Currency        | USD        |
      | Shipping Point  |            |
      | Ship via        |            |
      | Notes           |            |
      | Internal notes  |            |

