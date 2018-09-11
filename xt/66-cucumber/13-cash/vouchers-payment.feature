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
   And I press "Continue"
  Then I should see the Filtering Payments screen
  When I enter "2017-12-01" into "Date From"
   And I enter "2017-12-31" into "Date To"
   And I enter "1001" into "Start Source Numbering At"
   And I press "Continue"
  Then I should see the Payments Detail screen
   And I expect to see the 'date_paid' value of '2018-01-01'
   And I expect to see the 'filter_from' value of '2017-12-01'
   And I expect to see the 'filter_to' value of '2017-12-31'
