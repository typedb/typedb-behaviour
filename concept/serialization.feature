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
Feature: Concept Serialization

  Background:
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
        owns name,
        owns date-of-birth,
        owns ref @key;
      company sub entity,
        plays employment:employer,
        owns name,
        owns ref @key;
      friendship sub relation,
        relates friend,
        owns ref @key;
      employment sub relation,
        relates employee,
        relates employer,
        owns ref @key;
      name sub attribute, value string;
      ref sub attribute, value long;
      date-of-birth sub attribute, value datetime;
      """
    Given transaction commits
    Given connection close all sessions

    Given connection open data session for database: typedb
    Given session opens transaction of type: write

  Scenario: Serialized type contains its label
    When get answers of typeql match
      """
      match $x type person;
      """
    Then JSON of answer concepts matches
      """
      [ { "x": { "label": "person" } } ]
      """

  Scenario: Serialized entity contains its type label only
    Given typeql insert
      """
      insert
      $x isa person, has ref 0;
      $y isa person, has ref 1;
      """
    When get answers of typeql match
      """
      match $x isa person;
      """
    Then JSON of answer concepts matches
      """
      [
        { "x": { "type": "person" } },
        { "x": { "type": "person" } }
      ]
      """

  Scenario: Serialized relation contains its type label only
    Given typeql insert
      """
      insert
      $x isa person, has ref 0;
      $y isa company, has ref 1;
      $z (friend: $x) isa friendship, has ref 2;
      $w (employee: $x, employer: $y) isa employment, has ref 3;
      """
    When get answers of typeql match
      """
      match $x isa relation;
      """
    Then JSON of answer concepts matches
      """
      [
        { "x": { "type": "friendship" } },
        { "x": { "type": "employment" } }
      ]
      """

  Scenario: Serialized attribute contains its type label, value and value type
    Given typeql insert
      """
      insert
      $x isa person, has ref 0, has name "Alan";
      """
    When get answers of typeql match
      """
      match $x isa attribute;
      """
    Then JSON of answer concepts matches
      """
      [
        { "x": { "type": "name", "value_type": "string", "value": "Alan" } },
        { "x": { "type": "ref", "value_type": "long", "value": 0 } }
      ]
      """

  Scenario: Serialized datetime attribute is represented according to ISO 8601
    Given typeql insert
      """
      insert
      $dob 2023-03-21T12:34:56.789 isa date-of-birth;
      """
    When get answers of typeql match
      """
      match $x isa date-of-birth;
      """
    Then JSON of answer concepts matches
      """
      [ { "x": { "type": "date-of-birth", "value_type": "datetime", "value": "2023-03-21T12:34:56.789" } } ]
      """

  Scenario: Serialized datetime attribute always has resolution of milliseconds
    Given typeql insert
      """
      insert
      $dob 2023-03-21T12:34:56 isa date-of-birth;
      $dob 2023-03-21T12:34 isa date-of-birth;
      $dob 2023-03-21 isa date-of-birth;
      """
    When get answers of typeql match
      """
      match $x isa date-of-birth;
      """
    Then JSON of answer concepts matches
      """
      [
        { "x": { "type": "date-of-birth", "value_type": "datetime", "value": "2023-03-21T12:34:56.000" } },
        { "x": { "type": "date-of-birth", "value_type": "datetime", "value": "2023-03-21T12:34:00.000" } },
        { "x": { "type": "date-of-birth", "value_type": "datetime", "value": "2023-03-21T00:00:00.000" } }
      ]
      """

  Scenario: Serialized concept map can contain a mix of types, role types, and entities
    Given typeql insert
      """
      insert
      $x isa person, has ref 0;
      $y isa company, has ref 1;
      $z (employee: $x, employer: $y) isa employment, has ref 2;
      """
    When get answers of typeql match
      """
      match $x($r:$y) isa! $t, has ref $z;
      """
    Then JSON of answer concepts matches
      """
      [
        {
          "r": { "label": "relation:role" },
          "t": { "label": "employment" },
          "x": { "type": "employment" },
          "y": { "type": "person" },
          "z": { "value_type": "long", "value": 2, "type": "ref" }
        },
        {
          "r": { "label": "employment:employee" },
          "t": { "label": "employment" },
          "x": { "type": "employment" },
          "y": { "type": "person" },
          "z": { "value_type": "long", "value": 2, "type": "ref" }
        },
        {
          "r": { "label": "relation:role" },
          "t": { "label": "employment" },
          "x": { "type": "employment" },
          "y": { "type": "company" },
          "z": { "value_type": "long", "value": 2, "type": "ref" }
        },
        {
          "r": { "label": "employment:employer" },
          "t": { "label": "employment" },
          "x": { "type": "employment" },
          "y": { "type": "company" },
          "z": { "value_type": "long", "value": 2, "type": "ref" }
        }
      ]
      """
