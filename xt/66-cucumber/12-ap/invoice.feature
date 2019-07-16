@weasel
Feature: AP transaction document handling
  As a LedgerSMB user, I want to be able to create transactions,
  save them and post them, with or without separation of duties
  and search for them.


Background:
   Given a standard test company
     And a logged in admin
     And a vendor "Vendor 1"
     And a vendor "Vendor 2"
     And a part with these properties:
       | name        | value    |
       | partnumber  | p1       |
       | description | Part 1   |
       | sellprice   | 30       |
       | unit        | ea       |


Scenario: Creation of a new sales invoice, no taxes
    When I open the purchase invoice entry screen
    Then I expect to see an invoice with 1 empty line
     And I expect to see these invoice header fields and values
       | name            | value    |
       | Invoice Created |         |
       | Invoice Date    | $$today |
       | Due Date        |          |
       | Record in       | 2100--Accounts Payable |
       | Currency        | USD      |
       | Description     |          |
       | Invoice Number  |          |
       | Order Number    |          |
       | SO Number       |          |
    When I select vendor "Vendor 2"
     And I add an invoice line with part "p1"
    Then I expect to see an invoice with these lines
       | Item | Number | Description | Qty | Unit | OH | Price | % | Extended | TaxForm | Delivery Date | Notes | Serial No. |
       | 1    | p1     | Part 1      | 1   | ea   | 0  |  0.00 | 0 |  0.00    |         |               |       |            |
     And I expect to see the invoice subtotal of 0.00 and total of 0.00 without taxes
     And I expect to see 1 empty payment line
    When I post the invoice
    Then I expect to see these invoice header fields and values
       | name            | value    |
       | Invoice Created | $$today |
       | Invoice Date    | $$today |
       | Due Date        | $$today |
       | Record in       | 2100--Accounts Payable |
       | Currency        | USD      |
       | Description     |          |
       | Invoice Number  | 2        |
       | Order Number    |          |
       | SO Number       |          |
     And I expect to see an invoice with these lines
       | Item | Number | Description | Qty | Unit | OH | Price | % | Extended | TaxForm | Delivery Date | Notes | Serial No. |
       | 1    | p1     | Part 1      | 1   | ea   |  1 |  0.00 | 0 |  0.00    |         | $$today       |       |            |
     And I expect to see the invoice subtotal of 0.00 and total of 0.00 without taxes
###TODO:
#     And I expect to see 1 empty payment line
## For some reason, there are 2 empty payment lines?!