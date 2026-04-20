# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: Validate Function Signatures Against Definition & Calls

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
    entity person, owns name, owns weight, owns nationality;
    entity cat, owns name, owns weight, owns breed;
    attribute name, value string;
    attribute nationality, value string;
    attribute breed, value string;
    attribute weight, value double;
    """
    Given transaction commits


  Scenario: Functions whose return do not match the signature error
    Given connection open schema transaction for database: typedb
    Then typeql schema query; fails with a message containing: "The function declares it returns 2 item(s), but the definition returns 1"
    """
    define
    fun i_return_a_stream_of_two() -> { person, person }:
    match
      $x isa person; $y isa person;
    return { $x };
    """

    Given connection open schema transaction for database: typedb
    Then typeql schema query; fails with a message containing: "The function declares it returns 1 item(s), but the definition returns 2"
    """
    define
    fun i_return_a_stream_of_one() -> { person }:
    match
      $x isa person; $y isa person;
    return { $x, $y };
    """

    Given connection open schema transaction for database: typedb
    Then typeql schema query; fails with a message containing: "The function declares it returns a single row but the implementation returns a stream"
    """
    define
    fun i_return_a_single_person() -> person:
    match
      $x isa person;
    return { $x };
    """

    Given connection open schema transaction for database: typedb
    Then typeql schema query; fails with a message containing: "The function declares it returns a stream but the implementation returns a single row"
    """
    define
    fun i_return_a_stream_of_persons() -> { person }:
    match
      $x isa person;
    return first $x;
    """

    Given connection open schema transaction for database: typedb
    Then typeql schema query; fails with a message containing: "The function declares it returns a single row but the implementation returns a stream"
    """
    define
    fun i_return_a_string() -> string:
    match
      $x isa person;
    return { $x };
    """

    Given connection open schema transaction for database: typedb
    Then typeql schema query; fails with a message containing: "The optionality of the value returned by the function at index '1' did not match that declared in the signature"
    """
    define
    fun the_first_returned_value_is_optional() -> { person, person }:
    match
      $x isa person;
      try { $y isa person; };
    return { $x, $y };
    """


  Scenario Outline: A function returning the <op> of a stream must declare the corresponding return as optional
    Given connection open schema transaction for database: typedb
    Then typeql schema query; fails with a message containing: "The optionality of the value returned by the function at index '0' did not match that declared in the signature"
    """
    define
    fun my_reduce_returns_optional() -> double:
    match
      $x isa person, has weight $weight;
    return <op>($weight);
    """

    Given connection open schema transaction for database: typedb
    When typeql schema query
    """
    define
    fun my_reduce_returns_optional() -> double?:
    match
      $x isa person, has weight $weight;
    return <op>($weight);
    """
    Then transaction commits
    Examples:
      | op     |
      | min    |
      | max    |
      | median |
      | std    |


  Scenario: Functions which do not return the specified type fail type-inference
    Given connection open schema transaction for database: typedb
    When typeql schema query
    """
    define
    fun cats_of_name($name: name) -> { cat }:
    match
      $name isa name;
      $cat isa person, has $name;
    return { $cat };
    """
    Then transaction commits; fails with a message containing: "The types inferred for the return statement of function 'cats_of_name' did not match those declared in the signature. Mismatching index: 0"

    Given connection open schema transaction for database: typedb
    When typeql schema query
    """
    define
    fun name_of_cat($cat: cat) -> { string }:
    match
      $name isa name;
      $cat has $name;
    return { $name };
    """
    Then transaction commits; fails with a message containing: "The types inferred for the return statement of function 'name_of_cat' did not match those declared in the signature. Mismatching index: 0"


  Scenario: Functions arguments which are inconsistent with the body fail type-inference
    Given connection open schema transaction for database: typedb
    When typeql schema query; fails
    """
    define
    fun cats_of_name($name: string) -> { cat }:
    match
      $name isa name;
      $cat isa cat, has $name;
    return { $cat };
    """

    Given connection open schema transaction for database: typedb
    When typeql schema query
    """
    define
    fun name_of_cat($cat: cat) -> { name }:
    match
      $cat isa person, has name $name;
    return { $name };
    """
    Then transaction commits; fails with a message containing: "Type-inference was unable to find compatible types for the pair of variables 'cat' & 'person'"


  Scenario: Function calls which do not match the arguments in the signature error
    Given connection open schema transaction for database: typedb
    Given typeql schema query
    """
    define
    fun cats_of_name($name: name) -> { cat }:
    match
      $name isa name;
      $cat isa cat, has $name;
    return { $cat };
    """
    Given transaction commits
    Given connection open read transaction for database: typedb
    Then typeql read query; fails
    """
    match
      let $name = "Socks";
      let $cat in cats_of_name($name);
    """
    Then typeql read query; fails
    """
    match
      $name isa breed;
      let $cat in cats_of_name($name);
    """


  Scenario: If the assignment of the return of the function calls do not match the signature, it is an error
    Given connection open schema transaction for database: typedb
    Given typeql schema query
    """
    define

    fun name_string_of_cat($cat: cat) -> { string }:
    match
      $name_attr isa name;
      $cat isa cat, has $name_attr;
      let $name = $name_attr;
    return { $name };
    """
    Given transaction commits
    Given connection open read transaction for database: typedb
    Then typeql read query; fails
    """
    match
      let $name in name_string_of_cat($cat);
      $name isa name;
      $other-cat has $name;
    """


  Scenario: Function calls with argument types inconsistent with the signature fail type-inference
    Given connection open schema transaction for database: typedb
    Given typeql schema query
    """
    define
    fun cats_of_name($name: name) -> { cat }:
    match
      $name isa name;
      $cat isa cat, has $name;
    return { $cat };
    """
    Given transaction commits
    Given connection open read transaction for database: typedb
    Then typeql read query; fails
    """
    match
      $name isa breed;
      let $cat in cats_of_name($name);
    """


  Scenario: Function calls with assigned variable types inconsistent with the signature fail type-inference
    Given connection open schema transaction for database: typedb
    Given typeql schema query
    """
    define
    fun name_attribute_of_cat($cat: cat) -> { name }:
    match
      $name isa name;
      $cat isa cat, has $name;
    return { $name };
    """
    Given transaction commits
    Given connection open read transaction for database: typedb
    Then typeql read query; fails
    """
    match
      let $name in name_attribute_of_cat($cat);
      $name isa breed;
    """


  Scenario: A function call assigning an optional returned value must mark the return as optional
    Given connection open schema transaction for database: typedb
    Given typeql schema query
    """
    define
    fun cats_and_their_names() -> { cat, name? }:
    match
      $cat isa cat;
      try { $cat has name $name; };
    return { $cat, $name };
    """
    Given transaction commits
    Given connection open read transaction for database: typedb
    Then typeql read query; fails with a message containing: "The variable 'name' is assigned an optional value but not marked with a '?'"
    """
    match
      let $cat, $name in cats_and_their_names();
    """

    When get answers of typeql read query
    """
    match
      let $cat, $name? in cats_and_their_names();
    """
    Then answer size is: 0


  Scenario: A variable assigned an optional value by a function call may not be referenced in the same stage
    Given connection open schema transaction for database: typedb
    Given typeql schema query
    """
    define
    fun cats_and_their_names() -> { cat, name? }:
    match
      $cat isa cat;
      try { $cat has name $name; };
    return { $cat, $name };
    """
    Given transaction commits
    Given connection open read transaction for database: typedb
    Then typeql read query; fails with a message containing: "The variable 'name' is optionally assigned by a function return, and may not be referenced elsewhere in the same stage"
    """
    match
      let $cat, $name? in cats_and_their_names();
      $p isa person, has name $name;
    """

    When get answers of typeql read query
    """
    match
      let $cat, $name? in cats_and_their_names();
    match
      try { $p isa person, has name $name; };
    """
    Then answer size is: 0

