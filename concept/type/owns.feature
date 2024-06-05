# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: Concept Owns

  Background:
    Given typedb starts
    # TODO: "open" or "opens"?
    Given connection opens with default authentication
    Given connection has been opened
    Given connection does not have any database
    # TODO: "create" or "createS"?
    Given connection create database: typedb
    # TODO: "open" or "opens"?
    Given connection opens schema transaction for database: typedb
    # TODO: Create structs in concept api
    Given put struct type: custom-struct
    Given struct(custom-struct) create field: custom-field
    Given struct(custom-struct) get field(custom-field); set value-type: string
    Given transaction commits
    Given connection opens schema transaction for database: typedb

  Scenario Outline: Entity types can own and unset attributes
    When put attribute type: name
    When attribute(name) set value-type: <value-type>
    When put attribute type: surname
    When attribute(surname) set value-type: <value-type>
    When put attribute type: birthday
    When attribute(birthday) set value-type: <value-type-2>
    When put entity type: person
    When entity(person) set owns: name
    When entity(person) set owns: birthday
    When entity(person) set owns: surname
    Then entity(person) get owns contain:
      | name     |
      | surname  |
      | birthday |
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then entity(person) get owns contain:
      | name     |
      | surname  |
      | birthday |
    When entity(person) unset owns: surname
    Then entity(person) get owns do not contain:
      | surname |
    Then entity(person) get owns contain:
      | name     |
      | birthday |
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then entity(person) get owns contain:
      | name     |
      | birthday |
    When entity(person) unset owns: birthday
    Then entity(person) get owns do not contain:
      | birthday |
    Then entity(person) get owns contain:
      | name |
    When entity(person) unset owns: name
    Then entity(person) get owns do not contain:
      | name     |
      | surname  |
      | birthday |
    Then entity(person) get owns is empty
    Examples:
      | value-type    | value-type-2 |
      | long          | string       |
      | double        | datetimetz   |
      | decimal       | datetime     |
      | string        | duration     |
      | boolean       | long         |
      | datetime      | decimal      |
      | datetimetz    | double       |
      | duration      | boolean      |
      | custom-struct | long         |

  Scenario Outline: Entity types can redeclare owning attributes
    When put attribute type: name
    When attribute(name) set value-type: <value-type>
    When put attribute type: email
    When attribute(email) set value-type: <value-type>
    When put entity type: person
    When entity(person) set owns: name
    When entity(person) set owns: email
    Then entity(person) set owns: name
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then entity(person) set owns: email
    Examples:
      | value-type    |
      | long          |
      | double        |
      | decimal       |
      | string        |
      | boolean       |
      | datetime      |
      | datetimetz    |
      | duration      |
      | custom-struct |

  Scenario Outline: Entity types cannot unset owning attributes that are owned by existing instances
    When put attribute type: name
    When attribute(name) set value-type: <value-type>
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
    Then entity(person) get owns contain: name
    Examples:
      | value-type    |
      | long          |
      | double        |
      | decimal       |
      | string        |
      | boolean       |
      | datetime      |
      | datetimetz    |
      | duration      |
      | custom-struct |

  Scenario: Entity types can not own entities, relations, roles, structs, and structs fields
    When put entity type: car
    When put relation type: credit
    When relation(marriage) create role: creditor
    # TODO: Create structs in concept api
    When put struct type: passport
    When struct(passport) create field: first-name
    When struct(passport) get field(first-name); set value-type: string
    When struct(passport) create field: surname
    When struct(passport) get field(surname); set value-type: string
    When struct(passport) create field: birthday
    When struct(passport) get field(birthday); set value-type: datetime
    When put entity type: person
    Then entity(person) set owns: car; fails
    Then entity(person) set owns: credit; fails
    Then entity(person) set owns: marriage:creditor; fails
    Then entity(person) set owns: passport; fails
    Then entity(person) set owns: passport:birthday; fails
    Then entity(person) get owns is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(person) get owns is empty

  Scenario Outline: Relation types can own attributes
    When put attribute type: license
    When attribute(license) set value-type: <value-type>
    When put attribute type: starting-date
    When attribute(starting-date) set value-type: <value-type>
    When put attribute type: comment
    When attribute(comment) set value-type: <value-type-2>
    When put relation type: marriage
    When relation(marriage) create role: spouse
    When relation(marriage) set owns: license
    When relation(marriage) set owns: starting-date
    When relation(marriage) set owns: comment
    Then relation(marriage) get owns contain:
      | license       |
      | starting-date |
      | comment       |
    When transaction commits
    When connection opens read transaction for database: typedb
    Then relation(marriage) get owns contain:
      | license       |
      | starting-date |
      | comment       |
    When relation(marriage) unset owns: starting-date
    Then relation(marriage) get owns do not contain:
      | starting-date |
    Then relation(marriage) get owns contain:
      | license |
      | comment |
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then relation(marriage) get owns contain:
      | license |
      | comment |
    When relation(marriage) unset owns: license
    Then relation(marriage) get owns do not contain:
      | license |
    Then relation(marriage) get owns contain:
      | comment |
    When relation(marriage) unset owns: comment
    Then relation(marriage) get owns do not contain:
      | license       |
      | starting-date |
      | comment       |
    Then relation(marriage) get owns is empty
    Examples:
      | value-type    | value-type-2 |
      | long          | string       |
      | double        | datetimetz   |
      | decimal       | datetime     |
      | string        | duration     |
      | boolean       | long         |
      | datetime      | decimal      |
      | datetimetz    | double       |
      | duration      | boolean      |
      | custom-struct | long         |

  Scenario Outline: Relation types can redeclare owning attributes
    When put attribute type: name
    When attribute(name) set value-type: <value-type>
    When put attribute type: email
    When attribute(email) set value-type: <value-type>
    When put relation type: reference
    When relation(reference) create role: target
    When relation(reference) set owns: name
    When relation(reference) set owns: email
    Then relation(reference) set owns: name
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then relation(reference) set owns: email
    Examples:
      | value-type    |
      | long          |
      | double        |
      | decimal       |
      | string        |
      | boolean       |
      | datetime      |
      | datetimetz    |
      | duration      |
      | custom-struct |

  Scenario: Relation types can not own entities, relations, roles, structs, and structs fields
    When put entity type: person
    When put relation type: credit
    When relation(marriage) create role: creditor
    When put relation type: marriage
    When relation(marriage) create role: spouse
    # TODO: Create structs in concept api
    When put struct type: passport-document
    When struct(passport-document) create field: first-name
    When struct(passport-document) get field(first-name); set value-type: string
    When struct(passport-document) create field: surname
    When struct(passport-document) get field(surname); set value-type: string
    When struct(passport-document) create field: birthday
    When struct(passport-document) get field(birthday); set value-type: datetime
    Then relation(marriage) set owns: person; fails
    Then relation(marriage) set owns: credit; fails
    Then relation(marriage) set owns: marriage:creditor; fails
    Then relation(marriage) set owns: passport; fails
    Then relation(marriage) set owns: passport:birthday; fails
    Then relation(marriage) set owns: marriage:spouse; fails
    Then relation(marriage) get owns is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then relation(marriage) get owns is empty

  Scenario: Attribute types can not own entities, attributes, relations, roles, structs, and structs fields
    When put entity type: person
    When put attribute type: surname
    When put relation type: marriage
    When relation(marriage) create role: spouse
    When attribute(surname) set value-type: string
    # TODO: Create structs in concept api
    When put struct type: passport
    When struct(passport) create field: first-name
    When struct(passport) get field(first-name); set value-type: string
    When struct(passport) create field: surname
    When struct(passport) get field(surname); set value-type: string
    When struct(passport) create field: birthday
    When struct(passport) get field(birthday); set value-type: datetime
    When put attribute type: name
    When attribute(name) set value-type: string
    Then attribute(name) set owns: person; fails
    Then attribute(name) set owns: surname; fails
    Then attribute(name) set owns: marriage; fails
    Then attribute(name) set owns: marriage:spouse; fails
    Then attribute(name) set owns: passport; fails
    Then attribute(name) set owns: passport:birthday; fails
    Then attribute(name) get owns is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then attribute(name) get owns is empty

  Scenario: Struct types can not own entities, attributes, relations, roles, structs, and structs fields
    When put entity type: person
    When put attribute type: name
    When put relation type: marriage
    When relation(marriage) create role: spouse
    When attribute(surname) set value-type: string
    # TODO: Create structs in concept api
    When put struct type: passport
    When struct(passport) create field: first-name
    When struct(passport) get field(first-name); set value-type: string
    When struct(passport) create field: surname
    When struct(passport) get field(surname); set value-type: string
    When struct(passport) create field: birthday
    When struct(passport) get field(birthday); set value-type: datetime
    # TODO: Create structs in concept api
    When put struct type: wallet
    When struct(wallet) create field: currency
    When struct(wallet) get field(currency); set value-type: string
    When struct(wallet) create field: value
    When struct(wallet) get field(value); set value-type: double
    Then struct(wallet) set owns: person; fails
    Then struct(wallet) set owns: name; fails
    Then struct(wallet) set owns: marriage; fails
    Then struct(wallet) set owns: marriage:spouse; fails
    Then struct(wallet) set owns: passport; fails
    Then struct(wallet) set owns: passport:birthday; fails
    Then struct(wallet) set owns: wallet:currency; fails
    Then struct(wallet) get owns is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then struct(wallet) get owns is empty

#################
# Entity owns
#################

  # TODO: Maybe adapt to all annotations
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
    When entity(customer) set owns: username
    When entity(customer) get owns: username; set override: name
    When entity(customer) get owns: username, set annotation: @key
    Then entity(customer) get owns overridden(username) get label: name
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
    Then entity(customer) get owns overridden(username) get label: name
    Then entity(customer) get owns, with annotations (DEPRECATED): key; contain:
      | username |
    Then entity(customer) get owns, with annotations (DEPRECATED): key; do not contain:
      | name |
    Then entity(customer) get owns contain:
      | username |
    Then entity(customer) get owns do not contain:
      | name |

    # TODO: Can set twice? Add tests for all the annotations!
  Scenario: Entity types can redeclare keys as keys
    When put attribute type: name
    When attribute(name) set value-type: string
    When put attribute type: email
    When attribute(email) set value-type: string
    When put entity type: person
    When entity(person) set owns: name
    When entity(person) get owns: name, set annotation: @key
    When entity(person) set owns: email
    When entity(person) get owns: email, set annotation: @key
    Then entity(person) set owns: name
    Then entity(person) get owns: name, set annotation: @key
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then entity(person) set owns: email
    Then entity(person) get owns: email, set annotation: @key

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
    When entity(person) get owns: email, set annotation: @key
    When put entity type: customer
    When entity(customer) set annotation: @abstract
    When entity(customer) set supertype: person
    When entity(customer) set owns: work-email
    When entity(customer) get owns: work-email; set override: email
    Then entity(customer) get owns overridden(work-email) get label: email
    When transaction commits
    When connection opens schema transaction for database: typedb
    When entity(customer) set owns: work-email
    When entity(customer) get owns: work-email; set override: email
    Then entity(customer) get owns overridden(work-email) get label: email

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
    When entity(customer) set owns: nick-name
    When entity(customer) get owns: nick-name; set override: name
    Then entity(customer) get owns overridden(nick-name) get label: name
    When transaction commits
    When connection opens schema transaction for database: typedb
    When entity(customer) set owns: nick-name
    When entity(customer) get owns: nick-name; set override: name
    Then entity(customer) get owns overridden(nick-name) get label: name

  Scenario: Entity types can redeclare keys as attributes
    When put attribute type: name
    When attribute(name) set value-type: string
    When put attribute type: email
    When attribute(email) set value-type: string
    When put entity type: person
    When entity(person) set owns: name
    When entity(person) get owns: name, set annotation: @key
    When entity(person) set owns: email
    When entity(person) get owns: email, set annotation: @key
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
    Then entity(person) get owns: name, set annotation: @key
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then entity(person) set owns: email
    Then entity(person) get owns: email, set annotation: @key

  Scenario: Entity types can redeclare inherited attributes as keys (which will override)
    When put attribute type: email
    When attribute(email) set value-type: string
    When put entity type: person
    When entity(person) set owns: email
    Then entity(person) get owns overridden(email) does not exist
    When put entity type: customer
    When entity(customer) set supertype: person
    Then entity(customer) set owns: email
    Then entity(customer) get owns: email, set annotation: @key
    Then entity(customer) get owns overridden(email) exists
    Then entity(customer) get owns overridden(email) get label: email
    Then entity(customer) get owns, with annotations (DEPRECATED): key; contain:
      | email |
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then entity(customer) get owns, with annotations (DEPRECATED): key; contain:
      | email |
    When put entity type: subscriber
    When entity(subscriber) set supertype: person
    Then entity(subscriber) set owns: email
    Then entity(subscriber) get owns: email, set annotation: @key
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
    When entity(person) get owns: email, set annotation: @key
    When put entity type: customer
    When entity(customer) set supertype: person
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then entity(customer) set owns: email
    Then transaction commits; fails
    Then transaction closes
    When connection opens schema transaction for database: typedb
    Then entity(customer) set owns: email
    Then entity(customer) get owns: email, set annotation: @key
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
    When entity(person) get owns: email, set annotation: @key
    When put entity type: customer
    When entity(customer) set supertype: person
    When entity(customer) set owns: customer-email
    When entity(customer) get owns: customer-email, set annotation: @key
    When put entity type: subscriber
    When entity(subscriber) set supertype: customer
    Then entity(subscriber) set owns: email
    Then entity(subscriber) get owns: email, set annotation: @key
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
    When entity(person) get owns: email, set annotation: @key
    When put entity type: customer
    When entity(customer) set supertype: person
    When entity(customer) set owns: customer-email
    When entity(customer) get owns: customer-email, set annotation: @key
    When put entity type: subscriber
    When entity(subscriber) set supertype: customer
    Then entity(subscriber) set owns: customer-email
    Then entity(subscriber) get owns: customer-email, set annotation: @key
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
    When entity(person) get owns: username, set annotation: @key
    When entity(person) set owns: name
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then entity(person) set owns: email
    Then entity(person) get owns: email; set override: username
    Then entity(person) get owns: email, set annotation: @key; fails
    When connection opens schema transaction for database: typedb
    Then entity(person) set owns: first-name
    Then entity(person) get owns: first-name; set override: name

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
    When entity(person) get owns: username, set annotation: @key
    When entity(person) set owns: name
    When put entity type: customer
    When entity(customer) set supertype: person
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then entity(customer) set owns: reference
    Then entity(customer) get owns: reference, set annotation: @key
    Then entity(customer) get owns: reference; set override: username; fails
    When connection opens schema transaction for database: typedb
    Then entity(customer) set owns: rating
    Then entity(customer) get owns: rating; set override: name

#################
# @key
#################

  Scenario Outline: Owns can set @key annotation for <value-type> value type and unset it
    When put entity type: person
    When put attribute type: custom-attribute
    When attribute(custom-attribute) set value-type: <value-type>
    When entity(person) set owns: custom-attribute
    When entity(person) get owns: custom-attribute, set annotation: @key
    Then entity(person) get owns: custom-attribute; get annotations contain: @key
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then entity(person) get owns: custom-attribute; get annotations contain: @key
    When entity(person) unset owns: custom-attribute
    Then entity(person) get owns is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(person) get owns is empty
    Examples:
      | value-type |
      | long       |
      | string     |
      | boolean    |
      | datetime   |
      | datetimetz |
      | duration   |

  Scenario Outline: Owns can not set @key annotation for <value-type> as it is not keyable
    When put entity type: person
    When put attribute type: custom-attribute
    When attribute(custom-attribute) set value-type: <value-type>
    When entity(person) set owns: custom-attribute
    When entity(person) get owns: custom-attribute, set annotation: @key
    Then entity(person) get owns: custom-attribute; get annotations contain: @key
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then entity(person) get owns: custom-attribute; get annotations contain: @key
    When entity(person) unset owns: custom-attribute
    Then entity(person) get owns is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(person) get owns is empty
    Examples:
      | value-type    |
      | double        |
      | decimal       |
      | custom-struct |

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
    When entity(person) get owns: email, set annotation: @key
    When entity(person) set owns: username
    When entity(person) get owns: username, set annotation: @key
    When entity(person) set owns: name
    When entity(person) set owns: age
    Then entity(person) get owns: email; get annotations contain: @key
    Then entity(person) get owns: username; get annotations contain: @key
    Then entity(person) get owns contain:
      | email    |
      | username |
      | name     |
      | age      |
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(person) get owns: email; get annotations contain: @key
    Then entity(person) get owns: username; get annotations contain: @key
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
    When entity(person) get owns: email, set annotation: @key
    When entity(person) set owns: name
    When put entity type: customer
    When entity(customer) set supertype: person
    When entity(customer) set owns: reference
    When entity(customer) get owns: reference, set annotation: @key
    When entity(customer) set owns: rating
    Then entity(customer) get owns contain:
      | email     |
      | reference |
      | name      |
      | rating    |
    Then entity(customer) get declared owns contain:
      | reference |
      | rating    |
    Then entity(customer) get declared owns do not contain:
      | email |
      | name  |
    Then entity(customer) get owns: email; get annotations contain: @key
    Then entity(customer) get owns: reference; get annotations contain: @key
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then entity(customer) get owns contain:
      | email     |
      | reference |
      | name      |
      | rating    |
    Then entity(customer) get declared owns contain:
      | reference |
      | rating    |
    Then entity(customer) get declared owns do not contain:
      | email |
      | name  |
    Then entity(customer) get owns: email; get annotations contain: @key
    Then entity(customer) get owns: reference; get annotations contain: @key
    When put attribute type: license
    When attribute(license) set value-type: string
    When put attribute type: points
    When attribute(points) set value-type: double
    When put entity type: subscriber
    When entity(subscriber) set supertype: customer
    When entity(subscriber) set owns: license
    When entity(subscriber) get owns: license, set annotation: @key
    When entity(subscriber) set owns: points
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(customer) get owns contain:
      | email     |
      | reference |
      | name      |
      | rating    |
    Then entity(customer) get declared owns contain:
      | reference |
      | rating    |
    Then entity(customer) get declared owns do not contain:
      | email |
      | name  |
    Then entity(customer) get owns: email; get annotations contain: @key
    Then entity(customer) get owns: reference; get annotations contain: @key
    Then entity(subscriber) get owns: email; get annotations contain: @key
    Then entity(subscriber) get owns: reference; get annotations contain: @key
    Then entity(subscriber) get owns: license; get annotations contain: @key
    Then entity(subscriber) get owns contain:
      | email     |
      | reference |
      | license   |
      | name      |
      | rating    |
      | points    |
    Then entity(subscriber) get declared owns contain:
      | license |
      | points  |
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
    When entity(person) get owns: username, set annotation: @key
    When entity(person) set owns: score
    When put entity type: customer
    When entity(customer) set annotation: @abstract
    When entity(customer) set supertype: person
    When entity(customer) set owns: reference
    When entity(customer) get owns: reference, set annotation: @key
    When entity(customer) set owns: rating
    Then entity(customer) get owns contain:
      | username  |
      | reference |
      | score     |
      | rating    |
    Then entity(customer) get declared owns contain:
      | reference |
      | rating    |
    Then entity(customer) get declared owns do not contain:
      | username |
      | score    |
    Then entity(customer) get owns: username; get annotations contain: @key
    Then entity(customer) get owns: reference; get annotations contain: @key
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then entity(customer) get owns contain:
      | username  |
      | reference |
      | score     |
      | rating    |
    Then entity(customer) get declared owns contain:
      | reference |
      | rating    |
    Then entity(customer) get declared owns do not contain:
      | username |
      | score    |
    Then entity(customer) get owns: username; get annotations contain: @key
    Then entity(customer) get owns: reference; get annotations contain: @key
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
    When entity(subscriber) get owns: license, set annotation: @key
    When entity(subscriber) set owns: points
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(customer) get owns contain:
      | username  |
      | reference |
      | score     |
      | rating    |
    Then entity(customer) get declared owns contain:
      | reference |
      | rating    |
    Then entity(customer) get declared owns do not contain:
      | username |
      | score    |
    Then entity(customer) get owns: username; get annotations contain: @key
    Then entity(customer) get owns: reference; get annotations contain: @key
    Then entity(subscriber) get owns contain:
      | username  |
      | reference |
      | license   |
      | score     |
      | rating    |
      | points    |
    Then entity(subscriber) get declared owns contain:
      | license |
      | points  |
    Then entity(subscriber) get declared owns do not contain:
      | username  |
      | reference |
      | score     |
      | rating    |
    Then entity(subscriber) get owns: username; get annotations contain: @key
    Then entity(subscriber) get owns: reference; get annotations contain: @key
    Then entity(subscriber) get owns: license; get annotations contain: @key

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
    When entity(person) get owns: username, set annotation: @key
    When entity(person) set owns: email
    When entity(person) get owns: email, set annotation: @key
    When entity(person) set owns: name
    When entity(person) set owns: age
    When put entity type: customer
    When entity(customer) set annotation: @abstract
    When entity(customer) set supertype: person
    When entity(customer) set owns: reference
    When entity(customer) get owns: reference, set annotation: @key
    When entity(customer) set owns: work-email
    When entity(customer) get owns: work-email; set override: email
    When entity(customer) set owns: rating
    When entity(customer) set owns: nick-name
    When entity(customer) get owns: nick-name; set override: name
    Then entity(customer) get owns overridden(work-email) get label: email
    Then entity(customer) get owns overridden(nick-name) get label: name
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
      | username |
      | age      |
      | email    |
      | name     |
    Then entity(customer) get owns: username; get annotations contain: @key
    Then entity(customer) get owns: reference; get annotations contain: @key
    Then entity(customer) get owns: work-email; get annotations contain: @key
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then entity(customer) get owns overridden(work-email) get label: email
    Then entity(customer) get owns overridden(nick-name) get label: name
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
      | username |
      | age      |
      | email    |
      | name     |
    Then entity(customer) get owns: username; get annotations contain: @key
    Then entity(customer) get owns: reference; get annotations contain: @key
    Then entity(customer) get owns: work-email; get annotations contain: @key
    When put attribute type: license
    When attribute(license) set value-type: string
    When attribute(license) set supertype: reference
    When put attribute type: points
    When attribute(points) set value-type: double
    When attribute(points) set supertype: rating
    When put entity type: subscriber
    When entity(subscriber) set supertype: customer
    When entity(subscriber) set owns: license
    When entity(subscriber) get owns: license; set override: reference
    When entity(subscriber) set owns: points
    When entity(subscriber) get owns: points; set override: rating
    When transaction commits
    When connection opens read transaction for database: typedb
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
      | username |
      | age      |
      | email    |
      | name     |
    Then entity(customer) get owns: username; get annotations contain: @key
    Then entity(customer) get owns: reference; get annotations contain: @key
    Then entity(customer) get owns: work-email; get annotations contain: @key
    Then entity(subscriber) get owns overridden(license) get label: reference
    Then entity(subscriber) get owns overridden(points) get label: rating
    Then entity(subscriber) get owns contain:
      | username   |
      | license    |
      | work-email |
      | age        |
      | points     |
      | nick-name  |
    Then entity(subscriber) get owns do not contain:
      | email     |
      | reference |
      | name      |
      | rating    |
    Then entity(subscriber) get declared owns contain:
      | license |
      | points  |
    Then entity(subscriber) get declared owns do not contain:
      | username   |
      | work-email |
      | age        |
      | nick-name  |
      | email      |
      | reference  |
      | name       |
      | rating     |
    Then entity(subscriber) get owns: username; get annotations contain: @key
    Then entity(subscriber) get owns: license; get annotations contain: @key
    Then entity(subscriber) get owns: work-email; get annotations contain: @key

  # TODO: Move to thing?
  Scenario: Entity types can only commit keys if every instance owns a distinct key
    When put attribute type: email
    When attribute(email) set value-type: string
    When put attribute type: username
    When attribute(username) set value-type: string
    When put entity type: person
    When entity(person) set owns: username
    When entity(person) get owns: username, set annotation: @key
    Then transaction commits
    When connection opens write transaction for database: typedb
    When $a = entity(person) create new instance with key(username): alice
    When $b = entity(person) create new instance with key(username): bob
    Then transaction commits
    When connection opens schema transaction for database: typedb
    When entity(person) set owns: email
    When entity(person) get owns: email, set annotation: @key; fails
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
    When entity(person) get owns: email, set annotation: @key
    Then entity(person) get owns: email; get annotations contain: @key
    Then entity(person) get owns: username; get annotations contain: @key
    Then transaction commits
    When connection opens read transaction for database: typedb
    Then entity(person) get owns: email; get annotations contain: @key
    Then entity(person) get owns: username; get annotations contain: @key


  # TODO


#################
# @subkey
#################
  # TODO



#################
# @unique
#################

  Scenario Outline: Owns can set @unique annotation for <value-type> value type and unset it
    When put entity type: person
    When put attribute type: custom-attribute
    When attribute(custom-attribute) set value-type: <value-type>
    When entity(person) set owns: custom-attribute
    When entity(person) get owns: custom-attribute, set annotation: @unique
    Then entity(person) get owns: custom-attribute; get annotations contain: @unique
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then entity(person) get owns: custom-attribute; get annotations contain: @unique
    When entity(person) unset owns: custom-attribute
    Then entity(person) get owns is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(person) get owns is empty
    Examples:
      | value-type    |
      | long          |
      | string        |
      | boolean       |
      | double        |
      | decimal       |
      | datetime      |
      | datetimetz    |
      | duration      |
      | custom-struct |

  # TODO


#################
# @values
#################

  Scenario Outline: Owns can set @values annotation for <value-type> value type and unset it
    When put entity type: person
    When put attribute type: custom-attribute
    When attribute(custom-attribute) set value-type: <value-type>
    When entity(person) set owns: custom-attribute
    When entity(person) get owns: custom-attribute, set annotation: @values(<args>)
    Then entity(person) get owns: custom-attribute; get annotations contain: @values(<args>)
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then entity(person) get owns: custom-attribute; get annotations contain: @values(<args>)
    When entity(person) unset owns: custom-attribute
    Then entity(person) get owns is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(person) get owns is empty
    Examples:
      | value-type | args                                                                                                                                                                                                                                                                                                                                                                                                 |
      | long       | 0                                                                                                                                                                                                                                                                                                                                                                                                    |
      | long       | 1                                                                                                                                                                                                                                                                                                                                                                                                    |
      | long       | -1                                                                                                                                                                                                                                                                                                                                                                                                   |
      | long       | 1, 2                                                                                                                                                                                                                                                                                                                                                                                                 |
      | long       | -9223372036854775808, 9223372036854775807                                                                                                                                                                                                                                                                                                                                                            |
      | long       | 2, 1, 3, 4, 5, 6, 7, 9, 10, 11, 55, -1, -654321, 123456                                                                                                                                                                                                                                                                                                                                              |
      | long       | 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99 |
      | string     | ""                                                                                                                                                                                                                                                                                                                                                                                                   |
      | string     | "1"                                                                                                                                                                                                                                                                                                                                                                                                  |
      | string     | "福"                                                                                                                                                                                                                                                                                                                                                                                                  |
      | string     | "s", "S"                                                                                                                                                                                                                                                                                                                                                                                             |
      | string     | "This rank contains a sufficiently detailed description of its nature"                                                                                                                                                                                                                                                                                                                               |
      | string     | "Scout", "Stone Guard", "Stone Guard", "High Warlord"                                                                                                                                                                                                                                                                                                                                                |
      | string     | "Rank with optional space", "Rank with optional space ", " Rank with optional space", "Rankwithoptionalspace", "Rank with optional space  "                                                                                                                                                                                                                                                          |
      | boolean    | true                                                                                                                                                                                                                                                                                                                                                                                                 |
      | boolean    | false                                                                                                                                                                                                                                                                                                                                                                                                |
      | boolean    | false, true                                                                                                                                                                                                                                                                                                                                                                                          |
      | double     | 0.0                                                                                                                                                                                                                                                                                                                                                                                                  |
      | double     | 0                                                                                                                                                                                                                                                                                                                                                                                                    |
      | double     | 1.1                                                                                                                                                                                                                                                                                                                                                                                                  |
      | double     | -2.45                                                                                                                                                                                                                                                                                                                                                                                                |
      | double     | -3.444, 3.445                                                                                                                                                                                                                                                                                                                                                                                        |
      | double     | 0.00001, 0.0001, 0.001, 0.01                                                                                                                                                                                                                                                                                                                                                                         |
      | double     | -333.553, 33895, 98984.4555, 902394.44, 1000000000, 0.00001, 0.3, 3.14159265358979323                                                                                                                                                                                                                                                                                                                |
      | decimal    | 0.0                                                                                                                                                                                                                                                                                                                                                                                                  |
      | decimal    | 0                                                                                                                                                                                                                                                                                                                                                                                                    |
      | decimal    | 1.1                                                                                                                                                                                                                                                                                                                                                                                                  |
      | decimal    | -2.45                                                                                                                                                                                                                                                                                                                                                                                                |
      | decimal    | -3.444, 3.445                                                                                                                                                                                                                                                                                                                                                                                        |
      | decimal    | 0.00001, 0.0001, 0.001, 0.01                                                                                                                                                                                                                                                                                                                                                                         |
      | decimal    | -333.553, 33895, 98984.4555, 902394.44, 1000000000, 0.00001, 0.3, 3.14159265358979323                                                                                                                                                                                                                                                                                                                |
      | datetime   | 2024-06-04                                                                                                                                                                                                                                                                                                                                                                                           |
      | datetime   | 2024-06-04T16:35                                                                                                                                                                                                                                                                                                                                                                                     |
      | datetime   | 2024-06-04T16:35:02                                                                                                                                                                                                                                                                                                                                                                                  |
      | datetime   | 2024-06-04T16:35:02.1                                                                                                                                                                                                                                                                                                                                                                                |
      | datetime   | 2024-06-04T16:35:02.10                                                                                                                                                                                                                                                                                                                                                                               |
      | datetime   | 2024-06-04T16:35:02.103                                                                                                                                                                                                                                                                                                                                                                              |
      | datetime   | 2024-06-04, 2024-06-04T16:35, 2024-06-04T16:35:02, 2024-06-04T16:35:02.1, 2024-06-04T16:35:02.10, 2024-06-04T16:35:02.103                                                                                                                                                                                                                                                                            |
      | datetimetz | 2024-06-04+0000                                                                                                                                                                                                                                                                                                                                                                                      |
      | datetimetz | 2024-06-04 Asia/Kathmandu                                                                                                                                                                                                                                                                                                                                                                            |
      | datetimetz | 2024-06-04+0100                                                                                                                                                                                                                                                                                                                                                                                      |
      | datetimetz | 2024-06-04T16:35+0100                                                                                                                                                                                                                                                                                                                                                                                |
      | datetimetz | 2024-06-04T16:35:02+0100                                                                                                                                                                                                                                                                                                                                                                             |
      | datetimetz | 2024-06-04T16:35:02.1+0100                                                                                                                                                                                                                                                                                                                                                                           |
      | datetimetz | 2024-06-04T16:35:02.10+0100                                                                                                                                                                                                                                                                                                                                                                          |
      | datetimetz | 2024-06-04T16:35:02.103+0100                                                                                                                                                                                                                                                                                                                                                                         |
      | datetimetz | 2024-06-04+0001, 2024-06-04 Asia/Kathmandu, 2024-06-04+0002, 2024-06-04+0010, 2024-06-04+0100, 2024-06-04-0100, 2024-06-04T16:35-0100, 2024-06-04T16:35:02+0200, 2024-06-04T16:35:02.1-0300, 2024-06-04T16:35:02.10+1000, 2024-06-04T16:35:02.103+0011                                                                                                                                               |
      | duration   | P1Y                                                                                                                                                                                                                                                                                                                                                                                                  |
      | duration   | P2M                                                                                                                                                                                                                                                                                                                                                                                                  |
      | duration   | P1Y2M                                                                                                                                                                                                                                                                                                                                                                                                |
      | duration   | P1Y2M3D                                                                                                                                                                                                                                                                                                                                                                                              |
      | duration   | P1Y2M3DT4H                                                                                                                                                                                                                                                                                                                                                                                           |
      | duration   | P1Y2M3DT4H5M                                                                                                                                                                                                                                                                                                                                                                                         |
      | duration   | P1Y2M3DT4H5M6S                                                                                                                                                                                                                                                                                                                                                                                       |
      | duration   | P1Y2M3DT4H5M6.789S                                                                                                                                                                                                                                                                                                                                                                                   |
      | duration   | P1Y, P1Y1M, P1Y1M1D, P1Y1M1DT1H, P1Y1M1DT1H1M, P1Y1M1DT1H1M1S, 1Y1M1DT1H1M1S0.1S, 1Y1M1DT1H1M1S0.001S, 1Y1M1DT1H1M0.000001S                                                                                                                                                                                                                                                                          |

  Scenario: Owns can set @values annotation for struct value type
    # TODO: Do we want to have it? If we do, add it to other Scenario Outlines with different value types

  Scenario Outline: Owns can not have @values annotation with empty args
    When put entity type: person
    When put attribute type: custom-attribute
    When attribute(custom-attribute) set value-type: <value-type>
    When entity(person) set owns: custom-attribute
    Then entity(person) get owns: custom-attribute, set annotation: @values(); fails
    Then entity(person) get owns: custom-attribute; get annotations is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(person) get owns: custom-attribute; get annotations is empty
    Examples:
      | value-type |
      | long       |
      | double     |
      | decimal    |
      | string     |
      | boolean    |
      | datetime   |
      | datetimetz |
      | duration   |

  Scenario Outline: Owns can not have @values annotation for <value-type> value type with args of invalid value or type
    When put entity type: person
    When put attribute type: custom-attribute
    When attribute(custom-attribute) set value-type: <value-type>
    When entity(player) set owns: custom-attribute
    Then entity(player) get owns: custom-attribute, set annotation: @values(<args>); fails
    Then entity(player) get owns: custom-attribute; get annotations is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(player) get owns: custom-attribute; get annotations is empty
    Examples:
      | value-type | args                            |
      | long       | 0.1                             |
      | long       | "string"                        |
      | long       | true                            |
      | long       | 2024-06-04                      |
      | long       | 2024-06-04+0010                 |
      | double     | "string"                        |
      | double     | true                            |
      | double     | 2024-06-04                      |
      | double     | 2024-06-04+0010                 |
      | decimal    | "string"                        |
      | decimal    | true                            |
      | decimal    | 2024-06-04                      |
      | decimal    | 2024-06-04+0010                 |
      | string     | 123                             |
      | string     | true                            |
      | string     | 2024-06-04                      |
      | string     | 2024-06-04+0010                 |
      | string     | 'notstring'                     |
      | boolean    | 123                             |
      | boolean    | "string"                        |
      | boolean    | 2024-06-04                      |
      | boolean    | 2024-06-04+0010                 |
      | boolean    | truefalse                       |
      | datetime   | 123                             |
      | datetime   | "string"                        |
      | datetime   | true                            |
      | datetime   | 2024-06-04+0010                 |
      | datetimetz | 123                             |
      | datetimetz | "string"                        |
      | datetimetz | true                            |
      | datetimetz | 2024-06-04                      |
      | datetimetz | 2024-06-04 NotRealTimeZone/Zone |
      | duration   | 123                             |
      | duration   | "string"                        |
      | duration   | true                            |
      | duration   | 2024-06-04                      |
      | duration   | 2024-06-04+0100                 |
      | duration   | 1Y                              |
      | duration   | year                            |

  Scenario Outline: Owns can not have @values annotation for <value-type> value type with duplicated args
    When put entity type: person
    When put attribute type: custom-attribute
    When attribute(custom-attribute) set value-type: <value-type>
    When entity(player) set owns: custom-attribute
    Then entity(player) get owns: custom-attribute, set annotation: @values(<arg0>, <arg1>, <arg2>); fails
    Then entity(player) get owns: custom-attribute; get annotations is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(player) get owns: custom-attribute; get annotations is empty
    Examples:
      | value-type | arg0                        | arg1                         | arg2                         |
      | long       | 1                           | 1                            | 1                            |
      | long       | 1                           | 1                            | 2                            |
      | long       | 1                           | 2                            | 1                            |
      | long       | 1                           | 2                            | 2                            |
      | double     | 0.1                         | 0.0001                       | 0.0001                       |
      | decimal    | 0.1                         | 0.0001                       | 0.0001                       |
      | string     | "stringwithoutdifferences"  | "stringwithoutdifferences"   | "stringWITHdifferences"      |
      | string     | "stringwithoutdifferences " | "stringwithoutdifferences  " | "stringwithoutdifferences  " |
      | boolean    | true                        | true                         | false                        |
      | datetime   | 2024-06-04T16:35:02.101     | 2024-06-04T16:35:02.101      | 2024-06-04                   |
      | datetime   | 2020-06-04T16:35:02.10      | 2025-06-05T16:35             | 2025-06-05T16:35             |
      | datetimetz | 2020-06-04T16:35:02.10+0100 | 2020-06-04T16:35:02.10+0000  | 2020-06-04T16:35:02.10+0100  |
      | duration   | P1Y1M                       | P1Y1M                        | P1Y2M                        |

  Scenario Outline: Owns-related @values annotation for <value-type> value type can be inherited and overridden by a subset of args
    When put entity type: person
    When put relation type: contract
    When relation(contract) create role: participant
    When put attribute type: custom-attribute
    When attribute(custom-attribute) set value-type: <value-type>
    When put attribute type: second-custom-attribute
    When attribute(second-custom-attribute) set value-type: <value-type>
    When entity(person) set owns: custom-attribute
    When relation(contract) set owns: custom-attribute
    When entity(person) set owns: second-custom-attribute
    When relation(contract) set owns: second-custom-attribute
    When entity(person) get owns: custom-attribute, set annotation: @values(<args>)
    When relation(contract) get owns: custom-attribute, set annotation: @values(<args>)
    Then entity(person) get owns: custom-attribute; get annotations contain: @values(<args>)
    Then relation(contract) get owns: custom-attribute; get annotations contain: @values(<args>)
    When entity(person) get owns: second-custom-attribute, set annotation: @values(<args>)
    When relation(contract) get owns: second-custom-attribute, set annotation: @values(<args>)
    Then entity(person) get owns: second-custom-attribute; get annotations contain: @values(<args>)
    Then relation(contract) get owns: second-custom-attribute; get annotations contain: @values(<args>)
    When put entity type: player
    When put relation type: marriage
    When entity(player) set supertype: person
    When relation(marriage) set supertype: contract
    Then entity(player) get owns contain: custom-attribute
    Then relation(marriage) get owns contain: custom-attribute
    Then entity(player) get owns: custom-attribute, get annotations contain: @values(<args>)
    Then relation(marriage) get owns: custom-attribute, get annotations contain: @values(<args>)
    Then entity(player) get owns contain: second-custom-attribute
    Then relation(marriage) get owns contain: second-custom-attribute
    # TODO: Overrides? Remove second-custom-attribute from test if we remove overrides!
    When entity(player) get owns: second-custom-attribute; set override: overridden-custom-attribute
    When relation(marriage) get owns: second-custom-attribute; set override: overridden-custom-attribute
    Then entity(player) get owns do not contain: second-custom-attribute
    Then relation(marriage) get owns do not contain: second-custom-attribute
    Then entity(player) get owns contain: overridden-custom-attribute
    Then relation(marriage) get owns contain: overridden-custom-attribute
    Then entity(player) get owns: overridden-custom-attribute, get annotations contain: @values(<args>)
    Then relation(marriage) get owns: overridden-custom-attribute, get annotations contain: @values(<args>)
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then entity(player) get owns: custom-attribute, get annotations contain: @values(<args>)
    Then relation(marriage) get owns: custom-attribute, get annotations contain: @values(<args>)
    Then entity(player) get owns: overridden-custom-attribute, get annotations contain: @values(<args>)
    Then relation(marriage) get owns: overridden-custom-attribute, get annotations contain: @values(<args>)
    When entity(player) get owns: custom-attribute, set annotation: @values(<args-override>)
    When relation(marriage) get owns: custom-attribute, set annotation: @values(<args-override>)
    Then entity(player) get owns: custom-attribute, get annotations contain: @values(<args-override>)
    Then relation(marriage) get owns: custom-attribute, get annotations contain: @values(<args-override>)
    When entity(player) get owns: overridden-custom-attribute, set annotation: @values(<args-override>)
    When relation(marriage) get owns: overridden-custom-attribute, set annotation: @values(<args-override>)
    Then entity(player) get owns: overridden-custom-attribute, get annotations contain: @values(<args-override>)
    Then relation(marriage) get owns: overridden-custom-attribute, get annotations contain: @values(<args-override>)
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(player) get owns: custom-attribute, get annotations contain: @values(<args-override>)
    Then relation(marriage) get owns: custom-attribute, get annotations contain: @values(<args-override>)
    Then entity(player) get owns: overridden-custom-attribute, get annotations contain: @values(<args-override>)
    Then relation(marriage) get owns: overridden-custom-attribute, get annotations contain: @values(<args-override>)
    Examples:
      | value-type | args                                                                         | args-override                              |
      | long       | 1, 10, 20, 30                                                                | 10, 30                                     |
      | double     | 1.0, 2.0, 3.0, 4.5                                                           | 2.0                                        |
      | decimal    | 0.0, 1.0                                                                     | 0.0                                        |
      | string     | "john", "John", "Johnny", "johnny"                                           | "John", "Johnny"                           |
      | boolean    | true, false                                                                  | true                                       |
      | datetime   | 2024-06-04, 2024-06-05, 2024-06-06                                           | 2024-06-04, 2024-06-06                     |
      | datetimetz | 2024-06-04+0010, 2024-06-04 Asia/Kathmandu, 2024-06-05+0010, 2024-06-05+0100 | 2024-06-04 Asia/Kathmandu, 2024-06-05+0010 |
      | duration   | P6M, P1Y, P1Y1M, P1Y2M, P1Y3M, P1Y4M, P1Y6M                                  | P6M, P1Y3M, P1Y4M, P1Y6M                   |

  Scenario Outline: Inherited @values annotation on owns for <value-type> value type can not be overridden by the @values of same args or not a subset of args
    When put entity type: person
    When put relation type: contract
    When relation(contract) create role: participant
    When put attribute type: custom-attribute
    When attribute(custom-attribute) set value-type: <value-type>
    When put attribute type: second-custom-attribute
    When attribute(second-custom-attribute) set value-type: <value-type>
    When entity(person) set owns: custom-attribute
    When relation(contract) set owns: custom-attribute
    When entity(person) set owns: second-custom-attribute
    When relation(contract) set owns: second-custom-attribute
    When entity(person) get owns: custom-attribute, set annotation: @values(<args>)
    When relation(contract) get owns: custom-attribute, set annotation: @values(<args>)
    Then entity(person) get owns: custom-attribute; get annotations contain: @values(<args>)
    Then relation(contract) get owns: custom-attribute; get annotations contain: @values(<args>)
    When entity(person) get owns: second-custom-attribute, set annotation: @values(<args>)
    When relation(contract) get owns: second-custom-attribute, set annotation: @values(<args>)
    Then entity(person) get owns: second-custom-attribute; get annotations contain: @values(<args>)
    Then relation(contract) get owns: second-custom-attribute; get annotations contain: @values(<args>)
    When put entity type: player
    When put relation type: marriage
    When entity(player) set supertype: person
    When relation(marriage) set supertype: contract
    Then entity(player) get owns: custom-attribute, get annotations contain: @values(<args>)
    Then relation(marriage) get owns: custom-attribute, get annotations contain: @values(<args>)
    # TODO: Overrides? Remove second-custom-attribute from test if we remove overrides!
    When entity(player) get owns: second-custom-attribute; set override: overridden-custom-attribute
    When relation(marriage) get owns: second-custom-attribute; set override: overridden-custom-attribute
    Then entity(player) get owns: overridden-custom-attribute, get annotations contain: @values(<args>)
    Then relation(marriage) get owns: overridden-custom-attribute, get annotations contain: @values(<args>)
    Then entity(player) get owns: custom-attribute, set annotation: @values(<args>); fails
    Then relation(marriage) get owns: custom-attribute, set annotation: @values(<args>); fails
    Then entity(player) get owns: overridden-custom-attribute, set annotation: @values(<args>); fails
    Then relation(marriage) get owns: overridden-custom-attribute, set annotation: @values(<args>); fails
    Then entity(player) get owns: custom-attribute, set annotation: @values(<args-override>); fails
    Then relation(marriage) get owns: custom-attribute, set annotation: @values(<args-override>); fails
    Then entity(player) get owns: overridden-custom-attribute, set annotation: @values(<args-override>); fails
    Then relation(marriage) get owns: overridden-custom-attribute, set annotation: @values(<args-override>); fails
    Then entity(player) get owns: custom-attribute, get annotations contain: @values(<args>)
    Then relation(marriage) get owns: custom-attribute, get annotations contain: @values(<args>)
    Then entity(player) get owns: overridden-custom-attribute, get annotations contain: @values(<args>)
    Then relation(marriage) get owns: overridden-custom-attribute, get annotations contain: @values(<args>)
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then entity(player) get owns: custom-attribute, get annotations contain: @values(<args>)
    Then relation(marriage) get owns: custom-attribute, get annotations contain: @values(<args>)
    Then entity(player) get owns: overridden-custom-attribute, get annotations contain: @values(<args>)
    Then relation(marriage) get owns: overridden-custom-attribute, get annotations contain: @values(<args>)
    Examples:
      | value-type | args                                                                         | args-override            |
      | long       | 1, 10, 20, 30                                                                | 10, 31                   |
      | double     | 1.0, 2.0, 3.0, 4.5                                                           | 2.001                    |
      | decimal    | 0.0, 1.0                                                                     | 0.01                     |
      | string     | "john", "John", "Johnny", "johnny"                                           | "Jonathan"               |
      | boolean    | false                                                                        | true                     |
      | datetime   | 2024-06-04, 2024-06-05, 2024-06-06                                           | 2020-06-04, 2020-06-06   |
      | datetimetz | 2024-06-04+0010, 2024-06-04 Asia/Kathmandu, 2024-06-05+0010, 2024-06-05+0100 | 2024-06-04 Europe/London |
      | duration   | P6M, P1Y, P1Y1M, P1Y2M, P1Y3M, P1Y4M, P1Y6M                                  | P3M, P1Y3M, P1Y4M, P1Y6M |

#################
# @range
#################

  Scenario Outline: Owns can set @range annotation for <value-type> value type in correct order and unset it
    When put entity type: person
    When put attribute type: custom-attribute
    When attribute(custom-attribute) set value-type: <value-type>
    When entity(person) set owns: custom-attribute
    Then entity(player) get owns: custom-attribute, set annotation: @range(<arg1>, <arg0>); fails
    Then entity(person) get owns: custom-attribute; get annotations is empty
    When entity(person) get owns: custom-attribute, set annotation: @range(<arg0>, <arg1>)
    Then entity(person) get owns: custom-attribute; get annotations contain: @range(<arg0>, <arg1>)
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then entity(person) get owns: custom-attribute; get annotations contain: @range(<arg0>, <arg1>)
    When entity(person) unset owns: custom-attribute
    Then entity(person) get owns is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(person) get owns is empty
    Examples:
      | value-type | arg0                         | arg1                                                  |
      | long       | 0                            | 1                                                     |
      | long       | 1                            | 2                                                     |
      | long       | 0                            | 2                                                     |
      | long       | -1                           | 1                                                     |
      | long       | -9223372036854775808         | 9223372036854775807                                   |
      | string     | "A"                          | "a"                                                   |
      | string     | "a"                          | "z"                                                   |
      | string     | "A"                          | "福"                                                   |
      | string     | "AA"                         | "AAA"                                                 |
      | string     | "short string"               | "very-very-very-very-very-very-very-very long string" |
      | boolean    | false                        | true                                                  |
      | double     | 0.0                          | 0.0001                                                |
      | double     | 0.01                         | 1.0                                                   |
      | double     | 123.123                      | 123123123123.122                                      |
      | double     | -2.45                        | 2.45                                                  |
      | decimal    | 0.0                          | 0.0001                                                |
      | decimal    | 0.01                         | 1.0                                                   |
      | decimal    | 123.123                      | 123123123123.122                                      |
      | decimal    | -2.45                        | 2.45                                                  |
      | datetime   | 2024-06-04                   | 2024-06-05                                            |
      | datetime   | 2024-06-04                   | 2024-07-03                                            |
      | datetime   | 2024-06-04                   | 2025-01-01                                            |
      | datetime   | 1970-01-01                   | 9999-12-12                                            |
      | datetime   | 2024-06-04T16:35:02.10       | 2024-06-04T16:35:02.11                                |
      | datetimetz | 2024-06-04+0000              | 2024-06-05+0000                                       |
      | datetimetz | 2024-06-04+0100              | 2048-06-04+0100                                       |
      | datetimetz | 2024-06-04T16:35:02.103+0100 | 2024-06-04T16:35:02.104+0100                          |
      | datetimetz | 2024-06-04 Asia/Kathmandu    | 2024-06-05 Asia/Kathmandu                             |
      | duration   | P1Y                          | P2Y                                                   |
      | duration   | P2M                          | P1Y2M                                                 |
      | duration   | P1Y2M                        | P1Y2M3DT4H5M6.789S                                    |
      | duration   | P1Y2M3DT4H5M6.788S           | P1Y2M3DT4H5M6.789S                                    |

  Scenario: Owns can set @range annotation for struct value type
    # TODO: Do we want to have it? If we do, add it to other Scenario Outlines with different value types

  Scenario Outline: Owns can not have @range annotation for <value-type> value type with less than two args
    When put entity type: person
    When put attribute type: custom-attribute
    When attribute(custom-attribute) set value-type: <value-type>
    When entity(person) set owns: custom-attribute
    Then entity(person) get owns: custom-attribute, set annotation: @range(); fails
    Then entity(person) get owns: custom-attribute, set annotation: @range(<arg0>); fails
    Then entity(person) get owns: custom-attribute; get annotations is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(person) get owns: custom-attribute; get annotations is empty
    Examples:
      | value-type | arg0            |
      | long       | 1               |
      | double     | 1.0             |
      | decimal    | 1.0             |
      | string     | "1"             |
      | boolean    | false           |
      | datetime   | 2024-06-04      |
      | datetimetz | 2024-06-04+0100 |
      | duration   | P1Y             |

    # TODO: If we allow arg0 == arg1, move this case to another test!
  Scenario Outline: Owns can not have @range annotation for <value-type> value type with invalid args or args number
    When put entity type: person
    When put attribute type: custom-attribute
    When attribute(custom-attribute) set value-type: <value-type>
    When entity(player) set owns: custom-attribute
    Then entity(player) get owns: custom-attribute, set annotation: @range(<arg0>, <args>); fails
    Then entity(player) get owns: custom-attribute; get annotations is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(player) get owns: custom-attribute; get annotations is empty
    Examples:
      | value-type | arg0                            | args                                               |
      | long       | 1                               | 1                                                  |
      | long       | 1                               | 2, 3                                               |
      | long       | 1                               | "string"                                           |
      | long       | 1                               | 2, "string"                                        |
      | long       | 1                               | 2, "string", true, 2024-06-04, 55                  |
      | long       | "string"                        | 1                                                  |
      | long       | true                            | 1                                                  |
      | long       | 2024-06-04                      | 1                                                  |
      | long       | 2024-06-04+0010                 | 1                                                  |
      | double     | 1.0                             | 1.0                                                |
      | double     | 1.0                             | 2.0, 3.0                                           |
      | double     | 1.0                             | "string"                                           |
      | double     | "string"                        | 1.0                                                |
      | double     | true                            | 1.0                                                |
      | double     | 2024-06-04                      | 1.0                                                |
      | double     | 2024-06-04+0010                 | 1.0                                                |
      | decimal    | 1.0                             | 1.0                                                |
      | decimal    | 1.0                             | 2.0, 3.0                                           |
      | decimal    | 1.0                             | "string"                                           |
      | decimal    | "string"                        | 1.0                                                |
      | decimal    | true                            | 1.0                                                |
      | decimal    | 2024-06-04                      | 1.0                                                |
      | decimal    | 2024-06-04+0010                 | 1.0                                                |
      | string     | "123"                           | "123"                                              |
      | string     | "123"                           | "1234", "12345"                                    |
      | string     | "123"                           | 123                                                |
      | string     | 123                             | "123"                                              |
      | string     | true                            | "str"                                              |
      | string     | 2024-06-04                      | "str"                                              |
      | string     | 2024-06-04+0010                 | "str"                                              |
      | string     | 'notstring'                     | "str"                                              |
      | boolean    | false                           | false                                              |
      | boolean    | true                            | true                                               |
      | boolean    | true                            | 123                                                |
      | boolean    | 123                             | true                                               |
      | boolean    | "string"                        | true                                               |
      | boolean    | 2024-06-04                      | true                                               |
      | boolean    | 2024-06-04+0010                 | true                                               |
      | boolean    | truefalse                       | true                                               |
      | datetime   | 2030-06-04                      | 2030-06-04                                         |
      | datetime   | 2030-06-04                      | 2030-06-05, 2030-06-06                             |
      | datetime   | 2030-06-04                      | 123                                                |
      | datetime   | 123                             | 2030-06-04                                         |
      | datetime   | "string"                        | 2030-06-04                                         |
      | datetime   | true                            | 2030-06-04                                         |
      | datetime   | 2024-06-04+0010                 | 2030-06-04                                         |
      | datetimetz | 2030-06-04 Europe/London        | 2030-06-04 Europe/London                           |
      | datetimetz | 2030-06-04 Europe/London        | 2030-06-05 Europe/London, 2030-06-06 Europe/London |
      | datetimetz | 2030-06-05 Europe/London        | 123                                                |
      | datetimetz | 123                             | 2030-06-05 Europe/London                           |
      | datetimetz | "string"                        | 2030-06-05 Europe/London                           |
      | datetimetz | true                            | 2030-06-05 Europe/London                           |
      | datetimetz | 2024-06-04                      | 2030-06-05 Europe/London                           |
      | datetimetz | 2024-06-04 NotRealTimeZone/Zone | 2030-06-05 Europe/London                           |
      | duration   | P1Y                             | P1Y                                                |
      | duration   | P1Y                             | P2Y, P3Y                                           |
      | duration   | P1Y                             | 123                                                |
      | duration   | 123                             | P1Y                                                |
      | duration   | "string"                        | P1Y                                                |
      | duration   | true                            | P1Y                                                |
      | duration   | 2024-06-04                      | P1Y                                                |
      | duration   | 2024-06-04+0100                 | P1Y                                                |
      | duration   | 1Y                              | P1Y                                                |
      | duration   | year                            | P1Y                                                |

  Scenario Outline: Owns-related @range annotation for <value-type> value type can be inherited and overridden by a subset of args
    When put entity type: person
    When put relation type: contract
    When relation(contract) create role: participant
    When put attribute type: custom-attribute
    When attribute(custom-attribute) set value-type: <value-type>
    When put attribute type: second-custom-attribute
    When attribute(second-custom-attribute) set value-type: <value-type>
    When entity(person) set owns: custom-attribute
    When relation(contract) set owns: custom-attribute
    When entity(person) set owns: second-custom-attribute
    When relation(contract) set owns: second-custom-attribute
    When entity(person) get owns: custom-attribute, set annotation: @range(<args>)
    When relation(contract) get owns: custom-attribute, set annotation: @range(<args>)
    Then entity(person) get owns: custom-attribute; get annotations contain: @range(<args>)
    Then relation(contract) get owns: custom-attribute; get annotations contain: @range(<args>)
    When entity(person) get owns: second-custom-attribute, set annotation: @range(<args>)
    When relation(contract) get owns: second-custom-attribute, set annotation: @range(<args>)
    Then entity(person) get owns: second-custom-attribute; get annotations contain: @range(<args>)
    Then relation(contract) get owns: second-custom-attribute; get annotations contain: @range(<args>)
    When put entity type: player
    When put relation type: marriage
    When entity(player) set supertype: person
    When relation(marriage) set supertype: contract
    Then entity(player) get owns contain: custom-attribute
    Then relation(marriage) get owns contain: custom-attribute
    Then entity(player) get owns: custom-attribute, get annotations contain: @range(<args>)
    Then relation(marriage) get owns: custom-attribute, get annotations contain: @range(<args>)
    Then entity(player) get owns contain: second-custom-attribute
    Then relation(marriage) get owns contain: second-custom-attribute
    # TODO: Overrides? Remove second-custom-attribute from test if we remove overrides!
    When entity(player) get owns: second-custom-attribute; set override: overridden-custom-attribute
    When relation(marriage) get owns: second-custom-attribute; set override: overridden-custom-attribute
    Then entity(player) get owns do not contain: second-custom-attribute
    Then relation(marriage) get owns do not contain: second-custom-attribute
    Then entity(player) get owns contain: overridden-custom-attribute
    Then relation(marriage) get owns contain: overridden-custom-attribute
    Then entity(player) get owns: overridden-custom-attribute, get annotations contain: @range(<args>)
    Then relation(marriage) get owns: overridden-custom-attribute, get annotations contain: @range(<args>)
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then entity(player) get owns: custom-attribute, get annotations contain: @range(<args>)
    Then relation(marriage) get owns: custom-attribute, get annotations contain: @range(<args>)
    Then entity(player) get owns: overridden-custom-attribute, get annotations contain: @range(<args>)
    Then relation(marriage) get owns: overridden-custom-attribute, get annotations contain: @range(<args>)
    When entity(player) get owns: custom-attribute, set annotation: @range(<args-override>)
    When relation(marriage) get owns: custom-attribute, set annotation: @range(<args-override>)
    Then entity(player) get owns: custom-attribute, get annotations contain: @range(<args-override>)
    Then relation(marriage) get owns: custom-attribute, get annotations contain: @range(<args-override>)
    When entity(player) get owns: overridden-custom-attribute, set annotation: @range(<args-override>)
    When relation(marriage) get owns: overridden-custom-attribute, set annotation: @range(<args-override>)
    Then entity(player) get owns: overridden-custom-attribute, get annotations contain: @range(<args-override>)
    Then relation(marriage) get owns: overridden-custom-attribute, get annotations contain: @range(<args-override>)
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(player) get owns: custom-attribute, get annotations contain: @range(<args-override>)
    Then relation(marriage) get owns: custom-attribute, get annotations contain: @range(<args-override>)
    Then entity(player) get owns: overridden-custom-attribute, get annotations contain: @range(<args-override>)
    Then relation(marriage) get owns: overridden-custom-attribute, get annotations contain: @range(<args-override>)
    Examples:
      | value-type | args                             | args-override                             |
      | long       | 1, 10                            | 1, 5                                      |
      | double     | 1.0, 10.0                        | 2.0, 10.0                                 |
      | decimal    | 0.0, 1.0                         | 0.0, 0.999999                             |
      | string     | "A", "Z"                         | "J", "Z"                                  |
      | datetime   | 2024-06-04, 2024-06-05           | 2024-06-04, 2024-06-04T12:00:00           |
      | datetimetz | 2024-06-04+0010, 2024-06-05+0010 | 2024-06-04+0010, 2024-06-04T12:00:00+0010 |
      | duration   | P6M, P1Y                         | P8M, P9M                                  |

  Scenario Outline: Inherited @range annotation on owns for <value-type> value type can not be overridden by the @range of same args or not a subset of args
    When put entity type: person
    When put relation type: contract
    When relation(contract) create role: participant
    When put attribute type: custom-attribute
    When attribute(custom-attribute) set value-type: <value-type>
    When put attribute type: second-custom-attribute
    When attribute(second-custom-attribute) set value-type: <value-type>
    When entity(person) set owns: custom-attribute
    When relation(contract) set owns: custom-attribute
    When entity(person) set owns: second-custom-attribute
    When relation(contract) set owns: second-custom-attribute
    When entity(person) get owns: custom-attribute, set annotation: @range(<args>)
    When relation(contract) get owns: custom-attribute, set annotation: @range(<args>)
    Then entity(person) get owns: custom-attribute; get annotations contain: @range(<args>)
    Then relation(contract) get owns: custom-attribute; get annotations contain: @range(<args>)
    When entity(person) get owns: second-custom-attribute, set annotation: @range(<args>)
    When relation(contract) get owns: second-custom-attribute, set annotation: @range(<args>)
    Then entity(person) get owns: second-custom-attribute; get annotations contain: @range(<args>)
    Then relation(contract) get owns: second-custom-attribute; get annotations contain: @range(<args>)
    When put entity type: player
    When put relation type: marriage
    When entity(player) set supertype: person
    When relation(marriage) set supertype: contract
    Then entity(player) get owns: custom-attribute, get annotations contain: @range(<args>)
    Then relation(marriage) get owns: custom-attribute, get annotations contain: @range(<args>)
    # TODO: Overrides? Remove second-custom-attribute from test if we remove overrides!
    When entity(player) get owns: second-custom-attribute; set override: overridden-custom-attribute
    When relation(marriage) get owns: second-custom-attribute; set override: overridden-custom-attribute
    Then entity(player) get owns: overridden-custom-attribute, get annotations contain: @range(<args>)
    Then relation(marriage) get owns: overridden-custom-attribute, get annotations contain: @range(<args>)
    Then entity(player) get owns: custom-attribute, set annotation: @range(<args>); fails
    Then relation(marriage) get owns: custom-attribute, set annotation: @range(<args>); fails
    Then entity(player) get owns: overridden-custom-attribute, set annotation: @range(<args>); fails
    Then relation(marriage) get owns: overridden-custom-attribute, set annotation: @range(<args>); fails
    Then entity(player) get owns: custom-attribute, set annotation: @range(<args-override>); fails
    Then relation(marriage) get owns: custom-attribute, set annotation: @range(<args-override>); fails
    Then entity(player) get owns: overridden-custom-attribute, set annotation: @range(<args-override>); fails
    Then relation(marriage) get owns: overridden-custom-attribute, set annotation: @range(<args-override>); fails
    Then entity(player) get owns: custom-attribute, get annotations contain: @range(<args>)
    Then relation(marriage) get owns: custom-attribute, get annotations contain: @range(<args>)
    Then entity(player) get owns: overridden-custom-attribute, get annotations contain: @range(<args>)
    Then relation(marriage) get owns: overridden-custom-attribute, get annotations contain: @range(<args>)
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then entity(player) get owns: custom-attribute, get annotations contain: @range(<args>)
    Then relation(marriage) get owns: custom-attribute, get annotations contain: @range(<args>)
    Then entity(player) get owns: overridden-custom-attribute, get annotations contain: @range(<args>)
    Then relation(marriage) get owns: overridden-custom-attribute, get annotations contain: @range(<args>)
    Examples:
      | value-type | args                             | args-override                             |
      | long       | 1, 10                            | -1, 5                                     |
      | double     | 1.0, 10.0                        | 0.0, 150.0                                |
      | decimal    | 0.0, 1.0                         | -0.0001, 0.999999                         |
      | string     | "A", "Z"                         | "A", "z"                                  |
      | datetime   | 2024-06-04, 2024-06-05           | 2023-06-04, 2024-06-04T12:00:00           |
      | datetimetz | 2024-06-04+0010, 2024-06-05+0010 | 2024-06-04+0010, 2024-06-05T01:00:00+0010 |
      | duration   | P6M, P1Y                         | P8M, P1Y1D                                |

#################
# @card
#################

  Scenario Outline: Owns can set @card annotation for <value-type> value type with args in correct order and unset it
    When put entity type: person
    When put attribute type: custom-attribute
    When attribute(custom-attribute) set value-type: <value-type>
    When entity(person) set owns: custom-attribute
    Then entity(player) get owns: custom-attribute, set annotation: @card(<arg1>, <arg0>); fails
    Then entity(person) get owns: custom-attribute; get annotations is empty
    When entity(person) get owns: custom-attribute, set annotation: @card(<arg0>, <arg1>)
    Then entity(person) get owns: custom-attribute; get annotations contain: @card(<arg0>, <arg1>)
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then entity(person) get owns: custom-attribute; get annotations contain: @card(<arg0>, <arg1>)
    When entity(person) unset owns: custom-attribute
    Then entity(person) get owns is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(person) get owns is empty
    Examples:
      | value-type    | arg0 | arg1                |
      | long          | 0    | 1                   |
      | long          | 0    | 10                  |
      | long          | 0    | 9223372036854775807 |
      | long          | 1    | 10                  |
      | long          | 0    | *                   |
      | long          | 1    | *                   |
      | long          | *    | 10                  |
      | string        | 0    | 1                   |
      | string        | 0    | 10                  |
      | string        | 0    | 9223372036854775807 |
      | string        | 1    | 10                  |
      | string        | 0    | *                   |
      | string        | 1    | *                   |
      | string        | *    | 10                  |
      | boolean       | 0    | 1                   |
      | boolean       | 0    | 10                  |
      | boolean       | 0    | 9223372036854775807 |
      | boolean       | 1    | 10                  |
      | boolean       | 0    | *                   |
      | boolean       | 1    | *                   |
      | boolean       | *    | 10                  |
      | double        | 0    | 1                   |
      | double        | 0    | 10                  |
      | double        | 0    | 9223372036854775807 |
      | double        | 1    | 10                  |
      | double        | 0    | *                   |
      | double        | 1    | *                   |
      | double        | *    | 10                  |
      | decimal       | 0    | 1                   |
      | decimal       | 0    | 10                  |
      | decimal       | 0    | 9223372036854775807 |
      | decimal       | 1    | 10                  |
      | decimal       | 0    | *                   |
      | decimal       | 1    | *                   |
      | decimal       | *    | 10                  |
      | datetime      | 0    | 1                   |
      | datetime      | 0    | 10                  |
      | datetime      | 0    | 9223372036854775807 |
      | datetime      | 1    | 10                  |
      | datetime      | 0    | *                   |
      | datetime      | 1    | *                   |
      | datetime      | *    | 10                  |
      | datetimetz    | 0    | 1                   |
      | datetimetz    | 0    | 10                  |
      | datetimetz    | 0    | 9223372036854775807 |
      | datetimetz    | 1    | 10                  |
      | datetimetz    | 0    | *                   |
      | datetimetz    | 1    | *                   |
      | datetimetz    | *    | 10                  |
      | duration      | 0    | 1                   |
      | duration      | 0    | 10                  |
      | duration      | 0    | 9223372036854775807 |
      | duration      | 1    | 10                  |
      | duration      | 0    | *                   |
      | duration      | 1    | *                   |
      | duration      | *    | 10                  |
      | custom-struct | 0    | 1                   |
      | custom-struct | 0    | 10                  |
      | custom-struct | 0    | 9223372036854775807 |
      | custom-struct | 1    | 10                  |
      | custom-struct | 0    | *                   |
      | custom-struct | 1    | *                   |
      | custom-struct | *    | 10                  |

  Scenario Outline: Owns can set @card annotation for <value-type> value type with duplicate args (exactly N ownerships)
    When put entity type: person
    When put attribute type: custom-attribute
    When attribute(custom-attribute) set value-type: <value-type>
    When entity(person) set owns: custom-attribute
    Then entity(person) get owns: custom-attribute; get annotations is empty
    When entity(person) get owns: custom-attribute, set annotation: @card(<arg>, <arg>)
    Then entity(person) get owns: custom-attribute; get annotations contain: @card(<arg>, <arg>)
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(person) get owns: custom-attribute; get annotations contain: @card(<arg>, <arg>)
    Examples:
      | value-type    | arg  |
      | long          | 1    |
      | long          | 9999 |
      | string        | 1    |
      | string        | 8888 |
      | boolean       | 1    |
      | boolean       | 7777 |
      | double        | 1    |
      | double        | 666  |
      | decimal       | 1    |
      | decimal       | 555  |
      | datetime      | 1    |
      | datetime      | 444  |
      | datetimetz    | 1    |
      | datetimetz    | 33   |
      | duration      | 1    |
      | duration      | 22   |
      | custom-struct | 1    |
      | custom-struct | 11   |

  Scenario Outline: Owns can not have @card annotation for <value-type> value type with less than two args
    When put entity type: person
    When put attribute type: custom-attribute
    When attribute(custom-attribute) set value-type: <value-type>
    When entity(person) set owns: custom-attribute
    Then entity(person) get owns: custom-attribute, set annotation: @card(); fails
    Then entity(person) get owns: custom-attribute, set annotation: @card(1); fails
    Then entity(person) get owns: custom-attribute, set annotation: @card(*); fails
    Then entity(person) get owns: custom-attribute; get annotations is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(person) get owns: custom-attribute; get annotations is empty
    Examples:
      | value-type |
      | long       |
      | double     |
      | decimal    |
      | string     |
      | boolean    |
      | datetime   |
      | datetimetz |
      | duration   |

  Scenario Outline: Owns can not have @card annotation for <value-type> value type with invalid args or args number
    When put entity type: person
    When put attribute type: custom-attribute
    When attribute(custom-attribute) set value-type: <value-type>
    When entity(player) set owns: custom-attribute
    Then entity(player) get owns: custom-attribute, set annotation: @card(-1, 1); fails
    Then entity(player) get owns: custom-attribute, set annotation: @card(0, 0.1); fails
    Then entity(player) get owns: custom-attribute, set annotation: @card(0, 1.5); fails
    Then entity(player) get owns: custom-attribute, set annotation: @card(*, *); fails
    Then entity(player) get owns: custom-attribute, set annotation: @card(0, **); fails
    Then entity(player) get owns: custom-attribute, set annotation: @card(1, 2, 3); fails
    Then entity(player) get owns: custom-attribute, set annotation: @card(1, "2"); fails
    Then entity(player) get owns: custom-attribute, set annotation: @card("1", 2); fails
    Then entity(player) get owns: custom-attribute; get annotations is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(player) get owns: custom-attribute; get annotations is empty
    Examples:
      | value-type |
      | long       |
      | double     |
      | decimal    |
      | string     |
      | boolean    |
      | datetime   |
      | datetimetz |
      | duration   |

  Scenario Outline: Owns-related @card annotation for <value-type> value type can be inherited and overridden by a subset of args
    When put entity type: person
    When put relation type: contract
    When relation(contract) create role: participant
    When put attribute type: custom-attribute
    When attribute(custom-attribute) set value-type: <value-type>
    When put attribute type: second-custom-attribute
    When attribute(second-custom-attribute) set value-type: <value-type>
    When entity(person) set owns: custom-attribute
    When relation(contract) set owns: custom-attribute
    When entity(person) set owns: second-custom-attribute
    When relation(contract) set owns: second-custom-attribute
    When entity(person) get owns: custom-attribute, set annotation: @card(<args>)
    When relation(contract) get owns: custom-attribute, set annotation: @card(<args>)
    Then entity(person) get owns: custom-attribute; get annotations contain: @card(<args>)
    Then relation(contract) get owns: custom-attribute; get annotations contain: @card(<args>)
    When entity(person) get owns: second-custom-attribute, set annotation: @card(<args>)
    When relation(contract) get owns: second-custom-attribute, set annotation: @card(<args>)
    Then entity(person) get owns: second-custom-attribute; get annotations contain: @card(<args>)
    Then relation(contract) get owns: second-custom-attribute; get annotations contain: @card(<args>)
    When put entity type: player
    When put relation type: marriage
    When entity(player) set supertype: person
    When relation(marriage) set supertype: contract
    Then entity(player) get owns contain: custom-attribute
    Then relation(marriage) get owns contain: custom-attribute
    Then entity(player) get owns: custom-attribute, get annotations contain: @card(<args>)
    Then relation(marriage) get owns: custom-attribute, get annotations contain: @card(<args>)
    Then entity(player) get owns contain: second-custom-attribute
    Then relation(marriage) get owns contain: second-custom-attribute
    # TODO: Overrides? Remove second-custom-attribute from test if we remove overrides!
    When entity(player) get owns: second-custom-attribute; set override: overridden-custom-attribute
    When relation(marriage) get owns: second-custom-attribute; set override: overridden-custom-attribute
    Then entity(player) get owns do not contain: second-custom-attribute
    Then relation(marriage) get owns do not contain: second-custom-attribute
    Then entity(player) get owns contain: overridden-custom-attribute
    Then relation(marriage) get owns contain: overridden-custom-attribute
    Then entity(player) get owns: overridden-custom-attribute, get annotations contain: @card(<args>)
    Then relation(marriage) get owns: overridden-custom-attribute, get annotations contain: @card(<args>)
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then entity(player) get owns: custom-attribute, get annotations contain: @card(<args>)
    Then relation(marriage) get owns: custom-attribute, get annotations contain: @card(<args>)
    Then entity(player) get owns: overridden-custom-attribute, get annotations contain: @card(<args>)
    Then relation(marriage) get owns: overridden-custom-attribute, get annotations contain: @card(<args>)
    When entity(player) get owns: custom-attribute, set annotation: @card(<args-override>)
    When relation(marriage) get owns: custom-attribute, set annotation: @card(<args-override>)
    Then entity(player) get owns: custom-attribute, get annotations contain: @card(<args-override>)
    Then relation(marriage) get owns: custom-attribute, get annotations contain: @card(<args-override>)
    When entity(player) get owns: overridden-custom-attribute, set annotation: @card(<args-override>)
    When relation(marriage) get owns: overridden-custom-attribute, set annotation: @card(<args-override>)
    Then entity(player) get owns: overridden-custom-attribute, get annotations contain: @card(<args-override>)
    Then relation(marriage) get owns: overridden-custom-attribute, get annotations contain: @card(<args-override>)
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(player) get owns: custom-attribute, get annotations contain: @card(<args-override>)
    Then relation(marriage) get owns: custom-attribute, get annotations contain: @card(<args-override>)
    Then entity(player) get owns: overridden-custom-attribute, get annotations contain: @card(<args-override>)
    Then relation(marriage) get owns: overridden-custom-attribute, get annotations contain: @card(<args-override>)
    Examples:
      | value-type | args       | args-override |
      | long       | 0, *       | 0, 10000      |
      | double     | 0, 10      | 0, 1          |
      | decimal    | 0, 2       | 1, 2          |
      | string     | 1, *       | 1, 1          |
      | datetime   | 1, 5       | 3, 4          |
      | datetimetz | 38, 111    | 39, 111       |
      | duration   | 1000, 1100 | 1000, 1099    |

  Scenario Outline: Inherited @card annotation on owns for <value-type> value type can not be overridden by the @card of same args or not a subset of args
    When put entity type: person
    When put relation type: contract
    When relation(contract) create role: participant
    When put attribute type: custom-attribute
    When attribute(custom-attribute) set value-type: <value-type>
    When put attribute type: second-custom-attribute
    When attribute(second-custom-attribute) set value-type: <value-type>
    When entity(person) set owns: custom-attribute
    When relation(contract) set owns: custom-attribute
    When entity(person) set owns: second-custom-attribute
    When relation(contract) set owns: second-custom-attribute
    When entity(person) get owns: custom-attribute, set annotation: @card(<args>)
    When relation(contract) get owns: custom-attribute, set annotation: @card(<args>)
    Then entity(person) get owns: custom-attribute; get annotations contain: @card(<args>)
    Then relation(contract) get owns: custom-attribute; get annotations contain: @card(<args>)
    When entity(person) get owns: second-custom-attribute, set annotation: @card(<args>)
    When relation(contract) get owns: second-custom-attribute, set annotation: @card(<args>)
    Then entity(person) get owns: second-custom-attribute; get annotations contain: @card(<args>)
    Then relation(contract) get owns: second-custom-attribute; get annotations contain: @card(<args>)
    When put entity type: player
    When put relation type: marriage
    When entity(player) set supertype: person
    When relation(marriage) set supertype: contract
    Then entity(player) get owns: custom-attribute, get annotations contain: @card(<args>)
    Then relation(marriage) get owns: custom-attribute, get annotations contain: @card(<args>)
    # TODO: Overrides? Remove second-custom-attribute from test if we remove overrides!
    When entity(player) get owns: second-custom-attribute; set override: overridden-custom-attribute
    When relation(marriage) get owns: second-custom-attribute; set override: overridden-custom-attribute
    Then entity(player) get owns: overridden-custom-attribute, get annotations contain: @card(<args>)
    Then relation(marriage) get owns: overridden-custom-attribute, get annotations contain: @card(<args>)
    Then entity(player) get owns: custom-attribute, set annotation: @card(<args>); fails
    Then relation(marriage) get owns: custom-attribute, set annotation: @card(<args>); fails
    Then entity(player) get owns: overridden-custom-attribute, set annotation: @card(<args>); fails
    Then relation(marriage) get owns: overridden-custom-attribute, set annotation: @card(<args>); fails
    Then entity(player) get owns: custom-attribute, set annotation: @card(<args-override>); fails
    Then relation(marriage) get owns: custom-attribute, set annotation: @card(<args-override>); fails
    Then entity(player) get owns: overridden-custom-attribute, set annotation: @card(<args-override>); fails
    Then relation(marriage) get owns: overridden-custom-attribute, set annotation: @card(<args-override>); fails
    Then entity(player) get owns: custom-attribute, get annotations contain: @card(<args>)
    Then relation(marriage) get owns: custom-attribute, get annotations contain: @card(<args>)
    Then entity(player) get owns: overridden-custom-attribute, get annotations contain: @card(<args>)
    Then relation(marriage) get owns: overridden-custom-attribute, get annotations contain: @card(<args>)
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then entity(player) get owns: custom-attribute, get annotations contain: @card(<args>)
    Then relation(marriage) get owns: custom-attribute, get annotations contain: @card(<args>)
    Then entity(player) get owns: overridden-custom-attribute, get annotations contain: @card(<args>)
    Then relation(marriage) get owns: overridden-custom-attribute, get annotations contain: @card(<args>)
    Examples:
      | value-type | args       | args-override |
      | long       | 0, 10000   | 0, 10001      |
      | double     | 0, 10      | 1, 11         |
      | decimal    | 0, 2       | 0, 0          |
      | string     | 1, *       | 0, 2          |
      | datetime   | 1, 5       | 6, 10         |
      | datetimetz | 38, 111    | 37, 111       |
      | duration   | 1000, 1100 | 1000, 1199    |

#################
# @distinct
#################

  Scenario Outline: Owns can set @distinct annotation for <value-type> value type list and unset it
    When put entity type: person
    When put attribute type: custom-attribute
    When attribute(custom-attribute) set value-type: <value-type>
    When entity(person) set owns: custom-attribute[]
    When entity(person) get owns: custom-attribute[], set annotation: @distinct
    Then entity(person) get owns: custom-attribute[]; get annotations contain: @distinct
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then entity(person) get owns: custom-attribute[]; get annotations contain: @distinct
    When entity(person) unset owns: custom-attribute[]
    Then entity(person) get owns is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(person) get owns is empty
    Examples:
      | value-type    |
      | long          |
      | string        |
      | boolean       |
      | double        |
      | decimal       |
      | datetime      |
      | datetimetz    |
      | duration      |
      | custom-struct |

  Scenario Outline: Owns can not have @distinct annotation for <value-type> non-list value type
    When put entity type: person
    When put attribute type: custom-attribute
    When attribute(custom-attribute) set value-type: <value-type>
    When entity(person) set owns: custom-attribute
    Then entity(person) get owns: custom-attribute, set annotation: @distinct; fails
    Then entity(person) get owns: custom-attribute; get annotations is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(person) get owns: custom-attribute; get annotations is empty
    Examples:
      | value-type    |
      | long          |
      | string        |
      | boolean       |
      | double        |
      | decimal       |
      | datetime      |
      | datetimetz    |
      | duration      |
      | custom-struct |

#################
# @annotations not compatible to owns: @abstract, @cascade, @independent, @replace
#################

  Scenario Outline: Owns can not have @abstract, @cascade, @independent, and @replace annotations for <value-type> value type
    When put entity type: person
    When put attribute type: custom-attribute
    When attribute(custom-attribute) set value-type: <value-type>
    When entity(person) set owns: custom-attribute
    Then entity(person) get owns: custom-attribute, set annotation: @abstract; fails
    Then entity(person) get owns: custom-attribute, set annotation: @cascade; fails
    Then entity(person) get owns: custom-attribute, set annotation: @independent; fails
    Then entity(person) get owns: custom-attribute, set annotation: @replace; fails
    Then entity(person) get owns: custom-attribute; get annotations is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(person) get owns: custom-attribute; get annotations is empty
    Examples:
      | value-type    |
      | long          |
      | string        |
      | boolean       |
      | double        |
      | decimal       |
      | datetime      |
      | datetimetz    |
      | duration      |
      | custom-struct |

#################
# @annotations combinations
#################
  # TODO
