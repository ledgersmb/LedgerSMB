Feature: This application tests general components of contact management
including new customers, vendors, leads and so forth.

# Background:
#    Given a ledgersmb database
#      And a US/General Chart of Accounts
#
# Scenario: Create a New Person as Customer
#      When I click on the Add Contact menu entry
#      Then I see the new customer screen
#      With one tab called 'Person'
#       And one tab called 'Company'
#      When I select the 'Person' tab
#       And enter a first name of 'Test'
#       And enter a last naame of 'Another test'
#       And select 'United States' as the country
#       And click Save
#      Then I see the 'Credit Account' Tab
#      With no credit accounts in the listing
#      When I click 'Save' on the Credit Account tab
#      Then I see a new line in the listing
#       And the Customer Number field is now filled in.
#
# Scenario: Create a New Company as Vendor
#      When I click on the Add Contact menu entry
#      Then I see the new customer screen
#      With one tab called 'Person'
#       And one tab called 'Company'
#      When I select the 'Company' tab
#       And enter a name of of 'Testing, Inc'
#       And select 'United States' as the country
#       And click Save
#      Then I see the 'Credit Account' Tab
#      With no credit accounts in the listing
#      When I click 'Save' on the Credit Account tab
#      Then I see a new line in the listing
#       And the Customer Number field is now filled in.
#
# Scenario: Look Up Existing Person as Customer
#      When I click on the Contacts/Search menu
#      Then I see the search filter screen.
#      When I select custommer as the entity class
#       And click continue
#      Then I see a listing with a customer with a name like 'Test'
#      When I click the 'Test
#      Then I see the 
#
# Scenario: Look Up Existing Company as Vendor
#      When I click on the Contacts/Search menu
#      Then I see the search filter screen.
#      When I select custommer as the entity class
#       And click continue
#      Then I see a listing with a customer with a name of 'Testing, Inc'
#      When I click the 'Testing, Inc'
#      Then I see the vendor ECA record
#
# Scenario: Add Address to Customer ECA
#    Given a person with a customer ECA
#     When I click on the Addresses tab
#      And enter a new address
#      And select credit account
#      And click save
#     Then I see the new address in the table list
#
# Scenario: Add Address to Customer Entity
#    Given a person with a customer ECA
#     When I click on the Addresses tab
#      And enter a new address
#      And select entity
#      And click save
#     Then I see the new address in the table list
#
# the below scenarios are still todo, but don't need to be finished by 1.5.0
# Scenario: Add new Vendor ECA to Customer
#
# Scenario: Add new Customer ECA to Vendor
#
# Scenario: Add New Phone number to Person
#
# Scenario: Add new note to company
#
# Scenario: Add nw bank account to person
#
# Scenario: Look up person customer with all info filled out
#
# Scenario: Look up company vendor wit all info flled out
