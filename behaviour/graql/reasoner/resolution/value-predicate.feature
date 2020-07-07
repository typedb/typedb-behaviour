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

  Background: Setup base KBs

    Given connection has been opened
    Given connection delete all keyspaces
    Given connection open sessions for keyspaces:
      | completion |
      | test       |
    Given graql define
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
    Given graql define
      """
      define
      lucky-number sub attribute, value long;
      person has lucky-number;
      rule-1337 sub rule, when { $x isa person; }, then { $x has lucky-number $n; $n 1337; };
      rule-1667 sub rule, when { $x isa person; }, then { $x has lucky-number $n; $n 1667; };
      rule-1997 sub rule, when { $x isa person; }, then { $x has lucky-number $n; $n 1997; };
      """
    Given graql insert
      """
      insert
      $x isa person, has ref 0;
      $y isa person, has ref 1;
      """
    When reference kb is completed
    Then for graql query
      """
      match
        $x isa person, has lucky-number $n;
        $n <op> 1667;
      get;
      """
    Then answer count is correct
    And answers resolution is correct
    And answer count is: <answer-count>
    Then test keyspace is complete

  Examples:
    | op | answer-count |
    | >  | 2            |
    | >= | 4            |
    | <  | 2            |
    | <= | 4            |
    | == | 2            |
    | != | 4            |


  Scenario Outline: when both sides of a `<op>` comparison are inferred attributes, all answers satisfy the predicate
    Given graql define
      """
      define
      lucky-number sub attribute, value long;
      person has lucky-number;
      rule-1337 sub rule, when { $x isa person; }, then { $x has lucky-number $n; $n 1337; };
      rule-1667 sub rule, when { $x isa person; }, then { $x has lucky-number $n; $n 1667; };
      """
    Given graql insert
      """
      insert
      $x isa person, has ref 0;
      $y isa person, has ref 1;
      """
    When reference kb is completed
    Then for graql query
      """
      match
        $x isa person, has lucky-number $m;
        $y isa person, has lucky-number $n;
        $m <op> $n;
      get;
      """
    Then answer count is correct
    And answers resolution is correct
    And answer count is: <answer-count>
    Then test keyspace is complete

    Examples:
      | op | answer-count |
      | >  | 1            |
      | >= | 3            |
      | <  | 1            |
      | <= | 3            |
      | == | 2            |
      | != | 2            |
