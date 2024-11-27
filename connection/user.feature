# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

# TODO: remove ignores for driver-python and driver-node once bootup can be configured through BDD
#noinspection CucumberUndefinedStep
Feature: Connection Users

  Scenario: Users can be created and deleted, connection is only available for existing users
    Given typedb starts
    Given connection opens with username "admin", password "password"
    Then connection has 1 user
    Then get users contains: admin
    Then get users does not contain: user
    When create user with username "user", password "password"
    When create user with username "user2", password "password2"
    When create user with username "user3", password "password3"
    Then get users contains: user
    Then get users contains: user2
    Then get users contains: user3
    When delete user: user2
    Then get users contains: user
    Then get users does not contain: user2
    Then get users contains: user3
    Then connection has 3 user
    Then get all users:
      | admin |
      | user  |
      | user3 |
    When connection closes
    Then connection opens with username "user2", password "password"; fails
    Then connection opens with username "user2", password "password2"; fails
    Then connection opens with username "user2", password "password3"; fails
    Then connection opens with username "user", password "password2"; fails
    Then connection opens with username "user", password "password3"; fails
    Then connection opens with username "user", password "password"
    When connection closes
    Then connection opens with username "user3", password "password"; fails
    Then connection opens with username "user3", password "password3"
    When connection closes
    Then connection opens with username "admin", password "password2"; fails
    Then connection opens with username "admin", password "password3"; fails
    Then connection opens with username "admin", password "password"
    When delete user: user
    Then get users does not contain: user


    # TODO: Maybe we want to restrict it just like database names?
  Scenario Outline: User names can contain any UTF symbols, the validation is case-sensitive (<name>)
    Given typedb starts
    Given connection opens with username "admin", password "password"
    When create user with username "<name>", password "password"
    Then get user(<name>) get name: <name>
    # TODO: Rename step to "get all users"?
    Then get users contains: <name>
    Then get does not contain: <wrong-name>
    Then get all users:
      | admin  |
      | <name> |
    Then get user(<name>) get name: <name>
    When connection closes

    Then connection opens with username "<wrong-name>", password "password"; fails
    Then connection opens with username "<name>", password "password"
    Examples:
      | name                                                                  | wrong-name |
      | bob                                                                   | BoB        |
      | BoB                                                                   | Bob        |
      | Bob                                                                   | bob        |
      | cAn-be_Like-that_WITH-a_pretty-looooooooooooong_name-and·even‿a·smile | c          |
      | ??(!@(**(£                                                            | ?(!@(**(£  |
      | 資料庫                                                                 | 資料        |
      | ·‿·                                                                   | =)         |
      | 😎                                                                    | B)         |


  Scenario Outline: User passwords can contain any UTF symbols, the validation is case-sensitive (<pass>)
    Given typedb starts
    Given connection opens with username "admin", password "password"
    When create user with username "user", password "<pass>"
    When connection closes

    Then connection opens with username "user", password "<wrong-pass>"; fails
    Then connection opens with username "user", password "<pass>"
    Examples:
      | pass                                                                  | wrong-pass |
      | bob                                                                   | BoB        |
      | BoB                                                                   | Bob        |
      | Bob                                                                   | bob        |
      | cAn-be_Like-that_WITH-a_pretty-looooooooooooong_name-and·even‿a·smile | c          |
      | ??(!@(**(£                                                            | ?(!@(**(£  |
      | 資料庫                                                                 | 資料        |
      | ·‿·                                                                   | =)         |
      | 😎                                                                    | B)         |


  Scenario: User cannot be created multiple times
    Given typedb starts
    Given connection opens with username "admin", password "password"
    When create user with username "user", password "password"
    Then create user with username "user", password "password"; fails
    Then create user with username "user", password "new-password"; fails
    Then create user with username "admin", password "password"; fails
    Then create user with username "admin", password "new-password"; fails


  Scenario: User can be created after deletion
    Given typedb starts
    Given connection opens with username "admin", password "password"
    When create user with username "user", password "password"
    When delete user: user
    When connection closes

    Then connection opens with username "user", password "password"
    When connection closes

    Given connection opens with username "admin", password "password"
    Then create user with username "user", password "password"
    When delete user: user
    Then create user with username "user", password "new-password"
    When connection closes

    Then connection opens with username "user", password "password"; fails
    Then connection opens with username "user", password "new-password"


  Scenario: Admin user cannot be deleted
    Given typedb starts
    Given connection opens with username "admin", password "password"
    Then delete user: admin; fails
    When create user with username "user", password "password"
    Then delete user: admin; fails
    Then delete user: user
    When create user with username "user2", password "password"
    When connection closes

    When connection opens with username "user2", password "password"
    Then delete user: admin; fails


  Scenario: User can be created multiple times
    Given typedb starts
    Given connection opens with username "admin", password "password"
    When create user with username "user", password "password"
    When delete user: user
    Then delete user: user
    Then delete user: user2
    Then delete user: surely-non-existing-user


  Scenario: User's name is retrievable only by admin
    Given typedb starts
    Given connection opens with username "admin", password "password"
    When create user with username "user", password "password"
    Then get user(user) get name: user
    Then get user(admin) get name: admin
    When connection closes

    When connection opens with username "user", password "password"
    Then get user: user; fails
    Then get user: admin; fails


  Scenario: All users are retrievable only by admin
    Given typedb starts
    Given connection opens with username "admin", password "password"
    When create user with username "user", password "password"
    When create user with username "user2", password "password"
    Then get all users:
      | admin |
      | user  |
      | user2 |
    When connection closes

    When connection opens with username "user", password "password"
    Then get all users; fails


  Scenario: Users can be created only by admin
    Given typedb starts
    Given connection opens with username "admin", password "password"
    Then create user with username "user", password "password"
    Then create user with username "user2", password "password"
    When connection closes

    When connection opens with username "user", password "password"
    Then create user with username "user3", password "password"; fails
    Then create user with username "user2", password "password"; fails
    Then create user with username "user", password "password"; fails
    When connection closes

    When connection opens with username "admin", password "password"
    Then create user with username "user3", password "password"


  Scenario: Users can be deleted only by admin
    Given typedb starts
    Given connection opens with username "admin", password "password"
    When create user with username "user", password "password"
    When create user with username "user2", password "password"
    When create user with username "user3", password "password"
    When create user with username "user4", password "password"
    When create user with username "user5", password "password"
    Then delete user: user4
    When connection closes

    When connection opens with username "user", password "password"
    Then delete user: user5; fails
    Then delete user: user4; fails
    When connection closes

    When connection opens with username "admin", password "password"
    Then delete user: user5


  Scenario: User's password can be changed without specifying the old password only by admin
    Given typedb starts
    Given connection opens with username "admin", password "password"
    Then create user with username "user", password "password"
    Then create user with username "user2", password "password"
    Then get user(user) set password: new-password
    When connection closes
    Then connection opens with username "admin", password "new-password"; fails
    Then connection opens with username "user", password "password"; fails

    Then connection opens with username "user", password "new-password"
    Then get user: admin; fails
    Then get user: user2; fails
    Then get user(user) set password: new-password; fails
    When connection closes

    When connection opens with username "admin", password "password"
    Then get user(user) set password: new-password
    Then get user(user) set password: password2
    Then get user(admin) set password: password2
    When connection closes

    Then connection opens with username "admin", password "password"; fails
    Then connection opens with username "user", password "password"; fails
    Then connection opens with username "user", password "new-password"; fails

    Then connection opens with username "admin", password "password2"
    When connection closes
    Then connection opens with username "user", password "password2"
    Then get user: admin; fails
    Then get user: user2; fails
    Then get user(user) set password: new-password; fails


    # TODO: Describe what happens to already connected users. Use "in background" for testing (maybe for driver.feature)
    # TODO: Implement (maybe move to driver.feature)
  Scenario: User's password can be changed through user only by admin or by this user
    Given typedb starts

    Given connection opens with username "admin", password "password"
    Given create user with username "user", password "password"
    Given create user with username "user2", password "password2"

    When get user(user) update password from "password" to "password"
    When connection closes
    Then connection opens with username "user", password "password"
    When connection closes

    When connection opens with username "admin", password "password"
    Then get user(user) update password from "new-password" to "password"; fails
    When get user(user) update password from "password" to "new-password"
    When connection closes
    Then connection opens with username "admin", password "new-password"; fails
    Then connection opens with username "user", password "password"; fails

    Then connection opens with username "user", password "new-password"
    Then get user(admin) update password from "new-password" to "password"; fails
    Then get user(admin) update password from "password" to "new-password"; fails
    Then get user(admin) update password from "new-password" to "password"; fails
    Then get user(user2) update password from "password" to "new-password"; fails
    Then get user(user2) update password from "new-password" to "password"; fails
    Then get user(user) update password from "new-password" to "password"
    Then connection closes

    Then connection opens with username "admin", password "new-password"; fails
    Then connection opens with username "user2", password "new-password"; fails
    Then connection opens with username "user", password "new-password"; fails
    Then connection opens with username "user", password "password"
    Then connection closes

    When connection opens with username "admin", password "password"
    Then get user(admin) update password from "new-password" to "password"; fails
    Then get user(admin) update password from "password" to "new-password"
    Then get user(user2) update password from "password" to "new-password"
    Then connection closes
    Then connection opens with username "admin", password "password"; fails
    Then connection opens with username "admin", password "new-password"


  Scenario: Connected username is retrievable
    Given typedb starts
    Given connection opens with username "admin", password "password"
    When create user with username "user", password "password"
    Then get current username: admin
    When connection closes
    When connection opens with username "user", password "password"
    Then get current username: user

  ##################
  # CONFIG OPTIONS #
  ##################

# TODO: Uncomment when config for password policy is introduced

#  @ignore-typedb-driver
#  Scenario: User passwords must comply with the minimum length
#    Given typedb has configuration
#      |server.authentication.password-policy.complexity.enable|true|
#      |server.authentication.password-policy.complexity.min-length|5|
#    Given typedb starts
#    Given connection opens with username "admin", password "password"
#    Then create user with username "user", password "password"
#    Then create user with username "user2", password "passw"
#    Then create user with username "user3", password "pass"; fails


#  @ignore-typedb-driver
#  Scenario: User passwords must comply with the minimum number of lowercase characters
#    Given typedb has configuration
#      |server.authentication.password-policy.complexity.enable|true|
#      |server.authentication.password-policy.complexity.min-lowercase|2|
#    Given typedb starts
#    Given connection opens with username "admin", password "password"
#    Then create user with username "user", password "password"
#    Then create user with username "user2", password "paSSWORD"
#    Then create user with username "user3", password "PASSWORD"; fails


#  @ignore-typedb-driver
#  Scenario: User passwords must comply with the minimum number of uppercase characters
#    Given typedb has configuration
#      |server.authentication.password-policy.complexity.enable|true|
#      |server.authentication.password-policy.complexity.min-uppercase|2|
#    Given typedb starts
#    Given connection opens with username "admin", password "password"
#    Then create user with username "user", password "password"
#    Then create user with username "user2", password "PAssword"
#    Then create user with username "user3", password "password"; fails


#  @ignore-typedb-driver
#  Scenario: User passwords must comply with the minimum number of numeric characters
#    Given typedb has configuration
#      |server.authentication.password-policy.complexity.enable|true|
#      |server.authentication.password-policy.complexity.min-numeric|2|
#    Given typedb starts
#    Given connection opens with username "admin", password "password"
#    Then create user with username "user", password "password"789
#    Then create user with username "user2", password "PASSWORD78"
#    Then create user with username "user3", password "PASSWORD7"; fails


#  @ignore-typedb-driver
#  Scenario: User passwords must comply with the minimum number of special characters
#    Given typedb has configuration
#      |server.authentication.password-policy.complexity.enable|true|
#      |server.authentication.password-policy.complexity.min-special|2|
#    Given typedb starts
#    Given connection opens with username "admin", password "password"
#    Then create user with username "user", password "password"!@£
#    Then create user with username "user2", password "PASSWORD&("
#    Then create user with username "user3", password "PASSWORD)"; fails


#  @ignore-typedb-driver
#  Scenario: User passwords must comply with the minimum number of different characters
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
#  Scenario: User passwords must be unique for a certain history size
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
#  Scenario: User can check their own password expiration seconds
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
#  Scenario: User passwords expire
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
