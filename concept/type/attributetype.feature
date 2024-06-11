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

    # TODO: Create structs in concept api
    Given put struct type: custom-struct
    Given struct(custom-struct) create field: custom-field
    Given struct(custom-struct) get field(custom-field); set value-type: string

    Given transaction commits
    Given connection open schema transaction for database: typedb

########################
# attribute type common
########################

  Scenario: Root attribute type cannot be deleted
    Then delete attribute type: attribute; fails

  Scenario Outline: Attribute types can be created with <value-type> value type
    When put attribute type: name
    When attribute(name) set value-type: <value-type>
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

  Scenario: Attribute types can be created with a struct as value type
    # TODO: Create structs in concept api
    When put struct type: multi-name
    When struct(multi-name) create field: first-name
    When struct(multi-name) get field(first-name); set value-type: string
    When struct(multi-name) create field: second-name
    When struct(multi-name) get field(second-name); set value-type: string
    When put attribute type: full-name
    When attribute(full-name) set value-type: multi-name
    Then attribute(full-name) exists
    Then attribute(full-name) get supertype: attribute
    Then attribute(full-name) get value type: multi-name
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(full-name) exists
    Then attribute(full-name) get supertype: attribute
    Then attribute(full-name) get value type: multi-name

  Scenario Outline: Attribute types can be deleted
    When put attribute type: name
    When attribute(name) set value-type: <value-type-1>
    Then attribute(name) exists
    When put attribute type: age
    When attribute(age) set value-type: <value-type-2>
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

  Scenario: Attribute types that have instances cannot be deleted
    When put attribute type: name
    When attribute(name) set value-type: string
    When transaction commits
    When connection open write transaction for database: typedb
    When $x = attribute(name) put: alice
    When transaction commits
    When connection open schema transaction for database: typedb
    Then delete attribute type: name; fails

  Scenario: Attribute types can change labels
    When put attribute type: name
    When attribute(name) set value-type: string
    Then attribute(name) get label: name
    When attribute(name) set label: username
    Then attribute(name) does not exist
    Then attribute(username) exists
    Then attribute(username) get label: username
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(username) get label: username
    When attribute(username) set label: email
    Then attribute(username) does not exist
    Then attribute(email) exists
    Then attribute(email) get label: email
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(email) exists
    Then attribute(email) get label: email

  Scenario: Attribute types cannot subtype itself
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
#    When put attribute type: is-open
#    When attribute(is-open) set value-type: boolean
#    When put attribute type: age
#    When attribute(age) set value-type: long
#    When put attribute type: rating
#    When attribute(rating) set value-type: double
#    When put attribute type: name
#    When attribute(name) set value-type: string
#    When put attribute type: timestamp
#    When attribute(timestamp) set value-type: datetime
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
#    When put attribute type: is-open
#    When attribute(is-open) set value-type: boolean
#    When put attribute type: age
#    When attribute(age) set value-type: long
#    When put attribute type: rating
#    When attribute(rating) set value-type: double
#    When put attribute type: name
#    When attribute(name) set value-type: string
#    When put attribute type: timestamp
#    When attribute(timestamp) set value-type: datetime
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

  Scenario Outline: Attribute type cannot unset @<annotation> that has not been set
    When put attribute type: name
    When attribute(name) set value-type: string
    Then attribute(name) unset annotation: @<annotation>; fails
    Examples:
      | annotation      |
      | abstract        |
      | regex("\S+")    |
      | independent     |
      | values("1")     |
      | range("1", "3") |

########################
# @abstract
########################

  Scenario: Attribute types can be set to abstract
    When put attribute type: name
    When attribute(name) set value-type: string
    When attribute(name) set annotation: @abstract
    Then attribute(name) get annotations contain: @abstract
    When transaction commits
    When connection open schema transaction for database: typedb
    When put attribute type: email
    When attribute(email) set value-type: string
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
    When put attribute type: company-email
    When attribute(company-email) set value-type: string
    When attribute(company-email) set supertype: email
    Then attribute(email) unset annotation: @abstract; fails

  Scenario: Attribute types can be subtypes of other attribute types
    When put attribute type: first-name
    When attribute(first-name) set value-type: string
    When put attribute type: last-name
    When attribute(last-name) set value-type: string
    When put attribute type: real-name
    When attribute(real-name) set value-type: string
    When put attribute type: username
    When attribute(username) set value-type: string
    When put attribute type: name
    When attribute(name) set value-type: string
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
    When put attribute type: name
    When attribute(name) set value-type: string
    When put attribute type: first-name
    When attribute(first-name) set value-type: string
    When put attribute type: last-name
    When attribute(last-name) set value-type: string
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(first-name) set supertype: name; fails
    When connection open schema transaction for database: typedb
    Then attribute(last-name) set supertype: name; fails

  Scenario: Attribute type cannot set @abstract annotation with arguments
    When put attribute type: name
    When attribute(name) set value-type: string
    Then attribute(name) set annotation: @abstract(); fails
    Then attribute(name) set annotation: @abstract(1); fails
    Then attribute(name) set annotation: @abstract(1, 2); fails
    Then attribute(name) get annotations is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(name) get annotations is empty

########################
# @regex
########################

  Scenario Outline: Attribute types with <value-type> value type can set @regex annotation and unset it
    When put attribute type: email
    When attribute(email) set value-type: <value-type>
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

  Scenario Outline: Attribute types with incompatible value types can't have @regex annotation
    When put attribute type: email
    When attribute(email) set value-type: <value-type>
    Then attribute(email) set annotation: @regex(<arg>); fails
    Then attribute(email) get annotations is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(email) set annotation: @regex(<arg>); fails
    Then attribute(email) get annotations is empty
    Examples:
      | value-type    | arg     |
      | long          | "value" |
      | boolean       | "value" |
      | double        | "value" |
      | decimal       | "value" |
      | datetime      | "value" |
      | datetimetz    | "value" |
      | duration      | "value" |
      | custom-struct | "value" |

  Scenario: Attribute types' @regex annotation can be inherited
    When put attribute type: name
    When attribute(name) set value-type: string
    When attribute(name) set annotation: @abstract
    When attribute(name) set annotation: @regex("value")
    When put attribute type: first-name
    When attribute(first-name) set value-type: string
    When attribute(first-name) set supertype: name
    Then attribute(first-name) get annotations contain: @regex("value")
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(first-name) get annotations contain: @regex("value")

  Scenario: Attribute type cannot set @regex annotation with wring arguments
    When put attribute type: name
    When attribute(name) set value-type: string
    Then attribute(name) set annotation: @regex; fails
    Then attribute(name) set annotation: @regex(); fails
    Then attribute(name) set annotation: @regex(1); fails
    Then attribute(name) set annotation: @regex(1, 2); fails
    Then attribute(name) set annotation: @regex("val1", "val2"); fails
    Then attribute(name) get annotations is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(name) get annotations is empty

  Scenario: Attribute type cannot set @regex annotation with wrong arguments
    When put attribute type: name
    When attribute(name) set value-type: string
    Then attribute(name) set annotation: @regex; fails
    Then attribute(name) set annotation: @regex(); fails
    Then attribute(name) set annotation: @regex(1); fails
    Then attribute(name) set annotation: @regex(1, 2); fails
    Then attribute(name) set annotation: @regex("val1", "val2"); fails
    Then attribute(name) get annotations is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(name) get annotations is empty

  Scenario Outline: Attribute type cannot set multiple @regex annotations with different arguments
    When put attribute type: name
    When attribute(name) set value-type: string
    When attribute(name) set annotation: @regex("\S+")
    Then attribute(name) set annotation: @regex("\S+")
    Then attribute(name) set annotation: @regex(<fail-args>); fails
    Then attribute(name) get annotations contain: @regex("\S+")
    Then attribute(name) get annotations do not contain: @regex(<fail-args>)
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(name) get annotations contain: @regex("\S+")
    Then attribute(name) get annotations do not contain: @regex(<fail-args>)
    Examples:
      | fail-args       |
      | "\S"            |
      | "S+"            |
      | "*"             |
      | "s"             |
      | " some string " |

  Scenario: Attribute type cannot override inherited @regex annotation
    When put attribute type: name
    When attribute(name) set value-type: string
    When put attribute type: first-name
    When attribute(name) set annotation: @regex("\S+")
    Then attribute(name) get annotations contains: @regex("\S+")
    Then attribute(first-name) get annotations is empty
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(name) get annotations contains: @regex("\S+")
    Then attribute(first-name) get annotations is empty
    When attribute(first-name) set supertype: name
    Then attribute(first-name) get annotations contains: @regex("\S+")
    Then attribute(first-name) set annotation: @regex("\S+"); fails
    Then attribute(first-name) set annotation: @regex("test"); fails
    When connection open schema transaction for database: typedb
    Then attribute(name) get annotations contains: @regex("\S+")
    Then attribute(first-name) get annotations is empty
    When attribute(first-name) set annotation: @regex("\S+")
    Then attribute(first-name) get annotation contains: @regex("\S+")
    Then attribute(first-name) set supertype: name; fails
    When attribute(first-name) unset annotation: @regex("\S+")
    When attribute(first-name) set supertype: name
    Then attribute(first-name) get annotation contains: @regex("\S+")
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(name) get annotation contains: @regex("\S+")
    Then attribute(first-name) get annotation contains: @regex("\S+")

########################
# @independent
########################
    # TODO: Implement

########################
# @values
########################
    # TODO: Implement

########################
# @range
########################
    # TODO: Implement

########################
# not compatible @annotations: @distinct, @key, @unique, @subkey, @card, @cascade, @replace
########################

  Scenario Outline: Attribute type of <value-type> value type cannot have @distinct, @key, @unique, @subkey, @card, @cascade, and @replace annotations
    When put attribute type: email
    When attribute(email) set value-type: <value-type>
    Then attribute(email) set annotation: @distinct; fails
    Then attribute(email) set annotation: @key; fails
    Then attribute(email) set annotation: @unique; fails
    Then attribute(email) set annotation: @subkey; fails
    Then attribute(email) set annotation: @subkey(LABEL); fails
    Then attribute(email) set annotation: @card; fails
    Then attribute(email) set annotation: @card(1, 2); fails
    Then attribute(email) set annotation: @cascade; fails
    Then attribute(email) set annotation: @replace; fails
    Then attribute(email) set annotation: @does-not-exist; fails
    Then attribute(email) get annotations is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(email) get annotations is empty
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
