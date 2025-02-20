@weasel
Feature: Add Entity
  As a LedgerSMB user I want to add a new entities - companies and people.

Background:
  Given a standard test company
    And a logged in admin user

Scenario: Add a new Customer with minimal information
  When I navigate the menu and select the item at "Contacts > Add Entity"
  Then I should see the Edit Contact screen
   And I expect the "Company" tab to be selected
  When I enter "Company A" into "Name"
   And I select "Spain" from the drop down "Country"
   And I press "Save"
  Then I expect the "Credit Accounts" tab to be selected
  When I press "Save New"
  Then I expect the Accounts table to contain 1 row

Scenario: Add a new Person with minimal information
  When I navigate the menu and select the item at "Contacts > Add Entity"
  Then I should see the Edit Contact screen
  When I select the "Person" tab
  Then I expect the "Person" tab to be selected
  When I select "Dr" from the drop down "Salutation"
   And I enter "James" into "Given Name"
   And I enter "Taylor" into "Surname"
   And I enter "-" into "Personal ID"
   And I enter "2025-01-01" into "Birthdate"
   And I press "Save"
  Then I expect the "Credit Accounts" tab to be selected
  When I press "Save New"
  Then I expect the Accounts table to contain 1 row
