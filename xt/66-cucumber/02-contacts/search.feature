@weasel
Feature: Search for Entity
  As a LedgerSMB user I want to seach for Entities using a range of filtering
  criteria, displaying the results as a report table.

Background: The standard test company comes with one Entity already defined.
  Given a standard test company
    And a logged in admin user
    And a vendor "Antelope" from Spain

Scenario: Search for all Entities without filtering
  When I navigate the menu and select the item at "Contacts > Search"
  Then I should see the Contact Search screen
  When I press "Search"
  Then I should see the Contact Search Report screen
   And I expect the report to contain 2 rows

Scenario: Search for a non-existent Entity
  When I navigate the menu and select the item at "Contacts > Search"
  Then I should see the Contact Search screen
  When I enter "A non-existent name" into the "Name" field
   And I press "Search"
  Then I should see the Contact Search Report screen
   And I expect the report to contain 0 rows

Scenario: Search based on Entity Name
  When I navigate the menu and select the item at "Contacts > Search"
  Then I should see the Contact Search screen
  When I enter "Antelope" into the "Name" field
   And I press "Search"
  Then I should see the Contact Search Report screen
   And I expect the report to contain 1 row

Scenario: Search based on Entity Country
  When I navigate the menu and select the item at "Contacts > Search"
  Then I should see the Contact Search screen
  When I select "Spain" from the drop down "Country"
   And I press "Search"
  Then I should see the Contact Search Report screen
   And I expect the report to contain 1 rows

