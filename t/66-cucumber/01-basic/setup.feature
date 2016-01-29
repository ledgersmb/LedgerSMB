Feature: setup.pl database creation and migration functionalities
  In order to create company databases or migrate company databases
  from earlier versions and SQL-Ledger, we want system admins to be
  able to use the setup.pl functionalities involved.



Background:
  Given a database super-user
    And a LedgerSMB instance


Scenario: Logging into setup.pl, creating a company *with* CoA
 Given a non-existant company name
  When I navigate to '/setup.pl'
   And I enter the super-user password into "Password"
   And I enter the super-user name into "Super-user login"
   And I enter the company name into "Database"
   And I press "Login"
  Then I should see "Database Management Console"
   And I should see "Database does not exist"
   And I should see "Create Database"
  When I press "Yes"
  Then I should see a button "Next"
   And I should see a button "Skip"
   And I should see a drop down "Country Code"
  When I select "us" from the drop down "Country Code"
   And I press "Next"
  Then I should see a button "Next"
   And I should see a button "Skip"
   And I should see a drop down "Chart of accounts" with these items:
      | text              |
      | General.sql       |
      | Manufacturing.sql |
  When I select "General.sql" from the drop down "Chart of accounts"
   And I press "Next"
  Then I should see "Select Templates to Load"
   And I should see a button "Load Templates"
   And I should see a drop down "Templates" with these items:
      | text              |
      | demo              |
      | demo_with_images  |
      | xedemo            |
  When I select "demo" from the drop down "Templates"
   And I press "Load Templates"
  Then I should see these fields:
      | label              |
      | Username           |
      | Password           |
      | Yes                |
      | No                 |
      | Salutation         |
      | First Name         |
      | Last name          |
      | Employee Number    |
      | Date of Birth      |
      | Tax ID/SSN         |
      | Country            |
      | Assign Permissions |
  When I enter "the-user" into "Username"
   And I enter "the-password" into "Password"
   And I enter these values:
      | label              | value            |
      | Salutation         | Mr.              |
      | First Name         | A                |
      | Last name          | Dmin             |
      | Employee Number    | 00000001         |
      | Date of Birth      | 09/01/2006       |
      | Tax ID/SSN         | 00000002         |
      | Country            | United States    |
      | Assign Permissions | Full Permissions |
   And I press "Create User"
  Then I should see "LedgerSMB may now be used."
