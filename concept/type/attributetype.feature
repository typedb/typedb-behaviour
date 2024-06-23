# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: Concept Attribute Type

  Background:
    Given typedb starts
    Given connection opens with default authentication
    Given connection has been opened
    Given connection does not have any database
    Given connection create database: typedb
    Given connection open schema transaction for database: typedb

#    Given create struct type: custom-struct
#    Given struct(custom-struct) create field: custom-field, with value type: string
#    Given create struct type: custom-struct-2
#    Given struct(custom-struct-2) create field: custom-field-2, with value type: string

    Given transaction commits
    Given connection open schema transaction for database: typedb

########################
# attribute type common
########################
  # TODO: Test how to set None value type

  Scenario: Root attribute type cannot be deleted
    Then delete attribute type: attribute; fails

  Scenario Outline: Attribute types can be created with <value-type> value type
    When create attribute type: name
    When attribute(name) set value type: <value-type>
    Then attribute(name) exists
    Then attribute(name) get supertype: attribute
    Then attribute(name) get value type: <value-type>
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(name) exists
    Then attribute(name) get supertype: attribute
    Then attribute(name) get value type: <value-type>
    Examples:
      | value-type |
      | long       |
      | string     |
      | boolean    |
      | double     |
      | decimal    |
      | datetime   |
      | datetimetz |
      | duration   |

#  Scenario: Attribute types can be created with a struct as value type
#    When create struct type: multi-name
#    When struct(multi-name) create field: first-name, with value type: string
#    When struct(multi-name) create field: second-name, with value type: string
#    When create attribute type: full-name
#    When attribute(full-name) set value type: multi-name
#    Then attribute(full-name) exists
#    Then attribute(full-name) get supertype: attribute
#    Then attribute(full-name) get value type: multi-name
#    When transaction commits
#    When connection open read transaction for database: typedb
#    Then attribute(full-name) exists
#    Then attribute(full-name) get supertype: attribute
#    Then attribute(full-name) get value type: multi-name

  Scenario Outline: Attribute types cannot be resetared with <value-type> value type
    When create attribute type: name
    When attribute(name) set value type: <value-type>
    Then attribute(name) exists
    Then create attribute type: name; fails
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(name) exists
    Then create attribute type: name; fails
    Examples:
      | value-type |
      | long       |
      | string     |
      | boolean    |
      | double     |
      | decimal    |
      | datetime   |
      | datetimetz |
      | duration   |
#      | custom-struct |

  Scenario: Attribute types cannot be created without value types
    When create attribute type: name
    Then attribute(name) exists
    Then attribute(name) get value type is none
    Then transaction commits; fails

  Scenario Outline: Attribute types can be deleted
    When create attribute type: name
    When attribute(name) set value type: <value-type-1>
    Then attribute(name) exists
    When create attribute type: age
    When attribute(age) set value type: <value-type-2>
    Then attribute(age) exists
    When delete attribute type: age
    Then attribute(age) does not exist
    Then attribute(attribute) get subtypes do not contain:
      | age |
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(name) exists
    Then attribute(age) does not exist
    Then attribute(attribute) get subtypes do not contain:
      | age |
    When delete attribute type: name
    Then attribute(name) does not exist
    Then attribute(attribute) get subtypes do not contain:
      | name |
      | age  |
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(name) does not exist
    Then attribute(age) does not exist
    Then attribute(attribute) get subtypes do not contain:
      | name |
      | age  |
    Examples:
      | value-type-1 | value-type-2 |
      | string       | long         |
      | boolean      | double       |
      | decimal      | datetimetz   |
      | datetime     | duration     |

  Scenario: Attribute types can get the root type
    When create attribute type: is-open
    When attribute(is-open) set value type: boolean
    When create attribute type: age
    When attribute(age) set value type: long
    When create attribute type: rating
    When attribute(rating) set value type: double
    When create attribute type: name
    When attribute(name) set value type: string
    When create attribute type: timestamp
    When attribute(timestamp) set value type: datetime
    Then attribute(is-open) get supertype: attribute
    Then attribute(age) get supertype: attribute
    Then attribute(rating) get supertype: attribute
    Then attribute(name) get supertype: attribute
    Then attribute(timestamp) get supertype: attribute
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(is-open) get supertype: attribute
    Then attribute(age) get supertype: attribute
    Then attribute(rating) get supertype: attribute
    Then attribute(name) get supertype: attribute
    Then attribute(timestamp) get supertype: attribute

    # TODO: Move to thing-feature or schema/data-validation?
#  Scenario: Attribute types that have instances cannot be deleted
#    When create attribute type: name
#    When attribute(name) set value type: string
#    When transaction commits
#    When connection open write transaction for database: typedb
#    When $x = attribute(name) put: alice
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then delete attribute type: name; fails

  Scenario: Attribute types can change labels
    When create attribute type: name
    When attribute(name) set value type: string
    Then attribute(name) get name: name
    When attribute(name) set label: username
    Then attribute(name) does not exist
    Then attribute(username) exists
    Then attribute(username) get name: username
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(username) get name: username
    When attribute(username) set label: email
    Then attribute(username) does not exist
    Then attribute(email) exists
    Then attribute(email) get name: email
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(email) exists
    Then attribute(email) get name: email

  Scenario: Attribute types cannot subtype itself
    When create attribute type: is-open
    When attribute(is-open) set value type: boolean
    When create attribute type: age
    When attribute(age) set value type: long
    When create attribute type: rating
    When attribute(rating) set value type: double
    When create attribute type: name
    When attribute(name) set value type: string
    When create attribute type: timestamp
    When attribute(timestamp) set value type: datetime
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(is-open) set supertype: is-open; fails
    When connection open schema transaction for database: typedb
    Then attribute(age) set supertype: age; fails
    When connection open schema transaction for database: typedb
    Then attribute(rating) set supertype: rating; fails
    When connection open schema transaction for database: typedb
    Then attribute(name) set supertype: name; fails
    When connection open schema transaction for database: typedb
    Then attribute(timestamp) set supertype: timestamp; fails

  Scenario: Attribute types cannot subtype another attribute type of different value type
    When create attribute type: is-open
    When attribute(is-open) set value type: boolean
    When create attribute type: age
    When attribute(age) set value type: long
    When create attribute type: rating
    When attribute(rating) set value type: double
    When create attribute type: name
    When attribute(name) set value type: string
    When create attribute type: timestamp
    When attribute(timestamp) set value type: datetime
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(is-open) set supertype: age; fails
    When connection open schema transaction for database: typedb
    Then attribute(is-open) set supertype: rating; fails
    When connection open schema transaction for database: typedb
    Then attribute(is-open) set supertype: name; fails
    When connection open schema transaction for database: typedb
    Then attribute(is-open) set supertype: timestamp; fails
    When connection open schema transaction for database: typedb
    Then attribute(age) set supertype: is-open; fails
    When connection open schema transaction for database: typedb
    Then attribute(age) set supertype: rating; fails
    When connection open schema transaction for database: typedb
    Then attribute(age) set supertype: name; fails
    When connection open schema transaction for database: typedb
    Then attribute(age) set supertype: timestamp; fails
    When connection open schema transaction for database: typedb
    Then attribute(rating) set supertype: is-open; fails
    When connection open schema transaction for database: typedb
    Then attribute(rating) set supertype: age; fails
    When connection open schema transaction for database: typedb
    Then attribute(rating) set supertype: name; fails
    When connection open schema transaction for database: typedb
    Then attribute(rating) set supertype: timestamp; fails
    When connection open schema transaction for database: typedb
    Then attribute(name) set supertype: is-open; fails
    When connection open schema transaction for database: typedb
    Then attribute(name) set supertype: age; fails
    When connection open schema transaction for database: typedb
    Then attribute(name) set supertype: rating; fails
    When connection open schema transaction for database: typedb
    Then attribute(name) set supertype: timestamp; fails
    When connection open schema transaction for database: typedb
    Then attribute(timestamp) set supertype: is-open; fails
    When connection open schema transaction for database: typedb
    Then attribute(timestamp) set supertype: age; fails
    When connection open schema transaction for database: typedb
    Then attribute(timestamp) set supertype: rating; fails
    When connection open schema transaction for database: typedb
    Then attribute(timestamp) set supertype: name; fails

  # Revisit if this is still valid
#  # TODO: Doesn't need to be tied to the root since we can have abstract non-valued attribute types.
#  # Scenario: Attribute types can be retrieved by value type
#  #   Then attribute(???)  get subtypes do not contain:
#  Scenario: Attribute type root can get attribute types of a specific value type
#    When create attribute type: is-open
#    When attribute(is-open) set value type: boolean
#    When create attribute type: age
#    When attribute(age) set value type: long
#    When create attribute type: rating
#    When attribute(rating) set value type: double
#    When create attribute type: name
#    When attribute(name) set value type: string
#    When create attribute type: timestamp
#    When attribute(timestamp) set value type: datetime
#    Then attribute(attribute) as(boolean) get subtypes contain:
#      | is-open   |
#    Then attribute(attribute) as(boolean) get subtypes do not contain:
#      | age       |
#      | rating    |
#      | name      |
#      | timestamp |
#    Then attribute(attribute) as(long) get subtypes contain:
#      | age       |
#    Then attribute(attribute) as(long) get subtypes do not contain:
#      | is-open   |
#      | rating    |
#      | name      |
#      | timestamp |
#    Then attribute(attribute) as(double) get subtypes contain:
#      | rating    |
#    Then attribute(attribute) as(double) get subtypes do not contain:
#      | is-open   |
#      | age       |
#      | name      |
#      | timestamp |
#    Then attribute(attribute) as(string) get subtypes contain:
#      | name      |
#    Then attribute(attribute) as(string) get subtypes do not contain:
#      | is-open   |
#      | age       |
#      | rating    |
#      | timestamp |
#    Then attribute(attribute) as(datetime) get subtypes contain:
#      | timestamp |
#    Then attribute(attribute) as(datetime) get subtypes do not contain:
#      | is-open |
#      | age     |
#      | rating  |
#      | name    |
#    When transaction commits
#    When connection open read transaction for database: typedb
#    Then attribute(attribute) as(boolean) get subtypes contain:
#      | is-open   |
#    Then attribute(attribute) as(boolean) get subtypes do not contain:
#      | age       |
#      | rating    |
#      | name      |
#      | timestamp |
#    Then attribute(attribute) as(long) get subtypes contain:
#      | age       |
#    Then attribute(attribute) as(long) get subtypes do not contain:
#      | is-open   |
#      | rating    |
#      | name      |
#      | timestamp |
#    Then attribute(attribute) as(double) get subtypes contain:
#      | rating    |
#    Then attribute(attribute) as(double) get subtypes do not contain:
#      | is-open   |
#      | age       |
#      | name      |
#      | timestamp |
#    Then attribute(attribute) as(string) get subtypes contain:
#      | name      |
#    Then attribute(attribute) as(string) get subtypes do not contain:
#      | is-open   |
#      | age       |
#      | rating    |
#      | timestamp |
#    Then attribute(attribute) as(datetime) get subtypes contain:
#      | timestamp |
#    Then attribute(attribute) as(datetime) get subtypes do not contain:
#      | is-open |
#      | age     |
#      | rating  |
#      | name    |

#  Scenario: Attribute type root can get attribute types of any value type
#    When create attribute type: is-open
#    When attribute(is-open) set value type: boolean
#    When create attribute type: age
#    When attribute(age) set value type: long
#    When create attribute type: rating
#    When attribute(rating) set value type: double
#    When create attribute type: name
#    When attribute(name) set value type: string
#    When create attribute type: timestamp
#    When attribute(timestamp) set value type: datetime
#    Then attribute(attribute) get subtypes contain:
#      | attribute |
#      | is-open   |
#      | age       |
#      | rating    |
#      | name      |
#      | timestamp |
#    When transaction commits
#    When connection open read transaction for database: typedb
#    Then attribute(attribute) get subtypes contain:
#      | attribute |
#      | is-open   |
#      | age       |
#      | rating    |
#      | name      |
#      | timestamp |

########################
# @annotations common
########################

  Scenario Outline: Attribute type can unset @<annotation> that has not been set
    When create attribute type: name
    When attribute(name) set value type: string
    Then attribute(name) get annotations do not contain: @<annotation>
    When attribute(name) unset annotation: @<annotation>
    Then attribute(name) get annotations do not contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(name) get annotations do not contain: @<annotation>
    When attribute(name) unset annotation: @<annotation>
    Then attribute(name) get annotations do not contain: @<annotation>
    Examples:
      | annotation   |
      | abstract     |
      | independent  |
      | regex("\S+") |
#      | values("1")     |
#      | range("1", "3") |

  Scenario Outline: Attribute type can set and unset @<annotation>
    When create attribute type: name
    When attribute(name) set value type: <value-type>
    When attribute(name) set annotation: @<annotation>
    Then attribute(name) get annotations contain: @<annotation>
    When attribute(name) unset annotation: @<annotation>
    Then attribute(name) get annotations do not contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(name) get annotations do not contain: @<annotation>
    When attribute(name) set annotation: @<annotation>
    Then attribute(name) get annotations contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(name) get annotations contain: @<annotation>
    Examples:
      | value-type | annotation   |
      | long       | abstract     |
      | long       | independent  |
#      | long       | values(1)                               |
#      | long       | range(1, 3)                             |
      | string     | abstract     |
      | string     | independent  |
      | string     | regex("\S+") |
#      | string     | values("1")                             |
#      | string     | range("1", "3")                         |
      | boolean    | abstract     |
      | boolean    | independent  |
#      | boolean    | values(true)                            |
#      | boolean    | range(false, true)                      |
      | double     | abstract     |
      | double     | independent  |
#      | double     | values(1.0)                             |
#      | double     | range(1.0, 3.0)                         |
      | decimal    | abstract     |
      | decimal    | independent  |
#      | decimal    | values(1.0)                             |
#      | decimal    | range(1.0, 3.0)                         |
      | datetime   | abstract     |
      | datetime   | independent  |
#      | datetime   | values(2024-05-06)                      |
#      | datetime   | range(2024-05-06, 2024-05-07)           |
      | datetimetz | abstract     |
      | datetimetz | independent  |
#      | datetimetz | values(2024-05-06+0010)                 |
#      | datetimetz | range(2024-05-06+0100, 2024-05-07+0100) |
      | duration   | abstract     |
      | duration   | independent  |
#      | duration   | values(P1Y)                             |
#      | duration   | range(P1Y, P5Y)                         |

    # TODO: Inheritance of annotations is not implemented yet
#  Scenario Outline: Attribute type cannot set or unset inherited @<annotation>
#    When create attribute type: name
#    When attribute(name) set value type: <value-type>
#    When attribute(name) set annotation: @abstract
#    When attribute(name) set annotation: @<annotation>
#    When create attribute type: surname
#    When attribute(surname) set value type: <value-type>
#    When attribute(surname) set supertype: name
#    Then attribute(name) get annotations contain: @<annotation>
#    Then attribute(surname) get annotations contain: @<annotation>
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then attribute(name) get annotations contain: @<annotation>
#    Then attribute(surname) get annotations contain: @<annotation>
#    When attribute(surname) set annotation: @<annotation>
#    Then transaction commits; fails
#    When connection open schema transaction for database: typedb
#    Then attribute(name) get annotations contain: @<annotation>
#    Then attribute(surname) get annotations contain: @<annotation>
#    Then attribute(surname) unset annotation: @<annotation>; fails
#    When connection open schema transaction for database: typedb
#    Then attribute(name) get annotations contain: @<annotation>
#    Then attribute(surname) get annotations contain: @<annotation>
#    Examples:
#      | value-type | annotation   |
#      # abstract is not inherited
#      | decimal    | independent  |
#      | string     | regex("\S+") |
##      | string     | values("1")                             |
##      | long     | range(1, 3)                         |

  # TODO: Write a test (and for other types!) that if supertype has @annotation and subtype has @annotation we need to explicitly remove @annotation from subtype before commit othewise we'll get an error!

########################
# @abstract
########################

  Scenario: Attribute types can be set to abstract
    When create attribute type: name
    When attribute(name) set value type: string
    When attribute(name) set annotation: @abstract
    Then attribute(name) get annotations contain: @abstract
    When transaction commits
    When connection open schema transaction for database: typedb
    When create attribute type: email
    Then attribute(email) get annotations do not contain: @abstract
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(name) get annotations contain: @abstract
    When connection open schema transaction for database: typedb
    Then attribute(email) get annotations do not contain: @abstract
    When attribute(email) set annotation: @abstract
    Then attribute(email) get annotations contain: @abstract
    When transaction commits
    When connection open schema transaction for database: typedb
    When create attribute type: company-email
    When attribute(company-email) set value type: string
    When attribute(company-email) set supertype: email
    Then attribute(email) unset annotation: @abstract; fails

  Scenario: Attribute types can be created without value types with @abstract value type
    When create attribute type: name
    Then attribute(name) exists
    When attribute(name) set annotation: @abstract
    Then attribute(name) exists
    Then attribute(name) get value type is none
    Then attribute(name) get annotations contain: @abstract
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(name) exists
    Then attribute(name) get value type is none
    Then attribute(name) get annotations contain: @abstract

    # TODO: Inherit value types
#  Scenario: Attribute type cannot set value type if it already inherits it
#    When create attribute type: name
#    When attribute(name) set value type: string
#    When attribute(name) set annotation: @abstract
#    Then attribute(name) get annotations contain: @abstract
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    When create attribute type: email
#    When attribute(email) set supertype: name
#    When attribute(email) set value type: string
#    Then transaction commits; fails
#    When connection open schema transaction for database: typedb
#    When create attribute type: email
#    When attribute(email) set value type: string
#    When attribute(email) set supertype: name
#    Then transaction commits; fails
#    When connection open schema transaction for database: typedb
#    When create attribute type: email
#    When attribute(email) set supertype: name
#    When transaction commits
#    When connection open read transaction for database: typedb
#    Then attribute(name) get value type: string
#    Then attribute(email) get value type: string

  Scenario: Inherited attribute types without @abstract cannot be created without value type
    When create attribute type: name
    When attribute(name) set annotation: @abstract
    When create attribute type: first-name
    When attribute(first-name) set supertype: name
    Then attribute(first-name) get value type is none
    Then transaction commits; fails

  Scenario: Attribute type can reset @abstract annotation
    When create attribute type: name
    When attribute(name) set value type: string
    When attribute(name) set annotation: @abstract
    Then attribute(name) get annotations contain: @abstract
    When attribute(name) set annotation: @abstract
    Then attribute(name) get annotations contain: @abstract
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(name) get annotations contain: @abstract

  Scenario Outline: Attribute type cannot subtype an attribute type with different value type
    When create attribute type: name
    When attribute(name) set annotation: @abstract
    Then attribute(name) get annotations contain: @abstract
    When attribute(name) set value type: <value-type-1>
    When create attribute type: first-name
    When attribute(first-name) set value type: <value-type-2>
    Then attribute(first-name) set supertype: name; fails
    Then attribute(name) get value type: <value-type-1>
    Then attribute(first-name) get value type: <value-type-2>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(name) get annotations contain: @abstract
    Then attribute(name) get value type: <value-type-1>
    Then attribute(first-name) get value type: <value-type-2>
    Then attribute(first-name) set supertype: name; fails
    Examples:
    # TODO: No structs!
      | value-type-1 | value-type-2 |
      | long         | string       |
      | long         | boolean      |
      | long         | double       |
      | long         | decimal      |
      | long         | datetime     |
      | long         | datetimetz   |
      | long         | duration     |
#      | long          | custom-struct   |
      | string       | long         |
      | string       | boolean      |
      | string       | double       |
      | string       | decimal      |
      | string       | datetime     |
      | string       | datetimetz   |
      | string       | duration     |
#      | string        | custom-struct   |
      | boolean      | long         |
      | boolean      | string       |
      | boolean      | double       |
      | boolean      | decimal      |
      | boolean      | datetime     |
      | boolean      | datetimetz   |
      | boolean      | duration     |
#      | boolean       | custom-struct   |
      | double       | long         |
      | double       | string       |
      | double       | boolean      |
      | double       | decimal      |
      | double       | datetime     |
      | double       | datetimetz   |
      | double       | duration     |
#      | double        | custom-struct   |
      | decimal      | long         |
      | decimal      | string       |
      | decimal      | boolean      |
      | decimal      | double       |
      | decimal      | datetime     |
      | decimal      | datetimetz   |
      | decimal      | duration     |
#      | decimal       | custom-struct   |
      | datetime     | long         |
      | datetime     | string       |
      | datetime     | boolean      |
      | datetime     | double       |
      | datetime     | decimal      |
      | datetime     | datetimetz   |
      | datetime     | duration     |
#      | datetime      | custom-struct   |
      | datetimetz   | long         |
      | datetimetz   | string       |
      | datetimetz   | boolean      |
      | datetimetz   | double       |
      | datetimetz   | decimal      |
      | datetimetz   | datetime     |
      | datetimetz   | duration     |
#      | datetimetz    | custom-struct   |
      | duration     | long         |
      | duration     | string       |
      | duration     | boolean      |
      | duration     | double       |
      | duration     | decimal      |
      | duration     | datetime     |
      | duration     | datetimetz   |
#      | duration      | custom-struct   |
#      | custom-struct | long            |
#      | custom-struct | string          |
#      | custom-struct | boolean         |
#      | custom-struct | double          |
#      | custom-struct | decimal         |
#      | custom-struct | datetime        |
#      | custom-struct | datetimetz      |
#      | custom-struct | custom-struct-2 |

  Scenario Outline: Attribute types can set <value-type> value type after inheriting from an abstract attribute type without value type
    When create attribute type: name
    When attribute(name) set annotation: @abstract
    When create attribute type: first-name
    When attribute(first-name) set supertype: name
    When attribute(first-name) set value type: <value-type>
    Then attribute(name) get value type is none
    Then attribute(first-name) get value type: <value-type>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(first-name) get value type: <value-type>
    Then attribute(name) get value type is none
    Examples:
      | value-type |
      | long       |
      | string     |
      | boolean    |
      | double     |
      | decimal    |
      | datetime   |
      | datetimetz |
      | duration   |
#      | custom-struct |

  Scenario Outline: Attribute types can set <value-type> value type before inheriting from an abstract attribute type without value type
    When create attribute type: name
    When attribute(name) set annotation: @abstract
    When create attribute type: first-name
    When attribute(first-name) set value type: <value-type>
    When attribute(first-name) set supertype: name
    Then attribute(name) get value type is none
    Then attribute(first-name) get value type: <value-type>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(first-name) get value type: <value-type>
    Then attribute(name) get value type is none
    Examples:
      | value-type |
      | long       |
      | string     |
      | boolean    |
      | double     |
      | decimal    |
      | datetime   |
      | datetimetz |
      | duration   |
#      | custom-struct |

  # TODO: Add value type inheritance
#  Scenario Outline: Attribute types can inherit <value-type> value type from supertype
#    When create attribute type: name
#    When attribute(name) set annotation: @abstract
#    When attribute(name) set value type: <value-type>
#    When create attribute type: first-name
#    Then attribute(first-name) set supertype: name; fails
#    Then attribute(first-name) get value type is none
#    When attribute(first-name) set supertype: name
#    Then attribute(first-name) get supertype: name
#    Then attribute(first-name) get value type: <value-type>
#    When transaction commits
#    When connection open read transaction for database: typedb
#    Then attribute(first-name) get supertype: name
#    Then attribute(first-name) get value type: <value-type>
#    Examples:
#      | value-type |
#      | long       |
#      | string     |
#      | boolean    |
#      | double     |
#      | decimal    |
#      | datetime   |
#      | datetimetz |
#      | duration   |
##      | custom-struct |

  Scenario Outline: Attribute type of <value-type> value type cannot inherit @abstract annotation, but can set it being a subtype
    When create attribute type: name
    When attribute(name) set annotation: @abstract
    Then attribute(name) get annotations contain: @abstract
    When attribute(name) set value type: <value-type>
    When create attribute type: first-name
    When attribute(first-name) set value type: <value-type>
    When attribute(first-name) set supertype: name
    Then attribute(name) get annotations contain: @abstract
    Then attribute(first-name) get annotations do not contain: @abstract
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(name) get annotations contain: @abstract
    Then attribute(first-name) get annotations do not contain: @abstract
    When attribute(first-name) set annotation: @abstract
    Then attribute(first-name) get annotations contain: @abstract
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(first-name) get annotations contain: @abstract
    Examples:
      | value-type |
      | long       |
      | string     |
      | boolean    |
      | double     |
      | decimal    |
      | datetime   |
      | datetimetz |
      | duration   |
#      | custom-struct |

      # TODO: Move to schema/data-validation?
#  Scenario: Attribute types cannot unset @abstract annotation if it does not have value type
#    When create attribute type: name
#    When attribute(name) set annotation: @abstract
#    Then attribute(name) get value type is none
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then attribute(name) get value type is none
#    When attribute(name) unset annotation: @abstract
#    Then transaction commits; fails

  Scenario: Attribute types can unset @abstract annotation if it gets value type before unsetting annotation
    When create attribute type: name
    When attribute(name) set annotation: @abstract
    When attribute(name) set value type: string
    When attribute(name) unset annotation: @abstract
    Then attribute(name) get annotations is empty
    When transaction commits
    When connection open schema transaction for database: typedb
    When attribute(name) get value type: string
    Then attribute(name) get annotations is empty

  Scenario: Attribute types can unset @abstract annotation if it gets value type after unsetting annotation
    When create attribute type: name
    When attribute(name) set annotation: @abstract
    When attribute(name) unset annotation: @abstract
    Then attribute(name) get annotations is empty
    When attribute(name) set value type: string
    When transaction commits
    When connection open schema transaction for database: typedb
    When attribute(name) get value type: string
    Then attribute(name) get annotations is empty

  Scenario: Attribute types can be subtypes of other attribute types
    When create attribute type: first-name
    When create attribute type: last-name
    When create attribute type: real-name
    When create attribute type: username
    When create attribute type: name
    When attribute(name) set value type: string
    When attribute(real-name) set annotation: @abstract
    When attribute(name) set annotation: @abstract
    When attribute(first-name) set supertype: real-name
    When attribute(last-name) set supertype: real-name
    When attribute(real-name) set supertype: name
    When attribute(username) set supertype: name
    Then attribute(first-name) get supertype: real-name
    Then attribute(last-name) get supertype: real-name
    Then attribute(real-name) get supertype: name
    Then attribute(username) get supertype: name
    Then attribute(first-name) get supertypes contain:
      | attribute |
      | real-name |
      | name      |
    Then attribute(last-name) get supertypes contain:
      | attribute |
      | real-name |
      | name      |
    Then attribute(real-name) get supertypes contain:
      | attribute |
      | name      |
    Then attribute(username) get supertypes contain:
      | attribute |
      | name      |
    Then attribute(first-name) get subtypes is empty
    Then attribute(last-name) get subtypes is empty
    Then attribute(real-name) get subtypes contain:
      | first-name |
      | last-name  |
    Then attribute(username) get subtypes is empty
    Then attribute(name) get subtypes contain:
      | username   |
      | real-name  |
      | first-name |
      | last-name  |
    Then attribute(attribute) get subtypes contain:
      | name       |
      | username   |
      | real-name  |
      | first-name |
      | last-name  |
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(first-name) get supertype: real-name
    Then attribute(last-name) get supertype: real-name
    Then attribute(real-name) get supertype: name
    Then attribute(username) get supertype: name
    Then attribute(first-name) get supertypes contain:
      | attribute |
      | real-name |
      | name      |
    Then attribute(last-name) get supertypes contain:
      | attribute |
      | real-name |
      | name      |
    Then attribute(real-name) get supertypes contain:
      | attribute |
      | name      |
    Then attribute(username) get supertypes contain:
      | attribute |
      | name      |
    Then attribute(first-name) get subtypes is empty
    Then attribute(last-name) get subtypes is empty
    Then attribute(real-name) get subtypes contain:
      | first-name |
      | last-name  |
    Then attribute(username) get subtypes is empty
    Then attribute(name) get subtypes contain:
      | username   |
      | real-name  |
      | first-name |
      | last-name  |
    Then attribute(attribute) get subtypes contain:
      | name       |
      | username   |
      | real-name  |
      | first-name |
      | last-name  |

  Scenario: Attribute types cannot subtype non abstract attribute types
    When create attribute type: name
    When attribute(name) set value type: string
    When create attribute type: first-name
    When attribute(first-name) set value type: string
    When create attribute type: last-name
    When attribute(last-name) set value type: string
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(first-name) set supertype: name; fails
    When connection open schema transaction for database: typedb
    Then attribute(last-name) set supertype: name; fails
#  TODO: Make it only for typeql
#  Scenario: Attribute type cannot set @abstract annotation with arguments
#    When create attribute type: name
#    When attribute(name) set value type: string
#    Then attribute(name) set annotation: @abstract(); fails
#    Then attribute(name) set annotation: @abstract(1); fails
#    Then attribute(name) set annotation: @abstract(1, 2); fails
#    Then attribute(name) get annotations is empty
#    When transaction commits
#    When connection open read transaction for database: typedb
#    Then attribute(name) get annotations is empty

########################
# @regex
########################

  Scenario Outline: Attribute types with <value-type> value type can set @regex annotation and unset it
    When create attribute type: email
    When attribute(email) set value type: <value-type>
    When attribute(email) set annotation: @regex(<arg>)
    Then attribute(email) get annotations contain: @regex(<arg>)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(email) get annotations contain: @regex(<arg>)
    Then attribute(email) unset annotation: @regex(<arg>)
    Then attribute(email) get annotations do not contain: @regex(<arg>)
    Then transaction commits
    When connection open read transaction for database: typedb
    Then attribute(email) get annotations do not contain: @regex(<arg>)
    Examples:
      | value-type | arg                 |
      | string     | "value"             |
      | string     | "123.456"           |
      | string     | "\S+"               |
      | string     | "\S+@\S+\.\S+"      |
      | string     | "^starts"           |
      | string     | "ends$"             |
      | string     | "^starts and ends$" |
      | string     | "^(not)$"           |
      | string     | "2024-06-04+0100"   |

  Scenario Outline: Attribute types with incompatible value types can't have @regex annotation
    When create attribute type: email
    When attribute(email) set value type: <value-type>
    Then attribute(email) set annotation: @regex(<arg>); fails
    Then attribute(email) get annotations is empty
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(email) set annotation: @regex(<arg>); fails
    Then attribute(email) get annotations is empty
    Examples:
      | value-type | arg     |
      | long       | "value" |
      | boolean    | "value" |
      | double     | "value" |
      | decimal    | "value" |
      | datetime   | "value" |
      | datetimetz | "value" |
      | duration   | "value" |
#      | custom-struct | "value" |

    # TODO: Inheritance of annotations is not implemented yet
#  Scenario: Attribute types' @regex annotation can be inherited
#    When create attribute type: name
#    When attribute(name) set value type: string
#    When attribute(name) set annotation: @abstract
#    When attribute(name) set annotation: @regex("value")
#    When create attribute type: first-name
#    When attribute(first-name) set value type: string
#    When attribute(first-name) set supertype: name
#    Then attribute(first-name) get annotations contain: @regex("value")
#    When transaction commits
#    When connection open read transaction for database: typedb
#    Then attribute(first-name) get annotations contain: @regex("value")

  #  TODO: Make it only for typeql
#  Scenario: Attribute type cannot set @regex annotation with wrong arguments
#    When create attribute type: name
#    When attribute(name) set value type: string
#    Then attribute(name) set annotation: @regex; fails
#    Then attribute(name) set annotation: @regex(); fails
#    Then attribute(name) set annotation: @regex(1); fails
#    Then attribute(name) set annotation: @regex(1, 2); fails
#    Then attribute(name) set annotation: @regex("val1", "val2"); fails
#    Then attribute(name) get annotations is empty
#    When transaction commits
#    When connection open read transaction for database: typedb
#    Then attribute(name) get annotations is empty

  Scenario Outline: Attribute type can reset @regex annotation
    When create attribute type: name
    When attribute(name) set value type: string
    When attribute(name) set annotation: @regex(<init-args>)
    Then attribute(name) get annotations contain: @regex(<init-args>)
    Then attribute(name) get annotations do not contain: @regex(<reset-args>)
    When attribute(name) set annotation: @regex(<init-args>)
    Then attribute(name) get annotations contain: @regex(<init-args>)
    Then attribute(name) get annotations do not contain: @regex(<reset-args>)
    When attribute(name) set annotation: @regex(<reset-args>)
    Then attribute(name) get annotations contain: @regex(<reset-args>)
    Then attribute(name) get annotations do not contain: @regex(<init-args>)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(name) get annotations contain: @regex(<reset-args>)
    Then attribute(name) get annotations do not contain: @regex(<init-args>)
    When attribute(name) set annotation: @regex(<init-args>)
    Then attribute(name) get annotations contain: @regex(<init-args>)
    Then attribute(name) get annotations do not contain: @regex(<reset-args>)
    Examples:
      | init-args | reset-args      |
      | "\S+"     | "\S"            |
      | "\S+"     | "S+"            |
      | "\S+"     | "*"             |
      | "\S+"     | "s"             |
      | "\S+"     | " some string " |

    # TODO: Inheritance of annotations is not implemented yet
#  Scenario: Attribute type cannot override inherited @regex annotation
#    When create attribute type: name
#    When attribute(name) set value type: string
#    When create attribute type: first-name
#    When attribute(first-name) set value type: string
#    When attribute(name) set annotation: @regex("\S+")
#    Then attribute(name) get annotations contain: @regex("\S+")
#    Then attribute(first-name) get annotations is empty
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then attribute(name) get annotations contain: @regex("\S+")
#    Then attribute(first-name) get annotations is empty
#    When attribute(first-name) set supertype: name
#    Then attribute(first-name) get annotations contain: @regex("\S+")
#    Then attribute(first-name) set annotation: @regex("\S+"); fails
#    Then attribute(first-name) set annotation: @regex("test"); fails
#    When connection open schema transaction for database: typedb
#    Then attribute(name) get annotations contain: @regex("\S+")
#    Then attribute(first-name) get annotations is empty
#    When attribute(first-name) set annotation: @regex("\S+")
#    Then attribute(first-name) get annotations contain    : @regex("\S+")
#    Then attribute(first-name) set supertype: name; fails
#    When attribute(first-name) unset annotation: @regex("\S+")
#    When attribute(first-name) set supertype: name
#    Then attribute(first-name) get annotations contain    : @regex("\S+")
#    When transaction commits
#    When connection open read transaction for database: typedb
#    Then attribute(name) get annotations contain    : @regex("\S+")
#    Then attribute(first-name) get annotations contain    : @regex("\S+")
#
#  Scenario: Attribute type cannot reset inherited @regex annotation
#    When create attribute type: name
#    When attribute(name) set annotation: @abstract
#    When attribute(name) set annotation: @regex("value")
#    When attribute(name) set value type: string
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    When create attribute type: first-name
#    When attribute(first-name) set value type: string
#    When attribute(first-name) set supertype: name
#    Then attribute(first-name) get annotations contain: @regex("value")
#    Then attribute(first-name) set annotation: @regex("another value"); fails
#    Then attribute(first-name) get annotations contain: @regex("value")
#    When attribute(first-name) set annotation: @regex("value")
#    Then transaction commits; fails
#    When connection open schema transaction for database: typedb
#    When attribute(first-name) set annotation: @regex("value")
#    Then transaction commits; fails
#
#  Scenario: Attribute type cannot unset inherited @regex annotation
#    When create attribute type: name
#    When attribute(name) set annotation: @abstract
#    When attribute(name) set annotation: @regex("value")
#    When attribute(name) set value type: string
#    When create attribute type: first-name
#    When attribute(first-name) set value type: string
#    When attribute(first-name) set supertype: name
#    Then attribute(first-name) get annotations contain: @regex("value")
#    Then attribute(first-name) unset annotation: @regex("another value"); fails
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then attribute(first-name) get annotations contain: @regex("value")
#    Then attribute(first-name) unset annotation: @regex("another value"); fails
#    When attribute(first-name) unset supertype: name
#    Then attribute(first-name) get annotations do not contain: @regex("value")
#    When transaction commits
#    When connection open read transaction for database: typedb
#    Then attribute(first-name) get annotations do not contain: @regex("value")

########################
# @independent
########################

  Scenario Outline: Attribute types with <value-type> value type can set @independent annotation and unset it
    When create attribute type: email
    When attribute(email) set value type: <value-type>
    When attribute(email) set annotation: @independent
    Then attribute(email) get annotations contain: @independent
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(email) get annotations contain: @independent
    Then attribute(email) unset annotation: @independent
    Then attribute(email) get annotations do not contain: @independent
    Then transaction commits
    When connection open read transaction for database: typedb
    Then attribute(email) get annotations do not contain: @independent
    Examples:
      | value-type |
      | long       |
      | string     |
      | boolean    |
      | double     |
      | decimal    |
      | datetime   |
      | datetimetz |
      | duration   |
#      | custom-struct |

  Scenario: Attribute type can reset @independent annotation
    When create attribute type: name
    When attribute(name) set value type: string
    When attribute(name) set annotation: @independent
    Then attribute(name) get annotations contain: @independent
    When attribute(name) set annotation: @independent
    Then attribute(name) get annotations contain: @independent
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(name) get annotations contain: @independent

    # TODO: Inheritance of annotations is not implemented yet
#  Scenario: Attribute types' @independent annotation can be inherited
#    When create attribute type: name
#    When attribute(name) set value type: string
#    When attribute(name) set annotation: @abstract
#    When attribute(name) set annotation: @independent
#    When create attribute type: first-name
#    When attribute(first-name) set value type: string
#    When attribute(first-name) set supertype: name
#    Then attribute(first-name) get annotations contain: @independent
#    When transaction commits
#    When connection open read transaction for database: typedb
#    Then attribute(first-name) get annotations contain: @independent

    # TODO: Inheritance of annotations is not implemented yet
#  Scenario: Attribute type cannot reset inherited @independent annotation
#    When create attribute type: name
#    When attribute(name) set annotation: @abstract
#    When attribute(name) set annotation: @independent
#    When attribute(name) set value type: string
#    When create attribute type: first-name
#    When attribute(first-name) set value type: string
#    When attribute(first-name) set supertype: name
#    Then attribute(first-name) get annotations contain: @independent
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    When attribute(first-name) set annotation: @independent
#    Then transaction commits; fails
#    When connection open schema transaction for database: typedb
#    When create attribute type: second-name
#    When attribute(second-name) set value type: string
#    When attribute(second-name) set supertype: name
#    Then attribute(second-name) get annotations contain: @independent
#    When attribute(second-name) set annotation: @independent
#    Then transaction commits; fails

    # TODO: Inheritance of annotations is not implemented yet
#  Scenario: Attribute type cannot unset inherited @independent annotation
#    When create attribute type: name
#    When attribute(name) set annotation: @abstract
#    When attribute(name) set annotation: @independent
#    When attribute(name) set value type: string
#    When create attribute type: first-name
#    When attribute(first-name) set value type: string
#    When attribute(first-name) set supertype: name
#    Then attribute(first-name) get annotations contain: @independent
#    Then attribute(first-name) unset annotation: @independent; fails
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then attribute(first-name) get annotations contain: @independent
#    Then attribute(first-name) unset annotation: @independent; fails
#    When attribute(first-name) unset supertype: name
#    Then attribute(first-name) get annotations do not contain: @independent
#    When transaction commits
#    When connection open read transaction for database: typedb
#    Then attribute(first-name) get annotations do not contain: @independent

#  TODO: Make it only for typeql
#  Scenario: Attribute type cannot set @independent annotation with arguments
#    When create attribute type: name
#    When attribute(name) set value type: string
#    Then attribute(name) set annotation: @independent(); fails
#    Then attribute(name) set annotation: @independent(1); fails
#    Then attribute(name) set annotation: @independent(1, 2); fails
#    Then attribute(name) set annotation: @independent("val1"); fails
#    Then attribute(name) get annotations is empty
#    When transaction commits
#    When connection open read transaction for database: typedb
#    Then attribute(name) get annotations is empty

########################
# @values
########################

#  Scenario Outline: Attribute types with <value-type> value type can set @values annotation and unset it
#    When create attribute type: email
#    When attribute(email) set value type: <value-type>
#    When attribute(email) set annotation: @values(<args>)
#    Then attribute(email) get annotations contain: @values(<args>)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then attribute(email) get annotations contain: @values(<args>)
#    Then attribute(email) unset annotation: @values(<args>)
#    Then attribute(email) get annotations do not contain: @values(<args>)
#    Then transaction commits
#    When connection open read transaction for database: typedb
#    Then attribute(email) get annotations do not contain: @values(<args>)
#    Examples:
#      | value-type | args                                                                                                                                                                                                                                                                                                                                                                                                 |
#      | long       | 0                                                                                                                                                                                                                                                                                                                                                                                                    |
#      | long       | 1                                                                                                                                                                                                                                                                                                                                                                                                    |
#      | long       | -1                                                                                                                                                                                                                                                                                                                                                                                                   |
#      | long       | 1, 2                                                                                                                                                                                                                                                                                                                                                                                                 |
#      | long       | -9223372036854775808, 9223372036854775807                                                                                                                                                                                                                                                                                                                                                            |
#      | long       | 2, 1, 3, 4, 5, 6, 7, 9, 10, 11, 55, -1, -654321, 123456                                                                                                                                                                                                                                                                                                                                              |
#      | long       | 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99 |
#      | string     | ""                                                                                                                                                                                                                                                                                                                                                                                                   |
#      | string     | "1"                                                                                                                                                                                                                                                                                                                                                                                                  |
#      | string     | "福"                                                                                                                                                                                                                                                                                                                                                                                                  |
#      | string     | "s", "S"                                                                                                                                                                                                                                                                                                                                                                                             |
#      | string     | "This rank contain a sufficiently detailed description of its nature"                                                                                                                                                                                                                                                                                                                                |
#      | string     | "Scout", "Stone Guard", "Stone Guard", "High Warlord"                                                                                                                                                                                                                                                                                                                                                |
#      | string     | "Rank with optional space", "Rank with optional space ", " Rank with optional space", "Rankwithoptionalspace", "Rank with optional space  "                                                                                                                                                                                                                                                          |
#      | boolean    | true                                                                                                                                                                                                                                                                                                                                                                                                 |
#      | boolean    | false                                                                                                                                                                                                                                                                                                                                                                                                |
#      | boolean    | false, true                                                                                                                                                                                                                                                                                                                                                                                          |
#      | double     | 0.0                                                                                                                                                                                                                                                                                                                                                                                                  |
#      | double     | 0                                                                                                                                                                                                                                                                                                                                                                                                    |
#      | double     | 1.1                                                                                                                                                                                                                                                                                                                                                                                                  |
#      | double     | -2.45                                                                                                                                                                                                                                                                                                                                                                                                |
#      | double     | -3.444, 3.445                                                                                                                                                                                                                                                                                                                                                                                        |
#      | double     | 0.00001, 0.0001, 0.001, 0.01                                                                                                                                                                                                                                                                                                                                                                         |
#      | double     | -333.553, 33895, 98984.4555, 902394.44, 1000000000, 0.00001, 0.3, 3.14159265358979323                                                                                                                                                                                                                                                                                                                |
#      | decimal    | 0.0                                                                                                                                                                                                                                                                                                                                                                                                  |
#      | decimal    | 0                                                                                                                                                                                                                                                                                                                                                                                                    |
#      | decimal    | 1.1                                                                                                                                                                                                                                                                                                                                                                                                  |
#      | decimal    | -2.45                                                                                                                                                                                                                                                                                                                                                                                                |
#      | decimal    | -3.444, 3.445                                                                                                                                                                                                                                                                                                                                                                                        |
#      | decimal    | 0.00001, 0.0001, 0.001, 0.01                                                                                                                                                                                                                                                                                                                                                                         |
#      | decimal    | -333.553, 33895, 98984.4555, 902394.44, 1000000000, 0.00001, 0.3, 3.14159265358979323                                                                                                                                                                                                                                                                                                                |
#      | datetime   | 2024-06-04                                                                                                                                                                                                                                                                                                                                                                                           |
#      | datetime   | 2024-06-04T16:35                                                                                                                                                                                                                                                                                                                                                                                     |
#      | datetime   | 2024-06-04T16:35:02                                                                                                                                                                                                                                                                                                                                                                                  |
#      | datetime   | 2024-06-04T16:35:02.1                                                                                                                                                                                                                                                                                                                                                                                |
#      | datetime   | 2024-06-04T16:35:02.10                                                                                                                                                                                                                                                                                                                                                                               |
#      | datetime   | 2024-06-04T16:35:02.103                                                                                                                                                                                                                                                                                                                                                                              |
#      | datetime   | 2024-06-04, 2024-06-04T16:35, 2024-06-04T16:35:02, 2024-06-04T16:35:02.1, 2024-06-04T16:35:02.10, 2024-06-04T16:35:02.103                                                                                                                                                                                                                                                                            |
#      | datetimetz | 2024-06-04+0000                                                                                                                                                                                                                                                                                                                                                                                      |
#      | datetimetz | 2024-06-04 Asia/Kathmandu                                                                                                                                                                                                                                                                                                                                                                            |
#      | datetimetz | 2024-06-04+0100                                                                                                                                                                                                                                                                                                                                                                                      |
#      | datetimetz | 2024-06-04T16:35+0100                                                                                                                                                                                                                                                                                                                                                                                |
#      | datetimetz | 2024-06-04T16:35:02+0100                                                                                                                                                                                                                                                                                                                                                                             |
#      | datetimetz | 2024-06-04T16:35:02.1+0100                                                                                                                                                                                                                                                                                                                                                                           |
#      | datetimetz | 2024-06-04T16:35:02.10+0100                                                                                                                                                                                                                                                                                                                                                                          |
#      | datetimetz | 2024-06-04T16:35:02.103+0100                                                                                                                                                                                                                                                                                                                                                                         |
#      | datetimetz | 2024-06-04+0001, 2024-06-04 Asia/Kathmandu, 2024-06-04+0002, 2024-06-04+0010, 2024-06-04+0100, 2024-06-04-0100, 2024-06-04T16:35-0100, 2024-06-04T16:35:02+0200, 2024-06-04T16:35:02.1-0300, 2024-06-04T16:35:02.10+1000, 2024-06-04T16:35:02.103+0011                                                                                                                                               |
#      | duration   | P1Y                                                                                                                                                                                                                                                                                                                                                                                                  |
#      | duration   | P2M                                                                                                                                                                                                                                                                                                                                                                                                  |
#      | duration   | P1Y2M                                                                                                                                                                                                                                                                                                                                                                                                |
#      | duration   | P1Y2M3D                                                                                                                                                                                                                                                                                                                                                                                              |
#      | duration   | P1Y2M3DT4H                                                                                                                                                                                                                                                                                                                                                                                           |
#      | duration   | P1Y2M3DT4H5M                                                                                                                                                                                                                                                                                                                                                                                         |
#      | duration   | P1Y2M3DT4H5M6S                                                                                                                                                                                                                                                                                                                                                                                       |
#      | duration   | P1Y2M3DT4H5M6.789S                                                                                                                                                                                                                                                                                                                                                                                   |
#      | duration   | P1Y, P1Y1M, P1Y1M1D, P1Y1M1DT1H, P1Y1M1DT1H1M, P1Y1M1DT1H1M1S, 1Y1M1DT1H1M1S0.1S, 1Y1M1DT1H1M1S0.001S, 1Y1M1DT1H1M0.000001S                                                                                                                                                                                                                                                                          |
#
##  Scenario: Attribute type cannot set @values annotation for struct value type
##    When create attribute type: email
##    When attribute(email) set value type: custom-struct
##    When attribute(email) set annotation: @values(custom-struct); fails
##    When attribute(email) set annotation: @values({"string"}); fails
##    When attribute(email) set annotation: @values({custom-field: "string"}); fails
##    When attribute(email) set annotation: @values(custom-struct{custom-field: "string"}); fails
##    When attribute(email) set annotation: @values(custom-struct("string")); fails
##    When attribute(email) set annotation: @values(custom-struct(custom-field: "string")); fails
#
#  Scenario: Attribute types' @values annotation can be inherited
#    When create attribute type: name
#    When attribute(name) set value type: string
#    When attribute(name) set annotation: @abstract
#    When attribute(name) set annotation: @values("value", "value2")
#    When create attribute type: first-name
#    When attribute(first-name) set value type: string
#    When attribute(first-name) set supertype: name
#    Then attribute(first-name) get annotations contain: @values("value", "value2")
#    When transaction commits
#    When connection open read transaction for database: typedb
#    Then attribute(first-name) get annotations contain: @values("value", "value2")
#
#  Scenario Outline: Attribute type with <value-type> value type cannot set @values with empty arguments
#    When create attribute type: name
#    When attribute(name) set value type: <value-type>
#    Then attribute(name) set annotation: @values; fails
#    Then attribute(name) set annotation: @values(); fails
#    Then attribute(name) get annotations is empty
#    When transaction commits
#    When connection open read transaction for database: typedb
#    Then attribute(name) get annotations is empty
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
#
#  Scenario Outline: Attribute type with <value-type> value type cannot set @values with incorrect arguments
#    When create attribute type: name
#    When attribute(name) set value type: <value-type>
#    Then attribute(name) set annotation: @values(<args>); fails
#    Then attribute(name) get annotations is empty
#    When transaction commits
#    When connection open read transaction for database: typedb
#    Then attribute(name) get annotations is empty
#    Examples:
#      | value-type | args                            |
#      | long       | 0.1                             |
#      | long       | "string"                        |
#      | long       | true                            |
#      | long       | 2024-06-04                      |
#      | long       | 2024-06-04+0010                 |
#      | double     | "string"                        |
#      | double     | true                            |
#      | double     | 2024-06-04                      |
#      | double     | 2024-06-04+0010                 |
#      | decimal    | "string"                        |
#      | decimal    | true                            |
#      | decimal    | 2024-06-04                      |
#      | decimal    | 2024-06-04+0010                 |
#      | string     | 123                             |
#      | string     | true                            |
#      | string     | 2024-06-04                      |
#      | string     | 2024-06-04+0010                 |
#      | string     | 'notstring'                     |
#      | string     | ""                              |
#      | boolean    | 123                             |
#      | boolean    | "string"                        |
#      | boolean    | 2024-06-04                      |
#      | boolean    | 2024-06-04+0010                 |
#      | boolean    | truefalse                       |
#      | datetime   | 123                             |
#      | datetime   | "string"                        |
#      | datetime   | true                            |
#      | datetime   | 2024-06-04+0010                 |
#      | datetimetz | 123                             |
#      | datetimetz | "string"                        |
#      | datetimetz | true                            |
#      | datetimetz | 2024-06-04                      |
#      | datetimetz | 2024-06-04 NotRealTimeZone/Zone |
#      | duration   | 123                             |
#      | duration   | "string"                        |
#      | duration   | true                            |
#      | duration   | 2024-06-04                      |
#      | duration   | 2024-06-04+0100                 |
#      | duration   | 1Y                              |
#      | duration   | year                            |
#
#  Scenario Outline: Attribute type with <value-type> value type can reset @values annotation
#    When create attribute type: name
#    When attribute(name) set value type: <value-type>
#    When attribute(name) set annotation: @values(<init-args>)
#    Then attribute(name) get annotations contain    : @values(<init-args>)
#    Then attribute(name) get annotation do not contain: @values(<reset-args>)
#    When attribute(name) set annotation: @values(<init-args>)
#    Then attribute(name) get annotations contain    : @values(<init-args>)
#    Then attribute(name) get annotation do not contain: @values(<reset-args>)
#    When attribute(name) set annotation: @values(<reset-args>)
#    Then attribute(name) get annotations contain: @values(<reset-args>)
#    Then attribute(name) get annotations do not contain: @values(<init-args>)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then attribute(name) get annotations contain: @values(<reset-args>)
#    Then attribute(name) get annotations do not contain: @values(<init-args>)
#    When attribute(name) set annotation: @values(<init-args>)
#    Then attribute(name) get annotations contain    : @values(<init-args>)
#    Then attribute(name) get annotation do not contain: @values(<reset-args>)
#    Examples:
#      | value-type | init-args       | reset-args      |
#      | long       | 1, 5            | 7, 9            |
#      | double     | 1.1, 1.5        | -8.0, 88.3      |
#      | decimal    | -8.0, 88.3      | 1.1, 1.5        |
#      | string     | "s"             | "not s"         |
#      | boolean    | true            | false           |
#      | datetime   | 2024-05-05      | 2024-06-05      |
#      | datetimetz | 2024-05-05+0100 | 2024-05-05+0010 |
#      | duration   | P1Y             | P2Y             |
#
#  Scenario Outline: Attribute type cannot have @values annotation for <value-type> value type with duplicated args
#    When create attribute type: name
#    When attribute(name) set value type: <value-type>
#    Then attribute(name) set annotation: @values(<arg0>, <arg1>, <arg2>); fails
#    Then attribute(name) get annotations is empty
#    When transaction commits
#    When connection open read transaction for database: typedb
#    Then attribute(name) get annotations is empty
#    Examples:
#      | value-type | arg0                        | arg1                         | arg2                         |
#      | long       | 1                           | 1                            | 1                            |
#      | long       | 1                           | 1                            | 2                            |
#      | long       | 1                           | 2                            | 1                            |
#      | long       | 1                           | 2                            | 2                            |
#      | double     | 0.1                         | 0.0001                       | 0.0001                       |
#      | decimal    | 0.1                         | 0.0001                       | 0.0001                       |
#      | string     | "stringwithoutdifferences"  | "stringwithoutdifferences"   | "stringWITHdifferences"      |
#      | string     | "stringwithoutdifferences " | "stringwithoutdifferences  " | "stringwithoutdifferences  " |
#      | boolean    | true                        | true                         | false                        |
#      | datetime   | 2024-06-04T16:35:02.101     | 2024-06-04T16:35:02.101      | 2024-06-04                   |
#      | datetime   | 2020-06-04T16:35:02.10      | 2025-06-05T16:35             | 2025-06-05T16:35             |
#      | datetimetz | 2020-06-04T16:35:02.10+0100 | 2020-06-04T16:35:02.10+0000  | 2020-06-04T16:35:02.10+0100  |
#      | duration   | P1Y1M                       | P1Y1M                        | P1Y2M                        |
#
#  Scenario: Attribute type cannot reset inherited @values annotation
#    When create attribute type: name
#    When attribute(name) set annotation: @abstract
#    When attribute(name) set annotation: @values("value")
#    When attribute(name) set value type: string
#    When create attribute type: first-name
#    When attribute(first-name) set value type: string
#    When attribute(first-name) set supertype: name
#    Then attribute(first-name) get annotations contain: @values("value")
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    When attribute(first-name) set annotation: @values("value")
#    Then transaction commits; fails
#    When connection open schema transaction for database: typedb
#    When create attribute type: second-name
#    When attribute(second-name) set value type: string
#    When attribute(second-name) set supertype: name
#    Then attribute(second-name) get annotations contain: @values("value")
#    When attribute(second-name) set annotation: @values("value")
#    Then transaction commits; fails
#
#  Scenario: Attribute type cannot unset inherited @values annotation
#    When create attribute type: name
#    When attribute(name) set annotation: @abstract
#    When attribute(name) set annotation: @values("value")
#    When attribute(name) set value type: string
#    When create attribute type: first-name
#    When attribute(first-name) set value type: string
#    When attribute(first-name) set supertype: name
#    Then attribute(first-name) get annotations contain: @values("value")
#    Then attribute(first-name) unset annotation: @values("value"); fails
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then attribute(first-name) get annotations contain: @values("value")
#    Then attribute(first-name) unset annotation: @values("value"); fails
#    When attribute(first-name) unset supertype: name
#    Then attribute(first-name) get annotations do not contain: @values("value")
#    When transaction commits
#    When connection open read transaction for database: typedb
#    Then attribute(first-name) get annotations do not contain: @values("value")
#
#  Scenario Outline: Attribute types' @values annotation for <value-type> value type can be inherited and overridden by a subset of arguments
#    When create attribute type: name
#    When attribute(name) set value type: <value-type>
#    When create attribute type: overridden-name
#    When attribute(overridden-name) set value type: <value-type>
#    When attribute(overridden-name) set supertype: name
#    When attribute(name) set annotation: @values(<args>)
#    Then attribute(name) get annotations contain: @values(<args>)
#    Then attribute(overridden-name) get annotations contain: @values(<args>)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then attribute(name) get annotations contain: @values(<args>)
#    Then attribute(overridden-name) get annotations contain: @values(<args>)
#    When attribute(overridden-name) set annotation: @values(<args-override>)
#    Then attribute(name) get annotations contain: @values(<args>)
#    Then attribute(overridden-name) get annotations contain: @values(<args-override>)
#    When transaction commits
#    When connection open read transaction for database: typedb
#    Then attribute(name) get annotations contain: @values(<args>)
#    Then attribute(overridden-name) get annotations contain: @values(<args-override>)
#    Examples:
#      | value-type | args                                                                         | args-override                              |
#      | long       | 1, 10, 20, 30                                                                | 10, 30                                     |
#      | double     | 1.0, 2.0, 3.0, 4.5                                                           | 2.0                                        |
#      | decimal    | 0.0, 1.0                                                                     | 0.0                                        |
#      | string     | "john", "John", "Johnny", "johnny"                                           | "John", "Johnny"                           |
#      | boolean    | true, false                                                                  | true                                       |
#      | datetime   | 2024-06-04, 2024-06-05, 2024-06-06                                           | 2024-06-04, 2024-06-06                     |
#      | datetimetz | 2024-06-04+0010, 2024-06-04 Asia/Kathmandu, 2024-06-05+0010, 2024-06-05+0100 | 2024-06-04 Asia/Kathmandu, 2024-06-05+0010 |
#      | duration   | P6M, P1Y, P1Y1M, P1Y2M, P1Y3M, P1Y4M, P1Y6M                                  | P6M, P1Y3M, P1Y4M, P1Y6M                   |
#
#  Scenario Outline: Inherited @values annotation on attribute types for <value-type> value type cannot be overridden by the @values of not a subset of arguments
#    When create attribute type: name
#    When attribute(name) set value type: <value-type>
#    When create attribute type: overridden-name
#    When attribute(overridden-name) set value type: <value-type>
#    When attribute(overridden-name) set supertype: name
#    When attribute(name) set annotation: @values(<args>)
#    Then attribute(name) get annotations contain: @values(<args>)
#    Then attribute(overridden-name) get annotations contain: @values(<args>)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then attribute(name) get annotations contain: @values(<args>)
#    Then attribute(overridden-name) get annotations contain: @values(<args>)
#    Then attribute(overridden-name) set annotation: @values(<args-override>); fails
#    Then attribute(name) get annotations contain: @values(<args>)
#    Then attribute(overridden-name) get annotations contain: @values(<args>)
#    When transaction commits
#    When connection open read transaction for database: typedb
#    Then attribute(name) get annotations contain: @values(<args>)
#    Then attribute(overridden-name) get annotations contain: @values(<args>)
#    Examples:
#      | value-type | args                                                                         | args-override            |
#      | long       | 1, 10, 20, 30                                                                | 10, 31                   |
#      | double     | 1.0, 2.0, 3.0, 4.5                                                           | 2.001                    |
#      | decimal    | 0.0, 1.0                                                                     | 0.01                     |
#      | string     | "john", "John", "Johnny", "johnny"                                           | "Jonathan"               |
#      | boolean    | false                                                                        | true                     |
#      | datetime   | 2024-06-04, 2024-06-05, 2024-06-06                                           | 2020-06-04, 2020-06-06   |
#      | datetimetz | 2024-06-04+0010, 2024-06-04 Asia/Kathmandu, 2024-06-05+0010, 2024-06-05+0100 | 2024-06-04 Europe/London |
#      | duration   | P6M, P1Y, P1Y1M, P1Y2M, P1Y3M, P1Y4M, P1Y6M                                  | P3M, P1Y3M, P1Y4M, P1Y6M |

########################
# @range
########################

#  Scenario Outline: Attribute types with <value-type> value type can set @range annotation and unset it
#    When create attribute type: email
#    When attribute(email) set value type: <value-type>
#    When attribute(email) set annotation: @range(<arg0>, <arg1>)
#    Then attribute(email) get annotations contain: @range(<arg0>, <arg1>)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then attribute(email) get annotations contain: @range(<arg0>, <arg1>)
#    Then attribute(email) unset annotation: @range(<arg0>, <arg1>)
#    Then attribute(email) get annotations do not contain: @range(<arg0>, <arg1>)
#    Then transaction commits
#    When connection open read transaction for database: typedb
#    Then attribute(email) get annotations do not contain: @range(<arg0>, <arg1>)
#    Examples:
#      | value-type | arg0                         | arg1                                                  |
#      | long       | 0                            | 1                                                     |
#      | long       | 1                            | 2                                                     |
#      | long       | 0                            | 2                                                     |
#      | long       | -1                           | 1                                                     |
#      | long       | -9223372036854775808         | 9223372036854775807                                   |
#      | string     | "A"                          | "a"                                                   |
#      | string     | "a"                          | "z"                                                   |
#      | string     | "A"                          | "福"                                                   |
#      | string     | "AA"                         | "AAA"                                                 |
#      | string     | "short string"               | "very-very-very-very-very-very-very-very long string" |
#      | boolean    | false                        | true                                                  |
#      | double     | 0.0                          | 0.0001                                                |
#      | double     | 0.01                         | 1.0                                                   |
#      | double     | 123.123                      | 123123123123.122                                      |
#      | double     | -2.45                        | 2.45                                                  |
#      | decimal    | 0.0                          | 0.0001                                                |
#      | decimal    | 0.01                         | 1.0                                                   |
#      | decimal    | 123.123                      | 123123123123.122                                      |
#      | decimal    | -2.45                        | 2.45                                                  |
#      | datetime   | 2024-06-04                   | 2024-06-05                                            |
#      | datetime   | 2024-06-04                   | 2024-07-03                                            |
#      | datetime   | 2024-06-04                   | 2025-01-01                                            |
#      | datetime   | 1970-01-01                   | 9999-12-12                                            |
#      | datetime   | 2024-06-04T16:35:02.10       | 2024-06-04T16:35:02.11                                |
#      | datetimetz | 2024-06-04+0000              | 2024-06-05+0000                                       |
#      | datetimetz | 2024-06-04+0100              | 2048-06-04+0100                                       |
#      | datetimetz | 2024-06-04T16:35:02.103+0100 | 2024-06-04T16:35:02.104+0100                          |
#      | datetimetz | 2024-06-04 Asia/Kathmandu    | 2024-06-05 Asia/Kathmandu                             |
#      | duration   | P1Y                          | P2Y                                                   |
#      | duration   | P2M                          | P1Y2M                                                 |
#      | duration   | P1Y2M                        | P1Y2M3DT4H5M6.789S                                    |
#      | duration   | P1Y2M3DT4H5M6.788S           | P1Y2M3DT4H5M6.789S                                    |
#
##  Scenario: Attribute type can set @range annotation for struct value type
##    When create attribute type: name
##    When attribute(name) set value type: custom-struct
##    When attribute(name) set annotation: @range(custom-struct, custom-struct); fails
##    When attribute(name) set annotation: @range({"string"}, {"string+1"}); fails
##    When attribute(name) set annotation: @range({custom-field: "string"}, {custom-field: "string+1"}); fails
##    When attribute(name) set annotation: @range(custom-struct{custom-field: "string"}, custom-struct{custom-field: "string+1"}); fails
##    When attribute(name) set annotation: @range(custom-struct("string"), custom-struct("string+1")); fails
##    When attribute(name) set annotation: @range(custom-struct(custom-field: "string"), custom-struct(custom-field: "string+1")); fails
#
#  Scenario: Attribute types' @range annotation can be inherited
#    When create attribute type: name
#    When attribute(name) set value type: string
#    When attribute(name) set annotation: @abstract
#    When attribute(name) set annotation: @range(3, 5)
#    When create attribute type: first-name
#    When attribute(first-name) set value type: string
#    When attribute(first-name) set supertype: name
#    Then attribute(first-name) get annotations contain: @range(3, 5)
#    When transaction commits
#    When connection open read transaction for database: typedb
#    Then attribute(first-name) get annotations contain: @range(3, 5)
#
#  Scenario Outline: Attribute type with <value-type> value type cannot set @range with empty arguments
#    When create attribute type: name
#    When attribute(name) set value type: <value-type>
#    Then attribute(name) set annotation: @range; fails
#    Then attribute(name) set annotation: @range(); fails
#    Then attribute(name) get annotations is empty
#    When transaction commits
#    When connection open read transaction for database: typedb
#    Then attribute(name) get annotations is empty
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
#
#  Scenario Outline: Attribute type with <value-type> value type cannot set @range with incorrect arguments
#    When create attribute type: name
#    When attribute(name) set value type: <value-type>
#    Then attribute(name) set annotation: @range(<arg0>, <args>); fails
#    Then attribute(name) get annotations is empty
#    When transaction commits
#    When connection open read transaction for database: typedb
#    Then attribute(name) get annotations is empty
#    Examples:
#      | value-type | arg0                            | args                                               |
#      | long       | 1                               | 1                                                  |
#      | long       | 1                               | 2, 3                                               |
#      | long       | 1                               | "string"                                           |
#      | long       | 1                               | 2, "string"                                        |
#      | long       | 1                               | 2, "string", true, 2024-06-04, 55                  |
#      | long       | "string"                        | 1                                                  |
#      | long       | true                            | 1                                                  |
#      | long       | 2024-06-04                      | 1                                                  |
#      | long       | 2024-06-04+0010                 | 1                                                  |
#      | double     | 1.0                             | 1.0                                                |
#      | double     | 1.0                             | 2.0, 3.0                                           |
#      | double     | 1.0                             | "string"                                           |
#      | double     | "string"                        | 1.0                                                |
#      | double     | true                            | 1.0                                                |
#      | double     | 2024-06-04                      | 1.0                                                |
#      | double     | 2024-06-04+0010                 | 1.0                                                |
#      | decimal    | 1.0                             | 1.0                                                |
#      | decimal    | 1.0                             | 2.0, 3.0                                           |
#      | decimal    | 1.0                             | "string"                                           |
#      | decimal    | "string"                        | 1.0                                                |
#      | decimal    | true                            | 1.0                                                |
#      | decimal    | 2024-06-04                      | 1.0                                                |
#      | decimal    | 2024-06-04+0010                 | 1.0                                                |
#      | string     | "123"                           | "123"                                              |
#      | string     | "123"                           | "1234", "12345"                                    |
#      | string     | "123"                           | 123                                                |
#      | string     | 123                             | "123"                                              |
#      | string     | true                            | "str"                                              |
#      | string     | 2024-06-04                      | "str"                                              |
#      | string     | 2024-06-04+0010                 | "str"                                              |
#      | string     | 'notstring'                     | "str"                                              |
#      | string     | ""                              | "str"                                              |
#      | boolean    | false                           | false                                              |
#      | boolean    | true                            | true                                               |
#      | boolean    | true                            | 123                                                |
#      | boolean    | 123                             | true                                               |
#      | boolean    | "string"                        | true                                               |
#      | boolean    | 2024-06-04                      | true                                               |
#      | boolean    | 2024-06-04+0010                 | true                                               |
#      | boolean    | truefalse                       | true                                               |
#      | datetime   | 2030-06-04                      | 2030-06-04                                         |
#      | datetime   | 2030-06-04                      | 2030-06-05, 2030-06-06                             |
#      | datetime   | 2030-06-04                      | 123                                                |
#      | datetime   | 123                             | 2030-06-04                                         |
#      | datetime   | "string"                        | 2030-06-04                                         |
#      | datetime   | true                            | 2030-06-04                                         |
#      | datetime   | 2024-06-04+0010                 | 2030-06-04                                         |
#      | datetimetz | 2030-06-04 Europe/London        | 2030-06-04 Europe/London                           |
#      | datetimetz | 2030-06-04 Europe/London        | 2030-06-05 Europe/London, 2030-06-06 Europe/London |
#      | datetimetz | 2030-06-05 Europe/London        | 123                                                |
#      | datetimetz | 123                             | 2030-06-05 Europe/London                           |
#      | datetimetz | "string"                        | 2030-06-05 Europe/London                           |
#      | datetimetz | true                            | 2030-06-05 Europe/London                           |
#      | datetimetz | 2024-06-04                      | 2030-06-05 Europe/London                           |
#      | datetimetz | 2024-06-04 NotRealTimeZone/Zone | 2030-06-05 Europe/London                           |
#      | duration   | P1Y                             | P1Y                                                |
#      | duration   | P1Y                             | P2Y, P3Y                                           |
#      | duration   | P1Y                             | 123                                                |
#      | duration   | 123                             | P1Y                                                |
#      | duration   | "string"                        | P1Y                                                |
#      | duration   | true                            | P1Y                                                |
#      | duration   | 2024-06-04                      | P1Y                                                |
#      | duration   | 2024-06-04+0100                 | P1Y                                                |
#      | duration   | 1Y                              | P1Y                                                |
#      | duration   | year                            | P1Y                                                |
#
#  Scenario Outline: Attribute type with <value-type> value type can reset @range annotation
#    When create attribute type: name
#    When attribute(name) set value type: <value-type>
#    When attribute(name) set annotation: @range(<init-args>)
#    Then attribute(name) get annotations contain: @range(<init-args>)
#    Then attribute(name) get annotations do not contain: @range(<reset-args>)
#    When attribute(name) set annotation: @range(<init-args>)
#    Then attribute(name) get annotations contain: @range(<init-args>)
#    Then attribute(name) get annotations do not contain: @range(<reset-args>)
#    When attribute(name) set annotation: @range(<reset-args>)
#    Then attribute(name) get annotations contain: @range(<reset-args>)
#    Then attribute(name) get annotations do not contain: @range(<init-args>)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then attribute(name) get annotations contain: @range(<reset-args>)
#    Then attribute(name) get annotations do not contain: @range(<init-args>)
#    When attribute(name) set annotation: @range(<init-args>)
#    Then attribute(name) get annotations contain: @range(<init-args>)
#    Then attribute(name) get annotations do not contain: @range(<reset-args>)
#    Examples:
#      | value-type | init-args                        | reset-args                       |
#      | long       | 1, 5                             | 7, 9                             |
#      | double     | 1.1, 1.5                         | -8.0, 88.3                       |
#      | decimal    | -8.0, 88.3                       | 1.1, 1.5                         |
#      | string     | "S", "s"                         | "not s", "xxxxxxxxx"             |
#      | datetime   | 2024-05-05, 2024-05-06           | 2024-06-05, 2024-06-06           |
#      | datetimetz | 2024-05-05+0100, 2024-05-06+0100 | 2024-05-05+0100, 2024-05-07+0100 |
#      | duration   | P1Y, P2Y                         | P1Y6M, P2Y                       |
#
#  Scenario: Attribute type cannot reset inherited @range annotation
#    When create attribute type: name
#    When attribute(name) set annotation: @abstract
#    When attribute(name) set annotation: @range("value", "value+1")
#    When attribute(name) set value type: string
#    When create attribute type: first-name
#    When attribute(first-name) set value type: string
#    When attribute(first-name) set supertype: name
#    Then attribute(first-name) get annotations contain: @range("value", "value+1")
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    When attribute(first-name) set annotation: @range("value", "value+1")
#    Then transaction commits; fails
#    When connection open schema transaction for database: typedb
#    When create attribute type: second-name
#    When attribute(second-name) set value type: string
#    When attribute(second-name) set supertype: name
#    Then attribute(second-name) get annotations contain: @range("value", "value+1")
#    When attribute(second-name) set annotation: @range("value", "value+1")
#    Then transaction commits; fails
#
#  Scenario: Attribute type cannot unset inherited @range annotation
#    When create attribute type: name
#    When attribute(name) set annotation: @abstract
#    When attribute(name) set annotation: @range("value", "value+1")
#    When attribute(name) set value type: string
#    When create attribute type: first-name
#    When attribute(first-name) set value type: string
#    When attribute(first-name) set supertype: name
#    Then attribute(first-name) get annotations contain: @range("value", "value+1")
#    Then attribute(first-name) unset annotation: @range("value", "value+1"); fail
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then attribute(first-name) get annotations contain: @range("value", "value+1")
#    Then attribute(first-name) unset annotation: @range("value", "value+1"); fail
#    Then attribute(first-name) unset supertype: name
#    Then attribute(first-name) get annotations do not contain: @range("value", "value+1")
#    When transaction commits
#    When connection open read transaction for database: typedb
#    Then attribute(first-name) get annotations do not contain: @range("value", "value+1")
#
#  Scenario Outline: Attribute types' @range annotation for <value-type> value type can be inherited and overridden by a subset of arguments
#    When create attribute type: name
#    When attribute(name) set value type: <value-type>
#    When create attribute type: overridden-name
#    When attribute(overridden-name) set value type: <value-type>
#    When attribute(overridden-name) set supertype: name
#    When attribute(name) set annotation: @range(<args>)
#    Then attribute(name) get annotations contain: @range(<args>)
#    Then attribute(overridden-name) get annotations contain: @range(<args>)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then attribute(name) get annotations contain: @range(<args>)
#    Then attribute(overridden-name) get annotations contain: @range(<args>)
#    When attribute(overridden-name) set annotation: @range(<args-override>)
#    Then attribute(name) get annotations contain: @range(<args>)
#    Then attribute(overridden-name) get annotations contain: @range(<args-override>)
#    When transaction commits
#    When connection open read transaction for database: typedb
#    Then attribute(name) get annotations contain: @range(<args>)
#    Then attribute(overridden-name) get annotations contain: @range(<args-override>)
#    Examples:
#      | value-type | args                             | args-override                             |
#      | long       | 1, 10                            | 1, 5                                      |
#      | double     | 1.0, 10.0                        | 2.0, 10.0                                 |
#      | decimal    | 0.0, 1.0                         | 0.0, 0.999999                             |
#      | string     | "A", "Z"                         | "J", "Z"                                  |
#      | datetime   | 2024-06-04, 2024-06-05           | 2024-06-04, 2024-06-04T12:00:00           |
#      | datetimetz | 2024-06-04+0010, 2024-06-05+0010 | 2024-06-04+0010, 2024-06-04T12:00:00+0010 |
#      | duration   | P6M, P1Y                         | P8M, P9M                                  |
#
#  Scenario Outline: Inherited @range annotation on attribute types for <value-type> value type cannot be overridden by the @range of not a subset of arguments
#    When create attribute type: name
#    When attribute(name) set value type: <value-type>
#    When create attribute type: overridden-name
#    When attribute(overridden-name) set value type: <value-type>
#    When attribute(overridden-name) set supertype: name
#    When attribute(name) set annotation: @range(<args>)
#    Then attribute(name) get annotations contain: @range(<args>)
#    Then attribute(overridden-name) get annotations contain: @range(<args>)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then attribute(name) get annotations contain: @range(<args>)
#    Then attribute(overridden-name) get annotations contain: @range(<args>)
#    Then attribute(overridden-name) set annotation: @range(<args-override>); fails
#    Then attribute(name) get annotations contain: @range(<args>)
#    Then attribute(overridden-name) get annotations contain: @range(<args>)
#    When transaction commits
#    When connection open read transaction for database: typedb
#    Then attribute(name) get annotations contain: @range(<args>)
#    Then attribute(overridden-name) get annotations contain: @range(<args>)
#    Examples:
#      | value-type | args                             | args-override                             |
#      | long       | 1, 10                            | -1, 5                                     |
#      | double     | 1.0, 10.0                        | 0.0, 150.0                                |
#      | decimal    | 0.0, 1.0                         | -0.0001, 0.999999                         |
#      | string     | "A", "Z"                         | "A", "z"                                  |
#      | datetime   | 2024-06-04, 2024-06-05           | 2023-06-04, 2024-06-04T12:00:00           |
#      | datetimetz | 2024-06-04+0010, 2024-06-05+0010 | 2024-06-04+0010, 2024-06-05T01:00:00+0010 |
#      | duration   | P6M, P1Y                         | P8M, P1Y1D                                |

########################
# not compatible @annotations: @distinct, @key, @unique, @subkey, @card, @cascade, @replace
########################

  #  TODO: Make it only for typeql
#  Scenario Outline: Attribute type of <value-type> value type cannot have @distinct, @key, @unique, @subkey, @card, @cascade, and @replace annotations
#    When create attribute type: email
#    When attribute(email) set value type: <value-type>
#    Then attribute(email) set annotation: @distinct; fails
#    Then attribute(email) set annotation: @key; fails
#    Then attribute(email) set annotation: @unique; fails
#    Then attribute(email) set annotation: @subkey(LABEL); fails
#    Then attribute(email) set annotation: @card(1, 2); fails
#    Then attribute(email) set annotation: @cascade; fails
#    Then attribute(email) set annotation: @replace; fails
#    Then attribute(email) get annotations is empty
#    When transaction commits
#    When connection open read transaction for database: typedb
#    Then attribute(email) get annotations is empty
#    Examples:
#      | value-type    |
#      | long          |
#      | double        |
#      | decimal       |
#      | string        |
#      | boolean       |
#      | datetime      |
#      | datetimetz    |
#      | duration      |
#      | custom-struct |

########################
# @annotations combinations:
# @abstract, @independent, @values, @range, @regex
########################

  Scenario Outline: Attribute type can set @<annotation-1> and @<annotation-2> together and unset it for <value-type> value type
    When create attribute type: name
    When attribute(name) set value type: <value-type>
    When attribute(name) set annotation: @<annotation-1>
    When attribute(name) set annotation: @<annotation-2>
    When attribute(name) get annotations contain: @<annotation-1>
    When attribute(name) get annotations contain: @<annotation-2>
    When transaction commits
    When connection open schema transaction for database: typedb
    When attribute(name) get annotations contain: @<annotation-1>
    When attribute(name) get annotations contain: @<annotation-2>
    When attribute(name) unset annotation: @<annotation-1>
    Then attribute(name) get annotations do not contain: @<annotation-1>
    Then attribute(name) get annotations contain: @<annotation-2>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(name) get annotations do not contain: @<annotation-1>
    Then attribute(name) get annotations contain: @<annotation-2>
    When attribute(name) set annotation: @<annotation-1>
    When attribute(name) unset annotation: @<annotation-2>
    Then attribute(name) get annotations do not contain: @<annotation-2>
    Then attribute(name) get annotations contain: @<annotation-1>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(name) get annotations do not contain: @<annotation-2>
    Then attribute(name) get annotations contain: @<annotation-1>
    When attribute(name) unset annotation: @<annotation-1>
    Then attribute(name) get annotations is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(name) get annotations is empty
    Examples:
    # TODO: Move to "cannot" test if something is wrong here.
      | annotation-1 | annotation-2 | value-type |
      | abstract     | independent  | datetimetz |
#      | abstract     | values(1, 2)       | double     |
#      | abstract     | range(1.0, 2.0)    | decimal    |
      | abstract     | regex("s")   | string     |
#      | independent  | values(1, 2)       | long       |
#      | independent  | range(false, true) | boolean    |
      | independent  | regex("s")   | string     |

  Scenario Outline: Owns cannot set @<annotation-1> and @<annotation-2> together for <value-type> value type
    When create attribute type: name
    When attribute(name) set value type: <value-type>
    When transaction commits
    When connection open schema transaction for database: typedb
    When attribute(name) set annotation: @<annotation-1>
    Then attribute(name) set annotation: @<annotation-2>; fails
    When connection open schema transaction for database: typedb
    When attribute(name) set annotation: @<annotation-2>
    Then attribute(name) set annotation: @<annotation-1>; fails
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(name) get annotations contain    : @<annotation-2>
    Then attribute(name) get annotation do not contain: @<annotation-1>
    Examples:
    # TODO: Move to "can" test if something is wrong here.
      | annotation-1 | annotation-2 | value-type |
      # TODO: If we allow values + range, write a test to check args compatibility!
#      | values(1.0, 2.0) | range(1.0, 2.0) | double     |
      # TODO: If we allow values + regex, write a test to check args compatibility!
#      | values("str")    | regex("s")      | string     |
      # TODO: If we allow range + regex, write a test to check args compatibility!
#      | range("1", "2")  | regex("s")      | string     |

########################
# structs common
########################

  Scenario Outline: Struct can be created with one field, including another struct
    When create struct type: passport
    Then struct(passport) exists
    Then struct(passport) get fields do not contain: name
    When struct(passport) create field: name, with value type: <value-type>
    Then struct(passport) get fields contain: name
    Then struct(passport) get field(name) get value type: <value-type>
    When transaction commits
    When connection open read transaction for database: typedb
    Then struct(passport) get fields contain: name
    Then struct(passport) get field(name) get value type: <value-type>
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

  Scenario Outline: Struct can be created with multiple fields, including another struct
    When create struct type: passport
    Then struct(passport) exists
    When struct(passport) create field: id, with value type: <value-type-1>
    When struct(passport) create field: name, with value type: <value-type-2>
    Then struct(passport) get fields contain: name
    When transaction commits
    When connection open read transaction for database: typedb
    Then struct(passport) get fields contain: id
    Then struct(passport) get field(id) get value type: <value-type-1>
    Then struct(passport) get fields contain: name
    Then struct(passport) get field(name) get value type: <value-type-2>
    Examples:
      | value-type-1  | value-type-2  |
      | long          | string        |
      | string        | boolean       |
      | boolean       | double        |
      | double        | decimal       |
      | decimal       | datetime      |
      | datetime      | datetimetz    |
      | datetimetz    | duration      |
      | duration      | custom-struct |
      | custom-struct | long          |
