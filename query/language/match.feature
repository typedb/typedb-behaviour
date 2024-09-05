# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: TypeQL Match Clause

  Background: Open connection and create a simple extensible schema
    Given typedb starts
    Given connection opens with default authentication
    Given connection has been opened
    Given connection does not have any database
    Given connection create database: typedb
    Given connection open schema transaction for database: typedb

    Given typeql define
      """
      define
      entity person
        plays friendship:friend,
        plays employment:employee,
        owns name,
        owns age,
        owns ref @key,
        owns email @unique;
      entity company
        plays employment:employer,
        owns name,
        owns ref @key;
      relation friendship
        relates friend @card(0..),
        owns ref @key;
      relation employment
        relates employee @card(0..),
        relates employer @card(0..),
        owns ref @key;
      attribute name value string;
      attribute age value long;
      attribute ref value long;
      attribute email value string;
      """
    Given transaction commits

    Given connection open schema transaction for database: typedb


  ##################
  # SCHEMA QUERIES #
  ##################

  Scenario: 'label' matches only the specified type, and does not match subtypes
    Given typeql define
      """
      define
      entity writer sub person;
      entity scifi-writer sub writer;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x label person;
      """
    Then uniquely identify answer concepts
      | x            |
      | label:person |


  Scenario: 'sub' can be used to match the specified type and all its subtypes, including indirect subtypes
    Given typeql define
      """
      define
      entity writer sub person;
      entity scifi-writer sub writer;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x sub person;
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
      entity writer sub person;
      entity scifi-writer sub writer;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match writer sub $x;
      """
    Then uniquely identify answer concepts
      | x            |
      | label:writer |
      | label:person |


  Scenario: 'sub' can be used to retrieve all instances of types that are subtypes of a given type
    Given typeql define
      """
      define

      entity child sub person;
      entity worker sub person;
      entity retired-person sub person;
      entity construction-worker sub worker;
      entity bricklayer sub construction-worker;
      entity crane-driver sub construction-worker;
      entity telecoms-worker sub worker;
      entity mobile-network-researcher sub telecoms-worker;
      entity smartphone-designer sub telecoms-worker;
      entity telecoms-business-strategist sub telecoms-worker;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
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

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
        $x isa $type;
        $type sub worker;
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
      entity writer sub person;
      entity scifi-writer sub writer;
      entity musician sub person;
      entity flutist sub musician;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x sub! person;
      """
    Then uniquely identify answer concepts
      | x              |
      | label:writer   |
      | label:musician |


  Scenario: 'sub!' can be used to match a type's direct supertype
    Given typeql define
      """
      define
      entity writer sub person;
      entity scifi-writer sub writer;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match writer sub! $x;
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
      entity sub1;
      entity sub2 sub sub1;
      entity sub3 sub sub1;
      entity sub4 sub sub2;
      entity sub5 sub sub4;
      entity sub6 sub sub5;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
        $x sub $y;
        $y sub $z;
        $z sub sub1;
      """
    Then each answer satisfies
      """
      match $x sub $z; $x iid <answer.x.iid>; $z iid <answer.z.iid>;
      """


  Scenario: 'owns' matches types that own the specified attribute type
    When get answers of typeql read query
      """
      match $x owns age;
      """
    Then uniquely identify answer concepts
      | x            |
      | label:person |


  Scenario: 'owns' does not match types that own only a subtype of the specified attribute type
    Given typeql define
      """
      define
      attribute general-name @abstract, value string;
      entity institution @abstract, owns general-name;
      attribute club-name sub general-name;
      entity club owns club-name;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x owns general-name;
      """
    Then uniquely identify answer concepts
      | x                 |
      | label:institution |


  Scenario: 'owns' does not match types that own only a supertype of the specified attribute type
    Given typeql define
      """
      define
      attribute general-name @abstract, value string;
      entity institution @abstract, owns general-name;
      attribute club-name sub general-name;
      entity club owns club-name;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x owns club-name;
      """
    Then uniquely identify answer concepts
      | x          |
      | label:club |


  Scenario: 'owns' can be used to match attribute types that a given type owns
    When get answers of typeql read query
      """
      match person owns $x;
      """
    Then uniquely identify answer concepts
      | x           |
      | label:name  |
      | label:email |
      | label:age   |
      | label:ref   |


  Scenario: directly declared 'owns' annotations are queryable
    When get answers of typeql read query
      """
      match $x owns ref @key;
      """
    Then uniquely identify answer concepts
      | x                |
      | label:person     |
      | label:company    |
      | label:friendship |
      | label:employment |
    When get answers of typeql read query
      """
      match $x owns $a @key;
      """
    Then uniquely identify answer concepts
      | x                | a         |
      | label:person     | label:ref |
      | label:company    | label:ref |
      | label:friendship | label:ref |
      | label:employment | label:ref |
    When get answers of typeql read query
      """
      match $x owns email @unique;
      """
    Then uniquely identify answer concepts
      | x            |
      | label:person |
    When get answers of typeql read query
      """
      match $x owns $a @unique;
      """
    Then uniquely identify answer concepts
      | x            | a           |
      | label:person | label:email |


  Scenario: inherited 'owns' annotations are queryable
    Given typeql define
      """
      define entity child sub person;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x owns ref @key;
      """
    Then uniquely identify answer concepts
      | x                |
      | label:person     |
      | label:child      |
      | label:company    |
      | label:friendship |
      | label:employment |
    When get answers of typeql read query
      """
      match $x owns $a @key;
      """
    Then uniquely identify answer concepts
      | x                | a         |
      | label:person     | label:ref |
      | label:child      | label:ref |
      | label:company    | label:ref |
      | label:friendship | label:ref |
      | label:employment | label:ref |
    When get answers of typeql read query
      """
      match $x owns email @unique;
      """
    Then uniquely identify answer concepts
      | x            |
      | label:person |
      | label:child  |
    When get answers of typeql read query
      """
      match $x owns $a @unique;
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

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x isa person, has ref 0;
      $y isa company, has ref 1;
      $z links (friend: $x), isa friendship, has ref 2;
      $w links (employee: $x, employer: $y), isa employment, has ref 3;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
        $x isa $type;
        $type owns name;
      """
    # friendship and ref should not be retrieved, as they can't have a name
    Then uniquely identify answer concepts
      | x         | type             |
      | key:ref:0 | label:person     |
      | key:ref:1 | label:company    |
      | key:ref:3 | label:employment |


  Scenario: 'plays' matches types that can play the specified role
    When get answers of typeql read query
      """
      match $x plays friendship:friend;
      """
    Then uniquely identify answer concepts
      | x            |
      | label:person |


  Scenario: 'plays' does not match types that only play a subrole of the specified role
    Given typeql define
      """
      define
      relation close-friendship sub friendship, relates close-friend as friend;
      entity friendly-person plays close-friendship:close-friend;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x plays friendship:friend;
      """
    Then uniquely identify answer concepts
      | x            |
      | label:person |


  Scenario: inherited role types cannot be be matched via role type alias
    Given typeql define
      """
      define
      relation close-friendship sub friendship;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When typeql read query; fails
      """
      match $x plays close-friendship:friend;
      """


  Scenario: 'plays' does not match types that only play a super-role of the specified role
    Given typeql define
      """
      define
      relation close-friendship sub friendship, relates close-friend as friend;
      entity friendly-person plays close-friendship:close-friend;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x plays close-friendship:close-friend;
      """
    Then uniquely identify answer concepts
      | x                     |
      | label:friendly-person |


  Scenario: 'plays' can be used to match roles that a particular type can play
    When get answers of typeql read query
      """
      match person plays $x;
      """
    Then uniquely identify answer concepts
      | x                         |
      | label:friendship:friend   |
      | label:employment:employee |


  Scenario: 'plays' can be used to retrieve all instances of types that can play a specific role
    Given typeql define
      """
      define
      entity dog
        plays friendship:friend,
        owns ref @key;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x isa person, has ref 0;
      $y isa company, has ref 1;
      $z isa dog, has ref 2;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
        $x isa $type;
        $type plays friendship:friend;
      """
    Then uniquely identify answer concepts
      | x         | type         |
      | key:ref:0 | label:person |
      | key:ref:2 | label:dog    |


  Scenario: 'owns @key' matches types that own the specified attribute type as a key
    Given typeql define
      """
      define
      attribute breed value string;
      entity dog owns breed @key;
      entity kennel owns breed;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x owns breed @key;
      """
    Then uniquely identify answer concepts
      | x         |
      | label:dog |


  Scenario: 'key' can be used to find all attribute types that a given type owns as a key
    When get answers of typeql read query
      """
      match person owns $x @key;
      """
    Then uniquely identify answer concepts
      | x         |
      | label:ref |


  Scenario: 'owns' without '@key' matches all types that own the specified attribute type, even if they use it as a key
    Given typeql define
      """
      define
      attribute breed value string;
      entity dog owns breed @key;
      entity cat owns breed;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x owns breed;
      """
    Then uniquely identify answer concepts
      | x         |
      | label:dog |
      | label:cat |


  Scenario: 'relates' matches relation types where the specified role can be played
    When get answers of typeql read query
      """
      match $x relates employee;
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
      relation close-friendship sub friendship, relates close-friend as friend;
      entity friendly-person plays close-friendship:close-friend;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x relates close-friend as friend;
      """
    Then uniquely identify answer concepts
      | x                      |
      | label:close-friendship |


  Scenario: 'relates' without 'as' does not match relation types that override the specified roleplayer
    Given typeql define
      """
      define
      relation close-friendship sub friendship, relates close-friend as friend;
      entity friendly-person plays close-friendship:close-friend;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x relates friend;
      """
    Then uniquely identify answer concepts
      | x                |
      | label:friendship |


  Scenario: 'relates' can be used to retrieve all the roles of a relation type
    When get answers of typeql read query
      """
      match employment relates $x;
      """
    Then uniquely identify answer concepts
      | x                         |
      | label:employment:employee |
      | label:employment:employer |


  # TODO we can't test like this because the IID is not a valid encoded IID -- need to rethink this test
  @ignore
  Scenario: when matching by a concept iid that doesn't exist, an empty result is returned
    When get answers of typeql read query
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
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $_ isa person, has ref 0;
      $_ isa person, has ref 1;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa $y;
      """
    Then uniquely identify answer concepts
      | x          | y               |
      | key:ref:0  | label:person    |
      | key:ref:1  | label:person    |
      | attr:ref:0 | label:ref       |
      | attr:ref:1 | label:ref       |

  Scenario: 'isa' matches things of the specified type and all its subtypes
    Given typeql define
      """
      define
      entity writer sub person;
      entity scifi-writer sub writer;
      entity good-scifi-writer sub scifi-writer;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x isa person, has ref 0;
      $y isa writer, has ref 1;
      $z isa scifi-writer, has ref 2;
      $w isa good-scifi-writer, has ref 3;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa writer;
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
      entity writer sub person;
      entity scifi-writer sub writer;
      entity good-scifi-writer sub scifi-writer;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x isa person, has ref 0;
      $y isa writer, has ref 1;
      $z isa scifi-writer, has ref 2;
      $w isa good-scifi-writer, has ref 3;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa! writer;
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:1 |


  Scenario: 'isa' matches no answers if the type tree is fully abstract
    Given typeql define
      """
      define
      entity person @abstract;
      entity writer @abstract, sub person;
      entity scifi-writer @abstract, sub writer;
      entity good-scifi-writer @abstract, sub scifi-writer;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa person;
      """
    Then answer size is: 0


  Scenario: 'iid' matches the instance with the specified internal iid
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x isa person, has ref 0;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa person;
      """
    Then each answer satisfies
      """
      match $x iid <answer.x.iid>;
      """


  Scenario: 'iid' for a variable of a different type finds no answers
    Given typeql define
      """
      define
      entity shop owns address;
      entity grocery sub shop;
      attribute address value string;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x isa shop, has address "123 street";
      $y isa grocery, has address "123 street";
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa! shop;
      """
    Then get answers of templated typeql read query
      """
      match $x iid <answer.x.iid>; $x isa grocery, has address "123 street";
      """
    Then answer size is: 0


  Scenario: match returns an empty answer if there are no matches
    When get answers of typeql read query
      """
      match $x isa person, has name "Anonymous Coward";
      """
    Then answer size is: 0


  Scenario: when matching by a type whose label doesn't exist, an error is thrown
    Then typeql read query; fails
      """
      match $x isa ganesh;
      """
    Then transaction is open: false


  Scenario: when matching by a relation type whose label doesn't exist, an error is thrown
    Then typeql read query; fails
      """
      match ($x, $y) isa $type; $type type jakas-relacja;
      """
    Then transaction is open: false


  Scenario: when matching a non-existent type label to a variable from a generic 'isa' query, an error is thrown
    Then typeql read query; fails
      """
      match $x isa $type; $type type polok;
      """
    Then transaction is open: false


  Scenario: when one entity exists, and we match two variables both of that entity type, the entity is returned
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert $x isa person, has ref 0;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
        $x isa person;
        $y isa person;
      """
    Then uniquely identify answer concepts
      | x         | y         |
      | key:ref:0 | key:ref:0 |


  Scenario: an error is thrown when matching that a variable has a specific type, when that type is in fact a role type
    Then typeql read query; fails
      """
      match $x isa friendship:friend;
      """


  #############
  # RELATIONS #
  #############

  Scenario: a relation is matchable from role players without specifying relation type
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x isa person, has ref 0;
      $y isa company, has ref 1;
      $r isa employment,
        links (employee: $x, employer: $y),
        has ref 2;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    Then get answers of typeql read query
      """
      match $x isa person; $r links (employee: $x);
      """
    Then uniquely identify answer concepts
      | x         | r         |
      | key:ref:0 | key:ref:2 |
    When get answers of typeql read query
      """
      match $y isa company; $r links (employer: $y);
      """
    Then uniquely identify answer concepts
      | y         | r         |
      | key:ref:1 | key:ref:2 |


  Scenario: relations are matchable from roleplayers without specifying any roles
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x isa person, has ref 0;
      $y isa company, has ref 1;
      $r links (employee: $x, employer: $y), isa employment,
         has ref 2;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa person; $r links ($x);
      """
    Then uniquely identify answer concepts
      | x         | r         |
      | key:ref:0 | key:ref:2 |


  Scenario: all combinations of players in a relation can be retrieved
    Given transaction commits

    Given connection open write transaction for database: typedb
    When typeql write query
      """
      insert $p isa person, has ref 0;
      $c isa company, has ref 1;
      $c2 isa company, has ref 2;
      $r links (employee: $p, employer: $c, employer: $c2), isa employment, has ref 3;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    Then get answers of typeql read query
      """
      match $r links ($x, $y), isa employment;
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
      entity some-entity plays symmetric:player, owns ref @key;
      relation symmetric relates player, owns ref @key;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert $x isa some-entity, has ref 0; (player: $x, player: $x) isa symmetric, has ref 1;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $r links (player: $x, player: $x);
      """
    Then uniquely identify answer concepts
      | x         | r         |
      | key:ref:0 | key:ref:1 |


  Scenario: repeated role players are retrieved singly when queried singly
    Given typeql define
      """
      define
      entity some-entity plays symmetric:player, owns ref @key;
      relation symmetric relates player, owns ref @key;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert $x isa some-entity, has ref 0; (player: $x, player: $x) isa symmetric, has ref 1;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $r links (player: $x);
      """
    Then uniquely identify answer concepts
      | x         | r         |
      | key:ref:0 | key:ref:1 |


  Scenario: a mixture of variable and explicit roles can retrieve relations
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x isa company, has ref 0;
      $y isa person, has ref 1;
      (employer: $x, employee: $y) isa employment, has ref 2;
      """
    Given transaction commits
    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match (employer: $e, $role: $x) isa employment;
      """
    Then uniquely identify answer concepts
      | e         | x         | role                      |
      | key:ref:0 | key:ref:1 | label:employment:employee |

  @ignore
  Scenario: A relation can play a role in itself
    Given typeql define
      """
      define
      relation comparator
        relates compared,
        plays comparator:compared;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $rlinks (compared:$r), isa comparator;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $rlinks (compared:$r), isa comparator;
      """
    Then answer size is: 1

  @ignore
  Scenario: A relation can play a role in itself and have additional roleplayers
    Given typeql define
      """
      define
      relation comparator
        relates compared,
        plays comparator:compared;
      entity variable
        plays comparator:compared;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $rlinks (compared: $v, compared:$r), isa comparator;
      $v isa variable;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $rlinks (compared: $v, compared:$r), isa comparator;
      """
    Then answer size is: 1


  Scenario: relations between distinct concepts are not retrieved when matching concepts that relate to themselves
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x isa person, has ref 1;
      $y isa person, has ref 2;
      (friend: $x, friend: $y) isa friendship, has ref 0;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match (friend: $x, friend: $x) isa friendship;
      """
    Then answer size is: 0


  Scenario: matching a chain of relations only returns answers if there is a chain of the required length
    Given typeql define
      """
      define

      relation gift-delivery
        relates sender,
        relates recipient;

      person plays gift-delivery:sender,
        plays gift-delivery:recipient;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
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

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
        (sender: $a, recipient: $b) isa gift-delivery;
        (sender: $b, recipient: $c) isa gift-delivery;
      """
    Then uniquely identify answer concepts
      | a         | b         | c         |
      | key:ref:0 | key:ref:1 | key:ref:2 |
    When get answers of typeql read query
      """
      match
        (sender: $a, recipient: $b) isa gift-delivery;
        (sender: $b, recipient: $c) isa gift-delivery;
        (sender: $c, recipient: $d) isa gift-delivery;
      """
    Then answer size is: 0


  Scenario: when multiple relation instances exist with the same roleplayer, matching that player returns just 1 answer
    Given typeql define
      """
      define
      relation residency
        relates resident,
        owns ref @key;
      person plays residency:resident;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x isa person, has ref 0;
      $e links (employee: $x), isa employment, has ref 1;
      $f links (friend: $x), isa friendship, has ref 2;
      $r links (resident: $x), isa residency, has ref 3;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    Given get answers of typeql read query
      """
      match relation $t; $r isa $t;
      """
    Given uniquely identify answer concepts
      | r         |
      | key:ref:1 |
      | key:ref:2 |
      | key:ref:3 |
    When get answers of typeql read query
      """
      match ($x) isa $_;
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:0 |
    When get answers of typeql read query
      """
      match ($x);
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:0 |


  Scenario: an error is thrown when matching an entity type as if it were a role type
    Then typeql read query; fails
      """
      match (person: $x);
      """
    Then transaction is open: false


  Scenario: an error is thrown when matching an entity type as if it were a relation type
    Then typeql read query; fails
      """
      match ($x) isa person;
      """
    Then transaction is open: false


  Scenario: an error is thrown when matching a non-existent type label as if it were a relation type
    Then typeql read query; fails
      """
      match ($x) isa bottle-of-rum;
      """
    Then transaction is open: false


  Scenario: when matching a role type that doesn't exist, an error is thrown
    Then typeql read query; fails
      """
      match (rolein-rolein-rolein: $rolein);
      """
    Then transaction is open: false


  Scenario: when matching a role in a relation type that doesn't have that role, an error is thrown
    Then typeql read query; fails
      """
      match (friend: $x) isa employment;
      """
    Then transaction is open: false


  Scenario: when matching a roleplayer in a relation that can't actually play that role, an error is thrown
    When typeql read query; fails
      """
      match
      $x isa company;
      ($x) isa friendship;
      """
    Then transaction is open: false


  Scenario: Relations can be queried with pairings of relation and role types that are not directly related to each other
    Given typeql define
      """
      define
      person plays marriage:spouse, plays hetero-marriage:husband, plays hetero-marriage:wife;
      relation marriage relates spouse;
      relation hetero-marriage sub marriage, relates husband as spouse, relates wife as spouse;
      relation civil-marriage sub marriage;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $a isa person, has ref 1;
      $b isa person, has ref 2;
      (wife: $a, husband: $b) isa hetero-marriage;
      (spouse: $a, spouse: $b) isa civil-marriage;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $m links (wife: $x, husband: $y), isa hetero-marriage;
      """
    Then answer size is: 1
    Then typeql read query; fails
      """
      match $m links (wife: $x, husband: $y), isa civil-marriage;
      """
    Then transaction is open: false
    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $m links (wife: $x, husband: $y), isa marriage;
      """
    Then answer size is: 1
    When get answers of typeql read query
      """
      match $m links (wife: $x, husband: $y);
      """
    Then answer size is: 1
    When get answers of typeql read query
      """
      match $m links (spouse: $x, spouse: $y), isa hetero-marriage;
      """
    Then answer size is: 2
    When get answers of typeql read query
      """
      match $m links (spouse: $x, spouse: $y), isa civil-marriage;
      """
    Then answer size is: 2
    When get answers of typeql read query
      """
      match $m links (spouse: $x, spouse: $y), isa marriage;
      """
    Then answer size is: 4
    When get answers of typeql read query
      """
      match $m links (spouse: $x, spouse: $y);
      """
    Then answer size is: 4
    When get answers of typeql read query
      """
      match $m links (role: $x, role: $y), isa hetero-marriage;
      """
    Then answer size is: 2
    When get answers of typeql read query
      """
      match $m links (role: $x, role: $y), isa civil-marriage;
      """
    Then answer size is: 2
    When get answers of typeql read query
      """
      match $m links (role: $x, role: $y), isa marriage;
      """
    Then answer size is: 4
    When get answers of typeql read query
      """
      match $m links (role: $x, role: $y);
      """
    Then answer size is: 4


  Scenario: When some relations do not satisfy the query, the correct ones are still found
    Given typeql define
      """
      define
      entity car plays ownership:owned, owns ref @key;
      person plays ownership:owner;
      company plays ownership:owner;
      relation ownership relates owned, relates owner, owns is-insured;
      attribute is-insured value boolean;
      """
    Given transaction commits
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      (owned: $c1, owner: $company) isa ownership, has is-insured true;
      $c1 isa car, has ref 0; $company isa company, has ref 1;
      """
    Given transaction commits
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      (owned: $c2, owner: $person) isa ownership, has is-insured true;
      $c2 isa car, has ref 2; $person isa person, has ref 3;
      """
    Given transaction commits
    Given connection open read transaction for database: typedb
    When get answers of typeql read query
    """
    match $r links (owner: $x), isa ownership, has is-insured true; $x isa person;
    """
    Then answer size is: 1

  ##############
  # ATTRIBUTES #
  ##############

  Scenario Outline: '<type>' attributes can be matched by value
    Given typeql define
      """
      define attribute <attr> value <type>;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert $n <value> isa <attr>;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $a <value>;
      """
    Then uniquely identify answer concepts
      | a             |
      | attr:<attr>:0 |

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
      define attribute <attr> value <type>;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $a <value>;
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
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x "Seven Databases in Seven Weeks" isa name;
      $y "Four Weddings and a Funeral" isa name;
      $z "Fun Facts about Space" isa name;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x contains "Fun";
      """
    Then uniquely identify answer concepts
      | x                                     |
      | attr:name:Four Weddings and a Funeral |
      | attr:name:Fun Facts about Space       |


  Scenario: 'contains' performs a case-insensitive match
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x "The Phantom of the Opera" isa name;
      $y "Pirates of the Caribbean" isa name;
      $z "Mr. Bean" isa name;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x contains "Bean";
      """
    Then uniquely identify answer concepts
      | x                                  |
      | attr:name:Pirates of the Caribbean |
      | attr:name:Mr. Bean                 |


  Scenario: 'like' matches strings that match the specified regex
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x "ABC123" isa name;
      $y "123456" isa name;
      $z "9" isa name;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x like "^[0-9]+$";
      """
    Then uniquely identify answer concepts
      | x                |
      | attr:name:123456 |
      | attr:name:9      |


  # TODO we can't test like this because the IID is not a valid encoded IID -- need to rethink this test
  @ignore
  Scenario: when querying for a non-existent attribute type iid, an empty result is returned
    When get answers of typeql read query
      """
      match $x has name $y; $x iid 0x83cb2;
      """
    Then answer size is: 0
    When get answers of typeql read query
      """
      match $x has name $y; $y iid 0x83cb2;
      """
    Then answer size is: 0

  # TODO: this test uses attributes, but is ultimately testing the traversal structure,
  #       such that match query does not throw. Perhaps we should introduce a new feature file
  #       containing a new set of scenarios that test: traversal structure, plan and procedure
  Scenario: Traversal planner can handle "loops" in the traversal structure
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x isa person, has name 'alice', has ref 0;
      $y isa person, has name 'alice', has ref 1;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
      $x isa person, has $n;
      $y isa person, has $n;
      """

  #######################
  # ATTRIBUTE OWNERSHIP #
  #######################

  Scenario: 'has' can be used to match things that own any instance of the specified attribute
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x isa person, has name "Leila", has ref 0;
      $y isa person, has ref 1;
      $c isa company, has name "TypeDB", has ref 2;
      $d isa company, has ref 3;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x has name $y;
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:0 |
      | key:ref:2 |


  Scenario: using the 'attribute' meta label, 'has' can match things that own any attribute with a specified value
    Given typeql define
      """
      define
      attribute shoe-size value long;
      person owns shoe-size;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x isa person, has age 9, has ref 0;
      $y isa person, has shoe-size 9, has ref 1;
      $z isa person, has age 12, has shoe-size 12, has ref 2;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x has $_ 9;
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
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x isa person, has name "Zoe", has age 21, has ref 0;
      $y links (friend: $x), isa friendship, has age 21, has ref 1;
      $w isa person, has ref 2;
      $v links (friend: $x, friend: $w), isa friendship, has age 7, has ref 3;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x has age 21;
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:0 |
      | key:ref:1 |


  Scenario: 'has' matches an attribute's owner even if it owns more attributes of the same type
    Given typeql define
      """
      define
      attribute lucky-number value long;
      person owns lucky-number;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x isa person, has lucky-number 10, has lucky-number 20, has lucky-number 30, has ref 0;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x has lucky-number 20;
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:0 |


  Scenario: an error is thrown when matching by attribute ownership, when the owned thing is actually an entity
    Then typeql read query; fails
      """
      match $x has person "Luke";
      """
    Then transaction is open: false


  Scenario: exception is thrown when matching by an attribute ownership, if the owner can't actually own it
    Then typeql read query; fails
      """
      match $x isa company, has age $n;
      """
    Then transaction is open: false


  Scenario: an error is thrown when matching by attribute ownership, when the owned type label doesn't exist
    Then typeql read query; fails
      """
      match $x has bananananananana "rama";
      """
    Then transaction is open: false



  ##############################
  # ATTRIBUTE VALUE COMPARISON #
  ##############################

  Scenario: when things own attributes of different types but the same value, they match by equality
    Given typeql define
      """
      define
      attribute start-date value datetime;
      attribute graduation-date value datetime;
      person owns graduation-date;
      employment owns start-date;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x isa person, has name "James", has ref 0, has graduation-date 2009-07-16;
      $r links (employee: $x), isa employment, has start-date 2009-07-16, has ref 1;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    Then get answers of typeql read query
      """
      match
        $x isa person, has graduation-date $date;
        $r links (employee: $x), isa employment, has start-date == $date;
      """
    Then answer size is: 1
    Then uniquely identify answer concepts
      | x         | r         | date                            |
      | key:ref:0 | key:ref:1 | attr:graduation-date:2009-07-16 |


  Scenario: 'has $attr == $x' matches owners of any instance '$y' of '$attr' where '$y' and '$x' are equal by value
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x isa person, has name "Susie", has age 16, has ref 0;
      $y isa person, has name "Donald", has age 25, has ref 1;
      $z isa person, has name "Ralph", has age 18, has ref 2;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x has age == 16;
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:0 |


  Scenario: 'has $attr > $x' matches owners of any instance '$y' of '$attr' where '$y > $x'
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x isa person, has name "Susie", has age 16, has ref 0;
      $y isa person, has name "Donald", has age 25, has ref 1;
      $z isa person, has name "Ralph", has age 18, has ref 2;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x has age > 18;
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:1 |


  Scenario: 'has $attr < $x' matches owners of any instance '$y' of '$attr' where '$y < $x'
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x isa person, has name "Susie", has age 16, has ref 0;
      $y isa person, has name "Donald", has age 25, has ref 1;
      $z isa person, has name "Ralph", has age 18, has ref 2;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x has age < 18;
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:0 |


  Scenario: 'has $attr != $x' matches owners of any instance '$y' of '$attr' where '$y != $x'
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x isa person, has name "Susie", has age 16, has ref 0;
      $y isa person, has name "Donald", has age 25, has ref 1;
      $z isa person, has name "Ralph", has age 18, has ref 2;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x has age != 18;
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:0 |
      | key:ref:1 |


  Scenario: value comparisons can be performed between a 'double' and a 'long'
    Given typeql define
      """
      define
      attribute house-number value long;
      attribute length value double;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x 1 isa house-number;
      $y 2.0 isa length;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
        $x isa house-number;
        $x == 1.0;
      """
    Then answer size is: 1
    When get answers of typeql read query
      """
      match
        $x isa length;
        $x == 2;
      """
    Then answer size is: 1
    When get answers of typeql read query
      """
      match
        $x isa house-number;
        $x 1.0;
      """
    Then answer size is: 1
    When get answers of typeql read query
      """
      match
        $x isa length;
        $x 2;
      """
    Then answer size is: 1
    When get answers of typeql read query
      """
      match
        $x isa $a;
        $x >= 1;
      """
    Then answer size is: 2
    When get answers of typeql read query
      """
      match
        $x isa $a;
        $x < 2.0;
      """
    Then answer size is: 1

    When get answers of typeql read query
      """
      match
        $x isa house-number;
        $y isa length;
        $x < $y;
      """
    Then answer size is: 1


  Scenario: when a thing owns multiple attributes of the same type, a value comparison matches if any value matches
    Given typeql define
      """
      define
      attribute lucky-number value long;
      person owns lucky-number;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x isa person, has lucky-number 10, has lucky-number 20, has lucky-number 30, has ref 0;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x has lucky-number > 25;
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:0 |


  Scenario: an attribute variable used in both '=' and '>=' predicates is correctly resolved
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x isa person, has name "Susie", has age 16, has ref 0;
      $y isa person, has name "Donald", has age 25, has ref 1;
      $z isa person, has name "Ralph", has age 18, has ref 2;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
        $x has age == $z;
        $z >= 17;
        $z isa age;
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:1 |
      | key:ref:2 |


  Scenario: when the answers of a value comparison include both a 'double' and a 'long', both answers are returned
    Given typeql define
      """
      define
      attribute length value double;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $a 24 isa age;
      $b 19 isa age;
      $c 20.9 isa length;
      $d 19.9 isa length;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
        $x isa $_;
        $x > 20;
      """
    Then uniquely identify answer concepts
      | x                |
      | attr:age:24      |
      | attr:length:20.9 |


  Scenario: when one entity exists, and we match two variables with concept inequality, an empty answer is returned
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert $x isa person, has ref 0;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
        $x isa person;
        $y isa person;
        not { $x is $y; };
      """
    Then answer size is: 0


  Scenario: concept comparison of unbound variables throws an error
    Then typeql read query; fails
      """
      match not { $x is $y; };
      """
    Then transaction is open: false

  ############
  # PATTERNS #
  ############

  Scenario: disjunctions return the union of composing query statements
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x isa person, has name "Jeff", has ref 0;
      $y isa company, has name "Amazon", has ref 1;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa $t; { $t label person; } or {$t label company;};
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:0 |
      | key:ref:1 |
    When get answers of typeql read query
      """
      match $x isa $_; {$x has name "Jeff";} or {$x has name "Amazon";};
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:0 |
      | key:ref:1 |


  Scenario: disjunctions with no answers can be limited
    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa $t; { $t label person; } or {$t label company;};
      """
    Then answer size is: 0
    When get answers of typeql read query
      """
      match $x isa $t; { $t label person; } or {$t label company;};
      """
    Then answer size is: 0


  Scenario: negations can be applied to filtered variables
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x isa person, has name "Jeff", has ref 0;
      $y isa person, has name "Jenny", has ref 1;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa person, has name $a; not { $a == "Jeff"; };
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:1 |


  # TODO use non-root types
  Scenario: multiple negations can be applied
    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x sub! thing; not { $x type thing; }; not { $x type entity; }; not { $x type relation; };
      """
    Then uniquely identify answer concepts
      | x               |
      | label:attribute |

  Scenario: pattern variable without named variable is invalid
    Given connection open read transaction for database: typedb
    Then typeql read query; fails
      """
      match $x isa person, has name $a; "bob" isa name;
      """


  ##################
  # VARIABLE TYPES #
  ##################

  Scenario: all instances and their types can be retrieved
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x isa person, has name "Bertie", has ref 0;
      $y isa person, has name "Angelina", has ref 1;
      $r links (friend: $x, friend: $y), isa friendship, has ref 2;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    Given get answers of typeql read query
      """
      match entity $t; $x isa $t;
      """
    Given answer size is: 2
    Given get answers of typeql read query
      """
      match relation $t; $x isa $t;
      """
    Given answer size is: 1
    Given get answers of typeql read query
      """
      match attribute $t; $x isa $t;
      """
    Given answer size is: 5
    When get answers of typeql read query
      """
      match $x isa $type;
      """
    # 2 entities x 1 type {person}
    # 1 relation x 1 type {friendship}
    # 5 attributes x 2 types {ref/name}
    Then answer size is: 13


  Scenario: all relations and their types can be retrieved
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x isa person, has name "Bertie", has ref 0;
      $y isa person, has name "Angelina", has ref 1;
      $r links (friend: $x, friend: $y), isa friendship, has ref 2;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    Given get answers of typeql read query
      """
      match relation $t; $r isa $t;
      """
    Given answer size is: 1
    Given get answers of typeql read query
      """
      match ($x, $y);
      """
    # 2 permutations of the roleplayers
    Given answer size is: 2
    When get answers of typeql read query
      """
      match ($x, $y) isa $type;
      """
    # 2 permutations of the roleplayers
    Then answer size is: 2


  Scenario: variable role types with relations playing roles
    Given typeql define
      """
      define
        relation parent relates nested, owns id;
        relation nested relates player, plays parent:nested;
        entity player owns id, plays nested:player;
        attribute id value string;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
        $i1 "i1" isa id;
        $i2 "i2" isa id;
        $p1 isa player, has id $i1;
        $p2 isa player, has id $i2;
        $n1 links (player: $p1), isa nested;
        $n2 links (player: $p2), isa nested;
        $p1 links (nested: $n1), isa parent, has id $i1;
        $p2 links (nested: $n2), isa parent, has id $i2;
      """
    Given transaction commits
    Given connection open read transaction for database: typedb

    # Force traversal of role edges in each direction: See vaticle/typedb#6925
    When get answers of typeql read query
      """
      match
        $boundId1 = "i1";

        $p links ($role-nested: $n), isa parent, has id $boundId1;
        $n links ($role-player: $i), isa nested;

        not { $role-nested sub! $r; };
        not { $role-player sub! $r; };
      """
    Then answer size is: 1

    When get answers of typeql read query
      """
      match
        $boundId1 = "i1";

        $p links ($role-nested: $n), isa parent, has id $i;
        $n links ($role-player: $p), isa nested;
        $p has $boundId1;

        not { $role-nested sub! $r; };
        not { $role-player sub! $r; };
      """
    Then answer size is: 1


  #######################
  # NEGATION VALIDATION #
  #######################

  # Negation resolution is handled by Reasoner, but query validation is handled by the language.
  Scenario: when the entire match clause is a negation, an error is thrown
  At least one negated pattern variable must be bound outside the negation block, so this query is invalid.
    Then typeql read query; fails
      """
      match not { $x has $a "value"; };
      """
    Then transaction is open: false

  Scenario: when matching a negation whose pattern variables are all unbound outside it, an error is thrown
    Then typeql read query; fails
      """
      match
        entity $t;
        $r isa $t;
        not {
          ($r2, $i);
        };
      """
    Then transaction is open: false

  Scenario: the first variable in a negation can be unbound, as long as it is connected to a bound variable
    Then get answers of typeql read query
      """
      match
        attribute $a;
        $r isa $a;
        not {
          $x has $r;
        };
      """

  # TODO: We should verify the answers
  Scenario: negations can contain disjunctions
    Then get answers of typeql read query
      """
      match
        entity $t;
        $x isa $t;
        not {
          { $x has $a 1; } or { $x has $a 2; };
        };
      """

  Scenario: when negating a negation redundantly, an error is thrown
    Then typeql read query; fails
      """
      match
        $x isa person, has name "Tim";
        not {
          not {
            $x has age 55;
          };
        };
      """


  #######################
  #   Unicode Support   #
  #######################

  Scenario: string attribute values can be non-ascii
    Given typeql define
      """
      define
      person owns favorite-phrase;
      attribute favorite-phrase value string;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x isa person, has favorite-phrase "你明白了吗", has ref 0;
      $y isa person, has favorite-phrase "בוקר טוב", has ref 1;
      $r links (friend: $x, friend: $y), isa friendship, has ref 2;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    Given get answers of typeql read query
      """
      match $phrase isa favorite-phrase;
      """
    Then uniquely identify answer concepts
      | phrase                             |
      | attr:favorite-phrase:你明白了吗    |
      | attr:favorite-phrase:בוקר טוב      |

    Given get answers of typeql read query
      """
      match $x isa person, has favorite-phrase "你明白了吗";
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:0 |

    Given get answers of typeql read query
      """
      match $x isa person, has favorite-phrase "בוקר טוב";
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:1 |

    Given get answers of typeql read query
      """
      match $x isa person, has favorite-phrase "请给我一";
      """
    Then answer size is: 0


  Scenario: type labels can be non-ascii
    Given typeql define
      """
      define
      entity 人 owns name, owns ref @key; entity אדם owns name, owns ref @key;
      """
    Given transaction commits
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x isa 人, has name "Liu", has ref 0;
      $y isa אדם, has name "Solomon", has ref 1;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    Given get answers of typeql read query
      """
      match $x isa! $t; $x has name $_;
      """
    Then uniquely identify answer concepts
      | t         |
      | label:人  |
      | label:אדם |

    Given get answers of typeql read query
      """
      match $x isa 人;
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:0 |

    Given get answers of typeql read query
      """
      match $x isa אדם;
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:1 |


  Scenario: variables can be non-ascii
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $人 isa person, has name "Liu", has ref 0;
      $אדם isa person, has name "Solomon", has ref 1;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    Given get answers of typeql read query
      """
      match $人 isa person; $人 has name "Liu";
      """
    Then uniquely identify answer concepts
      | 人        |
      | key:ref:0 |

    Given get answers of typeql read query
      """
      match $אדם isa person; $אדם has name "Solomon";
      """
    Then uniquely identify answer concepts
      | אדם       |
      | key:ref:1 |


  Scenario: labels and variables have different identifier formats
    Given typeql define; parsing fails
      """
      define
      entity 0_leading_digit_fails;
      """

    Given connection open read transaction for database: typedb
    Given get answers of typeql read query
      """
      match
      entity $0_leading_digit_allowed;
      """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    Given typeql define; parsing fails
      """
      define
      entity _leading_connector_disallowed;
      """

    Given connection open read transaction for database: typedb
    Given typeql read query; parsing fails
      """
      match
      entity $_leading_connector_disallowed;
      """

    Given connection open schema transaction for database: typedb
    Given typeql define
      """
      define
      entity following_connectors-and-digits-1-2-3-allowed;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    Given get answers of typeql read query
      """
      match
      entity $following_connectors-and-digits-1-2-3-allowed;
      """
