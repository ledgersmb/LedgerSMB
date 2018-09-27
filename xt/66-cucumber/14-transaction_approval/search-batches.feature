@weasel
Feature: Search Batches
  As a LedgerSMB user I want to be able to search for previously created
  voucher batches according to parameters which I specify, with the results
  presented as a list.

Background:
  Given a standard test company
    And a logged in admin user

Scenario: Search for all unapproved batches
 Given batches with these properties:
       | Type    | Date       | Batch Number | Description | Approved |
       | ap      | 2018-01-01 | B-1001       | Batch-1     | no       |
       | ar      | 2018-02-01 | B-1002       | Batch-ABC-2 | no       |
       | payment | 2018-03-01 | B-1003       | Batch-3     | no       |
       | payment | 2018-04-01 | B-1004       | Batch-4     | yes      |
  When I navigate the menu and select the item at "Transaction Approval > Batches"
  Then I should see the Search Batches screen
  When I press "Search"
  Then I should see the Batch Search Report screen
   And I should see these headings:
       | Heading             | Contents     |
       | Report Name         | Batch Search |
       | Company             | standard-0   |
       | Transaction Type    |              |
       | Description         |              |
       | Amount Greater Than |              |
       | Amount Less Than    |              |
   And I expect the report to contain 3 rows
   And I expect the 'Type' report column to contain 'ap' for Batch Number 'B-1001'
   And I expect the 'Date' report column to contain '2018-01-01' for Batch Number 'B-1001'
   And I expect the 'Description' report column to contain 'Batch-1' for Batch Number 'B-1001'
   And I expect the 'AR/AP/GL Amount' report column to contain '0.00' for Batch Number 'B-1001'
   And I expect the 'Payment Amount' report column to contain '0.00' for Batch Number 'B-1001'

Scenario: Search for batches, filtering by batch type
  When I navigate the menu and select the item at "Transaction Approval > Batches"
  Then I should see the Search Batches screen
  When I select "payment" from the drop down "Transaction Type"
   And I press "Search"
  Then I should see the Batch Search Report screen
   And I should see these headings:
       | Heading             | Contents     |
       | Report Name         | Batch Search |
       | Company             | standard-0   |
       | Transaction Type    | payment      |
       | Description         |              |
       | Amount Greater Than |              |
       | Amount Less Than    |              |
   And I expect the report to contain 1 row
   And I expect the 'Description' report column to contain 'Batch-3' for Batch Number 'B-1003'

 Scenario: Search for batches, filtering by description
  When I navigate the menu and select the item at "Transaction Approval > Batches"
  Then I should see the Search Batches screen
  When I enter "ABC" into "Description"
   And I press "Search"
  Then I should see the Batch Search Report screen
   And I should see these headings:
       | Heading             | Contents     |
       | Report Name         | Batch Search |
       | Company             | standard-0   |
       | Transaction Type    |              |
       | Description         | ABC          |
       | Amount Greater Than |              |
       | Amount Less Than    |              |
   And I expect the report to contain 1 row
   And I expect the 'Description' report column to contain 'Batch-ABC-2' for Batch Number 'B-1002'

Scenario: Search for all approved batches
  When I navigate the menu and select the item at "Transaction Approval > Batches"
  Then I should see the Search Batches screen
  When I select "Approved"
   And I press "Search"
  Then I should see the Batch Search Report screen
   And I should see these headings:
       | Heading             | Contents     |
       | Report Name         | Batch Search |
       | Company             | standard-0   |
       | Transaction Type    |              |
       | Description         |              |
       | Amount Greater Than |              |
       | Amount Less Than    |              |
   And I expect the report to contain 1 row
   And I expect the 'Description' report column to contain 'Batch-4' for Batch Number 'B-1004'


