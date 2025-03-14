@weasel
Feature: Add Entity
  As a LedgerSMB user I want to add contact information, such as a telephone
  number to an Entity, then edit it to correct errors, or delete it when it
  becomes outdated.

Background:
  Given a standard test company
    And a logged in admin user
    And a vendor "Company A"

Scenario: Add contact information to a Company, edit it, then delete it.
  When I navigate the menu and select the item at "Contacts > Search"
  Then I should see the Contact Search screen
  When I enter "Company A" into "Name"
   And I press "Search"
  Then I should see the Contact Search Report screen
  When I click "Company A" for the row with Name "Company A"
  Then I should see the Edit Contact screen
  When I select the "Contact Info" tab
  Then I expect the "Contact Info" tab to be selected
  When I enter "Accounts Payable" into the "Description" field
   And I enter "ap@example.com" into the "Contact Info" field
   And I press "Save Contact"
  Then I expect the Contact Information table to contain 1 row
   And I expect the 'Description' column to contain 'Accounts Payable' for Contact Info 'ap@example.com'
  When I click "[Edit]" for the row with Contact Info "ap@example.com"
  Then I expect the "Description" field to contain "Accounts Payable"
   And I expect the "Contact Info" field to contain "ap@example.com"
  When I enter "Accounts Department" into the "Description" field
   And I enter "accounts@example.com" into the "Contact Info" field
   And I press "Save Contact"
  Then I expect the Contact Information table to contain 1 row
   And I expect the 'Description' column to contain 'Accounts Department' for Contact Info 'accounts@example.com'
  When I click "[Delete]" for the row with Contact Info "accounts@example.com"
  Then I expect the Contact Information table to contain 0 rows

