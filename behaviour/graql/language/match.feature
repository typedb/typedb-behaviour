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
    Given connection delete all keyspaces
    Given connection open sessions for keyspaces:
      | test_match |
    Given transaction is initialised
    Given graql define
      """
      define
      person sub entity,
        plays friend,
        plays employee,
        has name,
        has age,
        key ref;
      company sub entity,
        plays employer,
        has name,
        key ref;
      friendship sub relation,
        relates friend,
        key ref;
      employment sub relation,
        relates employee,
        relates employer,
        key ref;
      name sub attribute, value string;
      age sub attribute, value long;
      ref sub attribute, value long;
      """
    Given the integrity is validated


  ###################
  # SCHEMA CONCEPTS #
  ###################

  Scenario: `type` matches only the specified type, and does not match subtypes
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


  Scenario: `sub` can be used to match the specified type and all its subtypes, including indirect subtypes
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


  Scenario: `sub` can be used to match the specified type and all its supertypes, including indirect supertypes
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
      |     | check | value   |
      | WRI | label | writer  |
      | PER | label | person  |
      | ENT | label | entity  |
      | THI | label | thing   |
    Then uniquely identify answer concepts
      | x   |
      | WRI |
      | PER |
      | ENT |
      | THI |


  Scenario: `sub!` matches the specified type and its direct subtypes
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


  Scenario: `sub!` can be used to match the specified type and its direct supertype
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
      |     | check | value   |
      | WRI | label | writer  |
      | PER | label | person  |
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
      match $x sub $z; $x id <answer.x.id>; $z id <answer.z.id>; get;
      """


  Scenario: `has` matches types that have the specified attribute type
    When get answers of graql query
      """
      match $x has age; get;
      """
    And concept identifiers are
      |     | check | value  |
      | PER | label | person |
    Then uniquely identify answer concepts
      | x   |
      | PER |


  Scenario: `has` does not match types that have only a subtype of the specified attribute type
    Given graql define
      """
      define
      club-name sub name;
      club sub entity, has club-name;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x has name; get;
      """
    And concept identifiers are
      |     | check | value   |
      | PER | label | person  |
      | COM | label | company |
    Then uniquely identify answer concepts
      | x   |
      | PER |
      | COM |


  Scenario: `has` does not match types that have only a supertype of the specified attribute type
    Given graql define
      """
      define
      club-name sub name;
      club sub entity, has club-name;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x has club-name; get;
      """
    And concept identifiers are
      |     | check | value |
      | CLU | label | club  |
    Then uniquely identify answer concepts
      | x   |
      | CLU |


  @ignore
  # TODO: re-enable when we can retrieve attribute types that a specified type has (issue #4664)
  Scenario: `has` can be used to match attribute types that a particular type has
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


  Scenario: `plays` matches types that can play the specified role
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


  Scenario: `plays` does not match types that only play a subrole of the specified role
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


  Scenario: `plays` does not match types that only play a super-role of the specified role
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


  Scenario: `plays` can be used to match roles that a particular type can play
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


  Scenario: `key` matches types that have the specified attribute type as a key
    Given graql define
      """
      define
      breed sub attribute, value string;
      dog sub entity, key breed;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x key breed; get;
      """
    And concept identifiers are
      |     | check | value |
      | DOG | label | dog   |
    Then uniquely identify answer concepts
      | x   |
      | DOG |


  @ignore
  # TODO: re-enable when we can retrieve attribute types that a specified type has (issue #4664)
  Scenario: `key` can be used to find all attribute types that the specified type uses as key
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


  Scenario: `has` matches types that have the specified attribute type, even if they use it as a key
    Given graql define
      """
      define
      breed sub attribute, value string;
      dog sub entity, key breed;
      cat sub entity, has breed;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x has breed; get;
      """
    And concept identifiers are
      |     | check | value |
      | DOG | label | dog   |
      | CAT | label | cat   |
    Then uniquely identify answer concepts
      | x   |
      | DOG |
      | CAT |


  Scenario: `relates` matches relation types where the specified role can be played
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


  Scenario: `relates` with `as` matches relation types where the specified role is played as a subrole of the specified super-role
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


  Scenario: `relates` does not match relation types that block the specified roleplayer with `as`
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
      |     | check | value            |
      | FRE | label | friendship       |
    Then uniquely identify answer concepts
      | x   |
      | FRE |


  Scenario: `relates` can be used to retrieve all the roles of a relation type
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


  ##########
  # THINGS #
  ##########

  Scenario: `isa` matches things of the specified type and all its subtypes
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


  Scenario: `isa!` only matches things of the specified type, and does not match subtypes
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
    Then uniquely identify answer concepts
      | x   |
      | WRI |


  Scenario: `id` matches the instance with the specified internal id
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
      match $x id <answer.x.id>; get;
      """


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
      some-entity sub entity, plays player, key ref;
      symmetric sub relation, relates player, key ref;
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
      some-entity sub entity, plays player, key ref;
      symmetric sub relation, relates player, key ref;
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


  ##############
  # ATTRIBUTES #
  ##############

  Scenario Outline: `<type>` attributes can be matched by value
    Given graql define
      """
      define <attr> sub attribute, value <type>, has ref 0;
      """
    Given the integrity is validated
    Given graql insert
      """
      insert $n <value> isa <attr>;
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


  Scenario: `contains` matches strings that contain the specified substring
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


  Scenario: `contains` performs a case-insensitive match
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


  Scenario: `like` matches strings that match the specified regex
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


  #######################
  # ATTRIBUTE OWNERSHIP #
  #######################

  Scenario: `has` can be used to match things that own any instance of the specified attribute
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


  Scenario: by using the `attribute` meta label, `has` can be used to match things that own any type of attribute with a specified value
    Given graql define
      """
      define
      shoe-size sub attribute, value long;
      person has shoe-size;
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


  Scenario: when an attribute instance is fully specified, `has` matches its owners
    Given graql insert
      """
      insert
      $x isa person, has name "John", has ref 0;
      $y isa person, has name "John", has ref 1;
      $z isa person, has name "Not John", has ref 2;
      $w isa person, has ref 3;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x has name "John"; get;
      """
    And concept identifiers are
      |     | check | value |
      | JH1 | key   | ref:0 |
      | JH2 | key   | ref:1 |
    Then uniquely identify answer concepts
      | x   |
      | JH1 |
      | JH2 |


  Scenario: `has` with an instance fully specified matches all its owners, even if they own other instances of the same attribute
    Given graql define
      """
      define
      lucky-number sub attribute, value long;
      person has lucky-number;
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


  ##############################
  # ATTRIBUTE VALUE COMPARISON #
  ##############################

  Scenario: when two things each own an attribute with the same value, and those attributes have different types, they will match by equality, but not by ownership
    Given graql define
      """
      define
      start-date sub attribute, value datetime;
      graduation-date sub attribute, value datetime;
      person has graduation-date;
      employment has start-date;
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


  Scenario: `has $attr > $x` matches owners of any instance `$y` of `$attr` where `$y > $x`
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


  Scenario: `has $attr < $x` matches owners of any instance `$y` of `$attr` where `$y < $x`
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


  Scenario: `has $attr !== $x` matches owners of any instance `$y` of `$attr` where `$y !== $x`
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


  Scenario: `has $attr > $x` matches owners of any instance `$y` of `$attr` where `$y > $x` even if they also own instance `$z` where `$z < $x`
    Given graql define
      """
      define
      lucky-number sub attribute, value long;
      person has lucky-number;
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


  Scenario: a negation matches if the negated block has no matches
    Given graql insert
      """
      insert
      $x isa person, has name "Jeff", has ref 0;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match
        $x isa person;
        not {
          $e (employee: $x) isa employment;
        };
      get;
      """
    And concept identifiers are
      |     | check | value |
      | JEF | key   | ref:0 |
    Then uniquely identify answer concepts
      | x   |
      | JEF |


  Scenario: a negation does not match if the negated block has any matches
    Given graql insert
      """
      insert
      $x isa person, has name "Jeff", has ref 0;
      $c isa company, has name "Amazon", has ref 1;
      $e (employee: $x, employer: $c) isa employment, has ref 2;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match
        $x isa person;
        not {
          $e (employee: $x) isa employment;
        };
      get;
      """
    Then answer size is: 0
