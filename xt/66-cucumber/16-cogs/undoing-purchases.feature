# HARNESS-DURATION-MEDIUM
Feature: COGS from performing corrections on purchases
   In the event a purchase invoice needs correction, COGS may need to
   be corrected as a consequence.

   Please note that Returns are different from corrections in the
   sense that these belong to a different business process.

Background:
  Given a standard test company

Scenario: COGS from negative purchase quantities (inventory change)
  Given 10 units inventory of a part purchased at 10 USD each
    And 8 units sold
   When -2 units are purchased at 10 USD each
   Then COGS should be at 80 USD
    And the inventory should be at 0 USD

Scenario: COGS from negative purchase quantities (sales to back-order)
  Given 10 units inventory of a part purchased at 10 USD each
    And 8 units sold
   When -4 units are purchased at 10 USD each
   Then COGS should be at 60 USD
    And the inventory should be at 0 USD

Scenario: COGS from negative purchase quantities (full return of inventory)
  Given 10 units inventory of a part purchased at 10 USD each
   When -10 units are purchased at 10 USD each
   Then COGS should be at 0 USD
    And the inventory should be at 0 USD

Scenario: COGS from negative purchase quantities (full return of inventory -- sold)
  Given 10 units inventory of a part purchased at 10 USD each
    And 10 units sold
   When -10 units are purchased at 10 USD each
   Then COGS should be at 0 USD
    And the inventory should be at 0 USD

