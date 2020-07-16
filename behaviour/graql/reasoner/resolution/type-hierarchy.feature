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

Feature: Type Hierarchy Resolution

  Background: Set up keyspaces for resolution testing

    Given connection has been opened
    Given connection delete all keyspaces
    Given connection open sessions for keyspaces:
      | materialised |
      | reasoned     |
    Given materialised keyspace is named: materialised
    Given reasoned keyspace is named: reasoned


  Scenario: when matching different roles to those that are actually inferred, no answers are returned
    Given for each session, graql define
      """
      define

      entity1 sub entity,
          plays role1,
          plays role2,
          plays role3;

      relation1 sub relation,
          relates role1,
          relates role2;

      relation2 sub relation,
          relates role1,
          relates role2,
          relates role3;

      rule-1 sub rule,
      when {
          (role1:$x, role2:$y) isa relation1;
      },
      then {
          (role1:$x, role3:$y) isa relation2;
      };
      """
    Given for each session, graql insert
      """
      insert
      $x isa entity1;
      $y isa entity1;
      (role1:$x, role2:$y) isa relation1;
      """
    When materialised keyspace is completed
    Then for graql query
      """
      match (role2:$x, role3:$y) isa relation2; get;
      """
    Then answer size in reasoned keyspace is: 0
    Then materialised and reasoned keyspaces are the same size


  Scenario: when a relation with sub-roles is inferred, it can be retrieved by matching their super-roles
    Given for each session, graql define
      """
      define

      role1 sub role;
      role2 sub role;
      role3 sub role1;
      role4 sub role2;

      entity1 sub entity,
          plays role1,
          plays role2,
          plays role3,
          plays role4;

      relation1 sub relation,
          relates role1,
          relates role2;

      relation2 sub relation,
          relates role1,
          relates role2;

      relation3 sub relation2,
          relates role3,
          relates role4;

      rule-1 sub rule,
      when {
          (role1:$x, role2:$y) isa relation1;
      },
      then {
          (role3:$x, role4:$y) isa relation3;
      };
      """
    Given for each session, graql insert
      """
      insert
      $x isa entity1;
      $y isa entity1;
      (role1:$x, role2:$y) isa relation1;
      """
    When materialised keyspace is completed
    Then for graql query
      """
      match (role1:$x, role2:$y) isa relation2; get;
      """
    Then all answers are correct in reasoned keyspace
    Then answer size in reasoned keyspace is: 1
    Then materialised and reasoned keyspaces are the same size


  Scenario: subtypes trigger rules based on their parents; parent types don't trigger rules based on their children
    Given for each session, graql define
      """
      define

      entity1 sub entity,
          has name,
          plays role1,
          plays role2;

      subEntity1 sub entity1;

      relation1 sub relation,
          relates role1,
          relates role2;

      relation2 sub relation,
          relates role1,
          relates role2;

      name sub attribute, value string;

      rule-1 sub rule,
      when {
          $x isa subEntity1;
          $y isa entity1;
          (role1:$x, role2:$y) isa relation2;
      },
      then {
          (role1:$x, role2:$y) isa relation1;
      };
      """
    Given for each session, graql insert
      """
      insert
      $x isa subEntity1, has name "a";
      $y isa entity1, has name "b";
      $z isa entity1, has name "a";
      $w isa entity1, has name "b2";
      $v isa subEntity1, has name "a";

      (role1:$x, role2:$z) isa relation2;     # subEntity1 - entity1    -> satisfies rule
      (role1:$y, role2:$z) isa relation2;     # entity1 - entity1       -> doesn't satisfy rule
      (role1:$x, role2:$v) isa relation2;     # subEntity1 - subEntity1 -> satisfies rule
      (role1:$y, role2:$v) isa relation2;     # entity1 - subEntity1    -> doesn't satisfy rule
      """
    When materialised keyspace is completed
    Then for graql query
      """
      match
        $x isa entity1;
        $y isa entity1;
        (role1: $x, role2: $y) isa relation1;
      get;
      """
    Then all answers are correct in reasoned keyspace
    # Answers are (role1:$x, role2:$z) and (role1:$x, role2:$v)
    Then answer size in reasoned keyspace is: 2
    Then for graql query
      """
      match
        $x isa entity1;
        $y isa entity1;
        (role1: $x, role2: $y) isa relation1;
        $y has name 'a';
      get;
      """
    Then all answers are correct in reasoned keyspace
    Then answer size in reasoned keyspace is: 2
    Then for graql query
      """
      match
        $x isa entity1;
        $y isa subEntity1;
        (role1: $x, role2: $y) isa relation1;
      get;
      """
    Then all answers are correct in reasoned keyspace
    # Answer is (role1:$x, role2:$v) ONLY
    Then answer size in reasoned keyspace is: 1
    Then for graql query
      """
      match
        $x isa entity1;
        $y isa subEntity1;
        (role1: $x, role2: $y) isa relation1;
        $y has name 'a';
      get;
      """
    Then all answers are correct in reasoned keyspace
    Then answer size in reasoned keyspace is: 1
    Then for graql query
      """
      match
        $x isa subEntity1;
        $y isa entity1;
        (role1: $x, role2: $y) isa relation1;
      get;
      """
    Then all answers are correct in reasoned keyspace
    # Answers are (role1:$x, role2:$z) and (role1:$x, role2:$v)
    Then answer size in reasoned keyspace is: 2
    Then for graql query
      """
      match
        $x isa subEntity1;
        $y isa entity1;
        (role1: $x, role2: $y) isa relation1;
        $y has name 'a';
      get;
      """
    Then all answers are correct in reasoned keyspace
    Then answer size in reasoned keyspace is: 2
    Then materialised and reasoned keyspaces are the same size


  Scenario: when a rule is recursive, its inferences respect type hierarchies
    Given for each session, graql define
      """
      define

      entity1 sub entity,
          has name,
          plays role1,
          plays role2;

      subEntity1 sub entity1;

      relation1 sub relation,
          relates role1,
          relates role2;

      relation2 sub relation,
          relates role1,
          relates role2;

      name sub attribute, value string;

      rule-1 sub rule,
      when {
          $x isa subEntity1;
          $y isa entity1;
          (role1:$x, role2:$y) isa relation2;
      },
      then {
          (role1:$x, role2:$y) isa relation1;
      };

      rule-2 sub rule,
      when {
          $x isa entity1;
          $y isa subEntity1;
          (role1:$x, role2:$y) isa relation2;
      },
      then {
          (role1:$x, role2:$y) isa relation2;
      };
      """
    Given for each session, graql insert
      """
      insert
      $x isa subEntity1, has name "a";
      $y isa entity1, has name "b";
      $z isa entity1, has name "a";
      $w isa entity1, has name "b2";
      $v isa subEntity1, has name "a";

      (role1:$x, role2:$z) isa relation2;     # subEntity1 - entity1    -> satisfies rule
      (role1:$y, role2:$z) isa relation2;     # entity1 - entity1       -> doesn't satisfy rule
      (role1:$x, role2:$v) isa relation2;     # subEntity1 - subEntity1 -> satisfies rule
      (role1:$y, role2:$v) isa relation2;     # entity1 - subEntity1    -> doesn't satisfy rule
      """
    When materialised keyspace is completed
    Then for graql query
      """
      match
        $x isa entity1;
        $y isa entity1;
        (role1: $x, role2: $y) isa relation1;
      get;
      """
    Then all answers are correct in reasoned keyspace
    # Answers are (role1:$x, role2:$z) and (role1:$x, role2:$v)
    Then answer size in reasoned keyspace is: 2
    Then for graql query
      """
      match
        $x isa entity1;
        $y isa entity1;
        (role1: $x, role2: $y) isa relation1;
        $y has name 'a';
      get;
      """
    Then all answers are correct in reasoned keyspace
    Then answer size in reasoned keyspace is: 2
    Then for graql query
      """
      match
        $x isa entity1;
        $y isa subEntity1;
        (role1: $x, role2: $y) isa relation1;
      get;
      """
    Then all answers are correct in reasoned keyspace
    # Answer is (role1:$x, role2:$v) ONLY
    Then answer size in reasoned keyspace is: 1
    Then for graql query
      """
      match
        $x isa entity1;
        $y isa subEntity1;
        (role1: $x, role2: $y) isa relation1;
        $y has name 'a';
      get;
      """
    Then all answers are correct in reasoned keyspace
    Then answer size in reasoned keyspace is: 1
    Then for graql query
      """
      match
        $x isa subEntity1;
        $y isa entity1;
        (role1: $x, role2: $y) isa relation1;
      get;
      """
    Then all answers are correct in reasoned keyspace
    # Answers are (role1:$x, role2:$z) and (role1:$x, role2:$v)
    Then answer size in reasoned keyspace is: 2
    Then for graql query
      """
      match
        $x isa subEntity1;
        $y isa entity1;
        (role1: $x, role2: $y) isa relation1;
        $y has name 'a';
      get;
      """
    Then all answers are correct in reasoned keyspace
    Then answer size in reasoned keyspace is: 2
    Then materialised and reasoned keyspaces are the same size


  Scenario: querying for a super-relation gives the same answer as querying for its inferred sub-relation
    Given for each session, graql define
      """
      define

      entity1 sub entity,
          plays role1,
          plays role2;

      relation1 sub relation,
          relates role1,
          relates role2;

      sub-relation1 sub relation1,
          relates role1,
          relates role2;

      relation2 sub relation,
          relates role1,
          relates role2;

      rule-1 sub rule,
      when {
          (role1:$x, role2:$y) isa relation2;
      },
      then {
          (role1:$x, role2:$y) isa sub-relation1;
      };
      """
    Given for each session, graql insert
      """
      insert
      $x isa entity1;
      $y isa entity1;
      (role1:$x, role2:$y) isa relation2;
      """
    When materialised keyspace is completed
    Then for graql query
      """
      match
        (role1: $x, role2: $y) isa relation1;
      get;
      """
    Then all answers are correct in reasoned keyspace
    Then answer size in reasoned keyspace is: 1
    Then for graql query
      """
      match
        (role1: $x, role2: $y) isa relation1;
        (role1: $x, role2: $y) isa sub-relation1;
      get;
      """
    Then all answers are correct in reasoned keyspace
    Then answer size in reasoned keyspace is: 1
    Then materialised and reasoned keyspaces are the same size


  # TODO: re-enable all steps once attribute re-attachment is resolvable
  Scenario: querying for a super-entity gives the same answer as querying for its inferred sub-entity
    Given for each session, graql define
      """
      define

      #Entities

      baseEntity sub entity;
      subEntity sub baseEntity;
      anotherBaseEntity sub entity;

      #Rules

      rule-1 sub rule,
      when {
          $x isa anotherBaseEntity;
      },
      then {
          $x isa subEntity;
      };
      """
    Given for each session, graql insert
      """
      insert
      $x isa anotherBaseEntity;
      """
#    When materialised keyspace is completed
    Then for graql query
      """
      match
        $x isa baseEntity;
      get;
      """
#    Then all answers are correct in reasoned keyspace
    Then answer size in reasoned keyspace is: 1
    Then for graql query
      """
      match
        $x isa baseEntity;
        $x isa subEntity;
      get;
      """
#    Then all answers are correct in reasoned keyspace
    Then answer size in reasoned keyspace is: 1
#    Then materialised and reasoned keyspaces are the same size
