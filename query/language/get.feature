# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: TypeQL Get Query

  Background: Open connection and create a simple extensible schema
    Given typedb starts
    Given connection opens with default authentication
    Given connection has been opened
    Given connection does not have any database
    Given connection create database: typedb
    Given connection open schema session for database: typedb
    Given session opens transaction of type: write

    Given typeql define
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

    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write


  #############
  # VARIABLES #
  #############

  Scenario: 'get' can be used to restrict the set of variables that appear in an answer set
    Given typeql insert
      """
      insert
      $x "Lisa" isa name;
      $y 16 isa age;
      $z isa person, has name $x, has age $y, has ref 0;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql read query
      """
      match
        $z isa person, has name $x, has age $y;
      get $z, $x;
      """
    Then uniquely identify answer concepts
      | z         | x               |
      | key:ref:0 | attr:name:Lisa  |


  Scenario: when a 'get' has unbound variables, an error is thrown
    Then typeql throws exception
      """
      match $x isa person; get $y;
      """


  Scenario: Value variables can be specified in a 'get'
    Given typeql insert
      """
      insert
      $x "Lisa" isa name;
      $y 16 isa age;
      $z isa person, has name $x, has age $y, has ref 0;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql read query
      """
      match
        $z isa person, has name $x, has age $y;
        ?b = 2017 - $y;
      get $z, $x, ?b;
      """
    Then uniquely identify answer concepts
      | z         | x              | b                |
      | key:ref:0 | attr:name:Lisa | value:long:2001  |


  # Guards against regression of #6967
  Scenario: A `get` filter is applied after negations
    Given typeql insert
      """
      insert
      $p1 isa person, has name "Klaus", has ref 0;
      $p2 isa person, has name "Kristina", has ref 1;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql read query
      """
      match
        $p isa person, has name $n, has ref $r;
        $n = "Klaus";
        not { $p has name "Kristina"; };
      get $n, $r;
      """
    Then uniquely identify answer concepts
      | n               | r               |
      | attr:name:Klaus | attr:ref:0      |

    When get answers of typeql read query
      """
      match
        $p isa person, has name $n, has ref $r;
        $n = "Klaus";
        not { $p has name "Kristina"; };
      get $n, $r;
      sort $r; # The sort triggered the bug
      """
    Then uniquely identify answer concepts
      | n               | r               |
      | attr:name:Klaus | attr:ref:0      |

  #############
  # AGGREGATE #
  #############

  Scenario: 'count' returns the total number of answers
    Given typeql insert
      """
      insert
      $p1 isa person, has name "Klaus", has ref 0;
      $p2 isa person, has name "Kristina", has ref 1;
      $p3 isa person, has name "Karen", has ref 2;
      $f (friend: $p1, friend: $p2) isa friendship, has ref 3;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql read query
      """
      match
        $x isa person;
        $y isa name;
        $f isa friendship;

      """
    Then answer size is: 9
    When get answer of typeql read query aggregate
      """
      match
        $x isa person;
        $y isa name;
        $f isa friendship;

      count;
      """
    Then aggregate value is: 9
    When get answers of typeql read query
      """
      match
        $x isa person;
        $y isa name;
        $f (friend: $x) isa friendship;

      """
    Then answer size is: 6
    When get answer of typeql read query aggregate
      """
      match
        $x isa person;
        $y isa name;
        $f (friend: $x) isa friendship;

      count;
      """
    Then aggregate value is: 6


  Scenario: the 'count' of an empty answer set is zero
    When get answer of typeql read query aggregate
      """
      match $x isa person, has name "Voldemort";

      count;
      """
    Then aggregate value is: 0


  Scenario Outline: the <agg_type> of an answer set of '<type>' values can be retrieved
    Given connection close all sessions
    Given connection open schema session for database: typedb
    Given session opens transaction of type: write
    Given typeql define
      """
      define
      <attr> sub attribute, value <type>;
      person owns <attr>;
      """
    Given transaction commits

    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $p1 isa person, has <attr> <val1>, has ref 0;
      $p2 isa person, has <attr> <val2>, has ref 1;
      $p3 isa person, has <attr> <val3>, has ref 2;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answer of typeql read query aggregate
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
    Given connection open schema session for database: typedb
    Given session opens transaction of type: write
    Given typeql define
      """
      define
      weight sub attribute, value double;
      person owns weight;
      """
    Given transaction commits

    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $p1 isa person, has weight 61.8, has ref 0;
      $p2 isa person, has weight 86.5, has ref 1;
      $p3 isa person, has weight 24.8, has ref 2;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answer of typeql read query aggregate
      """
      match $x isa person, has weight $y;

      std $y;
      """
    # Note: This is the sample standard deviation, NOT the population standard deviation
    Then aggregate value is: 31.0537


  Scenario: restricting variables with 'get' does not affect the result of a 'sum'
    Given typeql insert
      """
      insert
      $p1 isa person, has name "Jeff", has age 30, has ref 0;
      $p2 isa person, has name "Yoko", has age 20, has ref 1;
      $p3 isa person, has name "Miles", has age 15, has ref 2;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answer of typeql read query aggregate
      """
      match $x isa person, has name $y, has age $z;

      sum $z;
      """
    Then aggregate value is: 65
    Then get answer of typeql read query aggregate
      """
      match $x isa person, has name $y, has age $z;
      get $y, $z;
      sum $z;
      """
    Then aggregate value is: 65

  Scenario Outline: duplicate attribute values are included in a '<agg_type>'
    Given typeql insert
      """
      insert
      $p1 isa person, has age <val1and2>, has ref 0;
      $p2 isa person, has age <val1and2>, has ref 1;
      $p3 isa person, has age <val3>, has ref 2;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answer of typeql read query aggregate
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
    Given typeql insert
      """
      insert
      $p1 isa person, has age 42, has ref 0;
      $p2 isa person, has age 38, has ref 1;
      $p3 isa person, has age 19, has ref 2;
      $p4 isa person, has age 35, has ref 3;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answer of typeql read query aggregate
      """
      match $x isa person, has age $y;

      median $y;
      """
    Then aggregate value is: 36.5


  Scenario Outline: when an answer set is empty, calling '<agg_type>' on it returns an empty answer
    Given connection close all sessions
    Given connection open schema session for database: typedb
    Given session opens transaction of type: write
    Given typeql define
      """
      define
      income sub attribute, value double;
      person owns income;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answer of typeql read query aggregate
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
    Then typeql get aggregate; throws exception
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
    Given typeql insert
      """
      insert $x isa person, has ref 0;
      """
    Given transaction commits

    Given session opens transaction of type: read
    Then typeql get aggregate; throws exception
      """
      match $x isa person;

      min $x;
      """


  Scenario Outline: an error is thrown when getting the '<agg_type>' of attributes that have the inapplicable type, '<type>'
    Given connection close all sessions
    Given connection open schema session for database: typedb
    Given session opens transaction of type: write
    Given typeql define
      """
      define
      <attr> sub attribute, value <type>;
      person owns <attr>;
      """
    Given transaction commits

    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $x isa person, has ref 0, has <attr> <value>;
      """
    Given transaction commits

    Given session opens transaction of type: read
    Then typeql get aggregate; throws exception
      """
      match $x isa person, has <attr> $y;

      <agg_type> $y;
      """


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
    Given typeql insert
      """
      insert
      $x isa person, has name "Barry", has age 39, has ref 0;
      $y isa person, has name "Gloria", has age 28, has ref 1;
      """
    Given transaction commits

    Given session opens transaction of type: read
    Then typeql get aggregate; throws exception
      """
      match $x isa person, has attribute $y;

      sum $y;
      """


  Scenario: when taking the sum of an empty set, even if any matches would definitely be strings, no error is thrown and an empty answer is returned
    When get answer of typeql read query aggregate
      """
      match $x isa person, has name $y;

      sum $y;
      """
    Then aggregate answer is empty


  #########
  # GROUP #
  #########

  Scenario: answers can be grouped by a variable contained in the answer set
    Given typeql insert
      """
      insert
      $p1 isa person, has name "Violet", has ref 0;
      $p2 isa person, has name "Rupert", has ref 1;
      $p3 isa person, has name "Bernard", has ref 2;
      $p4 isa person, has name "Colin", has ref 3;
      $f (friend: $p1, friend: $p2, friend: $p3, friend: $p4) isa friendship, has ref 4;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql read query
      """
      match ($x, $y) isa friendship;
      """
    Then uniquely identify answer concepts
      | x         | y         |
      | key:ref:0 | key:ref:1 |
      | key:ref:0 | key:ref:2 |
      | key:ref:0 | key:ref:3 |
      | key:ref:1 | key:ref:0 |
      | key:ref:1 | key:ref:2 |
      | key:ref:1 | key:ref:3 |
      | key:ref:2 | key:ref:0 |
      | key:ref:2 | key:ref:1 |
      | key:ref:2 | key:ref:3 |
      | key:ref:3 | key:ref:0 |
      | key:ref:3 | key:ref:1 |
      | key:ref:3 | key:ref:2 |
    When get answers of typeql read query group
      """
      match ($x, $y) isa friendship;

      group $x;
      """
    Then answer groups are
      | owner     | x         | y         |
      | key:ref:0 | key:ref:0 | key:ref:1 |
      | key:ref:0 | key:ref:0 | key:ref:2 |
      | key:ref:0 | key:ref:0 | key:ref:3 |
      | key:ref:1 | key:ref:1 | key:ref:0 |
      | key:ref:1 | key:ref:1 | key:ref:2 |
      | key:ref:1 | key:ref:1 | key:ref:3 |
      | key:ref:2 | key:ref:2 | key:ref:0 |
      | key:ref:2 | key:ref:2 | key:ref:1 |
      | key:ref:2 | key:ref:2 | key:ref:3 |
      | key:ref:3 | key:ref:3 | key:ref:0 |
      | key:ref:3 | key:ref:3 | key:ref:1 |
      | key:ref:3 | key:ref:3 | key:ref:2 |

  Scenario: answers can be grouped by a value variable contained in the answer set
    Given typeql insert
      """
      insert
      $p1 isa person, has name "Violet", has ref 1250;
      $p2 isa person, has name "Rupert", has ref 1750;
      $p3 isa person, has name "Bernard", has ref 2050;
      $p4 isa person, has name "Colin", has ref 3000;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql read query group
      """
      match
       $x isa person, has ref $r;
       ?bracket = floor($r/1000) * 1000;
       get $x, ?bracket;
       group ?bracket;
      """
    Then answer groups are
      | owner           | x            |
      | value:long:1000 | key:ref:1250 |
      | value:long:1000 | key:ref:1750 |
      | value:long:2000 | key:ref:2050 |
      | value:long:3000 | key:ref:3000 |

  Scenario: when grouping answers by a variable that is not contained in the answer set, an error is thrown
    Given typeql insert
      """
      insert
      $p1 isa person, has name "Violet", has ref 0;
      $p2 isa person, has name "Rupert", has ref 1;
      $f (friend: $p1, friend: $p2) isa friendship, has ref 2;
      """
    Given transaction commits

    Given session opens transaction of type: read
    Then typeql get group; throws exception
      """
      match ($x, $y) isa friendship;
      get $x;
      group $y;
      """



  ###################
  # GROUP AGGREGATE #
  ###################

  Scenario: the size of each answer group can be retrieved using a group 'count'
    Given typeql insert
      """
      insert
      $p1 isa person, has name "Violet", has ref 0;
      $p2 isa person, has name "Rupert", has ref 1;
      $p3 isa person, has name "Bernard", has ref 2;
      $p4 isa person, has name "Colin", has ref 3;
      $f (friend: $p1, friend: $p2, friend: $p3, friend: $p4) isa friendship, has ref 4;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql read query
      """
      match $x isa person;
      """
    When get answers of typeql read query group aggregate
      """
      match ($x, $y) isa friendship;

      group $x;
      count;
      """
    Then group aggregate values are
      | owner     | value |
      | key:ref:0 | 3     |
      | key:ref:1 | 3     |
      | key:ref:2 | 3     |
      | key:ref:3 | 3     |


  Scenario: the size of answer groups is still computed correctly when restricting variables with 'get'
    Given typeql insert
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

    Given session opens transaction of type: read
    When get answers of typeql read query
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
      | x         | y         | z         |
      | key:ref:0 | key:ref:2 | key:ref:3 |
      | key:ref:0 | key:ref:2 | key:ref:4 |
      | key:ref:0 | key:ref:3 | key:ref:2 |
      | key:ref:0 | key:ref:3 | key:ref:4 |
      | key:ref:1 | key:ref:4 | key:ref:2 |
      | key:ref:1 | key:ref:4 | key:ref:3 |
    Then get answers of typeql read query group aggregate
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
    Then group aggregate values are
      | owner     | value |
      | key:ref:0 | 4     |
      | key:ref:1 | 2     |


  Scenario: the maximum value for a particular variable within each answer group can be retrieved using a group 'max'
    Given typeql insert
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

    Given session opens transaction of type: read
    When get answers of typeql read query group aggregate
      """
      match
        $x isa company;
        $y isa person, has age $z;
        ($x, $y) isa employment;

      group $x;
      max $z;
      """
    Then group aggregate values are
      | owner     | value |
      | key:ref:0 | 57    |
      | key:ref:1 | 45    |


  Scenario: Grouped aggregates can be performed on value variables
    Given typeql insert
      """
      insert
        $a1 isa person, has name "Alice", has age 22, has ref 0;
        $a2 isa person, has name "Alice", has age 18, has ref 1;
        $b1 isa person, has name "Bob", has age 21, has ref 2;
        $b2 isa person, has name "Bob", has age 24, has ref 3;
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql read query group aggregate
      """
      match
       $p isa person, has name $name, has age $a;
       ?n = $name;
       ?to25 = 25 - $a;
      get   ?n, ?to25;
      group ?n; sum ?to25;
      """
    Then group aggregate values are
      | owner              | value |
      | value:string:Alice |  10   |
      | value:string:Bob   |   5   |


  Scenario: Grouped standard deviation aggregate of one value returns an empty group value
    Given connection close all sessions
    Given connection open schema session for database: typedb
    Given session opens transaction of type: write
    Given typeql define
      """
      define
      income sub attribute, value double;
      person owns income;
      """
    Given transaction commits
    Given connection close all sessions

    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
    """
    insert
    $x isa person, has income 100.0, has ref 0;
    """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql read query group aggregate
      """
      match $x isa person, has income $y;
      get $x, $y;
      group $x;
      std $y;
      """
    Then group aggregate answer value is empty
