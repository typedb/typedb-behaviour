# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

# This file is separated from owns.feature to speed up Rust cucumber execution

#noinspection CucumberUndefinedStep
Feature: Concept Owns Annotations

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
# @annotations common: contain common tests for annotations suitable for **scalar** owns:
# @key, @unique, @subkey, @values, @range, @card, @regex
# DOES NOT test:
# @distinct
########################

  Scenario Outline: <root-type> types can set and unset owns with @<annotation>
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When <root-type>(<type-name>) set owns: custom-attribute
    When <root-type>(<type-name>) get owns(custom-attribute) set annotation: @<annotation>
    Then <root-type>(<type-name>) get owns(custom-attribute) get constraints contain: @<constraint>
    Then <root-type>(<type-name>) get owns(custom-attribute) get declared annotations contain: @<annotation>
    Then <root-type>(<type-name>) get owns(custom-attribute) get declared annotation categories contain: @<annotation-category>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<type-name>) get owns(custom-attribute) get constraints contain: @<constraint>
    Then <root-type>(<type-name>) get owns(custom-attribute) get declared annotations contain: @<annotation>
    Then <root-type>(<type-name>) get owns(custom-attribute) get declared annotation categories contain: @<annotation-category>
    When <root-type>(<type-name>) get owns(custom-attribute) unset annotation: @<annotation-category>
    Then <root-type>(<type-name>) get owns(custom-attribute) get constraints do not contain: @<constraint>
    Then <root-type>(<type-name>) get owns(custom-attribute) get declared annotations do not contain: @<annotation>
    Then <root-type>(<type-name>) get owns(custom-attribute) get declared annotation categories do not contain: @<annotation-category>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<type-name>) get owns(custom-attribute) get constraints do not contain: @<constraint>
    Then <root-type>(<type-name>) get owns(custom-attribute) get declared annotations do not contain: @<annotation>
    Then <root-type>(<type-name>) get owns(custom-attribute) get declared annotation categories do not contain: @<annotation-category>
    When <root-type>(<type-name>) get owns(custom-attribute) set annotation: @<annotation>
    Then <root-type>(<type-name>) get owns(custom-attribute) get constraints contain: @<constraint>
    Then <root-type>(<type-name>) get owns(custom-attribute) get declared annotations contain: @<annotation>
    Then <root-type>(<type-name>) get owns(custom-attribute) get declared annotation categories contain: @<annotation-category>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<type-name>) get owns(custom-attribute) get constraints contain: @<constraint>
    Then <root-type>(<type-name>) get owns(custom-attribute) get declared annotations contain: @<annotation>
    Then <root-type>(<type-name>) get owns(custom-attribute) get declared annotation categories contain: @<annotation-category>
    When <root-type>(<type-name>) unset owns: custom-attribute
    Then <root-type>(<type-name>) get owns is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then <root-type>(<type-name>) get owns is empty
    Examples:
      | root-type | type-name   | annotation       | annotation-category | constraint       | constraint-category | value-type |
      | entity    | person      | key              | key                 | unique           | unique              | string     |
      | entity    | person      | unique           | unique              | unique           | unique              | string     |
#      | entity    | person      | subkey(LABEL)    | subkey              | subkey(LABEL)    | subkey              | string     |
      | entity    | person      | values("1", "2") | values              | values("1", "2") | values              | string     |
      | entity    | person      | range("1".."2")  | range               | range("1".."2")  | range               | string     |
      | entity    | person      | card(1..1)       | card                | card(1..1)       | card                | string     |
      | entity    | person      | regex("\S+")     | regex               | regex("\S+")     | regex               | string     |
      | relation  | description | key              | key                 | unique           | unique              | string     |
      | relation  | description | unique           | unique              | unique           | unique              | string     |
#      | relation  | description | subkey(LABEL)    | subkey              | subkey(LABEL)    | subkey              | string     |
      | relation  | description | values("1", "2") | values              | values("1", "2") | values              | string     |
      | relation  | description | range("1".."2")  | range               | range("1".."2")  | range               | string     |
      | relation  | description | card(1..1)       | card                | card(1..1)       | card                | string     |
      | relation  | description | regex("\S+")     | regex               | regex("\S+")     | regex               | string     |

  Scenario Outline: <root-type> types can have owns with @<annotation> alongside pure owns
    When create attribute type: email
    When attribute(email) set value type: string
    When create attribute type: username
    When attribute(username) set value type: string
    When create attribute type: name
    When attribute(name) set value type: string
    When create attribute type: age
    When attribute(age) set value type: integer
    When <root-type>(<type-name>) set owns: email
    When <root-type>(<type-name>) get owns(email) set annotation: @<annotation>
    When <root-type>(<type-name>) set owns: username
    When <root-type>(<type-name>) get owns(username) set annotation: @<annotation>
    When <root-type>(<type-name>) set owns: name
    When <root-type>(<type-name>) set owns: age
    Then <root-type>(<type-name>) get owns(email) get constraints contain: @<constraint>
    Then <root-type>(<type-name>) get owns(email) get declared annotations contain: @<annotation>
    Then <root-type>(<type-name>) get owns(username) get constraints contain: @<constraint>
    Then <root-type>(<type-name>) get owns(username) get declared annotations contain: @<annotation>
    Then <root-type>(<type-name>) get owns contain:
      | email    |
      | username |
      | name     |
      | age      |
    When transaction commits
    When connection open read transaction for database: typedb
    Then <root-type>(<type-name>) get owns(email) get constraints contain: @<constraint>
    Then <root-type>(<type-name>) get owns(email) get declared annotations contain: @<annotation>
    Then <root-type>(<type-name>) get owns(username) get constraints contain: @<constraint>
    Then <root-type>(<type-name>) get owns(username) get declared annotations contain: @<annotation>
    Then <root-type>(<type-name>) get owns contain:
      | email    |
      | username |
      | name     |
      | age      |
    Examples:
      | root-type | type-name   | annotation       | constraint       |
      | entity    | person      | key              | unique           |
      | entity    | person      | unique           | unique           |
#      | entity    | person      | subkey(LABEL)    |subkey(LABEL)    |
      | entity    | person      | values("1", "2") | values("1", "2") |
      | entity    | person      | range("1".."2")  | range("1".."2")  |
      | entity    | person      | card(1..1)       | card(1..1)       |
      | entity    | person      | regex("\S+")     | regex("\S+")     |
      | relation  | description | key              | unique           |
      | relation  | description | unique           | unique           |
#      | relation  | description | subkey(LABEL)    |subkey(LABEL)    |
      | relation  | description | values("1", "2") | values("1", "2") |
      | relation  | description | range("1".."2")  | range("1".."2")  |
      | relation  | description | card(1..1)       | card(1..1)       |
      | relation  | description | regex("\S+")     | regex("\S+")     |

  Scenario Outline: <root-type> types can unset not set @<annotation> of ownership
    When create attribute type: username
    When attribute(username) set value type: string
    When create attribute type: reference
    When attribute(reference) set value type: string
    When <root-type>(<type-name>) set owns: username
    Then <root-type>(<type-name>) get owns(username) get constraints do not contain: @<constraint>
    Then <root-type>(<type-name>) get owns(username) get declared annotations do not contain: @<annotation>
    When <root-type>(<type-name>) get owns(username) set annotation: @<annotation>
    Then <root-type>(<type-name>) get owns(username) get constraints contain: @<constraint>
    Then <root-type>(<type-name>) get owns(username) get declared annotations contain: @<annotation>
    When <root-type>(<type-name>) set owns: reference
    Then <root-type>(<type-name>) get owns(reference) get constraints do not contain: @<constraint>
    Then <root-type>(<type-name>) get owns(reference) get declared annotations do not contain: @<annotation>
    When <root-type>(<type-name>) get owns(reference) unset annotation: @<annotation-category>
    Then <root-type>(<type-name>) get owns(reference) get constraints do not contain: @<constraint>
    Then <root-type>(<type-name>) get owns(reference) get declared annotations do not contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<type-name>) get owns(username) get constraints contain: @<constraint>
    Then <root-type>(<type-name>) get owns(username) get declared annotations contain: @<annotation>
    Then <root-type>(<type-name>) get owns(reference) get constraints do not contain: @<constraint>
    Then <root-type>(<type-name>) get owns(reference) get declared annotations do not contain: @<annotation>
    When <root-type>(<type-name>) get owns(reference) unset annotation: @<annotation-category>
    Then <root-type>(<type-name>) get owns(reference) get constraints do not contain: @<constraint>
    Then <root-type>(<type-name>) get owns(reference) get declared annotations do not contain: @<annotation>
    Then <root-type>(<type-name>) get owns(username) get constraints contain: @<constraint>
    Then <root-type>(<type-name>) get owns(username) get declared annotations contain: @<annotation>
    When <root-type>(<type-name>) get owns(username) unset annotation: @<annotation-category>
    Then <root-type>(<type-name>) get owns(username) get constraints do not contain: @<constraint>
    Then <root-type>(<type-name>) get owns(username) get declared annotations do not contain: @<annotation>
    When <root-type>(<type-name>) get owns(username) unset annotation: @<annotation-category>
    Then <root-type>(<type-name>) get owns(username) get constraints do not contain: @<constraint>
    Then <root-type>(<type-name>) get owns(username) get declared annotations do not contain: @<annotation>
    When transaction commits
    When connection open read transaction for database: typedb
    Then <root-type>(<type-name>) get owns(username) get constraints do not contain: @<constraint>
    Then <root-type>(<type-name>) get owns(username) get declared annotations is empty
    Then <root-type>(<type-name>) get owns(reference) get constraints do not contain: @<constraint>
    Then <root-type>(<type-name>) get owns(reference) get declared annotations is empty
    Examples:
      | root-type | type-name   | annotation       | annotation-category | constraint       |
      | entity    | person      | key              | key                 | unique           |
      | entity    | person      | unique           | unique              | unique           |
#      | entity    | person      | subkey(LABEL)    | subkey              |subkey(LABEL)    |
      | entity    | person      | values("1", "2") | values              | values("1", "2") |
      | entity    | person      | range("1".."2")  | range               | range("1".."2")  |
      | entity    | person      | card(1..1)       | card                | card(1..1)       |
      | entity    | person      | regex("\S+")     | regex               | regex("\S+")     |
      | relation  | description | key              | key                 | unique           |
      | relation  | description | unique           | unique              | unique           |
#      | relation  | description | subkey(LABEL)    | subkey              |subkey(LABEL)    |
      | relation  | description | values("1", "2") | values              | values("1", "2") |
      | relation  | description | range("1".."2")  | range               | range("1".."2")  |
      | relation  | description | card(1..1)       | card                | card(1..1)       |
      | relation  | description | regex("\S+")     | regex               | regex("\S+")     |

  Scenario Outline: <root-type> types can set and unset @<annotation> of inherited ownership
    When create attribute type: username
    When attribute(username) set value type: string
    When <root-type>(<supertype-name>) set owns: username
    When <root-type>(<supertype-name>) get owns(username) set annotation: @<annotation>
    Then <root-type>(<supertype-name>) get owns(username) get constraints contain: @<constraint>
    Then <root-type>(<supertype-name>) get owns(username) get declared annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get owns(username) get constraints contain: @<constraint>
    Then <root-type>(<subtype-name>) get owns(username) get declared annotations contain: @<annotation>
    When <root-type>(<subtype-name>) get owns(username) unset annotation: @<annotation-category>
    Then <root-type>(<subtype-name>) get owns(username) get constraints do not contain: @<constraint>
    Then <root-type>(<subtype-name>) get owns(username) get declared annotations do not contain: @<annotation>
    Then <root-type>(<supertype-name>) get owns(username) get constraints do not contain: @<constraint>
    Then <root-type>(<supertype-name>) get owns(username) get declared annotations do not contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<subtype-name>) get owns(username) get constraints do not contain: @<constraint>
    Then <root-type>(<subtype-name>) get owns(username) get declared annotations do not contain: @<annotation>
    Then <root-type>(<supertype-name>) get owns(username) get constraints do not contain: @<constraint>
    Then <root-type>(<supertype-name>) get owns(username) get declared annotations do not contain: @<annotation>
    When <root-type>(<subtype-name>) get owns(username) set annotation: @<annotation>
    Then <root-type>(<subtype-name>) get owns(username) get constraints contain: @<constraint>
    Then <root-type>(<subtype-name>) get owns(username) get declared annotations contain: @<annotation>
    Then <root-type>(<supertype-name>) get owns(username) get constraints contain: @<constraint>
    Then <root-type>(<supertype-name>) get owns(username) get declared annotations contain: @<annotation>
    When transaction commits
    When connection open read transaction for database: typedb
    Then <root-type>(<subtype-name>) get owns(username) get constraints contain: @<constraint>
    Then <root-type>(<subtype-name>) get owns(username) get declared annotations contain: @<annotation>
    Then <root-type>(<supertype-name>) get owns(username) get constraints contain: @<constraint>
    Then <root-type>(<supertype-name>) get owns(username) get declared annotations contain: @<annotation>
    Examples:
      | root-type | supertype-name | subtype-name | annotation       | annotation-category | constraint       |
      | entity    | person         | customer     | key              | key                 | unique           |
      | entity    | person         | customer     | unique           | unique              | unique           |
#      | entity    | person         | customer     | subkey(LABEL)    | subkey              | subkey(LABEL)    |
      | entity    | person         | customer     | values("1", "2") | values              | values("1", "2") |
      | entity    | person         | customer     | range("1".."2")  | range               | range("1".."2")  |
      | entity    | person         | customer     | card(1..1)       | card                | card(1..1)       |
      | entity    | person         | customer     | regex("\S+")     | regex               | regex("\S+")     |
      | relation  | description    | registration | key              | key                 | unique           |
      | relation  | description    | registration | unique           | unique              | unique           |
#      | relation  | description    | registration | subkey(LABEL)    | subkey              | subkey(LABEL)    |
      | relation  | description    | registration | values("1", "2") | values              | values("1", "2") |
      | relation  | description    | registration | range("1".."2")  | range               | range("1".."2")  |
      | relation  | description    | registration | card(1..1)       | card                | card(1..1)       |
      | relation  | description    | registration | regex("\S+")     | regex               | regex("\S+")     |

  Scenario Outline: <root-type> types can set and unset @<annotation> of inherited ownership without annotations
    When create attribute type: username
    When attribute(username) set value type: string
    When <root-type>(<supertype-name>) set owns: username
    When <root-type>(<subtype-name>) set owns: username
    Then <root-type>(<supertype-name>) get owns(username) get constraints do not contain: @<constraint>
    Then <root-type>(<supertype-name>) get owns(username) get declared annotations do not contain: @<annotation>
    Then <root-type>(<subtype-name>) get owns(username) get constraints do not contain: @<constraint>
    Then <root-type>(<subtype-name>) get owns(username) get declared annotations do not contain: @<annotation>
    Then <root-type>(<subtype-name>) get owns(username) set annotation: @<annotation>
    Then <root-type>(<supertype-name>) get owns(username) get constraints do not contain: @<constraint>
    Then <root-type>(<supertype-name>) get owns(username) get declared annotations do not contain: @<annotation>
    Then <root-type>(<subtype-name>) get owns(username) get constraints contain: @<constraint>
    Then <root-type>(<subtype-name>) get owns(username) get declared annotations contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<supertype-name>) get owns(username) get constraints do not contain: @<constraint>
    Then <root-type>(<supertype-name>) get owns(username) get declared annotations do not contain: @<annotation>
    Then <root-type>(<subtype-name>) get owns(username) get constraints contain: @<constraint>
    Then <root-type>(<subtype-name>) get owns(username) get declared annotations contain: @<annotation>
    When <root-type>(<subtype-name>) get owns(username) set annotation: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<supertype-name>) get owns(username) get constraints do not contain: @<constraint>
    Then <root-type>(<supertype-name>) get owns(username) get declared annotations do not contain: @<annotation>
    Then <root-type>(<subtype-name>) get owns(username) get constraints contain: @<constraint>
    Then <root-type>(<subtype-name>) get owns(username) get declared annotations contain: @<annotation>
    When <root-type>(<subtype-name>) get owns(username) unset annotation: @<annotation-category>
    Then transaction commits; fails
    When connection open schema transaction for database: typedb
    When <root-type>(<subtype-name>) get owns(username) unset annotation: @<annotation-category>
    When <root-type>(<subtype-name>) unset owns: username
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<supertype-name>) get owns(username) get constraints do not contain: @<constraint>
    Then <root-type>(<supertype-name>) get owns(username) get declared annotations do not contain: @<annotation>
    Then <root-type>(<subtype-name>) get owns(username) get constraints do not contain: @<constraint>
    Then <root-type>(<subtype-name>) get owns(username) get declared annotations do not contain: @<annotation>
    Examples:
      | root-type | supertype-name | subtype-name | annotation       | annotation-category | constraint       |
      | entity    | person         | customer     | key              | key                 | unique           |
      | entity    | person         | customer     | unique           | unique              | unique           |
#      | entity    | person         | customer     | subkey(LABEL)    | subkey              | subkey(LABEL)    |
      | entity    | person         | customer     | values("1", "2") | values              | values("1", "2") |
      | entity    | person         | customer     | range("1".."2")  | range               | range("1".."2")  |
      | entity    | person         | customer     | card(1..1)       | card                | card(1..1)       |
      | entity    | person         | customer     | regex("\S+")     | regex               | regex("\S+")     |
      | relation  | description    | registration | key              | key                 | unique           |
      | relation  | description    | registration | unique           | unique              | unique           |
#      | relation  | description    | registration | subkey(LABEL)    | subkey              | subkey(LABEL)    |
      | relation  | description    | registration | values("1", "2") | values              | values("1", "2") |
      | relation  | description    | registration | range("1".."2")  | range               | range("1".."2")  |
      | relation  | description    | registration | card(1..1)       | card                | card(1..1)       |
      | relation  | description    | registration | regex("\S+")     | regex               | regex("\S+")     |

  Scenario Outline: <root-type> types can set and unset @<annotation> of specialised ownership
    When create attribute type: username
    When attribute(username) set value type: string
    When attribute(username) set annotation: @abstract
    When create attribute type: playername
    When attribute(playername) set supertype: username
    When <root-type>(<supertype-name>) set owns: username
    When <root-type>(<subtype-name>) set owns: playername
    Then <root-type>(<supertype-name>) get constraints for owned attribute(username) do not contain: @<constraint>
    Then <root-type>(<supertype-name>) get owns(username) get constraints do not contain: @<constraint>
    Then <root-type>(<supertype-name>) get owns(username) get declared annotations do not contain: @<annotation>
    Then <root-type>(<subtype-name>) get constraints for owned attribute(playername) do not contain: @<constraint>
    Then <root-type>(<subtype-name>) get owns(playername) get constraints do not contain: @<constraint>
    Then <root-type>(<subtype-name>) get owns(playername) get declared annotations do not contain: @<annotation>
    When <root-type>(<subtype-name>) get owns(playername) set annotation: @<annotation>
    Then <root-type>(<supertype-name>) get constraints for owned attribute(username) do not contain: @<constraint>
    Then <root-type>(<supertype-name>) get owns(username) get constraints do not contain: @<constraint>
    Then <root-type>(<supertype-name>) get owns(username) get declared annotations do not contain: @<annotation>
    Then <root-type>(<subtype-name>) get constraints for owned attribute(playername) contain: @<constraint>
    Then <root-type>(<subtype-name>) get owns(playername) get constraints contain: @<constraint>
    Then <root-type>(<subtype-name>) get owns(playername) get declared annotations contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<supertype-name>) get constraints for owned attribute(username) do not contain: @<constraint>
    Then <root-type>(<supertype-name>) get owns(username) get constraints do not contain: @<constraint>
    Then <root-type>(<supertype-name>) get owns(username) get declared annotations do not contain: @<annotation>
    Then <root-type>(<subtype-name>) get constraints for owned attribute(playername) contain: @<constraint>
    Then <root-type>(<subtype-name>) get owns(playername) get constraints contain: @<constraint>
    Then <root-type>(<subtype-name>) get owns(playername) get declared annotations contain: @<annotation>
    When <root-type>(<subtype-name>) get owns(playername) set annotation: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<supertype-name>) get constraints for owned attribute(username) do not contain: @<constraint>
    Then <root-type>(<supertype-name>) get owns(username) get constraints do not contain: @<constraint>
    Then <root-type>(<supertype-name>) get owns(username) get declared annotations do not contain: @<annotation>
    Then <root-type>(<subtype-name>) get constraints for owned attribute(playername) contain: @<constraint>
    Then <root-type>(<subtype-name>) get owns(playername) get constraints contain: @<constraint>
    Then <root-type>(<subtype-name>) get owns(playername) get declared annotations contain: @<annotation>
    When <root-type>(<subtype-name>) get owns(playername) unset annotation: @<annotation-category>
    Then <root-type>(<supertype-name>) get constraints for owned attribute(username) do not contain: @<constraint>
    Then <root-type>(<supertype-name>) get owns(username) get constraints do not contain: @<constraint>
    Then <root-type>(<supertype-name>) get owns(username) get declared annotations do not contain: @<annotation>
    Then <root-type>(<subtype-name>) get constraints for owned attribute(playername) do not contain: @<constraint>
    Then <root-type>(<subtype-name>) get owns(playername) get constraints do not contain: @<constraint>
    Then <root-type>(<subtype-name>) get owns(playername) get declared annotations do not contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<supertype-name>) get constraints for owned attribute(username) do not contain: @<constraint>
    Then <root-type>(<supertype-name>) get owns(username) get constraints do not contain: @<constraint>
    Then <root-type>(<supertype-name>) get owns(username) get declared annotations do not contain: @<annotation>
    Then <root-type>(<subtype-name>) get constraints for owned attribute(playername) do not contain: @<constraint>
    Then <root-type>(<subtype-name>) get owns(playername) get constraints do not contain: @<constraint>
    Then <root-type>(<subtype-name>) get owns(playername) get declared annotations do not contain: @<annotation>
    Examples:
      | root-type | supertype-name | subtype-name | annotation       | annotation-category | constraint       |
      | entity    | person         | customer     | key              | key                 | unique           |
      | entity    | person         | customer     | unique           | unique              | unique           |
#      | entity    | person         | customer     | subkey(LABEL)    | subkey              |subkey(LABEL)    |
      | entity    | person         | customer     | values("1", "2") | values              | values("1", "2") |
      | entity    | person         | customer     | range("1".."2")  | range               | range("1".."2")  |
      | entity    | person         | customer     | card(1..1)       | card                | card(1..1)       |
      | entity    | person         | customer     | regex("\S+")     | regex               | regex("\S+")     |
      | relation  | description    | registration | key              | key                 | unique           |
      | relation  | description    | registration | unique           | unique              | unique           |
#      | relation  | description    | registration | subkey(LABEL)    | subkey              |subkey(LABEL)    |
      | relation  | description    | registration | values("1", "2") | values              | values("1", "2") |
      | relation  | description    | registration | range("1".."2")  | range               | range("1".."2")  |
      | relation  | description    | registration | card(1..1)       | card                | card(1..1)       |
      | relation  | description    | registration | regex("\S+")     | regex               | regex("\S+")     |

  Scenario Outline: <root-type> types can set and unset @<annotation> of specialised ownership with inherited annotation
    When create attribute type: username
    When attribute(username) set value type: string
    When attribute(username) set annotation: @abstract
    When create attribute type: playername
    When attribute(playername) set supertype: username
    When <root-type>(<supertype-name>) set owns: username
    When <root-type>(<supertype-name>) get owns(username) set annotation: @<annotation>
    When <root-type>(<subtype-name>) set owns: playername
    Then <root-type>(<supertype-name>) get constraints for owned attribute(username) contain: @<constraint>
    Then <root-type>(<supertype-name>) get owns(username) get constraints contain: @<constraint>
    Then <root-type>(<supertype-name>) get owns(username) get declared annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get constraints for owned attribute(playername) contain: @<constraint>
    Then <root-type>(<subtype-name>) get owns(playername) get constraints do not contain: @<constraint>
    Then <root-type>(<subtype-name>) get owns(playername) get declared annotations do not contain: @<annotation>
    Then <root-type>(<subtype-name>) get owns(playername) unset annotation: @<annotation-category>
    Then <root-type>(<subtype-name>) get constraints for owned attribute(playername) contain: @<constraint>
    Then <root-type>(<subtype-name>) get owns(playername) get constraints do not contain: @<constraint>
    Then <root-type>(<subtype-name>) get owns(playername) get declared annotations do not contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<supertype-name>) get constraints for owned attribute(username) contain: @<constraint>
    Then <root-type>(<supertype-name>) get owns(username) get constraints contain: @<constraint>
    Then <root-type>(<supertype-name>) get owns(username) get declared annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get constraints for owned attribute(playername) contain: @<constraint>
    Then <root-type>(<subtype-name>) get owns(playername) get constraints do not contain: @<constraint>
    Then <root-type>(<subtype-name>) get owns(playername) get declared annotations do not contain: @<annotation>
    When <root-type>(<subtype-name>) get owns(playername) set annotation: @<annotation>
    Then <root-type>(<supertype-name>) get constraints for owned attribute(username) contain: @<constraint>
    Then <root-type>(<supertype-name>) get owns(username) get constraints contain: @<constraint>
    Then <root-type>(<supertype-name>) get owns(username) get declared annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get constraints for owned attribute(playername) contain: @<constraint>
    Then <root-type>(<subtype-name>) get owns(playername) get constraints contain: @<constraint>
    Then <root-type>(<subtype-name>) get owns(playername) get declared annotations contain: @<annotation>
    Then transaction commits
    Examples:
      | root-type | supertype-name | subtype-name | annotation       | annotation-category | constraint       |
      | entity    | person         | customer     | key              | key                 | unique           |
      | entity    | person         | customer     | unique           | unique              | unique           |
#      | entity    | person         | customer     | subkey(LABEL)    | subkey              |subkey(LABEL)    |
      | entity    | person         | customer     | values("1", "2") | values              | values("1", "2") |
      | entity    | person         | customer     | range("1".."2")  | range               | range("1".."2")  |
      | entity    | person         | customer     | card(1..1)       | card                | card(1..1)       |
      | entity    | person         | customer     | regex("\S+")     | regex               | regex("\S+")     |
      | relation  | description    | registration | key              | key                 | unique           |
      | relation  | description    | registration | unique           | unique              | unique           |
#      | relation  | description    | registration | subkey(LABEL)    | subkey              |subkey(LABEL)    |
      | relation  | description    | registration | values("1", "2") | values              | values("1", "2") |
      | relation  | description    | registration | range("1".."2")  | range               | range("1".."2")  |
      | relation  | description    | registration | card(1..1)       | card                | card(1..1)       |
      | relation  | description    | registration | regex("\S+")     | regex               | regex("\S+")     |

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
    Then <root-type>(<subtype-name>) get owns(email) get constraints contain: @<constraint>
    Then <root-type>(<subtype-name>) get owns(reference) get constraints contain: @<constraint>
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
    Then <root-type>(<subtype-name>) get owns(email) get constraints contain: @<constraint>
    Then <root-type>(<subtype-name>) get owns(reference) get constraints contain: @<constraint>
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
    Then <root-type>(<subtype-name>) get owns(email) get constraints contain: @<constraint>
    Then <root-type>(<subtype-name>) get owns(reference) get constraints contain: @<constraint>
    Then <root-type>(<subtype-name-2>) get owns(email) get constraints contain: @<constraint>
    Then <root-type>(<subtype-name-2>) get owns(reference) get constraints contain: @<constraint>
    Then <root-type>(<subtype-name-2>) get owns(license) get constraints contain: @<constraint>
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
      | root-type | supertype-name | subtype-name | subtype-name-2 | annotation       | constraint       |
      | entity    | person         | customer     | subscriber     | key              | unique           |
      | entity    | person         | customer     | subscriber     | unique           | unique           |
#      | entity    | person         | customer     | subscriber     | subkey(LABEL)    |subkey(LABEL)    |
      | entity    | person         | customer     | subscriber     | values("1", "2") | values("1", "2") |
      | entity    | person         | customer     | subscriber     | range("1".."2")  | range("1".."2")  |
      | entity    | person         | customer     | subscriber     | card(1..1)       | card(1..1)       |
      | entity    | person         | customer     | subscriber     | regex("\S+")     | regex("\S+")     |
      | relation  | description    | registration | profile        | key              | unique           |
      | relation  | description    | registration | profile        | unique           | unique           |
#      | relation  | description    | registration | profile        | subkey(LABEL)    |subkey(LABEL)    |
      | relation  | description    | registration | profile        | values("1", "2") | values("1", "2") |
      | relation  | description    | registration | profile        | range("1".."2")  | range("1".."2")  |
      | relation  | description    | registration | profile        | card(1..1)       | card(1..1)       |
      | relation  | description    | registration | profile        | regex("\S+")     | regex("\S+")     |

  Scenario Outline: <root-type> types can redeclare owns with @<annotation>s as owns with @<annotation>s
    When create attribute type: name
    When attribute(name) set value type: <value-type>
    When create attribute type: email
    When attribute(email) set value type: <value-type>
    When <root-type>(<type-name>) set owns: name
    When <root-type>(<type-name>) get owns(name) set annotation: @<annotation>
    Then <root-type>(<type-name>) get owns(name) get constraints contain: @<constraint>
    When <root-type>(<type-name>) set owns: email
    When <root-type>(<type-name>) get owns(email) set annotation: @<annotation>
    Then <root-type>(<type-name>) get owns(email) get constraints contain: @<constraint>
    Then <root-type>(<type-name>) set owns: name
    Then <root-type>(<type-name>) get owns(name) set annotation: @<annotation>
    Then <root-type>(<type-name>) get owns(name) get constraints contain: @<constraint>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<type-name>) get owns(name) get constraints contain: @<constraint>
    Then <root-type>(<type-name>) set owns: email
    Then <root-type>(<type-name>) get owns(email) set annotation: @<annotation>
    Then <root-type>(<type-name>) get owns(email) get constraints contain: @<constraint>
    Examples:
      | root-type | type-name   | annotation       | constraint       | value-type |
      | entity    | person      | key              | unique           | string     |
      | entity    | person      | unique           | unique           | string     |
#      | entity    | person      | subkey(LABEL)    | subkey(LABEL)    | string     |
      | entity    | person      | values("1", "2") | values("1", "2") | string     |
      | entity    | person      | range("1".."2")  | range("1".."2")  | string     |
      | entity    | person      | card(1..1)       | card(1..1)       | string     |
      | entity    | person      | regex("\S+")     | regex("\S+")     | string     |
      | relation  | description | key              | unique           | string     |
      | relation  | description | unique           | unique           | string     |
#      | relation  | description | subkey(LABEL)    | subkey(LABEL)    | string     |
      | relation  | description | values("1", "2") | values("1", "2") | string     |
      | relation  | description | range("1".."2")  | range("1".."2")  | string     |
      | relation  | description | card(1..1)       | card(1..1)       | string     |
      | relation  | description | regex("\S+")     | regex("\S+")     | string     |

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
    Then <root-type>(<type-name>) get owns(name) get constraints contain: @<constraint>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<type-name>) set owns: email
    Then <root-type>(<type-name>) get owns(email) get constraints do not contain: @<constraint>
    When <root-type>(<type-name>) get owns(email) set annotation: @<annotation>
    Then <root-type>(<type-name>) get owns(email) get constraints contain: @<constraint>
    Then <root-type>(<type-name>) get owns(address) get constraints do not contain: @<constraint>
    When <root-type>(<type-name>) get owns(address) set annotation: @<annotation>
    Then <root-type>(<type-name>) get owns(address) get constraints contain: @<constraint>
    Examples:
      | root-type | type-name   | annotation       | constraint       | value-type |
      | entity    | person      | key              | unique           | string     |
      | entity    | person      | unique           | unique           | string     |
#      | entity    | person      | subkey(LABEL)    | subkey(LABEL)    | string     |
      | entity    | person      | values("1", "2") | values("1", "2") | string     |
      | entity    | person      | range("1".."2")  | range("1".."2")  | string     |
      | entity    | person      | card(1..1)       | card(1..1)       | string     |
      | entity    | person      | regex("\S+")     | regex("\S+")     | string     |
      | relation  | description | key              | unique           | string     |
      | relation  | description | unique           | unique           | string     |
#      | relation  | description | subkey(LABEL)    | subkey(LABEL)    | string     |
      | relation  | description | values("1", "2") | values("1", "2") | string     |
      | relation  | description | range("1".."2")  | range("1".."2")  | string     |
      | relation  | description | card(1..1)       | card(1..1)       | string     |
      | relation  | description | regex("\S+")     | regex("\S+")     | string     |

  Scenario Outline: <root-type> types can redeclare owns and save its @<annotation>
    When create attribute type: name
    When attribute(name) set value type: <value-type>
    When create attribute type: email
    When attribute(email) set value type: <value-type>
    When <root-type>(<type-name>) set owns: name
    When <root-type>(<type-name>) get owns(name) set annotation: @<annotation>
    Then <root-type>(<type-name>) get owns(name) get constraints contain: @<constraint>
    Then <root-type>(<type-name>) get owns(name) get declared annotations contain: @<annotation>
    When <root-type>(<type-name>) set owns: email
    When <root-type>(<type-name>) get owns(email) set annotation: @<annotation>
    Then <root-type>(<type-name>) get owns(email) get constraints contain: @<constraint>
    Then <root-type>(<type-name>) get owns(email) get declared annotations contain: @<annotation>
    Then <root-type>(<type-name>) set owns: name
    Then <root-type>(<type-name>) get owns(name) get constraints contain: @<constraint>
    Then <root-type>(<type-name>) get owns(name) get declared annotations contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<type-name>) get owns(email) get constraints contain: @<constraint>
    Then <root-type>(<type-name>) get owns(email) get declared annotations contain: @<annotation>
    When <root-type>(<type-name>) set owns: email
    Then <root-type>(<type-name>) get owns(email) get constraints contain: @<constraint>
    Then <root-type>(<type-name>) get owns(email) get declared annotations contain: @<annotation>
    Examples:
      | root-type | type-name   | annotation       | constraint       | value-type |
      | entity    | person      | key              | unique           | string     |
      | entity    | person      | unique           | unique           | string     |
#      | entity    | person      | subkey(LABEL)    | subkey(LABEL)    | string     |
      | entity    | person      | values("1", "2") | values("1", "2") | string     |
      | entity    | person      | range("1".."2")  | range("1".."2")  | string     |
      | entity    | person      | card(1..1)       | card(1..1)       | string     |
      | entity    | person      | regex("\S+")     | regex("\S+")     | string     |
      | relation  | description | key              | unique           | string     |
      | relation  | description | unique           | unique           | string     |
#      | relation  | description | subkey(LABEL)    | subkey(LABEL)    | string     |
      | relation  | description | values("1", "2") | values("1", "2") | string     |
      | relation  | description | range("1".."2")  | range("1".."2")  | string     |
      | relation  | description | card(1..1)       | card(1..1)       | string     |
      | relation  | description | regex("\S+")     | regex("\S+")     | string     |

  Scenario Outline: <root-type> types can specialise inherited pure owns as owns with @<annotation>s
    When create attribute type: name
    When attribute(name) set value type: <value-type>
    When attribute(name) set annotation: @abstract
    When create attribute type: username
    When attribute(username) set supertype: name
    When <root-type>(<supertype-name>) set annotation: @abstract
    When <root-type>(<supertype-name>) set owns: name
    When <root-type>(<subtype-name>) set owns: username
    When <root-type>(<subtype-name>) get owns(username) set annotation: @<annotation>
    Then <root-type>(<subtype-name>) get owns contain:
      | username |
      | name     |
    Then <root-type>(<supertype-name>) get owns(name) get constraints do not contain: @<constraint>
    Then <root-type>(<supertype-name>) get owns(name) get declared annotations do not contain: @<annotation>
    Then <root-type>(<subtype-name>) get owns(username) get constraints contain: @<constraint>
    Then <root-type>(<subtype-name>) get owns(username) get declared annotations contain: @<annotation>
    When transaction commits
    When connection open read transaction for database: typedb
    Then <root-type>(<subtype-name>) get owns contain:
      | username |
      | name     |
    Then <root-type>(<supertype-name>) get owns(name) get constraints do not contain: @<constraint>
    Then <root-type>(<supertype-name>) get owns(name) get declared annotations do not contain: @<annotation>
    Then <root-type>(<subtype-name>) get owns(username) get constraints contain: @<constraint>
    Then <root-type>(<subtype-name>) get owns(username) get declared annotations contain: @<annotation>
    Examples:
      | root-type | supertype-name | subtype-name | annotation       | constraint       | value-type |
      | entity    | person         | customer     | key              | unique           | string     |
      | entity    | person         | customer     | unique           | unique           | string     |
#      | entity    | person         | customer     | subkey(LABEL)    | subkey(LABEL)    | string     |
      | entity    | person         | customer     | values("1", "2") | values("1", "2") | string     |
      | entity    | person         | customer     | range("1".."2")  | range("1".."2")  | string     |
      | entity    | person         | customer     | card(1..1)       | card(1..1)       | string     |
      | entity    | person         | customer     | regex("\S+")     | regex("\S+")     | string     |
      | relation  | description    | registration | key              | unique           | string     |
      | relation  | description    | registration | unique           | unique           | string     |
#      | relation  | description    | registration | subkey(LABEL)    | subkey(LABEL)    | string     |
      | relation  | description    | registration | values("1", "2") | values("1", "2") | string     |
      | relation  | description    | registration | range("1".."2")  | range("1".."2")  | string     |
      | relation  | description    | registration | card(1..1)       | card(1..1)       | string     |
      | relation  | description    | registration | regex("\S+")     | regex("\S+")     | string     |

  Scenario Outline: <root-type> types can re-specialise owns with <annotation>s
    When create attribute type: email
    When attribute(email) set value type: <value-type>
    When attribute(email) set annotation: @abstract
    When create attribute type: work-email
    When attribute(work-email) set supertype: email
    When <root-type>(<supertype-name>) set annotation: @abstract
    When <root-type>(<supertype-name>) set owns: email
    When <root-type>(<supertype-name>) get owns(email) set annotation: @<annotation>
    When <root-type>(<subtype-name>) set annotation: @abstract
    Then <root-type>(<subtype-name>) get owns contain:
      | email |
    Then <root-type>(<subtype-name>) get owns(email) get declared annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get owns(email) get constraints contain: @<constraint>
    Then <root-type>(<subtype-name>) get constraints for owned attribute(email) contain: @<constraint>
    When <root-type>(<subtype-name>) set owns: work-email
    Then <root-type>(<subtype-name>) get owns(work-email) get declared annotations do not contain: @<annotation>
    Then <root-type>(<subtype-name>) get owns(work-email) get constraints do not contain: @<constraint>
    Then <root-type>(<subtype-name>) get constraints for owned attribute(work-email) contain: @<constraint>
    When transaction commits
    When connection open schema transaction for database: typedb
    When <root-type>(<subtype-name>) set owns: work-email
    Then <root-type>(<subtype-name>) get owns(work-email) get declared annotations do not contain: @<annotation>
    Then <root-type>(<subtype-name>) get owns(work-email) get constraints do not contain: @<constraint>
    Then <root-type>(<subtype-name>) get constraints for owned attribute(work-email) contain: @<constraint>
    When transaction commits
    When connection open read transaction for database: typedb
    Then <root-type>(<subtype-name>) get owns(work-email) get declared annotations do not contain: @<annotation>
    Then <root-type>(<subtype-name>) get owns(work-email) get constraints do not contain: @<constraint>
    Then <root-type>(<subtype-name>) get constraints for owned attribute(work-email) contain: @<constraint>
    Examples:
      | root-type | supertype-name | subtype-name | annotation       | constraint       | value-type |
      | entity    | person         | customer     | key              | unique           | string     |
      | entity    | person         | customer     | unique           | unique           | string     |
#      | entity    | person         | customer     | subkey(LABEL)    | subkey(LABEL)    | string     |
      | entity    | person         | customer     | values("1", "2") | values("1", "2") | string     |
      | entity    | person         | customer     | range("1".."2")  | range("1".."2")  | string     |
      | entity    | person         | customer     | card(1..1)       | card(1..1)       | string     |
      | entity    | person         | customer     | regex("\S+")     | regex("\S+")     | string     |
      | relation  | description    | registration | key              | unique           | string     |
      | relation  | description    | registration | unique           | unique           | string     |
#      | relation  | description    | registration | subkey(LABEL)    | subkey(LABEL)    | string     |
      | relation  | description    | registration | values("1", "2") | values("1", "2") | string     |
      | relation  | description    | registration | range("1".."2")  | range("1".."2")  | string     |
      | relation  | description    | registration | card(1..1)       | card(1..1)       | string     |
      | relation  | description    | registration | regex("\S+")     | regex("\S+")     | string     |

  Scenario Outline: <root-type> types cannot redeclare inherited owns as owns with @<annotation> without specialising
    When create attribute type: name
    When attribute(name) set value type: <value-type>
    When attribute(name) set annotation: @abstract
    When <root-type>(<supertype-name>) set owns: name
    When <root-type>(<subtype-name-2>) set supertype: <subtype-name>
    When transaction commits
    When connection open schema transaction for database: typedb
    When <root-type>(<subtype-name>) set owns: name
    Then transaction commits; fails
    When connection open schema transaction for database: typedb
    When <root-type>(<subtype-name>) set owns: name
    When <root-type>(<subtype-name>) get owns(name) set annotation: @<annotation>
    Then transaction commits
    When connection open schema transaction for database: typedb
    When create attribute type: surname
    When attribute(surname) set supertype: name
    When <root-type>(<subtype-name>) set owns: surname
    When <root-type>(<subtype-name>) get owns(surname) set annotation: @<annotation>
    Then <root-type>(<subtype-name>) get owns(surname) get label: surname
    Then <root-type>(<supertype-name>) get constraints for owned attribute(name) do not contain: @<constraint>
    Then <root-type>(<supertype-name>) get owns(name) get constraints do not contain: @<constraint>
    When <root-type>(<subtype-name>) get owns(surname) set annotation: @<annotation>
    Then <root-type>(<subtype-name>) get constraints for owned attribute(surname) contain: @<constraint>
    Then <root-type>(<subtype-name>) get owns(surname) get constraints contain: @<constraint>
    Then <root-type>(<subtype-name>) get constraints for owned attribute(name) contain: @<constraint>
    Then <root-type>(<supertype-name>) get constraints for owned attribute(name) do not contain: @<constraint>
    Then <root-type>(<supertype-name>) get owns(name) get constraints do not contain: @<constraint>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<subtype-name>) get constraints for owned attribute(surname) contain: @<constraint>
    Then <root-type>(<subtype-name>) get owns(surname) get constraints contain: @<constraint>
    Then <root-type>(<subtype-name>) get constraints for owned attribute(name) contain: @<constraint>
    Then <root-type>(<supertype-name>) get constraints for owned attribute(name) do not contain: @<constraint>
    Then <root-type>(<supertype-name>) get owns(name) get constraints do not contain: @<constraint>
    Then <root-type>(<subtype-name-2>) get constraints for owned attribute(surname) contain: @<constraint>
    Then <root-type>(<subtype-name-2>) get owns(surname) get constraints contain: @<constraint>
    When <root-type>(<subtype-name-2>) set owns: surname
    Then <root-type>(<subtype-name-2>) get constraints for owned attribute(surname) contain: @<constraint>
    Then <root-type>(<subtype-name-2>) get owns(surname) get constraints do not contain: @<constraint>
    Then <root-type>(<subtype-name-2>) get owns(surname) get declared annotations do not contain: @<annotation>
    When <root-type>(<subtype-name-2>) get owns(surname) set annotation: @<annotation>
    Then <root-type>(<subtype-name-2>) get constraints for owned attribute(surname) contain: @<constraint>
    Then <root-type>(<subtype-name-2>) get owns(surname) get constraints contain: @<constraint>
    Then <root-type>(<subtype-name>) get owns(surname) get constraints contain: @<constraint>
    Then <root-type>(<subtype-name-2>) get owns(surname) get declared annotations contain: @<annotation>
    Then transaction commits; fails
    When connection open schema transaction for database: typedb
    When <root-type>(<subtype-name-2>) set owns: surname
    Then transaction commits; fails
    Examples:
      | root-type | supertype-name | subtype-name | subtype-name-2 | annotation       | constraint       | value-type |
      | entity    | person         | customer     | subscriber     | key              | unique           | string     |
      | entity    | person         | customer     | subscriber     | unique           | unique           | string     |
#      | entity    | person         | customer     | subscriber     | subkey(LABEL)    | subkey(LABEL)    | string     |
      | entity    | person         | customer     | subscriber     | values("1", "2") | values("1", "2") | string     |
      | entity    | person         | customer     | subscriber     | range("1".."2")  | range("1".."2")  | string     |
      | entity    | person         | customer     | subscriber     | card(1..1)       | card(1..1)       | string     |
      | entity    | person         | customer     | subscriber     | regex("\S+")     | regex("\S+")     | string     |
      | relation  | description    | registration | profile        | key              | unique           | string     |
      | relation  | description    | registration | profile        | unique           | unique           | string     |
#      | relation  | description    | registration | profile        | subkey(LABEL)    | subkey(LABEL)    | string     |
      | relation  | description    | registration | profile        | values("1", "2") | values("1", "2") | string     |
      | relation  | description    | registration | profile        | range("1".."2")  | range("1".."2")  | string     |
      | relation  | description    | registration | profile        | card(1..1)       | card(1..1)       | string     |
      | relation  | description    | registration | profile        | regex("\S+")     | regex("\S+")     | string     |

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
    When connection open schema transaction for database: typedb
    Then <root-type>(<subtype-name>) set owns: email
    Then <root-type>(<subtype-name>) get owns(email) set annotation: @<annotation>
    Then transaction commits; fails
    Examples:
      | root-type | supertype-name | subtype-name | annotation       | value-type |
      | entity    | person         | customer     | key              | string     |
      | entity    | person         | customer     | unique           | string     |
#      | entity    | person         | customer     | subkey(LABEL)    | string     |
      | entity    | person         | customer     | values("1", "2") | string     |
      | entity    | person         | customer     | range("1".."2")  | string     |
      | entity    | person         | customer     | card(1..1)       | string     |
      | entity    | person         | customer     | regex("\S+")     | string     |
      | relation  | description    | registration | key              | string     |
      | relation  | description    | registration | unique           | string     |
#      | relation  | description    | registration | subkey(LABEL)    | string     |
      | relation  | description    | registration | values("1", "2") | string     |
      | relation  | description    | registration | range("1".."2")  | string     |
      | relation  | description    | registration | card(1..1)       | string     |
      | relation  | description    | registration | regex("\S+")     | string     |

  Scenario Outline: <root-type> types cannot redeclare inherited owns with @<annotation>
    When create attribute type: email
    When attribute(email) set value type: <value-type>
    When attribute(email) set annotation: @abstract
    When create attribute type: customer-email
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
#      | entity    | person         | customer     | subscriber     | subkey(LABEL)    | string     |
      | entity    | person         | customer     | subscriber     | values("1", "2") | string     |
      | entity    | person         | customer     | subscriber     | range("1".."2")  | string     |
      | entity    | person         | customer     | subscriber     | card(1..1)       | string     |
      | entity    | person         | customer     | subscriber     | regex("\S+")     | string     |
      | relation  | description    | registration | profile        | key              | string     |
      | relation  | description    | registration | profile        | unique           | string     |
#      | relation  | description    | registration | profile        | subkey(LABEL)    | string     |
      | relation  | description    | registration | profile        | values("1", "2") | string     |
      | relation  | description    | registration | profile        | range("1".."2")  | string     |
      | relation  | description    | registration | profile        | card(1..1)       | string     |
      | relation  | description    | registration | profile        | regex("\S+")     | string     |

  Scenario Outline: <root-type> types can redeclare specialised owns with @<annotation>s
    When create attribute type: email
    When attribute(email) set value type: <value-type>
    When attribute(email) set annotation: @abstract
    When create attribute type: customer-email
    When attribute(customer-email) set supertype: email
    When <root-type>(<supertype-name>) set annotation: @abstract
    When <root-type>(<supertype-name>) set owns: email
    When <root-type>(<supertype-name>) get owns(email) set annotation: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    When <root-type>(<subtype-name>) set owns: customer-email
    When <root-type>(<subtype-name-2>) set supertype: <subtype-name>
    Then <root-type>(<subtype-name-2>) set owns: customer-email
    Then transaction commits; fails
    When connection open schema transaction for database: typedb
    When <root-type>(<subtype-name>) set owns: customer-email
    When <root-type>(<subtype-name-2>) set supertype: <subtype-name>
    Then <root-type>(<subtype-name-2>) set owns: customer-email
    Then <root-type>(<subtype-name-2>) get owns(customer-email) set annotation: @<annotation>
    Then transaction commits
    Examples:
      | root-type | supertype-name | subtype-name | subtype-name-2 | annotation       | value-type |
      | entity    | person         | customer     | subscriber     | key              | string     |
      | entity    | person         | customer     | subscriber     | unique           | string     |
#      | entity    | person         | customer     | subscriber     | subkey(LABEL)    | string     |
      | entity    | person         | customer     | subscriber     | values("1", "2") | string     |
      | entity    | person         | customer     | subscriber     | range("1".."2")  | string     |
      | entity    | person         | customer     | subscriber     | card(1..1)       | string     |
      | entity    | person         | customer     | subscriber     | regex("\S+")     | string     |
      | relation  | description    | registration | profile        | key              | string     |
      | relation  | description    | registration | profile        | unique           | string     |
#      | relation  | description    | registration | profile        | subkey(LABEL)    | string     |
      | relation  | description    | registration | profile        | values("1", "2") | string     |
      | relation  | description    | registration | profile        | range("1".."2")  | string     |
      | relation  | description    | registration | profile        | card(1..1)       | string     |
      | relation  | description    | registration | profile        | regex("\S+")     | string     |

  Scenario Outline: <root-type> types cannot redeclare specialised owns with @<annotation>s on multiple layers
    When create attribute type: email
    When attribute(email) set value type: <value-type>
    When attribute(email) set annotation: @abstract
    When create attribute type: customer-email
    When attribute(customer-email) set supertype: email
    When <root-type>(<supertype-name>) set annotation: @abstract
    When <root-type>(<supertype-name>) set owns: email
    When <root-type>(<supertype-name>) get owns(email) set annotation: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    When <root-type>(<subtype-name>) set owns: customer-email
    When <root-type>(<subtype-name-2>) set supertype: <subtype-name>
    Then <root-type>(<subtype-name-2>) set owns: customer-email
    Then transaction commits; fails
    When connection open schema transaction for database: typedb
    When <root-type>(<subtype-name>) set owns: customer-email
    When <root-type>(<subtype-name>) get owns(customer-email) set annotation: @<annotation>
    When <root-type>(<subtype-name-2>) set supertype: <subtype-name>
    Then <root-type>(<subtype-name-2>) set owns: customer-email
    Then transaction commits; fails
    When connection open schema transaction for database: typedb
    When <root-type>(<subtype-name>) set owns: customer-email
    When <root-type>(<subtype-name>) get owns(customer-email) set annotation: @<annotation>
    When <root-type>(<subtype-name-2>) set supertype: <subtype-name>
    Then <root-type>(<subtype-name-2>) set owns: customer-email
    Then <root-type>(<subtype-name-2>) get owns(customer-email) set annotation: @<annotation>
    Then transaction commits; fails
    When connection open schema transaction for database: typedb
    When <root-type>(<subtype-name>) set owns: customer-email
    When <root-type>(<subtype-name>) get owns(customer-email) set annotation: @<annotation>
    When <root-type>(<subtype-name-2>) set supertype: <subtype-name>
    Then <root-type>(<subtype-name-2>) set owns: email
    Then transaction commits; fails
    When connection open schema transaction for database: typedb
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
#      | entity    | person         | customer     | subscriber     | subkey(LABEL)    | string     |
      | entity    | person         | customer     | subscriber     | values("1", "2") | string     |
      | entity    | person         | customer     | subscriber     | range("1".."2")  | string     |
      | entity    | person         | customer     | subscriber     | card(1..1)       | string     |
      | entity    | person         | customer     | subscriber     | regex("\S+")     | string     |
      | relation  | description    | registration | profile        | key              | string     |
      | relation  | description    | registration | profile        | unique           | string     |
#      | relation  | description    | registration | profile        | subkey(LABEL)    | string     |
      | relation  | description    | registration | profile        | values("1", "2") | string     |
      | relation  | description    | registration | profile        | range("1".."2")  | string     |
      | relation  | description    | registration | profile        | card(1..1)       | string     |
      | relation  | description    | registration | profile        | regex("\S+")     | string     |

  Scenario Outline: <root-type> subtypes can specialise owns with @<annotation>
    When create attribute type: name
    When attribute(name) set value type: <value-type>
    When attribute(name) set annotation: @abstract
    When create attribute type: surname
    When attribute(surname) set supertype: name
    When <root-type>(<supertype-name>) set annotation: @abstract
    When <root-type>(<supertype-name>) set owns: name
    When <root-type>(<supertype-name>) get owns(name) set annotation: @<annotation>
    Then <root-type>(<supertype-name>) get constraints for owned attribute(name) contain: @<constraint>
    Then <root-type>(<supertype-name>) get owns(name) get constraints contain: @<constraint>
    Then <root-type>(<supertype-name>) get owns(name) get declared annotations contain: @<annotation>
    When <root-type>(<subtype-name>) set owns: surname
    Then <root-type>(<subtype-name>) get constraints for owned attribute(surname) contain: @<constraint>
    Then <root-type>(<subtype-name>) get owns(surname) get constraints do not contain: @<constraint>
    Then <root-type>(<subtype-name>) get owns(surname) get declared annotations do not contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<supertype-name>) get owns(name) get constraints contain: @<constraint>
    Then <root-type>(<supertype-name>) get owns(name) get declared annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get constraints for owned attribute(surname) contain: @<constraint>
    Then <root-type>(<subtype-name>) get owns(surname) get constraints do not contain: @<constraint>
    Then <root-type>(<subtype-name>) get owns(surname) get declared annotations do not contain: @<annotation>
    When <root-type>(<subtype-name>) get owns(surname) set annotation: @<annotation>
    Then <root-type>(<subtype-name>) get constraints for owned attribute(surname) contain: @<constraint>
    Then <root-type>(<subtype-name>) get owns(surname) get constraints contain: @<constraint>
    Then <root-type>(<subtype-name>) get owns(surname) get declared annotations contain: @<annotation>
    Then transaction commits
    When connection open schema transaction for database: typedb
    When <root-type>(<supertype-name>) get owns(name) unset annotation: @<annotation-category>
    Then <root-type>(<supertype-name>) get constraints for owned attribute(name) do not contain: @<constraint>
    Then <root-type>(<supertype-name>) get owns(name) get constraints do not contain: @<constraint>
    Then <root-type>(<supertype-name>) get owns(name) get declared annotations is empty
    Then <root-type>(<subtype-name>) get constraints for owned attribute(surname) contain: @<constraint>
    Then <root-type>(<subtype-name>) get owns(surname) get constraints contain: @<constraint>
    Then <root-type>(<subtype-name>) get owns(surname) get declared annotations contain: @<annotation>
    When transaction commits
    When connection open read transaction for database: typedb
    Then <root-type>(<supertype-name>) get constraints for owned attribute(name) do not contain: @<constraint>
    Then <root-type>(<supertype-name>) get owns(name) get constraints do not contain: @<constraint>
    Then <root-type>(<supertype-name>) get owns(name) get declared annotations is empty
    Then <root-type>(<subtype-name>) get constraints for owned attribute(surname) contain: @<constraint>
    Then <root-type>(<subtype-name>) get owns(surname) get constraints contain: @<constraint>
    Then <root-type>(<subtype-name>) get owns(surname) get declared annotations contain: @<annotation>
    Examples:
      | root-type | supertype-name | subtype-name | annotation       | annotation-category | constraint       | value-type |
      | entity    | person         | customer     | key              | key                 | unique           | string     |
      | entity    | person         | customer     | unique           | unique              | unique           | string     |
#      | entity    | person         | customer     | subkey(LABEL)    | subkey              | subkey(LABEL)    | string     |
      | entity    | person         | customer     | values("1", "2") | values              | values("1", "2") | string     |
      | entity    | person         | customer     | range("1".."2")  | range               | range("1".."2")  | string     |
      | entity    | person         | customer     | card(1..1)       | card                | card(1..1)       | string     |
      | entity    | person         | customer     | regex("\S+")     | regex               | regex("\S+")     | string     |
      | relation  | description    | registration | key              | key                 | unique           | string     |
      | relation  | description    | registration | unique           | unique              | unique           | string     |
#      | relation  | description    | registration | subkey(LABEL)    | subkey              | subkey(LABEL)    | string     |
      | relation  | description    | registration | values("1", "2") | values              | values("1", "2") | string     |
      | relation  | description    | registration | range("1".."2")  | range               | range("1".."2")  | string     |
      | relation  | description    | registration | card(1..1)       | card                | card(1..1)       | string     |
      | relation  | description    | registration | regex("\S+")     | regex               | regex("\S+")     | string     |

  Scenario Outline: <root-type> types can inherit owns with @<annotation>s and pure owns that are subtypes of each other
    When create attribute type: username
    When attribute(username) set value type: string
    When attribute(username) set annotation: @abstract
    When create attribute type: score
    When attribute(score) set value type: string
    When attribute(score) set annotation: @abstract
    When create attribute type: reference
    When attribute(reference) set annotation: @abstract
    When attribute(reference) set supertype: username
    When create attribute type: rating
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
    Then <root-type>(<subtype-name>) get owns(username) get constraints contain: @<constraint>
    Then <root-type>(<subtype-name>) get owns(reference) get constraints contain: @<constraint>
    Then <root-type>(<subtype-name>) get owns(score) get constraints do not contain: @<constraint>
    Then <root-type>(<subtype-name>) get owns(rating) get constraints do not contain: @<constraint>
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
    Then <root-type>(<subtype-name>) get owns(username) get constraints contain: @<constraint>
    Then <root-type>(<subtype-name>) get owns(reference) get constraints contain: @<constraint>
    Then <root-type>(<subtype-name>) get owns(score) get constraints do not contain: @<constraint>
    Then <root-type>(<subtype-name>) get owns(rating) get constraints do not contain: @<constraint>
    When create attribute type: license
    When attribute(license) set supertype: reference
    When create attribute type: points
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
    Then <root-type>(<subtype-name>) get owns(username) get constraints contain: @<constraint>
    Then <root-type>(<subtype-name>) get owns(reference) get constraints contain: @<constraint>
    Then <root-type>(<subtype-name>) get owns(score) get constraints do not contain: @<constraint>
    Then <root-type>(<subtype-name>) get owns(rating) get constraints do not contain: @<constraint>
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
    Then <root-type>(<subtype-name-2>) get owns(username) get constraints contain: @<constraint>
    Then <root-type>(<subtype-name-2>) get owns(reference) get constraints contain: @<constraint>
    Then <root-type>(<subtype-name-2>) get owns(license) get constraints contain: @<constraint>
    Then <root-type>(<subtype-name-2>) get owns(score) get constraints do not contain: @<constraint>
    Then <root-type>(<subtype-name-2>) get owns(rating) get constraints do not contain: @<constraint>
    Then <root-type>(<subtype-name-2>) get owns(points) get constraints do not contain: @<constraint>
    Examples:
      | root-type | supertype-name | subtype-name | subtype-name-2 | annotation       | constraint       |
      | entity    | person         | customer     | subscriber     | key              | unique           |
      | entity    | person         | customer     | subscriber     | unique           | unique           |
#      | entity    | person         | customer     | subscriber     | subkey(LABEL)    | subkey(LABEL)    |
      | entity    | person         | customer     | subscriber     | values("1", "2") | values("1", "2") |
      | entity    | person         | customer     | subscriber     | range("1".."2")  | range("1".."2")  |
      | entity    | person         | customer     | subscriber     | card(1..1)       | card(1..1)       |
      | entity    | person         | customer     | subscriber     | regex("\S+")     | regex("\S+")     |
      | relation  | description    | registration | profile        | key              | unique           |
      | relation  | description    | registration | profile        | unique           | unique           |
#      | relation  | description    | registration | profile        | subkey(LABEL)    | subkey(LABEL)    |
      | relation  | description    | registration | profile        | values("1", "2") | values("1", "2") |
      | relation  | description    | registration | profile        | range("1".."2")  | range("1".."2")  |
      | relation  | description    | registration | profile        | card(1..1)       | card(1..1)       |
      | relation  | description    | registration | profile        | regex("\S+")     | regex("\S+")     |

  Scenario Outline: <root-type> types can specialise inherited owns with @<annotation>s and pure owns
    When create attribute type: username
    When attribute(username) set value type: string
    When create attribute type: email
    When attribute(email) set value type: string
    When attribute(email) set annotation: @abstract
    When create attribute type: name
    When attribute(name) set value type: string
    When attribute(name) set annotation: @abstract
    When create attribute type: age
    When attribute(age) set value type: integer
    When create attribute type: reference
    When attribute(reference) set value type: string
    When attribute(reference) set annotation: @abstract
    When create attribute type: work-email
    When attribute(work-email) set supertype: email
    When create attribute type: nick-name
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
    When <root-type>(<subtype-name>) set owns: rating
    When <root-type>(<subtype-name>) set owns: nick-name
    Then <root-type>(<subtype-name>) get owns contain:
      | username   |
      | reference  |
      | work-email |
      | age        |
      | rating     |
      | nick-name  |
      | email      |
      | name       |
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
    Then <root-type>(<subtype-name>) get owns(username) get constraints contain: @<constraint>
    Then <root-type>(<subtype-name>) get owns(reference) get constraints contain: @<constraint>
    Then <root-type>(<subtype-name>) get owns(work-email) get constraints do not contain: @<constraint>
    Then <root-type>(<subtype-name>) get constraints for owned attribute(username) contain: @<constraint>
    Then <root-type>(<subtype-name>) get constraints for owned attribute(reference) contain: @<constraint>
    Then <root-type>(<subtype-name>) get constraints for owned attribute(work-email) contain: @<constraint>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<subtype-name>) get owns contain:
      | username   |
      | reference  |
      | work-email |
      | age        |
      | rating     |
      | nick-name  |
      | email      |
      | name       |
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
    Then <root-type>(<subtype-name>) get owns(username) get constraints contain: @<constraint>
    Then <root-type>(<subtype-name>) get owns(reference) get constraints contain: @<constraint>
    Then <root-type>(<subtype-name>) get owns(work-email) get constraints do not contain: @<constraint>
    Then <root-type>(<subtype-name>) get constraints for owned attribute(username) contain: @<constraint>
    Then <root-type>(<subtype-name>) get constraints for owned attribute(reference) contain: @<constraint>
    Then <root-type>(<subtype-name>) get constraints for owned attribute(work-email) contain: @<constraint>
    When create attribute type: license
    When attribute(license) set supertype: reference
    When create attribute type: points
    When attribute(points) set supertype: rating
    When <root-type>(<subtype-name-2>) set supertype: <subtype-name>
    When <root-type>(<subtype-name-2>) set owns: license
    When <root-type>(<subtype-name-2>) set owns: points
    When transaction commits
    When connection open read transaction for database: typedb
    Then <root-type>(<subtype-name>) get owns contain:
      | username   |
      | reference  |
      | work-email |
      | age        |
      | rating     |
      | nick-name  |
      | email      |
      | name       |
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
    Then <root-type>(<subtype-name>) get owns(username) get constraints contain: @<constraint>
    Then <root-type>(<subtype-name>) get owns(reference) get constraints contain: @<constraint>
    Then <root-type>(<subtype-name>) get owns(work-email) get constraints do not contain: @<constraint>
    Then <root-type>(<subtype-name>) get constraints for owned attribute(username) contain: @<constraint>
    Then <root-type>(<subtype-name>) get constraints for owned attribute(reference) contain: @<constraint>
    Then <root-type>(<subtype-name>) get constraints for owned attribute(work-email) contain: @<constraint>
    Then <root-type>(<subtype-name-2>) get owns contain:
      | username   |
      | license    |
      | work-email |
      | age        |
      | points     |
      | nick-name  |
      | email      |
      | reference  |
      | name       |
      | rating     |
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
    Then <root-type>(<subtype-name-2>) get owns(username) get constraints contain: @<constraint>
    Then <root-type>(<subtype-name-2>) get owns(license) get constraints do not contain: @<constraint>
    Then <root-type>(<subtype-name-2>) get owns(work-email) get constraints do not contain: @<constraint>
    Then <root-type>(<subtype-name-2>) get constraints for owned attribute(username) contain: @<constraint>
    Then <root-type>(<subtype-name-2>) get constraints for owned attribute(license) contain: @<constraint>
    Then <root-type>(<subtype-name-2>) get constraints for owned attribute(work-email) contain: @<constraint>
    Examples:
      | root-type | supertype-name | subtype-name | subtype-name-2 | annotation       | constraint       |
      | entity    | person         | customer     | subscriber     | key              | unique           |
      | entity    | person         | customer     | subscriber     | unique           | unique           |
#      | entity    | person         | customer     | subscriber     | subkey(LABEL)    | subkey(LABEL)    |
      | entity    | person         | customer     | subscriber     | values("1", "2") | values("1", "2") |
      | entity    | person         | customer     | subscriber     | range("1".."2")  | range("1".."2")  |
      | entity    | person         | customer     | subscriber     | card(1..1)       | card(1..1)       |
      | entity    | person         | customer     | subscriber     | regex("\S+")     | regex("\S+")     |
      | relation  | description    | registration | profile        | key              | unique           |
      | relation  | description    | registration | profile        | unique           | unique           |
#      | relation  | description    | registration | profile        | subkey(LABEL)    | subkey(LABEL)    |
      | relation  | description    | registration | profile        | values("1", "2") | values("1", "2") |
      | relation  | description    | registration | profile        | range("1".."2")  | range("1".."2")  |
      | relation  | description    | registration | profile        | card(1..1)       | card(1..1)       |
      | relation  | description    | registration | profile        | regex("\S+")     | regex("\S+")     |

  Scenario Outline: <root-type> type can set "redundant" duplicated @<annotation> on plays while it inherits it
    When create attribute type: name
    When attribute(name) set value type: string
    When attribute(name) set annotation: @abstract
    When create attribute type: surname
    When attribute(surname) set supertype: name
    When <root-type>(<supertype-name>) set owns: name
    When <root-type>(<supertype-name>) get owns(name) set annotation: @<annotation>
    When <root-type>(<subtype-name>) set owns: surname
    Then <root-type>(<supertype-name>) get owns(name) get declared annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get owns(surname) get declared annotations do not contain: @<annotation>
    Then <root-type>(<supertype-name>) get owns(name) get constraints contain: @<constraint>
    Then <root-type>(<subtype-name>) get owns(surname) get constraints do not contain: @<constraint>
    Then <root-type>(<supertype-name>) get constraints for owned attribute(name) contain: @<constraint>
    Then <root-type>(<subtype-name>) get constraints for owned attribute(name) contain: @<constraint>
    Then <root-type>(<subtype-name>) get constraints for owned attribute(surname) contain: @<constraint>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<supertype-name>) get owns(name) get declared annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get owns(surname) get declared annotations do not contain: @<annotation>
    Then <root-type>(<supertype-name>) get owns(name) get constraints contain: @<constraint>
    Then <root-type>(<subtype-name>) get owns(surname) get constraints do not contain: @<constraint>
    Then <root-type>(<supertype-name>) get constraints for owned attribute(name) contain: @<constraint>
    Then <root-type>(<subtype-name>) get constraints for owned attribute(name) contain: @<constraint>
    Then <root-type>(<subtype-name>) get constraints for owned attribute(surname) contain: @<constraint>
    When <root-type>(<subtype-name>) get owns(surname) set annotation: @<annotation>
    Then <root-type>(<supertype-name>) get owns(name) get declared annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get owns(surname) get declared annotations contain: @<annotation>
    Then <root-type>(<supertype-name>) get owns(name) get constraints contain: @<constraint>
    Then <root-type>(<subtype-name>) get owns(surname) get constraints contain: @<constraint>
    Then <root-type>(<supertype-name>) get constraints for owned attribute(name) contain: @<constraint>
    Then <root-type>(<subtype-name>) get constraints for owned attribute(name) contain: @<constraint>
    Then <root-type>(<subtype-name>) get constraints for owned attribute(surname) contain: @<constraint>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<supertype-name>) get owns(name) get declared annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get owns(surname) get declared annotations contain: @<annotation>
    Then <root-type>(<supertype-name>) get owns(name) get constraints contain: @<constraint>
    Then <root-type>(<subtype-name>) get owns(surname) get constraints contain: @<constraint>
    Then <root-type>(<supertype-name>) get constraints for owned attribute(name) contain: @<constraint>
    Then <root-type>(<subtype-name>) get constraints for owned attribute(name) contain: @<constraint>
    Then <root-type>(<subtype-name>) get constraints for owned attribute(surname) contain: @<constraint>
    When <root-type>(<supertype-name>) get owns(name) unset annotation: @<annotation-category>
    Then <root-type>(<supertype-name>) get owns(name) get declared annotations do not contain: @<annotation>
    Then <root-type>(<subtype-name>) get owns(surname) get declared annotations contain: @<annotation>
    Then <root-type>(<supertype-name>) get owns(name) get constraints do not contain: @<constraint>
    Then <root-type>(<subtype-name>) get owns(surname) get constraints contain: @<constraint>
    Then <root-type>(<supertype-name>) get constraints for owned attribute(name) do not contain: @<constraint>
    Then <root-type>(<subtype-name>) get constraints for owned attribute(name) do not contain: @<constraint>
    Then <root-type>(<subtype-name>) get constraints for owned attribute(surname) contain: @<constraint>
    When transaction commits
    When connection open read transaction for database: typedb
    Then <root-type>(<supertype-name>) get owns(name) get declared annotations do not contain: @<annotation>
    Then <root-type>(<subtype-name>) get owns(surname) get declared annotations contain: @<annotation>
    Then <root-type>(<supertype-name>) get owns(name) get constraints do not contain: @<constraint>
    Then <root-type>(<subtype-name>) get owns(surname) get constraints contain: @<constraint>
    Then <root-type>(<supertype-name>) get constraints for owned attribute(name) do not contain: @<constraint>
    Then <root-type>(<subtype-name>) get constraints for owned attribute(name) do not contain: @<constraint>
    Then <root-type>(<subtype-name>) get constraints for owned attribute(surname) contain: @<constraint>
    Examples:
      | root-type | supertype-name | subtype-name | annotation       | annotation-category | constraint       |
      | entity    | person         | customer     | key              | key                 | unique           |
      | entity    | person         | customer     | unique           | unique              | unique           |
#      | entity    | person         | customer     | subkey(LABEL)    | subkey              | subkey(LABEL)               |
      | entity    | person         | customer     | values("1", "2") | values              | values("1", "2") |
      | entity    | person         | customer     | range("1".."2")  | range               | range("1".."2")  |
      | entity    | person         | customer     | card(1..1)       | card                | card(1..1)       |
      | entity    | person         | customer     | regex("\S+")     | regex               | regex("\S+")     |
      | relation  | description    | registration | key              | key                 | unique           |
      | relation  | description    | registration | unique           | unique              | unique           |
#      | relation  | description    | registration | subkey(LABEL)    | subkey              | subkey(LABEL)               |
      | relation  | description    | registration | values("1", "2") | values              | values("1", "2") |
      | relation  | description    | registration | range("1".."2")  | range               | range("1".."2")  |
      | relation  | description    | registration | card(1..1)       | card                | card(1..1)       |
      | relation  | description    | registration | regex("\S+")     | regex               | regex("\S+")     |

#########################
## @key
#########################

  Scenario: Owns with @card(1..1) and @unique annotations without @key is not a key
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: string
    When entity(person) set owns: custom-attribute
    When entity(person) get owns(custom-attribute) set annotation: @card(1..1)
    When entity(person) get owns(custom-attribute) set annotation: @unique
    Then entity(person) get owns(custom-attribute) is key: false
    Then entity(person) get owns(custom-attribute) set annotation: @key; fails
    Then entity(person) get owns(custom-attribute) is key: false
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get owns(custom-attribute) set annotation: @key; fails
    Then entity(person) get owns(custom-attribute) is key: false
    When entity(person) get owns(custom-attribute) unset annotation: @unique
    Then entity(person) get owns(custom-attribute) set annotation: @key; fails
    Then entity(person) get owns(custom-attribute) is key: false
    When entity(person) get owns(custom-attribute) unset annotation: @card
    Then entity(person) get owns(custom-attribute) set annotation: @key
    Then entity(person) get owns(custom-attribute) is key: true
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get owns(custom-attribute) is key: true

  Scenario Outline: Owns can set @key annotation for <value-type> value type and unset it
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When entity(person) set owns: custom-attribute
    Then entity(person) get owns(custom-attribute) get cardinality: @card(0..1)
    When entity(person) get owns(custom-attribute) set annotation: @key
    Then entity(person) get owns(custom-attribute) is key: true
    Then entity(person) get owns(custom-attribute) get cardinality: @card(1..1)
    Then entity(person) get owns(custom-attribute) get constraints contain: @card(1..1)
    Then entity(person) get owns(custom-attribute) get constraints contain: @unique
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get owns(custom-attribute) is key: true
    Then entity(person) get owns(custom-attribute) get cardinality: @card(1..1)
    Then entity(person) get owns(custom-attribute) get constraints contain: @card(1..1)
    Then entity(person) get owns(custom-attribute) get constraints contain: @unique
    When entity(person) get owns(custom-attribute) unset annotation: @key
    Then entity(person) get owns(custom-attribute) get constraints do not contain: @card(1..1)
    Then entity(person) get owns(custom-attribute) get constraints do not contain: @unique
    Then entity(person) get owns(custom-attribute) get constraints contain: @card(0..1)
    Then entity(person) get owns(custom-attribute) get cardinality: @card(0..1)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get constraints do not contain: @card(1..1)
    Then entity(person) get owns(custom-attribute) get constraints do not contain: @unique
    Then entity(person) get owns(custom-attribute) get cardinality: @card(0..1)
    When entity(person) get owns(custom-attribute) set annotation: @key
    Then entity(person) get owns(custom-attribute) is key: true
    Then entity(person) get owns(custom-attribute) get cardinality: @card(1..1)
    Then entity(person) get owns(custom-attribute) get constraints contain: @card(1..1)
    Then entity(person) get owns(custom-attribute) get constraints contain: @unique
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get owns(custom-attribute) is key: true
    Then entity(person) get owns(custom-attribute) get cardinality: @card(1..1)
    Then entity(person) get owns(custom-attribute) get constraints contain: @card(1..1)
    Then entity(person) get owns(custom-attribute) get constraints contain: @unique
    When entity(person) unset owns: custom-attribute
    Then entity(person) get owns is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get owns is empty
    Examples:
      | value-type  |
      | integer     |
      | decimal     |
      | string      |
      | boolean     |
      | date        |
      | datetime    |
      | datetime-tz |
      | duration    |

  Scenario Outline: Owns can reset @key annotations
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When entity(person) set owns: custom-attribute
    When entity(person) get owns(custom-attribute) set annotation: @key
    Then entity(person) get owns(custom-attribute) is key: true
    When entity(person) get owns(custom-attribute) set annotation: @key
    Then entity(person) get owns(custom-attribute) is key: true
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get owns(custom-attribute) is key: true
    When entity(person) get owns(custom-attribute) set annotation: @key
    Then entity(person) get owns(custom-attribute) is key: true
    Examples:
      | value-type  |
      | integer     |
      | decimal     |
      | string      |
      | boolean     |
      | date        |
      | datetime    |
      | datetime-tz |
      | duration    |

  Scenario Outline: Owns cannot set @key annotation for <value-type> as it is not keyable
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When entity(person) set owns: custom-attribute
    Then entity(person) get owns(custom-attribute) set annotation: @key; fails
    Then entity(person) get owns(custom-attribute) get constraints do not contain: @unique
    Then entity(person) get owns(custom-attribute) get constraints do not contain: @card(1..1)
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get constraints do not contain: @unique
    Then entity(person) get owns(custom-attribute) get constraints do not contain: @card(1..1)
    Examples:
      | value-type            |
      | double                |
      | struct(custom-struct) |

  Scenario: Owns cannot set @key annotation for empty value type
    When create attribute type: id
    Then attribute(id) get value type is none
    When attribute(id) set annotation: @abstract
    When entity(person) set owns: id
    When entity(person) get owns(id) set annotation: @key; fails
    Then entity(person) get owns(id) get declared annotations do not contain: @key
    Then entity(person) get constraints for owned attribute(id) do not contain: @unique
    Then entity(person) get owns(id) get constraints do not contain: @unique
    Then entity(person) get constraints for owned attribute(id) do not contain: @card(1..1)
    Then entity(person) get owns(id) get constraints do not contain: @card(1..1)
    Then entity(person) get owns(id) is key: false
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get owns(id) get declared annotations do not contain: @key
    Then entity(person) get constraints for owned attribute(id) do not contain: @unique
    Then entity(person) get owns(id) get constraints do not contain: @unique
    Then entity(person) get constraints for owned attribute(id) do not contain: @card(1..1)
    Then entity(person) get owns(id) get constraints do not contain: @card(1..1)
    Then entity(person) get owns(id) is key: false

  Scenario: Attribute type cannot unset value type if it has owns with @key annotation
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set annotation: @abstract
    When attribute(custom-attribute) set value type: string
    When entity(person) set owns: custom-attribute
    When entity(person) get owns(custom-attribute) set annotation: @key
    Then attribute(custom-attribute) unset value type; fails
    Then attribute(custom-attribute) set value type: double; fails
    Then attribute(custom-attribute) set value type: struct(custom-struct); fails
    When attribute(custom-attribute) set value type: string
    When entity(person) get owns(custom-attribute) unset annotation: @key
    When attribute(custom-attribute) unset value type
    Then attribute(custom-attribute) get value type is none
    Then entity(person) get owns(custom-attribute) set annotation: @key; fails
    When attribute(custom-attribute) set value type: string
    When entity(person) get owns(custom-attribute) set annotation: @key
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get owns(custom-attribute) is key: true
    Then attribute(custom-attribute) get value type: string
    Then attribute(custom-attribute) unset value type; fails

  Scenario Outline: Owns can set @key annotation for ordered ownership
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When entity(person) set owns: custom-attribute
    When entity(person) get owns(custom-attribute) set ordering: ordered
    When entity(person) get owns(custom-attribute) set annotation: @key
    Then entity(person) get owns(custom-attribute) is key: true
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get owns(custom-attribute) is key: true
    Examples:
      | value-type  |
      | integer     |
      | decimal     |
      | string      |
      | boolean     |
      | date        |
      | datetime    |
      | datetime-tz |
      | duration    |

  Scenario Outline: Owns cannot set @key annotation for <value-type> as it is not keyable for ordered ownership
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When entity(person) set owns: custom-attribute
    When entity(person) get owns(custom-attribute) set ordering: ordered
    Then entity(person) get owns(custom-attribute) set annotation: @key; fails
    Then entity(person) get owns(custom-attribute) get constraints do not contain: @unique
    Then entity(person) get owns(custom-attribute) get constraints do not contain: @card(1..1)
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get constraints do not contain: @unique
    Then entity(person) get owns(custom-attribute) get constraints do not contain: @card(1..1)
    Examples:
      | value-type            |
      | double                |
      | struct(custom-struct) |

  Scenario Outline: Can set multiple specialises on the same type for a @key owns even if the cardinality is blocked
    When create attribute type: name
    When attribute(name) set value type: <value-type>
    When attribute(name) set annotation: @abstract
    When create attribute type: surname
    When attribute(surname) set supertype: name
    When create attribute type: third-name
    When attribute(third-name) set supertype: name
    When <root-type>(<supertype-name>) set owns: name
    Then <root-type>(<supertype-name>) get owns(name) get cardinality: @card(0..1)
    When <root-type>(<supertype-name>) get owns(name) set annotation: @key
    Then <root-type>(<supertype-name>) get owns(name) get cardinality: @card(1..1)
    When <root-type>(<subtype-name>) set supertype: <supertype-name>
    When <root-type>(<subtype-name>) set owns: surname
    When transaction commits
    When connection open schema transaction for database: typedb
    When <root-type>(<subtype-name>) set owns: third-name
    When transaction commits
    When connection open schema transaction for database: typedb
    When <root-type>(<supertype-name>) get owns(name) unset annotation: @key
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<supertype-name>) get owns(name) is key: false
    Then <root-type>(<subtype-name>) get owns(surname) is key: false
    Then <root-type>(<subtype-name>) get owns(third-name) is key: false
    Then <root-type>(<supertype-name>) get owns(name) get cardinality: @card(0..1)
    Then <root-type>(<subtype-name>) get owns(surname) get cardinality: @card(0..1)
    Then <root-type>(<subtype-name>) get owns(third-name) get cardinality: @card(0..1)
    When <root-type>(<subtype-name>) get owns(surname) set annotation: @key
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<supertype-name>) get owns(name) get cardinality: @card(0..1)
    Then <root-type>(<subtype-name>) get owns(surname) get cardinality: @card(1..1)
    Then <root-type>(<subtype-name>) get owns(third-name) get cardinality: @card(0..1)
    When <root-type>(<subtype-name>) get owns(surname) unset annotation: @key
    Then <root-type>(<supertype-name>) get owns(name) set annotation: @key
    Examples:
      | root-type | supertype-name | subtype-name | value-type |
      | entity    | person         | customer     | string     |
      | relation  | description    | registration | decimal    |

  Scenario Outline: Owns set and unset annotation @key cannot break cardinality between affected siblings
    When create attribute type: literal
    When attribute(literal) set value type: string
    When attribute(literal) set annotation: @abstract
    When <root-type>(<supertype-name>) set owns: literal
    Then <root-type>(<supertype-name>) get owns(literal) set annotation: @key
    Then <root-type>(<supertype-name>) get owns(literal) get cardinality: @card(1..1)
    When create attribute type: name
    When attribute(name) set supertype: literal
    When attribute(name) set annotation: @abstract
    When create attribute type: letter
    When attribute(letter) set supertype: literal
    When attribute(letter) set annotation: @abstract
    When <root-type>(<subtype-name>) set supertype: <supertype-name>
    When <root-type>(<subtype-name>) set owns: name
    Then <root-type>(<subtype-name>) get constraints for owned attribute(name) contain: @card(1..1)
    Then <root-type>(<subtype-name>) get constraints for owned attribute(name) contain: @card(0..1)
    Then <root-type>(<subtype-name>) get owns(name) get constraints do not contain: @card(1..1)
    Then <root-type>(<subtype-name>) get owns(name) get constraints contain: @card(0..1)
    Then <root-type>(<subtype-name>) get owns(name) get cardinality: @card(0..1)
    When <root-type>(<subtype-name>) set owns: letter
    When create attribute type: surname
    When attribute(surname) set supertype: name
    When create attribute type: first-name
    When attribute(first-name) set supertype: name
    When <root-type>(<subtype-name-2>) set supertype: <subtype-name>
    When <root-type>(<subtype-name-2>) set owns: first-name
    When <root-type>(<subtype-name-2>) set owns: surname
    Then <root-type>(<subtype-name-2>) get owns(first-name) get cardinality: @card(0..1)
    Then <root-type>(<subtype-name-2>) get constraints for owned attribute(first-name) contain: @card(1..1)
    Then <root-type>(<subtype-name-2>) get constraints for owned attribute(first-name) contain: @card(0..1)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<supertype-name>) get owns(literal) get cardinality: @card(1..1)
    When <root-type>(<supertype-name>) get owns(literal) unset annotation: @key
    Then <root-type>(<supertype-name>) get owns(literal) get cardinality: @card(0..1)
    When <root-type>(<supertype-name>) get owns(literal) set annotation: @key
    Then <root-type>(<supertype-name>) get owns(literal) get cardinality: @card(1..1)
    When transaction commits
    When connection open schema transaction for database: typedb
    When <root-type>(<supertype-name>) get owns(literal) unset annotation: @key
    When <root-type>(<subtype-name>) get owns(name) set annotation: @key
    When <root-type>(<subtype-name>) get owns(name) unset annotation: @key
    Then transaction commits
    Examples:
      | root-type | supertype-name | subtype-name | subtype-name-2 |
      | entity    | person         | customer     | subscriber     |
      | relation  | description    | registration | profile        |

#########################
## @subkey
#########################
  # TODO: Not implemented
#  Scenario Outline: Owns can set @subkey annotation for <value-type> value type and unset it
#    When create attribute type: custom-attribute
#    When attribute(custom-attribute) set value type: <value-type>
#    When entity(person) set owns: custom-attribute
#    When entity(person) get owns(custom-attribute) set annotation: @subkey(<arg>)
#    Then entity(person) get owns(custom-attribute) get constraints contain: @subkey(<arg>)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then entity(person) get owns(custom-attribute) get constraints contain: @subkey(<arg>)
#    When entity(person) get owns(custom-attribute) unset annotation: @subkey
#    Then entity(person) get owns(custom-attribute) get constraints do not contain: @subkey
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then entity(person) get owns(custom-attribute) get constraints do not contain: @subkey
#    When entity(person) get owns(custom-attribute) set annotation: @subkey(<arg>)
#    Then entity(person) get owns(custom-attribute) get constraints contain: @subkey(<arg>)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then entity(person) get owns(custom-attribute) get constraints contain: @subkey(<arg>)
#    When entity(person) unset owns: custom-attribute
#    Then entity(person) get owns is empty
#    When transaction commits
#    When connection open read transaction for database: typedb
#    Then entity(person) get owns is empty
#    Examples:
#      | value-type | arg                            |
#      | integer       | LABEL                          |
#      | decimal    | 1.5                            |
#      | string     | label                          |
#      | boolean    | lAbEl_Of_FoRmaT                |
#      | date        | l                              |
#      | datetime   | l                              |
#      | datetime-tz | l2                             |
#      | duration   | trydigits2723andafter          |
#      | integer       | LABEL, LABEL2                  |
#      | string     | label, label2                  |
#      | boolean    | lAbEl_Of_FoRmaT, another_label |
#      | datetime   | l, m, b, k, r, e2, ss, s, sss  |
#      | date       | l, m, b, k, r, e2, ss, s, sss  |
#
#  Scenario Outline: Owns can set @subkey annotation for multiple attributes of <root-type> type
#    When create attribute type: first-name
#    When attribute(first-name) set value type: string
#    When create attribute type: second-name
#    When attribute(second-name) set value type: string
#    When create attribute type: third-name
#    When attribute(third-name) set value type: string
#    When create attribute type: birthday
#    When attribute(birthday) set value type: date
#    When create attribute type: balance
#    When attribute(balance) set value type: decimal
#    When create attribute type: progress
#    When attribute(progress) set value type: double
#    When create attribute type: age
#    When attribute(age) set value type: integer
#    When <root-type>(<type-name>) set owns: first-name
#    When <root-type>(<type-name>) get owns(first-name) set annotation: @subkey(primary)
#    Then <root-type>(<type-name>) get owns(first-name) get constraints contain: @subkey(primary)
#    When <root-type>(<type-name>) set owns: second-name
#    When <root-type>(<type-name>) get owns(second-name) set annotation: @subkey(primary)
#    Then <root-type>(<type-name>) get owns(second-name) get constraints contain: @subkey(primary)
#    When <root-type>(<type-name>) set owns: third-name
#    When <root-type>(<type-name>) get owns(third-name) set annotation: @subkey(optional)
#    Then <root-type>(<type-name>) get owns(third-name) get constraints contain: @subkey(optional)
#    When <root-type>(<type-name>) set owns: birthday
#    When <root-type>(<type-name>) get owns(birthday) set annotation: @subkey(primary)
#    Then <root-type>(<type-name>) get owns(birthday) get constraints contain: @subkey(primary)
#    When <root-type>(<type-name>) set owns: balance
#    When <root-type>(<type-name>) get owns(balance) set annotation: @subkey(single)
#    Then <root-type>(<type-name>) get owns(balance) get constraints contain: @subkey(single)
#    When <root-type>(<type-name>) set owns: progress
#    When <root-type>(<type-name>) get owns(progress) set annotation: @subkey(optional)
#    Then <root-type>(<type-name>) get owns(progress) get constraints contain: @subkey(optional)
#    When <root-type>(<type-name>) set owns: age
#    When <root-type>(<type-name>) get owns(age) set annotation: @subkey(primary)
#    Then <root-type>(<type-name>) get owns(age) get constraints contain: @subkey(primary)
#    When transaction commits
#    When connection open read transaction for database: typedb
#    Then <root-type>(<type-name>) get owns(first-name) get constraints contain: @subkey(primary)
#    Then <root-type>(<type-name>) get owns(second-name) get constraints contain: @subkey(primary)
#    Then <root-type>(<type-name>) get owns(third-name) get constraints contain: @subkey(optional)
#    Then <root-type>(<type-name>) get owns(birthday) get constraints contain: @subkey(primary)
#    Then <root-type>(<type-name>) get owns(balance) get constraints contain: @subkey(single)
#    Then <root-type>(<type-name>) get owns(progress) get constraints contain: @subkey(optional)
#    Then <root-type>(<type-name>) get owns(age) get constraints contain: @subkey(primary)
#    Examples:
#      | root-type | type-name   |
#      | entity    | person      |
#      | relation  | description |
#
#  # TODO: Test for empty value type
#
#  Scenario Outline: Owns can reset @subkey annotation with the same argument
#    When create attribute type: custom-attribute
#    When attribute(custom-attribute) set value type: <value-type>
#    When entity(person) set owns: custom-attribute
#    When entity(person) get owns(custom-attribute) set annotation: @subkey(LABEL)
#    Then entity(person) get owns(custom-attribute) get constraints contain: @subkey(LABEL)
#    When entity(person) get owns(custom-attribute) set annotation: @subkey(LABEL)
#    Then entity(person) get owns(custom-attribute) get constraints contain: @subkey(LABEL)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then entity(person) get owns(custom-attribute) get constraints contain: @subkey(LABEL)
#    When entity(person) get owns(custom-attribute) set annotation: @subkey(LABEL)
#    Then entity(person) get owns(custom-attribute) get constraints contain: @subkey(LABEL)
#    Examples:
#      | value-type |
#      | integer       |
#      | decimal    |
#      | string     |
#      | boolean    |
#      | date       |
#      | datetime   |
#      | datetime-tz |
#      | duration   |
#
#  Scenario: Owns can set multiple @subkey annotations with different arguments
#    When create attribute type: name
#    When attribute(name) set value type: string
#    When create attribute type: surname
#    When attribute(surname) set value type: string
#    When create attribute type: age
#    When attribute(age) set value type: integer
#    When entity(person) set owns: name
#    When entity(person) get owns(name) set annotation: @subkey(NAME-AGE)
#    When entity(person) get owns(name) set annotation: @subkey(FULL-NAME)
#    Then entity(person) get owns(name) get constraints contain:
#      | @subkey(NAME-AGE)  |
#      | @subkey(FULL-NAME) |
#    When entity(person) set owns: surname
#    When entity(person) get owns(surname) set annotation: @subkey(FULL-NAME)
#    Then entity(person) get owns(surname) get constraints contain: @subkey(FULL-NAME)
#    When entity(person) set owns: age
#    When entity(person) get owns(age) set annotation: @subkey(NAME-AGE)
#    Then entity(person) get owns(age) get constraints contain: @subkey(NAME-AGE)
#    When transaction commits
#    When connection open read transaction for database: typedb
#    Then entity(person) get owns(name) get constraints contain:
#      | @subkey(NAME-AGE)  |
#      | @subkey(FULL-NAME) |
#    Then entity(person) get owns(surname) get constraints contain: @subkey(FULL-NAME)
#    Then entity(person) get owns(age) get constraints contain: @subkey(NAME-AGE)
#
#  Scenario Outline: Owns cannot set @subkey annotation for <value-type> as it is not keyable
#    When create attribute type: custom-attribute
#    When attribute(custom-attribute) set value type: <value-type>
#    When entity(person) set owns: custom-attribute
#    Then entity(person) get owns(custom-attribute) set annotation: @subkey(LABEL); fails
#    Then entity(person) get owns(custom-attribute) get constraints do not contain: @subkey(LABEL)
#    When transaction commits
#    When connection open read transaction for database: typedb
#    Then entity(person) get owns(custom-attribute) get constraints do not contain: @subkey(LABEL)
#    Examples:
#      | value-type |
#      | double     |
#      | struct(custom-struct) |
#
#  Scenario: Owns cannot set @subkey annotation for incorrect arguments
#    When create attribute type: custom-attribute
#    When attribute(custom-attribute) set value type: integer
#    When entity(person) set owns: custom-attribute
#    Then entity(person) get owns(custom-attribute) set annotation: @subkey("LABEL"); fails
#    Then entity(person) get owns(custom-attribute) set annotation: @subkey(福); fails
#    Then entity(person) get owns(custom-attribute) set annotation: @subkey(d./';;p480909!208923r09zlmk*((*£*()(@£Q**&$@)); fails
#    Then entity(person) get owns(custom-attribute) set annotation: @subkey(49j93848); fails
#    Then entity(person) get owns(custom-attribute) set annotation: @subkey(LABEL, LABEL); fails
#    Then entity(person) get owns(custom-attribute) set annotation: @subkey(LABEL, LABEL2); fails
#    Then entity(person) get owns(custom-attribute) set annotation: @subkey(LABEL, LABEL2, LABEL3); fails
#    Then entity(person) get owns(custom-attribute) get constraint categories do not contain: @subkey
#    When transaction commits
#    When connection open read transaction for database: typedb
#    Then entity(person) get owns(custom-attribute) get constraint categories do not contain: @subkey
#
#  Scenario Outline: Owns can set @subkey annotation for ordered ownership
#    When create attribute type: custom-attribute
#    When attribute(custom-attribute) set value type: <value-type>
#    When entity(person) set owns: custom-attribute
#    When entity(person) get owns(custom-attribute) set ordering: ordered
#    When entity(person) get owns(custom-attribute) set annotation: @subkey(LABEL)
#    Then entity(person) get owns(custom-attribute) get constraints contain: @subkey(LABEL)
#    When transaction commits
#    When connection open read transaction for database: typedb
#    Then entity(person) get owns(custom-attribute) get constraints contain: @subkey(LABEL)
#    Examples:
#      | value-type |
#      | integer       |
#      | string     |
#      | boolean    |
#      | decimal    |
#      | date       |
#      | datetime   |
#      | datetime-tz |
#      | duration   |

########################
# @unique
########################

  Scenario Outline: Owns can set @unique annotation for <value-type> value type and unset it
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When entity(person) set owns: custom-attribute
    When entity(person) get owns(custom-attribute) set annotation: @unique
    Then entity(person) get owns(custom-attribute) get constraints contain: @unique
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get constraints contain: @unique
    When entity(person) get owns(custom-attribute) unset annotation: @unique
    Then entity(person) get owns(custom-attribute) get constraints do not contain: @unique
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get constraints do not contain: @unique
    When entity(person) get owns(custom-attribute) set annotation: @unique
    Then entity(person) get owns(custom-attribute) get constraints contain: @unique
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get constraints contain: @unique
    When entity(person) unset owns: custom-attribute
    Then entity(person) get owns is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get owns is empty
    Examples:
      | value-type  |
      | integer     |
      | decimal     |
      | string      |
      | boolean     |
      | date        |
      | datetime    |
      | datetime-tz |
      | duration    |

  Scenario Outline: Owns can reset @unique annotation
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When entity(person) set owns: custom-attribute
    When entity(person) get owns(custom-attribute) set annotation: @unique
    Then entity(person) get owns(custom-attribute) get constraints contain: @unique
    When entity(person) get owns(custom-attribute) set annotation: @unique
    Then entity(person) get owns(custom-attribute) get constraints contain: @unique
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get constraints contain: @unique
    When entity(person) get owns(custom-attribute) set annotation: @unique
    Then entity(person) get owns(custom-attribute) get constraints contain: @unique
    Examples:
      | value-type  |
      | integer     |
      | decimal     |
      | string      |
      | boolean     |
      | date        |
      | datetime    |
      | datetime-tz |
      | duration    |

  Scenario Outline: Owns cannot set @unique annotation for <value-type> as it is not keyable
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When entity(person) set owns: custom-attribute
    Then entity(person) get owns(custom-attribute) set annotation: @unique; fails
    Then entity(person) get owns(custom-attribute) get constraints do not contain: @unique
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get constraints do not contain: @unique
    Examples:
      | value-type            |
      | double                |
      | struct(custom-struct) |

  Scenario: Owns cannot set @unique annotation for empty value type
    When create attribute type: id
    Then attribute(id) get value type is none
    When attribute(id) set annotation: @abstract
    When entity(person) set owns: id
    When entity(person) get owns(id) set annotation: @unique; fails
    Then entity(person) get constraints for owned attribute(id) do not contain: @unique
    Then entity(person) get owns(id) get constraints do not contain: @unique
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get constraints for owned attribute(id) do not contain: @unique
    Then entity(person) get owns(id) get constraints do not contain: @unique
    When entity(person) get owns(id) set annotation: @unique; fails
    Then entity(person) get constraints for owned attribute(id) do not contain: @unique
    Then entity(person) get owns(id) get constraints do not contain: @unique

  Scenario: Attribute type cannot unset value type if it has owns with @unique annotation
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set annotation: @abstract
    When attribute(custom-attribute) set value type: string
    When entity(person) set owns: custom-attribute
    When entity(person) get owns(custom-attribute) set annotation: @unique
    Then attribute(custom-attribute) unset value type; fails
    Then attribute(custom-attribute) set value type: double; fails
    Then attribute(custom-attribute) set value type: struct(custom-struct); fails
    When attribute(custom-attribute) set value type: string
    When entity(person) get owns(custom-attribute) unset annotation: @unique
    When attribute(custom-attribute) unset value type
    Then attribute(custom-attribute) get value type is none
    Then entity(person) get owns(custom-attribute) set annotation: @unique; fails
    When attribute(custom-attribute) set value type: string
    When entity(person) get owns(custom-attribute) set annotation: @unique
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get constraints contain: @unique
    Then attribute(custom-attribute) get value type: string
    Then attribute(custom-attribute) unset value type; fails

  Scenario Outline: Ordered owns can set @unique annotation for <value-type> value type and unset it
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When entity(person) set owns: custom-attribute
    When entity(person) get owns(custom-attribute) set ordering: ordered
    When entity(person) get owns(custom-attribute) set annotation: @unique
    Then entity(person) get owns(custom-attribute) get ordering: ordered
    Then entity(person) get owns(custom-attribute) get constraints contain: @unique
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get ordering: ordered
    Then entity(person) get owns(custom-attribute) get constraints contain: @unique
    When entity(person) get owns(custom-attribute) unset annotation: @unique
    Then entity(person) get owns(custom-attribute) get constraints do not contain: @unique
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get constraints do not contain: @unique
    When entity(person) get owns(custom-attribute) set annotation: @unique
    Then entity(person) get owns(custom-attribute) get ordering: ordered
    Then entity(person) get owns(custom-attribute) get constraints contain: @unique
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get ordering: ordered
    Then entity(person) get owns(custom-attribute) get constraints contain: @unique
    When entity(person) unset owns: custom-attribute
    Then entity(person) get owns is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get owns is empty
    Examples:
      | value-type  |
      | integer     |
      | decimal     |
      | string      |
      | boolean     |
      | date        |
      | datetime    |
      | datetime-tz |
      | duration    |

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
    Then entity(person) get owns(custom-attribute) get constraints contain: @values(<args>)
    When entity(person) set owns: custom-attribute-2
    When entity(person) get owns(custom-attribute-2) set ordering: ordered
    When entity(person) get owns(custom-attribute-2) set annotation: @values(<args>)
    Then entity(person) get owns(custom-attribute-2) get constraints contain: @values(<args>)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get constraints contain: @values(<args>)
    Then entity(person) get owns(custom-attribute-2) get constraints contain: @values(<args>)
    When entity(person) unset owns: custom-attribute
    When entity(person) unset owns: custom-attribute-2
    Then entity(person) get owns is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get owns is empty
    Examples:
      | value-type  | args                                                                                                                                                                                                                                                                                                                                                                                                 |
      | integer     | 0                                                                                                                                                                                                                                                                                                                                                                                                    |
      | integer     | 1                                                                                                                                                                                                                                                                                                                                                                                                    |
      | integer     | -1                                                                                                                                                                                                                                                                                                                                                                                                   |
      | integer     | 1, 2                                                                                                                                                                                                                                                                                                                                                                                                 |
      | integer     | -9223372036854775808, 9223372036854775807                                                                                                                                                                                                                                                                                                                                                            |
      | integer     | 2, 1, 3, 4, 5, 6, 7, 9, 10, 11, 55, -1, -654321, 123456                                                                                                                                                                                                                                                                                                                                              |
      | integer     | 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99 |
      | string      | ""                                                                                                                                                                                                                                                                                                                                                                                                   |
      | string      | "1"                                                                                                                                                                                                                                                                                                                                                                                                  |
      | string      | "福"                                                                                                                                                                                                                                                                                                                                                                                                  |
      | string      | "s", "S"                                                                                                                                                                                                                                                                                                                                                                                             |
      | string      | "This rank contain a sufficiently detailed description of its nature"                                                                                                                                                                                                                                                                                                                                |
      | string      | "Scout", "Stone Guard", "High Warlord"                                                                                                                                                                                                                                                                                                                                                               |
      | string      | "Rank with optional space", "Rank with optional space ", " Rank with optional space", "Rankwithoptionalspace", "Rank with optional space  "                                                                                                                                                                                                                                                          |
      | boolean     | true                                                                                                                                                                                                                                                                                                                                                                                                 |
      | boolean     | false                                                                                                                                                                                                                                                                                                                                                                                                |
      | boolean     | false, true                                                                                                                                                                                                                                                                                                                                                                                          |
      | double      | 0.0                                                                                                                                                                                                                                                                                                                                                                                                  |
      | double      | 0                                                                                                                                                                                                                                                                                                                                                                                                    |
      | double      | 1.1                                                                                                                                                                                                                                                                                                                                                                                                  |
      | double      | -2.45                                                                                                                                                                                                                                                                                                                                                                                                |
      | double      | -3.444, 3.445                                                                                                                                                                                                                                                                                                                                                                                        |
      | double      | 0.00001, 0.0001, 0.001, 0.01                                                                                                                                                                                                                                                                                                                                                                         |
      | double      | -333.553, 33895, 98984.4555, 902394.44, 1000000000, 0.00001, 0.3, 3.14159265358979323                                                                                                                                                                                                                                                                                                                |
      | decimal     | 0.0dec                                                                                                                                                                                                                                                                                                                                                                                               |
      | decimal     | 1.1dec                                                                                                                                                                                                                                                                                                                                                                                               |
      | decimal     | -2.45dec                                                                                                                                                                                                                                                                                                                                                                                             |
      | decimal     | -3.444dec, 3.445dec                                                                                                                                                                                                                                                                                                                                                                                  |
      | decimal     | 0.00001dec, 0.0001dec, 0.001dec, 0.01dec                                                                                                                                                                                                                                                                                                                                                             |
      | decimal     | -333.553dec, 33895, 98984.4555dec, 902394.44dec, 1000000000.0dec, 0.00001dec, 0.3dec, 3.14159265358979323dec                                                                                                                                                                                                                                                                                         |
      | date        | 2024-06-04                                                                                                                                                                                                                                                                                                                                                                                           |
      | date        | 2024-06-04, 2024-06-09, 2020-07-10                                                                                                                                                                                                                                                                                                                                                                   |
      | datetime    | 2024-06-04                                                                                                                                                                                                                                                                                                                                                                                           |
      | datetime    | 2024-06-04T16:35                                                                                                                                                                                                                                                                                                                                                                                     |
      | datetime    | 2024-06-04T16:35:02                                                                                                                                                                                                                                                                                                                                                                                  |
      | datetime    | 2024-06-04T16:35:02.1                                                                                                                                                                                                                                                                                                                                                                                |
      | datetime    | 2024-06-04T16:35:02.10                                                                                                                                                                                                                                                                                                                                                                               |
      | datetime    | 2024-06-04T16:35:02.103                                                                                                                                                                                                                                                                                                                                                                              |
      | datetime    | 2024-06-04, 2024-06-04T16:35, 2024-06-04T16:35:02, 2024-06-04T16:35:02.01, 2024-06-04T16:35:02.10, 2024-06-04T16:35:02.103                                                                                                                                                                                                                                                                           |
      | datetime-tz | 2024-06-04T00:00:00 Asia/Kathmandu                                                                                                                                                                                                                                                                                                                                                                   |
      | datetime-tz | 2024-06-04T16:35+0100                                                                                                                                                                                                                                                                                                                                                                                |
      | datetime-tz | 2024-06-04T16:35:02+0100                                                                                                                                                                                                                                                                                                                                                                             |
      | datetime-tz | 2024-06-04T16:35:02.1+0100                                                                                                                                                                                                                                                                                                                                                                           |
      | datetime-tz | 2024-06-04T16:35:02.10+0100                                                                                                                                                                                                                                                                                                                                                                          |
      | datetime-tz | 2024-06-04T16:35:02.103+0100                                                                                                                                                                                                                                                                                                                                                                         |
      | datetime-tz | 2024-06-04T00:00+0001, 2024-06-04T00:00 Asia/Kathmandu, 2024-06-04T00:00+0002, 2024-06-04T00:00+0010, 2024-06-04T00:00+0100, 2024-06-04T00:00-0100, 2024-06-04T16:35-0100, 2024-06-04T16:35:02+0200, 2024-06-04T16:35:02.10+1000                                                                                                                                                                     |
      | duration    | P1Y                                                                                                                                                                                                                                                                                                                                                                                                  |
      | duration    | P2M                                                                                                                                                                                                                                                                                                                                                                                                  |
      | duration    | P1Y2M                                                                                                                                                                                                                                                                                                                                                                                                |
      | duration    | P1Y2M3D                                                                                                                                                                                                                                                                                                                                                                                              |
      | duration    | P1Y2M3DT4H                                                                                                                                                                                                                                                                                                                                                                                           |
      | duration    | P1Y2M3DT4H5M                                                                                                                                                                                                                                                                                                                                                                                         |
      | duration    | P1Y2M3DT4H5M6S                                                                                                                                                                                                                                                                                                                                                                                       |
      | duration    | P1Y2M3DT4H5M6.789S                                                                                                                                                                                                                                                                                                                                                                                   |
      | duration    | P1Y, P1Y1M, P1Y1M1D, P1Y1M1DT1H, P1Y1M1DT1H1M, P1Y1M1DT1H1M1S, P1Y1M1DT1H1M1.1S, P1Y1M1DT1H1M1.001S, P1Y1M1DT1H1M0.000001S                                                                                                                                                                                                                                                                           |

    # TODO: Struct parsing is not supported in concept api tests now
#  Scenario: Owns cannot set @values annotation for struct value type
#    When create attribute type: custom-attribute
#    When attribute(custom-attribute) set value type: struct(custom-struct)
#    When entity(person) set owns: custom-attribute
#    When entity(person) get owns(custom-attribute) set annotation: @values(custom-struct); fails
#    When entity(person) get owns(custom-attribute) set annotation: @values({"string"}); fails
#    When entity(person) get owns(custom-attribute) set annotation: @values({custom-field: "string"}); fails
#    When entity(person) get owns(custom-attribute) set annotation: @values(custom-struct{custom-field: "string"}); fails
#    When entity(person) get owns(custom-attribute) set annotation: @values(custom-struct("string")); fails
#    When entity(person) get owns(custom-attribute) set annotation: @values(custom-struct(custom-field: "string")); fails

  Scenario Outline: Owns @values annotation correctly validates nanoseconds
    When create attribute type: today
    When attribute(today) set value type: <value-type>
    When entity(person) set owns: today
    When entity(person) get owns(today) set annotation: @values(<first>, <second>)
    Then entity(person) get owns(today) set annotation: @values(<first>, <first>); fails
    Then entity(person) get owns(today) set annotation: @values(<second>, <second>); fails
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get owns(today) get constraints contain: @values(<first>, <second>)
    Then entity(person) get owns(today) get constraints do not contain: @values(<first>, <first>)
    Then entity(person) get owns(today) get constraints do not contain: @values(<second>, <second>)
    Then entity(person) get owns(today) set annotation: @values(<first>, <first>); fails
    Then entity(person) get owns(today) set annotation: @values(<second>, <second>); fails
    Examples:
      | value-type  | first                              | second                             |
      | datetime    | 2024-05-05T16:15:18.8              | 2024-05-05T16:15:18.9              |
      | datetime    | 2024-05-05T16:15:18.78             | 2024-05-05T16:15:18.79             |
      | datetime    | 2024-05-05T16:15:18.678            | 2024-05-05T16:15:18.679            |
      | datetime    | 2024-05-05T16:15:18.5678           | 2024-05-05T16:15:18.5679           |
      | datetime    | 2024-05-05T16:15:18.45678          | 2024-05-05T16:15:18.45679          |
      | datetime    | 2024-05-05T16:15:18.345678         | 2024-05-05T16:15:18.345679         |
      | datetime    | 2024-05-05T16:15:18.2345678        | 2024-05-05T16:15:18.2345679        |
      | datetime    | 2024-05-05T16:15:18.12345678       | 2024-05-05T16:15:18.12345679       |
      | datetime    | 2024-05-05T16:15:18.112345678      | 2024-05-05T16:15:18.112345679      |
      | datetime-tz | 2024-05-05T16:15:18.8+0010         | 2024-05-05T16:15:18.9+0010         |
      | datetime-tz | 2024-05-05T16:15:18.78+0010        | 2024-05-05T16:15:18.79+0010        |
      | datetime-tz | 2024-05-05T16:15:18.678+0010       | 2024-05-05T16:15:18.679+0010       |
      | datetime-tz | 2024-05-05T16:15:18.5678+0010      | 2024-05-05T16:15:18.5679+0010      |
      | datetime-tz | 2024-05-05T16:15:18.45678+0010     | 2024-05-05T16:15:18.45679+0010     |
      | datetime-tz | 2024-05-05T16:15:18.345678+0010    | 2024-05-05T16:15:18.345679+0010    |
      | datetime-tz | 2024-05-05T16:15:18.2345678+0010   | 2024-05-05T16:15:18.2345679+0010   |
      | datetime-tz | 2024-05-05T16:15:18.12345678+0010  | 2024-05-05T16:15:18.12345679+0010  |
      | datetime-tz | 2024-05-05T16:15:18.112345678+0010 | 2024-05-05T16:15:18.112345679+0010 |

  Scenario Outline: Owns can reset @values annotation with the same argument
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When entity(person) set owns: custom-attribute
    When entity(person) get owns(custom-attribute) set annotation: @values(<args>)
    Then entity(person) get owns(custom-attribute) get constraints contain: @values(<args>)
    When entity(person) get owns(custom-attribute) set annotation: @values(<args>)
    Then entity(person) get owns(custom-attribute) get constraints contain: @values(<args>)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get constraints contain: @values(<args>)
    When entity(person) get owns(custom-attribute) set annotation: @values(<args>)
    Then entity(person) get owns(custom-attribute) get constraints contain: @values(<args>)
    Examples:
      | value-type  | args                                         |
      | integer     | 1, 2                                         |
      | double      | 1.0, 2.0                                     |
      | decimal     | 1.0dec, 2.0dec                               |
      | string      | "str", "str another"                         |
      | boolean     | false, true                                  |
      | date        | 2024-05-06, 2024-05-08                       |
      | datetime    | 2024-05-06, 2024-05-08                       |
      | datetime-tz | 2024-05-07T00:00+0100, 2024-05-10T00:00+0100 |
      | duration    | P1Y, P2Y                                     |

  Scenario Outline: Owns can reset @values annotation with different arguments
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When entity(person) set owns: custom-attribute
    When entity(person) get owns(custom-attribute) set annotation: @values(<args>)
    When entity(person) get owns(custom-attribute) set annotation: @values(<reset-args>)
    Then entity(person) get owns(custom-attribute) get constraints contain: @values(<reset-args>)
    Then entity(person) get owns(custom-attribute) get constraints do not contain: @values(<args>)
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get constraints contain: @values(<reset-args>)
    Then entity(person) get owns(custom-attribute) get constraints do not contain: @values(<args>)
    Examples:
      | value-type  | args                  | reset-args            |
      | integer     | 1, 5                  | 7, 9                  |
      | double      | 1.1, 1.5              | -8.0, 88.3            |
      | decimal     | -8.0dec, 88.3dec      | 1.1dec, 1.5dec        |
      | string      | "s"                   | "not s"               |
      | boolean     | true                  | false                 |
      | date        | 2024-05-05            | 2024-06-05            |
      | datetime    | 2024-05-05            | 2024-06-05            |
      | datetime-tz | 2024-05-05T00:00+0100 | 2024-05-05T00:00+0010 |
      | duration    | P1Y                   | P2Y                   |

  Scenario Outline: Owns-related @values annotation for <value-type> value type can be inherited and specialised by a subset of arguments
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When create attribute type: second-custom-attribute
    When attribute(second-custom-attribute) set value type: <value-type>
    When attribute(second-custom-attribute) set annotation: @abstract
    When create attribute type: specialised-custom-attribute
    When attribute(specialised-custom-attribute) set supertype: second-custom-attribute
    When entity(person) set owns: custom-attribute
    When relation(description) set owns: custom-attribute
    When entity(person) set owns: second-custom-attribute
    When relation(description) set owns: second-custom-attribute
    When entity(person) get owns(custom-attribute) set annotation: @values(<args>)
    When relation(description) get owns(custom-attribute) set annotation: @values(<args>)
    Then entity(person) get owns(custom-attribute) get constraints contain: @values(<args>)
    Then entity(person) get owns(custom-attribute) get declared annotations contain: @values(<args>)
    Then relation(description) get owns(custom-attribute) get constraints contain: @values(<args>)
    Then relation(description) get owns(custom-attribute) get declared annotations contain: @values(<args>)
    When entity(person) get owns(second-custom-attribute) set annotation: @values(<args>)
    When relation(description) get owns(second-custom-attribute) set annotation: @values(<args>)
    Then entity(person) get owns(second-custom-attribute) get constraints contain: @values(<args>)
    Then entity(person) get owns(second-custom-attribute) get declared annotations contain: @values(<args>)
    Then relation(description) get owns(second-custom-attribute) get constraints contain: @values(<args>)
    Then relation(description) get owns(second-custom-attribute) get declared annotations contain: @values(<args>)
    When create entity type: player
    When create relation type: marriage
    When entity(player) set supertype: person
    When relation(marriage) set supertype: description
    When entity(player) set owns: specialised-custom-attribute
    When relation(marriage) set owns: specialised-custom-attribute
    Then entity(player) get owns contain:
      | custom-attribute |
    Then relation(marriage) get owns contain:
      | custom-attribute |
    Then entity(player) get constraints for owned attribute(custom-attribute) contain: @values(<args>)
    Then entity(player) get owns(custom-attribute) get constraints contain: @values(<args>)
    Then entity(player) get owns(custom-attribute) get declared annotations contain: @values(<args>)
    Then relation(marriage) get constraints for owned attribute(custom-attribute) contain: @values(<args>)
    Then relation(marriage) get owns(custom-attribute) get constraints contain: @values(<args>)
    Then relation(marriage) get owns(custom-attribute) get declared annotations contain: @values(<args>)
    Then entity(player) get owns contain:
      | second-custom-attribute      |
      | specialised-custom-attribute |
    Then relation(marriage) get owns contain:
      | second-custom-attribute      |
      | specialised-custom-attribute |
    Then entity(player) get constraints for owned attribute(specialised-custom-attribute) contain: @values(<args>)
    Then entity(player) get owns(specialised-custom-attribute) get constraints do not contain: @values(<args>)
    Then entity(player) get owns(specialised-custom-attribute) get declared annotations do not contain: @values(<args>)
    Then relation(marriage) get constraints for owned attribute(specialised-custom-attribute) contain: @values(<args>)
    Then relation(marriage) get owns(specialised-custom-attribute) get constraints do not contain: @values(<args>)
    Then relation(marriage) get owns(specialised-custom-attribute) get declared annotations do not contain: @values(<args>)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(player) get constraints for owned attribute(custom-attribute) contain: @values(<args>)
    Then entity(player) get owns(custom-attribute) get constraints contain: @values(<args>)
    Then entity(player) get owns(custom-attribute) get declared annotations contain: @values(<args>)
    Then relation(marriage) get constraints for owned attribute(custom-attribute) contain: @values(<args>)
    Then relation(marriage) get owns(custom-attribute) get constraints contain: @values(<args>)
    Then relation(marriage) get owns(custom-attribute) get declared annotations contain: @values(<args>)
    Then entity(player) get constraints for owned attribute(specialised-custom-attribute) contain: @values(<args>)
    Then entity(player) get owns(specialised-custom-attribute) get constraints do not contain: @values(<args>)
    Then entity(player) get owns(specialised-custom-attribute) get declared annotations do not contain: @values(<args>)
    Then relation(marriage) get constraints for owned attribute(specialised-custom-attribute) contain: @values(<args>)
    Then relation(marriage) get owns(specialised-custom-attribute) get constraints do not contain: @values(<args>)
    Then relation(marriage) get owns(specialised-custom-attribute) get declared annotations do not contain: @values(<args>)
    When entity(player) get owns(custom-attribute) set annotation: @values(<args-specialise>)
    When relation(marriage) get owns(custom-attribute) set annotation: @values(<args-specialise>)
    When entity(player) get owns(specialised-custom-attribute) set annotation: @values(<args-specialise>)
    When relation(marriage) get owns(specialised-custom-attribute) set annotation: @values(<args-specialise>)
    Then entity(person) get constraints for owned attribute(custom-attribute) contain: @values(<args-specialise>)
    Then entity(person) get owns(custom-attribute) get constraints contain: @values(<args-specialise>)
    Then entity(person) get constraints for owned attribute(custom-attribute) do not contain: @values(<args>)
    Then entity(person) get owns(custom-attribute) get constraints do not contain: @values(<args>)
    Then entity(person) get constraints for owned attribute(second-custom-attribute) do not contain: @values(<args-specialise>)
    Then entity(person) get owns(second-custom-attribute) get constraints do not contain: @values(<args-specialise>)
    Then entity(person) get constraints for owned attribute(second-custom-attribute) contain: @values(<args>)
    Then entity(person) get owns(second-custom-attribute) get constraints contain: @values(<args>)
    Then entity(player) get constraints for owned attribute(custom-attribute) contain: @values(<args-specialise>)
    Then entity(player) get owns(custom-attribute) get constraints contain: @values(<args-specialise>)
    Then entity(player) get constraints for owned attribute(custom-attribute) do not contain: @values(<args>)
    Then entity(player) get owns(custom-attribute) get constraints do not contain: @values(<args>)
    Then entity(player) get constraints for owned attribute(specialised-custom-attribute) contain: @values(<args-specialise>)
    Then entity(player) get owns(specialised-custom-attribute) get constraints contain: @values(<args-specialise>)
    Then entity(player) get constraints for owned attribute(specialised-custom-attribute) contain: @values(<args>)
    Then entity(player) get owns(specialised-custom-attribute) get constraints do not contain: @values(<args>)
    Then entity(player) get constraints for owned attribute(second-custom-attribute) do not contain: @values(<args-specialise>)
    Then entity(player) get owns(second-custom-attribute) get constraints do not contain: @values(<args-specialise>)
    Then entity(player) get constraints for owned attribute(second-custom-attribute) contain: @values(<args>)
    Then entity(player) get owns(second-custom-attribute) get constraints contain: @values(<args>)
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get constraints for owned attribute(custom-attribute) contain: @values(<args-specialise>)
    Then entity(person) get owns(custom-attribute) get constraints contain: @values(<args-specialise>)
    Then entity(person) get constraints for owned attribute(custom-attribute) do not contain: @values(<args>)
    Then entity(person) get owns(custom-attribute) get constraints do not contain: @values(<args>)
    Then entity(person) get constraints for owned attribute(second-custom-attribute) do not contain: @values(<args-specialise>)
    Then entity(person) get owns(second-custom-attribute) get constraints do not contain: @values(<args-specialise>)
    Then entity(person) get constraints for owned attribute(second-custom-attribute) contain: @values(<args>)
    Then entity(person) get owns(second-custom-attribute) get constraints contain: @values(<args>)
    Then entity(player) get constraints for owned attribute(custom-attribute) contain: @values(<args-specialise>)
    Then entity(player) get owns(custom-attribute) get constraints contain: @values(<args-specialise>)
    Then entity(player) get constraints for owned attribute(custom-attribute) do not contain: @values(<args>)
    Then entity(player) get owns(custom-attribute) get constraints do not contain: @values(<args>)
    Then entity(player) get constraints for owned attribute(specialised-custom-attribute) contain: @values(<args-specialise>)
    Then entity(player) get owns(specialised-custom-attribute) get constraints contain: @values(<args-specialise>)
    Then entity(player) get constraints for owned attribute(specialised-custom-attribute) contain: @values(<args>)
    Then entity(player) get owns(specialised-custom-attribute) get constraints do not contain: @values(<args>)
    Then entity(player) get constraints for owned attribute(second-custom-attribute) do not contain: @values(<args-specialise>)
    Then entity(player) get owns(second-custom-attribute) get constraints do not contain: @values(<args-specialise>)
    Then entity(player) get constraints for owned attribute(second-custom-attribute) contain: @values(<args>)
    Then entity(player) get owns(second-custom-attribute) get constraints contain: @values(<args>)
    Examples:
      | value-type  | args                                                                                                 | args-specialise                                        |
      | integer     | 1, 10, 20, 30                                                                                        | 10, 30                                                 |
      | double      | 1.0, 2.0, 3.0, 4.5                                                                                   | 2.0                                                    |
      | decimal     | 0.0dec, 1.0dec                                                                                       | 0.0dec                                                 |
      | string      | "john", "John", "Johnny", "johnny"                                                                   | "John", "Johnny"                                       |
      | boolean     | true, false                                                                                          | true                                                   |
      | date        | 2024-06-04, 2024-06-05, 2024-06-06                                                                   | 2024-06-04, 2024-06-06                                 |
      | datetime    | 2024-06-04, 2024-06-05, 2024-06-06                                                                   | 2024-06-04, 2024-06-06                                 |
      | datetime-tz | 2024-06-04T00:00+0010, 2024-06-04T00:00 Asia/Kathmandu, 2024-06-05T00:00+0010, 2024-06-05T00:00+0100 | 2024-06-04T00:00 Asia/Kathmandu, 2024-06-05T00:00+0010 |
      | duration    | P6M, P1Y, P1Y1M, P1Y2M, P1Y3M, P1Y4M, P1Y6M                                                          | P6M, P1Y3M, P1Y4M, P1Y6M                               |

  Scenario Outline: Inherited @values annotation on owns for <value-type> value type can be reset or specialised by the @values of not a subset of arguments
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When create attribute type: second-custom-attribute
    When attribute(second-custom-attribute) set value type: <value-type>
    When attribute(second-custom-attribute) set annotation: @abstract
    When create attribute type: specialised-custom-attribute
    When attribute(specialised-custom-attribute) set supertype: second-custom-attribute
    When entity(person) set owns: custom-attribute
    When relation(description) set owns: custom-attribute
    When entity(person) set owns: second-custom-attribute
    When relation(description) set owns: second-custom-attribute
    When entity(person) get owns(custom-attribute) set annotation: @values(<args>)
    When relation(description) get owns(custom-attribute) set annotation: @values(<args>)
    Then entity(person) get owns(custom-attribute) get constraints contain: @values(<args>)
    Then relation(description) get owns(custom-attribute) get constraints contain: @values(<args>)
    When entity(person) get owns(second-custom-attribute) set annotation: @values(<args>)
    When relation(description) get owns(second-custom-attribute) set annotation: @values(<args>)
    Then entity(person) get owns(second-custom-attribute) get constraints contain: @values(<args>)
    Then relation(description) get owns(second-custom-attribute) get constraints contain: @values(<args>)
    When create entity type: player
    When create relation type: marriage
    When entity(player) set supertype: person
    When relation(marriage) set supertype: description
    When entity(player) set owns: specialised-custom-attribute
    When relation(marriage) set owns: specialised-custom-attribute
    Then entity(player) get owns(custom-attribute) get constraints contain: @values(<args>)
    Then relation(marriage) get owns(custom-attribute) get constraints contain: @values(<args>)
    Then entity(player) get constraints for owned attribute(specialised-custom-attribute) contain: @values(<args>)
    Then entity(player) get owns(specialised-custom-attribute) get constraints do not contain: @values(<args>)
    Then relation(marriage) get constraints for owned attribute(specialised-custom-attribute) contain: @values(<args>)
    Then relation(marriage) get owns(specialised-custom-attribute) get constraints do not contain: @values(<args>)
    When entity(player) get owns(custom-attribute) set annotation: @values(<args-specialise>)
    When relation(marriage) get owns(custom-attribute) set annotation: @values(<args-specialise>)
    When entity(player) get owns(specialised-custom-attribute) set annotation: @values(<args-specialise>)
    When relation(marriage) get owns(specialised-custom-attribute) set annotation: @values(<args-specialise>)
    Then entity(person) get constraints for owned attribute(custom-attribute) contain: @values(<args-specialise>)
    Then entity(person) get owns(custom-attribute) get constraints contain: @values(<args-specialise>)
    Then entity(person) get constraints for owned attribute(custom-attribute) do not contain: @values(<args>)
    Then entity(person) get owns(custom-attribute) get constraints do not contain: @values(<args>)
    Then entity(person) get constraints for owned attribute(second-custom-attribute) do not contain: @values(<args-specialise>)
    Then entity(person) get owns(second-custom-attribute) get constraints do not contain: @values(<args-specialise>)
    Then entity(person) get constraints for owned attribute(second-custom-attribute) contain: @values(<args>)
    Then entity(person) get owns(second-custom-attribute) get constraints contain: @values(<args>)
    Then entity(player) get constraints for owned attribute(custom-attribute) contain: @values(<args-specialise>)
    Then entity(player) get owns(custom-attribute) get constraints contain: @values(<args-specialise>)
    Then entity(player) get constraints for owned attribute(custom-attribute) do not contain: @values(<args>)
    Then entity(player) get owns(custom-attribute) get constraints do not contain: @values(<args>)
    Then entity(player) get constraints for owned attribute(specialised-custom-attribute) contain: @values(<args-specialise>)
    Then entity(player) get owns(specialised-custom-attribute) get constraints contain: @values(<args-specialise>)
    Then entity(player) get constraints for owned attribute(specialised-custom-attribute) contain: @values(<args>)
    Then entity(player) get owns(specialised-custom-attribute) get constraints do not contain: @values(<args>)
    Then entity(player) get constraints for owned attribute(second-custom-attribute) do not contain: @values(<args-specialise>)
    Then entity(player) get owns(second-custom-attribute) get constraints do not contain: @values(<args-specialise>)
    Then entity(player) get constraints for owned attribute(second-custom-attribute) contain: @values(<args>)
    Then entity(player) get owns(second-custom-attribute) get constraints contain: @values(<args>)
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get constraints for owned attribute(custom-attribute) contain: @values(<args-specialise>)
    Then entity(person) get owns(custom-attribute) get constraints contain: @values(<args-specialise>)
    Then entity(person) get constraints for owned attribute(custom-attribute) do not contain: @values(<args>)
    Then entity(person) get owns(custom-attribute) get constraints do not contain: @values(<args>)
    Then entity(person) get constraints for owned attribute(second-custom-attribute) do not contain: @values(<args-specialise>)
    Then entity(person) get owns(second-custom-attribute) get constraints do not contain: @values(<args-specialise>)
    Then entity(person) get constraints for owned attribute(second-custom-attribute) contain: @values(<args>)
    Then entity(person) get owns(second-custom-attribute) get constraints contain: @values(<args>)
    Then entity(player) get constraints for owned attribute(custom-attribute) contain: @values(<args-specialise>)
    Then entity(player) get owns(custom-attribute) get constraints contain: @values(<args-specialise>)
    Then entity(player) get constraints for owned attribute(custom-attribute) do not contain: @values(<args>)
    Then entity(player) get owns(custom-attribute) get constraints do not contain: @values(<args>)
    Then entity(player) get constraints for owned attribute(specialised-custom-attribute) contain: @values(<args-specialise>)
    Then entity(player) get owns(specialised-custom-attribute) get constraints contain: @values(<args-specialise>)
    Then entity(player) get constraints for owned attribute(specialised-custom-attribute) contain: @values(<args>)
    Then entity(player) get owns(specialised-custom-attribute) get constraints do not contain: @values(<args>)
    Then entity(player) get constraints for owned attribute(second-custom-attribute) do not contain: @values(<args-specialise>)
    Then entity(player) get owns(second-custom-attribute) get constraints do not contain: @values(<args-specialise>)
    Then entity(player) get constraints for owned attribute(second-custom-attribute) contain: @values(<args>)
    Then entity(player) get owns(second-custom-attribute) get constraints contain: @values(<args>)
    Examples:
      | value-type  | args                                                                                                 | args-specialise                |
      | integer     | 1, 10, 20, 30                                                                                        | 10, 31                         |
      | double      | 1.0, 2.0, 3.0, 4.5                                                                                   | 2.001                          |
      | decimal     | 0.0dec, 1.0dec                                                                                       | 0.01dec                        |
      | string      | "john", "John", "Johnny", "johnny"                                                                   | "Jonathan"                     |
      | boolean     | false                                                                                                | true                           |
      | date        | 2024-06-04, 2024-06-05, 2024-06-06                                                                   | 2020-06-04, 2020-06-06         |
      | datetime    | 2024-06-04, 2024-06-05, 2024-06-06                                                                   | 2020-06-04, 2020-06-06         |
      | datetime-tz | 2024-06-04T00:00+0010, 2024-06-04T00:00 Asia/Kathmandu, 2024-06-05T00:00+0010, 2024-06-05T00:00+0100 | 2024-06-04T00:00 Europe/London |
      | duration    | P6M, P1Y, P1Y1M, P1Y2M, P1Y3M, P1Y4M, P1Y6M                                                          | P3M, P1Y3M, P1Y4M, P1Y6M       |

  Scenario Outline: Values can be narrowed for the same attribute for <root-type>'s owns
    When create attribute type: name
    When attribute(name) set value type: integer
    When <root-type>(<supertype-name>) set owns: name
    When <root-type>(<supertype-name>) get owns(name) set annotation: @values(0, 1, 2, 3, 4, 5)
    When <root-type>(<subtype-name>) set supertype: <supertype-name>
    When <root-type>(<subtype-name-2>) set supertype: <subtype-name>
    When <root-type>(<subtype-name>) set owns: name
    Then <root-type>(<supertype-name>) get constraints for owned attribute(name) contain: @values(0, 1, 2, 3, 4, 5)
    Then <root-type>(<subtype-name>) get constraints for owned attribute(name) contain: @values(0, 1, 2, 3, 4, 5)
    Then <root-type>(<subtype-name-2>) get constraints for owned attribute(name) contain: @values(0, 1, 2, 3, 4, 5)
    Then <root-type>(<supertype-name>) get owns(name) get constraints contain: @values(0, 1, 2, 3, 4, 5)
    Then <root-type>(<subtype-name>) get owns(name) get constraints do not contain: @values(0, 1, 2, 3, 4, 5)
    Then <root-type>(<subtype-name-2>) get owns(name) get constraints do not contain: @values(0, 1, 2, 3, 4, 5)
    Then <root-type>(<supertype-name>) get owns(name) get declared annotations contain: @values(0, 1, 2, 3, 4, 5)
    Then <root-type>(<subtype-name>) get owns(name) get declared annotations do not contain: @values(0, 1, 2, 3, 4, 5)
    Then <root-type>(<subtype-name-2>) get owns(name) get declared annotations do not contain: @values(0, 1, 2, 3, 4, 5)
    When <root-type>(<subtype-name>) get owns(name) set annotation: @values(2, 3, 4, 5)
    Then <root-type>(<supertype-name>) get constraints for owned attribute(name) contain: @values(0, 1, 2, 3, 4, 5)
    Then <root-type>(<subtype-name>) get constraints for owned attribute(name) contain: @values(0, 1, 2, 3, 4, 5)
    Then <root-type>(<subtype-name-2>) get constraints for owned attribute(name) contain: @values(0, 1, 2, 3, 4, 5)
    Then <root-type>(<supertype-name>) get owns(name) get constraints contain: @values(0, 1, 2, 3, 4, 5)
    Then <root-type>(<subtype-name>) get owns(name) get constraints do not contain: @values(0, 1, 2, 3, 4, 5)
    Then <root-type>(<subtype-name-2>) get owns(name) get constraints do not contain: @values(0, 1, 2, 3, 4, 5)
    Then <root-type>(<supertype-name>) get owns(name) get declared annotations contain: @values(0, 1, 2, 3, 4, 5)
    Then <root-type>(<subtype-name>) get owns(name) get declared annotations do not contain: @values(0, 1, 2, 3, 4, 5)
    Then <root-type>(<subtype-name-2>) get owns(name) get declared annotations do not contain: @values(0, 1, 2, 3, 4, 5)
    Then <root-type>(<supertype-name>) get constraints for owned attribute(name) do not contain: @values(2, 3, 4, 5)
    Then <root-type>(<subtype-name>) get constraints for owned attribute(name) contain: @values(2, 3, 4, 5)
    Then <root-type>(<subtype-name-2>) get constraints for owned attribute(name) contain: @values(2, 3, 4, 5)
    Then <root-type>(<supertype-name>) get owns(name) get constraints do not contain: @values(2, 3, 4, 5)
    Then <root-type>(<subtype-name>) get owns(name) get constraints contain: @values(2, 3, 4, 5)
    Then <root-type>(<subtype-name-2>) get owns(name) get constraints contain: @values(2, 3, 4, 5)
    Then <root-type>(<supertype-name>) get owns(name) get declared annotations do not contain: @values(2, 3, 4, 5)
    Then <root-type>(<subtype-name>) get owns(name) get declared annotations contain: @values(2, 3, 4, 5)
    Then <root-type>(<subtype-name-2>) get owns(name) get declared annotations contain: @values(2, 3, 4, 5)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<supertype-name>) get constraints for owned attribute(name) contain: @values(0, 1, 2, 3, 4, 5)
    Then <root-type>(<subtype-name>) get constraints for owned attribute(name) contain: @values(0, 1, 2, 3, 4, 5)
    Then <root-type>(<subtype-name-2>) get constraints for owned attribute(name) contain: @values(0, 1, 2, 3, 4, 5)
    Then <root-type>(<supertype-name>) get owns(name) get constraints contain: @values(0, 1, 2, 3, 4, 5)
    Then <root-type>(<subtype-name>) get owns(name) get constraints do not contain: @values(0, 1, 2, 3, 4, 5)
    Then <root-type>(<subtype-name-2>) get owns(name) get constraints do not contain: @values(0, 1, 2, 3, 4, 5)
    Then <root-type>(<supertype-name>) get owns(name) get declared annotations contain: @values(0, 1, 2, 3, 4, 5)
    Then <root-type>(<subtype-name>) get owns(name) get declared annotations do not contain: @values(0, 1, 2, 3, 4, 5)
    Then <root-type>(<subtype-name-2>) get owns(name) get declared annotations do not contain: @values(0, 1, 2, 3, 4, 5)
    Then <root-type>(<supertype-name>) get constraints for owned attribute(name) do not contain: @values(2, 3, 4, 5)
    Then <root-type>(<subtype-name>) get constraints for owned attribute(name) contain: @values(2, 3, 4, 5)
    Then <root-type>(<subtype-name-2>) get constraints for owned attribute(name) contain: @values(2, 3, 4, 5)
    Then <root-type>(<supertype-name>) get owns(name) get constraints do not contain: @values(2, 3, 4, 5)
    Then <root-type>(<subtype-name>) get owns(name) get constraints contain: @values(2, 3, 4, 5)
    Then <root-type>(<subtype-name-2>) get owns(name) get constraints contain: @values(2, 3, 4, 5)
    Then <root-type>(<supertype-name>) get owns(name) get declared annotations do not contain: @values(2, 3, 4, 5)
    Then <root-type>(<subtype-name>) get owns(name) get declared annotations contain: @values(2, 3, 4, 5)
    Then <root-type>(<subtype-name-2>) get owns(name) get declared annotations contain: @values(2, 3, 4, 5)
    When <root-type>(<subtype-name-2>) set owns: name
    Then <root-type>(<subtype-name-2>) get constraints for owned attribute(name) contain: @values(2, 3, 4, 5)
    Then <root-type>(<subtype-name-2>) get owns(name) get constraints do not contain: @values(2, 3, 4, 5)
    Then <root-type>(<subtype-name-2>) get owns(name) get declared annotations do not contain: @values(2, 3, 4, 5)
    When <root-type>(<subtype-name-2>) get owns(name) set annotation: @values(2, 3)
    Then <root-type>(<supertype-name>) get constraints for owned attribute(name) contain: @values(0, 1, 2, 3, 4, 5)
    Then <root-type>(<subtype-name>) get constraints for owned attribute(name) contain: @values(0, 1, 2, 3, 4, 5)
    Then <root-type>(<subtype-name-2>) get constraints for owned attribute(name) contain: @values(0, 1, 2, 3, 4, 5)
    Then <root-type>(<supertype-name>) get owns(name) get constraints contain: @values(0, 1, 2, 3, 4, 5)
    Then <root-type>(<subtype-name>) get owns(name) get constraints do not contain: @values(0, 1, 2, 3, 4, 5)
    Then <root-type>(<subtype-name-2>) get owns(name) get constraints do not contain: @values(0, 1, 2, 3, 4, 5)
    Then <root-type>(<supertype-name>) get owns(name) get declared annotations contain: @values(0, 1, 2, 3, 4, 5)
    Then <root-type>(<subtype-name>) get owns(name) get declared annotations do not contain: @values(0, 1, 2, 3, 4, 5)
    Then <root-type>(<subtype-name-2>) get owns(name) get declared annotations do not contain: @values(0, 1, 2, 3, 4, 5)
    Then <root-type>(<supertype-name>) get constraints for owned attribute(name) do not contain: @values(2, 3, 4, 5)
    Then <root-type>(<subtype-name>) get constraints for owned attribute(name) contain: @values(2, 3, 4, 5)
    Then <root-type>(<subtype-name-2>) get constraints for owned attribute(name) contain: @values(2, 3, 4, 5)
    Then <root-type>(<supertype-name>) get owns(name) get constraints do not contain: @values(2, 3, 4, 5)
    Then <root-type>(<subtype-name>) get owns(name) get constraints contain: @values(2, 3, 4, 5)
    Then <root-type>(<subtype-name-2>) get owns(name) get constraints do not contain: @values(2, 3, 4, 5)
    Then <root-type>(<supertype-name>) get owns(name) get declared annotations do not contain: @values(2, 3, 4, 5)
    Then <root-type>(<subtype-name>) get owns(name) get declared annotations contain: @values(2, 3, 4, 5)
    Then <root-type>(<subtype-name-2>) get owns(name) get declared annotations do not contain: @values(2, 3, 4, 5)
    Then <root-type>(<supertype-name>) get constraints for owned attribute(name) do not contain: @values(2, 3)
    Then <root-type>(<subtype-name>) get constraints for owned attribute(name) do not contain: @values(2, 3)
    Then <root-type>(<subtype-name-2>) get constraints for owned attribute(name) contain: @values(2, 3)
    Then <root-type>(<supertype-name>) get owns(name) get constraints do not contain: @values(2, 3)
    Then <root-type>(<subtype-name>) get owns(name) get constraints do not contain: @values(2, 3)
    Then <root-type>(<subtype-name-2>) get owns(name) get constraints contain: @values(2, 3)
    Then <root-type>(<supertype-name>) get owns(name) get declared annotations do not contain: @values(2, 3)
    Then <root-type>(<subtype-name>) get owns(name) get declared annotations do not contain: @values(2, 3)
    Then <root-type>(<subtype-name-2>) get owns(name) get declared annotations contain: @values(2, 3)
    When transaction commits
    When connection open read transaction for database: typedb
    Then <root-type>(<supertype-name>) get constraints for owned attribute(name) contain: @values(0, 1, 2, 3, 4, 5)
    Then <root-type>(<subtype-name>) get constraints for owned attribute(name) contain: @values(0, 1, 2, 3, 4, 5)
    Then <root-type>(<subtype-name-2>) get constraints for owned attribute(name) contain: @values(0, 1, 2, 3, 4, 5)
    Then <root-type>(<supertype-name>) get owns(name) get constraints contain: @values(0, 1, 2, 3, 4, 5)
    Then <root-type>(<subtype-name>) get owns(name) get constraints do not contain: @values(0, 1, 2, 3, 4, 5)
    Then <root-type>(<subtype-name-2>) get owns(name) get constraints do not contain: @values(0, 1, 2, 3, 4, 5)
    Then <root-type>(<supertype-name>) get owns(name) get declared annotations contain: @values(0, 1, 2, 3, 4, 5)
    Then <root-type>(<subtype-name>) get owns(name) get declared annotations do not contain: @values(0, 1, 2, 3, 4, 5)
    Then <root-type>(<subtype-name-2>) get owns(name) get declared annotations do not contain: @values(0, 1, 2, 3, 4, 5)
    Then <root-type>(<supertype-name>) get constraints for owned attribute(name) do not contain: @values(2, 3, 4, 5)
    Then <root-type>(<subtype-name>) get constraints for owned attribute(name) contain: @values(2, 3, 4, 5)
    Then <root-type>(<subtype-name-2>) get constraints for owned attribute(name) contain: @values(2, 3, 4, 5)
    Then <root-type>(<supertype-name>) get owns(name) get constraints do not contain: @values(2, 3, 4, 5)
    Then <root-type>(<subtype-name>) get owns(name) get constraints contain: @values(2, 3, 4, 5)
    Then <root-type>(<subtype-name-2>) get owns(name) get constraints do not contain: @values(2, 3, 4, 5)
    Then <root-type>(<supertype-name>) get owns(name) get declared annotations do not contain: @values(2, 3, 4, 5)
    Then <root-type>(<subtype-name>) get owns(name) get declared annotations contain: @values(2, 3, 4, 5)
    Then <root-type>(<subtype-name-2>) get owns(name) get declared annotations do not contain: @values(2, 3, 4, 5)
    Then <root-type>(<supertype-name>) get constraints for owned attribute(name) do not contain: @values(2, 3)
    Then <root-type>(<subtype-name>) get constraints for owned attribute(name) do not contain: @values(2, 3)
    Then <root-type>(<subtype-name-2>) get constraints for owned attribute(name) contain: @values(2, 3)
    Then <root-type>(<supertype-name>) get owns(name) get constraints do not contain: @values(2, 3)
    Then <root-type>(<subtype-name>) get owns(name) get constraints do not contain: @values(2, 3)
    Then <root-type>(<subtype-name-2>) get owns(name) get constraints contain: @values(2, 3)
    Then <root-type>(<supertype-name>) get owns(name) get declared annotations do not contain: @values(2, 3)
    Then <root-type>(<subtype-name>) get owns(name) get declared annotations do not contain: @values(2, 3)
    Then <root-type>(<subtype-name-2>) get owns(name) get declared annotations contain: @values(2, 3)
    Examples:
      | root-type | supertype-name | subtype-name | subtype-name-2 |
      | entity    | person         | customer     | subscriber     |
      | relation  | description    | registration | profile        |

  Scenario: Owns can change attribute type value type and @values through @values resetting
    When create attribute type: name
    When create attribute type: surname
    When attribute(name) set annotation: @abstract
    When attribute(surname) set supertype: name
    When attribute(surname) set value type: string
    When entity(person) set owns: name
    When entity(customer) set owns: surname
    When entity(customer) get owns(surname) set annotation: @values("only this string is allowed")
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(name) set value type: integer; fails
    Then attribute(surname) set value type: integer; fails
    When entity(customer) get owns(surname) unset annotation: @values
    Then attribute(surname) unset value type; fails
    When attribute(surname) set value type: integer
    When attribute(name) set value type: integer
    When attribute(surname) unset value type
    When entity(customer) get owns(surname) set annotation: @values(1, 2, 3)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(customer) get owns(surname) get constraints contain: @values(1, 2, 3)
    Then attribute(surname) get value type: integer
    When entity(person) get owns(name) set annotation: @values(1, 2, 3)
    When entity(customer) get owns(surname) unset annotation: @values
    Then entity(customer) get constraints for owned attribute(surname) contain: @values(1, 2, 3)
    Then entity(customer) get owns(surname) get constraints do not contain: @values(1, 2, 3)
    Then attribute(surname) set value type: string; fails
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(customer) get constraints for owned attribute(surname) contain: @values(1, 2, 3)
    Then entity(customer) get owns(surname) get constraints do not contain: @values(1, 2, 3)
    Then attribute(surname) get value type: integer

########################
# @range
########################
  Scenario Outline: Ordered owns can set @range annotation for <value-type> value type in correct order and unset it
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When create attribute type: custom-attribute-2
    When attribute(custom-attribute-2) set value type: <value-type>
    When entity(person) set owns: custom-attribute
    Then entity(person) get owns(custom-attribute) set annotation: @range(<arg1>..<arg0>); fails
    Then entity(person) get owns(custom-attribute) set annotation: @range(..); fails
    Then entity(person) get owns(custom-attribute) get constraint categories do not contain: @range
    When entity(person) get owns(custom-attribute) set annotation: @range(<arg0>..<arg1>)
    Then entity(person) get owns(custom-attribute) get constraints contain: @range(<arg0>..<arg1>)
    When entity(person) set owns: custom-attribute-2
    When entity(person) get owns(custom-attribute-2) set ordering: ordered
    Then entity(person) get owns(custom-attribute-2) set annotation: @range(<arg1>..<arg0>); fails
    Then entity(person) get owns(custom-attribute-2) get constraint categories do not contain: @range
    When entity(person) get owns(custom-attribute-2) set annotation: @range(<arg0>..<arg1>)
    Then entity(person) get owns(custom-attribute-2) get constraints contain: @range(<arg0>..<arg1>)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get constraints contain: @range(<arg0>..<arg1>)
    Then entity(person) get owns(custom-attribute-2) get constraints contain: @range(<arg0>..<arg1>)
    When entity(person) unset owns: custom-attribute
    When entity(person) unset owns: custom-attribute-2
    Then entity(person) get owns is empty
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get owns is empty
    When entity(person) set owns: custom-attribute
    When entity(person) get owns(custom-attribute) set annotation: @range(..<arg1>)
    Then entity(person) get owns(custom-attribute) get constraints contain: @range(..<arg1>)
    Then entity(person) get owns(custom-attribute) get declared annotations contain: @range(..<arg1>)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get constraints contain: @range(..<arg1>)
    Then entity(person) get owns(custom-attribute) get declared annotations contain: @range(..<arg1>)
    When entity(person) get owns(custom-attribute) unset annotation: @range
    Then entity(person) get owns(custom-attribute) get constraints do not contain: @range(..<arg1>)
    Then entity(person) get owns(custom-attribute) get declared annotations do not contain: @range(..<arg1>)
    Then entity(person) get owns(custom-attribute) get constraint categories do not contain: @range
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get constraints do not contain: @range(..<arg1>)
    Then entity(person) get owns(custom-attribute) get declared annotations do not contain: @range(..<arg1>)
    Then entity(person) get owns(custom-attribute) get constraint categories do not contain: @range
    When entity(person) get owns(custom-attribute) set annotation: @range(<arg0>..)
    Then entity(person) get owns(custom-attribute) get constraints contain: @range(<arg0>..)
    Then entity(person) get owns(custom-attribute) get declared annotations contain: @range(<arg0>..)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get constraints contain: @range(<arg0>..)
    Then entity(person) get owns(custom-attribute) get declared annotations contain: @range(<arg0>..)
    When entity(person) get owns(custom-attribute) unset annotation: @range
    Then entity(person) get owns(custom-attribute) get constraints do not contain: @range(<arg0>..)
    Then entity(person) get owns(custom-attribute) get declared annotations do not contain: @range(<arg0>..)
    Then entity(person) get owns(custom-attribute) get constraint categories do not contain: @range
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get constraint categories do not contain: @range
    Examples:
      | value-type  | arg0                              | arg1                                                  |
      | integer     | 0                                 | 1                                                     |
      | integer     | 1                                 | 2                                                     |
      | integer     | 0                                 | 2                                                     |
      | integer     | -1                                | 1                                                     |
      | integer     | -9223372036854775808              | 9223372036854775807                                   |
      | string      | "A"                               | "a"                                                   |
      | string      | "a"                               | "z"                                                   |
      | string      | "A"                               | "福"                                                   |
      | string      | "AA"                              | "AAA"                                                 |
      | string      | "short string"                    | "very-very-very-very-very-very-very-very long string" |
      | boolean     | false                             | true                                                  |
      | double      | 0.0                               | 0.0001                                                |
      | double      | 0.01                              | 1.0                                                   |
      | double      | 123.123                           | 123123123123.122                                      |
      | double      | -2.45                             | 2.45                                                  |
      | decimal     | 0.0dec                            | 0.0001dec                                             |
      | decimal     | 0.01dec                           | 1.0dec                                                |
      | decimal     | 123.123dec                        | 123123123123.122dec                                   |
      | decimal     | -2.45dec                          | 2.45dec                                               |
      | date        | 2024-06-04                        | 2024-06-05                                            |
      | date        | 2024-06-04                        | 2024-07-03                                            |
      | date        | 2024-06-04                        | 2025-01-01                                            |
      | date        | 1970-01-01                        | 9999-12-12                                            |
      | datetime    | 2024-06-04                        | 2024-06-05                                            |
      | datetime    | 2024-06-04                        | 2024-07-03                                            |
      | datetime    | 2024-06-04                        | 2025-01-01                                            |
      | datetime    | 1970-01-01                        | 9999-12-12                                            |
      | datetime    | 2024-06-04T16:35:02.10            | 2024-06-04T16:35:02.11                                |
      | datetime-tz | 2024-06-04T16:35:02.103+0100      | 2024-06-04T16:35:02.104+0100                          |
      | datetime-tz | 2024-06-04T00:00 Asia/Kathmandu   | 2024-06-05T00:00 Asia/Kathmandu                       |
      | datetime-tz | 2024-05-05T00:00:00 Europe/Berlin | 2024-05-05T00:00:00 Europe/London                     |

    # TODO: Struct parsing is not supported now
#  Scenario: Owns cannot set @range annotation for struct value type
#    When create attribute type: custom-attribute
#    When attribute(custom-attribute) set value type: struct(custom-struct)
#    When entity(person) set owns: custom-attribute
#    When entity(person) get owns(custom-attribute) set annotation: @range(custom-struct..custom-struct); fails
#    When entity(person) get owns(custom-attribute) set annotation: @range({"string"}..{"string+1"}); fails
#    When entity(person) get owns(custom-attribute) set annotation: @range({custom-field: "string"}..{custom-field: "string+1"}); fails
#    When entity(person) get owns(custom-attribute) set annotation: @range(custom-struct{custom-field: "string"}..custom-struct{custom-field: "string+1"}); fails
#    When entity(person) get owns(custom-attribute) set annotation: @range(custom-struct("string")..custom-struct("string+1")); fails
#    When entity(person) get owns(custom-attribute) set annotation: @range(custom-struct(custom-field: "string")..custom-struct(custom-field: "string+1")); fails

  Scenario Outline: Owns cannot set @range annotation with <value-type> value type
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When entity(person) set owns: custom-attribute
    Then entity(person) get owns(custom-attribute) set annotation: @range(<arg0>..<arg1>); fails
    Then entity(person) get owns(custom-attribute) get constraints do not contain: @range(<arg0>..<arg1>)
    Then entity(person) get owns(custom-attribute) get declared annotations do not contain: @range(<arg0>..<arg1>)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get constraints do not contain: @range(<arg0>..<arg1>)
    Then entity(person) get owns(custom-attribute) get declared annotations do not contain: @range(<arg0>..<arg1>)
    Then entity(person) get owns(custom-attribute) set annotation: @range(<arg0>..<arg1>); fails
    Then entity(person) get owns(custom-attribute) get constraints do not contain: @range(<arg0>..<arg1>)
    Then entity(person) get owns(custom-attribute) get declared annotations do not contain: @range(<arg0>..<arg1>)
    When transaction closes
    When connection open read transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get constraints do not contain: @range(<arg0>..<arg1>)
    Then entity(person) get owns(custom-attribute) get declared annotations do not contain: @range(<arg0>..<arg1>)
    Examples:
      | value-type | arg0               | arg1               |
      | duration   | P1Y                | P2Y                |
      | duration   | P2M                | P1Y2M              |
      | duration   | P1Y2M              | P1Y2M3DT4H5M6.789S |
      | duration   | P1Y2M3DT4H5M6.788S | P1Y2M3DT4H5M6.789S |

  Scenario Outline: Owns @range annotation correctly validates nanoseconds
    When create attribute type: today
    When attribute(today) set value type: <value-type>
    When entity(person) set owns: today
    When entity(person) get owns(today) set annotation: @range(<from>..<to>)
    Then entity(person) get owns(today) set annotation: @range(<to>..<from>); fails
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get owns(today) get constraints contain: @range(<from>..<to>)
    Then entity(person) get owns(today) get constraints do not contain: @range(<to>..<from>)
    Then entity(person) get owns(today) set annotation: @range(<to>..<from>); fails
    Examples:
      | value-type  | from                               | to                                 |
      | datetime    | 2024-05-05T16:15:18.8              | 2024-05-05T16:15:18.9              |
      | datetime    | 2024-05-05T16:15:18.78             | 2024-05-05T16:15:18.79             |
      | datetime    | 2024-05-05T16:15:18.678            | 2024-05-05T16:15:18.679            |
      | datetime    | 2024-05-05T16:15:18.5678           | 2024-05-05T16:15:18.5679           |
      | datetime    | 2024-05-05T16:15:18.45678          | 2024-05-05T16:15:18.45679          |
      | datetime    | 2024-05-05T16:15:18.345678         | 2024-05-05T16:15:18.345679         |
      | datetime    | 2024-05-05T16:15:18.2345678        | 2024-05-05T16:15:18.2345679        |
      | datetime    | 2024-05-05T16:15:18.12345678       | 2024-05-05T16:15:18.12345679       |
      | datetime    | 2024-05-05T16:15:18.112345678      | 2024-05-05T16:15:18.112345679      |
      | datetime-tz | 2024-05-05T16:15:18.8+0010         | 2024-05-05T16:15:18.9+0010         |
      | datetime-tz | 2024-05-05T16:15:18.78+0010        | 2024-05-05T16:15:18.79+0010        |
      | datetime-tz | 2024-05-05T16:15:18.678+0010       | 2024-05-05T16:15:18.679+0010       |
      | datetime-tz | 2024-05-05T16:15:18.5678+0010      | 2024-05-05T16:15:18.5679+0010      |
      | datetime-tz | 2024-05-05T16:15:18.45678+0010     | 2024-05-05T16:15:18.45679+0010     |
      | datetime-tz | 2024-05-05T16:15:18.345678+0010    | 2024-05-05T16:15:18.345679+0010    |
      | datetime-tz | 2024-05-05T16:15:18.2345678+0010   | 2024-05-05T16:15:18.2345679+0010   |
      | datetime-tz | 2024-05-05T16:15:18.12345678+0010  | 2024-05-05T16:15:18.12345679+0010  |
      | datetime-tz | 2024-05-05T16:15:18.112345678+0010 | 2024-05-05T16:15:18.112345679+0010 |

  Scenario Outline: Owns can reset @range annotation with the same argument
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When entity(person) set owns: custom-attribute
    When entity(person) get owns(custom-attribute) set annotation: @range(<args>)
    Then entity(person) get owns(custom-attribute) get constraints contain: @range(<args>)
    When entity(person) get owns(custom-attribute) set annotation: @range(<args>)
    Then entity(person) get owns(custom-attribute) get constraints contain: @range(<args>)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get constraints contain: @range(<args>)
    When entity(person) get owns(custom-attribute) set annotation: @range(<args>)
    Then entity(person) get owns(custom-attribute) get constraints contain: @range(<args>)
    Examples:
      | value-type  | args                                         |
      | integer     | 1..2                                         |
      | double      | 1.0..2.0                                     |
      | decimal     | 1.0dec..2.0dec                               |
      | string      | "str".."str another"                         |
      | boolean     | false..true                                  |
      | date        | 2024-05-06..2024-05-08                       |
      | datetime    | 2024-05-06..2024-05-08                       |
      | datetime-tz | 2024-05-07T00:00+0100..2024-05-10T00:00+0100 |

  Scenario Outline: Owns can reset @range annotation with different arguments
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When entity(person) set owns: custom-attribute
    When entity(person) get owns(custom-attribute) set annotation: @range(<args>)
    Then entity(person) get owns(custom-attribute) get constraints contain: @range(<args>)
    Then entity(person) get owns(custom-attribute) get constraints do not contain: @range(<reset-args>)
    When entity(person) get owns(custom-attribute) set annotation: @range(<reset-args>)
    Then entity(person) get owns(custom-attribute) get constraints contain: @range(<reset-args>)
    Then entity(person) get owns(custom-attribute) get constraints do not contain: @range(<args>)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get constraints contain: @range(<reset-args>)
    Then entity(person) get owns(custom-attribute) get constraints do not contain: @range(<args>)
    When entity(person) get owns(custom-attribute) set annotation: @range(<args>)
    Then entity(person) get owns(custom-attribute) get constraints contain: @range(<args>)
    Then entity(person) get owns(custom-attribute) get constraints do not contain: @range(<reset-args>)
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get constraints contain: @range(<args>)
    Then entity(person) get owns(custom-attribute) get constraints do not contain: @range(<reset-args>)
    Examples:
      | value-type  | args                                         | reset-args                                   |
      | integer     | 1..5                                         | 7..9                                         |
      | double      | 1.1..1.5                                     | -8.0..88.3                                   |
      | decimal     | -8.0dec..88.3dec                             | 1.1dec..1.5dec                               |
      | string      | "S".."s"                                     | "not s".."xxxxxxxxx"                         |
      | date        | 2024-05-05..2024-05-06                       | 2024-06-05..2024-06-06                       |
      | datetime    | 2024-05-05..2024-05-06                       | 2024-06-05..2024-06-06                       |
      | datetime-tz | 2024-05-05T00:00+0100..2024-05-06T00:00+0100 | 2024-05-05T00:00+0100..2024-05-07T00:00+0100 |

  Scenario Outline: Owns cannot have @range annotation for <value-type> value type with duplicated arguments
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When entity(person) set owns: custom-attribute
    Then entity(person) get owns(custom-attribute) set annotation: @range(<arg0>..<args>); fails
    Then entity(person) get owns(custom-attribute) get constraint categories do not contain: @range
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get constraint categories do not contain: @range
    Examples:
      | value-type  | arg0                           | args                           |
      | integer     | 1                              | 1                              |
      | double      | 1.0                            | 1.0                            |
      | decimal     | 1.0dec                         | 1.0dec                         |
      | string      | "123"                          | "123"                          |
      | boolean     | false                          | false                          |
      | date        | 2030-06-04                     | 2030-06-04                     |
      | datetime    | 2030-06-04                     | 2030-06-04                     |
      | datetime-tz | 2030-06-04T00:00 Europe/London | 2030-06-04T00:00 Europe/London |

  Scenario Outline: Owns-related @range annotation for <value-type> value type can be inherited and specialised by a subset of arguments
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When create attribute type: second-custom-attribute
    When attribute(second-custom-attribute) set value type: <value-type>
    When attribute(second-custom-attribute) set annotation: @abstract
    When create attribute type: specialised-custom-attribute
    When attribute(specialised-custom-attribute) set supertype: second-custom-attribute
    When entity(person) set owns: custom-attribute
    When relation(description) set owns: custom-attribute
    When entity(person) set owns: second-custom-attribute
    When relation(description) set owns: second-custom-attribute
    When entity(person) get owns(custom-attribute) set annotation: @range(<args>)
    When relation(description) get owns(custom-attribute) set annotation: @range(<args>)
    Then entity(person) get owns(custom-attribute) get constraints contain: @range(<args>)
    Then entity(person) get owns(custom-attribute) get declared annotations contain: @range(<args>)
    Then relation(description) get owns(custom-attribute) get constraints contain: @range(<args>)
    Then relation(description) get owns(custom-attribute) get declared annotations contain: @range(<args>)
    When entity(person) get owns(second-custom-attribute) set annotation: @range(<args>)
    When relation(description) get owns(second-custom-attribute) set annotation: @range(<args>)
    Then entity(person) get owns(second-custom-attribute) get constraints contain: @range(<args>)
    Then entity(person) get owns(second-custom-attribute) get declared annotations contain: @range(<args>)
    Then relation(description) get owns(second-custom-attribute) get constraints contain: @range(<args>)
    Then relation(description) get owns(second-custom-attribute) get declared annotations contain: @range(<args>)
    When create entity type: player
    When create relation type: marriage
    When entity(player) set supertype: person
    When relation(marriage) set supertype: description
    When entity(player) set owns: specialised-custom-attribute
    When relation(marriage) set owns: specialised-custom-attribute
    Then entity(player) get owns contain:
      | custom-attribute |
    Then relation(marriage) get owns contain:
      | custom-attribute |
    Then entity(player) get constraints for owned attribute(custom-attribute) contain: @range(<args>)
    Then entity(player) get owns(custom-attribute) get constraints contain: @range(<args>)
    Then entity(player) get owns(custom-attribute) get declared annotations contain: @range(<args>)
    Then relation(marriage) get constraints for owned attribute(custom-attribute) contain: @range(<args>)
    Then relation(marriage) get owns(custom-attribute) get constraints contain: @range(<args>)
    Then relation(marriage) get owns(custom-attribute) get declared annotations contain: @range(<args>)
    Then entity(player) get owns contain:
      | second-custom-attribute      |
      | specialised-custom-attribute |
    Then relation(marriage) get owns contain:
      | second-custom-attribute      |
      | specialised-custom-attribute |
    Then entity(player) get constraints for owned attribute(specialised-custom-attribute) contain: @range(<args>)
    Then entity(player) get owns(specialised-custom-attribute) get constraints do not contain: @range(<args>)
    Then entity(player) get owns(specialised-custom-attribute) get declared annotations do not contain: @range(<args>)
    Then relation(marriage) get constraints for owned attribute(specialised-custom-attribute) contain: @range(<args>)
    Then relation(marriage) get owns(specialised-custom-attribute) get constraints do not contain: @range(<args>)
    Then relation(marriage) get owns(specialised-custom-attribute) get declared annotations do not contain: @range(<args>)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(player) get constraints for owned attribute(custom-attribute) contain: @range(<args>)
    Then entity(player) get owns(custom-attribute) get constraints contain: @range(<args>)
    Then entity(player) get owns(custom-attribute) get declared annotations contain: @range(<args>)
    Then relation(marriage) get constraints for owned attribute(custom-attribute) contain: @range(<args>)
    Then relation(marriage) get owns(custom-attribute) get constraints contain: @range(<args>)
    Then relation(marriage) get owns(custom-attribute) get declared annotations contain: @range(<args>)
    Then entity(player) get constraints for owned attribute(specialised-custom-attribute) contain: @range(<args>)
    Then entity(player) get owns(specialised-custom-attribute) get constraints do not contain: @range(<args>)
    Then entity(player) get owns(specialised-custom-attribute) get declared annotations do not contain: @range(<args>)
    Then relation(marriage) get constraints for owned attribute(specialised-custom-attribute) contain: @range(<args>)
    Then relation(marriage) get owns(specialised-custom-attribute) get constraints do not contain: @range(<args>)
    Then relation(marriage) get owns(specialised-custom-attribute) get declared annotations do not contain: @range(<args>)
    When entity(player) get owns(custom-attribute) set annotation: @range(<args-specialise>)
    When relation(marriage) get owns(custom-attribute) set annotation: @range(<args-specialise>)
    When entity(player) get owns(specialised-custom-attribute) set annotation: @range(<args-specialise>)
    When relation(marriage) get owns(specialised-custom-attribute) set annotation: @range(<args-specialise>)
    Then entity(person) get constraints for owned attribute(custom-attribute) contain: @range(<args-specialise>)
    Then entity(person) get owns(custom-attribute) get constraints contain: @range(<args-specialise>)
    Then entity(person) get constraints for owned attribute(custom-attribute) do not contain: @range(<args>)
    Then entity(person) get owns(custom-attribute) get constraints do not contain: @range(<args>)
    Then entity(person) get constraints for owned attribute(second-custom-attribute) do not contain: @range(<args-specialise>)
    Then entity(person) get owns(second-custom-attribute) get constraints do not contain: @range(<args-specialise>)
    Then entity(person) get constraints for owned attribute(second-custom-attribute) contain: @range(<args>)
    Then entity(person) get owns(second-custom-attribute) get constraints contain: @range(<args>)
    Then entity(player) get constraints for owned attribute(custom-attribute) contain: @range(<args-specialise>)
    Then entity(player) get owns(custom-attribute) get constraints contain: @range(<args-specialise>)
    Then entity(player) get constraints for owned attribute(custom-attribute) do not contain: @range(<args>)
    Then entity(player) get owns(custom-attribute) get constraints do not contain: @range(<args>)
    Then entity(player) get constraints for owned attribute(specialised-custom-attribute) contain: @range(<args-specialise>)
    Then entity(player) get owns(specialised-custom-attribute) get constraints contain: @range(<args-specialise>)
    Then entity(player) get constraints for owned attribute(specialised-custom-attribute) contain: @range(<args>)
    Then entity(player) get owns(specialised-custom-attribute) get constraints do not contain: @range(<args>)
    Then entity(player) get constraints for owned attribute(second-custom-attribute) do not contain: @range(<args-specialise>)
    Then entity(player) get owns(second-custom-attribute) get constraints do not contain: @range(<args-specialise>)
    Then entity(player) get constraints for owned attribute(second-custom-attribute) contain: @range(<args>)
    Then entity(player) get owns(second-custom-attribute) get constraints contain: @range(<args>)
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get constraints for owned attribute(custom-attribute) contain: @range(<args-specialise>)
    Then entity(person) get owns(custom-attribute) get constraints contain: @range(<args-specialise>)
    Then entity(person) get constraints for owned attribute(custom-attribute) do not contain: @range(<args>)
    Then entity(person) get owns(custom-attribute) get constraints do not contain: @range(<args>)
    Then entity(person) get constraints for owned attribute(second-custom-attribute) do not contain: @range(<args-specialise>)
    Then entity(person) get owns(second-custom-attribute) get constraints do not contain: @range(<args-specialise>)
    Then entity(person) get constraints for owned attribute(second-custom-attribute) contain: @range(<args>)
    Then entity(person) get owns(second-custom-attribute) get constraints contain: @range(<args>)
    Then entity(player) get constraints for owned attribute(custom-attribute) contain: @range(<args-specialise>)
    Then entity(player) get owns(custom-attribute) get constraints contain: @range(<args-specialise>)
    Then entity(player) get constraints for owned attribute(custom-attribute) do not contain: @range(<args>)
    Then entity(player) get owns(custom-attribute) get constraints do not contain: @range(<args>)
    Then entity(player) get constraints for owned attribute(specialised-custom-attribute) contain: @range(<args-specialise>)
    Then entity(player) get owns(specialised-custom-attribute) get constraints contain: @range(<args-specialise>)
    Then entity(player) get constraints for owned attribute(specialised-custom-attribute) contain: @range(<args>)
    Then entity(player) get owns(specialised-custom-attribute) get constraints do not contain: @range(<args>)
    Then entity(player) get constraints for owned attribute(second-custom-attribute) do not contain: @range(<args-specialise>)
    Then entity(player) get owns(second-custom-attribute) get constraints do not contain: @range(<args-specialise>)
    Then entity(player) get constraints for owned attribute(second-custom-attribute) contain: @range(<args>)
    Then entity(player) get owns(second-custom-attribute) get constraints contain: @range(<args>)
    Examples:
      | value-type  | args                                         | args-specialise                                 |
      | integer     | 1..10                                        | 1..5                                            |
      | double      | 1.0..10.0                                    | 2.0..10.0                                       |
      | decimal     | 0.0dec..1.0dec                               | 0.0dec..0.999999dec                             |
      | string      | "A".."Z"                                     | "J".."Z"                                        |
      | date        | 2024-06-04..2024-06-06                       | 2024-06-04..2024-06-05                          |
      | datetime    | 2024-06-04..2024-06-05                       | 2024-06-04..2024-06-04T12:00:00                 |
      | datetime-tz | 2024-06-04T00:00+0010..2024-06-05T00:00+0010 | 2024-06-04T00:00+0010..2024-06-04T12:00:00+0010 |

  Scenario Outline: Inherited @range annotation on owns for <value-type> value type can be reset or specialised by the @range of not a subset of arguments
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When create attribute type: second-custom-attribute
    When attribute(second-custom-attribute) set value type: <value-type>
    When attribute(second-custom-attribute) set annotation: @abstract
    When create attribute type: specialised-custom-attribute
    When attribute(specialised-custom-attribute) set supertype: second-custom-attribute
    When entity(person) set owns: custom-attribute
    When relation(description) set owns: custom-attribute
    When entity(person) set owns: second-custom-attribute
    When relation(description) set owns: second-custom-attribute
    When entity(person) get owns(custom-attribute) set annotation: @range(<args>)
    When relation(description) get owns(custom-attribute) set annotation: @range(<args>)
    Then entity(person) get owns(custom-attribute) get constraints contain: @range(<args>)
    Then relation(description) get owns(custom-attribute) get constraints contain: @range(<args>)
    When entity(person) get owns(second-custom-attribute) set annotation: @range(<args>)
    When relation(description) get owns(second-custom-attribute) set annotation: @range(<args>)
    Then entity(person) get owns(second-custom-attribute) get constraints contain: @range(<args>)
    Then relation(description) get owns(second-custom-attribute) get constraints contain: @range(<args>)
    When create entity type: player
    When create relation type: marriage
    When entity(player) set supertype: person
    When relation(marriage) set supertype: description
    When entity(player) set owns: specialised-custom-attribute
    When relation(marriage) set owns: specialised-custom-attribute
    Then entity(player) get owns(custom-attribute) get constraints contain: @range(<args>)
    Then relation(marriage) get owns(custom-attribute) get constraints contain: @range(<args>)
    Then entity(player) get constraints for owned attribute(specialised-custom-attribute) contain: @range(<args>)
    Then entity(player) get owns(specialised-custom-attribute) get constraints do not contain: @range(<args>)
    Then relation(marriage) get constraints for owned attribute(specialised-custom-attribute) contain: @range(<args>)
    Then relation(marriage) get owns(specialised-custom-attribute) get constraints do not contain: @range(<args>)
    When entity(player) get owns(custom-attribute) set annotation: @range(<args-specialise>)
    When relation(marriage) get owns(custom-attribute) set annotation: @range(<args-specialise>)
    When entity(player) get owns(specialised-custom-attribute) set annotation: @range(<args-specialise>)
    When relation(marriage) get owns(specialised-custom-attribute) set annotation: @range(<args-specialise>)
    Then entity(person) get constraints for owned attribute(custom-attribute) contain: @range(<args-specialise>)
    Then entity(person) get owns(custom-attribute) get constraints contain: @range(<args-specialise>)
    Then entity(person) get constraints for owned attribute(custom-attribute) do not contain: @range(<args>)
    Then entity(person) get owns(custom-attribute) get constraints do not contain: @range(<args>)
    Then entity(person) get constraints for owned attribute(second-custom-attribute) do not contain: @range(<args-specialise>)
    Then entity(person) get owns(second-custom-attribute) get constraints do not contain: @range(<args-specialise>)
    Then entity(person) get constraints for owned attribute(second-custom-attribute) contain: @range(<args>)
    Then entity(person) get owns(second-custom-attribute) get constraints contain: @range(<args>)
    Then entity(player) get constraints for owned attribute(custom-attribute) contain: @range(<args-specialise>)
    Then entity(player) get owns(custom-attribute) get constraints contain: @range(<args-specialise>)
    Then entity(player) get constraints for owned attribute(custom-attribute) do not contain: @range(<args>)
    Then entity(player) get owns(custom-attribute) get constraints do not contain: @range(<args>)
    Then entity(player) get constraints for owned attribute(specialised-custom-attribute) contain: @range(<args-specialise>)
    Then entity(player) get owns(specialised-custom-attribute) get constraints contain: @range(<args-specialise>)
    Then entity(player) get constraints for owned attribute(specialised-custom-attribute) contain: @range(<args>)
    Then entity(player) get owns(specialised-custom-attribute) get constraints do not contain: @range(<args>)
    Then entity(player) get constraints for owned attribute(second-custom-attribute) do not contain: @range(<args-specialise>)
    Then entity(player) get owns(second-custom-attribute) get constraints do not contain: @range(<args-specialise>)
    Then entity(player) get constraints for owned attribute(second-custom-attribute) contain: @range(<args>)
    Then entity(player) get owns(second-custom-attribute) get constraints contain: @range(<args>)
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get constraints for owned attribute(custom-attribute) contain: @range(<args-specialise>)
    Then entity(person) get owns(custom-attribute) get constraints contain: @range(<args-specialise>)
    Then entity(person) get constraints for owned attribute(custom-attribute) do not contain: @range(<args>)
    Then entity(person) get owns(custom-attribute) get constraints do not contain: @range(<args>)
    Then entity(person) get constraints for owned attribute(second-custom-attribute) do not contain: @range(<args-specialise>)
    Then entity(person) get owns(second-custom-attribute) get constraints do not contain: @range(<args-specialise>)
    Then entity(person) get constraints for owned attribute(second-custom-attribute) contain: @range(<args>)
    Then entity(person) get owns(second-custom-attribute) get constraints contain: @range(<args>)
    Then entity(player) get constraints for owned attribute(custom-attribute) contain: @range(<args-specialise>)
    Then entity(player) get owns(custom-attribute) get constraints contain: @range(<args-specialise>)
    Then entity(player) get constraints for owned attribute(custom-attribute) do not contain: @range(<args>)
    Then entity(player) get owns(custom-attribute) get constraints do not contain: @range(<args>)
    Then entity(player) get constraints for owned attribute(specialised-custom-attribute) contain: @range(<args-specialise>)
    Then entity(player) get owns(specialised-custom-attribute) get constraints contain: @range(<args-specialise>)
    Then entity(player) get constraints for owned attribute(specialised-custom-attribute) contain: @range(<args>)
    Then entity(player) get owns(specialised-custom-attribute) get constraints do not contain: @range(<args>)
    Then entity(player) get constraints for owned attribute(second-custom-attribute) do not contain: @range(<args-specialise>)
    Then entity(player) get owns(second-custom-attribute) get constraints do not contain: @range(<args-specialise>)
    Then entity(player) get constraints for owned attribute(second-custom-attribute) contain: @range(<args>)
    Then entity(player) get owns(second-custom-attribute) get constraints contain: @range(<args>)
    Examples:
      | value-type  | args                                         | args-specialise                                 |
      | integer     | 1..10                                        | -1..5                                           |
      | double      | 1.0..10.0                                    | 0.0..150.0                                      |
      | decimal     | 0.0dec..1.0dec                               | -0.0001dec..0.999999dec                         |
      | string      | "A".."Z"                                     | "A".."z"                                        |
      | date        | 2024-06-04..2024-06-06                       | 2023-06-04..2024-06-05                          |
      | datetime    | 2024-06-04..2024-06-05                       | 2023-06-04..2024-06-04T12:00:00                 |
      | datetime-tz | 2024-06-04T00:00+0010..2024-06-05T00:00+0010 | 2024-06-04T00:00+0010..2024-06-05T01:00:00+0010 |

  Scenario Outline: Range can be narrowed for the same attribute for <root-type>'s owns
    When create attribute type: name
    When attribute(name) set value type: integer
    When <root-type>(<supertype-name>) set owns: name
    When <root-type>(<supertype-name>) get owns(name) set annotation: @range(0..5)
    When <root-type>(<subtype-name>) set supertype: <supertype-name>
    When <root-type>(<subtype-name-2>) set supertype: <subtype-name>
    When <root-type>(<subtype-name>) set owns: name
    Then <root-type>(<supertype-name>) get constraints for owned attribute(name) contain: @range(0..5)
    Then <root-type>(<subtype-name>) get constraints for owned attribute(name) contain: @range(0..5)
    Then <root-type>(<subtype-name-2>) get constraints for owned attribute(name) contain: @range(0..5)
    Then <root-type>(<supertype-name>) get owns(name) get constraints contain: @range(0..5)
    Then <root-type>(<subtype-name>) get owns(name) get constraints do not contain: @range(0..5)
    Then <root-type>(<subtype-name-2>) get owns(name) get constraints do not contain: @range(0..5)
    Then <root-type>(<supertype-name>) get owns(name) get declared annotations contain: @range(0..5)
    Then <root-type>(<subtype-name>) get owns(name) get declared annotations do not contain: @range(0..5)
    Then <root-type>(<subtype-name-2>) get owns(name) get declared annotations do not contain: @range(0..5)
    When <root-type>(<subtype-name>) get owns(name) set annotation: @range(2..5)
    Then <root-type>(<supertype-name>) get constraints for owned attribute(name) contain: @range(0..5)
    Then <root-type>(<subtype-name>) get constraints for owned attribute(name) contain: @range(0..5)
    Then <root-type>(<subtype-name-2>) get constraints for owned attribute(name) contain: @range(0..5)
    Then <root-type>(<supertype-name>) get owns(name) get constraints contain: @range(0..5)
    Then <root-type>(<subtype-name>) get owns(name) get constraints do not contain: @range(0..5)
    Then <root-type>(<subtype-name-2>) get owns(name) get constraints do not contain: @range(0..5)
    Then <root-type>(<supertype-name>) get owns(name) get declared annotations contain: @range(0..5)
    Then <root-type>(<subtype-name>) get owns(name) get declared annotations do not contain: @range(0..5)
    Then <root-type>(<subtype-name-2>) get owns(name) get declared annotations do not contain: @range(0..5)
    Then <root-type>(<supertype-name>) get constraints for owned attribute(name) do not contain: @range(2..5)
    Then <root-type>(<subtype-name>) get constraints for owned attribute(name) contain: @range(2..5)
    Then <root-type>(<subtype-name-2>) get constraints for owned attribute(name) contain: @range(2..5)
    Then <root-type>(<supertype-name>) get owns(name) get constraints do not contain: @range(2..5)
    Then <root-type>(<subtype-name>) get owns(name) get constraints contain: @range(2..5)
    Then <root-type>(<subtype-name-2>) get owns(name) get constraints contain: @range(2..5)
    Then <root-type>(<supertype-name>) get owns(name) get declared annotations do not contain: @range(2..5)
    Then <root-type>(<subtype-name>) get owns(name) get declared annotations contain: @range(2..5)
    Then <root-type>(<subtype-name-2>) get owns(name) get declared annotations contain: @range(2..5)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<supertype-name>) get constraints for owned attribute(name) contain: @range(0..5)
    Then <root-type>(<subtype-name>) get constraints for owned attribute(name) contain: @range(0..5)
    Then <root-type>(<subtype-name-2>) get constraints for owned attribute(name) contain: @range(0..5)
    Then <root-type>(<supertype-name>) get owns(name) get constraints contain: @range(0..5)
    Then <root-type>(<subtype-name>) get owns(name) get constraints do not contain: @range(0..5)
    Then <root-type>(<subtype-name-2>) get owns(name) get constraints do not contain: @range(0..5)
    Then <root-type>(<supertype-name>) get owns(name) get declared annotations contain: @range(0..5)
    Then <root-type>(<subtype-name>) get owns(name) get declared annotations do not contain: @range(0..5)
    Then <root-type>(<subtype-name-2>) get owns(name) get declared annotations do not contain: @range(0..5)
    Then <root-type>(<supertype-name>) get constraints for owned attribute(name) do not contain: @range(2..5)
    Then <root-type>(<subtype-name>) get constraints for owned attribute(name) contain: @range(2..5)
    Then <root-type>(<subtype-name-2>) get constraints for owned attribute(name) contain: @range(2..5)
    Then <root-type>(<supertype-name>) get owns(name) get constraints do not contain: @range(2..5)
    Then <root-type>(<subtype-name>) get owns(name) get constraints contain: @range(2..5)
    Then <root-type>(<subtype-name-2>) get owns(name) get constraints contain: @range(2..5)
    Then <root-type>(<supertype-name>) get owns(name) get declared annotations do not contain: @range(2..5)
    Then <root-type>(<subtype-name>) get owns(name) get declared annotations contain: @range(2..5)
    Then <root-type>(<subtype-name-2>) get owns(name) get declared annotations contain: @range(2..5)
    When <root-type>(<subtype-name-2>) set owns: name
    Then <root-type>(<subtype-name-2>) get owns(name) get declared annotations do not contain: @range(2..5)
    Then <root-type>(<subtype-name-2>) get owns(name) get constraints do not contain: @range(2..5)
    Then <root-type>(<subtype-name-2>) get constraints for owned attribute(name) contain: @range(2..5)
    When <root-type>(<subtype-name-2>) get owns(name) set annotation: @range(2..3)
    Then <root-type>(<supertype-name>) get constraints for owned attribute(name) contain: @range(0..5)
    Then <root-type>(<subtype-name>) get constraints for owned attribute(name) contain: @range(0..5)
    Then <root-type>(<subtype-name-2>) get constraints for owned attribute(name) contain: @range(0..5)
    Then <root-type>(<supertype-name>) get owns(name) get constraints contain: @range(0..5)
    Then <root-type>(<subtype-name>) get owns(name) get constraints do not contain: @range(0..5)
    Then <root-type>(<subtype-name-2>) get owns(name) get constraints do not contain: @range(0..5)
    Then <root-type>(<supertype-name>) get owns(name) get declared annotations contain: @range(0..5)
    Then <root-type>(<subtype-name>) get owns(name) get declared annotations do not contain: @range(0..5)
    Then <root-type>(<subtype-name-2>) get owns(name) get declared annotations do not contain: @range(0..5)
    Then <root-type>(<supertype-name>) get constraints for owned attribute(name) do not contain: @range(2..5)
    Then <root-type>(<subtype-name>) get constraints for owned attribute(name) contain: @range(2..5)
    Then <root-type>(<subtype-name-2>) get constraints for owned attribute(name) contain: @range(2..5)
    Then <root-type>(<supertype-name>) get owns(name) get constraints do not contain: @range(2..5)
    Then <root-type>(<subtype-name>) get owns(name) get constraints contain: @range(2..5)
    Then <root-type>(<subtype-name-2>) get owns(name) get constraints do not contain: @range(2..5)
    Then <root-type>(<supertype-name>) get owns(name) get declared annotations do not contain: @range(2..5)
    Then <root-type>(<subtype-name>) get owns(name) get declared annotations contain: @range(2..5)
    Then <root-type>(<subtype-name-2>) get owns(name) get declared annotations do not contain: @range(2..5)
    Then <root-type>(<supertype-name>) get constraints for owned attribute(name) do not contain: @range(2..3)
    Then <root-type>(<subtype-name>) get constraints for owned attribute(name) do not contain: @range(2..3)
    Then <root-type>(<subtype-name-2>) get constraints for owned attribute(name) contain: @range(2..3)
    Then <root-type>(<supertype-name>) get owns(name) get constraints do not contain: @range(2..3)
    Then <root-type>(<subtype-name>) get owns(name) get constraints do not contain: @range(2..3)
    Then <root-type>(<subtype-name-2>) get owns(name) get constraints contain: @range(2..3)
    Then <root-type>(<supertype-name>) get owns(name) get declared annotations do not contain: @range(2..3)
    Then <root-type>(<subtype-name>) get owns(name) get declared annotations do not contain: @range(2..3)
    Then <root-type>(<subtype-name-2>) get owns(name) get declared annotations contain: @range(2..3)
    When transaction commits
    When connection open read transaction for database: typedb
    Then <root-type>(<supertype-name>) get constraints for owned attribute(name) contain: @range(0..5)
    Then <root-type>(<subtype-name>) get constraints for owned attribute(name) contain: @range(0..5)
    Then <root-type>(<subtype-name-2>) get constraints for owned attribute(name) contain: @range(0..5)
    Then <root-type>(<supertype-name>) get owns(name) get constraints contain: @range(0..5)
    Then <root-type>(<subtype-name>) get owns(name) get constraints do not contain: @range(0..5)
    Then <root-type>(<subtype-name-2>) get owns(name) get constraints do not contain: @range(0..5)
    Then <root-type>(<supertype-name>) get owns(name) get declared annotations contain: @range(0..5)
    Then <root-type>(<subtype-name>) get owns(name) get declared annotations do not contain: @range(0..5)
    Then <root-type>(<subtype-name-2>) get owns(name) get declared annotations do not contain: @range(0..5)
    Then <root-type>(<supertype-name>) get constraints for owned attribute(name) do not contain: @range(2..5)
    Then <root-type>(<subtype-name>) get constraints for owned attribute(name) contain: @range(2..5)
    Then <root-type>(<subtype-name-2>) get constraints for owned attribute(name) contain: @range(2..5)
    Then <root-type>(<supertype-name>) get owns(name) get constraints do not contain: @range(2..5)
    Then <root-type>(<subtype-name>) get owns(name) get constraints contain: @range(2..5)
    Then <root-type>(<subtype-name-2>) get owns(name) get constraints do not contain: @range(2..5)
    Then <root-type>(<supertype-name>) get owns(name) get declared annotations do not contain: @range(2..5)
    Then <root-type>(<subtype-name>) get owns(name) get declared annotations contain: @range(2..5)
    Then <root-type>(<subtype-name-2>) get owns(name) get declared annotations do not contain: @range(2..5)
    Then <root-type>(<supertype-name>) get constraints for owned attribute(name) do not contain: @range(2..3)
    Then <root-type>(<subtype-name>) get constraints for owned attribute(name) do not contain: @range(2..3)
    Then <root-type>(<subtype-name-2>) get constraints for owned attribute(name) contain: @range(2..3)
    Then <root-type>(<supertype-name>) get owns(name) get constraints do not contain: @range(2..3)
    Then <root-type>(<subtype-name>) get owns(name) get constraints do not contain: @range(2..3)
    Then <root-type>(<subtype-name-2>) get owns(name) get constraints contain: @range(2..3)
    Then <root-type>(<supertype-name>) get owns(name) get declared annotations do not contain: @range(2..3)
    Then <root-type>(<subtype-name>) get owns(name) get declared annotations do not contain: @range(2..3)
    Then <root-type>(<subtype-name-2>) get owns(name) get declared annotations contain: @range(2..3)
    Examples:
      | root-type | supertype-name | subtype-name | subtype-name-2 |
      | entity    | person         | customer     | subscriber     |
      | relation  | description    | registration | profile        |

  Scenario: Owns can change attribute type value type and @range through @range resetting
    When create attribute type: name
    When create attribute type: surname
    When attribute(name) set annotation: @abstract
    When attribute(surname) set supertype: name
    When attribute(surname) set value type: string
    When entity(person) set owns: name
    When entity(customer) set owns: surname
    When entity(customer) get owns(surname) set annotation: @range("a start".."finish line")
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(name) set value type: integer; fails
    Then attribute(surname) set value type: integer; fails
    When entity(customer) get owns(surname) unset annotation: @range
    Then attribute(surname) unset value type; fails
    When attribute(surname) set value type: integer
    When attribute(name) set value type: integer
    When attribute(surname) unset value type
    When entity(customer) get owns(surname) set annotation: @range(1..3)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(customer) get owns(surname) get constraints contain: @range(1..3)
    Then attribute(surname) get value type: integer
    When entity(person) get owns(name) set annotation: @range(1..3)
    When entity(customer) get owns(surname) unset annotation: @range
    Then entity(customer) get owns(surname) get constraints do not contain: @range(1..3)
    Then entity(customer) get constraints for owned attribute(surname) contain: @range(1..3)
    Then attribute(surname) set value type: string; fails
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(customer) get owns(surname) get constraints do not contain: @range(1..3)
    Then entity(customer) get constraints for owned attribute(surname) contain: @range(1..3)
    Then attribute(surname) get value type: integer

########################
# @card
########################

  Scenario Outline: Owns have default cardinality without annotation
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When create attribute type: custom-attribute-2
    When attribute(custom-attribute-2) set value type: <value-type>
    When entity(person) set owns: custom-attribute
    Then entity(person) get owns(custom-attribute) get declared annotations is empty
    Then entity(person) get owns(custom-attribute) get cardinality: @card(0..1)
    When entity(person) set owns: custom-attribute-2
    Then entity(person) get owns(custom-attribute-2) get declared annotations is empty
    Then entity(person) get owns(custom-attribute-2) get cardinality: @card(0..1)
    When entity(person) get owns(custom-attribute-2) set ordering: ordered
    Then entity(person) get owns(custom-attribute-2) get declared annotations is empty
    Then entity(person) get owns(custom-attribute-2) get cardinality: @card(0..)
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get declared annotations is empty
    Then entity(person) get owns(custom-attribute) get cardinality: @card(0..1)
    Then entity(person) get owns(custom-attribute-2) get declared annotations is empty
    Then entity(person) get owns(custom-attribute-2) get cardinality: @card(0..)
    Examples:
      | value-type  |
      | integer     |
      | double      |
      | decimal     |
      | string      |
      | boolean     |
      | date        |
      | datetime    |
      | datetime-tz |
      | duration    |

  Scenario Outline: Owns can set @card annotation for <value-type> value type with arguments in correct order and unset it
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When entity(person) set owns: custom-attribute
    Then entity(person) get owns(custom-attribute) get constraints do not contain: @card(<arg0>..<arg1>)
    Then entity(person) get owns(custom-attribute) get cardinality: @card(0..1)
    When entity(person) get owns(custom-attribute) set annotation: @card(<arg0>..<arg1>)
    Then entity(person) get owns(custom-attribute) get constraints contain: @card(<arg0>..<arg1>)
    Then entity(person) get owns(custom-attribute) get cardinality: @card(<arg0>..<arg1>)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get constraints contain: @card(<arg0>..<arg1>)
    Then entity(person) get owns(custom-attribute) get cardinality: @card(<arg0>..<arg1>)
    When entity(person) get owns(custom-attribute) unset annotation: @card
    Then entity(person) get owns(custom-attribute) get constraints do not contain: @card(<arg0>..<arg1>)
    Then entity(person) get owns(custom-attribute) get cardinality: @card(0..1)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get constraints do not contain: @card(<arg0>..<arg1>)
    Then entity(person) get owns(custom-attribute) get cardinality: @card(0..1)
    When entity(person) get owns(custom-attribute) set annotation: @card(<arg0>..<arg1>)
    Then entity(person) get owns(custom-attribute) get constraints contain: @card(<arg0>..<arg1>)
    Then entity(person) get owns(custom-attribute) get cardinality: @card(<arg0>..<arg1>)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get constraints contain: @card(<arg0>..<arg1>)
    Then entity(person) get owns(custom-attribute) get cardinality: @card(<arg0>..<arg1>)
    When entity(person) unset owns: custom-attribute
    Then entity(person) get owns is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get owns is empty
    Examples:
      | value-type            | arg0                | arg1                |
      | string                | 0                   | 10                  |
      | boolean               | 0                   | 9223372036854775807 |
      | double                | 1                   | 10                  |
      | decimal               | 0                   |                     |
      | date                  | 1                   |                     |
      | datetime-tz           | 1                   | 1                   |
      | duration              | 9223372036854775807 | 9223372036854775807 |
      | struct(custom-struct) | 9223372036854775807 |                     |

  Scenario Outline: Ordered owns can set @card annotation for <value-type> value type with arguments in correct order and unset it
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When entity(person) set owns: custom-attribute
    When entity(person) get owns(custom-attribute) set ordering: ordered
    Then entity(person) get owns(custom-attribute) get constraints do not contain: @card(<arg0>..<arg1>)
    Then entity(person) get owns(custom-attribute) get cardinality: @card(0..)
    When entity(person) get owns(custom-attribute) set annotation: @card(<arg0>..<arg1>)
    Then entity(person) get owns(custom-attribute) get constraints contain: @card(<arg0>..<arg1>)
    Then entity(person) get owns(custom-attribute) get cardinality: @card(<arg0>..<arg1>)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get constraints contain: @card(<arg0>..<arg1>)
    Then entity(person) get owns(custom-attribute) get cardinality: @card(<arg0>..<arg1>)
    When entity(person) get owns(custom-attribute) unset annotation: @card
    Then entity(person) get owns(custom-attribute) get constraints do not contain: @card(<arg0>..<arg1>)
    Then entity(person) get owns(custom-attribute) get cardinality: @card(0..)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get constraints do not contain: @card(<arg0>..<arg1>)
    Then entity(person) get owns(custom-attribute) get cardinality: @card(0..)
    When entity(person) get owns(custom-attribute) set annotation: @card(<arg0>..<arg1>)
    Then entity(person) get owns(custom-attribute) get constraints contain: @card(<arg0>..<arg1>)
    Then entity(person) get owns(custom-attribute) get cardinality: @card(<arg0>..<arg1>)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get constraints contain: @card(<arg0>..<arg1>)
    Then entity(person) get owns(custom-attribute) get cardinality: @card(<arg0>..<arg1>)
    When entity(person) unset owns: custom-attribute
    Then entity(person) get owns is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get owns is empty
    Examples:
      | value-type            | arg0                | arg1                |
      | integer               | 0                   | 1                   |
      | string                | 0                   | 10                  |
      | boolean               | 0                   | 9223372036854775807 |
      | double                | 1                   | 10                  |
      | date                  | 1                   |                     |
      | datetime-tz           | 1                   | 1                   |
      | duration              | 9223372036854775807 | 9223372036854775807 |
      | struct(custom-struct) | 9223372036854775807 |                     |

  Scenario Outline: Owns can set @card annotation for <value-type> value type with duplicate args (exactly N ownerships)
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When entity(person) set owns: custom-attribute
    Then entity(person) get owns(custom-attribute) get constraints do not contain: @card(<arg>..<arg>)
    When entity(person) get owns(custom-attribute) set annotation: @card(<arg>..<arg>)
    Then entity(person) get owns(custom-attribute) get constraints contain: @card(<arg>..<arg>)
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get constraints contain: @card(<arg>..<arg>)
    Examples:
      | value-type            | arg  |
      | integer               | 1    |
      | integer               | 9999 |
      | string                | 8888 |
      | boolean               | 7777 |
      | double                | 666  |
      | decimal               | 555  |
      | date                  | 444  |
      | datetime              | 444  |
      | datetime-tz           | 33   |
      | duration              | 22   |
      | struct(custom-struct) | 11   |

  Scenario Outline: Owns cannot have @card annotation for <value-type> value type with invalid arguments
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When entity(person) set owns: custom-attribute
    Then entity(person) get owns(custom-attribute) set annotation: @card(2..1); fails
    Then entity(person) get owns(custom-attribute) set annotation: @card(0..0); fails
    Then entity(person) get owns(custom-attribute) get declared annotation categories do not contain: @card
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get declared annotation categories do not contain: @card
    Examples:
      | value-type |
      | integer    |

  Scenario: Owns can have @card annotation for none value type
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set annotation: @abstract
    When attribute(custom-attribute) get value type is none
    When entity(person) set owns: custom-attribute
    Then entity(person) get owns(custom-attribute) set ordering: ordered
    When entity(person) get owns(custom-attribute) set annotation: @card(0..2)
    Then entity(person) get owns(custom-attribute) get constraints contain: @card(0..2)
    Then attribute(custom-attribute) get value type is none
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get constraints contain: @card(0..2)
    Then attribute(custom-attribute) get value type is none

  Scenario Outline: Owns can reset @card annotation with the same argument
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When entity(person) set owns: custom-attribute
    When entity(person) get owns(custom-attribute) set annotation: @card(<args>)
    Then entity(person) get owns(custom-attribute) get constraints contain: @card(<args>)
    When entity(person) get owns(custom-attribute) set annotation: @card(<args>)
    Then entity(person) get owns(custom-attribute) get constraints contain: @card(<args>)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get constraints contain: @card(<args>)
    When entity(person) get owns(custom-attribute) set annotation: @card(<args>)
    Then entity(person) get owns(custom-attribute) get constraints contain: @card(<args>)
    Examples:
      | value-type | args |
      | integer    | 1..2 |
      | duration   | 0..9 |

  Scenario Outline: Owns can reset @card annotations
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: decimal
    When entity(person) set owns: custom-attribute
    When entity(person) get owns(custom-attribute) set annotation: @card(2..5)
    Then entity(person) get owns(custom-attribute) set annotation: @card(<reset-args>)
    Then entity(person) get owns(custom-attribute) get constraints do not contain: @card(2..5)
    Then entity(person) get owns(custom-attribute) get constraints contain: @card(<reset-args>)
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get constraints do not contain: @card(2..5)
    Then entity(person) get owns(custom-attribute) get constraints contain: @card(<reset-args>)
    Examples:
      | reset-args |
      | 0..1       |
      | 0..2       |
      | 0..3       |
      | 0..5       |
      | 0..        |
      | 2..3       |
      | 2..        |
      | 3..4       |
      | 3..5       |
      | 3..        |
      | 5..        |
      | 6..        |

  Scenario Outline: Owns can redeclare @card annotation with different arguments
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When entity(person) set owns: custom-attribute
    When entity(person) get owns(custom-attribute) set annotation: @card(<args>)
    When entity(person) get owns(custom-attribute) set annotation: @card(<reset-args>)
    Then entity(person) get owns(custom-attribute) get constraints contain: @card(<reset-args>)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get constraints contain: @card(<reset-args>)
    When entity(person) get owns(custom-attribute) set annotation: @card(<args>)
    Then entity(person) get owns(custom-attribute) get constraints contain: @card(<args>)
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get constraints contain: @card(<args>)
    Examples:
      | value-type  | args | reset-args |
      | integer     | 2..5 | 7..9       |
      | double      | 2..5 | 0..1       |
      | decimal     | 2..5 | 0..        |
      | string      | 2..5 | 4..        |
      | boolean     | 2..5 | 4..5       |
      | date        | 2..5 | 2..2       |
      | datetime    | 2..5 | 2..6       |
      | datetime-tz | 2..5 | 2..4       |
      | duration    | 2..5 | 2..        |

  Scenario Outline: Owns-related @card annotation for <value-type> value type can be inherited and specialised by a subset of arguments
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When create attribute type: second-custom-attribute
    When attribute(second-custom-attribute) set value type: <value-type>
    When attribute(second-custom-attribute) set annotation: @abstract
    When create attribute type: specialised-custom-attribute
    When attribute(specialised-custom-attribute) set supertype: second-custom-attribute
    When entity(person) set owns: custom-attribute
    When relation(description) set owns: custom-attribute
    When entity(person) set owns: second-custom-attribute
    When relation(description) set owns: second-custom-attribute
    When entity(person) get owns(custom-attribute) set annotation: @card(<args>)
    When relation(description) get owns(custom-attribute) set annotation: @card(<args>)
    Then entity(person) get owns(custom-attribute) get constraints contain: @card(<args>)
    Then entity(person) get owns(custom-attribute) get declared annotations contain: @card(<args>)
    Then relation(description) get owns(custom-attribute) get constraints contain: @card(<args>)
    Then relation(description) get owns(custom-attribute) get declared annotations contain: @card(<args>)
    When entity(person) get owns(second-custom-attribute) set annotation: @card(<args>)
    When relation(description) get owns(second-custom-attribute) set annotation: @card(<args>)
    Then entity(person) get owns(second-custom-attribute) get constraints contain: @card(<args>)
    Then entity(person) get owns(second-custom-attribute) get declared annotations contain: @card(<args>)
    Then relation(description) get owns(second-custom-attribute) get constraints contain: @card(<args>)
    Then relation(description) get owns(second-custom-attribute) get declared annotations contain: @card(<args>)
    When create entity type: player
    When create relation type: marriage
    When entity(player) set supertype: person
    When relation(marriage) set supertype: description
    When entity(player) set owns: specialised-custom-attribute
    When relation(marriage) set owns: specialised-custom-attribute
    Then entity(player) get owns contain:
      | custom-attribute |
    Then relation(marriage) get owns contain:
      | custom-attribute |
    Then entity(player) get constraints for owned attribute(custom-attribute) contain: @card(<args>)
    Then entity(player) get owns(custom-attribute) get constraints contain: @card(<args>)
    Then entity(player) get owns(custom-attribute) get declared annotations contain: @card(<args>)
    Then relation(marriage) get constraints for owned attribute(custom-attribute) contain: @card(<args>)
    Then relation(marriage) get owns(custom-attribute) get constraints contain: @card(<args>)
    Then relation(marriage) get owns(custom-attribute) get declared annotations contain: @card(<args>)
    Then entity(player) get owns contain:
      | second-custom-attribute |
    Then relation(marriage) get owns contain:
      | second-custom-attribute |
    Then entity(player) get owns contain:
      | specialised-custom-attribute |
    Then relation(marriage) get owns contain:
      | specialised-custom-attribute |
    Then entity(player) get constraints for owned attribute(specialised-custom-attribute) contain: @card(<args>)
    Then entity(player) get owns(specialised-custom-attribute) get constraints do not contain: @card(<args>)
    Then entity(player) get owns(specialised-custom-attribute) get declared annotations do not contain: @card(<args>)
    Then relation(marriage) get constraints for owned attribute(specialised-custom-attribute) contain: @card(<args>)
    Then relation(marriage) get owns(specialised-custom-attribute) get constraints do not contain: @card(<args>)
    Then relation(marriage) get owns(specialised-custom-attribute) get declared annotations do not contain: @card(<args>)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(player) get constraints for owned attribute(custom-attribute) contain: @card(<args>)
    Then entity(player) get owns(custom-attribute) get constraints contain: @card(<args>)
    Then entity(player) get owns(custom-attribute) get declared annotations contain: @card(<args>)
    Then relation(marriage) get constraints for owned attribute(custom-attribute) contain: @card(<args>)
    Then relation(marriage) get owns(custom-attribute) get constraints contain: @card(<args>)
    Then relation(marriage) get owns(custom-attribute) get declared annotations contain: @card(<args>)
    Then entity(player) get constraints for owned attribute(specialised-custom-attribute) contain: @card(<args>)
    Then entity(player) get owns(specialised-custom-attribute) get constraints do not contain: @card(<args>)
    Then entity(player) get owns(specialised-custom-attribute) get declared annotations do not contain: @card(<args>)
    Then relation(marriage) get constraints for owned attribute(specialised-custom-attribute) contain: @card(<args>)
    Then relation(marriage) get owns(specialised-custom-attribute) get constraints do not contain: @card(<args>)
    Then relation(marriage) get owns(specialised-custom-attribute) get declared annotations do not contain: @card(<args>)
    When entity(player) get owns(custom-attribute) set annotation: @card(<args-specialise>)
    When relation(marriage) get owns(custom-attribute) set annotation: @card(<args-specialise>)
    Then entity(player) get constraints for owned attribute(custom-attribute) contain: @card(<args-specialise>)
    Then entity(player) get owns(custom-attribute) get constraints contain: @card(<args-specialise>)
    Then entity(player) get owns(custom-attribute) get declared annotations contain: @card(<args-specialise>)
    Then relation(marriage) get constraints for owned attribute(custom-attribute) contain: @card(<args-specialise>)
    Then relation(marriage) get owns(custom-attribute) get constraints contain: @card(<args-specialise>)
    Then relation(marriage) get owns(custom-attribute) get declared annotations contain: @card(<args-specialise>)
    Then entity(player) get constraints for owned attribute(specialised-custom-attribute) do not contain: @card(<args-specialise>)
    Then entity(player) get constraints for owned attribute(specialised-custom-attribute) contain: @card(<args>)
    Then entity(player) get owns(specialised-custom-attribute) get constraints do not contain: @card(<args>)
    Then entity(player) get owns(specialised-custom-attribute) get declared annotations do not contain: @card(<args>)
    Then relation(marriage) get constraints for owned attribute(specialised-custom-attribute) do not contain: @card(<args-specialise>)
    Then relation(marriage) get constraints for owned attribute(specialised-custom-attribute) contain: @card(<args>)
    Then relation(marriage) get owns(specialised-custom-attribute) get constraints do not contain: @card(<args>)
    Then relation(marriage) get owns(specialised-custom-attribute) get declared annotations do not contain: @card(<args>)
    When entity(player) get owns(specialised-custom-attribute) set annotation: @card(<args-specialise>)
    When relation(marriage) get owns(specialised-custom-attribute) set annotation: @card(<args-specialise>)
    Then entity(player) get constraints for owned attribute(specialised-custom-attribute) contain: @card(<args>)
    Then entity(player) get constraints for owned attribute(specialised-custom-attribute) contain: @card(<args-specialise>)
    Then entity(player) get owns(specialised-custom-attribute) get constraints do not contain: @card(<args>)
    Then entity(player) get owns(specialised-custom-attribute) get constraints contain: @card(<args-specialise>)
    Then entity(player) get owns(specialised-custom-attribute) get declared annotations do not contain: @card(<args>)
    Then entity(player) get owns(specialised-custom-attribute) get declared annotations contain: @card(<args-specialise>)
    Then relation(marriage) get constraints for owned attribute(specialised-custom-attribute) contain: @card(<args>)
    Then relation(marriage) get constraints for owned attribute(specialised-custom-attribute) contain: @card(<args-specialise>)
    Then relation(marriage) get owns(specialised-custom-attribute) get constraints do not contain: @card(<args>)
    Then relation(marriage) get owns(specialised-custom-attribute) get constraints contain: @card(<args-specialise>)
    Then relation(marriage) get owns(specialised-custom-attribute) get declared annotations do not contain: @card(<args>)
    Then relation(marriage) get owns(specialised-custom-attribute) get declared annotations contain: @card(<args-specialise>)
    Then entity(person) get constraints for owned attribute(second-custom-attribute) contain: @card(<args>)
    Then entity(person) get constraints for owned attribute(second-custom-attribute) do not contain: @card(<args-specialise>)
    Then entity(person) get owns(second-custom-attribute) get constraints contain: @card(<args>)
    Then entity(person) get owns(second-custom-attribute) get constraints do not contain: @card(<args-specialise>)
    Then entity(person) get owns(second-custom-attribute) get declared annotations contain: @card(<args>)
    Then entity(person) get owns(second-custom-attribute) get declared annotations do not contain: @card(<args-specialise>)
    Then relation(description) get constraints for owned attribute(second-custom-attribute) contain: @card(<args>)
    Then relation(description) get constraints for owned attribute(second-custom-attribute) do not contain: @card(<args-specialise>)
    Then relation(description) get owns(second-custom-attribute) get constraints contain: @card(<args>)
    Then relation(description) get owns(second-custom-attribute) get constraints do not contain: @card(<args-specialise>)
    Then relation(description) get owns(second-custom-attribute) get declared annotations contain: @card(<args>)
    Then relation(description) get owns(second-custom-attribute) get declared annotations do not contain: @card(<args-specialise>)
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(player) get constraints for owned attribute(specialised-custom-attribute) contain: @card(<args>)
    Then entity(player) get constraints for owned attribute(specialised-custom-attribute) contain: @card(<args-specialise>)
    Then entity(player) get owns(specialised-custom-attribute) get constraints do not contain: @card(<args>)
    Then entity(player) get owns(specialised-custom-attribute) get constraints contain: @card(<args-specialise>)
    Then entity(player) get owns(specialised-custom-attribute) get declared annotations do not contain: @card(<args>)
    Then entity(player) get owns(specialised-custom-attribute) get declared annotations contain: @card(<args-specialise>)
    Then relation(marriage) get constraints for owned attribute(specialised-custom-attribute) contain: @card(<args>)
    Then relation(marriage) get constraints for owned attribute(specialised-custom-attribute) contain: @card(<args-specialise>)
    Then relation(marriage) get owns(specialised-custom-attribute) get constraints do not contain: @card(<args>)
    Then relation(marriage) get owns(specialised-custom-attribute) get constraints contain: @card(<args-specialise>)
    Then relation(marriage) get owns(specialised-custom-attribute) get declared annotations do not contain: @card(<args>)
    Then relation(marriage) get owns(specialised-custom-attribute) get declared annotations contain: @card(<args-specialise>)
    Then entity(person) get constraints for owned attribute(second-custom-attribute) contain: @card(<args>)
    Then entity(person) get constraints for owned attribute(second-custom-attribute) do not contain: @card(<args-specialise>)
    Then entity(person) get owns(second-custom-attribute) get constraints contain: @card(<args>)
    Then entity(person) get owns(second-custom-attribute) get constraints do not contain: @card(<args-specialise>)
    Then entity(person) get owns(second-custom-attribute) get declared annotations contain: @card(<args>)
    Then entity(person) get owns(second-custom-attribute) get declared annotations do not contain: @card(<args-specialise>)
    Then relation(description) get constraints for owned attribute(second-custom-attribute) contain: @card(<args>)
    Then relation(description) get constraints for owned attribute(second-custom-attribute) do not contain: @card(<args-specialise>)
    Then relation(description) get owns(second-custom-attribute) get constraints contain: @card(<args>)
    Then relation(description) get owns(second-custom-attribute) get constraints do not contain: @card(<args-specialise>)
    Then relation(description) get owns(second-custom-attribute) get declared annotations contain: @card(<args>)
    Then relation(description) get owns(second-custom-attribute) get declared annotations do not contain: @card(<args-specialise>)
    Examples:
      | value-type  | args       | args-specialise |
      | integer     | 0..        | 0..10000        |
      | double      | 0..10      | 0..2            |
      | decimal     | 0..2       | 1..2            |
      | string      | 1..        | 1..1            |
      | date        | 1..5       | 3..5            |
      | datetime    | 1..5       | 3..4            |
      | datetime-tz | 38..111    | 39..111         |
      | duration    | 1000..1100 | 1000..1099      |

  Scenario Outline: Inherited @card annotation on owns for <value-type> value type can be reset or specialised by the @card of not a subset of arguments
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When create attribute type: second-custom-attribute
    When attribute(second-custom-attribute) set value type: <value-type>
    When attribute(second-custom-attribute) set annotation: @abstract
    When create attribute type: specialised-custom-attribute
    When attribute(specialised-custom-attribute) set supertype: second-custom-attribute
    When entity(person) set owns: custom-attribute
    When relation(description) set owns: custom-attribute
    When entity(person) set owns: second-custom-attribute
    When relation(description) set owns: second-custom-attribute
    When entity(person) get owns(custom-attribute) set annotation: @card(<args>)
    When relation(description) get owns(custom-attribute) set annotation: @card(<args>)
    Then entity(person) get owns(custom-attribute) get constraints contain: @card(<args>)
    Then relation(description) get owns(custom-attribute) get constraints contain: @card(<args>)
    When entity(person) get owns(second-custom-attribute) set annotation: @card(<args>)
    When relation(description) get owns(second-custom-attribute) set annotation: @card(<args>)
    Then entity(person) get owns(second-custom-attribute) get constraints contain: @card(<args>)
    Then relation(description) get owns(second-custom-attribute) get constraints contain: @card(<args>)
    When create entity type: player
    When create relation type: marriage
    When entity(player) set supertype: person
    When relation(marriage) set supertype: description
    When entity(player) set owns: specialised-custom-attribute
    When relation(marriage) set owns: specialised-custom-attribute
    Then entity(player) get owns(custom-attribute) get constraints contain: @card(<args>)
    Then relation(marriage) get owns(custom-attribute) get constraints contain: @card(<args>)
    Then entity(player) get owns(specialised-custom-attribute) get constraints do not contain: @card(<args>)
    Then entity(player) get constraints for owned attribute(specialised-custom-attribute) contain: @card(<args>)
    Then relation(marriage) get owns(specialised-custom-attribute) get constraints do not contain: @card(<args>)
    Then relation(marriage) get constraints for owned attribute(specialised-custom-attribute) contain: @card(<args>)
    When entity(player) get owns(custom-attribute) set annotation: @card(<args-specialise>)
    When relation(marriage) get owns(custom-attribute) set annotation: @card(<args-specialise>)
    When entity(player) get owns(specialised-custom-attribute) set annotation: @card(<args-specialise>)
    When relation(marriage) get owns(specialised-custom-attribute) set annotation: @card(<args-specialise>)
    Then entity(player) get owns(custom-attribute) get constraints contain: @card(<args-specialise>)
    Then entity(person) get owns(custom-attribute) get constraints contain: @card(<args-specialise>)
    Then relation(marriage) get owns(custom-attribute) get constraints contain: @card(<args-specialise>)
    Then relation(description) get owns(custom-attribute) get constraints contain: @card(<args-specialise>)
    Then entity(player) get owns(specialised-custom-attribute) get constraints do not contain: @card(<args>)
    Then relation(marriage) get owns(specialised-custom-attribute) get constraints do not contain: @card(<args>)
    Then entity(player) get constraints for owned attribute(specialised-custom-attribute) contain: @card(<args>)
    Then relation(marriage) get constraints for owned attribute(specialised-custom-attribute) contain: @card(<args>)
    Then entity(player) get constraints for owned attribute(specialised-custom-attribute) contain: @card(<args-specialise>)
    Then relation(marriage) get constraints for owned attribute(specialised-custom-attribute) contain: @card(<args-specialise>)
    Then entity(player) get constraints for owned attribute(custom-attribute) do not contain: @card(<args>)
    Then relation(marriage) get constraints for owned attribute(custom-attribute) do not contain: @card(<args>)
    Then entity(player) get constraints for owned attribute(custom-attribute) contain: @card(<args-specialise>)
    Then relation(marriage) get constraints for owned attribute(custom-attribute) contain: @card(<args-specialise>)
    Then entity(person) get constraints for owned attribute(second-custom-attribute) contain: @card(<args>)
    Then relation(description) get constraints for owned attribute(second-custom-attribute) contain: @card(<args>)
    Then entity(person) get constraints for owned attribute(second-custom-attribute) do not contain: @card(<args-specialise>)
    Then relation(description) get constraints for owned attribute(second-custom-attribute) do not contain: @card(<args-specialise>)
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(player) get owns(custom-attribute) get constraints contain: @card(<args-specialise>)
    Then entity(person) get owns(custom-attribute) get constraints contain: @card(<args-specialise>)
    Then relation(marriage) get owns(custom-attribute) get constraints contain: @card(<args-specialise>)
    Then relation(description) get owns(custom-attribute) get constraints contain: @card(<args-specialise>)
    Then entity(player) get owns(specialised-custom-attribute) get constraints do not contain: @card(<args>)
    Then relation(marriage) get owns(specialised-custom-attribute) get constraints do not contain: @card(<args>)
    Then entity(player) get constraints for owned attribute(specialised-custom-attribute) contain: @card(<args>)
    Then relation(marriage) get constraints for owned attribute(specialised-custom-attribute) contain: @card(<args>)
    Then entity(player) get constraints for owned attribute(specialised-custom-attribute) contain: @card(<args-specialise>)
    Then relation(marriage) get constraints for owned attribute(specialised-custom-attribute) contain: @card(<args-specialise>)
    Then entity(player) get constraints for owned attribute(custom-attribute) do not contain: @card(<args>)
    Then relation(marriage) get constraints for owned attribute(custom-attribute) do not contain: @card(<args>)
    Then entity(player) get constraints for owned attribute(custom-attribute) contain: @card(<args-specialise>)
    Then relation(marriage) get constraints for owned attribute(custom-attribute) contain: @card(<args-specialise>)
    Then entity(person) get constraints for owned attribute(second-custom-attribute) contain: @card(<args>)
    Then relation(description) get constraints for owned attribute(second-custom-attribute) contain: @card(<args>)
    Then entity(person) get constraints for owned attribute(second-custom-attribute) do not contain: @card(<args-specialise>)
    Then relation(description) get constraints for owned attribute(second-custom-attribute) do not contain: @card(<args-specialise>)
    Examples:
      | value-type  | args       | args-specialise |
      | integer     | 0..10000   | 0..10001        |
      | double      | 0..10      | 1..11           |
      | string      | 1..        | 0..2            |
      | decimal     | 2..2       | 1..1            |
      | date        | 1..5       | 1..             |
      | datetime    | 1..5       | 6..10           |
      | datetime-tz | 38..111    | 37..111         |
      | duration    | 1000..1100 | 1000..1199      |

  Scenario Outline: Cardinality can be narrowed for the same attribute for <root-type>'s owns
    When create attribute type: name
    When attribute(name) set value type: <value-type>
    When <root-type>(<supertype-name>) set owns: name
    When <root-type>(<supertype-name>) get owns(name) set annotation: @card(0..)
    When <root-type>(<subtype-name>) set supertype: <supertype-name>
    When <root-type>(<subtype-name-2>) set supertype: <subtype-name>
    When <root-type>(<subtype-name>) set owns: name
    Then <root-type>(<supertype-name>) get owns(name) get constraints contain: @card(0..)
    Then <root-type>(<subtype-name>) get owns(name) get constraints do not contain: @card(0..)
    Then <root-type>(<subtype-name-2>) get owns(name) get constraints do not contain: @card(0..)
    Then <root-type>(<supertype-name>) get owns(name) get declared annotations contain: @card(0..)
    Then <root-type>(<subtype-name>) get owns(name) get declared annotations do not contain: @card(0..)
    Then <root-type>(<subtype-name-2>) get owns(name) get declared annotations do not contain: @card(0..)
    Then <root-type>(<supertype-name>) get constraints for owned attribute(name) contain: @card(0..)
    Then <root-type>(<subtype-name>) get constraints for owned attribute(name) contain: @card(0..)
    Then <root-type>(<subtype-name-2>) get constraints for owned attribute(name) contain: @card(0..)
    When <root-type>(<subtype-name>) get owns(name) set annotation: @card(3..)
    Then <root-type>(<supertype-name>) get owns(name) get constraints contain: @card(0..)
    Then <root-type>(<subtype-name>) get owns(name) get constraints do not contain: @card(0..)
    Then <root-type>(<subtype-name-2>) get owns(name) get constraints do not contain: @card(0..)
    Then <root-type>(<supertype-name>) get owns(name) get declared annotations contain: @card(0..)
    Then <root-type>(<subtype-name>) get owns(name) get declared annotations do not contain: @card(0..)
    Then <root-type>(<subtype-name-2>) get owns(name) get declared annotations do not contain: @card(0..)
    Then <root-type>(<supertype-name>) get constraints for owned attribute(name) contain: @card(0..)
    Then <root-type>(<subtype-name>) get constraints for owned attribute(name) contain: @card(0..)
    Then <root-type>(<subtype-name-2>) get constraints for owned attribute(name) contain: @card(0..)
    Then <root-type>(<supertype-name>) get owns(name) get constraints do not contain: @card(3..)
    Then <root-type>(<subtype-name>) get owns(name) get constraints contain: @card(3..)
    Then <root-type>(<subtype-name-2>) get owns(name) get constraints contain: @card(3..)
    Then <root-type>(<supertype-name>) get owns(name) get declared annotations do not contain: @card(3..)
    Then <root-type>(<subtype-name>) get owns(name) get declared annotations contain: @card(3..)
    Then <root-type>(<subtype-name-2>) get owns(name) get declared annotations contain: @card(3..)
    Then <root-type>(<supertype-name>) get constraints for owned attribute(name) do not contain: @card(3..)
    Then <root-type>(<subtype-name>) get constraints for owned attribute(name) contain: @card(3..)
    Then <root-type>(<subtype-name-2>) get constraints for owned attribute(name) contain: @card(3..)
    Then <root-type>(<subtype-name-2>) get declared owns do not contain:
      | name |
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<supertype-name>) get owns(name) get constraints contain: @card(0..)
    Then <root-type>(<subtype-name>) get owns(name) get constraints do not contain: @card(0..)
    Then <root-type>(<subtype-name-2>) get owns(name) get constraints do not contain: @card(0..)
    Then <root-type>(<supertype-name>) get owns(name) get declared annotations contain: @card(0..)
    Then <root-type>(<subtype-name>) get owns(name) get declared annotations do not contain: @card(0..)
    Then <root-type>(<subtype-name-2>) get owns(name) get declared annotations do not contain: @card(0..)
    Then <root-type>(<supertype-name>) get constraints for owned attribute(name) contain: @card(0..)
    Then <root-type>(<subtype-name>) get constraints for owned attribute(name) contain: @card(0..)
    Then <root-type>(<subtype-name-2>) get constraints for owned attribute(name) contain: @card(0..)
    Then <root-type>(<supertype-name>) get owns(name) get constraints do not contain: @card(3..)
    Then <root-type>(<subtype-name>) get owns(name) get constraints contain: @card(3..)
    Then <root-type>(<subtype-name-2>) get owns(name) get constraints contain: @card(3..)
    Then <root-type>(<supertype-name>) get owns(name) get declared annotations do not contain: @card(3..)
    Then <root-type>(<subtype-name>) get owns(name) get declared annotations contain: @card(3..)
    Then <root-type>(<subtype-name-2>) get owns(name) get declared annotations contain: @card(3..)
    Then <root-type>(<supertype-name>) get constraints for owned attribute(name) do not contain: @card(3..)
    Then <root-type>(<subtype-name>) get constraints for owned attribute(name) contain: @card(3..)
    Then <root-type>(<subtype-name-2>) get constraints for owned attribute(name) contain: @card(3..)
    When <root-type>(<subtype-name-2>) set owns: name
    Then <root-type>(<subtype-name-2>) get owns(name) get declared annotations do not contain: @card(3..)
    Then <root-type>(<subtype-name-2>) get owns(name) get constraints do not contain: @card(3..)
    Then <root-type>(<subtype-name-2>) get constraints for owned attribute(name) contain: @card(3..)
    When <root-type>(<subtype-name-2>) get owns(name) set annotation: @card(3..6)
    Then <root-type>(<supertype-name>) get owns(name) get constraints contain: @card(0..)
    Then <root-type>(<subtype-name>) get owns(name) get constraints do not contain: @card(0..)
    Then <root-type>(<subtype-name-2>) get owns(name) get constraints do not contain: @card(0..)
    Then <root-type>(<supertype-name>) get owns(name) get declared annotations contain: @card(0..)
    Then <root-type>(<subtype-name>) get owns(name) get declared annotations do not contain: @card(0..)
    Then <root-type>(<subtype-name-2>) get owns(name) get declared annotations do not contain: @card(0..)
    Then <root-type>(<supertype-name>) get constraints for owned attribute(name) contain: @card(0..)
    Then <root-type>(<subtype-name>) get constraints for owned attribute(name) contain: @card(0..)
    Then <root-type>(<subtype-name-2>) get constraints for owned attribute(name) contain: @card(0..)
    Then <root-type>(<supertype-name>) get owns(name) get constraints do not contain: @card(3..)
    Then <root-type>(<subtype-name>) get owns(name) get constraints contain: @card(3..)
    Then <root-type>(<subtype-name-2>) get owns(name) get constraints do not contain: @card(3..)
    Then <root-type>(<supertype-name>) get owns(name) get declared annotations do not contain: @card(3..)
    Then <root-type>(<subtype-name>) get owns(name) get declared annotations contain: @card(3..)
    Then <root-type>(<subtype-name-2>) get owns(name) get declared annotations do not contain: @card(3..)
    Then <root-type>(<supertype-name>) get constraints for owned attribute(name) do not contain: @card(3..)
    Then <root-type>(<subtype-name>) get constraints for owned attribute(name) contain: @card(3..)
    Then <root-type>(<subtype-name-2>) get constraints for owned attribute(name) contain: @card(3..)
    Then <root-type>(<supertype-name>) get owns(name) get constraints do not contain: @card(3..6)
    Then <root-type>(<subtype-name>) get owns(name) get constraints do not contain: @card(3..6)
    Then <root-type>(<subtype-name-2>) get owns(name) get constraints contain: @card(3..6)
    Then <root-type>(<supertype-name>) get owns(name) get declared annotations do not contain: @card(3..6)
    Then <root-type>(<subtype-name>) get owns(name) get declared annotations do not contain: @card(3..6)
    Then <root-type>(<subtype-name-2>) get owns(name) get declared annotations contain: @card(3..6)
    Then <root-type>(<supertype-name>) get constraints for owned attribute(name) do not contain: @card(3..6)
    Then <root-type>(<subtype-name>) get constraints for owned attribute(name) do not contain: @card(3..6)
    Then <root-type>(<subtype-name-2>) get constraints for owned attribute(name) contain: @card(3..6)
    When transaction commits
    When connection open read transaction for database: typedb
    Then <root-type>(<supertype-name>) get owns(name) get constraints contain: @card(0..)
    Then <root-type>(<subtype-name>) get owns(name) get constraints do not contain: @card(0..)
    Then <root-type>(<subtype-name-2>) get owns(name) get constraints do not contain: @card(0..)
    Then <root-type>(<supertype-name>) get owns(name) get declared annotations contain: @card(0..)
    Then <root-type>(<subtype-name>) get owns(name) get declared annotations do not contain: @card(0..)
    Then <root-type>(<subtype-name-2>) get owns(name) get declared annotations do not contain: @card(0..)
    Then <root-type>(<supertype-name>) get constraints for owned attribute(name) contain: @card(0..)
    Then <root-type>(<subtype-name>) get constraints for owned attribute(name) contain: @card(0..)
    Then <root-type>(<subtype-name-2>) get constraints for owned attribute(name) contain: @card(0..)
    Then <root-type>(<supertype-name>) get owns(name) get constraints do not contain: @card(3..)
    Then <root-type>(<subtype-name>) get owns(name) get constraints contain: @card(3..)
    Then <root-type>(<subtype-name-2>) get owns(name) get constraints do not contain: @card(3..)
    Then <root-type>(<supertype-name>) get owns(name) get declared annotations do not contain: @card(3..)
    Then <root-type>(<subtype-name>) get owns(name) get declared annotations contain: @card(3..)
    Then <root-type>(<subtype-name-2>) get owns(name) get declared annotations do not contain: @card(3..)
    Then <root-type>(<supertype-name>) get constraints for owned attribute(name) do not contain: @card(3..)
    Then <root-type>(<subtype-name>) get constraints for owned attribute(name) contain: @card(3..)
    Then <root-type>(<subtype-name-2>) get constraints for owned attribute(name) contain: @card(3..)
    Then <root-type>(<supertype-name>) get owns(name) get constraints do not contain: @card(3..6)
    Then <root-type>(<subtype-name>) get owns(name) get constraints do not contain: @card(3..6)
    Then <root-type>(<subtype-name-2>) get owns(name) get constraints contain: @card(3..6)
    Then <root-type>(<supertype-name>) get owns(name) get declared annotations do not contain: @card(3..6)
    Then <root-type>(<subtype-name>) get owns(name) get declared annotations do not contain: @card(3..6)
    Then <root-type>(<subtype-name-2>) get owns(name) get declared annotations contain: @card(3..6)
    Then <root-type>(<supertype-name>) get constraints for owned attribute(name) do not contain: @card(3..6)
    Then <root-type>(<subtype-name>) get constraints for owned attribute(name) do not contain: @card(3..6)
    Then <root-type>(<subtype-name-2>) get constraints for owned attribute(name) contain: @card(3..6)
    Examples:
      | root-type | supertype-name | subtype-name | subtype-name-2 | value-type |
      | entity    | person         | customer     | subscriber     | decimal    |
      | relation  | description    | registration | profile        | string     |

    # TODO: We (temporarily) don't revalidate cardinality narrowing in schema!
#  Scenario Outline: Default @card annotation for <value-type> value type owns can be specialised only by a subset of arguments
#    When create attribute type: custom-attribute
#    When attribute(custom-attribute) set value type: <value-type>
#    When attribute(custom-attribute) set annotation: @abstract
#    When create attribute type: ordered-custom-attribute
#    When attribute(ordered-custom-attribute) set value type: <value-type>
#    When attribute(ordered-custom-attribute) set annotation: @abstract
#    When create attribute type: custom-attribute-2
#    When attribute(custom-attribute-2) set value type: <value-type>
#    When create attribute type: ordered-custom-attribute-2
#    When attribute(ordered-custom-attribute-2) set value type: <value-type>
#    When create attribute type: specialised-custom-attribute
#    When attribute(specialised-custom-attribute) set supertype: custom-attribute
#    When create attribute type: specialised-ordered-custom-attribute
#    When attribute(specialised-ordered-custom-attribute) set supertype: ordered-custom-attribute
#    When <root-type>(<supertype-name>) set owns: custom-attribute
#    Then <root-type>(<supertype-name>) get owns(custom-attribute) get ordering: unordered
#    Then <root-type>(<supertype-name>) get owns(custom-attribute) get cardinality: @card(0..1)
#    When <root-type>(<supertype-name>) set owns: custom-attribute-2
#    Then <root-type>(<supertype-name>) get owns(custom-attribute-2) get ordering: unordered
#    Then <root-type>(<supertype-name>) get owns(custom-attribute-2) get cardinality: @card(0..1)
#    When <root-type>(<supertype-name>) set owns: ordered-custom-attribute
#    When <root-type>(<supertype-name>) get owns(ordered-custom-attribute) set ordering: ordered
#    Then <root-type>(<supertype-name>) get owns(ordered-custom-attribute) get ordering: ordered
#    Then <root-type>(<supertype-name>) get owns(ordered-custom-attribute) get cardinality: @card(0..)
#    When <root-type>(<supertype-name>) set owns: ordered-custom-attribute-2
#    When <root-type>(<supertype-name>) get owns(ordered-custom-attribute-2) set ordering: ordered
#    Then <root-type>(<supertype-name>) get owns(ordered-custom-attribute-2) get ordering: ordered
#    Then <root-type>(<supertype-name>) get owns(ordered-custom-attribute-2) get cardinality: @card(0..)
#    When <root-type>(<subtype-name>) set supertype: <supertype-name>
#    When <root-type>(<subtype-name>) set owns: specialised-custom-attribute
#    When <root-type>(<subtype-name>) get owns(specialised-custom-attribute) set specialise: custom-attribute
#    When <root-type>(<subtype-name>) set owns: specialised-ordered-custom-attribute
#    Then <root-type>(<subtype-name>) get owns(specialised-ordered-custom-attribute) set specialise: ordered-custom-attribute; fails
#    When <root-type>(<subtype-name>) get owns(specialised-ordered-custom-attribute) set ordering: ordered
#    When <root-type>(<subtype-name>) get owns(specialised-ordered-custom-attribute) set specialise: ordered-custom-attribute
#    When <root-type>(<subtype-name>) set owns: custom-attribute-2
#    When <root-type>(<subtype-name>) set owns: ordered-custom-attribute-2
#    When <root-type>(<subtype-name>) get owns(custom-attribute-2) set specialise: custom-attribute-2
#    Then <root-type>(<subtype-name>) get owns(ordered-custom-attribute-2) set specialise: ordered-custom-attribute-2; fails
#    When <root-type>(<subtype-name>) get owns(ordered-custom-attribute-2) set ordering: ordered
#    When <root-type>(<subtype-name>) get owns(ordered-custom-attribute-2) set specialise: ordered-custom-attribute-2
#    When <root-type>(<subtype-name>) get owns(specialised-custom-attribute) set annotation: @card(0..1)
#    When <root-type>(<subtype-name>) get owns(specialised-ordered-custom-attribute) set annotation: @card(0..1)
#    When <root-type>(<subtype-name>) get owns(custom-attribute-2) set annotation: @card(0..1)
#    When <root-type>(<subtype-name>) get owns(ordered-custom-attribute-2) set annotation: @card(0..1)
#    Then <root-type>(<subtype-name>) get owns(specialised-custom-attribute) get cardinality: @card(0..1)
#    Then <root-type>(<subtype-name>) get owns(specialised-ordered-custom-attribute) get cardinality: @card(0..1)
#    Then <root-type>(<subtype-name>) get owns(custom-attribute-2) get cardinality: @card(0..1)
#    Then <root-type>(<subtype-name>) get owns(ordered-custom-attribute-2) get cardinality: @card(0..1)
#    Then <root-type>(<supertype-name>) get owns(custom-attribute) get cardinality: @card(0..1)
#    Then <root-type>(<supertype-name>) get owns(ordered-custom-attribute) get cardinality: @card(0..)
#    Then <root-type>(<supertype-name>) get owns(custom-attribute-2) get cardinality: @card(0..1)
#    Then <root-type>(<supertype-name>) get owns(ordered-custom-attribute-2) get cardinality: @card(0..)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then <root-type>(<subtype-name>) get owns(specialised-custom-attribute) get cardinality: @card(0..1)
#    Then <root-type>(<subtype-name>) get owns(specialised-ordered-custom-attribute) get cardinality: @card(0..1)
#    Then <root-type>(<subtype-name>) get owns(custom-attribute-2) get cardinality: @card(0..1)
#    Then <root-type>(<subtype-name>) get owns(ordered-custom-attribute-2) get cardinality: @card(0..1)
#    Then <root-type>(<supertype-name>) get owns(custom-attribute) get cardinality: @card(0..1)
#    Then <root-type>(<supertype-name>) get owns(ordered-custom-attribute) get cardinality: @card(0..)
#    Then <root-type>(<supertype-name>) get owns(custom-attribute-2) get cardinality: @card(0..1)
#    Then <root-type>(<supertype-name>) get owns(ordered-custom-attribute-2) get cardinality: @card(0..)
#    When <root-type>(<subtype-name>) get owns(specialised-custom-attribute) set annotation: @card(1..1)
#    When <root-type>(<subtype-name>) get owns(specialised-ordered-custom-attribute) set annotation: @card(1..1)
#    When <root-type>(<subtype-name>) get owns(custom-attribute-2) set annotation: @card(1..1)
#    When <root-type>(<subtype-name>) get owns(ordered-custom-attribute-2) set annotation: @card(1..1)
#    Then <root-type>(<subtype-name>) get owns(specialised-custom-attribute) get cardinality: @card(1..1)
#    Then <root-type>(<subtype-name>) get owns(specialised-ordered-custom-attribute) get cardinality: @card(1..1)
#    Then <root-type>(<subtype-name>) get owns(custom-attribute-2) get cardinality: @card(1..1)
#    Then <root-type>(<subtype-name>) get owns(ordered-custom-attribute-2) get cardinality: @card(1..1)
#    Then <root-type>(<supertype-name>) get owns(custom-attribute) get cardinality: @card(0..1)
#    Then <root-type>(<supertype-name>) get owns(ordered-custom-attribute) get cardinality: @card(0..)
#    Then <root-type>(<supertype-name>) get owns(custom-attribute-2) get cardinality: @card(0..1)
#    Then <root-type>(<supertype-name>) get owns(ordered-custom-attribute-2) get cardinality: @card(0..)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then <root-type>(<subtype-name>) get owns(specialised-custom-attribute) get cardinality: @card(1..1)
#    Then <root-type>(<subtype-name>) get owns(specialised-ordered-custom-attribute) get cardinality: @card(1..1)
#    Then <root-type>(<subtype-name>) get owns(custom-attribute-2) get cardinality: @card(1..1)
#    Then <root-type>(<subtype-name>) get owns(ordered-custom-attribute-2) get cardinality: @card(1..1)
#    Then <root-type>(<supertype-name>) get owns(custom-attribute) get cardinality: @card(0..1)
#    Then <root-type>(<supertype-name>) get owns(ordered-custom-attribute) get cardinality: @card(0..)
#    Then <root-type>(<supertype-name>) get owns(custom-attribute-2) get cardinality: @card(0..1)
#    Then <root-type>(<supertype-name>) get owns(ordered-custom-attribute-2) get cardinality: @card(0..)
#    Then <root-type>(<subtype-name>) get owns(specialised-custom-attribute) set annotation: @card(1..5); fails
#    When <root-type>(<subtype-name>) get owns(specialised-ordered-custom-attribute) set annotation: @card(1..5)
#    Then <root-type>(<subtype-name>) get owns(custom-attribute-2) set annotation: @card(1..5); fails
#    When <root-type>(<subtype-name>) get owns(ordered-custom-attribute-2) set annotation: @card(1..5)
#    Then <root-type>(<subtype-name>) get owns(specialised-custom-attribute) get cardinality: @card(1..1)
#    Then <root-type>(<subtype-name>) get owns(specialised-ordered-custom-attribute) get cardinality: @card(1..5)
#    Then <root-type>(<subtype-name>) get owns(custom-attribute-2) get cardinality: @card(1..1)
#    Then <root-type>(<subtype-name>) get owns(ordered-custom-attribute-2) get cardinality: @card(1..5)
#    Then <root-type>(<supertype-name>) get owns(custom-attribute) get cardinality: @card(0..1)
#    Then <root-type>(<supertype-name>) get owns(ordered-custom-attribute) get cardinality: @card(0..)
#    Then <root-type>(<supertype-name>) get owns(custom-attribute-2) get cardinality: @card(0..1)
#    Then <root-type>(<supertype-name>) get owns(ordered-custom-attribute-2) get cardinality: @card(0..)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then <root-type>(<subtype-name>) get owns(specialised-custom-attribute) get cardinality: @card(1..1)
#    Then <root-type>(<subtype-name>) get owns(specialised-ordered-custom-attribute) get cardinality: @card(1..5)
#    Then <root-type>(<subtype-name>) get owns(custom-attribute-2) get cardinality: @card(1..1)
#    Then <root-type>(<subtype-name>) get owns(ordered-custom-attribute-2) get cardinality: @card(1..5)
#    Then <root-type>(<supertype-name>) get owns(custom-attribute) get cardinality: @card(0..1)
#    Then <root-type>(<supertype-name>) get owns(ordered-custom-attribute) get cardinality: @card(0..)
#    Then <root-type>(<supertype-name>) get owns(custom-attribute-2) get cardinality: @card(0..1)
#    Then <root-type>(<supertype-name>) get owns(ordered-custom-attribute-2) get cardinality: @card(0..)
#    Then <root-type>(<subtype-name>) get owns(specialised-custom-attribute) set annotation: @card(0..); fails
#    When <root-type>(<subtype-name>) get owns(specialised-ordered-custom-attribute) set annotation: @card(0..)
#    Then <root-type>(<subtype-name>) get owns(custom-attribute-2) set annotation: @card(0..); fails
#    When <root-type>(<subtype-name>) get owns(ordered-custom-attribute-2) set annotation: @card(0..)
#    Then <root-type>(<subtype-name>) get owns(specialised-custom-attribute) get cardinality: @card(1..1)
#    Then <root-type>(<subtype-name>) get owns(specialised-ordered-custom-attribute) get cardinality: @card(0..)
#    Then <root-type>(<subtype-name>) get owns(custom-attribute-2) get cardinality: @card(1..1)
#    Then <root-type>(<subtype-name>) get owns(ordered-custom-attribute-2) get cardinality: @card(0..)
#    Then <root-type>(<supertype-name>) get owns(custom-attribute) get cardinality: @card(0..1)
#    Then <root-type>(<supertype-name>) get owns(ordered-custom-attribute) get cardinality: @card(0..)
#    Then <root-type>(<supertype-name>) get owns(custom-attribute-2) get cardinality: @card(0..1)
#    Then <root-type>(<supertype-name>) get owns(ordered-custom-attribute-2) get cardinality: @card(0..)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then <root-type>(<subtype-name>) get owns(specialised-custom-attribute) get cardinality: @card(1..1)
#    Then <root-type>(<subtype-name>) get owns(specialised-ordered-custom-attribute) get cardinality: @card(0..)
#    Then <root-type>(<subtype-name>) get owns(custom-attribute-2) get cardinality: @card(1..1)
#    Then <root-type>(<subtype-name>) get owns(ordered-custom-attribute-2) get cardinality: @card(0..)
#    Then <root-type>(<supertype-name>) get owns(custom-attribute) get cardinality: @card(0..1)
#    Then <root-type>(<supertype-name>) get owns(ordered-custom-attribute) get cardinality: @card(0..)
#    Then <root-type>(<supertype-name>) get owns(custom-attribute-2) get cardinality: @card(0..1)
#    Then <root-type>(<supertype-name>) get owns(ordered-custom-attribute-2) get cardinality: @card(0..)
#    When <root-type>(<subtype-name>) get owns(specialised-custom-attribute) unset annotation: @card
#    When <root-type>(<subtype-name>) get owns(specialised-ordered-custom-attribute) unset annotation: @card
#    When <root-type>(<subtype-name>) get owns(custom-attribute-2) unset annotation: @card
#    When <root-type>(<subtype-name>) get owns(ordered-custom-attribute-2) unset annotation: @card
#    Then <root-type>(<subtype-name>) get owns(specialised-custom-attribute) get cardinality: @card(0..1)
#    Then <root-type>(<subtype-name>) get owns(specialised-ordered-custom-attribute) get cardinality: @card(0..)
#    Then <root-type>(<subtype-name>) get owns(custom-attribute-2) get cardinality: @card(0..1)
#    Then <root-type>(<subtype-name>) get owns(ordered-custom-attribute-2) get cardinality: @card(0..)
#    Then <root-type>(<supertype-name>) get owns(custom-attribute) get cardinality: @card(0..1)
#    Then <root-type>(<supertype-name>) get owns(ordered-custom-attribute) get cardinality: @card(0..)
#    Then <root-type>(<supertype-name>) get owns(custom-attribute-2) get cardinality: @card(0..1)
#    Then <root-type>(<supertype-name>) get owns(ordered-custom-attribute-2) get cardinality: @card(0..)
#    Then transaction commits; fails
#    When connection open schema transaction for database: typedb
#    When <root-type>(<subtype-name>) get owns(specialised-custom-attribute) unset annotation: @card
#    When <root-type>(<subtype-name>) get owns(specialised-ordered-custom-attribute) unset annotation: @card
#    When <root-type>(<subtype-name>) get owns(custom-attribute-2) unset annotation: @card
#    When <root-type>(<subtype-name>) get owns(ordered-custom-attribute-2) unset annotation: @card
#    When <root-type>(<subtype-name>) get owns(custom-attribute-2) unset specialise
#    When <root-type>(<subtype-name>) get owns(ordered-custom-attribute-2) unset specialise
#    Then transaction commits; fails
#    When connection open schema transaction for database: typedb
#    When <root-type>(<subtype-name>) get owns(specialised-custom-attribute) unset annotation: @card
#    When <root-type>(<subtype-name>) get owns(specialised-ordered-custom-attribute) unset annotation: @card
#    When <root-type>(<subtype-name>) get owns(custom-attribute-2) unset annotation: @card
#    When <root-type>(<subtype-name>) get owns(ordered-custom-attribute-2) unset annotation: @card
#    When <root-type>(<subtype-name>) unset owns: custom-attribute-2
#    When <root-type>(<subtype-name>) unset owns: ordered-custom-attribute-2
#    Then <root-type>(<subtype-name>) get declared owns do not contain:
#      | custom-attribute-2         |
#      | ordered-custom-attribute-2 |
#    Then <root-type>(<subtype-name>) get owns contain:
#      | custom-attribute-2         |
#      | ordered-custom-attribute-2 |
#    Then <root-type>(<subtype-name>) get owns(specialised-custom-attribute) get cardinality: @card(0..1)
#    Then <root-type>(<subtype-name>) get owns(specialised-ordered-custom-attribute) get cardinality: @card(0..)
#    Then <root-type>(<subtype-name>) get owns(custom-attribute-2) get cardinality: @card(0..1)
#    Then <root-type>(<subtype-name>) get owns(ordered-custom-attribute-2) get cardinality: @card(0..)
#    Then <root-type>(<supertype-name>) get owns(custom-attribute) get cardinality: @card(0..1)
#    Then <root-type>(<supertype-name>) get owns(ordered-custom-attribute) get cardinality: @card(0..)
#    Then <root-type>(<supertype-name>) get owns(custom-attribute-2) get cardinality: @card(0..1)
#    Then <root-type>(<supertype-name>) get owns(ordered-custom-attribute-2) get cardinality: @card(0..)
#    When transaction commits
#    When connection open read transaction for database: typedb
#    Then <root-type>(<subtype-name>) get owns(specialised-custom-attribute) get cardinality: @card(0..1)
#    Then <root-type>(<subtype-name>) get owns(specialised-ordered-custom-attribute) get cardinality: @card(0..)
#    Then <root-type>(<subtype-name>) get owns(custom-attribute-2) get cardinality: @card(0..1)
#    Then <root-type>(<subtype-name>) get owns(ordered-custom-attribute-2) get cardinality: @card(0..)
#    Then <root-type>(<supertype-name>) get owns(custom-attribute) get cardinality: @card(0..1)
#    Then <root-type>(<supertype-name>) get owns(ordered-custom-attribute) get cardinality: @card(0..)
#    Then <root-type>(<supertype-name>) get owns(custom-attribute-2) get cardinality: @card(0..1)
#    Then <root-type>(<supertype-name>) get owns(ordered-custom-attribute-2) get cardinality: @card(0..)
#    Examples:
#      | root-type | supertype-name | subtype-name | value-type |
#      | entity    | person         | customer     | integer       |
#      | relation  | description    | registration | string     |

    # TODO: We (temporarily) don't revalidate cardinality narrowing in schema!
#  Scenario Outline: Owns cannot have card that is not narrowed by other owns narrowing it for different subowners
#    When create attribute type: name
#    When attribute(name) set annotation: @abstract
#    When attribute(name) set value type: <value-type>
#    When create attribute type: specialised-name
#    When attribute(specialised-name) set supertype: name
#    When create attribute type: specialised-name-2
#    When attribute(specialised-name-2) set supertype: name
#    When <root-type>(<supertype-name>) set owns: name
#    Then <root-type>(<supertype-name>) get owns(name) get cardinality: @card(0..1)
#    When <root-type>(<subtype-name>) set supertype: <supertype-name>
#    When <root-type>(<subtype-name>) set owns: specialised-name
#    When <root-type>(<subtype-name>) get owns(specialised-name) set specialise: name
#    Then <root-type>(<subtype-name>) get owns(specialised-name) get cardinality: @card(0..1)
#    When <root-type>(<subtype-name-2>) set supertype: <supertype-name>
#    When <root-type>(<subtype-name-2>) set owns: specialised-name-2
#    When <root-type>(<subtype-name-2>) get owns(specialised-name-2) set specialise: name
#    Then <root-type>(<subtype-name-2>) get owns(specialised-name-2) get cardinality: @card(0..1)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then <root-type>(<supertype-name>) get owns(name) get cardinality: @card(0..1)
#    Then <root-type>(<subtype-name>) get owns(specialised-name) get cardinality: @card(0..1)
#    Then <root-type>(<subtype-name-2>) get owns(specialised-name-2) get cardinality: @card(0..1)
#    Then <root-type>(<subtype-name>) get owns(specialised-name) set annotation: @card(1..2); fails
#    Then <root-type>(<subtype-name-2>) get owns(specialised-name-2) set annotation: @card(1..2); fails
#    When <root-type>(<supertype-name>) get owns(name) set annotation: @card(0..2)
#    When <root-type>(<subtype-name>) get owns(specialised-name) set annotation: @card(0..1)
#    When <root-type>(<subtype-name-2>) get owns(specialised-name-2) set annotation: @card(1..2)
#    Then <root-type>(<supertype-name>) get owns(name) get cardinality: @card(0..2)
#    Then <root-type>(<subtype-name>) get owns(specialised-name) get cardinality: @card(0..1)
#    Then <root-type>(<subtype-name-2>) get owns(specialised-name-2) get cardinality: @card(1..2)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then <root-type>(<supertype-name>) get owns(name) get cardinality: @card(0..2)
#    Then <root-type>(<subtype-name>) get owns(specialised-name) get cardinality: @card(0..1)
#    Then <root-type>(<subtype-name-2>) get owns(specialised-name-2) get cardinality: @card(1..2)
#    When <root-type>(<subtype-name>) get owns(specialised-name) set annotation: @card(1..2)
#    Then <root-type>(<subtype-name>) get owns(specialised-name) get cardinality: @card(1..2)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then <root-type>(<supertype-name>) get owns(name) get cardinality: @card(0..2)
#    Then <root-type>(<subtype-name>) get owns(specialised-name) get cardinality: @card(1..2)
#    Then <root-type>(<subtype-name-2>) get owns(specialised-name-2) get cardinality: @card(1..2)
#    When <root-type>(<subtype-name-2>) get owns(specialised-name-2) set annotation: @card(2..2)
#    Then <root-type>(<subtype-name-2>) get owns(specialised-name-2) get cardinality: @card(2..2)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then <root-type>(<supertype-name>) get owns(name) get cardinality: @card(0..2)
#    Then <root-type>(<subtype-name>) get owns(specialised-name) get cardinality: @card(1..2)
#    Then <root-type>(<subtype-name-2>) get owns(specialised-name-2) get cardinality: @card(2..2)
#    Then <root-type>(<supertype-name>) get owns(name) set annotation: @card(0..1); fails
#    Then <root-type>(<supertype-name>) get owns(name) set annotation: @card(2..2); fails
#    When <root-type>(<supertype-name>) get owns(name) set annotation: @card(0..)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then <root-type>(<supertype-name>) get owns(name) get cardinality: @card(0..)
#    Then <root-type>(<subtype-name>) get owns(specialised-name) get cardinality: @card(1..2)
#    Then <root-type>(<subtype-name-2>) get owns(specialised-name-2) get cardinality: @card(2..2)
#    When <root-type>(<subtype-name-2>) get owns(specialised-name-2) set annotation: @card(4..5)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then <root-type>(<supertype-name>) get owns(name) get cardinality: @card(0..)
#    Then <root-type>(<subtype-name>) get owns(specialised-name) get cardinality: @card(1..2)
#    Then <root-type>(<subtype-name-2>) get owns(specialised-name-2) get cardinality: @card(4..5)
#    Then <root-type>(<supertype-name>) get owns(name) set annotation: @card(0..4); fails
#    Then <root-type>(<supertype-name>) get owns(name) set annotation: @card(3..3); fails
#    Then <root-type>(<supertype-name>) get owns(name) set annotation: @card(2..5); fails
#    Then <root-type>(<supertype-name>) get owns(name) unset annotation: @card; fails
#    When <root-type>(<supertype-name>) get owns(name) set annotation: @card(0..5)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then <root-type>(<supertype-name>) get owns(name) get cardinality: @card(0..5)
#    Then <root-type>(<subtype-name>) get owns(specialised-name) get cardinality: @card(1..2)
#    Then <root-type>(<subtype-name-2>) get owns(specialised-name-2) get cardinality: @card(4..5)
#    When <root-type>(<subtype-name>) get owns(specialised-name) set annotation: @card(1..1)
#    When <root-type>(<subtype-name-2>) get owns(specialised-name-2) set annotation: @card(0..1)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then <root-type>(<supertype-name>) get owns(name) get cardinality: @card(0..5)
#    Then <root-type>(<subtype-name>) get owns(specialised-name) get cardinality: @card(1..1)
#    Then <root-type>(<subtype-name-2>) get owns(specialised-name-2) get cardinality: @card(0..1)
#    When <root-type>(<supertype-name>) get owns(name) unset annotation: @card
#    When transaction commits
#    When connection open read transaction for database: typedb
#    Then <root-type>(<supertype-name>) get owns(name) get cardinality: @card(0..1)
#    Then <root-type>(<subtype-name>) get owns(specialised-name) get cardinality: @card(1..1)
#    Then <root-type>(<subtype-name-2>) get owns(specialised-name-2) get cardinality: @card(0..1)
#    Then <root-type>(<supertype-name>) get owns(name) get constraints do not contain: @card(0..1)
#    Then <root-type>(<subtype-name>) get owns(specialised-name) get constraints contain: @card(1..1)
#    Then <root-type>(<subtype-name-2>) get owns(specialised-name-2) get constraints contain: @card(0..1)
#    Examples:
#      | root-type | supertype-name | subtype-name | subtype-name-2 | value-type |
#      | entity    | person         | customer     | subscriber     | decimal    |
#      | relation  | description    | registration | profile        | double     |

    # TODO: We (temporarily) don't revalidate cardinality narrowing in schema!
#  Scenario Outline: Owns can have multiple specialising owns with narrowing cardinalities and correct min sum
#    When create attribute type: attribute-to-disturb
#    When attribute(attribute-to-disturb) set value type: string
#    When attribute(attribute-to-disturb) set annotation: @abstract
#    When <root-type>(<supertype-name>) set owns: attribute-to-disturb
#    When <root-type>(<supertype-name>) get owns(attribute-to-disturb) set annotation: @card(1..1)
#    When create attribute type: subtype-to-disturb
#    When attribute(subtype-to-disturb) set supertype: attribute-to-disturb
#    When attribute(subtype-to-disturb) set annotation: @abstract
#    When <root-type>(<subtype-name>) set supertype: <supertype-name>
#    When <root-type>(<subtype-name>) set owns: subtype-to-disturb
#    When <root-type>(<subtype-name>) get owns(subtype-to-disturb) set specialise: attribute-to-disturb
#    Then <root-type>(<subtype-name>) get owns(subtype-to-disturb) get cardinality: @card(1..1)
#    When create attribute type: literal
#    When attribute(literal) set value type: string
#    When attribute(literal) set annotation: @abstract
#    When <root-type>(<supertype-name>) set owns: literal
#    When <root-type>(<supertype-name>) get owns(literal) set annotation: @card(1..2)
#    When <root-type>(<supertype-name>) get owns(literal) get cardinality: @card(1..2)
#    When create attribute type: name
#    When attribute(name) set supertype: literal
#    When <root-type>(<subtype-name>) set owns: name
#    When <root-type>(<subtype-name>) get owns(name) set specialise: literal
#    Then <root-type>(<subtype-name>) get owns(name) get cardinality: @card(1..2)
#    When create attribute type: text
#    When attribute(text) set supertype: literal
#    When <root-type>(<subtype-name>) set owns: text
#    When <root-type>(<subtype-name>) get owns(text) set specialise: literal
#    Then <root-type>(<subtype-name>) get owns(text) get cardinality: @card(1..2)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    When <root-type>(<subtype-name>) get owns(name) set annotation: @card(1..1)
#    Then <root-type>(<subtype-name>) get owns(name) get cardinality: @card(1..1)
#    When <root-type>(<subtype-name>) get owns(text) set annotation: @card(1..1)
#    Then <root-type>(<subtype-name>) get owns(text) get cardinality: @card(1..1)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    When create attribute type: cardinality-destroyer
#    When attribute(cardinality-destroyer) set supertype: literal
#    When <root-type>(<subtype-name>) set owns: cardinality-destroyer
#    # card becomes 1..2
#    Then <root-type>(<subtype-name>) get owns(cardinality-destroyer) set specialise: literal; fails
#    When transaction closes
#    When connection open schema transaction for database: typedb
#    When create attribute type: cardinality-destroyer
#    When attribute(cardinality-destroyer) set supertype: literal
#    When <root-type>(<subtype-name>) set owns: cardinality-destroyer
#    When <root-type>(<supertype-name>) get owns(literal) set annotation: @card(1..3)
#    Then <root-type>(<supertype-name>) get owns(literal) get cardinality: @card(1..3)
#    When <root-type>(<subtype-name>) get owns(cardinality-destroyer) set specialise: literal
#    Then <root-type>(<subtype-name>) get owns(name) get cardinality: @card(1..1)
#    Then <root-type>(<subtype-name>) get owns(text) get cardinality: @card(1..1)
#    Then <root-type>(<subtype-name>) get owns(cardinality-destroyer) get cardinality: @card(1..3)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    When <root-type>(<supertype-name>) get owns(literal) set annotation: @card(0..3)
#    Then <root-type>(<supertype-name>) get owns(literal) get cardinality: @card(0..3)
#    Then <root-type>(<subtype-name>) get owns(name) get cardinality: @card(1..1)
#    Then <root-type>(<subtype-name>) get owns(text) get cardinality: @card(1..1)
#    Then <root-type>(<subtype-name>) get owns(cardinality-destroyer) get cardinality: @card(0..3)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then <root-type>(<subtype-name>) get owns(cardinality-destroyer) set annotation: @card(3..3); fails
#    Then <root-type>(<subtype-name>) get owns(cardinality-destroyer) set annotation: @card(2..3); fails
#    When <root-type>(<subtype-name>) get owns(name) set annotation: @card(0..1)
#    When <root-type>(<subtype-name>) get owns(cardinality-destroyer) set annotation: @card(2..3)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then <root-type>(<supertype-name>) get owns(literal) get cardinality: @card(0..3)
#    Then <root-type>(<subtype-name>) get owns(name) get cardinality: @card(0..1)
#    Then <root-type>(<subtype-name>) get owns(text) get cardinality: @card(1..1)
#    Then <root-type>(<subtype-name>) get owns(cardinality-destroyer) get cardinality: @card(2..3)
#    Then <root-type>(<supertype-name>) get owns(literal) set annotation: @card(0..1); fails
#    When <root-type>(<subtype-name>) get owns(name) unset annotation: @card
#    When <root-type>(<subtype-name>) get owns(text) unset annotation: @card
#    When <root-type>(<subtype-name>) get owns(cardinality-destroyer) unset annotation: @card
#    When <root-type>(<supertype-name>) get owns(literal) set annotation: @card(0..1)
#    Then <root-type>(<supertype-name>) get owns(literal) get cardinality: @card(0..1)
#    Then <root-type>(<subtype-name>) get owns(name) get cardinality: @card(0..1)
#    Then <root-type>(<subtype-name>) get owns(text) get cardinality: @card(0..1)
#    Then <root-type>(<subtype-name>) get owns(cardinality-destroyer) get cardinality: @card(0..1)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    When <root-type>(<subtype-name>) get owns(name) set annotation: @card(1..1)
#    Then <root-type>(<supertype-name>) get owns(literal) get cardinality: @card(0..1)
#    Then <root-type>(<subtype-name>) get owns(name) get cardinality: @card(1..1)
#    Then <root-type>(<subtype-name>) get owns(text) get cardinality: @card(0..1)
#    Then <root-type>(<subtype-name>) get owns(cardinality-destroyer) get cardinality: @card(0..1)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then <root-type>(<subtype-name>) get owns(cardinality-destroyer) set annotation: @card(1..1); fails
#    When create attribute type: subsubtype-to-disturb
#    When attribute(subsubtype-to-disturb) set supertype: subtype-to-disturb
#    When <root-type>(<subtype-name-2>) set supertype: <subtype-name>
#    When <root-type>(<subtype-name-2>) set owns: subsubtype-to-disturb
#    When <root-type>(<subtype-name-2>) get owns(subsubtype-to-disturb) set specialise: subtype-to-disturb
#    Then <root-type>(<subtype-name-2>) get owns(subsubtype-to-disturb) get cardinality: @card(1..1)
#    When transaction commits
#    Examples:
#      | root-type | supertype-name | subtype-name | subtype-name-2 |
#      | entity    | person         | customer     | subscriber     |
#      | relation  | description    | registration | profile        |

    # TODO: We (temporarily) don't revalidate cardinality narrowing in schema!
#  Scenario Outline: Type can have only N/M specialising owns when the root owns has cardinality(M, N) that are inherited
#    When create attribute type: literal
#    When attribute(literal) set value type: string
#    When attribute(literal) set annotation: @abstract
#    When <root-type>(<supertype-name>) set owns: literal
#    When <root-type>(<supertype-name>) get owns(literal) set annotation: @card(1..1)
#    When <root-type>(<supertype-name>) get owns(literal) get cardinality: @card(1..1)
#    When create attribute type: name
#    When attribute(name) set supertype: literal
#    When create attribute type: surname
#    When attribute(surname) set supertype: literal
#    When create attribute type: third-name
#    When attribute(third-name) set supertype: literal
#    When <root-type>(<subtype-name>) set supertype: <supertype-name>
#    When <root-type>(<subtype-name>) set owns: name
#    When <root-type>(<subtype-name>) set owns: surname
#    When <root-type>(<subtype-name>) set owns: third-name
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    When <root-type>(<subtype-name>) get owns(name) set specialise: literal
#    Then <root-type>(<subtype-name>) get owns(name) get cardinality: @card(1..1)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    # card becomes 1..1
#    Then <root-type>(<subtype-name>) get owns(surname) set specialise: literal; fails
#    # card becomes 1..1
#    When <root-type>(<subtype-name>) get owns(third-name) set specialise: literal; fails
#    When <root-type>(<subtype-name>) get owns(name) unset specialise
#    When <root-type>(<supertype-name>) get owns(literal) set annotation: @card(1..2)
#    When <root-type>(<supertype-name>) get owns(literal) get cardinality: @card(1..2)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    When <root-type>(<subtype-name>) get owns(name) set specialise: literal
#    Then <root-type>(<subtype-name>) get owns(name) get cardinality: @card(1..2)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    When <root-type>(<subtype-name>) get owns(surname) set specialise: literal
#    Then <root-type>(<subtype-name>) get owns(surname) get cardinality: @card(1..2)
#    # card becomes 1..2
#    Then <root-type>(<subtype-name>) get owns(third-name) set specialise: literal; fails
#    When transaction closes
#    When connection open schema transaction for database: typedb
#    When <root-type>(<subtype-name>) get owns(surname) set specialise: literal
#    Then <root-type>(<subtype-name>) get owns(surname) get cardinality: @card(1..2)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    # card becomes 1..2
#    Then <root-type>(<subtype-name>) get owns(third-name) set specialise: literal; fails
#    When <root-type>(<subtype-name>) get owns(name) unset specialise
#    When <root-type>(<subtype-name>) get owns(surname) unset specialise
#    When <root-type>(<supertype-name>) get owns(literal) set annotation: @card(1..3)
#    When <root-type>(<supertype-name>) get owns(literal) get cardinality: @card(1..3)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    When <root-type>(<subtype-name>) get owns(surname) set specialise: literal
#    Then <root-type>(<subtype-name>) get owns(surname) get cardinality: @card(1..3)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    When <root-type>(<subtype-name>) get owns(third-name) set specialise: literal
#    Then <root-type>(<subtype-name>) get owns(third-name) get cardinality: @card(1..3)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    When <root-type>(<subtype-name>) get owns(name) set specialise: literal
#    Then <root-type>(<subtype-name>) get owns(name) get cardinality: @card(1..3)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then <root-type>(<supertype-name>) get owns(literal) set annotation: @card(2..3); fails
#    When <root-type>(<subtype-name>) get owns(third-name) unset specialise
#    Then <root-type>(<supertype-name>) get owns(literal) set annotation: @card(2..3); fails
#    When transaction closes
#    When connection open schema transaction for database: typedb
#    Then <root-type>(<supertype-name>) get owns(literal) set annotation: @card(2..3); fails
#    When <root-type>(<subtype-name>) get owns(third-name) unset specialise
#    When <root-type>(<subtype-name>) get owns(surname) unset specialise
#    When <root-type>(<supertype-name>) get owns(literal) set annotation: @card(2..3)
#    When <root-type>(<supertype-name>) get owns(literal) get cardinality: @card(2..3)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    # card becomes 2..3
#    Then <root-type>(<subtype-name>) get owns(surname) set specialise: literal; fails
#    When <root-type>(<supertype-name>) get owns(literal) set annotation: @card(2..4)
#    When <root-type>(<supertype-name>) get owns(literal) get cardinality: @card(2..4)
#    When <root-type>(<subtype-name>) get owns(surname) set specialise: literal
#    When <root-type>(<subtype-name>) get owns(surname) get cardinality: @card(2..4)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    # card becomes 2..4
#    Then <root-type>(<subtype-name>) get owns(third-name) set specialise: literal; fails
#    When <root-type>(<supertype-name>) get owns(literal) set annotation: @card(2..6)
#    When <root-type>(<supertype-name>) get owns(literal) get cardinality: @card(2..6)
#    When <root-type>(<subtype-name>) get owns(third-name) set specialise: literal
#    When <root-type>(<subtype-name>) get owns(third-name) get cardinality: @card(2..6)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then <root-type>(<supertype-name>) get owns(literal) set annotation: @card(2..5); fails
#    Then <root-type>(<supertype-name>) get owns(literal) set annotation: @card(3..8); fails
#    When <root-type>(<supertype-name>) get owns(literal) set annotation: @card(3..9)
#    Then <root-type>(<supertype-name>) get owns(literal) get cardinality: @card(3..9)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then <root-type>(<supertype-name>) get owns(literal) set annotation: @card(1..1); fails
#    When <root-type>(<supertype-name>) get owns(literal) set annotation: @card(0..1)
#    Then <root-type>(<supertype-name>) get owns(literal) get cardinality: @card(0..1)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    When <root-type>(<subtype-name>) get owns(third-name) set annotation: @card(1..1)
#    Then <root-type>(<subtype-name>) get owns(third-name) get cardinality: @card(1..1)
#    Then <root-type>(<subtype-name>) get owns(surname) get cardinality: @card(0..1)
#    Then <root-type>(<subtype-name>) get owns(name) get cardinality: @card(0..1)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then <root-type>(<subtype-name>) get owns(third-name) get cardinality: @card(1..1)
#    Then <root-type>(<subtype-name>) get owns(name) get cardinality: @card(0..1)
#    Then <root-type>(<subtype-name>) get owns(surname) set annotation: @card(1..1); fails
#    Examples:
#      | root-type | supertype-name | subtype-name |
#      | entity    | person         | customer     |
#      | relation  | description    | registration |

    # TODO: We (temporarily) don't revalidate cardinality narrowing in schema!
#  Scenario: Owns cardinality should be checked against specialises' specialises cardinality
#    When create attribute type: literal
#    When attribute(literal) set value type: string
#    When attribute(literal) set annotation: @abstract
#    When entity(person) set owns: literal
#    When entity(person) get owns(literal) set annotation: @card(5..10)
#    Then entity(person) get owns(literal) get cardinality: @card(5..10)
#    When create attribute type: name
#    When attribute(name) set supertype: literal
#    When attribute(name) set annotation: @abstract
#    When entity(customer) set supertype: person
#    When entity(customer) set owns: name
#    When entity(customer) get owns(name) set specialise: literal
#    Then entity(customer) get owns(name) get cardinality: @card(5..10)
#    When create attribute type: text
#    When attribute(text) set supertype: literal
#    When attribute(text) set annotation: @abstract
#    When entity(customer) set owns: text
#    When entity(customer) get owns(text) set specialise: literal
#    Then entity(customer) get owns(text) get cardinality: @card(5..10)
#    When create attribute type: surname
#    When attribute(surname) set supertype: name
#    When entity(subscriber) set supertype: customer
#    When entity(subscriber) set owns: surname
#    When entity(subscriber) get owns(surname) set specialise: name
#    Then entity(subscriber) get owns(surname) get cardinality: @card(5..10)
#    When create attribute type: article
#    When attribute(article) set supertype: text
#    When entity(subscriber) set owns: article
#    When entity(subscriber) get owns(article) set specialise: text
#    Then entity(subscriber) get owns(article) get cardinality: @card(5..10)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    When create attribute type: surname-2
#    When attribute(surname-2) set supertype: name
#    When entity(subscriber) set owns: surname-2
#    Then entity(subscriber) get owns(surname-2) get cardinality: @card(0..1)
#    When create attribute type: article-2
#    When attribute(article-2) set supertype: text
#    When entity(subscriber) set owns: article-2
#    Then entity(subscriber) get owns(article-2) get cardinality: @card(0..1)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    # card becomes 5..10
#    Then entity(subscriber) get owns(surname-2) set specialise: name; fails
#    # card becomes 5..10
#    When entity(subscriber) get owns(article-2) set specialise: text; fails
#    When entity(person) get owns(literal) set annotation: @card(3..10)
#    Then entity(person) get owns(literal) get cardinality: @card(3..10)
#    When entity(subscriber) get owns(surname-2) set specialise: name
#    Then entity(subscriber) get owns(surname-2) get cardinality: @card(3..10)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    When entity(subscriber) get owns(surname-2) set specialise: name
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    # card becomes 3..10
#    Then entity(subscriber) get owns(article-2) set specialise: text; fails
#    When entity(person) get owns(literal) set annotation: @card(3..)
#    Then entity(person) get owns(literal) get cardinality: @card(3..)
#    When entity(subscriber) get owns(article-2) set specialise: text
#    Then entity(subscriber) get owns(article-2) get cardinality: @card(3..)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    When entity(customer) get owns(name) unset specialise
#    When entity(customer) get owns(text) unset specialise
#    When entity(customer) get owns(name) set annotation: @card(0..)
#    When entity(customer) get owns(text) set annotation: @card(0..)
#    When entity(person) get owns(literal) set annotation: @card(1..1)
#    Then entity(person) get owns(literal) get cardinality: @card(1..1)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    When entity(subscriber) get owns(surname-2) unset specialise
#    When entity(customer) get owns(name) unset annotation: @card
#    When entity(customer) get owns(name) set specialise: literal
#    Then entity(subscriber) get owns(surname) get cardinality: @card(1..1)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then entity(subscriber) get owns(surname) get cardinality: @card(1..1)
#    # card becomes 1..1
#    Then entity(subscriber) get owns(surname-2) set specialise: name; fails
#    When entity(person) get owns(literal) set annotation: @card(2..5)
#    When entity(subscriber) get owns(surname-2) set specialise: name
#    Then entity(subscriber) get owns(surname-2) get cardinality: @card(2..5)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    When entity(subscriber) get owns(article-2) unset specialise
#    When entity(customer) get owns(text) unset annotation: @card
#    # subscriber: 2 article + 2 surname + 2 surname-2 = 6 > 5
#    Then entity(customer) get owns(text) set specialise: literal; fails
#    When entity(person) get owns(literal) set annotation: @card(2..6)
#    When entity(customer) get owns(text) set specialise: literal
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then entity(subscriber) get owns(article-2) set specialise: text; fails
#    When create attribute type: logo
#    When attribute(logo) set supertype: name
#    When attribute(logo) set annotation: @abstract
#    When create entity type: real-customer
#    When entity(real-customer) set supertype: customer
#    When entity(real-customer) set annotation: @abstract
#    When entity(real-customer) set owns: logo
#    When entity(real-customer) get owns(logo) set specialise: name
#    Then entity(real-customer) get owns(logo) get cardinality: @card(2..6)
#    When create attribute type: book
#    When attribute(book) set supertype: text
#    When attribute(book) set annotation: @abstract
#    When entity(real-customer) set owns: book
#    When entity(real-customer) get owns(book) set specialise: text
#    Then entity(real-customer) get owns(book) get cardinality: @card(2..6)
#    When create attribute type: book-starting-A
#    When attribute(book-starting-A) set supertype: book
#    When attribute(book-starting-A) set annotation: @abstract
#    When create attribute type: book-starting-B
#    When attribute(book-starting-B) set supertype: book
#    When attribute(book-starting-B) set annotation: @abstract
#    When create attribute type: book-starting-C
#    When attribute(book-starting-C) set supertype: book
#    When attribute(book-starting-C) set annotation: @abstract
#    When create entity type: real-customer-with-three-books
#    When entity(real-customer-with-three-books) set supertype: real-customer
#    When entity(real-customer-with-three-books) set annotation: @abstract
#    When entity(real-customer-with-three-books) set owns: book-starting-A
#    When entity(real-customer-with-three-books) get owns(book-starting-A) set specialise: book
#    Then entity(real-customer-with-three-books) get owns(book-starting-A) get cardinality: @card(2..6)
#    When entity(real-customer-with-three-books) set owns: book-starting-B
#    When entity(real-customer-with-three-books) get owns(book-starting-B) set specialise: book
#    Then entity(real-customer-with-three-books) get owns(book-starting-B) get cardinality: @card(2..6)
#    When entity(real-customer-with-three-books) set owns: book-starting-C
#    When entity(real-customer-with-three-books) get owns(book-starting-C) set specialise: book
#    Then entity(real-customer-with-three-books) get owns(book-starting-C) get cardinality: @card(2..6)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    When create attribute type: book-logo
#    When attribute(book-logo) set supertype: logo
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    When entity(real-customer-with-three-books) set owns: book-logo
#    # card becomes 2..6
#    Then entity(real-customer-with-three-books) get owns(book-logo) set specialise: logo; fails
#    When transaction closes
#    When connection open schema transaction for database: typedb
#    When entity(customer) get owns(name) unset specialise
#    When entity(customer) get owns(name) set annotation: @card(2..6)
#    When entity(real-customer-with-three-books) set owns: book-logo
#    When entity(real-customer-with-three-books) get owns(book-logo) set specialise: logo
#    Then entity(real-customer-with-three-books) get owns(book-logo) get cardinality: @card(2..6)
#    Then transaction commits

  Scenario: Owns default cardinality is permissively validated in multiple inheritance
    When create attribute type: literal
    When attribute(literal) set value type: string
    When attribute(literal) set annotation: @abstract
    When entity(person) set owns: literal
    Then entity(person) get owns(literal) get cardinality: @card(0..1)
    When create attribute type: name
    When attribute(name) set supertype: literal
    When attribute(name) set annotation: @abstract
    When entity(customer) set supertype: person
    When entity(customer) set owns: name
    Then entity(customer) get owns(name) get cardinality: @card(0..1)
    When transaction commits
    When connection open schema transaction for database: typedb
    When create attribute type: surname
    When attribute(surname) set supertype: name
    When entity(subscriber) set supertype: customer
    When entity(subscriber) set owns: surname
    Then entity(subscriber) get owns(surname) get cardinality: @card(0..1)
    When transaction commits
    When connection open schema transaction for database: typedb
    When create attribute type: third-name
    When attribute(third-name) set supertype: name
    When entity(subscriber) set owns: third-name
    Then entity(subscriber) get owns(third-name) get cardinality: @card(0..1)
    Then transaction commits

  Scenario Outline: Owns unset annotation @card cannot break cardinality between affected siblings
    When create attribute type: literal
    When attribute(literal) set value type: string
    When attribute(literal) set annotation: @abstract
    When <root-type>(<supertype-name>) set owns: literal
    Then <root-type>(<supertype-name>) get owns(literal) set annotation: @card(1..1)
    Then <root-type>(<supertype-name>) get owns(literal) get cardinality: @card(1..1)
    Then <root-type>(<supertype-name>) get constraints for owned attribute(literal) contain: @card(1..1)
    Then <root-type>(<supertype-name>) get constraints for owned attribute(literal) do not contain: @card(0..1)
    When create attribute type: name
    When attribute(name) set supertype: literal
    When attribute(name) set annotation: @abstract
    When create attribute type: letter
    When attribute(letter) set supertype: literal
    When attribute(letter) set annotation: @abstract
    When <root-type>(<subtype-name>) set supertype: <supertype-name>
    When <root-type>(<subtype-name>) set owns: name
    Then <root-type>(<subtype-name>) get owns(name) get cardinality: @card(0..1)
    Then <root-type>(<subtype-name>) get constraints for owned attribute(name) contain: @card(1..1)
    Then <root-type>(<subtype-name>) get constraints for owned attribute(name) contain: @card(0..1)
    When <root-type>(<subtype-name>) set owns: letter
    Then <root-type>(<supertype-name>) get owns(literal) set annotation: @card(1..2)
    Then <root-type>(<subtype-name>) get owns(name) get cardinality: @card(0..1)
    Then <root-type>(<subtype-name>) get constraints for owned attribute(name) contain: @card(1..2)
    Then <root-type>(<subtype-name>) get constraints for owned attribute(name) contain: @card(0..1)
    Then <root-type>(<subtype-name>) get constraints for owned attribute(name) do not contain: @card(1..1)
    Then <root-type>(<supertype-name>) get owns(literal) get cardinality: @card(1..2)
    Then <root-type>(<subtype-name>) get owns(letter) get cardinality: @card(0..1)
    Then <root-type>(<subtype-name>) get constraints for owned attribute(letter) contain: @card(1..2)
    Then <root-type>(<subtype-name>) get constraints for owned attribute(letter) contain: @card(0..1)
    Then <root-type>(<subtype-name>) get constraints for owned attribute(letter) do not contain: @card(1..1)
    When create attribute type: surname
    When attribute(surname) set supertype: name
    When create attribute type: first-name
    When attribute(first-name) set supertype: name
    When <root-type>(<subtype-name-2>) set supertype: <subtype-name>
    When <root-type>(<subtype-name-2>) set owns: first-name
    When <root-type>(<subtype-name-2>) set owns: surname
    Then <root-type>(<subtype-name-2>) get owns(first-name) get cardinality: @card(0..1)
    Then <root-type>(<subtype-name-2>) get constraints for owned attribute(first-name) contain: @card(1..2)
    Then <root-type>(<subtype-name-2>) get constraints for owned attribute(first-name) contain: @card(0..1)
    Then <root-type>(<subtype-name-2>) get owns(surname) get cardinality: @card(0..1)
    Then <root-type>(<subtype-name-2>) get constraints for owned attribute(surname) contain: @card(1..2)
    Then <root-type>(<subtype-name-2>) get constraints for owned attribute(surname) contain: @card(0..1)
    When transaction commits
    When connection open schema transaction for database: typedb
    When <root-type>(<supertype-name>) get owns(literal) unset annotation: @card
    Then <root-type>(<supertype-name>) get owns(literal) get cardinality: @card(0..1)
    Then <root-type>(<supertype-name>) get constraints for owned attribute(literal) contain: @card(0..1)
    Then <root-type>(<supertype-name>) get constraints for owned attribute(literal) do not contain: @card(1..2)
    Then <root-type>(<subtype-name>) get owns(name) get cardinality: @card(0..1)
    Then <root-type>(<subtype-name>) get constraints for owned attribute(name) contain: @card(0..1)
    Then <root-type>(<subtype-name>) get constraints for owned attribute(name) do not contain: @card(1..2)
    Then <root-type>(<subtype-name>) get owns(letter) get cardinality: @card(0..1)
    Then <root-type>(<subtype-name>) get constraints for owned attribute(letter) contain: @card(0..1)
    Then <root-type>(<subtype-name>) get constraints for owned attribute(letter) do not contain: @card(1..2)
    Then <root-type>(<subtype-name-2>) get owns(first-name) get cardinality: @card(0..1)
    Then <root-type>(<subtype-name-2>) get constraints for owned attribute(first-name) contain: @card(0..1)
    Then <root-type>(<subtype-name-2>) get constraints for owned attribute(first-name) do not contain: @card(1..2)
    Then <root-type>(<subtype-name-2>) get owns(surname) get cardinality: @card(0..1)
    Then <root-type>(<subtype-name-2>) get constraints for owned attribute(surname) contain: @card(0..1)
    Then <root-type>(<subtype-name-2>) get constraints for owned attribute(surname) do not contain: @card(1..2)
    When <root-type>(<supertype-name>) get owns(literal) set annotation: @card(0..2)
    When <root-type>(<subtype-name>) get owns(name) set annotation: @card(1..2)
    Then <root-type>(<subtype-name-2>) get owns(first-name) get cardinality: @card(0..1)
    Then <root-type>(<subtype-name-2>) get constraints for owned attribute(first-name) contain: @card(0..1)
    Then <root-type>(<subtype-name-2>) get constraints for owned attribute(first-name) contain: @card(0..2)
    Then <root-type>(<subtype-name-2>) get constraints for owned attribute(first-name) contain: @card(1..2)
    Then <root-type>(<subtype-name-2>) get owns(surname) get cardinality: @card(0..1)
    Then <root-type>(<subtype-name-2>) get constraints for owned attribute(surname) contain: @card(0..1)
    Then <root-type>(<subtype-name-2>) get constraints for owned attribute(surname) contain: @card(0..2)
    Then <root-type>(<subtype-name-2>) get constraints for owned attribute(surname) contain: @card(1..2)
    When <root-type>(<subtype-name>) get owns(name) unset annotation: @card
    Then <root-type>(<subtype-name-2>) get owns(first-name) get cardinality: @card(0..1)
    Then <root-type>(<subtype-name-2>) get constraints for owned attribute(first-name) do not contain: @card(1..2)
    Then <root-type>(<subtype-name-2>) get owns(surname) get cardinality: @card(0..1)
    Then <root-type>(<subtype-name-2>) get constraints for owned attribute(surname) do not contain: @card(1..2)
    Then transaction commits
    Examples:
      | root-type | supertype-name | subtype-name | subtype-name-2 |
      | entity    | person         | customer     | subscriber     |
      | relation  | description    | registration | profile        |

########################
# @distinct
########################

  Scenario Outline: Unordered owns for have @distinct constraint by default and cannot change it
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When create attribute type: custom-attribute-ordered
    When attribute(custom-attribute-ordered) set value type: <value-type>
    When <root-type>(<type-name>) set owns: custom-attribute
    Then <root-type>(<type-name>) get owns(custom-attribute) get declared annotations do not contain: @distinct
    Then <root-type>(<type-name>) get owns(custom-attribute) get constraints contain: @distinct
    Then <root-type>(<type-name>) get constraints for owned attribute(custom-attribute) contain: @distinct
    When <root-type>(<type-name>) get owns(custom-attribute) unset annotation: @distinct
    Then <root-type>(<type-name>) get owns(custom-attribute) get declared annotations do not contain: @distinct
    Then <root-type>(<type-name>) get owns(custom-attribute) get constraints contain: @distinct
    Then <root-type>(<type-name>) get constraints for owned attribute(custom-attribute) contain: @distinct
    Then <root-type>(<type-name>) get owns(custom-attribute) set annotation: @distinct; fails
    Then <root-type>(<type-name>) get owns(custom-attribute) get declared annotations do not contain: @distinct
    Then <root-type>(<type-name>) get owns(custom-attribute) get constraints contain: @distinct
    Then <root-type>(<type-name>) get constraints for owned attribute(custom-attribute) contain: @distinct
    When <root-type>(<type-name>) set owns: custom-attribute-ordered[]
    Then <root-type>(<type-name>) get owns(custom-attribute-ordered) get declared annotations do not contain: @distinct
    Then <root-type>(<type-name>) get owns(custom-attribute-ordered) get constraints do not contain: @distinct
    Then <root-type>(<type-name>) get constraints for owned attribute(custom-attribute-ordered) do not contain: @distinct
    When <root-type>(<type-name>) get owns(custom-attribute-ordered) unset annotation: @distinct
    Then <root-type>(<type-name>) get owns(custom-attribute-ordered) get declared annotations do not contain: @distinct
    Then <root-type>(<type-name>) get owns(custom-attribute-ordered) get constraints do not contain: @distinct
    Then <root-type>(<type-name>) get constraints for owned attribute(custom-attribute-ordered) do not contain: @distinct
    When transaction commits
    When connection open read transaction for database: typedb
    Then <root-type>(<type-name>) get owns(custom-attribute) get declared annotations do not contain: @distinct
    Then <root-type>(<type-name>) get owns(custom-attribute) get constraints contain: @distinct
    Then <root-type>(<type-name>) get constraints for owned attribute(custom-attribute) contain: @distinct
    Then <root-type>(<type-name>) get owns(custom-attribute-ordered) get declared annotations do not contain: @distinct
    Then <root-type>(<type-name>) get owns(custom-attribute-ordered) get constraints do not contain: @distinct
    Then <root-type>(<type-name>) get constraints for owned attribute(custom-attribute-ordered) do not contain: @distinct
    Examples:
      | root-type | type-name   | value-type |
      | entity    | person      | integer    |
      | relation  | description | string     |

  Scenario Outline: Ordered owns for <root-type> can set @distinct annotation for <value-type> value type and unset it
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When <root-type>(<type-name>) set owns: custom-attribute
    When <root-type>(<type-name>) get owns(custom-attribute) set ordering: ordered
    When <root-type>(<type-name>) get owns(custom-attribute) set annotation: @distinct
    Then <root-type>(<type-name>) get owns(custom-attribute) get constraints contain: @distinct
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<type-name>) get owns(custom-attribute) get constraints contain: @distinct
    When <root-type>(<type-name>) get owns(custom-attribute) unset annotation: @distinct
    Then <root-type>(<type-name>) get owns(custom-attribute) get constraints do not contain: @distinct
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<type-name>) get owns(custom-attribute) get constraints do not contain: @distinct
    When <root-type>(<type-name>) get owns(custom-attribute) set annotation: @distinct
    Then <root-type>(<type-name>) get owns(custom-attribute) get constraints contain: @distinct
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<type-name>) get owns(custom-attribute) get constraints contain: @distinct
    When <root-type>(<type-name>) unset owns: custom-attribute
    Then <root-type>(<type-name>) get owns is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then <root-type>(<type-name>) get owns is empty
    Examples:
      | root-type | type-name   | value-type            |
      | entity    | person      | integer               |
      | entity    | person      | string                |
      | entity    | person      | boolean               |
      | entity    | person      | double                |
      | entity    | person      | decimal               |
      | entity    | person      | date                  |
      | entity    | person      | datetime              |
      | entity    | person      | datetime-tz           |
      | entity    | person      | duration              |
      | entity    | person      | struct(custom-struct) |
      | relation  | description | integer               |
      | relation  | description | string                |
      | relation  | description | boolean               |
      | relation  | description | double                |
      | relation  | description | decimal               |
      | relation  | description | date                  |
      | relation  | description | datetime              |
      | relation  | description | datetime-tz           |
      | relation  | description | duration              |
      | relation  | description | struct(custom-struct) |

  Scenario: Owns can have @distinct annotation for none value type
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set annotation: @abstract
    When attribute(custom-attribute) get value type is none
    When entity(person) set owns: custom-attribute
    Then entity(person) get owns(custom-attribute) set ordering: ordered
    When entity(person) get owns(custom-attribute) set annotation: @distinct
    Then entity(person) get owns(custom-attribute) get constraints contain: @distinct
    Then attribute(custom-attribute) get value type is none
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get constraints contain: @distinct
    Then attribute(custom-attribute) get value type is none

  Scenario Outline: Owns can reset @distinct annotations
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When entity(person) set owns: custom-attribute
    When entity(person) get owns(custom-attribute) set ordering: ordered
    When entity(person) get owns(custom-attribute) set annotation: @distinct
    Then entity(person) get owns(custom-attribute) get constraints contain: @distinct
    When entity(person) get owns(custom-attribute) set annotation: @distinct
    Then entity(person) get owns(custom-attribute) get constraints contain: @distinct
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get constraints contain: @distinct
    When entity(person) get owns(custom-attribute) set annotation: @distinct
    Then entity(person) get owns(custom-attribute) get constraints contain: @distinct
    Examples:
      | value-type |
      | integer    |
      | decimal    |

  Scenario Outline: <root-type> types can redeclare owns as owns with @distinct
    When create attribute type: name
    When attribute(name) set value type: <value-type>
    When create attribute type: email
    When attribute(email) set value type: <value-type>
    When create attribute type: address
    When attribute(address) set value type: <value-type>
    When <root-type>(<type-name>) set owns: name
    When <root-type>(<type-name>) set owns: email
    When <root-type>(<type-name>) get owns(email) set ordering: ordered
    When <root-type>(<type-name>) set owns: address
    When <root-type>(<type-name>) get owns(address) set ordering: ordered
    When <root-type>(<type-name>) set owns: name
    Then <root-type>(<type-name>) get owns(name) get ordering: unordered
    Then <root-type>(<type-name>) get owns(name) set annotation: @distinct; fails
    Then <root-type>(<type-name>) get owns(name) get constraints contain: @distinct
    When <root-type>(<type-name>) get owns(name) set ordering: ordered
    Then <root-type>(<type-name>) get owns(name) get constraints do not contain: @distinct
    When <root-type>(<type-name>) get owns(name) set annotation: @distinct
    Then <root-type>(<type-name>) get owns(name) get constraints contain: @distinct
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<type-name>) set owns: email; fails
    When <root-type>(<type-name>) unset owns: email
    When <root-type>(<type-name>) set owns: email
    Then <root-type>(<type-name>) get owns(email) get ordering: unordered
    Then <root-type>(<type-name>) get owns(email) get constraints contain: @distinct
    Then <root-type>(<type-name>) get owns(email) set annotation: @distinct; fails
    When <root-type>(<type-name>) get owns(email) set ordering: ordered
    Then <root-type>(<type-name>) get owns(email) get constraints do not contain: @distinct
    When <root-type>(<type-name>) get owns(email) set annotation: @distinct
    Then <root-type>(<type-name>) get owns(email) get constraints contain: @distinct
    Then <root-type>(<type-name>) get owns(address) get constraints do not contain: @distinct
    When <root-type>(<type-name>) get owns(address) set annotation: @distinct
    Then <root-type>(<type-name>) get owns(address) get constraints contain: @distinct
    When transaction commits
    When connection open read transaction for database: typedb
    Then <root-type>(<type-name>) get owns(name) get constraints contain: @distinct
    Then <root-type>(<type-name>) get owns(email) get constraints contain: @distinct
    Then <root-type>(<type-name>) get owns(address) get constraints contain: @distinct
    Then <root-type>(<type-name>) get owns(name) get ordering: ordered
    Then <root-type>(<type-name>) get owns(email) get ordering: ordered
    Then <root-type>(<type-name>) get owns(address) get ordering: ordered
    Examples:
      | root-type | type-name   | value-type |
      | entity    | person      | string     |
      | entity    | person      | integer    |
      | relation  | description | datetime   |
      | relation  | description | duration   |

  Scenario Outline: <root-type> types can unset not set @distinct of ownership of <value-type> value type
    When create attribute type: username
    When attribute(username) set value type: <value-type>
    When create attribute type: reference
    When attribute(reference) set value type: <value-type>
    When <root-type>(<type-name>) set owns: username
    When <root-type>(<type-name>) get owns(username) set ordering: ordered
    When <root-type>(<type-name>) get owns(username) set annotation: @distinct
    Then <root-type>(<type-name>) get owns(username) get constraints contain: @distinct
    When <root-type>(<type-name>) set owns: reference
    When <root-type>(<type-name>) get owns(reference) set ordering: ordered
    Then <root-type>(<type-name>) get owns(reference) get constraints do not contain: @distinct
    When <root-type>(<type-name>) get owns(reference) unset annotation: @distinct
    Then <root-type>(<type-name>) get owns(reference) get constraints do not contain: @distinct
    When <root-type>(<type-name>) get owns(reference) set ordering: unordered
    When <root-type>(<type-name>) get owns(reference) unset annotation: @distinct
    Then <root-type>(<type-name>) get owns(reference) get constraints contain: @distinct
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<type-name>) get owns(username) get constraints contain: @distinct
    Then <root-type>(<type-name>) get owns(reference) get constraints contain: @distinct
    Then <root-type>(<type-name>) get owns(username) unset annotation: @distinct
    Then <root-type>(<type-name>) get owns(reference) unset annotation: @distinct
    Then <root-type>(<type-name>) get owns(username) get constraints do not contain: @distinct
    Then <root-type>(<type-name>) get owns(reference) get constraints contain: @distinct
    When transaction commits
    When connection open read transaction for database: typedb
    Then <root-type>(<type-name>) get owns(username) get constraints do not contain: @distinct
    Then <root-type>(<type-name>) get owns(reference) get constraints contain: @distinct
    Examples:
      | root-type | type-name   | value-type |
      | entity    | person      | string     |
      | entity    | person      | integer    |
      | relation  | description | datetime   |
      | relation  | description | duration   |

  Scenario Outline: <root-type> types can unset @distinct of inherited ownership
    When create attribute type: username
    When attribute(username) set value type: string
    When <root-type>(<supertype-name>) set owns: username
    When <root-type>(<supertype-name>) get owns(username) set ordering: ordered
    When <root-type>(<supertype-name>) get owns(username) set annotation: @distinct
    Then <root-type>(<supertype-name>) get owns(username) get constraints contain: @distinct
    Then <root-type>(<subtype-name>) get owns(username) get constraints contain: @distinct
    When <root-type>(<subtype-name>) get owns(username) unset annotation: @distinct
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<subtype-name>) get owns(username) get constraints do not contain: @distinct
    When <root-type>(<supertype-name>) get owns(username) unset annotation: @distinct
    Then <root-type>(<subtype-name>) get owns(username) get constraints do not contain: @distinct
    Examples:
      | root-type | supertype-name | subtype-name |
      | entity    | person         | customer     |
      | relation  | description    | registration |

  Scenario Outline: <root-type> types cannot unset @distinct of specialised ownership
    When create attribute type: username
    When attribute(username) set annotation: @abstract
    When attribute(username) set value type: string
    When create attribute type: subusername
    When attribute(subusername) set supertype: username
    When <root-type>(<supertype-name>) set owns: username
    When <root-type>(<supertype-name>) get owns(username) set ordering: ordered
    When <root-type>(<supertype-name>) get owns(username) set annotation: @distinct
    Then <root-type>(<supertype-name>) get owns(username) get constraints contain: @distinct
    When <root-type>(<subtype-name>) set owns: subusername[]
    Then <root-type>(<subtype-name>) get constraints for owned attribute(subusername) contain: @distinct
    Then <root-type>(<subtype-name>) get owns(subusername) get constraints do not contain: @distinct
    Then <root-type>(<subtype-name>) get owns(subusername) get declared annotations do not contain: @distinct
    When <root-type>(<subtype-name>) get owns(subusername) unset annotation: @distinct
    Then <root-type>(<subtype-name>) get constraints for owned attribute(subusername) contain: @distinct
    Then <root-type>(<subtype-name>) get owns(subusername) get constraints do not contain: @distinct
    Then <root-type>(<subtype-name>) get owns(subusername) get declared annotations do not contain: @distinct
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<subtype-name>) get constraints for owned attribute(subusername) contain: @distinct
    Then <root-type>(<subtype-name>) get owns(subusername) get constraints do not contain: @distinct
    Then <root-type>(<subtype-name>) get owns(subusername) get declared annotations do not contain: @distinct
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
    Then entity(person) get owns(custom-attribute) get constraints contain: @regex(<arg>)
    When entity(person) set owns: custom-attribute-2
    When entity(person) get owns(custom-attribute-2) set ordering: ordered
    When entity(person) get owns(custom-attribute-2) set annotation: @regex(<arg>)
    Then entity(person) get owns(custom-attribute-2) get constraints contain: @regex(<arg>)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get constraints contain: @regex(<arg>)
    When entity(person) get owns(custom-attribute) unset annotation: @regex
    Then entity(person) get owns(custom-attribute) get constraint categories do not contain: @regex
    Then entity(person) get owns(custom-attribute-2) get constraints contain: @regex(<arg>)
    When entity(person) get owns(custom-attribute-2) unset annotation: @regex
    Then entity(person) get owns(custom-attribute-2) get constraint categories do not contain: @regex
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get constraint categories do not contain: @regex
    When entity(person) get owns(custom-attribute) set annotation: @regex(<arg>)
    Then entity(person) get owns(custom-attribute) get constraints contain: @regex(<arg>)
    Then entity(person) get owns(custom-attribute-2) get constraint categories do not contain: @regex
    When entity(person) get owns(custom-attribute-2) set annotation: @regex(<arg>)
    Then entity(person) get owns(custom-attribute-2) get constraints contain: @regex(<arg>)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get constraints contain: @regex(<arg>)
    Then entity(person) get owns(custom-attribute-2) get constraints contain: @regex(<arg>)
    When entity(person) unset owns: custom-attribute
    When entity(person) unset owns: custom-attribute-2
    Then entity(person) get owns is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get owns is empty
    Examples:
      | value-type | arg                     |
      | string     | "value"                 |
      | string     | "123.456"               |
      | string     | "\S+"                   |
      | string     | "\S+@\S+\.\S+"          |
      | string     | "^starts"               |
      | string     | "ends$"                 |
      | string     | "^starts and ends$"     |
      | string     | "^(not)$"               |
      | string     | "2024-06-04T00:00+0100" |

  Scenario: Owns cannot have @regex annotation for none value type
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set annotation: @abstract
    When attribute(custom-attribute) get value type is none
    When entity(person) set owns: custom-attribute
    Then entity(person) get owns(custom-attribute) set annotation: @regex("\S+"); fails
    Then entity(person) get owns(custom-attribute) get constraint categories do not contain: @regex
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get constraint categories do not contain: @regex

  Scenario Outline: Owns cannot have @regex annotation for <value-type> value type
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When entity(person) set owns: custom-attribute
    Then entity(person) get owns(custom-attribute) set annotation: @regex("\S+"); fails
    Then entity(person) get owns(custom-attribute) get constraint categories do not contain: @regex
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get constraint categories do not contain: @regex
    Examples:
      | value-type            |
      | integer               |
      | boolean               |
      | double                |
      | decimal               |
      | date                  |
      | datetime              |
      | datetime-tz           |
      | duration              |
      | struct(custom-struct) |

  Scenario: Owns can set @regex annotation if there is a different @regex annotation on the attribute
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: string
    When attribute(custom-attribute) set annotation: @regex("\S+")
    When transaction commits
    When connection open schema transaction for database: typedb
    When entity(person) set owns: custom-attribute
    When entity(person) get owns(custom-attribute) set annotation: @regex("\S+")
    Then transaction commits; fails
    When connection open schema transaction for database: typedb
    When entity(person) set owns: custom-attribute
    When entity(person) get owns(custom-attribute) set annotation: @regex("\S*")
    Then entity(person) get owns(custom-attribute) get constraints contain: @regex("\S*")
    Then entity(person) get owns(custom-attribute) get constraints do not contain: @regex("\S+")
    Then attribute(custom-attribute) get constraints contain: @regex("\S+")
    Then attribute(custom-attribute) get constraints do not contain: @regex("\S*")
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get constraints contain: @regex("\S*")
    Then entity(person) get owns(custom-attribute) get constraints do not contain: @regex("\S+")
    Then attribute(custom-attribute) get constraints contain: @regex("\S+")
    Then attribute(custom-attribute) get constraints do not contain: @regex("\S*")

  Scenario: Attribute type can have @regex annotation if owns has a different @regex annotation
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: string
    When entity(person) set owns: custom-attribute
    When entity(person) get owns(custom-attribute) set annotation: @regex("\S*")
    Then entity(person) get owns(custom-attribute) get constraints contain: @regex("\S*")
    When transaction commits
    When connection open schema transaction for database: typedb
    When attribute(custom-attribute) set annotation: @regex("\S*")
    Then transaction commits; fails
    When connection open schema transaction for database: typedb
    When attribute(custom-attribute) set annotation: @regex("\S+")
    Then entity(person) get owns(custom-attribute) get constraints contain: @regex("\S*")
    Then entity(person) get owns(custom-attribute) get constraints do not contain: @regex("\S+")
    Then attribute(custom-attribute) get constraints contain: @regex("\S+")
    Then attribute(custom-attribute) get constraints do not contain: @regex("\S*")
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get constraints contain: @regex("\S*")
    Then entity(person) get owns(custom-attribute) get constraints do not contain: @regex("\S+")
    Then attribute(custom-attribute) get constraints contain: @regex("\S+")
    Then attribute(custom-attribute) get constraints do not contain: @regex("\S*")

  Scenario Outline: Owns cannot have @regex annotation of invalid arguments
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: string
    When entity(person) set owns: custom-attribute
    Then entity(person) get owns(custom-attribute) set annotation: @regex(<args>); fails
    Then entity(person) get owns(custom-attribute) get constraint categories do not contain: @regex
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get constraint categories do not contain: @regex
    Examples:
      | args |
      | ""   |

  Scenario Outline: Owns can reset @regex annotation of the same argument
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: string
    When entity(person) set owns: custom-attribute
    When entity(person) get owns(custom-attribute) set ordering: ordered
    When entity(person) get owns(custom-attribute) set annotation: @regex(<args>)
    Then entity(person) get owns(custom-attribute) get constraints contain: @regex(<args>)
    When entity(person) get owns(custom-attribute) set annotation: @regex(<args>)
    Then entity(person) get owns(custom-attribute) get constraints contain: @regex(<args>)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get constraints contain: @regex(<args>)
    When entity(person) get owns(custom-attribute) set annotation: @regex(<args>)
    Then entity(person) get owns(custom-attribute) get constraints contain: @regex(<args>)
    Examples:
      | args                                 |
      | "\S+"                                |
      | "another regex with specific string" |

  Scenario Outline: Owns can reset @regex annotation
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: string
    When entity(person) set owns: custom-attribute
    When entity(person) get owns(custom-attribute) set annotation: @regex(<init-args>)
    Then entity(person) get owns(custom-attribute) get constraints contain: @regex(<init-args>)
    Then entity(person) get owns(custom-attribute) get constraints do not contain: @regex(<reset-args>)
    When entity(person) get owns(custom-attribute) set annotation: @regex(<init-args>)
    Then entity(person) get owns(custom-attribute) get constraints contain: @regex(<init-args>)
    Then entity(person) get owns(custom-attribute) get constraints do not contain: @regex(<reset-args>)
    When entity(person) get owns(custom-attribute) set annotation: @regex(<reset-args>)
    Then entity(person) get owns(custom-attribute) get constraints contain: @regex(<reset-args>)
    Then entity(person) get owns(custom-attribute) get constraints do not contain: @regex(<init-args>)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get constraints contain: @regex(<reset-args>)
    Then entity(person) get owns(custom-attribute) get constraints do not contain: @regex(<init-args>)
    When entity(person) get owns(custom-attribute) set annotation: @regex(<init-args>)
    Then entity(person) get owns(custom-attribute) get constraints contain: @regex(<init-args>)
    Then entity(person) get owns(custom-attribute) get constraints do not contain: @regex(<reset-args>)
    Examples:
      | init-args | reset-args      |
      | "\S+"     | "\S"            |
      | "\S+"     | "S+"            |
      | "\S+"     | ".*"            |
      | "\S+"     | "s"             |
      | "\S+"     | " some string " |

  Scenario: Owns can specialise inherited @regex annotation with any value
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: string
    When attribute(custom-attribute) set annotation: @abstract
    When entity(person) set owns: custom-attribute
    When entity(person) get owns(custom-attribute) set annotation: @regex("\S+")
    Then entity(person) get owns(custom-attribute) get constraints contain: @regex("\S+")
    Then entity(customer) get owns(custom-attribute) get constraints contain: @regex("\S+")
    When create attribute type: custom-attribute-2
    When attribute(custom-attribute-2) set supertype: custom-attribute
    When entity(customer) set owns: custom-attribute-2
    Then entity(customer) get owns(custom-attribute-2) get constraint categories do not contain: @regex
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get constraints contain: @regex("\S+")
    Then entity(customer) get owns(custom-attribute) get constraints contain: @regex("\S+")
    Then entity(customer) get owns(custom-attribute-2) get constraint categories do not contain: @regex
    When entity(customer) get owns(custom-attribute-2) set annotation: @regex("test")
    Then entity(person) get owns(custom-attribute) get declared annotations do not contain: @regex("test")
    Then entity(person) get owns(custom-attribute) get declared annotations contain: @regex("\S+")
    Then entity(person) get owns(custom-attribute) get constraints do not contain: @regex("test")
    Then entity(person) get owns(custom-attribute) get constraints contain: @regex("\S+")
    Then entity(person) get constraints for owned attribute(custom-attribute) do not contain: @regex("test")
    Then entity(person) get constraints for owned attribute(custom-attribute) contain: @regex("\S+")
    Then entity(customer) get owns(custom-attribute-2) get declared annotations contain: @regex("test")
    Then entity(customer) get owns(custom-attribute-2) get declared annotations do not contain: @regex("\S+")
    Then entity(customer) get owns(custom-attribute-2) get constraints contain: @regex("test")
    Then entity(customer) get owns(custom-attribute-2) get constraints do not contain: @regex("\S+")
    Then entity(customer) get constraints for owned attribute(custom-attribute-2) contain: @regex("test")
    Then entity(customer) get constraints for owned attribute(custom-attribute-2) contain: @regex("\S+")
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get declared annotations do not contain: @regex("test")
    Then entity(person) get owns(custom-attribute) get declared annotations contain: @regex("\S+")
    Then entity(person) get owns(custom-attribute) get constraints do not contain: @regex("test")
    Then entity(person) get owns(custom-attribute) get constraints contain: @regex("\S+")
    Then entity(person) get constraints for owned attribute(custom-attribute) do not contain: @regex("test")
    Then entity(person) get constraints for owned attribute(custom-attribute) contain: @regex("\S+")
    Then entity(customer) get owns(custom-attribute-2) get declared annotations contain: @regex("test")
    Then entity(customer) get owns(custom-attribute-2) get declared annotations do not contain: @regex("\S+")
    Then entity(customer) get owns(custom-attribute-2) get constraints contain: @regex("test")
    Then entity(customer) get owns(custom-attribute-2) get constraints do not contain: @regex("\S+")
    Then entity(customer) get constraints for owned attribute(custom-attribute-2) contain: @regex("test")
    Then entity(customer) get constraints for owned attribute(custom-attribute-2) contain: @regex("\S+")

  Scenario: Attribute type cannot unset value type if it has owns with @regex annotation
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set annotation: @abstract
    When attribute(custom-attribute) set value type: string
    When entity(person) set owns: custom-attribute
    When entity(person) get owns(custom-attribute) set annotation: @regex("\S+")
    Then attribute(custom-attribute) unset value type; fails
    Then attribute(custom-attribute) set value type: integer; fails
    Then attribute(custom-attribute) set value type: boolean; fails
    Then attribute(custom-attribute) set value type: double; fails
    Then attribute(custom-attribute) set value type: decimal; fails
    Then attribute(custom-attribute) set value type: date; fails
    Then attribute(custom-attribute) set value type: datetime; fails
    Then attribute(custom-attribute) set value type: datetime-tz; fails
    Then attribute(custom-attribute) set value type: duration; fails
    Then attribute(custom-attribute) set value type: struct(custom-struct); fails
    When attribute(custom-attribute) set value type: string
    When entity(person) get owns(custom-attribute) unset annotation: @regex
    When attribute(custom-attribute) unset value type
    When attribute(custom-attribute) get value type is none
    Then entity(person) get owns(custom-attribute) set annotation: @regex("\S+"); fails
    When attribute(custom-attribute) set value type: string
    When entity(person) get owns(custom-attribute) set annotation: @regex("\S+")
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get owns(custom-attribute) get constraints contain: @regex("\S+")
    Then attribute(custom-attribute) unset value type; fails
    Then attribute(custom-attribute) set value type: integer; fails
    Then attribute(custom-attribute) set value type: boolean; fails
    Then attribute(custom-attribute) set value type: double; fails
    Then attribute(custom-attribute) set value type: decimal; fails
    Then attribute(custom-attribute) set value type: date; fails
    Then attribute(custom-attribute) set value type: datetime; fails
    Then attribute(custom-attribute) set value type: datetime-tz; fails
    Then attribute(custom-attribute) set value type: duration; fails
    Then attribute(custom-attribute) set value type: struct(custom-struct); fails
    When attribute(custom-attribute) set value type: string
    Then attribute(custom-attribute) get value type: string
    Then transaction commits

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
    Then relation(description) get owns(custom-attribute) get declared annotations contain: @<annotation-1>
    Then relation(description) get owns(custom-attribute) get declared annotations contain: @<annotation-2>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(description) get owns(custom-attribute) get declared annotations contain: @<annotation-1>
    Then relation(description) get owns(custom-attribute) get declared annotations contain: @<annotation-2>
    When relation(description) get owns(custom-attribute) unset annotation: @<annotation-category-1>
    Then relation(description) get owns(custom-attribute) get declared annotations do not contain: @<annotation-1>
    Then relation(description) get owns(custom-attribute) get declared annotations contain: @<annotation-2>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(description) get owns(custom-attribute) get declared annotations do not contain: @<annotation-1>
    Then relation(description) get owns(custom-attribute) get declared annotations contain: @<annotation-2>
    When relation(description) get owns(custom-attribute) set annotation: @<annotation-1>
    When relation(description) get owns(custom-attribute) unset annotation: @<annotation-category-2>
    Then relation(description) get owns(custom-attribute) get declared annotations do not contain: @<annotation-2>
    Then relation(description) get owns(custom-attribute) get declared annotations contain: @<annotation-1>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(description) get owns(custom-attribute) get declared annotations do not contain: @<annotation-2>
    Then relation(description) get owns(custom-attribute) get declared annotations contain: @<annotation-1>
    When relation(description) get owns(custom-attribute) unset annotation: @<annotation-category-1>
    Then relation(description) get owns(custom-attribute) get declared annotations do not contain: @<annotation-1>
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(description) get owns(custom-attribute) get declared annotations do not contain: @<annotation-1>
    Then relation(description) get owns(custom-attribute) get declared annotations do not contain: @<annotation-2>
    Examples:
    # TODO: Move to "cannot" test if something is wrong here.
      | annotation-1                  | annotation-2          | annotation-category-1 | annotation-category-2 | value-type  |
      | key                           | values(1, 2)          | key                   | values                | decimal     |
      | key                           | range(1..2)           | key                   | range                 | decimal     |
      | key                           | regex("s")            | key                   | regex                 | string      |
      | key                           | regex("s")            | key                   | regex                 | string      |
      # TODO: subkey is not implemented
#      | key                               | subkey(L)          | key                   | subkey                | integer        |
#      | subkey(L)                         | unique             | subkey                | unique                | duration    |
#      | subkey(L)                         | values(1, 2)       | subkey                | values                | integer        |
#      | subkey(L)                         | range(false..true) | subkey                | range                 | boolean     |
#      | subkey(L)                         | card(0..1)         | subkey                | card                  | integer        |
#      | subkey(L)                         | regex("s")         | subkey                | regex                 | string      |
      | unique                        | values(1, 2)          | unique                | values                | integer     |
      | unique                        | range(1.0dec..2.0dec) | unique                | range                 | decimal     |
      | unique                        | card(0..1)            | unique                | card                  | decimal     |
      | unique                        | regex("s")            | unique                | regex                 | string      |
      | values(2024-05-06T00:00+0100) | card(0..1)            | values                | card                  | datetime-tz |
      | range(2020-05-05..2025-05-05) | card(0..1)            | range                 | card                  | datetime    |
      | card(0..1)                    | regex("s")            | card                  | regex                 | string      |
      | values(1.0dec, 2.0dec)        | range(1.0dec..2.0dec) | values                | range                 | decimal     |
      | values("str")                 | regex("s")            | values                | regex                 | string      |
      | range("1".."2")               | regex("s")            | range                 | regex                 | string      |

  Scenario Outline: Ordered ownership can set @<annotation-1> and @<annotation-2> together and unset it for <value-type> value type
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When relation(description) set owns: custom-attribute
    When relation(description) get owns(custom-attribute) set ordering: ordered
    When relation(description) get owns(custom-attribute) set annotation: @<annotation-1>
    When relation(description) get owns(custom-attribute) set annotation: @<annotation-2>
    Then relation(description) get owns(custom-attribute) get declared annotations contain: @<annotation-1>
    Then relation(description) get owns(custom-attribute) get declared annotations contain: @<annotation-2>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(description) get owns(custom-attribute) get declared annotations contain: @<annotation-1>
    Then relation(description) get owns(custom-attribute) get declared annotations contain: @<annotation-2>
    When relation(description) get owns(custom-attribute) unset annotation: @<annotation-category-1>
    Then relation(description) get owns(custom-attribute) get declared annotations do not contain: @<annotation-1>
    Then relation(description) get owns(custom-attribute) get declared annotations contain: @<annotation-2>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(description) get owns(custom-attribute) get declared annotations do not contain: @<annotation-1>
    Then relation(description) get owns(custom-attribute) get declared annotations contain: @<annotation-2>
    When relation(description) get owns(custom-attribute) set annotation: @<annotation-1>
    When relation(description) get owns(custom-attribute) unset annotation: @<annotation-category-2>
    Then relation(description) get owns(custom-attribute) get declared annotations do not contain: @<annotation-2>
    Then relation(description) get owns(custom-attribute) get declared annotations contain: @<annotation-1>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(description) get owns(custom-attribute) get declared annotations do not contain: @<annotation-2>
    Then relation(description) get owns(custom-attribute) get declared annotations contain: @<annotation-1>
    When relation(description) get owns(custom-attribute) unset annotation: @<annotation-category-1>
    Then relation(description) get owns(custom-attribute) get declared annotations do not contain: @<annotation-1>
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(description) get owns(custom-attribute) get declared annotations do not contain: @<annotation-1>
    Then relation(description) get owns(custom-attribute) get declared annotations do not contain: @<annotation-2>
    Examples:
    # TODO: Move to "cannot" test if something is wrong here.
      | annotation-1                  | annotation-2 | annotation-category-1 | annotation-category-2 | value-type  |
      | unique                        | values(1, 2) | unique                | values                | integer     |
      | unique                        | range(1..2)  | unique                | range                 | decimal     |
      | unique                        | card(0..1)   | unique                | card                  | integer     |
      | unique                        | regex("s")   | unique                | regex                 | string      |
      | unique                        | distinct     | unique                | distinct              | string      |
      | values(2024-05-06T00:00+0100) | card(0..1)   | values                | card                  | datetime-tz |
      | values(1, 2)                  | distinct     | values                | distinct              | integer     |
      | values(1, 2)                  | range(1..2)  | values                | range                 | decimal     |
      | values("str")                 | regex("s")   | values                | regex                 | string      |
      | range(2020-05-05..2025-05-05) | card(0..1)   | range                 | card                  | datetime    |
      | range(2020-05-05..2025-05-05) | distinct     | range                 | distinct              | date        |
      | card(0..1)                    | regex("s")   | card                  | regex                 | string      |
      | card(0..1)                    | distinct     | card                  | distinct              | integer     |
      | regex("s")                    | distinct     | regex                 | distinct              | string      |
      | range("1".."2")               | regex("s")   | range                 | regex                 | string      |

  Scenario Outline: Owns cannot set @<annotation-1> and @<annotation-2> together for scalar <value-type>
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When transaction commits
    When connection open schema transaction for database: typedb
    When relation(description) set owns: custom-attribute
    When relation(description) get owns(custom-attribute) set annotation: @<annotation-1>
    Then relation(description) get owns(custom-attribute) set annotation: @<annotation-2>; fails
    When transaction closes
    When connection open schema transaction for database: typedb
    When relation(description) set owns: custom-attribute
    When relation(description) get owns(custom-attribute) set annotation: @<annotation-2>
    Then relation(description) get owns(custom-attribute) set annotation: @<annotation-1>; fails
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(description) get owns(custom-attribute) get declared annotations contain: @<annotation-2>
    Then relation(description) get owns(custom-attribute) get declared annotations do not contain: @<annotation-1>
    Examples:
      | annotation-1 | annotation-2 | value-type |
      | key          | unique       | integer    |
      | key          | card(0..1)   | integer    |
      | key          | card(0..)    | integer    |
      | key          | card(1..1)   | integer    |
      | key          | card(2..5)   | integer    |

  Scenario Outline: Ordered ownership cannot set @<annotation-1> and @<annotation-2> together for <value-type> value type
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set value type: <value-type>
    When transaction commits
    When connection open schema transaction for database: typedb
    When relation(description) set owns: custom-attribute
    When relation(description) get owns(custom-attribute) set ordering: ordered
    When relation(description) get owns(custom-attribute) set annotation: @<annotation-1>
    Then relation(description) get owns(custom-attribute) set annotation: @<annotation-2>; fails
    When transaction closes
    When connection open schema transaction for database: typedb
    When relation(description) set owns: custom-attribute
    When relation(description) get owns(custom-attribute) set ordering: ordered
    When relation(description) get owns(custom-attribute) set annotation: @<annotation-2>
    Then relation(description) get owns(custom-attribute) set annotation: @<annotation-1>; fails
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(description) get owns(custom-attribute) get declared annotations contain: @<annotation-2>
    Then relation(description) get owns(custom-attribute) get declared annotations do not contain: @<annotation-1>
    Examples:
      | annotation-1 | annotation-2 | value-type |
      | key          | unique       | integer    |
      | key          | card(0..1)   | integer    |
      | key          | card(0..)    | integer    |
      | key          | card(1..1)   | integer    |
      | key          | card(2..5)   | integer    |

  Scenario Outline: Annotation @key can be set if type has inherited cardinality that can be narrowed
    When create attribute type: name
    When attribute(name) set value type: string
    When attribute(name) set annotation: @abstract
    When create attribute type: surname
    When attribute(surname) set supertype: name
    When create attribute type: non-card-name
    When attribute(non-card-name) set supertype: name
    When attribute(non-card-name) set annotation: @abstract
    When create attribute type: third-name
    When attribute(third-name) set supertype: non-card-name
    When entity(person) set owns: name
    When entity(person) get owns(name) set annotation: @card(<card-args>)
    When entity(person) set owns: non-card-name
    When entity(customer) set supertype: person
    When entity(customer) set owns: surname
    When entity(subscriber) set supertype: person
    When entity(subscriber) set owns: surname
    When entity(subscriber) get owns(surname) set annotation: @key
    Then entity(subscriber) get owns(surname) get cardinality: @card(1..1)
    When entity(subscriber) set owns: third-name
    When entity(person) get owns(name) set annotation: @card(<card-args>)
    Then entity(person) get owns(name) get constraints contain: @card(<card-args>)
    Then entity(person) get owns(name) get declared annotations contain: @card(<card-args>)
    Then entity(person) get owns(name) get cardinality: @card(<card-args>)
    Then entity(person) get owns(name) is key: false
    Then entity(customer) get owns(surname) get declared annotations do not contain: @card(<card-args>)
    Then entity(customer) get owns(surname) get constraints do not contain: @card(<card-args>)
    Then entity(customer) get constraints for owned attribute(surname) contain: @card(<card-args>)
    Then entity(customer) get owns(surname) get cardinality: @card(0..1)
    Then entity(customer) get owns(surname) is key: false
    Then entity(subscriber) get owns(surname) is key: true
    Then entity(subscriber) get constraints for owned attribute(surname) contain: @card(1..1)
    Then entity(subscriber) get owns(surname) get cardinality: @card(1..1)
    Then entity(person) get owns(name) set annotation: @key; fails
    When entity(customer) get owns(surname) set annotation: @key
    Then entity(customer) get owns(surname) is key: true
    Then entity(customer) get owns(surname) get cardinality: @card(1..1)
    Then entity(customer) get constraints for owned attribute(surname) contain: @card(1..1)
    When entity(subscriber) get owns(third-name) set annotation: @key
    Then entity(subscriber) get owns(third-name) is key: true
    Then entity(subscriber) get owns(third-name) get cardinality: @card(1..1)
    Then entity(subscriber) get constraints for owned attribute(third-name) contain: @card(1..1)
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get owns(name) is key: false
    Then entity(person) get owns(name) get constraints contain: @card(<card-args>)
    Then entity(person) get constraints for owned attribute(name) contain: @card(<card-args>)
    Then entity(person) get owns(name) get cardinality: @card(<card-args>)
    Then entity(customer) get owns(surname) is key: true
    Then entity(customer) get owns(surname) get cardinality: @card(1..1)
    Then entity(customer) get constraints for owned attribute(surname) contain: @card(1..1)
    Then entity(customer) get constraints for owned attribute(surname) contain: @card(<card-args>)
    Then entity(subscriber) get owns(surname) is key: true
    Then entity(subscriber) get owns(surname) get cardinality: @card(1..1)
    Then entity(subscriber) get constraints for owned attribute(surname) contain: @card(1..1)
    Then entity(subscriber) get constraints for owned attribute(surname) contain: @card(<card-args>)
    Then entity(subscriber) get owns(third-name) is key: true
    Then entity(subscriber) get owns(third-name) get cardinality: @card(1..1)
    Then entity(subscriber) get constraints for owned attribute(third-name) contain: @card(1..1)
    Then entity(subscriber) get constraints for owned attribute(third-name) contain: @card(<card-args>)
    Examples:
      | card-args |
      | 0..2      |
      | 0..       |

    # TODO: We (temporarily) don't revalidate cardinality narrowing in schema!
#  Scenario: Cannot set multiple @key annotations to owns that specialise a single owns with too low cardinality
#    When create attribute type: name
#    When attribute(name) set value type: string
#    When attribute(name) set annotation: @abstract
#    When create attribute type: surname
#    When attribute(surname) set supertype: name
#    When create attribute type: non-card-name
#    When attribute(non-card-name) set supertype: name
#    When attribute(non-card-name) set annotation: @abstract
#    When create attribute type: third-name
#    When attribute(third-name) set supertype: non-card-name
#    When entity(person) set owns: name
#    When entity(person) get owns(name) set annotation: @card(0..1)
#    When entity(person) set owns: non-card-name
#    When entity(customer) set supertype: person
#    When entity(customer) set owns: surname
#    When entity(customer) get owns(surname) set specialise: name
#    When entity(subscriber) set supertype: person
#    When entity(subscriber) set owns: surname
#    When entity(subscriber) get owns(surname) set annotation: @key
#    Then entity(subscriber) get owns(surname) get cardinality: @card(1..1)
#    When entity(subscriber) set owns: third-name
#    When entity(subscriber) get owns(third-name) set specialise: name
#    When entity(person) get owns(name) set annotation: @card(0..1)
#    Then entity(person) get owns(name) get constraints contain: @card(0..1)
#    Then entity(person) get owns(name) get declared annotations contain: @card(0..1)
#    Then entity(person) get owns(name) get cardinality: @card(0..1)
#    Then entity(person) get owns(name) is key: false
#    Then entity(customer) get owns(surname) get constraints contain: @card(0..1)
#    Then entity(customer) get owns(surname) get declared annotations do not contain: @card(0..1)
#    Then entity(customer) get owns(surname) get cardinality: @card(0..1)
#    Then entity(customer) get owns(surname) is key: false
#    Then entity(subscriber) get owns(surname) get constraints do not contain: @card(0..1)
#    Then entity(subscriber) get owns(surname) is key: true
#    Then entity(subscriber) get owns(surname) get cardinality: @card(1..1)
#    Then entity(person) get owns(name) set annotation: @key; fails
#    When entity(customer) get owns(surname) set annotation: @key
#    Then entity(customer) get owns(surname) is key: true
#    Then entity(customer) get owns(surname) get cardinality: @card(1..1)
#    When entity(subscriber) get owns(surname) set specialise: name
#    Then entity(subscriber) get owns(third-name) set annotation: @key; fails

    # TODO: We (temporarily) don't revalidate cardinality narrowing in schema!
#  Scenario Outline: Annotation @key cannot be set if type has not suitable cardinality
#    When create attribute type: name
#    When attribute(name) set value type: string
#    When attribute(name) set annotation: @abstract
#    When create attribute type: surname
#    When attribute(surname) set supertype: name
#    When create attribute type: non-card-name
#    When attribute(non-card-name) set supertype: name
#    When attribute(non-card-name) set annotation: @abstract
#    When create attribute type: third-name
#    When attribute(third-name) set supertype: non-card-name
#    When entity(person) set owns: name
#    When entity(person) get owns(name) set annotation: @card(<card-args>)
#    When entity(person) set owns: non-card-name
#    When entity(customer) set supertype: person
#    When entity(customer) set owns: surname
#    When entity(customer) get owns(surname) set specialise: name
#    When entity(subscriber) set supertype: person
#    When entity(subscriber) set owns: surname
#    When entity(subscriber) get owns(surname) set annotation: @key
#    When entity(subscriber) set owns: third-name
#    When entity(subscriber) get owns(third-name) set specialise: name
#    When entity(person) get owns(name) set annotation: @card(<card-args>)
#    Then entity(person) get owns(name) get constraints contain: @card(<card-args>)
#    Then entity(person) get owns(name) get declared annotations contain: @card(<card-args>)
#    Then entity(person) get owns(name) get cardinality: @card(<card-args>)
#    Then entity(person) get owns(name) is key: false
#    Then entity(customer) get owns(surname) get constraints contain: @card(<card-args>)
#    Then entity(customer) get owns(surname) get declared annotations do not contain: @card(<card-args>)
#    Then entity(customer) get owns(surname) get cardinality: @card(<card-args>)
#    Then entity(customer) get owns(surname) is key: false
#    Then entity(subscriber) get owns(surname) get constraints do not contain: @card(<card-args>)
#    Then entity(subscriber) get owns(surname) is key: true
#    Then entity(subscriber) get owns(surname) get cardinality: @card(1..1)
#    Then entity(person) get owns(name) set annotation: @key; fails
#    Then entity(customer) get owns(surname) set annotation: @key; fails
#    Then entity(subscriber) get owns(surname) set specialise: name; fails
#    Then entity(subscriber) get owns(third-name) set annotation: @key; fails
#    When entity(subscriber) get owns(third-name) set specialise: non-card-name
#    When entity(subscriber) get owns(third-name) set annotation: @key
#    Then entity(subscriber) get owns(third-name) is key: true
#    Then entity(subscriber) get owns(third-name) get declared annotations contain: @key
#    Then entity(subscriber) get owns(third-name) get cardinality: @card(1..1)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then entity(person) get owns(name) get constraints contain: @card(<card-args>)
#    Then entity(person) get owns(name) get declared annotations contain: @card(<card-args>)
#    Then entity(person) get owns(name) get cardinality: @card(<card-args>)
#    Then entity(person) get owns(name) is key: false
#    Then entity(customer) get owns(surname) get constraints contain: @card(<card-args>)
#    Then entity(customer) get owns(surname) get declared annotations do not contain: @card(<card-args>)
#    Then entity(customer) get owns(surname) get cardinality: @card(<card-args>)
#    Then entity(customer) get owns(surname) is key: false
#    Then entity(subscriber) get owns(surname) get constraints do not contain: @card(<card-args>)
#    Then entity(subscriber) get owns(surname) is key: true
#    Then entity(subscriber) get owns(third-name) is key: true
#    Then entity(subscriber) get owns(third-name) get declared annotations contain: @key
#    Then entity(subscriber) get owns(third-name) get cardinality: @card(1..1)
#    Then entity(person) get owns(name) set annotation: @key; fails
#    Then entity(customer) get owns(surname) set annotation: @key; fails
#    Then entity(subscriber) get owns(surname) set specialise: name; fails
#    Then entity(subscriber) get owns(third-name) set specialise: name; fails
#    When entity(customer) get owns(surname) unset specialise
#    When entity(subscriber) get owns(surname) unset annotation: @key
#    When entity(customer) get owns(surname) set annotation: @key
#    When entity(subscriber) get owns(surname) set specialise: name
#    Then entity(person) get owns(name) set annotation: @key; fails
#    Then entity(customer) get owns(surname) set specialise: name; fails
#    Then entity(subscriber) get owns(surname) set annotation: @key; fails
#    Then entity(person) get owns(name) get constraints contain: @card(<card-args>)
#    Then entity(person) get owns(name) get declared annotations contain: @card(<card-args>)
#    Then entity(person) get owns(name) get cardinality: @card(<card-args>)
#    Then entity(person) get owns(name) is key: false
#    Then entity(subscriber) get owns(surname) get constraints contain: @card(<card-args>)
#    Then entity(subscriber) get owns(surname) get declared annotations do not contain: @card(<card-args>)
#    Then entity(subscriber) get owns(surname) get cardinality: @card(<card-args>)
#    Then entity(subscriber) get owns(surname) is key: false
#    Then entity(customer) get owns(surname) get constraints do not contain: @card(<card-args>)
#    Then entity(customer) get owns(surname) is key: true
#    Then entity(customer) get owns(surname) get cardinality: @card(1..1)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then entity(person) get owns(name) set annotation: @key; fails
#    Then entity(customer) get owns(surname) set specialise: name; fails
#    Then entity(subscriber) get owns(surname) set annotation: @key; fails
#    Then entity(person) get owns(name) get constraints contain: @card(<card-args>)
#    Then entity(person) get owns(name) get declared annotations contain: @card(<card-args>)
#    Then entity(person) get owns(name) get cardinality: @card(<card-args>)
#    Then entity(person) get owns(name) is key: false
#    Then entity(subscriber) get owns(surname) get constraints contain: @card(<card-args>)
#    Then entity(subscriber) get owns(surname) get declared annotations do not contain: @card(<card-args>)
#    Then entity(subscriber) get owns(surname) get cardinality: @card(<card-args>)
#    Then entity(subscriber) get owns(surname) is key: false
#    Then entity(customer) get owns(surname) get constraints do not contain: @card(<card-args>)
#    Then entity(customer) get owns(surname) is key: true
#    Then entity(customer) get owns(surname) get cardinality: @card(1..1)
#    When entity(person) get owns(name) unset annotation: @card
#    When entity(customer) get owns(surname) set specialise: name
#    When entity(subscriber) get owns(surname) set annotation: @key
#    Then entity(person) get owns(name) is key: false
#    Then entity(person) get owns(name) get cardinality: @card(0..1)
#    Then entity(customer) get owns(surname) is key: true
#    Then entity(customer) get owns(surname) get cardinality: @card(1..1)
#    Then entity(subscriber) get owns(surname) is key: true
#    Then entity(subscriber) get owns(surname) get cardinality: @card(1..1)
#    When transaction commits
#    When connection open read transaction for database: typedb
#    Then entity(person) get owns(name) is key: false
#    Then entity(person) get owns(name) get cardinality: @card(0..1)
#    Then entity(customer) get owns(surname) is key: true
#    Then entity(customer) get owns(surname) get cardinality: @card(1..1)
#    Then entity(subscriber) get owns(surname) is key: true
#    Then entity(subscriber) get owns(surname) get cardinality: @card(1..1)
#    Examples:
#      | card-args |
#      | 2..       |
#      | 2..2      |

    # TODO: We (temporarily) don't revalidate cardinality narrowing in schema!
#  Scenario Outline: Annotation @unique is not inherited if @key is declared on a subtype for owns, cannot be declared having key
#    When create attribute type: name
#    When attribute(name) set value type: string
#    When attribute(name) set annotation: @abstract
#    When create attribute type: name2
#    When attribute(name2) set annotation: @abstract
#    When attribute(name2) set supertype: name
#    When create attribute type: subname2
#    When attribute(subname2) set supertype: name2
#    When create attribute type: name3
#    When attribute(name3) set supertype: name
#    When create attribute type: name4
#    When attribute(name4) set supertype: name
#    When entity(person) set annotation: @abstract
#    When entity(person) set owns: name
#    When entity(person) get owns(name) set annotation: @unique
#    When create entity type: player
#    When entity(player) set supertype: person
#    When entity(player) set annotation: @abstract
#    When entity(player) set owns: name2
#    When entity(player) get owns(name2) set specialise: name
#    When entity(player) get owns(name2) set annotation: @key
#    Then entity(player) get owns(name2) set annotation: @unique; fails
#    When create entity type: subplayer
#    When entity(subplayer) set supertype: player
#    When entity(subplayer) set annotation: @abstract
#    When entity(subplayer) set owns: subname2
#    When entity(subplayer) get owns(subname2) set specialise: name2
#    Then entity(subplayer) get owns(subname2) is key: true
#    Then entity(subplayer) get owns(subname2) get constraint categories do not contain: @unique
#    Then entity(subplayer) get owns(subname2) set annotation: @unique; fails
#    When entity(subplayer) get owns(subname2) unset specialise
#    When entity(subplayer) get owns(subname2) set annotation: @unique
#    Then entity(subplayer) get owns(subname2) get constraints contain: @unique
#    Then entity(subplayer) get owns(subname2) set specialise: name2; fails
#    When create entity type: player2
#    When entity(player2) set supertype: person
#    When entity(player2) set owns: name3
#    When entity(player2) get owns(name3) set specialise: name
#    Then entity(player2) get owns(name3) set annotation: @card(<card-non-default-narrowing-args>); fails
#    When entity(player2) get owns(name3) set annotation: @card(<card-args>)
#    When create entity type: player3
#    When entity(player3) set supertype: person
#    When entity(player3) set owns: name4
#    When entity(player3) get owns(name4) set specialise: name
#    Then entity(person) get owns(name) get constraints contain: @unique
#    Then entity(person) get owns(name) get declared annotations contain: @unique
#    Then entity(player) get owns(name2) is key: true
#    Then entity(player) get owns(name2) get constraints do not contain: @unique
#    Then entity(player) get owns(name2) get declared annotations contain: @key
#    Then entity(player) get owns(name2) get declared annotations do not contain: @unique
#    Then entity(player2) get owns(name3) get constraints contain: @card(<card-args>)
#    Then entity(player2) get owns(name3) get constraints contain: @unique
#    Then entity(player2) get owns(name3) get declared annotations contain: @card(<card-args>)
#    Then entity(player2) get owns(name3) get declared annotations do not contain: @unique
#    Then entity(player3) get owns(name4) get constraints contain: @unique
#    Then entity(player3) get owns(name4) get declared annotations do not contain: @unique
#    When transaction commits
#    When connection open read transaction for database: typedb
#    Then entity(person) get owns(name) get constraints contain: @unique
#    Then entity(person) get owns(name) get declared annotations contain: @unique
#    Then entity(player) get owns(name2) is key: true
#    Then entity(player) get owns(name2) get constraints do not contain: @unique
#    Then entity(player) get owns(name2) get declared annotations contain: @key
#    Then entity(player) get owns(name2) get declared annotations do not contain: @unique
#    Then entity(player2) get owns(name3) get constraints contain: @card(<card-args>)
#    Then entity(player2) get owns(name3) get constraints contain: @unique
#    Then entity(player2) get owns(name3) get declared annotations contain: @card(<card-args>)
#    Then entity(player2) get owns(name3) get declared annotations do not contain: @unique
#    Then entity(player3) get owns(name4) get constraints contain: @unique
#    Then entity(player3) get owns(name4) get declared annotations do not contain: @unique
#    Examples:
#      | card-args | card-non-default-narrowing-args |
#      | 1..1      | 0..2                            |
#      | 0..1      | 0..                             |

    # TODO: We (temporarily) don't revalidate cardinality narrowing in schema!
#  Scenario Outline: Constraint @card is not inherited if @key is declared on a subtype for owns, cannot be declared having key
#    When create attribute type: name
#    When attribute(name) set value type: string
#    When attribute(name) set annotation: @abstract
#    When create attribute type: name2
#    When attribute(name2) set annotation: @abstract
#    When attribute(name2) set supertype: name
#    When create attribute type: subname2
#    When attribute(subname2) set supertype: name2
#    When create attribute type: name3
#    When attribute(name3) set supertype: name
#    When create attribute type: name4
#    When attribute(name4) set supertype: name
#    When entity(person) set annotation: @abstract
#    When entity(person) set owns: name
#    When entity(person) get owns(name) set annotation: @card(<card-args>)
#    When create entity type: player
#    When entity(player) set supertype: person
#    When entity(player) set annotation: @abstract
#    When entity(player) set owns: name2
#    When entity(player) get owns(name2) set specialise: name
#    When entity(player) get owns(name2) set annotation: @key
#    Then entity(player) get owns(name2) get cardinality: @card(1..1)
#    Then entity(player) get owns(name2) set annotation: @card(<card-args>); fails
#    When create entity type: subplayer
#    When entity(subplayer) set supertype: player
#    When entity(subplayer) set annotation: @abstract
#    When entity(subplayer) set owns: subname2
#    When entity(subplayer) get owns(subname2) set specialise: name2
#    Then entity(subplayer) get owns(subname2) is key: true
#    Then entity(subplayer) get owns(subname2) get cardinality: @card(1..1)
#    Then entity(subplayer) get owns(subname2) set annotation: @card(<card-args>); fails
#    When entity(subplayer) get owns(subname2) unset specialise
#    When entity(subplayer) get owns(subname2) set annotation: @card(<card-args>)
#    Then entity(subplayer) get owns(subname2) get constraints contain: @card(<card-args>)
#    Then entity(subplayer) get owns(subname2) get cardinality: @card(<card-args>)
#    Then entity(subplayer) get owns(subname2) set specialise: name2; fails
#    When create entity type: player2
#    When entity(player2) set supertype: person
#    When entity(player2) set owns: name3
#    When entity(player2) get owns(name3) set specialise: name
#    When entity(player2) get owns(name3) set annotation: @unique
#    When create entity type: player3
#    When entity(player3) set supertype: person
#    When entity(player3) set owns: name4
#    When entity(player3) get owns(name4) set specialise: name
#    Then entity(person) get owns(name) get constraints contain: @card(<card-args>)
#    Then entity(person) get owns(name) get declared annotations contain: @card(<card-args>)
#    Then entity(person) get owns(name) get cardinality: @card(<card-args>)
#    Then entity(player) get owns(name2) is key: true
#    Then entity(player) get owns(name2) get constraints do not contain: @card(<card-args>)
#    Then entity(player) get owns(name2) get declared annotations contain: @key
#    Then entity(player) get owns(name2) get declared annotations do not contain: @card(<card-args>)
#    Then entity(player) get owns(name2) get cardinality: @card(1..1)
#    Then entity(player2) get owns(name3) get constraints contain: @unique
#    Then entity(player2) get owns(name3) get constraints contain: @card(<card-args>)
#    Then entity(player2) get owns(name3) get declared annotations contain: @unique
#    Then entity(player2) get owns(name3) get declared annotations do not contain: @card(<card-args>)
#    Then entity(player3) get owns(name4) get constraints contain: @card(<card-args>)
#    Then entity(player3) get owns(name4) get declared annotations do not contain: @card(<card-args>)
#    Then entity(player3) get owns(name4) get cardinality: @card(<card-args>)
#    When transaction commits
#    When connection open read transaction for database: typedb
#    Then entity(person) get owns(name) get constraints contain: @card(<card-args>)
#    Then entity(person) get owns(name) get declared annotations contain: @card(<card-args>)
#    Then entity(person) get owns(name) get cardinality: @card(<card-args>)
#    Then entity(player) get owns(name2) is key: true
#    Then entity(player) get owns(name2) get constraints do not contain: @card(<card-args>)
#    Then entity(player) get owns(name2) get declared annotations contain: @key
#    Then entity(player) get owns(name2) get declared annotations do not contain: @card(<card-args>)
#    Then entity(player) get owns(name2) get cardinality: @card(1..1)
#    Then entity(player2) get owns(name3) get constraints contain: @unique
#    Then entity(player2) get owns(name3) get constraints contain: @card(<card-args>)
#    Then entity(player2) get owns(name3) get declared annotations contain: @unique
#    Then entity(player2) get owns(name3) get declared annotations do not contain: @card(<card-args>)
#    Then entity(player3) get owns(name4) get constraints contain: @card(<card-args>)
#    Then entity(player3) get owns(name4) get declared annotations do not contain: @card(<card-args>)
#    Then entity(player3) get owns(name4) get cardinality: @card(<card-args>)
#    Examples:
#      | card-args |
#      | 1..1      |
#      | 0..1      |
#      | 0..2      |
#      | 0..       |

    # TODO: We (temporarily) don't revalidate key/card/unique narrowing in schema!
#  Scenario: Annotations on ownership specialises must be at least as strict as the specialised ownerships
#    When create attribute type: attr0
#    When attribute(attr0) set value type: string
#    When attribute(attr0) set annotation: @abstract
#    When create attribute type: attr1
#    When attribute(attr1) set supertype: attr0
#    When create entity type: ent0k
#    When entity(ent0k) set annotation: @abstract
#    When entity(ent0k) set owns: attr0
#    When entity(ent0k) get owns(attr0) set annotation: @key
#    When create entity type: ent0n
#    When entity(ent0n) set annotation: @abstract
#    When entity(ent0n) set owns: attr0
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    When create entity type: ent1u
#    When entity(ent1u) set supertype: ent0k
#    When entity(ent1u) set owns: attr1
#    When entity(ent1u) get owns(attr1) set specialise: attr0
#    Then entity(ent1u) get owns(attr1) set annotation: @unique; fails
#    When transaction closes
#    When connection open schema transaction for database: typedb
#    When create entity type: ent1u
#    When entity(ent1u) set supertype: ent0k
#    When entity(ent1u) set owns: attr1
#    When entity(ent1u) get owns(attr1) set annotation: @unique
#    Then entity(ent1u) get owns(attr1) set specialise: attr0; fails
#    When transaction closes
#    When connection open schema transaction for database: typedb
#    When create entity type: ent1u
#    When entity(ent1u) set supertype: ent0n
#    When entity(ent1u) set owns: attr1
#    When entity(ent1u) get owns(attr1) set specialise: attr0
#    When entity(ent1u) get owns(attr1) set annotation: @unique
#    Then transaction commits
#    When connection open schema transaction for database: typedb
#    Then entity(ent1u) set supertype: ent0k; fails
#    When transaction closes
#    When connection open schema transaction for database: typedb
#    Then entity(ent0n) get owns(attr0) set annotation: @key; fails

    # TODO: We (temporarily) don't revalidate key/card/unique narrowing in schema!
#  Scenario: Annotations on ownership redeclarations must be stricter than the previous declaration or will be flagged as redundant on commit
#    When create attribute type: attr0
#    When attribute(attr0) set value type: string
#    When create entity type: ent0n
#    When entity(ent0n) set annotation: @abstract
#    When entity(ent0n) set owns: attr0
#    When create entity type: ent0k
#    When entity(ent0k) set annotation: @abstract
#    When entity(ent0k) set owns: attr0
#    When entity(ent0k) get owns(attr0) set annotation: @key
#    When create entity type: ent0u
#    When entity(ent0u) set annotation: @abstract
#    When entity(ent0u) set owns: attr0
#    When entity(ent0u) get owns(attr0) set annotation: @unique
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    When create entity type: ent1u
#    When entity(ent1u) set supertype: ent0k
#    When entity(ent1u) set owns: attr0
#    Then transaction commits; fails
#    When connection open schema transaction for database: typedb
#    When create entity type: ent1u
#    When entity(ent1u) set supertype: ent0k
#    When entity(ent1u) set owns: attr0
#    When entity(ent0u) get owns(attr0) set annotation: @unique
#    Then transaction commits; fails
#    When connection open schema transaction for database: typedb
#    When create entity type: ent1u
#    When entity(ent1u) set supertype: ent0k
#    When entity(ent1u) set owns: attr0
#    When entity(ent1u) get owns(attr0) set specialise: attr0
#    When entity(ent0u) get owns(attr0) set annotation: @unique
#    Then transaction commits; fails
#    When connection open schema transaction for database: typedb
#    When create entity type: ent1u
#    When entity(ent1u) set supertype: ent0k
#    When entity(ent1u) set owns: attr0
#    When entity(ent0u) get owns(attr0) set annotation: @unique
#    When entity(ent1u) get owns(attr0) set specialise: attr0
#    Then transaction commits; fails
#    When connection open schema transaction for database: typedb
#    When create entity type: ent1u
#    When entity(ent1u) set supertype: ent0u
#    # Fails redundant annotations at commit
#    When entity(ent1u) set owns: attr0
#    When entity(ent1u) get owns(attr0) set annotation: @unique
#    Then transaction commits; fails
#    When connection open schema transaction for database: typedb
#    When create entity type: ent1u
#    When entity(ent1u) set supertype: ent0n
#    When entity(ent1u) set owns: attr0
#    When entity(ent1u) get owns(attr0) set annotation: @unique
#    Then transaction commits; fails
#    When connection open schema transaction for database: typedb
#    When create entity type: ent1u
#    When entity(ent1u) set supertype: ent0n
#    When entity(ent1u) set owns: attr0
#    When entity(ent1u) get owns(attr0) set annotation: @unique
#    When entity(ent1u) get owns(attr0) set specialise: attr0
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then entity(ent1u) set supertype: ent0k; fails
#    When entity(ent1u) get owns(attr0) unset specialise
#    When entity(ent1u) set supertype: ent0k
#    Then transaction commits; fails
#    When connection open schema transaction for database: typedb
#    Then entity(ent0n) get owns(attr0) set annotation: @key; fails
