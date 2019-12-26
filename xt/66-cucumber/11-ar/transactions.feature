@weasel
Feature: AR transaction document handling
  As a LedgerSMB user, I want to be able to create transactions,
  save them and post them, with or without separation of duties
  and search for them.


Background:
   Given a standard test company
     And a customer "Customer 1"
     And a logged in admin


Scenario: Creation of a new AR transaction, no taxes
    When I open the AR transaction entry screen
     And I select customer "Customer 1"
    Then I expect to see these transaction header fields and values
       | name            | value    |
       | Invoice Created | $$today  |
       | Invoice Date    | $$today  |
       | Due Date        | $$today  |
       | Currency        | USD      |
       | Description     |          |
       | Invoice Number  |          |
       | Order Number    |          |
       | PO Number       |          |
     And I expect to see a transaction with 2 lines
###TODO: entry of amounts and other data
