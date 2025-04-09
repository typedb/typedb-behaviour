# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: Concept Owns

  Background:
    Given typedb starts
    Given connection opens with default authentication
    Given connection is open: true
    Given connection reset database: typedb
    Given connection open schema transaction for database: typedb

    Given create entity type: person
    Given create entity type: customer
    Given create entity type: subscriber
    # Notice: supertypes are the same, but can be specialised for the second subtype inside the tests
    Given entity(customer) set supertype: person
    Given entity(subscriber) set supertype: person
    Given entity(person) set annotation: @abstract
    Given entity(customer) set annotation: @abstract
    Given entity(subscriber) set annotation: @abstract
    Given create relation type: description
    Given relation(description) create role: object
    Given create relation type: registration
    Given relation(registration) create role: registration-object
    Given create relation type: profile
    Given relation(profile) create role: profile-object
    # Notice: supertypes are the same, but can be specialised for the second subtype inside the tests
    Given relation(registration) set supertype: description
    Given relation(profile) set supertype: description
    Given relation(description) set annotation: @abstract
    Given relation(registration) set annotation: @abstract
    Given relation(profile) set annotation: @abstract
    Given create struct: custom-struct
    Given struct(custom-struct) create field: custom-field, with value type: string

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
      | value-type            | value-type-2 |
      | integer               | string       |
      | double                | datetime-tz  |
      | decimal               | datetime     |
      | string                | duration     |
      | boolean               | integer      |
      | date                  | decimal      |
      | datetime-tz           | double       |
      | duration              | boolean      |
      | struct(custom-struct) | integer      |

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
      | value-type            |
      | integer               |
      | datetime              |
      | struct(custom-struct) |

  Scenario: Non-abstract entity type can own abstract attribute with and without value type
    When create entity type: player
    When create attribute type: name
    When attribute(name) set annotation: @abstract
    When create attribute type: email
    When attribute(email) set value type: string
    When attribute(email) set annotation: @abstract
    Then entity(player) set owns: name
    Then entity(player) set owns: email
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(player) get owns contain:
      | name  |
      | email |
    When create attribute type: concrete-name
    When attribute(concrete-name) set supertype: name
    When attribute(concrete-name) set value type: string
    Then entity(player) get owns do not contain:
      | concrete-name |
    When entity(player) set owns: concrete-name
    Then entity(player) get owns contain:
      | name          |
      | email         |
      | concrete-name |
    Then transaction commits

  Scenario: Abstract entity type cannot own non-abstract attribute without value type
    When create entity type: player
    When entity(player) set annotation: @abstract
    When create attribute type: name
    When entity(player) set owns: name
    Then transaction commits; fails
    When connection open schema transaction for database: typedb
    When create entity type: player
    When entity(player) set annotation: @abstract
    When create attribute type: name
    When entity(player) set owns: name
    When attribute(name) set value type: string
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(player) get declared owns contain:
      | name |

  Scenario: Abstract entity type can own abstract attribute with and without value type
    When create entity type: player
    When entity(player) set annotation: @abstract
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

  Scenario: Entity type can unset @abstract annotation if it owns an abstract attribute
    When create entity type: player
    When entity(player) set annotation: @abstract
    When create attribute type: name
    When attribute(name) set annotation: @abstract
    When entity(player) set owns: name
    When entity(player) get owns contain:
      | name |
    Then entity(player) unset annotation: @abstract
    Then entity(player) get constraints do not contain: @abstract
    Then attribute(name) get constraints contain: @abstract
    Then entity(player) get owns(name) get ordering: unordered
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(player) get owns contain:
      | name |
    Then entity(player) get owns(name) get ordering: unordered
    Then entity(player) get constraints do not contain: @abstract
    Then attribute(name) get constraints contain: @abstract

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
    When connection open schema transaction for database: typedb
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
      | value-type            | value-type-2 |
      | integer               | string       |
      | double                | datetime-tz  |
      | decimal               | datetime     |
      | string                | duration     |
      | boolean               | integer      |
      | date                  | decimal      |
      | datetime-tz           | double       |
      | duration              | boolean      |
      | struct(custom-struct) | integer      |

  Scenario: The schema does not contain redundant owns declarations
    When create attribute type: attr0
    When attribute(attr0) set value type: string
    When create entity type: ent00
    When entity(ent00) set owns: attr0
    When create entity type: ent01
    When create entity type: ent1
    When entity(ent1) set supertype: ent00
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(ent1) set owns: attr0
    Then transaction commits; fails
    When connection open schema transaction for database: typedb
    When entity(ent1) set supertype: ent01
    When entity(ent1) set owns: attr0
    Then transaction commits
    When connection open schema transaction for database: typedb
    Then entity(ent1) set supertype: ent00
    Then transaction commits; fails

  Scenario: A type can redeclare ownership of an attribute that has been declared multiple layers above
    When create attribute type: attr0
    When attribute(attr0) set value type: string
    When attribute(attr0) set annotation: @abstract
    When create attribute type: attr1
    When attribute(attr1) set annotation: @abstract
    When attribute(attr1) set supertype: attr0
    When create attribute type: attr2
    When attribute(attr2) set supertype: attr1
    When attribute(attr2) set annotation: @abstract
    When create entity type: ent0
    When entity(ent0) set annotation: @abstract
    When entity(ent0) set owns: attr0
    When create entity type: ent1
    When entity(ent1) set supertype: ent0
    When entity(ent1) set annotation: @abstract
    When entity(ent1) set owns: attr1
    When transaction commits
    When connection open schema transaction for database: typedb
    When create entity type: ent2
    When entity(ent2) set supertype: ent1
    When entity(ent2) set annotation: @abstract
    Then entity(ent2) set owns: attr2
    Then entity(ent2) set owns: attr0
    Then entity(ent2) get owns(attr0) set annotation: @regex("just to specialise")
    When transaction commits
    Then connection open read transaction for database: typedb
    Then entity(ent0) get owns(attr0) get declared annotations do not contain: @regex("just to specialise")
    Then entity(ent2) get owns(attr0) get declared annotations contain: @regex("just to specialise")

  Scenario: A concrete type can have ownerships of abstract attributes
    When create attribute type: attr00
    When attribute(attr00) set value type: string
    When attribute(attr00) set annotation: @abstract
    When create attribute type: attr10
    When attribute(attr10) set supertype: attr00
    When create attribute type: attr01
    When attribute(attr01) set value type: string
    When attribute(attr01) set annotation: @abstract
    When create attribute type: attr11
    When attribute(attr11) set supertype: attr01
    When create entity type: ent00
    When entity(ent00) set annotation: @abstract
    When entity(ent00) set owns: attr00
    When create entity type: ent01
    When entity(ent01) set annotation: @abstract
    When entity(ent01) set owns: attr01
    When create entity type: ent1
    When transaction commits
    When connection open schema transaction for database: typedb
    When entity(ent1) set supertype: ent00
    Then transaction commits
    When connection open schema transaction for database: typedb
    When entity(ent1) set supertype: ent00
    When entity(ent1) set owns: attr10
    Then transaction commits

  Scenario: A type can have ownerships of both abstract and concrete attributes and subattributes
    When create attribute type: attr0
    When attribute(attr0) set value type: string
    When attribute(attr0) set annotation: @abstract
    When create attribute type: attr1
    When attribute(attr1) set supertype: attr0
    When create attribute type: attr2
    When attribute(attr2) set value type: string
    When create entity type: ent0
    When entity(ent0) set annotation: @abstract
    When create entity type: ent0sub
    When entity(ent0sub) set supertype: ent0
    When create entity type: ent1
    When create entity type: ent1sub
    When entity(ent1sub) set supertype: ent1
    When entity(ent0) set owns: attr0
    When entity(ent0) set owns: attr1
    When entity(ent0) set owns: attr2
    When entity(ent1) set owns: attr0
    When entity(ent1) set owns: attr2
    When entity(ent1sub) set owns: attr1
    Then transaction commits
    When connection open read transaction for database: typedb
    Then attribute(attr0) get constraints contain: @abstract
    Then attribute(attr1) get constraints do not contain: @abstract
    Then attribute(attr2) get constraints do not contain: @abstract
    Then entity(ent0) get owns contain:
      | attr0 |
      | attr1 |
      | attr2 |
    Then entity(ent0sub) get owns contain:
      | attr0 |
      | attr1 |
      | attr2 |
    Then entity(ent1) get owns contain:
      | attr0 |
      | attr2 |
    Then entity(ent1) get owns do not contain:
      | attr1 |
    Then entity(ent1sub) get owns contain:
      | attr0 |
      | attr1 |
      | attr2 |

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
      | value-type |
      | double     |
      | boolean    |
      | date       |

  Scenario: Non-abstract relation type can own abstract attribute with and without value type
    When create relation type: reference
    When relation(reference) create role: target
    When create attribute type: name
    When attribute(name) set annotation: @abstract
    When create attribute type: email
    When attribute(email) set value type: string
    When attribute(email) set annotation: @abstract
    Then relation(reference) set owns: name
    Then relation(reference) set owns: email
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(reference) get owns contain:
      | name  |
      | email |
    When create attribute type: concrete-name
    When attribute(concrete-name) set supertype: name
    When attribute(concrete-name) set value type: string
    Then relation(reference) get owns do not contain:
      | concrete-name |
    When relation(reference) set owns: concrete-name
    Then relation(reference) get owns contain:
      | name          |
      | email         |
      | concrete-name |
    Then transaction commits

  Scenario: Abstract relation type cannot own non-abstract attribute without value type
    When create relation type: reference
    When relation(reference) create role: target
    When relation(reference) set annotation: @abstract
    When create attribute type: name
    When relation(reference) set owns: name
    Then transaction commits; fails

  Scenario: Abstract relation type can own abstract attribute with and without value type
    When create relation type: reference
    When relation(reference) create role: target
    When relation(reference) set annotation: @abstract
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

  Scenario: Relation type cannot unset @abstract annotation if it owns an abstract attribute
    When create relation type: reference
    When relation(reference) create role: target
    When relation(reference) set annotation: @abstract
    When create attribute type: name
    When attribute(name) set annotation: @abstract
    When relation(reference) set owns: name
    When relation(reference) get owns contain:
      | name |
    Then relation(reference) unset annotation: @abstract
    Then relation(reference) get constraints do not contain: @abstract
    Then attribute(name) get constraints contain: @abstract
    Then relation(reference) get owns(name) get ordering: unordered
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(reference) get owns contain:
      | name |
    Then relation(reference) get owns(name) get ordering: unordered
    Then relation(reference) get constraints do not contain: @abstract
    Then attribute(name) get constraints contain: @abstract

  Scenario Outline: <root-type> types can unset not set owns
    When create attribute type: email
    When attribute(email) set value type: string
    Then <root-type>(<type-name>) get owns do not contain:
      | email |
    When <root-type>(<type-name>) unset owns: email
    Then <root-type>(<type-name>) get owns do not contain:
      | email |
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<type-name>) get owns do not contain:
      | email |
    When <root-type>(<type-name>) unset owns: email
    Then <root-type>(<type-name>) get owns do not contain:
      | email |
    Examples:
      | root-type | type-name   |
      | entity    | person      |
      | relation  | description |

  Scenario Outline: Deleting an attribute type does not leave dangling owns declarations
    When create attribute type: attr0
    When attribute(attr0) set value type: string
    When create entity type: ent0
    When <root-type>(<type-name>) set owns: attr0
    When transaction commits
    When connection open schema transaction for database: typedb
    When <root-type>(<type-name>) get owns contain:
      | attr0 |
    When delete attribute type: attr0
    Then <root-type>(<type-name>) get owns do not contain:
      | attr0 |
    Then transaction commits
    When connection open read transaction for database: typedb
    Then <root-type>(<type-name>) get owns do not contain:
      | attr0 |
    Examples:
      | root-type | type-name   |
      | entity    | person      |
      | relation  | description |

  Scenario Outline: <root-type> types cannot redeclare inherited owns without specialisation
    When create attribute type: email
    When attribute(email) set value type: <value-type>
    When create attribute type: name
    When attribute(name) set value type: <value-type>
    When <root-type>(<supertype-name>) set owns: name
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<subtype-name>) get owns contain:
      | name |
    When <root-type>(<subtype-name>) set owns: name
    Then transaction commits; fails
    Examples:
      | root-type | supertype-name | subtype-name | value-type |
      | entity    | person         | customer     | string     |
      | entity    | person         | customer     | integer    |
      | relation  | description    | registration | string     |
      | relation  | description    | registration | datetime   |

  Scenario Outline: <root-type> types cannot redeclare inherited owns in multiple layers of inheritance
    When create attribute type: name
    When attribute(name) set value type: <value-type>
    When attribute(name) set annotation: @abstract
    When create attribute type: customer-name
    When attribute(customer-name) set supertype: name
    When <root-type>(<supertype-name>) set annotation: @abstract
    When <root-type>(<supertype-name>) set owns: name
    When <root-type>(<subtype-name>) set owns: customer-name
    When <root-type>(<subtype-name-2>) set supertype: <subtype-name>
    Then <root-type>(<subtype-name-2>) set owns: name
    Then transaction commits; fails
    Examples:
      | root-type | supertype-name | subtype-name | subtype-name-2 | value-type            |
      | entity    | person         | customer     | subscriber     | datetime-tz           |
      | entity    | person         | customer     | subscriber     | struct(custom-struct) |
      | relation  | description    | registration | profile        | decimal               |
      | relation  | description    | registration | profile        | string                |

  Scenario Outline: <root-type> types cannot unset inherited ownership
    When create attribute type: username
    When attribute(username) set value type: <value-type>
    When <root-type>(<supertype-name>) set owns: username
    Then <root-type>(<supertype-name>) get owns contain:
      | username |
    Then <root-type>(<subtype-name>) get owns contain:
      | username |
    Then <root-type>(<subtype-name>) unset owns: username; fails
    Then <root-type>(<subtype-name>) get owns contain:
      | username |
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<subtype-name>) get owns contain:
      | username |
    Then <root-type>(<subtype-name>) unset owns: username; fails
    Examples:
      | root-type | supertype-name | subtype-name | value-type |
      | entity    | person         | customer     | string     |
      | relation  | description    | registration | integer    |

    # TODO: Move to annotation tests
  Scenario Outline: <root-type> types can have multiple subtypes of attribute type affected by its constraints
    When create attribute type: name
    When attribute(name) set value type: string
    When attribute(name) set annotation: @abstract
    When create attribute type: first-name
    When attribute(first-name) set supertype: name
    When create attribute type: second-name
    When attribute(second-name) set supertype: name
    When <root-type>(<supertype-name>) set owns: name
    When <root-type>(<supertype-name>) get owns(name) set annotation: @regex("test")
    Then <root-type>(<supertype-name>) get owns contain:
      | name |
    When <root-type>(<subtype-name>) set owns: first-name
    When <root-type>(<subtype-name>) set owns: second-name
    When <root-type>(<supertype-name>) get constraints for owned attribute(name) contain: @regex("test")
    When <root-type>(<supertype-name>) get constraints for owned attribute(first-name) do not contain: @regex("test")
    When <root-type>(<supertype-name>) get constraints for owned attribute(second-name) do not contain: @regex("test")
    When <root-type>(<subtype-name>) get constraints for owned attribute(name) contain: @regex("test")
    When <root-type>(<subtype-name>) get constraints for owned attribute(first-name) contain: @regex("test")
    When <root-type>(<subtype-name>) get constraints for owned attribute(second-name) contain: @regex("test")
    Then <root-type>(<subtype-name>) get owns contain:
      | name        |
      | first-name  |
      | second-name |
    When transaction commits
    When connection open read transaction for database: typedb
    Then <root-type>(<subtype-name>) get owns contain:
      | name        |
      | first-name  |
      | second-name |
    Examples:
      | root-type | supertype-name | subtype-name |
      | entity    | person         | customer     |
      | relation  | description    | registration |

  Scenario Outline: Abstract <root-type> can own and non-abstract <root-type> can inherit non-abstract attribute
    When create attribute type: username
    When attribute(username) set value type: string
    When <root-type>(<supertype-name>) set annotation: @abstract
    When <root-type>(<supertype-name>) set owns: username
    When <root-type>(<supertype-name>) get owns contain:
      | username |
    When <root-type>(<subtype-name>) get owns contain:
      | username |
    When transaction commits
    When connection open read transaction for database: typedb
    Then <root-type>(<supertype-name>) get owns contain:
      | username |
    Then <root-type>(<subtype-name>) get owns contain:
      | username |
    Then attribute(username) get constraints do not contain: @abstract
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
      | value-type            | value-type-2 |
      | integer               | string       |
      | double                | datetime-tz  |
      | decimal               | datetime     |
      | string                | duration     |
      | boolean               | integer      |
      | date                  | decimal      |
      | datetime-tz           | double       |
      | duration              | boolean      |
      | struct(custom-struct) | integer      |

  Scenario Outline: Entity types can redeclare ordered ownership
    When create attribute type: name
    When attribute(name) set value type: <value-type>
    When create attribute type: email
    When attribute(email) set value type: <value-type>
    When entity(person) set owns: name
    When entity(person) get owns(name) set ordering: ordered
    When entity(person) set owns: email
    When entity(person) get owns(email) set ordering: ordered
    Then entity(person) set owns: name; fails
    When entity(person) set owns: name[]
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) set owns: email; fails
    When entity(person) set owns: email[]
    Then entity(person) get owns(email) get ordering: ordered
    When entity(person) get owns(email) set ordering: unordered
    Then entity(person) get owns(email) get ordering: unordered
    Then transaction commits
    Examples:
      | value-type            |
      | integer               |
      | double                |
      | decimal               |
      | string                |
      | boolean               |
      | date                  |
      | datetime              |
      | datetime-tz           |
      | duration              |
      | struct(custom-struct) |

  Scenario: Abstract entity type can set ordered ownership
    When create entity type: player
    When entity(player) set annotation: @abstract
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
    When connection open schema transaction for database: typedb
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
      | value-type            | value-type-2 |
      | integer               | string       |
      | double                | datetime-tz  |
      | struct(custom-struct) | decimal      |

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
    Then relation(reference) set owns: name; fails
    When relation(reference) set owns: name[]
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(reference) set owns: email; fails
    When relation(reference) set owns: email[]
    Then relation(reference) get owns(email) get ordering: ordered
    When relation(reference) get owns(email) set ordering: unordered
    Then relation(reference) get owns(email) get ordering: unordered
    Then transaction commits
    Examples:
      | value-type            |
      | integer               |
      | double                |
      | decimal               |
      | string                |
      | boolean               |
      | date                  |
      | datetime              |
      | datetime-tz           |
      | duration              |
      | struct(custom-struct) |

  Scenario: Abstract relation type can set ordered ownership of abstract attribute
    When create relation type: reference
    When relation(reference) create role: target
    When relation(reference) set annotation: @abstract
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

  Scenario: Relation type can unset @abstract annotation if it has ordered ownership of abstract attribute
    When create relation type: reference
    When relation(reference) create role: target
    When relation(reference) set annotation: @abstract
    When create attribute type: name
    When attribute(name) set annotation: @abstract
    When relation(reference) set owns: name
    When relation(reference) get owns contain:
      | name |
    When relation(reference) get owns(name) set ordering: ordered
    Then relation(reference) unset annotation: @abstract
    Then relation(reference) get constraints do not contain: @abstract
    Then attribute(name) get constraints contain: @abstract
    Then relation(reference) get owns(name) get ordering: ordered
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(reference) get owns contain:
      | name |
    Then relation(reference) get owns(name) get ordering: ordered
    Then relation(reference) get constraints do not contain: @abstract
    Then attribute(name) get constraints contain: @abstract

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
      | entity    | person      | date       |
      | relation  | description | duration   |

  Scenario Outline: Ordered owns can redeclare ordering
    When create attribute type: name
    When attribute(name) set value type: <value-type>
    When <root-type>(<type-name>) set owns: name
    When <root-type>(<type-name>) get owns(name) set ordering: ordered
    Then <root-type>(<type-name>) get owns(name) get ordering: ordered
    When <root-type>(<type-name>) get owns(name) set ordering: ordered
    Then <root-type>(<type-name>) get owns(name) get ordering: ordered
    When transaction commits
    When connection open schema transaction for database: typedb
    When <root-type>(<type-name>) get owns(name) set ordering: ordered
    Then <root-type>(<type-name>) get owns(name) get ordering: ordered
    Examples:
      | root-type | type-name   | value-type |
      | entity    | person      | duration   |
      | relation  | description | string     |

  Scenario Outline: <root-type> types cannot redeclare ordered inherited owns as owns without specialisation
    When create attribute type: email
    When attribute(email) set value type: <value-type>
    When create attribute type: name
    When attribute(name) set value type: <value-type>
    When <root-type>(<supertype-name>) set owns: name
    When <root-type>(<supertype-name>) get owns(name) set ordering: ordered
    Then <root-type>(<subtype-name>) set owns: name; fails
    When <root-type>(<subtype-name>) set owns: name[]
    Then transaction commits; fails
    Examples:
      | root-type | supertype-name | subtype-name | value-type |
      | entity    | person         | customer     | string     |
      | entity    | person         | customer     | integer    |
      | relation  | description    | registration | string     |
      | relation  | description    | registration | datetime   |

  Scenario Outline: <root-type> types cannot redeclare ordered inherited owns in multiple layers of inheritance without specialisation
    When create attribute type: name
    When attribute(name) set value type: <value-type>
    When attribute(name) set annotation: @abstract
    When create attribute type: customer-name
    When attribute(customer-name) set supertype: name
    When <root-type>(<supertype-name>) set annotation: @abstract
    When <root-type>(<supertype-name>) set owns: name[]
    When <root-type>(<subtype-name>) set owns: customer-name[]
    When <root-type>(<subtype-name-2>) set supertype: <subtype-name>
    Then <root-type>(<subtype-name-2>) set owns: name; fails
    When <root-type>(<subtype-name-2>) set owns: name[]
    Then transaction commits; fails
    Examples:
      | root-type | supertype-name | subtype-name | subtype-name-2 | value-type            |
      | entity    | person         | customer     | subscriber     | datetime-tz           |
      | entity    | person         | customer     | subscriber     | struct(custom-struct) |
      | relation  | description    | registration | profile        | decimal               |
      | relation  | description    | registration | profile        | string                |

  Scenario Outline: <root-type> types cannot own super and sub attribute types of different orderings
    When create attribute type: name
    When attribute(name) set value type: <value-type>
    When attribute(name) set annotation: @abstract
    When create attribute type: first-name
    When attribute(first-name) set supertype: name
    When <root-type>(<type-name>) set annotation: @abstract
    When <root-type>(<type-name>) set owns: name
    When <root-type>(<type-name>) get owns(name) set ordering: ordered
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<type-name>) set owns: first-name; fails
    When <root-type>(<type-name>) set owns: first-name[]
    Then <root-type>(<type-name>) get owns(first-name) get ordering: ordered
    Then transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<type-name>) get owns(first-name) set ordering: unordered; fails
    Then <root-type>(<type-name>) get owns(name) set ordering: unordered; fails
    When <root-type>(<type-name>) unset owns: first-name
    Then <root-type>(<type-name>) set owns: first-name; fails
    When <root-type>(<type-name>) get owns(name) set ordering: unordered
    When <root-type>(<type-name>) set owns: first-name
    Then <root-type>(<type-name>) get owns(first-name) get ordering: unordered
    When transaction commits
    When connection open read transaction for database: typedb
    Then <root-type>(<type-name>) get owns(name) get ordering: unordered
    Then <root-type>(<type-name>) get owns(first-name) get ordering: unordered
    Examples:
      | root-type | type-name   | value-type |
      | entity    | person      | string     |
      | relation  | description | string     |

  Scenario Outline: <root-type> types cannot unset inherited ordered ownership
    When create attribute type: username
    When attribute(username) set value type: <value-type>
    When <root-type>(<supertype-name>) set owns: username
    Then <root-type>(<supertype-name>) get owns contain:
      | username |
    When <root-type>(<supertype-name>) get owns(username) set ordering: ordered
    Then <root-type>(<subtype-name>) get owns contain:
      | username |
    Then <root-type>(<subtype-name>) get owns(username) get ordering: ordered
    Then <root-type>(<subtype-name>) unset owns: username; fails
    Then <root-type>(<subtype-name>) get owns contain:
      | username |
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<subtype-name>) get owns contain:
      | username |
    Then <root-type>(<subtype-name>) get owns(username) get ordering: ordered
    Then <root-type>(<subtype-name>) unset owns: username; fails
    Then <root-type>(<subtype-name>) get owns contain:
      | username |
    Examples:
      | root-type | supertype-name | subtype-name | value-type |
      | entity    | person         | customer     | string     |
      | relation  | description    | registration | integer    |

  Scenario Outline: Ownerships with subtypes and supertypes can change ordering only together for <root-type>
    When create attribute type: literal
    When attribute(literal) set annotation: @abstract
    When attribute(literal) set value type: <value-type>
    When create attribute type: name
    When attribute(name) set annotation: @abstract
    When attribute(name) set supertype: literal
    When create attribute type: surname
    When attribute(surname) set annotation: @abstract
    When attribute(surname) set supertype: name
    When <root-type>(<supertype-name>) set annotation: @abstract
    When <root-type>(<supertype-name>) set owns: literal
    When <root-type>(<subtype-name>) set annotation: @abstract
    When <root-type>(<subtype-name>) set supertype: <supertype-name>
    When <root-type>(<subtype-name>) set owns: name
    When <root-type>(<subtype-name-2>) set supertype: <subtype-name>
    When <root-type>(<subtype-name-2>) set annotation: @abstract
    When <root-type>(<subtype-name-2>) set owns: surname
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<supertype-name>) get owns(literal) set ordering: ordered; fails
    Then <root-type>(<subtype-name>) get owns(name) set ordering: ordered; fails
    Then <root-type>(<subtype-name-2>) get owns(surname) set ordering: ordered; fails
    When attribute(name) unset supertype
    Then <root-type>(<supertype-name>) get owns(literal) set ordering: ordered
    Then attribute(name) set supertype: literal; fails
    Then <root-type>(<subtype-name>) get owns(name) set ordering: ordered; fails
    Then <root-type>(<subtype-name-2>) get owns(surname) set ordering: ordered; fails
    When <root-type>(<subtype-name-2>) unset owns: surname
    Then <root-type>(<subtype-name>) get owns(name) set ordering: ordered
    When attribute(name) set supertype: literal
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<subtype-name-2>) set owns: surname; fails
    When <root-type>(<subtype-name-2>) set owns: surname[]
    Then transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<supertype-name>) get owns(literal) get ordering: ordered
    Then <root-type>(<subtype-name>) get owns(name) get ordering: ordered
    Then <root-type>(<subtype-name-2>) get owns(surname) get ordering: ordered
    Then <root-type>(<supertype-name>) get owns(literal) set ordering: unordered; fails
    Then <root-type>(<subtype-name>) get owns(name) set ordering: unordered; fails
    Then <root-type>(<subtype-name-2>) get owns(surname) set ordering: unordered; fails
    When <root-type>(<supertype-name>) unset owns: literal
    Then <root-type>(<subtype-name>) get owns(name) set ordering: unordered; fails
    Then <root-type>(<subtype-name-2>) get owns(surname) set ordering: unordered; fails
    When attribute(surname) unset supertype
    Then <root-type>(<subtype-name>) get owns(name) set ordering: unordered
    Then <root-type>(<subtype-name-2>) get owns(surname) set ordering: unordered
    When <root-type>(<supertype-name>) set owns: literal
    Then <root-type>(<supertype-name>) get owns(literal) get ordering: unordered
    Then <root-type>(<subtype-name>) get owns(name) get ordering: unordered
    Then <root-type>(<subtype-name-2>) get owns(surname) get ordering: unordered
    Then transaction commits
    When connection open read transaction for database: typedb
    Then <root-type>(<supertype-name>) get owns(literal) get ordering: unordered
    Then <root-type>(<subtype-name>) get owns(name) get ordering: unordered
    Then <root-type>(<subtype-name-2>) get owns(surname) get ordering: unordered
    Examples:
      | root-type | supertype-name | subtype-name | subtype-name-2 | value-type            |
      | entity    | person         | customer     | subscriber     | decimal               |
      | relation  | description    | registration | profile        | struct(custom-struct) |

  Scenario Outline: <root-type> type can only redeclare ownership if it specialises the inherited one with an annotation
    When create attribute type: literal
    When attribute(literal) set annotation: @abstract
    When attribute(literal) set value type: string
    When create attribute type: name
    When attribute(name) set annotation: @abstract
    When attribute(name) set supertype: literal
    When <root-type>(<supertype-name>) set owns: literal
    When <root-type>(<supertype-name>) set owns: name
    When transaction commits
    When connection open schema transaction for database: typedb
    When <root-type>(<subtype-name>) set owns: name
    Then transaction commits; fails
    When connection open schema transaction for database: typedb
    When <root-type>(<subtype-name>) set owns: name
    When <root-type>(<subtype-name>) get owns(name) set annotation: @regex("Accept me, please")
    Then transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<supertype-name>) get owns(name) get declared annotations do not contain: @regex("Accept me, please")
    Then <root-type>(<subtype-name>) get owns(name) get declared annotations contain: @regex("Accept me, please")
    Then <root-type>(<supertype-name>) get owns(literal) get declared annotations do not contain: @regex("Accept me, please")
    Then <root-type>(<subtype-name>) get owns(literal) get declared annotations do not contain: @regex("Accept me, please")
    Then <root-type>(<supertype-name>) get owns(name) get constraints do not contain: @regex("Accept me, please")
    Then <root-type>(<subtype-name>) get owns(name) get constraints contain: @regex("Accept me, please")
    Then <root-type>(<supertype-name>) get owns(literal) get constraints do not contain: @regex("Accept me, please")
    Then <root-type>(<subtype-name>) get owns(literal) get constraints do not contain: @regex("Accept me, please")
    Examples:
      | root-type | supertype-name | subtype-name |
      | entity    | person         | customer     |
      | relation  | description    | registration |
