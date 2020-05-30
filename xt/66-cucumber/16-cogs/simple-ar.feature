Feature: FIFO COGS posting on AR invoice
  As part of posting an AR invoice which includes goods, there
  should be posting of Cost Of Goods Sold (COGS). COGS are known
  to be required to use various different valuation approaches
  in various jurisdictions.

  LedgerSMB supports only the FIFO method out of the box; this
  feature tests the FIFO approach to COGS.

Background:
  Given a standard test company

# Scenario: no COGS posting for services

Scenario: COGS posting for goods (excess inventory)
  Given 10 units inventory of a part purchased at 10 USD each
   When 3 units are sold
   Then the inventory should be at 70 USD
    And COGS should be at 30 USD


# Scenario: correct COGS for mixed parts & services invoice


Scenario: COGS posting for goods (exact-match inventory)
  Given 10 units inventory of a part purchased at 10 USD each
   When 10 units are sold
   Then the inventory should be at 0 USD
    And COGS should be at 100 USD

Scenario: COGS posting for goods (short inventory)
  Given 10 units inventory of a part purchased at 10 USD each
   When 12 units are sold
   Then the inventory should be at 0 USD
    And COGS should be at 100 USD
#    And the on-hand amount for the part should be -2


