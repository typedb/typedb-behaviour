# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: Basic Analyze queries

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
      attribute ref value integer;
      attribute name value string;
      relation friendship, relates friend @card(2);
      entity person,
        owns name, owns ref @key,
        plays friendship:friend;
      """
    Given transaction commits


  Scenario: Analyze returns the structure of each stage in the query
    Given connection open read transaction for database: typedb
    When get answers of typeql analyze query
      """
      match $x isa person; $n isa name;
      insert $x has $n;
      """
    Then analyzed query pipeline structure is:
    """
    Pipeline([
      Match([
        Isa($x, person),
        Isa($n, name)
      ]),
      Insert([
        Has($x, $n)
      ])
    ])
    """
    Given transaction closes


  Scenario: Analyze returns the structure of each function in the preamble
    Given connection open read transaction for database: typedb
    When get answers of typeql analyze query
      """
      with
      fun persons() -> { person }:
      match $p isa person;
      return { $p };

      with
      fun name_of($p: person) -> name:
      match $p has name $n;
      return first $n;

      match
        let $p in persons();
        let $n = name_of($p);
      """
    Then analyzed query preamble contains:
    """
    Function(
      [],
      Stream([$p]),
      Pipeline([
        Match([Isa($p, person)])
      ])
    )
    """
    Then analyzed query preamble contains:
    """
    Function(
      [$p],
      Single(first, [$n]),
      Pipeline([
        Match([
          Has($p, $n),
          Isa($n, name)
        ])
      ])
    )
    """
    Then analyzed query pipeline structure is:
    """
    Pipeline([
      Match([
        FunctionCall(persons(),[$p],[]),
        FunctionCall(name_of($p),[$n],[$p])
      ])
    ])
    """
    Given transaction closes


  Scenario: Nested patterns can be reconstructed from the analyzed query
    Given connection open read transaction for database: typedb
    When get answers of typeql analyze query
      """
      match
        $p isa person;
        { $p has name "John"; } or { $p has ref 0; };
        not { $p has name "Doe"; };
      """
    Then analyzed query pipeline structure is:
    """
    Pipeline([
      Match([
        Isa($p, person),
        Or([
          [Comparison($_, "John", ==), Has($p, $_), Isa($_, name) ],
          [Comparison($_, 0, ==), Has($p, $_), Isa($_, ref)]
        ]),
        Not([Comparison($_, "Doe", ==), Has($p, $_), Isa($_, name)])
      ])
    ])
    """
    Given transaction closes


  Scenario: All relevant constraints are present in the structure
    Given connection open read transaction for database: typedb
    When get answers of typeql analyze query
      """
      with
      fun pi() -> double:
        match let $pi = 3.14; # close enough?
      return first $pi;

      match
        $p1 isa! person, has name $n1;
        $n1 contains "son";
        $f isa friendship, links (friend: $p1, $p2);
        $p1 is $p2;
        let $x = ceil(2 * pi());
      """
    Then analyzed query pipeline structure is:
    """
    Pipeline([
      Match([
        IsaExact($p1, person), Has($p1, $n1), Isa($n1, name),
        Comparison($n1, "son", contains),
        Isa($f, friendship), Links($f, $p1, friend), Links($f, $p2, $_),
        Is($p1, $p2),
        FunctionCall(pi(), [$_], []),
        Expression(let $x = ceil(2 * pi()), [$x], [$_])
      ])
    ])
    """
    Given transaction closes
