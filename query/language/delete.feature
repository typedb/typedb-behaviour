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
        owns email;
      entity company,
        plays employment:employer;
      relation friendship,
        relates friend @card(1..),
        owns ref @key;
      relation employment,
        relates employee,
        relates employer,
        owns ref @key;
      attribute name, value string;
      attribute email, value string;
      attribute ref, value long;
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
      $n "John" isa name;
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
        $n "John" isa name;
      delete
        $x; $r; $n;
      """
    Then transaction commits

    When session opens transaction of type: read
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
      $n "John" isa name;
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

    When session opens transaction of type: read
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
      $n "John" isa name;
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
        $r isa relation;
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql read query
      """
      match $x isa friendship;
      """
    Then answer size is: 0


  Scenario: an attribute can be deleted
    Given get answers of typeql write query
      """
      insert
      $n "John" isa name;
      """
    Then uniquely identify answer concepts
      | n              |
      | attr:name:John |
    Given transaction commits
    Given connection open write transaction for database: typedb
    When typeql write query
      """
      match
        $r "John" isa name;
      delete
        $r;
      """
    Then transaction commits

    When session opens transaction of type: read
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

    When session opens transaction of type: read
    When get answers of typeql read query
      """
      match $x isa person;
      """
    Then answer size is: 0


  Scenario: deleting an instance using an unrelated type label errors
    Given typeql write query
      """
      insert
      $x isa person, has name "Alex";
      $n "John" isa name;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Then typeql write query; fails
      """
      match
        $x isa person;
        $r isa name; $r "John";
      delete
        $r isa person;
      """


  Scenario: deleting an instance using a non-existing type label errors
    Given typeql write query
      """
      insert
      $n "John" isa name;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Then typeql write query; fails
      """
      match
        $r isa name; $r "John";
      delete
        $r isa heffalump;
      """


  Scenario: deleting a relation instance using a too-specific (downcasting) type errors
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
      special-friendship sub friendship;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x isa person, has name "Alex";
      $y isa person, has name "Bob";
      $r isa friendship, links (friend: $x, friend: $y), has ref 0;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Then typeql write query; fails
      """
      match
        $r ($x, $y) isa friendship;
      delete
        $r isa special-friendship;
      """


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
      $p isa person, has name $n0; $n0 "John";
      $r ($p) isa! $r-type, has ref $r0; $r0 0;
      $p-type type person;
      delete
      $p isa $p-type, has $n0;
      $r ($p) isa $r-type, has $r0;
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
      $p isa $p-type, has $n0;
      $r ($role-type: $p) isa $r-type, has $r0;
      """
    Given transaction commits

    When session opens transaction of type: read
    When get answers of typeql read query
      """
      match
      $x isa person;
      $r ($x) isa friendship;

      """
    Then answer size is: 0


  ###############
  # ROLEPLAYERS #
  ###############

  #TODO: This is flaky
  @ignore
  Scenario: deleting a role player from a relation using its role keeps the relation and removes the role player from it
    Given get answers of typeql write query
      """
      insert
      $x isa person, has name "Alex";
      $y isa person, has name "Bob";
      $z isa person, has name "Carrie";
      $r (friend: $x, friend: $y, friend: $z) isa friendship,
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
        $r (friend: $x, friend: $y, friend: $z) isa friendship;
        $x isa person, has name "Alex";
        $y isa person, has name "Bob";
        $z isa person, has name "Carrie";
      delete
        $r (friend: $x);
      """
    Then transaction commits

    When connection open write transaction for database: typedb
    When get answers of typeql read query
      """
      match isa friendship, links (friend: $x, friend: $y);
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
        $x isa person;
      """
    Then transaction commits

    When session opens transaction of type: read
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
      match $r (friend: $x) isa friendship;
      """
    Then uniquely identify answer concepts
      | r         | x               |
      | key:ref:1 | key:name:Bob    |
      | key:ref:2 | key:name:Carrie |


  Scenario: repeated role players can be deleted from a relation
    Given get answers of typeql write query
      """
      insert
      $x isa person, has name "Alex";
      $y isa person, has name "Bob";
      $r (friend: $x, friend: $x, friend: $y) isa friendship, has ref 0;
      """
    Then uniquely identify answer concepts
      | x             | y            | r         |
      | key:name:Alex | key:name:Bob | key:ref:0 |
    Given transaction commits
    When connection open write transaction for database: typedb
    When typeql write query
      """
      match
        $r (friend: $x, friend: $x) isa friendship;
      delete
        $r (friend: $x, friend: $x);
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql read query
      """
      match $r (friend: $x) isa friendship;
      """
    Then uniquely identify answer concepts
      | r         | x            |
      | key:ref:0 | key:name:Bob |


  Scenario: when deleting multiple repeated role players from a relation, it removes the number you asked to delete
    Given get answers of typeql write query
      """
      insert
      $x isa person, has name "Alex";
      $y isa person, has name "Bob";
      $r (friend: $x, friend: $x, friend: $x, friend: $y) isa friendship, has ref 0;
      """
    Then uniquely identify answer concepts
      | x             | y            | r         |
      | key:name:Alex | key:name:Bob | key:ref:0 |
    Given transaction commits
    When connection open write transaction for database: typedb
    When typeql write query
      """
      match
        $r (friend: $x, friend: $x, friend: $x) isa friendship;
      delete
        $r (friend: $x, friend: $x);
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql read query
      """
      match $r isa friendship, links (friend: $x, friend: $y);
      """
    Then uniquely identify answer concepts
      | r         | x             | y             |
      | key:ref:0 | key:name:Bob  | key:name:Alex |
      | key:ref:0 | key:name:Alex | key:name:Bob  |


  Scenario: when deleting repeated role players in multiple statements, it removes the total number you asked to delete
    Given get answers of typeql write query
      """
      insert
      $x isa person, has name "Alex";
      $y isa person, has name "Bob";
      $r (friend: $x, friend: $x, friend: $x, friend: $y) isa friendship, has ref 0;
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
        $r (friend: $x, friend: $x, friend: $x) isa friendship;
      delete
        $r (friend: $x, friend: $x);
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql read query
      """
      match $r isa friendship, links (friend: $x, friend: $y);
      """
    Then uniquely identify answer concepts
      | r         | x             | y             |
      | key:ref:0 | key:name:Bob  | key:name:Alex |
      | key:ref:0 | key:name:Alex | key:name:Bob  |


  Scenario: when deleting one of the repeated role players from a relation, only one duplicate is removed
    Given get answers of typeql write query
      """
      insert
      $x isa person, has name "Alex";
      $y isa person, has name "Bob";
      $r (friend: $x, friend: $x, friend: $y) isa friendship, has ref 0;
      """
    Then uniquely identify answer concepts
      | x             | y            | r         |
      | key:name:Alex | key:name:Bob | key:ref:0 |
    Given transaction commits
    When connection open write transaction for database: typedb
    When typeql write query
      """
      match
        $r (friend: $x) isa friendship;
        $x isa person, has name "Alex";
      delete
        $r (friend: $x);
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql read query
      """
      match $r isa friendship, links (friend: $x, friend: $y);
      """
    Then uniquely identify answer concepts
      | r         | x             | y             |
      | key:ref:0 | key:name:Bob  | key:name:Alex |
      | key:ref:0 | key:name:Alex | key:name:Bob  |


  @ignore
  Scenario: deleting role players in multiple statements errors
    Given get answers of typeql write query
      """
      insert
      $x isa person, has name "Alex";
      $y isa person, has name "Bob";
      $z isa person, has name "Carrie";
      $r (friend: $x, friend: $y, friend: $z) isa friendship, has ref 0;
      """
    Then uniquely identify answer concepts
      | x             | y            | z               | r         |
      | key:name:Alex | key:name:Bob | key:name:Carrie | key:ref:0 |
    Given transaction commits
    When connection open write transaction for database: typedb
    When typeql write query; fails
      """
      match
        $r (friend: $x, friend: $y, friend: $z) isa friendship;
        $x isa person, has name "Alex";
        $y isa person, has name "Bob";
        $z isa person, has name "Carrie";
      delete
        $r (friend: $x);
        $r (friend: $y);
      """


  Scenario: when deleting overlapping answers, deletes are idempotent
    Given typeql write query
      """
      insert
      $x isa person, has name "Alex", has email "alex@email.com", has email "al@email.com", has email "a@email.com";
      $y isa person, has name "Bob";
      $z isa person, has name "Charlie";
      $r (friend: $x, friend: $y, friend: $z) isa friendship, has ref 0;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Then typeql write query
      """
      match
        $r isa friendship, links (friend: $x, friend: $y);
      delete
        $r (friend: $x, friend: $y);
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
        $x has $a, has $b;
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
        $x isa person;
        $y isa person;
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
      $e (employee: $x, employer: $c) isa employment, has ref 1;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Then typeql write query; fails
      """
      match
        $x isa person;
        $a isa ref;
      delete
        $x has $a;
      """
    Then typeql write query; fails
      """
      match
        $x isa person;
        $r ($x) isa friendship;
      delete
        $r (employee: $x);
      """
    Then typeql write query; fails
      """
      match
        $x isa company;
        $r isa friendship;
      delete
        $r (friend: $x);
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

    When session opens transaction of type: read
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
        $r ($x, $y) isa friendship;
      delete
        links (friend: $x, friend: $y) of $r;
      """
    Then transaction commits

    When session opens transaction of type: read
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
      special-friendship sub friendship,
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
#  We only delete role player edges until the 'match' is no longer satisfied
#
#  For example
#
#  match $r links ($role1: $x, director: $y), isa directed-by; // concrete instance matches: $r (production: $x, director: $y) isa directed-by;
#  delete links ($role1: $x) of $r
#
#  We will match '$role1' = ROLE meta type. Using this first answer we will remove $x from $r via the 'production role'.
#  This means the match clause is no longer satisfiable, and should throw the next (identical, up to role type) answer that is matched.
#
#  So, if the user does not specify a specific-enough roles, we may throw.
  Scenario: deleting a role player with a variable role errors if the role selector has multiple distinct matches
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
      relation ship-crew, relates captain, relates navigator, relates chef;
      person plays ship-crew:captain, plays ship-crew:navigator, plays ship-crew:chef;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x isa person, has name "Cook";
      $y isa person, has name "Drake";
      $z isa person, has name "Joshua";
      $r (captain: $x, navigator: $y, chef: $z) isa ship-crew;
      """
    Then transaction commits

    When connection open write transaction for database: typedb
    Then typeql write query; fails
      """
      match
        $r ($role1: $x, captain: $y) isa ship-crew;
      delete
        $r links ($role1: $x);
      """



#  Even when a $role variable matches multiple roles (will always match 'role' unless constrained)
#  We only delete role player edges until the 'match' is no longer satisfied.
#
#  **Sometimes this means multiple repeated role players will be unassigned **
#
#  For example
#
#  // concrete instance:  $r (production: $x, production: $x, production: $x, director: $y) isa directed-by;
#  match $r ($role1: $x, director: $y) isa directed-by; $type sub work;
#  delete $r links ($role1: $x);
#
#  First, we will match '$role1' = ROLE meta role. Using this answer we will remove a single $x from $r via the 'production'.
#  Next, we will match '$role1' = WORK role, and we delete another 'production' player. This repeats again for $role='production'.

# TODO: This behaviour was possible in 1.8 but is not implemented yet in 2.0, reimplement when type variables are allowed in insert and delete again
  @ignore
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
      $r (captain: $x, chef: $y, chef: $y) isa ship-crew, has ref 0;
      """
    Given transaction commits

    When connection open write transaction for database: typedb
    When get answers of typeql read query
      """
      match $rel (chef: $p) isa ship-crew;
      """
    Then uniquely identify answer concepts
      | rel       | p               |
      | key:ref:0 | key:name:Joshua |
    When typeql write query
      """
      match
        $r ($role1: $x, captain: $y) isa ship-crew;
      delete
        $r links ($role1: $x);
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql read query
      """
      match $rel (chef: $p) isa ship-crew;
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
      attribute age, value long;
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
        $x 18 isa age;
      delete
        $x;
      """
    Then transaction commits

    When session opens transaction of type: read
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
    When typeql write query; fails
      """
      match
        $x isa person, has lastname $n, has name "Alex";
        $n "Smith";
      delete
        has $n of $x;
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
    When typeql write query; fails containing "Illegal anonymous delete variable"
      """
      match
        $x isa person, has email "alex@abc.com";
      delete
        has name "Alex" of $x;
      """


  Scenario: deleting an attribute ownership using 'thing' as a label errors
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
      attribute address, value string, abstract;
      postcode sub address;
      person owns postcode;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x isa person, has name "Sherlock", has postcode "W1U8ED";
      """
    Given transaction commits

    When connection open write transaction for database: typedb
    Then typeql write query; fails
      """
      match
        $x isa person, has address $a;
      delete
        has $a of $x;
      """


  Scenario: deleting the owner of an attribute also deletes the attribute ownership
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
      attribute duration, value long;
      friendship owns duration;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x isa person, has name "Tom";
      $y isa person, has name "Jerry";
      $r isa friendship, links (friend: $x, friend: $y), has ref 0, has duration 1000;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    When get answers of typeql read query
      """
      match $x has duration $d;
      """
    Then uniquely identify answer concepts
      | x         | d                  |
      | key:ref:0 | attr:duration:1000 |
    When typeql write query
      """
      match
        $r isa friendship;
      delete
        $r;
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql read query
      """
      match $x has duration $d;
      """
    Then answer size is: 0


  Scenario: deleting the last roleplayer in a relation deletes both the relation and its attribute ownerships
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
      attribute duration, value long;
      friendship owns duration;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x isa person, has name "Emma";
      $r (friend: $x) isa friendship, has ref 0, has duration 1000;
      """
    Given transaction commits

    When connection open write transaction for database: typedb
    When get answers of typeql read query
      """
      match $x has duration $d;
      """
    Then uniquely identify answer concepts
      | x         | d                  |
      | key:ref:0 | attr:duration:1000 |
    When typeql write query
      """
      match
        $r (friend: $x) isa friendship;
      delete
        links (friend: $x) of $r;
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql read query
      """
      match $x has duration $d;
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
        has diameter $val of $x;
      """


  ####################
  # COMPLEX PATTERNS #
  ####################

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
      $reflexive (friend: $x, friend: $x) isa friendship, has ref 3;
      """
    Given transaction commits

    When connection open write transaction for database: typedb
    When typeql write query
      """
      match
        $x isa person, has name "Alex", has lastname $n;
        $y isa person, has name "John", has lastname $n;
        $refl (friend: $x, friend: $x) isa friendship, has ref 3;
        $f1 isa friendship, links (friend: $x, friend: $y), has ref 1;
      delete
        $x has $n;
        $refl (friend: $x);
        $f1 isa friendship;
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql read query
      """
      match $f (friend: $x) isa friendship;
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
      $reflexive (friend: $x, friend: $x) isa friendship, has ref 3;
      """
    Given transaction commits

    When connection open write transaction for database: typedb
    When typeql write query
      """
      match
        $x isa person, has name "Alex", has lastname $n;
        $y isa person, has name "John", has lastname $n;
        $refl (friend: $x, friend: $x) isa friendship, has ref $r1; $r1 3;
        $f1 isa friendship, links (friend: $x, friend: $y), has ref $r2; $r2 1;
      delete
        $x isa person, has $n;
        $y isa person, has $n;
        $refl (friend: $x, friend: $x) isa friendship, has $r1;
        $f1 isa friendship, links (friend: $x, friend: $y), has $r2;
      """
    Then transaction commits

    When session opens transaction of type: read
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
        $n "Alex";
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
        $x "Tatyana" isa name;
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
