# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: Attribute Attachment Resolution

  Background: Set up database
    Given typedb starts
    Given connection opens with default authentication
    Given reasoning schema
      """
      define

      person sub entity,
          plays team:leader,
          plays team:member,
          owns string-attribute,
          owns unrelated-attribute,
          owns age,
          owns is-old;

      tortoise sub entity,
          owns age,
          owns is-old;

      soft-drink sub entity,
          owns retailer;

      team sub relation,
          relates leader,
          relates member,
          owns string-attribute;

      string-attribute sub attribute, value string;
      retailer sub attribute, value string;
      age sub attribute, value long;
      is-old sub attribute, value boolean;
      unrelated-attribute sub attribute, value string;
      """


  # TODO: REMOVE: I guess we can't do this anymore.
  Scenario: a rule can infer an attribute value that did not previously exist in the graph


  Scenario: a function with disjunctions considers every branch
    Given reasoning schema
      """
      define
      crisps sub entity, owns retailer;
      rule tesco-sells-everything-ocado-sells-and-all-soft-drinks: when {
        $x isa $t;
        {$x has retailer 'Ocado';} or {$t type soft-drink;};
      } then {
        $x has retailer 'Tesco';
      };
      """
    Given reasoning data
      """
      insert
      $aeW isa crisps;
      $aeX isa crisps, has retailer 'Ocado';
      $aeY isa soft-drink;
      $aeZ isa soft-drink;
      """
    Given verifier is initialised
    Given reasoning query
      """
      match $x has retailer 'Tesco';
      """
    Then verify answer size is: 3
    Then verify answers are sound
    Then verify answers are complete
    Then verify answer set is equivalent for query
      """
      match
      $x isa $t;
      {$x has retailer 'Ocado';} or {$t type soft-drink;};
      get $x;
      """


  Scenario: a function with negated disjunctions considers every branch
    Given reasoning schema
      """
      define
      crisps sub entity, owns retailer;
      rule tesco-sells-everything-that-Ocado-doesnt-except-soft-drinks: when {
        $x isa $t; $t owns retailer;
        not { {$x has retailer 'Ocado';} or {$t type soft-drink;}; };
      } then {
        $x has retailer 'Tesco';
      };
      """
    Given reasoning data
      """
      insert
      $aeW isa crisps;
      $aeX isa crisps, has retailer 'Ocado';
      $aeY isa soft-drink;
      $aeZ isa soft-drink;
      """
    Given verifier is initialised
    Given reasoning query
      """
      match $x has retailer 'Tesco';
      """
    Then verify answer size is: 1
    Then verify answers are sound
    Then verify answers are complete
    Then verify answer set is equivalent for query
      """
      match
      $x isa $t; $t owns retailer;
      not {$x has retailer 'Ocado';}; not {$t type soft-drink;};
      get $x;
      """


  Scenario: A function can return a value derived from an expression
    Given reasoning schema
      """
      define
      age-in-days sub attribute, value long;
      tortoise owns age-in-days;
      person owns age-in-days;

      rule infer-age-in-days-from-age-in-years:
      when {
        $x has age $age;
        ?age-in-days = $age * 365;
      } then {
        $x has age-in-days ?age-in-days;
      };
      """
    Given reasoning data
      """
      insert
      $t isa tortoise, has age 60;
      """
    Given verifier is initialised
    Given reasoning query
      """
      match $x has age-in-days $days;
      """
    Then verify answer size is: 1
    Then verify answers are sound
    Then verify answers are complete

    Given reasoning query
      """
      match
        $x has age-in-days $days-thing;
        ?days = $days-thing;
      get
        ?days;
      """
    Then verify answer size is: 1
    Then verify answer set is equivalent for query
      """
      match
        $x type thing;    # Query needs a concrete variable
        ?days = 21900;
      get
        ?days;
      """
