# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: Concept Entity Type

  Background:
    Given typedb starts
    Given connection opens with default authentication
    Given connection has been opened
    Given connection does not have any database
    Given connection create database: typedb
    Given connection open schema transaction for database: typedb

  Scenario: Root entity type cannot be deleted
    Then delete entity type: entity; fails

  Scenario: Entity types can be created
    When put entity type: person
    Then entity(person) exists
    Then entity(person) get supertype: entity
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) exists
    Then entity(person) get supertype: entity

  Scenario: Entity types can be deleted
    When put entity type: person
    Then entity(person) exists
    When put entity type: company
    Then entity(company) exists
    When delete entity type: company
    Then entity(company) does not exist
    Then entity(entity) get subtypes do not contain:
      | company |
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) exists
    Then entity(company) does not exist
    Then entity(entity) get subtypes do not contain:
      | company |
    When delete entity type: person
    Then entity(person) does not exist
    Then entity(entity) get subtypes do not contain:
      | person  |
      | company |
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) does not exist
    Then entity(company) does not exist
    Then entity(entity) get subtypes do not contain:
      | person  |
      | company |

  Scenario: Entity types that have instances cannot be deleted
    When put entity type: person
    When transaction commits
    When connection open write transaction for database: typedb
    When $x = entity(person) create new instance
    When transaction commits
    When connection open schema transaction for database: typedb
    Then delete entity type: person; fails

  Scenario: Entity types can change labels
    When put entity type: person
    Then entity(person) get label: person
    When entity(person) set label: horse
    Then entity(person) does not exist
    Then entity(horse) exists
    Then entity(horse) get label: horse
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(horse) get label: horse
    When entity(horse) set label: animal
    Then entity(horse) does not exist
    Then entity(animal) exists
    Then entity(animal) get label: animal
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(animal) exists
    Then entity(animal) get label: animal

  Scenario: Entity types can be set to abstract
    When put entity type: person
    When entity(person) set annotation: @abstract
    When put entity type: company
    Then entity(person) get annotations contain: @abstract
    When transaction commits
    When connection open write transaction for database: typedb
    Then entity(person) create new instance; fails
    When connection open write transaction for database: typedb
    Then entity(company) get annotations do not contain: @abstract
    Then entity(person) get annotations contain: @abstract
    Then entity(person) create new instance; fails
    When connection open schema transaction for database: typedb
    Then entity(company) get annotations do not contain: @abstract
    When entity(company) set annotation: @abstract
    Then entity(company) get annotations contain: @abstract
    When transaction commits
    When connection open write transaction for database: typedb
    Then entity(company) create new instance; fails
    When connection open write transaction for database: typedb
    Then entity(company) get annotations contain: @abstract
    Then entity(company) create new instance; fails

  Scenario: Entity types can be subtypes of other entity types
    When put entity type: man
    When put entity type: woman
    When put entity type: person
    When put entity type: cat
    When put entity type: animal
    When entity(man) set supertype: person
    When entity(woman) set supertype: person
    When entity(person) set supertype: animal
    When entity(cat) set supertype: animal
    Then entity(man) get supertype: person
    Then entity(woman) get supertype: person
    Then entity(person) get supertype: animal
    Then entity(cat) get supertype: animal
    Then entity(man) get supertypes contain:
      | entity |
      | person |
      | animal |
    Then entity(woman) get supertypes contain:
      | entity |
      | person |
      | animal |
    Then entity(person) get supertypes contain:
      | entity |
      | animal |
    Then entity(cat) get supertypes contain:
      | entity |
      | animal |
    Then entity(man) get subtypes is empty
    Then entity(woman) get subtypes is empty
    Then entity(person) get subtypes contain:
      | man    |
      | woman  |
    Then entity(cat) get subtypes is empty
    Then entity(animal) get subtypes contain:
      | cat    |
      | person |
      | man    |
      | woman  |
    Then entity(entity) get subtypes contain:
      | animal |
      | cat    |
      | person |
      | man    |
      | woman  |
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(man) get supertype: person
    Then entity(woman) get supertype: person
    Then entity(person) get supertype: animal
    Then entity(cat) get supertype: animal
    Then entity(man) get supertypes contain:
      | entity |
      | person |
      | animal |
    Then entity(woman) get supertypes contain:
      | entity |
      | person |
      | animal |
    Then entity(person) get supertypes contain:
      | entity |
      | animal |
    Then entity(cat) get supertypes contain:
      | entity |
      | animal |
    Then entity(man) get subtypes is empty
    Then entity(woman) get subtypes is empty
    Then entity(person) get subtypes contain:
      | man    |
      | woman  |
    Then entity(cat) get subtypes is empty
    Then entity(animal) get subtypes contain:
      | cat    |
      | person |
      | man    |
      | woman  |
    Then entity(entity) get subtypes contain:
      | animal |
      | cat    |
      | person |
      | man    |
      | woman  |

  Scenario: Entity types cannot subtype itself
    When put entity type: person
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) set supertype: person; fails
    When connection open schema transaction for database: typedb
    Then entity(person) set supertype: person; fails
