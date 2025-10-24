# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: Analyzed query annotations

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
    When get answers of typeql analyze
      """
      match $x isa person;
      """
    Then analyzed query pipeline annotations are:
    """
    Pipeline([
      Match(
        And({ $x: thing([person]) }, [])
      )
    ])
    """

    When get answers of typeql analyze
      """
      match $x isa dummy;
      """
    Then analyzed query pipeline annotations are:
    """
    Pipeline([
      Match(
        And({ $x: thing([dummy, subdummy]) }, [])
      )
    ])
    """

    When get answers of typeql analyze
      """
      match $x has $n;
      """
    Then analyzed query pipeline annotations are:
    """
    Pipeline([
      Match(And({
        $n: thing([name,ref]),
        $x: thing([person])
      }, []))
    ])
    """

    When get answers of typeql analyze
      """
      match $f links ($r: $p);
      """
    Then analyzed query pipeline annotations are:
    """
    Pipeline([
      Match(
        And({
          $f: thing([friendship]),
          $p: thing([person]),
          $r: type([friendship:friend])
        }, [])
      )
    ])
    """

    When get answers of typeql analyze
      """
      match $x isa $t;
      """
    Then analyzed query pipeline annotations are:
    """
    Pipeline([
      Match(And({
        $t: type([dummy, friendship, name, person, ref, subdummy]),
        $x: thing([dummy, friendship, name, person, ref, subdummy])
      }, []))
    ])
    """

    When get answers of typeql analyze
      """
      match $s sub $t;
      """
    Then analyzed query pipeline annotations are:
    """
    Pipeline([
      Match(And({
        $s: type([dummy, friendship, friendship:friend, name, person, ref, subdummy]),
        $t: type([dummy, friendship, friendship:friend, name, person, ref, subdummy])
      }, []))
    ])
    """

    When get answers of typeql analyze
      """
      match $s sub! $t;
      """
    Then analyzed query pipeline annotations are:
    """
    Pipeline([
      Match(And({
        $s: type([subdummy]),
        $t: type([dummy])
      }, []))
    ])
    """

    When get answers of typeql analyze
      """
      match $o owns $a;
      """
    Then analyzed query pipeline annotations are:
    """
    Pipeline([
      Match(
        And({ $a: type([name, ref]), $o: type([person]) }, [])
      )
    ])
    """

    When get answers of typeql analyze
      """
      match $rel relates $role;
      """
    Then analyzed query pipeline annotations are:
    """
    Pipeline([
      Match(
        And({ $rel: type([friendship]), $role: type([friendship:friend]) }, [])
      )
    ])
    """

    When get answers of typeql analyze
      """
      match $p plays $role;
      """
    Then analyzed query pipeline annotations are:
    """
    Pipeline([
      Match(And({
        $p: type([person]),
        $role: type([friendship:friend])
      }, []))
    ])
    """

    When get answers of typeql analyze
      """
      match
        let $x = 1;
        let $y = "why";
      """
    Then analyzed query pipeline annotations are:
    """
    Pipeline([
      Match(And({
        $x: value([integer]),
        $y: value([string])
      }, []))
    ])
    """


  Scenario: Analyze returns the annotations of each subpattern in the query
    Given connection open read transaction for database: typedb
    When get answers of typeql analyze
      """
      match
        $p isa person;
        { $x isa person; } or { $x isa subdummy; };
        not { $x has name $n; };
      """
    Then analyzed query pipeline annotations are:
    """
    Pipeline([
      Match(
        And(
          { $p: thing([person]), $x: thing([person, subdummy]) },
          [
            Or([
              And({ $x: thing([person]) }, []),
              And({ $x: thing([subdummy]) }, [])
            ]),
            Not(And({ $n: thing([name]), $x: thing([person]) }, []))
          ]
        )
      )
    ])
    """


  Scenario: Analyze returns the annotations of every stage in the query
    Given connection open read transaction for database: typedb
    When get answers of typeql analyze
      """
      match
        $x isa person, has name $n, has ref $r;
        { $r == 2; } or { $r == 3; };
      select $n, $x;
      delete $n;
      insert $x has name "John";
      match $n1 isa name == "J";
      put $x has name $n1;
      """
    Then analyzed query pipeline annotations are:
    """
    Pipeline([
      Match(
        And(
          { $n: thing([name]), $r: thing([ref]), $x: thing([person]) },
          [
            Or([
              And({ $r: thing([ref]) }, []),
              And({ $r: thing([ref]) }, [])
            ])
          ]
        )
      ),
      Select(),
      Delete(And({ $n: thing([name]), $x: thing([person]) }, [])),
      Insert(And({ $_: thing([name]), $x: thing([person]) }, [])),
      Match(And({ $n1:thing([name]), $x: thing([person]) }, [])),
      Put(And({ $n1:thing([name]), $x: thing([person]) }, []))
    ])
    """


  Scenario: Analyze returns the annotations of functions in the preamble
    Given connection open read transaction for database: typedb
    When get answers of typeql analyze
      """
      with
      fun names_of($p: person) -> { name }:
      match $p has name $n;
      return { $n };

      match
        $p isa person;
        let $n in names_of($p);
      """

    Then analyzed preamble annotations contains:
      """
      Function(
        [thing([person])],
        stream([thing([name])]),
        Pipeline([
          Match(
            And({ $n: thing([name]), $p: thing([person]) }, [])
          )
        ])
      )
      """

    Then analyzed query pipeline annotations are:
      """
      Pipeline([
        Match(
          And({ $n: thing([name]), $p: thing([person]) }, [])
        )
      ])
      """


  Scenario: Analyze returns the annotations of fetch
    # Basic concept
    Given connection open read transaction for database: typedb
    When get answers of typeql analyze
      """
      match $n isa name;
      fetch { "names": $n };
      """
    Then analyzed fetch annotations are:
    """
    { names: [string] }
    """

    # Basic value
    When get answers of typeql analyze
      """
      match let $x = 5;
      fetch { "x": $x };
      """
    Then analyzed fetch annotations are:
    """
    { x: [integer] }
    """

    # Wildcard
    When get answers of typeql analyze
      """
      match $x isa person;
      fetch {
        $x.*
      };
      """
    Then analyzed fetch annotations are:
    """
    {
        name: [string],
        ref: [integer]
    }
    """

    # Subquery returning list
    When get answers of typeql analyze
      """
      match 1==1;
      fetch {
        "names" : [ match $n isa name; return { $n }; ]
      };
      """
    Then analyzed fetch annotations are:
    """
    { names: List([string]) }
    """

    # Subquery returning single
    When get answers of typeql analyze
      """
      match 1==1;
      fetch {
        "names" : (match $n isa name; return first $n; )
      };
      """
    Then analyzed fetch annotations are:
    """
    { names: [string] }
    """

    # Function returning list
    When get answers of typeql analyze
      """
      with
      fun names() -> { name }:
      match $n isa name;
      return { $n };

      match 1==1;
      fetch {
        "names": [names()]
      };
      """
    Then analyzed fetch annotations are:
    """
    { names: List([string]) }
    """

    # Function returning single
    When get answers of typeql analyze
      """
      with
      fun one_name() -> name:
      match $n isa name;
      return first $n;

      match 1==1;
      fetch {
        "names" : one_name()
      };
      """
    Then analyzed fetch annotations are:
    """
    { names: [string] }
    """

    # Nested single
    When get answers of typeql analyze
      """
      match $n isa name;
      fetch {
        "nested": {
          "name": $n
        }
      };
      """
    Then analyzed fetch annotations are:
    """
    {
      nested: {
        name: [string]
      }
    }
    """

    # Nested list
    When get answers of typeql analyze
      """
      match 1 == 1;
      fetch {
        "nested": {
          "names": [ match $n isa name; return { $n }; ]
        }
      };
      """
    Then analyzed fetch annotations are:
    """
    {
      nested: {
        names: List([string])
      }
    }
    """

    # Nested fetch
    When get answers of typeql analyze
    """
      match
        $p isa person, has ref $r;
      fetch {
        "ref": $r,
        "friends": [
          match
            $_ isa friendship, links (friend: $p, friend: $f);
            $f has name $nf;
          fetch {
            "name": $nf
          };
        ]
      };
    """
    Then analyzed fetch annotations are:
    """
      {
        friends: List({
          name: [string]
        }),
        ref: [integer]
      }
    """
