#
# Copyright (C) 2022 Vaticle
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#

# Driver smoke test: since the full query test suite is quite large, and we have four drivers in the same repo,
# Factory begins to struggle when those tests run on every commit. We set aside a representative sample of driver
# tests that should signal to us if something goes wrong, without overloading Factory.

#noinspection CucumberUndefinedStep
Feature: TypeDB Driver Queries

  Background: Open connection and create a simple extensible schema
    Given typedb starts
    Given connection opens with default authentication
    Given connection has been opened
    Given connection does not have any database
    Given connection create database: typedb
    Given connection open schema session for database: typedb
    Given session opens transaction of type: write

    Given typeql define
      """
      define

      person sub entity,
        plays employment:employee,
        plays friendship:friend,
        owns name,
        owns age,
        owns ref @key,
        owns email @unique;

      company sub entity,
        plays employment:employer,
        owns name,
        owns ref @key;

      employment sub relation,
        relates employee,
        relates employer,
        owns ref @key;

      friendship sub relation,
        relates friend,
        owns ref @key;

      name sub attribute,
        value string;

      age sub attribute,
        value long;

      ref sub attribute,
        value long;

      email sub attribute,
        value string;
      """
    Given transaction commits

    Given connection close all sessions

  ##########
  # DEFINE #
  ##########

  # A define query should already successfully run as part of Background and multiple other tests

  Scenario: when overriding a role that doesn't exist on the parent relation, an error is thrown
    Given connection open schema session for database: typedb
    Given session opens transaction of type: write

    Then typeql define; throws exception
      """
      define
      close-friendship sub relation, relates close-friend as friend;
      """

  ############
  # UNDEFINE #
  ############

  Scenario: calling 'undefine' with 'sub entity' on a subtype of 'entity' deletes it
    Given connection open schema session for database: typedb
    Given session opens transaction of type: write

    Given get answers of typeql get
      """
      match $x sub entity;
      """
    Given uniquely identify answer concepts
      | x                   |
      | label:person        |
      | label:entity        |
      | label:company       |
    When typeql undefine
      """
      undefine person sub entity;
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql get
      """
      match $x sub entity;
      """
    Then uniquely identify answer concepts
      | x                   |
      | label:entity        |
      | label:company       |

  Scenario: undefining a relation type throws on commit if it has existing instances
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $p isa person, has name "Harald", has ref 0, has email "harald@vaticle.com";
      $r (employee: $p) isa employment, has ref 1;
      """
    Given transaction commits
    Given connection close all sessions

    Given connection open schema session for database: typedb
    Given session opens transaction of type: write
    Then typeql undefine; throws exception
      """
      undefine
      employment relates employee;
      employment relates employer;
      person plays employment:employee;
      employment sub relation;
      """

  ##########
  # INSERT #
  ##########

  Scenario: one query can insert multiple things
    Given connection open data session for database: typedb
    Given session opens transaction of type: write

    When typeql insert
      """
      insert
      $x isa person, has ref 0;
      $y isa person, has ref 1;
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql get
      """
      match $x isa person;
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:0 |
      | key:ref:1 |

  Scenario: when inserting a roleplayer that can't play the role, an error is thrown
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Then typeql insert; throws exception
      """
      insert
      $r (employer: $p) isa employment, has ref 0;
      $p isa person, has ref 1;
      """

  ##########
  # DELETE #
  ##########

  Scenario: one delete statement can delete multiple things
    Given connection open data session for database: typedb
    Given session opens transaction of type: write

    Given get answers of typeql insert
      """
      insert
      $a isa person, has ref 0;
      $b isa person, has ref 1;
      """
    Then uniquely identify answer concepts
      | a         | b         |
      | key:ref:0 | key:ref:1 |

    Given transaction commits
    Given session opens transaction of type: write
    When typeql delete
      """
      match
      $p isa person;
      delete
      $p isa person;
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql get
      """
      match $x isa person;
      """
    Then answer size is: 0

  Scenario: deleting an instance using an unrelated type label throws
    Given connection open data session for database: typedb
    Given session opens transaction of type: write

    Given typeql insert
      """
      insert
      $x isa person, has name "Alex", has ref 0;
      $n "John" isa name;
      """
    Given transaction commits

    Given session opens transaction of type: write
    Then typeql delete; throws exception
      """
      match
        $x isa person;
        $r isa name; $r "John";
      delete
        $r isa person;
      """

  ##########
  # UPDATE #
  ##########

  Scenario: Roleplayer exchange
    Given connection open schema session for database: typedb
    Given session opens transaction of type: write

    Given typeql define
      """
      define
      person
        plays parenthood:parent,
        plays parenthood:child;
      parenthood sub relation,
        relates parent,
        relates child;
      """
    Given transaction commits
    Given connection close all sessions

    Given connection open data session for database: typedb
    Given session opens transaction of type: write

    Given get answers of typeql insert
      """
      insert
      $x isa person, has name "Alex", has ref 0;
      $y isa person, has name "Bob", has ref 1;
      $r (parent: $x, child:$y) isa parenthood;
      """
    Given transaction commits

    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    When typeql update
      """
      match $r (parent: $x, child: $y) isa parenthood;
      delete $r isa parenthood;
      insert (parent: $y, child: $x) isa parenthood;
      """

  Scenario: Deleting anonymous variables throws an exception
    Given connection open data session for database: typedb
    Given session opens transaction of type: write

    Given get answers of typeql insert
      """
      insert
        $x isa person, has name "Alex", has ref 0;
        $y isa person, has name "Alex", has ref 1;
      """
    Given transaction commits

    Given session opens transaction of type: write
    Then typeql update; throws exception
      """
      match
      $x isa person, has ref 1;
      delete $x has name "Alex";
      insert $x has name "Bob";
      """
    Then session transaction closes

  #########
  #  GET  #
  #########

  Scenario: when a 'get' has unbound variables, an error is thrown
    Given connection open data session for database: typedb
    Given session opens transaction of type: read
    Then typeql get; throws exception
      """
      match $x isa person; get $y;
      """

  Scenario: Value variables can be specified in a 'get'
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $x "Lisa" isa name;
      $y 16 isa age;
      $z isa person, has name $x, has age $y, has ref 0;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match
        $z isa person, has name $x, has age $y;
        ?b = 2017 - $y;
      get $z, $x, ?b;
      """
    Then uniquely identify answer concepts
      | z         | x              | b                |
      | key:ref:0 | attr:name:Lisa | value:long:2001  |

  Scenario: 'count' returns the total number of answers
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $p1 isa person, has name "Klaus", has ref 0;
      $p2 isa person, has name "Kristina", has ref 1;
      $p3 isa person, has name "Karen", has ref 2;
      $f (friend: $p1, friend: $p2) isa friendship, has ref 3;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match
        $x isa person;
        $y isa name;
        $f isa friendship;
      """
    Then answer size is: 9
    When get answer of typeql get aggregate
      """
      match
        $x isa person;
        $y isa name;
        $f isa friendship;
      count;
      """
    Then aggregate value is: 9
    When get answers of typeql get
      """
      match
        $x isa person;
        $y isa name;
        $f (friend: $x) isa friendship;
      """
    Then answer size is: 6
    When get answer of typeql get aggregate
      """
      match
        $x isa person;
        $y isa name;
        $f (friend: $x) isa friendship;
      count;
      """
    Then aggregate value is: 6

  Scenario: answers can be grouped by a value variable contained in the answer set
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $p1 isa person, has name "Violet", has ref 1250;
      $p2 isa person, has name "Rupert", has ref 1750;
      $p3 isa person, has name "Bernard", has ref 2050;
      $p4 isa person, has name "Colin", has ref 3000;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql get group
      """
      match
       $x isa person, has ref $r;
       ?bracket = floor($r/1000) * 1000;
       get $x, ?bracket;
       group ?bracket;
      """
    Then answer groups are
      | owner           | x            |
      | value:long:1000 | key:ref:1250 |
      | value:long:1000 | key:ref:1750 |
      | value:long:2000 | key:ref:2050 |
      | value:long:3000 | key:ref:3000 |

  Scenario: the size of each answer group can be retrieved using a group 'count'
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $p1 isa person, has name "Violet", has ref 0;
      $p2 isa person, has name "Rupert", has ref 1;
      $p3 isa person, has name "Bernard", has ref 2;
      $p4 isa person, has name "Colin", has ref 3;
      $f (friend: $p1, friend: $p2, friend: $p3, friend: $p4) isa friendship, has ref 4;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match $x isa person;
      """
    When get answers of typeql get group aggregate
      """
      match ($x, $y) isa friendship;
      group $x;
      count;
      """
    Then group aggregate values are
      | owner     | value |
      | key:ref:0 | 3     |
      | key:ref:1 | 3     |
      | key:ref:2 | 3     |
      | key:ref:3 | 3     |

  ###############
  # EXPRESSIONS #
  ###############

  Scenario: A value variable must have exactly one assignment constraint in the same scope
    Given connection open data session for database: typedb

    Given session opens transaction of type: read
    Then typeql get; throws exception containing "value variable '?v' is never assigned to"
    """
      match
        $x isa person, has age $a, has age $h;
        ?v == $a;
        ?v > $h;
      get
        $x, ?v;
      """

    Given session opens transaction of type: read
    Then typeql get; throws exception containing "value variable '?v' can only have one assignment in the first scope"
    """
      match
        $x isa person, has age $a, has age $h;
        ?v = $a * 2;
        ?v = $h / 2;
      get
        $x, ?v;
      """

  Scenario: Test operator definitions
    Given connection open data session for database: typedb
    Given session opens transaction of type: read

    When get answers of typeql get
    """
      match
        ?a = 6.0 + 3.0;
        ?b = 6.0 - 3.0;
        ?c = 6.0 * 3.0;
        ?d = 6.0 / 3.0;
      get
        ?a, ?b, ?c, ?d;
      """
    Then uniquely identify answer concepts
      | a                 | b                 | c                  | d                  |
      | value:double: 9.0 | value:double: 3.0 | value:double: 18.0 | value:double: 2.0  |

    When get answers of typeql get
    """
      match
        ?a = 6 + 3;
        ?b = 6 - 3;
        ?c = 6 * 3;
        ?d = 6 / 3;
      get
        ?a, ?b, ?c, ?d;
      """
    Then uniquely identify answer concepts
      | a             | b            | c             | d                  |
      | value:long: 9 | value:long:3 | value:long:18 | value:double: 2.0  |

    When get answers of typeql get
    """
      match
        ?a = 6.0 + 3;
        ?b = 6.0 - 3;
        ?c = 6.0 * 3;
        ?d = 6.0 / 3;
      get
        ?a, ?b, ?c, ?d;
      """
    Then uniquely identify answer concepts
      | a                 | b                 | c                  | d                  |
      | value:double: 9.0 | value:double: 3.0 | value:double: 18.0 | value:double: 2.0  |

    When get answers of typeql get
    """
      match
        ?a = 6 + 3.0;
        ?b = 6 - 3.0;
        ?c = 6 * 3.0;
        ?d = 6 / 3.0;
      get
        ?a, ?b, ?c, ?d;
      """
    Then uniquely identify answer concepts
      | a                 | b                 | c                  | d                  |
      | value:double: 9.0 | value:double: 3.0 | value:double: 18.0 | value:double: 2.0  |
