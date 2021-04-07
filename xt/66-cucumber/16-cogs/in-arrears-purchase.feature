# HARNESS-DURATION-SHORT
Feature: COGS posted on purchase when inventory sold short
  In case inventory is sold short - which can both happen when the true
  sequence is to sell before buy *or* when transactions are entered
  out-of-order during periodic bookkeeping - COGS should be posted as
  soon as the price of the goods is known. That condition is met the moment
  the purchase invoice is posted.

# Scenario: no COGS posting when purchasing services

Background:
  Given a standard test company
    And a part

Scenario: COGS posting when purchasing parts in arrears (still short)
  Given 10 units sold
   When 5 units are purchased at 10 USD each
   Then the inventory should be at 0 USD
    And COGS should be at 50 USD

Scenario: COGS posting when purchasing parts in arrears (exact match)
  Given 10 units sold
   When 10 units are purchased at 10 USD each
   Then the inventory should be at 0 USD
    And COGS should be at 100 USD

Scenario: COGS posting when purchasing parts in arrears (partly into inventory)
  Given 10 units sold
   When 20 units are purchased at 10 USD each
   Then the inventory should be at 100 USD
    And COGS should be at 100 USD

