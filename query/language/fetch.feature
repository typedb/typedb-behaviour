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
      entity nothing;
      entity person
        plays friendship:friend,
        plays employment:employee,
        owns name @card(0..),
        owns person-name @card(0..),
        owns age @card(0..1),
        owns karma @card(0..2),
        owns ref @key;
      entity company
        plays employment:employer,
        owns company-name @card(1..1),
        owns description @card(1..1000),
        owns achievement @card(0..1),
        owns company-achievement @card(0..),
        owns ref @key;
      relation friendship
        relates friend @card(0..),
        owns ref @key;
      relation employment
        relates employee,
        relates employer,
        owns ref @key,
        owns start-date @card(0..),
        owns end-date @card(0..);
      attribute name @abstract, value string;
      attribute person-name sub name;
      attribute company-name sub name;
      attribute description, value string;
      attribute age value long;
      attribute karma value double;
      attribute ref value long;
      attribute start-date value datetime;
      attribute end-date value datetime;
      attribute achievement @abstract;
      attribute company-achievement sub achievement, value string;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $n isa nothing;
      $p1 isa person, has person-name "Alice", has person-name "Allie", has age 10, has karma 123.4567891, has ref 0;
      $p2 isa person, has person-name "Bob", has ref 1;
      $c1 isa company, has company-name "TypeDB", has ref 2, has description "Nice and shy guys", has company-achievement "Green BDD tests for fetch";
      $f1 links (friend: $p1, friend: $p2), isa friendship, has ref 3;
      $e1 links (employee: $p1, employer: $c1), isa employment, has ref 4, has start-date 2020-01-01T13:13:13.999, has end-date 2021-01-01;
      """
    Given transaction commits
    Given connection open read transaction for database: typedb


  Scenario: a fetch with zero projections errors
    Then typeql read query; parsing fails
      """
      match
      $p isa person, has person-name $n;
      fetch;
      """


  Scenario: a fetch with a not available variable errors
# TODO when the server is updated with the needed step to check errors: check message "The variable 'p' is not available"
    Then typeql read query; fails
      """
      match
        entity $t;
      fetch {
        "name": $name,
      };
      """


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


# TODO: Not implemented
  Scenario: a variable projection of entities and relations is not acceptable
    # TODO: Check error message: "Fetching entities and relations is not supported"
    Then typeql read query; fails
      """
      match
      entity $t; $x isa $t;
      fetch {
        "entity": $x
      };
      """
    # TODO: Check error message: "Fetching entities and relations is not supported"
    Then typeql read query; fails
      """
      match
      relation $t; $x isa $t;
      fetch {
        "relation": $x
      };
      """


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


  Scenario: a scalar attribute can be fetched from an object as a scalar value with nulls
    When get answers of typeql read query
      """
      match
      $p isa person;
      fetch {
        "person's age": $p.age
      };
      """
    Then answer size is: 2
    Then answer contains document:
      """
      {
        "person's age": 10
      }
      """
    Then answer contains document:
      """
      {
        "person's age": null
      }
      """
    Then answer does not contain document:
      """
      {
        "person's age": [ 10 ]
      }
      """

    When get answers of typeql read query
      """
      match
      $c isa company;
      fetch {
        "company's achievement": $c.company-achievement
      };
      """
    Then answer size is: 1
    Then answer contains document:
      """
      {
        "company's achievement": "Green BDD tests for fetch"
      }
      """
    Then answer does not contain document:
      """
      {
        "company's achievement": [ "Green BDD tests for fetch" ]
      }
      """


  Scenario: a scalar attribute can be fetched from an object as a list
    When get answers of typeql read query
      """
      match
      $p isa person;
      fetch {
        "person's age": [ $p.age ]
      };
      """
    Then answer size is: 2
    Then answer contains document:
      """
      {
        "person's age": [ 10 ]
      }
      """
    Then answer contains document:
      """
      {
        "person's age": [ ]
      }
      """
    Then answer does not contain document:
      """
      {
        "person's age": 10
      }
      """

    When get answers of typeql read query
      """
      match
      $c isa company;
      fetch {
        "company's achievement": [ $c.company-achievement ]
      };
      """
    Then answer size is: 1
    Then answer contains document:
      """
      {
        "company's achievement": [ "Green BDD tests for fetch" ]
      }
      """
    Then answer does not contain document:
      """
      {
        "company's achievement": "Green BDD tests for fetch"
      }
      """


  Scenario: trying to fetch a scalar value from an object's attribute with non-scalar cardinality leads to error
    # TODO: Check error message: "this attribute can be owned more than 1 time"
    Then typeql read query; fails
      """
      match
        $p isa person;
      fetch {
        "non-existing karma": $p.person-name
      };
      """


  Scenario: a non-scalar object's attribute can be fetched from as a list
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
        "name": [ $p.person-name ]
      };
      """
    Then answer size is: 1
    Then answer contains document:
      """
      {
        "name": [ "Bob" ]
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


# TODO: Not implemented
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
    # TODO when the server is updated with the needed step to check errors: check message "is not an object type"
    Then typeql read query; fails
      """
      match
        attribute $t; $a isa $t;
      fetch {
        "company name": $a.company-name
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
        "non-existing karma": $p.age
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
    Then answer contains document:
      """
      {
        "person-name": [ "Alice", "Allie" ],
        "age": 10.0,
        "karma": [ 123.4567891 ],
        "ref": 0.0
      }
      """
    Then answer contains document:
      """
      {
        "person-name": [ "Bob" ],
        "ref": 1.0
      }
      """
    Then answer contains document:
      """
      {
        "company-name": "TypeDB",
        "description": [ "Nice and shy guys" ],
        "company-achievement": "Green BDD tests for fetch",
        "ref": 2.0
      }
      """
    Then answer contains document:
      """
      {
        "ref": 3.0
      }
      """
    Then answer contains document:
      """
      {
        "start-date": [ "2020-01-01T13:13:13.999000000" ],
        "end-date": [ "2021-01-01T00:00:00.000000000" ],
        "ref": 4.0
      }
      """

    Then typeql read query; parsing fails
      """
      match
        $p has ref $_;
      fetch {
        "all attributes": $p.*
      };
      """
    When connection open read transaction for database: typedb


    When get answers of typeql read query
      """
      match
        $p has ref $_;
      fetch {
        "all attributes": { $p.* }
      };
      """
    Then answer size is: 5
    Then answer contains document:
      """
      {
        "all attributes": {
          "person-name": [ "Alice", "Allie" ],
          "age": 10.0,
          "karma": [ 123.4567891 ],
          "ref": 0.0
        }
      }
      """
    Then answer contains document:
      """
      {
        "all attributes": {
          "person-name": [ "Bob" ],
          "ref": 1.0
        }
      }
      """
    Then answer contains document:
      """
      {
        "all attributes": {
          "company-name": "TypeDB",
          "description": [ "Nice and shy guys" ],
          "company-achievement": "Green BDD tests for fetch",
          "ref": 2.0
        }
      }
      """
    Then answer contains document:
      """
      {
        "all attributes": {
          "ref": 3.0
        }
      }
      """
    Then answer contains document:
      """
      {
        "all attributes": {
          "start-date": [ "2020-01-01T13:13:13.999000000" ],
          "end-date": [ "2021-01-01T00:00:00.000000000" ],
          "ref": 4.0
        }
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






  # ///// ....... Tests below are not fixed, but serve as a tip for future tests reimplementations



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
