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
        plays employee,
        has name,
        key ref;
      company sub entity,
        plays employer,
        has name,
        key ref;
      employment sub relation,
        relates employee,
        relates employer,
        key ref;
      name sub attribute, value string;
      ref sub attribute, value long;
      """
    Given the integrity is validated

  Scenario: `type` matches only the specified type, and does not match subtypes

  Scenario: `sub` matches the specified type and all its subtypes

  Scenario: `sub!` matches the specified type and its direct subtypes

  # TODO: ensure there are types that don't have the specified attribute, as well, so we know it's a precise match
  Scenario: `has` matches types that have the specified attribute type

  Scenario: `has` matches types that have only a subtype of the specified attribute type (?)

  Scenario: `plays` matches types that can play the specified role

  Scenario: `key` matches types that have the specified attribute type as a key (?)

  Scenario: `has` matches types that have the specified attribute type, even if they use it as a key (?)

  Scenario: `relates` matches types that have the specified roleplayer, regardless of their role

  Scenario: `relates` with `as` matches only types that have the specified roleplayer playing the specified role

  Scenario: `relates` matches/does not match types that block the specified roleplayer with `as` (?)

  Scenario: `isa` matches things of the specified type and all its subtypes

  Scenario: `isa!` matches only things of the specified type, and does not match subtypes

  # TODO: Create 5 scenarios in place of this one, one for each attribute value type
  Scenario: attributes can be matched by value
    Given graql define
      """
      define name sub attribute, value string;
      """
    Given the integrity is validated
    Given graql insert
      """
      insert $n "John" isa name;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $a "John"; get;
      """
    Then concept identifiers are
      |      | check | value     |
      | JOHN | value | name:John |
    Then uniquely identify answer concepts
      | a    |
      | JOHN |


  Scenario: when an attribute type is specified but no value, `has` matches things that have any instance of the specified attribute (?)

  Scenario: when a value is specified but no type, `has` matches things that have any kind of attribute with that value

  Scenario: when an attribute instance is fully specified, `has` matches all of its owners

  Scenario: `has` with an instance fully specified matches all of its owners, even if they own other instances of the same attribute

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
    Then concept identifiers are
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
    Then concept identifiers are
      |     | check | value                         |
      | PIR | value | name:Pirates of the Caribbean |
      | MRB | value | name:Mr. Bean                 |
    Then uniquely identify answer concepts
      | x   |
      | PIR |
      | MRB |


  Scenario: `like` matches strings that match the specified regex

  Scenario: `has $attr > $x` matches owners of any instance `$y` of `$attr` where `$y > $x`

  Scenario: `has $attr < $x` matches owners of any instance `$y` of `$attr` where `$y < $x`

  Scenario: `has $attr !== $x` matches owners of any instance `$y` of `$attr` where `$y !== $x`

  Scenario: `has $attr > $x` matches owners of any instance `$y` of `$attr` where `$y > $x` even if they also own instance `$z` where `$z < $x`

  Scenario: `id` matches the instance with the specified internal id

  Scenario: disjunctions return the union of composing query statements

  Scenario: a negation matches if the negated block has no matches

  Scenario: a negation does not match if the negated block has any matches

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
    Then concept identifiers are
      |      | check | value |
      | REF0 | key   | ref:0 |
      | REF1 | key   | ref:1 |
      | REF2 | key   | ref:2 |
    Then uniquely identify answer concepts
      | x    | r    |
      | REF0 | REF2 |
    Then get answers of graql query
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
    Then concept identifiers are
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
    Then concept identifiers are
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
    Then concept identifiers are
      |      | check | value |
      | REF0 | key   | ref:0 |
      | REF1 | key   | ref:1 |
    Then uniquely identify answer concepts
      | x    | r    |
      | REF0 | REF1 |
