# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: TypeQL Get Query with Expressions

  Background: Open connection and create a simple extensible schema
    Given typedb starts
    Given connection opens with default authentication
    Given connection is open: true
    Given connection has 0 databases
    Given connection create database: typedb
    Given connection open schema transaction for database: typedb

    Given typeql schema query
      """
      define
      person sub entity,
        owns name @key,
        owns age,
        owns height,
        owns weight;
      name sub attribute, value string;
      age sub attribute, value long;
      height sub attribute, value long;
      weight sub attribute, value long;

      limit-double sub attribute, value double;
      """
    Given transaction commits


  Scenario: A value variable must have exactly one assignment constraint in the same scope
    Given connection open read transaction for database: typedb
    When typeql throws exception containing "value variable '?v' is never assigned to"
    """
      match
        $x isa person, has age $a, has age $h;
        ?v == $a;
        ?v > $h;
      get
        $x, ?v;
      """

    Given connection open read transaction for database: typedb
    When typeql throws exception containing "value variable '?v' can only have one assignment in the first scope"
    """
      match
        $x isa person, has age $a, has age $h;
        ?v = $a * 2;
        ?v = $h / 2;
      get
        $x, ?v;
      """


  Scenario: A value variable must have exactly one assignment constraint recursively
    Given connection open read transaction for database: typedb
    When typeql throws exception containing "value variable '?v' can only have one assignment in the first scope"
    """
      match
        $x isa person, has age $a, has age $h;
        ?v  = $a + $h;
        not { $a > 10; not { ?v = 10; }; };
      get
        $x, ?v;
      """


  Scenario: A value variable's assignment must be in the highest scope
    Given connection open read transaction for database: typedb
    When typeql throws exception containing "value variable '?v' can only have one assignment in the first scope"
    """
      match
        $x isa person, has age $a, has age $h;
        ?v > $h;
        not { ?v = $a / 2;};
      get
        $x, ?v;
      """


  Scenario: Value variable assignments may not form cycles
    Given connection open read transaction for database: typedb
    When typeql throws exception containing "cyclic assignment between value variables was detected"
    """
      match
        $x isa person, has age $a, has age $h;
        ?v = $a + ?v;
      get
        $x, ?v;
      """

    Given connection open read transaction for database: typedb
    When typeql throws exception containing "cyclic assignment between value variables was detected"
    """
      match
        $x isa person, has age $a, has age $h;
        ?u = $a + ?v;
        ?v = $h + ?u;
      get
        $x, ?u, ?v;
      """


  Scenario: Value variables can cross over into negations
    Given connection open write transaction for database: typedb
    Given typeql insert
      """
      insert
      $x "Lisa" isa name;
      $y 16 isa age;
      $z isa person, has name $x, has age $y;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
        $z isa person, has name $x, has age $y;
        ?y2 = $y * 2;
        not { $y > ?y2; };
      get $x, $y;
      """
    Then uniquely identify answer concepts
      | x               |
      | attr:name:Lisa  |


  Scenario: Value variables and concept variables may not share name
    Given connection open write transaction for database: typedb
    Given typeql insert
      """
      insert
      $x "Lisa" isa name;
      $y 16 isa age;
      $z isa person, has name $x, has age $y;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    Then typeql throws exception containing "The variable(s) named 'y' cannot be used for both concept variables and a value variables"
      """
      match
        $z isa person, has age $y;
        ?y = $y;
      get $z, $y, ?y;
      """


  Scenario: Test unary minus sign
    Given connection open write transaction for database: typedb
    Given typeql insert
      """
      insert
      $x 16 isa age;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    Then get answers of typeql read query
      """
      match
        $x isa age;
        ?const = -10;
        ?plus-negative = $x + -10;
        ?minus-negative = $x - -10;

      """
    Then uniquely identify answer concepts
      | x            | const           | plus-negative  | minus-negative  |
      | attr:age:16  | value:long:-10  | value:long:6   | value:long:26   |


  Scenario: Test operator definitions
    Given connection open read transaction for database: typedb
    When get answers of typeql read query
    """
      match
        ?a = 6.0 + 3.0;
        ?b = 6.0 - 3.0;
        ?c = 6.0 * 3.0;
        ?d = 6.0 / 3.0;
      get
        ?a, ?b, ?c, ?d;
      """
    Then uniquely identify answer concepts
      | a                 | b                 | c                  | d                  |
      | value:double: 9.0 | value:double: 3.0 | value:double: 18.0 | value:double: 2.0  |

    When get answers of typeql read query
    """
      match
        ?a = 6 + 3;
        ?b = 6 - 3;
        ?c = 6 * 3;
        ?d = 6 / 3;
      get
        ?a, ?b, ?c, ?d;
      """
    Then uniquely identify answer concepts
      | a             | b            | c             | d                  |
      | value:long: 9 | value:long:3 | value:long:18 | value:double: 2.0  |

    When get answers of typeql read query
    """
      match
        ?a = 6.0 + 3;
        ?b = 6.0 - 3;
        ?c = 6.0 * 3;
        ?d = 6.0 / 3;
      get
        ?a, ?b, ?c, ?d;
      """
    Then uniquely identify answer concepts
      | a                 | b                 | c                  | d                  |
      | value:double: 9.0 | value:double: 3.0 | value:double: 18.0 | value:double: 2.0  |

    When get answers of typeql read query
    """
      match
        ?a = 6 + 3.0;
        ?b = 6 - 3.0;
        ?c = 6 * 3.0;
        ?d = 6 / 3.0;
      get
        ?a, ?b, ?c, ?d;
      """
    Then uniquely identify answer concepts
      | a                 | b                 | c                  | d                  |
      | value:double: 9.0 | value:double: 3.0 | value:double: 18.0 | value:double: 2.0  |


  Scenario: Test functions
    Given connection open data session for database: typedb
    Given session opens transaction of type: read

    When get answers of typeql read query
    """
      match
        ?a = floor(3/2);
        ?b = ceil(3/2);
      get
        ?a, ?b;
      """
    Then uniquely identify answer concepts
      | a             | b             |
      | value:long: 1 | value:long: 2 |

    When get answers of typeql read query
    """
      match
        ?a = round(2/3);
        ?b = abs(-1/2);
      get
        ?a, ?b;
      """
    Then uniquely identify answer concepts
      | a             | b                 |
      | value:long: 1 | value:double: 0.5 |

    When get answers of typeql read query
    """
      match
        ?a = max(2, -3);
        ?b = min(2, -3, -5);
      get
        ?a, ?b;
      """
    Then uniquely identify answer concepts
      | a             | b              |
      | value:long: 2 | value:long: -5 |



  Scenario: Test operators on variables
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert $x isa person,
          has name 'Steve',
          has age 20,
          has height 160,
          has weight 60;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql read query
      """
      match
        $p isa person, has name $name,
         has age $a, has weight $w, has height $h;

        ?bmi = $w/($h/100 * $h/100);

        ?days-since-18 = ($a - 18) * 365.25;
        ?hours-per-day = 24;
        ?hours-since-18 = ?hours-per-day * ?days-since-18;
      get
        $name, ?hours-since-18, ?bmi;
      """

    Then uniquely identify answer concepts
      | name             | hours-since-18       | bmi                    |
      | attr:name:Steve  | value:double:17532.0 | value:double:23.4375   |


  Scenario: Test predicates between value variables and constants
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
        $x isa person, has name "b25.0", has height 160, has weight 64;
        $y isa person, has name "b22.2", has height 180, has weight 72;
        $z isa person, has name "b26.1", has height 175, has weight 80;
        $l 25 isa limit-double;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql read query
      """
      match
        $p isa person, has name $name, has height $h, has weight $w;
        ?bmi = $w/($h/100 * $h/100);
        ?bmi < 25;
      get
        $name;
      """

    Then uniquely identify answer concepts
      | name             |
      | attr:name:b22.2 |

    Given session opens transaction of type: read
    When get answers of typeql read query
      """
      match
        $p isa person, has name $name, has height $h, has weight $w;
        ?bmi = $w/($h/100 * $h/100);
        ?bmi <= 25;
      get
        $name;
      """

    Then uniquely identify answer concepts
      | name             |
      | attr:name:b22.2 |
      | attr:name:b25.0 |


  Scenario: Test predicates between value variables and value variables
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
        $x isa person, has name "b25.0", has height 160, has weight 64;
        $y isa person, has name "b22.2", has height 180, has weight 72;
        $z isa person, has name "b26.1", has height 175, has weight 80;
        $l 25 isa limit-double;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql read query
      """
      match
        $p isa person, has name $name, has height $h, has weight $w;
        ?bmi = $w/($h/100 * $h/100);
        ?lim = 25;
        ?bmi < ?lim;
      get
        $name;
      """

    Then uniquely identify answer concepts
      | name             |
      | attr:name:b22.2 |

    Given session opens transaction of type: read
    When get answers of typeql read query
      """
      match
        $p isa person, has name $name, has height $h, has weight $w;
        ?bmi = $w/($h/100 * $h/100);
        ?lim = 25;
        ?bmi <= ?lim;
      get
        $name;
      """

    Then uniquely identify answer concepts
      | name             |
      | attr:name:b22.2 |
      | attr:name:b25.0 |


  Scenario: Test predicates between value variables and thing variables
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
        $x isa person, has name "b25.0", has height 160, has weight 64;
        $y isa person, has name "b22.2", has height 180, has weight 72;
        $z isa person, has name "b26.1", has height 175, has weight 80;
        $l 25 isa limit-double;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql read query
      """
      match
        $p isa person, has name $name, has height $h, has weight $w;
        ?bmi = $w/($h/100 * $h/100);
        $lim isa limit-double;
        ?bmi < $lim;
      get
        $name;
      """

    Then uniquely identify answer concepts
      | name             |
      | attr:name:b22.2 |

    Given session opens transaction of type: read
    When get answers of typeql read query
      """
      match
        $p isa person, has name $name, has height $h, has weight $w;
        ?bmi = $w/($h/100 * $h/100);
        $lim isa limit-double;
        ?bmi <= $lim;
      get
        $name;
      """

    Then uniquely identify answer concepts
      | name             |
      | attr:name:b22.2 |
      | attr:name:b25.0 |


  Scenario: Test predicates between thing variables and value variables
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
        $x isa person, has name "b25.0", has height 160, has weight 64;
        $y isa person, has name "b22.2", has height 180, has weight 72;
        $z isa person, has name "b26.1", has height 175, has weight 80;
        $l 25 isa limit-double;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql read query
      """
      match
        $p isa person, has name $name, has height $h, has weight $w;
        ?bmi = $w/($h/100 * $h/100);
        $lim isa limit-double;
        $lim > ?bmi;
      get
        $name;
      """

    Then uniquely identify answer concepts
      | name             |
      | attr:name:b22.2 |

    Given session opens transaction of type: read
    When get answers of typeql read query
      """
      match
        $p isa person, has name $name, has height $h, has weight $w;
        ?bmi = $w/($h/100 * $h/100);
        $lim isa limit-double;
        $lim >= ?bmi;
      get
        $name;
      """

    Then uniquely identify answer concepts
      | name             |
      | attr:name:b22.2 |
      | attr:name:b25.0 |


  Scenario: Division by zero throws a useful error
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $n "Baby" isa name;
      $a 20 isa age;
      $p isa person, has name $n, has age $a;
      """
    Given transaction commits

    Given session opens transaction of type: read
    Then typeql throws exception containing "division by zero"
      """
      match
        $p isa person, has age $a;
        ?div-zero = $a / 0.0;
      get $p;
      """
