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

#noinspection CucumberUndefinedStep
Feature: TypeQL Match Clause

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
        plays friendship:friend,
        plays employment:employee,
        owns name,
        owns age,
        owns ref @key,
        owns email @unique;
      company sub entity,
        plays employment:employer,
        owns name,
        owns ref @key;
      friendship sub relation,
        relates friend,
        owns ref @key;
      employment sub relation,
        relates employee,
        relates employer,
        owns ref @key;
      name sub attribute, value string;
      age sub attribute, value long;
      ref sub attribute, value long;
      email sub attribute, value string;
      """
    Given transaction commits

    Given session opens transaction of type: write


  ##################
  # SCHEMA QUERIES #
  ##################

  Scenario: 'type' matches only the specified type, and does not match subtypes
    Given typeql define
      """
      define
      writer sub person;
      scifi-writer sub writer;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match $x type person; get;
      """
    Then uniquely identify answer concepts
      | x            |
      | label:person |


  Scenario: 'sub' can be used to match the specified type and all its subtypes, including indirect subtypes
    Given typeql define
      """
      define
      writer sub person;
      scifi-writer sub writer;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match $x sub person; get;
      """
    Then uniquely identify answer concepts
      | x                  |
      | label:person       |
      | label:writer       |
      | label:scifi-writer |


  Scenario: 'sub' can be used to match the specified type and all its supertypes, including indirect supertypes
    Given typeql define
      """
      define
      writer sub person;
      scifi-writer sub writer;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match writer sub $x; get;
      """
    Then uniquely identify answer concepts
      | x            |
      | label:writer |
      | label:person |
      | label:entity |
      | label:thing  |


  Scenario: 'sub' can be used to retrieve all instances of types that are subtypes of a given type
    Given typeql define
      """
      define

      child sub person;
      worker sub person;
      retired-person sub person;
      construction-worker sub worker;
      bricklayer sub construction-worker;
      crane-driver sub construction-worker;
      telecoms-worker sub worker;
      mobile-network-researcher sub telecoms-worker;
      smartphone-designer sub telecoms-worker;
      telecoms-business-strategist sub telecoms-worker;
      """
    Given transaction commits

    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $a isa child, has name "Alfred", has ref 0;
      $b isa retired-person, has name "Barbara", has ref 1;
      $c isa bricklayer, has name "Charles", has ref 2;
      $d isa crane-driver, has name "Debbie", has ref 3;
      $e isa mobile-network-researcher, has name "Edmund", has ref 4;
      $f isa telecoms-business-strategist, has name "Felicia", has ref 5;
      $g isa worker, has name "Gary", has ref 6;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match
        $x isa $type;
        $type sub worker;
      get;
      """
    # Alfred and Barbara are not retrieved, as they aren't subtypes of worker
    Then uniquely identify answer concepts
      | x         | type                               |
      | key:ref:2 | label:bricklayer                   |
      | key:ref:2 | label:construction-worker          |
      | key:ref:2 | label:worker                       |
      | key:ref:3 | label:crane-driver                 |
      | key:ref:3 | label:construction-worker          |
      | key:ref:3 | label:worker                       |
      | key:ref:4 | label:mobile-network-researcher    |
      | key:ref:4 | label:telecoms-worker              |
      | key:ref:4 | label:worker                       |
      | key:ref:5 | label:telecoms-business-strategist |
      | key:ref:5 | label:telecoms-worker              |
      | key:ref:5 | label:worker                       |
      | key:ref:6 | label:worker                       |


  Scenario: 'sub!' matches the type's direct subtypes
    Given typeql define
      """
      define
      writer sub person;
      scifi-writer sub writer;
      musician sub person;
      flutist sub musician;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match $x sub! person; get;
      """
    Then uniquely identify answer concepts
      | x              |
      | label:writer   |
      | label:musician |


  Scenario: 'sub!' can be used to match a type's direct supertype
    Given typeql define
      """
      define
      writer sub person;
      scifi-writer sub writer;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match writer sub! $x; get;
      """
    Then uniquely identify answer concepts
      | x            |
      | label:person |


  @ignore
  # TODO this does not work on types anymore - types cannot be specified by IID
  Scenario: subtype hierarchy satisfies transitive sub assertions
    Given typeql define
      """
      define
      sub1 sub entity;
      sub2 sub sub1;
      sub3 sub sub1;
      sub4 sub sub2;
      sub5 sub sub4;
      sub6 sub sub5;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match
        $x sub $y;
        $y sub $z;
        $z sub sub1;
      """
    Then each answer satisfies
      """
      match $x sub $z; $x iid <answer.x.iid>; $z iid <answer.z.iid>; get;
      """


  Scenario: 'owns' matches types that own the specified attribute type
    When get answers of typeql get
      """
      match $x owns age; get;
      """
    Then uniquely identify answer concepts
      | x            |
      | label:person |


  Scenario: 'owns' can match types that can own themselves
    Given typeql define
      """
      define
      unit sub attribute, value string, owns unit;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match $x owns $x; get;
      """
    Then uniquely identify answer concepts
      | x          |
      | label:unit |


  Scenario: 'owns' does not match types that own only a subtype of the specified attribute type
    Given typeql define
      """
      define
      general-name sub attribute, abstract, value string;
      institution sub entity, abstract, owns general-name;
      club-name sub general-name;
      club sub entity, owns club-name;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match $x owns general-name; get;
      """
    Then uniquely identify answer concepts
      | x                 |
      | label:institution |


  Scenario: 'owns' does not match types that own only a supertype of the specified attribute type
    Given typeql define
      """
      define
      general-name sub attribute, abstract, value string;
      institution sub entity, abstract, owns general-name;
      club-name sub general-name;
      club sub entity, owns club-name;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match $x owns club-name; get;
      """
    Then uniquely identify answer concepts
      | x          |
      | label:club |


  Scenario: 'owns' can be used to match attribute types that a given type owns
    When get answers of typeql get
      """
      match person owns $x; get;
      """
    Then uniquely identify answer concepts
      | x           |
      | label:name  |
      | label:email |
      | label:age   |
      | label:ref   |


  Scenario: directly declared 'owns' annotations are queryable
    When get answers of typeql get
      """
      match $x owns ref @key; get;
      """
    Then uniquely identify answer concepts
      | x                |
      | label:person     |
      | label:company    |
      | label:friendship |
      | label:employment |
    When get answers of typeql get
      """
      match $x owns $a @key; get;
      """
    Then uniquely identify answer concepts
      | x                | a         |
      | label:person     | label:ref |
      | label:company    | label:ref |
      | label:friendship | label:ref |
      | label:employment | label:ref |
    When get answers of typeql get
      """
      match $x owns email @unique; get;
      """
    Then uniquely identify answer concepts
      | x            |
      | label:person |
    When get answers of typeql get
      """
      match $x owns $a @unique; get;
      """
    Then uniquely identify answer concepts
      | x            | a           |
      | label:person | label:email |


  Scenario: inherited 'owns' annotations are queryable
    Given typeql define
      """
      define child sub person;
      """
    Given transaction commits
    Given session opens transaction of type: write
    When get answers of typeql get
      """
      match $x owns ref @key; get;
      """
    Then uniquely identify answer concepts
      | x                |
      | label:person     |
      | label:child      |
      | label:company    |
      | label:friendship |
      | label:employment |
    When get answers of typeql get
      """
      match $x owns $a @key; get;
      """
    Then uniquely identify answer concepts
      | x                | a         |
      | label:person     | label:ref |
      | label:child      | label:ref |
      | label:company    | label:ref |
      | label:friendship | label:ref |
      | label:employment | label:ref |
    When get answers of typeql get
      """
      match $x owns email @unique; get;
      """
    Then uniquely identify answer concepts
      | x            |
      | label:person |
      | label:child  |
    When get answers of typeql get
      """
      match $x owns $a @unique; get;
      """
    Then uniquely identify answer concepts
      | x            | a           |
      | label:person | label:email |
      | label:child  | label:email |


  Scenario: 'owns' can be used to retrieve all instances of types that can own a given attribute type
    Given typeql define
      """
      define
      employment owns name;
      """
    Given transaction commits

    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $x isa person, has ref 0;
      $y isa company, has ref 1;
      $z (friend: $x) isa friendship, has ref 2;
      $w (employee: $x, employer: $y) isa employment, has ref 3;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match
        $x isa $type;
        $type owns name;
      get;
      """
    # friendship and ref should not be retrieved, as they can't have a name
    Then uniquely identify answer concepts
      | x         | type             |
      | key:ref:0 | label:person     |
      | key:ref:1 | label:company    |
      | key:ref:3 | label:employment |


  Scenario: 'plays' matches types that can play the specified role
    When get answers of typeql get
      """
      match $x plays friendship:friend; get;
      """
    Then uniquely identify answer concepts
      | x            |
      | label:person |


  Scenario: 'plays' does not match types that only play a subrole of the specified role
    Given typeql define
      """
      define
      close-friendship sub friendship, relates close-friend as friend;
      friendly-person sub entity, plays close-friendship:close-friend;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match $x plays friendship:friend; get;
      """
    Then uniquely identify answer concepts
      | x            |
      | label:person |


  Scenario: inherited role types cannot be be matched via role type alias
    Given typeql define
      """
      define
      close-friendship sub friendship;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When typeql get; throws exception
      """
      match $x plays close-friendship:friend; get;
      """


  Scenario: 'plays' does not match types that only play a super-role of the specified role
    Given typeql define
      """
      define
      close-friendship sub friendship, relates close-friend as friend;
      friendly-person sub entity, plays close-friendship:close-friend;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match $x plays close-friendship:close-friend; get;
      """
    Then uniquely identify answer concepts
      | x                     |
      | label:friendly-person |


  Scenario: 'plays' can be used to match roles that a particular type can play
    When get answers of typeql get
      """
      match person plays $x; get;
      """
    Then uniquely identify answer concepts
      | x                         |
      | label:friendship:friend   |
      | label:employment:employee |


  Scenario: 'plays' can be used to retrieve all instances of types that can play a specific role
    Given typeql define
      """
      define
      dog sub entity,
        plays friendship:friend,
        owns ref @key;
      """
    Given transaction commits

    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $x isa person, has ref 0;
      $y isa company, has ref 1;
      $z isa dog, has ref 2;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match
        $x isa $type;
        $type plays friendship:friend;
      get;
      """
    Then uniquely identify answer concepts
      | x         | type         |
      | key:ref:0 | label:person |
      | key:ref:2 | label:dog    |


  Scenario: 'owns @key' matches types that own the specified attribute type as a key
    Given typeql define
      """
      define
      breed sub attribute, value string;
      dog sub entity, owns breed @key;
      kennel sub entity, owns breed;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match $x owns breed @key; get;
      """
    Then uniquely identify answer concepts
      | x         |
      | label:dog |


  Scenario: 'key' can be used to find all attribute types that a given type owns as a key
    When get answers of typeql get
      """
      match person owns $x @key; get;
      """
    Then uniquely identify answer concepts
      | x         |
      | label:ref |


  Scenario: 'owns' without '@key' matches all types that own the specified attribute type, even if they use it as a key
    Given typeql define
      """
      define
      breed sub attribute, value string;
      dog sub entity, owns breed @key;
      cat sub entity, owns breed;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match $x owns breed; get;
      """
    Then uniquely identify answer concepts
      | x         |
      | label:dog |
      | label:cat |


  Scenario: 'relates' matches relation types where the specified role can be played
    When get answers of typeql get
      """
      match $x relates employee; get;
      """
    Then uniquely identify answer concepts
      | x                |
      | label:employment |

  # TODO cannot currently query for schema with 'as'
  @ignore
  Scenario: 'relates' with 'as' matches relation types that override the specified roleplayer
    Given typeql define
      """
      define
      close-friendship sub friendship, relates close-friend as friend;
      friendly-person sub entity, plays close-friendship:close-friend;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match $x relates close-friend as friend; get;
      """
    Then uniquely identify answer concepts
      | x                      |
      | label:close-friendship |


  Scenario: 'relates' without 'as' does not match relation types that override the specified roleplayer
    Given typeql define
      """
      define
      close-friendship sub friendship, relates close-friend as friend;
      friendly-person sub entity, plays close-friendship:close-friend;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match $x relates friend; get;
      """
    Then uniquely identify answer concepts
      | x                |
      | label:friendship |


  Scenario: 'relates' can be used to retrieve all the roles of a relation type
    When get answers of typeql get
      """
      match employment relates $x; get;
      """
    Then uniquely identify answer concepts
      | x                         |
      | label:employment:employee |
      | label:employment:employer |


  # TODO we can't test like this because the IID is not a valid encoded IID -- need to rethink this test
  @ignore
  Scenario: when matching by a concept iid that doesn't exist, an empty result is returned
    When get answers of typeql get
      """
      match
        $x iid 0x83cb2;
        $y iid 0x4ba92;
      """
    Then answer size is: 0


  ##########
  # THINGS #
  ##########

  Scenario: 'isa' gets any thing for any type
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $_ isa person, has ref 0;
      $_ isa person, has ref 1;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match $x isa $y; get;
      """
    Then uniquely identify answer concepts
      | x          | y               |
      | key:ref:0  | label:person    |
      | key:ref:0  | label:entity    |
      | key:ref:0  | label:thing     |
      | key:ref:1  | label:person    |
      | key:ref:1  | label:entity    |
      | key:ref:1  | label:thing     |
      | attr:ref:0 | label:ref       |
      | attr:ref:0 | label:attribute |
      | attr:ref:0 | label:thing     |
      | attr:ref:1 | label:ref       |
      | attr:ref:1 | label:attribute |
      | attr:ref:1 | label:thing     |

  Scenario: 'isa' matches things of the specified type and all its subtypes
    Given typeql define
      """
      define
      writer sub person;
      scifi-writer sub writer;
      good-scifi-writer sub scifi-writer;
      """
    Given transaction commits

    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $x isa person, has ref 0;
      $y isa writer, has ref 1;
      $z isa scifi-writer, has ref 2;
      $w isa good-scifi-writer, has ref 3;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match $x isa writer; get;
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:1 |
      | key:ref:2 |
      | key:ref:3 |


  Scenario: 'isa!' only matches things of the specified type, and does not match subtypes
    Given typeql define
      """
      define
      writer sub person;
      scifi-writer sub writer;
      good-scifi-writer sub scifi-writer;
      """
    Given transaction commits

    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $x isa person, has ref 0;
      $y isa writer, has ref 1;
      $z isa scifi-writer, has ref 2;
      $w isa good-scifi-writer, has ref 3;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match $x isa! writer; get;
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:1 |


  Scenario: 'isa' matches no answers if the type tree is fully abstract
    Given typeql define
      """
      define
      person sub entity, abstract;
      writer sub person, abstract;
      scifi-writer sub writer, abstract;
      good-scifi-writer sub scifi-writer, abstract;
      """
    Given transaction commits

    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match $x isa person; get;
      """
    Then answer size is: 0


  Scenario: 'iid' matches the instance with the specified internal iid
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $x isa person, has ref 0;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match $x isa person; get;
      """
    Then each answer satisfies
      """
      match $x iid <answer.x.iid>; get;
      """


  Scenario: 'iid' for a variable of a different type throws
    Given typeql define
      """
      define
      shop sub entity, owns address;
      grocery sub shop;
      address sub attribute, value string;
      """
    Given transaction commits

    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $x isa shop, has address "123 street";
      $y isa grocery, has address "123 street";
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match $x isa! shop; get;
      """
    Then templated typeql get; throws exception
      """
      match $x iid <answer.x.iid>; $x isa grocery, has address "123 street"; get;
      """


  Scenario: match returns an empty answer if there are no matches
    When get answers of typeql get
      """
      match $x isa person, has name "Anonymous Coward"; get;
      """
    Then answer size is: 0


  Scenario: when matching by a type whose label doesn't exist, an error is thrown
    Then typeql get; throws exception
      """
      match $x isa ganesh; get;
      """
    Then session transaction is open: false


  Scenario: when matching by a relation type whose label doesn't exist, an error is thrown
    Then typeql get; throws exception
      """
      match ($x, $y) isa $type; $type type jakas-relacja; get;
      """
    Then session transaction is open: false


  Scenario: when matching a non-existent type label to a variable from a generic 'isa' query, an error is thrown
    Then typeql get; throws exception
      """
      match $x isa $type; $type type polok; get;
      """
    Then session transaction is open: false


  Scenario: when one entity exists, and we match two variables both of that entity type, the entity is returned
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert $x isa person, has ref 0;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match
        $x isa person;
        $y isa person;
      get;
      """
    Then uniquely identify answer concepts
      | x         | y         |
      | key:ref:0 | key:ref:0 |


  Scenario: an error is thrown when matching that a variable has a specific type, when that type is in fact a role type
    Then typeql get; throws exception
      """
      match $x isa friendship:friend; get;
      """


  # TODO we can't query for rule anymore
  @ignore
  Scenario: an error is thrown when matching that a variable has a specific type, when that type is in fact a rule
    Given typeql define
      """
      define
      rule metre-rule:
      when {
        $x isa person;
      } then {
        $x has name "metre";
      };
      """
    Given transaction commits

    Given session opens transaction of type: read
    Then typeql get; throws exception
      """
      match $x isa metre-rule; get;
      """
    Then session transaction is open: false



  #############
  # RELATIONS #
  #############

  Scenario: a relation is matchable from role players without specifying relation type
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $x isa person, has ref 0;
      $y isa company, has ref 1;
      $r (employee: $x, employer: $y) isa employment,
         has ref 2;
      """
    Given transaction commits

    Given session opens transaction of type: read
    Then get answers of typeql get
      """
      match $x isa person; $r (employee: $x) isa relation; get;
      """
    Then uniquely identify answer concepts
      | x         | r         |
      | key:ref:0 | key:ref:2 |
    When get answers of typeql get
      """
      match $y isa company; $r (employer: $y) isa relation; get;
      """
    Then uniquely identify answer concepts
      | y         | r         |
      | key:ref:1 | key:ref:2 |


  Scenario: relations are matchable from roleplayers without specifying any roles
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $x isa person, has ref 0;
      $y isa company, has ref 1;
      $r (employee: $x, employer: $y) isa employment,
         has ref 2;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match $x isa person; $r ($x) isa relation; get;
      """
    Then uniquely identify answer concepts
      | x         | r         |
      | key:ref:0 | key:ref:2 |


  Scenario: all combinations of players in a relation can be retrieved
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    When typeql insert
      """
      insert $p isa person, has ref 0;
      $c isa company, has ref 1;
      $c2 isa company, has ref 2;
      $r (employee: $p, employer: $c, employer: $c2) isa employment, has ref 3;
      """
    Given transaction commits

    Given session opens transaction of type: read
    Then get answers of typeql get
      """
      match $r ($x, $y) isa employment; get;
      """
    Then uniquely identify answer concepts
      | x         | y         | r         |
      | key:ref:0 | key:ref:1 | key:ref:3 |
      | key:ref:1 | key:ref:0 | key:ref:3 |
      | key:ref:0 | key:ref:2 | key:ref:3 |
      | key:ref:2 | key:ref:0 | key:ref:3 |
      | key:ref:1 | key:ref:2 | key:ref:3 |
      | key:ref:2 | key:ref:1 | key:ref:3 |


  Scenario: repeated role players are retrieved singly when queried doubly
    Given typeql define
      """
      define
      some-entity sub entity, plays symmetric:player, owns ref @key;
      symmetric sub relation, relates player, owns ref @key;
      """
    Given transaction commits

    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert $x isa some-entity, has ref 0; (player: $x, player: $x) isa symmetric, has ref 1;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match $r (player: $x, player: $x) isa relation; get;
      """
    Then uniquely identify answer concepts
      | x         | r         |
      | key:ref:0 | key:ref:1 |


  Scenario: repeated role players are retrieved singly when queried singly
    Given typeql define
      """
      define
      some-entity sub entity, plays symmetric:player, owns ref @key;
      symmetric sub relation, relates player, owns ref @key;
      """
    Given transaction commits

    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert $x isa some-entity, has ref 0; (player: $x, player: $x) isa symmetric, has ref 1;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match $r (player: $x) isa relation; get;
      """
    Then uniquely identify answer concepts
      | x         | r         |
      | key:ref:0 | key:ref:1 |


  Scenario: a mixture of variable and explicit roles can retrieve relations
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $x isa company, has ref 0;
      $y isa person, has ref 1;
      (employer: $x, employee: $y) isa employment, has ref 2;
      """
    Given transaction commits
    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match (employer: $e, $role: $x) isa employment; get;
      """
    Then uniquely identify answer concepts
      | e         | x         | role                      |
      | key:ref:0 | key:ref:1 | label:employment:employee |
      | key:ref:0 | key:ref:1 | label:relation:role       |

  @ignore
  Scenario: A relation can play a role in itself
    Given typeql define
      """
      define
      comparator sub relation,
        relates compared,
        plays comparator:compared;
      """
    Given transaction commits

    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $r(compared:$r) isa comparator;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match $r(compared:$r) isa comparator; get;
      """
    Then answer size is: 1

  @ignore
  Scenario: A relation can play a role in itself and have additional roleplayers
    Given typeql define
      """
      define
      comparator sub relation,
        relates compared,
        plays comparator:compared;
      variable sub entity,
        plays comparator:compared;
      """
    Given transaction commits

    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $r(compared: $v, compared:$r) isa comparator;
      $v isa variable;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match $r(compared: $v, compared:$r) isa comparator; get;
      """
    Then answer size is: 1


  Scenario: relations between distinct concepts are not retrieved when matching concepts that relate to themselves
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $x isa person, has ref 1;
      $y isa person, has ref 2;
      (friend: $x, friend: $y) isa friendship, has ref 0;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match (friend: $x, friend: $x) isa friendship; get;
      """
    Then answer size is: 0


  Scenario: matching a chain of relations only returns answers if there is a chain of the required length
    Given typeql define
      """
      define

      gift-delivery sub relation,
        relates sender,
        relates recipient;

      person plays gift-delivery:sender,
        plays gift-delivery:recipient;
      """
    Given transaction commits

    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $x1 isa person, has name "Soroush", has ref 0;
      $x2a isa person, has name "Martha", has ref 1;
      $x2b isa person, has name "Patricia", has ref 2;
      $x2c isa person, has name "Lily", has ref 3;

      (sender: $x1, recipient: $x2a) isa gift-delivery;
      (sender: $x1, recipient: $x2b) isa gift-delivery;
      (sender: $x1, recipient: $x2c) isa gift-delivery;
      (sender: $x2a, recipient: $x2b) isa gift-delivery;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match
        (sender: $a, recipient: $b) isa gift-delivery;
        (sender: $b, recipient: $c) isa gift-delivery;
      get;
      """
    Then uniquely identify answer concepts
      | a         | b         | c         |
      | key:ref:0 | key:ref:1 | key:ref:2 |
    When get answers of typeql get
      """
      match
        (sender: $a, recipient: $b) isa gift-delivery;
        (sender: $b, recipient: $c) isa gift-delivery;
        (sender: $c, recipient: $d) isa gift-delivery;
      get;
      """
    Then answer size is: 0


  Scenario: when multiple relation instances exist with the same roleplayer, matching that player returns just 1 answer
    Given typeql define
      """
      define
      residency sub relation,
        relates resident,
        owns ref @key;
      person plays residency:resident;
      """
    Given transaction commits

    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $x isa person, has ref 0;
      $e (employee: $x) isa employment, has ref 1;
      $f (friend: $x) isa friendship, has ref 2;
      $r (resident: $x) isa residency, has ref 3;
      """
    Given transaction commits

    Given session opens transaction of type: read
    Given get answers of typeql get
      """
      match $r isa relation; get;
      """
    Given uniquely identify answer concepts
      | r         |
      | key:ref:1 |
      | key:ref:2 |
      | key:ref:3 |
    When get answers of typeql get
      """
      match ($x) isa relation; get;
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:0 |
    When get answers of typeql get
      """
      match ($x); get;
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:0 |


  Scenario: an error is thrown when matching an entity type as if it were a role type
    Then typeql get; throws exception
      """
      match (person: $x) isa relation; get;
      """
    Then session transaction is open: false


  Scenario: an error is thrown when matching an entity type as if it were a relation type
    Then typeql get; throws exception
      """
      match ($x) isa person; get;
      """
    Then session transaction is open: false


  Scenario: an error is thrown when matching a non-existent type label as if it were a relation type
    Then typeql get; throws exception
      """
      match ($x) isa bottle-of-rum; get;
      """
    Then session transaction is open: false


  Scenario: when matching a role type that doesn't exist, an error is thrown
    Then typeql get; throws exception
      """
      match (rolein-rolein-rolein: $rolein) isa relation; get;
      """
    Then session transaction is open: false


  Scenario: when matching a role in a relation type that doesn't have that role, an error is thrown
    Then typeql get; throws exception
      """
      match (friend: $x) isa employment; get;
      """
    Then session transaction is open: false


  Scenario: when matching a roleplayer in a relation that can't actually play that role, an error is thrown
    When typeql get; throws exception
      """
      match
      $x isa company;
      ($x) isa friendship;
      """
    Then session transaction is open: false


  Scenario: Relations can be queried with pairings of relation and role types that are not directly related to each other
    Given typeql define
      """
      define
      person plays marriage:spouse, plays hetero-marriage:husband, plays hetero-marriage:wife;
      marriage sub relation, relates spouse;
      hetero-marriage sub marriage, relates husband as spouse, relates wife as spouse;
      civil-marriage sub marriage;
      """
    Given transaction commits

    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $a isa person, has ref 1;
      $b isa person, has ref 2;
      (wife: $a, husband: $b) isa hetero-marriage;
      (spouse: $a, spouse: $b) isa civil-marriage;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match $m (wife: $x, husband: $y) isa hetero-marriage; get;
      """
    Then answer size is: 1
    Then typeql get; throws exception
      """
      match $m (wife: $x, husband: $y) isa civil-marriage; get;
      """
    Then session transaction is open: false
    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match $m (wife: $x, husband: $y) isa marriage; get;
      """
    Then answer size is: 1
    When get answers of typeql get
      """
      match $m (wife: $x, husband: $y) isa relation; get;
      """
    Then answer size is: 1
    When get answers of typeql get
      """
      match $m (spouse: $x, spouse: $y) isa hetero-marriage; get;
      """
    Then answer size is: 2
    When get answers of typeql get
      """
      match $m (spouse: $x, spouse: $y) isa civil-marriage; get;
      """
    Then answer size is: 2
    When get answers of typeql get
      """
      match $m (spouse: $x, spouse: $y) isa marriage; get;
      """
    Then answer size is: 4
    When get answers of typeql get
      """
      match $m (spouse: $x, spouse: $y) isa relation; get;
      """
    Then answer size is: 4
    When get answers of typeql get
      """
      match $m (role: $x, role: $y) isa hetero-marriage; get;
      """
    Then answer size is: 2
    When get answers of typeql get
      """
      match $m (role: $x, role: $y) isa civil-marriage; get;
      """
    Then answer size is: 2
    When get answers of typeql get
      """
      match $m (role: $x, role: $y) isa marriage; get;
      """
    Then answer size is: 4
    When get answers of typeql get
      """
      match $m (role: $x, role: $y) isa relation; get;
      """
    Then answer size is: 4


  Scenario: When some relations do not satisfy the query, the correct ones are still found
    Given typeql define
      """
      define
      car sub entity, plays ownership:owned, owns ref @key;
      person plays ownership:owner;
      company plays ownership:owner;
      ownership sub relation, relates owned, relates owner, owns is-insured;
      is-insured sub attribute, value boolean;
      """
    Given transaction commits
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      (owned: $c1, owner: $company) isa ownership, has is-insured true;
      $c1 isa car, has ref 0; $company isa company, has ref 1;
      """
    Given transaction commits
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      (owned: $c2, owner: $person) isa ownership, has is-insured true;
      $c2 isa car, has ref 2; $person isa person, has ref 3;
      """
    Given transaction commits
    Given session opens transaction of type: read
    When get answers of typeql get
    """
    match $r (owner: $x) isa ownership, has is-insured true; $x isa person; get;
    """
    Then answer size is: 1

  ##############
  # ATTRIBUTES #
  ##############

  Scenario Outline: '<type>' attributes can be matched by value
    Given typeql define
      """
      define <attr> sub attribute, value <type>, owns ref @key;
      """
    Given transaction commits

    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert $n <value> isa <attr>, has ref 0;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match $a <value>; get;
      """
    Then uniquely identify answer concepts
      | a         |
      | key:ref:0 |

    Examples:
      | attr        | type     | value      |
      | colour      | string   | "Green"    |
      | calories    | long     | 1761       |
      | grams       | double   | 9.6        |
      | gluten-free | boolean  | false      |
      | use-by-date | datetime | 2020-06-16 |


  Scenario Outline: when matching a '<type>' attribute by a value that doesn't exist, an empty answer is returned
    Given typeql define
      """
      define <attr> sub attribute, value <type>, owns ref @key;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match $a <value>; get;
      """
    Then answer size is: 0

    Examples:
      | attr        | type     | value      |
      | colour      | string   | "Green"    |
      | calories    | long     | 1761       |
      | grams       | double   | 9.6        |
      | gluten-free | boolean  | false      |
      | use-by-date | datetime | 2020-06-16 |


  Scenario: 'contains' matches strings that contain the specified substring
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $x "Seven Databases in Seven Weeks" isa name;
      $y "Four Weddings and a Funeral" isa name;
      $z "Fun Facts about Space" isa name;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match $x contains "Fun"; get;
      """
    Then uniquely identify answer concepts
      | x                                     |
      | attr:name:Four Weddings and a Funeral |
      | attr:name:Fun Facts about Space       |


  Scenario: 'contains' performs a case-insensitive match
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $x "The Phantom of the Opera" isa name;
      $y "Pirates of the Caribbean" isa name;
      $z "Mr. Bean" isa name;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match $x contains "Bean"; get;
      """
    Then uniquely identify answer concepts
      | x                                  |
      | attr:name:Pirates of the Caribbean |
      | attr:name:Mr. Bean                 |


  Scenario: 'like' matches strings that match the specified regex
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $x "ABC123" isa name;
      $y "123456" isa name;
      $z "9" isa name;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match $x like "^[0-9]+$"; get;
      """
    Then uniquely identify answer concepts
      | x                |
      | attr:name:123456 |
      | attr:name:9      |


  # TODO we can't test like this because the IID is not a valid encoded IID -- need to rethink this test
  @ignore
  Scenario: when querying for a non-existent attribute type iid, an empty result is returned
    When get answers of typeql get
      """
      match $x has name $y; $x iid 0x83cb2; get;
      """
    Then answer size is: 0
    When get answers of typeql get
      """
      match $x has name $y; $y iid 0x83cb2; get;
      """
    Then answer size is: 0

  # TODO: this test uses attributes, but is ultimately testing the traversal structure,
  #       such that match query does not throw. Perhaps we should introduce a new feature file
  #       containing a new set of scenarios that test: traversal structure, plan and procedure
  Scenario: Traversal planner can handle "loops" in the traversal structure
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $x isa person, has name 'alice', has ref 0;
      $y isa person, has name 'alice', has ref 1;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match
      $x isa person, has $n;
      $y isa person, has $n;
      get;
      """

  #######################
  # ATTRIBUTE OWNERSHIP #
  #######################

  Scenario: 'has' can be used to match things that own any instance of the specified attribute
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $x isa person, has name "Leila", has ref 0;
      $y isa person, has ref 1;
      $c isa company, has name "TypeDB", has ref 2;
      $d isa company, has ref 3;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match $x has name $y; get $x;
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:0 |
      | key:ref:2 |


  Scenario: using the 'attribute' meta label, 'has' can match things that own any attribute with a specified value
    Given typeql define
      """
      define
      shoe-size sub attribute, value long;
      person owns shoe-size;
      """
    Given transaction commits

    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $x isa person, has age 9, has ref 0;
      $y isa person, has shoe-size 9, has ref 1;
      $z isa person, has age 12, has shoe-size 12, has ref 2;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match $x has attribute 9; get;
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:0 |
      | key:ref:1 |


  Scenario: when an attribute instance is fully specified, 'has' matches its owners
    Given typeql define
      """
      define
      friendship owns age;
      graduation-date sub attribute, value datetime, owns age, owns ref @key;
      person owns graduation-date;
      """
    Given transaction commits

    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $x isa person, has name "Zoe", has age 21, has graduation-date 2020-06-01, has ref 0;
      $y (friend: $x) isa friendship, has age 21, has ref 1;
      $z 2020-06-01 isa graduation-date, has age 21, has ref 2;
      $w isa person, has ref 3;
      $v (friend: $x, friend: $w) isa friendship, has age 7, has ref 4;
      $u 2019-06-03 isa graduation-date, has age 22, has ref 5;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match $x has age 21; get;
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:0 |
      | key:ref:1 |
      | key:ref:2 |


  Scenario: 'has' matches an attribute's owner even if it owns more attributes of the same type
    Given typeql define
      """
      define
      lucky-number sub attribute, value long;
      person owns lucky-number;
      """
    Given transaction commits

    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $x isa person, has lucky-number 10, has lucky-number 20, has lucky-number 30, has ref 0;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match $x has lucky-number 20; get;
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:0 |


  Scenario: 'has' can match instances that have themselves
    Given typeql define
      """
      define
      unit sub attribute, value string, owns unit, owns ref @key;
      """
    Given transaction commits

    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $x "meter" isa unit, has $x, has ref 0;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match $x has $x; get;
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:0 |


  Scenario: an error is thrown when matching by attribute ownership, when the owned thing is actually an entity
    Then typeql get; throws exception
      """
      match $x has person "Luke"; get;
      """
    Then session transaction is open: false


  Scenario: exception is thrown when matching by an attribute ownership, if the owner can't actually own it
    Then typeql get; throws exception
      """
      match $x isa company, has age $n; get;
      """
    Then session transaction is open: false


  Scenario: an error is thrown when matching by attribute ownership, when the owned type label doesn't exist
    Then typeql get; throws exception
      """
      match $x has bananananananana "rama"; get;
      """
    Then session transaction is open: false



  ##############################
  # ATTRIBUTE VALUE COMPARISON #
  ##############################

  Scenario: when things own attributes of different types but the same value, they match by equality
    Given typeql define
      """
      define
      start-date sub attribute, value datetime;
      graduation-date sub attribute, value datetime;
      person owns graduation-date;
      employment owns start-date;
      """
    Given transaction commits

    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $x isa person, has name "James", has ref 0, has graduation-date 2009-07-16;
      $r (employee: $x) isa employment, has start-date 2009-07-16, has ref 1;
      """
    Given transaction commits

    Given session opens transaction of type: read
    Then get answers of typeql get
      """
      match
        $x isa person, has graduation-date $date;
        $r (employee: $x) isa employment, has start-date == $date;
      get;
      """
    Then answer size is: 1
    Then uniquely identify answer concepts
      | x         | r         | date                            |
      | key:ref:0 | key:ref:1 | attr:graduation-date:2009-07-16 |


  Scenario: 'has $attr == $x' matches owners of any instance '$y' of '$attr' where '$y' and '$x' are equal by value
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $x isa person, has name "Susie", has age 16, has ref 0;
      $y isa person, has name "Donald", has age 25, has ref 1;
      $z isa person, has name "Ralph", has age 18, has ref 2;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match $x has age == 16; get;
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:0 |


  Scenario: 'has $attr > $x' matches owners of any instance '$y' of '$attr' where '$y > $x'
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $x isa person, has name "Susie", has age 16, has ref 0;
      $y isa person, has name "Donald", has age 25, has ref 1;
      $z isa person, has name "Ralph", has age 18, has ref 2;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match $x has age > 18; get;
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:1 |


  Scenario: 'has $attr < $x' matches owners of any instance '$y' of '$attr' where '$y < $x'
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $x isa person, has name "Susie", has age 16, has ref 0;
      $y isa person, has name "Donald", has age 25, has ref 1;
      $z isa person, has name "Ralph", has age 18, has ref 2;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match $x has age < 18; get;
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:0 |


  Scenario: 'has $attr != $x' matches owners of any instance '$y' of '$attr' where '$y != $x'
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $x isa person, has name "Susie", has age 16, has ref 0;
      $y isa person, has name "Donald", has age 25, has ref 1;
      $z isa person, has name "Ralph", has age 18, has ref 2;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match $x has age != 18; get;
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:0 |
      | key:ref:1 |


  Scenario: value comparisons can be performed between a 'double' and a 'long'
    Given typeql define
      """
      define
      house-number sub attribute, value long;
      length sub attribute, value double;
      """
    Given transaction commits

    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $x 1 isa house-number;
      $y 2.0 isa length;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match
        $x isa house-number;
        $x == 1.0;
      get;
      """
    Then answer size is: 1
    When get answers of typeql get
      """
      match
        $x isa length;
        $x == 2;
      get;
      """
    Then answer size is: 1
    When get answers of typeql get
      """
      match
        $x isa house-number;
        $x 1.0;
      get;
      """
    Then answer size is: 1
    When get answers of typeql get
      """
      match
        $x isa length;
        $x 2;
      get;
      """
    Then answer size is: 1
    When get answers of typeql get
      """
      match
        $x isa attribute;
        $x >= 1;
      get;
      """
    Then answer size is: 2
    When get answers of typeql get
      """
      match
        $x isa attribute;
        $x < 2.0;
      get;
      """
    Then answer size is: 1

    When get answers of typeql get
      """
      match
        $x isa house-number;
        $y isa length;
        $x < $y;
      get;
      """
    Then answer size is: 1


  Scenario: when a thing owns multiple attributes of the same type, a value comparison matches if any value matches
    Given typeql define
      """
      define
      lucky-number sub attribute, value long;
      person owns lucky-number;
      """
    Given transaction commits

    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $x isa person, has lucky-number 10, has lucky-number 20, has lucky-number 30, has ref 0;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match $x has lucky-number > 25; get;
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:0 |


  Scenario: an attribute variable used in both '=' and '>=' predicates is correctly resolved
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $x isa person, has name "Susie", has age 16, has ref 0;
      $y isa person, has name "Donald", has age 25, has ref 1;
      $z isa person, has name "Ralph", has age 18, has ref 2;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match
        $x has age == $z;
        $z >= 17;
        $z isa age;
      get $x;
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:1 |
      | key:ref:2 |


  Scenario: when the answers of a value comparison include both a 'double' and a 'long', both answers are returned
    Given typeql define
      """
      define
      length sub attribute, value double;
      """
    Given transaction commits

    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $a 24 isa age;
      $b 19 isa age;
      $c 20.9 isa length;
      $d 19.9 isa length;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match
        $x isa attribute;
        $x > 20;
      get;
      """
    Then uniquely identify answer concepts
      | x                |
      | attr:age:24      |
      | attr:length:20.9 |


  Scenario: when one entity exists, and we match two variables with concept inequality, an empty answer is returned
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert $x isa person, has ref 0;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match
        $x isa person;
        $y isa person;
        not { $x is $y; };
      get;
      """
    Then answer size is: 0


  Scenario: concept comparison of unbound variables throws an error
    Then typeql get; throws exception
      """
      match not { $x is $y; }; get;
      """
    Then session transaction is open: false

  ############
  # PATTERNS #
  ############

  Scenario: disjunctions return the union of composing query statements
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $x isa person, has name "Jeff", has ref 0;
      $y isa company, has name "Amazon", has ref 1;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match $x isa $t; { $t type person; } or {$t type company;}; get $x;
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:0 |
      | key:ref:1 |
    When get answers of typeql get
      """
      match $x isa entity; {$x has name "Jeff";} or {$x has name "Amazon";}; get;
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:0 |
      | key:ref:1 |


  Scenario: disjunctions with no answers can be limited
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match $x isa $t; { $t type person; } or {$t type company;}; get;
      """
    Then answer size is: 0
    When get answers of typeql get
      """
      match $x isa $t; { $t type person; } or {$t type company;}; get; limit 1;
      """
    Then answer size is: 0


  Scenario: negations can be applied to filtered variables
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $x isa person, has name "Jeff", has ref 0;
      $y isa person, has name "Jenny", has ref 1;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match $x isa person, has name $a; not { $a == "Jeff"; }; get $x;
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:1 |


  Scenario: multiple negations can be applied
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match $x sub! thing; not { $x type thing; }; not { $x type entity; }; not { $x type relation; }; get;
      """
    Then uniquely identify answer concepts
      | x               |
      | label:attribute |

  Scenario: pattern variable without named variable is invalid
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: read
    Then typeql get; throws exception
      """
      match $x isa person, has name $a; "bob" isa name; get;
      """


  ##################
  # VARIABLE TYPES #
  ##################

  Scenario: all instances and their types can be retrieved
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $x isa person, has name "Bertie", has ref 0;
      $y isa person, has name "Angelina", has ref 1;
      $r (friend: $x, friend: $y) isa friendship, has ref 2;
      """
    Given transaction commits

    Given session opens transaction of type: read
    Given get answers of typeql get
      """
      match $x isa entity; get;
      """
    Given answer size is: 2
    Given get answers of typeql get
      """
      match $r isa relation; get;
      """
    Given answer size is: 1
    Given get answers of typeql get
      """
      match $x isa attribute; get;
      """
    Given answer size is: 5
    When get answers of typeql get
      """
      match $x isa $type; get;
      """
    # 2 entities x 3 types {person,entity,thing}
    # 1 relation x 3 types {friendship,relation,thing}
    # 5 attributes x 3 types {ref/name,attribute,thing}
    Then answer size is: 24


  Scenario: all relations and their types can be retrieved
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $x isa person, has name "Bertie", has ref 0;
      $y isa person, has name "Angelina", has ref 1;
      $r (friend: $x, friend: $y) isa friendship, has ref 2;
      """
    Given transaction commits

    Given session opens transaction of type: read
    Given get answers of typeql get
      """
      match $r isa relation; get;
      """
    Given answer size is: 1
    Given get answers of typeql get
      """
      match ($x, $y) isa relation; get;
      """
    # 2 permutations of the roleplayers
    Given answer size is: 2
    When get answers of typeql get
      """
      match ($x, $y) isa $type; get;
      """
    # 2 permutations x 3 types {friendship,relation,thing}
    Then answer size is: 6


  Scenario: variable role types with relations playing roles
    Given connection close all sessions
    Given connection open schema session for database: typedb
    Given session opens transaction of type: write
    Given typeql define
      """
      define
        parent sub relation, relates nested, owns id;
        nested sub relation, relates id, plays parent:nested;
        id sub attribute, value string, plays nested:id;
      """
    Given transaction commits
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
        $i1 "i1" isa id;
        $i2 "i2" isa id;
        $n1 (id: $i1) isa nested;
        $n2 (id: $i2) isa nested;
        $p1 (nested: $n1) isa parent, has id $i1;
        $p2 (nested: $n2) isa parent, has id $i2;
      """
    Given transaction commits
    Given session opens transaction of type: read

    # Force traversal of role edges in each direction: See vaticle/typedb#6925
    When get answers of typeql get
      """
      match
        $role-nested sub! relation:role;
        $role-id sub! relation:role;
        $boundId1 = "i1";

        $p ($role-nested: $n) isa parent, has id $boundId1;
        $n ($role-id: $i) isa nested;
      get $p, $n, $i;
      """
    Then answer size is: 1

    When get answers of typeql get
      """
      match
        $role-nested sub! relation:role;
        $role-id sub! relation:role;
        $boundId1 = "i1";

        $p ($role-nested: $n) isa parent, has id $i;
        $n ($role-id: $boundId1) isa nested;
      get $p, $n, $i;
      """
    Then answer size is: 1


  #######################
  # NEGATION VALIDATION #
  #######################

  # Negation resolution is handled by Reasoner, but query validation is handled by the language.
  Scenario: when the entire match clause is a negation, an error is thrown
  At least one negated pattern variable must be bound outside the negation block, so this query is invalid.
    Then typeql get; throws exception
      """
      match not { $x has attribute "value"; }; get;
      """
    Then session transaction is open: false

  Scenario: when matching a negation whose pattern variables are all unbound outside it, an error is thrown
    Then typeql get; throws exception
      """
      match
        $r isa entity;
        not {
          ($r2, $i);
          $i isa entity;
        };
      get;
      """
    Then session transaction is open: false

  Scenario: the first variable in a negation can be unbound, as long as it is connected to a bound variable
    Then get answers of typeql get
      """
      match
        $r isa attribute;
        not {
          $x isa entity, has attribute $r;
        };
      get;
      """

  # TODO: We should verify the answers
  Scenario: negations can contain disjunctions
    Then get answers of typeql get
      """
      match
        $x isa entity;
        not {
          { $x has attribute 1; } or { $x has attribute 2; };
        };
      get;
      """

  Scenario: when negating a negation redundantly, an error is thrown
    Then typeql get; throws exception
      """
      match
        $x isa person, has name "Tim";
        not {
          not {
            $x has age 55;
          };
        };
      get;
      """


  #######################
  #   Unicode Support   #
  #######################

  Scenario: string attribute values can be non-ascii
    Given typeql define
      """
      define
      person owns favorite-phrase;
      favorite-phrase sub attribute, value string;
      """
    Given transaction commits
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $x isa person, has favorite-phrase "你明白了吗", has ref 0;
      $y isa person, has favorite-phrase "בוקר טוב", has ref 1;
      $r (friend: $x, friend: $y) isa friendship, has ref 2;
      """
    Given transaction commits

    Given session opens transaction of type: read
    Given get answers of typeql get
      """
      match $phrase isa favorite-phrase; get;
      """
    Then uniquely identify answer concepts
      | phrase                        |
      | attr:favorite-phrase:你明白了吗    |
      | attr:favorite-phrase:בוקר טוב |

    Given get answers of typeql get
      """
      match $x isa person, has favorite-phrase "你明白了吗"; get;
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:0 |

    Given get answers of typeql get
      """
      match $x isa person, has favorite-phrase "בוקר טוב"; get;
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:1 |

    Given get answers of typeql get
      """
      match $x isa person, has favorite-phrase "请给我一"; get;
      """
    Then answer size is: 0


  Scenario: type labels can be non-ascii
    Given typeql define
      """
      define
      人 sub entity, owns name, owns ref @key; אדם sub entity, owns name, owns ref @key;
      """
    Given transaction commits
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $x isa 人, has name "Liu", has ref 0;
      $y isa אדם, has name "Solomon", has ref 1;
      """
    Given transaction commits

    Given session opens transaction of type: read
    Given get answers of typeql get
      """
      match $x isa! $t; $x has name $_; get $t;
      """
    Then uniquely identify answer concepts
      | t         |
      | label:人   |
      | label:אדם |

    Given get answers of typeql get
      """
      match $x isa 人; get;
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:0 |

    Given get answers of typeql get
      """
      match $x isa אדם; get;
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:1 |


  Scenario: variables can be non-ascii
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $人 isa person, has name "Liu", has ref 0;
      $אדם isa person, has name "Solomon", has ref 1;
      """
    Given transaction commits

    Given session opens transaction of type: read
    Given get answers of typeql get
      """
      match $人 isa person; $人 has name "Liu"; get $人;
      """
    Then uniquely identify answer concepts
      | 人         |
      | key:ref:0 |

    Given get answers of typeql get
      """
      match $אדם isa person; $אדם has name "Liu"; get $אדם;
      """
    Then uniquely identify answer concepts
      | אדם       |
      | key:ref:1 |


