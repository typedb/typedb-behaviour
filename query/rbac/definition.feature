# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
# TODO: redefining a role (adding accesses via a second `define rbac ...`) — merge or error?
# TODO: undefining a role that has been granted to users — block, cascade, or leave dangling grants?
# TODO: undefining the last access on a role — implicitly deletes the role or leaves an empty one?
Feature: Defining RBAC roles

  Background:
    Given typedb starts
    Given connection opens with default authentication
    Given connection is open: true
    Given connection has 0 databases
    Given connection create database: typedb
    Given connection open schema transaction for database: typedb

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
    Given transaction commits


  Scenario: RBAC roles can be defined & read back
    Given connection open schema transaction for database: typedb
    Given typeql schema query
    """
    define
      rbac post-readers,
        reads { post, comment, user },
        writes { views };
    """
    # Read them from the buffer
    Then list rbac declared access for role: post-readers
      | type    | access |
      | post    | read   |
      | comment | read   |
      | user    | read   |
      | views   | write  |
    Given transaction commits

    # Read them without a cache
    Given connection open schema transaction for database: typedb
    Then list rbac declared access for role: post-readers
      | type    | access |
      | post    | read   |
      | comment | read   |
      | user    | read   |
      | views   | write  |
    Given transaction closes
    # Read them from a cache
    Given connection open read transaction for database: typedb
    Then list rbac declared access for role: post-readers
      | type    | access |
      | post    | read   |
      | comment | read   |
      | user    | read   |
      | views   | write  |

    Then rbac role 'post-readers' has read access on type 'post': true
    Then rbac role 'post-readers' has read access on type 'comment': true
    Then rbac role 'post-readers' has read access on type 'user': true
    # Write access implies read access?
    # Then rbac role 'post-readers' has read access on type 'views': true

    Then rbac role 'post-readers' has write access on type 'post': false
    Then rbac role 'post-readers' has write access on type 'comment': false
    Then rbac role 'post-readers' has write access on type 'user': false
    Then rbac role 'post-readers' has write access on type 'views': true


  Scenario: Undefining an RBAC role removes it
    Given connection open schema transaction for database: typedb
    Given typeql schema query
    """
    define
      rbac post-readers,
        reads { post, comment },
        writes { views };
    """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    Then rbac role 'post-readers' exists: true
    When typeql schema query
    """
    undefine
      rbac post-readers;
    """
    Then rbac role 'post-readers' exists: false
    Given transaction commits

    Given connection open schema transaction for database: typedb
    Then rbac role 'post-readers' exists: false
    Given transaction closes

    Given connection open read transaction for database: typedb
    Then rbac role 'post-readers' exists: false


  Scenario: Undefining a specific access on an RBAC role leaves the role and other accesses intact
    Given connection open schema transaction for database: typedb
    Given typeql schema query
    """
    define
      rbac post-readers,
        reads { post, comment },
        writes { views };
    """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    When typeql schema query
    """
    undefine
      rbac post-readers reads { post };
    """
    Then list rbac declared access for role: post-readers
      | type    | access |
      | comment | read   |
      | views   | write  |
    Given transaction commits

    Given connection open read transaction for database: typedb
    Then rbac role 'post-readers' exists: true
    Then list rbac declared access for role: post-readers
      | type    | access |
      | comment | read   |
      | views   | write  |

