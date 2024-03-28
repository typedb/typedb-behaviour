# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: TypeQL Fetch Query

  Background: Open connection and create a simple extensible schema
    Given typedb starts
    Given connection opens with default authentication
    Given connection has been opened
    Given connection does not have any database
    Given connection create database: typedb
    Given connection open schema session for database: typedb
    Given session opens transaction of type: write

    Given typeql define
      """
      define
      person sub entity,
        plays friendship:friend,
        plays employment:employee,
        owns person-name,
        owns age,
        owns karma,
        owns ref @key;
      company sub entity,
        plays employment:employer,
        owns company-name,
        owns ref @key;
      friendship sub relation,
        relates friend,
        owns ref @key;
      employment sub relation,
        relates employee,
        relates employer,
        owns ref @key,
        owns start-date,
        owns end-date;
      name sub attribute, abstract, value string;
      person-name sub name;
      company-name sub name;
      age sub attribute, value long;
      karma sub attribute, value double;
      ref sub attribute, value long;
      start-date sub attribute, value datetime;
      end-date sub attribute, value datetime;
      """
    Given transaction commits

    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $p1 isa person, has person-name "Alice", has person-name "Allie", has age 10, has karma 123.4567891, has ref 0;
      $p2 isa person, has person-name "Bob", has ref 1;
      $c1 isa company, has company-name "Vaticle", has ref 2;
      $f1 (friend: $p1, friend: $p2) isa friendship, has ref 3;
      $e1 (employee: $p1, employer: $c1) isa employment, has ref 4, has start-date 2020-01-01T13:13:13.999, has end-date 2021-01-01;
      """
    Given transaction commits

    Given session opens transaction of type: read


  Scenario: a type can be fetched
    When get answers of typeql fetch
      """
      match
      $p type person;
      fetch
      $p;
      """
    Then fetch answers are
      """
      [{
        "p": { "root": "entity", "label": "person" }
      }]
      """
    When get answers of typeql fetch
      """
      match
      $p type friendship:friend;
      fetch
      $p;
      """
    Then fetch answers are
      """
      [{
        "p": { "root": "relation:role", "label": "friendship:friend" }
      }]
      """


  Scenario: a fetched attribute type contains its value type
    When get answers of typeql fetch
      """
      match
      $n type name;
      fetch
      $n;
      """
    Then fetch answers are
      """
      [{
        "n": { "root": "attribute", "label": "name", "value_type": "string" }
      }]
      """


  # TODO: remove this scenario when we finish deprecating 'thing' type
  Scenario: root thing type can be fetched
    When get answers of typeql fetch
      """
      match
      $p type thing;
      fetch
      $p;
      """
    Then fetch answers are
      """
      [{
        "p": { "root": "thing", "label": "thing" }
      }]
      """


  Scenario: an attribute can be fetched
    When get answers of typeql fetch
      """
      match
      $a isa name;
      fetch
      $a;
      sort $a;
      """
    Then fetch answers are
      """
      [{
        "a": { "value":"Alice", "type": { "root": "attribute", "label": "person-name", "value_type": "string" } }
      },
      {
        "a": { "value":"Allie", "type": { "root": "attribute", "label": "person-name", "value_type": "string" } }
      },
      {
        "a": { "value":"Bob", "type": { "root": "attribute", "label": "person-name", "value_type": "string" } }
      },
      {
        "a": { "value":"Vaticle", "type": { "root": "attribute", "label": "company-name", "value_type": "string" } }
      }]
      """
    When get answers of typeql fetch
      """
      match
      $a isa $t; $t value datetime;
      fetch
      $a;
      sort $a;
      """
    Then fetch answers are
      """
      [{
        "a": { "value": "2020-01-01T13:13:13.999", "type": { "root": "attribute", "label": "start-date", "value_type": "datetime" } }
      },
      {
        "a": { "value": "2021-01-01T00:00:00.000", "type": { "root": "attribute", "label": "end-date", "value_type": "datetime" } }
      }]
      """


  Scenario: a value can be fetched
    When get answers of typeql fetch
      """
      match
      $a isa name;
      ?v = $a;
      fetch
      ?v;
      sort $a;
      """
    Then fetch answers are
      """
      [{
        "v": { "value":"Alice", "value_type": "string" }
      },
      {
        "v": { "value":"Allie", "value_type": "string" }
      },
      {
        "v": { "value":"Bob", "value_type": "string" }
      },
      {
        "v": { "value":"Vaticle", "value_type": "string" }
      }]
      """


  Scenario: a concept's attributes can be fetched
    When get answers of typeql fetch
      """
      match
      $p isa person, has person-name $n; { $n == "Alice"; } or  { $n == "Bob"; };
      fetch
      $p: person-name, age;
      sort $n;
      """
    Then fetch answers are
      """
      [{
        "p": {
          "type": { "root": "entity", "label": "person" },
          "person-name": [
            { "value":"Alice", "type": { "root": "attribute", "label": "person-name", "value_type": "string" } },
            { "value":"Allie", "type": { "root": "attribute", "label": "person-name", "value_type": "string" } }
          ],
          "age": [
            { "value": 10, "type": { "root": "attribute", "label": "age", "value_type": "long" } }
          ]
        }
      },
      {
        "p": {
          "type": { "root": "entity", "label": "person" },
          "person-name": [
            { "value":"Bob", "type": { "root": "attribute", "label": "person-name", "value_type": "string" } }
          ],
          "age": []
        }
      }]
      """


  Scenario: a concept's attributes can be fetched using more general types than the concept type owns
    When get answers of typeql fetch
      """
      match
      $p isa person, has person-name "Alice";
      fetch
      $p: attribute;
      """
    Then fetch answers are
      """
      [{
        "p": {
          "type": { "root": "entity", "label": "person" },
          "attribute": [
            { "value": "Alice", "type": { "root": "attribute", "label": "person-name", "value_type": "string" } },
            { "value": "Allie", "type": { "root": "attribute", "label": "person-name", "value_type": "string" } },
            { "value": 10, "type": { "root": "attribute", "label": "age", "value_type": "long" } },
            { "value": 123.4567891, "type": { "root": "attribute", "label": "karma", "value_type": "double" } },
            { "value": 0, "type": { "root": "attribute", "label": "ref", "value_type": "long" } }
          ]
        }
      }]
      """


  Scenario: attribute ownership fetch can trigger inferred ownerships
    Given connection close all sessions
    Given connection open schema session for database: typedb
    Given session opens transaction of type: write
    Given typeql define
      """
      define
      rule alice-as-alicia:
      when {
        $p isa person, has person-name "Alice";
      } then {
        $p has person-name "Alicia";
      };
      """
    Given transaction commits
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: read
    When get answers of typeql fetch
      """
      match
      $p isa person, has age 10;
      fetch
      $p: person-name;
      """
    Then fetch answers are
      """
      [{
        "p": {
          "type": { "root": "entity", "label": "person" },
          "person-name": [
            { "value":"Alice", "type": { "root": "attribute", "label": "person-name", "value_type": "string" } },
            { "value":"Allie", "type": { "root": "attribute", "label": "person-name", "value_type": "string" } },
            { "value":"Alicia", "type": { "root": "attribute", "label": "person-name", "value_type": "string" } }
          ]
        }
      }]
      """
    When get answers of typeql fetch
      """
      match
      $p isa person, has age 10;
      fetch
      $p: attribute;
      """
    Then fetch answers are
      """
      [{
        "p": {
          "type": { "root": "entity", "label": "person" },
          "attribute": [
            { "value":10, "type": { "root": "attribute", "label": "age", "value_type": "long" } },
            { "value": 123.4567891, "type": { "root": "attribute", "label": "karma", "value_type": "double" } },
            { "value":0, "type": { "root": "attribute", "label": "ref", "value_type": "long" } },
            { "value":"Alice", "type": { "root": "attribute", "label": "person-name", "value_type": "string" } },
            { "value":"Allie", "type": { "root": "attribute", "label": "person-name", "value_type": "string" } },
            { "value":"Alicia", "type": { "root": "attribute", "label": "person-name", "value_type": "string" } }
          ]
        }
      }]
      """

  Scenario: match limits do not affect attribute ownership fetch
    Given connection close all sessions
    Given connection open schema session for database: typedb
    Given session opens transaction of type: write
    Given typeql define
      """
      define
      rule alice-as-alicia:
      when {
        $p isa person, has person-name "Alice";
      } then {
        $p has person-name "Alicia";
      };
      """
    Given transaction commits
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: read
    When get answers of typeql fetch
      """
      match
      $p isa person, has age 10;
      fetch
      $p: person-name;
      limit 1;
      """
    Then fetch answers are
      """
      [{
        "p": {
          "type": { "root": "entity", "label": "person" },
          "person-name": [
            { "value":"Alice", "type": { "root": "attribute", "label": "person-name", "value_type": "string" } },
            { "value":"Allie", "type": { "root": "attribute", "label": "person-name", "value_type": "string" } },
            { "value":"Alicia", "type": { "root": "attribute", "label": "person-name", "value_type": "string" } }
          ]
        }
      }]
      """


  Scenario: attributes that can never be owned by any matching type of a variable throw exceptions
    When typeql fetch; throws exception
      """
      match
      $p isa person, has person-name "Alice";
      fetch
      $p: company-name;
      """


  Scenario: a fetch subquery can be a match-fetch query
    When get answers of typeql fetch
      """
      match
      $p isa person, has person-name $n; { $n == "Alice"; } or { $n == "Bob"; };
      fetch
      $p: person-name, age;
      "employers": {
        match
        (employee: $p, employer: $c) isa employment;
        fetch
        $c: name;
      };
      sort $n;
      """
    Then fetch answers are
      """
      [{
        "p": {
          "type": { "root": "entity", "label": "person" },
          "person-name": [
            { "value":"Alice", "type": { "root": "attribute", "label": "person-name", "value_type": "string" } },
            { "value":"Allie", "type": { "root": "attribute", "label": "person-name", "value_type": "string" } }
          ],
          "age": [
            { "value": 10, "type": { "root": "attribute", "label": "age", "value_type": "long" } }
          ]
        },
        "employers": [
          {
            "c": {
              "type": { "root": "entity", "label": "company" },
              "name": [
                { "value": "Vaticle", "type": { "root": "attribute", "label": "company-name", "value_type": "string" } }
              ]
            }
          }
        ]
      },
      {
        "p": {
          "type": { "root": "entity", "label": "person" },
          "person-name": [
            { "value":"Bob", "type": { "root": "attribute", "label": "person-name", "value_type": "string" } }
          ],
          "age": [ ]
        },
        "employers": [ ]
      }]
      """


  Scenario: a fetch subquery can be a match-aggregate query
    When get answers of typeql fetch
      """
      match
      $p isa person, has person-name $n; { $n == "Alice"; } or { $n == "Bob"; };
      fetch
      $p: person-name, age;
      employment-count: {
        match
        $r (employee: $p, employer: $c) isa employment;
        get $r;
        count;
      };
      sort $n;
      """
    Then fetch answers are
      """
      [{
        "p": {
          "type": { "root": "entity", "label": "person" },
          "person-name": [
            { "value":"Alice", "type": { "root": "attribute", "label": "person-name", "value_type": "string" } },
            { "value":"Allie", "type": { "root": "attribute", "label": "person-name", "value_type": "string" } }
          ],
          "age": [
            { "value": 10, "type": { "root": "attribute", "label": "age", "value_type": "long" } }
          ]
        },
        "employment-count": { "value": 1, "value_type": "long" }
      },
      {
        "p": {
         "type": { "root": "entity", "label": "person" },
         "person-name": [
            { "value":"Bob", "type": { "root": "attribute", "label": "person-name", "value_type": "string" } }
         ],
         "age": []
       },
       "employment-count": { "value": 0, "value_type": "long" }
      }]
      """


  Scenario: a fetch subquery can be a match-aggregate query with zero answers
    When get answers of typeql fetch
      """
      match
      $p isa person, has person-name "Bob";
      fetch
      ages-sum: {
        match
        $p has age $a;
        get $a;
        sum $a;
      };
      limit 1;
      """
    Then fetch answers are
      """
      [{
        "ages-sum": null
      }]
      """


  Scenario: fetch subqueries can be nested and use bindings from any parent
    Given session transaction closes
    Given session opens transaction of type: write
    Given typeql insert
      """
      match
      $p2 isa person, has person-name "Bob";
      $c1 isa company, has name "Vaticle";
      insert
      (employee: $p2, employer: $c1) isa employment, has ref 6;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql fetch
      """
      match
      $p isa person, has person-name "Alice";
      fetch
      $p: age;
      alice-employers: {
        match
        (employee: $p, employer: $c) isa employment;
        fetch
        $c as company: name;
        alice-employment-rel: {
          match
          $r (employee: $p, employer: $c) isa employment;
          fetch
          $r: ref;
        };
      };
      """
    Then fetch answers are
      """
      [{
        "p": {
          "type": { "root": "entity", "label": "person" },
          "age": [
            { "value": 10, "type": { "root": "attribute", "label": "age", "value_type": "long" } }
          ]
        },
        "alice-employers": [
          {
            "company": {
              "type": { "root": "entity", "label": "company" },
              "name": [
                { "value": "Vaticle", "type": { "root": "attribute", "label": "company-name", "value_type": "string" } }
              ]
            },
            "alice-employment-rel": [
              {
                "r": {
                  "ref": [
                    { "value": 4, "type": { "root": "attribute", "label": "ref", "value_type": "long" } }
                  ],
                  "type": { "root": "relation", "label": "employment" }
                }
              }
            ]
          }
        ]
      }]
      """


  Scenario: a fetch subquery is not affected by match-fetch query limits
    When get answers of typeql fetch
      """
      match
      $p isa person, has age 10;
      fetch
      $p: age;
      "names": {
        match
        $p has person-name $pn;
        fetch
        $pn as "person name";
      };
      limit 1;
      """
    Then fetch answers are
      """
      [{
        "p": {
          "type": { "root": "entity", "label": "person" },
          "age": [
            { "value": 10, "type": { "root": "attribute", "label": "age", "value_type": "long" } }
          ]
        },
        "names": [
          {
            "person name": {
              "type": { "root": "attribute", "label": "person-name", "value_type": "string" },
              "value": "Alice"
            }
          },
          {
            "person name": {
              "type": { "root": "attribute", "label": "person-name", "value_type": "string" },
              "value": "Allie"
            }
          }
        ]
      }]
      """


  Scenario: fetch subqueries can trigger reasoning
    Given connection close all sessions
    Given connection open schema session for database: typedb
    Given session opens transaction of type: write
    Given typeql define
      """
      define
      rule alice-as-alicia:
      when {
        $p isa person, has person-name "Alice";
      } then {
        $p has person-name "Alicia";
      };
      """
    Given transaction commits
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: read
    When get answers of typeql fetch
      """
      match
      $p isa person, has age 10;
      fetch
      $p: age;
      "names": {
        match
        $p has person-name $pn;
        fetch
        $pn as "person name";
      };
      limit 1;
      """
    Then fetch answers are
      """
      [{
        "p": {
          "type": { "root": "entity", "label": "person" },
          "age": [
            { "value": 10, "type": { "root": "attribute", "label": "age", "value_type": "long" } }
          ]
        },
        "names": [
          {
            "person name": {
              "type": { "root": "attribute", "label": "person-name", "value_type": "string" },
              "value": "Alice"
            }
          },
          {
            "person name": {
              "type": { "root": "attribute", "label": "person-name", "value_type": "string" },
              "value": "Allie"
            }
          },
          {
            "person name": {
              "type": { "root": "attribute", "label": "person-name", "value_type": "string" },
              "value": "Alicia"
            }
          }
        ]
      }]
      """


  Scenario: a projection can be relabeled
    When get answers of typeql fetch
      """
      match
      $p type person;
      fetch
      $p as person;
      """
    Then fetch answers are
      """
      [{
        "person": { "root": "entity", "label": "person" }
      }]
      """


  Scenario: labels can have spaces
    When get answers of typeql fetch
      """
      match
      $p isa person, has person-name "Alice";
      fetch
      $p as "person Alice": age as "her age";
      """
    Then fetch answers are
      """
      [{
        "person Alice": {
          "type": { "root": "entity", "label": "person" },
          "her age": [
            { "value": 10, "type": { "root": "attribute", "label": "age", "value_type": "long" } }
          ]
        }
      }]
      """


  Scenario: an attribute projection can be relabeled
    When get answers of typeql fetch
      """
      match
      $p isa person, has person-name $n; { $n == "Alice"; } or { $n == "Bob"; };
      fetch
      $p: person-name as name, age;
      sort $n;
      """
    Then fetch answers are
      """
      [{
        "p": {
          "type": { "root": "entity", "label": "person" },
          "name": [
            { "value": "Alice", "type": { "root": "attribute", "label": "person-name", "value_type": "string" } },
            { "value": "Allie", "type": { "root": "attribute", "label": "person-name", "value_type": "string" } }
          ],
          "age": [
            { "value": 10, "type": { "root": "attribute", "label": "age", "value_type": "long" } }
          ]
        }
      },
      {
        "p": {
          "type": { "root": "entity", "label": "person" },
          "name": [
            { "value": "Bob", "type": { "root": "attribute", "label": "person-name", "value_type": "string" } }
          ],
          "age": [ ]
        }
      }]
      """


  Scenario: a fetch with zero projections throws
    When typeql fetch; throws exception
      """
      match
      $p isa person, has person-name $n;
      fetch;
      """


  Scenario: a variable projection that can contain entities or relations throws
    When typeql fetch; throws exception
      """
      match
      $x isa entity;
      fetch
      $x;
      """


  Scenario: an attribute projection with an invalid attribute type throws
    When typeql fetch; throws exception
      """
      match
      $p isa person, has person-name $n; { $n == "Alice"; } or { $n == "Bob"; };
      fetch
      $p: type;
      sort $n;
      """
    Given session opens transaction of type: read
    When typeql fetch; throws exception
      """
      match
      $p isa person, has person-name $n; { $n == "Alice"; } or { $n == "Bob"; };
      fetch
      $p: person;
      sort $n;
      """


  Scenario: an attribute projection from a type throws
    When typeql fetch; throws exception
      """
      match
      $p type person;
      fetch
      $p: name;
      """


  Scenario: fetching a variable that is not present in the match throws
    When typeql fetch; throws exception
      """
      match
      $p isa person, has person-name $n;
      fetch
      $x: type;
      """


  Scenario: a subquery that is not connected to the match throws
    When typeql fetch; throws exception
      """
      match
      $p isa person, has person-name $n;
      fetch
      all-employments-count: {
        match
        $r isa employment;
        get $r;
        count;
      };
      """


  Scenario: a fetch subquery cannot be an insert, match-get, match-group, or match-group-aggregate
    When typeql fetch; throws exception
    """
      match
      $p isa person, has person-name $n; { $n == "Alice"; } or { $n == "Bob"; };
      fetch
      $p: person-name, age;
      inserted: {
        insert $p has age 20;
      };
      sort $n;
      """
    Given session opens transaction of type: read
    When typeql fetch; throws exception
      """
      match
      $p isa person, has person-name $n; { $n == "Alice"; } or { $n == "Bob"; };
      fetch
      $p: person-name, age;
      ages: {
        match
        $p has age $n;
        get $n;
      };
      sort $n;
      """
    Given session opens transaction of type: read
    When typeql fetch; throws exception
      """
      match
      $p isa person, has person-name $n; { $n == "Alice"; } or { $n == "Bob"; };
      fetch
      $p: person-name, age;
      groups: {
        match
        $p has age $a;
        get $p, $n;
        group $p;
      };
      sort $n;
      """
    Given session opens transaction of type: read
    When typeql fetch; throws exception
      """
      match
      $p isa person, has person-name $n; { $n == "Alice"; } or { $n == "Bob"; };
      fetch
      $p: person-name, age;
      group-counts: {
        match
        $p has age $n;
        get $a, $n;
        group $n;
        count;
      };
      sort $n;
      """
