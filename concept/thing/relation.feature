# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: Concept Relation

  Background:
    Given typedb starts
    Given connection opens with default authentication
    Given connection has been opened
    Given connection does not have any database
    Given connection create database: typedb
    Given connection open schema transaction for database: typedb

    Given create attribute type: username
    Given attribute(username) set value type: string
    Given create attribute type: license
    Given attribute(license) set value type: string
    Given create attribute type: date
    Given attribute(date) set value type: datetime

    Given create relation type: marriage
    Given relation(marriage) set owns: license
    Given relation(marriage) get owns(license) set annotation: @key
    Given relation(marriage) set owns: date

    Given relation(marriage) create role: wife
    Given relation(marriage) get role(wife) set annotation: @card(0..1)
    Given relation(marriage) create role: husband
    Given relation(marriage) get role(husband) set annotation: @card(0..1)

    Given create entity type: person
    Given entity(person) set owns: username
    Given entity(person) get owns(username) set annotation: @key
    Given entity(person) set plays: marriage:wife
    Given entity(person) set plays: marriage:husband

    Given transaction commits
    Given connection open write transaction for database: typedb

  Scenario: Relation with role players can be created and role players can be retrieved
    When $m = relation(marriage) create new instance with key(license): m
    Then relation $m exists
    Then relation $m has type: marriage
    Then relation(marriage) get instances contain: $m
    When $a = entity(person) create new instance with key(username): alice
    When $b = entity(person) create new instance with key(username): bob
    When relation $m add player for role(wife): $a
    When relation $m add player for role(husband): $b
    Then relation $m exists
    Then relation $m has type: marriage
    Then relation(marriage) get instances contain: $m
    Then relation $m get players for role(wife) contain: $a
    Then relation $m get players for role(husband) contain: $b
    Then relation $m get players contain: $a
    Then relation $m get players contain: $b
    Then relation $m get players contain:
      | wife    | $a |
      | husband | $b |
    When transaction commits
    When connection open read transaction for database: typedb
    When $m = relation(marriage) get instance with key(license): m
    Then relation $m exists
    Then relation $m has type: marriage
    Then relation(marriage) get instances contain: $m
    When $a = entity(person) get instance with key(username): alice
    When $b = entity(person) get instance with key(username): bob
    Then relation $m get players for role(wife) contain: $a
    Then relation $m get players for role(husband) contain: $b
    Then relation $m get players contain: $a
    Then relation $m get players contain: $b
    Then relation $m get players contain:
      | wife    | $a |
      | husband | $b |

  Scenario: Role players can get relations
    When $m = relation(marriage) create new instance with key(license): m
    When $a = entity(person) create new instance with key(username): alice
    When $b = entity(person) create new instance with key(username): bob
    Then entity $a get relations(marriage) with role(wife) do not contain: $m
    Then entity $b get relations(marriage) with role(husband) do not contain: $m
    When relation $m add player for role(wife): $a
    When relation $m add player for role(husband): $b
    Then entity $a get relations(marriage) with role(wife) contain: $m
    Then entity $b get relations(marriage) with role(husband) contain: $m
    When transaction commits
    When connection open read transaction for database: typedb
    When $m = relation(marriage) get instance with key(license): m
    Then relation(marriage) get instances contain: $m
    When $a = entity(person) get instance with key(username): alice
    When $b = entity(person) get instance with key(username): bob
    Then entity $a get relations(marriage) with role(wife) contain: $m
    Then entity $b get relations(marriage) with role(husband) contain: $m

  Scenario: Role player can be unassigned from relation
    When $m = relation(marriage) create new instance with key(license): m
    When $a = entity(person) create new instance with key(username): alice
    When $b = entity(person) create new instance with key(username): bob
    When relation $m add player for role(wife): $a
    When relation $m add player for role(husband): $b
    When relation $m remove player for role(wife): $a
    Then entity $a get relations(marriage) with role(wife) do not contain: $m
    Then relation $m get players for role(wife) do not contain: $a
    Then relation $m get players do not contain:
      | wife | $a |
    When transaction commits
    When connection open write transaction for database: typedb
    When $m = relation(marriage) get instance with key(license): m
    When $a = entity(person) get instance with key(username): alice
    Then entity $a get relations(marriage) with role(wife) do not contain: $m
    Then relation $m get players for role(wife) do not contain: $a
    Then relation $m get players do not contain:
      | wife | $a |
    When relation $m add player for role(wife): $a
    When transaction commits
    When connection open write transaction for database: typedb
    When $m = relation(marriage) get instance with key(license): m
    When $a = entity(person) get instance with key(username): alice
    When relation $m remove player for role(wife): $a
    Then entity $a get relations(marriage) with role(wife) do not contain: $m
    Then relation $m get players for role(wife) do not contain: $a
    Then relation $m get players do not contain:
      | wife | $a |
    When transaction commits
    When connection open read transaction for database: typedb
    When $m = relation(marriage) get instance with key(license): m
    When $a = entity(person) get instance with key(username): alice
    Then entity $a get relations(marriage) with role(wife) do not contain: $m
    Then relation $m get players for role(wife) do not contain: $a
    Then relation $m get players do not contain:
      | wife | $a |

  Scenario: Relation without role players get deleted on commit
    When $m = relation(marriage) create new instance with key(license): m
    When transaction commits
    When connection open read transaction for database: typedb
    When $m = relation(marriage) get instance with key(license): m
    Then relation $m does not exist
    Then relation(marriage) get instances is empty

  Scenario: Relation chain with no other role players gets deleted on commit
    Then transaction commits
    Given connection open schema transaction for database: typedb
    Given relation(marriage) create role: dependent-marriage, with @card(0..)
    Given relation(marriage) set plays: marriage:dependent-marriage
    Given transaction commits
    Given connection open write transaction for database: typedb

    When $m = relation(marriage) create new instance with key(license): m
    When $n = relation(marriage) create new instance with key(license): n
    When $o = relation(marriage) create new instance with key(license): o
    When $p = relation(marriage) create new instance with key(license): p
    When $q = relation(marriage) create new instance with key(license): q
    When $r = relation(marriage) create new instance with key(license): r
    When relation $m add player for role(dependent-marriage): $n
    When relation $n add player for role(dependent-marriage): $o
    When relation $o add player for role(dependent-marriage): $p
    When relation $p add player for role(dependent-marriage): $q
    When relation $q add player for role(dependent-marriage): $r
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(marriage) get instances is empty

  Scenario: Relation with role players can be deleted
    When $m = relation(marriage) create new instance with key(license): m
    When $a = entity(person) create new instance with key(username): alice
    When $b = entity(person) create new instance with key(username): bob
    When relation $m add player for role(wife): $a
    When relation $m add player for role(husband): $b
    When delete relation: $m
    Then relation $m is deleted: true
    Then relation(marriage) get instances do not contain: $m
    Then entity $a get relations do not contain: $m
    Then entity $b get relations do not contain: $m
    Then relation(marriage) get instances is empty
    When transaction commits
    When connection open write transaction for database: typedb
    When $a = entity(person) get instance with key(username): alice
    When $b = entity(person) get instance with key(username): bob
    When $m = relation(marriage) create new instance with key(license): m
    When relation $m add player for role(wife): $a
    When relation $m add player for role(husband): $b
    When transaction commits
    When connection open write transaction for database: typedb
    When $a = entity(person) get instance with key(username): alice
    When $b = entity(person) get instance with key(username): bob
    When $m = relation(marriage) get instance with key(license): m
    When delete relation: $m
    Then relation $m is deleted: true
    Then relation(marriage) get instances do not contain: $m
    Then entity $a get relations do not contain: $m
    Then entity $b get relations do not contain: $m
    Then relation(marriage) get instances is empty
    When transaction commits
    When connection open read transaction for database: typedb
    When $m = relation(marriage) get instance with key(license): m
    Then relation $m does not exist
    Then relation(marriage) get instances is empty

  Scenario: Relation cannot have roleplayers inserted after deletion
    When $m = relation(marriage) create new instance with key(license): m
    When $a = entity(person) create new instance with key(username): alice
    When relation $m add player for role(wife): $a
    When delete relation: $m
    Then relation $m is deleted: true
    When relation $m add player for role(wife): $a; fails

  Scenario: Cannot create instances of abstract relation type and role type
    Given transaction closes
    Given connection open schema transaction for database: typedb
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) set annotation: @abstract
    When relation(parentship) get role(parent) set annotation: @abstract
    When create entity type: parentship-player
    When entity(parentship-player) set annotation: @abstract
    When entity(parentship-player) set plays: parentship:parent
    When transaction commits
    When connection open write transaction for database: typedb
    Then relation(parentship) create new instance; fails
    When transaction closes
    When connection open schema transaction for database: typedb
    Then relation(parentship) unset annotation: @abstract; fails
    When relation(parentship) get role(parent) unset annotation: @abstract
    When relation(parentship) unset annotation: @abstract
    When entity(parentship-player) unset annotation: @abstract
    When transaction commits
    When connection open write transaction for database: typedb
    Then $r = relation(parentship) create new instance
    Then $p = entity(parentship-player) create new instance
    Then relation $r add player for role(parent): $p
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(parentship) get instances is not empty

  Scenario: Relations are cleaned up after their players are cleaned up
    Given transaction closes
    Given connection open schema transaction for database: typedb
    When create relation type: parentship
    When relation(parentship) create role: parent, with @card(0..1)
    When create relation type: parentship-player
    When relation(parentship-player) create role: unplayed-role-leading-to-cleanup, with @card(0..1)
    Then relation(parentship-player) get role(unplayed-role-leading-to-cleanup) get cardinality: @card(0..1)
    When relation(parentship-player) set plays: parentship:parent
    When transaction commits
    When connection open write transaction for database: typedb
    Then $r = relation(parentship) create new instance
    Then $p = relation(parentship-player) create new instance
    Then relation $r add player for role(parent): $p
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(parentship-player) get instances is empty
    Then relation(parentship) get instances is empty
