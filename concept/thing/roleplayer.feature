# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: Concept Ordered Role Players

  Background:
    Given typedb starts
    Given connection opens with default authentication
    Given connection has been opened
    Given connection does not have any database
    Given connection create database: typedb
    Given connection open schema transaction for database: typedb

    # Write schema for the test scenarios
    Given create attribute type: name
    Given attribute(name) set value-type: string
    Given create attribute type: company-name
    Given attribute(company-name) set value-type: string
    Given create attribute type: date
    Given attribute(date) set value-type: datetime

    Given create relation type: employment
    Given relation(employment) set owns: date

    Given relation(employment) create role: employer
    Given relation(employment) create role: employee[]

    Given create entity type: company
    Given entity(company) set owns: company-name
    Given entity(company) get owns(company-name) set annotation: @key
    Given entity(company) set plays: employment:employer

    Given create entity type: person
    Given entity(person) set owns: name
    Given entity(person) get owns(name) set annotation: @key
    Given entity(person) set plays: employment:employee

    Given transaction commits

    Given connection open write transaction for database: typedb

  Scenario: Role players can be ordered
    When $alice = entity(person) create new instance with key(name): alice
    When $bob = entity(person) create new instance with key(name): bob
    When $company = entity(company) create new instance with key(company-name): acme
    When $employment = relation(employment) create new instance
    When relation $employment set players for role(employee[]): [$alice, $bob]
    When relation $employment add player for role(employer): $company
    Then transaction commits

  Scenario: Ordered roleplayers can be retrieved and indexed
    When $alice = entity(person) create new instance with key(name): alice
    When $bob = entity(person) create new instance with key(name): bob
    When $company = entity(company) create new instance with key(company-name): acme
    When $employment = relation(employment) create new instance
    When relation $employment set players for role(employee[]): [$alice, $bob]
    When relation $employment add player for role(employer): $company
    Then transaction commits
    When connection opens read transaction for database: typedb
    Then $employees = relation $employment get players for role(employee[])
    Then roleplayer $employees[0] is $alice
    Then roleplayer $employees[1] is $bob

  Scenario: Ordered roleplayers can be retrieved as unordered
    When $alice = entity(person) create new instance with key(name): alice
    When $bob = entity(person) create new instance with key(name): bob
    When $company = entity(company) create new instance with key(company-name): acme
    When $employment = relation(employment) create new instance
    When relation $employment set players for role(employee[]): [$alice, $bob]
    When relation $employment add player for role(employer): $company
    Then transaction commits
    When connection opens read transaction for database: typedb
    Then relation $employment get players for role(employee) contain: $alice
    Then relation $employment get players for role(employee) contain: $bob

  Scenario: Ordered roleplayers can be overwritten
    When $alice = entity(person) create new instance with key(name): alice
    When $bob = entity(person) create new instance with key(name): bob
    When $company = entity(company) create new instance with key(company-name): acme
    When $employment = relation(employment) create new instance
    When relation $employment set players for role(employee[]): [$alice, $bob]
    When relation $employment add player for role(employer): $company
    Then transaction commits
    When connection opens write transaction for database: typedb
    Then $employees = relation $employment get players for role(employee[])
    Then roleplayer $employees[0] is $alice
    Then roleplayer $employees[1] is $bob
    When relation $employment set players for role(employee[]): [$bob, $alice]
    Then transaction commits
    When connection opens read transaction for database: typedb
    Then $employees = relation $employment get players for role(employee[])
    Then roleplayer $employees[0] is $bob
    Then roleplayer $employees[1] is $alice

  Scenario: Ordered roleplayers can contain the same player multiple times
    When $alice = entity(person) create new instance with key(name): alice
    When $bob = entity(person) create new instance with key(name): bob
    When $company = entity(company) create new instance with key(company-name): acme
    When $employment = relation(employment) create new instance
    When relation $employment set players for role(employee[]): [$alice, $bob, $alice, $alice, $bob]
    When relation $employment add player for role(employer): $company
    Then transaction commits
    When connection opens read transaction for database: typedb
    Then $employees = relation $employment get players for role(employee[])
    Then roleplayer $employees[0] is $alice
    Then roleplayer $employees[1] is $bob
    Then roleplayer $employees[2] is $alice
    Then roleplayer $employees[3] is $alice
    Then roleplayer $employees[4] is $bob

