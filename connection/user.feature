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

# TODO: remove ignores for client-python and client-node once bootup can be configured through BDD
Feature: Connection Users

  Scenario: users can be created and deleted
    Given typedb starts
    Given connection opens with authentication: admin, password
    Then users contains: admin
    Then users not contains: user
    When users create: user, password
    When users create: user2, password2
    When users contains: user
    When users contains: user2
    When users password set: user, new-password
    When users delete: user2
    Then connection closes
    Given connection opens with authentication: user, new-password
    Then connection closes
    Given connection opens with authentication: admin, password
    Given users delete: user
    Then users not contains: user

  Scenario: connected user is retrievable
    Given typedb starts
    Given connection opens with authentication: admin, password
    When users create: user, password
    Then connection closes
    Given connection opens with authentication: user, password
    Then get connected user

  @ignore-typedb-client-python @ignore-typedb-client-nodejs @ignore-typedb-client-rust
  Scenario: user passwords must comply with the minimum length
    Given typedb has configuration
      |server.authentication.password-policy.complexity.min-length|5|
      |server.authentication.password-policy.complexity.enable|true|
    Given typedb starts
    Given connection opens with authentication: admin, password
    Then users create: user, password
    Then users create: user2, passw
    Then users create: user3, pass; throws exception

  @ignore-typedb-client-python @ignore-typedb-client-nodejs @ignore-typedb-client-rust
  Scenario: user passwords must comply with the minimum number of lowercase characters
    Given typedb has configuration
      |server.authentication.password-policy.complexity.min-lowercase|2|
      |server.authentication.password-policy.complexity.enable|true|
    Given typedb starts
    Given connection opens with authentication: admin, password
    Then users create: user, password
    Then users create: user2, paSSWORD
    Then users create: user3, PASSWORD; throws exception

  @ignore-typedb-client-python @ignore-typedb-client-nodejs @ignore-typedb-client-rust
  Scenario: user passwords must comply with the minimum number of uppercase characters
    Given typedb has configuration
      |server.authentication.password-policy.complexity.min-uppercase|2|
      |server.authentication.password-policy.complexity.enable|true|
    Given typedb starts
    Given connection opens with authentication: admin, password
    Then users create: user, PASSWORD
    Then users create: user2, PAssword
    Then users create: user3, password; throws exception

  @ignore-typedb-client-python @ignore-typedb-client-nodejs @ignore-typedb-client-rust
  Scenario: user passwords must comply with the minimum number of numeric characters
    Given typedb has configuration
      |server.authentication.password-policy.complexity.min-numerics|2|
      |server.authentication.password-policy.complexity.enable|true|
    Given typedb starts
    Given connection opens with authentication: admin, password
    Then users create: user, PASSWORD789
    Then users create: user2, PASSWORD78
    Then users create: user3, PASSWORD7; throws exception

  @ignore-typedb-client-python @ignore-typedb-client-nodejs @ignore-typedb-client-rust
  Scenario: user passwords must comply with the minimum number of special characters
    Given typedb has configuration
      |server.authentication.password-policy.complexity.min-special-chars|2|
      |server.authentication.password-policy.complexity.enable|true|
    Given typedb starts
    Given connection opens with authentication: admin, password
    Then users create: user, PASSWORD!@£
    Then users create: user2, PASSWORD&(
    Then users create: user3, PASSWORD); throws exception

  @ignore-typedb-client-python @ignore-typedb-client-nodejs @ignore-typedb-client-rust
  Scenario: user passwords must comply with the minimum number of different characters
    Given typedb has configuration
      |server.authentication.password-policy.complexity.min-different-chars|4|
      |server.authentication.password-policy.complexity.enable|true|
    Given typedb starts
    Given connection opens with authentication: admin, password
    Then users create: user, password
    Then connection closes
    Given connection opens with authentication: user, password
    Then user password update: password, new-password
    Then connection closes
    Given connection opens with authentication: user, new-password
    Then user password update: new-password, bad-password; throws exception
    Then user password update: new-password, even-newer-password
    Then connection closes
    Given connection opens with authentication: user, even-newer-password

  @ignore-typedb-client-python @ignore-typedb-client-nodejs @ignore-typedb-client-rust
  Scenario: user passwords must be unique for a certain history size
    Given typedb has configuration
      |server.authentication.password-policy.unique-history-size|2|
    Given typedb starts
    Given connection opens with authentication: admin, password
    Then users create: user, password
    Then connection closes
    Given connection opens with authentication: user, password
    Then user password update: password, password; throws exception
    Then user password update: password, new-password
    Then connection closes
    Given connection opens with authentication: user, new-password
    Then user password update: new-password, password; throws exception
    Then connection closes
    Given connection opens with authentication: user, new-password
    Then user password update: new-password, newer-password
    Then connection closes
    Given connection opens with authentication: user, newer-password
    Then user password update: newer-password, newest-password
    Given connection opens with authentication: user, newest-password
    And user password update: newest-password, password

  @ignore-typedb-client-python @ignore-typedb-client-nodejs @ignore-typedb-client-rust
  Scenario: user can check their own password expiration seconds
    Given typedb has configuration
      |server.authentication.password-policy.expiration.enable|true|
      |server.authentication.password-policy.expiration.min-duration|0s|
      |server.authentication.password-policy.expiration.max-duration|5d|
    Given typedb starts
    Given connection opens with authentication: admin, password
    Then users create: user, password
    Then connection closes
    Given connection opens with authentication: user, password
    Then user expiry-seconds

  @ignore-typedb-client-python @ignore-typedb-client-nodejs @ignore-typedb-client-rust
  Scenario: user passwords expire
    Given typedb has configuration
      |server.authentication.password-policy.expiration.enable|true|
      |server.authentication.password-policy.expiration.min-duration|0s|
      |server.authentication.password-policy.expiration.max-duration|5s|
    Given typedb starts
    Given connection opens with authentication: admin, password
    Then users create: user, password
    Then connection closes
    Then wait 5 seconds
    Given connection opens with authentication: user, password; throws exception

  Scenario: non-admin user cannot perform permissioned actions
    Given typedb starts
    Given connection opens with authentication: admin, password
    Then users create: user, password
    Then users create: user2, password2
    Then connection closes
    Given connection opens with authentication: user, password
    Then users get all; throws exception
    Then users get user: admin; throws exception
    Then users create: user3, password; throws exception
    Then users contains: admin; throws exception
    Then users delete: admin; throws exception
    Then users delete: user2; throws exception
    Then users password set: user2, new-password; throws exception