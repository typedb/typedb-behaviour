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

# TODO: re-enable all steps in file when 3-hop transitivity is resolvable
Feature: Concept Inequality Resolution

  Background: Set up databases for resolution testing

    Given connection has been opened
    Given connection delete all databases
    Given connection open sessions for databases:
      | materialised |
      | reasoned     |
    Given materialised database is named: materialised
    Given reasoned database is named: reasoned
    Given for each session, graql define
      """
      define

      person sub entity,
          owns name;

      ball sub entity,
          owns name,
          plays ball1,
          plays ball2;

      # Represents a selection of balls from a bag, with replacement after each selection
      selection sub relation,
          relates ball1,
          relates ball2;

      name sub attribute, value string;

      transitivity sub rule,
      when {
          (ball1:$x, ball2:$y) isa selection;
          (ball1:$y, ball2:$z) isa selection;
      },
      then {
          (ball1:$x, ball2:$z) isa selection;
      };
      """
    Given for each session, graql insert
      """
      insert

      $a isa ball, has name 'a';
      $b isa ball, has name 'b';
      $c isa ball, has name 'c';

      # selection is effectively reflexive, symmetric and transitive
      (ball1: $a, ball2: $b) isa selection;
      (ball1: $b, ball2: $a) isa selection;
      (ball1: $b, ball2: $c) isa selection;
      (ball1: $c, ball2: $b) isa selection;
      """


  # TODO: re-enable all steps when 3-hop transitivity is resolvable
  Scenario: a rule can be applied based on concept inequality
    Given for each session, graql define
      """
      define

      state sub entity,
          plays related-state,
          owns name;

      transition sub relation,
        relates related-state;

      achieved sub transition,
          relates related-state;

      prior sub transition,
          relates related-state;

      holds sub transition,
          relates related-state;

      state-rule sub rule,
      when {
          $st isa state;
          (related-state: $st) isa achieved;
          (related-state: $st2) isa prior;
          $st != $st2;
      },
      then {
          (related-state: $st) isa holds;
      };
      """
    Given for each session, graql insert
      """
      insert

      $s1 isa state, has name 's1';
      $s2 isa state, has name 's2';

      (related-state: $s1) isa prior;
      (related-state: $s1) isa achieved;
      (related-state: $s2) isa achieved;
      """
#    When materialised database is completed
    Then for graql query
      """
      match (related-state: $s) isa holds; get;
      """
#    Then all answers are correct in reasoned database
    Then answer size in reasoned database is: 1
    Then answer set is equivalent for graql query
      """
      match $s isa state, has name 's2'; get;
      """
#    Then materialised and reasoned databases are the same size


  Scenario: inferred binary relations can be filtered by concept inequality of their roleplayers
#    When materialised database is completed
    Given for graql query
      """
      match
        (ball1: $x, ball2: $y) isa selection;
      get;
      """
#    Given all answers are correct in reasoned database
    # materialised: [ab, ba, bc, cb]
    # inferred: [aa, ac, bb, ca, cc]
    Given answer size in reasoned database is: 9
    Then for graql query
      """
      match
        (ball1: $x, ball2: $y) isa selection;
        $x != $y;
      get;
      """
#    Then all answers are correct in reasoned database
    # materialised: [ab, ba, bc, cb]
    # inferred: [ac, ca]
    Then answer size in reasoned database is: 6
    # verify that the answer pairs to the previous query have distinct names within each pair
    Then for graql query
      """
      match
        (ball1: $x, ball2: $y) isa selection;
        $x != $y;
        $x has name $nx;
        $y has name $ny;
        $nx !== $ny;
      get $x, $y;
      """
#    Then all answers are correct in reasoned database
    Then answer size in reasoned database is: 6
#    Then materialised and reasoned databases are the same size


  Scenario: inferred binary relations can be filtered by inequality to a specific concept
#    When materialised database is completed
    Then for graql query
      """
      match
        (ball1: $x, ball2: $y) isa selection;
        $x != $y;
        $y has name 'c';
      get;
      """
#    Then all answers are correct in reasoned database
    Then answer size in reasoned database is: 2
    # verify answers are [ac, bc]
    Then for graql query
      """
      match
        (ball1: $x, ball2: $y) isa selection;
        $x != $y;
        $y has name 'c';
        {$x has name 'a';} or {$x has name 'b';};
      get;
      """
#    Then all answers are correct in reasoned database
    Then answer size in reasoned database is: 2
#    Then materialised and reasoned databases are the same size


  Scenario: pairs of inferred relations can be filtered by inequality of players in the same role

  Tests a scenario in which the neq predicate binds free variables of two equivalent relations.
  Corresponds to the following pattern:

  x
  / \
  /   \
  v     v
  y  !=   z

#    When materialised database is completed
    Then for graql query
      """
      match
        (ball1: $x, ball2: $y) isa selection;
        (ball1: $x, ball2: $z) isa selection;
        $y != $z;
      get;
      """
#    Then all answers are correct in reasoned database
    # [aab, aac, aba, abc, aca, acb,
    #  bab, bac, bba, bbc, bca, bcb,
    #  cab, cac, cba, cbc, cca, ccb]
    Then answer size in reasoned database is: 18
    # verify that $y and $z always have distinct names
    Then for graql query
      """
      match
        (ball1: $x, ball2: $y) isa selection;
        (ball1: $x, ball2: $z) isa selection;
        $y != $z;
        $y has name $ny;
        $z has name $nz;
        $ny !== $nz;
      get $x, $y, $z;
      """
#    Then all answers are correct in reasoned database
    Then answer size in reasoned database is: 18
#    Then materialised and reasoned databases are the same size




  Scenario: pairs of inferred relations can be filtered by inequality of players in different roles

  Tests a scenario in which the neq predicate binds free variables
  of two non-equivalent relations. Corresponds to the following pattern:

  y
  ^ \
  /   \
  /     v
  x  !=   z

#    When materialised database is completed
    Then for graql query
      """
      match
        (ball1: $x, ball2: $y) isa selection;
        (ball1: $y, ball2: $z) isa selection;
        $x != $z;
      get;
      """
#    Then all answers are correct in reasoned database
    Then answer size in reasoned database is: 18
    # verify that $y and $z always have distinct names
    Then for graql query
      """
      match
        (ball1: $x, ball2: $y) isa selection;
        (ball1: $x, ball2: $z) isa selection;
        $x != $z;
        $x has name $nx;
        $z has name $nz;
        $nx !== $nz;
      get $x, $y, $z;
      """
#    Then all answers are correct in reasoned database
    Then answer size in reasoned database is: 18
#    Then materialised and reasoned databases are the same size


  Scenario: inequality predicates can operate independently against multiple pairs of relations in the same query

  Tests a scenario in which multiple neq predicates are present but bind at most a single var in a relation.
  Corresponds to the following pattern:

  y    !=    z1
  ^        ^
  \      /
  \    /
  x[a]
  /    \
  /      \
  v        v
  y2    !=    z2

#    When materialised database is completed
    Given for graql query
      """
      match
        (ball1: $x, ball2: $y1) isa selection;
        (ball1: $x, ball2: $z1) isa selection;
        (ball1: $x, ball2: $y2) isa selection;
        (ball1: $x, ball2: $z2) isa selection;
      get;
      """
#    Given all answers are correct in reasoned database
    # For each of the [3] values of $x, there are 3^4 = 81 choices for {$y1, $z1, $y2, $z2}, for a total of 243
    Given answer size in reasoned database is: 243
    Then for graql query
      """
      match
        (ball1: $x, ball2: $y1) isa selection;
        (ball1: $x, ball2: $z1) isa selection;
        (ball1: $x, ball2: $y2) isa selection;
        (ball1: $x, ball2: $z2) isa selection;

        $y1 != $z1;
        $y2 != $z2;
      get;
      """
#    Then all answers are correct in reasoned database
    # Each neq predicate reduces the answer size by 1/3, cutting it to 162, then 108
    Then answer size in reasoned database is: 108
    # verify that $y1 and $z1 - as well as $y2 and $z2 - always have distinct names
    Then for graql query
      """
      match
        (ball1: $x, ball2: $y1) isa selection;
        (ball1: $x, ball2: $z1) isa selection;
        (ball1: $x, ball2: $y2) isa selection;
        (ball1: $x, ball2: $z2) isa selection;
        $y1 != $z1;
        $y2 != $z2;
        $y1 has name $ny1;
        $z1 has name $nz1;
        $y2 has name $ny2;
        $z2 has name $nz2;
        $ny1 !== $nz1;
        $ny2 !== $nz2;
      get $x, $y1, $z1, $y2, $z2;
      """
#    Then all answers are correct in reasoned database
    Then answer size in reasoned database is: 108
#    Then materialised and reasoned databases are the same size


  Scenario: inequality predicates can operate independently against multiple roleplayers in the same relation

  Tests a scenario in which a single relation has both variables bound with two different neq predicates.
  Corresponds to the following pattern:

  x[a]  - != - >  z1
  |
  |
  v
  y     - != - >  z2

#    When materialised database is completed
    Given for graql query
      """
      match
        (ball1: $x, ball2: $y) isa selection;
        (ball1: $x, ball2: $z1) isa selection;
        (ball1: $y, ball2: $z2) isa selection;
      get;
      """
#    Given all answers are correct in reasoned database
    # There are 3^4 possible choices for the set {$x, $y, $z1, $z2}, for a total of 81
    Given answer size in reasoned database is: 81
    Then for graql query
      """
      match
        (ball1: $x, ball2: $y) isa selection;
        (ball1: $x, ball2: $z1) isa selection;
        (ball1: $x, ball2: $z2) isa selection;

        $x != $z1;
        $y != $z2;
      get;
      """
#    Then all answers are correct in reasoned database
    # Each neq predicate reduces the answer size by 1/3, cutting it to 54, then 36
    Then answer size in reasoned database is: 36
    # verify that $y1 and $z1 - as well as $y2 and $z2 - always have distinct names
    Then for graql query
      """
      match
        (ball1: $x, ball2: $y) isa selection;
        (ball1: $x, ball2: $z1) isa selection;
        (ball1: $x, ball2: $z2) isa selection;
        $x != $z1;
        $y != $z2;
        $x has name $nx;
        $z1 has name $nz1;
        $y has name $ny;
        $z2 has name $nz2;
        $nx !== $nz1;
        $ny !== $nz2;
      get $x, $y, $z1, $z2;
      """
#    Then all answers are correct in reasoned database
    Then answer size in reasoned database is: 36
#    Then materialised and reasoned databases are the same size


  @ignore
  # TODO: re-enable once grakn#5821 is fixed (in some answers, $typeof_ax is 'base-attribute' which is incorrect)
  # TODO: re-enable all steps once implicit attribute variables are resolvable
  # TODO: migrate to concept-inequality.feature
  Scenario: when restricting concept types of a pair of inferred attributes with '!=', the answers have distinct types
    Given for each session, graql define
      """
      define
      soft-drink sub entity,
        owns name,
        owns retailer;
      base-attribute sub attribute, value string, abstract;
      string-attribute sub base-attribute;
      name sub base-attribute;
      retailer sub base-attribute;
      person owns string-attribute;

      tesco-sells-all-soft-drinks sub rule,
      when {
        $x isa soft-drink;
      },
      then {
        $x has retailer 'Tesco';
      };
      """
    Given for each session, graql insert
      """
      insert
      $x isa person, has string-attribute "Tesco";
      $y isa soft-drink, has name "Tesco";
      """
    When materialised database is completed
    Then for graql query
      """
      match
        $x has base-attribute $ax;
        $y has base-attribute $ay;
        $ax isa! $typeof_ax;
        $ay isa! $typeof_ay;
        $typeof_ax != $typeof_ay;
      get;
      """
    Then all answers are correct in reasoned database
    # x   | ax  | y   | ay  |
    # PER | STA | SOF | NAM |
    # PER | STA | SOF | RET |
    # SOF | NAM | PER | STA |
    # SOF | RET | PER | STA |
    # SOF | NAM | SOF | STA |
    # SOF | STA | SOF | NAM |
    Then answer size in reasoned database is: 6
    Then materialised and reasoned databases are the same size

  @ignore
  # TODO: re-enable once grakn#5821 is fixed
  # TODO: re-enable all steps once implicit attribute variables are resolvable
  # TODO: migrate to concept-inequality.feature
  Scenario: inferred attribute matches can be simultaneously restricted by both concept type and attribute value
    Given for each session, graql define
      """
      define
      soft-drink sub entity,
        owns name,
        owns retailer;
      base-attribute sub attribute, value string, abstract;
      string-attribute sub base-attribute;
      retailer sub base-attribute;
      person owns string-attribute;

      transfer-string-attribute-to-other-people sub rule,
      when {
        $x isa person, has string-attribute $r1;
        $y isa person;
      },
      then {
        $y has string-attribute $r1;
      };

      tesco-sells-all-soft-drinks sub rule,
      when {
        $x isa soft-drink;
      },
      then {
        $x has retailer 'Tesco';
      };

      if-ocado-exists-it-sells-all-soft-drinks sub rule,
      when {
        $x isa retailer;
        $x == 'Ocado';
        $y isa soft-drink;
      },
      then {
        $y has retailer $x;
      };
      """
    Given for each session, graql insert
      """
      insert
      $w isa person, has string-attribute "Ocado";
      $x isa person, has string-attribute "Tesco";
      $y isa soft-drink, has name "Sprite";
      $z "Ocado" isa retailer;
      """
    When materialised database is completed
    Then for graql query
      """
      match
        $x has base-attribute $value;
        $y has base-attribute $unwantedValue;
        $value !== $unwantedValue;
        $unwantedValue "Ocado";
        $value isa! $type;
        $unwantedValue isa! $type;
        $type != $unwantedType;
        $unwantedType type string-attribute;
      get $x, $value, $type;
      """
    Then all answers are correct in reasoned database
    # x      | value | type     |
    # Sprite | Tesco | retailer |
    Then answer size in reasoned database is: 1
#    Then materialised and reasoned databases are the same size
