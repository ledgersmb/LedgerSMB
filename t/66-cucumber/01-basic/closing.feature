@one-db @weasel
Feature: correct operation of period closing and year end posting
  As an accounting admin, I want to make sure users can't post new
  transactions to prior periods and/or years as of a moment I designate.


Background:
  Given a standard test company
    And a logged in admin
# should have been : And a logged in accounting user

Scenario: Closed books disallow posting
 Given the following GL transaction posted on 2015-11-01:
     | accno   |  debit_bc |  credit_bc  |
     | 1060    |   200.00  |             |
     | 2210    |           |   200.00    |
  When I navigate the menu and select the item at "General Journal > Year End"
   And I select the "Close Period" tab
   And I enter "2015-11-30" into "Close As-Of"
   And I press "Close Period"
  Then I can't post a transaction on 2015-11-16


Scenario: Reopen a closed period
  When I navigate the menu and select the item at "General Journal > Year End"
   And I select the "Re-open Books" tab
   And I enter "2015-11-16" into "Re-Open As Of"
   And I press "Re-open Period"
  Then I can't post a transaction on 2015-11-15
  When I post the following GL transaction on 2015-11-16:
     | accno   |  debit_bc |  credit_bc  |
     | 2210    |   215.00  |             |
     | 5610    |           |   215.00    |
  Then the Balance Sheet per 2016-01-01 looks like:
     | accno               |  type      |  amount  |
     | 1060                |  asset     |   200.00 |
     | 2210                |  liability |   -15.00 |
     | current earnings    |  equity    |   215.00 |


Scenario: Post year-end
  When I navigate the menu and select the item at "General Journal > Year End"
   And I select the "Close Year" tab
   And I enter these values:
     | label             | value                                 |
     | Yearend           |                            2015-12-31 |
     | Retained Earnings | 3590--Retained Earnings - prior years |
   And I press "Post Yearend"
  Then I should see the year-end confirmation screen
   And the Balance Sheet per 2015-12-31 looks like:
     | accno  |  type      |  amount  |
     | 1060   |  asset     |   200.00 |
     | 2210   |  liability |   -15.00 |
     | 3590   |  equity    |   215.00 |
