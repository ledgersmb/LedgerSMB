@weasel
Feature: Customer History Report
  As a LedgerSMB user I want to be able to search the purchase history
  of customers to generate a report, filtering by various parameters.

Background:
  Given a standard test company named "standard-customer-history"
    And a logged in admin user

Scenario: Run the Customer History report
 Given a vendor "Vendor A"
  When I navigate the menu and select the item at "AR > Reports > Customer History"
  Then I should see the Purchase History Search screen
  When I press "Continue"
  Then I should see the Purchase History Report screen
   And I should see these headings:
       | Heading             | Contents         |
       | Report Name         | Purchase History |
       | Company             | standard-customer-history   |

