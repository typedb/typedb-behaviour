# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

# TODO: remove ignores for driver-python and driver-node once bootup can be configured through BDD
#noinspection CucumberUndefinedStep
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

  @ignore-typedb-driver
  Scenario: user passwords must comply with the minimum length
    Given typedb has configuration
      |server.authentication.password-policy.complexity.enable|true|
      |server.authentication.password-policy.complexity.min-length|5|
    Given typedb starts
    Given connection opens with authentication: admin, password
    Then users create: user, password
    Then users create: user2, passw
    Then users create: user3, pass; fails

  @ignore-typedb-driver
  Scenario: user passwords must comply with the minimum number of lowercase characters
    Given typedb has configuration
      |server.authentication.password-policy.complexity.enable|true|
      |server.authentication.password-policy.complexity.min-lowercase|2|
    Given typedb starts
    Given connection opens with authentication: admin, password
    Then users create: user, password
    Then users create: user2, paSSWORD
    Then users create: user3, PASSWORD; fails

  @ignore-typedb-driver
  Scenario: user passwords must comply with the minimum number of uppercase characters
    Given typedb has configuration
      |server.authentication.password-policy.complexity.enable|true|
      |server.authentication.password-policy.complexity.min-uppercase|2|
    Given typedb starts
    Given connection opens with authentication: admin, password
    Then users create: user, PASSWORD
    Then users create: user2, PAssword
    Then users create: user3, password; fails

  @ignore-typedb-driver
  Scenario: user passwords must comply with the minimum number of numeric characters
    Given typedb has configuration
      |server.authentication.password-policy.complexity.enable|true|
      |server.authentication.password-policy.complexity.min-numeric|2|
    Given typedb starts
    Given connection opens with authentication: admin, password
    Then users create: user, PASSWORD789
    Then users create: user2, PASSWORD78
    Then users create: user3, PASSWORD7; fails

  @ignore-typedb-driver
  Scenario: user passwords must comply with the minimum number of special characters
    Given typedb has configuration
      |server.authentication.password-policy.complexity.enable|true|
      |server.authentication.password-policy.complexity.min-special|2|
    Given typedb starts
    Given connection opens with authentication: admin, password
    Then users create: user, PASSWORD!@£
    Then users create: user2, PASSWORD&(
    Then users create: user3, PASSWORD); fails

  @ignore-typedb-driver
  Scenario: user passwords must comply with the minimum number of different characters
    Given typedb has configuration
      |server.authentication.password-policy.complexity.enable|true|
      |server.authentication.password-policy.min-chars-different|4|
    Given typedb starts
    Given connection opens with authentication: admin, password
    Then users create: user, password
    Then connection closes
    Given connection opens with authentication: user, password
    Then user password update: password, new-password
    Then connection closes
    Given connection opens with authentication: user, new-password
    Then user password update: new-password, bad-password; fails
    Then user password update: new-password, even-newer-password
    Then connection closes
    Given connection opens with authentication: user, even-newer-password

  @ignore-typedb-driver
  Scenario: user passwords must be unique for a certain history size
    Given typedb has configuration
      |server.authentication.password-policy.unique-history-size|2|
    Given typedb starts
    Given connection opens with authentication: admin, password
    Then users create: user, password
    Then connection closes
    Given connection opens with authentication: user, password
    Then user password update: password, password; fails
    Then user password update: password, new-password
    Then connection closes
    Given connection opens with authentication: user, new-password
    Then user password update: new-password, password; fails
    Then connection closes
    Given connection opens with authentication: user, new-password
    Then user password update: new-password, newer-password
    Then connection closes
    Given connection opens with authentication: user, newer-password
    Then user password update: newer-password, newest-password
    Given connection opens with authentication: user, newest-password
    And user password update: newest-password, password

  @ignore-typedb-driver
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

  @ignore-typedb-driver
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
    Given connection opens with authentication: user, password; fails

  Scenario: non-admin user cannot perform permissioned actions
    Given typedb starts
    Given connection opens with authentication: admin, password
    Then users create: user, password
    Then users create: user2, password2
    Then connection closes
    Given connection opens with authentication: user, password
    Then users get all; fails
    Then users get user: admin; fails
    Then users create: user3, password; fails
    Then users contains: admin; fails
    Then users delete: admin; fails
    Then users delete: user2; fails
    Then users password set: user2, new-password; fails
