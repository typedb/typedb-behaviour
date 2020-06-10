#
# Copyright (C) 2020 Grakn Labs
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

Feature: Concept Attribute

  Background:
    Given connection has been opened
    Given connection delete all keyspaces
    Given connection does not have any keyspace
    Given connection create keyspace: grakn
    Given connection open schema session for keyspace: grakn
    Given session opens transaction of type: write
    # Write schema for the test scenarios
    Given put attribute type: is-alive, value type: boolean
    Given put attribute type: age, value type: long
    Given put attribute type: score, value type: double
    Given put attribute type: name, value type: string
    Given put attribute type: birth-date, value type: datetime
    Given put entity type: person
    Given entity(person) set has attribute: is-alive
    Given entity(person) set has attribute: age
    Given entity(person) set has attribute: score
    Given entity(person) set has attribute: name
    Given entity(person) set has attribute: birth-date
    Given transaction commits
    Given connection close all sessions
    Given connection open data session for keyspace: grakn
    Given session opens transaction of type: write

  Scenario: Attribute with value type boolean can be created
    When $x = attribute(is-alive) as(boolean) put: true
    Then attribute $x is null: false
    Then attribute $x has type: is-alive
    Then attribute $x has value type: boolean
    Then attribute $x has boolean value: true
    When transaction commits
    When session opens transaction of type: read
    When $x = attribute(is-alive) as(boolean) get: true
    Then attribute $x is null: false
    Then attribute $x has type: is-alive
    Then attribute $x has value type: boolean
    Then attribute $x has boolean value: true

  Scenario: Attribute with value type long can be created
    When $x = attribute(age) as(long) put: 21
    Then attribute $x is null: false
    Then attribute $x has type: age
    Then attribute $x has value type: long
    Then attribute $x has long value: 21
    When transaction commits
    When session opens transaction of type: read
    When $x = attribute(age) as(long) get: 21
    Then attribute $x is null: false
    Then attribute $x has type: age
    Then attribute $x has value type: long
    Then attribute $x has long value: 21

  Scenario: Attribute with value type double can be created
    When $x = attribute(score) as(double) put: 123.456
    Then attribute $x is null: false
    Then attribute $x has type: score
    Then attribute $x has value type: double
    Then attribute $x has double value: 123.456
    When transaction commits
    When session opens transaction of type: read
    When $x = attribute(score) as(double) get: 123.456
    Then attribute $x is null: false
    Then attribute $x has type: score
    Then attribute $x has value type: double
    Then attribute $x has double value: 123.456

  Scenario: Attribute with value type string can be created
    When $x = attribute(name) as(string) put: alice
    Then attribute $x is null: false
    Then attribute $x has type: name
    Then attribute $x has value type: string
    Then attribute $x has string value: alice
    When transaction commits
    When session opens transaction of type: read
    When $x = attribute(name) as(string) get: alice
    Then attribute $x is null: false
    Then attribute $x has type: name
    Then attribute $x has value type: string
    Then attribute $x has string value: alice

  Scenario: Attribute with value type datetime can be created
    When $x = attribute(birth-date) as(datetime) put: 1990-01-01 11:22:33
    Then attribute $x is null: false
    Then attribute $x has type: birth-date
    Then attribute $x has value type: datetime
    Then attribute $x has datetime value: 1990-01-01 11:22:33
    When transaction commits
    When session opens transaction of type: read
    When $x = attribute(birth-date) as(datetime) get: 1990-01-01 11:22:33
    Then attribute $x is null: false
    Then attribute $x has type: birth-date
    Then attribute $x has value type: datetime
    Then attribute $x has datetime value: 1990-01-01 11:22:33

  Scenario: Attribute with value type boolean can be retrieved from its type
    When $x = attribute(is-alive) as(boolean) put: true
    Then attribute(is-alive) instances contain: $x
    When transaction commits
    When session opens transaction of type: read
    When $x = attribute(is-alive) as(boolean) get: true
    Then attribute(is-alive) instances contain: $x

  Scenario: Attribute with value type long can be retrieved from its type
    When $x = attribute(age) as(long) put: 21
    Then attribute(age) instances contain: $x
    When transaction commits
    When session opens transaction of type: read
    When $x = attribute(age) as(long) get: 21
    Then attribute(age) instances contain: $x

  Scenario: Attribute with value type double can be retrieved from its type
    When $x = attribute(score) as(double) put: 123.456
    Then attribute(score) instances contain: $x
    When transaction commits
    When session opens transaction of type: read
    When $x = attribute(score) as(double) get: 123.456
    Then attribute(score) instances contain: $x

  Scenario: Attribute with value type string can be retrieved from its type
    When $x = attribute(name) as(string) put: alice
    Then attribute(name) instances contain: $x
    When transaction commits
    When session opens transaction of type: read
    When $x = attribute(name) as(string) get: alice
    Then attribute(name) instances contain: $x

  Scenario: Attribute with value type datetime can be retrieved from its type
    When $x = attribute(birth-date) as(datetime) put: 1990-01-01 11:22:33
    Then attribute(birth-date) instances contain: $x
    When transaction commits
    When session opens transaction of type: read
    When $x = attribute(birth-date) as(datetime) get: 1990-01-01 11:22:33
    Then attribute(birth-date) instances contain: $x

  Scenario: Attribute with value type boolean can be deleted
    When $x = attribute(is-alive) as(boolean) put: true
    When attribute $x is deleted
    When $x = attribute(is-alive) as(boolean) get: true
    Then attribute $x is null: true
    When transaction commits
    When session opens transaction of type: read

  Scenario: Attribute with value type long can be deleted
    When $x = attribute(age) as(long) put: 21
    When attribute $x is deleted
    When $x = attribute(age) as(long) get: 21
    Then attribute $x is null: true
    When transaction commits
    When session opens transaction of type: read

  Scenario: Attribute with value type double can be deleted
    When $x = attribute(score) as(double) put: 123.456
    When attribute $x is deleted
    When $x = attribute(score) as(double) get: 123.456
    Then attribute $x is null: true

  Scenario: Attribute with value type string can be deleted
    When $x = attribute(name) as(string) put: alice
    When attribute $x is deleted
    When $x = attribute(name) as(string) get: alice
    Then attribute $x is null: true
    When transaction commits
    When session opens transaction of type: read

  Scenario: Attribute with value type datetime can be deleted
    When $x = attribute(birth-date) as(datetime) put: 1990-01-01 11:22:33
    When attribute $x is deleted
    When $x = attribute(birth-date) as(datetime) get: 1990-01-01 11:22:33
    Then attribute $x is null: true
    When transaction commits
    When session opens transaction of type: read
