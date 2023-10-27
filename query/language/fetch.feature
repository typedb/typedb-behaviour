#
# Copyright (C) 2022 Vaticle
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#

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
        owns ref @key;
      name sub attribute, abstract, value string;
      person-name sub name;
      company-name sub name;
      age sub attribute, value long;
      ref sub attribute, value long;
      """
    Given transaction commits

    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $p1 isa person, has person-name "Alice", has person-name "Allie", has age 10, has ref 0;
      $p2 isa person, has person-name "Bob", has ref 1;
      $c1 isa company, has company-name "Vaticle", has ref 2;
      $f1 (friend: $p1, friend: $p2) isa friendship, has ref 3;
      $e1 (employee: $p1, employer: $c1) isa employment, has ref 4;
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
        "a": { "value":"Alice", "value_type": "string", "type": { "root": "attribute", "label": "person-name" } }
      },
      {
        "a": { "value":"Allie", "value_type": "string", "type": { "root": "attribute", "label": "person-name" } }
      },
      {
        "a": { "value":"Bob", "value_type": "string", "type": { "root": "attribute", "label": "person-name" } }
      },
      {
        "a": { "value":"Vaticle", "value_type": "string", "type": { "root": "attribute", "label": "company-name" } }
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
            { "value":"Alice", "value_type": "string", "type": { "root": "attribute", "label": "person-name" } },
            { "value":"Allie", "value_type": "string", "type": { "root": "attribute", "label": "person-name" } }
          ],
          "age": [
            { "value": 10, "value_type": "long", "type": { "root": "attribute", "label": "age" } }
          ]
        }
      },
      {
        "p": {
          "type": { "root": "entity", "label": "person" },
          "person-name": [
            { "value":"Bob", "value_type": "string", "type": { "root": "attribute", "label": "person-name" } }
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
            { "value": "Alice", "value_type": "string", "type": { "root": "attribute", "label": "person-name" } },
            { "value": "Allie", "value_type": "string", "type": { "root": "attribute", "label": "person-name" } },
            { "value": 10, "value_type": "long", "type": { "root": "attribute", "label": "age" } },
            { "value": 0, "value_type": "long", "type": { "root": "attribute", "label": "ref" } }
          ]
        }
      }]
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
            { "value":"Alice", "value_type": "string", "type": { "root": "attribute", "label": "person-name" } },
            { "value":"Allie", "value_type": "string", "type": { "root": "attribute", "label": "person-name" } }
          ],
          "age": [
            { "value": 10, "value_type": "long", "type": { "root": "attribute", "label": "age" } }
          ]
        },
        "employers": [
          {
            "c": {
              "type": { "root": "entity", "label": "company" },
              "name": [
                { "value": "Vaticle", "value_type": "string", "type": { "root": "attribute", "label": "company-name" } }
              ]
            }
          }
        ]
      },
      {
        "p": {
          "type": { "root": "entity", "label": "person" },
          "person-name": [
            { "value":"Bob", "value_type": "string", "type": { "root": "attribute", "label": "person-name" } }
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
            { "value":"Alice", "value_type": "string", "type": { "root": "attribute", "label": "person-name" } },
            { "value":"Allie", "value_type": "string", "type": { "root": "attribute", "label": "person-name" } }
          ],
          "age": [
            { "value": 10, "value_type": "long", "type": { "root": "attribute", "label": "age" } }
          ]
        },
        "employment-count": { "value":1 }
      },
      {
        "p": {
         "type": { "root": "entity", "label": "person" },
         "person-name": [
            { "value":"Bob", "value_type": "string", "type": { "root": "attribute", "label": "person-name" } }
         ],
         "age": [ ]
       },
       "employment-count": { "value":0 }
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
            { "value": 10, "value_type": "long", "type": { "root": "attribute", "label": "age" } }
          ]
        },
        "alice-employers": [
          {
            "company": {
              "type": { "root": "entity", "label": "company" },
              "name": [
                { "value": "Vaticle", "value_type": "string", "type": { "root": "attribute", "label": "company-name" } }
              ]
            },
            "alice-employment-rel": [
              {
                "r": {
                  "ref": [
                    { "value": 4, "value_type": "long", "type": { "root": "attribute", "label": "ref" } }
                  ]
                }
              }
            ]
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
            { "value": 10, "value_type": "long", "type": { "root": "attribute", "label": "age" } }
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
            { "value": "Alice", "value_type": "string", "type": { "root": "attribute", "label": "person-name" } },
            { "value": "Allie", "value_type": "string", "type": { "root": "attribute", "label": "person-name" } }
          ],
          "age": [
            { "value": 10, "value_type": "long", "type": { "root": "attribute", "label": "age" } }
          ]
        }
      },
      {
        "p": {
          "type": { "root": "entity", "label": "person" },
          "name": [
            { "value": "Bob", "value_type": "string", "type": { "root": "attribute", "label": "person-name" } }
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