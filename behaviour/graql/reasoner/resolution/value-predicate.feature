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

  Background: Set up keyspaces for resolution testing

    Given connection has been opened
    Given connection delete all keyspaces
    Given connection open sessions for keyspaces:
      | materialised |
      | reasoned     |
    Given materialised keyspace is named: materialised
    Given reasoned keyspace is named: reasoned
    Given for each session, graql define
      """
      define

      person sub entity,
        plays leader,
        plays team-member,
        has string-attribute,
        has unrelated-attribute,
        has sub-string-attribute,
        has name,
        has age,
        has is-old,
        key ref;

      tortoise sub entity,
        has age,
        has is-old,
        key ref;

      soft-drink sub entity,
        has name,
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
      name sub attribute, value string;
      is-old sub attribute, value boolean;
      sub-string-attribute sub string-attribute;
      unrelated-attribute sub attribute, value string;
      ref sub attribute, value long;
      """


  # TODO: change 'then' block to "$x has is-old true" once implicit attribute variables are resolvable
  Scenario: a rule can infer an attribute ownership based on a value predicate
    Given for each session, graql define
      """
      define
      tortoises-become-old-at-age-1-year sub rule,
      when {
        $x isa tortoise, has age $a;
        $a > 0;
      },
      then {
        $x has is-old $t;
        $t true;
      };
      """
    Given for each session, graql insert
      """
      insert
      $se isa tortoise, has age 1, has ref 0;
      """
    When materialised keyspace is completed
    Then for graql query
      """
      match $x has is-old $r; get;
      """
    Then in reasoned keyspace, all answers are correct
    Then in reasoned keyspace, answer size is: 1
    Then materialised and reasoned keyspaces are the same size


  # TODO: re-enable all steps once materialised keyspace counts duplicate attributes only once
  Scenario Outline: when querying for inferred attributes with `<op>`, the answers matching the predicate are returned
    Given for each session, graql define
      """
      define
      lucky-number sub attribute, value long;
      person has lucky-number;
      rule-1337 sub rule, when { $x isa person; }, then { $x has lucky-number $n; $n 1337; };
      rule-1667 sub rule, when { $x isa person; }, then { $x has lucky-number $n; $n 1667; };
      rule-1997 sub rule, when { $x isa person; }, then { $x has lucky-number $n; $n 1997; };
      """
    Given for each session, graql insert
      """
      insert
      $x isa person, has ref 0;
      $y isa person, has ref 1;
      """
    When materialised keyspace is completed
    Then for graql query
      """
      match
        $x isa person, has lucky-number $n;
        $n <op> 1667;
      get;
      """
    Then in reasoned keyspace, all answers are correct
    Then in reasoned keyspace, answer size is: <answer-size>
#    Then materialised and reasoned keyspaces are the same size

    Examples:
      | op  | answer-size |
      | >   | 2           |
      | >=  | 4           |
      | <   | 2           |
      | <=  | 4           |
      | ==  | 2           |
      | !== | 4           |


  # TODO: re-enable all steps when fixed (#75)
  Scenario Outline: when both sides of a `<op>` comparison are inferred attributes, all answers satisfy the predicate
    Given for each session, graql define
      """
      define
      lucky-number sub attribute, value long;
      person has lucky-number;
      rule-1337 sub rule, when { $x isa person; }, then { $x has lucky-number $n; $n 1337; };
      rule-1667 sub rule, when { $x isa person; }, then { $x has lucky-number $n; $n 1667; };
      """
    Given for each session, graql insert
      """
      insert
      $x isa person, has name "Alice", has ref 0;
      $y isa person, has name "Bob", has ref 1;
      """
    When materialised keyspace is completed
    Then for graql query
      """
      match
        $x isa person, has lucky-number $m;
        $y isa person, has lucky-number $n;
        $m <op> $n;
      get;
      """
#    Then in reasoned keyspace, all answers are correct
    Then in reasoned keyspace, answer size is: <answer-size>
    Then materialised and reasoned keyspaces are the same size

    Examples:
      | op  | answer-size |
      | >   | 1           |
      | >=  | 3           |
      | <   | 1           |
      | <=  | 3           |
      | ==  | 2           |
      | !== | 2           |


  # TODO: re-enable all steps when fixed (#75)
  Scenario Outline: when comparing an inferred attribute and a bound variable with `<op>`, answers satisfy the predicate
    Given for each session, graql define
      """
      define
      lucky-number sub attribute, value long;
      person has lucky-number;
      rule-1337 sub rule, when { $x isa person; }, then { $x has lucky-number $n; $n 1337; };
      rule-1667 sub rule, when { $x isa person; }, then { $x has lucky-number $n; $n 1667; };
      rule-1997 sub rule, when { $x isa person; }, then { $x has lucky-number $n; $n 1997; };
      """
    Given for each session, graql insert
      """
      insert
      $x isa person, has ref 0;
      $y isa person, has ref 1;
      """
    When materialised keyspace is completed
    Then for graql query
      """
      match
        $x isa person, has lucky-number $m;
        $y isa person, has lucky-number $n;
        $m <op> $n;
        $n <op> 1667;
      get;
      """
#    Then in reasoned keyspace, all answers are correct
    Then in reasoned keyspace, answer size is: <answer-size>
    Then materialised and reasoned keyspaces are the same size

    Examples:
      | op  | answer-size |
      | >   | 0           |
      | >=  | 4           |
      | <   | 0           |
      | <=  | 4           |
      | ==  | 2           |
      | !== | 8           |


  # TODO: re-enable all steps once implicit attribute variables are resolvable
  Scenario: inferred attributes can be matched by inequality to a variable that is equal to a specified value
    Given for each session, graql define
      """
      define
      tesco-sells-all-soft-drinks sub rule,
      when {
        $x isa soft-drink;
      },
      then {
        $x has retailer 'Tesco';
      };

      if-ocado-exists-it-sells-all-soft-drinks sub rule,
      when {
        $x isa retailer;
        $x == 'Ocado';
        $y isa soft-drink;
      },
      then {
        $y has retailer 'Ocado';
      };
      """
    Given for each session, graql insert
      """
      insert
      $x isa soft-drink, has name "Fanta", has ref 0;
      $y isa soft-drink, has name "Tango", has ref 1;
      $r "Ocado" isa retailer;
      """
#    When materialised keyspace is completed
    Then for graql query
      """
      match
        $x has retailer $r;
        $r !== $unwanted;
        $unwanted == "Ocado";
      get;
      """
#    Given in reasoned keyspace, all answers are correct
    # x     | r     |
    # Fanta | Tesco |
    # Tango | Tesco |
    Given in reasoned keyspace, answer size is: 2
#    Then materialised and reasoned keyspaces are the same size


  # TODO: re-enable all steps once implicit attribute variables are resolvable
  Scenario: inferred attributes can be matched by equality to a variable that is not equal to a specified value
    Given for each session, graql define
      """
      define
      tesco-sells-all-soft-drinks sub rule,
      when {
        $x isa soft-drink;
      },
      then {
        $x has retailer 'Tesco';
      };

      if-ocado-exists-it-sells-all-soft-drinks sub rule,
      when {
        $x isa retailer;
        $x == 'Ocado';
        $y isa soft-drink;
      },
      then {
        $y has retailer 'Ocado';
      };
      """
    Given for each session, graql insert
      """
      insert
      $x isa soft-drink, has name "Fanta", has ref 0;
      $y isa soft-drink, has name "Tango", has ref 1;
      $r "Ocado" isa retailer;
      """
#    When materialised keyspace is completed
    Then for graql query
      """
      match
        $x has retailer $r;
        $wanted == "Ocado";
        $r == $wanted;
      get;
      """
#    Given in reasoned keyspace, all answers are correct
    # x     | r     |
    # Fanta | Ocado |
    # Tango | Ocado |
    Given in reasoned keyspace, answer size is: 2
#    Then materialised and reasoned keyspaces are the same size


  # TODO: re-enable all steps when fixed (#75)
  Scenario: inferred attributes can be filtered to include only values that contain a specified string
    Given for each session, graql define
      """
      define

      iceland-sells-drinks sub rule,
      when {
        $x isa soft-drink;
      },
      then {
        $x has retailer 'Iceland';
      };

      poundland-sells-drinks sub rule,
      when {
        $x isa soft-drink;
      },
      then {
        $x has retailer 'Poundland';
      };

      londis-sells-drinks sub rule,
      when {
        $x isa soft-drink;
      },
      then {
        $x has retailer 'Londis';
      };
      """
    Given for each session, graql insert
      """
      insert $x isa soft-drink, has name "Fanta", has ref 0;
      """
    When materialised keyspace is completed
    Then for graql query
      """
      match
        $x has retailer $rx;
        $rx contains "land";
      get;
      """
    Then in reasoned keyspace, all answers are correct
    Then in reasoned keyspace, answer size is: 2
#    Then materialised and reasoned keyspaces are the same size


  # TODO: re-enable all steps when fixed (#75)
  Scenario: inferred attributes can be matched by equality to an attribute that contains a specified string
    Given for each session, graql define
      """
      define

      iceland-sells-drinks sub rule,
      when {
        $x isa soft-drink;
      },
      then {
        $x has retailer 'Iceland';
      };

      poundland-sells-drinks sub rule,
      when {
        $x isa soft-drink;
      },
      then {
        $x has retailer 'Poundland';
      };

      londis-sells-drinks sub rule,
      when {
        $x isa soft-drink;
      },
      then {
        $x has retailer 'Londis';
      };
      """
    Given for each session, graql insert
      """
      insert
      $x isa soft-drink, has name "Fanta", has ref 0;
      $y isa soft-drink, has name "Tango", has ref 1;
      """
    When materialised keyspace is completed
    Then for graql query
      """
      match
        $x has retailer $rx;
        $y has retailer $ry;
        $rx == $ry;
        $ry contains 'land';
      get;
      """
#    Then in reasoned keyspace, all answers are correct
    # x     | rx        | y     | ry        |
    # Fanta | Iceland   | Tango | Iceland   |
    # Tango | Iceland   | Fanta | Iceland   |
    # Fanta | Poundland | Tango | Poundland |
    # Tango | Poundland | Fanta | Poundland |
    Then in reasoned keyspace, answer size is: 4
    Then materialised and reasoned keyspaces are the same size


  # TODO: re-enable all steps when fixed (#75)
  Scenario: inferred attributes can be matched by inequality to an attribute that contains a specified string
    Given for each session, graql define
      """
      define

      iceland-sells-drinks sub rule,
      when {
        $x isa soft-drink;
      },
      then {
        $x has retailer 'Iceland';
      };

      poundland-sells-drinks sub rule,
      when {
        $x isa soft-drink;
      },
      then {
        $x has retailer 'Poundland';
      };

      londis-sells-drinks sub rule,
      when {
        $x isa soft-drink;
      },
      then {
        $x has retailer 'Londis';
      };
      """
    Given for each session, graql insert
      """
      insert
      $x isa soft-drink, has name "Fanta", has ref 0;
      $y isa soft-drink, has name "Tango", has ref 1;
      """
    When materialised keyspace is completed
    Then for graql query
      """
      match
        $x has retailer $rx;
        $y has retailer $ry;
        $rx !== $ry;
        $ry contains 'land';
      get;
      """
#    Then in reasoned keyspace, all answers are correct
    # x     | rx        | y     | ry        |
    # Fanta | Iceland   | Tango | Poundland |
    # Tango | Iceland   | Fanta | Poundland |
    # Fanta | Poundland | Tango | Iceland   |
    # Tango | Poundland | Fanta | Iceland   |
    Then in reasoned keyspace, answer size is: 4
    Then materialised and reasoned keyspaces are the same size


  # TODO: re-enable all steps once implicit attribute variables are resolvable
  Scenario: in a rule, `not { $x == $y; }` is the same as saying `$x !== $y`
    Given for each session, graql define
      """
      define
      tesco-sells-all-soft-drinks sub rule,
      when {
        $x isa soft-drink;
      },
      then {
        $x has retailer 'Tesco';
      };

      if-ocado-exists-it-sells-all-soft-drinks sub rule,
      when {
        $x isa retailer;
        $x == 'Ocado';
        $y isa soft-drink;
      },
      then {
        $y has retailer 'Ocado';
      };
      """
    Given for each session, graql insert
      """
      insert
      $x isa soft-drink, has name "Fanta", has ref 0;
      $y isa soft-drink, has name "Tango", has ref 1;
      $r "Ocado" isa retailer;
      """
#    When materialised keyspace is completed
    Given for graql query
      """
      match
        $x has retailer $r;
        $r !== "Ocado";
      get;
      """
#    Given in reasoned keyspace, all answers are correct
    # x     | r     |
    # Fanta | Tesco |
    # Tango | Tesco |
    Given in reasoned keyspace, answer size is: 2
    Then for graql query
      """
      match
        $x has retailer $r;
        not { $r == "Ocado"; };
      get;
      """
#    Then in reasoned keyspace, all answers are correct
    Then in reasoned keyspace, answer size is: 2
#    Then materialised and reasoned keyspaces are the same size


  # TODO: re-enable all steps once implicit attribute variables are resolvable
  Scenario: in a rule, `not { $x !== $y; }` is the same as saying `$x == $y`
    Given for each session, graql define
      """
      define
      tesco-sells-all-soft-drinks sub rule,
      when {
        $x isa soft-drink;
      },
      then {
        $x has retailer 'Tesco';
      };

      if-ocado-exists-it-sells-all-soft-drinks sub rule,
      when {
        $x isa retailer;
        $x == 'Ocado';
        $y isa soft-drink;
      },
      then {
        $y has retailer 'Ocado';
      };
      """
    Given for each session, graql insert
      """
      insert
      $x isa soft-drink, has name "Fanta", has ref 0;
      $y isa soft-drink, has name "Tango", has ref 1;
      $r "Ocado" isa retailer;
      """
#    When materialised keyspace is completed
    Given for graql query
      """
      match
        $x has retailer $r;
        $r == "Ocado";
      get;
      """
#    Given in reasoned keyspace, all answers are correct
    # x     | r     |
    # Fanta | Ocado |
    # Tango | Ocado |
    Given in reasoned keyspace, answer size is: 2
    Then for graql query
      """
      match
        $x has retailer $r;
        not { $r !== "Ocado"; };
      get;
      """
#    Then in reasoned keyspace, all answers are correct
    Then in reasoned keyspace, answer size is: 2
#    Then materialised and reasoned keyspaces are the same size


  # TODO: move to negation.feature
  # TODO: re-enable all steps once implicit attribute variables are resolvable
  Scenario: a negation can filter out variables by equality to another variable with a specified value
    Given for each session, graql define
      """
      define
      tesco-sells-all-soft-drinks sub rule,
      when {
        $x isa soft-drink;
      },
      then {
        $x has retailer 'Tesco';
      };

      if-ocado-exists-it-sells-all-soft-drinks sub rule,
      when {
        $x isa retailer;
        $x == 'Ocado';
        $y isa soft-drink;
      },
      then {
        $y has retailer 'Ocado';
      };
      """
    Given for each session, graql insert
      """
      insert
      $x isa soft-drink, has name "Fanta", has ref 0;
      $y isa soft-drink, has name "Tango", has ref 1;
      $r "Ocado" isa retailer;
      """
#    When materialised keyspace is completed
    Then for graql query
      """
      match
        $x has retailer $r;
        not {
          $r == $unwanted;
          $unwanted == "Ocado";
        };
      get;
      """
#    Then in reasoned keyspace, all answers are correct
    # x     | r     |
    # Fanta | Tesco |
    # Tango | Tesco |
    Then in reasoned keyspace, answer size is: 2
#    Then materialised and reasoned keyspaces are the same size


  # TODO: re-enable all steps once implicit attribute variables are resolvable
  Scenario: when matching a pair of unrelated inferred attributes with `!==`, the answers are unequal
    Given for each session, graql define
      """
      define
      transfer-string-attribute-to-other-people sub rule,
      when {
        $x isa person, has string-attribute $r1;
        $y isa person;
      },
      then {
        $y has string-attribute $r1;
      };

      tesco-sells-all-soft-drinks sub rule,
      when {
        $x isa soft-drink;
      },
      then {
        $x has retailer 'Tesco';
      };
      """
    Given for each session, graql insert
      """
      insert
      $x isa person, has string-attribute "Tesco", has ref 0;
      $y isa person, has string-attribute "Safeway", has ref 1;
      $z isa soft-drink, has name "Tango", has ref 2;
      """
#    When materialised keyspace is completed
    Then for graql query
      """
      match
        $x has retailer $re;
        $y has string-attribute $sa;
        $re !== $sa;
      get;
      """
#    Then in reasoned keyspace, all answers are correct
    # x   | re      | y   | sa    |
    # SAF | Safeway | TAN | Tesco |
    Then in reasoned keyspace, answer size is: 1
#    Then materialised and reasoned keyspaces are the same size


  # TODO: re-enable all steps once implicit attribute variables are resolvable
  # TODO: move to negation.feature
  Scenario: when matching a pair of unrelated inferred attributes with negation and ==, the answers are unequal
    Given for each session, graql define
      """
      define
      transfer-string-attribute-to-other-people sub rule,
      when {
        $x isa person, has string-attribute $r1;
        $y isa person;
      },
      then {
        $y has string-attribute $r1;
      };

      tesco-sells-all-soft-drinks sub rule,
      when {
        $x isa soft-drink;
      },
      then {
        $x has retailer 'Tesco';
      };
      """
    Given for each session, graql insert
      """
      insert
      $x isa person, has string-attribute "Tesco", has ref 0;
      $y isa person, has string-attribute "Safeway", has ref 1;
      $z isa soft-drink, has name "Tango", has ref 2;
      """
#    When materialised keyspace is completed
    Then for graql query
      """
      match
        $x has retailer $re;
        $y has string-attribute $sa;
        not { $re == $sa; };
      get;
      """
#    Then in reasoned keyspace, all answers are correct
    # x   | re      | y   | sa    |
    # SAF | Safeway | TAN | Tesco |
    Then in reasoned keyspace, answer size is: 1
#    Then materialised and reasoned keyspaces are the same size


  # TODO: re-enable all steps once implicit attribute variables are resolvable
  Scenario: when restricting the values of a pair of inferred attributes with `!=`, the answers have distinct types
    Given for each session, graql define
      """
      define
      base-attribute sub attribute, value string, abstract;
      string-attribute sub base-attribute;
      name sub base-attribute;
      retailer sub base-attribute;

      transfer-string-attribute-to-other-people sub rule,
      when {
        $x isa person, has string-attribute $r1;
        $y isa person;
      },
      then {
        $y has string-attribute $r1;
      };

      tesco-sells-all-soft-drinks sub rule,
      when {
        $x isa soft-drink;
      },
      then {
        $x has retailer 'Tesco';
      };
      """
    Given for each session, graql insert
      """
      insert
      $x isa person, has string-attribute "Tesco", has ref 0;
      $y isa soft-drink, has name "Tesco", has ref 1;
      """
#    When materialised keyspace is completed
    Then for graql query
      """
      match
        $x has base-attribute $ax;
        $y has base-attribute $ay;
        $ax != $ay;
      get;
      """
#    Then in reasoned keyspace, all answers are correct
    # x   | ax  | y   | ay  |
    # PER | STA | SOF | NAM |
    # PER | STA | SOF | RET |
    # SOF | NAM | PER | STA |
    # SOF | RET | PER | STA |
    Then in reasoned keyspace, answer size is: 4
#    Then materialised and reasoned keyspaces are the same size


  # TODO: re-enable all steps once implicit attribute variables are resolvable
  Scenario: when restricting concept types of a pair of inferred attributes with `!=`, the answers have distinct types
    Given for each session, graql define
      """
      define
      base-attribute sub attribute, value string, abstract;
      string-attribute sub base-attribute;
      name sub base-attribute;
      retailer sub base-attribute;

      transfer-string-attribute-to-other-people sub rule,
      when {
        $x isa person, has string-attribute $r1;
        $y isa person;
      },
      then {
        $y has string-attribute $r1;
      };

      tesco-sells-all-soft-drinks sub rule,
      when {
        $x isa soft-drink;
      },
      then {
        $x has retailer 'Tesco';
      };
      """
    Given for each session, graql insert
      """
      insert
      $x isa person, has string-attribute "Tesco", has ref 0;
      $y isa soft-drink, has name "Tesco", has ref 1;
      """
#    When materialised keyspace is completed
    Then for graql query
      """
      match
        $x has base-attribute $ax;
        $y has base-attribute $ay;
        $ax isa $typeof_ax;
        $ay isa $typeof_ay;
        $typeof_ax != $typeof_ay;
      get;
      """
#    Then in reasoned keyspace, all answers are correct
    # x   | ax  | y   | ay  |
    # PER | STA | SOF | NAM |
    # PER | STA | SOF | RET |
    # SOF | NAM | PER | STA |
    # SOF | RET | PER | STA |
    Then in reasoned keyspace, answer size is: 4
#    Then materialised and reasoned keyspaces are the same size


  # TODO: re-enable all steps once implicit attribute variables are resolvable
  Scenario: inferred attribute matches can be simultaneously restricted by both concept type and attribute value
    Given for each session, graql define
      """
      define
      base-attribute sub attribute, value string, abstract;
      string-attribute sub base-attribute;
      retailer sub base-attribute;

      transfer-string-attribute-to-other-people sub rule,
      when {
        $x isa person, has string-attribute $r1;
        $y isa person;
      },
      then {
        $y has string-attribute $r1;
      };

      tesco-sells-all-soft-drinks sub rule,
      when {
        $x isa soft-drink;
      },
      then {
        $x has retailer 'Tesco';
      };

      if-ocado-exists-it-sells-all-soft-drinks sub rule,
      when {
        $x isa retailer;
        $x == 'Ocado';
        $y isa soft-drink;
      },
      then {
        $y has retailer $x;
      };
      """
    Given for each session, graql insert
      """
      insert
      $w isa person, has string-attribute "Ocado", has ref 0;
      $x isa person, has string-attribute "Tesco", has ref 1;
      $y isa soft-drink, has name "Sprite", has ref 2;
      $z "Ocado" isa retailer;
      """
#    When materialised keyspace is completed
    Then for graql query
      """
      match
        $x has base-attribute $value;
        $y has base-attribute $unwantedValue;
        $value !== $unwantedValue;
        $unwantedValue "Ocado";
        $value isa $type;
        $unwantedValue isa $type;
        $type != $unwantedType;
        $unwantedType type string-attribute;
      get $x, $value, $type;
      """
#    Then in reasoned keyspace, all answers are correct
    # x      | value | type     |
    # Sprite | Tesco | retailer |
    Then in reasoned keyspace, answer size is: 1
#    Then materialised and reasoned keyspaces are the same size
