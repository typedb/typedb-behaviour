# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: Compound Query Resolution

  Background: Set up database
    Given typedb starts
    Given connection opens with default authentication
    Given reasoning schema
      """
      define

      person sub entity,
        owns name;

      soft-drink sub entity,
        owns name,
        owns retailer;

      string-attribute sub attribute, value string, abstract;
      retailer sub attribute, value string;
      name sub attribute, value string;
      """
    # each scenario specialises the schema further


  Scenario: Functions can be called in expressions.
    # TODO

  Scenario: Functions can be called in comparators.
    # TODO

  Scenario: Functions can be called in `is` statements.
    # TODO

  

  Scenario: repeated function calls within a query trigger execution from all pattern occurrences
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

      """
    Then verify answers are sound
    Then verify answers are complete
    # x   | ax  | y   | ay  |
    # PER | BSA | SOF | NAM |
    # PER | BSA | SOF | RET |
    # SOF | NAM | PER | BSA |
    # SOF | RET | PER | BSA |
    # SOF | NAM | SOF | RET |
    # SOF | RET | SOF | NAM |
    Then verify answer size is: 9
    Then verify answers are sound
    Then verify answers are complete
