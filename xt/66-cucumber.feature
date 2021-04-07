# HARNESS-DURATION-SHORT
@weasel
Feature: Test redirection

Scenario: Redirecting / to /login.pl
  When I navigate to the application root
  Then I should see the application login page
