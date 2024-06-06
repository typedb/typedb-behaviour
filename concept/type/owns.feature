# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: Concept Owns

  # TODO: Refactor "DEPRECATED"!
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
    Given put entity type: person
    Given put entity type: customer
    Given put entity type: subscriber
    # Notice: supertypes are the same, but can be overridden for the second subtype inside the tests
    Given entity(customer) set supertype: person
    Given entity(subscriber) set supertype: person
    Given put relation type: description
    Given relation(description) create role: object
    Given put relation type: registration
    Given put relation type: profile
    # Notice: supertypes are the same, but can be overridden for the second subtype inside the tests
    Given relation(registration) set supertype: description
    Given relation(profile) set supertype: description
    # TODO: Create structs in concept api
    Given put struct type: custom-struct
    Given struct(custom-struct) create field: custom-field
    Given struct(custom-struct) get field(custom-field); set value-type: string
    Given transaction commits
    Given connection opens schema transaction for database: typedb

########################
# owns common
########################

  Scenario Outline: Entity types can own and unset attributes
    When put attribute type: name
    When attribute(name) set value-type: <value-type>
    When put attribute type: surname
    When attribute(surname) set value-type: <value-type>
    When put attribute type: birthday
    When attribute(birthday) set value-type: <value-type-2>
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

  Scenario: Entity types cannot own entities, relations, roles, structs, and structs fields
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
    Then entity(person) set owns: car; fails
    Then entity(person) set owns: credit; fails
    Then entity(person) set owns: marriage:creditor; fails
    Then entity(person) set owns: passport; fails
    Then entity(person) set owns: passport:birthday; fails
    Then entity(person) get owns is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(person) get owns is empty

  Scenario Outline: Relation types can own and unset attributes
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

  Scenario: Relation types cannot own entities, relations, roles, structs, and structs fields
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

  Scenario: Attribute types cannot own entities, attributes, relations, roles, structs, and structs fields
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

  Scenario: Struct types cannot own entities, attributes, relations, roles, structs, and structs fields
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

  Scenario Outline: <root-type> types can re-override owns
    When put attribute type: email
    When attribute(email) set value-type: <value-type>
    When attribute(email) set annotation: @abstract
    When put attribute type: work-email
    When attribute(work-email) set value-type: <value-type>
    When attribute(work-email) set supertype: email
    When <root-type>(<supertype-name>) set annotation: @abstract
    When <root-type>(<supertype-name>) set owns: email
    When <root-type>(<sub-name>) set annotation: @abstract
    When <root-type>(<subtype-name>) set supertype: person
    When <root-type>(<subtype-name>) set owns: work-email
    When <root-type>(<subtype-name>) get owns: work-email; set override: email
    Then <root-type>(<subtype-name>) get owns overridden(work-email) get label: email
    When transaction commits
    When connection opens schema transaction for database: typedb
    When <root-type>(<subtype-name>) set owns: work-email
    When <root-type>(<subtype-name>) get owns: work-email; set override: email
    Then <root-type>(<subtype-name>) get owns overridden(work-email) get label: email
    Examples:
      | root-type | supertype-name | subtype-name | value-type    |
      | entity    | person         | customer     | long          |
      | entity    | person         | customer     | double        |
      | entity    | person         | customer     | decimal       |
      | entity    | person         | customer     | string        |
      | entity    | person         | customer     | boolean       |
      | entity    | person         | customer     | datetime      |
      | entity    | person         | customer     | datetimetz    |
      | entity    | person         | customer     | duration      |
      | entity    | person         | customer     | custom-struct |
      | relation  | description    | registration | long          |
      | relation  | description    | registration | double        |
      | relation  | description    | registration | decimal       |
      | relation  | description    | registration | string        |
      | relation  | description    | registration | boolean       |
      | relation  | description    | registration | datetime      |
      | relation  | description    | registration | datetimetz    |
      | relation  | description    | registration | duration      |
      | relation  | description    | registration | custom-struct |

  Scenario Outline: <root-type> types cannot redeclare inherited owns as owns
    When put attribute type: email
    When attribute(email) set value-type: <value-type>
    When put attribute type: name
    When attribute(name) set value-type: <value-type>
    When <root-type>(<supertype-name>) set owns: name
    Then <root-type>(<subtype-name>) set owns: name
    Then transaction commits; fails
    Examples:
      | root-type | supertype-name | subtype-name | value-type |
      | entity    | person         | customer     | string     |
      | entity    | person         | customer     | long       |
      | relation  | description    | registration | string     |
      | relation  | description    | registration | datetime   |

  Scenario Outline: <root-type> types cannot redeclare inherited owns in multiple layers of inheritance
    When put attribute type: name
    When attribute(name) set value-type: <value-type>
    When attribute(name) set annotation: @abstract
    When put attribute type: customer-name
    When attribute(customer-name) set value-type: <value-type>
    When attribute(customer-name) set supertype: name
    When <root-type>(<supertype-name>) set annotation: @abstract
    When <root-type>(<supertype-name>) set owns: name
    When <root-type>(<subtype-name>) set owns: customer-name
    When <root-type>(<subtype-name-2>) set supertype: <subtype-name>
    Then <root-type>(<subtype-name-2>) set owns: name
    Then transaction commits; fails
    Examples:
      | root-type | supertype-name | subtype-name | subtype-name-2 | value-type    |
      | entity    | person         | customer     | subscriber     | datetimetz    |
      | entity    | person         | customer     | subscriber     | custom-struct |
      | relation  | description    | registration | profile        | decimal       |
      | relation  | description    | registration | profile        | string        |

  Scenario Outline: <root-type> types cannot redeclare overridden owns as owns
    When put attribute type: name
    When attribute(name) set value-type: <value-type>
    When attribute(name) set annotation: @abstract
    When put attribute type: customer-name
    When attribute(customer-name) set value-type: <value-type>
    When attribute(customer-name) set supertype: name
    When <root-type>(<supertype-name>) set annotation: @abstract
    When <root-type>(<supertype-name>) set owns: name
    # TODO: No set override here?
    When <root-type>(<subtype-name>) set owns: customer-name
    When <root-type>(<subtype-name-2>) set supertype: <subtype-name>
    Then <root-type>(<subtype-name-2>) set owns: customer-name
    Then transaction commits; fails
    Examples:
      | root-type | supertype-name | subtype-name | subtype-name-2 | value-type |
      | entity    | person         | customer     | subscriber     | boolean    |
      | entity    | person         | customer     | subscriber     | long       |
      | relation  | description    | registration | profile        | duration   |
      | relation  | description    | registration | profile        | double     |

  Scenario Outline: <root-type> types cannot override declared owns with owns
    When put attribute type: name
    When attribute(name) set value-type: <value-type>
    When attribute(name) set annotation: @abstract
    When put attribute type: first-name
    When attribute(first-name) set value-type: <value-type>
    When attribute(first-name) set supertype: name
    When <root-type>(<type-name>) set annotation: @abstract
    When <root-type>(<type-name>) set owns: name
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then <root-type>(<type-name>) set owns: first-name
    Then <root-type>(<type-name>) get owns: first-name; set override: name; fails
    Examples:
      | root-type | type-name   | value-type |
      | entity    | person      | string     |
      | relation  | description | string     |

  Scenario Outline: <root-type> types cannot override inherited owns other than with their subtypes
    When put attribute type: username
    When attribute(username) set value-type: <value-type>
    When put attribute type: reference
    When attribute(reference) set value-type: <value-type>
    When <root-type>(<supertype-name>) set owns: username
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then <root-type>(<subtype-name>) set owns: reference
    Then <root-type>(<subtype-name>) get owns: reference; set override: username; fails
    Examples:
      | root-type | supertype-name | subtype-name | value-type |
      | entity    | person         | customer     | double     |
      | relation  | description    | registration | string     |

  Scenario Outline: <root-type> types cannot unset not owned ownership
    When put attribute type: username
    When attribute(username) set value-type: <value-type>
    When put attribute type: reference
    When attribute(reference) set value-type: <value-type>
    When <root-type>(<type-name>) set owns: username
    Then <root-type>(<type-name>) get owns contain: username
    Then <root-type>(<type-name>) unset owns: reference; fails
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then <root-type>(<type-name>) get owns contain: username
    Then <root-type>(<type-name>) unset owns: reference; fails
    Then <root-type>(<type-name>) unset owns: username
    Then <root-type>(<type-name>) unset owns: username; fails
    Then <root-type>(<type-name>) get owns is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then <root-type>(<type-name>) get owns is empty
    Examples:
      | root-type | type-name   | value-type |
      | entity    | person      | string     |
      | relation  | description | long       |

  Scenario Outline: <root-type> types cannot unset inherited ownership
    When put attribute type: username
    When attribute(username) set value-type: <value-type>
    When <root-type>(<supertype-name>) set owns: username
    Then <root-type>(<supertype-name>) get owns contain: username
    Then <root-type>(<subtype-name>) get owns contain: username
    Then <root-type>(<subtype-name>) unset owns: username; fails
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then <root-type>(<subtype-name>) get owns contain: username
    Then <root-type>(<subtype-name>) unset owns: username; fails
    Examples:
      | root-type | supertype-name | subtype-name | value-type |
      | entity    | person         | customer     | string     |
      | relation  | description    | registration | long       |

########################
# @annotations common: contain common tests for annotations suitable for **scalar** attributes:
# @key, @unique, @subkey, @values, @range, @card, @regex
# DOES NOT test:
# @distinct
########################

  Scenario Outline: <root-type> types can set owns with @<annotation> and unset it
    When put attribute type: custom-attribute
    When attribute(custom-attribute) set value-type: <value-type>
    When <root-type>(<type-name>) set owns: custom-attribute
    When <root-type>(<type-name>) get owns: custom-attribute, set annotation: @<annotation>
    Then <root-type>(<type-name>) get owns: custom-attribute, get annotations contain: @<annotation>
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then <root-type>(<type-name>) get owns: custom-attribute, get annotations contain: @<annotation>
    When <root-type>(<type-name>) get owns: custom-attribute, unset annotation: @<annotation>
    Then <root-type>(<type-name>) get owns: custom-attribute, get annotations is empty
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then <root-type>(<type-name>) get owns: custom-attribute, get annotations is empty
    When <root-type>(<type-name>) get owns: custom-attribute, set annotation: @<annotation>
    Then <root-type>(<type-name>) get owns: custom-attribute, get annotations contain: @<annotation>
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then <root-type>(<type-name>) get owns: custom-attribute, get annotations contain: @<annotation>
    When <root-type>(<type-name>) unset owns: custom-attribute
    Then <root-type>(<type-name>) get owns is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then <root-type>(<type-name>) get owns is empty
    Examples:
      | root-type | type-name   | annotation       | value-type |
      | entity    | person      | key              | string     |
      | entity    | person      | unique           | string     |
      | entity    | person      | subkey(LABEL)    | string     |
      | entity    | person      | values("1", "2") | string     |
      | entity    | person      | range("1", "2")  | string     |
      | entity    | person      | card(1, 2)       | string     |
      | entity    | person      | regex("\S+")     | string     |
      | relation  | description | key              | string     |
      | relation  | description | unique           | string     |
      | relation  | description | subkey(LABEL)    | string     |
      | relation  | description | values("1", "2") | string     |
      | relation  | description | range("1", "2")  | string     |
      | relation  | description | card(1, 2)       | string     |
      | relation  | description | regex("\S+")     | string     |

  Scenario Outline: <root-type> types can have owns with @<annotation> alongside pure owns
    When put attribute type: email
    When attribute(email) set value-type: string
    When put attribute type: username
    When attribute(username) set value-type: string
    When put attribute type: name
    When attribute(name) set value-type: string
    When put attribute type: age
    When attribute(age) set value-type: long
    When <root-type>(<type-name>) set owns: email
    When <root-type>(<type-name>) get owns: email, set annotation: @<annotation>
    When <root-type>(<type-name>) set owns: username
    When <root-type>(<type-name>) get owns: username, set annotation: @<annotation>
    When <root-type>(<type-name>) set owns: name
    When <root-type>(<type-name>) set owns: age
    Then <root-type>(<type-name>) get owns: email, get annotations contain: @<annotation>
    Then <root-type>(<type-name>) get owns: username, get annotations contain: @<annotation>
    Then <root-type>(<type-name>) get owns contain:
      | email    |
      | username |
      | name     |
      | age      |
    When transaction commits
    When connection opens read transaction for database: typedb
    Then <root-type>(<type-name>) get owns: email, get annotations contain: @<annotation>
    Then <root-type>(<type-name>) get owns: username, get annotations contain: @<annotation>
    Then <root-type>(<type-name>) get owns contain:
      | email    |
      | username |
      | name     |
      | age      |
    Examples:
      | root-type | type-name   | annotation       |
      | entity    | person      | key              |
      | entity    | person      | unique           |
      | entity    | person      | subkey(LABEL)    |
      | entity    | person      | values("1", "2") |
      | entity    | person      | range("1", "2")  |
      | entity    | person      | card(1, 2)       |
      | entity    | person      | regex("\S+")     |
      | relation  | description | key              |
      | relation  | description | unique           |
      | relation  | description | subkey(LABEL)    |
      | relation  | description | values("1", "2") |
      | relation  | description | range("1", "2")  |
      | relation  | description | card(1, 2)       |
      | relation  | description | regex("\S+")     |

  Scenario Outline: <root-type> types cannot unset not set @<annotation> of ownership
    When put attribute type: username
    When attribute(username) set value-type: string
    When put attribute type: reference
    When attribute(reference) set value-type: string
    When <root-type>(<type-name>) set owns: username
    When <root-type>(<type-name>) get owns: username, set annotation: @<annotation>
    Then <root-type>(<type-name>) get owns: username, get annotation contain: @<annotation>
    When <root-type>(<type-name>) set owns: reference
    Then <root-type>(<type-name>) get owns: reference, unset annotation: @<annotation>; fails
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then <root-type>(<type-name>) get owns: username, get annotation contain: @<annotation>
    Then <root-type>(<type-name>) get owns: reference, unset annotation: @<annotation>; fails
    Then <root-type>(<type-name>) get owns: username, unset annotation: @<annotation>
    Then <root-type>(<type-name>) get owns: username, unset annotation: @<annotation>; fails
    Then <root-type>(<type-name>) get owns: username, get annotations is empty
    Then <root-type>(<type-name>) get owns: reference, get annotations is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then <root-type>(<type-name>) get owns: username, get annotations is empty
    Then <root-type>(<type-name>) get owns: reference, get annotations is empty
    Examples:
      | root-type | type-name   | annotation       |
      | entity    | person      | key              |
      | entity    | person      | unique           |
      | entity    | person      | subkey(LABEL)    |
      | entity    | person      | values("1", "2") |
      | entity    | person      | range("1", "2")  |
      | entity    | person      | card(1, 2)       |
      | entity    | person      | regex("\S+")     |
      | relation  | description | key              |
      | relation  | description | unique           |
      | relation  | description | subkey(LABEL)    |
      | relation  | description | values("1", "2") |
      | relation  | description | range("1", "2")  |
      | relation  | description | card(1, 2)       |
      | relation  | description | regex("\S+")     |

  Scenario Outline: <root-type> types cannot unset @<annotation> of inherited ownership
    When put attribute type: username
    When attribute(username) set value-type: string
    When <root-type>(<supertype-name>) set owns: username
    When <root-type>(<supertype-name>) get owns: username, set annotation: @<annotation>
    Then <root-type>(<supertype-name>) get owns: username, get annotation contain: @<annotation>
    Then <root-type>(<subtype-name>) get owns: username, get annotation contain: @<annotation>
    Then <root-type>(<subtype-name>) get owns: username, unset annotation: @<annotation>; fails
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then <root-type>(<subtype-name>) get owns: username, get annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get owns: username, unset annotation: @<annotation>; fails
    Examples:
      | root-type | supertype-name | subtype-name | annotation       |
      | entity    | person         | customer     | key              |
      | entity    | person         | customer     | unique           |
      | entity    | person         | customer     | subkey(LABEL)    |
      | entity    | person         | customer     | values("1", "2") |
      | entity    | person         | customer     | range("1", "2")  |
      | entity    | person         | customer     | card(1, 2)       |
      | entity    | person         | customer     | regex("\S+")     |
      | relation  | description    | registration | key              |
      | relation  | description    | registration | unique           |
      | relation  | description    | registration | subkey(LABEL)    |
      | relation  | description    | registration | values("1", "2") |
      | relation  | description    | registration | range("1", "2")  |
      | relation  | description    | registration | card(1, 2)       |
      | relation  | description    | registration | regex("\S+")     |

  Scenario Outline: <root-type> types can inherit owns with @<annotation>s alongside pure owns
    When put attribute type: email
    When attribute(email) set value-type: string
    When put attribute type: name
    When attribute(name) set value-type: string
    When put attribute type: reference
    When attribute(reference) set value-type: string
    When put attribute type: rating
    When attribute(rating) set value-type: double
    When <root-type>(<supertype-name>) set owns: email
    When <root-type>(<supertype-name>) get owns: email, set annotation: @<annotation>
    When <root-type>(<supertype-name>) set owns: name
    When <root-type>(<subtype-name>) set owns: reference
    When <root-type>(<subtype-name>) get owns: reference, set annotation: @<annotation>
    When <root-type>(<subtype-name>) set owns: rating
    Then <root-type>(<subtype-name>) get owns contain:
      | email     |
      | reference |
      | name      |
      | rating    |
    Then <root-type>(<subtype-name>) get declared owns contain:
      | reference |
      | rating    |
    Then <root-type>(<subtype-name>) get declared owns do not contain:
      | email |
      | name  |
    Then <root-type>(<subtype-name>) get owns: email, get annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get owns: reference, get annotations contain: @<annotation>
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then <root-type>(<subtype-name>) get owns contain:
      | email     |
      | reference |
      | name      |
      | rating    |
    Then <root-type>(<subtype-name>) get declared owns contain:
      | reference |
      | rating    |
    Then <root-type>(<subtype-name>) get declared owns do not contain:
      | email |
      | name  |
    Then <root-type>(<subtype-name>) get owns: email, get annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get owns: reference, get annotations contain: @<annotation>
    When put attribute type: license
    When attribute(license) set value-type: string
    When put attribute type: points
    When attribute(points) set value-type: double
    When <root-type>(<subtype-name-2>) set supertype: <subtype-name>
    When <root-type>(<subtype-name-2>) set owns: license
    When <root-type>(<subtype-name-2>) get owns: license, set annotation: @<annotation>
    When <root-type>(<subtype-name-2>) set owns: points
    When transaction commits
    When connection opens read transaction for database: typedb
    Then <root-type>(<subtype-name>) get owns contain:
      | email     |
      | reference |
      | name      |
      | rating    |
    Then <root-type>(<subtype-name>) get declared owns contain:
      | reference |
      | rating    |
    Then <root-type>(<subtype-name>) get declared owns do not contain:
      | email |
      | name  |
    Then <root-type>(<subtype-name>) get owns: email, get annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get owns: reference, get annotations contain: @<annotation>
    Then <root-type>(<subtype-name-2>) get owns: email, get annotations contain: @<annotation>
    Then <root-type>(<subtype-name-2>) get owns: reference, get annotations contain: @<annotation>
    Then <root-type>(<subtype-name-2>) get owns: license, get annotations contain: @<annotation>
    Then <root-type>(<subtype-name-2>) get owns contain:
      | email     |
      | reference |
      | license   |
      | name      |
      | rating    |
      | points    |
    Then <root-type>(<subtype-name-2>) get declared owns contain:
      | license |
      | points  |
    Then <root-type>(<subtype-name-2>) get declared owns do not contain:
      | email     |
      | reference |
      | name      |
      | rating    |
    Examples:
      | root-type | supertype-name | subtype-name | subtype-name-2 | annotation       |
      | entity    | person         | customer     | subscriber     | key              |
      | entity    | person         | customer     | subscriber     | unique           |
      | entity    | person         | customer     | subscriber     | subkey(LABEL)    |
      | entity    | person         | customer     | subscriber     | values("1", "2") |
      | entity    | person         | customer     | subscriber     | range("1", "2")  |
      | entity    | person         | customer     | subscriber     | card(1, 2)       |
      | entity    | person         | customer     | subscriber     | regex("\S+")     |
      | relation  | description    | registration | profile        | key              |
      | relation  | description    | registration | profile        | unique           |
      | relation  | description    | registration | profile        | subkey(LABEL)    |
      | relation  | description    | registration | profile        | values("1", "2") |
      | relation  | description    | registration | profile        | range("1", "2")  |
      | relation  | description    | registration | profile        | card(1, 2)       |
      | relation  | description    | registration | profile        | regex("\S+")     |

  Scenario Outline: <root-type> types can redeclare @<annotation>s as @<annotation>s
    When put attribute type: name
    When attribute(name) set value-type: <value-type>
    When put attribute type: email
    When attribute(email) set value-type: <value-type>
    When <root-type>(<type-name>) set owns: name
    When <root-type>(<type-name>) get owns: name, set annotation: @<annotation>
    Then <root-type>(<type-name>) get owns: name, get annotation contain: @<annotation>
    When <root-type>(<type-name>) set owns: email
    When <root-type>(<type-name>) get owns: email, set annotation: @<annotation>
    Then <root-type>(<type-name>) get owns: email, get annotation contain: @<annotation>
    Then <root-type>(<type-name>) set owns: name
    Then <root-type>(<type-name>) get owns: name, set annotation: @<annotation>
    Then <root-type>(<type-name>) get owns: name, get annotation contain: @<annotation>
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then <root-type>(<type-name>) get owns: name, get annotation contain: @<annotation>
    Then <root-type>(<type-name>) set owns: email
    Then <root-type>(<type-name>) get owns: email, set annotation: @<annotation>
    Then <root-type>(<type-name>) get owns: email, get annotation contain: @<annotation>
    Examples:
      | root-type | type-name   | annotation       | value-type |
      | entity    | person      | key              | string     |
      | entity    | person      | unique           | string     |
      | entity    | person      | subkey(LABEL)    | string     |
      | entity    | person      | values("1", "2") | string     |
      | entity    | person      | range("1", "2")  | string     |
      | entity    | person      | card(1, 2)       | string     |
      | entity    | person      | regex("\S+")     | string     |
      | relation  | description | key              | string     |
      | relation  | description | unique           | string     |
      | relation  | description | subkey(LABEL)    | string     |
      | relation  | description | values("1", "2") | string     |
      | relation  | description | range("1", "2")  | string     |
      | relation  | description | card(1, 2)       | string     |
      | relation  | description | regex("\S+")     | string     |

  Scenario Outline: <root-type> types can redeclare owns as owns with @<annotation>
    When put attribute type: name
    When attribute(name) set value-type: <value-type>
    When put attribute type: email
    When attribute(email) set value-type: <value-type>
    When put attribute type: address
    When attribute(address) set value-type: <value-type>
    When <root-type>(<type-name>) set owns: name
    When <root-type>(<type-name>) set owns: email
    When <root-type>(<type-name>) set owns: address
    Then <root-type>(<type-name>) set owns: name
    Then <root-type>(<type-name>) get owns: name, set annotation: @<annotation>
    Then <root-type>(<type-name>) get owns: name, get annotations contain: @<annotation>
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then <root-type>(<type-name>) set owns: email
    Then <root-type>(<type-name>) get owns: email, get annotations is empty
    When <root-type>(<type-name>) get owns: email, set annotation: @<annotation>
    Then <root-type>(<type-name>) get owns: email, get annotations contain: @<annotation>
    Then <root-type>(<type-name>) get owns: address, get annotations is empty
    When <root-type>(<type-name>) get owns: address, set annotation: @<annotation>
    Then <root-type>(<type-name>) get owns: address, get annotations contain: @<annotation>
    Examples:
      | root-type | type-name   | annotation       | value-type |
      | entity    | person      | key              | string     |
      | entity    | person      | unique           | string     |
      | entity    | person      | subkey(LABEL)    | string     |
      | entity    | person      | values("1", "2") | string     |
      | entity    | person      | range("1", "2")  | string     |
      | entity    | person      | card(1, 2)       | string     |
      | entity    | person      | regex("\S+")     | string     |
      | relation  | description | key              | string     |
      | relation  | description | unique           | string     |
      | relation  | description | subkey(LABEL)    | string     |
      | relation  | description | values("1", "2") | string     |
      | relation  | description | range("1", "2")  | string     |
      | relation  | description | card(1, 2)       | string     |
      | relation  | description | regex("\S+")     | string     |

    # TODO: We set annotations independently now. Is the scenario still relevant? I think so.
  Scenario Outline: <root-type> types can redeclare owns with @<annotation> as pure owns
    When put attribute type: name
    When attribute(name) set value-type: <value-type>
    When put attribute type: email
    When attribute(email) set value-type: <value-type>
    When <root-type>(<type-name>) set owns: name
    When <root-type>(<type-name>) get owns: name, set annotation: @<annotation>
    Then <root-type>(<type-name>) get owns: name, get annotations contain: @<annotation>
    When <root-type>(<type-name>) set owns: email
    When <root-type>(<type-name>) get owns: email, set annotation: @<annotation>
    Then <root-type>(<type-name>) get owns: email, get annotations contain: @<annotation>
    Then <root-type>(<type-name>) set owns: name
    Then <root-type>(<type-name>) get owns: name, get annotations is empty
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then <root-type>(<type-name>) get owns: email, get annotations contain: @<annotation>
    When <root-type>(<type-name>) set owns: email
    Then <root-type>(<type-name>) get owns: email, get annotations is empty
    Examples:
      | root-type | type-name   | annotation       | value-type |
      | entity    | person      | key              | string     |
      | entity    | person      | unique           | string     |
      | entity    | person      | subkey(LABEL)    | string     |
      | entity    | person      | values("1", "2") | string     |
      | entity    | person      | range("1", "2")  | string     |
      | entity    | person      | card(1, 2)       | string     |
      | entity    | person      | regex("\S+")     | string     |
      | relation  | description | key              | string     |
      | relation  | description | unique           | string     |
      | relation  | description | subkey(LABEL)    | string     |
      | relation  | description | values("1", "2") | string     |
      | relation  | description | range("1", "2")  | string     |
      | relation  | description | card(1, 2)       | string     |
      | relation  | description | regex("\S+")     | string     |

  Scenario Outline: <root-type> types can override inherited pure owns as owns with @<annotation>s
    When put attribute type: name
    When attribute(name) set value-type: <value-type>
    When attribute(name) set annotation: @abstract
    When put attribute type: username
    When attribute(username) set value-type: <value-type>
    When attribute(username) set supertype: name
    When <root-type>(<supertype-name>) set annotation: @abstract
    When <root-type>(<supertype-name>) set owns: name
    When <root-type>(<subtype-name>) set owns: username
    When <root-type>(<subtype-name>) get owns: username; set override: name
    When <root-type>(<subtype-name>) get owns: username, set annotation: @<annotation>
    Then <root-type>(<subtype-name>) get owns overridden(username) get label: name
    Then <root-type>(<subtype-name>) get owns, with annotations (DEPRECATED): <annotation>; contain:
      | username |
    Then <root-type>(<subtype-name>) get owns, with annotations (DEPRECATED): <annotation>; do not contain:
      | name |
    Then <root-type>(<subtype-name>) get owns contain:
      | username |
    Then <root-type>(<subtype-name>) get owns do not contain:
      | name |
    When transaction commits
    When connection opens read transaction for database: typedb
    Then <root-type>(<subtype-name>) get owns overridden(username) get label: name
    Then <root-type>(<subtype-name>) get owns, with annotations (DEPRECATED): <annotation>; contain:
      | username |
    Then <root-type>(<subtype-name>) get owns, with annotations (DEPRECATED): <annotation>; do not contain:
      | name |
    Then <root-type>(<subtype-name>) get owns contain:
      | username |
    Then <root-type>(<subtype-name>) get owns do not contain:
      | name |
    Examples:
      | root-type | supertype-name | subtype-name | annotation       | value-type |
      | entity    | person         | customer     | key              | string     |
      | entity    | person         | customer     | unique           | string     |
      | entity    | person         | customer     | subkey(LABEL)    | string     |
      | entity    | person         | customer     | values("1", "2") | string     |
      | entity    | person         | customer     | range("1", "2")  | string     |
      | entity    | person         | customer     | card(1, 2)       | string     |
      | entity    | person         | customer     | regex("\S+")     | string     |
      | relation  | description    | registration | key              | string     |
      | relation  | description    | registration | unique           | string     |
      | relation  | description    | registration | subkey(LABEL)    | string     |
      | relation  | description    | registration | values("1", "2") | string     |
      | relation  | description    | registration | range("1", "2")  | string     |
      | relation  | description    | registration | card(1, 2)       | string     |
      | relation  | description    | registration | regex("\S+")     | string     |

    # TODO: Maybe it should be rejected?
  Scenario Outline: <root-type> types can re-override owns with <annotation>s
    When put attribute type: email
    When attribute(email) set value-type: <value-type>
    When attribute(email) set annotation: @abstract
    When put attribute type: work-email
    When attribute(work-email) set value-type: <value-type>
    When attribute(work-email) set supertype: email
    When <root-type>(<supertype-name>) set annotation: @abstract
    When <root-type>(<supertype-name>) set owns: email
    When <root-type>(<supertype-name>) get owns: email, set annotation: @<annotation>
    When <root-type>(<subtype-name>) set annotation: @abstract
    When <root-type>(<subtype-name>) set supertype: person
    Then <root-type>(<subtype-name>) get owns contain: email
    Then <root-type>(<subtype-name>) get owns: email, get annotations contain: @<annotation>
    When <root-type>(<subtype-name>) set owns: work-email
    When <root-type>(<subtype-name>) get owns: work-email; set override: email
    # TODO: These commas, semicolons, and colons are a mess and are different for different subcases. Need to refactor it!
    Then <root-type>(<subtype-name>) get owns overridden(work-email) get label: email
    Then <root-type>(<subtype-name>) get owns overridden(work-email), get annotations contain: @<annotation>
    When transaction commits
    When connection opens schema transaction for database: typedb
    When <root-type>(<subtype-name>) set owns: work-email
    When <root-type>(<subtype-name>) get owns: work-email; set override: email
    Then <root-type>(<subtype-name>) get owns overridden(work-email) get label: email
    Then <root-type>(<subtype-name>) get owns overridden(work-email), get annotations contain: @<annotation>
    Examples:
      | root-type | supertype-name | subtype-name | annotation       | value-type |
      | entity    | person         | customer     | key              | string     |
      | entity    | person         | customer     | unique           | string     |
      | entity    | person         | customer     | subkey(LABEL)    | string     |
      | entity    | person         | customer     | values("1", "2") | string     |
      | entity    | person         | customer     | range("1", "2")  | string     |
      | entity    | person         | customer     | card(1, 2)       | string     |
      | entity    | person         | customer     | regex("\S+")     | string     |
      | relation  | description    | registration | key              | string     |
      | relation  | description    | registration | unique           | string     |
      | relation  | description    | registration | subkey(LABEL)    | string     |
      | relation  | description    | registration | values("1", "2") | string     |
      | relation  | description    | registration | range("1", "2")  | string     |
      | relation  | description    | registration | card(1, 2)       | string     |
      | relation  | description    | registration | regex("\S+")     | string     |

  Scenario Outline: <root-type> types can redeclare inherited attributes as keys (which will override)
    When put attribute type: email
    When attribute(email) set value-type: <value-type>
    When <root-type>(<supertype-name>) set owns: email
    Then <root-type>(<supertype-name>) get owns overridden(email) does not exist
    Then <root-type>(<subtype-name>) set owns: email
    Then <root-type>(<subtype-name>) get owns: email, set annotation: @<annotation>
    Then <root-type>(<subtype-name>) get owns overridden(email) exists
    Then <root-type>(<subtype-name>) get owns overridden(email) get label: email
    Then <root-type>(<subtype-name>) get owns, with annotations (DEPRECATED): <annotation>; contain: email
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then <root-type>(<subtype-name>) get owns, with annotations (DEPRECATED): <annotation>; contain: email
    Then <root-type>(<subtype-name-2>) set owns: email
    Then <root-type>(<subtype-name-2>) get owns: email, set annotation: @<annotation>
    Then <root-type>(<subtype-name-2>) get owns, with annotations (DEPRECATED): <annotation>; contain: email
    Examples:
      | root-type | supertype-name | subtype-name | subtype-name-2 | annotation       | value-type |
      | entity    | person         | customer     | subscriber     | key              | string     |
      | entity    | person         | customer     | subscriber     | unique           | string     |
      | entity    | person         | customer     | subscriber     | subkey(LABEL)    | string     |
      | entity    | person         | customer     | subscriber     | values("1", "2") | string     |
      | entity    | person         | customer     | subscriber     | range("1", "2")  | string     |
      | entity    | person         | customer     | subscriber     | card(1, 2)       | string     |
      | entity    | person         | customer     | subscriber     | regex("\S+")     | string     |
      | relation  | description    | registration | profile        | key              | string     |
      | relation  | description    | registration | profile        | unique           | string     |
      | relation  | description    | registration | profile        | subkey(LABEL)    | string     |
      | relation  | description    | registration | profile        | values("1", "2") | string     |
      | relation  | description    | registration | profile        | range("1", "2")  | string     |
      | relation  | description    | registration | profile        | card(1, 2)       | string     |
      | relation  | description    | registration | profile        | regex("\S+")     | string     |

  Scenario Outline: <root-type> types cannot redeclare inherited owns with @<annotation> as pure owns or owns with @<annotation>
    When put attribute type: email
    When attribute(email) set value-type: <value-type>
    When put attribute type: name
    When attribute(name) set value-type: <value-type>
    When <root-type>(<supertype-name>) set owns: email
    When <root-type>(<supertype-name>) get owns: email, set annotation: @<annotation>
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then <root-type>(<subtype-name>) set owns: email
    Then transaction commits; fails
    Then transaction closes
    When connection opens schema transaction for database: typedb
    Then <root-type>(<subtype-name>) set owns: email
    Then <root-type>(<subtype-name>) get owns: email, set annotation: @<annotation>
    Then transaction commits; fails
    Examples:
      | root-type | supertype-name | subtype-name | annotation       | value-type |
      | entity    | person         | customer     | key              | string     |
      | entity    | person         | customer     | unique           | string     |
      | entity    | person         | customer     | subkey(LABEL)    | string     |
      | entity    | person         | customer     | values("1", "2") | string     |
      | entity    | person         | customer     | range("1", "2")  | string     |
      | entity    | person         | customer     | card(1, 2)       | string     |
      | entity    | person         | customer     | regex("\S+")     | string     |
      | relation  | description    | registration | key              | string     |
      | relation  | description    | registration | unique           | string     |
      | relation  | description    | registration | subkey(LABEL)    | string     |
      | relation  | description    | registration | values("1", "2") | string     |
      | relation  | description    | registration | range("1", "2")  | string     |
      | relation  | description    | registration | card(1, 2)       | string     |
      | relation  | description    | registration | regex("\S+")     | string     |

  Scenario Outline: <root-type> types cannot redeclare inherited owns with @<annotation>
    When put attribute type: email
    When attribute(email) set value-type: <value-type>
    When attribute(email) set annotation: @abstract
    When put attribute type: customer-email
    When attribute(customer-email) set value-type: <value-type>
    When attribute(customer-email) set supertype: email
    When <root-type>(<supertype-name>) set annotation: @abstract
    When <root-type>(<supertype-name>) set owns: email
    When <root-type>(<supertype-name>) get owns: email, set annotation: @<annotation>
    When <root-type>(<subtype-name>) set owns: customer-email
    When <root-type>(<subtype-name>) get owns: customer-email, set annotation: @<annotation>
    When <root-type>(<subtype-name-2>) set supertype: <subtype-name>
    Then <root-type>(<subtype-name-2>) set owns: email
    Then <root-type>(<subtype-name-2>) get owns: email, set annotation: @<annotation>
    Then transaction commits; fails
    Examples:
      | root-type | supertype-name | subtype-name | subtype-name-2 | annotation       | value-type |
      | entity    | person         | customer     | subscriber     | key              | string     |
      | entity    | person         | customer     | subscriber     | unique           | string     |
      | entity    | person         | customer     | subscriber     | subkey(LABEL)    | string     |
      | entity    | person         | customer     | subscriber     | values("1", "2") | string     |
      | entity    | person         | customer     | subscriber     | range("1", "2")  | string     |
      | entity    | person         | customer     | subscriber     | card(1, 2)       | string     |
      | entity    | person         | customer     | subscriber     | regex("\S+")     | string     |
      | relation  | description    | registration | profile        | key              | string     |
      | relation  | description    | registration | profile        | unique           | string     |
      | relation  | description    | registration | profile        | subkey(LABEL)    | string     |
      | relation  | description    | registration | profile        | values("1", "2") | string     |
      | relation  | description    | registration | profile        | range("1", "2")  | string     |
      | relation  | description    | registration | profile        | card(1, 2)       | string     |
      | relation  | description    | registration | profile        | regex("\S+")     | string     |

  Scenario Outline: <root-type> types cannot redeclare overridden owns with @<annotation>s
    When put attribute type: email
    When attribute(email) set value-type: <value-type>
    When attribute(email) set annotation: @abstract
    When put attribute type: customer-email
    When attribute(customer-email) set value-type: <value-type>
    When attribute(customer-email) set supertype: email
    When <root-type>(<supertype-name>) set annotation: @abstract
    When <root-type>(<supertype-name>) set owns: email
    When <root-type>(<supertype-name>) get owns: email, set annotation: @<annotation>
    When <root-type>(<subtype-name>) set owns: customer-email
    # TODO: Do we have overrides? Revalidate "override"-mentioning tests if we do need it and place it everywhere!
#    When <root-type>(<subtype-name>) get owns: customer-email, set override: email
    When <root-type>(<subtype-name-2>) set supertype: <subtype-name>
    Then <root-type>(<subtype-name-2>) set owns: customer-email
    Then <root-type>(<subtype-name-2>) get owns: customer-email, set annotation: @<annotation>
    Then transaction commits; fails
    Examples:
      | root-type | supertype-name | subtype-name | subtype-name-2 | annotation       | value-type |
      | entity    | person         | customer     | subscriber     | key              | string     |
      | entity    | person         | customer     | subscriber     | unique           | string     |
      | entity    | person         | customer     | subscriber     | subkey(LABEL)    | string     |
      | entity    | person         | customer     | subscriber     | values("1", "2") | string     |
      | entity    | person         | customer     | subscriber     | range("1", "2")  | string     |
      | entity    | person         | customer     | subscriber     | card(1, 2)       | string     |
      | entity    | person         | customer     | subscriber     | regex("\S+")     | string     |
      | relation  | description    | registration | profile        | key              | string     |
      | relation  | description    | registration | profile        | unique           | string     |
      | relation  | description    | registration | profile        | subkey(LABEL)    | string     |
      | relation  | description    | registration | profile        | values("1", "2") | string     |
      | relation  | description    | registration | profile        | range("1", "2")  | string     |
      | relation  | description    | registration | profile        | card(1, 2)       | string     |
      | relation  | description    | registration | profile        | regex("\S+")     | string     |

  Scenario Outline: <root-type> types cannot redeclare overridden owns with @<annotation>s on multiple layers
    When put attribute type: email
    When attribute(email) set value-type: <value-type>
    When attribute(email) set annotation: @abstract
    When put attribute type: customer-email
    When attribute(customer-email) set value-type: <value-type>
    When attribute(customer-email) set supertype: email
    When <root-type>(<supertype-name>) set annotation: @abstract
    When <root-type>(<supertype-name>) set owns: email
    When <root-type>(<supertype-name>) get owns: email, set annotation: @<annotation>
    When <root-type>(<subtype-name>) set owns: customer-email
    When <root-type>(<subtype-name>) get owns: customer-email, set annotation: @<annotation>
        # TODO: Do we have overrides?
#    When <root-type>(<subtype-name>) get owns: customer-email, set override: email
    When <root-type>(<subtype-name-2>) set supertype: <subtype-name>
    Then <root-type>(<subtype-name-2>) set owns: customer-email
    Then <root-type>(<subtype-name-2>) get owns: customer-email, set annotation: @<annotation>
    Then transaction commits; fails
    Examples:
      | root-type | supertype-name | subtype-name | subtype-name-2 | annotation       | value-type |
      | entity    | person         | customer     | subscriber     | key              | string     |
      | entity    | person         | customer     | subscriber     | unique           | string     |
      | entity    | person         | customer     | subscriber     | subkey(LABEL)    | string     |
      | entity    | person         | customer     | subscriber     | values("1", "2") | string     |
      | entity    | person         | customer     | subscriber     | range("1", "2")  | string     |
      | entity    | person         | customer     | subscriber     | card(1, 2)       | string     |
      | entity    | person         | customer     | subscriber     | regex("\S+")     | string     |
      | relation  | description    | registration | profile        | key              | string     |
      | relation  | description    | registration | profile        | unique           | string     |
      | relation  | description    | registration | profile        | subkey(LABEL)    | string     |
      | relation  | description    | registration | profile        | values("1", "2") | string     |
      | relation  | description    | registration | profile        | range("1", "2")  | string     |
      | relation  | description    | registration | profile        | card(1, 2)       | string     |
      | relation  | description    | registration | profile        | regex("\S+")     | string     |

  Scenario Outline: <root-type> subtypes can redeclare @<annotation>s after it is unset from supertype
    When put attribute type: name
    When attribute(name) set value-type: <value-type>
    When put attribute type: surname
    When attribute(surname) set supertype: name
    When <root-type>(<type-name>) set owns: name
    When <root-type>(<type-name>) get owns: name, set annotation: @<annotation>
    Then <root-type>(<type-name>) get owns: name, get annotation contain: @<annotation>
    When <root-type>(<type-name>) set owns: surname
    Then <root-type>(<type-name>) get owns: surname, get annotation contain: @<annotation>
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then <root-type>(<type-name>) get owns: name, get annotation contain: @<annotation>
    Then <root-type>(<type-name>) get owns: surname, get annotation contain: @<annotation>
    Then <root-type>(<type-name>) get owns: surname, set annotation: @<annotation>; fails
    When <root-type>(<type-name>) get owns: name, unset annotation: @<annotation>
    Then <root-type>(<type-name>) get owns: name, get annotation is empty
    Then <root-type>(<type-name>) get owns: surname, get annotation is empty
    Then <root-type>(<type-name>) get owns: surname, set annotation: @<annotation>
    Then <root-type>(<type-name>) get owns: name, get annotation is empty
    Then <root-type>(<type-name>) get owns: surname, get annotation contain: @<annotation>
    When transaction commits
    When connection opens read transaction for database: typedb
    Then <root-type>(<type-name>) get owns: name, get annotation is empty
    Then <root-type>(<type-name>) get owns: surname, get annotation contain: @<annotation>
    Examples:
      | root-type | type-name   | annotation       | value-type |
      | entity    | person      | key              | string     |
      | entity    | person      | unique           | string     |
      | entity    | person      | subkey(LABEL)    | string     |
      | entity    | person      | values("1", "2") | string     |
      | entity    | person      | range("1", "2")  | string     |
      | entity    | person      | card(1, 2)       | string     |
      | entity    | person      | regex("\S+")     | string     |
      | relation  | description | key              | string     |
      | relation  | description | unique           | string     |
      | relation  | description | subkey(LABEL)    | string     |
      | relation  | description | values("1", "2") | string     |
      | relation  | description | range("1", "2")  | string     |
      | relation  | description | card(1, 2)       | string     |
      | relation  | description | regex("\S+")     | string     |

  Scenario Outline: <root-type> types can inherit owns with @<annotation>s and pure owns that are subtypes of each other
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
    When <root-type>(<supertype-name>) set annotation: @abstract
    When <root-type>(<supertype-name>) set owns: username
    When <root-type>(<supertype-name>) get owns: username, set annotation: @<annotation>
    When <root-type>(<supertype-name>) set owns: score
    When <root-type>(<subtype-name>) set annotation: @abstract
    When <root-type>(<subtype-name>) set owns: reference
    When <root-type>(<subtype-name>) get owns: reference, set annotation: @<annotation>
    When <root-type>(<subtype-name>) set owns: rating
    Then <root-type>(<subtype-name>) get owns contain:
      | username  |
      | reference |
      | score     |
      | rating    |
    Then <root-type>(<subtype-name>) get declared owns contain:
      | reference |
      | rating    |
    Then <root-type>(<subtype-name>) get declared owns do not contain:
      | username |
      | score    |
    Then <root-type>(<subtype-name>) get owns: username, get annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get owns: reference, get annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get owns: score, get annotations do not contain: @<annotation>
    Then <root-type>(<subtype-name>) get owns: rating, get annotations do not contain: @<annotation>
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then <root-type>(<subtype-name>) get owns contain:
      | username  |
      | reference |
      | score     |
      | rating    |
    Then <root-type>(<subtype-name>) get declared owns contain:
      | reference |
      | rating    |
    Then <root-type>(<subtype-name>) get declared owns do not contain:
      | username |
      | score    |
    Then <root-type>(<subtype-name>) get owns: username, get annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get owns: reference, get annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get owns: score, get annotations do not contain: @<annotation>
    Then <root-type>(<subtype-name>) get owns: rating, get annotations do not contain: @<annotation>
    When put attribute type: license
    When attribute(license) set value-type: string
    When attribute(license) set supertype: reference
    When put attribute type: points
    When attribute(points) set value-type: double
    When attribute(points) set supertype: rating
    When <root-type>(<subtype-name-2>) set annotation: @abstract
    When <root-type>(<subtype-name-2>) set supertype: <subtype-name>
    When <root-type>(<subtype-name-2>) set owns: license
    When <root-type>(<subtype-name-2>) get owns: license, set annotation: @<annotation>
    When <root-type>(<subtype-name-2>) set owns: points
    Then <root-type>(<subtype-name-2>) get owns contain:
      | username  |
      | reference |
      | license   |
      | score     |
      | rating    |
      | points    |
    Then <root-type>(<subtype-name-2>) get declared owns contain:
      | license |
      | points  |
    Then <root-type>(<subtype-name-2>) get declared owns do not contain:
      | username  |
      | reference |
      | score     |
      | rating    |
    When transaction commits
    When connection opens read transaction for database: typedb
    Then <root-type>(<subtype-name>) get owns contain:
      | username  |
      | reference |
      | score     |
      | rating    |
    Then <root-type>(<subtype-name>) get declared owns contain:
      | reference |
      | rating    |
    Then <root-type>(<subtype-name>) get declared owns do not contain:
      | username |
      | score    |
    Then <root-type>(<subtype-name>) get owns: username, get annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get owns: reference, get annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get owns: score, get annotations do not contain: @<annotation>
    Then <root-type>(<subtype-name>) get owns: rating, get annotations do not contain: @<annotation>
    Then <root-type>(<subtype-name-2>) get owns contain:
      | username  |
      | reference |
      | license   |
      | score     |
      | rating    |
      | points    |
    Then <root-type>(<subtype-name-2>) get declared owns contain:
      | license |
      | points  |
    Then <root-type>(<subtype-name-2>) get declared owns do not contain:
      | username  |
      | reference |
      | score     |
      | rating    |
    Then <root-type>(<subtype-name-2>) get owns: username, get annotations contain: @<annotation>
    Then <root-type>(<subtype-name-2>) get owns: reference, get annotations contain: @<annotation>
    Then <root-type>(<subtype-name-2>) get owns: license, get annotations contain: @<annotation>
    Then <root-type>(<subtype-name-2>) get owns: score, get annotations do not contain: @<annotation>
    Then <root-type>(<subtype-name-2>) get owns: rating, get annotations do not contain: @<annotation>
    Then <root-type>(<subtype-name-2>) get owns: points, get annotations do not contain: @<annotation>
    Examples:
      | root-type | supertype-name | subtype-name | subtype-name-2 | annotation       |
      | entity    | person         | customer     | subscriber     | key              |
      | entity    | person         | customer     | subscriber     | unique           |
      | entity    | person         | customer     | subscriber     | subkey(LABEL)    |
      | entity    | person         | customer     | subscriber     | values("1", "2") |
      | entity    | person         | customer     | subscriber     | range("1", "2")  |
      | entity    | person         | customer     | subscriber     | card(1, 2)       |
      | entity    | person         | customer     | subscriber     | regex("\S+")     |
      | relation  | description    | registration | profile        | key              |
      | relation  | description    | registration | profile        | unique           |
      | relation  | description    | registration | profile        | subkey(LABEL)    |
      | relation  | description    | registration | profile        | values("1", "2") |
      | relation  | description    | registration | profile        | range("1", "2")  |
      | relation  | description    | registration | profile        | card(1, 2)       |
      | relation  | description    | registration | profile        | regex("\S+")     |

  Scenario Outline: <root-type> types can override inherited owns with @<annotation>s and pure owns
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
    When <root-type>(<supertype-name>) set annotation: @abstract
    When <root-type>(<supertype-name>) set owns: username
    When <root-type>(<supertype-name>) get owns: username, set annotation: @<annotation>
    When <root-type>(<supertype-name>) set owns: email
    When <root-type>(<supertype-name>) get owns: email, set annotation: @<annotation>
    When <root-type>(<supertype-name>) set owns: name
    When <root-type>(<supertype-name>) set owns: age
    When <root-type>(<subtype-name>) set annotation: @abstract
    When <root-type>(<subtype-name>) set owns: reference
    When <root-type>(<subtype-name>) get owns: reference, set annotation: @<annotation>
    When <root-type>(<subtype-name>) set owns: work-email
    When <root-type>(<subtype-name>) get owns: work-email; set override: email
    When <root-type>(<subtype-name>) set owns: rating
    When <root-type>(<subtype-name>) set owns: nick-name
    When <root-type>(<subtype-name>) get owns: nick-name; set override: name
    Then <root-type>(<subtype-name>) get owns overridden(work-email) get label: email
    Then <root-type>(<subtype-name>) get owns overridden(nick-name) get label: name
    Then <root-type>(<subtype-name>) get owns contain:
      | username   |
      | reference  |
      | work-email |
      | age        |
      | rating     |
      | nick-name  |
    Then <root-type>(<subtype-name>) get owns do not contain:
      | email |
      | name  |
    Then <root-type>(<subtype-name>) get declared owns contain:
      | reference  |
      | work-email |
      | rating     |
      | nick-name  |
    Then <root-type>(<subtype-name>) get declared owns do not contain:
      | username |
      | age      |
      | email    |
      | name     |
    Then <root-type>(<subtype-name>) get owns: username, get annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get owns: reference, get annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get owns: work-email, get annotations contain: @<annotation>
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then <root-type>(<subtype-name>) get owns overridden(work-email) get label: email
    Then <root-type>(<subtype-name>) get owns overridden(nick-name) get label: name
    Then <root-type>(<subtype-name>) get owns contain:
      | username   |
      | reference  |
      | work-email |
      | age        |
      | rating     |
      | nick-name  |
    Then <root-type>(<subtype-name>) get owns do not contain:
      | email |
      | name  |
    Then <root-type>(<subtype-name>) get declared owns contain:
      | reference  |
      | work-email |
      | rating     |
      | nick-name  |
    Then <root-type>(<subtype-name>) get declared owns do not contain:
      | username |
      | age      |
      | email    |
      | name     |
    Then <root-type>(<subtype-name>) get owns: username, get annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get owns: reference, get annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get owns: work-email, get annotations contain: @<annotation>
    When put attribute type: license
    When attribute(license) set value-type: string
    When attribute(license) set supertype: reference
    When put attribute type: points
    When attribute(points) set value-type: double
    When attribute(points) set supertype: rating
    When <root-type>(<subtype-name-2>) set supertype: <subtype-name>
    When <root-type>(<subtype-name-2>) set owns: license
    When <root-type>(<subtype-name-2>) get owns: license; set override: reference
    When <root-type>(<subtype-name-2>) set owns: points
    When <root-type>(<subtype-name-2>) get owns: points; set override: rating
    When transaction commits
    When connection opens read transaction for database: typedb
    Then <root-type>(<subtype-name>) get owns contain:
      | username   |
      | reference  |
      | work-email |
      | age        |
      | rating     |
      | nick-name  |
    Then <root-type>(<subtype-name>) get owns do not contain:
      | email |
      | name  |
    Then <root-type>(<subtype-name>) get declared owns contain:
      | reference  |
      | work-email |
      | rating     |
      | nick-name  |
    Then <root-type>(<subtype-name>) get declared owns do not contain:
      | username |
      | age      |
      | email    |
      | name     |
    Then <root-type>(<subtype-name>) get owns: username, get annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get owns: reference, get annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get owns: work-email, get annotations contain: @<annotation>
    Then <root-type>(<subtype-name-2>) get owns overridden(license) get label: reference
    Then <root-type>(<subtype-name-2>) get owns overridden(points) get label: rating
    Then <root-type>(<subtype-name-2>) get owns contain:
      | username   |
      | license    |
      | work-email |
      | age        |
      | points     |
      | nick-name  |
    Then <root-type>(<subtype-name-2>) get owns do not contain:
      | email     |
      | reference |
      | name      |
      | rating    |
    Then <root-type>(<subtype-name-2>) get declared owns contain:
      | license |
      | points  |
    Then <root-type>(<subtype-name-2>) get declared owns do not contain:
      | username   |
      | work-email |
      | age        |
      | nick-name  |
      | email      |
      | reference  |
      | name       |
      | rating     |
    Then <root-type>(<subtype-name-2>) get owns: username, get annotations contain: @<annotation>
    Then <root-type>(<subtype-name-2>) get owns: license, get annotations contain: @<annotation>
    Then <root-type>(<subtype-name-2>) get owns: work-email, get annotations contain: @<annotation>
    Examples:
      | root-type | supertype-name | subtype-name | subtype-name-2 | annotation       |
      | entity    | person         | customer     | subscriber     | key              |
      | entity    | person         | customer     | subscriber     | unique           |
      | entity    | person         | customer     | subscriber     | subkey(LABEL)    |
      | entity    | person         | customer     | subscriber     | values("1", "2") |
      | entity    | person         | customer     | subscriber     | range("1", "2")  |
      | entity    | person         | customer     | subscriber     | card(1, 2)       |
      | entity    | person         | customer     | subscriber     | regex("\S+")     |
      | relation  | description    | registration | profile        | key              |
      | relation  | description    | registration | profile        | unique           |
      | relation  | description    | registration | profile        | subkey(LABEL)    |
      | relation  | description    | registration | profile        | values("1", "2") |
      | relation  | description    | registration | profile        | range("1", "2")  |
      | relation  | description    | registration | profile        | card(1, 2)       |
      | relation  | description    | registration | profile        | regex("\S+")     |

########################
# @key
########################

  Scenario Outline: Owns can set @key annotation for <value-type> value type and unset it
    When put attribute type: custom-attribute
    When attribute(custom-attribute) set value-type: <value-type>
    When entity(person) set owns: custom-attribute
    When entity(person) get owns: custom-attribute, set annotation: @key
    Then entity(person) get owns: custom-attribute, get annotations contain: @key
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then entity(person) get owns: custom-attribute, get annotations contain: @key
    When entity(person) get owns: custom-attribute, unset annotation: @key
    Then entity(person) get owns: custom-attribute, get annotations is empty
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then entity(person) get owns: custom-attribute, get annotations is empty
    When entity(person) get owns: custom-attribute, set annotation: @key
    Then entity(person) get owns: custom-attribute, get annotations contain: @key
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then entity(person) get owns: custom-attribute, get annotations contain: @key
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

  Scenario Outline: Owns cannot set @key annotation for <value-type> as it is not keyable
    When put attribute type: custom-attribute
    When attribute(custom-attribute) set value-type: <value-type>
    When entity(person) set owns: custom-attribute
    Then entity(person) get owns: custom-attribute, set annotation: @key; fails
    Then entity(person) get owns: custom-attribute, get annotations is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(person) get owns: custom-attribute, get annotations is empty
    Examples:
      | value-type    |
      | double        |
      | decimal       |
      | custom-struct |

  Scenario Outline: Owns cannot set @key annotation for lists
    When put attribute type: custom-attribute
    When attribute(custom-attribute) set value-type: <value-type>
    When entity(person) set owns: custom-attribute[]
    Then entity(person) get owns: custom-attribute[], set annotation: @key; fails
    Then entity(person) get owns: custom-attribute[], get annotations is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(person) get owns: custom-attribute[], get annotations is empty
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

########################
# @subkey
########################

  Scenario Outline: Owns can set @subkey annotation for <value-type> value type and unset it
    When put attribute type: custom-attribute
    When attribute(custom-attribute) set value-type: <value-type>
    When entity(person) set owns: custom-attribute
    When entity(person) get owns: custom-attribute, set annotation: @subkey(<arg>)
    Then entity(person) get owns: custom-attribute, get annotations contain: @subkey(<arg>)
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then entity(person) get owns: custom-attribute, get annotations contain: @subkey(<arg>)
    When entity(person) get owns: custom-attribute, unset annotation: @subkey(<arg>)
    Then entity(person) get owns: custom-attribute, get annotations is empty
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then entity(person) get owns: custom-attribute, get annotations is empty
    When entity(person) get owns: custom-attribute, set annotation: @subkey(<arg>)
    Then entity(person) get owns: custom-attribute, get annotations contain: @subkey(<arg>)
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then entity(person) get owns: custom-attribute, get annotations contain: @subkey(<arg>)
    When entity(person) unset owns: custom-attribute
    Then entity(person) get owns is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(person) get owns is empty
    Examples:
      | value-type | arg                   |
      | long       | LABEL                 |
      | string     | label                 |
      | boolean    | lAbEl_Of_FoRmaT       |
      | datetime   | l                     |
      | datetimetz | l2                    |
      | duration   | trydigits2723andafter |

  Scenario Outline: Owns can set @subkey annotation for multiple attributes of <root-type> type
    When put attribute type: first-name
    When attribute(first-name) set value-type: string
    When put attribute type: second-name
    When attribute(second-name) set value-type: string
    When put attribute type: third-name
    When attribute(third-name) set value-type: string
    When put attribute type: birthday
    When attribute(birthday) set value-type: datetime
    When put attribute type: balance
    When attribute(balance) set value-type: decimal
    When put attribute type: progress
    When attribute(progress) set value-type: double
    When put attribute type: age
    When attribute(age) set value-type: long
    When <root-type>(<type-name>) set owns: first-name
    When <root-type>(<type-name>) get owns: first-name, set annotation: @subkey(primary)
    Then <root-type>(<type-name>) get owns: first-name, get annotations contain: @subkey(primary)
    When <root-type>(<type-name>) set owns: second-name
    When <root-type>(<type-name>) get owns: second-name, set annotation: @subkey(primary)
    Then <root-type>(<type-name>) get owns: second-name, get annotations contain: @subkey(primary)
    When <root-type>(<type-name>) set owns: third-name
    When <root-type>(<type-name>) get owns: third-name, set annotation: @subkey(optional)
    Then <root-type>(<type-name>) get owns: third-name, get annotations contain: @subkey(optional)
    When <root-type>(<type-name>) set owns: birthday
    When <root-type>(<type-name>) get owns: birthday, set annotation: @subkey(primary)
    Then <root-type>(<type-name>) get owns: birthday, get annotations contain: @subkey(primary)
    When <root-type>(<type-name>) set owns: balance
    When <root-type>(<type-name>) get owns: balance, set annotation: @subkey(single)
    Then <root-type>(<type-name>) get owns: balance, get annotations contain: @subkey(single)
    When <root-type>(<type-name>) set owns: progress
    When <root-type>(<type-name>) get owns: progress, set annotation: @subkey(optional)
    Then <root-type>(<type-name>) get owns: progress, get annotations contain: @subkey(optional)
    When <root-type>(<type-name>) set owns: age
    When <root-type>(<type-name>) get owns: age, set annotation: @subkey(primary)
    Then <root-type>(<type-name>) get owns: age, get annotations contain: @subkey(primary)
    When transaction commits
    When connection opens read transaction for database: typedb
    Then <root-type>(<type-name>) get owns: first-name, get annotations contain: @subkey(primary)
    Then <root-type>(<type-name>) get owns: second-name, get annotations contain: @subkey(primary)
    Then <root-type>(<type-name>) get owns: third-name, get annotations contain: @subkey(optional)
    Then <root-type>(<type-name>) get owns: birthday, get annotations contain: @subkey(primary)
    Then <root-type>(<type-name>) get owns: balance, get annotations contain: @subkey(single)
    Then <root-type>(<type-name>) get owns: progress, get annotations contain: @subkey(optional)
    Then <root-type>(<type-name>) get owns: age, get annotations contain: @subkey(primary)
    Examples:
      | root-type | type-name   |
      | entity    | person      |
      | relation  | description |

  Scenario: Owns can set multiple @subkey annotations with different arguments
    When put attribute type: name
    When attribute(name) set value-type: string
    When put attribute type: surname
    When attribute(surname) set value-type: string
    When put attribute type: age
    When attribute(age) set value-type: long
    When entity(person) set owns: name
    When entity(person) get owns: name, set annotation: @subkey(NAME-AGE)
    When entity(person) get owns: name, set annotation: @subkey(FULL-NAME)
    Then entity(person) get owns: name, get annotations contain:
      | @subkey(NAME-AGE)  |
      | @subkey(FULL-NAME) |
    When entity(person) set owns: surname
    When entity(person) get owns: surname, set annotation: @subkey(FULL-NAME)
    Then entity(person) get owns: surname, get annotations contain: @subkey(FULL-NAME)
    When entity(person) set owns: age
    When entity(person) get owns: age, set annotation: @subkey(NAME-AGE)
    Then entity(person) get owns: age, get annotations contain: @subkey(NAME-AGE)
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(person) get owns: name, get annotations contain:
      | @subkey(NAME-AGE)  |
      | @subkey(FULL-NAME) |
    Then entity(person) get owns: surname, get annotations contain: @subkey(FULL-NAME)
    Then entity(person) get owns: age, get annotations contain: @subkey(NAME-AGE)

  Scenario Outline: Owns cannot set @subkey annotation for <value-type> as it is not keyable
    When put attribute type: custom-attribute
    When attribute(custom-attribute) set value-type: <value-type>
    When entity(person) set owns: custom-attribute
    Then entity(person) get owns: custom-attribute, set annotation: @subkey(LABEL); fails
    Then entity(person) get owns: custom-attribute, get annotations is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(person) get owns: custom-attribute, get annotations is empty
    Examples:
      | value-type    |
      | double        |
      | decimal       |
      | custom-struct |

  Scenario: Owns cannot set @subkey annotation for incorrect arguments
    When put attribute type: custom-attribute
    When attribute(custom-attribute) set value-type: long
    When entity(person) set owns: custom-attribute
    # TODO: Move the case to successful cases if it should work!
    Then entity(person) get owns: custom-attribute, set annotation: @subkey; fails
    Then entity(person) get owns: custom-attribute, set annotation: @subkey(); fails
    Then entity(person) get owns: custom-attribute, set annotation: @subkey("LABEL"); fails
    Then entity(person) get owns: custom-attribute, set annotation: @subkey(福); fails
    Then entity(person) get owns: custom-attribute, set annotation: @subkey(d./';;p480909!208923r09zlmk*((*£*()(@£Q**&$@)); fails
    Then entity(person) get owns: custom-attribute, set annotation: @subkey(49j93848); fails
    Then entity(person) get owns: custom-attribute, set annotation: @subkey(LABEL, LABEL); fails
    Then entity(person) get owns: custom-attribute, set annotation: @subkey(LABEL, LABEL2); fails
    Then entity(person) get owns: custom-attribute, set annotation: @subkey(LABEL, LABEL2, LABEL3); fails
    Then entity(person) get owns: custom-attribute, get annotations is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(person) get owns: custom-attribute, get annotations is empty

  Scenario Outline: Owns cannot set @subkey annotation for lists
    When put attribute type: custom-attribute
    When attribute(custom-attribute) set value-type: <value-type>
    When entity(person) set owns: custom-attribute[]
    Then entity(person) get owns: custom-attribute[], set annotation: @subkey(LABEL); fails
    Then entity(person) get owns: custom-attribute[], get annotations is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(person) get owns: custom-attribute[], get annotations is empty
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

########################
# @unique
########################

  Scenario Outline: Owns can set @unique annotation for <value-type> value type and unset it
    When put attribute type: custom-attribute
    When attribute(custom-attribute) set value-type: <value-type>
    When entity(person) set owns: custom-attribute
    When entity(person) get owns: custom-attribute, set annotation: @unique
    Then entity(person) get owns: custom-attribute, get annotations contain: @unique
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then entity(person) get owns: custom-attribute, get annotations contain: @unique
    When entity(person) get owns: custom-attribute, unset annotation: @unique
    Then entity(person) get owns: custom-attribute, get annotations is empty
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then entity(person) get owns: custom-attribute, get annotations is empty
    When entity(person) get owns: custom-attribute, set annotation: @unique
    Then entity(person) get owns: custom-attribute, get annotations contain: @unique
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then entity(person) get owns: custom-attribute, get annotations contain: @unique
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

  Scenario Outline: Owns cannot set @unique annotation for <value-type> as it is not keyable
    When put attribute type: custom-attribute
    When attribute(custom-attribute) set value-type: <value-type>
    When entity(person) set owns: custom-attribute
    Then entity(person) get owns: custom-attribute, set annotation: @unique; fails
    Then entity(person) get owns: custom-attribute, get annotations is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(person) get owns: custom-attribute, get annotations is empty
    Examples:
      | value-type    |
      | double        |
      | decimal       |
      | custom-struct |

  # TODO: Change the test if owns can set @unique annotation for lists!
  Scenario Outline: Owns cannot set @unique annotation for lists
    When put attribute type: custom-attribute
    When attribute(custom-attribute) set value-type: <value-type>
    When entity(person) set owns: custom-attribute[]
    Then entity(person) get owns: custom-attribute[], set annotation: @unique; fails
    Then entity(person) get owns: custom-attribute[], get annotations is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(person) get owns: custom-attribute[], get annotations is empty
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

########################
# @values
########################

  Scenario Outline: Owns can set @values annotation for <value-type> value type and lists and unset it
    When put attribute type: custom-attribute
    When attribute(custom-attribute) set value-type: <value-type>
    When put attribute type: custom-attribute-2
    When attribute(custom-attribute-2) set value-type: <value-type>
    When entity(person) set owns: custom-attribute
    When entity(person) get owns: custom-attribute, set annotation: @values(<args>)
    Then entity(person) get owns: custom-attribute, get annotations contain: @values(<args>)
    When entity(person) set owns: custom-attribute-2[]
    When entity(person) get owns: custom-attribute-2[], set annotation: @values(<args>)
    Then entity(person) get owns: custom-attribute-2[], get annotations contain: @values(<args>)
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then entity(person) get owns: custom-attribute, get annotations contain: @values(<args>)
    Then entity(person) get owns: custom-attribute-2[], get annotations contain: @values(<args>)
    When entity(person) unset owns: custom-attribute
    When entity(person) unset owns: custom-attribute-2[]
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
      | string     | "This rank contain a sufficiently detailed description of its nature"                                                                                                                                                                                                                                                                                                                                |
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

  Scenario Outline: Owns cannot have @values annotation with empty args
    When put attribute type: custom-attribute
    When attribute(custom-attribute) set value-type: <value-type>
    When entity(person) set owns: custom-attribute
    Then entity(person) get owns: custom-attribute, set annotation: @values; fails
    Then entity(person) get owns: custom-attribute, set annotation: @values(); fails
    Then entity(person) get owns: custom-attribute, get annotations is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(person) get owns: custom-attribute, get annotations is empty
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

  Scenario Outline: Owns cannot have @values annotation for <value-type> value type with args of invalid value or type
    When put attribute type: custom-attribute
    When attribute(custom-attribute) set value-type: <value-type>
    When entity(player) set owns: custom-attribute
    Then entity(player) get owns: custom-attribute, set annotation: @values(<args>); fails
    Then entity(player) get owns: custom-attribute, get annotations is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(player) get owns: custom-attribute, get annotations is empty
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
      | string     | ""                              |
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

  Scenario Outline: Owns cannot have @values annotation for <value-type> value type with duplicated args
    When put attribute type: custom-attribute
    When attribute(custom-attribute) set value-type: <value-type>
    When entity(player) set owns: custom-attribute
    Then entity(player) get owns: custom-attribute, set annotation: @values(<arg0>, <arg1>, <arg2>); fails
    Then entity(player) get owns: custom-attribute, get annotations is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(player) get owns: custom-attribute, get annotations is empty
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

  Scenario: Owns cannot set multiple @values annotations with different arguments
    When put attribute type: name
    When attribute(name) set value-type: string
    When entity(person) set owns: name
    When entity(person) get owns: name, set annotation: @values("hi", "HI")
    Then entity(person) get owns: name, set annotation: @values("Hi"); fails
    Then entity(person) get owns: name, get annotations contain: @values("hi", "HI")
    Then entity(person) get owns: name, get annotations do not contain: @values("Hi")
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(person) get owns: name, get annotations contain: @values("hi", "HI")
    Then entity(person) get owns: name, get annotations do not contain: @values("Hi")

  Scenario Outline: Owns-related @values annotation for <value-type> value type can be inherited and overridden by a subset of args
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
    Then entity(person) get owns: custom-attribute, get annotations contain: @values(<args>)
    Then relation(contract) get owns: custom-attribute, get annotations contain: @values(<args>)
    When entity(person) get owns: second-custom-attribute, set annotation: @values(<args>)
    When relation(contract) get owns: second-custom-attribute, set annotation: @values(<args>)
    Then entity(person) get owns: second-custom-attribute, get annotations contain: @values(<args>)
    Then relation(contract) get owns: second-custom-attribute, get annotations contain: @values(<args>)
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

  Scenario Outline: Inherited @values annotation on owns for <value-type> value type cannot be overridden by the @values of same args or not a subset of args
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
    Then entity(person) get owns: custom-attribute, get annotations contain: @values(<args>)
    Then relation(contract) get owns: custom-attribute, get annotations contain: @values(<args>)
    When entity(person) get owns: second-custom-attribute, set annotation: @values(<args>)
    When relation(contract) get owns: second-custom-attribute, set annotation: @values(<args>)
    Then entity(person) get owns: second-custom-attribute, get annotations contain: @values(<args>)
    Then relation(contract) get owns: second-custom-attribute, get annotations contain: @values(<args>)
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

########################
# @range
########################

  Scenario Outline: Owns can set @range annotation for <value-type> value type and lists in correct order and unset it
    When put attribute type: custom-attribute
    When attribute(custom-attribute) set value-type: <value-type>
    When put attribute type: custom-attribute-2
    When attribute(custom-attribute-2) set value-type: <value-type>
    When entity(person) set owns: custom-attribute
    Then entity(player) get owns: custom-attribute, set annotation: @range(<arg1>, <arg0>); fails
    Then entity(person) get owns: custom-attribute, get annotations is empty
    When entity(person) get owns: custom-attribute, set annotation: @range(<arg0>, <arg1>)
    Then entity(person) get owns: custom-attribute, get annotations contain: @range(<arg0>, <arg1>)
    When entity(person) set owns: custom-attribute-2[]
    Then entity(player) get owns: custom-attribute-2[], set annotation: @range(<arg1>, <arg0>); fails
    Then entity(person) get owns: custom-attribute-2[], get annotations is empty
    When entity(person) get owns: custom-attribute-2[], set annotation: @range(<arg0>, <arg1>)
    Then entity(person) get owns: custom-attribute-2[], get annotations contain: @range(<arg0>, <arg1>)
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then entity(person) get owns: custom-attribute, get annotations contain: @range(<arg0>, <arg1>)
    Then entity(person) get owns: custom-attribute-2[], get annotations contain: @range(<arg0>, <arg1>)
    When entity(person) unset owns: custom-attribute
    When entity(person) unset owns: custom-attribute-2[]
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

  Scenario Outline: Owns cannot have @range annotation for <value-type> value type with less than two args
    When put attribute type: custom-attribute
    When attribute(custom-attribute) set value-type: <value-type>
    When entity(person) set owns: custom-attribute
    Then entity(person) get owns: custom-attribute, set annotation: @range; fails
    Then entity(person) get owns: custom-attribute, set annotation: @range(); fails
    Then entity(person) get owns: custom-attribute, set annotation: @range(<arg0>); fails
    Then entity(person) get owns: custom-attribute, get annotations is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(person) get owns: custom-attribute, get annotations is empty
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
  Scenario Outline: Owns cannot have @range annotation for <value-type> value type with invalid args or args number
    When put attribute type: custom-attribute
    When attribute(custom-attribute) set value-type: <value-type>
    When entity(player) set owns: custom-attribute
    Then entity(player) get owns: custom-attribute, set annotation: @range(<arg0>, <args>); fails
    Then entity(player) get owns: custom-attribute, get annotations is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(player) get owns: custom-attribute, get annotations is empty
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
      | string     | ""                              | "str"                                              |
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

  Scenario Outline: Owns cannot set multiple @range annotations with different arguments
    When put attribute type: name
    When attribute(name) set value-type: long
    When entity(person) set owns: name
    When entity(person) get owns: name, set annotation: @range(2, 5)
    Then entity(person) get owns: name, set annotation: @range(<fail-args>); fails
    Then entity(person) get owns: name, set annotation: @range(<fail-args>); fails
    Then entity(person) get owns: name, get annotations contain: @range(2, 5)
    Then entity(person) get owns: name, get annotations do not contain: @range(<fail-args>)
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(person) get owns: name, get annotations contain: @range(2, 5)
    Then entity(person) get owns: name, get annotations do not contain: @range(<fail-args>)
    Examples:
      | fail-args |
      | 0, 1      |
      | 0, 2      |
      | 0, 3      |
      | 0, 5      |
      | 0, 6      |
      | 2, 3      |
      | 2, 5      |
      | 2, 6      |
      | 3, 4      |
      | 3, 5      |
      | 3, 6      |
      | 5, 6      |
      | 6, 10     |

  Scenario Outline: Owns-related @range annotation for <value-type> value type can be inherited and overridden by a subset of args
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
    Then entity(person) get owns: custom-attribute, get annotations contain: @range(<args>)
    Then relation(contract) get owns: custom-attribute, get annotations contain: @range(<args>)
    When entity(person) get owns: second-custom-attribute, set annotation: @range(<args>)
    When relation(contract) get owns: second-custom-attribute, set annotation: @range(<args>)
    Then entity(person) get owns: second-custom-attribute, get annotations contain: @range(<args>)
    Then relation(contract) get owns: second-custom-attribute, get annotations contain: @range(<args>)
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

  Scenario Outline: Inherited @range annotation on owns for <value-type> value type cannot be overridden by the @range of same args or not a subset of args
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
    Then entity(person) get owns: custom-attribute, get annotations contain: @range(<args>)
    Then relation(contract) get owns: custom-attribute, get annotations contain: @range(<args>)
    When entity(person) get owns: second-custom-attribute, set annotation: @range(<args>)
    When relation(contract) get owns: second-custom-attribute, set annotation: @range(<args>)
    Then entity(person) get owns: second-custom-attribute, get annotations contain: @range(<args>)
    Then relation(contract) get owns: second-custom-attribute, get annotations contain: @range(<args>)
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

########################
# @card
########################

  Scenario Outline: Owns can set @card annotation for <value-type> value type with args in correct order and unset it
    When put attribute type: custom-attribute
    When attribute(custom-attribute) set value-type: <value-type>
    When put attribute type: custom-attribute-2
    When attribute(custom-attribute-2) set value-type: <value-type>
    When entity(person) set owns: custom-attribute
    Then entity(player) get owns: custom-attribute, set annotation: @card(<arg1>, <arg0>); fails
    Then entity(person) get owns: custom-attribute, get annotations is empty
    When entity(person) get owns: custom-attribute, set annotation: @card(<arg0>, <arg1>)
    Then entity(person) get owns: custom-attribute, get annotations contain: @card(<arg0>, <arg1>)
    When entity(person) set owns: custom-attribute-2[]
    Then entity(player) get owns: custom-attribute-2[], set annotation: @card(<arg1>, <arg0>); fails
    Then entity(person) get owns: custom-attribute-2[], get annotations is empty
    When entity(person) get owns: custom-attribute-2[], set annotation: @card(<arg0>, <arg1>)
    Then entity(person) get owns: custom-attribute-2[], get annotations contain: @card(<arg0>, <arg1>)
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then entity(person) get owns: custom-attribute, get annotations contain: @card(<arg0>, <arg1>)
    Then entity(person) get owns: custom-attribute-2[], get annotations contain: @card(<arg0>, <arg1>)
    When entity(person) unset owns: custom-attribute
    When entity(person) unset owns: custom-attribute-2[]
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
    When put attribute type: custom-attribute
    When attribute(custom-attribute) set value-type: <value-type>
    When entity(person) set owns: custom-attribute
    Then entity(person) get owns: custom-attribute, get annotations is empty
    When entity(person) get owns: custom-attribute, set annotation: @card(<arg>, <arg>)
    Then entity(person) get owns: custom-attribute, get annotations contain: @card(<arg>, <arg>)
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(person) get owns: custom-attribute, get annotations contain: @card(<arg>, <arg>)
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

  Scenario Outline: Owns cannot have @card annotation for <value-type> value type with less than two args
    When put attribute type: custom-attribute
    When attribute(custom-attribute) set value-type: <value-type>
    When entity(person) set owns: custom-attribute
    Then entity(person) get owns: custom-attribute, set annotation: @card; fails
    Then entity(person) get owns: custom-attribute, set annotation: @card(); fails
    Then entity(person) get owns: custom-attribute, set annotation: @card(1); fails
    Then entity(person) get owns: custom-attribute, set annotation: @card(*); fails
    Then entity(person) get owns: custom-attribute, get annotations is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(person) get owns: custom-attribute, get annotations is empty
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

  Scenario Outline: Owns cannot have @card annotation for <value-type> value type with invalid args or args number
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
    Then entity(player) get owns: custom-attribute, get annotations is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(player) get owns: custom-attribute, get annotations is empty
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

  Scenario Outline: Owns cannot set multiple @card annotations with different arguments
    When put attribute type: name
    When attribute(name) set value-type: long
    When entity(person) set owns: name
    When entity(person) get owns: name, set annotation: @card(2, 5)
    Then entity(person) get owns: name, set annotation: @card(<fail-args>); fails
    Then entity(person) get owns: name, set annotation: @card(<fail-args>); fails
    Then entity(person) get owns: name, get annotations contain: @card(2, 5)
    Then entity(person) get owns: name, get annotations do not contain: @card(<fail-args>)
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(person) get owns: name, get annotations contain: @card(2, 5)
    Then entity(person) get owns: name, get annotations do not contain: @card(<fail-args>)
    Examples:
      | fail-args |
      | 0, 1      |
      | 0, 2      |
      | 0, 3      |
      | 0, 5      |
      | 0, *      |
      | 2, 3      |
      | 2, 5      |
      | 2, *      |
      | 3, 4      |
      | 3, 5      |
      | 3, *      |
      | 5, *      |
      | 6, *      |

  Scenario Outline: Owns-related @card annotation for <value-type> value type can be inherited and overridden by a subset of args
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
    Then entity(person) get owns: custom-attribute, get annotations contain: @card(<args>)
    Then relation(contract) get owns: custom-attribute, get annotations contain: @card(<args>)
    When entity(person) get owns: second-custom-attribute, set annotation: @card(<args>)
    When relation(contract) get owns: second-custom-attribute, set annotation: @card(<args>)
    Then entity(person) get owns: second-custom-attribute, get annotations contain: @card(<args>)
    Then relation(contract) get owns: second-custom-attribute, get annotations contain: @card(<args>)
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

  Scenario Outline: Inherited @card annotation on owns for <value-type> value type cannot be overridden by the @card of same args or not a subset of args
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
    Then entity(person) get owns: custom-attribute, get annotations contain: @card(<args>)
    Then relation(contract) get owns: custom-attribute, get annotations contain: @card(<args>)
    When entity(person) get owns: second-custom-attribute, set annotation: @card(<args>)
    When relation(contract) get owns: second-custom-attribute, set annotation: @card(<args>)
    Then entity(person) get owns: second-custom-attribute, get annotations contain: @card(<args>)
    Then relation(contract) get owns: second-custom-attribute, get annotations contain: @card(<args>)
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

########################
# @distinct
########################

  Scenario Outline: Owns for <root-type> can set @distinct annotation for <value-type> value type list and unset it
    When put attribute type: custom-attribute
    When attribute(custom-attribute) set value-type: <value-type>
    When <root-type>(<type-name>) set owns: custom-attribute[]
    When <root-type>(<type-name>) get owns: custom-attribute[], set annotation: @distinct
    Then <root-type>(<type-name>) get owns: custom-attribute[], get annotations contain: @distinct
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then <root-type>(<type-name>) get owns: custom-attribute[], get annotations contain: @distinct
    When <root-type>(<type-name>) get owns: custom-attribute[], unset annotation: @distinct
    Then <root-type>(<type-name>) get owns: custom-attribute[], get annotations is empty
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then <root-type>(<type-name>) get owns: custom-attribute[], get annotations is empty
    When <root-type>(<type-name>) get owns: custom-attribute[], set annotation: @distinct
    Then <root-type>(<type-name>) get owns: custom-attribute[], get annotations contain: @distinct
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then <root-type>(<type-name>) get owns: custom-attribute[], get annotations contain: @distinct
    When <root-type>(<type-name>) unset owns: custom-attribute[]
    Then <root-type>(<type-name>) get owns is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then <root-type>(<type-name>) get owns is empty
    Examples:
      | root-type | type-name   | value-type    |
      | entity    | person      | long          |
      | entity    | person      | string        |
      | entity    | person      | boolean       |
      | entity    | person      | double        |
      | entity    | person      | decimal       |
      | entity    | person      | datetime      |
      | entity    | person      | datetimetz    |
      | entity    | person      | duration      |
      | entity    | person      | custom-struct |
      | relation  | description | long          |
      | relation  | description | string        |
      | relation  | description | boolean       |
      | relation  | description | double        |
      | relation  | description | decimal       |
      | relation  | description | datetime      |
      | relation  | description | datetimetz    |
      | relation  | description | duration      |
      | relation  | description | custom-struct |

  Scenario Outline: Owns for <root-type> cannot have @distinct annotation for <value-type> non-list value type
    When put attribute type: custom-attribute
    When attribute(custom-attribute) set value-type: <value-type>
    When <root-type>(<type-name>) set owns: custom-attribute
    Then <root-type>(<type-name>) get owns: custom-attribute, set annotation: @distinct; fails
    Then <root-type>(<type-name>) get owns: custom-attribute, get annotations is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then <root-type>(<type-name>) get owns: custom-attribute, get annotations is empty
    Examples:
      | root-type | type-name   | value-type    |
      | entity    | person      | long          |
      | entity    | person      | string        |
      | entity    | person      | boolean       |
      | entity    | person      | double        |
      | entity    | person      | decimal       |
      | entity    | person      | datetime      |
      | entity    | person      | datetimetz    |
      | entity    | person      | duration      |
      | entity    | person      | custom-struct |
      | relation  | description | long          |
      | relation  | description | string        |
      | relation  | description | boolean       |
      | relation  | description | double        |
      | relation  | description | decimal       |
      | relation  | description | datetime      |
      | relation  | description | datetimetz    |
      | relation  | description | duration      |
      | relation  | description | custom-struct |

  Scenario Outline: Owns cannot have @distinct annotation for <value-type> with args
    When put attribute type: custom-attribute
    When attribute(custom-attribute) set value-type: <value-type>
    When entity(person) set owns: custom-attribute
    Then entity(person) get owns: custom-attribute, set annotation: @distinct(); fails
    Then entity(person) get owns: custom-attribute, set annotation: @distinct(1); fails
    Then entity(person) get owns: custom-attribute, set annotation: @distinct("1"); fails
    Then entity(person) get owns: custom-attribute, get annotations is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(person) get owns: custom-attribute, get annotations is empty
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

  Scenario Outline: <root-type> types can redeclare owns as owns with @distinct
    When put attribute type: name
    When attribute(name) set value-type: <value-type>
    When put attribute type: email
    When attribute(email) set value-type: <value-type>
    When put attribute type: address
    When attribute(address) set value-type: <value-type>
    When <root-type>(<type-name>) set owns: name[]
    When <root-type>(<type-name>) set owns: email[]
    When <root-type>(<type-name>) set owns: address[]
    Then <root-type>(<type-name>) set owns: name[]
    Then <root-type>(<type-name>) get owns: name[], set annotation: @distinct
    Then <root-type>(<type-name>) get owns: name[], get annotations contain: @distinct
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then <root-type>(<type-name>) set owns: email[]
    Then <root-type>(<type-name>) get owns: email[], get annotations is empty
    When <root-type>(<type-name>) get owns: email[], set annotation: @distinct
    Then <root-type>(<type-name>) get owns: email[], get annotations contain: @distinct
    Then <root-type>(<type-name>) get owns: address[], get annotations is empty
    When <root-type>(<type-name>) get owns: address[], set annotation: @distinct
    Then <root-type>(<type-name>) get owns: address[], get annotations contain: @distinct
    Examples:
      | root-type | type-name   | value-type |
      | entity    | person      | string     |
      | entity    | person      | long       |
      | relation  | description | datetime   |
      | relation  | description | duration   |

  Scenario Outline: <root-type> types cannot unset not set @distinct of ownership of <value-type> value type
    When put attribute type: username
    When attribute(username) set value-type: <value-type>
    When put attribute type: reference
    When attribute(reference) set value-type: <value-type>
    When <root-type>(<type-name>) set owns: username[]
    When <root-type>(<type-name>) get owns: username[], set annotation: @distinct
    Then <root-type>(<type-name>) get owns: username[], get annotation contain: @distinct
    When <root-type>(<type-name>) set owns: reference[]
    Then <root-type>(<type-name>) get owns: reference[], unset annotation: @distinct; fails
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then <root-type>(<type-name>) get owns: username[], get annotation contain: @distinct
    Then <root-type>(<type-name>) get owns: reference[], unset annotation: @distinct; fails
    Then <root-type>(<type-name>) get owns: username[], unset annotation: @distinct
    Then <root-type>(<type-name>) get owns: username[], unset annotation: @distinct; fails
    Then <root-type>(<type-name>) get owns: username[], get annotations is empty
    Then <root-type>(<type-name>) get owns: reference[], get annotations is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then <root-type>(<type-name>) get owns: username[], get annotations is empty
    Then <root-type>(<type-name>) get owns: reference[], get annotations is empty
    Examples:
      | root-type | type-name   | value-type |
      | entity    | person      | string     |
      | entity    | person      | long       |
      | relation  | description | datetime   |
      | relation  | description | duration   |

  Scenario Outline: <root-type> types cannot unset @distinct of inherited ownership
    When put attribute type: username
    When attribute(username) set value-type: string
    When <root-type>(<supertype-name>) set owns: username
    When <root-type>(<supertype-name>) get owns: username, set annotation: @distinct
    Then <root-type>(<supertype-name>) get owns: username, get annotation contain: @distinct
    Then <root-type>(<subtype-name>) get owns: username, get annotation contain: @distinct
    Then <root-type>(<subtype-name>) get owns: username, unset annotation: @distinct; fails
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then <root-type>(<subtype-name>) get owns: username, get annotations contain: @distinct
    Then <root-type>(<subtype-name>) get owns: username, unset annotation: @distinct; fails
    Examples:
      | root-type | supertype-name | subtype-name |
      | entity    | person         | customer     |
      | relation  | description    | registration |

########################
# @regex
########################

  Scenario Outline: Owns can set @regex annotation for <value-type> value type and unset it
    When put attribute type: custom-attribute
    When attribute(custom-attribute) set value-type: <value-type>
    When put attribute type: custom-attribute-2
    When attribute(custom-attribute-2) set value-type: <value-type>
    When entity(person) set owns: custom-attribute
    When entity(person) get owns: custom-attribute, set annotation: @regex(<arg>)
    Then entity(person) get owns: custom-attribute, get annotations contain: @regex(<arg>)
    When entity(person) set owns: custom-attribute-2[]
    When entity(person) get owns: custom-attribute-2[], set annotation: @regex(<arg>)
    Then entity(person) get owns: custom-attribute-2[], get annotations contain: @regex(<arg>)
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then entity(person) get owns: custom-attribute, get annotations contain: @regex(<arg>)
    When entity(person) get owns: custom-attribute, unset annotation: @regex(<arg>)
    Then entity(person) get owns: custom-attribute, get annotations is empty
    Then entity(person) get owns: custom-attribute-2[], get annotations contain: @regex(<arg>)
    When entity(person) get owns: custom-attribute-2[], unset annotation: @regex(<arg>)
    Then entity(person) get owns: custom-attribute-2[], get annotations is empty
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then entity(person) get owns: custom-attribute, get annotations is empty
    When entity(person) get owns: custom-attribute, set annotation: @regex(<arg>)
    Then entity(person) get owns: custom-attribute, get annotations contain: @regex(<arg>)
    Then entity(person) get owns: custom-attribute-2[], get annotations is empty
    When entity(person) get owns: custom-attribute-2[], set annotation: @regex(<arg>)
    Then entity(person) get owns: custom-attribute-2[], get annotations contain: @regex(<arg>)
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then entity(person) get owns: custom-attribute, get annotations contain: @regex(<arg>)
    Then entity(person) get owns: custom-attribute-2[], get annotations contain: @regex(<arg>)
    When entity(person) unset owns: custom-attribute
    When entity(person) unset owns: custom-attribute-2[]
    Then entity(person) get owns is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(person) get owns is empty
    Examples:
      | value-type | arg                  |
      | string     | "value"              |
      | string     | "123.456"            |
      | string     | "\S+"                |
      | string     | "\S+@\S+\.\S+"       |
      | string     | "^starts"            |
      | string     | "ends$"              |
      | string     | "^starts and ends$"  |
      | string     | "^(one \| another)$" |
      | string     | "2024-06-04+0100"    |

  Scenario Outline: Owns cannot have @regex annotation for <value-type> value type
    When put attribute type: custom-attribute
    When attribute(custom-attribute) set value-type: <value-type>
    When entity(person) set owns: custom-attribute
    Then entity(person) get owns: custom-attribute, set annotation: @regex("\S+"); fails
    Then entity(person) get owns: custom-attribute, get annotations is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(person) get owns: custom-attribute, get annotations is empty
    Examples:
      | value-type    |
      | long          |
      | boolean       |
      | double        |
      | decimal       |
      | datetime      |
      | datetimetz    |
      | duration      |
      | custom-struct |

  Scenario Outline: Owns cannot have @regex annotation of invalid args
    When put attribute type: custom-attribute
    When attribute(custom-attribute) set value-type: <value-type>
    When entity(person) set owns: custom-attribute
    Then entity(person) get owns: custom-attribute, set annotation: @regex; fails
    Then entity(person) get owns: custom-attribute, set annotation: @regex(); fails
    Then entity(person) get owns: custom-attribute, set annotation: @regex(<args>); fails
    Then entity(person) get owns: custom-attribute, get annotations is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(person) get owns: custom-attribute, get annotations is empty
    Examples:
      | args                  |
      | ""                    |
      | "\S+", "\S+"          |
      | "one", "two", "three" |
      | 123                   |
      | 2024-06-04+0100       |
      | 2024-06-04            |
      | true                  |
      | 123.54543             |
      | value                 |
      | P1Y                   |

########################
# not compatible @annotations: @abstract, @cascade, @independent, @replace
########################

  Scenario Outline: Owns cannot have @abstract, @cascade, @independent, and @replace annotations for <value-type> value type
    When put attribute type: custom-attribute
    When attribute(custom-attribute) set value-type: <value-type>
    When entity(person) set owns: custom-attribute
    Then entity(person) get owns: custom-attribute, set annotation: @abstract; fails
    Then entity(person) get owns: custom-attribute, set annotation: @cascade; fails
    Then entity(person) get owns: custom-attribute, set annotation: @independent; fails
    Then entity(person) get owns: custom-attribute, set annotation: @replace; fails
    Then entity(person) get owns: custom-attribute, get annotations is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(person) get owns: custom-attribute, get annotations is empty
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

########################
# @annotations combinations
########################
  # TODO
  # @key, @unique, @subkey, @values, @range, @card, @regex, @distinct

  Scenario Outline: Owns can set @<annotation-1> and @<annotation-2> together and unset it for scalar <value-type>
    When put attribute type: custom-attribute
    When attribute(custom-attribute) set value-type: <value-type>
    When relation(description) set owns: custom-attribute
    When relation(description) get owns: custom-attribute, set annotation: @<annotation-1>
    When relation(description) get owns: custom-attribute, set annotation: @<annotation-2>
    Then relation(description) get owns: custom-attribute, get annotations contain:
      | @<annotation-1> |
      | @<annotation-2> |
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then relation(description) get owns: custom-attribute, get annotations contain:
      | @<annotation-1> |
      | @<annotation-2> |
    When relation(description) get owns: custom-attribute, unset annotation: @<annotation-1>
    Then relation(description) get owns: custom-attribute, get annotations do not contain: @<annotation-1>
    Then relation(description) get owns: custom-attribute, get annotations contain: @<annotation-2>
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then relation(description) get owns: custom-attribute, get annotations do not contain: @<annotation-1>
    Then relation(description) get owns: custom-attribute, get annotations contain: @<annotation-2>
    When relation(description) get owns: custom-attribute, set annotation: @<annotation-1>
    When relation(description) get owns: custom-attribute, unset annotation: @<annotation-2>
    Then relation(description) get owns: custom-attribute, get annotations do not contain: @<annotation-2>
    Then relation(description) get owns: custom-attribute, get annotations contain: @<annotation-1>
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then relation(description) get owns: custom-attribute, get annotations do not contain: @<annotation-2>
    Then relation(description) get owns: custom-attribute, get annotations contain: @<annotation-1>
    When relation(description) get owns: custom-attribute, unset annotation: @<annotation-1>
    Then relation(description) get owns: custom-attribute, get annotations is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then relation(description) get owns: custom-attribute, get annotations is empty
    Examples:
      | annotation-1 | annotation-2 | value-type |
      | key          |              | long       |
      | subkey       |              | double     |
      | unique       |              | decimal    |
      | values       |              | string     |
      | range        |              | datetime   |
      | card         |              | datetimetz |
      | regex        |              | duration   |
      | distinct     |              | string     |
    # TODO fill the values!
  
  Scenario Outline: Owns can set @<annotation-1> and @<annotation-2> together and unset it for lists of <value-type>
    When put attribute type: custom-attribute
    When attribute(custom-attribute) set value-type: <value-type>
    When relation(description) set owns: custom-attribute[]
    When relation(description) get owns: custom-attribute[], set annotation: @<annotation-1>
    When relation(description) get owns: custom-attribute[], set annotation: @<annotation-2>
    Then relation(description) get owns: custom-attribute[], get annotations contain:
      | @<annotation-1> |
      | @<annotation-2> |
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then relation(description) get owns: custom-attribute[], get annotations contain:
      | @<annotation-1> |
      | @<annotation-2> |
    When relation(description) get owns: custom-attribute[], unset annotation: @<annotation-1>
    Then relation(description) get owns: custom-attribute[], get annotations do not contain: @<annotation-1>
    Then relation(description) get owns: custom-attribute[], get annotations contain: @<annotation-2>
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then relation(description) get owns: custom-attribute[], get annotations do not contain: @<annotation-1>
    Then relation(description) get owns: custom-attribute[], get annotations contain: @<annotation-2>
    When relation(description) get owns: custom-attribute[], set annotation: @<annotation-1>
    When relation(description) get owns: custom-attribute[], unset annotation: @<annotation-2>
    Then relation(description) get owns: custom-attribute[], get annotations do not contain: @<annotation-2>
    Then relation(description) get owns: custom-attribute[], get annotations contain: @<annotation-1>
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then relation(description) get owns: custom-attribute[], get annotations do not contain: @<annotation-2>
    Then relation(description) get owns: custom-attribute[], get annotations contain: @<annotation-1>
    When relation(description) get owns: custom-attribute[], unset annotation: @<annotation-1>
    Then relation(description) get owns: custom-attribute[], get annotations is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then relation(description) get owns: custom-attribute[], get annotations is empty
    Examples:
      | annotation-1 | annotation-2 | value-type |
      | key          |              | long       |
      | subkey       |              | double     |
      | unique       |              | decimal    |
      | values       |              | string     |
      | range        |              | datetime   |
      | card         |              | datetimetz |
      | regex        |              | duration   |
      | distinct     |              | string     |
    # TODO fill the values!

  Scenario Outline: Owns cannot set @<annotation-1> and @<annotation-2> together for scalar <value-type>
    When put attribute type: custom-attribute
    When attribute(custom-attribute) set value-type: <value-type>
    When transaction commits
    When connection opens schema transaction for database: typedb
    When relation(description) set owns: custom-attribute
    When relation(description) get owns: custom-attribute, set annotation: @<annotation-1>
    Then relation(description) get owns: custom-attribute, set annotation: @<annotation-2>; fails
    When connection opens schema transaction for database: typedb
    When relation(description) set owns: custom-attribute
    Then relation(description) get owns: custom-attribute, set annotation: @<annotation-2>
    When relation(description) get owns: custom-attribute, set annotation: @<annotation-1>; fails
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then relation(description) get owns: custom-attribute, get annotation contain: @<annotation-2>
    Then relation(description) get owns: custom-attribute, get annotation do not contain: @<annotation-1>
    Examples:
      | annotation-1 | annotation-2 | value-type |
      | key          |              | long       |
      | subkey       |              | double     |
      | unique       |              | decimal    |
      | values       |              | string     |
      | range        |              | datetime   |
      | card         |              | datetimetz |
      | regex        |              | duration   |
      | distinct     |              | string     |
    # TODO fill the values!

  Scenario Outline: Owns can set @<annotation-1> and @<annotation-2> together and unset it for lists of <value-type>
    When put attribute type: custom-attribute
    When attribute(custom-attribute) set value-type: <value-type>
    When transaction commits
    When connection opens schema transaction for database: typedb
    When relation(description) set owns: custom-attribute[]
    When relation(description) get owns: custom-attribute[], set annotation: @<annotation-1>
    Then relation(description) get owns: custom-attribute[], set annotation: @<annotation-2>; fails
    When connection opens schema transaction for database: typedb
    When relation(description) set owns: custom-attribute[]
    Then relation(description) get owns: custom-attribute[], set annotation: @<annotation-2>
    When relation(description) get owns: custom-attribute[], set annotation: @<annotation-1>; fails
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then relation(description) get owns: custom-attribute[], get annotation contain: @<annotation-2>
    Then relation(description) get owns: custom-attribute[], get annotation do not contain: @<annotation-1>
    Examples:
      | annotation-1 | annotation-2 | value-type |
      | key          |              | long       |
      | subkey       |              | double     |
      | unique       |              | decimal    |
      | values       |              | string     |
      | range        |              | datetime   |
      | card         |              | datetimetz |
      | regex        |              | duration   |
      | distinct     |              | string     |
    # TODO fill the values!


# TODO: Tests for lists without annotations!
