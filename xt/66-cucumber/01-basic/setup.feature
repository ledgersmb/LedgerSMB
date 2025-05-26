@weasel @exclude-chrome
Feature: setup.pl database creation and migration functionalities
  In order to create company databases or migrate company databases
  from earlier versions and SQL-Ledger, we want system admins to be
  able to use the setup.pl functionalities involved.



Background:
  Given a database super-user

Scenario: Create a company *with* CoA
 Given a nonexistent company named "setup-test"
   And a nonexistent user named "the-user"
  When I navigate to the setup login page
   And I log into the company using the super-user credentials
  Then I should see the company creation page
  When I confirm database creation with these parameters:
      | parameter name    | value         |
      | Country           | United States |
      | Chart of accounts | General.xml   |
      | Templates         | demo          |
  Then I should see the user creation page
  When I create a user with these values:
      | label              | value            |
      | Username           | the-user         |
      | Password           | abcd3fg          |
      | Salutation         | Mr.              |
      | First Name         | A                |
      | Last name          | Dmin             |
      | Employee Number    | 00000001         |
      | Date of Birth      | 2006-01-09       |
      | Tax ID/SSN         | 00000002         |
      | Country            | United States    |
      | Assign Permissions | Full Permissions |
  Then I should see the setup confirmation page


Scenario: Login procedure
 Given an existing company named "setup-test"
  When I navigate to the setup login page
   And I log into the company using the super-user credentials
  Then I should see my setup.pl credentials

Scenario: List users in a company
 Given an existing company named "setup-test"
  When I navigate to the setup login page
   And I log into the company using the super-user credentials
  Then I should see the setup admin page
  When I request the users list
  Then I should see the setup user list page
   And I should see the table of available users:
      | Username |
      | the-user |


Scenario: Edit user in a company
 Given an existing company named "setup-test"
  When I navigate to the setup login page
   And I log into the company using the super-user credentials
  Then I should see the setup admin page
  When I request the users list
  Then I should see the setup user list page
   And I should see the table of available users:
      | Username |
      | the-user |
  When I request the user overview for "the-user"
  Then I should see the edit user page
   And I should see all permission checkboxes checked


Scenario: Add user to a company
 Given an existing company named "setup-test"
   And a nonexistent user named "the-user2"
  When I navigate to the setup login page
   And I log into the company using the super-user credentials
  Then I should see the setup admin page
  When I request to add a user
  Then I should see the user creation page
  When I create a user with these values:
      | label              | value            |
      | Username           | the-user2        |
      | Password           | klm2fly          |
      | Salutation         | Mr.              |
      | First Name         | Common           |
      | Last name          | User             |
      | Employee Number    | 00000010         |
      | Date of Birth      | 2006-09-06       |
      | Tax ID/SSN         | 00000003         |
      | Country            | United States    |
      | Assign Permissions | No changes       |
  Then I should see the setup confirmation page
  When I navigate to the setup login page
   And I log into the company using the super-user credentials
  Then I should see the setup admin page
  When I request the users list
  Then I should see the setup user list page
   And I should see the table of available users:
      | Username  |
      | the-user  |
      | the-user2 |

Scenario: Add a 'manage users' admin to a company
 Given an existing company named "setup-test"
   And a nonexistent user named "the-admin"
  When I navigate to the setup login page
   And I log into the company using the super-user credentials
  Then I should see the setup admin page
  When I request to add a user
  Then I should see the user creation page
  When I create a user with these values:
      | label              | value            |
      | Username           | the-admin        |
      | Password           | airmiles         |
      | Salutation         | Mr.              |
      | First Name         | User             |
      | Last name          | Admin            |
      | Employee Number    | 00000011         |
      | Date of Birth      | 2006-09-07       |
      | Tax ID/SSN         | 00000004         |
      | Country            | United States    |
      | Assign Permissions | Manage Users     |
  Then I should see the setup confirmation page
  When I navigate to the setup login page
   And I log into the company using the super-user credentials
  Then I should see the setup admin page
  When I request the users list
  Then I should see the setup user list page
   And I should see the table of available users:
      | Username  |
      | the-user  |
      | the-user2 |
      | the-admin |
  When I request the user overview for "the-admin"
  Then I should see the edit user page
   And I should see only these permission checkboxes checked:
      | perms label  |
      | base user    |
      | users manage |


Scenario: Copy a company
 Given a nonexistent company named "setup-test2"
   And an existing company named "setup-test"
  When I navigate to the setup login page
   And I log into the company using the super-user credentials
  Then I should see the setup admin page
  When I copy the company to "setup-test2"
  Then I should see the setup confirmation page
  When I navigate to the setup login page
   And I log into "setup-test2" using the super-user credentials
  Then I should see the setup admin page

Scenario: Create database with ampersand in the name
 Given a nonexistent company named "setup&.test"
   And a nonexistent user named "the&.user"
  When I navigate to the setup login page
   And I log into the company using the super-user credentials
  Then I should see the company creation page
  When I confirm database creation with these parameters:
      | parameter name    | value         |
      | Country           | United States |
      | Chart of accounts | General.xml   |
      | Templates         | demo          |
  Then I should see the user creation page
  When I create a user with these values:
      | label              | value            |
      | Username           | the&.user        |
      | Password           | abcd3fg          |
      | Salutation         | Mr.              |
      | First Name         | A                |
      | Last name          | Dmin             |
      | Employee Number    | 00000001         |
      | Date of Birth      | 2006-09-01       |
      | Tax ID/SSN         | 00000002         |
      | Country            | United States    |
      | Assign Permissions | Full Permissions |
  Then I should see the setup confirmation page

Scenario: Login procedure with ampersand
 Given an existing company named "setup&.test"
  When I navigate to the setup login page
   And I log into the company using the super-user credentials
  Then I should see my setup.pl credentials


#Scenario: Upgrade a comapny from 1.4
# Given a 1.4 company named "upgrade-test"
#  When I navigate to the setup login page
#   And I log into the company using the super-user credentials
#  Then I should see the setup admin page
#  When I upgrade the database
#  Then I should see the setup confirmation page

