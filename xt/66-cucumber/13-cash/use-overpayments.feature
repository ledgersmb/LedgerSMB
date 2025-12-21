@weasel

Feature: Use Overpayment
    As a LedgerSMB User I want to use a pre-payment or overpayment
    previously entered.

Background:
    Given a standard test company
      And a customer "Customer A"
      And an AR Overpayment with these values:
          | Customer   | Date       | Amount |
          | Customer A | 2016-12-01 | 100.00 |
      And an unpaid AR transaction with these values:
       | Customer   | Date       | Invoice Number | Amount |
       | Customer A | 2017-01-01 | INV100         | 200.00 |

Scenario:  Applying the Payment to the Invoice
    When I navigate the menu and select "Cash & Banking > Use AR Overpayment"
    Then I should see the Use AR Overpayment Customer Selection screen
    When I enter "Customer A" into "Customer Name"
     And I press "Continue"
    Then I should see the Use AR Overpayment Entry Screen
     And I expect the overpayments table to contain 1 row
     And I expect the overpayment to show:
        | Column | Expected |
        | Customer    | Customer A |
        | Overpayment | 200.00 |
    When I enter "Customer A" into Customer Name
     And I press Update
    Then I expect the Invoices table to contain 1 row
     And I expect the open item for invoice INV100 to show:
        | Column | Expected   |
        | Due    | 100.00     |
        | Name   | Customer A |
    When I enter "2017-02-01" into "Date"
     And I enter 100 into the "Amount" field for invoice INV100
     And I press Post
    Then I see the Use AR Overpayment Customer Selection screen
    When I enter "Customer A" into "Customer Name"
     And I press "Continue"
    Then I should see the Use AR Overpayment Entry Screen
     And I expect the overpayments table to contain 1 row
     And I expect the overpayment to show:
        | Column | Expected |
        | Customer    | Customer A |
        | Overpayment | 100.00 |
     And I expect the open items to show no rows.
