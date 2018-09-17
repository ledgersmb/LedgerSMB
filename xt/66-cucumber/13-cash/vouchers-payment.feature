@weasel
Feature: Bulk payments
  As a LedgerSMB user I want to be able to create a new Batch of payment
  Vouchers.

Background:
  Given a standard test company
    And a logged in admin user

Scenario: Add payments to a new batch
  When I navigate the menu and select the item at "Cash > Vouchers > Payments"
  Then I should see the Create New Batch screen
  When I enter "2018-01-01" into "Batch Date"
   And I enter "B-1001" into "Batch Number"
   And I enter "Test Batch" into "Description"
   And I press "Continue"
  Then I should see the Filtering Payments screen
   And I should see the title "Filtering Payments"
  When I enter "1001" into "Start Source Numbering At"
   And I press "Continue"
  Then I should see the Payments Detail screen
   And I expect to see the 'date_paid' value of '2018-01-01'

Scenario: Add payments to an existing batch
  When I navigate the menu and select the item at "Cash > Vouchers > Payments"
  Then I should see the Create New Batch screen
   And I should see a Batch with these values:
       | label          | value      |
       | Control Number | B-1001     |
       | Description    | Test Batch |
       | Post Date      | 2018-01-01 |
  When I click on the Batch with Control Number "B-1001"
  Then I should see the Filtering Payments screen
   And I should see the title "Filtering Payments"
  When I enter "2001" into "Start Source Numbering At"
   And I press "Continue"
  Then I should see the Payments Detail screen
   And I expect to see the 'date_paid' value of '2018-01-01'
