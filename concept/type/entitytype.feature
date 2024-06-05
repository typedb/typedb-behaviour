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
    Given connection opens schema transaction for database: typedb

  Scenario: Root entity type cannot be deleted
    Then delete entity type: entity; fails

  Scenario: Entity types can be created
    When put entity type: person
    Then entity(person) exists
    Then entity(person) get supertype: entity
    When transaction commits
    When connection opens read transaction for database: typedb
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
    When connection opens schema transaction for database: typedb
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
    When connection opens read transaction for database: typedb
    Then entity(person) does not exist
    Then entity(company) does not exist
    Then entity(entity) get subtypes do not contain:
      | person  |
      | company |

  Scenario: Entity types that have instances cannot be deleted
    When put entity type: person
    When transaction commits
    When connection opens write transaction for database: typedb
    When $x = entity(person) create new instance
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then delete entity type: person; fails

  Scenario: Entity types can change labels
    When put entity type: person
    Then entity(person) get label: person
    When entity(person) set label: horse
    Then entity(person) does not exist
    Then entity(horse) exists
    Then entity(horse) get label: horse
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then entity(horse) get label: horse
    When entity(horse) set label: animal
    Then entity(horse) does not exist
    Then entity(animal) exists
    Then entity(animal) get label: animal
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(animal) exists
    Then entity(animal) get label: animal

  Scenario: Entity types can be set to abstract
    When put entity type: person
    When entity(person) set annotation: @abstract
    When put entity type: company
    Then entity(person) get annotations contain: @abstract
    When transaction commits
    When connection opens write transaction for database: typedb
    Then entity(person) create new instance; fails
    When connection opens write transaction for database: typedb
    Then entity(company) get annotations do not contain: @abstract
    Then entity(person) get annotations contain: @abstract
    Then entity(person) create new instance; fails
    When connection opens schema transaction for database: typedb
    Then entity(company) get annotations do not contain: @abstract
    When entity(company) set annotation: @abstract
    Then entity(company) get annotations contain: @abstract
    When transaction commits
    When connection opens write transaction for database: typedb
    Then entity(company) create new instance; fails
    When connection opens write transaction for database: typedb
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
    When connection opens read transaction for database: typedb
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
    When connection opens schema transaction for database: typedb
    Then entity(person) set supertype: person; fails
    When connection opens schema transaction for database: typedb
    Then entity(person) set supertype: person; fails

  Scenario: Entity types can play role types
    When put relation type: marriage
    When relation(marriage) create role: husband
    When put entity type: person
    When entity(person) set plays role: marriage:husband
    Then entity(person) get plays roles contain:
      | marriage:husband |
    Then relation(marriage) get role(husband) get players contain:
      | person |
    When transaction commits
    When connection opens schema transaction for database: typedb
    When relation(marriage) create role: wife
    When entity(person) set plays role: marriage:wife
    Then entity(person) get plays roles contain:
      | marriage:husband |
      | marriage:wife    |
    Then relation(marriage) get role(husband) get players contain:
      | person |
    Then relation(marriage) get role(wife) get players contain:
      | person |
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(person) get plays roles contain:
      | marriage:husband |
      | marriage:wife    |
    Then relation(marriage) get role(husband) get players contain:
      | person |
    Then relation(marriage) get role(wife) get players contain:
      | person |

  Scenario: Entity types can unset playing role types
    When put relation type: marriage
    When relation(marriage) create role: husband
    When relation(marriage) create role: wife
    When put entity type: person
    When entity(person) set plays role: marriage:husband
    When entity(person) set plays role: marriage:wife
    Then entity(person) unset plays role: marriage:husband
    Then entity(person) get plays roles do not contain:
      | marriage:husband |
    Then relation(marriage) get role(husband) get players do not contain:
      | person |
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then entity(person) unset plays role: marriage:wife
    Then entity(person) get plays roles do not contain:
      | marriage:husband |
      | marriage:wife    |
    Then relation(marriage) get role(husband) get players do not contain:
      | person |
    Then relation(marriage) get role(wife) get players do not contain:
      | person |
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(person) get plays roles do not contain:
      | marriage:husband |
      | marriage:wife    |
    Then relation(marriage) get role(husband) get players do not contain:
      | person |
    Then relation(marriage) get role(wife) get players do not contain:
      | person |

  Scenario: Attempting to unset playing a role type that an entity type cannot actually play throws
    When put relation type: marriage
    When relation(marriage) create role: husband
    When relation(marriage) create role: wife
    When put entity type: person
    When entity(person) set plays role: marriage:wife
    Then entity(person) get plays roles do not contain:
      | marriage:husband |
    Then entity(person) unset plays role: marriage:husband; fails

  Scenario: Entity types cannot unset playing role types that are currently played by existing instances
    When put relation type: marriage
    When relation(marriage) create role: husband
    When relation(marriage) create role: wife
    When put entity type: person
    When entity(person) set plays role: marriage:wife
    Then transaction commits
    When connection opens write transaction for database: typedb
    When $m = relation(marriage) create new instance
    When $a = entity(person) create new instance
    When relation $m add player for role(wife): $a
    Then transaction commits
    When connection opens schema transaction for database: typedb
    Then entity(person) unset plays role: marriage:wife; fails

  Scenario: Entity types can inherit playing role types
    When put relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) create role: child
    When put relation type: marriage
    When relation(marriage) create role: husband
    When relation(marriage) create role: wife
    When put entity type: animal
    When entity(animal) set plays role: parentship:parent
    When entity(animal) set plays role: parentship:child
    When put entity type: person
    When entity(person) set supertype: animal
    When entity(person) set plays role: marriage:husband
    When entity(person) set plays role: marriage:wife
    Then entity(person) get plays roles contain:
      | parentship:parent |
      | parentship:child  |
      | marriage:husband  |
      | marriage:wife     |
    Then entity(person) get plays roles explicit contain:
      | marriage:husband  |
      | marriage:wife     |
    Then entity(person) get plays roles explicit do not contain:
      | parentship:parent |
      | parentship:child  |
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then entity(person) get plays roles contain:
      | parentship:parent |
      | parentship:child  |
      | marriage:husband  |
      | marriage:wife     |
    Then entity(person) get plays roles explicit contain:
      | marriage:husband  |
      | marriage:wife     |
    Then entity(person) get plays roles explicit do not contain:
      | parentship:parent |
      | parentship:child  |
    When put relation type: sales
    When relation(sales) create role: buyer
    When put entity type: customer
    When entity(customer) set supertype: person
    When entity(customer) set plays role: sales:buyer
    Then entity(customer) get plays roles contain:
      | parentship:parent |
      | parentship:child  |
      | marriage:husband  |
      | marriage:wife     |
      | sales:buyer       |
    Then entity(customer) get plays roles explicit contain:
      | sales:buyer       |
    Then entity(customer) get plays roles explicit do not contain:
      | parentship:parent |
      | parentship:child  |
      | marriage:husband  |
      | marriage:wife     |
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(animal) get plays roles contain:
      | parentship:parent |
      | parentship:child  |
    Then entity(person) get plays roles contain:
      | parentship:parent |
      | parentship:child  |
      | marriage:husband  |
      | marriage:wife     |
    Then entity(customer) get plays roles contain:
      | parentship:parent |
      | parentship:child  |
      | marriage:husband  |
      | marriage:wife     |
      | sales:buyer       |

  Scenario: Entity types can inherit playing role types that are subtypes of each other
    When put relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) create role: child
    When put relation type: fathership
    When relation(fathership) set supertype: parentship
    When relation(fathership) create role: father
    When relation(fathership) get role(father); set override: parent
    When put entity type: person
    When entity(person) set plays role: parentship:parent
    When entity(person) set plays role: parentship:child
    When put entity type: man
    When entity(man) set supertype: person
    When entity(man) set plays role: fathership:father
    Then entity(man) get plays roles contain:
      | parentship:parent |
      | fathership:father |
      | parentship:child  |
    Then entity(man) get plays roles explicit contain:
      | fathership:father |
    Then entity(man) get plays roles explicit do not contain:
      | parentship:parent |
      | parentship:child  |
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then entity(man) get plays roles contain:
      | parentship:parent |
      | fathership:father |
      | parentship:child  |
    Then entity(man) get plays roles explicit contain:
      | fathership:father |
    Then entity(man) get plays roles explicit do not contain:
      | parentship:parent |
      | parentship:child  |
    When put relation type: mothership
    When relation(mothership) set supertype: parentship
    When relation(mothership) create role: mother
    When relation(mothership) get role(mother); set override: parent
    When put entity type: woman
    When entity(woman) set supertype: person
    When entity(woman) set plays role: mothership:mother
    Then entity(woman) get plays roles contain:
      | parentship:parent |
      | mothership:mother |
      | parentship:child  |
    Then entity(woman) get plays roles explicit contain:
      | mothership:mother |
    Then entity(woman) get plays roles explicit do not contain:
      | parentship:parent |
      | parentship:child  |
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(person) get plays roles contain:
      | parentship:parent |
      | parentship:child  |
    Then entity(man) get plays roles contain:
      | parentship:parent |
      | fathership:father |
      | parentship:child  |
    Then entity(man) get plays roles explicit contain:
      | fathership:father |
    Then entity(man) get plays roles explicit do not contain:
      | parentship:parent |
      | parentship:child  |
    Then entity(woman) get plays roles contain:
      | parentship:parent |
      | mothership:mother |
      | parentship:child  |
    Then entity(woman) get plays roles explicit contain:
      | mothership:mother |
    Then entity(woman) get plays roles explicit do not contain:
      | parentship:parent |
      | parentship:child  |

  Scenario: Entity types can override inherited playing role types
    When put relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) create role: child
    When put relation type: fathership
    When relation(fathership) set supertype: parentship
    When relation(fathership) create role: father
    When relation(fathership) get role(father); set override: parent
    When put entity type: person
    When entity(person) set plays role: parentship:parent
    When entity(person) set plays role: parentship:child
    When put entity type: man
    When entity(man) set supertype: person
    When entity(man) set plays role: fathership:father
    When entity(man) get plays role: fathership:father; set override: parentship:parent
    Then entity(man) get plays roles contain:
      | fathership:father |
      | parentship:child  |
    Then entity(man) get plays roles do not contain:
      | parentship:parent |
    Then entity(man) get plays roles explicit contain:
      | fathership:father |
    Then entity(man) get plays roles explicit do not contain:
      | parentship:child  |
      | parentship:parent |
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then entity(man) get plays roles contain:
      | fathership:father |
      | parentship:child  |
    Then entity(man) get plays roles do not contain:
      | parentship:parent |
    Then entity(man) get plays roles explicit contain:
      | fathership:father |
    Then entity(man) get plays roles explicit do not contain:
      | parentship:child  |
      | parentship:parent |
    When put relation type: mothership
    When relation(mothership) set supertype: parentship
    When relation(mothership) create role: mother
    When relation(mothership) get role(mother); set override: parent
    When put entity type: woman
    When entity(woman) set supertype: person
    When entity(woman) set plays role: mothership:mother
    When entity(woman) get plays role: mothership:mother; set override: parentship:parent
    Then entity(woman) get plays roles contain:
      | mothership:mother |
      | parentship:child  |
    Then entity(woman) get plays roles do not contain:
      | parentship:parent |
    Then entity(woman) get plays roles explicit contain:
      | mothership:mother |
    Then entity(woman) get plays roles explicit do not contain:
      | parentship:child  |
      | parentship:parent |
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(person) get plays roles contain:
      | parentship:parent |
      | parentship:child  |
    Then entity(man) get plays roles contain:
      | fathership:father |
      | parentship:child  |
    Then entity(man) get plays roles do not contain:
      | parentship:parent |
    Then entity(man) get plays roles explicit contain:
      | fathership:father |
    Then entity(man) get plays roles explicit do not contain:
      | parentship:child  |
      | parentship:parent |
    Then entity(woman) get plays roles contain:
      | mothership:mother |
      | parentship:child  |
    Then entity(woman) get plays roles do not contain:
      | parentship:parent |
    Then entity(woman) get plays roles explicit contain:
      | mothership:mother |
    Then entity(woman) get plays roles explicit do not contain:
      | parentship:child  |
      | parentship:parent |

  Scenario: Entity types can redeclare playing role types
    When put relation type: parentship
    When relation(parentship) create role: parent
    When put entity type: person
    When entity(person) set plays role: parentship:parent
    When transaction commits
    When connection opens schema transaction for database: typedb
    When entity(person) set plays role: parentship:parent

  Scenario: Entity types can re-override inherited playing role types
    When put relation type: parentship
    When relation(parentship) create role: parent
    When put relation type: fathership
    When relation(fathership) set supertype: parentship
    When relation(fathership) create role: father
    When relation(fathership) get role(father); set override: parent
    When put entity type: person
    When entity(person) set plays role: parentship:parent
    When put entity type: man
    When entity(man) set supertype: person
    When entity(man) set plays role: fathership:father
    When entity(man) get plays role: fathership:father; set override: parentship:parent
    When transaction commits
    When connection opens schema transaction for database: typedb
    When entity(man) set plays role: fathership:father
    When entity(man) get plays role: fathership:father; set override: parentship:parent

  Scenario: Entity types cannot redeclare inherited/overridden playing role types
    When put relation type: parentship
    When relation(parentship) create role: parent
    When put relation type: fathership
    When relation(fathership) set supertype: parentship
    When relation(fathership) create role: father
    When relation(fathership) get role(father); set override: parent
    When put entity type: person
    When entity(person) set plays role: parentship:parent
    When put entity type: man
    When entity(man) set supertype: person
    When entity(man) set plays role: fathership:father
    When entity(man) get plays role: fathership:father; set override: parentship:parent
    When put entity type: boy
    When entity(boy) set supertype: man
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then entity(boy) set plays role: parentship:parent; fails
    When connection opens schema transaction for database: typedb
    Then entity(boy) set plays role: fathership:father
    Then transaction commits; fails

  Scenario: Entity types cannot override declared playing role types
    When put relation type: parentship
    When relation(parentship) create role: parent
    When put relation type: fathership
    When relation(fathership) set supertype: parentship
    When relation(fathership) create role: father
    When relation(fathership) get role(father); set override: parent
    When put entity type: person
    When entity(person) set plays role: parentship:parent
    Then entity(person) set plays role: fathership:father
    Then entity(person) get plays role: fathership:father; set override: parentship:parent; fails

  Scenario: Entity types cannot override inherited playing role types other than with their subtypes
    When put relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) create role: child
    When put relation type: fathership
    When relation(fathership) create role: father
    When put entity type: person
    When entity(person) set plays role: parentship:parent
    When entity(person) set plays role: parentship:child
    When put entity type: man
    When entity(man) set supertype: person
    Then entity(man) set plays role: fathership:father
    Then entity(man) get plays role: fathership:father; set override: parentship:parent; fails
