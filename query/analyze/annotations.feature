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
      entity dummy;
      entity subdummy sub dummy;
      relation friendship, relates friend @card(2);
      entity person,
        owns name, owns ref @key,
        plays friendship:friend;
      """
    Given transaction commits


  Scenario: Analyze returns the annotations of variables in the query
    Given connection open read transaction for database: typedb
    When get answers of typeql analyze query
      """
      match $x isa person;
      """
    Then analyzed query pipeline annotations are:
    """
    Pipeline([
      Match([Trunk({
        $x: thing([person])
      })])
    ])
    """

    When get answers of typeql analyze query
      """
      match $x isa dummy;
      """
    Then analyzed query pipeline annotations are:
    """
    Pipeline([
      Match([Trunk({
        $x: thing([dummy, subdummy])
      })])
    ])
    """

    When get answers of typeql analyze query
      """
      match $x has $n;
      """
    Then analyzed query pipeline annotations are:
    """
    Pipeline([
      Match([Trunk({
        $n: thing([name,ref]),
        $x: thing([person])
      })])
    ])
    """

    When get answers of typeql analyze query
      """
      match $f links ($r: $p);
      """
    Then analyzed query pipeline annotations are:
    """
    Pipeline([
      Match([Trunk({
        $f: thing([friendship]),
        $p: thing([person]),
        $r: type([friendship:friend])
      })])
    ])
    """

    When get answers of typeql analyze query
      """
      match $x isa $t;
      """
    Then analyzed query pipeline annotations are:
    """
    Pipeline([
      Match([Trunk({
        $t: type([dummy, friendship, name, person, ref, subdummy]),
        $x: thing([dummy, friendship, name, person, ref, subdummy])
      })])
    ])
    """

    When get answers of typeql analyze query
      """
      match $s sub $t;
      """
    Then analyzed query pipeline annotations are:
    """
    Pipeline([
      Match([Trunk({
        $s: type([dummy, friendship, friendship:friend, name, person, ref, subdummy]),
        $t: type([dummy, friendship, friendship:friend, name, person, ref, subdummy])
      })])
    ])
    """

    When get answers of typeql analyze query
      """
      match $s sub! $t;
      """
    Then analyzed query pipeline annotations are:
    """
    Pipeline([
      Match([Trunk({
        $s: type([subdummy]),
        $t: type([dummy])
      })])
    ])
    """

    When get answers of typeql analyze query
      """
      match $o owns $a;
      """
    Then analyzed query pipeline annotations are:
    """
    Pipeline([
      Match([Trunk({
        $a: type([name, ref]),
        $o: type([person])
      })])
    ])
    """

    When get answers of typeql analyze query
      """
      match $rel relates $role;
      """
    Then analyzed query pipeline annotations are:
    """
    Pipeline([
      Match([Trunk({
        $rel: type([friendship]),
        $role: type([friendship:friend])
      })])
    ])
    """

    When get answers of typeql analyze query
      """
      match $p plays $role;
      """
    Then analyzed query pipeline annotations are:
    """
    Pipeline([
      Match([Trunk({
        $p: type([person]),
        $role: type([friendship:friend])
      })])
    ])
    """

  Scenario: Analyze returns the annotations of each subpattern in the query
    Given connection open read transaction for database: typedb
    When get answers of typeql analyze query
      """
      match
        $p isa person;
        { $x isa person; } or { $x isa subdummy; };
        not { $x has name $n; };
      """
    Then analyzed query pipeline annotations are:
    """
    Pipeline([
      Match([
        Trunk({
          $p: thing([person]),
          $x: thing([person, subdummy])
        }),
        Or([
          [Trunk({ $x: thing([person]) })],
          [Trunk({ $x: thing([subdummy]) })]
        ]),
        Not([Trunk({ $n: thing([name]), $x: thing([person]) })])
      ])
    ])
    """
