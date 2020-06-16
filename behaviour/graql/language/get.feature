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
Feature: Graql Get Query

  Background: Open connection and create a simple extensible schema
    Given connection has been opened
    Given connection delete all keyspaces
    Given connection open sessions for keyspaces:
      | test_get |
    Given transaction is initialised
    Given graql define
      """
      define
      person sub entity,
        plays friend,
        has name,
        has age,
        key ref;
      friendship sub relation,
        relates friend,
        key ref;
      name sub attribute, value string;
      age sub attribute, value long;
      ref sub attribute, value long;
      """
    Given the integrity is validated

  Scenario: match-get returns an empty answer if there are no matches

  Scenario: Disjunctions return the union of composing query statements

  Scenario: Restricting variables in get removes variable from answer maps


  ########
  # SORT #
  ########

  Scenario Outline: the answers of a get can be sorted by an attribute of type `<type>`
    Given graql define
      """
      define
      <attr> sub attribute, value <type>, key ref;
      """
    Given the integrity is validated
    Given graql insert
      """
      insert
      $a <val1> isa <attr>, has ref 0;
      $b <val2> isa <attr>, has ref 1;
      $c <val3> isa <attr>, has ref 2;
      $d <val4> isa <attr>, has ref 3;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match
        $x isa <attr>;
      get;
      sort $x asc;
      """
    Then concept identifiers are
      |      | check | value |
      | VAL1 | key   | ref:0 |
      | VAL2 | key   | ref:1 |
      | VAL3 | key   | ref:2 |
      | VAL4 | key   | ref:3 |
    Then order of answer concepts is
      | x    |
      | VAL4 |
      | VAL2 |
      | VAL3 |
      | VAL1 |

  Examples:
    | attr          | type     | val4       | val2             | val3             | val1       |
    | colour        | string   | "blue"     | "green"          | "red"            | "yellow"   |
    | score         | long     | -38        | -4               | 18               | 152        |
    | correlation   | double   | -29.7      | -0.9             | 0.01             | 100.0      |
    | date-of-birth | datetime | 1970-01-01 | 1999-12-31T23:00 | 1999-12-31T23:01 | 2020-02-29 |


  Scenario: sort order can be ascending or descending
    Given graql insert
      """
      insert
      $a isa person, has name "Gary", has ref 0;
      $b isa person, has name "Jemima", has ref 1;
      $c isa person, has name "Frederick", has ref 2;
      $d isa person, has name "Brenda", has ref 3;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match
        $x isa person, has name $y;
      get;
      sort $y asc;
      """
    Then concept identifiers are
      |      | check | value          |
      | GAR  | key   | ref:0          |
      | JEM  | key   | ref:1          |
      | FRE  | key   | ref:2          |
      | BRE  | key   | ref:3          |
      | nGAR | value | name:Gary      |
      | nJEM | value | name:Jemima    |
      | nFRE | value | name:Frederick |
      | nBRE | value | name:Brenda    |
    Then order of answer concepts is
      | x   | y    |
      | BRE | nBRE |
      | FRE | nFRE |
      | GAR | nGAR |
      | JEM | nJEM |
    Then get answers of graql query
      """
      match
        $x isa person, has name $y;
      get;
      sort $y desc;
      """
    Then order of answer concepts is
      | x   | y    |
      | JEM | nJEM |
      | GAR | nGAR |
      | FRE | nFRE |
      | BRE | nBRE |


  Scenario: the default sort order is ascending
    Given graql insert
      """
      insert
      $a isa person, has name "Gary", has ref 0;
      $b isa person, has name "Jemima", has ref 1;
      $c isa person, has name "Frederick", has ref 2;
      $d isa person, has name "Brenda", has ref 3;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match
        $x isa person, has name $y;
      get;
      """
    Then concept identifiers are
      |      | check | value          |
      | GAR  | key   | ref:0          |
      | JEM  | key   | ref:1          |
      | FRE  | key   | ref:2          |
      | BRE  | key   | ref:3          |
      | nGAR | value | name:Gary      |
      | nJEM | value | name:Jemima    |
      | nFRE | value | name:Frederick |
      | nBRE | value | name:Brenda    |
    Then order of answer concepts is
      | x   | y    |
      | BRE | nBRE |
      | FRE | nFRE |
      | GAR | nGAR |
      | JEM | nJEM |


  Scenario: a sorted result set can be limited to a specific size
    Given graql insert
      """
      insert
      $a isa person, has name "Gary", has ref 0;
      $b isa person, has name "Jemima", has ref 1;
      $c isa person, has name "Frederick", has ref 2;
      $d isa person, has name "Brenda", has ref 3;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match
        $x isa person, has name $y;
      get;
      sort $y asc;
      limit 3;
      """
    Then concept identifiers are
      |      | check | value          |
      | GAR  | key   | ref:0          |
      | FRE  | key   | ref:2          |
      | BRE  | key   | ref:3          |
      | nGAR | value | name:Gary      |
      | nFRE | value | name:Frederick |
      | nBRE | value | name:Brenda    |
    Then order of answer concepts is
      | x   | y    |
      | BRE | nBRE |
      | FRE | nFRE |
      | GAR | nGAR |


  Scenario: sorted results can be retrieved starting from a specific offset
    Given graql insert
      """
      insert
      $a isa person, has name "Gary", has ref 0;
      $b isa person, has name "Jemima", has ref 1;
      $c isa person, has name "Frederick", has ref 2;
      $d isa person, has name "Brenda", has ref 3;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match
        $x isa person, has name $y;
      get;
      sort $y asc;
      offset 2;
      """
    Then concept identifiers are
      |      | check | value          |
      | GAR  | key   | ref:0          |
      | JEM  | key   | ref:1          |
      | nGAR | value | name:Gary      |
      | nJEM | value | name:Jemima    |
    Then order of answer concepts is
      | x   | y    |
      | GAR | nGAR |
      | JEM | nJEM |


  Scenario: `offset` and `limit` can be used together to restrict the answer set
    Given graql insert
      """
      insert
      $a isa person, has name "Gary", has ref 0;
      $b isa person, has name "Jemima", has ref 1;
      $c isa person, has name "Frederick", has ref 2;
      $d isa person, has name "Brenda", has ref 3;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match
        $x isa person, has name $y;
      get;
      sort $y asc;
      offset 1;
      limit 2;
      """
    Then concept identifiers are
      |      | check | value          |
      | GAR  | key   | ref:0          |
      | FRE  | key   | ref:2          |
      | nGAR | value | name:Gary      |
      | nFRE | value | name:Frederick |
    Then order of answer concepts is
      | x   | y    |
      | FRE | nFRE |
      | GAR | nGAR |


  Scenario: when the answer size limit is 0, an empty answer set is returned
    Given graql insert
      """
      insert
      $a isa person, has name "Gary", has ref 0;
      $b isa person, has name "Jemima", has ref 1;
      $c isa person, has name "Frederick", has ref 2;
      $d isa person, has name "Brenda", has ref 3;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match
        $x isa person, has name $y;
      get;
      sort $y asc;
      limit 0;
      """
    Then answer size is: 0


  Scenario: when the offset is outside the bounds of the matched answer set, an empty answer set is returned
    Given graql insert
      """
      insert
      $a isa person, has name "Gary", has ref 0;
      $b isa person, has name "Jemima", has ref 1;
      $c isa person, has name "Frederick", has ref 2;
      $d isa person, has name "Brenda", has ref 3;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match
        $x isa person, has name $y;
      get;
      sort $y asc;
      offset 5;
      """
    Then answer size is: 0


  Scenario: string sorting is case-insensitive
    When get answers of graql query
      """
      insert
      $a "Bond" isa name;
      $b "James Bond" isa name;
      $c "007" isa name;
      $d "agent" isa name;
      $e "secret agent" isa name;
      """
    When the integrity is validated
    Then concept identifiers are
      |     | check | value             |
      | BON | value | name:Bond         |
      | JAM | value | name:James Bond   |
      | 007 | value | name:007          |
      | AGE | value | name:agent        |
      | SEC | value | name:secret agent |
    Then get answers of graql query
      """
      match
        $x isa name;
      get;
      sort $x asc;
      """
    Then order of answer concepts is
      | x   |
      | 007 |
      | AGE |
      | BON |
      | JAM |
      | SEC |


  Scenario: sort is able to correctly handle duplicates in the value set
    Given graql insert
      """
      insert
      $a isa person, has age 2, has ref 0;
      $b isa person, has age 6, has ref 1;
      $c isa person, has age 12, has ref 2;
      $d isa person, has age 6, has ref 3;
      $e isa person, has age 2, has ref 4;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match
        $x isa person, has age $y;
      get;
      sort $y asc;
      limit 2;
      """
    Then concept identifiers are
      |      | check | value |
      | A2P1 | key   | ref:0 |
      | A2P2 | key   | ref:4 |
      | AGE2 | value | age:2 |
    Then uniquely identify answer concepts
      | x    | y    |
      | A2P1 | AGE2 |
      | A2P2 | AGE2 |
    Then get answers of graql query
      """
      match
        $x isa person, has age $y;
      get;
      sort $y asc;
      offset 2;
      limit 2;
      """
    Then concept identifiers are
      |      | check | value |
      | A6P1 | key   | ref:1 |
      | A6P2 | key   | ref:3 |
      | AGE6 | value | age:6 |
    Then uniquely identify answer concepts
      | x    | y    |
      | A6P1 | AGE6 |
      | A6P2 | AGE6 |


  #############
  # AGGREGATE #
  #############

  Scenario: `count` returns the total number of answers
    Given graql insert
      """
      insert
      $p1 isa person, has name "Klaus", has ref 0;
      $p2 isa person, has name "Kristina", has ref 1;
      $p3 isa person, has name "Karen", has ref 2;
      $f (friend: $p1, friend: $p2) isa friendship, has ref 3;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match
        $x isa person;
        $y isa name;
        $f isa friendship;
      get;
      """
    Then answer size is: 9
    Then get answers of graql query
      """
      match
        $x isa person;
        $y isa name;
        $f isa friendship;
      get;
      count;
      """
    Then aggregate value is: 9
    Then get answers of graql query
      """
      match
        $x isa person;
        $y isa name;
        $f (friend: $x) isa friendship;
      get;
      """
    Then answer size is: 6
    Then get answers of graql query
      """
      match
        $x isa person;
        $y isa name;
        $f (friend: $x) isa friendship;
      get;
      count;
      """
    Then aggregate value is: 6


  #########
  # GROUP #
  #########

  Scenario: answers can be grouped by a variable contained in the answer set
    Given graql insert
      """
      insert
      $p1 isa person, has name "Violet", has ref 0;
      $p2 isa person, has name "Rupert", has ref 1;
      $p3 isa person, has name "Bernard", has ref 2;
      $p4 isa person, has name "Colin", has ref 3;
      $f (friend: $p1, friend: $p2, friend: $p3, friend: $p4) isa friendship, has ref 4;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match ($x, $y) isa friendship; get;
      """
    Then concept identifiers are
      |     | check | value |
      | VIO | key   | ref:0 |
      | RUP | key   | ref:1 |
      | BER | key   | ref:2 |
      | COL | key   | ref:3 |
    Then uniquely identify answer concepts
      | x   | y   |
      | VIO | RUP |
      | VIO | BER |
      | VIO | COL |
      | RUP | VIO |
      | RUP | BER |
      | RUP | COL |
      | BER | VIO |
      | BER | RUP |
      | BER | COL |
      | COL | VIO |
      | COL | RUP |
      | COL | BER |
    When get answers of graql query
      """
      match ($x, $y) isa friendship;
      get;
      group $x;
      """
    Then group identifiers are
      |      | owner |
      | gVIO | VIO   |
      | gRUP | RUP   |
      | gBER | BER   |
      | gCOL | COL   |
    Then answer groups are
      | group | x   | y   |
      | gVIO  | VIO | RUP |
      | gVIO  | VIO | BER |
      | gVIO  | VIO | COL |
      | gRUP  | RUP | VIO |
      | gRUP  | RUP | BER |
      | gRUP  | RUP | COL |
      | gBER  | BER | VIO |
      | gBER  | BER | RUP |
      | gBER  | BER | COL |
      | gCOL  | COL | VIO |
      | gCOL  | COL | RUP |
      | gCOL  | COL | BER |


  Scenario: answer groups can be counted
    Given graql insert
      """
      insert
      $p1 isa person, has name "Violet", has ref 0;
      $p2 isa person, has name "Rupert", has ref 1;
      $p3 isa person, has name "Bernard", has ref 2;
      $p4 isa person, has name "Colin", has ref 3;
      $f (friend: $p1, friend: $p2, friend: $p3, friend: $p4) isa friendship, has ref 4;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x isa person; get;
      """
    Then concept identifiers are
      |     | check | value |
      | VIO | key   | ref:0 |
      | RUP | key   | ref:1 |
      | BER | key   | ref:2 |
      | COL | key   | ref:3 |
    When get answers of graql query
      """
      match ($x, $y) isa friendship;
      get;
      group $x;
      count;
      """
    Then group identifiers are
      |      | owner |
      | gVIO | VIO   |
      | gRUP | RUP   |
      | gBER | BER   |
      | gCOL | COL   |
    Then aggregate group answers are
      | group | value |
      | gVIO  | 3     |
      | gRUP  | 3     |
      | gBER  | 3     |
      | gCOL  | 3     |
