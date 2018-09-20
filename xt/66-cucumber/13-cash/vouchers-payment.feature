@weasel
Feature: Bulk payments
  As a LedgerSMB user I want to be able to create a new batch of payment
  vouchers and add a payment to that batch. I then want to review that
  batch to see what payments it contains.

Background:
  Given a standard test company
    And a logged in admin user

Scenario: Add payments to a new batch
 Given a vendor 'Vendor A'
   And an unpaid AP transaction with "Vendor A" for $100
  When I navigate the menu and select the item at "Cash > Vouchers > Payments"
  Then I should see the Create New Batch screen
  When I enter "2018-01-01" into "Batch Date"
   And I enter "B-1001" into "Batch Number"
   And I enter "Test Batch" into "Description"
   And I press "Continue"
  Then I should see the Filtering Payments screen
   And I should see the title "Filtering Payments"
  When I enter "1001" into "Start Source Numbering At"
   And I select "2100--Accounts Payable" from the drop down "Account"
   And I select "USD" from the drop down "Currency"
   And I select "1060--Checking Account" from the drop down "Pay From"
   And I press "Continue"
  Then I should see the Payments Detail screen
   And I expect to see the 'date_paid' value of '2018-01-01'
   And I expect to see the 'account_info' value of '2100 -- Accounts Payable'
   And I expect to see the 'cash_accno' value of '1060 -- Checking Account'
   And I should see a payment line with these values:
       | Name     | Invoice Total | Source |
       | Vendor A | 100.00 USD    | 1001   |
  When I select the payment line with these values:
       | Name     | Invoice Total | Source |
       | Vendor A | 100.00 USD    | 1001   |
   And I press "Update"
   And I wait for the page to load
  Then I should see the Payments Detail screen
   And I expect to see the 'grand_total' value of '100.00'
   And I expect to see the 'grand_total_currency' value of 'USD'

Scenario: Add payments to an existing batch
  When I navigate the menu and select the item at "Cash > Vouchers > Payments"
  Then I should see the Create New Batch screen
   And I should see a Batch with these values:
       | Control Number | Description | Post Date  |
       | B-1001         | Test Batch  | 2018-01-01 |
  When I click on the Batch with Control Number "B-1001"
  Then I should see the Filtering Payments screen
   And I should see the title "Filtering Payments"
  When I enter "2001" into "Start Source Numbering At"
   And I press "Continue"
  Then I should see the Payments Detail screen
   And I expect to see the 'date_paid' value of '2018-01-01'
