@wip @weasel
Feature: Check operation of Cash->Vouchers->Payment
  As a LedgerSMB user I want to be able to create a new Batch of payment
  Vouchers.

Background:
  Given a standard test company
    And a logged in accounting user

Scenario: Add payments to a new batch
  When I navigate the menu and select the item at "Cash > Vouchers > Payments"
  Then I should see the "Create New Batch" screen
  When I enter a "Batch Date" of "2018-01-01"
   And I click "Continue"
  Then I should see the "Filtering Payments" screen

