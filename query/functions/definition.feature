# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: Function Definition

  Background: Set up database
    Given typedb starts
    Given connection opens with default authentication
    Given connection is open: true
    Given connection has 0 databases
    Given connection create database: typedb

    Given connection open schema transaction for database: typedb
    Given typeql schema query
    """
    define
    entity person, owns name;
    attribute name, value string;
    """
    Given transaction commits


  Scenario: Functions can be defined
    Given connection open schema transaction for database: typedb
    Given typeql schema query
    """
    define
    fun five() -> integer :
    match
      let $five = 5;
    return first $five;
    """
    Given transaction commits


  Scenario: Functions can be undefined
    Given connection open schema transaction for database: typedb
    Given typeql schema query
    """
    define
    fun five() -> integer :
    match
      let $five = 5;
    return first $five;
    """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
    """
    match let $five = five();
    """
    Then answer size is: 1
    Given transaction closes

    Given connection open schema transaction for database: typedb
    When typeql schema query
    """
    undefine
    fun five;
    """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When typeql read query; fails with a message containing: "Could not resolve function with name 'five'."
    """
    match let $five = five();
    """


  Scenario: Functions can be redefined
    Given connection open schema transaction for database: typedb
    Given typeql schema query
    """
    define
    fun five() -> integer :
    match
      let $five = 4;
    return first $five;
    """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
    """
    match let $five = five();
    """
    Then uniquely identify answer concepts
      | five         |
      | value:integer:4 |
    Given transaction closes

    Given connection open schema transaction for database: typedb
    When typeql schema query
    """
    redefine
    fun five() -> integer :
    match
      let $five = 5;
    return first $five;
    """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
    """
    match let $five = five();
    """
    Then uniquely identify answer concepts
      | five         |
      | value:integer:5 |
    Given transaction closes


  Scenario: Functions are stratified wrt negation
    Given connection open schema transaction for database: typedb
    Given typeql schema query
    """
    define
    attribute nickname, value string;
    person owns nickname;
    entity nickname-mapping, owns name, owns nickname;
    """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    Given typeql schema query
    """
    define
    fun nickname_of($p: person) -> { nickname }:
    match
      let $dummy = $nickname;
      { $p has nickname $nickname; } or
      { let $nickname in default_nickname($p); };
    return { $nickname };

    fun default_nickname($p: person) -> { nickname }:
    match
      not { let $ignored in nickname_of($p); }; # $p has no nickname
      $nickname-mapping isa nickname-mapping;
      $p has name $name;
      $nickname-mapping has name $name;
      $nickname-mapping has nickname $nickname;
    return { $nickname };
    """
    Given transaction commits; fails with a message containing: "Detected a recursive cycle through a negation or reduction"
    Given connection open read transaction for database: typedb
    Given typeql read query; fails with a message containing: "Detected a recursive cycle through a negation or reduction"
    """
    with
    fun nickname_of($p: person) -> { nickname }:
    match
      let $dummy = $nickname;
      { $p has nickname $nickname; } or
      { let $nickname in default_nickname($p); };
    return { $nickname };

    with
    fun default_nickname($p: person) -> { nickname }:
    match
      not { let $ignored in nickname_of($p); }; # $p has no nickname
      $nickname-mapping isa nickname-mapping;
      $p has name $name;
      $nickname-mapping has name $name;
      $nickname-mapping has nickname $nickname;
    return { $nickname };

    match
      $p isa person;
      let $nickname in nickname_of($p);
    """


  Scenario: Functions are stratified wrt aggregates
    Given connection open schema transaction for database: typedb
    Given typeql schema query
    """
    define
    relation purchase relates item, relates customer;
    person plays purchase:customer;
    attribute price, value double;
    entity item, plays purchase:item, owns price;
  """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    Given typeql schema query
  """
    define
    fun annual_reward($customer: person) -> {double}:
    match
      let $dummy = $reward;
      { $purchase isa purchase ($customer, $item); let $reward in purchase_reward($item); } or
      { let $reward in special_rewards($customer); };
    reduce $total_rewards = sum($reward);
    return { $total_rewards };

    fun purchase_reward($item: item) -> { double }:
    match
      $item has price $price;
      let $reward = 1.1 * $price;
    return { $reward };

    fun special_rewards($customer: person) -> {double}:
    match
       let $joining_bonus = 1000;
       let $loyalty = loyalty_bonus($customer);
       let $total = $joining_bonus + $loyalty;
    return { $total };

    fun loyalty_bonus($customer: person) ->  { double }:
    match
      $customer has joining-year $year;
      let $years-completed = (2024 - $year);
      let $loyalty-bonus = annual_reward($p) * (1 + $years-completed * 0.01); # An extra 1% per year!!!
    return { $loyalty-bonus };
    """
    Then transaction commits; fails with a message containing: "Detected a recursive cycle through a negation or reduction"

    Given connection open read transaction for database: typedb
    Then typeql read query; fails with a message containing: "Detected a recursive cycle through a negation or reduction"
    """
    with
    fun annual_reward($customer: person) -> {double}:
    match
      let $dummy = $reward;
      { $purchase isa purchase ($customer, $item); let $reward in purchase_reward($item); } or
      { let $reward in special_rewards($customer); };
    reduce $total_rewards = sum($reward);
    return { $total_rewards };

    with
    fun purchase_reward($item: item) -> { double }:
    match
      $item has price $price;
      let $reward = 1.1 * $price;
    return { $reward };

    with
    fun special_rewards($customer: person) -> {double}:
    match
       let $joining_bonus = 1000;
       let $loyalty = loyalty_bonus($customer);
       let $total = $joining_bonus + $loyalty;
    return { $total };

    with
    fun loyalty_bonus($customer: person) ->  { double }:
    match
      $customer has joining-year $year;
      let $years-completed = (2024 - $year);
      let $loyalty-bonus = annual_reward($p) * (1 + $years-completed * 0.01); # An extra 1% per year!!!
    return { $loyalty-bonus };

    match
      $p isa person;
      let $reward in annual_reward($p);
    """


  Scenario: A function being undefined must not be referenced by a separate function which is not being undefined.
    Given connection open schema transaction for database: typedb
    Given typeql schema query
    """
    define
    attribute nickname, value string;
    person owns nickname;
    """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    Given typeql schema query
    """
    define
    fun nickname_of($p: person) -> { nickname }:
    match
      let $nickname in default_nickname($p);
    return { $nickname };

    fun default_nickname($p: person) -> { nickname }:
    match
      $p isa $t; # Avoid unused argument
      $nickname isa nickname "Steve";
    return { $nickname };
    """
    Given transaction commits
    Given connection open schema transaction for database: typedb
    Given typeql schema query
    """
    undefine
    fun default_nickname;
    """
    Then transaction commits; fails with a message containing: "Could not resolve function with name 'default_nickname'"


  Scenario: If a modification of a function causes a caller function to become invalid, the modification is blocked.
    Given connection open schema transaction for database: typedb
    Given typeql schema query
    """
    define
    attribute nickname, value string;
    person owns nickname;
    """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    Given typeql schema query
    """
    define
    fun nickname_of($p: person) -> { nickname }:
    match
      let $nickname in default_nickname($p);
    return { $nickname };

    fun default_nickname($p: person) -> { nickname }:
    match
      $p isa $t; # Avoid unused argument
      $nickname isa nickname "Steve";
    return { $nickname };
    """
    Given transaction commits
    Given connection open schema transaction for database: typedb
    Given typeql schema query
    """
    redefine
    fun default_nickname($p: person) -> { string }:
    match
      $p isa $t; # Avoid unused argument
      $nickname_attr isa nickname "Steve";
      let $nickname_value = $nickname_attr;
    return { $nickname_value };
    """
    Then transaction commits; fails with a message containing: "Type checking all functions currently defined failed"


  Scenario: If a modification of the schema causes a stored function to become invalid, the modification is blocked at commit time
    Given connection open schema transaction for database: typedb
    Given typeql schema query
    """
    define
    attribute nickname, value string;
    person owns nickname;
    """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    Given typeql schema query
    """
    define
    fun nickname_of($p: person) -> { nickname }:
    match
      $p isa $t; # Avoid unused argument
      $nickname isa nickname;
      $nickname == "Steve";
    return { $nickname };

    """
    Given transaction commits
    Given connection open schema transaction for database: typedb
    Given typeql schema query
    """
    undefine
    nickname;
    """
    Then transaction commits; fails
    # TODO: Add messsage when it's an explicit check at query time


  # TODO: 3.x: (Or rather, me right now) See if we're missing any of these.
  #############
  # FUNCTIONS #
  #############
# TODO: Write new tests for functions. Consider old Rules tests to be reimplemented if applicable
#  Scenario: undefining a rule removes it
#    Given typeql schema query
#      """
#      define
#      entity company, plays employment:employer;
#      rule a-rule:
#      when {
#        $c isa company; $y isa person;
#      } then {
#        (employer: $c, employee: $y) isa employment;
#      };
#      """
#    Given transaction commits
#
#    When connection open schema transaction for database: typedb
#    Then rules contain: a-rule
#    When typeql schema query
#      """
#      undefine rule a-rule;
#      """
#    Then transaction commits
#
#    When connection open read transaction for database: typedb
#    Then rules do not contain: a-rule
#
#  Scenario: after undefining a rule, concepts previously inferred by that rule are no longer inferred
#    Given typeql schema query
#      """
#      define
#      rule samuel-email-rule:
#      when {
#        $x has email "samuel@typedb.com";
#      } then {
#        $x has name "Samuel";
#      };
#      """
#    Given transaction commits
#
#    Given connection open write transaction for database: typedb
#    Given typeql write query
#      """
#      insert $x isa person, has email "samuel@typedb.com";
#      """
#    Given transaction commits
#
#    Given connection open read transaction for database: typedb
#    Given get answers of typeql read query
#      """
#      match
#        $x has name $n;
#      get $n;
#      """
#    Given uniquely identify answer concepts
#      | n                 |
#      | attr:name:Samuel  |
#    Given transaction closes
#    Given connection open schema transaction for database: typedb
#    When typeql schema query
#      """
#      undefine rule samuel-email-rule;
#      """
#    Then transaction commits
#
#    When connection open read transaction for database: typedb
#    Then typeql read query; fails with a message containing: "empty-set for some variable"
#      """
#      match
#        $x has name $n;
#      get $n;
#      """
#
#
#  # enable when we can do reasoning in a schema write transaction (it was a todo previously, not relevant anymore)
#  @ignore
#  Scenario: when undefining a rule, concepts inferred by that rule can still be retrieved until the next commit
#    Given typeql schema query
#      """
#      define
#      rule samuel-email-rule:
#      when {
#        $x has email "samuel@typedb.com";
#      } then {
#        $x has name "Samuel";
#      };
#      """
#    Given transaction commits
#
#    Given connection open write transaction for database: typedb
#    Given typeql write query
#      """
#      insert $x isa person, has email "samuel@typedb.com";
#      """
#    Given transaction commits
#
#    Given connection open schema transaction for database: typedb
#    Given get answers of typeql read query
#      """
#      match
#        $x has name $n;
#      get $n;
#      """
#    Given uniquely identify answer concepts
#      | n                 |
#      | attr:name:Samuel  |
#    When typeql schema query
#      """
#      undefine rule samuel-email-rule;
#      """
#
#    When get answers of typeql read query
#      """
#      match
#        $x has name $n;
#      get $n;
#      """
#    Then uniquely identify answer concepts
#      | n                 |
#      | attr:name:Samuel  |
#
#  Scenario: You cannot undefine a type if it is used in a rule
#    Given typeql schema query
#    """
#    define
#
#    entity type-to-undefine, owns name;
#
#    rule rule-referencing-type-to-undefine:
#    when {
#      $x isa type-to-undefine;
#    } then {
#      $x has name "dummy";
#    };
#    """
#    Given transaction commits
#
#    Given connection open schema transaction for database: typedb
#
#    Given typeql schema query; fails
#    """
#    undefine
#      type-to-undefine;
#    """
#
#  Scenario: You cannot undefine a type if it is used in a negation in a rule
#    Given typeql schema query
#    """
#    define
#    relation rel, relates rol;
#    entity other-type, owns name, plays rel:rol;
#    entity type-to-undefine, owns name, plays rel:rol;
#
#    rule rule-referencing-type-to-undefine:
#    when {
#      $x isa other-type;
#      not { ($x, $y) isa relation; $y isa type-to-undefine; };
#    } then {
#      $x has name "dummy";
#    };
#    """
#    Given transaction commits
#
#    Given connection open schema transaction for database: typedb
#
#    Given typeql schema query; fails
#    """
#    undefine
#      type-to-undefine;
#    """
#
#  Scenario: You cannot undefine a type if it is used in any disjunction in a rule
#    Given typeql schema query
#    """
#    define
#
#    entity type-to-undefine, owns name;
#
#    rule rule-referencing-type-to-undefine:
#    when {
#      $x has name $y;
#      { $x isa person; } or { $x isa type-to-undefine; };
#    } then {
#      $x has name "dummy";
#    };
#    """
#    Given transaction commits
#
#    Given connection open schema transaction for database: typedb
#
#    Given typeql schema query; fails
#    """
#    undefine
#      type-to-undefine;
#    """
#
#  Scenario: You cannot undefine a type if it is used in the then of a rule
#    Given typeql schema query
#    """
#    define
#    attribute name-to-undefine, value string;
#    entity some-type, owns name-to-undefine;
#
#    rule rule-referencing-type-to-undefine:
#    when {
#      $x isa some-type;
#    } then {
#      $x has name-to-undefine "dummy";
#    };
#    """
#    Given transaction commits
#
#    Given connection open schema transaction for database: typedb
#
#    Given typeql schema query; fails
#    """
#    undefine
#      name-to-undefine;
#    """
