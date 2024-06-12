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

########################
# entity type common
########################

  Scenario: Root entity type cannot be deleted
    Then delete entity type: entity; fails

  Scenario: Entity types can be created
    When create entity type: person
    Then entity(person) exists
    Then entity(person) get supertype: entity
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) exists
    Then entity(person) get supertype: entity

  Scenario: Entity types cannot be redeclared
    When create entity type: person
    Then entity(person) exists
    Then create entity type: person; fails
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) exists
    Then create entity type: person; fails

  Scenario: Entity types can be deleted
    When create entity type: person
    Then entity(person) exists
    When create entity type: company
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
    When create entity type: person
    When transaction commits
    When connection open write transaction for database: typedb
    When $x = entity(person) create new instance
    When transaction commits
    When connection open schema transaction for database: typedb
    Then delete entity type: person; fails

  Scenario: Entity types can change labels
    When create entity type: person
    Then entity(person) get name: person
    When entity(person) set name: horse
    Then entity(person) does not exist
    Then entity(horse) exists
    Then entity(horse) get name: horse
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(horse) get name: horse
    When entity(horse) set name: animal
    Then entity(horse) does not exist
    Then entity(animal) exists
    Then entity(animal) get name: animal
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(animal) exists
    Then entity(animal) get name: animal


  Scenario: Entity types can be subtypes of other entity types
    When create entity type: man
    When create entity type: woman
    When create entity type: person
    When create entity type: cat
    When create entity type: animal
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
    When create entity type: person
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) set supertype: person; fails
    When connection open schema transaction for database: typedb
    Then entity(person) set supertype: person; fails

########################
# @annotations common
########################

  Scenario Outline: Entity type cannot unset @<annotation> that has not been set
    When create entity type: person
    Then entity(person) unset annotation: @<annotation>; fails
    Examples:
      | annotation      |
      | abstract        |

########################
# @abstract
########################

  Scenario: Entity types can be set to abstract
    When create entity type: person
    When entity(person) set annotation: @abstract
    When create entity type: company
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

  Scenario: Entity types can be set to abstract when a subtype has instances
    When create entity type: person
    When create entity type: player
    When entity(player) set supertype: person
    Then transaction commits
    When connection open write transaction for database: typedb
    When $m = entity(player) create new instance
    Then transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) set annotation: @abstract
    Then transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get annotations contain: @abstract

  Scenario: Entity cannot set @abstract annotation with arguments
    When create entity type: person
    Then entity(person) set annotation: @abstract(); fails
    Then entity(person) set annotation: @abstract(1); fails
    Then entity(person) set annotation: @abstract(1, 2); fails
    Then entity(person) get annotations is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get annotations is empty

  Scenario: Entity types can subtype non abstract entity types
    When create entity type: person
    When create entity type: player
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get annotations do not contain: @abstract
    When entity(player) set supertype: person
    Then entity(player) get supertypes contain: person
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(player) get supertypes contain: person

########################
# not compatible @annotations: @distinct, @key, @unique, @subkey, @values, @range, @card, @cascade, @independent, @replace, @regex
########################

  Scenario: Entity type cannot have @distinct, @key, @unique, @subkey, @values, @range, @card, @cascade, @independent, @replace, and @regex annotations
    When create entity type: person
    When entity(person) set value type: <value-type>
    Then entity(person) set annotation: @distinct; fails
    Then entity(person) set annotation: @key; fails
    Then entity(person) set annotation: @unique; fails
    Then entity(person) set annotation: @subkey; fails
    Then entity(person) set annotation: @subkey(LABEL); fails
    Then entity(person) set annotation: @values; fails
    Then entity(person) set annotation: @values(1, 2); fails
    Then entity(person) set annotation: @range; fails
    Then entity(person) set annotation: @range(1, 2); fails
    Then entity(person) set annotation: @card; fails
    Then entity(person) set annotation: @card(1, 2); fails
    Then entity(person) set annotation: @cascade; fails
    Then entity(person) set annotation: @independent; fails
    Then entity(person) set annotation: @replace; fails
    Then entity(person) set annotation: @regex; fails
    Then entity(person) set annotation: @regex("val"); fails
    Then entity(person) set annotation: @does-not-exist; fails
    Then entity(person) get annotations is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get annotations is empty
