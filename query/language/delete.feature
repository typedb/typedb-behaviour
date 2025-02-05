# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: TypeQL Delete Query

  Background: Open connection and create a simple extensible schema
    Given typedb starts
    Given connection opens with default authentication
    Given connection is open: true
    Given connection has 0 databases
    Given connection create database: typedb
    Given connection open schema transaction for database: typedb

    Given typeql schema query
      """
      define
      entity person,
        plays friendship:friend,
        plays employment:employee,
        owns name @key,
        owns email @card(0..);
      entity company,
        plays employment:employer;
      relation friendship,
        relates friend @card(0..),
        owns ref @key;
      relation employment,
        relates employee,
        relates employer,
        owns ref @key;
      attribute name @independent, value string;
      attribute email @independent, value string;
      attribute ref @independent, value integer;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb


  ##########
  # THINGS #
  ##########

  Scenario: when deleting multiple variables, they all get deleted
    Given get answers of typeql write query
      """
      insert
      $x isa person, has name "Alex";
      $y isa person, has name "Bob";
      $r isa friendship, links (friend: $x, friend: $y), has ref 0;
      $n isa name "John";
      """
    Given uniquely identify answer concepts
      | x             | y            | r         | n              |
      | key:name:Alex | key:name:Bob | key:ref:0 | attr:name:John |
    Given transaction commits
    Given connection open write transaction for database: typedb
    When typeql write query
      """
      match
        $x isa person, has name "Alex";
        $r isa friendship, has ref 0;
        $n isa name "John";
      delete
        $x; $r; $n;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa person;
      """
    Then uniquely identify answer concepts
      | x            |
      | key:name:Bob |
    When get answers of typeql read query
      """
      match $x isa friendship;
      """
    Then answer size is: 0
    When get answers of typeql read query
      """
      match $x isa name;
      """
    Then uniquely identify answer concepts
      | x              |
      | attr:name:Alex |
      | attr:name:Bob  |


  Scenario: an entity can be deleted
    Given get answers of typeql write query
      """
      insert
      $x isa person, has name "Alex";
      $y isa person, has name "Bob";
      $r isa friendship, links (friend: $x, friend: $y),
         has ref 0;
      $n isa name "John";
      """
    Then uniquely identify answer concepts
      | x             | y            | r         | n              |
      | key:name:Alex | key:name:Bob | key:ref:0 | attr:name:John |
    Given transaction commits
    Given connection open write transaction for database: typedb
    When typeql write query
      """
      match
        $r isa person, has name "Alex";
      delete
        $r;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa person;
      """
    Then uniquely identify answer concepts
      | x            |
      | key:name:Bob |


  Scenario: a relation can be deleted
    Given get answers of typeql write query
      """
      insert
      $x isa person, has name "Alex";
      $y isa person, has name "Bob";
      $r isa friendship, links (friend: $x, friend: $y),
         has ref 0;
      $n isa name "John";
      """
    Then uniquely identify answer concepts
      | x             | y            | r         | n              |
      | key:name:Alex | key:name:Bob | key:ref:0 | attr:name:John |
    Given transaction commits
    Given connection open write transaction for database: typedb
    When typeql write query
      """
      match
        $r isa friendship, has ref 0;
      delete
        $r;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa friendship;
      """
    Then answer size is: 0


  Scenario: an attribute can be deleted
    Given get answers of typeql write query
      """
      insert
      $n isa name "John";
      """
    Then uniquely identify answer concepts
      | n              |
      | attr:name:John |
    Given transaction commits
    Given connection open write transaction for database: typedb
    When typeql write query
      """
      match
        $r isa name "John";
      delete
        $r;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa name;
      """
    Then answer size is: 0


  Scenario: one delete statement can delete multiple things
    Given get answers of typeql write query
      """
      insert
      $a isa person, has name "Alice";
      $b isa person, has name "Barbara";
      """
    Then uniquely identify answer concepts
      | a              | b                |
      | key:name:Alice | key:name:Barbara |
    Given transaction commits
    Given connection open write transaction for database: typedb
    When typeql write query
      """
      match
      $p isa person;
      delete
      $p;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa person;
      """
    Then answer size is: 0


  # TODO: 3.x: Needs finer insert validation.
  @ignore
  Scenario: variable types can be used in deletes
    Given typeql write query
      """
      insert
      $x isa person, has name 'John';
      (friend: $x) isa friendship, has ref 0;
      $y isa person, has name 'Alice';
      (friend: $y) isa friendship, has ref 1;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      match
      $p isa person, has name $n0; $n0 == "John";
      $r isa! $r-type ($p), has ref $r0; $r0 == 0;
      $p-type label person;
      delete
      $p;
      has $n0 of $p;
      $r;
      links ($p) of $r;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      match
      $p isa person, has name $n0; $n0 "Alice";
      $r ($role-type: $p) isa! $r-type, has ref $r0; $r0 1;
      $p-type type person;
      $r-type type friendship, relates $role-type;
      delete
      $p has $n0;
      $p;
      links ($role-type: $p) of $r;
      $r has $r0;
      $r;
      """
    Given transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
      $x isa person;
      $r isa friendship ($x);

      """
    Then answer size is: 0


  ###############
  # ROLEPLAYERS #
  ###############

  Scenario: deleting a role player from a relation using its role keeps the relation and removes the role player from it
    Given get answers of typeql write query
      """
      insert
      $x isa person, has name "Alex";
      $y isa person, has name "Bob";
      $z isa person, has name "Carrie";
      $r isa friendship (friend: $x, friend: $y, friend: $z),
         has ref 0;
      """
    Then uniquely identify answer concepts
      | x             | y            | z               | r         |
      | key:name:Alex | key:name:Bob | key:name:Carrie | key:ref:0 |
    Given transaction commits
    Given connection open write transaction for database: typedb
    When typeql write query
      """
      match
        $r isa friendship (friend: $x, friend: $y, friend: $z);
        $x isa person, has name "Alex";
        $y isa person, has name "Bob";
        $z isa person, has name "Carrie";
      delete
        links (friend: $x) of $r;
      """
    Then transaction commits

    When connection open write transaction for database: typedb
    When get answers of typeql read query
      """
      match $r isa friendship, links (friend: $x, friend: $y);
      select $x, $y;
      """
    Then uniquely identify answer concepts
      | x               | y               |
      | key:name:Bob    | key:name:Carrie |
      | key:name:Carrie | key:name:Bob    |


  Scenario: deleting an instance removes it from all relations
    Given get answers of typeql write query
      """
      insert
      $x isa person, has name "Alex";
      $y isa person, has name "Bob";
      $z isa person, has name "Carrie";
      $r isa friendship, links (friend: $x, friend: $y), has ref 1;
      $r2 isa friendship, links (friend: $x, friend: $z), has ref 2;
      """
    Then uniquely identify answer concepts
      | x             | y            | z               | r         | r2        |
      | key:name:Alex | key:name:Bob | key:name:Carrie | key:ref:1 | key:ref:2 |
    Given transaction commits
    When connection open write transaction for database: typedb
    When typeql write query
      """
      match
        $x isa person, has name "Alex";
      delete
        $x;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa person;
      """
    Then uniquely identify answer concepts
      | x               |
      | key:name:Bob    |
      | key:name:Carrie |
    When get answers of typeql read query
      """
      match $r isa friendship (friend: $x);
      """
    Then uniquely identify answer concepts
      | r         | x               |
      | key:ref:1 | key:name:Bob    |
      | key:ref:2 | key:name:Carrie |


  @ignore
  # TODO: 3.x: Bring back when we have lists
  Scenario: repeated role players can be deleted from a relation
    Given get answers of typeql write query
      """
      insert
      $x isa person, has name "Alex";
      $y isa person, has name "Bob";
      $r isa friendship (friend: $x, friend: $x, friend: $y), has ref 0;
      """
    Then uniquely identify answer concepts
      | x             | y            | r         |
      | key:name:Alex | key:name:Bob | key:ref:0 |
    Given transaction commits
    When connection open write transaction for database: typedb
    When typeql write query
      """
      match
        $r isa friendship (friend: $x, friend: $x);
      delete
        links (friend: $x, friend: $x) of $r;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $r isa friendship (friend: $x);
      """
    Then uniquely identify answer concepts
      | r         | x            |
      | key:ref:0 | key:name:Bob |


  Scenario: The role player playing the specialized role can be deleted
    Given transaction closes

    Given connection open schema transaction for database: typedb
    Given typeql schema query
    """
    define
    relation internship sub employment, relates intern as employee;
    entity student sub person, plays internship:intern;
    """
    Given transaction commits

    Given connection open write transaction for database: typedb
    When typeql write query
    """
    insert
      $p0 isa person, has name "p0";
      $e0 isa employment, links (employee: $p0), has ref 0;
      $s1 isa student, has name "s1";
      $e1 isa employment, links (employee: $s1), has ref 1;
      $s2 isa student, has name "s2";
      $i2 isa internship, links (intern: $s2), has ref 2;
    """
    Then transaction commits

    # We're not particular about this:
    Given connection open write transaction for database: typedb
    When typeql write query; fails with a message containing: "Write execution failed due to a concept write error"
    """
    match
      $e isa employment, links (employee: $p);
    delete
      links (employee: $p) of $e;
    """
    Given transaction closes

    Given connection open write transaction for database: typedb
    When typeql write query
    """
    match
      $e isa! employment, links (employee: $p);
    delete
      links (employee: $p) of $e;
    """
    Then get answers of typeql read query
    """
    match $e isa employment, links (employee: $p);
    """
    Then uniquely identify answer concepts
      | e         | p           |
      | key:ref:2 | key:name:s2 |

    Then transaction commits

    Given connection open write transaction for database: typedb
    When typeql write query
    """
    match
      $e isa employment, links (employee: $p);
    delete
      links (intern: $p) of $e;
    """
    Then get answers of typeql read query
    """
    match $e isa employment, links (employee: $p);
    """
    Then answer size is: 0
    Then transaction commits


  @ignore
  # TODO: 3.x: Bring back when we have lists ( this also fails because we don't have role-player de-duplication?)
  Scenario: when deleting multiple repeated role players from a relation, it removes the number you asked to delete
    Given get answers of typeql write query
      """
      insert
      $x isa person, has name "Alex";
      $y isa person, has name "Bob";
      $r isa friendship (friend: $x, friend: $x, friend: $x, friend: $y), has ref 0;
      """
    Then uniquely identify answer concepts
      | x             | y            | r         |
      | key:name:Alex | key:name:Bob | key:ref:0 |
    Given transaction commits
    When connection open write transaction for database: typedb
    When typeql write query
      """
      match
        $r isa friendship (friend: $x, friend: $x, friend: $x);
      delete
        links (friend: $x, friend: $x) of $r;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $r isa friendship, links (friend: $x, friend: $y);
      """
    Then uniquely identify answer concepts
      | r         | x             | y             |
      | key:ref:0 | key:name:Bob  | key:name:Alex |
      | key:ref:0 | key:name:Alex | key:name:Bob  |


  @ignore
  # TODO: 3.x: Bring back when we have lists
  Scenario: when deleting repeated role players in multiple statements, it removes the total number you asked to delete
    Given get answers of typeql write query
      """
      insert
      $x isa person, has name "Alex";
      $y isa person, has name "Bob";
      $r isa friendship (friend: $x, friend: $x, friend: $x, friend: $y), has ref 0;
      """
    Then uniquely identify answer concepts
      | x             | y            | r         |
      | key:name:Alex | key:name:Bob | key:ref:0 |
    Given transaction commits
    When connection open write transaction for database: typedb
    When typeql write query
      """
      match
        $x isa person;
        $r isa friendship (friend: $x, friend: $x, friend: $x);
      delete
        links (friend: $x, friend: $x) of $r;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $r isa friendship, links (friend: $x, friend: $y);
      """
    Then uniquely identify answer concepts
      | r         | x             | y             |
      | key:ref:0 | key:name:Bob  | key:name:Alex |
      | key:ref:0 | key:name:Alex | key:name:Bob  |


  @ignore
  # TODO: 3.x: Bring back when we have lists
  Scenario: when deleting one of the repeated role players from a relation, only one duplicate is removed
    Given get answers of typeql write query
      """
      insert
      $x isa person, has name "Alex";
      $y isa person, has name "Bob";
      $r isa friendship (friend: $x, friend: $x, friend: $y), has ref 0;
      """
    Then uniquely identify answer concepts
      | x             | y            | r         |
      | key:name:Alex | key:name:Bob | key:ref:0 |
    Given transaction commits
    When connection open write transaction for database: typedb
    When typeql write query
      """
      match
        $r isa friendship (friend: $x);
        $x isa person, has name "Alex";
      delete
        links (friend: $x) of $r;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $r isa friendship, links (friend: $x, friend: $y);
      """
    Then uniquely identify answer concepts
      | r         | x             | y             |
      | key:ref:0 | key:name:Bob  | key:name:Alex |
      | key:ref:0 | key:name:Alex | key:name:Bob  |


  Scenario: deleting role players in multiple statements is allowed
    Given get answers of typeql write query
      """
      insert
      $x isa person, has name "Alex";
      $y isa person, has name "Bob";
      $z isa person, has name "Carrie";
      $r isa friendship (friend: $x, friend: $y, friend: $z), has ref 0;
      """
    Then uniquely identify answer concepts
      | x             | y            | z               | r         |
      | key:name:Alex | key:name:Bob | key:name:Carrie | key:ref:0 |
    Given transaction commits
    When connection open write transaction for database: typedb
    When typeql write query
      """
      match
        $r isa friendship (friend: $x, friend: $y, friend: $z);
        $x isa person, has name "Alex";
        $y isa person, has name "Bob";
        $z isa person, has name "Carrie";
      delete
        links (friend: $x) of $r;
        links (friend: $y) of $r;
      """
    Then transaction commits


  Scenario: when deleting overlapping answers, deletes are idempotent
    Given typeql write query
      """
      insert
      $x isa person, has name "Alex", has email "alex@email.com", has email "al@email.com", has email "a@email.com";
      $y isa person, has name "Bob";
      $z isa person, has name "Charlie";
      $r isa friendship (friend: $x, friend: $y, friend: $z), has ref 0;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Then typeql write query
      """
      match
        $r isa friendship, links (friend: $x, friend: $y);
      delete
        links (friend: $x, friend: $y) of $r;
      """
    Given transaction commits
    When connection open write transaction for database: typedb
    When get answers of typeql read query
      """
      match $r isa friendship, links (friend: $x, friend: $y);
      """
    Then answer size is: 0

    Then typeql write query
      """
      match
        $x has email $a, has email $b;
      delete
        has $a of $x;
        has $b of $x;
      """
    Given transaction commits
    When connection open write transaction for database: typedb
    When get answers of typeql read query
      """
      match $r has email $a, has email $b;
      """
    Then answer size is: 0

    Then typeql write query
      """
      match
        $x isa person;
        $y isa person;
      delete
        $x;
        $y;
      """
    Given transaction commits
    When connection open write transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa person; $y isa person;
      """
    Then answer size is: 0


  Scenario: when deleting incompatible ownerships or role players, an error is thrown
    Given typeql write query
      """
      insert
      $x isa person, has name "Alex";
      $y isa person, has name "Bob";
      $c isa company;
      $r isa friendship, links (friend: $x, friend: $y), has ref 0;
      $e isa employment (employee: $x, employer: $c), has ref 1;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Then typeql write query; fails
      """
      match
        $x isa person;
        $a isa ref;
      delete
        has $a of $x;
      """
    Then typeql write query; fails
      """
      match
        $x isa person;
        $r isa friendship ($x);
      delete
        links (employee: $x) of $r;
      """
    Then typeql write query; fails
      """
      match
        $x isa company;
        $r isa friendship;
      delete
        links (friend: $x) of $r;
      """


  Scenario: when all instances that play roles in a relation are deleted, the relation instance gets cleaned up
    Given get answers of typeql write query
      """
      insert
      $x isa person, has name "Alex";
      $y isa person, has name "Bob";
      $r isa friendship, links (friend: $x, friend: $y), has ref 0;
      """
    Then uniquely identify answer concepts
      | x             | y            | r         |
      | key:name:Alex | key:name:Bob | key:ref:0 |
    Given transaction commits
    When connection open write transaction for database: typedb
    When typeql write query
      """
      match
        $x isa person, has name "Alex";
        $y isa person, has name "Bob";
      delete
        $x;
        $y;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $r isa friendship;
      """
    Then answer size is: 0


  Scenario: when the last role player is disassociated from a relation instance, the relation instance gets cleaned up
    Given get answers of typeql write query
      """
      insert
      $x isa person, has name "Alex";
      $y isa person, has name "Bob";
      $r isa friendship, links (friend: $x, friend: $y), has ref 0;
      """
    Then uniquely identify answer concepts
      | x             | y            | r         |
      | key:name:Alex | key:name:Bob | key:ref:0 |
    Given transaction commits
    When connection open write transaction for database: typedb
    When typeql write query
      """
      match
        $x isa person, has name "Alex";
        $y isa person, has name "Bob";
        $r isa friendship ($x, $y);
      delete
        links (friend: $x, friend: $y) of $r;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $r isa friendship;
      """
    Then answer size is: 0


  Scenario: deleting a role player with a too-specific (downcasting) role errors
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
      relation special-friendship sub friendship,
        relates special-friend as friend;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    When typeql write query
      """
      insert
      $x isa person, has name "Alex";
      $y isa person, has name "Bob";
      $r isa friendship, links (friend: $x, friend: $y), has ref 0;
      """
    Then transaction commits

    When connection open write transaction for database: typedb
    Then typeql write query; fails
      """
      match
        $x isa person, has name "Alex";
        $y isa person, has name "Bob";
        $r isa friendship, links (friend: $x, friend: $y);
      delete
        links (special-friend: $x) of $r;
      """


#  Even when a $role variable matches multiple roles (will always match 'role' unless constrained)
#  We only delete role player edges until the 'match' is no longer satisfied.
#
#  **Sometimes this means multiple repeated role players will be unassigned **
#
#  For example
#
#  // concrete instance:  $r isa directed-by (production: $x, production: $x, production: $x, director: $y);
#  match $r isa directed-by ($role1: $x, director: $y); $type sub work;
#  delete links ($role1: $x) of $r;
#
#  First, we will match '$role1' = ROLE meta role. Using this answer we will remove a single $x from $r via the 'production'.
#  Next, we will match '$role1' = WORK role, and we delete another 'production' player. This repeats again for $role='production'.
  Scenario: when deleting repeated role players with a single variable role, both repetitions are removed
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
      relation ship-crew, relates captain, relates navigator, relates chef, owns ref @key;
      person plays ship-crew:captain, plays ship-crew:navigator, plays ship-crew:chef;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x isa person, has name "Cook";
      $y isa person, has name "Joshua";
      $r isa ship-crew (captain: $x, chef: $y, chef: $y), has ref 0;
      """
    Given transaction commits

    When connection open write transaction for database: typedb
    When get answers of typeql read query
      """
      match $rel isa ship-crew (chef: $p);
      """
    Then uniquely identify answer concepts
      | rel       | p               |
      | key:ref:0 | key:name:Joshua |
    When typeql write query
      """
      match
        $r isa ship-crew ($role1: $x, captain: $y);
      delete
        links ($role1: $x) of $r;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $rel isa ship-crew (chef: $p);
      """
    Then answer size is: 0


  ########################
  # ATTRIBUTE OWNERSHIPS #
  ########################

  Scenario: deleting an attribute instance also deletes its ownerships
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
      attribute age, value integer;
      person owns age;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x isa person, has name "Anna", has age 18;
      """
    Given transaction commits

    When connection open write transaction for database: typedb
    When get answers of typeql read query
      """
      match $x has age 18;
      """
    Then uniquely identify answer concepts
      | x             |
      | key:name:Anna |
    When typeql write query
      """
      match
        $x isa age 18;
      delete
        $x;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x has age 18;
      """
    Then answer size is: 0


  Scenario: attempting to delete an attribute ownership with a redeclared isa errors
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
      attribute lastname, value string;
      entity person, owns lastname;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given get answers of typeql write query
      """
      insert
      $x isa person,
        has lastname "Smith",
        has name "Alex";
      $y isa person,
        has lastname "Smith",
        has name "John";
      """
    Then uniquely identify answer concepts
      | x             | y             |
      | key:name:Alex | key:name:John |
    Given transaction commits
    When connection open write transaction for database: typedb
    When typeql write query; parsing fails
      """
      match
        $x isa person, has lastname $n, has name "Alex";
        $n == "Smith";
      delete
        has lastname $n of $x;
      """


  Scenario: an attribute deletion using anonymous thing variables errors
    Given typeql write query
      """
      insert
      $x isa person,
        has email "alex@abc.com",
        has name "Alex";
      """
    Given transaction commits
    When connection open write transaction for database: typedb
    When typeql write query; parsing fails
      """
      match
        $x isa person, has email "alex@abc.com";
      delete
        has name "Alex" of $x;
      """


  Scenario: deleting the owner of an attribute also deletes the attribute ownership
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
      attribute timespan, value integer;
      friendship owns timespan;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x isa person, has name "Tom";
      $y isa person, has name "Jerry";
      $r isa friendship, links (friend: $x, friend: $y), has ref 0, has timespan 1000;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    When get answers of typeql read query
      """
      match $x has timespan $d;
      """
    Then uniquely identify answer concepts
      | x         | d                  |
      | key:ref:0 | attr:timespan:1000 |
    When typeql write query
      """
      match
        $r isa friendship;
      delete
        $r;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x has timespan $d;
      """
    Then answer size is: 0


  Scenario: deleting the last roleplayer in a relation deletes both the relation and its attribute ownerships
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
      attribute timespan, value integer;
      friendship owns timespan;
      """
    Given transaction commits
    Given connection open write transaction for database: typedb

    Given typeql write query
      """
      insert
      $x isa person, has name "Emma";
      $r isa friendship (friend: $x), has ref 0, has timespan 1000;
      """
    Given transaction commits

    When connection open write transaction for database: typedb
    When get answers of typeql read query
      """
      match $x has timespan $d;
      """
    Then uniquely identify answer concepts
      | x         | d                  |
      | key:ref:0 | attr:timespan:1000 |
    When typeql write query
      """
      match
        $r isa friendship (friend: $x);
      delete
        links (friend: $x) of $r;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x has timespan $d;
      """
    Then answer size is: 0
    When get answers of typeql read query
      """
      match $r isa friendship;
      """
    Then answer size is: 0


  Scenario: an error is thrown when deleting the ownership of a non-existent attribute
    Then typeql write query; fails
      """
      match
        $x has diameter $val;
      delete
        has $val of $x;
      """


  Scenario: has can be deleted for instances of multiple attribute supertypes and subtypes
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
        person owns encrypted-email @card(0..), owns corporate-email;
        attribute encrypted-email sub email;
        attribute corporate-email sub encrypted-email;
      """
    Given typeql write query
      """
      insert
        $p isa person,
          has name "Bob",
          has email "bob@mail.com",
          has email "bobbie1987@gmail.com",
          has encrypted-email "b0b@bob.bob",
          has corporate-email "bob@typedb.com";
      """
    Given transaction commits
    When connection open write transaction for database: typedb
    When typeql write query
      """
      match
        $p has email $e;
      delete
        has $e of $p;
      """
    When get answers of typeql read query
      """
      match $_ has email $e;
      """
    Then answer size is: 0

    When typeql write query
      """
      match
        $p isa person;
      delete
        $p;
      """
    When typeql write query
      """
      insert
        $p isa person,
          has name "Bob",
          has email "bob@mail.com",
          has email "bobbie1987@gmail.com",
          has encrypted-email "b0b@bob.bob",
          has corporate-email "bob@typedb.com";
      """
    When typeql write query
      """
      match
        $p has encrypted-email $e;
      delete
        has $e of $p;
      """
    When get answers of typeql read query
      """
      match $_ has email $e;
      """
    Then uniquely identify answer concepts
      | e                                 |
      | attr:email:"bob@mail.com"         |
      | attr:email:"bobbie1987@gmail.com" |

    When typeql write query
      """
      match
        $p isa person;
      delete
        $p;
      """
    When typeql write query
      """
      insert
        $p isa person,
          has name "Bob",
          has email "bob@mail.com",
          has email "bobbie1987@gmail.com",
          has encrypted-email "b0b@bob.bob",
          has corporate-email "bob@typedb.com";
      """
    When typeql write query
      """
      match
        $p has corporate-email $e;
      delete
        has $e of $p;
      """
    When get answers of typeql read query
      """
      match $_ has email $e;
      """
    Then uniquely identify answer concepts
      | e                                  |
      | attr:email:"bob@mail.com"          |
      | attr:email:"bobbie1987@gmail.com"  |
      | attr:encrypted-email:"b0b@bob.bob" |
    Then transaction commits

  ####################
  # COMPLEX PATTERNS #
  ####################

  # TODO: 3.x: Bring back when we have lists, because (friend: $x, friend: $x)
  @ignore
  Scenario: deletion of a complex pattern
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
      attribute lastname, value string;
      entity person, owns lastname;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x isa person,
        has lastname "Smith",
        has name "Alex";
      $y isa person,
        has lastname "Smith",
        has name "John";
      $r isa friendship, links (friend: $x, friend: $y), has ref 1;
      $r1 isa friendship, links (friend: $x, friend: $y), has ref 2;
      $reflexive isa friendship (friend: $x, friend: $x), has ref 3;
      """
    Given transaction commits

    When connection open write transaction for database: typedb
    When typeql write query
      """
      match
        $x isa person, has name "Alex", has lastname $n;
        $y isa person, has name "John", has lastname $n;
        $refl isa friendship (friend: $x, friend: $x), has ref 3;
        $f1 isa friendship, links (friend: $x, friend: $y), has ref 1;
      delete
        has $n of $x;
        links (friend: $x) of $refl;
        $f1;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $f isa friendship (friend: $x);
      """
    Then uniquely identify answer concepts
      | f         | x             |
      | key:ref:2 | key:name:Alex |
      | key:ref:2 | key:name:John |
      | key:ref:3 | key:name:Alex |
    When get answers of typeql read query
      """
      match $n isa name;
      """
    Then uniquely identify answer concepts
      | n              |
      | attr:name:John |
      | attr:name:Alex |
    When get answers of typeql read query
      """
      match $x isa person, has lastname $n;
      """
    Then uniquely identify answer concepts
      | x             | n                   |
      | key:name:John | attr:lastname:Smith |


  # TODO: 3.x: Bring back when we have lists (friend: $x, friend: $x)
  @ignore
  Scenario: deleting everything in a complex pattern
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
      attribute lastname, value string;
      entity person, owns lastname;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x isa person,
        has lastname "Smith",
        has name "Alex";
      $y isa person,
        has lastname "Smith",
        has name "John";
      $r isa friendship, links (friend: $x, friend: $y), has ref 1;
      $r1 isa friendship, links (friend: $x, friend: $y), has ref 2;
      $reflexive isa friendship (friend: $x, friend: $x), has ref 3;
      """
    Given transaction commits

    When connection open write transaction for database: typedb
    When typeql write query
      """
      match
        $x isa person, has name "Alex", has lastname $n;
        $y isa person, has name "John", has lastname $n;
        $refl isa friendship (friend: $x, friend: $x), has ref $r1; $r1 == 3;
        $f1 isa friendship, links (friend: $x, friend: $y), has ref $r2; $r2 == 1;
      delete
        $x; $y; $refl; $f1;
        has $n of $x;
        has $n of $y;
        links (friend: $x, friend: $x) of $refl;
        has $r1 of $refl;
        links (friend: $x, friend: $y) of $f1;
        has $r2 of $f1;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa person, has lastname $n;
      """
    Then answer size is: 0


  ##############
  # EDGE CASES #
  ##############

  Scenario: deleting a variable not in the query errors, even if there were no matches
    Then typeql write query; fails
      """
      match $x isa person; delete $n;
      """


  Scenario: deleting a has ownership @key errors on commit
    Given typeql write query
      """
      insert
      $x isa person, has name "Alex";
      """
    Given transaction commits

    When connection open write transaction for database: typedb
    Then typeql write query
      """
      match
        $x isa person, has name $n;
        $n == "Alex";
      delete
        has $n of $x;
      """
    Then transaction commits; fails


  Scenario: deleting an attribute instance that is owned as a has @key errors
    Given typeql write query
      """
      insert
      $x isa person, has name "Tatyana";
      """
    Given transaction commits

    When connection open write transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa name;
      """
    Then uniquely identify answer concepts
      | x                 |
      | attr:name:Tatyana |
    Then typeql write query
      """
      match
        $x isa name "Tatyana";
      delete
        $x;
      """
    Then transaction commits; fails


  Scenario: deleting a type errors
    Then typeql write query; fails
      """
      match
        $x label person;
      delete
        $x;
      """
