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


  Scenario: Functions with undefined types in their signature error.
    Given connection open schema transaction for database: typedb
    When typeql schema query
    """
    define
    fun get_attr($arg: doesnotexist) -> integer :
    match
      $arg has $a;
      let $x = $a;
    return first $x;
    """
    Then transaction commits; fails with a message containing: "An error occurred when trying to resolve the type of the argument at index: 0"

    Given connection open schema transaction for database: typedb
    When typeql schema query
    """
    define
    fun pi() -> irrational :
    match
      let $x = 3.2;
    return first $x;
    """
    Then transaction commits; fails with a message containing: "An error occurred when trying to resolve the type at return index: 0"


  Scenario: A functions with an unused argument errors
    Given connection open schema transaction for database: typedb
    When typeql schema query; fails with a message containing: "Function argument variable 'arg' is unused."
    """
    define
    fun get_attr($arg: person) -> { name } :
    match
      $arg_with_a_typo has name $name;
    return { $name };
    """
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

    # TODO: 3.x: Add the negation in just one branch of a disjunction.


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


  # TODO: The following tests are old tests for rules from the concept/migration directory.
  # Rewrite these tests to functions if needed (otherwise, delete) and make sure that every schema modification
  # affecting functions (even if uncovered by rules) is validated accordingly.
#  Scenario: Types which are referenced in rules may not be renamed
#    Given typeql schema query
#    """
#    define
#      rel00 sub relation, relates role00;
#      rel01 sub relation, relates role01;
#      ent0 sub entity, plays rel00:role00, plays rel01:role01;
#
#      rule make-me-illegal:
#      when {
#        (role00: $e) isa rel00;
#      } then {
#        (role01: $e) isa rel01;
#      };
#    """
#    Given transaction commits
#
#    When connection open schema transaction for database: typedb
#    Then relation(rel00) set label: renamed-rel00
#    Then transaction commits; fails
#
#  Scenario: Types which are referenced in rules may not be deleted
#    Given typeql schema query
#    """
#    define
#      rel00 sub relation, relates role00, relates extra_role;
#      rel01 sub relation, relates role01;
#      rel1 sub rel00;
#      ent0 sub entity, plays rel00:role00, plays rel01:role01;
#
#      rule make-me-illegal:
#      when {
#        (role00: $e) isa rel1;
#      } then {
#        (role01: $e) isa rel01;
#      };
#    """
#    Given transaction commits
#
#    When connection open schema transaction for database: typedb
#    Then delete relation type: rel01; fails
#
#    When transaction closes
#    When connection open schema transaction for database: typedb
#    Then delete relation type: rel1; fails
#
#    When transaction closes
#    When connection open schema transaction for database: typedb
#    Then relation(rel01) delete role: role01; fails
#
#    # We currently can't do this at operation time, so we check at commit-time
#    When transaction closes
#    When connection open schema transaction for database: typedb
#    Then relation(rel00) delete role: role00
#    Then transaction commits; fails
#
#  Scenario: Rules made unsatisfiable by schema modifications are flagged at commit time
#    Given typeql schema query
#    """
#    define
#      rel00 sub relation, relates role00, relates extra_role;
#      rel01 sub relation, relates role01;
#      rel1 sub rel00;
#
#      ent00 sub entity, abstract, plays rel00:role00, plays rel01:role01;
#      ent01 sub entity, abstract;
#      ent1 sub ent00;
#
#      rule make-me-unsatisfiable:
#      when {
#        $e isa ent1;
#        (role00: $e) isa rel1;
#      } then {
#        (role01: $e) isa rel01;
#      };
#    """
#    Given transaction commits
#
#    When connection open schema transaction for database: typedb
#    Then relation(rel1) set supertype: rel01
#    Then transaction commits; fails
#
#    When connection open schema transaction for database: typedb
#    Then entity(ent00) unset plays: rel00:role00
#    Then transaction commits; fails
#
#    When connection open schema transaction for database: typedb
#    Then entity(ent1) set supertype: ent01
#    Then transaction commits; fails