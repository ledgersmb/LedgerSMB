@weasel
Feature: Bulk payments
  As a LedgerSMB user I want to be able to create a new batch of payment
  vouchers and add a payment to that batch. I then want to review that
  batch to see what payments it contains.

Background:
  Given a standard test company
    And a logged in admin user

Scenario: Add payments to a new batch
 Given a vendor "Vendor A"
   And an unpaid AP transaction with these values:
       | Vendor   | Date       | Invoice Number | Amount |
       | Vendor A | 2017-01-01 | INV100         | 100.00 |
  When I navigate the menu and select the item at "Cash & Banking > Vouchers > Payments"
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
   And I update the page
  Then I should see the Payments Detail screen
   And I expect to see the 'grand_total' value of '100.00'
   And I expect to see the 'grand_total_currency' value of 'USD'
  When I press "Post"
  Then I should see the Payment Batch Summary screen
  When I press "Save Batch"
  Then I should see the Filtering Payments screen

Scenario: Add payments to an existing batch
 Given a vendor "Vendor B"
   And an unpaid AP transaction with these values:
       | Vendor   | Date       | Invoice Number | Amount |
       | Vendor B | 2017-01-02 | INV101         | 25.00  |
   And a payment batch with these properties:
       | Property     | Value      |
       | Description  | Test Batch |
       | Batch Date   | 2018-01-01 |
       | Batch Number | B-1001     |
  When I navigate the menu and select the item at "Cash & Banking > Vouchers > Payments"
  Then I should see the Create New Batch screen
   And I should see a Batch with these values:
       | Batch Number | Description | Post Date  |
       | B-1001       | Test Batch  | 2018-01-01 |
  When I click on the Batch with Batch Number "B-1001"
  Then I should see the Filtering Payments screen
   And I should see the title "Filtering Payments"
  When I enter "2001" into "Start Source Numbering At"
   And I press "Continue"
  Then I should see the Payments Detail screen
   And I expect to see the 'date_paid' value of '2018-01-01'
  When I select the payment line with these values:
       | Name     | Invoice Total | Source |
       | Vendor B | 25.00 USD     | 2001   |
   And I update the page
  Then I should see the Payments Detail screen
   And I expect to see the 'grand_total' value of '25.00'
   And I expect to see the 'grand_total_currency' value of 'USD'
  When I press "Post"
  Then I should see the Payment Batch Summary screen
  When I press "Save Batch"
  Then I should see the Filtering Payments screen

Scenario: Add partial payment to an existing batch
 Given a vendor "Vendor C"
   And an unpaid AP transaction with these values:
       | Vendor   | Date       | Invoice Number | Amount |
       | Vendor C | 2017-03-01 | INV103         | 250.00 |
   And a payment batch with these properties:
       | Property     | Value      |
       | Description  | Test Batch |
       | Batch Date   | 2018-01-01 |
       | Batch Number | B-1001     |
  When I navigate the menu and select the item at "Cash & Banking > Vouchers > Payments"
  Then I should see the Create New Batch screen
   And I should see a Batch with these values:
       | Batch Number | Description | Post Date  |
       | B-1001       | Test Batch  | 2018-01-01 |
  When I click on the Batch with Batch Number "B-1001"
  Then I should see the Filtering Payments screen
  When I enter "3001" into "Start Source Numbering At"
   And I press "Continue"
  Then I should see the Payments Detail screen
  When I select the payment line with these values:
       | Name     | Invoice Total  | Source |
       | Vendor C | 250.00 USD     | 3001   |
   And I select "Some" on the payment line for "Vendor C"
  Then I expect to see the Invoice Detail table for "Vendor C"
   And I should see an invoice from "Vendor C" with these values:
       | Date       | Invoice Number | Total  | Paid | Discount | Net Due |
       | 2017-03-01 | INV103         | 250.00 | 0.00 | 0.00     | 250.00  |
  When I enter "1.00" into "To Pay" for the invoice from "Vendor C" with these values:
       | Date       | Invoice Number |
       | 2017-03-01 | INV103         |
   And I update the page
  Then I should see the Payments Detail screen
   And I expect to see the 'grand_total' value of '1.00'
   And I expect to see the 'grand_total_currency' value of 'USD'
   And I expect to see the "Contact Total" of "1.00 USD" for "Vendor C"
  When I press "Post"
  Then I should see the Payment Batch Summary screen
  When I press "Save Batch"
  Then I should see the Filtering Payments screen

###TODO: This test was dependent on the previous one
# Also, there's an important underlying question: should we test
# transaction approval as part of the original functionality or is it
# a separate functionality to be tested?
# Scenario: Review the contents of an existing batch
#   When I navigate the menu and select the item at "Transaction Approval > Batches"
#   Then I should see the Search Batches screen
#   When I enter "Test Batch" into "Description"
#    And I press "Search"
#   Then I should see the Batch Search Report screen
#    And I expect the report to contain 1 row
#    And I expect the 'Payment Amount' report column to contain '126.00' for Batch Number 'B-1001'

