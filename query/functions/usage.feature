# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: Function call positions behaviour

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
    fun five() -> long :
    match
      $five = 5;
    return first $five;
    """
    Given transaction commits

  Scenario: Functions can be undefined
    Given connection open schema transaction for database: typedb
    Given typeql schema query
    """
    define
    fun five() -> long :
    match
      $five = 5;
    return first $five;
    """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
    """
    match $five = five();
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
    match $five = five();
    """

  Scenario: Functions can be redefined
    Given connection open schema transaction for database: typedb
    Given typeql schema query
    """
    define
    fun five() -> long :
    match
      $five = 4;
    return first $five;
    """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
    """
    match $five = five();
    """
    Then uniquely identify answer concepts
      | five         |
      | value:long:4 |
    Given transaction closes

    Given connection open schema transaction for database: typedb
    When typeql schema query
    """
    redefine
    fun five() -> long :
    match
      $five = 5;
    return first $five;
    """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
    """
    match $five = five();
    """
    Then uniquely identify answer concepts
      | five         |
      | value:long:5 |
    Given transaction closes

  Scenario: Functions can be called in expressions.
    Given connection open schema transaction for database: typedb
    Given typeql schema query
    """
    define
    fun five() -> long :
    match
      $five = 5;
    return first $five;
    """
    Given transaction commits
    Given connection open read transaction for database: typedb
    When get answers of typeql read query
    """
    match
      $six = five() + 1;
    """
    Then uniquely identify answer concepts
      | six          |
      | value:long:6 |
    Given transaction closes


  Scenario: Functions can be called in comparators.
    Given connection open schema transaction for database: typedb
    Given typeql schema query
    """
    define
    fun five() -> long :
    match
      $five = 5;
    return first $five;

    fun six() -> long :
    match
      $six = 6;
    return first $six;
    """
    Given transaction commits
    Given connection open read transaction for database: typedb
    When get answers of typeql read query
    """
    match
      five() < 6;
    """
    Then answer size is: 1
    When get answers of typeql read query
    """
    match
      5 < six();
    """
    Then answer size is: 1
    When get answers of typeql read query
    """
    match
      five() < six();
    """
    Then answer size is: 1
    When get answers of typeql read query
    """
    match
      five() > six();
    """
    Then answer size is: 0


  Scenario: repeated function calls within a query trigger execution from all pattern occurrences
    Given connection open schema transaction for database: typedb
    Given typeql schema query
    """
    define
    fun five() -> long :
    match
      $five = 5;
    return first $five;
    """
    Given transaction commits
    Given connection open read transaction for database: typedb
    When get answers of typeql read query
    """
    match
      $ten = five() + five();
    """
    Then uniquely identify answer concepts
      | ten           |
      | value:long:10 |
    Given transaction closes

  Scenario: The same variable cannot be 'assigned' to twice, either by the same or different functions.
    Given connection open schema transaction for database: typedb
    Given typeql schema query
    """
    define
    fun five() -> long :
    match
      $five = 5;
    return first $five;
    """
    Given transaction commits
    Given connection open read transaction for database: typedb
    When typeql read query; fails
    """
    match
      $five = five();
      $five = five();
    """


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
      $dummy = $nickname;
      { $p has nickname $nickname; } or
      { $nickname in default_nickname($p); };
    return { $nickname };

    fun default_nickname($p: person) -> { nickname }:
    match
      not { $ignored in nickname_of($p); }; # $p has no nickname
      $nickname-mapping isa nickname-mapping;
      $p has name $name;
      $nickname-mapping has name $name;
      $nickname-mapping has nickname $nickname;
    return { $nickname };
    """
    Given transaction commits; fails with a message containing: "StratificationViolation"
    Given connection open read transaction for database: typedb
    Given typeql read query; fails with a message containing: "StratificationViolation"
    """
    with
    fun nickname_of($p: person) -> { nickname }:
    match
      $dummy = $nickname;
      { $p has nickname $nickname; } or
      { $nickname in default_nickname($p); };
    return { $nickname };

    with
    fun default_nickname($p: person) -> { nickname }:
    match
      not { $ignored in nickname_of($p); }; # $p has no nickname
      $nickname-mapping isa nickname-mapping;
      $p has name $name;
      $nickname-mapping has name $name;
      $nickname-mapping has nickname $nickname;
    return { $nickname };

    match
      $p isa person;
      $nickname in nickname_of($p);
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
      $dummy = $reward;
      { ($customer, $item) isa purchase; $reward in purchase_reward($item); } or
      { $reward in special_rewards($customer); };
    reduce $total_rewards = sum($reward);
    return { $total_rewards };

    fun purchase_reward($item: item) -> { double }:
    match
      $item has price $price;
      $reward = 1.1 * $price;
    return { $reward };

    fun special_rewards($customer: person) -> {double}:
    match
       $joining_bonus = 1000;
       $loyalty = loyalty_bonus($customer);
       $total = $joining + $loyalty;
    return { $total };

    fun loyalty_bonus($customer: person) ->  { double }:
    match
      $customer has joining-year $year;
      $years-completed = (2024 - $year);
      $loyalty-bonus = annual_reward($p) * (1 + $years-completed * 0.01); # An extra 1% per year!!!
    return { $loyalty-bonus };
    """
    Then transaction commits; fails with a message containing: "StratificationViolation"

    Given connection open read transaction for database: typedb
    Then typeql read query; fails with a message containing: "StratificationViolation"
    """
    with
    fun annual_reward($customer: person) -> {double}:
    match
      $dummy = $reward;
      { ($customer, $item) isa purchase; $reward in purchase_reward($item); } or
      { $reward in special_rewards($customer); };
    reduce $total_rewards = sum($reward);
    return { $total_rewards };

    with
    fun purchase_reward($item: item) -> { double }:
    match
      $item has price $price;
      $reward = 1.1 * $price;
    return { $reward };

    with
    fun special_rewards($customer: person) -> {double}:
    match
       $joining_bonus = 1000;
       $loyalty = loyalty_bonus($customer);
       $total = $joining + $loyalty;
    return { $total };

    with
    fun loyalty_bonus($customer: person) ->  { double }:
    match
      $customer has joining-year $year;
      $years-completed = (2024 - $year);
      $loyalty-bonus = annual_reward($p) * (1 + $years-completed * 0.01); # An extra 1% per year!!!
    return { $loyalty-bonus };

    match
      $p isa person;
      $reward in annual_reward($p);
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
      $nickname in default_nickname($p);
    return { $nickname };

    fun default_nickname($p: person) -> { nickname }:
    match
      $p isa $t; # Avoid unused argument
      $nickname "Steve" isa nickname;
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
      $nickname in default_nickname($p);
    return { $nickname };

    fun default_nickname($p: person) -> { nickname }:
    match
      $p isa $t; # Avoid unused argument
      $nickname "Steve" isa nickname;
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
      $nickname_attr "Steve" isa nickname;
      $nickname_value = $nickname_attr;
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

