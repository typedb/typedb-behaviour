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
    Then no answers are resolved in reasoned keyspace
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
