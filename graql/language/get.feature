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

#noinspection CucumberUndefinedStep
Feature: Graql Get Clause

  Background: Open connection and create a simple extensible schema
    Given connection has been opened
    Given connection delete all databases
    Given connection does not have any database
    Given connection create database: grakn
    Given connection open schema session for database: grakn
    Given session opens transaction of type: write
    Given the integrity is validated
    Given graql define
      """
      define
      person sub entity,
        plays friendship:friend,
        plays employment:employee,
        owns name,
        owns age,
        owns ref @key;
      company sub entity,
        plays employment:employer,
        owns name,
        owns ref @key;
      friendship sub relation,
        relates friend,
        owns ref @key;
      employment sub relation,
        relates employee,
        relates employer,
        owns ref @key;
      name sub attribute, value string;
      age sub attribute, value long;
      ref sub attribute, value long;
      """
    Given transaction commits
    Given the integrity is validated
    Given connection close all sessions
    Given connection open data session for database: grakn
    Given session opens transaction of type: write


  #############
  # VARIABLES #
  #############

  Scenario: 'get' can be used to restrict the set of variables that appear in an answer set
    Given graql insert
      """
      insert
      $x "Lisa" isa name;
      $y 16 isa age;
      $z isa person, has name $x, has age $y, has ref 0;
      """
    Given transaction commits
    Given the integrity is validated
    Given session opens transaction of type: read
    And concept identifiers are
      |     | check | value     |
      | PER | key   | ref:0     |
      | LIS | value | name:Lisa |
      | SIX | value | age:16    |
    When get answers of graql query
      """
      match
        $z isa person, has name $x, has age $y;
      get $z, $x;
      """
    Then uniquely identify answer concepts
      | z   | x   |
      | PER | LIS |


  Scenario: when a 'get' has unbound variables, an error is thrown
    Then graql match; throws exception
      """
      match $x isa person; get $y;
      """
    Then the integrity is validated


  ########
  # SORT #
  ########

  Scenario Outline: the answers of a match can be sorted by an attribute of type '<type>'
    Given connection close all sessions
    Given connection open schema session for database: grakn
    Given session opens transaction of type: write
    Given graql define
      """
      define
      <attr> sub attribute, value <type>, owns ref @key;
      """
    Given transaction commits
    Given the integrity is validated
    Given connection close all sessions
    Given connection open data session for database: grakn
    Given session opens transaction of type: write
    Given graql insert
      """
      insert
      $a <val1> isa <attr>, has ref 0;
      $b <val2> isa <attr>, has ref 1;
      $c <val3> isa <attr>, has ref 2;
      $d <val4> isa <attr>, has ref 3;
      """
    Given transaction commits
    Given the integrity is validated
    Given session opens transaction of type: read
    When get answers of graql query
      """
      match $x isa <attr>;
      sort $x asc;
      """
    And concept identifiers are
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
    Given transaction commits
    Given the integrity is validated
    Given session opens transaction of type: read
    When get answers of graql query
      """
      match $x isa person, has name $y;
      sort $y asc;
      """
    And concept identifiers are
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
    When get answers of graql query
      """
      match $x isa person, has name $y;
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
    Given transaction commits
    Given the integrity is validated
    Given session opens transaction of type: read
    When get answers of graql query
      """
      match $x isa person, has name $y;
      sort $y;
      """
    And concept identifiers are
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
    Given transaction commits
    Given the integrity is validated
    Given session opens transaction of type: read
    When get answers of graql query
      """
      match $x isa person, has name $y;
      sort $y asc;
      limit 3;
      """
    And concept identifiers are
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
    Given transaction commits
    Given the integrity is validated
    Given session opens transaction of type: read
    When get answers of graql query
      """
      match $x isa person, has name $y;
      sort $y asc;
      offset 2;
      """
    And concept identifiers are
      |      | check | value       |
      | GAR  | key   | ref:0       |
      | JEM  | key   | ref:1       |
      | nGAR | value | name:Gary   |
      | nJEM | value | name:Jemima |
    Then order of answer concepts is
      | x   | y    |
      | GAR | nGAR |
      | JEM | nJEM |


  Scenario: 'offset' and 'limit' can be used together to restrict the answer set
    Given graql insert
      """
      insert
      $a isa person, has name "Gary", has ref 0;
      $b isa person, has name "Jemima", has ref 1;
      $c isa person, has name "Frederick", has ref 2;
      $d isa person, has name "Brenda", has ref 3;
      """
    Given transaction commits
    Given the integrity is validated
    Given session opens transaction of type: read
    When get answers of graql query
      """
      match $x isa person, has name $y;
      sort $y asc;
      offset 1;
      limit 2;
      """
    And concept identifiers are
      |      | check | value          |
      | GAR  | key   | ref:0          |
      | FRE  | key   | ref:2          |
      | nGAR | value | name:Gary      |
      | nFRE | value | name:Frederick |
    Then order of answer concepts is
      | x   | y    |
      | FRE | nFRE |
      | GAR | nGAR |


  Scenario: when the answer size is limited to 0, an empty answer set is returned
    Given graql insert
      """
      insert
      $a isa person, has name "Gary", has ref 0;
      $b isa person, has name "Jemima", has ref 1;
      $c isa person, has name "Frederick", has ref 2;
      $d isa person, has name "Brenda", has ref 3;
      """
    Given transaction commits
    Given the integrity is validated
    Given session opens transaction of type: read
    When get answers of graql query
      """
      match $x isa person, has name $y;
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
    Given transaction commits
    Given the integrity is validated
    Given session opens transaction of type: read
    When get answers of graql query
      """
      match $x isa person, has name $y;
      sort $y asc;
      offset 5;
      """
    Then answer size is: 0


  Scenario: string sorting is case-insensitive
    Given graql insert
      """
      insert
      $a "Bond" isa name;
      $b "James Bond" isa name;
      $c "007" isa name;
      $d "agent" isa name;
      $e "secret agent" isa name;
      """
    Given transaction commits
    Given the integrity is validated
    Given session opens transaction of type: read
    When concept identifiers are
      |     | check | value             |
      | BON | value | name:Bond         |
      | JAM | value | name:James Bond   |
      | 007 | value | name:007          |
      | AGE | value | name:agent        |
      | SEC | value | name:secret agent |
    Then get answers of graql query
      """
      match $x isa name;
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
    Given transaction commits
    Given the integrity is validated
    Given session opens transaction of type: read
    When get answers of graql query
      """
      match $x isa person, has age $y;
      sort $y asc;
      limit 2;
      """
    And concept identifiers are
      |      | check | value |
      | A2P1 | key   | ref:0 |
      | A2P2 | key   | ref:4 |
      | AGE2 | value | age:2 |
    Then uniquely identify answer concepts
      | x    | y    |
      | A2P1 | AGE2 |
      | A2P2 | AGE2 |
    When get answers of graql query
      """
      match $x isa person, has age $y;
      sort $y asc;
      offset 2;
      limit 2;
      """
    And concept identifiers are
      |      | check | value |
      | A6P1 | key   | ref:1 |
      | A6P2 | key   | ref:3 |
      | AGE6 | value | age:6 |
    Then uniquely identify answer concepts
      | x    | y    |
      | A6P1 | AGE6 |
      | A6P2 | AGE6 |


  Scenario: when sorting by a variable not contained in the answer set, an error is thrown
    Given graql insert
      """
      insert
      $a isa person, has age 2, has ref 0;
      $b isa person, has age 6, has ref 1;
      """
    Given transaction commits
    Given the integrity is validated
    Given session opens transaction of type: read
    Then graql match; throws exception
      """
      match
        $x isa person, has age $y;
      get $x;
      sort $y asc;
      limit 2;
      """


  #############
  # AGGREGATE #
  #############

  Scenario: 'count' returns the total number of answers
    Given graql insert
      """
      insert
      $p1 isa person, has name "Klaus", has ref 0;
      $p2 isa person, has name "Kristina", has ref 1;
      $p3 isa person, has name "Karen", has ref 2;
      $f (friend: $p1, friend: $p2) isa friendship, has ref 3;
      """
    Given transaction commits
    Given the integrity is validated
    Given session opens transaction of type: read
    When get answers of graql query
      """
      match
        $x isa person;
        $y isa name;
        $f isa friendship;
      """
    Then answer size is: 9
    When get answers of graql query
      """
      match
        $x isa person;
        $y isa name;
        $f isa friendship;
      count;
      """
    Then aggregate value is: 9
    When get answers of graql query
      """
      match
        $x isa person;
        $y isa name;
        $f (friend: $x) isa friendship;
      """
    Then answer size is: 6
    When get answers of graql query
      """
      match
        $x isa person;
        $y isa name;
        $f (friend: $x) isa friendship;
      count;
      """
    Then aggregate value is: 6


  Scenario: the 'count' of an empty answer set is zero
    When get answers of graql query
      """
      match $x isa person, has name "Voldemort";
      count;
      """
    Then aggregate value is: 0


  Scenario Outline: the <agg_type> of an answer set of '<type>' values can be retrieved
    Given connection close all sessions
    Given connection open schema session for database: grakn
    Given session opens transaction of type: write
    Given graql define
      """
      define
      <attr> sub attribute, value <type>;
      person owns <attr>;
      """
    Given transaction commits
    Given the integrity is validated
    Given connection close all sessions
    Given connection open data session for database: grakn
    Given session opens transaction of type: write
    Given graql insert
      """
      insert
      $p1 isa person, has <attr> <val1>, has ref 0;
      $p2 isa person, has <attr> <val2>, has ref 1;
      $p3 isa person, has <attr> <val3>, has ref 2;
      """
    Given transaction commits
    Given the integrity is validated
    Given session opens transaction of type: read
    When get answers of graql query
      """
      match $x isa person, has <attr> $y;
      <agg_type> $y;
      """
    Then aggregate value is: <agg_val>

    Examples:
      | attr   | type   | val1 | val2 | val3 | agg_type | agg_val |
      | age    | long   | 6    | 30   | 14   | sum      | 50      |
      | age    | long   | 6    | 30   | 14   | max      | 30      |
      | age    | long   | 6    | 30   | 14   | min      | 6       |
      | age    | long   | 6    | 30   | 14   | mean     | 16.6667 |
      | age    | long   | 6    | 30   | 14   | median   | 14      |
      | weight | double | 61.8 | 86.5 | 24.8 | sum      | 173.1   |
      | weight | double | 61.8 | 86.5 | 24.8 | max      | 86.5    |
      | weight | double | 61.8 | 86.5 | 24.8 | min      | 24.8    |
      | weight | double | 61.8 | 86.5 | 24.8 | mean     | 57.7    |
      | weight | double | 61.8 | 86.5 | 24.8 | median   | 61.8    |


  Scenario: the sample standard deviation can be retrieved for an answer set of 'double' values
    Given connection close all sessions
    Given connection open schema session for database: grakn
    Given session opens transaction of type: write
    Given graql define
      """
      define
      weight sub attribute, value double;
      person owns weight;
      """
    Given transaction commits
    Given the integrity is validated
    Given connection close all sessions
    Given connection open data session for database: grakn
    Given session opens transaction of type: write
    Given graql insert
      """
      insert
      $p1 isa person, has weight 61.8, has ref 0;
      $p2 isa person, has weight 86.5, has ref 1;
      $p3 isa person, has weight 24.8, has ref 2;
      """
    Given transaction commits
    Given the integrity is validated
    Given session opens transaction of type: read
    When get answers of graql query
      """
      match $x isa person, has weight $y;
      std $y;
      """
    # Note: This is the sample standard deviation, NOT the population standard deviation
    Then aggregate value is: 31.0537


  Scenario: restricting variables with 'get' does not affect the result of a 'sum'
    Given graql insert
      """
      insert
      $p1 isa person, has name "Jeff", has age 30, has ref 0;
      $p2 isa person, has name "Yoko", has age 20, has ref 1;
      $p3 isa person, has name "Miles", has age 15, has ref 2;
      """
    Given transaction commits
    Given the integrity is validated
    Given session opens transaction of type: read
    When get answers of graql query
      """
      match $x isa person, has name $y, has age $z;
      sum $z;
      """
    Then aggregate value is: 65
    Then get answers of graql query
      """
      match
        $x isa person, has name $y, has age $z;
      get $y, $z;
      sum $z;
      """
    Then aggregate value is: 65


  Scenario Outline: duplicate attribute values are included in a '<agg_type>'
    Given graql insert
      """
      insert
      $p1 isa person, has age <val1and2>, has ref 0;
      $p2 isa person, has age <val1and2>, has ref 1;
      $p3 isa person, has age <val3>, has ref 2;
      """
    Given transaction commits
    Given the integrity is validated
    Given session opens transaction of type: read
    When get answers of graql query
      """
      match $x isa person, has age $y;
      <agg_type> $y;
      """
    Then aggregate value is: <agg_val>

    Examples:
      | val1and2 | val3 | agg_type | agg_val |
      | 30       | 75   | sum      | 135     |
      | 30       | 60   | mean     | 40      |
      | 17       | 14   | median   | 17      |


  Scenario: the median of an even number of values is the number halfway between the two most central values
    Given graql insert
      """
      insert
      $p1 isa person, has age 42, has ref 0;
      $p2 isa person, has age 38, has ref 1;
      $p3 isa person, has age 19, has ref 2;
      $p4 isa person, has age 35, has ref 3;
      """
    Given transaction commits
    Given the integrity is validated
    Given session opens transaction of type: read
    When get answers of graql query
      """
      match $x isa person, has age $y;
      median $y;
      """
    Then aggregate value is: 36.5


  Scenario Outline: when an answer set is empty, calling '<agg_type>' on it returns an empty answer
    Given connection close all sessions
    Given connection open schema session for database: grakn
    Given session opens transaction of type: write
    Given graql define
      """
      define
      income sub attribute, value double;
      person owns income;
      """
    Given transaction commits
    Given the integrity is validated
    Given session opens transaction of type: read
    When get answers of graql query
      """
      match $x isa person, has income $y;
      <agg_type> $y;
      """
    Then aggregate answer is empty

    Examples:
      | agg_type |
      | sum      |
      | max      |
      | min      |
      | mean     |
      | median   |
      | std      |


  Scenario Outline: an error is thrown when getting the '<agg_type>' of an undefined variable in an aggregate query
    Then graql match; throws exception
      """
      match $x isa person;
      <agg_type> $y;
      """

    Examples:
      | agg_type |
      | sum      |
      | max      |
      | min      |
      | mean     |
      | median   |
      | std      |


  Scenario: aggregates can only be performed over sets of attributes
    Given graql insert
      """
      insert $x isa person, has ref 0;
      """
    Given transaction commits
    Given the integrity is validated
    Given session opens transaction of type: read
    Then graql match; throws exception
      """
      match $x isa person;
      min $x;
      """
    Then the integrity is validated


  Scenario Outline: an error is thrown when getting the '<agg_type>' of attributes that have the inapplicable type, '<type>'
    Given connection close all sessions
    Given connection open schema session for database: grakn
    Given session opens transaction of type: write
    Given graql define
      """
      define
      <attr> sub attribute, value <type>;
      person owns <attr>;
      """
    Given transaction commits
    Given the integrity is validated
    Given connection close all sessions
    Given connection open data session for database: grakn
    Given session opens transaction of type: write
    Given graql insert
      """
      insert
      $x isa person, has ref 0, has <attr> <value>;
      """
    Given transaction commits
    Given the integrity is validated
    Given session opens transaction of type: read
    Then graql match; throws exception
      """
      match $x isa person, has <attr> $y;
      <agg_type> $y;
      """
    Then the integrity is validated

    Examples:
      | attr       | type     | value      | agg_type |
      | name       | string   | "Talia"    | sum      |
      | name       | string   | "Talia"    | max      |
      | name       | string   | "Talia"    | min      |
      | name       | string   | "Talia"    | mean     |
      | name       | string   | "Talia"    | median   |
      | name       | string   | "Talia"    | std      |
      | is-awake   | boolean  | true       | sum      |
      | is-awake   | boolean  | true       | max      |
      | is-awake   | boolean  | true       | min      |
      | is-awake   | boolean  | true       | mean     |
      | is-awake   | boolean  | true       | median   |
      | is-awake   | boolean  | true       | std      |
      | birth-date | datetime | 2000-01-01 | sum      |
      | birth-date | datetime | 2000-01-01 | max      |
      | birth-date | datetime | 2000-01-01 | min      |
      | birth-date | datetime | 2000-01-01 | mean     |
      | birth-date | datetime | 2000-01-01 | median   |
      | birth-date | datetime | 2000-01-01 | std      |


  Scenario: when taking the sum of a set of attributes, where some are numeric and others are strings, an error is thrown
    Given graql insert
      """
      insert
      $x isa person, has name "Barry", has age 39, has ref 0;
      $y isa person, has name "Gloria", has age 28, has ref 1;
      """
    Given transaction commits
    Given the integrity is validated
    Given session opens transaction of type: read
    Then graql match; throws exception
      """
      match $x isa person, has attribute $y;
      sum $y;
      """
    Then the integrity is validated


  Scenario: when taking the sum of an empty set, even if any matches would definitely be strings, no error is thrown and an empty answer is returned
    When get answers of graql query
      """
      match $x isa person, has name $y;
      sum $y;
      """
    Then aggregate answer is empty


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
    Given transaction commits
    Given the integrity is validated
    Given session opens transaction of type: read
    When get answers of graql query
      """
      match ($x, $y) isa friendship;
      """
    And concept identifiers are
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
      group $x;
      """
    And group identifiers are
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


  Scenario: when grouping answers by a variable that is not contained in the answer set, an error is thrown
    Given graql insert
      """
      insert
      $p1 isa person, has name "Violet", has ref 0;
      $p2 isa person, has name "Rupert", has ref 1;
      $f (friend: $p1, friend: $p2) isa friendship, has ref 2;
      """
    Given transaction commits
    Given the integrity is validated
    Given session opens transaction of type: read
    Then graql match; throws exception
      """
      match ($x, $y) isa friendship;
      get $x;
      group $y;
      """
    Then the integrity is validated


  ###################
  # GROUP AGGREGATE #
  ###################

  Scenario: the size of each answer group can be retrieved using a group 'count'
    Given graql insert
      """
      insert
      $p1 isa person, has name "Violet", has ref 0;
      $p2 isa person, has name "Rupert", has ref 1;
      $p3 isa person, has name "Bernard", has ref 2;
      $p4 isa person, has name "Colin", has ref 3;
      $f (friend: $p1, friend: $p2, friend: $p3, friend: $p4) isa friendship, has ref 4;
      """
    Given transaction commits
    Given the integrity is validated
    Given session opens transaction of type: read
    When get answers of graql query
      """
      match $x isa person;
      """
    And concept identifiers are
      |     | check | value |
      | VIO | key   | ref:0 |
      | RUP | key   | ref:1 |
      | BER | key   | ref:2 |
      | COL | key   | ref:3 |
    When get answers of graql query
      """
      match ($x, $y) isa friendship;
      group $x;
      count;
      """
    And group identifiers are
      |      | owner |
      | gVIO | VIO   |
      | gRUP | RUP   |
      | gBER | BER   |
      | gCOL | COL   |
    Then group aggregate values are
      | group | value |
      | gVIO  | 3     |
      | gRUP  | 3     |
      | gBER  | 3     |
      | gCOL  | 3     |


  Scenario: the size of answer groups is still computed correctly when restricting variables with 'get'
    Given graql insert
      """
      insert
      $c1 isa company, has name "Apple", has ref 0;
      $c2 isa company, has name "Google", has ref 1;
      $p1 isa person, has name "Elena", has ref 2;
      $p2 isa person, has name "Flynn", has ref 3;
      $p3 isa person, has name "Lyudmila", has ref 4;
      $e1 (employer: $c1, employee: $p1, employee: $p2) isa employment, has ref 5;
      $e2 (employer: $c2, employee: $p3) isa employment, has ref 6;
      """
    Given transaction commits
    Given the integrity is validated
    Given session opens transaction of type: read
    And concept identifiers are
      |     | check | value |
      | APP | key   | ref:0 |
      | GOO | key   | ref:1 |
      | ELE | key   | ref:2 |
      | FLY | key   | ref:3 |
      | LYU | key   | ref:4 |
    When get answers of graql query
      """
      match
        $x isa company;
        $y isa person;
        $z isa person;
        not { $y is $z; };
        ($x, $y) isa relation;
      get $x, $y, $z;
      """
    Then uniquely identify answer concepts
      | x   | y   | z   |
      | APP | ELE | FLY |
      | APP | ELE | LYU |
      | APP | FLY | ELE |
      | APP | FLY | LYU |
      | GOO | LYU | ELE |
      | GOO | LYU | FLY |
    Then get answers of graql query
      """
      match
        $x isa company;
        $y isa person;
        $z isa person;
        not { $y is $z; };
        ($x, $y) isa relation;
      get $x, $y, $z;
      group $x;
      count;
      """
    And group identifiers are
      |      | owner |
      | gAPP | APP   |
      | gGOO | GOO   |
    Then group aggregate values are
      | group | value |
      | gAPP  | 4     |
      | gGOO  | 2     |


  Scenario: the maximum value for a particular variable within each answer group can be retrieved using a group 'max'
    Given graql insert
      """
      insert
      $c1 isa company, has name "Lloyds", has ref 0;
      $c2 isa company, has name "Barclays", has ref 1;
      $p1 isa person, has name "Amy", has age 48, has ref 2;
      $p2 isa person, has name "Weiyi", has age 57, has ref 3;
      $p3 isa person, has name "Kimberly", has age 31, has ref 4;
      $p4 isa person, has name "Reginald", has age 45, has ref 5;
      $e1 (employer: $c1, employee: $p1, employee: $p2, employee: $p3) isa employment, has ref 6;
      $e2 (employer: $c2, employee: $p4) isa employment, has ref 7;
      """
    Given transaction commits
    Given the integrity is validated
    Given session opens transaction of type: read
    And concept identifiers are
      |     | check | value |
      | LLO | key   | ref:0 |
      | BAR | key   | ref:1 |
    When get answers of graql query
      """
      match
        $x isa company;
        $y isa person, has age $z;
        ($x, $y) isa employment;
      group $x;
      max $z;
      """
    And group identifiers are
      |      | owner |
      | gLLO | LLO   |
      | gBAR | BAR   |
    Then group aggregate values are
      | group | value |
      | gLLO  | 57    |
      | gBAR  | 45    |
