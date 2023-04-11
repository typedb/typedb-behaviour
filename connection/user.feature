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

Feature: Connection Users

  Scenario: users can be created and deleted
    When typedb starts
    And user connect: admin, password
    Then users contains: admin
    And users not contains: user
    When users create: user, password
    And users create: user2, password2
    And users contains: user
    And users contains: user2
    And users password set: user, new-password
    And users delete: user2
    And user disconnect
    And user connect: user, new-password
    And user disconnect
    And user connect: admin, password
    And users delete: user
    Then users not contains: user

  Scenario: user passwords must comply with the minimum length
    Given typedb has configuration
      |server.authentication.password-policy.complexity.min-length|5|
      |server.authentication.password-policy.complexity.enable|true|
    When typedb starts
    And user connect: admin, password
    And users create: user, password
    And users create: user2, passw
    And users create: user3, pass; throws exception

  Scenario: user passwords must comply with the minimum number of lowercase characters
    Given typedb has configuration
      |server.authentication.password-policy.complexity.min-lowercase|2|
      |server.authentication.password-policy.complexity.enable|true|
    When typedb starts
    And user connect: admin, password
    And users create: user, password
    And users create: user2, paSSWORD
    And users create: user3, PASSWORD; throws exception

  Scenario: user passwords must comply with the minimum number of uppercase characters
    Given typedb has configuration
      |server.authentication.password-policy.complexity.min-uppercase|2|
      |server.authentication.password-policy.complexity.enable|true|
    When typedb starts
    And user connect: admin, password
    And users create: user, PASSWORD
    And users create: user2, PAssword
    And users create: user3, password; throws exception

  Scenario: user passwords must comply with the minimum number of numeric characters
    Given typedb has configuration
      |server.authentication.password-policy.complexity.min-numerics|2|
      |server.authentication.password-policy.complexity.enable|true|
    When typedb starts
    And user connect: admin, password
    And users create: user, PASSWORD789
    And users create: user2, PASSWORD78
    And users create: user3, PASSWORD7; throws exception

  Scenario: user passwords must comply with the minimum number of special characters
    Given typedb has configuration
      |server.authentication.password-policy.complexity.min-special-chars|2|
      |server.authentication.password-policy.complexity.enable|true|
    When typedb starts
    And user connect: admin, password
    And users create: user, PASSWORD!@£
    And users create: user2, PASSWORD&(
    And users create: user3, PASSWORD); throws exception

  Scenario: user passwords must comply with the minimum number of different characters
    Given typedb has configuration
      |server.authentication.password-policy.complexity.min-different-chars|4|
      |server.authentication.password-policy.complexity.enable|true|
    When typedb starts
    And user connect: admin, password
    And users create: user, password
    And user disconnect
    And user connect: user, password
    And user password update: password, new-password
    And user disconnect
    And user connect: user, new-password
    And user password update: new-password, bad-password; throws exception
    And user password update: new-password, even-newer-password
    And user disconnect
    And user connect: user, even-newer-password

  Scenario: user passwords must be unique for a certain history size
    Given typedb has configuration
      |server.authentication.password-policy.unique-history-size|2|
    When typedb starts
    And user connect: admin, password
    And users create: user, password
    And user disconnect
    And user connect: user, password
    And user password update: password, password; throws exception
    And user password update: password, new-password
    And user disconnect
    And user connect: user, new-password
    And user password update: new-password, password; throws exception
    And user disconnect
    And user connect: user, new-password
    And user password update: new-password, newer-password
    And user disconnect
    And user connect: user, newer-password
    And user password update: newer-password, newest-password
    And user connect: user, newest-password
    And user password update: newest-password, password

  Scenario: user can check their own password expiration seconds
    Given typedb has configuration
      |server.authentication.password-policy.expiration.enable|true|
      |server.authentication.password-policy.expiration.min-duration|0s|
      |server.authentication.password-policy.expiration.max-duration|5d|
    When typedb starts
    And user connect: admin, password
    And users create: user, password
    And user disconnect
    And user connect: user, password
    And user expiry-seconds

  Scenario: user passwords expire
    Given typedb has configuration
      |server.authentication.password-policy.expiration.enable|true|
      |server.authentication.password-policy.expiration.min-duration|0s|
      |server.authentication.password-policy.expiration.max-duration|5s|
    When typedb starts
    And user connect: admin, password
    And users create: user, password
    And user disconnect
    And wait 5 seconds
    And user connect: user, password; throws exception

  Scenario: non-admin user cannot perform permissioned actions
    When typedb starts
    And user connect: admin, password
    And users create: user, password
    And users create: user2, password2
    And user disconnect
    And user connect: user, password
    And users get all; throws exception
    And users get user: admin; throws exception
    And users create: user3, password; throws exception
    And users contains: admin; throws exception
    And users delete: admin; throws exception
    And users delete: user2; throws exception
    And users password set: user2, new-password; throws exception