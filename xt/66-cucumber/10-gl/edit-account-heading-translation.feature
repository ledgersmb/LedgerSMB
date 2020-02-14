@weasel
Feature: Edit account translation
  As a LedgerSMB user I want to be able to specify account heading
  descriptions in multiple languages.

Background:
  Given a standard test company
    And a logged in admin user

Scenario: Add translations for an account heading description
  When I navigate the menu and select the item at "General Journal > Chart of Accounts"
  Then I should see the Chart of Accounts screen
  When I click Account Number "4000"
   And I wait for the page to load
  Then I should see the Account screen
  When I select the "Translations" tab
  Then I expect the "Spanish" field to contain ""
   And I expect the "French" field to contain ""
  When I enter "Ingresos por ventas" into "Spanish"
   And I enter "Revenu de vente" into "French"
   And I save the translations
  Then I should see the Account screen
  When I select the "Translations" tab
  Then I expect the "Spanish" field to contain "Ingresos por ventas"
   And I expect the "French" field to contain "Revenu de vente"

