# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: Concept Role Players

  Background:
    Given typedb starts
    Given connection opens with default authentication
    Given connection has been opened
    Given connection does not have any database
    Given connection create database: typedb
    Given connection opens schema transaction for database: typedb

    # Write schema for the test scenarios
    Given put attribute type: name
    Given attribute(name) set value-type: string
    Given put attribute type: company-name
    Given attribute(company-name) set value-type: string
    Given put attribute type: date
    Given attribute(date) set value-type: datetime

    Given put relation type: employment
    Given relation(employment) set owns: date

    Given relation(employment) create role: employer
    Given relation(employment) create role: employee[]

    Given put entity type: company
    Given entity(company) set owns: company-name
    Given entity(company) get owns: company-name, set annotation: @key
    Given entity(company) set plays role: employment:employer

    Given put entity type: person
    Given entity(person) set owns: name
    Given entity(person) get owns: name, set annotation: @key
    Given entity(person) set plays role: employment:employee

    Given transaction commits

    Given connection opens write transaction for database: typedb

  # TODO move all other role player steps here

  Scenario: Role players can be ordered
    When $a = entity(person) create new instance with key(name): alice
    When $b = entity(person) create new instance with key(name): bob
    When $c = entity(company) create new instance with key(company-name): acme
    When $e = relation(employment) create new instance
    When relation $e add players for role(employee[]): [$a, $b]
    When relation $e add player for role(employer): $c
    Then transaction commits

