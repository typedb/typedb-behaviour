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


  Scenario: Functions are stratified wrt aggregates
    Given connection open schema transaction for database: typedb
    Given typeql schema query
    """
    define
    relation purchase relates item, relates customer;
    person plays purchase:customer;
    attribute price, value double;
    entity item, plays purchase:item, owns price;

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
    Given transaction commits
    # Given transaction commits; fails with a message containing: "StratificationViolation"


  Scenario: A function being undefined must not be referenced by a separate function which is not being undefined.
    Given TODO

  Scenario: If a modification of a function causes a caller function to become invalid, the modification is blocked.
    Given TODO

  Scenario: If a modification of the schema causes a stored function to become invalid, the modification is blocked at commit itme
    Given TODO
