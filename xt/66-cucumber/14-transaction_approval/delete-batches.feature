@weasel
Feature: Delete Batches
  As a LedgerSMB user I want to search for previously created
  voucher batches and delete them.

Background:
  Given a standard test company
    And a logged in admin user

Scenario: Delete an unapproved batch
 Given batches with these properties:
       | Type    | Date       | Batch Number | Description | Approved |
       | payment | 2018-03-01 | B-1003       | Batch-3     | no       |
       | payment | 2018-04-01 | B-1004       | Batch-4     | no       |
  When I navigate the menu and select the item at "Transaction Approval > Batches"
  Then I should see the Search Batches screen
  When I press "Search"
   And I wait for the page to load
  Then I should see the Batch Search Report screen
   And I expect the report to contain 2 rows
  When I select the row where "Batch Number" is "B-1003"
   And I press "Delete"
   And I wait for the page to load
  Then I should see the Search Batches screen
  When I press "Search"
   And I wait for the page to load
  Then I should see the Batch Search Report screen
   And I expect the report to contain 1 rows
   And I expect the 'Description' report column to contain 'Batch-4' for Batch Number 'B-1004'
