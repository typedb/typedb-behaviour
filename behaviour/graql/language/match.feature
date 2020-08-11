#
# Copyright (C) 2020 Grakn Labs
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
Feature: Graql Match Clause

  Background: Open connection
    Given connection has been opened
    Given connection delete all databases
    Given connection open sessions for databases:
      | test_match |
    Given transaction is initialised
    Given graql define
      """
      define
      person sub entity,
        plays friend,
        plays employee,
        owns name,
        owns age,
        owns ref;
      company sub entity,
        plays employer,
        owns name,
        owns ref;
      friendship sub relation,
        relates friend,
        owns ref;
      employment sub relation,
        relates employee,
        relates employer,
        owns ref;
      name sub attribute, value string;
      age sub attribute, value long;
      ref sub attribute, value long;
      """
    Given the integrity is validated


  ##################
  # SCHEMA QUERIES #
  ##################

  Scenario: 'type' matches only the specified type, and does not match subtypes
    Given graql define
      """
      define
      writer sub person;
      scifi-writer sub writer;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x type person; get;
      """
    And concept identifiers are
      |     | check | value  |
      | PER | label | person |
    Then uniquely identify answer concepts
      | x   |
      | PER |


  Scenario: 'sub' can be used to match the specified type and all its subtypes, including indirect subtypes
    Given graql define
      """
      define
      writer sub person;
      scifi-writer sub writer;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x sub person; get;
      """
    And concept identifiers are
      |     | check | value        |
      | PER | label | person       |
      | WRI | label | writer       |
      | SCW | label | scifi-writer |
    Then uniquely identify answer concepts
      | x   |
      | PER |
      | WRI |
      | SCW |


  Scenario: 'sub' can be used to match the specified type and all its supertypes, including indirect supertypes
    Given graql define
      """
      define
      writer sub person;
      scifi-writer sub writer;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match writer sub $x; get;
      """
    And concept identifiers are
      |     | check | value  |
      | WRI | label | writer |
      | PER | label | person |
      | ENT | label | entity |
      | THI | label | thing  |
    Then uniquely identify answer concepts
      | x   |
      | WRI |
      | PER |
      | ENT |
      | THI |


  Scenario: 'sub' can be used to retrieve all instances of types that are subtypes of a given type
    Given graql define
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
    Given the integrity is validated
    Given graql insert
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
    Given the integrity is validated
    When get answers of graql query
      """
      match
        $x isa $type;
        $type sub worker;
      get;
      """
    When concept identifiers are
      |     | check | value                        |
      | CHA | key   | ref:2                        |
      | DEB | key   | ref:3                        |
      | EDM | key   | ref:4                        |
      | FEL | key   | ref:5                        |
      | GAR | key   | ref:6                        |
      | CON | label | construction-worker          |
      | BRI | label | bricklayer                   |
      | CRA | label | crane-driver                 |
      | TEL | label | telecoms-worker              |
      | MNR | label | mobile-network-researcher    |
      | TBS | label | telecoms-business-strategist |
      | WOR | label | worker                       |
    # Alfred and Barbara are not retrieved, as they aren't subtypes of worker
    Then uniquely identify answer concepts
      | x   | type |
      | CHA | BRI  |
      | CHA | CON  |
      | CHA | WOR  |
      | DEB | CRA  |
      | DEB | CON  |
      | DEB | WOR  |
      | EDM | MNR  |
      | EDM | TEL  |
      | EDM | WOR  |
      | FEL | TBS  |
      | FEL | TEL  |
      | FEL | WOR  |
      | GAR | WOR  |


  Scenario: 'sub!' matches the specified type and its direct subtypes
    Given graql define
      """
      define
      writer sub person;
      scifi-writer sub writer;
      musician sub person;
      flutist sub musician;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x sub! person; get;
      """
    And concept identifiers are
      |     | check | value    |
      | PER | label | person   |
      | WRI | label | writer   |
      | MUS | label | musician |
    Then uniquely identify answer concepts
      | x   |
      | PER |
      | WRI |
      | MUS |


  Scenario: 'sub!' can be used to match the specified type and its direct supertype
    Given graql define
      """
      define
      writer sub person;
      scifi-writer sub writer;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match writer sub! $x; get;
      """
    And concept identifiers are
      |     | check | value  |
      | WRI | label | writer |
      | PER | label | person |
    Then uniquely identify answer concepts
      | x   |
      | WRI |
      | PER |


  Scenario: subtype hierarchy satisfies transitive sub assertions
    Given graql define
      """
      define
      sub1 sub entity;
      sub2 sub sub1;
      sub3 sub sub1;
      sub4 sub sub2;
      sub5 sub sub4;
      sub6 sub sub5;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match
        $x sub $y;
        $y sub $z;
        $z sub sub1;
      get;
      """
    Then each answer satisfies
      """
      match $x sub $z; $x iid <answer.x.iid>; $z iid <answer.z.iid>; get;
      """


  Scenario: 'has' matches types that have the specified attribute type
    When get answers of graql query
      """
      match $x owns age; get;
      """
    And concept identifiers are
      |     | check | value  |
      | PER | label | person |
    Then uniquely identify answer concepts
      | x   |
      | PER |


  Scenario: 'has' does not match types that have only a subtype of the specified attribute type
    Given graql define
      """
      define
      club-name sub name;
      club sub entity, owns club-name;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x owns name; get;
      """
    And concept identifiers are
      |     | check | value   |
      | PER | label | person  |
      | COM | label | company |
    Then uniquely identify answer concepts
      | x   |
      | PER |
      | COM |


  Scenario: 'has' does not match types that have only a supertype of the specified attribute type
    Given graql define
      """
      define
      club-name sub name;
      club sub entity, owns club-name;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x owns club-name; get;
      """
    And concept identifiers are
      |     | check | value |
      | CLU | label | club  |
    Then uniquely identify answer concepts
      | x   |
      | CLU |


  @ignore
  # TODO: re-enable when we can retrieve attribute types that a specified type has (issue #4664)
  Scenario: 'has' can be used to match attribute types that a particular type has
    When get answers of graql query
      """
      match person has $x; get;
      """
    And concept identifiers are
      |     | check | value |
      | NAM | label | name  |
      | AGE | label | age   |
      | REF | label | ref   |
    Then uniquely identify answer concepts
      | x   |
      | NAM |
      | AGE |
      | REF |


  Scenario: 'has' can be used to retrieve all instances of types that can own a given attribute type
    Given graql define
      """
      define
      employment owns name;
      """
    Given the integrity is validated
    Given graql insert
      """
      insert
      $x isa person, has ref 0;
      $y isa company, has ref 1;
      $z (friend: $x) isa friendship, has ref 2;
      $w (employee: $x, employer: $y) isa employment, has ref 3;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match
        $x isa $type;
        $type owns name;
      get;
      """
    When concept identifiers are
      |      | check | value      |
      | PER  | key   | ref:0      |
      | COM  | key   | ref:1      |
      | EMP  | key   | ref:3      |
      | tPER | label | person     |
      | tCOM | label | company    |
      | tEMP | label | employment |
    # friendship and ref should not be retrieved, as they can't have a name
    Then uniquely identify answer concepts
      | x   | type |
      | PER | tPER |
      | COM | tCOM |
      | EMP | tEMP |


  Scenario: 'plays' matches types that can play the specified role
    When get answers of graql query
      """
      match $x plays friend; get;
      """
    And concept identifiers are
      |     | check | value  |
      | PER | label | person |
    Then uniquely identify answer concepts
      | x   |
      | PER |


  Scenario: 'plays' does not match types that only play a subrole of the specified role
    Given graql define
      """
      define
      close-friendship sub relation, relates close-friend as friend;
      friendly-person sub entity, plays close-friend;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x plays friend; get;
      """
    And concept identifiers are
      |     | check | value  |
      | PER | label | person |
    Then uniquely identify answer concepts
      | x   |
      | PER |


  Scenario: 'plays' does not match types that only play a super-role of the specified role
    Given graql define
      """
      define
      close-friendship sub relation, relates close-friend as friend;
      friendly-person sub entity, plays close-friend;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x plays close-friend; get;
      """
    And concept identifiers are
      |     | check | value           |
      | FRP | label | friendly-person |
    Then uniquely identify answer concepts
      | x   |
      | FRP |


  Scenario: 'plays' can be used to match roles that a particular type can play
    When get answers of graql query
      """
      match person plays $x; get;
      """
    And concept identifiers are
      |     | check | value    |
      | FRI | label | friend   |
      | EMP | label | employee |
    Then uniquely identify answer concepts
      | x   |
      | FRI |
      | EMP |


  Scenario: 'plays' can be used to retrieve all instances of types that can play a specific role
    Given graql define
      """
      define
      dog sub entity,
        plays friend,
        owns ref;
      """
    Given the integrity is validated
    Given graql insert
      """
      insert
      $x isa person, has ref 0;
      $y isa company, has ref 1;
      $z isa dog, has ref 2;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match
        $x isa $type;
        $type plays friend;
      get;
      """
    When concept identifiers are
      |      | check | value  |
      | PER  | key   | ref:0  |
      | DOG  | key   | ref:2  |
      | tPER | label | person |
      | tDOG | label | dog    |
    Then uniquely identify answer concepts
      | x   | type |
      | PER | tPER |
      | DOG | tDOG |


  Scenario: 'key' matches types that have the specified attribute type as a key
    Given graql define
      """
      define
      breed sub attribute, value string;
      dog sub entity, owns breed;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x owns breed; get;
      """
    And concept identifiers are
      |     | check | value |
      | DOG | label | dog   |
    Then uniquely identify answer concepts
      | x   |
      | DOG |


  @ignore
  # TODO: re-enable when we can retrieve attribute types that a specified type has (issue #4664)
  Scenario: 'key' can be used to find all attribute types that the specified type uses as key
    When get answers of graql query
      """
      match person key $x; get;
      """
    And concept identifiers are
      |     | check | value |
      | REF | label | ref   |
    Then uniquely identify answer concepts
      | x   |
      | REF |


  Scenario: 'has' matches types that have the specified attribute type, even if they use it as a key
    Given graql define
      """
      define
      breed sub attribute, value string;
      dog sub entity, owns breed;
      cat sub entity, owns breed;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x owns breed; get;
      """
    And concept identifiers are
      |     | check | value |
      | DOG | label | dog   |
      | CAT | label | cat   |
    Then uniquely identify answer concepts
      | x   |
      | DOG |
      | CAT |


  Scenario: 'relates' matches relation types where the specified role can be played
    When get answers of graql query
      """
      match $x relates employee; get;
      """
    And concept identifiers are
      |     | check | value      |
      | EMP | label | employment |
    Then uniquely identify answer concepts
      | x   |
      | EMP |


  Scenario: 'relates' with 'as' matches relation types where the specified role is played as a subrole of the specified super-role
    Given graql define
      """
      define
      close-friendship sub relation, relates close-friend as friend;
      friendly-person sub entity, plays close-friend;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x relates close-friend as friend; get;
      """
    And concept identifiers are
      |     | check | value            |
      | CLF | label | close-friendship |
    Then uniquely identify answer concepts
      | x   |
      | CLF |


  Scenario: 'relates' does not match relation types that block the specified roleplayer with 'as'
    Given graql define
      """
      define
      close-friendship sub relation, relates close-friend as friend;
      friendly-person sub entity, plays close-friend;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x relates friend; get;
      """
    And concept identifiers are
      |     | check | value      |
      | FRE | label | friendship |
    Then uniquely identify answer concepts
      | x   |
      | FRE |


  Scenario: 'relates' can be used to retrieve all the roles of a relation type
    When get answers of graql query
      """
      match employment relates $x; get;
      """
    And concept identifiers are
      |     | check | value    |
      | EME | label | employee |
      | EMR | label | employer |
    Then uniquely identify answer concepts
      | x   |
      | EME |
      | EMR |


  Scenario: when matching by a concept iid that doesn't exist, an empty result is returned
    When get answers of graql query
      """
      match
        $x iid 83cb2;
        $y iid 4ba92;
      get;
      """
    Then answer size is: 0


  ##########
  # THINGS #
  ##########

  Scenario: 'isa' matches things of the specified type and all its subtypes
    Given graql define
      """
      define
      writer sub person;
      scifi-writer sub writer;
      good-scifi-writer sub scifi-writer;
      """
    Given the integrity is validated
    Given graql insert
      """
      insert
      $x isa person, has ref 0;
      $y isa writer, has ref 1;
      $z isa scifi-writer, has ref 2;
      $w isa good-scifi-writer, has ref 3;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x isa writer; get;
      """
    And concept identifiers are
      |     | check | value |
      | WRI | key   | ref:1 |
      | SCI | key   | ref:2 |
      | GOO | key   | ref:3 |
    Then uniquely identify answer concepts
      | x   |
      | WRI |
      | SCI |
      | GOO |


  Scenario: 'isa!' only matches things of the specified type, and does not match subtypes
    Given graql define
      """
      define
      writer sub person;
      scifi-writer sub writer;
      good-scifi-writer sub scifi-writer;
      """
    Given the integrity is validated
    Given graql insert
      """
      insert
      $x isa person, has ref 0;
      $y isa writer, has ref 1;
      $z isa scifi-writer, has ref 2;
      $w isa good-scifi-writer, has ref 3;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x isa! writer; get;
      """
    And concept identifiers are
      |     | check | value |
      | WRI | key   | ref:1 |
    Then uniquely identify answer concepts
      | x   |
      | WRI |


  Scenario: 'iid' matches the instance with the specified internal iid
    Given graql insert
      """
      insert
      $x isa person, has ref 0;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x isa person; get;
      """
    Then each answer satisfies
      """
      match $x iid <answer.x.iid>; get;
      """


  Scenario: when matching by a type whose label doesn't exist, an error is thrown
    Then graql get throws
      """
      match $x isa ganesh; get;
      """
    Then the integrity is validated


  Scenario: when matching by a type iid that doesn't exist, an empty result is returned
    When get answers of graql query
      """
      match $x isa $type; $type iid 83cb2; get;
      """
    Then answer size is: 0


  Scenario: when matching by a relation type whose label doesn't exist, an error is thrown
    Then graql get throws
      """
      match ($x, $y) isa $type; $type type jakas-relacja; get;
      """
    Then the integrity is validated


  Scenario: when matching a non-existent type label to a variable from a generic 'isa' query, an error is thrown
    Then graql get throws
      """
      match $x isa $type; $type type polok; get;
      """
    Then the integrity is validated


  Scenario: when matching that the same variable is of two types, an empty result is returned
    Then get answers of graql query
      """
      match
        $x isa person;
        $x isa company;
      get;
      """
    Then answer size is: 0


  Scenario: when one entity exists, and we match two variables both of that entity type, the entity is returned
    Given graql insert
      """
      insert $x isa person, has ref 0;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match
        $x isa person;
        $y isa person;
      get;
      """
    When concept identifiers are
      |     | check | value |
      | PER | key   | ref:0 |
    Then uniquely identify answer concepts
      | x   | y   |
      | PER | PER |


  Scenario: an error is thrown when matching that a variable has a specific type, when that type is in fact a role
    Then graql get throws
      """
      match $x isa friend; get;
      """
    Then the integrity is validated


  Scenario: an error is thrown when matching that a variable has a specific type, when that type is in fact a rule
    Given graql define
      """
      define
      metre-rule sub rule, when {
        $x isa person;
      }, then {
        $x has name "metre";
      };
      """
    Given the integrity is validated
    Then graql get throws
      """
      match $x isa metre-rule; get;
      """
    Then the integrity is validated


  #############
  # RELATIONS #
  #############

  Scenario: a relation is matchable from role players without specifying relation type
    When graql insert
      """
      insert
      $x isa person, has ref 0;
      $y isa company, has ref 1;
      $r (employee: $x, employer: $y) isa employment,
         has ref 2;
      """
    When the integrity is validated
    Then get answers of graql query
      """
      match $x isa person; $r (employee: $x) isa relation; get;
      """
    And concept identifiers are
      |      | check | value |
      | REF0 | key   | ref:0 |
      | REF1 | key   | ref:1 |
      | REF2 | key   | ref:2 |
    Then uniquely identify answer concepts
      | x    | r    |
      | REF0 | REF2 |
    When get answers of graql query
      """
      match $y isa company; $r (employer: $y) isa relation; get;
      """
    Then uniquely identify answer concepts
      | y    | r    |
      | REF1 | REF2 |


  Scenario: relations are matchable from roleplayers without specifying any roles
    Given graql insert
      """
      insert
      $x isa person, has ref 0;
      $y isa company, has ref 1;
      $r (employee: $x, employer: $y) isa employment,
         has ref 2;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x isa person; $r ($x) isa relation; get;
      """
    When concept identifiers are
      |      | check | value |
      | REF0 | key   | ref:0 |
      | REF2 | key   | ref:2 |
    Then uniquely identify answer concepts
      | x    | r    |
      | REF0 | REF2 |


  Scenario: retrieve all combinations of players in a relation
    When graql insert
      """
      insert $p isa person, has ref 0;
      $c isa company, has ref 1;
      $c2 isa company, has ref 2;
      $r (employee: $p, employer: $c, employer: $c2) isa employment, has ref 3;
      """
    When the integrity is validated
    Then get answers of graql query
      """
      match $r ($x, $y) isa employment; get;
      """
    And concept identifiers are
      |      | check | value |
      | REF0 | key   | ref:0 |
      | REF1 | key   | ref:1 |
      | REF2 | key   | ref:2 |
      | REF3 | key   | ref:3 |
    Then uniquely identify answer concepts
      | x    | y    | r    |
      | REF0 | REF1 | REF3 |
      | REF1 | REF0 | REF3 |
      | REF0 | REF2 | REF3 |
      | REF2 | REF0 | REF3 |
      | REF1 | REF2 | REF3 |
      | REF2 | REF1 | REF3 |


  Scenario: duplicate role players are retrieved singly when queried doubly
    Given graql define
      """
      define
      some-entity sub entity, plays player, owns ref;
      symmetric sub relation, relates player, owns ref;
      """
    Given the integrity is validated
    Given graql insert
      """
      insert $x isa some-entity, has ref 0; (player: $x, player: $x) isa symmetric, has ref 1;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $r (player: $x, player: $x) isa relation; get;
      """
    And concept identifiers are
      |      | check | value |
      | REF0 | key   | ref:0 |
      | REF1 | key   | ref:1 |
    Then uniquely identify answer concepts
      | x    | r    |
      | REF0 | REF1 |


  Scenario: duplicate role players are retrieved singly when queried singly
    Given graql define
      """
      define
      some-entity sub entity, plays player, owns ref;
      symmetric sub relation, relates player, owns ref;
      """
    Given the integrity is validated
    Given graql insert
      """
      insert $x isa some-entity, has ref 0; (player: $x, player: $x) isa symmetric, has ref 1;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $r (player: $x) isa relation; get;
      """
    And concept identifiers are
      |      | check | value |
      | REF0 | key   | ref:0 |
      | REF1 | key   | ref:1 |
    Then uniquely identify answer concepts
      | x    | r    |
      | REF0 | REF1 |


  Scenario: relations between distinct concepts are not retrieved when matching concepts that relate to themselves
    Given graql insert
      """
      insert
      $x isa person, has ref 1;
      $y isa person, has ref 2;
      (friend: $x, friend: $y) isa friendship, has ref 0;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match (friend: $x, friend: $x) isa friendship; get;
      """
    Then answer size is: 0


  Scenario: matching a chain of relations only returns answers if there is a chain of the required length
    Given graql define
      """
      define

      gift-delivery sub relation,
        relates sender,
        relates recipient;

      person plays sender,
        plays recipient;
      """
    Given the integrity is validated
    Given graql insert
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
    Given the integrity is validated
    When get answers of graql query
      """
      match
        (sender: $a, recipient: $b) isa gift-delivery;
        (sender: $b, recipient: $c) isa gift-delivery;
      get;
      """
    When concept identifiers are
      |     | check | value |
      | SOR | key   | ref:0 |
      | MAR | key   | ref:1 |
      | PAT | key   | ref:2 |
    Then uniquely identify answer concepts
      | a   | b   | c   |
      | SOR | MAR | PAT |
    When get answers of graql query
      """
      match
        (sender: $a, recipient: $b) isa gift-delivery;
        (sender: $b, recipient: $c) isa gift-delivery;
        (sender: $c, recipient: $d) isa gift-delivery;
      get;
      """
    Then answer size is: 0


  Scenario: when multiple relation instances exist with the same roleplayer, matching that player returns just 1 answer
    Given graql define
      """
      define
      residency sub relation,
        relates resident,
        owns ref;
      person plays resident;
      """
    Given the integrity is validated
    Given graql insert
      """
      insert
      $x isa person, has ref 0;
      $e (employee: $x) isa employment, has ref 1;
      $f (friend: $x) isa friendship, has ref 2;
      $r (resident: $x) isa residency, has ref 3;
      """
    Given the integrity is validated
    Given concept identifiers are
      |     | check | value |
      | PER | key   | ref:0 |
      | EMP | key   | ref:1 |
      | FRI | key   | ref:2 |
      | RES | key   | ref:3 |
    Given get answers of graql query
      """
      match $r isa relation; get;
      """
    Given uniquely identify answer concepts
      | r   |
      | EMP |
      | FRI |
      | RES |
    When get answers of graql query
      """
      match ($x) isa relation; get;
      """
    Then uniquely identify answer concepts
      | x   |
      | PER |
    When get answers of graql query
      """
      match ($x); get;
      """
    Then uniquely identify answer concepts
      | x   |
      | PER |


  Scenario: an error is thrown when matching an entity type as if it were a role
    Then graql get throws
      """
      match (person: $x) isa relation; get;
      """
    Then the integrity is validated


  Scenario: an error is thrown when matching an entity as if it were a relation
    Then graql get throws
      """
      match ($x) isa person; get;
      """
    Then the integrity is validated


  Scenario: an error is thrown when matching a non-existent type label as if it were a relation type
    Then graql get throws
      """
      match ($x) isa bottle-of-rum; get;
      """
    Then the integrity is validated


  Scenario: when matching a role that doesn't exist, an error is thrown
    Then graql get throws
      """
      match (rolein-rolein-rolein: $rolein) isa relation; get;
      """
    Then the integrity is validated


  Scenario: when matching a role in a relation type that doesn't have that role, an empty result is returned
    When get answers of graql query
      """
      match (friend: $x) isa employment; get;
      """
    Then answer size is: 0


  Scenario: when matching a roleplayer in a relation that can't actually play that role, an empty result is returned
    When get answers of graql query
      """
      match
        $x isa company;
        ($x) isa friendship;
      get;
      """
    Then answer size is: 0


  Scenario: when querying for a non-existent relation type iid, an empty result is returned
    When get answers of graql query
      """
      match ($x, $y) isa $type; $type iid 83cb2; get;
      """
    Then answer size is: 0
    When get answers of graql query
      """
      match $r ($x, $y) isa $type; $r iid 4ba92; get;
      """
    Then answer size is: 0


  ##############
  # ATTRIBUTES #
  ##############

  Scenario Outline: '<type>' attributes can be matched by value
    Given graql define
      """
      define <attr> sub attribute, value <type>, owns ref;
      """
    Given the integrity is validated
    Given graql insert
      """
      insert $n <value> isa <attr>, has ref 0;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $a <value>; get;
      """
    And concept identifiers are
      |     | check | value |
      | ATT | key   | ref:0 |
    Then uniquely identify answer concepts
      | a   |
      | ATT |

    Examples:
      | attr        | type     | value      |
      | colour      | string   | "Green"    |
      | calories    | long     | 1761       |
      | grams       | double   | 9.6        |
      | gluten-free | boolean  | false      |
      | use-by-date | datetime | 2020-06-16 |


  Scenario Outline: when matching a '<type>' attribute by a value that doesn't exist, an empty answer is returned
    Given graql define
      """
      define <attr> sub attribute, value <type>, owns ref;
      """
    Given the integrity is validated
    When get answers of graql query
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
    Given graql insert
      """
      insert
      $x "Seven Databases in Seven Weeks" isa name;
      $y "Four Weddings and a Funeral" isa name;
      $z "Fun Facts about Space" isa name;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x contains "Fun"; get;
      """
    And concept identifiers are
      |     | check | value                            |
      | FOU | value | name:Four Weddings and a Funeral |
      | FUN | value | name:Fun Facts about Space       |
    Then uniquely identify answer concepts
      | x   |
      | FOU |
      | FUN |


  Scenario: 'contains' performs a case-insensitive match
    Given graql insert
      """
      insert
      $x "The Phantom of the Opera" isa name;
      $y "Pirates of the Caribbean" isa name;
      $z "Mr. Bean" isa name;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x contains "Bean"; get;
      """
    And concept identifiers are
      |     | check | value                         |
      | PIR | value | name:Pirates of the Caribbean |
      | MRB | value | name:Mr. Bean                 |
    Then uniquely identify answer concepts
      | x   |
      | PIR |
      | MRB |


  Scenario: 'like' matches strings that match the specified regex
    Given graql insert
      """
      insert
      $x "ABC123" isa name;
      $y "123456" isa name;
      $z "9" isa name;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x like "^[0-9]+$"; get;
      """
    And concept identifiers are
      |     | check | value       |
      | ONE | value | name:123456 |
      | NIN | value | name:9      |
    Then uniquely identify answer concepts
      | x   |
      | ONE |
      | NIN |


  Scenario: when querying for a non-existent attribute type iid, an empty result is returned
    When get answers of graql query
      """
      match $x has name $y; $x iid 83cb2; get;
      """
    Then answer size is: 0
    When get answers of graql query
      """
      match $x has name $y; $y iid 83cb2; get;
      """
    Then answer size is: 0


  #######################
  # ATTRIBUTE OWNERSHIP #
  #######################

  Scenario: 'has' can be used to match things that own any instance of the specified attribute
    Given graql insert
      """
      insert
      $x isa person, has name "Leila", has ref 0;
      $y isa person, has ref 1;
      $c isa company, has name "Grakn", has ref 2;
      $d isa company, has ref 3;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x has name $y; get $x;
      """
    And concept identifiers are
      |     | check | value |
      | LEI | key   | ref:0 |
      | GRA | key   | ref:2 |
    Then uniquely identify answer concepts
      | x   |
      | LEI |
      | GRA |


  Scenario: using the 'attribute' meta label, 'has' can match things that own any attribute with a specified value
    Given graql define
      """
      define
      shoe-size sub attribute, value long;
      person owns shoe-size;
      """
    Given the integrity is validated
    Given graql insert
      """
      insert
      $x isa person, has age 9, has ref 0;
      $y isa person, has shoe-size 9, has ref 1;
      $z isa person, has age 12, has shoe-size 12, has ref 2;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x has attribute 9; get;
      """
    And concept identifiers are
      |     | check | value |
      | AG9 | key   | ref:0 |
      | SS9 | key   | ref:1 |
    Then uniquely identify answer concepts
      | x   |
      | AG9 |
      | SS9 |


  Scenario: when an attribute instance is fully specified, 'has' matches its owners
    Given graql define
      """
      define
      friendship owns age;
      graduation-date sub attribute, value datetime, owns age, owns ref;
      person owns graduation-date;
      """
    Given the integrity is validated
    Given graql insert
      """
      insert
      $x isa person, has name "Zoe", has age 21, has graduation-date 2020-06-01, has ref 0;
      $y (friend: $x) isa friendship, has age 21, has ref 1;
      $z 2020-06-01 isa graduation-date, has age 21, has ref 2;
      $w isa person, has ref 3;
      $v (friend: $x, friend: $w) isa friendship, has age 7, has ref 4;
      $u 2019-06-03 isa graduation-date, has age 22, has ref 5;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x has age 21; get;
      """
    And concept identifiers are
      |     | check | value |
      | PER | key   | ref:0 |
      | FRI | key   | ref:1 |
      | GRA | key   | ref:2 |
    Then uniquely identify answer concepts
      | x   |
      | PER |
      | FRI |
      | GRA |


  Scenario: 'has' matches an attribute's owner even if it owns more attributes of the same type
    Given graql define
      """
      define
      lucky-number sub attribute, value long;
      person owns lucky-number;
      """
    Given the integrity is validated
    Given graql insert
      """
      insert
      $x isa person, has lucky-number 10, has lucky-number 20, has lucky-number 30, has ref 0;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x has lucky-number 20; get;
      """
    And concept identifiers are
      |     | check | value |
      | PER | key   | ref:0 |
    Then uniquely identify answer concepts
      | x   |
      | PER |


  Scenario: an error is thrown when matching by attribute ownership, when the owned thing is actually an entity
    Then graql get throws
      """
      match $x has person "Luke"; get;
      """
    Then the integrity is validated


  Scenario: when matching by an attribute ownership, if the owner can't actually own it, an empty result is returned
    When get answers of graql query
      """
      match $x isa company, has age $n; get;
      """
    Then answer size is: 0


  Scenario: an error is thrown when matching by attribute ownership, when the owned type label doesn't exist
    Then graql get throws
      """
      match $x has bananananananana "rama"; get;
      """
    Then the integrity is validated


  ##############################
  # ATTRIBUTE VALUE COMPARISON #
  ##############################

  Scenario: when things own attributes of different types but the same value, they match by equality, but not ownership
    Given graql define
      """
      define
      start-date sub attribute, value datetime;
      graduation-date sub attribute, value datetime;
      person owns graduation-date;
      employment owns start-date;
      """
    Given the integrity is validated
    Given graql insert
      """
      insert
      $x isa person, has name "James", has ref 0, has graduation-date 2009-07-16;
      $r (employee: $x) isa employment, has start-date 2009-07-16, has ref 1;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match
        $x isa person, has graduation-date $date;
        $r (employee: $x) isa employment, has start-date $date;
      get;
      """
    Then answer size is: 0
    Then get answers of graql query
      """
      match
        $x isa person, has graduation-date $date;
        $r (employee: $x) isa employment, has start-date == $date;
      get;
      """
    Then answer size is: 1


  Scenario: 'has $attr == $x' matches owners of any instance '$y' of '$attr' where '$y' and '$x' are equal by value
    Given graql insert
      """
      insert
      $x isa person, has name "Susie", has age 16, has ref 0;
      $y isa person, has name "Donald", has age 25, has ref 1;
      $z isa person, has name "Ralph", has age 18, has ref 2;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x has age == 16; get;
      """
    And concept identifiers are
      |     | check | value |
      | SUS | key   | ref:0 |
    Then uniquely identify answer concepts
      | x   |
      | SUS |


  Scenario: 'has $attr > $x' matches owners of any instance '$y' of '$attr' where '$y > $x'
    Given graql insert
      """
      insert
      $x isa person, has name "Susie", has age 16, has ref 0;
      $y isa person, has name "Donald", has age 25, has ref 1;
      $z isa person, has name "Ralph", has age 18, has ref 2;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x has age > 18; get;
      """
    And concept identifiers are
      |     | check | value |
      | DON | key   | ref:1 |
    Then uniquely identify answer concepts
      | x   |
      | DON |


  Scenario: 'has $attr < $x' matches owners of any instance '$y' of '$attr' where '$y < $x'
    Given graql insert
      """
      insert
      $x isa person, has name "Susie", has age 16, has ref 0;
      $y isa person, has name "Donald", has age 25, has ref 1;
      $z isa person, has name "Ralph", has age 18, has ref 2;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x has age < 18; get;
      """
    And concept identifiers are
      |     | check | value |
      | SUS | key   | ref:0 |
    Then uniquely identify answer concepts
      | x   |
      | SUS |


  Scenario: 'has $attr !== $x' matches owners of any instance '$y' of '$attr' where '$y !== $x'
    Given graql insert
      """
      insert
      $x isa person, has name "Susie", has age 16, has ref 0;
      $y isa person, has name "Donald", has age 25, has ref 1;
      $z isa person, has name "Ralph", has age 18, has ref 2;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x has age !== 18; get;
      """
    And concept identifiers are
      |     | check | value |
      | DON | key   | ref:1 |
      | SUS | key   | ref:0 |
    Then uniquely identify answer concepts
      | x   |
      | DON |
      | SUS |


  Scenario: value comparisons can be performed between a 'double' and a 'long'
    Given graql define
      """
      define
      house-number sub attribute, value long;
      length sub attribute, value double;
      """
    Given the integrity is validated
    Given graql insert
      """
      insert
      $x 1 isa house-number;
      $y 2.0 isa length;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match
        $x isa house-number;
        $x == 1.0;
      get;
      """
    Then answer size is: 1
    When get answers of graql query
      """
      match
        $x isa length;
        $x == 2;
      get;
      """
    Then answer size is: 1
    When get answers of graql query
      """
      match
        $x isa house-number;
        $x 1.0;
      get;
      """
    Then answer size is: 1
    When get answers of graql query
      """
      match
        $x isa length;
        $x 2;
      get;
      """
    Then answer size is: 1
    When get answers of graql query
      """
      match
        $x isa attribute;
        $x >= 1;
      get;
      """
    Then answer size is: 2
    When get answers of graql query
      """
      match
        $x isa attribute;
        $x < 2.0;
      get;
      """
    Then answer size is: 1


  Scenario: when a thing owns multiple attributes of the same type, a value comparison matches if any value matches
    Given graql define
      """
      define
      lucky-number sub attribute, value long;
      person owns lucky-number;
      """
    Given the integrity is validated
    Given graql insert
      """
      insert
      $x isa person, has lucky-number 10, has lucky-number 20, has lucky-number 30, has ref 0;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x has lucky-number > 25; get;
      """
    And concept identifiers are
      |     | check | value |
      | PER | key   | ref:0 |
    Then uniquely identify answer concepts
      | x   |
      | PER |


  @ignore
  # TODO: re-enable when variables used in multiple value predicates are resolvable (grakn#5845)
  Scenario: an attribute variable used in both '==' and '>=' predicates is correctly resolved
    Given graql insert
      """
      insert
      $x isa person, has name "Susie", has age 16, has ref 0;
      $y isa person, has name "Donald", has age 25, has ref 1;
      $z isa person, has name "Ralph", has age 18, has ref 2;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match
        $x has age == $z;
        $z >= 17;
        $z isa age;
      get $x;
      """
    And concept identifiers are
      |     | check | value |
      | DON | key   | ref:1 |
      | RAL | key   | ref:2 |
    Then uniquely identify answer concepts
      | x   |
      | DON |
      | RAL |


  Scenario: when the answers of a value comparison include both a 'double' and a 'long', both answers are returned
    Given graql define
      """
      define
      length sub attribute, value double;
      """
    Given the integrity is validated
    Given graql insert
      """
      insert
      $a 24 isa age;
      $b 19 isa age;
      $c 20.9 isa length;
      $d 19.9 isa length;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match
        $x isa attribute;
        $x > 20;
      get;
      """
    And concept identifiers are
      |      | check | value       |
      | A24  | value | age:24      |
      | A19  | value | age:19      |
      | L209 | value | length:20.9 |
      | L199 | value | length:19.9 |
    Then uniquely identify answer concepts
      | x    |
      | A24  |
      | L209 |


  Scenario: when one entity exists, and we match two variables with concept inequality, an empty answer is returned
    Given graql insert
      """
      insert $x isa person, has ref 0;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match
        $x isa person;
        $y isa person;
        $x != $y;
      get;
      """
    Then answer size is: 0


  Scenario: concept comparison of unbound variables throws an error
    Then graql get throws
      """
      match $x != $y; get;
      """


  Scenario: value comparison of unbound variables throws an error
    Then graql get throws
      """
      match $x !== $y; get;
      """


  ############
  # PATTERNS #
  ############

  Scenario: disjunctions return the union of composing query statements
    Given graql insert
      """
      insert
      $x isa person, has name "Jeff", has ref 0;
      $y isa company, has name "Amazon", has ref 1;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match {$x isa person;} or {$x isa company;}; get;
      """
    And concept identifiers are
      |     | check | value |
      | JEF | key   | ref:0 |
      | AMA | key   | ref:1 |
    Then uniquely identify answer concepts
      | x   |
      | JEF |
      | AMA |


  ##################
  # VARIABLE TYPES #
  ##################

  Scenario: all instances and their types can be retrieved
    Given graql insert
      """
      insert
      $x isa person, has name "Bertie", has ref 0;
      $y isa person, has name "Angelina", has ref 1;
      $r (friend: $x, friend: $y) isa friendship, has ref 2;
      """
    Given the integrity is validated
    Given get answers of graql query
      """
      match $x isa entity; get;
      """
    Given answer size is: 2
    Given get answers of graql query
      """
      match $r isa relation; get;
      """
    Given answer size is: 1
    Given get answers of graql query
      """
      match $x isa attribute; get;
      """
    Given answer size is: 5
    When get answers of graql query
      """
      match $x isa $type; get;
      """
    # 2 entities x 3 types {person,entity,thing}
    # 1 relation x 3 types {friendship,relation,thing}
    # 5 attributes x 3 types {ref/name,attribute,thing}
    Then answer size is: 24


  Scenario: all relations and their types can be retrieved
    Given graql insert
      """
      insert
      $x isa person, has name "Bertie", has ref 0;
      $y isa person, has name "Angelina", has ref 1;
      $r (friend: $x, friend: $y) isa friendship, has ref 2;
      """
    Given the integrity is validated
    Given get answers of graql query
      """
      match $r isa relation; get;
      """
    Given answer size is: 1
    Given get answers of graql query
      """
      match ($x, $y) isa relation; get;
      """
    # 2 permutations of the roleplayers
    Given answer size is: 2
    When get answers of graql query
      """
      match ($x, $y) isa $type; get;
      """
    # 2 permutations x 3 types {friendship,relation,thing}
    Then answer size is: 6


  #######################
  # NEGATION VALIDATION #
  #######################

  # Negation resolution is handled by Reasoner, but query validation is handled by the language.

  Scenario: when the entire match clause is a negation, an error is thrown

  At least one negated pattern variable must be bound outside the negation block, so this query is invalid.

    Then graql get throws
      """
      match
        not { $x has attribute "value"; };
      get;
      """
    Then the integrity is validated


  Scenario: when matching a negation whose pattern variables are all unbound outside it, an error is thrown
    Then graql get throws
      """
      match
        $r isa entity;
        not {
          ($r2, $i);
          $i isa entity;
        };
      get;
      """
    Then the integrity is validated


  Scenario: the first variable in a negation can be unbound, as long as it is connected to a bound variable
    Then get answers of graql query
      """
      match
        $r isa attribute;
        not {
          $x isa entity, has attribute $r;
        };
      get;
      """
    Then the integrity is validated


  Scenario: negations cannot contain disjunctions
    Then graql get throws
      """
      match
        $x isa entity;
        not {
          { $x has attribute 1; } or { $x has attribute 2; };
        };
      get;
      """
    Then the integrity is validated
