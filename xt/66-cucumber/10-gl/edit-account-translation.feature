# HARNESS-DURATION-MEDIUM
@weasel
Feature: Edit account translation
  As a LedgerSMB user I want to be able to specify account descriptions
  in multiple languages.

Background:
  Given a standard test company
    And a logged in admin user

Scenario: Add translations for an account description
  When I navigate the menu and select the item at "General Journal > Chart of Accounts"
  Then I should see the Chart of Accounts screen
  When I click Account Number "1060"
  Then I should see the Account screen
  When I select the "Translations" tab
  Then I expect the "Spanish" field to contain ""
   And I expect the "French" field to contain ""
  When I enter "Cuenta de cheques" into "Spanish"
   And I enter "Compte courant" into "French"
   And I save the translations
  Then I should see the Account screen
  When I select the "Translations" tab
  Then I expect the "Spanish" field to contain "Cuenta de cheques"
   And I expect the "French" field to contain "Compte courant"

