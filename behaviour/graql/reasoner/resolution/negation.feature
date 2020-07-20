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

Feature: Negation Resolution

  Background: Set up keyspaces for resolution testing

    Given connection has been opened
    Given connection delete all keyspaces
    Given connection open sessions for keyspaces:
      | materialised |
      | reasoned     |
    Given materialised keyspace is named: materialised
    Given reasoned keyspace is named: reasoned


  Scenario: a rule can be triggered based on not having a particular attribute
    Given for each session, graql define
      """
      define
      person sub entity, has age, has name;
      age sub attribute, value long;
      name sub attribute, value string;
      not-ten sub rule,
      when {
        not { $x has age 10; };
      } then {
        $x has name "Not Ten";
      }
      """
    Given for each session, graql insert
      """
      insert
      $x isa person, has age 10;
      $y isa person, has age 20;
      """
    When materialised keyspace is completed
    Then for graql query
      """
      match $x has name "Not Ten", has age 20; get;
      """
    Then all answers are correct in reasoned keyspace
    Then answer size in reasoned keyspace is: 1
    Then for graql query
      """
      match $x has name "Not Ten", has age 10; get;
      """
    Then answer size in reasoned keyspace is: 0
    Then materialised and reasoned keyspaces are the same size
