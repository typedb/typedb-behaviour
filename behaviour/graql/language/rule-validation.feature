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

Feature: Graql Rule Validation

  Background: Initialise a session and transaction for each scenario
    Given connection has been opened
    Given connection delete all keyspaces
    Given connection open sessions for keyspaces:
      | test_rule_validation |
    Given transaction is initialised


  Scenario: when defining a rule to generate new entities from existing ones, an error is thrown
    Given graql define
      """
      define

      baseEntity sub entity;
      derivedEntity sub entity;
      """
    Given the integrity is validated
    Then graql define throws
      """
      define
      rule-1 sub rule,
      when {
          $x isa baseEntity;
      },
      then {
          $y isa derivedEntity;
      };
      """
    Then the integrity is validated


  Scenario: when defining a rule to generate new entities from existing relations, an error is thrown
    Given graql define
      """
      define

      baseEntity sub entity,
          plays role1,
          plays role2;

      derivedEntity sub entity,
          plays role1,
          plays role2;

      baseRelation sub relation,
          relates role1,
          relates role2;
      """
    Given the integrity is validated
    Then graql define throws
      """
      define
      rule-1 sub rule,
      when {
          (role1:$x, role2:$y) isa baseRelation;
          (role1:$y, role2:$z) isa baseRelation;
      },
      then {
          $u isa derivedEntity;
      };
      """
    Then the integrity is validated


  Scenario: when defining a rule to generate new relations from existing ones, an error is thrown
    Given graql define
      """
      define

      baseEntity sub entity,
          plays role1,
          plays role2;

      baseRelation sub relation,
          relates role1,
          relates role2;
      """
    Given the integrity is validated
    Then graql define throws
      """
      define
      rule-1 sub rule,
      when {
          (role1:$x, role2:$y) isa baseRelation;
          (role1:$y, role2:$z) isa baseRelation;
      },
      then {
          $u (role1:$x, role2:$z) isa baseRelation;
      };
      """
    Then the integrity is validated
