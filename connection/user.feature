# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

# TODO: remove ignores for driver-python and driver-node once bootup can be configured through BDD
#noinspection CucumberUndefinedStep
Feature: Connection Users

  Scenario: users can be created and deleted, connection is only available for existing users
    Given typedb starts
    Given connection opens with username "admin", password "password"
    Then get users contains: admin
    Then get users does not contain: user
    When create user with username "user", password "password"
    When create user with username "user2", password "password2"
    Then get users contains: user
    Then get users contains: user2
    # TODO: Move to another test
    When get user(user) set password: new-password
    When delete user: user2
    Then get users contains: user
    Then get users does not contain: user2
    When connection closes
    Then connection opens with username "user2", password "password2"; fails
    Then connection opens with username "user2", password "password"; fails
    Then connection opens with username "user2", password "new-password"; fails
    Then connection opens with username "user", password "password"; fails
    Then connection opens with username "user", password "new-password"
    When connection closes
    Then connection opens with username "admin", password "new-password"; fails
    Then connection opens with username "admin", password "password"
    When delete user: user
    Then get users does not contain: user


  Scenario: connected user is retrievable
    Given typedb starts
    Given connection opens with username "admin", password "password"
    When create user with username "user", password "password"
    # TODO: check the connected user???
    Then connection user exists
    When connection closes
    When connection opens with username "user", password "password"
    # TODO: check the connected user???
    Then connection user exists


  Scenario: non-admin user cannot perform permissioned actions
    Given typedb starts
    Given connection opens with username "admin", password "password"
    Then create user with username "user", password "password"
    Then create user with username "user2", "password2"
    When connection closes
    When connection opens with username "user", password "password"
    Then get all users; fails
    Then get user: admin; fails
    Then create user with username "user3", password "password"; fails
    Then delete user: admin; fails
    Then delete user: user2; fails
    Then get user(user2) set password: new-password; fails

  ##################
  # CONFIG OPTIONS #
  ##################

# TODO: Uncomment when config for password policy is introduced

#  @ignore-typedb-driver
#  Scenario: user passwords must comply with the minimum length
#    Given typedb has configuration
#      |server.authentication.password-policy.complexity.enable|true|
#      |server.authentication.password-policy.complexity.min-length|5|
#    Given typedb starts
#    Given connection opens with username "admin", password "password"
#    Then create user with username "user", password "password"
#    Then create user with username "user2", password "passw"
#    Then create user with username "user3", password "pass"; fails


#  @ignore-typedb-driver
#  Scenario: user passwords must comply with the minimum number of lowercase characters
#    Given typedb has configuration
#      |server.authentication.password-policy.complexity.enable|true|
#      |server.authentication.password-policy.complexity.min-lowercase|2|
#    Given typedb starts
#    Given connection opens with username "admin", password "password"
#    Then create user with username "user", password "password"
#    Then create user with username "user2", password "paSSWORD"
#    Then create user with username "user3", password "PASSWORD"; fails


#  @ignore-typedb-driver
#  Scenario: user passwords must comply with the minimum number of uppercase characters
#    Given typedb has configuration
#      |server.authentication.password-policy.complexity.enable|true|
#      |server.authentication.password-policy.complexity.min-uppercase|2|
#    Given typedb starts
#    Given connection opens with username "admin", password "password"
#    Then create user with username "user", password "password"
#    Then create user with username "user2", password "PAssword"
#    Then create user with username "user3", password "password"; fails


#  @ignore-typedb-driver
#  Scenario: user passwords must comply with the minimum number of numeric characters
#    Given typedb has configuration
#      |server.authentication.password-policy.complexity.enable|true|
#      |server.authentication.password-policy.complexity.min-numeric|2|
#    Given typedb starts
#    Given connection opens with username "admin", password "password"
#    Then create user with username "user", password "password"789
#    Then create user with username "user2", password "PASSWORD78"
#    Then create user with username "user3", password "PASSWORD7"; fails


#  @ignore-typedb-driver
#  Scenario: user passwords must comply with the minimum number of special characters
#    Given typedb has configuration
#      |server.authentication.password-policy.complexity.enable|true|
#      |server.authentication.password-policy.complexity.min-special|2|
#    Given typedb starts
#    Given connection opens with username "admin", password "password"
#    Then create user with username "user", password "password"!@£
#    Then create user with username "user2", password "PASSWORD&("
#    Then create user with username "user3", password "PASSWORD)"; fails


#  @ignore-typedb-driver
#  Scenario: user passwords must comply with the minimum number of different characters
#    Given typedb has configuration
#      |server.authentication.password-policy.complexity.enable|true|
#      |server.authentication.password-policy.min-chars-different|4|
#    Given typedb starts
#    Given connection opens with username "admin", password "password"
#    Then create user with username "user", password "password"
#    When connection closes
#    When connection opens with username "user", password "password"
#    Then connection user update password from "password" to "new-password"
#    When connection closes
#    Then connection opens with username "user", password "new-password"
#    Then connection user update password from "new-password" to "bad-password"; fails
#    Then connection user update password from "new-password" to "even-newer-password"
#    When connection closes
#    When connection opens with username "user", password "even-newer-password"


#  @ignore-typedb-driver
#  Scenario: user passwords must be unique for a certain history size
#    Given typedb has configuration
#      |server.authentication.password-policy.unique-history-size|2|
#    Given typedb starts
#    Given connection opens with username "admin", password "password"
#    Then create user with username "user", password "password"
#    When connection closes
#    When connection opens with username "user", password "password"
#    Then connection user update password from "password" to "password"; fails
#    Then connection user update password from "password" to "new-password"
#    When connection closes
#    When connection opens with username "user", password "new-password"
#    Then connection user update password from "new-password" to "password"; fails
#    When connection closes
#    When connection opens with username "user", password "new-password"
#    Then connection user update password from "new-password" to "newer-password"
#    When connection closes
#    When connection opens with username user, password newer-password
#    Then connection user update password from "newer-password" to "newest-password
#    When connection opens with username user, password newest-password
#    Then connection user update password from "newest-password" to "password"


#  @ignore-typedb-driver
#  Scenario: user can check their own password expiration seconds
#    Given typedb has configuration
#      |server.authentication.password-policy.expiration.enable|true|
#      |server.authentication.password-policy.expiration.min-duration|0s|
#      |server.authentication.password-policy.expiration.max-duration|5d|
#    Given typedb starts
#    Given connection opens with username "admin", password "password"
#    Then create user with username "user", password "password"
#    When connection closes
#    When connection opens with username "user", password "password"
#    Then connection user get expiry-seconds exists


#  @ignore-typedb-driver
#  Scenario: user passwords expire
#    Given typedb has configuration
#      |server.authentication.password-policy.expiration.enable|true|
#      |server.authentication.password-policy.expiration.min-duration|0s|
#      |server.authentication.password-policy.expiration.max-duration|5s|
#    Given typedb starts
#    Given connection opens with username "admin", password "password"
#    Then create user with username "user", password "password"
#    When connection closes
#    When wait 5 seconds
#    Then connection opens with username "user", password "password"; fails
