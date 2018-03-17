@wip @weasel
Feature: Check correct operation of Change Password screen

Background:
  Given a logged in user with a password "a6m1n"


Scenario: Error when "Old Password" field is empty
  When I navigate the menu and select the item at "Preferences"
   And I enter "" into "Old Password"
   And I enter "a new password" into "New password"
   And I enter "a new password" into "Verify"
  Then I should see an error message "Password Required"

Scenario: Error when no new password is entered
  When I navigate the menu and select the item at "Preferences"
   And I enter "a6m1n" into "Old Password"
   And I enter "" into "New password"
   And I enter "" into "Verify"
  Then I should see an error message "Password Required"

Scenario: Error when "New Password" and "Verify" fields don't match
  When I navigate the menu and select the item at "Preferences"
   And I enter "a6m1n" into "Old Password"
   And I enter "a new password" into "New password"
   And I enter "a different password" into "Verify"
  Then I should see an error message "Confirmation did not match"

Scenario: Error when the "Old Password" field is incorrect
  When I navigate the menu and select the item at "Preferences"
   And I enter "the wrong password" into "Old Password"
   And I enter "a new password" into "New password"
   And I enter "a new password" into "Verify"
  Then I should see an error message "Bad username/Password"

Scenario: Successfully change password
  When I navigate the menu and select the item at "Preferences"
   And I enter "a6m1n" into "Old Password"
   And I enter "a new password" into "New password"
   And I enter "a new password" into "Verify"
  Then I should see a message "Password Changed"

