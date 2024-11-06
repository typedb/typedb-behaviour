# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: TypeQL Fetch Query

  Background: Open connection and create a simple extensible schema
    Given typedb starts
    Given connection opens with default authentication
    Given connection is open: true
    Given connection has 0 databases
    Given connection create database: typedb
    Given connection open schema transaction for database: typedb

    Given typeql schema query
      """
      define
      entity person
        plays friendship:friend,
        plays employment:employee,
        owns person-name @card(0..),
        owns age,
        owns karma,
        owns ref @key;
      entity company
        plays employment:employer,
        owns company-name,
        owns description,
        owns ref @key;
      relation friendship
        relates friend @card(0..),
        owns ref @key;
      relation employment
        relates employee,
        relates employer,
        owns ref @key,
        owns start-date,
        owns end-date;
      attribute name @abstract, value string;
      attribute person-name sub name;
      attribute company-name sub name;
      attribute description, value string;
      attribute age value long;
      attribute karma value double;
      attribute ref value long;
      attribute start-date value datetime;
      attribute end-date value datetime;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $p1 isa person, has person-name "Alice", has person-name "Allie", has age 10, has karma 123.4567891, has ref 0;
      $p2 isa person, has person-name "Bob", has ref 1;
      $c1 isa company, has company-name "TypeDB", has ref 2, has description "Nice and shy guys";
      $f1 links (friend: $p1, friend: $p2), isa friendship, has ref 3;
      $e1 links (employee: $p1, employer: $c1), isa employment, has ref 4, has start-date 2020-01-01T13:13:13.999, has end-date 2021-01-01;
      """
    Given transaction commits
    Given connection open read transaction for database: typedb


  Scenario: a type can be fetched
    When get answers of typeql read query
      """
      match
      $p label person;
      fetch {
        "entity type label": $p
      };
      """
    Then answer size is: 1
    Then answer contains document:
      """
      {
        "entity type label": "person"
      }
      """
    Then answer does not contain document:
      """
      {
        "p": "person"
      }
      """

    When get answers of typeql read query
      """
      match
      $f label friendship;
      fetch {
        "relation type label": $f
      };
      """
    Then answer size is: 1
    Then answer contains document:
      """
      {
        "relation type label": "friendship"
      }
      """

    When get answers of typeql read query
      """
      match
      $n label name;
      fetch {
        "attribute type label": $n
      };
      """
    Then answer size is: 1
    Then answer contains document:
      """
      {
        "attribute type label": "name"
      }
      """

    When get answers of typeql read query
      """
      match
      $f label friendship:friend;
      fetch {
        "role type label": $f
      };
      """
    Then answer size is: 1
    Then answer does not contain document:
      """
      {
        "role type label": "friend"
      }
      """
    Then answer contains document:
      """
      {
        "role type label": "friendship:friend"
      }
      """


  # TODO: Add tests for value types when value types match/fetch is implemented


  Scenario: an attribute and a value can be fetched
    When get answers of typeql read query
      """
      match
      $a isa person-name;
      fetch {
        "person": $a
      };
      """
    Then answer size is: 3
    Then answer contains document:
      """
      {
        "person": "Alice"
      }
      """
    Then answer contains document:
      """
      {
        "person": "Allie"
      }
      """
    Then answer contains document:
      """
      {
        "person": "Bob"
      }
      """

    When get answers of typeql read query
      """
      match
      $a isa name;
      $v = $a;
      fetch {
        "value": $v,
        "attribute": $a
      };
      """
    Then answer size is: 4
    Then answer contains document:
      """
      {
        "value": "Alice",
        "attribute": "Alice"
      }
      """
    Then answer contains document:
      """
      {
        "value": "Allie",
        "attribute": "Allie"
      }
      """
    Then answer contains document:
      """
      {
        "value": "Bob",
        "attribute": "Bob"
      }
      """
    Then answer contains document:
      """
      {
        "value": "TypeDB",
        "attribute": "TypeDB"
      }
      """
    Then answer does not contain document:
      """
      {
        "value": "value",
        "attribute": "value"
      }
      """
    Then answer does not contain document:
      """
      {
        "value": "Allie",
        "attribute": "Alice"
      }
      """


  Scenario: an attribute and a value can be fetched from an object as scalar values
    When get answers of typeql read query
      """
      match
      $p isa person;
      fetch {
        "person": $p.person-name
      };
      """
    Then answer size is: 2
    Then answer contains document:
      """
      {
        "person": "Bob"
      }
      """
    # It can actually be "Alice" or "Allie"
    Then answer does not contain document:
      """
      {
        "person": ["Alice", "Allie"]
      }
      """


  Scenario: an attribute and a value can be fetched from an object as lists
    When get answers of typeql read query
      """
      match
      $p isa person;
      fetch {
        "person": [ $p.person-name ]
      };
      """
    Then answer size is: 2
    Then answer contains document:
      """
      {
        "person": [ "Alice", "Allie" ]
      }
      """
    Then answer contains document:
      """
      {
        "person": [ "Bob" ]
      }
      """


  Scenario: fetch uses results of match stream operators
    When get answers of typeql read query
      """
      match
        $p isa person, has age 10;
      limit 1;
      fetch {
        "person": [ $p.person-name ],
      };
      """
    Then answer size is: 1
    Then answer contains document:
      """
      {
        "person": ["Alice", "Allie"]
      }
      """

    When get answers of typeql read query
      """
      match
        $p isa person, has ref $r;
      sort $r desc;
      limit 1;
      fetch {
        "name": $p.person-name
      };
      """
    Then answer size is: 1
    Then answer contains document:
      """
      {
        "name": "Bob"
      }
      """

    When get answers of typeql read query
      """
      match
        $p-type sub person;
        $p isa! $p-type, has $a;
      select $p;
      fetch {
        "person": [ $p.person-name ],
      };
      """
    Then answer size is: 7

  # TODO when the server is updated with the needed step to check errors: check message "The variable 'p' is not available"
    Then typeql read query; fails
      """
      match
        $p-type sub person;
        $p isa! $p-type, has $a;
      select $a;
      fetch {
        "person": [ $p.person-name ],
      };
      """


  Scenario: attributes that can never be owned by any matching type of a variable error
    # TODO when the server is updated with the needed step to check errors: check message "attribute 'company-name' cannot be"
    Then typeql read query; fails
      """
      match
        $p isa person, has person-name "Alice";
      fetch {
        "company name": $p.company-name
      };
      """


  Scenario: non-existing fetched attribute produces null
    When get answers of typeql read query
      """
      match
        $p isa person, has ref 1;
      fetch {
        "non-existing karma": $p.karma
      };
      """
    Then answer size is: 1
    Then answer contains document:
      """
      {
        "non-existing karma": null
      }
      """


  Scenario: all attributes of objects can be fetched with correct card representation
    When get answers of typeql read query
      """
      match
        $p has ref $_;
      fetch {
        $p.*
      };
      """
    Then answer size is: 5
    # TODO: ref should not be a list because of card. Same for age
    Then answer contains document:
      """
      {
        "person-name": [ "Alice", "Allie" ],
        "age": [ 10.0 ],
        "karma": [ 123.4567891 ],
        "ref": [ 0.0 ]
      }
      """
    # TODO: ref should not be a list because of card
    Then answer contains document:
      """
      {
        "person-name": [ "Bob" ],
        "ref": [ 1.0 ]
      }
      """
    # TODO: ref should not be a list because of card. Same for description
    Then answer contains document:
      """
      {
        "company-name": [ "TypeDB" ],
        "description": [ "Nice and shy guys" ],
        "ref": [ 2.0 ]
      }
      """
    # TODO: ref should not be a list because of card
    Then answer contains document:
      """
      {
        "ref": [ 3.0 ]
      }
      """
    # TODO: ref should not be a list because of card
    Then answer contains document:
      """
      {
        "start-date": [ "2020-01-01T13:13:13.999000000" ],
        "end-date": [ "2021-01-01T00:00:00.000000000" ],
        "ref": [ 4.0 ]
      }
      """

    When get answers of typeql read query
      """
      match
        $n isa nothing;
      fetch {
        $n.*
      };
      """
    Then answer size is: 1
    Then answer contains document:
      """
      { }
      """

    When get answers of typeql read query
      """
      match
        $n isa nothing;
      fetch {
        "nothing": { $n.* }
      };
      """
    Then answer size is: 1
    Then answer contains document:
      """
      {
        "nothing": { }
      }
      """


  Scenario Outline: attributes and values of <value-type> type can be fetched
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
      entity collection owns item;
      attribute item value <value-type>;
      """
    Given transaction commits
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
        $c isa collection, has item <value>;
      """
    Given transaction commits
    Given connection open read transaction for database: typedb

    When get answers of typeql read query
      """
      match
        $_ isa collection, has $a;
      fetch {
        "a": $a
      };
      """
    Then answer size is: 1
    Then answer contains document:
      """
      {
        "a": <expected>
      }
      """
    Then answer does not contain document:
      """
      {
        "a": <not-expected>
      }
      """

    When get answers of typeql read query
      """
      match
        $_ isa collection, has $a;
        $v = $a;
      fetch {
        "v": $v
      };
      """
    Then answer size is: 1
    Then answer contains document:
      """
      {
        "v": <expected>
      }
      """
    Then answer does not contain document:
      """
      {
        "v": <not-expected>
      }
      """
    Examples:
      | value-type  | value                                       | expected                                      | not-expected                                 |
      | boolean     | true                                        | true                                          | false                                        |
      | long        | 12345090                                    | 12345090                                      | 0                                            |
      | double      | 0.0000000001                                | 0.0000000001                                  | 0.000000001                                  |
      | double      | 2.01234567                                  | 2.01234567                                    | 2.01234568                                   |
      | decimal     | 1234567890.0001234567890                    | "1234567890.000123456789"                     | "1234567890.0001234567890"                   |
      | decimal     | 0.0000000000000000001                       | "0.0000000000000000001"                       | 0.000000000000000001                         |
      | string      | "outPUT"                                    | "outPUT"                                      | "output"                                     |
      | date        | 2024-09-20                                  | "2024-09-20"                                  | "2025-09-20"                                 |
      | datetime    | 1999-02-26T12:15:05                         | "1999-02-26T12:15:05.000000000"               | "1999-02-26T12:15:05"                        |
      | datetime    | 1999-02-26T12:15:05.000000001               | "1999-02-26T12:15:05.000000001"               | "1999-02-26T12:15:05.000000000"              |
      | datetime-tz | 2024-09-20T16:40:05.000000001 Europe/London | "2024-09-20T16:40:05.000000001 Europe/London" | "2024-09-20T16:40:05.000000001Europe/London" |
      | datetime-tz | 2024-09-20T16:40:05.000000001+0100          | "2024-09-20T16:40:05.000000001+01:00"         | "2024-09-20T16:40:05.000000001+0100"         |
      | duration    | P1Y10M7DT15H44M5.00394892S                  | "P1Y10M7DT15H44M5.003948920S"                 | "P1Y10M7DT15H44M5.00394892S"                 |
      | duration    | P66W                                        | "P462D"                                       | "P66W"                                       |
    # TODO: Test documents and structs


# TODO: Everything below is old!


  Scenario: a fetch subquery can be a match-fetch query
    When get answers of typeql read query
      """
      match
      $p isa person, has person-name $n; { $n == "Alice"; } or { $n == "Bob"; };
      fetch
      $p: person-name, age;
      "employers": {
        match
        links (employee: $p, employer: $c), isa employment;
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
                { "value": "TypeDB", "type": { "root": "attribute", "label": "company-name", "value_type": "string" } }
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
    When get answers of typeql read query
      """
      match
      $p isa person, has person-name $n; { $n == "Alice"; } or { $n == "Bob"; };
      fetch
      $p: person-name, age;
      employment-count: {
        match
        $r links (employee: $p, employer: $c), isa employment;
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
    When get answers of typeql read query
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
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      match
      $p2 isa person, has person-name "Bob";
      $c1 isa company, has name "TypeDB";
      insert
      links (employee: $p2, employer: $c1), isa employment, has ref 6;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
      $p isa person, has person-name "Alice";
      fetch
      $p: age;
      alice-employers: {
        match
        links (employee: $p, employer: $c), isa employment;
        fetch
        $c as company: name;
        alice-employment-rel: {
          match
          $r links (employee: $p, employer: $c), isa employment;
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
                { "value": "TypeDB", "type": { "root": "attribute", "label": "company-name", "value_type": "string" } }
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
    When get answers of typeql read query
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
    Given typeql write query
      """
      match
      $p isa person, has person-name "Alice";
      insert
      $p has person-name "Alicia";
      """
    Given transaction commits
    Given connection open read transaction for database: typedb
    When get answers of typeql read query
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
    When get answers of typeql read query
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
    When get answers of typeql read query
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
    When get answers of typeql read query
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
    When typeql read query; fails
      """
      match
      $p isa person, has person-name $n;
      fetch;
      """


  Scenario: a variable projection that can contain entities or relations throws
    When typeql read query; fails
      """
      match
      $x isa entity;
      fetch
      $x;
      """


  Scenario: an attribute projection with an invalid attribute type throws
    When typeql read query; fails
      """
      match
      $p isa person, has person-name $n; { $n == "Alice"; } or { $n == "Bob"; };
      fetch
      $p: type;
      sort $n;
      """
    Given connection open read transaction for database: typedb
    When typeql read query; fails
      """
      match
      $p isa person, has person-name $n; { $n == "Alice"; } or { $n == "Bob"; };
      fetch
      $p: person;
      sort $n;
      """


  Scenario: an attribute projection from a type throws
    When typeql read query; fails
      """
      match
      $p type person;
      fetch
      $p: name;
      """


  Scenario: fetching a variable that is not present in the match throws
    When typeql read query; fails
      """
      match
      $p isa person, has person-name $n;
      fetch
      $x: type;
      """


  Scenario: a subquery that is not connected to the match throws
    When typeql read query; fails
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
    When typeql read query; fails
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
    Given connection open read transaction for database: typedb
    When typeql read query; fails
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
    Given connection open read transaction for database: typedb
    When typeql read query; fails
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
    When typeql read query; fails
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
