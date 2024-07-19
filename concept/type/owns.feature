# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: Concept Owns

  Background:
    Given typedb starts
    Given connection opens with default authentication
    Given connection has been opened
    Given connection reset database: typedb
    Given connection open schema transaction for database: typedb

    Given create entity type: person
    Given create entity type: customer
    Given create entity type: subscriber
    # Notice: supertypes are the same, but can be overridden for the second subtype inside the tests
    Given entity(customer) set supertype: person
    Given entity(subscriber) set supertype: person
    Given entity(person) set annotation: @abstract
    Given entity(customer) set annotation: @abstract
    Given entity(subscriber) set annotation: @abstract
    Given create relation type: description
    Given relation(description) create role: object
    Given create relation type: registration
    Given create relation type: profile
    # Notice: supertypes are the same, but can be overridden for the second subtype inside the tests
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
  Scenario Outline: Root types cannot own attributes
    When create attribute type: name
    Then <root-type>(<root-type>) set owns: name; fails
    Examples:
      | root-type |
      | entity    |
      | relation  |

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
      | double        | datetime-tz  |
      | decimal       | datetime     |
      | string        | duration     |
      | boolean       | long         |
      | date          | decimal      |
      | datetime-tz   | double       |
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
      | datetime      |
      | custom-struct |

    # TODO: Only for typeql
#  Scenario: Entity types cannot own entities, relations, roles, structs, structs fields, and non-existing things
#    When create entity type: car
#    When create relation type: credit
#    When relation(credit) create role: creditor
#    When create struct: passport
#    When struct(passport) create field: birthday, with value type: datetime
#    Then entity(person) set owns: car; fails
#    Then entity(person) set owns: credit; fails
#    Then entity(person) set owns: credit:creditor; fails
#    Then entity(person) set owns: passport; fails
#    Then entity(person) set owns: passport:birthday; fails
#    Then entity(person) set owns: does-not-exist; fails
#    Then entity(person) get owns is empty
#    When transaction commits
#    When connection open read transaction for database: typedb
#    Then entity(person) get owns is empty

  Scenario: Non-abstract entity type cannot own abstract attribute with and without value type
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
    When transaction closes
    When connection open schema transaction for database: typedb
    When create attribute type: attr0
    When attribute(attr0) set value type: string
    When attribute(attr0) set annotation: @abstract
    When create entity type: ent0
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(ent0) set owns: attr0; fails
    When transaction closes
    When connection open schema transaction for database: typedb
    When entity(ent0) set annotation: @abstract
    When entity(ent0) set owns: attr0
    Then transaction commits
    When connection open schema transaction for database: typedb
    Then entity(ent0) unset annotation: @abstract; fails
    When transaction closes
    When connection open schema transaction for database: typedb
    When create entity type: ent1
    When entity(ent1) set supertype: ent0
    Then transaction commits; fails

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

  Scenario: Entity type cannot unset abstract annotation if it owns an abstract attribute
    When create entity type: player
    When entity(player) set annotation: @abstract
    When create attribute type: name
    When attribute(name) set annotation: @abstract
    When entity(player) set owns: name
    When entity(player) get owns contain:
      | name |
    Then entity(player) unset annotation: @abstract; fails
    Then entity(player) get annotations contain: @abstract
    Then entity(player) get declared annotations contain: @abstract
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(player) get owns contain:
      | name |
    Then entity(player) get annotations contain: @abstract
    Then entity(player) get declared annotations contain: @abstract
    Then entity(player) unset annotation: @abstract; fails
    Then entity(player) get annotations contain: @abstract
    Then entity(player) get declared annotations contain: @abstract

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
      | value-type    | value-type-2 |
      | long          | string       |
      | double        | datetime-tz  |
      | decimal       | datetime     |
      | string        | duration     |
      | boolean       | long         |
      | date          | decimal      |
      | datetime-tz   | double       |
      | duration      | boolean      |
      | custom-struct | long         |

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


  Scenario: A type may only override an ownership it inherits
    When create attribute type: attr0
    When attribute(attr0) set value type: string
    When attribute(attr0) set annotation: @abstract
    When create attribute type: attr1
    When attribute(attr1) set supertype: attr0
    When create entity type: ent00
    When entity(ent00) set annotation: @abstract
    When entity(ent00) set owns: attr0
    When create entity type: ent01
    When entity(ent01) set annotation: @abstract
    When transaction commits
    When connection open schema transaction for database: typedb
    When create entity type: ent1
    When entity(ent1) set owns: attr1
    Then entity(ent1) get owns(attr1) set override: attr0; fails
    When transaction closes
    When connection open schema transaction for database: typedb
    When create entity type: ent1
    When entity(ent1) set supertype: ent00
    When entity(ent1) set owns: attr1
    When entity(ent1) get owns(attr1) set override: attr0
    Then transaction commits
    When connection open schema transaction for database: typedb
    When entity(ent00) unset owns: attr0
    Then transaction commits; fails
    When connection open schema transaction for database: typedb
    When entity(ent1) set supertype: ent01; fails

  Scenario: A type may not declare ownership of an attribute that has been overridden by an inherited ownership
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
    When entity(ent1) get owns(attr1) set override: attr0
    When transaction commits
    When connection open schema transaction for database: typedb
    When create entity type: ent2
    When entity(ent2) set supertype: ent1
    When entity(ent2) set annotation: @abstract
    Then entity(ent2) set owns: attr2
    Then entity(ent2) get owns(attr2) set override: attr0; fails
    When transaction closes
    When connection open schema transaction for database: typedb
    When create entity type: ent2
    When entity(ent2) set supertype: ent1
    When entity(ent2) set annotation: @abstract
    When entity(ent1) unset owns: attr1
    When entity(ent2) set owns: attr2
    When entity(ent2) get owns(attr2) set override: attr0
    Then transaction commits
    When connection open schema transaction for database: typedb
    When entity(ent1) set owns: attr1
    When entity(ent1) get owns(attr1) set override: attr0
    Then transaction commits; fails
    When connection open schema transaction for database: typedb
    When create entity type: ent3
    When entity(ent3) set annotation: @abstract
    When entity(ent3) set owns: attr0
    Then transaction commits
    When connection open schema transaction for database: typedb
    When entity(ent3) set supertype: ent2; fails
    When transaction closes
    When connection open schema transaction for database: typedb
    When create entity type: ent4
    When entity(ent4) set annotation: @abstract
    When entity(ent4) set owns: attr0
    When entity(ent4) set supertype: ent3
    When entity(ent3) unset owns: attr0
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(ent4) get supertype: ent3
    Then entity(ent4) get owns contain:
      | attr0 |
    Then entity(ent3) get owns do not contain:
      | attr0 |
    When entity(ent3) set supertype: ent2
    Then transaction commits; fails

  Scenario: A type may only override an ownership it inherits with a subtype of the inherited attribute
    When create attribute type: attr0
    When attribute(attr0) set value type: string
    When attribute(attr0) set annotation: @abstract
    When create attribute type: attr1
    When attribute(attr1) set value type: string
    # Same, but the attributes are not subtypes
    When create entity type: ent00
    When entity(ent00) set annotation: @abstract
    When entity(ent00) set owns: attr0
    When transaction commits
    When connection open schema transaction for database: typedb
    When create entity type: ent1
    When entity(ent1) set supertype: ent00
    When entity(ent1) set owns: attr1
    Then entity(ent1) get owns(attr1) set override: attr0; fails

  Scenario: A concrete type must override any ownerships of abstract attributes it inherits
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
    # inherits abstract ownership but does not override
    When connection open schema transaction for database: typedb
    When entity(ent1) set supertype: ent00
    Then transaction commits; fails
    # declares concrete ownership with a subtype but is missing override clause
    When connection open schema transaction for database: typedb
    When entity(ent1) set supertype: ent00
    When entity(ent1) set owns: attr10
    Then transaction commits; fails
    When connection open schema transaction for database: typedb
    When entity(ent1) set supertype: ent00
    When entity(ent1) set owns: attr10
    When entity(ent1) get owns(attr10) set override: attr00
    Then transaction commits
    When connection open schema transaction for database: typedb
    When entity(ent1) set supertype: ent00
    When entity(ent1) set owns: attr10
    When entity(ent1) get owns(attr10) set override: attr00
    Then transaction commits
    When connection open schema transaction for database: typedb
    When entity(ent1) set owns: attr11
    Then transaction commits
    When connection open schema transaction for database: typedb
    When entity(ent1) set supertype: ent01; fails

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

    # TODO: Only for typeql
#  Scenario: Relation types cannot own entities, relations, roles, structs, structs fields, and non-existing things
#    When create relation type: credit
#    When relation(credit) create role: creditor
#    When create relation type: marriage
#    When relation(marriage) create role: spouse
#    When create struct: passport-document
#    When struct(passport-document) create field: first-name, with value type: string
#    When struct(passport-document) create field: surname, with value type: string
#    When struct(passport-document) create field: birthday, with value type: datetime
#    Then relation(marriage) set owns: person; fails
#    Then relation(marriage) set owns: credit; fails
#    Then relation(marriage) set owns: credit:creditor; fails
#    Then relation(marriage) set owns: passport; fails
#    Then relation(marriage) set owns: passport:birthday; fails
#    Then relation(marriage) set owns: marriage:spouse; fails
#    Then relation(marriage) set owns: does-not-exist; fails
#    Then relation(marriage) get owns is empty
#    When transaction commits
#    When connection open read transaction for database: typedb
#    Then relation(marriage) get owns is empty

  Scenario: Non-abstract relation type cannot own abstract attribute with and without value type
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
    When transaction closes
    When connection open schema transaction for database: typedb
    When create attribute type: attr0
    When attribute(attr0) set value type: string
    When attribute(attr0) set annotation: @abstract
    When create relation type: rel0
    When relation(rel0) create role: role0
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(rel0) set owns: attr0; fails
    When transaction closes
    When connection open schema transaction for database: typedb
    When relation(rel0) set annotation: @abstract
    When relation(rel0) set owns: attr0
    Then transaction commits
    When connection open schema transaction for database: typedb
    Then relation(rel0) unset annotation: @abstract; fails
    When transaction closes
    When connection open schema transaction for database: typedb
    When create relation type: rel1
    When relation(rel1) set supertype: rel0
    When relation(rel1) create role: role1
    Then transaction commits; fails

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
    Then relation(reference) unset annotation: @abstract; fails
    Then relation(reference) get annotations contain: @abstract
    Then relation(reference) get declared annotations contain: @abstract
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(reference) get owns contain:
      | name |
    Then relation(reference) get annotations contain: @abstract
    Then relation(reference) get declared annotations contain: @abstract
    Then relation(reference) unset annotation: @abstract; fails
    Then relation(reference) get annotations contain: @abstract
    Then relation(reference) get declared annotations contain: @abstract

    # TODO: Only for typeql
#  Scenario: Attribute types cannot own entities, attributes, relations, roles, structs, structs fields, and non-existing things
#    When create attribute type: surname
#    When create relation type: marriage
#    When relation(marriage) create role: spouse
#    When attribute(surname) set value type: string
#    When create struct: passport
#    When struct(passport) create field: first-name, with value type: string
#    When struct(passport) create field: surname, with value type: string
#    When struct(passport) create field: birthday, with value type: datetime
#    When create attribute type: name
#    When attribute(name) set value type: string
#    Then attribute(name) set owns: person; fails
#    Then attribute(name) set owns: surname; fails
#    Then attribute(name) set owns: marriage; fails
#    Then attribute(name) set owns: marriage:spouse; fails
#    Then attribute(name) set owns: passport; fails
#    Then attribute(name) set owns: passport:birthday; fails
#    Then attribute(name) set owns: does-not-exist; fails
#    Then attribute(name) get owns is empty
#    When transaction commits
#    When connection open read transaction for database: typedb
#    Then attribute(name) get owns is empty

  # TODO: Only for typeql
#  Scenario: structs cannot own entities, attributes, relations, roles, structs, structs fields, and non-existing things
#    When create attribute type: name
#    When create relation type: marriage
#    When relation(marriage) create role: spouse
#    When attribute(surname) set value type: string
#    When create struct: passport
#    When struct(passport) create field: birthday, with value type: datetime
#    When create struct: wallet
#    When struct(wallet) create field: currency, with value type: string
#    When struct(wallet) create field: value, with value type: double
#    Then struct(wallet) set owns: person; fails
#    Then struct(wallet) set owns: name; fails
#    Then struct(wallet) set owns: marriage; fails
#    Then struct(wallet) set owns: marriage:spouse; fails
#    Then struct(wallet) set owns: passport; fails
#    Then struct(wallet) set owns: passport:birthday; fails
#    Then struct(wallet) set owns: wallet:currency; fails
#    Then struct(wallet) set owns: does-not-exist; fails
#    Then struct(wallet) get owns is empty
#    When transaction commits
#    When connection open read transaction for database: typedb
#    Then struct(wallet) get owns is empty

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
#    Then <root-type>(<type-name>) get owns contain:
#    |name|
#    Examples:
#      | root-type | type-name   | value-type | value           |
#      | entity    | person      | long       | 1               |
#      | entity    | person      | double     | 1.0             |
#      | entity    | person      | decimal    | 1.0             |
#      | entity    | person      | string     | "alice"         |
#      | entity    | person      | boolean    | true            |
#      | entity    | person      | date       | 2024-05-04      |
#      | entity    | person      | datetime   | 2024-05-04      |
#      | entity    | person      | datetime-tz | 2024-05-04+0010 |
#      | entity    | person      | duration   | P1Y             |
#      | relation  | description | long       | 1               |
#      | relation  | description | double     | 1.0             |
#      | relation  | description | decimal    | 1.0             |
#      | relation  | description | string     | "alice"         |
#      | relation  | description | boolean    | true            |
#      | relation  | description | date       | 2024-05-04      |
#      | relation  | description | datetime   | 2024-05-04      |
#      | relation  | description | datetime-tz | 2024-05-04+0010 |
#      | relation  | description | duration   | P1Y             |

  Scenario Outline: <root-type> types can re-override owns
    When create attribute type: email
    When attribute(email) set value type: <value-type>
    When attribute(email) set annotation: @abstract
    When create attribute type: work-email
    When attribute(work-email) set supertype: email
    When <root-type>(<supertype-name>) set annotation: @abstract
    When <root-type>(<supertype-name>) set owns: email
    When <root-type>(<subtype-name>) set annotation: @abstract
    When <root-type>(<subtype-name>) set owns: work-email
    When <root-type>(<subtype-name>) get owns(work-email) set override: email
    Then <root-type>(<subtype-name>) get owns overridden(work-email) get label: email
    When transaction commits
    When connection open schema transaction for database: typedb
    When <root-type>(<subtype-name>) set owns: work-email
    When <root-type>(<subtype-name>) get owns(work-email) set override: email
    Then <root-type>(<subtype-name>) get owns overridden(work-email) get label: email
    When transaction commits
    When connection open read transaction for database: typedb
    Then <root-type>(<subtype-name>) get owns overridden(work-email) get label: email
    Examples:
      | root-type | supertype-name | subtype-name | value-type    |
      | entity    | person         | customer     | double        |
      | entity    | person         | customer     | date          |
      | entity    | person         | customer     | datetime      |
      | entity    | person         | customer     | custom-struct |
      | relation  | description    | registration | long          |
      | relation  | description    | registration | decimal       |
      | relation  | description    | registration | string        |
      | relation  | description    | registration | datetime-tz   |

  Scenario Outline: <root-type> types can unset override of inherited owns
    When create attribute type: email
    When attribute(email) set value type: <value-type>
    When attribute(email) set annotation: @abstract
    When create attribute type: name
    When attribute(name) set value type: <value-type>
    When attribute(name) set annotation: @abstract
    When create attribute type: work-email
    When attribute(work-email) set supertype: email
    When <root-type>(<supertype-name>) set annotation: @abstract
    When <root-type>(<supertype-name>) set owns: email
    When <root-type>(<supertype-name>) set owns: name
    When <root-type>(<subtype-name>) set owns: work-email
    When <root-type>(<subtype-name>) get owns(work-email) set override: email
    Then <root-type>(<subtype-name>) get owns overridden(work-email) get label: email
    Then <root-type>(<subtype-name>) get owns contain:
      | work-email |
      | name       |
    Then <root-type>(<subtype-name>) get declared owns contain:
      | work-email |
    Then <root-type>(<subtype-name>) get declared owns do not contain:
      | name |
    Then <root-type>(<subtype-name>) get owns do not contain:
      | email |
    When <root-type>(<subtype-name>) get owns(work-email) unset override
    Then <root-type>(<subtype-name>) get owns contain:
      | work-email |
      | email      |
      | name       |
    Then <root-type>(<subtype-name>) get declared owns contain:
      | work-email |
    Then <root-type>(<subtype-name>) get declared owns do not contain:
      | email |
      | name  |
    When <root-type>(<subtype-name>) get owns(work-email) set override: email
    Then <root-type>(<subtype-name>) get owns contain:
      | work-email |
      | name       |
    Then <root-type>(<subtype-name>) get declared owns contain:
      | work-email |
    Then <root-type>(<subtype-name>) get declared owns do not contain:
      | email |
      | name  |
    Then <root-type>(<subtype-name>) get owns do not contain:
      | email |
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<subtype-name>) get owns contain:
      | work-email |
      | name       |
    Then <root-type>(<subtype-name>) get declared owns contain:
      | work-email |
    Then <root-type>(<subtype-name>) get declared owns do not contain:
      | name |
    Then <root-type>(<subtype-name>) get owns do not contain:
      | email |
    When <root-type>(<subtype-name>) get owns(work-email) unset override
    Then <root-type>(<subtype-name>) get owns contain:
      | work-email |
      | email      |
      | name       |
    Then <root-type>(<subtype-name>) get declared owns contain:
      | work-email |
    Then <root-type>(<subtype-name>) get declared owns do not contain:
      | email |
      | name  |
    When transaction commits
    When connection open read transaction for database: typedb
    Then <root-type>(<subtype-name>) get owns contain:
      | work-email |
      | email      |
      | name       |
    Then <root-type>(<subtype-name>) get declared owns contain:
      | work-email |
    Then <root-type>(<subtype-name>) get declared owns do not contain:
      | email |
      | name  |
    Examples:
      | root-type | supertype-name | subtype-name | value-type |
      | entity    | person         | customer     | double     |
      | relation  | description    | registration | long       |

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

  Scenario Outline: <root-type> types cannot redeclare inherited owns as owns
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
    When connection open schema transaction for database: typedb
    When <root-type>(<subtype-name>) set owns: name
    When <root-type>(<subtype-name>) get owns(name) set override: name
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
    When attribute(customer-name) set supertype: name
    When <root-type>(<supertype-name>) set annotation: @abstract
    When <root-type>(<supertype-name>) set owns: name
    When <root-type>(<subtype-name>) set owns: customer-name
    When <root-type>(<subtype-name-2>) set supertype: <subtype-name>
    Then <root-type>(<subtype-name-2>) set owns: name
    Then transaction commits; fails
    Examples:
      | root-type | supertype-name | subtype-name | subtype-name-2 | value-type    |
      | entity    | person         | customer     | subscriber     | datetime-tz   |
      | entity    | person         | customer     | subscriber     | custom-struct |
      | relation  | description    | registration | profile        | decimal       |
      | relation  | description    | registration | profile        | string        |

  Scenario Outline: <root-type> types cannot redeclare overridden owns as owns
    When create attribute type: name
    When attribute(name) set value type: <value-type>
    When attribute(name) set annotation: @abstract
    When create attribute type: customer-name
    When attribute(customer-name) set supertype: name
    When <root-type>(<supertype-name>) set annotation: @abstract
    When <root-type>(<supertype-name>) set owns: name
    When <root-type>(<subtype-name>) set owns: customer-name
    When <root-type>(<subtype-name-2>) set supertype: <subtype-name>
    When transaction commits
    When connection open schema transaction for database: typedb
    When <root-type>(<subtype-name-2>) set owns: customer-name
    When <root-type>(<subtype-name-2>) get owns(customer-name) set override: name
    Then transaction commits; fails
    When connection open schema transaction for database: typedb
    When <root-type>(<subtype-name-2>) set owns: name
    When <root-type>(<subtype-name>) get owns(customer-name) set override: name
    Then transaction commits; fails
    When connection open schema transaction for database: typedb
    When <root-type>(<subtype-name>) set owns: name
    When <root-type>(<subtype-name>) get owns(customer-name) set override: name
    Then transaction commits; fails
    When connection open schema transaction for database: typedb
    When <root-type>(<subtype-name>) get owns(customer-name) set override: name
    When <root-type>(<subtype-name-2>) set owns: customer-name
    Then <root-type>(<subtype-name-2>) set owns: name; fails
    Then <root-type>(<subtype-name-2>) get owns(customer-name) set override: name; fails
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
      | relation  | description    | registration | long       |

  Scenario Outline: <root-type> types can override inherited owns multiple times
    When create attribute type: name
    When attribute(name) set value type: <value-type>
    When attribute(name) set annotation: @abstract
    When create attribute type: first-name
    When attribute(first-name) set supertype: name
    When create attribute type: second-name
    When attribute(second-name) set supertype: name
    When <root-type>(<supertype-name>) set owns: name
    Then <root-type>(<supertype-name>) get owns contain:
      | name |
    When <root-type>(<subtype-name>) set owns: first-name
    When <root-type>(<subtype-name>) set owns: second-name
    When <root-type>(<subtype-name>) get owns(first-name) set override: name
    When <root-type>(<subtype-name>) get owns(second-name) set override: name
    Then <root-type>(<subtype-name>) get owns contain:
      | first-name  |
      | second-name |
    Then <root-type>(<subtype-name>) get owns do not contain:
      | name |
    When transaction commits
    When connection open read transaction for database: typedb
    Then <root-type>(<subtype-name>) get owns contain:
      | first-name  |
      | second-name |
    Then <root-type>(<subtype-name>) get owns do not contain:
      | name |
    Examples:
      | root-type | supertype-name | subtype-name | value-type |
      | entity    | person         | customer     | string     |
      | relation  | description    | registration | long       |

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
    Then attribute(username) get annotations do not contain: @abstract
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
      | double        | datetime-tz  |
      | decimal       | datetime     |
      | string        | duration     |
      | boolean       | long         |
      | date          | decimal      |
      | datetime-tz   | double       |
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
      | date          |
      | datetime      |
      | datetime-tz   |
      | duration      |
      | custom-struct |

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
      | value-type    | value-type-2 |
      | long          | string       |
      | double        | datetime-tz  |
      | custom-struct | decimal      |

     # TODO: Move to thing-feature or schema/data-validation?
#  Scenario: Ownership can change ordering if it does not have instances even if its owner has instances for relation type
#    When create attribute type: name
#    When attribute(name) set value type: double
#    When create relation type: parentship
#    When relation(parentship) create role: parent
#    When relation(parentship) set owns: name
#    When create entity type: person
#    When entity(person) set plays: email
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
#    When entity(person) set plays: email
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
      | date          |
      | datetime      |
      | datetime-tz   |
      | duration      |
      | custom-struct |

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

  Scenario: Relation type cannot unset @abstract annotation if it has ordered ownership of abstract attribute
    When create relation type: reference
    When relation(reference) create role: target
    When relation(reference) set annotation: @abstract
    When create attribute type: name
    When attribute(name) set annotation: @abstract
    When relation(reference) set owns: name
    When relation(reference) get owns contain:
      | name |
    When relation(reference) get owns(name) set ordering: ordered
    Then relation(reference) unset annotation: @abstract; fails
    Then relation(reference) get annotations contain: @abstract
    Then relation(reference) get owns(name) get ordering: ordered
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(reference) get owns contain:
      | name |
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

  Scenario Outline: <root-type> can set ordering (but only the same) for ownership after setting an override or an annotation
    When create attribute type: name
    When attribute(name) set value type: <value-type>
    When attribute(name) set annotation: @abstract
    When create attribute type: surname
    When attribute(surname) set supertype: name
    When <root-type>(<supertype-name>) set owns: name
    When <root-type>(<subtype-name>) set owns: surname
    When <root-type>(<subtype-name>) get owns(surname) set override: name
    When <root-type>(<subtype-name>) get owns(surname) set annotation: @card(0..1)
    Then <root-type>(<subtype-name>) get owns(surname) set ordering: ordered; fails
    When <root-type>(<supertype-name>) get owns(name) set ordering: ordered
    When <root-type>(<subtype-name>) get owns(surname) set ordering: ordered
    Then <root-type>(<subtype-name>) get owns(surname) get ordering: ordered
    When transaction commits
    When connection open read transaction for database: typedb
    Then <root-type>(<supertype-name>) get owns(name) get ordering: ordered
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
#    Then <root-type>(<type-name>) get owns contain:
#      | name |
#    Then <root-type>(<type-name>) get owns(name) get ordering: ordered
#    Examples:
#      | root-type | type-name   | value-type | value           |
#      | entity    | person      | long       | 1               |
#      | entity    | person      | double     | 1.0             |
#      | entity    | person      | decimal    | 1.0             |
#      | entity    | person      | string     | "alice"         |
#      | entity    | person      | boolean    | true            |
#      | entity    | person      | date       | 2024-05-04      |
#      | entity    | person      | datetime   | 2024-05-04      |
#      | entity    | person      | datetime-tz | 2024-05-04+0010 |
#      | entity    | person      | duration   | P1Y             |
#      | relation  | description | long       | 1               |
#      | relation  | description | double     | 1.0             |
#      | relation  | description | decimal    | 1.0             |
#      | relation  | description | string     | "alice"         |
#      | relation  | description | boolean    | true            |
#      | relation  | description | date       | 2024-05-04      |
#      | relation  | description | datetime   | 2024-05-04      |
#      | relation  | description | datetime-tz | 2024-05-04+0010 |
#      | relation  | description | duration   | P1Y             |

  Scenario Outline: <root-type> types can re-override ordered ownership
    When create attribute type: email
    When attribute(email) set value type: <value-type>
    When attribute(email) set annotation: @abstract
    When create attribute type: work-email
    When attribute(work-email) set supertype: email
    When <root-type>(<supertype-name>) set annotation: @abstract
    When <root-type>(<supertype-name>) set owns: email
    When <root-type>(<supertype-name>) get owns(email) set ordering: ordered
    Then <root-type>(<supertype-name>) get owns(email) get ordering: ordered
    When <root-type>(<subtype-name>) set annotation: @abstract
    When <root-type>(<subtype-name>) set owns: work-email
    Then <root-type>(<subtype-name>) get owns(work-email) set override: email; fails
    When <root-type>(<subtype-name>) get owns(work-email) set ordering: ordered
    When <root-type>(<subtype-name>) get owns(work-email) set override: email
    Then <root-type>(<subtype-name>) get owns overridden(work-email) get label: email
    Then <root-type>(<subtype-name>) get owns(work-email) get ordering: ordered
    When transaction commits
    When connection open schema transaction for database: typedb
    When <root-type>(<subtype-name>) set owns: work-email
    Then <root-type>(<subtype-name>) get owns(work-email) set override: email; fails
    When <root-type>(<subtype-name>) get owns(work-email) set ordering: ordered
    When <root-type>(<subtype-name>) get owns(work-email) set override: email
    Then <root-type>(<subtype-name>) get owns overridden(work-email) get label: email
    Then <root-type>(<subtype-name>) get owns(work-email) get ordering: ordered
    Examples:
      | root-type | supertype-name | subtype-name | value-type |
      | entity    | person         | customer     | long       |
      | relation  | description    | registration | string     |

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
      | entity    | person         | customer     | subscriber     | datetime-tz   |
      | entity    | person         | customer     | subscriber     | custom-struct |
      | relation  | description    | registration | profile        | decimal       |
      | relation  | description    | registration | profile        | string        |

  Scenario Outline: <root-type> types cannot redeclare overridden owns as owns
    When create attribute type: name
    When attribute(name) set value type: <value-type>
    When attribute(name) set annotation: @abstract
    When create attribute type: customer-name
    When attribute(customer-name) set supertype: name
    When <root-type>(<supertype-name>) set annotation: @abstract
    When <root-type>(<supertype-name>) set owns: name
    When <root-type>(<supertype-name>) get owns(name) set ordering: ordered
    When <root-type>(<subtype-name>) set owns: customer-name
    When <root-type>(<subtype-name>) get owns(customer-name) set ordering: ordered
    When <root-type>(<subtype-name>) get owns(customer-name) set override: name
    When <root-type>(<subtype-name-2>) set supertype: <subtype-name>
    Then <root-type>(<subtype-name-2>) set owns: name; fails
    When <root-type>(<subtype-name-2>) set owns: customer-name
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
      | relation  | description    | registration | long       |

  Scenario Outline: Ownerships can set override only if ordering matches for <root-type>
    When create attribute type: other
    When attribute(other) set annotation: @abstract
    When attribute(other) set value type: <value-type>
    When <root-type>(<supertype-name>) set annotation: @abstract
    When <root-type>(<supertype-name>) set owns: other
    When <root-type>(<supertype-name>) get owns(other) set ordering: ordered
    When create attribute type: name
    When attribute(name) set annotation: @abstract
    When <root-type>(<subtype-name>) set supertype: <supertype-name>
    When <root-type>(<subtype-name>) set annotation: @abstract
    When <root-type>(<subtype-name>) set owns: name
    When <root-type>(<subtype-name>) get owns(name) set ordering: ordered
    When attribute(name) set supertype: other
    When <root-type>(<subtype-name>) get owns(name) set override: other
    Then <root-type>(<subtype-name>) get owns overridden(name) get label: other
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<subtype-name>) get owns overridden(name) get label: other
    When create attribute type: surname
    When attribute(surname) set annotation: @abstract
    When attribute(surname) set value type: <value-type>
    When <root-type>(<supertype-name>) set owns: surname
    When <root-type>(<supertype-name>) get owns(surname) set ordering: ordered
    When attribute(name) set supertype: surname
    When <root-type>(<subtype-name>) get owns(name) set override: surname
    Then <root-type>(<subtype-name>) get owns overridden(name) get label: surname
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<subtype-name>) get owns overridden(name) get label: surname
    When attribute(name) set supertype: other
    When <root-type>(<subtype-name>) get owns(name) set override: other
    Then <root-type>(<subtype-name>) get owns overridden(name) get label: other
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<subtype-name>) get owns overridden(name) get label: other
    When <root-type>(<supertype-name>) get owns(surname) set ordering: unordered
    When attribute(name) set supertype: surname
    Then <root-type>(<subtype-name>) get owns(name) set override: surname; fails
    Then <root-type>(<subtype-name>) get owns overridden(name) get label: other
    When <root-type>(<subtype-name>) get owns(name) unset override
    When <root-type>(<subtype-name>) get owns(name) set ordering: unordered
    When <root-type>(<subtype-name>) get owns(name) set override: surname
    Then <root-type>(<subtype-name>) get owns overridden(name) get label: surname
    Then <root-type>(<supertype-name>) get owns(surname) get ordering: unordered
    Then <root-type>(<subtype-name>) get owns(name) get ordering: unordered
    Then <root-type>(<supertype-name>) get owns(other) get ordering: ordered
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<supertype-name>) get owns(surname) get ordering: unordered
    Then <root-type>(<subtype-name>) get owns(name) get ordering: unordered
    Then <root-type>(<supertype-name>) get owns(other) get ordering: ordered
    Then <root-type>(<subtype-name>) get owns overridden(name) get label: surname
    When attribute(name) set supertype: other
    Then <root-type>(<subtype-name>) get owns(name) set override: other; fails
    When <root-type>(<supertype-name>) get owns(other) set ordering: unordered
    When <root-type>(<subtype-name>) get owns(name) set override: other
    Then <root-type>(<supertype-name>) get owns(surname) get ordering: unordered
    Then <root-type>(<subtype-name>) get owns(name) get ordering: unordered
    Then <root-type>(<supertype-name>) get owns(other) get ordering: unordered
    Then <root-type>(<subtype-name>) get owns overridden(name) get label: other
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<supertype-name>) get owns(surname) get ordering: unordered
    Then <root-type>(<subtype-name>) get owns(name) get ordering: unordered
    Then <root-type>(<supertype-name>) get owns(other) get ordering: unordered
    Then <root-type>(<subtype-name>) get owns overridden(name) get label: other
    Examples:
      | root-type | supertype-name | subtype-name | value-type    |
      | entity    | person         | customer     | decimal       |
      | relation  | description    | registration | custom-struct |

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
    When <root-type>(<subtype-name>) get owns(name) set override: literal
    When <root-type>(<subtype-name-2>) set supertype: <subtype-name>
    When <root-type>(<subtype-name-2>) set annotation: @abstract
    When <root-type>(<subtype-name-2>) set owns: surname
    When <root-type>(<subtype-name-2>) get owns(surname) set override: name
    When transaction commits
    When connection open schema transaction for database: typedb
    When <root-type>(<supertype-name>) get owns(literal) set ordering: ordered
    Then transaction commits; fails
    When connection open schema transaction for database: typedb
    Then <root-type>(<subtype-name>) get owns(name) set ordering: ordered; fails
    When transaction closes
    When connection open schema transaction for database: typedb
    Then <root-type>(<subtype-name-2>) get owns(surname) set ordering: ordered; fails
    When transaction closes
    When connection open schema transaction for database: typedb
    When <root-type>(<supertype-name>) get owns(literal) set ordering: ordered
    When <root-type>(<subtype-name>) get owns(name) set ordering: ordered
    Then transaction commits; fails
    When connection open schema transaction for database: typedb
    When <root-type>(<supertype-name>) get owns(literal) set ordering: ordered
    Then <root-type>(<subtype-name-2>) get owns(surname) set ordering: ordered; fails
    When transaction closes
    When connection open schema transaction for database: typedb
    Then <root-type>(<subtype-name>) get owns(name) set ordering: ordered; fails
    When <root-type>(<supertype-name>) get owns(literal) set ordering: ordered
    When <root-type>(<subtype-name>) get owns(name) set ordering: ordered
    When <root-type>(<subtype-name-2>) get owns(surname) set ordering: ordered
    Then <root-type>(<supertype-name>) get owns(literal) get ordering: ordered
    Then <root-type>(<subtype-name>) get owns(name) get ordering: ordered
    Then <root-type>(<subtype-name-2>) get owns(surname) get ordering: ordered
    When transaction commits
    When connection open read transaction for database: typedb
    Then <root-type>(<supertype-name>) get owns(literal) get ordering: ordered
    Then <root-type>(<subtype-name>) get owns(name) get ordering: ordered
    Then <root-type>(<subtype-name-2>) get owns(surname) get ordering: ordered
    When transaction closes
    When connection open schema transaction for database: typedb
    When <root-type>(<supertype-name>) get owns(literal) set ordering: unordered
    Then transaction commits; fails
    When connection open schema transaction for database: typedb
    Then <root-type>(<subtype-name>) get owns(name) set ordering: unordered; fails
    When transaction closes
    When connection open schema transaction for database: typedb
    Then <root-type>(<subtype-name-2>) get owns(surname) set ordering: unordered; fails
    When transaction closes
    When connection open schema transaction for database: typedb
    When <root-type>(<supertype-name>) get owns(literal) set ordering: unordered
    When <root-type>(<subtype-name>) get owns(name) set ordering: unordered
    Then transaction commits; fails
    When connection open schema transaction for database: typedb
    When <root-type>(<supertype-name>) get owns(literal) set ordering: unordered
    Then <root-type>(<subtype-name-2>) get owns(surname) set ordering: unordered; fails
    When transaction closes
    When connection open schema transaction for database: typedb
    Then <root-type>(<subtype-name>) get owns(name) set ordering: unordered; fails
    When transaction closes
    When connection open schema transaction for database: typedb
    When <root-type>(<supertype-name>) get owns(literal) set ordering: unordered
    When <root-type>(<subtype-name>) get owns(name) set ordering: unordered
    When <root-type>(<subtype-name-2>) get owns(surname) set ordering: unordered
    Then <root-type>(<supertype-name>) get owns(literal) get ordering: unordered
    Then <root-type>(<subtype-name>) get owns(name) get ordering: unordered
    Then <root-type>(<subtype-name-2>) get owns(surname) get ordering: unordered
    When transaction commits
    When connection open read transaction for database: typedb
    Then <root-type>(<supertype-name>) get owns(literal) get ordering: unordered
    Then <root-type>(<subtype-name>) get owns(name) get ordering: unordered
    Then <root-type>(<subtype-name-2>) get owns(surname) get ordering: unordered
    Examples:
      | root-type | supertype-name | subtype-name | subtype-name-2 | value-type    |
      | entity    | person         | customer     | subscriber     | decimal       |
      | relation  | description    | registration | profile        | custom-struct |

  Scenario Outline: <root-type> types cannot unset supertype while having owns override
    When create attribute type: name
    When attribute(name) set annotation: @abstract
    When attribute(name) set value type: <value-type>
    When create attribute type: surname
    When attribute(surname) set supertype: name
    When <root-type>(<supertype-name>) set owns: name
    When <root-type>(<subtype-name>) set supertype: <supertype-name>
    When <root-type>(<subtype-name>) set owns: surname
    When <root-type>(<subtype-name>) get owns(surname) set override: name
    Then <root-type>(<subtype-name>) set supertype: <root-type>; fails
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<subtype-name>) set supertype: <root-type>; fails
    When <root-type>(<subtype-name>) get owns(surname) unset override
    When <root-type>(<subtype-name>) set supertype: <root-type>
    Then <root-type>(<subtype-name>) get supertype: <root-type>
    Then <root-type>(<subtype-name>) get owns overridden(surname) does not exist
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<subtype-name>) get supertype: <root-type>
    Then <root-type>(<subtype-name>) get owns overridden(surname) does not exist
    When <root-type>(<subtype-name>) set supertype: <supertype-name>
    When <root-type>(<subtype-name>) unset owns: surname
    When <root-type>(<subtype-name-2>) set owns: surname
    When <root-type>(<subtype-name-2>) set supertype: <subtype-name>
    When <root-type>(<subtype-name-2>) get owns(surname) set override: name
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<subtype-name-2>) set supertype: <root-type>; fails
    When <root-type>(<subtype-name>) set supertype: <root-type>
    Then transaction commits; fails
    When connection open schema transaction for database: typedb
    When <root-type>(<subtype-name-2>) get owns(surname) unset override
    When <root-type>(<subtype-name>) set supertype: <root-type>
    Then <root-type>(<subtype-name>) get supertype: <root-type>
    Then <root-type>(<subtype-name-2>) get owns overridden(surname) does not exist
    When transaction commits
    When connection open read transaction for database: typedb
    Then <root-type>(<subtype-name>) get supertype: <root-type>
    Then <root-type>(<subtype-name-2>) get owns overridden(surname) does not exist
    Examples:
      | root-type | supertype-name | subtype-name | subtype-name-2 | value-type  |
      | entity    | person         | customer     | subscriber     | datetime-tz |
      | relation  | description    | registration | profile        | double      |

  Scenario Outline: Attribute type cannot unset supertype while having <root-type>'s owns override
    When create attribute type: name
    When attribute(name) set annotation: @abstract
    When attribute(name) set value type: <value-type>
    When create attribute type: surname
    When attribute(surname) set annotation: @abstract
    When attribute(surname) set supertype: name
    When <root-type>(<supertype-name>) set owns: name
    When <root-type>(<subtype-name>) set supertype: <supertype-name>
    When <root-type>(<subtype-name>) set owns: surname
    When <root-type>(<subtype-name>) get owns(surname) set override: name
    When transaction commits
    When connection open schema transaction for database: typedb
    When attribute(surname) set supertype: attribute
    Then transaction commits; fails
    When connection open schema transaction for database: typedb
    When <root-type>(<subtype-name>) get owns(surname) unset override
    When attribute(surname) set supertype: attribute
    Then attribute(surname) get supertype: attribute
    Then <root-type>(<subtype-name>) get owns overridden(surname) does not exist
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(surname) get supertype: attribute
    Then <root-type>(<subtype-name>) get owns overridden(surname) does not exist
    When create attribute type: subsurname
    When attribute(subsurname) set supertype: surname
    When <root-type>(<subtype-name>) unset owns: surname
    When <root-type>(<subtype-name>) set owns: subsurname
    Then <root-type>(<subtype-name>) get owns(subsurname) set override: name; fails
    When attribute(surname) set supertype: name
    When <root-type>(<subtype-name>) get owns(subsurname) set override: name
    When transaction commits
    When connection open schema transaction for database: typedb
    When attribute(subsurname) set annotation: @abstract
    When attribute(subsurname) set supertype: attribute
    Then transaction commits; fails
    When connection open schema transaction for database: typedb
    When attribute(surname) set supertype: attribute
    Then transaction commits; fails
    When connection open schema transaction for database: typedb
    When <root-type>(<subtype-name>) get owns(subsurname) unset override
    When attribute(surname) set supertype: attribute
    Then attribute(surname) get supertype: attribute
    Then <root-type>(<subtype-name>) get owns overridden(subsurname) does not exist
    When attribute(subsurname) set annotation: @abstract
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(surname) get supertype: attribute
    Then <root-type>(<subtype-name>) get owns overridden(subsurname) does not exist
    Examples:
      | root-type | supertype-name | subtype-name | value-type  |
      | entity    | person         | customer     | datetime-tz |
      | relation  | description    | registration | double      |
