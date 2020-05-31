Feature: COGS from performing corrections on sales
   In the event a sales invoice needs correction, COGS may need to
   be corrected as a consequence.

   Please note that Returns are different from corrections in the
   sense that these belong to a different business process.

Background:
  Given a standard test company

Scenario: COGS from negative sales quantities
  Given 10 units inventory of a part purchased at 10 USD each
   When 8 units are sold
    And -2 units are sold
   Then COGS should be at 60 USD
    And the inventory should be at 40 USD

Scenario: COGS from credit invoice
  Given 10 units inventory of a part purchased at 10 USD each
   When 8 units are sold
    And 2 units are credited
   Then COGS should be at 60 USD
    And the inventory should be at 40 USD

Scenario: COGS from negative sales quantities (arrears purchase)
  Given a part
    And 8 units sold
   When -2 units are sold
    And 8 units are purchased at 10 USD each
   Then COGS should be at 60 USD
    And the inventory should be at 20 USD

Scenario: COGS from credit invoice (arrears purchase)
  Given a part
    And 8 units sold
   When 2 units are credited
    And 8 units are purchased at 10 USD each
   Then COGS should be at 60 USD
    And the inventory should be at 20 USD
