# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: Concept Owns

  Background:
    Given typedb starts
    Given connection opens with default authentication
    Given connection has been opened
    Given connection does not have any database
    Given connection create database: typedb
    Given connection open schema transaction for database: typedb

    Given create entity type: person
    Given create entity type: customer
    Given create entity type: subscriber
    # Notice: supertypes are the same, but can be overridden for the second subtype inside the tests
    Given entity(customer) set supertype: person
    Given entity(subscriber) set supertype: person
    Given create relation type: description
    Given relation(description) create role: object
    Given create relation type: registration
    Given create relation type: profile
    # Notice: supertypes are the same, but can be overridden for the second subtype inside the tests
    Given relation(registration) set supertype: description
    Given relation(profile) set supertype: description
    Given create struct type: custom-struct
    Given struct(custom-struct) create field: custom-field

    Given transaction commits
    Given connection open schema transaction for database: typedb

########################
# owns common
########################

  Scenario Outline: Entity types can own and unset attributes
    When create attribute type: name
    When attribute(name) set value type: <value-type>
    When create attribute type: surname
    When attribute(surname) set value type: <value-type>
    When create attribute type: birthday
    When attribute(birthday) set value type: <value-type-2>
    When entity(person) set owns: name
    When entity(person) set owns: birthday
    When entity(person) set owns: surname
    Then entity(person) get owns contain:
      | name     |
      | surname  |
      | birthday |
    When transaction commits
    When connection open schema transaction for database: typedb
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
    When connection open schema transaction for database: typedb
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

  Scenario Outline: Entity types can redeclare owning attributes with <value-type> value type
    When create attribute type: name
    When attribute(name) set value type: <value-type>
    When create attribute type: email
    When attribute(email) set value type: <value-type>
    When entity(person) set owns: name
    When entity(person) set owns: email
    Then entity(person) set owns: name
    When transaction commits
    When connection open schema transaction for database: typedb
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

  Scenario: Entity types cannot own entities, relations, roles, structs, structs fields, and non-existing things
    When create entity type: car
    When create relation type: credit
    When relation(credit) create role: creditor
    When create struct type: passport
    When struct(passport) create field: birthday, with value type: datetime
    Then entity(person) set owns: car; fails
    Then entity(person) set owns: credit; fails
    Then entity(person) set owns: credit:creditor; fails
    Then entity(person) set owns: passport; fails
    Then entity(person) set owns: passport:birthday; fails
    Then entity(person) set owns: does-not-exist; fails
    Then entity(person) get owns is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get owns is empty

  Scenario: Entity type cannot own attribute without value type
    When create entity type: player
    When create attribute type: name
    When create attribute type: email
    When attribute(email) set annotation: @abstract
    Then entity(player) set owns: name; fails
    Then entity(player) set owns: email; fails
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(player) set owns: name; fails
    Then entity(player) set owns: email; fails
    Then entity(player) get owns is empty

  Scenario: Non-abstract entity type cannot own abstract attribute
    When create entity type: player
    When create attribute type: name
    When attribute(name) set annotation: @abstract
    When create attribute type: email
    When attribute(email) set value type: string
    When attribute(email) set annotation: @abstract
    Then entity(player) set owns: name; fails
    Then entity(player) set owns: email; fails
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(player) set owns: name; fails
    Then entity(player) set owns: email; fails
    Then entity(player) get owns is empty

  Scenario: Abstract entity type cannot own non-abstract attribute without value type
    When create entity type: player
    When entity(player) set annotation: @abstract
    When create attribute type: name
    Then entity(player) set owns: name; fails
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(player) set owns: name; fails

  Scenario: Abstract entity type can own abstract attribute
    When create entity type: player
    When entity(type) set annotation: @abstract
    When create attribute type: name
    When attribute(name) set annotation: @abstract
    When create attribute type: email
    When attribute(email) set value type: string
    When attribute(email) set annotation: @abstract
    When entity(player) set owns: name
    When entity(player) set owns: email
    Then entity(player) get owns contain:
      | name  |
      | email |
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(player) get owns contain:
      | name  |
      | email |

  Scenario: Entity type cannot unset abstract annotation if it owns an abstract attribute
    When create entity type: player
    When entity(type) set annotation: @abstract
    When create attribute type: name
    When attribute(name) set annotation: @abstract
    When entity(player) set owns: name
    When entity(player) get owns contain: name
    Then entity(player) unset annotation: @abstract; fails
    Then entity(player) get annotations contain: @abstract
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(player) get owns contain: name
    Then entity(player) get annotations contain: @abstract
    Then entity(player) unset annotation: @abstract; fails
    Then entity(player) get annotations contain: @abstract

  Scenario Outline: Relation types can own and unset attributes
    When create attribute type: license
    When attribute(license) set value type: <value-type>
    When create attribute type: starting-date
    When attribute(starting-date) set value type: <value-type>
    When create attribute type: comment
    When attribute(comment) set value type: <value-type-2>
    When create relation type: marriage
    When relation(marriage) create role: spouse
    When relation(marriage) set owns: license
    When relation(marriage) set owns: starting-date
    When relation(marriage) set owns: comment
    Then relation(marriage) get owns contain:
      | license       |
      | starting-date |
      | comment       |
    When transaction commits
    When connection open read transaction for database: typedb
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
    When connection open schema transaction for database: typedb
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

  Scenario Outline: Relation types can redeclare owning attributes with <value-type> value type
    When create attribute type: name
    When attribute(name) set value type: <value-type>
    When create attribute type: email
    When attribute(email) set value type: <value-type>
    When create relation type: reference
    When relation(reference) create role: target
    When relation(reference) set owns: name
    When relation(reference) set owns: email
    Then relation(reference) set owns: name
    When transaction commits
    When connection open schema transaction for database: typedb
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

  Scenario: Relation types cannot own entities, relations, roles, structs, structs fields, and non-existing things
    When create relation type: credit
    When relation(credit) create role: creditor
    When create relation type: marriage
    When relation(marriage) create role: spouse
    When create struct type: passport-document
    When struct(passport-document) create field: first-name, with value type: string
    When struct(passport-document) create field: surname, with value type: string
    When struct(passport-document) create field: birthday, with value type: datetime
    Then relation(marriage) set owns: person; fails
    Then relation(marriage) set owns: credit; fails
    Then relation(marriage) set owns: credit:creditor; fails
    Then relation(marriage) set owns: passport; fails
    Then relation(marriage) set owns: passport:birthday; fails
    Then relation(marriage) set owns: marriage:spouse; fails
    Then relation(marriage) set owns: does-not-exist; fails
    Then relation(marriage) get owns is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(marriage) get owns is empty

  Scenario: Relation type cannot own attribute without value type
    When create relation type: reference
    When relation(reference) create role: target
    When create attribute type: name
    When create attribute type: email
    When attribute(email) set annotation: @abstract
    Then relation(reference) set owns: name; fails
    Then relation(reference) set owns: email; fails
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(reference) set owns: name; fails
    Then relation(reference) set owns: email; fails
    Then relation(reference) get owns is empty

  Scenario: Non-abstract relation type cannot own abstract attribute
    When create relation type: reference
    When relation(reference) create role: target
    When create attribute type: name
    When attribute(name) set annotation: @abstract
    When create attribute type: email
    When attribute(email) set value type: string
    When attribute(email) set annotation: @abstract
    Then relation(reference) set owns: name; fails
    Then relation(reference) set owns: email; fails
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(reference) set owns: name; fails
    Then relation(reference) set owns: email; fails
    Then relation(reference) get owns is empty

  Scenario: Abstract relation type cannot own non-abstract attribute without value type
    When create relation type: reference
    When relation(reference) create role: target
    When relation(reference) set annotation: @abstract
    When create attribute type: name
    Then relation(reference) set owns: name; fails
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(reference) set owns: name; fails

  Scenario: Abstract relation type can own abstract attribute
    When create relation type: reference
    When relation(reference) create role: target
    When entity(type) set annotation: @abstract
    When create attribute type: name
    When attribute(name) set annotation: @abstract
    When create attribute type: email
    When attribute(email) set value type: string
    When attribute(email) set annotation: @abstract
    When relation(reference) set owns: name
    When relation(reference) set owns: email
    Then relation(reference) get owns contain:
      | name  |
      | email |
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(reference) get owns contain:
      | name  |
      | email |

  Scenario: Relation type cannot unset abstract annotation if it owns an abstract attribute
    When create relation type: reference
    When relation(reference) create role: target
    When entity(type) set annotation: @abstract
    When create attribute type: name
    When attribute(name) set annotation: @abstract
    When relation(reference) set owns: name
    When relation(reference) get owns contain: name
    Then relation(reference) unset annotation: @abstract; fails
    Then relation(reference) get annotations contain: @abstract
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(reference) get owns contain: name
    Then relation(reference) get annotations contain: @abstract
    Then relation(reference) unset annotation: @abstract; fails
    Then relation(reference) get annotations contain: @abstract

  Scenario: Attribute types cannot own entities, attributes, relations, roles, structs, structs fields, and non-existing things
    When create attribute type: surname
    When create relation type: marriage
    When relation(marriage) create role: spouse
    When attribute(surname) set value type: string
    When create struct type: passport
    When struct(passport) create field: first-name, with value type: string
    When struct(passport) create field: surname, with value type: string
    When struct(passport) create field: birthday, with value type: datetime
    When create attribute type: name
    When attribute(name) set value type: string
    Then attribute(name) set owns: person; fails
    Then attribute(name) set owns: surname; fails
    Then attribute(name) set owns: marriage; fails
    Then attribute(name) set owns: marriage:spouse; fails
    Then attribute(name) set owns: passport; fails
    Then attribute(name) set owns: passport:birthday; fails
    Then attribute(name) set owns: does-not-exist; fails
    Then attribute(name) get owns is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(name) get owns is empty

  Scenario: Struct types cannot own entities, attributes, relations, roles, structs, structs fields, and non-existing things
    When create attribute type: name
    When create relation type: marriage
    When relation(marriage) create role: spouse
    When attribute(surname) set value type: string
    When create struct type: passport
    When struct(passport) create field: birthday, with value type: datetime
    When create struct type: wallet
    When struct(wallet) create field: currency, with value type: string
    When struct(wallet) create field: value, with value type: double
    Then struct(wallet) set owns: person; fails
    Then struct(wallet) set owns: name; fails
    Then struct(wallet) set owns: marriage; fails
    Then struct(wallet) set owns: marriage:spouse; fails
    Then struct(wallet) set owns: passport; fails
    Then struct(wallet) set owns: passport:birthday; fails
    Then struct(wallet) set owns: wallet:currency; fails
    Then struct(wallet) set owns: does-not-exist; fails
    Then struct(wallet) get owns is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then struct(wallet) get owns is empty

    # TODO: Move to thing-feature or schema/data-validation?
#  Scenario Outline: <root-type> types cannot unset owning attributes that are owned by existing instances
#    When create attribute type: name
#    When attribute(name) set value type: <value-type>
#    When <root-type>(<type-name>) set owns: name
#    Then transaction commits
#    When connection open write transaction for database: typedb
#    When $i = <root-type>(<type-name>) create new instance
#    When $a = attribute(name) as(<value-type>) put: <value>
#    When entity $i set has: $a
#    Then transaction commits
#    When connection open schema transaction for database: typedb
#    Then <root-type>(<type-name>) unset owns: name; fails
#    Then <root-type>(<type-name>) get owns contain: name
#    Examples:
#      | root-type | type-name   | value-type | value           |
#      | entity    | person      | long       | 1               |
#      | entity    | person      | double     | 1.0             |
#      | entity    | person      | decimal    | 1.0             |
#      | entity    | person      | string     | "alice"         |
#      | entity    | person      | boolean    | true            |
#      | entity    | person      | datetime   | 2024-05-04      |
#      | entity    | person      | datetimetz | 2024-05-04+0010 |
#      | entity    | person      | duration   | P1Y             |
#      | relation  | description | long       | 1               |
#      | relation  | description | double     | 1.0             |
#      | relation  | description | decimal    | 1.0             |
#      | relation  | description | string     | "alice"         |
#      | relation  | description | boolean    | true            |
#      | relation  | description | datetime   | 2024-05-04      |
#      | relation  | description | datetimetz | 2024-05-04+0010 |
#      | relation  | description | duration   | P1Y             |

  Scenario Outline: <root-type> types can re-override owns
    When create attribute type: email
    When attribute(email) set value type: <value-type>
    When attribute(email) set annotation: @abstract
    When create attribute type: work-email
    When attribute(work-email) set value type: <value-type>
    When attribute(work-email) set supertype: email
    When <root-type>(<supertype-name>) set annotation: @abstract
    When <root-type>(<supertype-name>) set owns: email
    When <root-type>(<sub-name>) set annotation: @abstract
    When <root-type>(<subtype-name>) set owns: work-email
    When <root-type>(<subtype-name>) get owns(work-email) set override: email
    Then <root-type>(<subtype-name>) get owns overridden(work-email) get name: email
    When transaction commits
    When connection open schema transaction for database: typedb
    When <root-type>(<subtype-name>) set owns: work-email
    When <root-type>(<subtype-name>) get owns(work-email) set override: email
    Then <root-type>(<subtype-name>) get owns overridden(work-email) get name: email
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
    When create attribute type: email
    When attribute(email) set value type: <value-type>
    When create attribute type: name
    When attribute(name) set value type: <value-type>
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
    When create attribute type: name
    When attribute(name) set value type: <value-type>
    When attribute(name) set annotation: @abstract
    When create attribute type: customer-name
    When attribute(customer-name) set value type: <value-type>
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
    When create attribute type: name
    When attribute(name) set value type: <value-type>
    When attribute(name) set annotation: @abstract
    When create attribute type: customer-name
    When attribute(customer-name) set value type: <value-type>
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
    When create attribute type: name
    When attribute(name) set value type: <value-type>
    When attribute(name) set annotation: @abstract
    When create attribute type: first-name
    When attribute(first-name) set value type: <value-type>
    When attribute(first-name) set supertype: name
    When <root-type>(<type-name>) set annotation: @abstract
    When <root-type>(<type-name>) set owns: name
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<type-name>) set owns: first-name
    Then <root-type>(<type-name>) get owns(first-name) set override: first-name; fails
    Then <root-type>(<type-name>) get owns(first-name) set override: name; fails
    Examples:
      | root-type | type-name   | value-type |
      | entity    | person      | string     |
      | relation  | description | string     |

  Scenario Outline: <root-type> types cannot override inherited owns other than with their subtypes
    When create attribute type: username
    When attribute(username) set value type: <value-type>
    When create attribute type: reference
    When attribute(reference) set value type: <value-type>
    When <root-type>(<supertype-name>) set owns: username
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<subtype-name>) set owns: reference
    Then <root-type>(<subtype-name>) get owns(reference) set override: reference; fails
    Then <root-type>(<subtype-name>) get owns(reference) set override: username; fails
    Examples:
      | root-type | supertype-name | subtype-name | value-type |
      | entity    | person         | customer     | double     |
      | relation  | description    | registration | string     |

  Scenario Outline: <root-type> types cannot unset not owned ownership
    When create attribute type: username
    When attribute(username) set value type: <value-type>
    When create attribute type: reference
    When attribute(reference) set value type: <value-type>
    When <root-type>(<type-name>) set owns: username
    Then <root-type>(<type-name>) get owns contain: username
    Then <root-type>(<type-name>) unset owns: reference; fails
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<type-name>) get owns contain: username
    Then <root-type>(<type-name>) unset owns: reference; fails
    Then <root-type>(<type-name>) unset owns: username
    Then <root-type>(<type-name>) unset owns: username; fails
    Then <root-type>(<type-name>) get owns is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then <root-type>(<type-name>) get owns is empty
    Examples:
      | root-type | type-name   | value-type |
      | entity    | person      | string     |
      | relation  | description | long       |

  Scenario Outline: <root-type> types cannot unset inherited ownership
    When create attribute type: username
    When attribute(username) set value type: <value-type>
    When <root-type>(<supertype-name>) set owns: username
    Then <root-type>(<supertype-name>) get owns contain: username
    Then <root-type>(<subtype-name>) get owns contain: username
    Then <root-type>(<subtype-name>) unset owns: username; fails
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<subtype-name>) get owns contain: username
    Then <root-type>(<subtype-name>) unset owns: username; fails
    Examples:
      | root-type | supertype-name | subtype-name | value-type |
      | entity    | person         | customer     | string     |
      | relation  | description    | registration | long       |

  Scenario Outline: Owns can be inherited from abstract <root-type> types
    When create attribute type: username
    When attribute(username) set value type: string
    When <root-type>(<supertype-name>) set annotation: @abstract
    When <root-type>(<supertype-name>) set owns: username
    When <root-type>(<supertype-name>) get owns contain: username
    When <root-type>(<subtype-name>) get owns contain: username
    When transaction commits
    When connection open read transaction for database: typedb
    Then <root-type>(<supertype-name>) get owns contain: username
    Then <root-type>(<subtype-name>) get owns contain: username
    Then <root-type>(<supertype-name>) get owns(username) get annotations do not contain: @abstract
    Then <root-type>(<subtype-name>) get owns(username) get annotations do not contain: @abstract
    Examples:
      | root-type | supertype-name | subtype-name |
      | entity    | person         | customer     |
      | relation  | description    | registration |

########################
# owns lists
########################

  Scenario Outline: Entity types can set and unset ordered ownership
    When create attribute type: name
    When attribute(name) set value type: <value-type>
    When create attribute type: surname
    When attribute(surname) set value type: <value-type>
    When create attribute type: birthday
    When attribute(birthday) set value type: <value-type-2>
    When entity(person) set owns: name
    When entity(person) set owns: birthday
    When entity(person) set owns: surname
    Then entity(person) get owns contain:
      | name     |
      | surname  |
      | birthday |
    Then entity(person) get owns(name) get ordering: unordered
    Then entity(person) get owns(birthday) get ordering: unordered
    Then entity(person) get owns(surname) get ordering: unordered
    When entity(person) get owns(name) set ordering: ordered
    When entity(person) get owns(birthday) set ordering: ordered
    When entity(person) get owns(surname) set ordering: ordered
    Then entity(person) get owns(name) get ordering: ordered
    Then entity(person) get owns(birthday) get ordering: ordered
    Then entity(person) get owns(surname) get ordering: ordered
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get owns contain:
      | name     |
      | surname  |
      | birthday |
    Then entity(person) get owns(name) get ordering: ordered
    Then entity(person) get owns(birthday) get ordering: ordered
    Then entity(person) get owns(surname) get ordering: ordered
    When entity(person) unset owns: surname
    Then entity(person) get owns do not contain:
      | surname |
    Then entity(person) get owns contain:
      | name     |
      | birthday |
    When transaction commits
    When connection open schema transaction for database: typedb
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

     # TODO: Move to thing-feature or schema/data-validation?
#  Scenario: Ownership can change ordering if it does not have instances even if its owner has instances for entity type
#    When create attribute type: name
#    When attribute(name) set value type: double
#    When create entity type: person
#    When entity(person) set owns: name
#    When transaction commits
#    When connection open write transaction for database: typedb
#    When $a = entity(person) create new instance
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    When entity(person) get owns(name) set ordering: ordered
#    Then entity(person) get owns(name) get ordering: ordered
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then entity(person) get owns(name) get ordering: ordered
#    When entity(person) get owns(name) set ordering: unordered
#    Then entity(person) get owns(name) get ordering: unordered
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then entity(person) get owns(name) get ordering: unordered

   # TODO: Move to thing-feature or schema/data-validation?
#  Scenario: Ownership cannot change ordering if it has role instances for entity type
#    When create attribute type: id
#    When attribute(id) set value type: long
#    When create attribute type: name
#    When attribute(name) set value type: string
#    When create attribute type: email
#    When attribute(email) set value type: decimal
#    When create entity type: person
#    When entity(person) set owns: id
#    When entity(person) get owns(id) set annotation: @key
#    When entity(person) set owns: name
#    When entity(person) set owns: email
#    When entity(person) get owns(email) set ordering: ordered
#    When transaction commits
#    When connection open write transaction for database: typedb
#    When $e = entity(person) create new instance with key(id): 1
#    When $a1 = attribute(name) create new instance
#    When $a2 = attribute(name) create new instance
#    When entity $e set has: $a1
#    When entity $e set has: $a2
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then entity(person) get owns(name) set ordering: unordered; fails
#    Then entity(person) get owns(name) set ordering: ordered; fails
#    Then entity(person) get owns(email) set ordering: unordered; fails
#    Then entity(person) get owns(email) set ordering: ordered; fails
#    When connection open write transaction for database: typedb
#    When $a = entity(person) get instance with key(id): 1
#    When delete entity: $a
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    When entity(person) get owns(name) set ordering: ordered
#    Then entity(person) get owns(name) get ordering: ordered
#    When entity(person) get owns(email) set ordering: unordered
#    Then entity(person) get owns(email) get ordering: unordered
#    When transaction commits
#    When connection open read transaction for database: typedb
#    Then entity(person) get owns(name) get ordering: ordered
#    Then entity(person) get owns(email) get ordering: unordered

  Scenario Outline: Entity types can redeclare ordered ownership
    When create attribute type: name
    When attribute(name) set value type: <value-type>
    When create attribute type: email
    When attribute(email) set value type: <value-type>
    When entity(person) set owns: name
    When entity(person) get owns(name) set ordering: ordered
    When entity(person) set owns: email
    When entity(person) get owns(email) set ordering: ordered
    Then entity(person) set owns: name
    When entity(person) get owns(name) set ordering: ordered
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) set owns: email
    Then entity(person) get owns(email) get ordering: unordered
    When entity(person) get owns(email) set ordering: ordered
    Then entity(person) get owns(email) get ordering: ordered
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

  Scenario: Abstract entity type can set ordered ownership
    When create entity type: player
    When entity(type) set annotation: @abstract
    When create attribute type: name
    When attribute(name) set annotation: @abstract
    When create attribute type: email
    When attribute(email) set value type: string
    When attribute(email) set annotation: @abstract
    When entity(player) set owns: name
    When entity(player) set owns: email
    Then entity(player) get owns contain:
      | name  |
      | email |
    When entity(player) get owns(name) set ordering: ordered
    When entity(player) get owns(email) set ordering: ordered
    Then entity(player) get owns(name) get ordering: ordered
    Then entity(player) get owns(email) get ordering: ordered
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(player) get owns contain:
      | name  |
      | email |
    Then entity(player) get owns(name) get ordering: ordered
    Then entity(player) get owns(email) get ordering: ordered

  Scenario Outline: Relation types can set and unset ordered ownership
    When create attribute type: license
    When attribute(license) set value type: <value-type>
    When create attribute type: starting-date
    When attribute(starting-date) set value type: <value-type>
    When create attribute type: comment
    When attribute(comment) set value type: <value-type-2>
    When create relation type: marriage
    When relation(marriage) create role: spouse
    When relation(marriage) set owns: license
    When relation(marriage) set owns: starting-date
    When relation(marriage) set owns: comment
    Then relation(marriage) get owns contain:
      | license       |
      | starting-date |
      | comment       |
    Then relation(marriage) get owns(license) get ordering: unordered
    Then relation(marriage) get owns(starting-date) get ordering: unordered
    Then relation(marriage) get owns(comment) get ordering: unordered
    When relation(marriage) get owns(license) set ordering: ordered
    When relation(marriage) get owns(starting-date) set ordering: ordered
    When relation(marriage) get owns(comment) set ordering: ordered
    Then relation(marriage) get owns(license) get ordering: ordered
    Then relation(marriage) get owns(starting-date) get ordering: ordered
    Then relation(marriage) get owns(comment) get ordering: ordered
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(marriage) get owns contain:
      | license       |
      | starting-date |
      | comment       |
    Then relation(marriage) get owns(license) get ordering: ordered
    Then relation(marriage) get owns(starting-date) get ordering: ordered
    Then relation(marriage) get owns(comment) get ordering: ordered
    When relation(marriage) unset owns: starting-date
    Then relation(marriage) get owns do not contain:
      | starting-date |
    Then relation(marriage) get owns contain:
      | license |
      | comment |
    When transaction commits
    When connection open schema transaction for database: typedb
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

     # TODO: Move to thing-feature or schema/data-validation?
#  Scenario: Ownership can change ordering if it does not have instances even if its owner has instances for relation type
#    When create attribute type: name
#    When attribute(name) set value type: double
#    When create relation type: parentship
#    When relation(parentship) create role: parent
#    When relation(parentship) set owns: name
#    When create entity type: person
#    When entity(person) set plays: parentship:parent
#    When transaction commits
#    When connection open write transaction for database: typedb
#    When $e = entity(person) create new instance
#    When $r = relation(parentship) create new instance
#    When relation $r add player for role(parent): $e
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    When relation(parentship) get owns(name) set ordering: ordered
#    Then relation(parentship) get owns(name) get ordering: ordered
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then relation(parentship) get owns(name) get ordering: ordered
#    When relation(parentship) get owns(name) set ordering: unordered
#    Then relation(parentship) get owns(name) get ordering: unordered
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then relation(parentship) get owns(name) get ordering: unordered

   # TODO: Move to thing-feature or schema/data-validation?
#  Scenario: Ownership cannot change ordering if it has role instances for relation type
#    When create attribute type: id
#    When attribute(id) set value type: long
#    When create attribute type: name
#    When attribute(name) set value type: string
#    When create attribute type: email
#    When attribute(email) set value type: decimal
#    When create relation type: parentship
#    When relation(parentship) create role: parent
#    When relation(parentship) set owns: name
#    When relation(parentship) set owns: email
#    When relation(parentship) get owns(email) set ordering: ordered
#    When relation(parentship) set owns: id
#    When relation(parentship) get owns(id) set annotation: @key
#    When create entity type: person
#    When entity(person) set plays: parentship:parent
#    When entity(person) set owns: id
#    When entity(person) get owns(id) set annotation: @key
#    When transaction commits
#    When connection open write transaction for database: typedb
#    When $e = entity(person) create new instance with key(id): 1
#    When $r = relation(parentship) create new instance with key(id): 1
#    When relation $r add player for role(parent): $e
#    When $a1 = attribute(name) create new instance
#    When $a2 = attribute(name) create new instance
#    When entity $r set has: $a1
#    When entity $r set has: $a2
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then relation(parentship) get owns(name) set ordering: unordered; fails
#    Then relation(parentship) get owns(name) set ordering: ordered; fails
#    Then relation(parentship) get owns(email) set ordering: unordered; fails
#    Then relation(parentship) get owns(email) set ordering: ordered; fails
#    When connection open write transaction for database: typedb
#    When $r = relation(parentship) get instance with key(id): 1
#    When $a = entity(person) get instance with key(id): 1
#    When delete entity: $a
#    When delete relation: $r
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    When relation(parentship) get owns(name) set ordering: ordered
#    Then relation(parentship) get owns(name) get ordering: ordered
#    When relation(parentship) get owns(email) set ordering: unordered
#    Then relation(parentship) get owns(email) get ordering: unordered
#    When transaction commits
#    When connection open read transaction for database: typedb
#    Then relation(parentship) get owns(name) get ordering: ordered
#    Then relation(parentship) get owns(email) get ordering: unordered

  Scenario Outline: Relation types can redeclare ordered ownership
    When create attribute type: name
    When attribute(name) set value type: <value-type>
    When create attribute type: email
    When attribute(email) set value type: <value-type>
    When create relation type: reference
    When relation(reference) create role: target
    When relation(reference) set owns: name
    When relation(reference) get owns(name) set ordering: ordered
    When relation(reference) set owns: email
    When relation(reference) get owns(email) set ordering: ordered
    Then relation(reference) set owns: name
    When relation(reference) get owns(name) set ordering: ordered
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(reference) set owns: email
    Then relation(reference) get owns(email) get ordering: unordered
    When relation(reference) get owns(email) set ordering: ordered
    Then relation(reference) get owns(email) get ordering: ordered
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

  Scenario: Abstract relation type can set ordered ownership of abstract attribute
    When create relation type: reference
    When relation(reference) create role: target
    When entity(type) set annotation: @abstract
    When create attribute type: name
    When attribute(name) set annotation: @abstract
    When create attribute type: email
    When attribute(email) set value type: string
    When attribute(email) set annotation: @abstract
    When relation(reference) set owns: name
    When relation(reference) get owns(name) set ordering: ordered
    When relation(reference) set owns: email
    When relation(reference) get owns(email) set ordering: ordered
    Then relation(reference) get owns contain:
      | name  |
      | email |
    Then relation(reference) get owns(name) get ordering: ordered
    Then relation(reference) get owns(email) get ordering: ordered
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(reference) get owns contain:
      | name  |
      | email |
    Then relation(reference) get owns(name) get ordering: ordered
    Then relation(reference) get owns(email) get ordering: ordered

  Scenario: Relation type cannot unset abstract annotation if it has ordered ownership of abstract attribute
    When create relation type: reference
    When relation(reference) create role: target
    When entity(type) set annotation: @abstract
    When create attribute type: name
    When attribute(name) set annotation: @abstract
    When relation(reference) set owns: name
    When relation(reference) get owns contain: name
    When relation(reference) get owns(name) set ordering: ordered
    Then relation(reference) unset annotation: @abstract; fails
    Then relation(reference) get annotations contain: @abstract
    Then relation(reference) get owns(name) get ordering: ordered
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(reference) get owns contain: name
    Then relation(reference) get owns(name) get ordering: ordered
    Then relation(reference) get annotations contain: @abstract
    Then relation(reference) unset annotation: @abstract; fails
    Then relation(reference) get annotations contain: @abstract

  Scenario Outline: <root-type> can change ordering of owns
    When create attribute type: name
    When attribute(name) set value type: <value-type>
    When create attribute type: surname
    When attribute(surname) set value type: <value-type>
    When <root-type>(<type-name>) set owns: name
    When <root-type>(<type-name>) set owns: surname
    When <root-type>(<type-name>) get owns(surname) set ordering: ordered
    Then <root-type>(<type-name>) get owns(name) get ordering: unordered
    Then <root-type>(<type-name>) get owns(surname) get ordering: ordered
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<type-name>) get owns(name) get ordering: unordered
    Then <root-type>(<type-name>) get owns(surname) get ordering: ordered
    When <root-type>(<type-name>) get owns(name) set ordering: ordered
    When <root-type>(<type-name>) get owns(surname) set ordering: unordered
    Then <root-type>(<type-name>) get owns(name) get ordering: ordered
    Then <root-type>(<type-name>) get owns(surname) get ordering: unordered
    When transaction commits
    When connection open read transaction for database: typedb
    Then <root-type>(<type-name>) get owns(name) get ordering: ordered
    Then <root-type>(<type-name>) get owns(surname) get ordering: unordered
    Examples:
      | root-type | type-name   | value-type |
      | entity    | person      | long       |
      | entity    | person      | double     |
      | entity    | person      | decimal    |
      | entity    | person      | string     |
      | entity    | person      | boolean    |
      | entity    | person      | datetime   |
      | entity    | person      | datetimetz |
      | entity    | person      | duration   |
      | relation  | description | long       |
      | relation  | description | double     |
      | relation  | description | decimal    |
      | relation  | description | string     |
      | relation  | description | boolean    |
      | relation  | description | datetime   |
      | relation  | description | datetimetz |
      | relation  | description | duration   |

  Scenario Outline: Ordered owns can redeclare ordering
    When create attribute type: name
    When attribute(name) set value type: <value-type>
    When <root-type>(<type-name>) set owns: name
    When <root-type>(<type-name>) get owns(name) set ordering: ordered
    Then <root-type>(<type-name>) get owns(name) get ordering: ordered
    When <root-type>(<type-name>) get owns(name) set ordering: ordered
    Then <root-type>(<type-name>) get owns(name) get ordering: ordered
    When connection open schema transaction for database: typedb
    When <root-type>(<type-name>) get owns(name) set ordering: ordered
    Then <root-type>(<type-name>) get owns(name) get ordering: ordered
    Examples:
      | root-type | type-name   | value-type |
      | entity    | person      | duration   |
      | relation  | description | string     |

  Scenario Outline: <root-type> can set ordering for ownership after setting an override or an annotation
    When create attribute type: name
    When attribute(name) set value type: <value-type>
    When attribute(name) set annotation: @abstract
    When create attribute type: surname
    When attribute(surname) set supertype: name
    When <root-type>(<supertype-name>) set owns: name
    When <root-type>(<subtype-name>) set owns: surname
    When <root-type>(<subtype-name>) get owns(surname) set override: surname
    When <root-type>(<subtype-name>) get owns(surname) set annotation: @card(0, 1)
    When <root-type>(<subtype-name>) get owns(surname) set ordering: ordered
    Then <root-type>(<subtype-name>) get owns(surname) get ordering: ordered
    When transaction commits
    When connection open read transaction for database: typedb
    Then <root-type>(<subtype-name>) get owns(surname) get ordering: ordered
    Examples:
      | root-type | supertype-name | subtype-name | value-type |
      | entity    | person         | customer     | duration   |
      | relation  | description    | registration | string     |

     # TODO: Move to thing-feature or schema/data-validation?
#  Scenario Outline: <root-type> types cannot unset ordered ownership of attributes that are owned by existing instances
#    When create attribute type: name
#    When attribute(name) set value type: <value-type>
#    When <root-type>(<type-name>) set owns: name
#    When <root-type>(<type-name>) get owns(name) set ordering: ordered
#    Then transaction commits
#    When connection open write transaction for database: typedb
#    When $i = <root-type>(<type-name>) create new instance
#    When $a = attribute(name) as(<value-type>) put: [<value>]
#    When entity $i set has: $a
#    Then transaction commits
#    When connection open schema transaction for database: typedb
#    Then <root-type>(<type-name>) unset owns: name; fails
#    Then <root-type>(<type-name>) get owns contain: name
#    Then <root-type>(<type-name>) get owns(name) get ordering: ordered
#    Examples:
#      | root-type | type-name   | value-type | value           |
#      | entity    | person      | long       | 1               |
#      | entity    | person      | double     | 1.0             |
#      | entity    | person      | decimal    | 1.0             |
#      | entity    | person      | string     | "alice"         |
#      | entity    | person      | boolean    | true            |
#      | entity    | person      | datetime   | 2024-05-04      |
#      | entity    | person      | datetimetz | 2024-05-04+0010 |
#      | entity    | person      | duration   | P1Y             |
#      | relation  | description | long       | 1               |
#      | relation  | description | double     | 1.0             |
#      | relation  | description | decimal    | 1.0             |
#      | relation  | description | string     | "alice"         |
#      | relation  | description | boolean    | true            |
#      | relation  | description | datetime   | 2024-05-04      |
#      | relation  | description | datetimetz | 2024-05-04+0010 |
#      | relation  | description | duration   | P1Y             |

  Scenario Outline: <root-type> types can re-override ordered ownership
    When create attribute type: email
    When attribute(email) set value type: <value-type>
    When attribute(email) set annotation: @abstract
    When create attribute type: work-email
    When attribute(work-email) set value type: <value-type>
    When attribute(work-email) set supertype: email
    When <root-type>(<supertype-name>) set annotation: @abstract
    When <root-type>(<supertype-name>) set owns: email
    When <root-type>(<supertype-name>) get owns(email) set ordering: ordered
    Then <root-type>(<supertype-name>) get owns(email) get ordering: ordered
    When <root-type>(<sub-name>) set annotation: @abstract
    When <root-type>(<subtype-name>) set owns: work-email
    When <root-type>(<subtype-name>) get owns(work-email) set override: email
    Then <root-type>(<subtype-name>) get owns overridden(work-email) get name: email
    Then <root-type>(<subtype-name>) get owns(work-email) get ordering: ordered
    When transaction commits
    When connection open schema transaction for database: typedb
    When <root-type>(<subtype-name>) set owns: work-email
    When <root-type>(<subtype-name>) get owns(work-email) set override: email
    Then <root-type>(<subtype-name>) get owns overridden(work-email) get name: email
    Then <root-type>(<subtype-name>) get owns(work-email) get ordering: ordered
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
    When create attribute type: email
    When attribute(email) set value type: <value-type>
    When create attribute type: name
    When attribute(name) set value type: <value-type>
    When <root-type>(<supertype-name>) set owns: name
    When <root-type>(<supertype-name>) get owns(name) set ordering: ordered
    Then <root-type>(<subtype-name>) set owns: name
    Then transaction commits; fails
    Examples:
      | root-type | supertype-name | subtype-name | value-type |
      | entity    | person         | customer     | string     |
      | entity    | person         | customer     | long       |
      | relation  | description    | registration | string     |
      | relation  | description    | registration | datetime   |

  Scenario Outline: <root-type> types cannot redeclare inherited owns in multiple layers of inheritance
    When create attribute type: name
    When attribute(name) set value type: <value-type>
    When attribute(name) set annotation: @abstract
    When create attribute type: customer-name
    When attribute(customer-name) set value type: <value-type>
    When attribute(customer-name) set supertype: name
    When <root-type>(<supertype-name>) set annotation: @abstract
    When <root-type>(<supertype-name>) set owns: name
    When <root-type>(<supertype-name>) get owns(name) set ordering: ordered
    When <root-type>(<subtype-name>) set owns: customer-name
    When <root-type>(<subtype-name>) get owns(customer-name) set ordering: ordered
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
    When create attribute type: name
    When attribute(name) set value type: <value-type>
    When attribute(name) set annotation: @abstract
    When create attribute type: customer-name
    When attribute(customer-name) set value type: <value-type>
    When attribute(customer-name) set supertype: name
    When <root-type>(<supertype-name>) set annotation: @abstract
    When <root-type>(<supertype-name>) set owns: name
    When <root-type>(<supertype-name>) get owns(name) set ordering: ordered
    # TODO: No set override here?
    When <root-type>(<subtype-name>) set owns: customer-name
    When <root-type>(<subtype-name>) get owns(customer-name) set ordering: ordered
    When <root-type>(<subtype-name-2>) set supertype: <subtype-name>
    Then <root-type>(<subtype-name-2>) set owns: customer-name
    When <root-type>(<subtype-name-2>) get owns(customer-name) set ordering: ordered
    Then transaction commits; fails
    Examples:
      | root-type | supertype-name | subtype-name | subtype-name-2 | value-type |
      | entity    | person         | customer     | subscriber     | boolean    |
      | entity    | person         | customer     | subscriber     | long       |
      | relation  | description    | registration | profile        | duration   |
      | relation  | description    | registration | profile        | double     |

  Scenario Outline: <root-type> types cannot override declared owns with owns
    When create attribute type: name
    When attribute(name) set value type: <value-type>
    When attribute(name) set annotation: @abstract
    When create attribute type: first-name
    When attribute(first-name) set value type: <value-type>
    When attribute(first-name) set supertype: name
    When <root-type>(<type-name>) set annotation: @abstract
    When <root-type>(<type-name>) set owns: name
    When <root-type>(<type-name>) get owns(name) set ordering: ordered
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<type-name>) set owns: first-name
    When <root-type>(<type-name>) get owns(first-name) set ordering: ordered
    Then <root-type>(<type-name>) get owns(first-name) set override: first-name; fails
    Then <root-type>(<type-name>) get owns(first-name) set override: name; fails
    Examples:
      | root-type | type-name   | value-type |
      | entity    | person      | string     |
      | relation  | description | string     |

  Scenario Outline: <root-type> types cannot override inherited owns other than with their subtypes
    When create attribute type: username
    When attribute(username) set value type: <value-type>
    When create attribute type: reference
    When attribute(reference) set value type: <value-type>
    When <root-type>(<supertype-name>) set owns: username
    When <root-type>(<supertype-name>) get owns(username) set ordering: ordered
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<subtype-name>) set owns: reference
    When <root-type>(<subtype-name>) get owns(reference) set ordering: ordered
    Then <root-type>(<subtype-name>) get owns(reference) set override: reference; fails
    Then <root-type>(<subtype-name>) get owns(reference) set override: username; fails
    Examples:
      | root-type | supertype-name | subtype-name | value-type |
      | entity    | person         | customer     | double     |
      | relation  | description    | registration | string     |

  Scenario Outline: <root-type> types cannot unset not owned ordered ownership
    When create attribute type: username
    When attribute(username) set value type: <value-type>
    When create attribute type: reference
    When attribute(reference) set value type: <value-type>
    When <root-type>(<type-name>) set owns: username
    Then <root-type>(<type-name>) get owns contain: username
    When <root-type>(<type-name>) get owns(username) set ordering: ordered
    Then <root-type>(<type-name>) unset owns: reference; fails
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<type-name>) get owns contain: username
    Then <root-type>(<type-name>) get owns(username) get ordering: ordered
    Then <root-type>(<type-name>) unset owns: reference; fails
    Then <root-type>(<type-name>) unset owns: username
    Then <root-type>(<type-name>) unset owns: username; fails
    Then <root-type>(<type-name>) get owns is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then <root-type>(<type-name>) get owns is empty
    Examples:
      | root-type | type-name   | value-type |
      | entity    | person      | string     |
      | relation  | description | long       |

  Scenario Outline: <root-type> types cannot unset inherited ordered ownership
    When create attribute type: username
    When attribute(username) set value type: <value-type>
    When <root-type>(<supertype-name>) set owns: username
    Then <root-type>(<supertype-name>) get owns contain: username
    When <root-type>(<supertype-name>) get owns(username) set ordering: ordered
    Then <root-type>(<subtype-name>) get owns contain: username
    Then <root-type>(<subtype-name>) get owns(username) get ordering: ordered
    Then <root-type>(<subtype-name>) unset owns: username; fails
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<subtype-name>) get owns contain: username
    Then <root-type>(<subtype-name>) get owns(username) get ordering: ordered
    Then <root-type>(<subtype-name>) unset owns: username; fails
    Examples:
      | root-type | supertype-name | subtype-name | value-type |
      | entity    | person         | customer     | string     |
      | relation  | description    | registration | long       |

  Scenario Outline: <root-type> types can set ordered for inherited unordered ownerships
    When create attribute type: email
    When attribute(email) set value type: <value-type>
    When attribute(email) set annotation: @abstract
    When create attribute type: work-email
    When attribute(work-email) set value type: <value-type>
    When attribute(work-email) set supertype: email
    When create attribute type: personal-email
    When attribute(personal-email) set value type: <value-type>
    When attribute(personal-email) set supertype: email
    When <root-type>(<supertype-name>) set annotation: @abstract
    When <root-type>(<supertype-name>) set owns: email
    Then <root-type>(<supertype-name>) get owns(email) get ordering: unordered
    When <root-type>(<subtype-name>) set owns: work-email
    Then <root-type>(<subtype-name>) get owns(work-email) get ordering: unordered
    When <root-type>(<subtype-name-2>) set owns: personal-email
    Then <root-type>(<subtype-name-2>) get owns(personal-email) get ordering: unordered
    When transaction commits
    When connection open schema transaction for database: typedb
    When <root-type>(<subtype-name>) get owns(work-email) set ordering: ordered
    When <root-type>(<subtype-name>) get owns(work-email) set override: email
    When <root-type>(<subtype-name-2>) get owns(personal-email) set override: email
    Then <root-type>(<subtype-name>) get owns(work-email) get supertype: email
    Then <root-type>(<subtype-name-2>) get owns(personal-email) get supertype: email
    When <root-type>(<subtype-name-2>) get owns(personal-email) set ordering: ordered
    Then <root-type>(<supertype-name>) get owns(email) get ordering: unordered
    Then <root-type>(<subtype-name>) get owns(work-email) get ordering: ordered
    Then <root-type>(<subtype-name-2>) get owns(personal-email) get ordering: ordered
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<supertype-name>) get owns(email) get ordering: unordered
    Then <root-type>(<subtype-name>) get owns(work-email) get ordering: ordered
    Then <root-type>(<subtype-name-2>) get owns(personal-email) get ordering: ordered
    When <root-type>(<subtype-name>) get owns(work-email) set ordering: unordered
    When <root-type>(<subtype-name-2>) get owns(personal-email) set ordering: unordered
    Then <root-type>(<supertype-name>) get owns(email) get ordering: unordered
    Then <root-type>(<subtype-name>) get owns(work-email) get ordering: unordered
    Then <root-type>(<subtype-name-2>) get owns(personal-email) get ordering: unordered
    When transaction commits
    When connection open read transaction for database: typedb
    Then <root-type>(<supertype-name>) get owns(email) get ordering: unordered
    Then <root-type>(<subtype-name>) get owns(work-email) get ordering: unordered
    Then <root-type>(<subtype-name-2>) get owns(personal-email) get ordering: unordered
    Examples:
      | root-type | supertype-name | subtype-name | subtype-name-2 | value-type    |
      | entity    | person         | customer     | subscriber     | decimal       |
      | relation  | description    | registration | profile        | custom-struct |

  Scenario Outline: Unordered and ordered are propagated to subtypes of ownerships for <root-type> types unless overridden
    When create attribute type: name
    When attribute(name) set value type: <value-type>
    When attribute(name) set annotation: @abstract
    When create attribute type: email
    When attribute(email) set value type: <value-type>
    When attribute(email) set annotation: @abstract
    When create attribute type: work-email
    When attribute(work-email) set supertype: email
    When create attribute type: first-name
    When attribute(first-name) set supertype: name
    When create attribute type: personal-email
    When attribute(personal-email) set supertype: email
    When create attribute type: surname
    When attribute(surname) set supertype: name
    When <root-type>(<supertype-name>) set annotation: @abstract
    When <root-type>(<supertype-name>) set owns: name
    Then <root-type>(<supertype-name>) get owns(name) get ordering: unordered
    When <root-type>(<supertype-name>) set owns: email
    When <root-type>(<supertype-name>) get owns(email) set ordering: ordered
    Then <root-type>(<supertype-name>) get owns(email) get ordering: ordered
    When <root-type>(<subtype-name>) set owns: first-name
    When <root-type>(<subtype-name-2>) set owns: surname
    When <root-type>(<subtype-name>) set owns: work-email
    When <root-type>(<subtype-name-2>) set owns: personal-email
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<subtype-name>) get owns(first-name) get ordering: unordered
    Then <root-type>(<subtype-name-2>) get owns(surname) get ordering: unordered
    Then <root-type>(<subtype-name>) get owns(work-email) get ordering: unordered
    Then <root-type>(<subtype-name-2>) get owns(personal-email) get ordering: unordered
    When <root-type>(<subtype-name>) get owns(first-name) set override: name
    Then <root-type>(<subtype-name>) get owns(first-name) get ordering: unordered
    When <root-type>(<subtype-name-2>) get owns(surname) set override: name
    Then <root-type>(<subtype-name-2>) get owns(surname) get ordering: unordered
    When <root-type>(<subtype-name>) get owns(work-email) set override: email
    Then <root-type>(<subtype-name>) get owns(work-email) get ordering: ordered
    When <root-type>(<subtype-name-2>) get owns(personal-email) set override: email
    Then <root-type>(<subtype-name-2>) get owns(personal-email) get ordering: ordered
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<subtype-name>) get owns(first-name) get ordering: unordered
    Then <root-type>(<subtype-name-2>) get owns(surname) get ordering: unordered
    Then <root-type>(<subtype-name>) get owns(work-email) get ordering: ordered
    Then <root-type>(<subtype-name-2>) get owns(personal-email) get ordering: ordered
    When <root-type>(<subtype-name-2>) get owns(surname) set ordering: ordered
    Then <root-type>(<subtype-name-2>) get owns(surname) get ordering: ordered
    When <root-type>(<subtype-name-2>) get owns(personal-email) set ordering: ordered
    Then <root-type>(<subtype-name-2>) get owns(personal-email) get ordering: ordered
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<subtype-name>) get owns(first-name) get ordering: unordered
    Then <root-type>(<subtype-name-2>) get owns(surname) get ordering: unordered
    Then <root-type>(<subtype-name>) get owns(work-email) get ordering: ordered
    Then <root-type>(<subtype-name-2>) get owns(personal-email) get ordering: ordered
    When <root-type>(<supertype-name>) get owns(name) set ordering: ordered
    Then <root-type>(<subtype-name>) get owns(first-name) get ordering: ordered
    Then <root-type>(<subtype-name-2>) get owns(surname) get ordering: ordered
    When <root-type>(<supertype-name>) get owns(email) set ordering: unordered
    Then <root-type>(<subtype-name>) get owns(first-name) get ordering: unordered
    Then <root-type>(<subtype-name-2>) get owns(surname) get ordering: ordered
    When transaction commits
    When connection open read transaction for database: typedb
    Then <root-type>(<subtype-name>) get owns(first-name) get ordering: ordered
    Then <root-type>(<subtype-name-2>) get owns(surname) get ordering: ordered
    Then <root-type>(<subtype-name>) get owns(first-name) get ordering: unordered
    Then <root-type>(<subtype-name-2>) get owns(surname) get ordering: ordered
    Examples:
      | root-type | supertype-name | subtype-name | value-type |
      | entity    | person         | customer     | datetime   |
      | relation  | description    | registration | double     |

  Scenario Outline: Ownership can set and unset ordering if it inherits unordered ownership for <root-type>
    When create attribute type: name
    When attribute(name) set value type: <value-type>
    When <root-type>(<supertype-name>) set owns: name
    Then <root-type>(<supertype-name>) get owns(name) get ordering: unordered
    Then <root-type>(<subtype-name>) get owns(name) get ordering: unordered
    When <root-type>(<subtype-name>) get owns(name) set ordering: ordered
    Then <root-type>(<supertype-name>) get owns(name) get ordering: unordered
    Then <root-type>(<subtype-name>) get owns(name) get ordering: ordered
    When transaction commit
    When connection open schema transaction for database: typedb
    Then <root-type>(<supertype-name>) get owns(name) get ordering: unordered
    Then <root-type>(<subtype-name>) get owns(name) get ordering: ordered
    When <root-type>(<subtype-name>) get owns(name) set ordering: unordered
    Then <root-type>(supertype-name>) get owns(name) get ordering: unordered
    Then <root-type>(<subtype-name>) get owns(name) get ordering: unordered
    When transaction commit
    When connection open read transaction for database: typedb
    Then <root-type>(<supertype-name>) get owns(name) get ordering: unordered
    Then <root-type>(<subtype-name>) get owns(name) get ordering: unordered
    Examples:
      | root-type | supertype-name | subtype-name | value-type |
      | entity    | person         | customer     | decimal    |
      | relation  | description    | registration | long       |

  Scenario Outline: Ownership cannot set or unset ordering if it inherits ordered ownership for <root-type>
    When create attribute type: name
    When attribute(name) set value type: <value-type>
    When <root-type>(<supertype-name>) set owns: name
    When <root-type>(<supertype-name>) get owns(name) set ordering: ordered
    Then <root-type>(<supertype-name>) get owns(name) get ordering: ordered
    When transaction commit
    When connection open schema transaction for database: typedb
    Then <root-type>(<supertype-name>) get owns(name) get ordering: ordered
    Then <root-type>(<subtype-name>) get owns(name) get ordering: ordered
    When <root-type>(<subtype-name>) get owns(name) set ordering: ordered
    Then transaction commit; fails
    When connection open schema transaction for database: typedb
    Then <root-type>(<supertype-name>) get owns(name) get ordering: ordered
    Then <root-type>(<subtype-name>) get owns(name) get ordering: ordered
    Then <root-type>(<subtype-name>) get owns(name) set ordering: unordered; fails
    Then <root-type>(<supertype-name>) get owns(name) get ordering: ordered
    Then <root-type>(<subtype-name>) get owns(name) get ordering: ordered
    Then transaction commit
    When connection open read transaction for database: typedb
    Then <root-type>(<supertype-name>) get owns(name) get ordering: ordered
    Then <root-type>(<subtype-name>) get owns(name) get ordering: ordered
    Examples:
      | root-type | supertype-name | subtype-name | value-type |
      | entity    | person         | customer     | boolean    |
      | relation  | description    | registration | datetimetz |

  Scenario Outline: Ownership can set and unset ordering if it overrides unordered ownership for <root-type>
    When create attribute type: name
    When attribute(name) set value type: <value-type>
    When attribute(name) set annotation: @abstract
    When create attribute type: surname
    When attribute(surname) set supertype: name
    When <root-type>(<supertype-name>) set owns: name
    Then <root-type>(<supertype-name>) get owns(name) get ordering: unordered
    When transaction commit
    When connection open schema transaction for database: typedb
    When <root-type>(<subtype-name>) set owns: surname
    When <root-type>(<subtype-name>) get owns(surname) set override: name
    Then <root-type>(<supertype-name>) get owns(name) get ordering: unordered
    Then <root-type>(<subtype-name>) get owns(surname) get ordering: unordered
    When <root-type>(<subtype-name>) get owns(surname) set ordering: ordered
    Then <root-type>(<supertype-name>) get owns(name) get ordering: unordered
    Then <root-type>(<subtype-name>) get owns(surname) get ordering: ordered
    Then <root-type>(<subtype-name>) get owns(surname) get supertype: name
    When transaction commit
    When connection open schema transaction for database: typedb
    Then <root-type>(<supertype-name>) get owns(name) get ordering: unordered
    Then <root-type>(<subtype-name>) get owns(surname) get ordering: ordered
    When <root-type>(<subtype-name>) get owns(surname) set ordering: unordered
    Then <root-type>(<supertype-name>) get owns(name) get ordering: unordered
    Then <root-type>(<subtype-name>) get owns(surname) get ordering: unordered
    When transaction commit
    When connection open schema transaction for database: typedb
    Then <root-type>(<supertype-name>) get owns(name) get ordering: unordered
    Then <root-type>(<subtype-name>) get owns(surname) get ordering: unordered
    When connection open schema transaction for database: typedb
    When create attribute type: third-name
    When attribute(third-name) set supertype: name
    When <root-type>(<subtype-name-2>) set owns: third-name
    When <root-type>(<subtype-name-2>) get owns(third-name) set ordering: ordered
    When <root-type>(<subtype-name-2>) get owns(third-name) set override: name
    Then <root-type>(<supertype-name>) get owns(name) get ordering: unordered
    Then <root-type>(<subtype-name-2>) get owns(third-name) get ordering: ordered
    Then <root-type>(<subtype-name-2>) get owns(third-name) get supertype: name
    When transaction commit
    When connection open schema transaction for database: typedb
    Then <root-type>(<supertype-name>) get owns(name) get ordering: unordered
    Then <root-type>(<subtype-name-2>) get owns(third-name) get ordering: ordered
    When <root-type>(<subtype-name-2>) get owns(third-name) set ordering: unordered
    Then <root-type>(<supertype-name>) get owns(name) get ordering: unordered
    Then <root-type>(<subtype-name-2>) get owns(third-name) get ordering: unordered
    When transaction commit
    When connection open read transaction for database: typedb
    Then <root-type>(<supertype-name>) get owns(name) get ordering: unordered
    Then <root-type>(<subtype-name-2>) get owns(third-name) get ordering: unordered
    Examples:
      | root-type | supertype-name | subtype-name | subtype-name-2 | value-type    |
      | entity    | person         | customer     | subscriber     | decimal       |
      | relation  | description    | registration | profile        | custom-struct |

  Scenario Outline: Ownership cannot set or unset ordering if it overrides ordered ownership for <root-type>
    When create attribute type: name
    When attribute(name) set value type: <value-type>
    When attribute(name) set annotation: @abstract
    When <root-type>(<supertype-name>) set owns: name
    When <root-type>(<supertype-name>) get owns(name) set ordering: ordered
    Then <root-type>(<supertype-name>) get owns(name) get ordering: ordered
    When transaction commit
    When connection open schema transaction for database: typedb
    When create attribute type: surname
    When attribute(surname) set supertype: name
    When <root-type>(<subtype-name>) set owns: surname
    When <root-type>(<subtype-name>) get owns(surname) set override: name
    Then <root-type>(<supertype-name>) get owns(name) get ordering: ordered
    Then <root-type>(<subtype-name>) get owns(surname) get ordering: ordered
    When transaction commit
    When connection open schema transaction for database: typedb
    Then <root-type>(<supertype-name>) get owns(name) get ordering: ordered
    Then <root-type>(<subtype-name>) get owns(surname) get ordering: ordered
    When <root-type>(<subtype-name>) get owns(surname) set ordering: ordered
    Then transaction commit; fails
    When connection open schema transaction for database: typedb
    Then <root-type>(<supertype-name>) get owns(name) get ordering: ordered
    Then <root-type>(<subtype-name>) get owns(surname) get ordering: ordered
    Then <root-type>(<subtype-name>) get owns(surname) set ordering: unordered; fails
    When connection open schema transaction for database: typedb
    When <root-type>(<subtype-name-2>) set owns: third-name
    When <root-type>(<subtype-name-2>) get owns(third-name) set ordering: ordered
    When relation(third-nameship) get owns(third-name) set override: name
    Then <root-type>(<supertype-name>) get owns(name) get ordering: ordered
    Then <root-type>(<subtype-name-2>) get owns(third-name) get ordering: ordered
    Then <root-type>(<subtype-name-2>) get owns(third-name) get supertype: name
    When transaction commit
    When connection open schema transaction for database: typedb
    Then <root-type>(<supertype-name>) get owns(name) get ordering: ordered
    Then <root-type>(<subtype-name-2>) get owns(third-name) get ordering: ordered
    When <root-type>(<subtype-name-2>) get owns(third-name) set ordering: ordered
    Then transaction commit; fails
    When connection open schema transaction for database: typedb
    Then <root-type>(<supertype-name>) get owns(name) get ordering: ordered
    Then <root-type>(<subtype-name-2>) get owns(third-name) get ordering: ordered
    Then <root-type>(<subtype-name-2>) get owns(third-name) set ordering: unordered; fails
    Examples:
      | root-type | supertype-name | subtype-name | subtype-name-2 | value-type    |
      | entity    | person         | customer     | subscriber     | decimal       |
      | relation  | description    | registration | profile        | custom-struct |

########################
# @annotations common: contain common tests for annotations suitable for **scalar** owns:
# @key, @unique, @subkey, @values, @range, @card, @regex
# DOES NOT test:
# @distinct
########################

  Scenario Outline: <root-type> types can set owns with @<annotation> and unset it
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When <root-type>(<type-name>) set owns: custom-attribute
    When <root-type>(<type-name>) get owns(custom-attribute) set annotation: @<annotation>
    Then <root-type>(<type-name>) get owns(custom-attribute) get annotations contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<type-name>) get owns(custom-attribute) get annotations contain: @<annotation>
    When <root-type>(<type-name>) get owns(custom-attribute) unset annotation: @<annotation>
    Then <root-type>(<type-name>) get owns(custom-attribute) get annotations is empty
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<type-name>) get owns(custom-attribute) get annotations is empty
    When <root-type>(<type-name>) get owns(custom-attribute) set annotation: @<annotation>
    Then <root-type>(<type-name>) get owns(custom-attribute) get annotations contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<type-name>) get owns(custom-attribute) get annotations contain: @<annotation>
    When <root-type>(<type-name>) unset owns: custom-attribute
    Then <root-type>(<type-name>) get owns is empty
    When transaction commits
    When connection open read transaction for database: typedb
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
    When create attribute type: email
    When attribute(email) set value type: string
    When create attribute type: username
    When attribute(username) set value type: string
    When create attribute type: name
    When attribute(name) set value type: string
    When create attribute type: age
    When attribute(age) set value type: long
    When <root-type>(<type-name>) set owns: email
    When <root-type>(<type-name>) get owns(email) set annotation: @<annotation>
    When <root-type>(<type-name>) set owns: username
    When <root-type>(<type-name>) get owns(username) set annotation: @<annotation>
    When <root-type>(<type-name>) set owns: name
    When <root-type>(<type-name>) set owns: age
    Then <root-type>(<type-name>) get owns(email) get annotations contain: @<annotation>
    Then <root-type>(<type-name>) get owns(username) get annotations contain: @<annotation>
    Then <root-type>(<type-name>) get owns contain:
      | email    |
      | username |
      | name     |
      | age      |
    When transaction commits
    When connection open read transaction for database: typedb
    Then <root-type>(<type-name>) get owns(email) get annotations contain: @<annotation>
    Then <root-type>(<type-name>) get owns(username) get annotations contain: @<annotation>
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
    When create attribute type: username
    When attribute(username) set value type: string
    When create attribute type: reference
    When attribute(reference) set value type: string
    When <root-type>(<type-name>) set owns: username
    When <root-type>(<type-name>) get owns(username) set annotation: @<annotation>
    Then <root-type>(<type-name>) get owns(username) get annotation contain: @<annotation>
    When <root-type>(<type-name>) set owns: reference
    Then <root-type>(<type-name>) get owns(reference) unset annotation: @<annotation>; fails
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<type-name>) get owns(username) get annotation contain: @<annotation>
    Then <root-type>(<type-name>) get owns(reference) unset annotation: @<annotation>; fails
    Then <root-type>(<type-name>) get owns(username) unset annotation: @<annotation>
    Then <root-type>(<type-name>) get owns(username) unset annotation: @<annotation>; fails
    Then <root-type>(<type-name>) get owns(username) get annotations is empty
    Then <root-type>(<type-name>) get owns(reference) get annotations is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then <root-type>(<type-name>) get owns(username) get annotations is empty
    Then <root-type>(<type-name>) get owns(reference) get annotations is empty
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
    When create attribute type: username
    When attribute(username) set value type: string
    When <root-type>(<supertype-name>) set owns: username
    When <root-type>(<supertype-name>) get owns(username) set annotation: @<annotation>
    Then <root-type>(<supertype-name>) get owns(username) get annotation contain: @<annotation>
    Then <root-type>(<subtype-name>) get owns(username) get annotation contain: @<annotation>
    Then <root-type>(<subtype-name>) get owns(username) unset annotation: @<annotation>; fails
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<subtype-name>) get owns(username) get annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get owns(username) unset annotation: @<annotation>; fails
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
    When create attribute type: email
    When attribute(email) set value type: string
    When create attribute type: name
    When attribute(name) set value type: string
    When create attribute type: reference
    When attribute(reference) set value type: string
    When create attribute type: rating
    When attribute(rating) set value type: double
    When <root-type>(<supertype-name>) set owns: email
    When <root-type>(<supertype-name>) get owns(email) set annotation: @<annotation>
    When <root-type>(<supertype-name>) set owns: name
    When <root-type>(<subtype-name>) set owns: reference
    When <root-type>(<subtype-name>) get owns(reference) set annotation: @<annotation>
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
    Then <root-type>(<subtype-name>) get owns(email) get annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get owns(reference) get annotations contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
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
    Then <root-type>(<subtype-name>) get owns(email) get annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get owns(reference) get annotations contain: @<annotation>
    When create attribute type: license
    When attribute(license) set value type: string
    When create attribute type: points
    When attribute(points) set value type: double
    When <root-type>(<subtype-name-2>) set supertype: <subtype-name>
    When <root-type>(<subtype-name-2>) set owns: license
    When <root-type>(<subtype-name-2>) get owns(license) set annotation: @<annotation>
    When <root-type>(<subtype-name-2>) set owns: points
    When transaction commits
    When connection open read transaction for database: typedb
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
    Then <root-type>(<subtype-name>) get owns(email) get annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get owns(reference) get annotations contain: @<annotation>
    Then <root-type>(<subtype-name-2>) get owns(email) get annotations contain: @<annotation>
    Then <root-type>(<subtype-name-2>) get owns(reference) get annotations contain: @<annotation>
    Then <root-type>(<subtype-name-2>) get owns(license) get annotations contain: @<annotation>
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

  Scenario Outline: <root-type> types can redeclare owns with @<annotation>s as owns with @<annotation>s
    When create attribute type: name
    When attribute(name) set value type: <value-type>
    When create attribute type: email
    When attribute(email) set value type: <value-type>
    When <root-type>(<type-name>) set owns: name
    When <root-type>(<type-name>) get owns(name) set annotation: @<annotation>
    Then <root-type>(<type-name>) get owns(name) get annotation contain: @<annotation>
    When <root-type>(<type-name>) set owns: email
    When <root-type>(<type-name>) get owns(email) set annotation: @<annotation>
    Then <root-type>(<type-name>) get owns(email) get annotation contain: @<annotation>
    Then <root-type>(<type-name>) set owns: name
    Then <root-type>(<type-name>) get owns(name) set annotation: @<annotation>
    Then <root-type>(<type-name>) get owns(name) get annotation contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<type-name>) get owns(name) get annotation contain: @<annotation>
    Then <root-type>(<type-name>) set owns: email
    Then <root-type>(<type-name>) get owns(email) set annotation: @<annotation>
    Then <root-type>(<type-name>) get owns(email) get annotation contain: @<annotation>
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
    When create attribute type: name
    When attribute(name) set value type: <value-type>
    When create attribute type: email
    When attribute(email) set value type: <value-type>
    When create attribute type: address
    When attribute(address) set value type: <value-type>
    When <root-type>(<type-name>) set owns: name
    When <root-type>(<type-name>) set owns: email
    When <root-type>(<type-name>) set owns: address
    Then <root-type>(<type-name>) set owns: name
    Then <root-type>(<type-name>) get owns(name) set annotation: @<annotation>
    Then <root-type>(<type-name>) get owns(name) get annotations contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<type-name>) set owns: email
    Then <root-type>(<type-name>) get owns(email) get annotations is empty
    When <root-type>(<type-name>) get owns(email) set annotation: @<annotation>
    Then <root-type>(<type-name>) get owns(email) get annotations contain: @<annotation>
    Then <root-type>(<type-name>) get owns(address) get annotations is empty
    When <root-type>(<type-name>) get owns(address) set annotation: @<annotation>
    Then <root-type>(<type-name>) get owns(address) get annotations contain: @<annotation>
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

  Scenario Outline: <root-type> types can redeclare owns with @<annotation> as pure owns
    When create attribute type: name
    When attribute(name) set value type: <value-type>
    When create attribute type: email
    When attribute(email) set value type: <value-type>
    When <root-type>(<type-name>) set owns: name
    When <root-type>(<type-name>) get owns(name) set annotation: @<annotation>
    Then <root-type>(<type-name>) get owns(name) get annotations contain: @<annotation>
    When <root-type>(<type-name>) set owns: email
    When <root-type>(<type-name>) get owns(email) set annotation: @<annotation>
    Then <root-type>(<type-name>) get owns(email) get annotations contain: @<annotation>
    Then <root-type>(<type-name>) set owns: name
    Then <root-type>(<type-name>) get owns(name) get annotations is empty
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<type-name>) get owns(email) get annotations contain: @<annotation>
    When <root-type>(<type-name>) set owns: email
    Then <root-type>(<type-name>) get owns(email) get annotations is empty
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
    When create attribute type: name
    When attribute(name) set value type: <value-type>
    When attribute(name) set annotation: @abstract
    When create attribute type: username
    When attribute(username) set value type: <value-type>
    When attribute(username) set supertype: name
    When <root-type>(<supertype-name>) set annotation: @abstract
    When <root-type>(<supertype-name>) set owns: name
    When <root-type>(<subtype-name>) set owns: username
    When <root-type>(<subtype-name>) get owns(username) set override: name
    When <root-type>(<subtype-name>) get owns(username) set annotation: @<annotation>
    Then <root-type>(<subtype-name>) get owns overridden(username) get name: name
    Then <root-type>(<subtype-name>) get owns(username) get annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get owns(name) get annotations do not contain: @<annotation>
    Then <root-type>(<subtype-name>) get owns contain:
      | username |
    Then <root-type>(<subtype-name>) get owns do not contain:
      | name |
    When transaction commits
    When connection open read transaction for database: typedb
    Then <root-type>(<subtype-name>) get owns overridden(username) get name: name
    Then <root-type>(<subtype-name>) get owns(username) get annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get owns(name) get annotations do not contain: @<annotation>
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

  Scenario Outline: <root-type> types can re-override owns with <annotation>s
    When create attribute type: email
    When attribute(email) set value type: <value-type>
    When attribute(email) set annotation: @abstract
    When create attribute type: work-email
    When attribute(work-email) set value type: <value-type>
    When attribute(work-email) set supertype: email
    When <root-type>(<supertype-name>) set annotation: @abstract
    When <root-type>(<supertype-name>) set owns: email
    When <root-type>(<supertype-name>) get owns(email) set annotation: @<annotation>
    When <root-type>(<subtype-name>) set annotation: @abstract
    Then <root-type>(<subtype-name>) get owns contain: email
    Then <root-type>(<subtype-name>) get owns(email) get annotations contain: @<annotation>
    When <root-type>(<subtype-name>) set owns: work-email
    When <root-type>(<subtype-name>) get owns(work-email) set override: email
    Then <root-type>(<subtype-name>) get owns overridden(work-email) get name: email
    Then <root-type>(<subtype-name>) get owns overridden(work-email)) get annotations contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    When <root-type>(<subtype-name>) set owns: work-email
    When <root-type>(<subtype-name>) get owns(work-email) set override: email
    Then <root-type>(<subtype-name>) get owns overridden(work-email) get name: email
    Then <root-type>(<subtype-name>) get owns overridden(work-email)) get annotations contain: @<annotation>
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

  Scenario Outline: <root-type> types can redeclare inherited owns as owns with @<annotation> (which will override)
    When create attribute type: email
    When attribute(email) set value type: <value-type>
    When <root-type>(<supertype-name>) set owns: email
    Then <root-type>(<supertype-name>) get owns overridden(email) does not exist
    Then <root-type>(<subtype-name>) set owns: email
    Then <root-type>(<subtype-name>) get owns(email) set annotation: @<annotation>
    Then <root-type>(<subtype-name>) get owns overridden(email) exists
    Then <root-type>(<subtype-name>) get owns overridden(email) get name: email
    Then <root-type>(<subtype-name>) get owns(email) get annotations contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<subtype-name>) get owns(email) get annotations contain: @<annotation>
    Then <root-type>(<subtype-name-2>) set owns: email
    Then <root-type>(<subtype-name-2>) get owns(email) set annotation: @<annotation>
    Then <root-type>(<subtype-name-2>) get owns(email) get annotations contain: @<annotation>
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
    When create attribute type: email
    When attribute(email) set value type: <value-type>
    When create attribute type: name
    When attribute(name) set value type: <value-type>
    When <root-type>(<supertype-name>) set owns: email
    When <root-type>(<supertype-name>) get owns(email) set annotation: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<subtype-name>) set owns: email
    Then transaction commits; fails
    Then transaction closes
    When connection open schema transaction for database: typedb
    Then <root-type>(<subtype-name>) set owns: email
    Then <root-type>(<subtype-name>) get owns(email) set annotation: @<annotation>
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
    When create attribute type: email
    When attribute(email) set value type: <value-type>
    When attribute(email) set annotation: @abstract
    When create attribute type: customer-email
    When attribute(customer-email) set value type: <value-type>
    When attribute(customer-email) set supertype: email
    When <root-type>(<supertype-name>) set annotation: @abstract
    When <root-type>(<supertype-name>) set owns: email
    When <root-type>(<supertype-name>) get owns(email) set annotation: @<annotation>
    When <root-type>(<subtype-name>) set owns: customer-email
    When <root-type>(<subtype-name>) get owns(customer-email) set annotation: @<annotation>
    When <root-type>(<subtype-name-2>) set supertype: <subtype-name>
    Then <root-type>(<subtype-name-2>) set owns: email
    Then <root-type>(<subtype-name-2>) get owns(email) set annotation: @<annotation>
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
    When create attribute type: email
    When attribute(email) set value type: <value-type>
    When attribute(email) set annotation: @abstract
    When create attribute type: customer-email
    When attribute(customer-email) set value type: <value-type>
    When attribute(customer-email) set supertype: email
    When <root-type>(<supertype-name>) set annotation: @abstract
    When <root-type>(<supertype-name>) set owns: email
    When <root-type>(<supertype-name>) get owns(email) set annotation: @<annotation>
    When <root-type>(<subtype-name>) set owns: customer-email
    # TODO: Do we have overrides? Revalidate "override"-mentioning tests if we do need it and place it everywhere!
#    When <root-type>(<subtype-name>) get owns(customer-email) set override: email
    When <root-type>(<subtype-name-2>) set supertype: <subtype-name>
    Then <root-type>(<subtype-name-2>) set owns: customer-email
    Then <root-type>(<subtype-name-2>) get owns(customer-email) set annotation: @<annotation>
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
    When create attribute type: email
    When attribute(email) set value type: <value-type>
    When attribute(email) set annotation: @abstract
    When create attribute type: customer-email
    When attribute(customer-email) set value type: <value-type>
    When attribute(customer-email) set supertype: email
    When <root-type>(<supertype-name>) set annotation: @abstract
    When <root-type>(<supertype-name>) set owns: email
    When <root-type>(<supertype-name>) get owns(email) set annotation: @<annotation>
    When <root-type>(<subtype-name>) set owns: customer-email
    When <root-type>(<subtype-name>) get owns(customer-email) set annotation: @<annotation>
        # TODO: Do we have overrides?
#    When <root-type>(<subtype-name>) get owns(customer-email) set override: email
    When <root-type>(<subtype-name-2>) set supertype: <subtype-name>
    Then <root-type>(<subtype-name-2>) set owns: customer-email
    Then <root-type>(<subtype-name-2>) get owns(customer-email) set annotation: @<annotation>
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

  Scenario Outline: <root-type> subtypes can redeclare owns with @<annotation>s after it is unset from supertype
    When create attribute type: name
    When attribute(name) set value type: <value-type>
    When create attribute type: surname
    When attribute(surname) set supertype: name
    When <root-type>(<type-name>) set owns: name
    When <root-type>(<type-name>) get owns(name) set annotation: @<annotation>
    Then <root-type>(<type-name>) get owns(name) get annotation contain: @<annotation>
    When <root-type>(<type-name>) set owns: surname
    Then <root-type>(<type-name>) get owns(surname) get annotation contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<type-name>) get owns(name) get annotation contain: @<annotation>
    Then <root-type>(<type-name>) get owns(surname) get annotation contain: @<annotation>
    Then <root-type>(<type-name>) get owns(surname) set annotation: @<annotation>; fails
    When <root-type>(<type-name>) get owns(name) unset annotation: @<annotation>
    Then <root-type>(<type-name>) get owns(name) get annotation is empty
    Then <root-type>(<type-name>) get owns(surname) get annotation is empty
    Then <root-type>(<type-name>) get owns(surname) set annotation: @<annotation>
    Then <root-type>(<type-name>) get owns(name) get annotation is empty
    Then <root-type>(<type-name>) get owns(surname) get annotation contain: @<annotation>
    When transaction commits
    When connection open read transaction for database: typedb
    Then <root-type>(<type-name>) get owns(name) get annotation is empty
    Then <root-type>(<type-name>) get owns(surname) get annotation contain: @<annotation>
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
    When create attribute type: username
    When attribute(username) set value type: string
    When attribute(username) set annotation: @abstract
    When create attribute type: score
    When attribute(score) set value type: double
    When attribute(score) set annotation: @abstract
    When create attribute type: reference
    When attribute(reference) set value type: string
    When attribute(reference) set annotation: @abstract
    When attribute(reference) set supertype: username
    When create attribute type: rating
    When attribute(rating) set value type: double
    When attribute(rating) set annotation: @abstract
    When attribute(rating) set supertype: score
    When <root-type>(<supertype-name>) set annotation: @abstract
    When <root-type>(<supertype-name>) set owns: username
    When <root-type>(<supertype-name>) get owns(username) set annotation: @<annotation>
    When <root-type>(<supertype-name>) set owns: score
    When <root-type>(<subtype-name>) set annotation: @abstract
    When <root-type>(<subtype-name>) set owns: reference
    When <root-type>(<subtype-name>) get owns(reference) set annotation: @<annotation>
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
    Then <root-type>(<subtype-name>) get owns(username) get annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get owns(reference) get annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get owns(score) get annotations do not contain: @<annotation>
    Then <root-type>(<subtype-name>) get owns(rating) get annotations do not contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
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
    Then <root-type>(<subtype-name>) get owns(username) get annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get owns(reference) get annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get owns(score) get annotations do not contain: @<annotation>
    Then <root-type>(<subtype-name>) get owns(rating) get annotations do not contain: @<annotation>
    When create attribute type: license
    When attribute(license) set value type: string
    When attribute(license) set supertype: reference
    When create attribute type: points
    When attribute(points) set value type: double
    When attribute(points) set supertype: rating
    When <root-type>(<subtype-name-2>) set annotation: @abstract
    When <root-type>(<subtype-name-2>) set supertype: <subtype-name>
    When <root-type>(<subtype-name-2>) set owns: license
    When <root-type>(<subtype-name-2>) get owns(license) set annotation: @<annotation>
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
    When connection open read transaction for database: typedb
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
    Then <root-type>(<subtype-name>) get owns(username) get annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get owns(reference) get annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get owns(score) get annotations do not contain: @<annotation>
    Then <root-type>(<subtype-name>) get owns(rating) get annotations do not contain: @<annotation>
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
    Then <root-type>(<subtype-name-2>) get owns(username) get annotations contain: @<annotation>
    Then <root-type>(<subtype-name-2>) get owns(reference) get annotations contain: @<annotation>
    Then <root-type>(<subtype-name-2>) get owns(license) get annotations contain: @<annotation>
    Then <root-type>(<subtype-name-2>) get owns(score) get annotations do not contain: @<annotation>
    Then <root-type>(<subtype-name-2>) get owns(rating) get annotations do not contain: @<annotation>
    Then <root-type>(<subtype-name-2>) get owns(points) get annotations do not contain: @<annotation>
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
    When create attribute type: username
    When attribute(username) set value type: string
    When create attribute type: email
    When attribute(email) set value type: string
    When attribute(email) set annotation: @abstract
    When create attribute type: name
    When attribute(name) set value type: string
    When attribute(name) set annotation: @abstract
    When create attribute type: age
    When attribute(age) set value type: long
    When create attribute type: reference
    When attribute(reference) set value type: string
    When attribute(reference) set annotation: @abstract
    When create attribute type: work-email
    When attribute(work-email) set value type: string
    When attribute(work-email) set supertype: email
    When create attribute type: nick-name
    When attribute(nick-name) set value type: string
    When attribute(nick-name) set supertype: name
    When create attribute type: rating
    When attribute(rating) set value type: double
    When attribute(rating) set annotation: @abstract
    When <root-type>(<supertype-name>) set annotation: @abstract
    When <root-type>(<supertype-name>) set owns: username
    When <root-type>(<supertype-name>) get owns(username) set annotation: @<annotation>
    When <root-type>(<supertype-name>) set owns: email
    When <root-type>(<supertype-name>) get owns(email) set annotation: @<annotation>
    When <root-type>(<supertype-name>) set owns: name
    When <root-type>(<supertype-name>) set owns: age
    When <root-type>(<subtype-name>) set annotation: @abstract
    When <root-type>(<subtype-name>) set owns: reference
    When <root-type>(<subtype-name>) get owns(reference) set annotation: @<annotation>
    When <root-type>(<subtype-name>) set owns: work-email
    When <root-type>(<subtype-name>) get owns(work-email) set override: email
    When <root-type>(<subtype-name>) set owns: rating
    When <root-type>(<subtype-name>) set owns: nick-name
    When <root-type>(<subtype-name>) get owns(nick-name) set override: name
    Then <root-type>(<subtype-name>) get owns overridden(work-email) get name: email
    Then <root-type>(<subtype-name>) get owns overridden(nick-name) get name: name
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
    Then <root-type>(<subtype-name>) get owns(username) get annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get owns(reference) get annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get owns(work-email) get annotations contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<subtype-name>) get owns overridden(work-email) get name: email
    Then <root-type>(<subtype-name>) get owns overridden(nick-name) get name: name
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
    Then <root-type>(<subtype-name>) get owns(username) get annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get owns(reference) get annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get owns(work-email) get annotations contain: @<annotation>
    When create attribute type: license
    When attribute(license) set value type: string
    When attribute(license) set supertype: reference
    When create attribute type: points
    When attribute(points) set value type: double
    When attribute(points) set supertype: rating
    When <root-type>(<subtype-name-2>) set supertype: <subtype-name>
    When <root-type>(<subtype-name-2>) set owns: license
    When <root-type>(<subtype-name-2>) get owns(license) set override: reference
    When <root-type>(<subtype-name-2>) set owns: points
    When <root-type>(<subtype-name-2>) get owns(points) set override: rating
    When transaction commits
    When connection open read transaction for database: typedb
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
    Then <root-type>(<subtype-name>) get owns(username) get annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get owns(reference) get annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get owns(work-email) get annotations contain: @<annotation>
    Then <root-type>(<subtype-name-2>) get owns overridden(license) get name: reference
    Then <root-type>(<subtype-name-2>) get owns overridden(points) get name: rating
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
    Then <root-type>(<subtype-name-2>) get owns(username) get annotations contain: @<annotation>
    Then <root-type>(<subtype-name-2>) get owns(license) get annotations contain: @<annotation>
    Then <root-type>(<subtype-name-2>) get owns(work-email) get annotations contain: @<annotation>
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
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When entity(person) set owns: custom-attribute
    When entity(person) get owns(custom-attribute) set annotation: @key
    Then entity(person) get owns(custom-attribute) get annotations contain: @key
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get annotations contain: @key
    When entity(person) get owns(custom-attribute) unset annotation: @key
    Then entity(person) get owns(custom-attribute) get annotations is empty
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get annotations is empty
    When entity(person) get owns(custom-attribute) set annotation: @key
    Then entity(person) get owns(custom-attribute) get annotations contain: @key
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get annotations contain: @key
    When entity(person) unset owns: custom-attribute
    Then entity(person) get owns is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get owns is empty
    Examples:
      | value-type |
      | long       |
      | string     |
      | boolean    |
      | datetime   |
      | datetimetz |
      | duration   |

  Scenario Outline: Owns can reset @key annotations
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When entity(person) set owns: custom-attribute
    When entity(person) get owns(custom-attribute) set annotation: @key
    Then entity(person) get owns(custom-attribute) get annotations contain: @key
    When entity(person) get owns(custom-attribute) set annotation: @key
    Then entity(person) get owns(custom-attribute) get annotations contain: @key
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get annotations contain: @key
    When entity(person) get owns(custom-attribute) set annotation: @key
    Then entity(person) get owns(custom-attribute) get annotations contain: @key
    Examples:
      | value-type |
      | long       |
      | string     |
      | boolean    |
      | datetime   |
      | datetimetz |
      | duration   |

  Scenario Outline: Owns cannot set @key annotation for <value-type> as it is not keyable
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When entity(person) set owns: custom-attribute
    Then entity(person) get owns(custom-attribute) set annotation: @key; fails
    Then entity(person) get owns(custom-attribute) get annotations is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get annotations is empty
    Examples:
      | value-type    |
      | double        |
      | decimal       |
      | custom-struct |

  Scenario Outline: Owns cannot set @key annotation for ordered ownership
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When entity(person) set owns: custom-attribute
    When entity(person) get owns(custom-attribute) set ordering: ordered
    Then entity(person) get owns(custom-attribute) set annotation: @key; fails
    Then entity(person) get owns(custom-attribute) get annotations is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get annotations is empty
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

     # TODO: Move to thing-feature or schema/data-validation?
#  Scenario: Entity types can only commit keys if every instance owns a distinct key
#    When create attribute type: email
#    When attribute(email) set value type: string
#    When create attribute type: username
#    When attribute(username) set value type: string
#    When entity(person) set owns: username
#    When entity(person) get owns(username) set annotation: @key
#    Then transaction commits
#    When connection open write transaction for database: typedb
#    When $a = entity(person) create new instance with key(username): alice
#    When $b = entity(person) create new instance with key(username): bob
#    Then transaction commits
#    When connection open schema transaction for database: typedb
#    When entity(person) set owns: email
#    When entity(person) get owns(email) set annotation: @key; fails
#    When connection open schema transaction for database: typedb
#    When entity(person) set owns: email
#    Then transaction commits
#    When connection open write transaction for database: typedb
#    When $a = entity(person) get instance with key(username): alice
#    When $alice = attribute(email) as(string) put: alice@vaticle.com
#    When entity $a set has: $alice
#    When $b = entity(person) get instance with key(username): bob
#    When $bob = attribute(email) as(string) put: bob@vaticle.com
#    When entity $b set has: $bob
#    Then transaction commits
#    When connection open schema transaction for database: typedb
#    When entity(person) set owns: email
#    When entity(person) get owns(email) set annotation: @key
#    Then entity(person) get owns(email; get annotations contain: @key
#    Then entity(person) get owns(username; get annotations contain: @key
#    Then transaction commits
#    When connection open read transaction for database: typedb
#    Then entity(person) get owns(email; get annotations contain: @key
#    Then entity(person) get owns(username; get annotations contain: @key

########################
# @subkey
########################

  Scenario Outline: Owns can set @subkey annotation for <value-type> value type and unset it
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When entity(person) set owns: custom-attribute
    When entity(person) get owns(custom-attribute) set annotation: @subkey(<arg>)
    Then entity(person) get owns(custom-attribute) get annotations contain: @subkey(<arg>)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get annotations contain: @subkey(<arg>)
    When entity(person) get owns(custom-attribute) unset annotation: @subkey(<arg>)
    Then entity(person) get owns(custom-attribute) get annotations is empty
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get annotations is empty
    When entity(person) get owns(custom-attribute) set annotation: @subkey(<arg>)
    Then entity(person) get owns(custom-attribute) get annotations contain: @subkey(<arg>)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get annotations contain: @subkey(<arg>)
    When entity(person) unset owns: custom-attribute
    Then entity(person) get owns is empty
    When transaction commits
    When connection open read transaction for database: typedb
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
    When create attribute type: first-name
    When attribute(first-name) set value type: string
    When create attribute type: second-name
    When attribute(second-name) set value type: string
    When create attribute type: third-name
    When attribute(third-name) set value type: string
    When create attribute type: birthday
    When attribute(birthday) set value type: datetime
    When create attribute type: balance
    When attribute(balance) set value type: decimal
    When create attribute type: progress
    When attribute(progress) set value type: double
    When create attribute type: age
    When attribute(age) set value type: long
    When <root-type>(<type-name>) set owns: first-name
    When <root-type>(<type-name>) get owns(first-name) set annotation: @subkey(primary)
    Then <root-type>(<type-name>) get owns(first-name) get annotations contain: @subkey(primary)
    When <root-type>(<type-name>) set owns: second-name
    When <root-type>(<type-name>) get owns(second-name) set annotation: @subkey(primary)
    Then <root-type>(<type-name>) get owns(second-name) get annotations contain: @subkey(primary)
    When <root-type>(<type-name>) set owns: third-name
    When <root-type>(<type-name>) get owns(third-name) set annotation: @subkey(optional)
    Then <root-type>(<type-name>) get owns(third-name) get annotations contain: @subkey(optional)
    When <root-type>(<type-name>) set owns: birthday
    When <root-type>(<type-name>) get owns(birthday) set annotation: @subkey(primary)
    Then <root-type>(<type-name>) get owns(birthday) get annotations contain: @subkey(primary)
    When <root-type>(<type-name>) set owns: balance
    When <root-type>(<type-name>) get owns(balance) set annotation: @subkey(single)
    Then <root-type>(<type-name>) get owns(balance) get annotations contain: @subkey(single)
    When <root-type>(<type-name>) set owns: progress
    When <root-type>(<type-name>) get owns(progress) set annotation: @subkey(optional)
    Then <root-type>(<type-name>) get owns(progress) get annotations contain: @subkey(optional)
    When <root-type>(<type-name>) set owns: age
    When <root-type>(<type-name>) get owns(age) set annotation: @subkey(primary)
    Then <root-type>(<type-name>) get owns(age) get annotations contain: @subkey(primary)
    When transaction commits
    When connection open read transaction for database: typedb
    Then <root-type>(<type-name>) get owns(first-name) get annotations contain: @subkey(primary)
    Then <root-type>(<type-name>) get owns(second-name) get annotations contain: @subkey(primary)
    Then <root-type>(<type-name>) get owns(third-name) get annotations contain: @subkey(optional)
    Then <root-type>(<type-name>) get owns(birthday) get annotations contain: @subkey(primary)
    Then <root-type>(<type-name>) get owns(balance) get annotations contain: @subkey(single)
    Then <root-type>(<type-name>) get owns(progress) get annotations contain: @subkey(optional)
    Then <root-type>(<type-name>) get owns(age) get annotations contain: @subkey(primary)
    Examples:
      | root-type | type-name   |
      | entity    | person      |
      | relation  | description |

  Scenario Outline: Owns can reset @subkey annotation with the same argument
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When entity(person) set owns: custom-attribute
    When entity(person) get owns(custom-attribute) set annotation: @subkey(LABEL)
    Then entity(person) get owns(custom-attribute) get annotations contain: @subkey(LABEL)
    When entity(person) get owns(custom-attribute) set annotation: @subkey(LABEL)
    Then entity(person) get owns(custom-attribute) get annotations contain: @subkey(LABEL)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get annotations contain: @subkey(LABEL)
    When entity(person) get owns(custom-attribute) set annotation: @subkey(LABEL)
    Then entity(person) get owns(custom-attribute) get annotations contain: @subkey(LABEL)
    Examples:
      | value-type |
      | long       |
      | string     |
      | boolean    |
      | datetime   |
      | datetimetz |
      | duration   |

  Scenario: Owns can set multiple @subkey annotations with different arguments
    When create attribute type: name
    When attribute(name) set value type: string
    When create attribute type: surname
    When attribute(surname) set value type: string
    When create attribute type: age
    When attribute(age) set value type: long
    When entity(person) set owns: name
    When entity(person) get owns(name) set annotation: @subkey(NAME-AGE)
    When entity(person) get owns(name) set annotation: @subkey(FULL-NAME)
    Then entity(person) get owns(name) get annotations contain:
      | @subkey(NAME-AGE)  |
      | @subkey(FULL-NAME) |
    When entity(person) set owns: surname
    When entity(person) get owns(surname) set annotation: @subkey(FULL-NAME)
    Then entity(person) get owns(surname) get annotations contain: @subkey(FULL-NAME)
    When entity(person) set owns: age
    When entity(person) get owns(age) set annotation: @subkey(NAME-AGE)
    Then entity(person) get owns(age) get annotations contain: @subkey(NAME-AGE)
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get owns(name) get annotations contain:
      | @subkey(NAME-AGE)  |
      | @subkey(FULL-NAME) |
    Then entity(person) get owns(surname) get annotations contain: @subkey(FULL-NAME)
    Then entity(person) get owns(age) get annotations contain: @subkey(NAME-AGE)

  Scenario Outline: Owns cannot set @subkey annotation for <value-type> as it is not keyable
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When entity(person) set owns: custom-attribute
    Then entity(person) get owns(custom-attribute) set annotation: @subkey(LABEL); fails
    Then entity(person) get owns(custom-attribute) get annotations is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get annotations is empty
    Examples:
      | value-type    |
      | double        |
      | decimal       |
      | custom-struct |

  Scenario: Owns cannot set @subkey annotation for incorrect arguments
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: long
    When entity(person) set owns: custom-attribute
    #  TODO: Make it only for typeql
#    Then entity(person) get owns(custom-attribute) set annotation: @subkey; fails
#    Then entity(person) get owns(custom-attribute) set annotation: @subkey(); fails
    Then entity(person) get owns(custom-attribute) set annotation: @subkey("LABEL"); fails
    Then entity(person) get owns(custom-attribute) set annotation: @subkey(福); fails
    Then entity(person) get owns(custom-attribute) set annotation: @subkey(d./';;p480909!208923r09zlmk*((*£*()(@£Q**&$@)); fails
    Then entity(person) get owns(custom-attribute) set annotation: @subkey(49j93848); fails
    Then entity(person) get owns(custom-attribute) set annotation: @subkey(LABEL, LABEL); fails
    Then entity(person) get owns(custom-attribute) set annotation: @subkey(LABEL, LABEL2); fails
    Then entity(person) get owns(custom-attribute) set annotation: @subkey(LABEL, LABEL2, LABEL3); fails
    Then entity(person) get owns(custom-attribute) get annotations is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get annotations is empty

  Scenario Outline: Owns cannot set @subkey annotation for ordered ownership
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When entity(person) set owns: custom-attribute
    When entity(person) get owns(custom-attribute) set ordering: ordered
    Then entity(person) get owns(custom-attribute) set annotation: @subkey(LABEL); fails
    Then entity(person) get owns(custom-attribute) get annotations is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get annotations is empty
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
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When entity(person) set owns: custom-attribute
    When entity(person) get owns(custom-attribute) set annotation: @unique
    Then entity(person) get owns(custom-attribute) get annotations contain: @unique
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get annotations contain: @unique
    When entity(person) get owns(custom-attribute) unset annotation: @unique
    Then entity(person) get owns(custom-attribute) get annotations is empty
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get annotations is empty
    When entity(person) get owns(custom-attribute) set annotation: @unique
    Then entity(person) get owns(custom-attribute) get annotations contain: @unique
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get annotations contain: @unique
    When entity(person) unset owns: custom-attribute
    Then entity(person) get owns is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get owns is empty
    Examples:
      | value-type |
      | long       |
      | string     |
      | boolean    |
      | datetime   |
      | datetimetz |
      | duration   |

  Scenario Outline: Owns can reset @unique annotation
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When entity(person) set owns: custom-attribute
    When entity(person) get owns(custom-attribute) set annotation: @unique
    Then entity(person) get owns(custom-attribute) get annotations contain: @unique
    When entity(person) get owns(custom-attribute) set annotation: @unique
    Then entity(person) get owns(custom-attribute) get annotations contain: @unique
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get annotations contain: @unique
    When entity(person) get owns(custom-attribute) set annotation: @unique
    Then entity(person) get owns(custom-attribute) get annotations contain: @unique
    Examples:
      | value-type |
      | long       |
      | string     |
      | boolean    |
      | datetime   |
      | datetimetz |
      | duration   |

  Scenario Outline: Owns cannot set @unique annotation for <value-type> as it is not keyable
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When entity(person) set owns: custom-attribute
    Then entity(person) get owns(custom-attribute) set annotation: @unique; fails
    Then entity(person) get owns(custom-attribute) get annotations is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get annotations is empty
    Examples:
      | value-type    |
      | double        |
      | decimal       |
      | custom-struct |

  # TODO: Change the test if owns can set @unique annotation for ordered ownership!
  Scenario Outline: Owns cannot set @unique annotation for ordered ownership
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When entity(person) set owns: custom-attribute
    When entity(person) get owns(custom-attribute) set ordering: ordered
    Then entity(person) get owns(custom-attribute) set annotation: @unique; fails
    Then entity(person) get owns(custom-attribute) get annotations is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get annotations is empty
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

  Scenario Outline: Ordered owns can set @values annotation for <value-type> value type and unset it
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When create attribute type: custom-attribute-2
    When attribute(custom-attribute-2) set value type: <value-type>
    When entity(person) set owns: custom-attribute
    When entity(person) get owns(custom-attribute) set annotation: @values(<args>)
    Then entity(person) get owns(custom-attribute) get annotations contain: @values(<args>)
    When entity(person) set owns: custom-attribute-2
    When entity(person) get owns(custom-attribute-2) set ordering: ordered
    When entity(person) get owns(custom-attribute-2) set annotation: @values(<args>)
    Then entity(person) get owns(custom-attribute-2) get annotations contain: @values(<args>)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get annotations contain: @values(<args>)
    Then entity(person) get owns(custom-attribute-2) get annotations contain: @values(<args>)
    When entity(person) unset owns: custom-attribute
    When entity(person) unset owns: custom-attribute-2
    Then entity(person) get owns is empty
    When transaction commits
    When connection open read transaction for database: typedb
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

  Scenario: Owns cannot set @values annotation for struct value type
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: custom-struct
    When entity(person) set owns: custom-attribute
    When entity(person) get owns(custom-attribute) set annotation: @values(custom-struct); fails
    When entity(person) get owns(custom-attribute) set annotation: @values({"string"}); fails
    When entity(person) get owns(custom-attribute) set annotation: @values({custom-field: "string"}); fails
    When entity(person) get owns(custom-attribute) set annotation: @values(custom-struct{custom-field: "string"}); fails
    When entity(person) get owns(custom-attribute) set annotation: @values(custom-struct("string")); fails
    When entity(person) get owns(custom-attribute) set annotation: @values(custom-struct(custom-field: "string")); fails

  Scenario Outline: Owns can reset @values annotation with the same argument
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When entity(person) set owns: custom-attribute
    When entity(person) get owns(custom-attribute) set annotation: @values(<args>)
    Then entity(person) get owns(custom-attribute) get annotations contain: @values(<args>)
    When entity(person) get owns(custom-attribute) set annotation: @values(<args>)
    Then entity(person) get owns(custom-attribute) get annotations contain: @values(<args>)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get annotations contain: @values(<args>)
    When entity(person) get owns(custom-attribute) set annotation: @values(<args>)
    Then entity(person) get owns(custom-attribute) get annotations contain: @values(<args>)
    Examples:
      | value-type | args                             |
      | long       | 1, 2                             |
      | double     | 1.0, 2.0                         |
      | decimal    | 1.0, 2.0                         |
      | string     | "str", "str another"             |
      | boolean    | false, true                      |
      | datetime   | 2024-05-06, 2024-05-08           |
      | datetimetz | 2024-05-07+0100, 2024-05-10+0100 |
      | duration   | P1Y, P2Y                         |

    #  TODO: Make it only for typeql
#  Scenario Outline: Owns cannot have @values annotation with empty arguments
#    When create attribute type: custom-attribute
#    When attribute(custom-attribute) set value type: <value-type>
#    When entity(person) set owns: custom-attribute
#    Then entity(person) get owns(custom-attribute) set annotation: @values; fails
#    Then entity(person) get owns(custom-attribute) set annotation: @values(); fails
#    Then entity(person) get owns(custom-attribute) get annotations is empty
#    When transaction commits
#    When connection open read transaction for database: typedb
#    Then entity(person) get owns(custom-attribute) get annotations is empty
#    Examples:
#      | value-type |
#      | long       |
#      | double     |
#      | decimal    |
#      | string     |
#      | boolean    |
#      | datetime   |
#      | datetimetz |
#      | duration   |

  Scenario Outline: Owns cannot have @values annotation for <value-type> value type with arguments of invalid value or type
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When entity(person) set owns: custom-attribute
    Then entity(person) get owns(custom-attribute) set annotation: @values(<args>); fails
    Then entity(person) get owns(custom-attribute) get annotations is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get annotations is empty
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

  Scenario Outline: Owns cannot set multiple @values annotation with different arguments
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When entity(person) set owns: custom-attribute
    Then entity(person) get owns(custom-attribute) set annotation: @values(<args>)
    Then entity(person) get owns(custom-attribute) set annotation: @values(<fail-args>); fails
    Then entity(person) get owns(custom-attribute) get annotations is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get annotations is empty
    Examples:
      | value-type | args            | fail-args       |
      | long       | 1, 5            | 7, 9            |
      | double     | 1.1, 1.5        | -8.0, 88.3      |
      | decimal    | -8.0, 88.3      | 1.1, 1.5        |
      | string     | "s"             | "not s"         |
      | boolean    | true            | false           |
      | datetime   | 2024-05-05      | 2024-06-05      |
      | datetimetz | 2024-05-05+0100 | 2024-05-05+0010 |
      | duration   | P1Y             | P2Y             |

  Scenario Outline: Owns cannot have @values annotation for <value-type> value type with duplicated args
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When entity(person) set owns: custom-attribute
    Then entity(person) get owns(custom-attribute) set annotation: @values(<arg0>, <arg1>, <arg2>); fails
    Then entity(person) get owns(custom-attribute) get annotations is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get annotations is empty
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

  Scenario Outline: Owns-related @values annotation for <value-type> value type can be inherited and overridden by a subset of arguments
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When create attribute type: second-custom-attribute
    When attribute(second-custom-attribute) set value type: <value-type>
    When create attribute type: overridden-custom-attribute
    When attribute(overridden-custom-attribute) set value type: <value-type>
    When attribute(overridden-custom-attribute) set supertype: second-custom-attribute
    When entity(person) set owns: custom-attribute
    When relation(description) set owns: custom-attribute
    When entity(person) set owns: second-custom-attribute
    When relation(description) set owns: second-custom-attribute
    When entity(person) get owns(custom-attribute) set annotation: @values(<args>)
    When relation(description) get owns(custom-attribute) set annotation: @values(<args>)
    Then entity(person) get owns(custom-attribute) get annotations contain: @values(<args>)
    Then relation(description) get owns(custom-attribute) get annotations contain: @values(<args>)
    When entity(person) get owns(second-custom-attribute) set annotation: @values(<args>)
    When relation(description) get owns(second-custom-attribute) set annotation: @values(<args>)
    Then entity(person) get owns(second-custom-attribute) get annotations contain: @values(<args>)
    Then relation(description) get owns(second-custom-attribute) get annotations contain: @values(<args>)
    When create entity type: player
    When create relation type: marriage
    When entity(player) set supertype: person
    When relation(marriage) set supertype: description
    When entity(player) set owns: overridden-custom-attribute
    When relation(marriage) set owns: overridden-custom-attribute
    # TODO: Overrides? Remove second-custom-attribute from test if we remove overrides!
    When entity(player) get owns(overridden-custom-attribute) set override: second-custom-attribute
    When relation(marriage) get owns(overridden-custom-attribute) set override: second-custom-attribute
    Then entity(player) get owns contain: custom-attribute
    Then relation(marriage) get owns contain: custom-attribute
    Then entity(player) get owns(custom-attribute) get annotations contain: @values(<args>)
    Then relation(marriage) get owns(custom-attribute) get annotations contain: @values(<args>)
    Then entity(player) get owns do not contain: second-custom-attribute
    Then relation(marriage) get owns do not contain: second-custom-attribute
    Then entity(player) get owns contain: overridden-custom-attribute
    Then relation(marriage) get owns contain: overridden-custom-attribute
    Then entity(player) get owns(overridden-custom-attribute) get annotations contain: @values(<args>)
    Then relation(marriage) get owns(overridden-custom-attribute) get annotations contain: @values(<args>)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(player) get owns(custom-attribute) get annotations contain: @values(<args>)
    Then relation(marriage) get owns(custom-attribute) get annotations contain: @values(<args>)
    Then entity(player) get owns(overridden-custom-attribute) get annotations contain: @values(<args>)
    Then relation(marriage) get owns(overridden-custom-attribute) get annotations contain: @values(<args>)
    When entity(player) get owns(custom-attribute) set annotation: @values(<args-override>)
    When relation(marriage) get owns(custom-attribute) set annotation: @values(<args-override>)
    Then entity(player) get owns(custom-attribute) get annotations contain: @values(<args-override>)
    Then relation(marriage) get owns(custom-attribute) get annotations contain: @values(<args-override>)
    When entity(player) get owns(overridden-custom-attribute) set annotation: @values(<args-override>)
    When relation(marriage) get owns(overridden-custom-attribute) set annotation: @values(<args-override>)
    Then entity(player) get owns(overridden-custom-attribute) get annotations contain: @values(<args-override>)
    Then relation(marriage) get owns(overridden-custom-attribute) get annotations contain: @values(<args-override>)
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(player) get owns(custom-attribute) get annotations contain: @values(<args-override>)
    Then relation(marriage) get owns(custom-attribute) get annotations contain: @values(<args-override>)
    Then entity(player) get owns(overridden-custom-attribute) get annotations contain: @values(<args-override>)
    Then relation(marriage) get owns(overridden-custom-attribute) get annotations contain: @values(<args-override>)
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

  Scenario Outline: Inherited @values annotation on owns for <value-type> value type cannot be reset or overridden by the @values of not a subset of arguments
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When create attribute type: second-custom-attribute
    When attribute(second-custom-attribute) set value type: <value-type>
    When create attribute type: overridden-custom-attribute
    When attribute(overridden-custom-attribute) set value type: <value-type>
    When attribute(overridden-custom-attribute) set supertype: second-custom-attribute
    When entity(person) set owns: custom-attribute
    When relation(description) set owns: custom-attribute
    When entity(person) set owns: second-custom-attribute
    When relation(description) set owns: second-custom-attribute
    When entity(person) get owns(custom-attribute) set annotation: @values(<args>)
    When relation(description) get owns(custom-attribute) set annotation: @values(<args>)
    Then entity(person) get owns(custom-attribute) get annotations contain: @values(<args>)
    Then relation(description) get owns(custom-attribute) get annotations contain: @values(<args>)
    When entity(person) get owns(second-custom-attribute) set annotation: @values(<args>)
    When relation(description) get owns(second-custom-attribute) set annotation: @values(<args>)
    Then entity(person) get owns(second-custom-attribute) get annotations contain: @values(<args>)
    Then relation(description) get owns(second-custom-attribute) get annotations contain: @values(<args>)
    When create entity type: player
    When create relation type: marriage
    When entity(player) set supertype: person
    When relation(marriage) set supertype: description
    When entity(player) set owns: overridden-custom-attribute
    When relation(marriage) set owns: overridden-custom-attribute
    # TODO: Overrides? Remove second-custom-attribute from test if we remove overrides!
    When entity(player) get owns(overridden-custom-attribute) set override: second-custom-attribute
    When relation(marriage) get owns(overridden-custom-attribute) set override: second-custom-attribute
    Then entity(player) get owns(custom-attribute) get annotations contain: @values(<args>)
    Then relation(marriage) get owns(custom-attribute) get annotations contain: @values(<args>)
    Then entity(player) get owns(overridden-custom-attribute) get annotations contain: @values(<args>)
    Then relation(marriage) get owns(overridden-custom-attribute) get annotations contain: @values(<args>)
    Then entity(player) get owns(custom-attribute) set annotation: @values(<args-override>); fails
    Then relation(marriage) get owns(custom-attribute) set annotation: @values(<args-override>); fails
    Then entity(player) get owns(overridden-custom-attribute) set annotation: @values(<args-override>); fails
    Then relation(marriage) get owns(overridden-custom-attribute) set annotation: @values(<args-override>); fails
    Then entity(player) get owns(custom-attribute) get annotations contain: @values(<args>)
    Then relation(marriage) get owns(custom-attribute) get annotations contain: @values(<args>)
    Then entity(player) get owns(overridden-custom-attribute) get annotations contain: @values(<args>)
    Then relation(marriage) get owns(overridden-custom-attribute) get annotations contain: @values(<args>)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(player) get owns(custom-attribute) get annotations contain: @values(<args>)
    Then relation(marriage) get owns(custom-attribute) get annotations contain: @values(<args>)
    Then entity(player) get owns(overridden-custom-attribute) get annotations contain: @values(<args>)
    Then relation(marriage) get owns(overridden-custom-attribute) get annotations contain: @values(<args>)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(player) get owns(custom-attribute) get annotations contain: @values(<args>)
    Then relation(marriage) get owns(custom-attribute) get annotations contain: @values(<args>)
    Then entity(player) get owns(overridden-custom-attribute) get annotations contain: @values(<args>)
    Then relation(marriage) get owns(overridden-custom-attribute) get annotations contain: @values(<args>)
    When entity(player) get owns(custom-attribute) set annotation: @values(<args>)
    Then transaction commits; fails
    When connection open schema transaction for database: typedb
    When relation(marriage) get owns(custom-attribute) set annotation: @values(<args>)
    Then transaction commits; fails
    When connection open schema transaction for database: typedb
    When entity(player) get owns(overridden-custom-attribute) set annotation: @values(<args>)
    Then transaction commits; fails
    When connection open schema transaction for database: typedb
    When relation(marriage) get owns(overridden-custom-attribute) set annotation: @values(<args>)
    Then transaction commits; fails
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

  Scenario Outline: Ordered owns can set @range annotation for <value-type> value type in correct order and unset it
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When create attribute type: custom-attribute-2
    When attribute(custom-attribute-2) set value type: <value-type>
    When entity(person) set owns: custom-attribute
    Then entity(player) get owns(custom-attribute) set annotation: @range(<arg1>, <arg0>); fails
    Then entity(person) get owns(custom-attribute) get annotations is empty
    When entity(person) get owns(custom-attribute) set annotation: @range(<arg0>, <arg1>)
    Then entity(person) get owns(custom-attribute) get annotations contain: @range(<arg0>, <arg1>)
    When entity(person) set owns: custom-attribute-2
    When entity(person) get owns(custom-attribute-2) set ordering: ordered
    Then entity(player) get owns(custom-attribute-2) set annotation: @range(<arg1>, <arg0>); fails
    Then entity(person) get owns(custom-attribute-2) get annotations is empty
    When entity(person) get owns(custom-attribute-2) set annotation: @range(<arg0>, <arg1>)
    Then entity(person) get owns(custom-attribute-2) get annotations contain: @range(<arg0>, <arg1>)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get annotations contain: @range(<arg0>, <arg1>)
    Then entity(person) get owns(custom-attribute-2) get annotations contain: @range(<arg0>, <arg1>)
    When entity(person) unset owns: custom-attribute
    When entity(person) unset owns: custom-attribute-2
    Then entity(person) get owns is empty
    When transaction commits
    When connection open read transaction for database: typedb
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

  Scenario: Owns cannot set @range annotation for struct value type
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: custom-struct
    When entity(person) set owns: custom-attribute
    When entity(person) get owns(custom-attribute) set annotation: @range(custom-struct, custom-struct); fails
    When entity(person) get owns(custom-attribute) set annotation: @range({"string"}, {"string+1"}); fails
    When entity(person) get owns(custom-attribute) set annotation: @range({custom-field: "string"}, {custom-field: "string+1"}); fails
    When entity(person) get owns(custom-attribute) set annotation: @range(custom-struct{custom-field: "string"}, custom-struct{custom-field: "string+1"}); fails
    When entity(person) get owns(custom-attribute) set annotation: @range(custom-struct("string"), custom-struct("string+1")); fails
    When entity(person) get owns(custom-attribute) set annotation: @range(custom-struct(custom-field: "string"), custom-struct(custom-field: "string+1")); fails

    #  TODO: Make it only for typeql
#  Scenario Outline: Owns cannot have @range annotation for <value-type> value type with less than two args
#    When create attribute type: custom-attribute
#    When attribute(custom-attribute) set value type: <value-type>
#    When entity(person) set owns: custom-attribute
#    Then entity(person) get owns(custom-attribute) set annotation: @range; fails
#    Then entity(person) get owns(custom-attribute) set annotation: @range(); fails
#    Then entity(person) get owns(custom-attribute) set annotation: @range(<arg0>); fails
#    Then entity(person) get owns(custom-attribute) get annotations is empty
#    When transaction commits
#    When connection open read transaction for database: typedb
#    Then entity(person) get owns(custom-attribute) get annotations is empty
#    Examples:
#      | value-type | arg0            |
#      | long       | 1               |
#      | double     | 1.0             |
#      | decimal    | 1.0             |
#      | string     | "1"             |
#      | boolean    | false           |
#      | datetime   | 2024-06-04      |
#      | datetimetz | 2024-06-04+0100 |
#      | duration   | P1Y             |

  Scenario Outline: Owns can reset @range annotation with the same argument
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When entity(person) set owns: custom-attribute
    When entity(person) get owns(custom-attribute) set annotation: @range(<args>)
    Then entity(person) get owns(custom-attribute) get annotations contain: @range(<args>)
    When entity(person) get owns(custom-attribute) set annotation: @range(<args>)
    Then entity(person) get owns(custom-attribute) get annotations contain: @range(<args>)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get annotations contain: @range(<args>)
    When entity(person) get owns(custom-attribute) set annotation: @range(<args>)
    Then entity(person) get owns(custom-attribute) get annotations contain: @range(<args>)
    Examples:
      | value-type | args                             |
      | long       | 1, 2                             |
      | double     | 1.0, 2.0                         |
      | decimal    | 1.0, 2.0                         |
      | string     | "str", "str another"             |
      | boolean    | false, true                      |
      | datetime   | 2024-05-06, 2024-05-08           |
      | datetimetz | 2024-05-07+0100, 2024-05-10+0100 |
      | duration   | P1Y, P2Y                         |

  Scenario Outline: Owns cannot set multiple @range annotation with different arguments
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When entity(person) set owns: custom-attribute
    Then entity(person) get owns(custom-attribute) set annotation: @range(<args>)
    Then entity(person) get owns(custom-attribute) set annotation: @range(<fail-args>); fails
    Then entity(person) get owns(custom-attribute) get annotations is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get annotations is empty
    Examples:
      | value-type | args                             | fail-args                        |
      | long       | 1, 5                             | 7, 9                             |
      | double     | 1.1, 1.5                         | -8.0, 88.3                       |
      | decimal    | -8.0, 88.3                       | 1.1, 1.5                         |
      | string     | "S", "s"                         | "not s", "xxxxxxxxx"             |
      | datetime   | 2024-05-05, 2024-05-06           | 2024-06-05, 2024-06-06           |
      | datetimetz | 2024-05-05+0100, 2024-05-06+0100 | 2024-05-05+0100, 2024-05-07+0100 |
      | duration   | P1Y, P2Y                         | P1Y6M, P2Y                       |

  Scenario Outline: Owns cannot have @range annotation for <value-type> value type with incorrect arguments
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When entity(person) set owns: custom-attribute
    Then entity(person) get owns(custom-attribute) set annotation: @range(<arg0>, <args>); fails
    Then entity(person) get owns(custom-attribute) get annotations is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get annotations is empty
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

  Scenario Outline: Owns-related @range annotation for <value-type> value type can be inherited and overridden by a subset of arguments
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When create attribute type: second-custom-attribute
    When attribute(second-custom-attribute) set value type: <value-type>
    When create attribute type: overridden-custom-attribute
    When attribute(overridden-custom-attribute) set value type: <value-type>
    When attribute(overridden-custom-attribute) set supertype: second-custom-attribute
    When entity(person) set owns: custom-attribute
    When relation(description) set owns: custom-attribute
    When entity(person) set owns: second-custom-attribute
    When relation(description) set owns: second-custom-attribute
    When entity(person) get owns(custom-attribute) set annotation: @range(<args>)
    When relation(description) get owns(custom-attribute) set annotation: @range(<args>)
    Then entity(person) get owns(custom-attribute) get annotations contain: @range(<args>)
    Then relation(description) get owns(custom-attribute) get annotations contain: @range(<args>)
    When entity(person) get owns(second-custom-attribute) set annotation: @range(<args>)
    When relation(description) get owns(second-custom-attribute) set annotation: @range(<args>)
    Then entity(person) get owns(second-custom-attribute) get annotations contain: @range(<args>)
    Then relation(description) get owns(second-custom-attribute) get annotations contain: @range(<args>)
    When create entity type: player
    When create relation type: marriage
    When entity(player) set supertype: person
    When relation(marriage) set supertype: description
    When entity(player) set owns: overridden-custom-attribute
    When relation(marriage) set owns: overridden-custom-attribute
    # TODO: Overrides? Remove second-custom-attribute from test if we remove overrides!
    When entity(player) get owns(overridden-custom-attribute) set override: second-custom-attribute
    When relation(marriage) get owns(overridden-custom-attribute) set override: second-custom-attribute
    Then entity(player) get owns contain: custom-attribute
    Then relation(marriage) get owns contain: custom-attribute
    Then entity(player) get owns(custom-attribute) get annotations contain: @range(<args>)
    Then relation(marriage) get owns(custom-attribute) get annotations contain: @range(<args>)
    Then entity(player) get owns do not contain: second-custom-attribute
    Then relation(marriage) get owns do not contain: second-custom-attribute
    Then entity(player) get owns contain: overridden-custom-attribute
    Then relation(marriage) get owns contain: overridden-custom-attribute
    Then entity(player) get owns(overridden-custom-attribute) get annotations contain: @range(<args>)
    Then relation(marriage) get owns(overridden-custom-attribute) get annotations contain: @range(<args>)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(player) get owns(custom-attribute) get annotations contain: @range(<args>)
    Then relation(marriage) get owns(custom-attribute) get annotations contain: @range(<args>)
    Then entity(player) get owns(overridden-custom-attribute) get annotations contain: @range(<args>)
    Then relation(marriage) get owns(overridden-custom-attribute) get annotations contain: @range(<args>)
    When entity(player) get owns(custom-attribute) set annotation: @range(<args-override>)
    When relation(marriage) get owns(custom-attribute) set annotation: @range(<args-override>)
    Then entity(player) get owns(custom-attribute) get annotations contain: @range(<args-override>)
    Then relation(marriage) get owns(custom-attribute) get annotations contain: @range(<args-override>)
    When entity(player) get owns(overridden-custom-attribute) set annotation: @range(<args-override>)
    When relation(marriage) get owns(overridden-custom-attribute) set annotation: @range(<args-override>)
    Then entity(player) get owns(overridden-custom-attribute) get annotations contain: @range(<args-override>)
    Then relation(marriage) get owns(overridden-custom-attribute) get annotations contain: @range(<args-override>)
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(player) get owns(custom-attribute) get annotations contain: @range(<args-override>)
    Then relation(marriage) get owns(custom-attribute) get annotations contain: @range(<args-override>)
    Then entity(player) get owns(overridden-custom-attribute) get annotations contain: @range(<args-override>)
    Then relation(marriage) get owns(overridden-custom-attribute) get annotations contain: @range(<args-override>)
    Examples:
      | value-type | args                             | args-override                             |
      | long       | 1, 10                            | 1, 5                                      |
      | double     | 1.0, 10.0                        | 2.0, 10.0                                 |
      | decimal    | 0.0, 1.0                         | 0.0, 0.999999                             |
      | string     | "A", "Z"                         | "J", "Z"                                  |
      | datetime   | 2024-06-04, 2024-06-05           | 2024-06-04, 2024-06-04T12:00:00           |
      | datetimetz | 2024-06-04+0010, 2024-06-05+0010 | 2024-06-04+0010, 2024-06-04T12:00:00+0010 |
      | duration   | P6M, P1Y                         | P8M, P9M                                  |

  Scenario Outline: Inherited @range annotation on owns for <value-type> value type cannot be reset or overridden by the @range of not a subset of arguments
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When create attribute type: second-custom-attribute
    When attribute(second-custom-attribute) set value type: <value-type>
    When create attribute type: overridden-custom-attribute
    When attribute(overridden-custom-attribute) set value type: <value-type>
    When attribute(overridden-custom-attribute) set supertype: second-custom-attribute
    When entity(person) set owns: custom-attribute
    When relation(description) set owns: custom-attribute
    When entity(person) set owns: second-custom-attribute
    When relation(description) set owns: second-custom-attribute
    When entity(person) get owns(custom-attribute) set annotation: @range(<args>)
    When relation(description) get owns(custom-attribute) set annotation: @range(<args>)
    Then entity(person) get owns(custom-attribute) get annotations contain: @range(<args>)
    Then relation(description) get owns(custom-attribute) get annotations contain: @range(<args>)
    When entity(person) get owns(second-custom-attribute) set annotation: @range(<args>)
    When relation(description) get owns(second-custom-attribute) set annotation: @range(<args>)
    Then entity(person) get owns(second-custom-attribute) get annotations contain: @range(<args>)
    Then relation(description) get owns(second-custom-attribute) get annotations contain: @range(<args>)
    When create entity type: player
    When create relation type: marriage
    When entity(player) set supertype: person
    When relation(marriage) set supertype: description
    When entity(player) set owns: overridden-custom-attribute
    When relation(marriage) set owns: overridden-custom-attribute
    # TODO: Overrides? Remove second-custom-attribute from test if we remove overrides!
    When entity(player) get owns(overridden-custom-attribute) set override: second-custom-attribute
    When relation(marriage) get owns(overridden-custom-attribute) set override: second-custom-attribute
    Then entity(player) get owns(custom-attribute) get annotations contain: @range(<args>)
    Then relation(marriage) get owns(custom-attribute) get annotations contain: @range(<args>)
    Then entity(player) get owns(overridden-custom-attribute) get annotations contain: @range(<args>)
    Then relation(marriage) get owns(overridden-custom-attribute) get annotations contain: @range(<args>)
    Then entity(player) get owns(custom-attribute) set annotation: @range(<args-override>); fails
    Then relation(marriage) get owns(custom-attribute) set annotation: @range(<args-override>); fails
    Then entity(player) get owns(overridden-custom-attribute) set annotation: @range(<args-override>); fails
    Then relation(marriage) get owns(overridden-custom-attribute) set annotation: @range(<args-override>); fails
    Then entity(player) get owns(custom-attribute) get annotations contain: @range(<args>)
    Then relation(marriage) get owns(custom-attribute) get annotations contain: @range(<args>)
    Then entity(player) get owns(overridden-custom-attribute) get annotations contain: @range(<args>)
    Then relation(marriage) get owns(overridden-custom-attribute) get annotations contain: @range(<args>)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(player) get owns(custom-attribute) get annotations contain: @range(<args>)
    Then relation(marriage) get owns(custom-attribute) get annotations contain: @range(<args>)
    Then entity(player) get owns(overridden-custom-attribute) get annotations contain: @range(<args>)
    Then relation(marriage) get owns(overridden-custom-attribute) get annotations contain: @range(<args>)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(player) get owns(custom-attribute) get annotations contain: @range(<args>)
    Then relation(marriage) get owns(custom-attribute) get annotations contain: @range(<args>)
    Then entity(player) get owns(overridden-custom-attribute) get annotations contain: @range(<args>)
    Then relation(marriage) get owns(overridden-custom-attribute) get annotations contain: @range(<args>)
    When entity(player) get owns(custom-attribute) set annotation: @range(<args>)
    Then transaction commits; fails
    When connection open schema transaction for database: typedb
    When relation(marriage) get owns(custom-attribute) set annotation: @range(<args>)
    Then transaction commits; fails
    When connection open schema transaction for database: typedb
    When entity(player) get owns(overridden-custom-attribute) set annotation: @range(<args>)
    Then transaction commits; fails
    When connection open schema transaction for database: typedb
    When relation(marriage) get owns(overridden-custom-attribute) set annotation: @range(<args>)
    Then transaction commits; fails
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

  Scenario Outline: Owns can set @card annotation for <value-type> value type with arguments in correct order and unset it
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When create attribute type: custom-attribute-2
    When attribute(custom-attribute-2) set value type: <value-type>
    When entity(person) set owns: custom-attribute
    Then entity(customer) get owns(custom-attribute) set annotation: @card(<arg1>, <arg0>); fails
    Then entity(person) get owns(custom-attribute) get annotations is empty
    When entity(person) get owns(custom-attribute) set annotation: @card(<arg0>, <arg1>)
    Then entity(person) get owns(custom-attribute) get annotations contain: @card(<arg0>, <arg1>)
    When entity(person) set owns: custom-attribute-2
    When entity(person) get owns(custom-attribute-2) set ordering: ordered
    Then entity(customer) get owns(custom-attribute-2) set annotation: @card(<arg1>, <arg0>); fails
    Then entity(person) get owns(custom-attribute-2) get annotations is empty
    When entity(person) get owns(custom-attribute-2) set annotation: @card(<arg0>, <arg1>)
    Then entity(person) get owns(custom-attribute-2) get annotations contain: @card(<arg0>, <arg1>)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get annotations contain: @card(<arg0>, <arg1>)
    Then entity(person) get owns(custom-attribute-2) get annotations contain: @card(<arg0>, <arg1>)
    When entity(person) unset owns: custom-attribute
    When entity(person) unset owns: custom-attribute-2
    Then entity(person) get owns is empty
    When transaction commits
    When connection open read transaction for database: typedb
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
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When entity(person) set owns: custom-attribute
    Then entity(person) get owns(custom-attribute) get annotations is empty
    When entity(person) get owns(custom-attribute) set annotation: @card(<arg>, <arg>)
    Then entity(person) get owns(custom-attribute) get annotations contain: @card(<arg>, <arg>)
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get annotations contain: @card(<arg>, <arg>)
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

  Scenario Outline: Owns cannot have @card annotation for <value-type> value type with invalid arguments
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When entity(person) set owns: custom-attribute
    #  TODO: Make it only for typeql
#    Then entity(person) get owns(custom-attribute) set annotation: @card; fails
#    Then entity(person) get owns(custom-attribute) set annotation: @card(); fails
#    Then entity(person) get owns(custom-attribute) set annotation: @card(1); fails
#    Then entity(person) get owns(custom-attribute) set annotation: @card(*); fails
#    Then entity(person) get owns(custom-attribute) set annotation: @card(1, 2, 3); fails
    Then entity(person) get owns(custom-attribute) set annotation: @card(-1, 1); fails
    Then entity(person) get owns(custom-attribute) set annotation: @card(0, 0.1); fails
    Then entity(person) get owns(custom-attribute) set annotation: @card(0, 1.5); fails
    Then entity(person) get owns(custom-attribute) set annotation: @card(*, *); fails
    Then entity(person) get owns(custom-attribute) set annotation: @card(0, **); fails
    Then entity(person) get owns(custom-attribute) set annotation: @card(1, "2"); fails
    Then entity(person) get owns(custom-attribute) set annotation: @card("1", 2); fails
    Then entity(person) get owns(custom-attribute) set annotation: @card(2, 1); fails
    Then entity(person) get owns(custom-attribute) get annotations is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get annotations is empty
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

  Scenario Outline: Owns can reset @card annotation with the same argument
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When entity(person) set owns: custom-attribute
    When entity(person) get owns(custom-attribute) set annotation: @card(<args>)
    Then entity(person) get owns(custom-attribute) get annotations contain: @card(<args>)
    When entity(person) get owns(custom-attribute) set annotation: @card(<args>)
    Then entity(person) get owns(custom-attribute) get annotations contain: @card(<args>)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get annotations contain: @card(<args>)
    When entity(person) get owns(custom-attribute) set annotation: @card(<args>)
    Then entity(person) get owns(custom-attribute) get annotations contain: @card(<args>)
    Examples:
      | value-type | args |
      | long       | 1, 2 |
      | double     | 1, 3 |
      | decimal    | 1, 4 |
      | string     | 1, 5 |
      | boolean    | 1, 6 |
      | datetime   | 1, 7 |
      | datetimetz | 1, 8 |
      | duration   | 0, 9 |

  Scenario Outline: Owns cannot set multiple @card annotations with different arguments
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: decimal
    When entity(person) set owns: custom-attribute
    When entity(person) get owns(custom-attribute) set annotation: @card(2, 5)
    Then entity(person) get owns(custom-attribute) set annotation: @card(<fail-args>); fails
    Then entity(person) get owns(custom-attribute) get annotations contain: @card(2, 5)
    Then entity(person) get owns(custom-attribute) get annotations do not contain: @card(<fail-args>)
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get annotations contain: @card(2, 5)
    Then entity(person) get owns(custom-attribute) get annotations do not contain: @card(<fail-args>)
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

  Scenario Outline: Owns cannot redeclare @card annotation with different arguments
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When entity(person) set owns: custom-attribute
    Then entity(person) get owns(custom-attribute) set annotation: @card(<args>)
    Then entity(person) get owns(custom-attribute) set annotation: @card(<fail-args>); fails
    Then entity(person) get owns(custom-attribute) get annotations is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get annotations is empty
    Examples:
      | value-type | args | fail-args |
      | long       | 2, 5 | 7, 9      |
      | double     | 2, 5 | 0, 1      |
      | decimal    | 2, 5 | 0, *      |
      | string     | 2, 5 | 4, *      |
      | boolean    | 2, 5 | 4, 5      |
      | datetime   | 2, 5 | 2, 6      |
      | datetimetz | 2, 5 | 2, 4      |
      | duration   | 2, 5 | 2, *      |

  Scenario Outline: Owns-related @card annotation for <value-type> value type can be inherited and overridden by a subset of arguments
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When create attribute type: second-custom-attribute
    When attribute(second-custom-attribute) set value type: <value-type>
    When create attribute type: overridden-custom-attribute
    When attribute(overridden-custom-attribute) set value type: <value-type>
    When attribute(overridden-custom-attribute) set supertype: second-custom-attribute
    When entity(person) set owns: custom-attribute
    When relation(description) set owns: custom-attribute
    When entity(person) set owns: second-custom-attribute
    When relation(description) set owns: second-custom-attribute
    When entity(person) get owns(custom-attribute) set annotation: @card(<args>)
    When relation(description) get owns(custom-attribute) set annotation: @card(<args>)
    Then entity(person) get owns(custom-attribute) get annotations contain: @card(<args>)
    Then relation(description) get owns(custom-attribute) get annotations contain: @card(<args>)
    When entity(person) get owns(second-custom-attribute) set annotation: @card(<args>)
    When relation(description) get owns(second-custom-attribute) set annotation: @card(<args>)
    Then entity(person) get owns(second-custom-attribute) get annotations contain: @card(<args>)
    Then relation(description) get owns(second-custom-attribute) get annotations contain: @card(<args>)
    When create entity type: player
    When create relation type: marriage
    When entity(player) set supertype: person
    When relation(marriage) set supertype: description
    When entity(player) set owns: overridden-custom-attribute
    When relation(marriage) set owns: overridden-custom-attribute
    # TODO: Overrides? Remove second-custom-attribute from test if we remove overrides!
    When entity(player) get owns(overridden-custom-attribute) set override: second-custom-attribute
    When relation(marriage) get owns(overridden-custom-attribute) set override: second-custom-attribute
    Then entity(player) get owns contain: custom-attribute
    Then relation(marriage) get owns contain: custom-attribute
    Then entity(player) get owns(custom-attribute) get annotations contain: @card(<args>)
    Then relation(marriage) get owns(custom-attribute) get annotations contain: @card(<args>)
    Then entity(player) get owns do not contain: second-custom-attribute
    Then relation(marriage) get owns do not contain: second-custom-attribute
    Then entity(player) get owns contain: overridden-custom-attribute
    Then relation(marriage) get owns contain: overridden-custom-attribute
    Then entity(player) get owns(overridden-custom-attribute) get annotations contain: @card(<args>)
    Then relation(marriage) get owns(overridden-custom-attribute) get annotations contain: @card(<args>)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(player) get owns(custom-attribute) get annotations contain: @card(<args>)
    Then relation(marriage) get owns(custom-attribute) get annotations contain: @card(<args>)
    Then entity(player) get owns(overridden-custom-attribute) get annotations contain: @card(<args>)
    Then relation(marriage) get owns(overridden-custom-attribute) get annotations contain: @card(<args>)
    When entity(player) get owns(custom-attribute) set annotation: @card(<args-override>)
    When relation(marriage) get owns(custom-attribute) set annotation: @card(<args-override>)
    Then entity(player) get owns(custom-attribute) get annotations contain: @card(<args-override>)
    Then relation(marriage) get owns(custom-attribute) get annotations contain: @card(<args-override>)
    When entity(player) get owns(overridden-custom-attribute) set annotation: @card(<args-override>)
    When relation(marriage) get owns(overridden-custom-attribute) set annotation: @card(<args-override>)
    Then entity(player) get owns(overridden-custom-attribute) get annotations contain: @card(<args-override>)
    Then relation(marriage) get owns(overridden-custom-attribute) get annotations contain: @card(<args-override>)
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(player) get owns(custom-attribute) get annotations contain: @card(<args-override>)
    Then relation(marriage) get owns(custom-attribute) get annotations contain: @card(<args-override>)
    Then entity(player) get owns(overridden-custom-attribute) get annotations contain: @card(<args-override>)
    Then relation(marriage) get owns(overridden-custom-attribute) get annotations contain: @card(<args-override>)
    Examples:
      | value-type | args       | args-override |
      | long       | 0, *       | 0, 10000      |
      | double     | 0, 10      | 0, 1          |
      | decimal    | 0, 2       | 1, 2          |
      | string     | 1, *       | 1, 1          |
      | datetime   | 1, 5       | 3, 4          |
      | datetimetz | 38, 111    | 39, 111       |
      | duration   | 1000, 1100 | 1000, 1099    |

  Scenario Outline: Inherited @card annotation on owns for <value-type> value type cannot be reset or overridden by the @card of not a subset of arguments
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When create attribute type: second-custom-attribute
    When attribute(second-custom-attribute) set value type: <value-type>
    When create attribute type: overridden-custom-attribute
    When attribute(overridden-custom-attribute) set value type: <value-type>
    When attribute(overridden-custom-attribute) set supertype: second-custom-attribute
    When entity(person) set owns: custom-attribute
    When relation(description) set owns: custom-attribute
    When entity(person) set owns: second-custom-attribute
    When relation(description) set owns: second-custom-attribute
    When entity(person) get owns(custom-attribute) set annotation: @card(<args>)
    When relation(description) get owns(custom-attribute) set annotation: @card(<args>)
    Then entity(person) get owns(custom-attribute) get annotations contain: @card(<args>)
    Then relation(description) get owns(custom-attribute) get annotations contain: @card(<args>)
    When entity(person) get owns(second-custom-attribute) set annotation: @card(<args>)
    When relation(description) get owns(second-custom-attribute) set annotation: @card(<args>)
    Then entity(person) get owns(second-custom-attribute) get annotations contain: @card(<args>)
    Then relation(description) get owns(second-custom-attribute) get annotations contain: @card(<args>)
    When create entity type: player
    When create relation type: marriage
    When entity(player) set supertype: person
    When relation(marriage) set supertype: description
    When entity(player) set owns: overridden-custom-attribute
    When relation(marriage) set owns: overridden-custom-attribute
    # TODO: Overrides? Remove second-custom-attribute from test if we remove overrides!
    When entity(player) get owns(overridden-custom-attribute) set override: second-custom-attribute
    When relation(marriage) get owns(overridden-custom-attribute) set override: second-custom-attribute
    Then entity(player) get owns(custom-attribute) get annotations contain: @card(<args>)
    Then relation(marriage) get owns(custom-attribute) get annotations contain: @card(<args>)
    Then entity(player) get owns(overridden-custom-attribute) get annotations contain: @card(<args>)
    Then relation(marriage) get owns(overridden-custom-attribute) get annotations contain: @card(<args>)
    Then entity(player) get owns(custom-attribute) set annotation: @card(<args>); fails
    Then relation(marriage) get owns(custom-attribute) set annotation: @card(<args>); fails
    Then entity(player) get owns(overridden-custom-attribute) set annotation: @card(<args>); fails
    Then relation(marriage) get owns(overridden-custom-attribute) set annotation: @card(<args>); fails
    Then entity(player) get owns(custom-attribute) set annotation: @card(<args-override>); fails
    Then relation(marriage) get owns(custom-attribute) set annotation: @card(<args-override>); fails
    Then entity(player) get owns(overridden-custom-attribute) set annotation: @card(<args-override>); fails
    Then relation(marriage) get owns(overridden-custom-attribute) set annotation: @card(<args-override>); fails
    Then entity(player) get owns(custom-attribute) get annotations contain: @card(<args>)
    Then relation(marriage) get owns(custom-attribute) get annotations contain: @card(<args>)
    Then entity(player) get owns(overridden-custom-attribute) get annotations contain: @card(<args>)
    Then relation(marriage) get owns(overridden-custom-attribute) get annotations contain: @card(<args>)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(player) get owns(custom-attribute) get annotations contain: @card(<args>)
    Then relation(marriage) get owns(custom-attribute) get annotations contain: @card(<args>)
    Then entity(player) get owns(overridden-custom-attribute) get annotations contain: @card(<args>)
    Then relation(marriage) get owns(overridden-custom-attribute) get annotations contain: @card(<args>)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(player) get owns(custom-attribute) get annotations contain: @card(<args>)
    Then relation(marriage) get owns(custom-attribute) get annotations contain: @card(<args>)
    Then entity(player) get owns(overridden-custom-attribute) get annotations contain: @card(<args>)
    Then relation(marriage) get owns(overridden-custom-attribute) get annotations contain: @card(<args>)
    When entity(player) get owns(custom-attribute) set annotation: @card(<args>)
    Then transaction commits; fails
    When connection open schema transaction for database: typedb
    When relation(marriage) get owns(custom-attribute) set annotation: @card(<args>)
    Then transaction commits; fails
    When connection open schema transaction for database: typedb
    When entity(player) get owns(overridden-custom-attribute) set annotation: @card(<args>)
    Then transaction commits; fails
    When connection open schema transaction for database: typedb
    When relation(marriage) get owns(overridden-custom-attribute) set annotation: @card(<args>)
    Then transaction commits; fails
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

  Scenario Outline: Ordered owns for <root-type> can set @distinct annotation for <value-type> value type and unset it
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When <root-type>(<type-name>) set owns: custom-attribute
    When <root-type>(<type-name>) get owns(custom-attribute) set ordering: ordered
    When <root-type>(<type-name>) get owns(custom-attribute) set annotation: @distinct
    Then <root-type>(<type-name>) get owns(custom-attribute) get annotations contain: @distinct
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<type-name>) get owns(custom-attribute) get annotations contain: @distinct
    When <root-type>(<type-name>) get owns(custom-attribute) unset annotation: @distinct
    Then <root-type>(<type-name>) get owns(custom-attribute) get annotations is empty
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<type-name>) get owns(custom-attribute) get annotations is empty
    When <root-type>(<type-name>) get owns(custom-attribute) set annotation: @distinct
    Then <root-type>(<type-name>) get owns(custom-attribute) get annotations contain: @distinct
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<type-name>) get owns(custom-attribute) get annotations contain: @distinct
    When <root-type>(<type-name>) unset owns: custom-attribute
    Then <root-type>(<type-name>) get owns is empty
    When transaction commits
    When connection open read transaction for database: typedb
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

  Scenario Outline: Unordered ownership for <root-type> cannot have @distinct annotation for <value-type> value type
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When <root-type>(<type-name>) set owns: custom-attribute
    Then <root-type>(<type-name>) get owns(custom-attribute) set annotation: @distinct; fails
    Then <root-type>(<type-name>) get owns(custom-attribute) get annotations is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then <root-type>(<type-name>) get owns(custom-attribute) get annotations is empty
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

    #  TODO: Make it only for typeql
#  Scenario Outline: Owns cannot have @distinct annotation for <value-type> with arguments
#    When create attribute type: custom-attribute
#    When attribute(custom-attribute) set value type: <value-type>
#    When entity(person) set owns: custom-attribute
#    When entity(person) get owns(custom-attribute) set ordering: ordered
#    Then entity(person) get owns(custom-attribute) set annotation: @distinct(); fails
#    Then entity(person) get owns(custom-attribute) set annotation: @distinct(1); fails
#    Then entity(person) get owns(custom-attribute) set annotation: @distinct("1"); fails
#    Then entity(person) get owns(custom-attribute) get annotations is empty
#    When transaction commits
#    When connection open read transaction for database: typedb
#    Then entity(person) get owns(custom-attribute) get annotations is empty
#    Examples:
#      | value-type    |
#      | long          |
#      | string        |
#      | boolean       |
#      | double        |
#      | decimal       |
#      | datetime      |
#      | datetimetz    |
#      | duration      |
#      | custom-struct |

  Scenario Outline: Owns can reset @distinct annotations
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When entity(person) set owns: custom-attribute
    When entity(person) get owns(custom-attribute) set ordering: ordered
    When entity(person) get owns(custom-attribute) set annotation: @distinct
    Then entity(person) get owns(custom-attribute) get annotations contain: @distinct
    When entity(person) get owns(custom-attribute) set annotation: @distinct
    Then entity(person) get owns(custom-attribute) get annotations contain: @distinct
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get annotations contain: @distinct
    When entity(person) get owns(custom-attribute) set annotation: @distinct
    Then entity(person) get owns(custom-attribute) get annotations contain: @distinct
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
    When create attribute type: name
    When attribute(name) set value type: <value-type>
    When create attribute type: email
    When attribute(email) set value type: <value-type>
    When create attribute type: address
    When attribute(address) set value type: <value-type>
    When <root-type>(<type-name>) set owns: name
    When <root-type>(<type-name>) get owns(name) set ordering: ordered
    When <root-type>(<type-name>) set owns: email
    When <root-type>(<type-name>) get owns(email) set ordering: ordered
    When <root-type>(<type-name>) set owns: address
    When <root-type>(<type-name>) get owns(address) set ordering: ordered
    When <root-type>(<type-name>) set owns: name
    Then <root-type>(<type-name>) get owns(name) get ordering: unordered
    Then <root-type>(<type-name>) get owns(name) get annotations is empty
    When <root-type>(<type-name>) get owns(name) set ordering: ordered
    When <root-type>(<type-name>) get owns(name) set annotation: @distinct
    Then <root-type>(<type-name>) get owns(name) get ordering: unordered
    Then <root-type>(<type-name>) get owns(name) get annotations contain: @distinct
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<type-name>) set owns: email
    Then <root-type>(<type-name>) get owns(email) get ordering: unordered
    Then <root-type>(<type-name>) get owns(email) get annotations is empty
    Then <root-type>(<type-name>) get owns(email) set annotation: @distinct; fails
    When <root-type>(<type-name>) get owns(email) set ordering: ordered
    When <root-type>(<type-name>) get owns(email) set annotation: @distinct
    Then <root-type>(<type-name>) get owns(email) get annotations contain: @distinct
    Then <root-type>(<type-name>) get owns(address) get annotations is empty
    When <root-type>(<type-name>) get owns(address) set annotation: @distinct
    Then <root-type>(<type-name>) get owns(address) get annotations contain: @distinct
    Examples:
      | root-type | type-name   | value-type |
      | entity    | person      | string     |
      | entity    | person      | long       |
      | relation  | description | datetime   |
      | relation  | description | duration   |

  Scenario Outline: <root-type> types cannot unset not set @distinct of ownership of <value-type> value type
    When create attribute type: username
    When attribute(username) set value type: <value-type>
    When create attribute type: reference
    When attribute(reference) set value type: <value-type>
    When <root-type>(<type-name>) set owns: username
    When <root-type>(<type-name>) get owns(username) set ordering: ordered
    When <root-type>(<type-name>) get owns(username) set annotation: @distinct
    Then <root-type>(<type-name>) get owns(username) get annotation contain: @distinct
    When <root-type>(<type-name>) set owns: reference
    When <root-type>(<type-name>) get owns(reference) set ordering: ordered
    Then <root-type>(<type-name>) get owns(reference) unset annotation: @distinct; fails
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<type-name>) get owns(username) get annotation contain: @distinct
    Then <root-type>(<type-name>) get owns(reference) unset annotation: @distinct; fails
    Then <root-type>(<type-name>) get owns(username) unset annotation: @distinct
    Then <root-type>(<type-name>) get owns(username) unset annotation: @distinct; fails
    Then <root-type>(<type-name>) get owns(username) get annotations is empty
    Then <root-type>(<type-name>) get owns(reference) get annotations is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then <root-type>(<type-name>) get owns(username) get annotations is empty
    Then <root-type>(<type-name>) get owns(reference) get annotations is empty
    Examples:
      | root-type | type-name   | value-type |
      | entity    | person      | string     |
      | entity    | person      | long       |
      | relation  | description | datetime   |
      | relation  | description | duration   |

  Scenario Outline: <root-type> types cannot unset @distinct of inherited ownership
    When create attribute type: username
    When attribute(username) set value type: string
    When <root-type>(<supertype-name>) set owns: username
    When <root-type>(<supertype-name>) get owns(username) set annotation: @distinct
    Then <root-type>(<supertype-name>) get owns(username) get annotation contain: @distinct
    Then <root-type>(<subtype-name>) get owns(username) get annotation contain: @distinct
    Then <root-type>(<subtype-name>) get owns(username) unset annotation: @distinct; fails
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<subtype-name>) get owns(username) get annotations contain: @distinct
    Then <root-type>(<subtype-name>) get owns(username) unset annotation: @distinct; fails
    Examples:
      | root-type | supertype-name | subtype-name |
      | entity    | person         | customer     |
      | relation  | description    | registration |

########################
# @regex
########################

  Scenario Outline: Owns can set @regex annotation for <value-type> value type and unset it
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When create attribute type: custom-attribute-2
    When attribute(custom-attribute-2) set value type: <value-type>
    When entity(person) set owns: custom-attribute
    When entity(person) get owns(custom-attribute) set annotation: @regex(<arg>)
    Then entity(person) get owns(custom-attribute) get annotations contain: @regex(<arg>)
    When entity(person) set owns: custom-attribute-2
    When entity(person) get owns(custom-attribute-2) set ordering: ordered
    When entity(person) get owns(custom-attribute-2) set annotation: @regex(<arg>)
    Then entity(person) get owns(custom-attribute-2) get annotations contain: @regex(<arg>)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get annotations contain: @regex(<arg>)
    When entity(person) get owns(custom-attribute) unset annotation: @regex(<arg>)
    Then entity(person) get owns(custom-attribute) get annotations is empty
    Then entity(person) get owns(custom-attribute-2) get annotations contain: @regex(<arg>)
    When entity(person) get owns(custom-attribute-2) unset annotation: @regex(<arg>)
    Then entity(person) get owns(custom-attribute-2) get annotations is empty
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get annotations is empty
    When entity(person) get owns(custom-attribute) set annotation: @regex(<arg>)
    Then entity(person) get owns(custom-attribute) get annotations contain: @regex(<arg>)
    Then entity(person) get owns(custom-attribute-2) get annotations is empty
    When entity(person) get owns(custom-attribute-2) set annotation: @regex(<arg>)
    Then entity(person) get owns(custom-attribute-2) get annotations contain: @regex(<arg>)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get annotations contain: @regex(<arg>)
    Then entity(person) get owns(custom-attribute-2) get annotations contain: @regex(<arg>)
    When entity(person) unset owns: custom-attribute
    When entity(person) unset owns: custom-attribute-2
    Then entity(person) get owns is empty
    When transaction commits
    When connection open read transaction for database: typedb
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
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When entity(person) set owns: custom-attribute
    Then entity(person) get owns(custom-attribute) set annotation: @regex("\S+"); fails
    Then entity(person) get owns(custom-attribute) get annotations is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get annotations is empty
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

  Scenario Outline: Owns cannot have @regex annotation of invalid arguments
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: string
    When entity(person) set owns: custom-attribute
    #  TODO: Make it only for typeql
#    Then entity(person) get owns(custom-attribute) set annotation: @regex; fails
#    Then entity(person) get owns(custom-attribute) set annotation: @regex(); fails
    Then entity(person) get owns(custom-attribute) set annotation: @regex(<args>); fails
    Then entity(person) get owns(custom-attribute) get annotations is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get annotations is empty
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

  Scenario Outline: Owns can reset @regex annotation of the same argument
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When entity(person) set owns: custom-attribute
    When entity(person) get owns(custom-attribute) set ordering: ordered
    When entity(person) get owns(custom-attribute) set annotation: @regex(<args>)
    Then entity(person) get owns(custom-attribute) get annotations contain: @regex(<args>)
    When entity(person) get owns(custom-attribute) set annotation: @regex(<args>)
    Then entity(person) get owns(custom-attribute) get annotations contain: @regex(<args>)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get annotations contain: @regex(<args>)
    When entity(person) get owns(custom-attribute) set annotation: @regex(<args>)
    Then entity(person) get owns(custom-attribute) get annotations contain: @regex(<args>)
    Examples:
      | value-type    | args  |
      | long          | "\S+" |
      | string        | "\S+" |
      | boolean       | "\S+" |
      | double        | "\S+" |
      | decimal       | "\S+" |
      | datetime      | "\S+" |
      | datetimetz    | "\S+" |
      | duration      | "\S+" |
      | custom-struct | "\S+" |

  Scenario Outline: Owns cannot set multiple @regex annotations with different arguments
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: string
    When entity(person) set owns: custom-attribute
    When entity(person) get owns(custom-attribute) set annotation: @regex("\S+")
    Then entity(person) get owns(custom-attribute) set annotation: @regex(<fail-args>); fails
    Then entity(person) get owns(custom-attribute) get annotations contain: @regex("\S+")
    Then entity(person) get owns(custom-attribute) get annotations do not contain: @regex(<fail-args>)
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get annotations contain: @regex("\S+")
    Then entity(person) get owns(custom-attribute) get annotations do not contain: @regex(<fail-args>)
    Examples:
      | fail-args       |
      | "\S"            |
      | "S+"            |
      | "*"             |
      | "s"             |
      | " some string " |

  Scenario: Owns cannot set @regex annotation if there is a @regex annotation on the attribute
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: string
    When attribute(custom-attribute) set annotation: @regex("\S+")
    When entity(person) set owns: custom-attribute
    When entity(person) get owns(custom-attribute) set annotation: @regex("\S+"); fails
    Then entity(person) get owns(custom-attribute) set annotation: @regex("s"); fails
    Then entity(person) get owns(custom-attribute) get annotations is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get annotations is empty

  Scenario: Owns cannot override inherited @regex annotation
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: string
    When entity(person) set owns: custom-attribute
    When entity(person) get owns(custom-attribute) set annotation: @regex("\S+")
    Then entity(person) get owns(custom-attribute) get annotations contain: @regex("\S+")
    Then entity(customer) get owns(custom-attribute) get annotations contain: @regex("\S+")
    When create attribute type: custom-attribute-2
    When attribute(custom-attribute-2) set value type: string
    When entity(customer) set owns: custom-attribute-2
    Then entity(customer) get owns(custom-attribute-2) get annotations is empty
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get annotations contain: @regex("\S+")
    Then entity(customer) get owns(custom-attribute) get annotations contain: @regex("\S+")
    Then entity(customer) get owns(custom-attribute-2) get annotations is empty
    When entity(customer) get owns(custom-attribute-2) set override: custom-attribute
    Then entity(customer) get owns(custom-attribute-2) set annotation: @regex("test"); fails
    When connection open schema transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get annotations contain: @regex("\S+")
    Then entity(customer) get owns(custom-attribute) get annotations contain: @regex("\S+")
    Then entity(customer) get owns(custom-attribute-2) get annotations is empty
    When entity(customer) get owns(custom-attribute-2) set override: custom-attribute
    When entity(customer) get owns(custom-attribute-2) set annotation: @regex("\S+")
    Then transaction commits; fails
    When connection open schema transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get annotations contain: @regex("\S+")
    Then entity(customer) get owns(custom-attribute) get annotations contain: @regex("\S+")
    Then entity(customer) get owns(custom-attribute-2) get annotations is empty
    When entity(customer) get owns(custom-attribute-2) set annotation: @regex("\S+")
    Then entity(customer) get owns(custom-attribute-2) set override: custom-attribute; fails
    When entity(customer) get owns(custom-attribute-2) unset annotation: @regex("\S+")
    When entity(customer) get owns(custom-attribute-2) set override: custom-attribute
    Then entity(customer) get owns(custom-attribute-2) get supertype: custom-attribute
    Then entity(customer) get owns(custom-attribute-2) get annotations contain: @regex("\S+")
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get annotations contain: @regex("\S+")
    Then entity(customer) get owns(custom-attribute) get annotations contain: @regex("\S+")
    Then entity(customer) get owns(custom-attribute-2) get annotations contain: @regex("\S+")

########################
# not compatible @annotations: @abstract, @cascade, @independent, @replace
########################

  Scenario Outline: <root-type> cannot own with @abstract, @cascade, @independent, and @replace annotations for <value-type> value type
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When <root-type>(<type-name>) set owns: custom-attribute
    Then <root-type>(<type-name>) get owns(custom-attribute) set annotation: @abstract; fails
    Then <root-type>(<type-name>) get owns(custom-attribute) set annotation: @cascade; fails
    Then <root-type>(<type-name>) get owns(custom-attribute) set annotation: @independent; fails
    Then <root-type>(<type-name>) get owns(custom-attribute) set annotation: @replace; fails
    Then <root-type>(<type-name>) get owns(custom-attribute) set annotation: @does-not-exist; fails
    Then <root-type>(<type-name>) get owns(custom-attribute) get annotations is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then <root-type>(<type-name>) get owns(custom-attribute) get annotations is empty
    Examples:
      | root-type | type-name   | value-type |
      | entity    | person      | long       |
      | relation  | description | string     |

########################
# @annotations combinations:
# @key, @unique, @subkey, @values, @range, @card, @regex, @distinct
########################

  Scenario Outline: Owns can set @<annotation-1> and @<annotation-2> together and unset it for scalar <value-type>
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When relation(description) set owns: custom-attribute
    When relation(description) get owns(custom-attribute) set annotation: @<annotation-1>
    When relation(description) get owns(custom-attribute) set annotation: @<annotation-2>
    Then relation(description) get owns(custom-attribute) get annotations contain:
      | @<annotation-1> |
      | @<annotation-2> |
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(description) get owns(custom-attribute) get annotations contain:
      | @<annotation-1> |
      | @<annotation-2> |
    When relation(description) get owns(custom-attribute) unset annotation: @<annotation-1>
    Then relation(description) get owns(custom-attribute) get annotations do not contain: @<annotation-1>
    Then relation(description) get owns(custom-attribute) get annotations contain: @<annotation-2>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(description) get owns(custom-attribute) get annotations do not contain: @<annotation-1>
    Then relation(description) get owns(custom-attribute) get annotations contain: @<annotation-2>
    When relation(description) get owns(custom-attribute) set annotation: @<annotation-1>
    When relation(description) get owns(custom-attribute) unset annotation: @<annotation-2>
    Then relation(description) get owns(custom-attribute) get annotations do not contain: @<annotation-2>
    Then relation(description) get owns(custom-attribute) get annotations contain: @<annotation-1>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(description) get owns(custom-attribute) get annotations do not contain: @<annotation-2>
    Then relation(description) get owns(custom-attribute) get annotations contain: @<annotation-1>
    When relation(description) get owns(custom-attribute) unset annotation: @<annotation-1>
    Then relation(description) get owns(custom-attribute) get annotations is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(description) get owns(custom-attribute) get annotations is empty
    Examples:
    # TODO: Move to "cannot" test if something is wrong here.
      | annotation-1                      | annotation-2       | value-type |
      | key                               | subkey(L)          | long       |
      | key                               | values(1, 2)       | double     |
      | key                               | range(1.0, 2.0)    | decimal    |
      | key                               | regex("s")         | string     |
      | subkey(L)                         | unique             | duration   |
      | subkey(L)                         | values(1, 2)       | long       |
      | subkey(L)                         | range(false, true) | boolean    |
      | subkey(L)                         | card(0, 1)         | long       |
      | subkey(L)                         | regex("s")         | string     |
      | unique                            | values(1, 2)       | long       |
      | unique                            | range(1.0, 2.0)    | decimal    |
      | unique                            | card(0, 1)         | double     |
      | unique                            | regex("s")         | string     |
      | values(2024-05-06+0100)           | card(0, 1)         | datetimetz |
      | range("2020-05-05", "2025-05-05") | card(0, 1)         | datetime   |
      | card(0, 1)                        | regex("s")         | string     |

  Scenario Outline: Ordered ownership can set @<annotation-1> and @<annotation-2> together and unset it for <value-type> value type
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When relation(description) set owns: custom-attribute
    When relation(description) get owns(custom-attribute) set ordering: ordered
    When relation(description) get owns(custom-attribute) set annotation: @<annotation-1>
    When relation(description) get owns(custom-attribute) set annotation: @<annotation-2>
    Then relation(description) get owns(custom-attribute) get annotations contain:
      | @<annotation-1> |
      | @<annotation-2> |
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(description) get owns(custom-attribute) get annotations contain:
      | @<annotation-1> |
      | @<annotation-2> |
    When relation(description) get owns(custom-attribute) unset annotation: @<annotation-1>
    Then relation(description) get owns(custom-attribute) get annotations do not contain: @<annotation-1>
    Then relation(description) get owns(custom-attribute) get annotations contain: @<annotation-2>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(description) get owns(custom-attribute) get annotations do not contain: @<annotation-1>
    Then relation(description) get owns(custom-attribute) get annotations contain: @<annotation-2>
    When relation(description) get owns(custom-attribute) set annotation: @<annotation-1>
    When relation(description) get owns(custom-attribute) unset annotation: @<annotation-2>
    Then relation(description) get owns(custom-attribute) get annotations do not contain: @<annotation-2>
    Then relation(description) get owns(custom-attribute) get annotations contain: @<annotation-1>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(description) get owns(custom-attribute) get annotations do not contain: @<annotation-2>
    Then relation(description) get owns(custom-attribute) get annotations contain: @<annotation-1>
    When relation(description) get owns(custom-attribute) unset annotation: @<annotation-1>
    Then relation(description) get owns(custom-attribute) get annotations is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(description) get owns(custom-attribute) get annotations is empty
    Examples:
    # TODO: Move to "cannot" test if something is wrong here.
      | annotation-1                      | annotation-2    | value-type    |
      | unique                            | values(1, 2)    | long          |
      | unique                            | range(1.0, 2.0) | decimal       |
      | unique                            | card(0, 1)      | double        |
      | unique                            | regex("s")      | string        |
      | unique                            | distinct        | string        |
      | values(2024-05-06+0100)           | card(0, 1)      | datetimetz    |
      | values(1, 2)                      | distinct        | long          |
      | range("2020-05-05", "2025-05-05") | card(0, 1)      | datetime      |
      | range("2020-05-05", "2025-05-05") | distinct        | datetime      |
      | card(0, 1)                        | regex("s")      | string        |
      | card(0, 1)                        | distinct        | custom-struct |
      | regex("s")                        | distinct        | string        |

  Scenario Outline: Owns cannot set @<annotation-1> and @<annotation-2> together for scalar <value-type>
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When transaction commits
    When connection open schema transaction for database: typedb
    When relation(description) set owns: custom-attribute
    When relation(description) get owns(custom-attribute) set annotation: @<annotation-1>
    Then relation(description) get owns(custom-attribute) set annotation: @<annotation-2>; fails
    When connection open schema transaction for database: typedb
    When relation(description) set owns: custom-attribute
    When relation(description) get owns(custom-attribute) set annotation: @<annotation-2>
    Then relation(description) get owns(custom-attribute) set annotation: @<annotation-1>; fails
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(description) get owns(custom-attribute) get annotation contain: @<annotation-2>
    Then relation(description) get owns(custom-attribute) get annotation do not contain: @<annotation-1>
    Examples:
    # TODO: Move to "can" test if something is wrong here.
      | annotation-1     | annotation-2    | value-type |
      # TODO: Key + unique = key in 2.x, but it would be good to restrict it for explicitness.
      | key              | unique          | long       |
      # TODO: key + card is similar to key + unique. I'd just restrict it.
      | key              | card(0, 1)      | long       |
      # TODO: If we allow values + range, write a test to check args compatibility!
      | values(1.0, 2.0) | range(1.0, 2.0) | double     |
      # TODO: If we allow values + regex, write a test to check args compatibility!
      | values("str")    | regex("s")      | string     |
      # TODO: If we allow range + regex, write a test to check args compatibility!
      | range("1", "2")  | regex("s")      | string     |

  Scenario Outline: Ordered ownership cannot set @<annotation-1> and @<annotation-2> together and unset it for <value-type> value type
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When transaction commits
    When connection open schema transaction for database: typedb
    When relation(description) set owns: custom-attribute
    When relation(description) get owns(custom-attribute) set ordering: ordered
    When relation(description) get owns(custom-attribute) set annotation: @<annotation-1>
    Then relation(description) get owns(custom-attribute) set annotation: @<annotation-2>; fails
    When connection open schema transaction for database: typedb
    When relation(description) set owns: custom-attribute
    When relation(description) get owns(custom-attribute) set ordering: ordered
    When relation(description) get owns(custom-attribute) set annotation: @<annotation-2>
    Then relation(description) get owns(custom-attribute) set annotation: @<annotation-1>; fails
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(description) get owns(custom-attribute) get annotation contain: @<annotation-2>
    Then relation(description) get owns(custom-attribute) get annotation do not contain: @<annotation-1>
    Examples:
    # TODO: Move to "can" test if something is wrong here.
      | annotation-1     | annotation-2    | value-type |
      # TODO: If we allow values + range, write a test to check args compatibility!
      | values(1.0, 2.0) | range(1.0, 2.0) | double     |
      # TODO: If we allow values + regex, write a test to check args compatibility!
      | values("str")    | regex("s")      | string     |
      # TODO: If we allow range + regex, write a test to check args compatibility!
      | range("1", "2")  | regex("s")      | string     |
