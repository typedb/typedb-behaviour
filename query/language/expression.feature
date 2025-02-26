# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: TypeQL Query with Expressions

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
      entity person,
        owns name @key,
        owns age,
        owns height,
        owns weight;
      attribute name @independent, value string;
      attribute age @independent, value integer;
      attribute height @independent, value integer;
      attribute weight @independent, value integer;

      attribute limit-double @independent, value double;
      """
    Given transaction commits


  Scenario: A value variable must have exactly one assignment constraint in the same branch of a pipeline
    Given connection open write transaction for database: typedb
    Given typeql write query
    """
    insert $p isa person, has name "Lisa", has age 10, has height 180;
    """
    Given transaction commits

    Given connection open read transaction for database: typedb
    Then typeql read query; fails with a message containing: "Invalid query containing unbound concept variable v"
    """
      match
        $x isa person, has age $a, has height $h;
        $v == $a;
        $v > $h;
      select
        $x, $v;
      """
    Given transaction closes

    Given connection open read transaction for database: typedb
    Then typeql read query; fails with a message containing: "Variable 'v' cannot be assigned to multiple times in the same branch."
    """
      match
        $x isa person, has age $a, has height $h;
        let $v = $a * 2;
        let $v = $h * 2;
      select
        $x, $v;
      """
    Then typeql read query; fails with a message containing: "The variable 'v' cannot be assigned to, as it was already assigned in a the previous stage."
    """
      match
        $x isa person, has age $a, has height $h;
        let $v = $a * 2;
      match
        let $v = $h * 2;
      select
        $x, $v;
      """
    Then typeql read query; fails with a message containing: "Variable 'v' cannot be assigned to multiple times in the same branch."
    """
      match
        $x isa person, has age $a, has height $h;
        let $v0 = $v; # TODO: Remove. once rebased on Dmitrii's changes
        { let $v = $a * 2; } or { let $v = 0; };
        { let $v = $h * 2; } or { let $v = 1; };
      select
        $x, $v;
      """
    Then typeql read query; fails with a message containing: "The variable 'v' cannot be assigned to, as it was already assigned in a the previous stage"
    """
      match
        $x isa person, has age $a, has height $h;
        let $v0 = $v; # TODO: Remove. once rebased on Dmitrii's changes
        { let $v = $a * 2; } or { let $v = 1; };
      match
        { let $v = $h * 2; } or { let $v = 2; };
      select
        $x, $v;
      """
    Then get answers of typeql read query
    """
      match
        $x isa person, has age $a, has height $h;
        let $v0 = $v; # TODO: Remove. once rebased on Dmitrii's changes
        { let $v = $a * 2; } or { let $v = $h * 2; };
      select
        $v;
      """
    Then uniquely identify answer concepts
      | v                 |
      | value:integer:20  |
      | value:integer:360 |


  Scenario: A value variable must have exactly one assignment constraint recursively
    Given connection open read transaction for database: typedb
    Then typeql read query; fails with a message containing: "Variable 'v' cannot be assigned to multiple times in the same branch."
    """
      match
        $x isa person, has age $a, has height $h;
        let $v = $a + $h;
        not { $a > 10; not { let $v = 10; }; };
      select
        $x, $v;
      """


  @ignore
  # TODO: 3.x: The beam search unwraps a None because there are no valid plans.
  Scenario: When no evaluation order can bind the variables in an expression, an error is returned.
    Given connection open read transaction for database: typedb
    Then typeql read query; fails with a message containing: "TODO"
    """
      match
        $x isa person, has age $a, has height $h;
        $v > $h;
        not { let $v = $a / 2;};
      select
        $x, $v;
      """


  Scenario: Value variable assignments may not form cycles
    Given connection open read transaction for database: typedb
    Then typeql read query; fails with a message containing: "illegal circular expression assignment & usage"
    """
      match
        $x isa person, has age $a, has height $h;
        let $v = $a + $v;
      select
        $x, $v;
      """
    Given transaction closes

    Given connection open read transaction for database: typedb
    Then typeql read query; fails with a message containing: "illegal circular expression assignment & usage"
    """
      match
        $x isa person, has age $a, has height $h;
        let $u = $a + $v;
        let $v = $h + $u;
      select
        $x, $u, $v;
      """


  Scenario: Value variables can cross over into negations
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x isa name "Lisa";
      $y isa age 16;
      $z isa person, has $x, has $y;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
        $z isa person, has name $x, has age $y;
        let $y2 = $y * 2;
        not { $y > $y2; };
      select $x, $y;
      """
    Then uniquely identify answer concepts
      | x               |
      | attr:name:Lisa  |


  Scenario: Value variables and concept variables may not share name
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x isa name "Lisa";
      $y isa age 16;
      $z isa person, has $x, has $y;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    Then typeql read query; fails with a message containing: "The variable 'y' cannot be declared as both a 'Value' and as a 'Attribute'"
      """
      match
        $z isa person, has age $y;
        let $y = $y;
      select $z, $y, $y;
      """


  Scenario: All assignments of value variables must have the same value type
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $p isa person, has name "Lisa", has age 16;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    Then typeql read query; fails with a message containing: "The variable 'a' must have a single possible value type to be used in an expression"
      """
      match
      $p isa person, has $a;
      let $v = $a;
      """
    Then typeql read query; fails with a message containing: "All assignments of the variable 'v' must have the same value type."
      """
      match
      $p isa person;
      let $v0 = $v; # TODO: Remove. once rebased on Dmitrii's changes
      { $p has age $a; let $v = $a; } or
      { $p has name $n; let $v = $n; };
      """
    Then typeql read query; fails with a message containing: "All assignments of the variable 'v' must have the same value type."
      """
      match
      $p isa person, has age $a;
      let $v0 = $v; # TODO: Remove. once rebased on Dmitrii's changes
      { let $v = $a * 2; } or
      { let $v = $a / 2.0; };
      """
#  All assignments of the variable 'a' must have the same value type



  Scenario: Test unary minus sign
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x isa age 16;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    Then get answers of typeql read query
      """
      match
        $x isa age;
        let $const = -10;
        let $plus-negative = $x + -10;
        let $minus-negative = $x - -10;
      """
    Then uniquely identify answer concepts
      | x            | const              | plus-negative    | minus-negative    |
      | attr:age:16  | value:integer:-10  | value:integer:6  | value:integer:26  |


  Scenario: Test operator definitions - double double
    Given connection open read transaction for database: typedb
    When get answers of typeql read query
    """
      match
        let $a = 6.0 + 3.0;
        let $b = 6.0 - 3.0;
        let $c = 6.0 * 3.0;
        let $d = 6.0 / 3.0;
      select
        $a, $b, $c, $d;
      """
    Then uniquely identify answer concepts
      | a                | b                | c                 | d                 |
      | value:double:9.0 | value:double:3.0 | value:double:18.0 | value:double:2.0  |


  Scenario: Test operator definitions - integer integer
    Given connection open read transaction for database: typedb

    When get answers of typeql read query
    """
      match
        let $a = 6 + 3;
        let $b = 6 - 3;
        let $c = 6 * 3;
        let $d = 6 / 3;
      select
        $a, $b, $c, $d;
      """
    Then uniquely identify answer concepts
      | a               | b               | c                | d                 |
      | value:integer:9 | value:integer:3 | value:integer:18 | value:double:2.0  |


  Scenario: Test operator definitions - double integer
    Given connection open read transaction for database: typedb

    When get answers of typeql read query
    """
      match
        let $a = 6.0 + 3;
        let $b = 6.0 - 3;
        let $c = 6.0 * 3;
        let $d = 6.0 / 3;
      select
        $a, $b, $c, $d;
      """
    Then uniquely identify answer concepts
      | a                | b                | c                 | d                 |
      | value:double:9.0 | value:double:3.0 | value:double:18.0 | value:double:2.0  |


  Scenario: Test operator definitions - integer double
    Given connection open read transaction for database: typedb

    When get answers of typeql read query
    """
      match
        let $a = 6 + 3.0;
        let $b = 6 - 3.0;
        let $c = 6 * 3.0;
        let $d = 6 / 3.0;
      select
        $a, $b, $c, $d;
      """
    Then uniquely identify answer concepts
      | a                | b                | c                 | d                 |
      | value:double:9.0 | value:double:3.0 | value:double:18.0 | value:double:2.0  |


  Scenario: Test operator definitions - decimal decimal
    Given connection open read transaction for database: typedb
    When get answers of typeql read query
    """
      match
        let $a = 6.0dec + 3.0dec;
        let $b = 6.0dec - 3.0dec;
        let $c = 6.0dec * 3.0dec;
        let $d = 6.0dec / 3.0dec;
      select
        $a, $b, $c, $d;
      """
    Then uniquely identify answer concepts
      | a                 | b                 | c                  | d                 |
      | value:decimal:9.0 | value:decimal:3.0 | value:decimal:18.0 | value:double:2.0  |


  Scenario: Test operator definitions - integer decimal
    Given connection open read transaction for database: typedb

    When get answers of typeql read query
    """
      match
        let $a = 6 + 3.0dec;
        let $b = 6 - 3.0dec;
        let $c = 6 * 3.0dec;
        let $d = 6 / 3.0dec;
      select
        $a, $b, $c, $d;
      """
    Then uniquely identify answer concepts
      | a                 | b                 | c                  | d                 |
      | value:decimal:9.0 | value:decimal:3.0 | value:decimal:18.0 | value:double:2.0  |


  Scenario: Test operator definitions - decimal integer
    Given connection open read transaction for database: typedb
    When get answers of typeql read query
    """
      match
        let $a = 6.0dec + 3;
        let $b = 6.0dec - 3;
        let $c = 6.0dec * 3;
        let $d = 6.0dec / 3;
      select
        $a, $b, $c, $d;
      """
    Then uniquely identify answer concepts
      | a                 | b                 | c                  | d                 |
      | value:decimal:9.0 | value:decimal:3.0 | value:decimal:18.0 | value:double:2.0  |


  Scenario: Test operator definitions - double decimal
    Given connection open read transaction for database: typedb
    When get answers of typeql read query
    """
      match
        let $a = 6.0 + 3.0dec;
        let $b = 6.0 - 3.0dec;
        let $c = 6.0 * 3.0dec;
        let $d = 6.0 / 3.0dec;
      select
        $a, $b, $c, $d;
      """
    Then uniquely identify answer concepts
      | a                | b                | c                 | d                 |
      | value:double:9.0 | value:double:3.0 | value:double:18.0 | value:double:2.0  |


  Scenario: Test operator definitions - decimal double
    Given connection open read transaction for database: typedb
    When get answers of typeql read query
    """
      match
        let $a = 6.0dec + 3.0;
        let $b = 6.0dec - 3.0;
        let $c = 6.0dec * 3.0;
        let $d = 6.0dec / 3.0;
      select
        $a, $b, $c, $d;
      """
    Then uniquely identify answer concepts
      | a                | b                | c                 | d                 |
      | value:double:9.0 | value:double:3.0 | value:double:18.0 | value:double:2.0  |


  Scenario: Test functions
    Given connection open read transaction for database: typedb
    When get answers of typeql read query
    """
      match
        let $a = floor(3/2);
        let $b = ceil(3/2);
      select
        $a, $b;
      """
    Then uniquely identify answer concepts
      | a               | b               |
      | value:integer:1 | value:integer:2 |

    When get answers of typeql read query
    """
      match
        let $a = round(2/3);
        let $b = abs(-1/2);
      select
        $a, $b;
      """
    Then uniquely identify answer concepts
      | a               | b                |
      | value:integer:1 | value:double:0.5 |
#    # TODO: 3.x: Re-enable once implemented
#    When get answers of typeql read query
#    """
#      match
#        let $a = max(2, -3);
#        let $b = min(2, -3, -5);
#      select
#        $a, $b;
#      """
#    Then uniquely identify answer concepts
#      | a               | b                |
#      | value:integer:2 | value:integer:-5 |



  Scenario: Test operators on variables
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert $x isa person,
          has name 'Steve',
          has age 20,
          has height 160,
          has weight 60;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
        $p isa person, has name $name,
         has age $a, has weight $w, has height $h;

        let $bmi = $w/($h/100 * $h/100);

        let $days-since-18 = ($a - 18) * 365.25;
        let $hours-per-day = 24;
        let $hours-since-18 = $hours-per-day * $days-since-18;
      select
        $name, $hours-since-18, $bmi;
      """

    Then uniquely identify answer concepts
      | name             | hours-since-18       | bmi                    |
      | attr:name:Steve  | value:double:17532.0 | value:double:23.4375   |


  Scenario: Test predicates between value variables and constants
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
        $x isa person, has name "b25.0", has height 160, has weight 64;
        $y isa person, has name "b22.2", has height 180, has weight 72;
        $z isa person, has name "b26.1", has height 175, has weight 80;
        $l isa limit-double 25;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
        $p isa person, has name $name, has height $h, has weight $w;
        let $bmi = $w/($h/100 * $h/100);
        $bmi < 25;
      select
        $name;
      """

    Then uniquely identify answer concepts
      | name             |
      | attr:name:b22.2 |

    When get answers of typeql read query
      """
      match
        $p isa person, has name $name, has height $h, has weight $w;
        let $bmi = $w/($h/100 * $h/100);
        $bmi <= 25;
      select
        $name;
      """

    Then uniquely identify answer concepts
      | name             |
      | attr:name:b22.2 |
      | attr:name:b25.0 |


  Scenario: Test predicates between value variables and value variables
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
        $x isa person, has name "b25.0", has height 160, has weight 64;
        $y isa person, has name "b22.2", has height 180, has weight 72;
        $z isa person, has name "b26.1", has height 175, has weight 80;
        $l isa limit-double 25;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
        $p isa person, has name $name, has height $h, has weight $w;
        let $bmi = $w/($h/100 * $h/100);
        let $lim = 25;
        $bmi < $lim;
      select
        $name;
      """

    Then uniquely identify answer concepts
      | name             |
      | attr:name:b22.2 |

    When get answers of typeql read query
      """
      match
        $p isa person, has name $name, has height $h, has weight $w;
        let $bmi = $w/($h/100 * $h/100);
        let $lim = 25;
        $bmi <= $lim;
      select
        $name;
      """

    Then uniquely identify answer concepts
      | name             |
      | attr:name:b22.2 |
      | attr:name:b25.0 |


  Scenario: Test predicates between value variables and thing variables
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
        $x isa person, has name "b25.0", has height 160, has weight 64;
        $y isa person, has name "b22.2", has height 180, has weight 72;
        $z isa person, has name "b26.1", has height 175, has weight 80;
        $l isa limit-double 25;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
        $p isa person, has name $name, has height $h, has weight $w;
        let $bmi = $w/($h/100 * $h/100);
        $lim isa limit-double;
        $bmi < $lim;
      select
        $name;
      """

    Then uniquely identify answer concepts
      | name             |
      | attr:name:b22.2 |

    When get answers of typeql read query
      """
      match
        $p isa person, has name $name, has height $h, has weight $w;
        let $bmi = $w/($h/100 * $h/100);
        $lim isa limit-double;
        $bmi <= $lim;
      select
        $name;
      """

    Then uniquely identify answer concepts
      | name             |
      | attr:name:b22.2 |
      | attr:name:b25.0 |


  Scenario: Test predicates between thing variables and value variables
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
        $x isa person, has name "b25.0", has height 160, has weight 64;
        $y isa person, has name "b22.2", has height 180, has weight 72;
        $z isa person, has name "b26.1", has height 175, has weight 80;
        $l isa limit-double 25;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
        $p isa person, has name $name, has height $h, has weight $w;
        let $bmi = $w/($h/100 * $h/100);
        $lim isa limit-double;
        $lim > $bmi;
      select
        $name;
      """

    Then uniquely identify answer concepts
      | name             |
      | attr:name:b22.2 |

    When get answers of typeql read query
      """
      match
        $p isa person, has name $name, has height $h, has weight $w;
        let $bmi = $w/($h/100 * $h/100);
        $lim isa limit-double;
        $lim >= $bmi;
      select
        $name;
      """

    Then uniquely identify answer concepts
      | name             |
      | attr:name:b22.2 |
      | attr:name:b25.0 |


  Scenario: Division by zero throws a useful error
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $n isa name "Baby";
      $a isa age 20;
      $p isa person, has $n, has $a;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    Then typeql read query; fails with a message containing: "Division failed"
      """
      match
        $p isa person, has age $a;
        let $div-zero = $a / 0.0;
      select $p;
      """


  Scenario: Test operator precedence
    Given connection open read transaction for database: typedb
    Given get answers of typeql read query
    """
    match
      let $a = 5 * 4 + 3;
      let $b = 3 + 4 * 5;
    """
    Then uniquely identify answer concepts
      | a                 | b                 |
      | value:integer:23  | value:integer:23  |
    Given get answers of typeql read query
    """
    match
      let $a = 6 * 5 ^ 3 + 2;
      let $b = (6 * (5 ^ 3)) + 2;
    """
    Then uniquely identify answer concepts
      | a                  | b                  |
      | value:double:752.0 | value:double:752.0 |


  Scenario: Operations other than exponentiation are right-associative
    Given connection open read transaction for database: typedb
    Given get answers of typeql read query
    """
    match
      let $a = 6 - 2 - 3;
      let $b = (6 - 2) - 3;
      let $c = 6 - (2 - 3);
    """
    Then uniquely identify answer concepts
      | a               | b               | c               |
      | value:integer:1 | value:integer:1 | value:integer:7 |
    Given get answers of typeql read query
    """
    match
      let $a = 6 / 2 / 3;
      let $b = (6 / 2) / 3;
      let $c = 6 / (2 / 3);
    """
    Then uniquely identify answer concepts
      | a                | b                | c                |
      | value:double:1.0 | value:double:1.0 | value:double:9.0 |
    Given get answers of typeql read query
    """
    match
      let $a = 6 / 2 * 3;
      let $b = (6 / 2) * 3;
      let $c = 6 / (2 * 3);
    """
    Then uniquely identify answer concepts
      | a                | b                | c                |
      | value:double:9.0 | value:double:9.0 | value:double:1.0 |

    Given get answers of typeql read query
    """
    match
      let $a = 5 * 4 % 3 * 2;
      let $b = ((5 * 4) % 3) * 2;
    """
    Then uniquely identify answer concepts
      | a               | b               |
      | value:integer:4 | value:integer:4 |

    # Exponentiation
    Given get answers of typeql read query
    """
    match
      let $a = 2 ^ 2 ^ 2 ^ 2;
      let $b = ((2 ^ 2) ^ 2) ^ 2;
      let $c = 2 ^ (2 ^ (2 ^ 2));
    """
    Then uniquely identify answer concepts
      | a                  | b                  | c                  |
      | value:double:65536 | value:double:256   | value:double:65536 |

