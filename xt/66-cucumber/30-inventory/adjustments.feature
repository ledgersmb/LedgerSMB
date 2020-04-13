@weasel
Feature: Adjusting stock levels
  As a trading or manufacturing company, I want to be able to
  adjust inventory when inventory counts don't correspond to the
  recorded levels, find these adjustments in the inventory activty
  report and be able to search for inventory adjustment reports.


# Note: we need a way to list inventory; 'part_edit' isn't that role...
#     And a logged in user with 'part_edit' rights


Scenario: Adjusting recorded inventory down (to a lower count)
     Note that half way through, we check that the adjustment was entered, but
     not yet approved. In that stage, there should not be a balance or inventory
     impact yet.
   Given a standard test company
     And a vendor "v1"
     And a part with these properties:
       | name       | value          |
       | partnumber | P001           |
       | description| Test part 001  |
       | sellprice  | 3.50           |
     And inventory has been built up for 'P001' from these transactions:
       | type     |  amount  | price  | vendor | transdate  |
       | purchase |  10      | 20     | v1     | 2016-11-11 |
     And a logged in admin
    When I search for part 'P001'
    Then I expect the 'On Hand' report column to contain '10' for Part Number 'P001'
    When I open the parts screen for 'P001'
    Then I expect to see the 'onhand' value of '10'
    When I create an inventory adjustment dated 2016-11-28 with these counts:
       | Partnumber | Counted |
       | P001       | 8       |
     And I open the parts screen for 'P001'
    Then I expect to see the 'onhand' value of '10'
    When I search for part 'P001'
    Then I expect the 'On Hand' report column to contain '10' for Part Number 'P001'
    When I approve the inventory adjustment
     And I open the parts screen for 'P001'
    Then I expect to see the 'onhand' value of '8'
    When I search for part 'P001'
    Then I expect the 'On Hand' report column to contain '8' for Part Number 'P001'
