# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: Effects a function signature have on the caller

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
    entity person, owns name, owns nationality;
    entity cat, owns name, owns breed;
    attribute name, value string;
    attribute nationality, value long;
    attribute breed, value string;
    """
    Given transaction commits


  Scenario: Functions whose return do not match the signature error
    Given connection open schema transaction for database: typedb
    Then typeql schema query; fails with a message containing: "The return statement in the body of the function did not match that in the signature"
    """
    define
    fun i_return_a_stream_of_two() -> { person, person }:
    match
      $x isa person; $y isa person;
    return { $x };
    """

    Then typeql schema query; fails with a message containing: "The return statement in the body of the function did not match that in the signature"
    """
    define
    fun i_return_a_stream_of_one() -> { person }:
    match
      $x isa person; $y isa person;
    return { $x, $y };
    """

    Then typeql schema query; fails with a message containing: "The return statement in the body of the function did not match that in the signature"
    """
    define
    fun i_return_a_single_person() -> person:
    match
      $x isa person;
    return { $x };
    """

    Then typeql schema query; fails with a message containing: "The return statement in the body of the function did not match that in the signature"
    """
    define
    fun i_return_a_stream_of_persons() -> { person }:
    match
      $x isa person;
    return first $x;
    """

    Then typeql schema query; fails with a message containing: "The return statement in the body of the function did not match that in the signature"
    """
    define
    fun i_return_a_string() -> string:
    match
      $x isa person;
    return { $x };
    """
    Given transaction closes


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
    Then transaction commits; fails with a message containing: "The types inferred for the return statement did not those declared in the signature"

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
    Then transaction commits; fails with a message containing: "The types inferred for the return statement did not those declared in the signature"


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
    Given transaction closes

    Given connection open schema transaction for database: typedb
    When typeql schema query
    """
    define
    fun name_of_cat($cat: cat) -> { name }:
    match
      $cat isa person, has name $name;
    return { $name };
    """
    Then transaction commits; fails with a message containing: "Type-inference derived an empty-set for some variable"


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
      $name = "Socks";
      $cat in cats_of_name($name);
    """
    Then typeql read query; fails
    """
    match
      $name isa breed;
      $cat in cats_of_name($name);
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
      $name = $name_attr;
    return { $name };
    """
    Given transaction commits
    Given connection open read transaction for database: typedb
    Then typeql read query; fails
    """
    match
      $name in name_string_of_cat($cat);
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
      $cat in cats_of_name($name);
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
      $name in name_attribute_of_cat($cat);
      $name isa breed;
    """


