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
     And a part with these properties:
       | name        | value    |
       | partnumber  | p1       |
       | description | Part 1   |
       | sellprice   | 30       |
       | unit        | ea       |


Scenario: Creation of a new sales invoice, no taxes
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
    Then I expect to see an invoice with these lines
       | Item | Number | Description | Qty | Unit | OH | Price | % | Extended | TaxForm | Delivery Date | Notes | Serial No. |
       | 1    | p1     | Part 1      | 1   | ea   | 0  | 30.00 | 0 | 30.00    |         |               |       |            |
     And I expect to see the invoice subtotal of 30.00 and total of 30.00 without taxes
     And I expect to see 1 empty payment line
    When I post the invoice
    Then I expect to see these invoice header fields and values
       | name            | value    |
       | Invoice Created | $$today |
       | Invoice Date    | $$today |
       | Due Date        | $$today |
       | Record in       | 1200--Accounts Receivables |
       | Currency        | USD      |
       | Description     |          |
       | Shipping Point  |          |
       | Ship via        |          |
       | Invoice Number  | 2        |
       | Order Number    |          |
       | PO Number       |          |
     And I expect to see an invoice with these lines
       | Item | Number | Description | Qty | Unit | OH | Price | % | Extended | TaxForm | Delivery Date | Notes | Serial No. |
       | 1    | p1     | Part 1      | 1   | ea   | -1 | 30.00 | 0 | 30.00    |         |               |       |            |
     And I expect to see the invoice subtotal of 30.00 and total of 30.00 without taxes
###TODO:
#     And I expect to see 1 empty payment line
## For some reason, there are 2 empty payment lines?!