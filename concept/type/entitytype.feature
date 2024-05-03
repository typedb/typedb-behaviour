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
    Then entity(person) exists: true
    Then entity(person) get supertype: entity
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(person) exists: true
    Then entity(person) get supertype: entity

  Scenario: Entity types can be deleted
    When put entity type: person
    Then entity(person) exists: true
    When put entity type: company
    Then entity(company) exists: true
    When delete entity type: company
    Then entity(company) exists: false
    Then entity(entity) get subtypes do not contain:
      | company |
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then entity(person) exists: true
    Then entity(company) exists: false
    Then entity(entity) get subtypes do not contain:
      | company |
    When delete entity type: person
    Then entity(person) exists: false
    Then entity(entity) get subtypes do not contain:
      | person  |
      | company |
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(person) exists: false
    Then entity(company) exists: false
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
    Then entity(person) exists: false
    Then entity(horse) exists: true
    Then entity(horse) get label: horse
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then entity(horse) get label: horse
    When entity(horse) set label: animal
    Then entity(horse) exists: false
    Then entity(animal) exists: true
    Then entity(animal) get label: animal
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(animal) exists: true
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
      | man    |
      | person |
      | animal |
    Then entity(woman) get supertypes contain:
      | entity |
      | woman  |
      | person |
      | animal |
    Then entity(person) get supertypes contain:
      | entity |
      | person |
      | animal |
    Then entity(cat) get supertypes contain:
      | entity |
      | cat    |
      | animal |
    Then entity(man) get subtypes contain:
      | man |
    Then entity(woman) get subtypes contain:
      | woman |
    Then entity(person) get subtypes contain:
      | person |
      | man    |
      | woman  |
    Then entity(cat) get subtypes contain:
      | cat |
    Then entity(animal) get subtypes contain:
      | animal |
      | cat    |
      | person |
      | man    |
      | woman  |
    Then entity(entity) get subtypes contain:
      | entity |
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
      | man    |
      | person |
      | animal |
    Then entity(woman) get supertypes contain:
      | entity |
      | woman  |
      | person |
      | animal |
    Then entity(person) get supertypes contain:
      | entity |
      | person |
      | animal |
    Then entity(cat) get supertypes contain:
      | entity |
      | cat    |
      | animal |
    Then entity(man) get subtypes contain:
      | man |
    Then entity(woman) get subtypes contain:
      | woman |
    Then entity(person) get subtypes contain:
      | person |
      | man    |
      | woman  |
    Then entity(cat) get subtypes contain:
      | cat |
    Then entity(animal) get subtypes contain:
      | animal |
      | cat    |
      | person |
      | man    |
      | woman  |
    Then entity(entity) get subtypes contain:
      | entity |
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

  Scenario: Entity types can have keys
    When put attribute type: email
    When attribute(email) set value-type: string
    When put attribute type: username
    When attribute(username) set value-type: string
    When put entity type: person
    When entity(person) set owns: email
    When entity(person) get owns: email, set annotation: key
    When entity(person) set owns: username
    When entity(person) get owns: username, set annotation: key
    Then entity(person) get owns, with annotations (DEPRECATED): key; contain:
      | email    |
      | username |
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(person) get owns, with annotations (DEPRECATED): key; contain:
      | email    |
      | username |

  Scenario: Entity types can only commit keys if every instance owns a distinct key
    When put attribute type: email
    When attribute(email) set value-type: string
    When put attribute type: username
    When attribute(username) set value-type: string
    When put entity type: person
    When entity(person) set owns: username
    When entity(person) get owns: username, set annotation: key
    Then transaction commits
    When connection opens write transaction for database: typedb
    When $a = entity(person) create new instance with key(username): alice
    When $b = entity(person) create new instance with key(username): bob
    Then transaction commits
    When connection opens schema transaction for database: typedb
    When entity(person) set owns: email
    When entity(person) get owns: email, set annotation: key; fails
    When connection opens schema transaction for database: typedb
    When entity(person) set owns: email
    Then transaction commits
    When connection opens write transaction for database: typedb
    When $a = entity(person) get instance with key(username): alice
    When $alice = attribute(email) as(string) put: alice@vaticle.com
    When entity $a set has: $alice
    When $b = entity(person) get instance with key(username): bob
    When $bob = attribute(email) as(string) put: bob@vaticle.com
    When entity $b set has: $bob
    Then transaction commits
    When connection opens schema transaction for database: typedb
    When entity(person) set owns: email
    When entity(person) get owns: email, set annotation: key
    Then entity(person) get owns, with annotations (DEPRECATED): key; contain:
      | email    |
      | username |
    Then transaction commits
    When connection opens read transaction for database: typedb
    Then entity(person) get owns, with annotations (DEPRECATED): key; contain:
      | email    |
      | username |

  Scenario: Entity types can unset keys
    When put attribute type: email
    When attribute(email) set value-type: string
    When put attribute type: username
    When attribute(username) set value-type: string
    When put entity type: person
    When entity(person) set owns: email
    When entity(person) get owns: email, set annotation: key
    When entity(person) set owns: username
    When entity(person) get owns: username, set annotation: key
    When entity(person) unset owns: email
    Then entity(person) get owns, with annotations (DEPRECATED): key; do not contain:
      | email |
    When transaction commits
    When connection opens schema transaction for database: typedb
    When entity(person) unset owns: username
    Then entity(person) get owns, with annotations (DEPRECATED): key; do not contain:
      | email    |
      | username |

  Scenario: Entity types cannot have keys of attributes that are not keyable
    When put attribute type: is-open
    When attribute(is-open) set value-type: boolean
    When put attribute type: age
    When attribute(age) set value-type: long
    When put attribute type: rating
    When attribute(rating) set value-type: double
    When put attribute type: name
    When attribute(name) set value-type: string
    When put attribute type: timestamp
    When attribute(timestamp) set value-type: datetime
    When put entity type: person
    When entity(person) set owns: age
    When entity(person) get owns: age, set annotation: key
    When entity(person) set owns: name
    When entity(person) get owns: name, set annotation: key
    When entity(person) set owns: timestamp
    When entity(person) get owns: timestamp, set annotation: key
    Then entity(person) set owns: is-open
    Then entity(person) get owns: is-open, set annotation: key
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then entity(person) set owns: rating
    Then entity(person) get owns: rating, set annotation: key; fails

  Scenario: Entity types can have attributes
    When put attribute type: name
    When attribute(name) set value-type: string
    When put attribute type: age
    When attribute(age) set value-type: long
    When put entity type: person
    When entity(person) set owns: name
    When entity(person) set owns: age
    Then entity(person) get owns contain:
      | name |
      | age  |
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(person) get owns contain:
      | name |
      | age  |

  Scenario: Entity types can unset owning attributes
    When put attribute type: name
    When attribute(name) set value-type: string
    When put attribute type: age
    When attribute(age) set value-type: long
    When put entity type: person
    When entity(person) set owns: name
    When entity(person) set owns: age
    When entity(person) unset owns: age
    Then entity(person) get owns do not contain:
      | age |
    When transaction commits
    When connection opens schema transaction for database: typedb
    When entity(person) unset owns: name
    Then entity(person) get owns do not contain:
      | name |
      | age  |

  Scenario: Entity types cannot unset owning attributes that are owned by existing instances
    When put attribute type: name
    When attribute(name) set value-type: string
    When put entity type: person
    When entity(person) set owns: name
    Then transaction commits
    When connection opens write transaction for database: typedb
    When $a = entity(person) create new instance
    When $alice = attribute(name) as(string) put: alice
    When entity $a set has: $alice
    Then transaction commits
    When connection opens schema transaction for database: typedb
    Then entity(person) unset owns: name; fails

  Scenario: Entity types can have keys and attributes
    When put attribute type: email
    When attribute(email) set value-type: string
    When put attribute type: username
    When attribute(username) set value-type: string
    When put attribute type: name
    When attribute(name) set value-type: string
    When put attribute type: age
    When attribute(age) set value-type: long
    When put entity type: person
    When entity(person) set owns: email
    When entity(person) get owns: email, set annotation: key
    When entity(person) set owns: username
    When entity(person) get owns: username, set annotation: key
    When entity(person) set owns: name
    When entity(person) set owns: age
    Then entity(person) get owns, with annotations (DEPRECATED): key; contain:
      | email    |
      | username |
    Then entity(person) get owns contain:
      | email    |
      | username |
      | name     |
      | age      |
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(person) get owns, with annotations (DEPRECATED): key; contain:
      | email    |
      | username |
    Then entity(person) get owns contain:
      | email    |
      | username |
      | name     |
      | age      |

  Scenario: Entity types can inherit keys and attributes
    When put attribute type: email
    When attribute(email) set value-type: string
    When put attribute type: name
    When attribute(name) set value-type: string
    When put attribute type: reference
    When attribute(reference) set value-type: string
    When put attribute type: rating
    When attribute(rating) set value-type: double
    When put entity type: person
    When entity(person) set owns: email
    When entity(person) get owns: email, set annotation: key
    When entity(person) set owns: name
    When put entity type: customer
    When entity(customer) set supertype: person
    When entity(customer) set owns: reference
    When entity(customer) get owns: reference, set annotation: key
    When entity(customer) set owns: rating
    Then entity(customer) get owns, with annotations (DEPRECATED): key; contain:
      | email     |
      | reference |
    Then entity(customer) get declared owns, with annotations (DEPRECATED): key; contain:
      | reference |
    Then entity(customer) get declared owns, with annotations (DEPRECATED): key; do not contain:
      | email     |
    Then entity(customer) get owns contain:
      | email     |
      | reference |
      | name      |
      | rating    |
    Then entity(customer) get declared owns contain:
      | reference |
      | rating    |
    Then entity(customer) get declared owns do not contain:
      | email     |
      | name      |
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then entity(customer) get owns, with annotations (DEPRECATED): key; contain:
      | email     |
      | reference |
    Then entity(customer) get declared owns, with annotations (DEPRECATED): key; contain:
      | reference |
    Then entity(customer) get declared owns, with annotations (DEPRECATED): key; do not contain:
      | email     |
    Then entity(customer) get owns contain:
      | email     |
      | reference |
      | name      |
      | rating    |
    Then entity(customer) get declared owns contain:
      | reference |
      | rating    |
    Then entity(customer) get declared owns do not contain:
      | email     |
      | name      |
    When put attribute type: license
    When attribute(license) set value-type: string
    When put attribute type: points
    When attribute(points) set value-type: double
    When put entity type: subscriber
    When entity(subscriber) set supertype: customer
    When entity(subscriber) set owns: license
    When entity(subscriber) get owns: license, set annotation: key
    When entity(subscriber) set owns: points
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(customer) get owns, with annotations (DEPRECATED): key; contain:
      | email     |
      | reference |
    Then entity(customer) get declared owns, with annotations (DEPRECATED): key; contain:
      | reference |
    Then entity(customer) get declared owns, with annotations (DEPRECATED): key; do not contain:
      | email     |
    Then entity(customer) get owns contain:
      | email     |
      | reference |
      | name      |
      | rating    |
    Then entity(customer) get declared owns contain:
      | reference |
      | rating    |
    Then entity(customer) get declared owns do not contain:
      | email     |
      | name      |
    Then entity(subscriber) get owns, with annotations (DEPRECATED): key; contain:
      | email     |
      | reference |
      | license   |
    Then entity(subscriber) get declared owns, with annotations (DEPRECATED): key; contain:
      | license   |
    Then entity(subscriber) get declared owns, with annotations (DEPRECATED): key; do not contain:
      | email     |
      | reference |
    Then entity(subscriber) get owns contain:
      | email     |
      | reference |
      | license   |
      | name      |
      | rating    |
      | points    |
    Then entity(subscriber) get declared owns contain:
      | license   |
      | points    |
    Then entity(subscriber) get declared owns do not contain:
      | email     |
      | reference |
      | name      |
      | rating    |

  Scenario: Entity types can inherit keys and attributes that are subtypes of each other
    When put attribute type: username
    When attribute(username) set value-type: string
    When attribute(username) set annotation: @abstract
    When put attribute type: score
    When attribute(score) set value-type: double
    When attribute(score) set annotation: @abstract
    When put attribute type: reference
    When attribute(reference) set value-type: string
    When attribute(reference) set annotation: @abstract
    When attribute(reference) set supertype: username
    When put attribute type: rating
    When attribute(rating) set value-type: double
    When attribute(rating) set annotation: @abstract
    When attribute(rating) set supertype: score
    When put entity type: person
    When entity(person) set annotation: @abstract
    When entity(person) set owns: username
    When entity(person) get owns: username, set annotation: key
    When entity(person) set owns: score
    When put entity type: customer
    When entity(customer) set annotation: @abstract
    When entity(customer) set supertype: person
    When entity(customer) set owns: reference
    When entity(customer) get owns: reference, set annotation: key
    When entity(customer) set owns: rating
    Then entity(customer) get owns, with annotations (DEPRECATED): key; contain:
      | username  |
      | reference |
    Then entity(customer) get declared owns, with annotations (DEPRECATED): key; contain:
      | reference |
    Then entity(customer) get declared owns, with annotations (DEPRECATED): key; do not contain:
      | username  |
    Then entity(customer) get owns contain:
      | username  |
      | reference |
      | score     |
      | rating    |
    Then entity(customer) get declared owns contain:
      | reference |
      | rating    |
    Then entity(customer) get declared owns do not contain:
      | username  |
      | score     |
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then entity(customer) get owns, with annotations (DEPRECATED): key; contain:
      | username  |
      | reference |
    Then entity(customer) get declared owns, with annotations (DEPRECATED): key; contain:
      | reference |
    Then entity(customer) get declared owns, with annotations (DEPRECATED): key; do not contain:
      | username  |
    Then entity(customer) get owns contain:
      | username  |
      | reference |
      | score     |
      | rating    |
    Then entity(customer) get declared owns contain:
      | reference |
      | rating    |
    Then entity(customer) get declared owns do not contain:
      | username  |
      | score     |
    When put attribute type: license
    When attribute(license) set value-type: string
    When attribute(license) set supertype: reference
    When put attribute type: points
    When attribute(points) set value-type: double
    When attribute(points) set supertype: rating
    When put entity type: subscriber
    When entity(subscriber) set annotation: @abstract
    When entity(subscriber) set supertype: customer
    When entity(subscriber) set owns: license
    When entity(subscriber) get owns: license, set annotation: key
    When entity(subscriber) set owns: points
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(customer) get owns, with annotations (DEPRECATED): key; contain:
      | username  |
      | reference |
    Then entity(customer) get declared owns, with annotations (DEPRECATED): key; contain:
      | reference |
    Then entity(customer) get declared owns, with annotations (DEPRECATED): key; do not contain:
      | username  |
    Then entity(customer) get owns contain:
      | username  |
      | reference |
      | score     |
      | rating    |
    Then entity(customer) get declared owns contain:
      | reference |
      | rating    |
    Then entity(customer) get declared owns do not contain:
      | username  |
      | score     |
    Then entity(subscriber) get owns, with annotations (DEPRECATED): key; contain:
      | username  |
      | reference |
      | license   |
    Then entity(subscriber) get declared owns, with annotations (DEPRECATED): key; contain:
      | license   |
    Then entity(subscriber) get declared owns, with annotations (DEPRECATED): key; do not contain:
      | username  |
      | reference |
    Then entity(subscriber) get owns contain:
      | username  |
      | reference |
      | license   |
      | score     |
      | rating    |
      | points    |
    Then entity(subscriber) get declared owns contain:
      | license   |
      | points    |
    Then entity(subscriber) get declared owns do not contain:
      | username  |
      | reference |
      | score     |
      | rating    |

  Scenario: Entity types can override inherited keys and attributes
    When put attribute type: username
    When attribute(username) set value-type: string
    When put attribute type: email
    When attribute(email) set value-type: string
    When attribute(email) set annotation: @abstract
    When put attribute type: name
    When attribute(name) set value-type: string
    When attribute(name) set annotation: @abstract
    When put attribute type: age
    When attribute(age) set value-type: long
    When put attribute type: reference
    When attribute(reference) set value-type: string
    When attribute(reference) set annotation: @abstract
    When put attribute type: work-email
    When attribute(work-email) set value-type: string
    When attribute(work-email) set supertype: email
    When put attribute type: nick-name
    When attribute(nick-name) set value-type: string
    When attribute(nick-name) set supertype: name
    When put attribute type: rating
    When attribute(rating) set value-type: double
    When attribute(rating) set annotation: @abstract
    When put entity type: person
    When entity(person) set annotation: @abstract
    When entity(person) set owns: username
    When entity(person) get owns: username, set annotation: key
    When entity(person) set owns: email
    When entity(person) get owns: email, set annotation: key
    When entity(person) set owns: name
    When entity(person) set owns: age
    When put entity type: customer
    When entity(customer) set annotation: @abstract
    When entity(customer) set supertype: person
    When entity(customer) set owns: reference
    When entity(customer) get owns: reference, set annotation: key
    When entity(customer) set owns: work-email as email
    When entity(customer) set owns: rating
    When entity(customer) set owns: nick-name as name
    Then entity(customer) get owns overridden attribute(work-email) get label: email
    Then entity(customer) get owns overridden attribute(nick-name) get label: name
    Then entity(customer) get owns, with annotations (DEPRECATED): key; contain:
      | username   |
      | reference  |
      | work-email |
    Then entity(customer) get owns, with annotations (DEPRECATED): key; do not contain:
      | email |
    Then entity(customer) get declared owns, with annotations (DEPRECATED): key; contain:
      | reference  |
      | work-email |
    Then entity(customer) get declared owns, with annotations (DEPRECATED): key; do not contain:
      | username   |
      | email      |
    Then entity(customer) get owns contain:
      | username   |
      | reference  |
      | work-email |
      | age        |
      | rating     |
      | nick-name  |
    Then entity(customer) get owns do not contain:
      | email |
      | name  |
    Then entity(customer) get declared owns contain:
      | reference  |
      | work-email |
      | rating     |
      | nick-name  |
    Then entity(customer) get declared owns do not contain:
      | username   |
      | age        |
      | email      |
      | name       |
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then entity(customer) get owns overridden attribute(work-email) get label: email
    Then entity(customer) get owns overridden attribute(nick-name) get label: name
    Then entity(customer) get owns, with annotations (DEPRECATED): key; contain:
      | username   |
      | reference  |
      | work-email |
    Then entity(customer) get owns, with annotations (DEPRECATED): key; do not contain:
      | email |
    Then entity(customer) get declared owns, with annotations (DEPRECATED): key; contain:
      | reference  |
      | work-email |
    Then entity(customer) get declared owns, with annotations (DEPRECATED): key; do not contain:
      | username   |
      | email      |
    Then entity(customer) get owns contain:
      | username   |
      | reference  |
      | work-email |
      | age        |
      | rating     |
      | nick-name  |
    Then entity(customer) get owns do not contain:
      | email |
      | name  |
    Then entity(customer) get declared owns contain:
      | reference  |
      | work-email |
      | rating     |
      | nick-name  |
    Then entity(customer) get declared owns do not contain:
      | username   |
      | age        |
      | email      |
      | name       |
    When put attribute type: license
    When attribute(license) set value-type: string
    When attribute(license) set supertype: reference
    When put attribute type: points
    When attribute(points) set value-type: double
    When attribute(points) set supertype: rating
    When put entity type: subscriber
    When entity(subscriber) set supertype: customer
    When entity(subscriber) set owns: license as reference
    When entity(subscriber) set owns: points as rating
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(customer) get owns, with annotations (DEPRECATED): key; contain:
      | username   |
      | reference  |
      | work-email |
    Then entity(customer) get owns, with annotations (DEPRECATED): key; do not contain:
      | email |
    Then entity(customer) get declared owns, with annotations (DEPRECATED): key; contain:
      | reference  |
      | work-email |
    Then entity(customer) get declared owns, with annotations (DEPRECATED): key; do not contain:
      | username   |
      | email      |
    Then entity(customer) get owns contain:
      | username   |
      | reference  |
      | work-email |
      | age        |
      | rating     |
      | nick-name  |
    Then entity(customer) get owns do not contain:
      | email |
      | name  |
    Then entity(customer) get declared owns contain:
      | reference  |
      | work-email |
      | rating     |
      | nick-name  |
    Then entity(customer) get declared owns do not contain:
      | username   |
      | age        |
      | email      |
      | name       |
    Then entity(subscriber) get owns overridden attribute(license) get label: reference
    Then entity(subscriber) get owns overridden attribute(points) get label: rating
    Then entity(subscriber) get owns, with annotations (DEPRECATED): key; contain:
      | username   |
      | license    |
      | work-email |
    Then entity(subscriber) get owns, with annotations (DEPRECATED): key; do not contain:
      | email     |
      | reference |
    Then entity(subscriber) get declared owns, with annotations (DEPRECATED): key; contain:
      | license    |
    Then entity(subscriber) get declared owns, with annotations (DEPRECATED): key; do not contain:
      | username   |
      | work-email |
      | email     |
      | reference |
    Then entity(subscriber) get owns contain:
      | username   |
      | license    |
      | work-email |
      | age        |
      | points     |
      | nick-name  |
    Then entity(subscriber) get owns do not contain:
      | email      |
      | references |
      | name       |
      | rating     |
    Then entity(subscriber) get declared owns contain:
      | license    |
      | points     |
    Then entity(subscriber) get declared owns do not contain:
      | username   |
      | work-email |
      | age        |
      | nick-name  |
      | email      |
      | references |
      | name       |
      | rating     |

  Scenario: Entity types can override inherited attributes as keys
    When put attribute type: name
    When attribute(name) set value-type: string
    When attribute(name) set annotation: @abstract
    When put attribute type: username
    When attribute(username) set value-type: string
    When attribute(username) set supertype: name
    When put entity type: person
    When entity(person) set annotation: @abstract
    When entity(person) set owns: name
    When put entity type: customer
    When entity(customer) set supertype: person
    When entity(customer) set owns: username as name
    When entity(customer) get owns: username as name, set annotation: key
    Then entity(customer) get owns overridden attribute(username) get label: name
    Then entity(customer) get owns, with annotations (DEPRECATED): key; contain:
      | username |
    Then entity(customer) get owns, with annotations (DEPRECATED): key; do not contain:
      | name |
    Then entity(customer) get owns contain:
      | username |
    Then entity(customer) get owns do not contain:
      | name |
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(customer) get owns overridden attribute(username) get label: name
    Then entity(customer) get owns, with annotations (DEPRECATED): key; contain:
      | username |
    Then entity(customer) get owns, with annotations (DEPRECATED): key; do not contain:
      | name |
    Then entity(customer) get owns contain:
      | username |
    Then entity(customer) get owns do not contain:
      | name |

  Scenario: Entity types can redeclare keys as keys
    When put attribute type: name
    When attribute(name) set value-type: string
    When put attribute type: email
    When attribute(email) set value-type: string
    When put entity type: person
    When entity(person) set owns: name
    When entity(person) get owns: name, set annotation: key
    When entity(person) set owns: email
    When entity(person) get owns: email, set annotation: key
    Then entity(person) set owns: name
    Then entity(person) get owns: name, set annotation: key
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then entity(person) set owns: email
    Then entity(person) get owns: email, set annotation: key

  Scenario: Entity types can redeclare attributes as attributes
    When put attribute type: name
    When attribute(name) set value-type: string
    When put attribute type: email
    When attribute(email) set value-type: string
    When put entity type: person
    When entity(person) set owns: name
    When entity(person) set owns: email
    Then entity(person) set owns: name
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then entity(person) set owns: email

  Scenario: Entity types can re-override keys
    When put attribute type: email
    When attribute(email) set value-type: string
    When attribute(email) set annotation: @abstract
    When put attribute type: work-email
    When attribute(work-email) set value-type: string
    When attribute(work-email) set supertype: email
    When put entity type: person
    When entity(person) set annotation: @abstract
    When entity(person) set owns: email
    When entity(person) get owns: email, set annotation: key
    When put entity type: customer
    When entity(customer) set annotation: @abstract
    When entity(customer) set supertype: person
    When entity(customer) set owns: work-email as email
    Then entity(customer) get owns overridden attribute(work-email) get label: email
    When transaction commits
    When connection opens schema transaction for database: typedb
    When entity(customer) set owns: work-email as email
    Then entity(customer) get owns overridden attribute(work-email) get label: email

  Scenario: Entity types can re-override attributes as attributes
    When put attribute type: name
    When attribute(name) set value-type: string
    When attribute(name) set annotation: @abstract
    When put attribute type: nick-name
    When attribute(nick-name) set value-type: string
    When attribute(nick-name) set supertype: name
    When put entity type: person
    When entity(person) set annotation: @abstract
    When entity(person) set owns: name
    When put entity type: customer
    When entity(customer) set annotation: @abstract
    When entity(customer) set supertype: person
    When entity(customer) set owns: nick-name as name
    Then entity(customer) get owns overridden attribute(nick-name) get label: name
    When transaction commits
    When connection opens schema transaction for database: typedb
    When entity(customer) set owns: nick-name as name
    Then entity(customer) get owns overridden attribute(nick-name) get label: name

  Scenario: Entity types can redeclare keys as attributes
    When put attribute type: name
    When attribute(name) set value-type: string
    When put attribute type: email
    When attribute(email) set value-type: string
    When put entity type: person
    When entity(person) set owns: name
    When entity(person) get owns: name, set annotation: key
    When entity(person) set owns: email
    When entity(person) get owns: email, set annotation: key
    Then entity(person) set owns: name
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then entity(person) set owns: email

  Scenario: Entity types can redeclare attributes as keys
    When put attribute type: name
    When attribute(name) set value-type: string
    When put attribute type: email
    When attribute(email) set value-type: string
    When put entity type: person
    When entity(person) set owns: name
    When entity(person) set owns: email
    Then entity(person) set owns: name
    Then entity(person) get owns: name, set annotation: key
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then entity(person) set owns: email
    Then entity(person) get owns: email, set annotation: key

  Scenario: Entity types can redeclare inherited attributes as keys (which will override)
    When put attribute type: email
    When attribute(email) set value-type: string
    When put entity type: person
    When entity(person) set owns: email
    Then entity(person) get owns overridden attribute(email) exists: false
    When put entity type: customer
    When entity(customer) set supertype: person
    Then entity(customer) set owns: email
    Then entity(customer) get owns: email, set annotation: key
    Then entity(customer) get owns overridden attribute(email) exists: true
    Then entity(customer) get owns overridden attribute(email) get label: email
    Then entity(customer) get owns, with annotations (DEPRECATED): key; contain:
      | email |
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then entity(customer) get owns, with annotations (DEPRECATED): key; contain:
      | email |
    When put entity type: subscriber
    When entity(subscriber) set supertype: person
    Then entity(subscriber) set owns: email
    Then entity(subscriber) get owns: email, set annotation: key
    Then entity(subscriber) get owns, with annotations (DEPRECATED): key; contain:
      | email |

  Scenario: Entity types cannot redeclare inherited attributes as attributes
    When put attribute type: email
    When attribute(email) set value-type: string
    When put attribute type: name
    When attribute(name) set value-type: string
    When put entity type: person
    When entity(person) set owns: name
    When put entity type: customer
    When entity(customer) set supertype: person
    Then entity(customer) set owns: name
    Then transaction commits; fails

  Scenario: Entity types cannot redeclare inherited keys as keys or attributes
    When put attribute type: email
    When attribute(email) set value-type: string
    When put attribute type: name
    When attribute(name) set value-type: string
    When put entity type: person
    When entity(person) set owns: email
    When entity(person) get owns: email, set annotation: key
    When put entity type: customer
    When entity(customer) set supertype: person
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then entity(customer) set owns: email
    Then transaction commits; fails
    Then transaction closes
    When connection opens schema transaction for database: typedb
    Then entity(customer) set owns: email
    Then entity(customer) get owns: email, set annotation: key
    Then transaction commits; fails

  Scenario: Entity types cannot redeclare inherited key attribute types
    When put attribute type: email
    When attribute(email) set value-type: string
    When attribute(email) set annotation: @abstract
    When put attribute type: customer-email
    When attribute(customer-email) set value-type: string
    When attribute(customer-email) set supertype: email
    When put entity type: person
    When entity(person) set annotation: @abstract
    When entity(person) set owns: email
    When entity(person) get owns: email, set annotation: key
    When put entity type: customer
    When entity(customer) set supertype: person
    When entity(customer) set owns: customer-email
    When entity(customer) get owns: customer-email, set annotation: key
    When put entity type: subscriber
    When entity(subscriber) set supertype: customer
    Then entity(subscriber) set owns: email
    Then entity(subscriber) get owns: email, set annotation: key
    Then transaction commits; fails

  Scenario: Entity types cannot redeclare overridden key attribute types
    When put attribute type: email
    When attribute(email) set value-type: string
    When attribute(email) set annotation: @abstract
    When put attribute type: customer-email
    When attribute(customer-email) set value-type: string
    When attribute(customer-email) set supertype: email
    When put entity type: person
    When entity(person) set annotation: @abstract
    When entity(person) set owns: email
    When entity(person) get owns: email, set annotation: key
    When put entity type: customer
    When entity(customer) set supertype: person
    When entity(customer) set owns: customer-email
    When entity(customer) get owns: customer-email, set annotation: key
    When put entity type: subscriber
    When entity(subscriber) set supertype: customer
    Then entity(subscriber) set owns: customer-email
    Then entity(subscriber) get owns: customer-email, set annotation: key
    Then transaction commits; fails

  Scenario: Entity types cannot redeclare inherited owns attribute types
    When put attribute type: name
    When attribute(name) set value-type: string
    When attribute(name) set annotation: @abstract
    When put attribute type: customer-name
    When attribute(customer-name) set value-type: string
    When attribute(customer-name) set supertype: name
    When put entity type: person
    When entity(person) set annotation: @abstract
    When entity(person) set owns: name
    When put entity type: customer
    When entity(customer) set supertype: person
    When entity(customer) set owns: customer-name
    When put entity type: subscriber
    When entity(subscriber) set supertype: customer
    Then entity(subscriber) set owns: name
    Then transaction commits; fails

  Scenario: Entity types cannot redeclare overridden owns attribute types
    When put attribute type: name
    When attribute(name) set value-type: string
    When attribute(name) set annotation: @abstract
    When put attribute type: customer-name
    When attribute(customer-name) set value-type: string
    When attribute(customer-name) set supertype: name
    When put entity type: person
    When entity(person) set annotation: @abstract
    When entity(person) set owns: name
    When put entity type: customer
    When entity(customer) set supertype: person
    When entity(customer) set owns: customer-name
    When put entity type: subscriber
    When entity(subscriber) set supertype: customer
    Then entity(subscriber) set owns: customer-name
    Then transaction commits; fails

  Scenario: Entity types cannot override declared keys and attributes
    When put attribute type: username
    When attribute(username) set value-type: string
    When attribute(username) set annotation: @abstract
    When put attribute type: email
    When attribute(email) set value-type: string
    When attribute(email) set supertype: username
    When put attribute type: name
    When attribute(name) set value-type: string
    When attribute(name) set annotation: @abstract
    When put attribute type: first-name
    When attribute(first-name) set value-type: string
    When attribute(first-name) set supertype: name
    When put entity type: person
    When entity(person) set annotation: @abstract
    When entity(person) set owns: username
    When entity(person) get owns: username, set annotation: key
    When entity(person) set owns: name
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then entity(person) set owns: email as username
    Then entity(person) get owns: email as username, set annotation: key; fails
    When connection opens schema transaction for database: typedb
    Then entity(person) set owns: first-name as name; fails

  Scenario: Entity types cannot override inherited keys and attributes other than with their subtypes
    When put attribute type: username
    When attribute(username) set value-type: string
    When put attribute type: name
    When attribute(name) set value-type: string
    When put attribute type: reference
    When attribute(reference) set value-type: string
    When put attribute type: rating
    When attribute(rating) set value-type: double
    When put entity type: person
    When entity(person) set owns: username
    When entity(person) get owns: username, set annotation: key
    When entity(person) set owns: name
    When put entity type: customer
    When entity(customer) set supertype: person
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then entity(customer) set owns: reference as username
    Then entity(customer) get owns: reference as username, set annotation: key; fails
    When connection opens schema transaction for database: typedb
    Then entity(customer) set owns: rating as name; fails

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
    When relation(fathership) create role: father as parent
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
    When relation(mothership) create role: mother as parent
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
    When relation(fathership) create role: father as parent
    When put entity type: person
    When entity(person) set plays role: parentship:parent
    When entity(person) set plays role: parentship:child
    When put entity type: man
    When entity(man) set supertype: person
    When entity(man) set plays role: fathership:father as parentship:parent
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
    When relation(mothership) create role: mother as parent
    When put entity type: woman
    When entity(woman) set supertype: person
    When entity(woman) set plays role: mothership:mother as parentship:parent
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
    When relation(fathership) create role: father as parent
    When put entity type: person
    When entity(person) set plays role: parentship:parent
    When put entity type: man
    When entity(man) set supertype: person
    When entity(man) set plays role: fathership:father as parentship:parent
    When transaction commits
    When connection opens schema transaction for database: typedb
    When entity(man) set plays role: fathership:father as parentship:parent

  Scenario: Entity types cannot redeclare inherited/overridden playing role types
    When put relation type: parentship
    When relation(parentship) create role: parent
    When put relation type: fathership
    When relation(fathership) set supertype: parentship
    When relation(fathership) create role: father as parent
    When put entity type: person
    When entity(person) set plays role: parentship:parent
    When put entity type: man
    When entity(man) set supertype: person
    When entity(man) set plays role: fathership:father as parentship:parent
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
    When relation(fathership) create role: father as parent
    When put entity type: person
    When entity(person) set plays role: parentship:parent
    Then entity(person) set plays role: fathership:father as parentship:parent; fails

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
    Then entity(man) set plays role: fathership:father as parentship:parent; fails
