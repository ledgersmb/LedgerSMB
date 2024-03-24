@weasel
Feature: Change user permissions
  As a LedgerSMB administrator I want to change the permissions of an
  existing user.

Background:
  Given a standard test company
    And a logged in admin user

Scenario: Remove a user permission
  When I navigate the menu and select the item at "HR > Employees > Search"
  Then I should see the Employee Search screen
  When I press "Search"
  Then I should see the Employee Search Report screen
  When I click Control Code "A-00001"
  Then I should see the Edit Employee screen
  When I select the "User" tab
  Then I expect the "account all" checkbox to be selected
  When I deselect checkbox "account all"
   And I press "Save Groups"
  Then I should see the Edit Employee screen
  When I select the "User" tab
  Then I expect the "account all" checkbox to be not selected

Scenario: Add a user permission
  When I navigate the menu and select the item at "HR > Employees > Search"
  Then I should see the Employee Search screen
  When I press "Search"
  Then I should see the Employee Search Report screen
  When I click Control Code "A-00001"
  Then I should see the Edit Employee screen
  When I select the "User" tab
  Then I expect the "account all" checkbox to be not selected
  When I select checkbox "account all"
   And I press "Save Groups"
  Then I should see the Edit Employee screen
  When I select the "User" tab
  Then I expect the "account all" checkbox to be selected
