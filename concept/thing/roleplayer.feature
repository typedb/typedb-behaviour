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
    Given connection open schema transaction for database: typedb

    # Write schema for the test scenarios
    Given create attribute type: name
    Given attribute(name) set value type: string
    Given create attribute type: company-name
    Given attribute(company-name) set value type: string
    Given create attribute type: date
    Given attribute(date) set value type: datetime

    Given create relation type: employment
    Given relation(employment) set owns: date

    Given create relation type: vacation
    Given relation(vacation) set owns: date
    Given relation(vacation) create role: employee

    Given relation(employment) create role: employer
    Given relation(employment) create role: employee
    Given relation(employment) get role(employee) set ordering: ordered

    Given create entity type: company
    Given entity(company) set owns: company-name
    Given entity(company) get owns(company-name) set annotation: @key
    Given entity(company) set plays: employment:employer

    Given create entity type: person
    Given entity(person) set owns: name
    Given entity(person) get owns(name) set annotation: @key
    Given entity(person) set plays: employment:employee
    Given entity(person) set plays: vacation:employee

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
    When connection open read transaction for database: typedb
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
    When connection open read transaction for database: typedb
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
    When connection open write transaction for database: typedb
    Then $employees = relation $employment get players for role(employee[])
    Then roleplayer $employees[0] is $alice
    Then roleplayer $employees[1] is $bob
    When relation $employment set players for role(employee[]): [$bob, $alice]
    Then transaction commits
    When connection open read transaction for database: typedb
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
    When connection open read transaction for database: typedb
    Then $employees = relation $employment get players for role(employee[])
    Then roleplayer $employees[0] is $alice
    Then roleplayer $employees[1] is $bob
    Then roleplayer $employees[2] is $alice
    Then roleplayer $employees[3] is $alice
    Then roleplayer $employees[4] is $bob

  Scenario: Relations are cleaned up without roleplayers
    When $alice = entity(person) create new instance with key(name): alice
    When $vacation = relation(vacation) create new instance with key(date): 2024-08-16
    When relation $vacation add player for role(employee): $alice
    When $no-vacation = relation(vacation) create new instance with key(date): 2020-03-23
    Then transaction commits
    When connection open write transaction for database: typedb
    When $vacation = relation(vacation) get instance with key(date): 2024-08-16
    When $no-vacation = relation(vacation) get instance with key(date): 2020-03-23
    Then relation $vacation exists
    Then relation $no-vacation does not exist
    When $alice = entity(person) get instance with key(name): alice
    When relation $vacation remove player for role(employee): $alice
    When $vacation = relation(vacation) get instance with key(date): 2024-08-16
    Then relation $vacation exists
    Then transaction commits
    When connection open read transaction for database: typedb
    When $vacation = relation(vacation) get instance with key(date): 2024-08-16
    Then relation $vacation does not exist

  Scenario: Cannot set roleplayer to relation that doesn't relate this role type and player that doesn't play the role
    When $company = entity(company) create new instance with key(company-name): acme
    When $vacation = relation(vacation) create new instance
    When $employment = relation(employment) create new instance
    Then relation $employment set players for role(employee[]): [$company]; fails
    Then relation $vacation add player for role(employee): $company; fails
    Then transaction commits

    # TODO: Cascade (when we understand it)

  Scenario: Relation can be a player of relation of the same type
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given create relation type: parentship
    Given relation(parentship) create role: info
    Given relation(parentship) set plays: parentship:info
    Given relation(parentship) get plays contain:
      | parentship:info |
    Given relation(parentship) set owns: name
    Given relation(parentship) get owns(name) set annotation: @key
    Given transaction commits
    Given connection open write transaction for database: typedb
    When $p1 = relation(parentship) create new instance with key(name): p1
    When $p2 = relation(parentship) create new instance with key(name): p2
    When $p3 = relation(parentship) create new instance with key(name): p3
    When relation $p1 add player for role(info): $p2
    When relation $p2 add player for role(info): $p1
    When relation $p3 add player for role(info): $p3
    When transaction commits
    When connection open read transaction for database: typedb
    When $p1 = relation(parentship) get instance with key(name): p1
    When $p2 = relation(parentship) get instance with key(name): p2
    When $p3 = relation(parentship) get instance with key(name): p3
    Then relation $p1 get players for role(info) contain: $p2
    Then relation $p2 get players for role(info) contain: $p1
    Then relation $p3 get players for role(info) contain: $p3
