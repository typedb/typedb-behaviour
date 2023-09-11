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
      $p2 isa person, has person-name "Bob", ref 1;
      $c1 isa company, has company-name "Vaticle", has ref 2
      $f1 (friend: $p1, friend: $p2) isa friendship, has ref 3;
      $e1 (employee: $p1, employer: $c1) isa employment, has ref 4;
      """
    Given transaction commits

    Given session opens transaction of type: read


  Feature: a type can be fetched
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
        p: { label: 'person' }
      }]
      """


  Feature: an attribute can be fetched
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
        a: { type: 'person-name', value: 'Alice' }
      },
      {
        a: { type: 'person-name', value: 'Allie' }
      },
      {
        a: { type: 'person-name', value: 'Bob' }
      },
      {
        a: { type: 'company-name', value: 'Vaticle' }
      }]
      """


  Feature: a value can be fetched
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
        v: { value: 'Alice' }
      },
      {
        v: { value: 'Allie' }
      },
      {
        v: { value: 'Bob' }
      },
      {
        v: { value: 'Vaticle' }
      }]
      """


  Feature: a concept's attributes can be fetched
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
        p: {
          type: 'person',
          person-name: [
            { type: 'person-name', value: 'Alice' },
            { type: 'person-name', value: 'Allie' }
          ],
          age: [
            { type: 'age', value: 10 }
          ]
      },
        p: {
          type: 'person',
          person-name: [
            { type: 'person-name', value: 'Bob' }
          ],
          age: [ ]
      }]
      """


  Feature: a concept's attributes can be fetched using more general types than the concept type owns
    When get answers of typeql fetch
      """
      match
      $p isa person, has person-name 'Alice';
      fetch
      $p: attribute;
      """
    Then fetch answers are
      """
      [{
        p: {
          type: 'person',
          attribute: [
            { type: 'person-name', value: 'Alice' },
            { type: 'age', value: 10 },
            { type: 'person-name', value: 'Allie' }
          ],
      }]
      """


  Feature: a fetch subquery can be a match-fetch query
    When get answers of typeql fetch
      """
      match
      $p isa person, has person-name $n; { $n == 'Alice'; } or { $n == 'Bob'; };
      fetch
      $p: person-name, age;
      employers: {
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
        p: {
          type: 'person',
          person-name: [
            { type: 'person-name', value: 'Alice' }
          ],
          age: [
            { type: 'age', value: 10 }
          ]
        },
        employers: [
          c: {
            type: 'company',
            name: [ { type: 'company-name', value: 'Vaticle' }]
          }
        ]
      },
      {
        p: {
         type: 'person',
         person-name: [
           { type: 'person-name', value: 'Bob' }
         ],
         age: [ ]
       },
       employers: [ ]
      }]
      """


  Feature: a fetch subquery can be a match-aggregate query
    When get answers of typeql fetch
      """
      match
      $p isa person, has person-name $n; { $n == 'Alice'; } or { $n == 'Bob'; };
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
        p: {
          type: 'person',
          person-name: [
            { type: 'person-name', value: 'Alice' }
          ],
          age: [
            { type: 'age', value: 10 }
          ]
        },
        employer-count: { value: 1 }
      },
      {
        p: {
         type: 'person',
         person-name: [
           { type: 'person-name', value: 'Bob' }
         ],
         age: [ ]
       },
       employment-count: { value: 0 }
      }]
      """


  Feature: a project can be relabeled
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
        person: { label: 'person' }
      }]
      """


  Feature: an attribute projection can be relabeled
    When get answers of typeql fetch
      """
      match
      $p isa person, has person-name $n; { $n == 'Alice'; } or { $n == 'Bob'; };
      fetch
      $p: person-name as name, age;
      sort $n;
      """
    Then fetch answers are
      """
      [{
        p: {
          type: 'person',
          name: [
            { type: 'person-name', value: 'Alice' }
          ],
          age: [
            { type: 'age', value: 10 }
          ]
      },
        p: {
          type: 'person',
          name: [
            { type: 'person-name', value: 'Bob' }
          ],
          age: [ ]
      }]
      """


  Feature: an attribute projection with an invalid type throws
    When get answers of typeql fetch; throws exception
      """
      match
      $p isa person, has person-name $n; { $n == 'Alice'; } or { $n == 'Bob'; };
      fetch
      $p: type;
      sort $n;
      """


  Feature: an attribute projection with an invalid relabel throws
    When get answers of typeql fetch; throws exception
      """
      match
      $p isa person, has person-name $n; { $n == 'Alice'; } or { $n == 'Bob'; };
      fetch
      $p: person-name as type;
      sort $n;
      """


  Feature: a fetch subquery cannot be an insert, match-get, match-group, or match-group-aggregate
    When get answers of typeql fetch; throws exception
    """
      match
      $p isa person, has person-name $n; { $n == 'Alice'; } or { $n == 'Bob'; };
      fetch
      $p: person-name, age;
      inserted: {
        insert $p has age 20;
      };
      sort $n;
      """
    When get answers of typeql fetch; throws exception
      """
      match
      $p isa person, has person-name $n; { $n == 'Alice'; } or { $n == 'Bob'; };
      fetch
      $p: person-name, age;
      ages: {
        match
        $p has age $n;
        get $n;
      };
      sort $n;
      """
    When get answers of typeql fetch; throws exception
      """
      match
      $p isa person, has person-name $n; { $n == 'Alice'; } or { $n == 'Bob'; };
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
    When get answers of typeql fetch; throws exception
      """
      match
      $p isa person, has person-name $n; { $n == 'Alice'; } or { $n == 'Bob'; };
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