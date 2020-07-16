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

Feature: Concept Inequality Resolution

  Background: Set up keyspaces for resolution testing

    Given connection has been opened
    Given connection delete all keyspaces
    Given connection open sessions for keyspaces:
      | materialised |
      | reasoned     |
    Given materialised keyspace is named: materialised
    Given reasoned keyspace is named: reasoned
    Given for each session, graql define
      """
      define

      entity1 sub entity,
          has name,
          plays role1,
          plays role2;

      relation1 sub relation,
          relates role1,
          relates role2;

      name sub attribute, value string;

      transitivity sub rule,
      when {
          (role1:$x, role2:$y) isa relation1;
          (role1:$y, role2:$z) isa relation1;
      },
      then {
          (role1:$x, role2:$z) isa relation1;
      };
      """
    Given for each session, graql insert
      """
      insert

      $a isa entity1, has name 'a';
      $b isa entity1, has name 'b';
      $c isa entity1, has name 'c';

      (role1: $a, role2: $b) isa relation1;
      (role1: $b, role2: $a) isa relation1;
      (role1: $b, role2: $c) isa relation1;
      (role1: $c, role2: $b) isa relation1;
      """


  # TODO: re-enable all steps when 3-hop transitivity is resolvable
  Scenario: a rule can be applied based on concept inequality
    Given for each session, graql define
      """
      define

      state sub entity,
          plays related-state,
          has name;

      achieved sub relation,
          relates related-state;

      prior sub relation,
          relates related-state;

      holds sub relation,
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
#    When materialised keyspace is completed
    Then for graql query
      """
      match (related-state: $s) isa holds; get;
      """
#    Then all answers are correct in reasoned keyspace
    Then answer size in reasoned keyspace is: 1
    Then for graql query
      """
      match
        $s isa state, has name 's2';
        (related-state: $s) isa holds;
      get;
      """
#    Then all answers are correct in reasoned keyspace
    Then answer size in reasoned keyspace is: 1
#    Then materialised and reasoned keyspaces are the same size


  Scenario: inferred binary relations can be filtered by concept inequality of their roleplayers
#    When materialised keyspace is completed
    Given for graql query
      """
      match
        (role1: $x, role2: $y) isa relation1;
      get;
      """
#    Given all answers are correct in reasoned keyspace
    # materialised: [ab, ba, bc, cb]
    # inferred: [aa, ac, bb, ca, cc]
    Given answer size in reasoned keyspace is: 9
    Then for graql query
      """
      match
        (role1: $x, role2: $y) isa relation1;
        $x != $y;
      get;
      """
#    Then all answers are correct in reasoned keyspace
    # materialised: [ab, ba, bc, cb]
    # inferred: [ac, ca]
    Then answer size in reasoned keyspace is: 6
    # verify that the answer pairs to the previous query have distinct names within each pair
    Then for graql query
      """
      match
        (role1: $x, role2: $y) isa relation1;
        $x != $y;
        $x has name $nx;
        $y has name $ny;
        $nx !== $ny;
      get $x, $y;
      """
#    Then all answers are correct in reasoned keyspace
    Then answer size in reasoned keyspace is: 6
#    Then materialised and reasoned keyspaces are the same size


  Scenario: inferred binary relations can be filtered by inequality to a specific concept
#    When materialised keyspace is completed
    Then for graql query
      """
      match
        (role1: $x, role2: $y) isa relation1;
        $x != $y;
        $y has name 'c';
      get;
      """
#    Then all answers are correct in reasoned keyspace
    Then answer size in reasoned keyspace is: 2
    # verify answers are [ac, bc]
    Then for graql query
      """
      match
        (role1: $x, role2: $y) isa relation1;
        $x != $y;
        $y has name 'c';
        {$x has name 'a';} or {$x has name 'b';};
      get;
      """
#    Then all answers are correct in reasoned keyspace
    Then answer size in reasoned keyspace is: 2
#    Then materialised and reasoned keyspaces are the same size


  Scenario: pairs of inferred relations can be filtered by inequality of players in the same role
#    When materialised keyspace is completed
    Then for graql query
      """
      match
        (role1: $x, role2: $y) isa relation1;
        (role1: $x, role2: $z) isa relation1;
        $y != $z;
      get;
      """
#    Then all answers are correct in reasoned keyspace
    # [aab, aac, aba, abc, aca, acb,
    #  bab, bac, bba, bbc, bca, bcb,
    #  cab, cac, cba, cbc, cca, ccb]
    Then answer size in reasoned keyspace is: 18
    # verify that $y and $z always have distinct names
    Then for graql query
      """
      match
        (role1: $x, role2: $y) isa relation1;
        (role1: $x, role2: $z) isa relation1;
        $y != $z;
        $y has name $ny;
        $z has name $nz;
        $ny !== $nz;
      get $x, $y, $z;
      """
#    Then all answers are correct in reasoned keyspace
    Then answer size in reasoned keyspace is: 18
#    Then materialised and reasoned keyspaces are the same size


  Scenario: pairs of inferred relations can be filtered by inequality of players in different roles
#    When materialised keyspace is completed
    Then for graql query
      """
      match
        (role1: $x, role2: $y) isa relation1;
        (role1: $y, role2: $z) isa relation1;
        $x != $z;
      get;
      """
#    Then all answers are correct in reasoned keyspace
    Then answer size in reasoned keyspace is: 18
    # verify that $y and $z always have distinct names
    Then for graql query
      """
      match
        (role1: $x, role2: $y) isa relation1;
        (role1: $x, role2: $z) isa relation1;
        $x != $z;
        $x has name $nx;
        $z has name $nz;
        $nx !== $nz;
      get $x, $y, $z;
      """
#    Then all answers are correct in reasoned keyspace
    Then answer size in reasoned keyspace is: 18
#    Then materialised and reasoned keyspaces are the same size
