#
# Copyright (C) 2022 Vaticle
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#

@ignore-typedb-client-java
@ignore-typedb-client-python
@ignore-typedb-client-nodejs
Feature: Connection Users

  Scenario: users can be created and deleted
    When connect as user admin with password password
    Then users contains: admin
    And users not contains: user
    When users create: user, password
    And users contains: user
    And user password set: user, new-password
    And user connect: user, new-password
    And users delete: user
    Then users not contains: user

  Scenario: user passwords must comply with the minimum length
    Given cluster has configuration
      |server.authentication.password-policy.complexity.min-length|5|
      |server.authentication.password-policy.complexity.enable|true|
    When cluster starts
    And connect as user admin with password password
    And users create: user, password
    And users create: user2, passw
    And users create: user3, pass; throws exception

  Scenario: user passwords must comply with the minimum number of lowercase characters
    Given cluster has configuration
      |server.authentication.password-policy.complexity.min-lowercase|2|
      |server.authentication.password-policy.complexity.enable|true|
    When cluster starts
    And connect as user admin with password password
    And users create: user, password
    And users create: user2, paSSWORD
    And users create: user3, PASSWORD; throws exception

  Scenario: user passwords must be unique for a certain history size
    Given cluster has configuration
      |server.authentication.password-policy.unique-history-size|3|
    When cluster starts
    And connect as user admin with password password
    And users create: user, password
    And disconnect current user
    And connect as user user with password password
    And user password update: password, new-password
    And user password update: new-password, newer-password
    And user password update: newer-password password; throws exception
    And user password update: newer-password newest-password

  Scenario non-admin user cannot perform permissioned actions
    When cluster starts
    And connect as user admin with password password
    And users create: user, password
    And users create: user2, password2
    And disconnect current user
    And connect as user user with password password
    And users get all; throws exception
    And users get user admin; throws exception
    And users create: user3, password; throws exception
    And users contains admin; throws exception
    And users delete admin; throws exception
    And users delete user2; throws exception
    And users password set: user2, new-password; throws exception


  testMinLength
  testMinLowercase
  testMinUppercase
  testMinNumerics
  testMinSpecialChars
  testMinDifferentChars
  testUniqueHistorySize
  testUserCannotGetAll
  testUserCannotCreate
  testUserCannotDelete
  testUserCannotContains
  testUserCannotPasswordSet
  testUserCannotPasswordUpdateAnotherUser
  testDeletion
