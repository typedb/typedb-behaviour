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

Feature: Value Predicate Resolution

  Background: Set up keyspaces for resolution testing

    Given connection has been opened
    Given connection delete all keyspaces
    Given connection open sessions for keyspaces:
      | materialised |
      | reasoned     |
    Given materialised keyspace is named: materialised
    Given reasoned keyspace is named: reasoned
    Given transaction is initialised
    Given for each session, graql define
      """
      define

      person sub entity,
          plays leader,
          plays team-member,
          has string-attribute,
          has unrelated-attribute,
          has sub-string-attribute,
          has age,
          has is-old,
          key ref;

      tortoise sub entity,
          has age,
          has is-old,
          key ref;

      soft-drink sub entity,
          has retailer,
          key ref;

      team sub relation,
          relates leader,
          relates team-member,
          has string-attribute,
          key ref;

      string-attribute sub attribute, value string;
      retailer sub attribute, value string;
      age sub attribute, value long;
      is-old sub attribute, value boolean;
      sub-string-attribute sub string-attribute;
      unrelated-attribute sub attribute, value string;
      ref sub attribute, value long;
      """


  Scenario Outline: when querying inferred attributes with `<op>`, the answers matching the predicate are returned
    Given for each session, graql define
      """
      define
      lucky-number sub attribute, value long;
      person has lucky-number;
      rule-1337 sub rule, when { $x isa person; }, then { $x has lucky-number $n; $n 1337; };
      rule-1667 sub rule, when { $x isa person; }, then { $x has lucky-number $n; $n 1667; };
      rule-1997 sub rule, when { $x isa person; }, then { $x has lucky-number $n; $n 1997; };
      """
    Given for each session, graql insert
      """
      insert
      $x isa person, has ref 0;
      $y isa person, has ref 1;
      """
    When materialised keyspace is completed
    Then for graql query
      """
      match
        $x isa person, has lucky-number $n;
        $n <op> 1667;
      get;
      """
    Then in reasoned keyspace, all answers are correct
    Then in reasoned keyspace, answer size is: <answer-size>
    Then materialised and reasoned keyspaces are the same size

  Examples:
    | op | answer-size |
    | >  | 2           |
    | >= | 4           |
    | <  | 2           |
    | <= | 4           |
    | == | 2           |
    | != | 4           |


  Scenario Outline: when both sides of a `<op>` comparison are inferred attributes, all answers satisfy the predicate
    Given for each session, graql define
      """
      define
      lucky-number sub attribute, value long;
      person has lucky-number;
      rule-1337 sub rule, when { $x isa person; }, then { $x has lucky-number $n; $n 1337; };
      rule-1667 sub rule, when { $x isa person; }, then { $x has lucky-number $n; $n 1667; };
      """
    Given for each session, graql insert
      """
      insert
      $x isa person, has ref 0;
      $y isa person, has ref 1;
      """
    When materialised keyspace is completed
    Then for graql query
      """
      match
        $x isa person, has lucky-number $m;
        $y isa person, has lucky-number $n;
        $m <op> $n;
      get;
      """
    Then in reasoned keyspace, all answers are correct
    Then in reasoned keyspace, answer size is: <answer-size>
    Then materialised and reasoned keyspaces are the same size

    Examples:
      | op | answer-size |
      | >  | 1           |
      | >= | 3           |
      | <  | 1           |
      | <= | 3           |
      | == | 2           |
      | != | 2           |
