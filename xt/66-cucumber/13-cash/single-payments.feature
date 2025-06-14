@weasel
Feature: Single payment
  As a LedgerSMB user I want to be able to create a single payment to
  pay one or more invoices - either in part or in whole.


Background:
  Given a standard test company
    And a logged in admin user
    And a vendor "Vendor A"
    And an unpaid AP transaction with these values:
       | Vendor   | Date       | Invoice Number | Amount |
       | Vendor A | 2017-01-01 | INV100         | 100.00 |

Scenario: Full payment of a single invoice
  When I navigate the menu and select the item at "Cash & Banking > Payment"
  Then I should see the Single Payment Vendor Selection screen
  When I enter "Vendor A" into "Vendor Name"
   And I press "Continue"
  Then I should see the Single Payment Entry screen
   And I expect the open items table to contain 1 row
   And I expect the open item for invoice INV100 to show:
      | Column   | Expected |
      | Total    |   100.00 |
      | Paid     |     0.00 |
      | Discount |     0.00 |
      | Due      |   100.00 |
      | To pay   |   100.00 |
  When I enter "2017-02-02" into "Date"
   And I press "Post"
   And I navigate the menu and select the item at "Cash & Banking > Reports > Payments"
   And I press "Search"
  Then I expect the 'Total Paid' report column to contain '100.00' for Vendor Number 'Vendor A'

Scenario: Partial payment of a single invoice
  When I navigate the menu and select the item at "Cash & Banking > Payment"
  Then I should see the Single Payment Vendor Selection screen
  When I enter "Vendor A" into "Vendor Name"
   And I press "Continue"
  Then I should see the Single Payment Entry screen
   And I expect the open items table to contain 1 row
   And I expect the open item for invoice INV100 to show:
      | Column   | Expected |
      | Total    |   100.00 |
      | Paid     |     0.00 |
      | Discount |     0.00 |
      | Due      |   100.00 |
      | To pay   |   100.00 |
  When I enter "2017-02-02" into "Date"
   And I edit the open item for invoice INV100 with these values:
    | Column | Value |
    | To pay | 50.00 |
   And I press "Post"
   And I navigate the menu and select the item at "Cash & Banking > Reports > Payments"
   And I press "Search"
  Then I expect the 'Total Paid' report column to contain '50.00' for Vendor Number 'Vendor A'
  When I navigate the menu and select the item at "Cash & Banking > Payment"
  Then I should see the Single Payment Vendor Selection screen
  When I enter "Vendor A" into "Vendor Name"
   And I press "Continue"
  Then I should see the Single Payment Entry screen
   And I expect the open items table to contain 1 row
   And I expect the open item for invoice INV100 to show:
      | Column   | Expected |
      | Total    |   100.00 |
      | Paid     |    50.00 |
      | Discount |     0.00 |
      | Due      |    50.00 |
      | To pay   |    50.00 |


Scenario: Payment within period of payment terms, posted afterwards
    This scenario tests that the payment terms and the resulting discount
    are correctly calculated when the transaction is posted on a date on
    which the customer/vendor is entitled to a discount, while the actual
    entry of the transaction is entered outside of the period in which the
    discount terms apply.

    Additionally, test that the discount is not being applied when the
    'Apply Discount' checkmark is unchecked.

 Given that standard payment terms apply for "Vendor A"
  When I navigate the menu and select the item at "Cash & Banking > Payment"
  Then I should see the Single Payment Vendor Selection screen
  When I enter "Vendor A" into "Vendor Name"
   And I press "Continue"
  Then I should see the Single Payment Entry screen
   And I expect the open items table to contain 1 row
   And I expect the open item for invoice INV100 to show:
      | Column   | Expected |
      | Total    |   100.00 |
      | Paid     |     0.00 |
      | Discount |     0.00 |
      | Due      |   100.00 |
      | To pay   |   100.00 |
  When I enter "2017-01-11" into "Date"
   And I update the form
  Then I expect the open item for invoice INV100 to show:
      | Column   | Expected |
      | Total    |   100.00 |
      | Paid     |     0.00 |
      | Discount |    10.00 |
      | Due      |    90.00 |
      | To pay   |    90.00 |

# This bit belongs to the scenario above, but is definitely broken
  # When I edit the open item for invoice INV100 with these values:
  #     | Column         | Value |
  #     | Apply Discount |       |
  #  And I update the form
  # Then I expect the open item for invoice INV100 to show:
  #     | Column   | Expected |
  #     | Total    |   100.00 |
  #     | Paid     |     0.00 |
  #     | Discount |    10.00 |
  #     | Due      |   100.00 |
  #     | To pay   |   100.00 |


@devel
Scenario: Exclusion of an invoice from the payment list
  Given an unpaid AP transaction with these values:
       | Vendor   | Date       | Invoice Number | Amount |
       | Vendor A | 2017-01-01 | INV101         | 100.00 |
  When I navigate the menu and select the item at "Cash & Banking > Payment"
  Then I should see the Single Payment Vendor Selection screen
  When I enter "Vendor A" into "Vendor Name"
   And I press "Continue"
  Then I should see the Single Payment Entry screen
   And I expect the open items table to contain 2 rows
  When I edit the open item for invoice INV100 with these values:
      | Column | Value |
      | X      |       |
  When I enter "2017-02-02" into "Date"
   And I update the form
  Then I expect the open items table to contain 1 row
   And I expect the open item for invoice INV101 to show:
      | Column   | Expected |
      | Total    |   100.00 |
      | Paid     |     0.00 |
      | Discount |     0.00 |
      | Due      |   100.00 |
      | To pay   |   100.00 |
