#
# Copyright (C) 2021 Vaticle
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
Feature: Value Predicate Resolution

  Background: Set up databases for resolution testing
    Given connection has been opened
    Given connection does not have any database
    Given connection create database: typedb
    Given connection open schema session for database: typedb
    Given session opens transaction of type: write
    Given typeql define
      """
      define

      person sub entity,
        owns unrelated-attribute,
        owns sub-string-attribute,
        owns name,
        owns age,
        owns is-old;

      tortoise sub entity,
        owns age,
        owns is-old;

      soft-drink sub entity,
        owns name,
        owns retailer,
        owns price;

      string-attribute sub attribute, value string, abstract;
      sub-string-attribute sub string-attribute;
      retailer sub attribute, value string;
      age sub attribute, value long;
      name sub attribute, value string;
      is-old sub attribute, value boolean;
      price sub attribute, value double;
      unrelated-attribute sub attribute, value string;
      """
    Given transaction commits
    # each scenario specialises the schema further
    Given session opens transaction of type: write

  Scenario: a rule can infer an attribute ownership based on a value predicate
    Given typeql define
      """
      define
      rule tortoises-become-old-at-age-1-year: when {
        $x isa tortoise, has age $a;
        $a > 0;
      } then {
        $x has is-old true;
      };
      """
    Given transaction commits
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $se isa tortoise, has age 1;
      """
    Given transaction commits
    Given correctness checker is initialised
    When get answers of typeql match
      """
      match $x has is-old $r;
      """
    Then answer size is: 1
    Then check all answers and explanations are sound
    Then check all answers and explanations are complete


  # TODO: re-enable all steps once materialised database counts duplicate attributes only once
  Scenario Outline: when querying for inferred attributes with '<op>', the answers matching the predicate are returned
    Given typeql define
      """
      define
      lucky-number sub attribute, value long;
      person owns lucky-number;
      rule rule-1337: when { $x isa person; } then { $x has lucky-number 1337; };
      rule rule-1667: when { $x isa person; } then { $x has lucky-number 1667; };
      rule rule-1997: when { $x isa person; } then { $x has lucky-number 1997; };
      """
    Given transaction commits
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $x isa person;
      $y isa person;
      """
    Given transaction commits
    Given correctness checker is initialised
    When get answers of typeql match
      """
      match
        $x isa person, has lucky-number $n;
        $n <op> 1667;
      """
    Then answer size is: <answer-size>
    Then check all answers and explanations are sound
    Then check all answers and explanations are complete

    Examples:
      | op | answer-size |
      | >  | 2           |
      | >= | 4           |
      | <  | 2           |
      | <= | 4           |
      | =  | 2           |
      | != | 4           |


  # TODO: re-enable all steps when fixed (#75)
  Scenario Outline: when both sides of a '<op>' comparison are inferred attributes, all answers satisfy the predicate
    Given typeql define
      """
      define
      lucky-number sub attribute, value long;
      person owns lucky-number;
      rule rule-1337: when { $x isa person; } then { $x has lucky-number 1337; };
      rule rule-1667: when { $x isa person; } then { $x has lucky-number 1667; };
      """
    Given transaction commits
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $x isa person, has name "Alice";
      $y isa person, has name "Bob";
      """
    Given transaction commits
    Given correctness checker is initialised
    When get answers of typeql match
      """
      match
        $x isa person, has name "Alice", has lucky-number $m;
        $y isa person, has name "Bob", has lucky-number $n;
        $m <op> $n;
      """
    Then answer size is: <answer-size>
    Then check all answers and explanations are sound
    Then check all answers and explanations are complete

    Examples:
      | op | answer-size |
      | >  | 1           |
      | >= | 3           |
      | <  | 1           |
      | <= | 3           |
      | =  | 2           |
      | != | 2           |


  # TODO: re-enable all steps when fixed (#75)
  Scenario Outline: when comparing an inferred attribute and a bound variable with '<op>', answers satisfy the predicate
    Given typeql define
      """
      define
      lucky-number sub attribute, value long;
      person owns lucky-number;
      rule rule-1337: when { $x isa person; } then { $x has lucky-number 1337; };
      rule rule-1667: when { $x isa person; } then { $x has lucky-number 1667; };
      rule rule-1997: when { $x isa person; } then { $x has lucky-number 1997; };
      """
    Given transaction commits
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $x isa person, has name "Alice";
      $y isa person, has name "Bob";
      """
    Given transaction commits
    Given correctness checker is initialised
    When get answers of typeql match
      """
      match
        $x isa person, has name "Alice", has lucky-number $m;
        $y isa person, has name "Bob", has lucky-number $n;
        $m <op> $n;
        $n <op> 1667;
      """
    Then answer size is: <answer-size>
    Then check all answers and explanations are sound
    Then check all answers and explanations are complete

    Examples:
      | op | answer-size |
      | >  | 0           |
      | >= | 3           |
      | <  | 0           |
      | <= | 3           |
      | =  | 1           |
      | != | 4           |


  Scenario: inferred attributes can be matched by inequality to a variable that is equal to a specified value
    Given typeql define
      """
      define
      rule tesco-sells-all-soft-drinks: when {
        $x isa soft-drink;
      } then {
        $x has retailer 'Tesco';
      };

      rule if-ocado-exists-it-sells-all-soft-drinks: when {
        $x isa retailer;
        $x = 'Ocado';
        $y isa soft-drink;
      } then {
        $y has retailer 'Ocado';
      };
      """
    Given transaction commits
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $x isa soft-drink, has name "Fanta";
      $y isa soft-drink, has name "Tango";
      $r "Ocado" isa retailer;
      """
    Given transaction commits
    Given correctness checker is initialised
    When get answers of typeql match
      """
      match
        $x has retailer $r;
        $r != $unwanted;
        $unwanted = "Ocado";
      """
    # x     | r     |
    # Fanta | Tesco |
    # Tango | Tesco |
    Then answer size is: 2
    Then check all answers and explanations are sound
    Then check all answers and explanations are complete


  Scenario: inferred attributes can be matched by equality to a variable that is not equal to a specified value
    Given typeql define
      """
      define
      rule tesco-sells-all-soft-drinks: when {
        $x isa soft-drink;
      } then {
        $x has retailer 'Tesco';
      };

      rule if-ocado-exists-it-sells-all-soft-drinks: when {
        $x isa retailer;
        $x = 'Ocado';
        $y isa soft-drink;
      } then {
        $y has retailer 'Ocado';
      };
      """
    Given transaction commits
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $x isa soft-drink, has name "Fanta";
      $y isa soft-drink, has name "Tango";
      $r "Ocado" isa retailer;
      """
    Given transaction commits
    Given correctness checker is initialised
    When get answers of typeql match
      """
      match
        $x has retailer $r;
        $wanted = "Ocado";
        $r = $wanted;
      """
    # x     | r     |
    # Fanta | Ocado |
    # Tango | Ocado |
    Then answer size is: 2
    Then check all answers and explanations are sound
    Then check all answers and explanations are complete


  # TODO: re-enable all steps when fixed (#75)
  Scenario: inferred attributes can be filtered to include only values that contain a specified string
    Given typeql define
      """
      define

      rule iceland-sells-drinks: when {
        $x isa soft-drink;
      } then {
        $x has retailer 'Iceland';
      };

      rule poundland-sells-drinks: when {
        $x isa soft-drink;
      } then {
        $x has retailer 'Poundland';
      };

      rule londis-sells-drinks: when {
        $x isa soft-drink;
      } then {
        $x has retailer 'Londis';
      };
      """
    Given transaction commits
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert $x isa soft-drink, has name "Fanta";
      """
    Given transaction commits
    Given correctness checker is initialised
    When get answers of typeql match
      """
      match
        $x has retailer $rx;
        $rx contains "land";
      """
    Then answer size is: 2
    Then check all answers and explanations are sound
    Then check all answers and explanations are complete


  Scenario: inferred attributes can be matched by equality to an attribute that contains a specified string
    Given typeql define
      """
      define

      rule iceland-sells-drinks: when {
        $x isa soft-drink;
      } then {
        $x has retailer 'Iceland';
      };

      rule poundland-sells-drinks: when {
        $x isa soft-drink;
      } then {
        $x has retailer 'Poundland';
      };

      rule londis-sells-drinks: when {
        $x isa soft-drink;
      } then {
        $x has retailer 'Londis';
      };
      """
    Given transaction commits
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $x isa soft-drink, has name "Fanta";
      $y isa soft-drink, has name "Tango";
      """
    Given transaction commits
    Given correctness checker is initialised
    When get answers of typeql match
      """
      match
        $x has retailer $rx;
        $y has retailer $ry;
        $rx = $ry;
        $ry contains 'land';
      """
    # x     | rx        | y     | ry        |
    # Fanta | Iceland   | Tango | Iceland   |
    # Tango | Iceland   | Fanta | Iceland   |
    # Fanta | Poundland | Tango | Poundland |
    # Tango | Poundland | Fanta | Poundland |
    # Fanta | Iceland   | Fanta | Iceland   |
    # Fanta | Poundland | Fanta | Poundland |
    # Tango | Iceland   | Tango | Iceland   |
    # Tango | Poundland | Tango | Poundland |
    Then answer size is: 8
    Then check all answers and explanations are sound
    Then check all answers and explanations are complete


  # TODO: re-enable all steps when fixed (#75)
  Scenario: inferred attributes can be matched by inequality to an attribute that contains a specified string
    Given typeql define
      """
      define

      rule iceland-sells-drinks: when {
        $x isa soft-drink;
      } then {
        $x has retailer 'Iceland';
      };

      rule poundland-sells-drinks: when {
        $x isa soft-drink;
      } then {
        $x has retailer 'Poundland';
      };

      rule londis-sells-drinks: when {
        $x isa soft-drink;
      } then {
        $x has retailer 'Londis';
      };
      """
    Given transaction commits
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $x isa soft-drink, has name "Fanta";
      $y isa soft-drink, has name "Tango";
      """
    Given transaction commits
    Given correctness checker is initialised
    When get answers of typeql match
      """
      match
        $x has retailer $rx;
        $y has retailer $ry;
        $rx != $ry;
        $ry contains 'land';
      """
    # x     | rx        | y     | ry        |
    # Fanta | Iceland   | Tango | Poundland |
    # Tango | Iceland   | Fanta | Poundland |
    # Fanta | Poundland | Tango | Iceland   |
    # Tango | Poundland | Fanta | Iceland   |
    # Fanta | Londis    | Tango | Poundland |
    # Tango | Londis    | Fanta | Poundland |
    # Fanta | Londis    | Tango | Iceland   |
    # Tango | Londis    | Fanta | Iceland   |
    # Fanta | Iceland   | Fanta | Poundland |
    # Tango | Iceland   | Tango | Poundland |
    # Fanta | Poundland | Fanta | Iceland   |
    # Tango | Poundland | Tango | Iceland   |
    # Fanta | Londis    | Fanta | Poundland |
    # Tango | Londis    | Tango | Poundland |
    # Fanta | Londis    | Fanta | Iceland   |
    # Tango | Londis    | Tango | Iceland   |
    Then answer size is: 16
    Then check all answers and explanations are sound
    Then check all answers and explanations are complete


  Scenario: in a rule, 'not { $x = $y; }' is the same as saying '$x != $y'
    Given typeql define
      """
      define
      rule tesco-sells-all-soft-drinks: when {
        $x isa soft-drink;
      } then {
        $x has retailer 'Tesco';
      };

      rule if-ocado-exists-it-sells-all-soft-drinks: when {
        $x isa retailer;
        $x = 'Ocado';
        $y isa soft-drink;
      } then {
        $y has retailer 'Ocado';
      };
      """
    Given transaction commits
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $x isa soft-drink, has name "Fanta";
      $y isa soft-drink, has name "Tango";
      $r "Ocado" isa retailer;
      """
    Given transaction commits
    Given correctness checker is initialised
    Given for typeql query
      """
      match
        $x has retailer $r;
        $r != "Ocado";
      """
    # x     | r     |
    # Fanta | Tesco |
    # Tango | Tesco |
    Then answer size is:  2
    Then check all answers and explanations are sound
    Then check all answers and explanations are complete
    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match
        $x has retailer $r;
        not { $r = "Ocado"; };
      """
    Then answer size is: 2
    Then check all answers and explanations are sound
    Then check all answers and explanations are complete


  Scenario: in a rule, 'not { $x != $y; }' is the same as saying '$x = $y'
    Given typeql define
      """
      define
      rule tesco-sells-all-soft-drinks: when {
        $x isa soft-drink;
      } then {
        $x has retailer 'Tesco';
      };

      rule if-ocado-exists-it-sells-all-soft-drinks: when {
        $x isa retailer;
        $x = 'Ocado';
        $y isa soft-drink;
      } then {
        $y has retailer 'Ocado';
      };
      """
    Given transaction commits
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $x isa soft-drink, has name "Fanta";
      $y isa soft-drink, has name "Tango";
      $r "Ocado" isa retailer;
      """
    Given transaction commits
    Given correctness checker is initialised
    Given for typeql query
      """
      match
        $x has retailer $r;
        $r = "Ocado";
      """
    # x     | r     |
    # Fanta | Ocado |
    # Tango | Ocado |
    Then answer size is:  2
    Then check all answers and explanations are sound
    Then check all answers and explanations are complete
    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match
        $x has retailer $r;
        not { $r != "Ocado"; };
      """
    Then answer size is: 2
    Then check all answers and explanations are sound
    Then check all answers and explanations are complete


  # TODO: move to negation.feature
  Scenario: a negation can filter out variables by equality to another variable with a specified value
    Given typeql define
      """
      define
      rule tesco-sells-all-soft-drinks: when {
        $x isa soft-drink;
      } then {
        $x has retailer 'Tesco';
      };

      rule if-ocado-exists-it-sells-all-soft-drinks: when {
        $x isa retailer;
        $x = 'Ocado';
        $y isa soft-drink;
      } then {
        $y has retailer 'Ocado';
      };
      """
    Given transaction commits
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $x isa soft-drink, has name "Fanta";
      $y isa soft-drink, has name "Tango";
      $r "Ocado" isa retailer;
      """
    Given transaction commits
    Given correctness checker is initialised
    When get answers of typeql match
      """
      match
        $x has retailer $r;
        not {
          $r = $unwanted;
          $unwanted = "Ocado";
        };
      """
    # x     | r     |
    # Fanta | Tesco |
    # Tango | Tesco |
    Then answer size is: 2
    Then check all answers and explanations are sound
    Then check all answers and explanations are complete


  # TODO: migrate to concept-inequality.feature
  Scenario: when using 'not { $x is $y; }' over attributes of the same value, the answers have distinct types
    Given typeql define
      """
      define
      base-attribute sub attribute, value string, abstract;
      base-string-attribute sub base-attribute;
      retailer sub base-attribute;
      brand-name sub base-attribute;

      person owns base-string-attribute;

      soft-drink owns retailer, owns base-string-attribute, owns brand-name;

      rule tesco-sells-all-soft-drinks: when {
        $x isa soft-drink;
      } then {
        $x has retailer "Tesco";
      };
      """
    Given transaction commits
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $x isa person, has base-string-attribute "Tesco";
      $y isa soft-drink, has brand-name "Tesco";
      """
    Given transaction commits
    Given correctness checker is initialised
    When get answers of typeql match
      """
      match
        $x has base-attribute $ax;
        $y has base-attribute $ay;
        not { $ax is $ay; };
      """
    # x   | ax  | y   | ay  |
    # PER | BSA | SOF | NAM |
    # PER | BSA | SOF | RET |
    # SOF | NAM | PER | BSA |
    # SOF | RET | PER | BSA |
    # SOF | NAM | SOF | RET |
    # SOF | RET | SOF | NAM |
    Then answer size is: 6
    Then check all answers and explanations are sound
    Then check all answers and explanations are complete


  Scenario: rules can divide entities into groups, linking each entity group to a specific concept by attribute value
    Given typeql define
      """
      define

      soft-drink plays price-classification:item;

      price-range sub attribute, value string,
        plays price-classification:category;

      price-classification sub relation,
        relates item,
        relates category;

      rule expensive-drinks: when {
        $x has price >= 3.50;
        $y "expensive" isa price-range;
      } then {
        (item: $x, category: $y) isa price-classification;
      };

      rule not-expensive-drinks: when {
        $x has price < 3.50;
        $y "not expensive" isa price-range;
      } then {
        (item: $x, category: $y) isa price-classification;
      };

      rule low-price-drinks: when {
        $x has price < 1.75;
        $y "low price" isa price-range;
      } then {
        (item: $x, category: $y) isa price-classification;
      };

      rule cheap-drinks: when {
        (item: $x, category: $y) isa price-classification;
        $y "not expensive" isa price-range;
        (item: $x, category: $y2) isa price-classification;
        $y2 "low price" isa price-range;
        $y3 "cheap" isa price-range;
      } then {
        (item: $x, category: $y3) isa price-classification;
      };
      """
    Given transaction commits
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert

      $x isa soft-drink, has name "San Pellegrino Limonata", has price 3.99;
      $y isa soft-drink, has name "Sprite", has price 2.00;
      $z isa soft-drink, has name "Tesco Value Lemonade", has price 0.39;

      $p1 "expensive" isa price-range;
      $p2 "not expensive" isa price-range;
      $p3 "low price" isa price-range;
      $p4 "cheap" isa price-range;
      """
    Given transaction commits
    Given correctness checker is initialised
    When get answers of typeql match
      """
      match
        $x "not expensive" isa price-range;
        ($x, item: $y) isa price-classification;
      """
    Then answer size is: 2
    Then check all answers and explanations are sound
    Then check all answers and explanations are complete
    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match
        $x "low price" isa price-range;
        ($x, item: $y) isa price-classification;
      """
    Then answer size is: 1
    Then check all answers and explanations are sound
    Then check all answers and explanations are complete
    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match
        $x "cheap" isa price-range;
        ($x, item: $y) isa price-classification;
      """
    Then answer size is: 1
    Then check all answers and explanations are sound
    Then check all answers and explanations are complete
    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match
        $x "expensive" isa price-range;
        ($x, item: $y) isa price-classification;
      """
    Then answer size is: 1
    Then check all answers and explanations are sound
    Then check all answers and explanations are complete
    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match
        $x isa price-range;
        ($x, item: $y) isa price-classification;
      """
    # sum of all previous answers
    Then answer size is: 5
    Then check all answers and explanations are sound
    Then check all answers and explanations are complete


  # TODO: re-enable all steps when resolvable (currently it takes too long to resolve) (#75)
  Scenario: attribute comparison can be used to classify concept pairs as predecessors and successors of each other
    Given typeql define
      """
      define

      post sub entity,
          plays reply-of:original,
          plays reply-of:reply,
          plays message-succession:predecessor,
          plays message-succession:successor,
          owns creation-date;

      reply-of sub relation,
          relates original,
          relates reply;

      message-succession sub relation,
          relates predecessor,
          relates successor;

      creation-date sub attribute, value datetime;

      rule succession-rule: when {
          (original:$p, reply:$s) isa reply-of;
          $s has creation-date $d1;
          $d1 < $d2;
          (original:$p, reply:$r) isa reply-of;
          $r has creation-date $d2;
      } then {
          (predecessor:$s, successor:$r) isa message-succession;
      };
      """
    Given transaction commits
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert

      $x isa post, has creation-date 2020-07-01;
      $x1 isa post, has creation-date 2020-07-02;
      $x2 isa post, has creation-date 2020-07-03;
      $x3 isa post, has creation-date 2020-07-04;
      $x4 isa post, has creation-date 2020-07-05;
      $x5 isa post, has creation-date 2020-07-06;

      (original:$x, reply:$x1) isa reply-of;
      (original:$x, reply:$x2) isa reply-of;
      (original:$x, reply:$x3) isa reply-of;
      (original:$x, reply:$x4) isa reply-of;
      (original:$x, reply:$x5) isa reply-of;
      """
    Given transaction commits
    Given correctness checker is initialised
    When get answers of typeql match
      """
      match (predecessor:$x1, successor:$x2) isa message-succession;
      """
    # the (n-1)th triangle number, where n is the number of replies to the first post
    Then answer size is: 10
    Then check all answers and explanations are sound
    Then check all answers and explanations are complete
