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

  Scenario: Put attribute instance of value type boolean
    When $x = attribute(is-alive) as(boolean) put: true
    Then attribute $x is null: false
    Then attribute $x has type: is-alive
    Then attribute $x has value type: boolean
    Then attribute $x has boolean value: true

  Scenario: Put attribute instance of value type long
    When $x = attribute(age) as(long) put: 21
    Then attribute $x is null: false
    Then attribute $x has type: age
    Then attribute $x has value type: long
    Then attribute $x has long value: 21

  Scenario: Put attribute instance of value type double
    When $x = attribute(score) as(double) put: 95.67
    Then attribute $x is null: false
    Then attribute $x has type: score
    Then attribute $x has value type: double
    Then attribute $x has double value: 95.67

  Scenario: Put attribute instance of value type string
    When $x = attribute(name) as(string) put: alice
    Then attribute $x is null: false
    Then attribute $x has type: name
    Then attribute $x has value type: string
    Then attribute $x has string value: alice

  Scenario: Put attribute instance of value type datetime
    When $x = attribute(birth-date) as(datetime) put: 1990-01-01 11:22:33
    Then attribute $x is null: false
    Then attribute $x has type: birth-date
    Then attribute $x has value type: datetime
    Then attribute $x has datetime value: 1990-01-01 11:22:33
