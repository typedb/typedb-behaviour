# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: Value Predicate Resolution

  Background: Set up database
    Given typedb starts
    Given connection opens with default authentication
    Given reasoning schema
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
    # each scenario specialises the schema further

  Scenario: a rule can infer an attribute ownership based on a value predicate
    Given reasoning schema
      """
      define
      rule tortoises-become-old-at-age-1-year: when {
        $x isa tortoise, has age $a;
        $a > 0;
      } then {
        $x has is-old true;
      };
      """
    Given reasoning data
      """
      insert
      $se isa tortoise, has age 1;
      """
    Given verifier is initialised
    Given reasoning query
      """
      match $x has is-old $r;
      """
    Then verify answer size: 1
    Then verify answers are sound
    Then verify answers are complete


  # TODO: re-enable all steps once materialised database counts duplicate attributes only once
  Scenario Outline: when querying for inferred attributes with '<op>', the answers matching the predicate are returned
    Given reasoning schema
      """
      define
      lucky-number sub attribute, value long;
      person owns lucky-number;
      rule rule-1337: when { $x isa person; } then { $x has lucky-number 1337; };
      rule rule-1667: when { $x isa person; } then { $x has lucky-number 1667; };
      rule rule-1997: when { $x isa person; } then { $x has lucky-number 1997; };
      """
    Given reasoning data
      """
      insert
      $x isa person;
      $y isa person;
      """
    Given verifier is initialised
    Given reasoning query
      """
      match
        $x isa person, has lucky-number $n;
        $n <op> 1667;

      """
    Then verify answer size: <answer-size>
    Then verify answers are sound
    Then verify answers are complete

    Examples:
      | op | answer-size |
      | >  | 2           |
      | >= | 4           |
      | <  | 2           |
      | <= | 4           |
      | == | 2           |
      | != | 4           |


  # TODO: re-enable all steps when fixed (#75)
  Scenario Outline: when both sides of a '<op>' comparison are inferred attributes, all answers satisfy the predicate
    Given reasoning schema
      """
      define
      lucky-number sub attribute, value long;
      person owns lucky-number;
      rule rule-1337: when { $x isa person; } then { $x has lucky-number 1337; };
      rule rule-1667: when { $x isa person; } then { $x has lucky-number 1667; };
      """
    Given reasoning data
      """
      insert
      $x isa person, has name "Alice";
      $y isa person, has name "Bob";
      """
    Given verifier is initialised
    Given reasoning query
      """
      match
        $x isa person, has name "Alice", has lucky-number $m;
        $y isa person, has name "Bob", has lucky-number $n;
        $m <op> $n;

      """
    Then verify answer size: <answer-size>
    Then verify answers are sound
    Then verify answers are complete

    Examples:
      | op | answer-size |
      | >  | 1           |
      | >= | 3           |
      | <  | 1           |
      | <= | 3           |
      | == | 2           |
      | != | 2           |


  # TODO: re-enable all steps when fixed (#75)
  Scenario Outline: when comparing an inferred attribute and a bound variable with '<op>', answers satisfy the predicate
    Given reasoning schema
      """
      define
      lucky-number sub attribute, value long;
      person owns lucky-number;
      rule rule-1337: when { $x isa person; } then { $x has lucky-number 1337; };
      rule rule-1667: when { $x isa person; } then { $x has lucky-number 1667; };
      rule rule-1997: when { $x isa person; } then { $x has lucky-number 1997; };
      """
    Given reasoning data
      """
      insert
      $x isa person, has name "Alice";
      $y isa person, has name "Bob";
      """
    Given verifier is initialised
    Given reasoning query
      """
      match
        $x isa person, has name "Alice", has lucky-number $m;
        $y isa person, has name "Bob", has lucky-number $n;
        $m <op> $n;
        $n <op> 1667;

      """
    Then verify answer size: <answer-size>
    Then verify answers are sound
    Then verify answers are complete

    Examples:
      | op | answer-size |
      | >  | 0           |
      | >= | 3           |
      | <  | 0           |
      | <= | 3           |
      | == | 1           |
      | != | 4           |


  Scenario: inferred attributes can be matched by inequality to a variable that is equal to a specified value
    Given reasoning schema
      """
      define
      rule tesco-sells-all-soft-drinks: when {
        $x isa soft-drink;
      } then {
        $x has retailer 'Tesco';
      };

      rule if-ocado-exists-it-sells-all-soft-drinks: when {
        $x isa retailer;
        $x == 'Ocado';
        $y isa soft-drink;
      } then {
        $y has retailer 'Ocado';
      };
      """
    Given reasoning data
      """
      insert
      $x isa soft-drink, has name "Fanta";
      $y isa soft-drink, has name "Tango";
      $r "Ocado" isa retailer;
      """
    Given verifier is initialised
    Given reasoning query
      """
      match
        $x has retailer $r;
        $r != $unwanted;
        $unwanted == "Ocado";

      """
    # x     | r     |
    # Fanta | Tesco |
    # Tango | Tesco |
    Then verify answer size: 2
    Then verify answers are sound
    Then verify answers are complete


  Scenario: inferred attributes can be matched by equality to a variable that is not equal to a specified value
    Given reasoning schema
      """
      define
      rule tesco-sells-all-soft-drinks: when {
        $x isa soft-drink;
      } then {
        $x has retailer 'Tesco';
      };

      rule if-ocado-exists-it-sells-all-soft-drinks: when {
        $x isa retailer;
        $x == 'Ocado';
        $y isa soft-drink;
      } then {
        $y has retailer 'Ocado';
      };
      """
    Given reasoning data
      """
      insert
      $x isa soft-drink, has name "Fanta";
      $y isa soft-drink, has name "Tango";
      $r "Ocado" isa retailer;
      """
    Given verifier is initialised
    Given reasoning query
      """
      match
        $x has retailer $r;
        $wanted == "Ocado";
        $r == $wanted;

      """
    # x     | r     |
    # Fanta | Ocado |
    # Tango | Ocado |
    Then verify answer size: 2
    Then verify answers are sound
    Then verify answers are complete


  # TODO: re-enable all steps when fixed (#75)
  Scenario: inferred attributes can be filtered to include only values that contain a specified string
    Given reasoning schema
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
    Given reasoning data
      """
      insert $x isa soft-drink, has name "Fanta";
      """
    Given verifier is initialised
    Given reasoning query
      """
      match
        $x has retailer $rx;
        $rx contains "land";

      """
    Then verify answer size: 2
    Then verify answers are sound
    Then verify answers are complete


  Scenario: inferred attributes can be matched by equality to an attribute that contains a specified string
    Given reasoning schema
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
    Given reasoning data
      """
      insert
      $x isa soft-drink, has name "Fanta";
      $y isa soft-drink, has name "Tango";
      """
    Given verifier is initialised
    Given reasoning query
      """
      match
        $x has retailer $rx;
        $y has retailer $ry;
        $rx == $ry;
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
    Then verify answer size: 8
    Then verify answers are sound
    Then verify answers are complete


  # TODO: re-enable all steps when fixed (#75)
  Scenario: inferred attributes can be matched by inequality to an attribute that contains a specified string
    Given reasoning schema
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
    Given reasoning data
      """
      insert
      $x isa soft-drink, has name "Fanta";
      $y isa soft-drink, has name "Tango";
      """
    Given verifier is initialised
    Given reasoning query
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
    Then verify answer size: 16
    Then verify answers are sound
    Then verify answers are complete


  Scenario: in a rule, 'not { $x == $y; }' is the same as saying '$x != $y'
    Given reasoning schema
      """
      define
      rule tesco-sells-all-soft-drinks: when {
        $x isa soft-drink;
      } then {
        $x has retailer 'Tesco';
      };

      rule if-ocado-exists-it-sells-all-soft-drinks: when {
        $x isa retailer;
        $x == 'Ocado';
        $y isa soft-drink;
      } then {
        $y has retailer 'Ocado';
      };
      """
    Given reasoning data
      """
      insert
      $x isa soft-drink, has name "Fanta";
      $y isa soft-drink, has name "Tango";
      $r "Ocado" isa retailer;
      """
    Given verifier is initialised
    Given reasoning query
      """
      match
        $x has retailer $r;
        $r != "Ocado";

      """
    # x     | r     |
    # Fanta | Tesco |
    # Tango | Tesco |
    Then verify answer size: 2
    Then verify answers are sound
    Then verify answers are complete
    Given reasoning query
      """
      match
        $x has retailer $r;
        not { $r == "Ocado"; };

      """
    Then verify answer size: 2
    Then verify answers are sound
    Then verify answers are complete


  Scenario: in a rule, 'not { $x != $y; }' is the same as saying '$x == $y'
    Given reasoning schema
      """
      define
      rule tesco-sells-all-soft-drinks: when {
        $x isa soft-drink;
      } then {
        $x has retailer 'Tesco';
      };

      rule if-ocado-exists-it-sells-all-soft-drinks: when {
        $x isa retailer;
        $x == 'Ocado';
        $y isa soft-drink;
      } then {
        $y has retailer 'Ocado';
      };
      """
    Given reasoning data
      """
      insert
      $x isa soft-drink, has name "Fanta";
      $y isa soft-drink, has name "Tango";
      $r "Ocado" isa retailer;
      """
    Given verifier is initialised
    Given reasoning query
      """
      match
        $x has retailer $r;
        $r == "Ocado";

      """
    # x     | r     |
    # Fanta | Ocado |
    # Tango | Ocado |
    Then verify answer size: 2
    Then verify answers are sound
    Then verify answers are complete
    Given reasoning query
      """
      match
        $x has retailer $r;
        not { $r != "Ocado"; };

      """
    Then verify answer size: 2
    Then verify answers are sound
    Then verify answers are complete


  Scenario: a negation can filter out variables by equality to another variable with a specified value
    Given reasoning schema
      """
      define
      rule tesco-sells-all-soft-drinks: when {
        $x isa soft-drink;
      } then {
        $x has retailer 'Tesco';
      };

      rule if-ocado-exists-it-sells-all-soft-drinks: when {
        $x isa retailer;
        $x == 'Ocado';
        $y isa soft-drink;
      } then {
        $y has retailer 'Ocado';
      };
      """
    Given reasoning data
      """
      insert
      $x isa soft-drink, has name "Fanta";
      $y isa soft-drink, has name "Tango";
      $r "Ocado" isa retailer;
      """
    Given verifier is initialised
    Given reasoning query
      """
      match
        $x has retailer $r;
        not {
          $r == $unwanted;
          $unwanted == "Ocado";
        };

      """
    # x     | r     |
    # Fanta | Tesco |
    # Tango | Tesco |
    Then verify answer size: 2
    Then verify answers are sound
    Then verify answers are complete


  # TODO: migrate to concept-inequality.feature
  Scenario: when using 'not { $x is $y; }' over attributes of the same value, the answers have distinct types
    Given reasoning schema
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
    Given reasoning data
      """
      insert
      $x isa person, has base-string-attribute "Tesco";
      $y isa soft-drink, has brand-name "Tesco";
      """
    Given verifier is initialised
    Given reasoning query
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
    Then verify answer size: 6
    Then verify answers are sound
    Then verify answers are complete


  Scenario: rules can divide entities into groups, linking each entity group to a specific concept by attribute value
    Given reasoning schema
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
    Given reasoning data
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
    Given verifier is initialised
    Given reasoning query
      """
      match
        $x "not expensive" isa price-range;
        ($x, item: $y) isa price-classification;

      """
    Then verify answer size: 2
    Then verify answers are sound
    Then verify answers are complete
    Given reasoning query
      """
      match
        $x "low price" isa price-range;
        ($x, item: $y) isa price-classification;

      """
    Then verify answer size: 1
    Then verify answers are sound
    Then verify answers are complete
    Given reasoning query
      """
      match
        $x "cheap" isa price-range;
        ($x, item: $y) isa price-classification;

      """
    Then verify answer size: 1
    Then verify answers are sound
    Then verify answers are complete
    Given reasoning query
      """
      match
        $x "expensive" isa price-range;
        ($x, item: $y) isa price-classification;

      """
    Then verify answer size: 1
    Then verify answers are sound
    Then verify answers are complete
    Given reasoning query
      """
      match
        $x isa price-range;
        ($x, item: $y) isa price-classification;

      """
    # sum of all previous answers
    Then verify answer size: 5
    Then verify answers are sound
    Then verify answers are complete


  # TODO: re-enable all steps when resolvable (currently it takes too long to resolve) (#75)
  Scenario: attribute comparison can be used to classify concept pairs as predecessors and successors of each other
    Given reasoning schema
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
    Given reasoning data
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
    Given verifier is initialised
    Given reasoning query
      """
      match (predecessor:$x1, successor:$x2) isa message-succession;
      """
    # the (n-1)th triangle number, where n is the number of replies to the first post
    Then verify answer size: 10
    Then verify answers are sound
    Then verify answers are complete
