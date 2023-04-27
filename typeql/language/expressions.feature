#
# Copyright (C) 2022 Vaticle
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
Feature: TypeQL Match Queries with expressions

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
    Given connection close all sessions


  Scenario: A value variable must have exactly one assignment constraint
    Given connection open data session for database: typedb

    Given session opens transaction of type: read
    When typeql match; throws exception containing "The value variable '?v' is never assigned to"
    """
      match
        $x isa person, has age $a, has age $h;
        ?v == $a;
        ?v > $h;
      get
        $x, ?v;
      """

    Given session opens transaction of type: read
    When typeql match; throws exception containing "The value variable '?v' is assigned to more than once"
    """
      match
        $x isa person, has age $a, has age $h;
        ?v = $a * 2;
        ?v = $h / 2;
      get
        $x, ?v;
      """


  Scenario: A value variable's assignment constraint may not be in a negation
    Given connection open data session for database: typedb
    Given session opens transaction of type: read
    When typeql match; throws exception containing "The value variable '?v' is never assigned to"
    """
      match
        $x isa person, has age $a, has age $h;
        not { ?v = $a / 2;};
        ?v > $h;
      get
        $x, ?v;
      """


  Scenario: Value variable assignments may not form cycles
    Given connection open data session for database: typedb

    Given session opens transaction of type: read
    When typeql match; throws exception containing "A cyclic assignment between value variables was detected"
    """
      match
        $x isa person, has age $a, has age $h;
        ?v = $a + ?v;
      get
        $x, ?v;
      """

    Given session opens transaction of type: read
    When typeql match; throws exception containing "A cyclic assignment between value variables was detected"
    """
      match
        $x isa person, has age $a, has age $h;
        ?u = $a + ?v;
        ?v = $h + ?u;
      get
        $x, ?u, ?v;
      """


  Scenario: Value variables can cross over into negations
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $x "Lisa" isa name;
      $y 16 isa age;
      $z isa person, has name $x, has age $y;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match
        $z isa person, has name $x, has age $y;
        ?y2 = $y * 2;
        not { $y > ?y2; };
      get $x, $y;
      """
    Then uniquely identify answer concepts
      | x               |
      | value:name:Lisa |


  Scenario: Value variables and concept variables may not share name
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $x "Lisa" isa name;
      $y 16 isa age;
      $z isa person, has name $x, has age $y;
      """
    Given transaction commits

    Given session opens transaction of type: read
    Then typeql match; throws exception containing "Invalid Query Pattern: The variable name 'y' was used both for a concept variable and a value variable"
      """
      match
        $z isa person, has age $y;
        ?y = $y;
      get $z, $y, ?y;
      """


  Scenario: Test operator definitions
    Given connection open data session for database: typedb
    Given session opens transaction of type: read

    When get answers of typeql match
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
      | a               | b               | c                | d                |
      | raw:double: 9.0 | raw:double: 3.0 | raw:double: 18.0 | raw:double: 2.0  |

    When get answers of typeql match
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
      | a           | b          | c           | d                |
      | raw:long: 9 | raw:long:3 | raw:long:18 | raw:double: 2.0  |

    When get answers of typeql match
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
      | a               | b               | c                | d                |
      | raw:double: 9.0 | raw:double: 3.0 | raw:double: 18.0 | raw:double: 2.0  |

    When get answers of typeql match
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
      | a               | b               | c                | d                |
      | raw:double: 9.0 | raw:double: 3.0 | raw:double: 18.0 | raw:double: 2.0  |


  Scenario: Test functions
    Given connection open data session for database: typedb
    Given session opens transaction of type: read

    When get answers of typeql match
    """
      match
        ?a = floor(3/2);
        ?b = ceil(3/2);
      get
        ?a, ?b;
      """
    Then uniquely identify answer concepts
      | a           | b           |
      | raw:long: 1 | raw:long: 2 |

    When get answers of typeql match
    """
      match
        ?a = round(2/3);
        ?b = abs(-1/2);
      get
        ?a, ?b;
      """
    Then uniquely identify answer concepts
      | a           | b               |
      | raw:long: 1 | raw:double: 0.5 |

    When get answers of typeql match
    """
      match
        ?a = max(2, -3);
        ?b = min(2, -3);
      get
        ?a, ?b;
      """
    Then uniquely identify answer concepts
      | a           | b            |
      | raw:long: 2 | raw:long: -3 |



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
    When get answers of typeql match
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
      | name             | hours-since-18     | bmi                  |
      | value:name:Steve | raw:double:17532.0 | raw:double:23.4375   |


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
    When get answers of typeql match
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
      | value:name:b22.2 |

    Given session opens transaction of type: read
    When get answers of typeql match
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
      | value:name:b22.2 |
      | value:name:b25.0 |


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
    When get answers of typeql match
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
      | value:name:b22.2 |

    Given session opens transaction of type: read
    When get answers of typeql match
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
      | value:name:b22.2 |
      | value:name:b25.0 |


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
    When get answers of typeql match
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
      | value:name:b22.2 |

    Given session opens transaction of type: read
    When get answers of typeql match
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
      | value:name:b22.2 |
      | value:name:b25.0 |


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
    When get answers of typeql match
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
      | value:name:b22.2 |

    Given session opens transaction of type: read
    When get answers of typeql match
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
      | value:name:b22.2 |
      | value:name:b25.0 |


  Scenario: Expressions which perform illegal arithmetic throw appropriate errors
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
    Then typeql match; throws exception containing "Invalid expression operation: An error occured while evaluating an expression"
      """
      match
        $p isa person, has age $a;
        ?div-zero = $a / 0;
      get $p;
      """
