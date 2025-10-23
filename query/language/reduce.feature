# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: TypeQL Reduce Queries

  Background: Open connection and create a simple extensible schema
    Given typedb starts
    Given connection opens with default authentication
    Given connection is open: true
    Given connection reset database: typedb
    Given connection open schema transaction for database: typedb

    Given typeql schema query
      """
      define
      entity person
        plays friendship:friend,
        plays employment:employee,
        owns name @card(0..),
        owns age @card(0..),
        owns ref @key,
        owns email @unique @card(0..);
      entity company
        plays employment:employer,
        owns name @card(0..),
        owns ref @key;
      relation friendship
        relates friend @card(0..),
        owns ref @key;
      relation employment
        relates employee @card(0..),
        relates employer @card(0..),
        owns ref @key;
      attribute name value string;
      attribute age value integer;
      attribute ref value integer;
      attribute email value string;
      """
    Given transaction commits


  #############
  #  reduce   #
  #############

  Scenario: 'count' returns the total number of answers
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $p1 isa person, has name "Klaus", has ref 0;
      $p2 isa person, has name "Kristina", has ref 1;
      $p3 isa person, has name "Karen", has ref 2;
      (friend: $p1, friend: $p2) isa friendship, has ref 3;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
        $x isa person;
        $y isa name;
        $f isa friendship;
      """
    Then answer size is: 9
    When get answers of typeql read query
      """
      match
        $x isa person;
        $y isa name;
        $f isa friendship;
      reduce $count = count($x);
      """
    Then result is a single row with variable 'count': value:integer:9
    When get answers of typeql read query
      """
      match
        $x isa person;
        $y isa name;
        $f isa friendship, links (friend: $x);
      """
    Then answer size is: 6
    When get answers of typeql read query
      """
      match
        $x isa person;
        $y isa name;
        $f isa friendship, links (friend: $x);
      reduce $count = count($x);
      """
    Then result is a single row with variable 'count': value:integer:6
    When get answers of typeql read query
      """
      match
        $x isa person;
        $y isa name;
        $f isa friendship, links (friend: $x);
      reduce $count = count;
      """
    Then result is a single row with variable 'count': value:integer:6


  Scenario: the 'count' of an empty answer set is zero
    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa person, has name "Voldemort";
      reduce $count = count($x);
      """
    Then result is a single row with variable 'count': value:integer:0


  Scenario Outline: the <reduction> of an answer set of '<type>' values can be retrieved
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
      attribute <attr>, value <type>;
      person owns <attr>;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $p1 isa person, has <attr> <val1>, has ref 0;
      $p2 isa person, has <attr> <val2>, has ref 1;
      $p3 isa person, has <attr> <val3>, has ref 2;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa person, has <attr> $y;
      reduce $red_var = <reduction>($y);
      """
    Then result is a single row with variable 'red_var': value:<val_type>:<red_val>

    Examples:
      |  attr          |  type     |  val1     |  val2     |  val3     |  reduction  |  val_type  |  red_val   |
      |  age           |  integer  |  6        |  30       |  14       |  sum        |  integer   |  50        |
      |  weight        |  double   |  61.8     |  86.5     |  24.8     |  sum        |  double    |  173.1     |
      |  bank-balance  |  decimal  |  61.8dec  |  86.5dec  |  24.8dec  |  sum        |  decimal   |  173.1dec  |

  Scenario Outline: the <reduction> of an answer set of '<type>' must be assigned to an optional variable
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
      attribute <attr>, value <type>;
      person owns <attr>;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $p1 isa person, has <attr> <val1>, has ref 0;
      $p2 isa person, has <attr> <val2>, has ref 1;
      $p3 isa person, has <attr> <val3>, has ref 2;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa person, has <attr> $y;
      reduce $red_var? = <reduction>($y);
      """
    Then result is a single row with variable 'red_var': value:<val_type>:<red_val>

    Examples:
      | attr              | type        | val1                 | val2                      | val3                      | reduction | val_type    | red_val                   |
      | age               | integer     | 6                    | 30                        | 14                        | max       | integer     | 30                        |
      | age               | integer     | 6                    | 30                        | 14                        | min       | integer     | 6                         |
      | age               | integer     | 6                    | 30                        | 14                        | mean      | double      | 16.6667                   |
      | age               | integer     | 6                    | 30                        | 14                        | median    | double      | 14                        |
      | weight            | double      | 61.8                 | 86.5                      | 24.8                      | max       | double      | 86.5                      |
      | weight            | double      | 61.8                 | 86.5                      | 24.8                      | min       | double      | 24.8                      |
      | weight            | double      | 61.8                 | 86.5                      | 24.8                      | mean      | double      | 57.7                      |
      | weight            | double      | 61.8                 | 86.5                      | 24.8                      | median    | double      | 61.8                      |
      | bank-balance      | decimal     | 61.8dec              | 86.5dec                   | 24.8dec                   | max       | decimal     | 86.5dec                   |
      | bank-balance      | decimal     | 61.8dec              | 86.5dec                   | 24.8dec                   | min       | decimal     | 24.8dec                   |
      | bank-balance      | decimal     | 61.8dec              | 86.5dec                   | 24.8dec                   | mean      | decimal     | 57.7dec                   |
      | bank-balance      | decimal     | 61.8dec              | 86.5dec                   | 24.8dec                   | median    | decimal     | 61.8dec                   |
      | name              | string      | "Alice"              | "Gina"                    | "Talia"                   | max       | string      | "Talia"                   |
      | name              | string      | "Alice"              | "Gina"                    | "Talia"                   | min       | string      | "Alice"                   |
      | birth-date        | date        | 2000-12-01           | 2001-11-11                | 2003-03-03                | max       | date        | 2003-03-03                |
      | birth-date        | date        | 2000-12-01           | 2001-11-11                | 2003-03-03                | min       | date        | 2000-12-01                |
      | birth-datetime    | datetime    | 2000-12-01T12:00:00  | 2001-11-11T12:34:56       | 2003-03-03T00:00:01       | max       | datetime    | 2003-03-03T00:00:01       |
      | birth-datetime    | datetime    | 2000-12-01T12:00:00  | 2001-11-11T12:34:56       | 2003-03-03T00:00:01       | min       | datetime    | 2000-12-01T12:00:00       |
      | birth-datetime-tz | datetime-tz | 2000-12-01T12:00:00Z | 2001-11-11T12:34:56+12:00 | 2003-03-03T00:00:01-13:00 | max       | datetime-tz | 2003-03-03T00:00:01-13:00 |
      | birth-datetime-tz | datetime-tz | 2000-12-01T12:00:00Z | 2001-11-11T12:34:56+12:00 | 2003-03-03T00:00:01-13:00 | min       | datetime-tz | 2000-12-01T12:00:00Z      |


  Scenario: the sample standard deviation can be retrieved for an answer set of 'double' values
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
      attribute weight, value double;
      person owns weight;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $p1 isa person, has weight 61.8, has ref 0;
      $p2 isa person, has weight 86.5, has ref 1;
      $p3 isa person, has weight 24.8, has ref 2;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa person, has weight $y;
      reduce $std? = std($y);
      """
      # Note: This is the sample standard deviation, NOT the population standard deviation
    Then result is a single row with variable 'std': value:double:31.0537


  Scenario: restricting variables with 'select' does not affect the result of a 'sum'
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $p1 isa person, has name "Jeff", has age 30, has ref 0;
      $p2 isa person, has name "Yoko", has age 20, has ref 1;
      $p3 isa person, has name "Miles", has age 15, has ref 2;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa person, has name $y, has age $z;
      reduce $sum = sum($z);
      """
    Then result is a single row with variable 'sum': value:integer:65
    When get answers of typeql read query
      """
      match $x isa person, has name $y, has age $z;
      select $y, $z;
      reduce $sum = sum($z);
      """
    Then result is a single row with variable 'sum': value:integer:65


  Scenario Outline: duplicate attribute values are included in a '<reduction>'
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $p1 isa person, has age <val1and2>, has ref 0;
      $p2 isa person, has age <val1and2>, has ref 1;
      $p3 isa person, has age <val3>, has ref 2;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa person, has age $y;
      """
    Then answer size is: 3
    When get answers of typeql read query
      """
      match $x isa person, has age $y;
      reduce $red_var? = <reduction>($y);
      """
    Then result is a single row with variable 'red_var': value:<val_type>:<red_val>

    Examples:
      | val1and2 | val3 | reduction | val_type | red_val |
      | 30       | 60   | mean      | double   | 40      |
      | 17       | 14   | median    | double   | 17      |


  Scenario: the median of an even number of values is the number halfway between the two most central values
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $p1 isa person, has age 42, has ref 0;
      $p2 isa person, has age 38, has ref 1;
      $p3 isa person, has age 19, has ref 2;
      $p4 isa person, has age 35, has ref 3;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa person, has age $y;
      reduce $median? = median($y);
      """
    Then result is a single row with variable 'median': value:double:36.5


  Scenario Outline: when an answer set is empty, calling '<reduction>' on it returns an empty answer
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
      attribute income value double;
      person owns income;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa person, has income $y;
      reduce $red_var? = <reduction>($y);
      """
    Then result is a single row with variable 'red_var': none

    Examples:
      | reduction |
      | max       |
      | min       |
      | mean      |
      | median    |
      | std       |


  Scenario Outline: an error is thrown when getting the '<reduction>' of an undefined variable in a reduce query
    Given connection open read transaction for database: typedb
    Then typeql read query; fails
      """
      match $x isa person;
      reduce $red_var = <reduction>($y);
      """
    Examples:
      | reduction |
      | count     |
      | sum       |


  Scenario Outline: an error is thrown when getting the '<reduction>' of an undefined variable in a fallible reduce query
    Given connection open read transaction for database: typedb
    Then typeql read query; fails
      """
      match $x isa person;
      reduce $red_var? = <reduction>($y);
      """
    Examples:
      | reduction |
      | max       |
      | min       |
      | mean      |
      | median    |
      | std       |


  Scenario: reductions can only be performed over sets of attributes or values
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert $x isa person, has ref 0;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    Then typeql read query; fails
      """
      match $x isa person;
      reduce $min = min($x);
      """

  Scenario Outline: an error is thrown when getting the '<reduction>' of attributes that have the inapplicable type, '<type>'
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
      attribute <attr> value <type>;
      person owns <attr>;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x isa person, has ref 0, has <attr> <value>;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    Then typeql read query; fails
      """
      match $x isa person, has <attr> $y;
      reduce $red_var = <reduction>($y);
      """
    Examples:
      | attr       | type     | value      | reduction |
      | name       | string   | "Talia"    | sum       |
      | is-awake   | boolean  | true       | sum       |
      | birth-date | datetime | 2000-01-01 | sum       |


  Scenario Outline: an error is thrown when getting the fallible '<reduction>' of attributes that have the inapplicable type, '<type>'
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
      attribute <attr> value <type>;
      person owns <attr>;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x isa person, has ref 0, has <attr> <value>;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    Then typeql read query; fails
      """
      match $x isa person, has <attr> $y;
      reduce $red_var? = <reduction>($y);
      """
    Examples:
      | attr       | type     | value      | reduction |
      | name       | string   | "Talia"    | mean      |
      | name       | string   | "Talia"    | median    |
      | name       | string   | "Talia"    | std       |
      | is-awake   | boolean  | true       | max       |
      | is-awake   | boolean  | true       | min       |
      | is-awake   | boolean  | true       | mean      |
      | is-awake   | boolean  | true       | median    |
      | is-awake   | boolean  | true       | std       |
      | birth-date | datetime | 2000-01-01 | mean      |
      | birth-date | datetime | 2000-01-01 | median    |
      | birth-date | datetime | 2000-01-01 | std       |


  Scenario: when taking the sum of a set of attributes, where some are numeric and others are strings, an error is thrown
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x isa person, has name "Barry", has age 39, has ref 0;
      $y isa person, has name "Gloria", has age 28, has ref 1;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    Then typeql read query; fails
      """
      match $x isa person, has $y;
      reduce $sum = sum($y);
      """


  ###################
  #  reduce-groupby  #
  ###################

  # TODO: re-enable after deduplicating identical players matched in the same relation
#  Scenario: the size of each answer group can be retrieved using a group 'count'
#    Given connection open write transaction for database: typedb
#    Given typeql write query
#      """
#      insert
#      $p1 isa person, has name "Violet", has ref 0;
#      $p2 isa person, has name "Rupert", has ref 1;
#      $p3 isa person, has name "Bernard", has ref 2;
#      $p4 isa person, has name "Colin", has ref 3;
#      $f isa friendship, links (friend: $p1, friend: $p2, friend: $p3, friend: $p4), has ref 4;
#      """
#    Given transaction commits
#
#    Given connection open read transaction for database: typedb
#    When get answers of typeql read query
#      """
#      match $x isa person;
#      """
#    When get answers of typeql read query
#      """
#      match ($x, $y) isa friendship;
#      reduce $count = count($y) groupby $x;
#      """
#    Then uniquely identify answer concepts
#      | x         | count        |
#      | key:ref:0 | value:integer:3 |
#      | key:ref:1 | value:integer:3 |
#      | key:ref:2 | value:integer:3 |
#      | key:ref:3 | value:integer:3 |
#
#    When get answers of typeql read query
#      """
#      match ($x, $y) isa friendship;
#      reduce $count = count groupby $x;
#      """
#    Then uniquely identify answer concepts
#      | x         | count        |
#      | key:ref:0 | value:integer:3 |
#      | key:ref:1 | value:integer:3 |
#      | key:ref:2 | value:integer:3 |
#      | key:ref:3 | value:integer:3 |


  Scenario: the size of answer groups is still computed correctly when restricting variables with 'select'
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $c1 isa company, has name "Apple", has ref 0;
      $c2 isa company, has name "Google", has ref 1;
      $p1 isa person, has name "Elena", has ref 2;
      $p2 isa person, has name "Flynn", has ref 3;
      $p3 isa person, has name "Lyudmila", has ref 4;
      $e1 isa employment, links (employer: $c1, employee: $p1, employee: $p2), has ref 5;
      $e2 isa employment, links (employer: $c2, employee: $p3), has ref 6;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
      $x isa company;
      $y isa person;
      $z isa person;
      not { $y is $z; };
      $r links ($x, $y);
      select $x, $y, $z;
      """
    Then uniquely identify answer concepts
      | x         | y         | z         |
      | key:ref:0 | key:ref:2 | key:ref:3 |
      | key:ref:0 | key:ref:2 | key:ref:4 |
      | key:ref:0 | key:ref:3 | key:ref:2 |
      | key:ref:0 | key:ref:3 | key:ref:4 |
      | key:ref:1 | key:ref:4 | key:ref:2 |
      | key:ref:1 | key:ref:4 | key:ref:3 |
    When get answers of typeql read query
      """
      match
        $x isa company;
        $y isa person;
        $z isa person;
        not { $y is $z; };
        $r links ($x, $y);
      select $x, $y, $z;
      reduce $cy = count($y), $cz = count($z) groupby $x;
      """
    Then uniquely identify answer concepts
      | x        | cy           | cz           |
      | key:ref:0 | value:integer:4 | value:integer:4 |
      | key:ref:1 | value:integer:2 | value:integer:2 |


  Scenario: the maximum value for a particular variable grouped by each answer group can be retrieved using a group 'max'
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $c1 isa company, has name "Lloyds", has ref 0;
      $c2 isa company, has name "Barclays", has ref 1;
      $p1 isa person, has name "Amy", has age 48, has ref 2;
      $p2 isa person, has name "Weiyi", has age 57, has ref 3;
      $p3 isa person, has name "Kimberly", has age 31, has ref 4;
      $p4 isa person, has name "Reginald", has age 45, has ref 5;
      $e1 isa employment, links (employer: $c1, employee: $p1, employee: $p2, employee: $p3), has ref 6;
      $e2 isa employment, links (employer: $c2, employee: $p4), has ref 7;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
        $x isa company;
        $y isa person, has age $z;
        $r isa employment, links ($x, $y);
      reduce $max? = max($z) groupby $x;
      """
    Then uniquely identify answer concepts
      | x         | max           |
      | key:ref:0 | value:integer:57 |
      | key:ref:1 | value:integer:45 |


  Scenario: Grouped reductions can be performed on value variables
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
        $a1 isa person, has name "Alice", has age 22, has ref 0;
        $a2 isa person, has name "Alice", has age 18, has ref 1;
        $b1 isa person, has name "Bob", has age 21, has ref 2;
        $b2 isa person, has name "Bob", has age 24, has ref 3;
      """
    Then transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
       $p isa person, has name $name, has age $a;
       let $n = $name;
       let $to25 = 25 - $a;
      reduce $sum = sum($to25) groupby $n;
      """
    Then uniquely identify answer concepts
      | n                  | sum           |
      | value:string:Alice | value:integer:10 |
      | value:string:Bob   | value:integer:5  |


  Scenario: Grouped standard deviation of one value returns an empty group value
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
      attribute income value double;
      person owns income;
      """
    Given transaction commits
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x isa person, has income 100.0, has ref 0;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa person, has income $y;
      select $x, $y;
      reduce $std? = std($y) groupby $x;
      """
    Then uniquely identify answer concepts
      | x         | std   |
      | key:ref:0 | none  |

