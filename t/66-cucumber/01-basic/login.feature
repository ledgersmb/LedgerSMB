Feature: Correct operation of setup.pl and login.pl login pages
   In order to assess the further quality of the software,
   we want to assess the availability and correct operation of
   the functionality of logging in, both as an admin and as a user.

Background:
  Given a user named "Admin" with a password "a6m1n"
    And a LedgerSMB instance at "http://localhost:5000"


Scenario: Viewing setup.pl
  When I navigate to the setup login page
  Then I should see the setup login page


Scenario: Viewing login.pl
  When I navigate to the application login page
  Then I should see the application login page

