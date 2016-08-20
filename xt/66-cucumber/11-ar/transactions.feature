@wip @weasel
Feature: AR transaction document handling
  As a LedgerSMB user, I want to be able to create transactions,
  save them and post them, with or without separation of duties
  and search for them.


Scenario: Creation of a new AR transaction
   Given a standard test company
     And a logged in admin
     And a customer named "Customer 1"
    When I open the AR transaction entry screen
     And I select customer "Customer 1"

