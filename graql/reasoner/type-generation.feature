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

Feature: Type Generation Resolution

  Background: Set up databases for resolution testing

    Given connection has been opened
    Given connection delete all databases
    Given connection open sessions for databases:
      | materialised |
      | reasoned     |
    Given materialised database is named: materialised
    Given reasoned database is named: reasoned


  # TODO: re-enable all steps once attribute re-attachment is resolvable
  Scenario: additional types for entities can be derived using 'isa'
    Given for each session, graql define
      """
      define
      baseEntity sub entity;
      derivedEntity sub entity;
      rule-1 sub rule,
      when {
        $x isa baseEntity;
      },
      then {
        $x isa derivedEntity;
      };
      """
    Given for each session, graql insert
      """
      insert
      $x isa baseEntity;
      """
#    When materialised database is completed
    Then for graql query
      """
      match $x isa derivedEntity; get;
      """
#    Then all answers are correct in reasoned database
    Then answer size in reasoned database is: 1
    Then for graql query
      """
      match $x isa $type; get;
      """
#    Then all answers are correct in reasoned database
    Then answer size in reasoned database is: 4
#    Then materialised and reasoned databases are the same size


  # TODO: re-enable all steps once attribute re-attachment is resolvable
  Scenario: additional types for entities can be derived using direct 'isa!'
    Given for each session, graql define
      """
      define

      baseEntity sub entity;
      subEntity sub baseEntity;
      subSubEntity sub subEntity;

      derivedEntity sub entity;
      directDerivedEntity sub derivedEntity;

      isaRule sub rule,
      when {
        $x isa subEntity;
      },
      then {
        $x isa derivedEntity;
      };

      directIsaRule sub rule,
      when {
        $x isa! subEntity;
      },
      then {
        $x isa directDerivedEntity;
      };
      """
    Given for each session, graql insert
      """
      insert
      $x isa baseEntity;
      $y isa subEntity;    # -> derivedEntity, directDerivedEntity
      $z isa subSubEntity; # -> derivedEntity
      """
#    When materialised database is completed
    Then for graql query
      """
      match $x isa derivedEntity; get;
      """
#    Then all answers are correct in reasoned database
    Then answer size in reasoned database is: 2
    Then for graql query
      """
      match $x isa! derivedEntity; get;
      """
#    Then all answers are correct in reasoned database
    Then answer size in reasoned database is: 2
    Then for graql query
      """
      match $x isa directDerivedEntity; get;
      """
#    Then all answers are correct in reasoned database
    Then answer size in reasoned database is: 1
#    Then materialised and reasoned databases are the same size


  # TODO: re-enable all steps once attribute re-attachment is resolvable
  Scenario: additional types for entities can be derived via relations that they play roles in
    Given for each session, graql define
      """
      define

      baseEntity sub entity,
          plays baseRelation:role1,
          plays baseRelation:role2;

      derivedEntity sub entity,
          plays baseRelation:role1,
          plays baseRelation:role2;

      baseRelation sub relation,
          relates role1,
          relates role2;

      rule-1 sub rule,
      when {
          (role1:$x, role2:$y) isa baseRelation;
          (role1:$y, role2:$x) isa baseRelation;
      },
      then {
          $x isa derivedEntity;
      };
      """
    Given for each session, graql insert
      """
      insert
      $x isa baseEntity;
      $y isa baseEntity;
      (role1:$x, role2:$y) isa baseRelation;
      (role1:$y, role2:$x) isa baseRelation;
      """
#    When materialised database is completed
    Then for graql query
      """
      match $x isa baseEntity; get;
      """
#    Then all answers are correct in reasoned database
    Then answer size in reasoned database is: 2
    Then for graql query
      """
      match
        $x isa derivedEntity;
      get;
      """
#    Then all answers are correct in reasoned database
    Then answer size in reasoned database is: 2
#    Then materialised and reasoned databases are the same size


  @ignore
  # TODO: re-enable when grakn#5824 is fixed (matching a variable with two types)
  Scenario: additional types for entities can be derived via attributes that they own
    Given for each session, graql define
      """
      define

      baseEntity sub entity,
          owns baseAttribute;

      derivedEntity sub entity,
          owns baseAttribute;

      baseAttribute sub attribute, value string;

      rule1
      when {
          $x has baseAttribute "derived";
      },
      then {
          $x isa derivedEntity;
      };
      """
    Given for each session, graql insert
      """
      insert
      $x isa baseEntity, has baseAttribute "derived";
      """
#    When materialised database is completed
    Then for graql query
      """
      match $x isa baseEntity; get;
      """
#    Then all answers are correct in reasoned database
    Then answer size in reasoned database is: 1
    Then for graql query
      """
      match $x isa baseAttribute; get;
      """
#    Then all answers are correct in reasoned database
    Then answer size in reasoned database is: 1
    Then for graql query
      """
      match
        $x isa derivedEntity;
        $x isa baseEntity;
      get;
      """
#    Then all answers are correct in reasoned database
    Then answer size in reasoned database is: 1
#    Then materialised and reasoned databases are the same size


  # TODO: re-enable all steps once attribute re-attachment is resolvable
  Scenario: additional types for relations can be derived using direct 'isa!'
    Given for each session, graql define
      """
      define

      baseEntity sub entity,
          plays baseRelation:baseRole,
          plays derivedRelation:derivedRelationRole;

      baseRelation sub relation,
          relates baseRole;
      subRelation sub baseRelation,
          relates baseRole;
      subSubRelation sub subRelation,
          relates baseRole;

      derivedRelation sub relation,
          relates derivedRelationRole;
      directDerivedRelation sub derivedRelation,
          relates derivedRelationRole;

      relationRule sub rule,
      when {
          ($x) isa subRelation;
      },
      then {
          (derivedRelationRole: $x) isa derivedRelation;
      };

      directRelationRule sub rule,
      when {
          ($x) isa! subRelation;
      },
      then {
          (derivedRelationRole: $x) isa directDerivedRelation;
      };
      """
    Given for each session, graql insert
      """
      insert
      $x isa baseEntity;
      $y isa baseEntity;
      $z isa baseEntity;

      (baseRole: $x) isa baseRelation;
      (baseRole: $y) isa subRelation;
      (baseRole: $z) isa subSubRelation;
      """
#    When materialised database is completed
    Then for graql query
      """
      match ($x) isa derivedRelation; get;
      """
#    Then all answers are correct in reasoned database
    Then answer size in reasoned database is: 2
    Then for graql query
      """
      match ($x) isa! derivedRelation; get;
      """
#    Then all answers are correct in reasoned database
    Then answer size in reasoned database is: 2
    Then for graql query
      """
      match ($x) isa directDerivedRelation; get;
      """
#    Then all answers are correct in reasoned database
    Then answer size in reasoned database is: 1
#    Then materialised and reasoned databases are the same size
