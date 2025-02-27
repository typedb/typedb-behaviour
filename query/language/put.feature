# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: TypeQL Insert Query

  Background: Open connection and create a simple extensible schema
    Given typedb starts
    Given connection opens with default authentication
    Given connection is open: true
    Given connection reset database: typedb
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define

      entity person
        plays employment:employee,
        owns name @card(0..),
        owns age,
        owns ref @key,
        owns email @unique @card(0..);

      entity company
        plays employment:employer,
        owns name,
        owns ref @key;

      relation employment
        relates employee @card(0..),
        relates employer,
        owns ref @key;

      attribute name
        value string;

      attribute age @independent,
        value integer;

      attribute ref
        value integer;

      attribute email
        value string;
      """
    Given transaction commits

    Given set time-zone: Europe/London

  #######################
  #  PUTTING INSTANCES  #
  #######################

  Scenario: Putting an entity will create it if no entity exists
    Given connection open schema transaction for database: typedb
    When typeql schema query
      """
      define entity standalone;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    When get answers of typeql read query
    """
    match $x isa standalone;
    """
    Then answer size is: 0
    When get answers of typeql write query
      """
      put $x isa standalone;
      """
    Then answer size is: 1
    When get answers of typeql read query
    """
    match $x isa standalone;
    """
    Then answer size is: 1
    When get answers of typeql write query
      """
      put $x isa standalone;
      """
    Then answer size is: 1
    When get answers of typeql read query
    """
    match $x isa standalone;
    """
    Then answer size is: 1
    Then transaction commits

    Given connection open write transaction for database: typedb
    When get answers of typeql write query
      """
      put $x isa standalone;
      """
    Then answer size is: 1
    When get answers of typeql read query
    """
    match $x isa standalone;
    """
    Then answer size is: 1


  Scenario: putting just an entity with a key does not error if one exists with that key
    Given connection open write transaction for database: typedb
    When get answers of typeql read query
    """
    match $p isa person;
    """
    Then answer size is: 0

    When get answers of typeql write query
    """
    put $p isa person, has ref 0;
    """
    Then uniquely identify answer concepts
      | p         |
      | key:ref:0 |
    When get answers of typeql read query
    """
    match $p isa person;
    """
    Then uniquely identify answer concepts
      | p         |
      | key:ref:0 |

    When get answers of typeql write query
    """
    put $p isa person, has ref 0;
    """
    Then uniquely identify answer concepts
      | p         |
      | key:ref:0 |
    When get answers of typeql read query
    """
    match $p isa person;
    """
    Then uniquely identify answer concepts
      | p         |
      | key:ref:0 |

    Then transaction commits
    Given connection open write transaction for database: typedb
    When get answers of typeql write query
    """
    put $p isa person, has ref 0;
    """
    Then uniquely identify answer concepts
      | p         |
      | key:ref:0 |
    When get answers of typeql read query
    """
    match $p isa person;
    """
    Then uniquely identify answer concepts
      | p         |
      | key:ref:0 |


  Scenario: Putting an entity of a certain type will not create the entity if an entity of a subtype exists.
    Given connection open schema transaction for database: typedb
    When typeql schema query
      """
      define entity child sub person;
      """
    Given transaction commits
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert $x isa child, has ref 0;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    When get answers of typeql read query
    """
    match $x isa! $t; $t sub person;
    """
    Then uniquely identify answer concepts
      | x         | t           |
      | key:ref:0 | label:child |

    When get answers of typeql write query
    """
    put $x isa person, has ref 0;
    """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:0 |
    When get answers of typeql read query
    """
    match $x isa! $t; $t sub person;
    """
    Then uniquely identify answer concepts
      | x         | t           |
      | key:ref:0 | label:child |
