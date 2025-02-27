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

  ####################
  #  Put Instances  #
  ###################

  Scenario: Putting an entity will create it if no entity exists, or return all matching entities
    Given connection open write transaction for database: typedb
    # Verify put does insert if not exists
    When get answers of typeql read query
    """
    match $x isa person;
    """
    Then answer size is: 0
    When get answers of typeql write query
      """
      put $x isa person;
      """
    Then answer size is: 1
    When get answers of typeql read query
    """
    match $x isa person;
    """
    Then answer size is: 1

    # Verify put does not insert if exists
    When get answers of typeql write query
      """
      put $x isa person;
      """
    Then answer size is: 1
    When get answers of typeql read query
    """
    match $x isa person;
    """
    Then answer size is: 1
    Then transaction commits

    Given connection open write transaction for database: typedb
    # Check the same behaviour post commit
    When get answers of typeql write query
      """
      put $x isa person;
      """
    Then answer size is: 1
    When get answers of typeql read query
    """
    match $x isa person;
    """
    Then answer size is: 1

    # Check put returns all matching answers by inserting one more person
    Given get answers of typeql write query
      """
      insert $x isa person;
      """
    When get answers of typeql write query
      """
      put $x isa person;
      """
    Then answer size is: 2


  Scenario: Putting an entity of a certain type will not create the entity if an entity of a subtype exists.
    Given connection open schema transaction for database: typedb
    When typeql schema query
      """
      define
      person owns ref @key;
      entity child sub person;
      """
    Given transaction commits
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert $x isa child, has ref 0;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    # Putting a person, does nothing since the child matches.
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


  Scenario: putting just an entity with a key does not error if one exists with that key
    Given connection open schema transaction for database: typedb
    When typeql schema query
      """
      define person owns ref @key;
      """
    Given transaction commits
    Given connection open write transaction for database: typedb
    When get answers of typeql write query
    """
    put $p isa person, has ref 0;
    """
    Then uniquely identify answer concepts
      | p         |
      | key:ref:0 |
    # Verify it exists
    When get answers of typeql read query
    """
    match $p isa person;
    """
    Then uniquely identify answer concepts
      | p         |
      | key:ref:0 |

    Then get answers of typeql write query
    """
    put $p isa person, has ref 0;
    """
    Then uniquely identify answer concepts
      | p         |
      | key:ref:0 |
    Then transaction commits

    Given connection open write transaction for database: typedb
    # Verify the same after commit
    When get answers of typeql write query
    """
    put $p isa person, has ref 0;
    """
    Then uniquely identify answer concepts
      | p         |
      | key:ref:0 |


  ####################
  #  Put Ownerships  #
  ####################

  Scenario: Putting an entity, attribute and ownership will create them if no matching answer exists
    Given connection open write transaction for database: typedb
    # Verify nothing in the beginning
    When get answers of typeql read query
    """
    match
    $o isa! $t;
    {$t sub person; } or { $t sub age; };
    select $t;
    """
    Then answer size is: 0

    # Verify a put does insert each of them
    Given get answers of typeql write query
    """
    put $p isa person, has age 10;
    """
    Then answer size is: 1
    When get answers of typeql read query
    """
    match
    $o isa! $t;
    {$t sub person; } or { $t sub age; };
    select $t;
    """
    Then uniquely identify answer concepts
      | t            |
      | label:person |
      | label:age    |
    When get answers of typeql read query
    """
    match $p isa person, has age $age;
    """
    Then answer size is: 1
    Given transaction commits

    Given connection open write transaction for database: typedb
    # Inserting the same ownership does nothing
    Given get answers of typeql write query
    """
    put $p isa person, has age 10;
    """
    Then answer size is: 1
    When get answers of typeql read query
    """
    match $p isa person, has age $age;
    """
    Then answer size is: 1

    # A different age will insert though
    Given get answers of typeql write query
    """
    put $p isa person, has age 11;
    """
    Then answer size is: 1
    When get answers of typeql read query
    """
    match $p isa person, has age $age;
    """
    Then answer size is: 2


  Scenario: If the entire pattern does not match, put will insert the whole pattern. To insert a partial pattern, pipeline puts.
    Given connection open write transaction for database: typedb
    When typeql write query
    """
    insert $p1 isa person, has name "alice", has email "alice@email.com";
    insert $p2 isa person, has name "bob", has email "bob@email.com";
    """
    Given transaction commits


    Given connection open write transaction for database: typedb
    # Bad pattern with alice
    When get answers of typeql read query
    """
    match $p isa person, has name "alice";
    """
    Then answer size is: 1
    When typeql write query
    """
    put $p isa person, has name "alice", has email "alice@typedb.com";
    """
    When get answers of typeql read query
    """
    match $p isa person, has name "alice";
    """
    Then answer size is: 2
    When get answers of typeql read query
    """
    match $p isa person, has name "alice", has email $email;
    """
    Then uniquely identify answer concepts
      | email                       |
      | attr:email:alice@email.com  |
      | attr:email:alice@typedb.com |

    # Pipelined with bob
    When get answers of typeql read query
    """
    match $p isa person, has name "bob";
    """
    Then answer size is: 1
    When typeql write query
    """
    put $p isa person, has name "bob";
    put $p has email "bob@typedb.com";
    """
    When get answers of typeql read query
    """
    match $p isa person, has name "bob";
    """
    Then answer size is: 1
    When get answers of typeql read query
    """
    match $p isa person, has name "bob", has email $email;
    """
    Then uniquely identify answer concepts
      | email                     |
      | attr:email:bob@email.com  |
      | attr:email:bob@typedb.com |

