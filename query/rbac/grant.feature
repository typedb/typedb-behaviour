# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
# TODO: dropping a database with granted roles — are role-assignments cleaned up or left dangling?
# TODO: enforcement tests — a user without a permission is blocked, a user with one is allowed through
Feature: Assigning permissions & RBAC roles

  Background:
    Given typedb starts
    Given connection opens with default authentication
    Given connection is open: true
    Given connection has 0 databases
    Given connection create database: typedb


  # --- Granting permissions ---

  Scenario Outline: Users can be assigned the global '<has-permission>' permission
    Given create user with username '<user>', password 'mypassword'

    When grant user '<user>' permission: <has-permission>
    Then user '<user>' has permission: <has-permission>
    Then user '<user>' does not have permission: <doesnt-have-1>
    Then user '<user>' does not have permission: <doesnt-have-2>

    Examples:
      | user       | has-permission    | doesnt-have-1    | doesnt-have-2     |
      | user-gp-mu | manage-users      | manage-databases | grant-permissions |
      | user-gp-md | manage-databases  | manage-users     | grant-permissions |
      | user-gp-gp | grant-permissions | manage-users     | manage-databases  |

  Scenario Outline: Users can be assigned the '<permission>' permission on a specific database
    Given connection create database: mydb

    Given create user with username '<user>', password 'mypassword'
    When grant user '<user>' permission: <permission>:<database>
    Then user '<user>' has permission: <permission>:<database>
    Then user '<user>' <may-have-other> permission: <other-permission>:<database>

    Examples:
      | user          | database | permission        | may-have-other | other-permission  |
      | user-dp-tr-tw | mydb     | transaction-read  | does not have  | transaction-write |
      | user-dp-tr-st | mydb     | transaction-read  | does not have  | schema-types      |
      | user-dp-tr-sr | mydb     | transaction-read  | does not have  | schema-roles      |

      | user-dp-tw-tr | mydb     | transaction-write | does not have  | transaction-read  |
      | user-dp-tw-st | mydb     | transaction-write | does not have  | schema-types      |
      | user-dp-tw-sr | mydb     | transaction-write | does not have  | schema-roles      |

      | user-dp-st-tr | mydb     | schema-types      | does not have  | transaction-read  |
      | user-dp-st-tw | mydb     | schema-types      | does not have  | transaction-write |
      | user-dp-st-sr | mydb     | schema-types      | does not have  | schema-roles      |

      | user-dp-sr-tr | mydb     | schema-roles      | does not have  | transaction-read  |
      | user-dp-sr-tw | mydb     | schema-roles      | does not have  | transaction-write |
      | user-dp-sr-st | mydb     | schema-roles      | does not have  | schema-types      |

  Scenario: Granting the same permission twice is idempotent
    Given connection create database: mydb

    Given create user with username 'user-idempotent', password 'mypassword'
    When grant user 'user-idempotent' permission: transaction-read:mydb
    When grant user 'user-idempotent' permission: transaction-read:mydb
    Then user 'user-idempotent' has permission: transaction-read:mydb

  Scenario: Database permissions are scoped to their database and do not apply to other databases
    Given connection create database: db-one
    Given connection create database: db-two

    Given create user with username 'user-cross-db', password 'mypassword'
    When grant user 'user-cross-db' permission: transaction-read:db-one
    When grant user 'user-cross-db' permission: transaction-write:db-two

    Then user 'user-cross-db' has permission: transaction-read:db-one
    Then user 'user-cross-db' does not have permission: transaction-read:db-two

    Then user 'user-cross-db' has permission: transaction-write:db-two
    Then user 'user-cross-db' does not have permission: transaction-write:db-one


  # --- Granting database roles ---

  Scenario: Users can be assigned rbac roles from specific databases
    Given connection create database: mydb

    Given connection open schema transaction for database: mydb
    Given typeql schema query
    """
    define
      attribute email, value string;
      attribute text, value string;
      attribute views, value integer;

      relation authorship,
        relates content @card(1),
        relates author;

      entity post,
        owns text, owns views,
        plays authorship:content;
      entity comment,
        owns text, owns views,
        plays authorship:content;
      entity user,
        owns email,
        plays authorship:author;
    """
    Given typeql schema query
    """
    define
      rbac post-readers,
        reads { post, comment, user },
        writes { views };

      rbac post-writers,
        writes { post, comment, user, views };
    """
    Given transaction commits

    Given create user with username 'user-role-reader', password 'mypassword'
    Given create user with username 'user-role-writer', password 'mypassword'
    Given create user with username 'user-role-both', password 'mypassword'

    When grant user 'user-role-reader' database role: mydb:post-readers
    When grant user 'user-role-writer' database role: mydb:post-writers
    When grant user 'user-role-both' database role: mydb:post-readers
    When grant user 'user-role-both' database role: mydb:post-writers

    Then user 'user-role-reader' has database role: mydb:post-readers
    Then user 'user-role-reader' does not have database role: mydb:post-writers

    Then user 'user-role-writer' does not have database role: mydb:post-readers
    Then user 'user-role-writer' has database role: mydb:post-writers

    Then user 'user-role-both' has database role: mydb:post-readers
    Then user 'user-role-both' has database role: mydb:post-writers

  Scenario: Granting a database role that is not defined fails
    Given connection create database: mydb

    Given create user with username 'user-no-role', password 'mypassword'
    Then grant user 'user-no-role' database role: mydb:nonexistent-role; fails with a message containing: "The referenced role 'nonexistent-role' was not found in the database 'mydb'"

  Scenario: Granting a database role after its definition has been deleted fails
    Given connection create database: mydb

    Given connection open schema transaction for database: mydb
    Given typeql schema query
    """
    define
      attribute email, value string;
      entity user, owns email;

      rbac post-readers, reads { user };
    """
    Given transaction commits

    Given connection open schema transaction for database: mydb
    When typeql schema query
    """
    undefine
      rbac post-readers;
    """
    Given transaction commits

    Given create user with username 'user-deleted-role', password 'mypassword'
    Then grant user 'user-deleted-role' database role: mydb:post-readers; fails with a message containing: "The referenced role 'post-readers' was not found in the database 'mydb'"


  # --- Revoking permissions ---

  Scenario Outline: Revoking a global '<permission>' permission removes it without affecting others
    Given create user with username '<user>', password 'mypassword'
    Given grant user '<user>' permission: <permission>

    When ungrant user '<user>' permission: <permission>
    Then user '<user>' does not have permission: <permission>

    Examples:
      | user           | permission        |
      | user-rv-gp-mu  | manage-users      |
      | user-rv-gp-md  | manage-databases  |
      | user-rv-gp-gp  | grant-permissions |

  Scenario: Revoking a database-scoped permission removes it without affecting other permissions
    Given connection create database: mydb
    Given connection create database: otherdb

    Given create user with username 'user-rv-dp', password 'mypassword'
    Given grant user 'user-rv-dp' permission: transaction-read:mydb
    Given grant user 'user-rv-dp' permission: transaction-read:otherdb
    Given grant user 'user-rv-dp' permission: transaction-write:mydb

    When ungrant user 'user-rv-dp' permission: transaction-read:mydb
    Then user 'user-rv-dp' does not have permission: transaction-read:mydb
    Then user 'user-rv-dp' has permission: transaction-read:otherdb
    Then user 'user-rv-dp' has permission: transaction-write:mydb


  # --- Revoking database roles ---

  Scenario: Revoking a database role removes it without affecting other roles
    Given connection create database: mydb

    Given connection open schema transaction for database: mydb
    Given typeql schema query
    """
    define
      attribute email, value string;
      attribute text, value string;
      attribute views, value integer;

      relation authorship,
        relates content @card(1),
        relates author;

      entity post,
        owns text, owns views,
        plays authorship:content;
      entity comment,
        owns text, owns views,
        plays authorship:content;
      entity user,
        owns email,
        plays authorship:author;
    """
    Given typeql schema query
    """
    define
      rbac post-readers,
        reads { post, comment, user },
        writes { views };

      rbac post-writers,
        writes { post, comment, user, views };
    """
    Given transaction commits

    Given create user with username 'user-revoke-role', password 'mypassword'
    Given grant user 'user-revoke-role' database role: mydb:post-readers
    Given grant user 'user-revoke-role' database role: mydb:post-writers

    When ungrant user 'user-revoke-role' database role: mydb:post-readers
    Then user 'user-revoke-role' does not have database role: mydb:post-readers
    Then user 'user-revoke-role' has database role: mydb:post-writers

  Scenario: Revoking a database role that was not granted fails
    Given connection create database: mydb

    Given connection open schema transaction for database: mydb
    Given typeql schema query
    """
    define
      attribute email, value string;
      entity user, owns email;

      rbac post-readers, reads { user };
    """
    Given transaction commits

    Given create user with username 'user-no-grant', password 'mypassword'
    Then ungrant user 'user-no-grant' database role: mydb:post-readers; fails with a message containing: "Unable to revoke role 'post-readers' on database 'mydb' from 'user:user-no-grant'"
