# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: Concept Attribute Type

  Background:
    Given typedb starts
    Given connection opens with default authentication
    Given connection is open: true
    Given connection reset database: typedb
    Given connection open schema transaction for database: typedb

    Given create struct: custom-struct
    Given struct(custom-struct) create field: custom-field, with value type: string
    Given create struct: custom-struct-2
    Given struct(custom-struct-2) create field: custom-field-2, with value type: string

    Given transaction commits
    Given connection open schema transaction for database: typedb

########################
# attribute type common
########################

  Scenario: Cyclic attribute type hierarchies are disallowed
    When create attribute type: attr0
    When attribute(attr0) set value type: string
    When create attribute type: attr1
    When attribute(attr0) set annotation: @abstract
    When attribute(attr1) set annotation: @abstract
    When attribute(attr1) set supertype: attr0
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(attr1) set supertype: attr1; fails
    Then attribute(attr0) set supertype: attr1; fails

  Scenario Outline: Attribute types can be created with <value-type> value type
    When create attribute type: name
    When attribute(name) set value type: <value-type>
    Then attribute(name) exists
    Then attribute(name) get supertype does not exist
    Then attribute(name) get value type: <value-type>
    Then attribute(name) get value type declared: <value-type>
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(name) exists
    Then attribute(name) get supertype does not exist
    Then attribute(name) get value type: <value-type>
    Then attribute(name) get value type declared: <value-type>
    Examples:
      | value-type  |
      | integer     |
      | string      |
      | boolean     |
      | double      |
      | decimal     |
      | date        |
      | datetime    |
      | datetime-tz |
      | duration    |

  Scenario: Attribute types can be created with a struct as value type
    When create struct: multi-name
    When struct(multi-name) create field: first-name, with value type: string
    When struct(multi-name) create field: second-name, with value type: string
    When create attribute type: full-name
    When attribute(full-name) set value type: multi-name
    Then attribute(full-name) exists
    Then attribute(full-name) get supertype does not exist
    Then attribute(full-name) get value type: multi-name
    Then attribute(full-name) get value type declared: multi-name
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(full-name) exists
    Then attribute(full-name) get supertype does not exist
    Then attribute(full-name) get value type: multi-name
    Then attribute(full-name) get value type declared: multi-name

  Scenario Outline: Attribute types cannot be recreated with <value-type> value type
    When create attribute type: name
    When attribute(name) set value type: <value-type>
    Then attribute(name) exists
    Then create attribute type: name; fails
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(name) exists
    Then create attribute type: name; fails
    Examples:
      | value-type    |
      | integer       |
      | string        |
      | boolean       |
      | double        |
      | decimal       |
      | date          |
      | datetime      |
      | datetime-tz   |
      | duration      |
      | custom-struct |

  Scenario: Attribute types cannot be created without value types
    When create attribute type: name
    Then attribute(name) exists
    Then attribute(name) get value type declared is none
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
    Then get attribute types do not contain:
      | age |
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(name) exists
    Then attribute(age) does not exist
    Then get attribute types do not contain:
      | age |
    When delete attribute type: name
    Then attribute(name) does not exist
    Then get attribute types do not contain:
      | name |
      | age  |
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(name) does not exist
    Then attribute(age) does not exist
    Then get attribute types do not contain:
      | name |
      | age  |
    Examples:
      | value-type-1 | value-type-2 |
      | string       | integer      |
      | boolean      | double       |
      | decimal      | datetime-tz  |
      | datetime     | duration     |

  Scenario: Attribute types can have absent supertypes
    When create attribute type: is-open
    When attribute(is-open) set value type: boolean
    When create attribute type: age
    When attribute(age) set value type: integer
    When create attribute type: rating
    When attribute(rating) set value type: double
    When create attribute type: name
    When attribute(name) set value type: string
    When create attribute type: timestamp
    When attribute(timestamp) set value type: datetime
    Then attribute(is-open) get supertype does not exist
    Then attribute(age) get supertype does not exist
    Then attribute(rating) get supertype does not exist
    Then attribute(name) get supertype does not exist
    Then attribute(timestamp) get supertype does not exist
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(is-open) get supertype does not exist
    Then attribute(age) get supertype does not exist
    Then attribute(rating) get supertype does not exist
    Then attribute(name) get supertype does not exist
    Then attribute(timestamp) get supertype does not exist

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
    When attribute(age) set value type: integer
    When create attribute type: rating
    When attribute(rating) set value type: double
    When create attribute type: name
    When attribute(name) set value type: string
    When create attribute type: timestamp
    When attribute(timestamp) set value type: datetime
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(is-open) set supertype: is-open; fails
    Then attribute(age) set supertype: age; fails
    Then attribute(rating) set supertype: rating; fails
    Then attribute(name) set supertype: name; fails
    Then attribute(timestamp) set supertype: timestamp; fails

########################
# @annotations common
########################

  Scenario Outline: Attribute type can set and unset @<annotation>
    When create attribute type: name
    When attribute(name) set value type: <value-type>
    When attribute(name) set annotation: @<annotation>
    Then attribute(name) get constraints contain: @<annotation>
    Then attribute(name) get constraint categories contain: @<annotation-category>
    Then attribute(name) get declared annotations contain: @<annotation>
    When attribute(name) unset annotation: @<annotation-category>
    Then attribute(name) get constraints do not contain: @<annotation>
    Then attribute(name) get constraint categories do not contain: @<annotation-category>
    Then attribute(name) get declared annotations do not contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(name) get constraints do not contain: @<annotation>
    Then attribute(name) get constraint categories do not contain: @<annotation-category>
    Then attribute(name) get declared annotations do not contain: @<annotation>
    When attribute(name) set annotation: @<annotation>
    Then attribute(name) get constraints contain: @<annotation>
    Then attribute(name) get constraint categories contain: @<annotation-category>
    Then attribute(name) get declared annotations contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(name) get constraints contain: @<annotation>
    Then attribute(name) get constraint categories contain: @<annotation-category>
    Then attribute(name) get declared annotations contain: @<annotation>
    Examples:
      | value-type  | annotation                              | annotation-category |
      | integer     | abstract                                | abstract            |
      | integer     | independent                             | independent         |
      | integer     | values(1)                               | values              |
      | integer     | range(1..3)                             | range               |
      | string      | abstract                                | abstract            |
      | string      | independent                             | independent         |
      | string      | regex("\S+")                            | regex               |
      | string      | values("1")                             | values              |
      | string      | range("1".."3")                         | range               |
      | boolean     | abstract                                | abstract            |
      | boolean     | independent                             | independent         |
      | boolean     | values(true)                            | values              |
      | boolean     | range(false..true)                      | range               |
      | double      | abstract                                | abstract            |
      | double      | independent                             | independent         |
      | double      | values(1.0)                             | values              |
      | double      | range(1.0..3.0)                         | range               |
      | decimal     | abstract                                | abstract            |
      | decimal     | independent                             | independent         |
      | decimal     | values(1.0dec)                          | values              |
      | decimal     | range(1.0dec..3.0dec)                   | range               |
      | date        | abstract                                | abstract            |
      | date        | independent                             | independent         |
      | datetime    | abstract                                | abstract            |
      | datetime    | independent                             | independent         |
      | datetime    | values(2024-05-06)                      | values              |
      | datetime    | range(2024-05-06..2024-05-07)           | range               |
      | datetime-tz | abstract                                | abstract            |
      | datetime-tz | independent                             | independent         |
      | datetime-tz | values(2024-05-06+0010)                 | values              |
      | datetime-tz | range(2024-05-06+0100..2024-05-07+0100) | range               |
      | duration    | abstract                                | abstract            |
      | duration    | independent                             | independent         |
      | duration    | values(P1Y)                             | values              |

  Scenario Outline: Attribute type can unset not set @<annotation>
    When create attribute type: name
    When attribute(name) set value type: string
    Then attribute(name) get constraints do not contain: @<annotation>
    When attribute(name) unset annotation: @<annotation-category>
    Then attribute(name) get constraints do not contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(name) get constraints do not contain: @<annotation>
    When attribute(name) unset annotation: @<annotation-category>
    Then attribute(name) get constraints do not contain: @<annotation>
    Examples:
      | annotation      | annotation-category |
      | abstract        | abstract            |
      | independent     | independent         |
      | regex("\S+")    | regex               |
      | values("1")     | values              |
      | range("1".."3") | range               |

  Scenario Outline: Attribute type cannot set or unset inherited @<annotation>
    When create attribute type: name
    When attribute(name) set value type: <value-type>
    When attribute(name) set annotation: @abstract
    When attribute(name) set annotation: @<annotation>
    When create attribute type: surname
    When attribute(surname) set supertype: name
    Then attribute(name) get constraints contain: @<annotation>
    Then attribute(name) get declared annotations contain: @<annotation>
    Then attribute(surname) get constraints contain: @<annotation>
    Then attribute(surname) get declared annotations do not contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(name) get constraints contain: @<annotation>
    Then attribute(name) get declared annotations contain: @<annotation>
    Then attribute(surname) get constraints contain: @<annotation>
    Then attribute(surname) get declared annotations do not contain: @<annotation>
    When attribute(surname) set annotation: @<annotation>
    Then transaction commits; fails
    When connection open schema transaction for database: typedb
    Then attribute(name) get constraints contain: @<annotation>
    Then attribute(name) get declared annotations contain: @<annotation>
    Then attribute(surname) get constraints contain: @<annotation>
    Then attribute(surname) get declared annotations do not contain: @<annotation>
    When attribute(surname) unset annotation: @<annotation-category>
    Then attribute(name) get constraints contain: @<annotation>
    Then attribute(name) get declared annotations contain: @<annotation>
    Then attribute(surname) get constraints contain: @<annotation>
    Then attribute(surname) get declared annotations do not contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(name) get constraints contain: @<annotation>
    Then attribute(name) get declared annotations contain: @<annotation>
    Then attribute(surname) get constraints contain: @<annotation>
    Then attribute(surname) get declared annotations do not contain: @<annotation>
    Examples:
      | value-type | annotation   | annotation-category |
      # abstract is not inherited
      | decimal    | independent  | independent         |
      | string     | regex("\S+") | regex               |
      | string     | values("1")  | values              |
      | integer    | range(1..3)  | range               |

  Scenario Outline: Attribute type cannot set supertype with the same @<annotation> until it is explicitly unset from type
    When create attribute type: name
    When attribute(name) set value type: <value-type>
    When attribute(name) set annotation: @abstract
    When attribute(name) set annotation: @<annotation>
    Then attribute(name) get constraints contain: @<annotation>
    Then attribute(name) get declared annotations contain: @<annotation>
    When create attribute type: surname
    When attribute(surname) set value type: <value-type>
    When attribute(surname) set annotation: @<annotation>
    Then attribute(surname) get constraints contain: @<annotation>
    Then attribute(surname) get declared annotations contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(name) get constraints contain: @<annotation>
    Then attribute(name) get declared annotations contain: @<annotation>
    Then attribute(surname) get constraints contain: @<annotation>
    Then attribute(surname) get declared annotations contain: @<annotation>
    When attribute(surname) set supertype: name
    Then attribute(name) get constraints contain: @<annotation>
    Then attribute(name) get declared annotations contain: @<annotation>
    Then attribute(surname) get constraints contain: @<annotation>
    Then attribute(surname) get declared annotations contain: @<annotation>
    Then transaction commits; fails
    When connection open schema transaction for database: typedb
    Then attribute(name) get constraints contain: @<annotation>
    Then attribute(name) get declared annotations contain: @<annotation>
    Then attribute(surname) get constraints contain: @<annotation>
    Then attribute(surname) get declared annotations contain: @<annotation>
    When attribute(surname) set supertype: name
    When attribute(surname) unset annotation: @<annotation-category>
    When attribute(surname) unset value type
    Then attribute(surname) get constraints contain: @<annotation>
    Then attribute(surname) get declared annotations do not contain: @<annotation>
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(name) get constraints contain: @<annotation>
    Then attribute(name) get declared annotations contain: @<annotation>
    Then attribute(surname) get constraints contain: @<annotation>
    Then attribute(surname) get declared annotations do not contain: @<annotation>
    Examples:
      | value-type | annotation   | annotation-category |
      # abstract is not inherited
      | decimal    | independent  | independent         |
      | string     | regex("\S+") | regex               |
      | string     | values("1")  | values              |
      | integer    | range(1..3)  | range               |

  Scenario Outline: Attribute type loses inherited @<annotation> if supertype is unset
    When create attribute type: name
    When attribute(name) set value type: <value-type>
    When attribute(name) set annotation: @abstract
    When attribute(name) set annotation: @<annotation>
    When create attribute type: surname
    When attribute(surname) set supertype: name
    Then attribute(name) get constraints contain: @<annotation>
    Then attribute(name) get declared annotations contain: @<annotation>
    Then attribute(surname) get constraints contain: @<annotation>
    Then attribute(surname) get declared annotations do not contain: @<annotation>
    Then attribute(surname) unset supertype; fails
    When attribute(surname) set annotation: @abstract
    When attribute(surname) unset supertype
    When attribute(surname) set value type: <value-type>
    Then attribute(name) get constraints contain: @<annotation>
    Then attribute(name) get declared annotations contain: @<annotation>
    Then attribute(surname) get constraints do not contain: @<annotation>
    Then attribute(surname) get declared annotations do not contain: @<annotation>
    When attribute(surname) set supertype: name
    When attribute(surname) unset value type
    Then attribute(name) get constraints contain: @<annotation>
    Then attribute(name) get declared annotations contain: @<annotation>
    Then attribute(surname) get constraints contain: @<annotation>
    Then attribute(surname) get declared annotations do not contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(name) get constraints contain: @<annotation>
    Then attribute(name) get declared annotations contain: @<annotation>
    Then attribute(surname) get constraints contain: @<annotation>
    Then attribute(surname) get declared annotations do not contain: @<annotation>
    When attribute(surname) unset supertype
    When attribute(surname) set value type: <value-type>
    Then attribute(name) get constraints contain: @<annotation>
    Then attribute(name) get declared annotations contain: @<annotation>
    Then attribute(surname) get constraints do not contain: @<annotation>
    Then attribute(surname) get declared annotations do not contain: @<annotation>
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(name) get constraints contain: @<annotation>
    Then attribute(name) get declared annotations contain: @<annotation>
    Then attribute(surname) get constraints do not contain: @<annotation>
    Then attribute(surname) get declared annotations do not contain: @<annotation>
    Examples:
      | value-type | annotation   |
      # abstract is not inherited
      | decimal    | independent  |
      | string     | regex("\S+") |
      | string     | values("1")  |
      | integer    | range(1..3)  |

  Scenario Outline: Attribute type cannot set redundant duplicated @<annotation> while inheriting it
    When create attribute type: name
    When attribute(name) set value type: <value-type>
    When attribute(name) set annotation: @abstract
    When attribute(name) set annotation: @<annotation>
    When create attribute type: surname
    When attribute(surname) set supertype: name
    When transaction commits
    When connection open schema transaction for database: typedb
    When attribute(surname) set annotation: @<annotation>
    Then transaction commits; fails
    When connection open schema transaction for database: typedb
    When attribute(surname) set annotation: @<annotation>
    When attribute(name) unset annotation: @<annotation-category>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(name) get constraints do not contain: @<annotation>
    Then attribute(surname) get constraints contain: @<annotation>
    When attribute(name) set annotation: @<annotation>
    Then transaction commits; fails
    Examples:
      | value-type | annotation   | annotation-category |
      # abstract is not inherited
      | decimal    | independent  | independent         |
      | string     | regex("\S+") | regex               |
      | string     | values("1")  | values              |
      | integer    | range(1..3)  | range               |

########################
# @abstract
########################

  Scenario: Attribute types can be set to abstract
    When create attribute type: name
    When attribute(name) set value type: string
    When attribute(name) set annotation: @abstract
    Then attribute(name) get constraints contain: @abstract
    Then attribute(name) get declared annotations contain: @abstract
    When transaction commits
    When connection open schema transaction for database: typedb
    When create attribute type: email
    Then attribute(email) get constraints do not contain: @abstract
    Then attribute(email) get declared annotations do not contain: @abstract
    Then transaction commits; fails
    When connection open schema transaction for database: typedb
    When create attribute type: email
    When attribute(email) set value type: string
    Then attribute(email) get constraints do not contain: @abstract
    Then attribute(email) get declared annotations do not contain: @abstract
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(name) get constraints contain: @abstract
    Then attribute(name) get declared annotations contain: @abstract
    When transaction closes
    When connection open schema transaction for database: typedb
    Then attribute(email) get constraints do not contain: @abstract
    Then attribute(email) get declared annotations do not contain: @abstract
    When attribute(email) set annotation: @abstract
    Then attribute(email) get constraints contain: @abstract
    Then attribute(email) get declared annotations contain: @abstract
    When transaction commits
    When connection open schema transaction for database: typedb
    When create attribute type: company-email
    When attribute(company-email) set supertype: email
    Then attribute(email) unset annotation: @abstract; fails
    When transaction closes
    When connection open schema transaction for database: typedb
    When attribute(email) unset value type
    When transaction commits
    When connection open schema transaction for database: typedb
    When create attribute type: company-email
    When attribute(company-email) set supertype: email
    Then attribute(email) unset annotation: @abstract; fails

  Scenario: Attribute types can be created without value types with @abstract annotation
    When create attribute type: name
    Then attribute(name) exists
    When attribute(name) set annotation: @abstract
    Then attribute(name) exists
    Then attribute(name) get value type is none
    Then attribute(name) get constraints contain: @abstract
    Then attribute(name) get declared annotations contain: @abstract
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(name) exists
    Then attribute(name) get value type is none
    Then attribute(name) get constraints contain: @abstract
    Then attribute(name) get declared annotations contain: @abstract

  Scenario: Attribute types cannot unset value type without @abstract annotation if value type is not inherited
    When create attribute type: email
    When attribute(email) set value type: string
    Then attribute(email) get value type: string
    Then attribute(email) get constraints do not contain: @abstract
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(email) get value type: string
    Then attribute(email) unset value type; fails
    Then attribute(email) get value type: string

  Scenario: Attribute types can unset value type without @abstract annotation if value type is inherited
    When create attribute type: name
    When attribute(name) set value type: string
    When attribute(name) set annotation: @abstract
    When create attribute type: surname
    When attribute(surname) set supertype: name
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(surname) get value type: string
    Then attribute(surname) get value type declared is none
    When attribute(surname) set value type: string
    Then attribute(surname) get value type: string
    Then attribute(surname) get value type declared: string
    When attribute(surname) unset value type
    Then attribute(surname) get value type declared is none
    Then attribute(surname) unset value type; fails
    Then attribute(name) get value type: string
    Then attribute(name) get value type declared: string
    Then attribute(surname) get value type: string
    Then attribute(surname) get value type declared is none
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(surname) unset supertype; fails
    When attribute(surname) set annotation: @abstract
    When attribute(surname) unset supertype
    Then attribute(surname) get value type is none
    Then attribute(surname) get value type declared is none
    When transaction commits
    When connection open schema transaction for database: typedb
    When attribute(surname) set supertype: name
    Then attribute(surname) get value type: string
    Then attribute(surname) get value type declared is none
    Then attribute(surname) unset value type; fails
    Then attribute(surname) get value type: string
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(name) get value type: string
    Then attribute(name) get value type declared: string
    Then attribute(surname) get value type: string
    Then attribute(surname) get value type declared is none

  Scenario: Attribute types cannot unset value type if there are subtypes without @abstract annotation and value types
    When create attribute type: name
    When attribute(name) set value type: string
    When attribute(name) set annotation: @abstract
    When create attribute type: surname
    Then attribute(surname) get value type is none
    When attribute(surname) set supertype: name
    Then attribute(surname) get value type: string
    Then attribute(surname) get constraints do not contain: @abstract
    When transaction commits
    When connection open schema transaction for database: typedb
    When attribute(name) unset value type; fails
    When attribute(surname) set value type: string
    When attribute(name) unset value type
    Then attribute(surname) get value type: string
    Then attribute(name) get value type is none
    When transaction commits
    When connection open schema transaction for database: typedb
    When attribute(name) set value type: string
    When attribute(surname) unset value type
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(name) get value type: string
    Then attribute(surname) get value type: string
    When attribute(name) unset value type; fails
    When transaction closes
    When connection open schema transaction for database: typedb
    When attribute(surname) set annotation: @abstract
    Then attribute(surname) get value type: string
    When attribute(name) unset value type
    Then attribute(name) get value type is none
    Then attribute(surname) get value type is none
    Then attribute(name) get constraints contain: @abstract
    Then attribute(surname) get constraints contain: @abstract
    Then attribute(surname) get supertype: name
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(name) get value type is none
    Then attribute(surname) get value type is none

  Scenario: Attribute types cannot unset @abstract annotation without value type
    When create attribute type: email
    Then attribute(email) get value type is none
    When attribute(email) set annotation: @abstract
    Then attribute(email) get constraints contain: @abstract
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(email) get value type is none
    Then attribute(email) get constraints contain: @abstract
    Then attribute(email) unset annotation: @abstract; fails
    Then attribute(email) get value type is none
    Then attribute(email) get constraints contain: @abstract
    When attribute(email) set value type: string
    When attribute(email) unset annotation: @abstract
    Then attribute(email) get value type: string
    Then attribute(email) get constraints do not contain: @abstract
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(email) get value type: string
    Then attribute(email) get constraints do not contain: @abstract

  Scenario: Attribute types can unset value type (even not set) if it has @abstract annotation
    When create attribute type: name
    When attribute(name) set annotation: @abstract
    When create attribute type: email
    When attribute(email) set annotation: @abstract
    When attribute(email) set value type: string
    When create attribute type: birthday
    When attribute(birthday) set value type: datetime
    Then attribute(name) get value type is none
    Then attribute(email) get value type: string
    Then attribute(birthday) get value type: datetime
    Then attribute(name) get constraints contain: @abstract
    Then attribute(email) get constraints contain: @abstract
    Then attribute(birthday) get constraints do not contain: @abstract
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(name) get value type is none
    Then attribute(email) get value type: string
    Then attribute(birthday) get value type: datetime
    When attribute(name) unset value type
    When attribute(email) unset value type
    Then attribute(birthday) unset value type; fails
    When attribute(birthday) set annotation: @abstract
    When attribute(birthday) unset value type
    Then attribute(name) get value type is none
    Then attribute(email) get value type is none
    Then attribute(birthday) get value type is none
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(name) get value type is none
    Then attribute(email) get value type is none
    Then attribute(birthday) get value type is none

  Scenario: Attribute type cannot set value type without value type annotations specialization if it already inherits it
    When create attribute type: name
    When attribute(name) set value type: string
    When attribute(name) set annotation: @abstract
    Then attribute(name) get constraints contain: @abstract
    When transaction commits
    When connection open schema transaction for database: typedb
    When create attribute type: surname
    When attribute(surname) set supertype: name
    When attribute(surname) set value type: string
    Then transaction commits; fails
    When connection open schema transaction for database: typedb
    When create attribute type: surname
    When attribute(surname) set value type: string
    When attribute(surname) set supertype: name
    Then transaction commits; fails
    When connection open schema transaction for database: typedb
    When create attribute type: surname
    When attribute(surname) set supertype: name
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(name) get value type: string
    Then attribute(name) get value type declared: string
    Then attribute(surname) get value type: string
    Then attribute(surname) get value type declared is none

  Scenario Outline: Attribute type cannot set value type without value type annotations specialization if it already inherits it (has <annotation> specialization)
    When create attribute type: name
    When attribute(name) set value type: string
    When attribute(name) set annotation: @abstract
    Then attribute(name) get constraints contain: @abstract
    When transaction commits
    When connection open schema transaction for database: typedb
    When create attribute type: surname
    When attribute(surname) set supertype: name
    When attribute(surname) set annotation: @<annotation>
    When attribute(surname) set value type: string
    Then transaction commits; fails
    When connection open schema transaction for database: typedb
    When create attribute type: surname
    When attribute(surname) set value type: string
    When attribute(surname) set supertype: name
    When attribute(surname) set annotation: @<annotation>
    Then transaction commits; fails
    Examples:
      | annotation  |
      | abstract    |
      | independent |

  Scenario Outline: Attribute type can set value type if it already inherits it with value type @<annotation> specialization
    When create attribute type: name
    When attribute(name) set value type: string
    When attribute(name) set annotation: @abstract
    Then attribute(name) get constraints contain: @abstract
    When transaction commits
    When connection open schema transaction for database: typedb
    When create attribute type: surname
    When attribute(surname) set supertype: name
    When attribute(surname) set value type: string
    When attribute(surname) set annotation: @<annotation>
    Then transaction commits
    When connection open schema transaction for database: typedb
    When create attribute type: third-name
    When attribute(third-name) set value type: string
    When attribute(third-name) set annotation: @<annotation>
    When attribute(third-name) set supertype: name
    Then transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(name) get value type: string
    Then attribute(name) get value type declared: string
    Then attribute(surname) get value type: string
    Then attribute(surname) get value type declared: string
    Then attribute(third-name) get value type: string
    Then attribute(third-name) get value type declared: string
    Examples:
      | annotation      |
      | regex("str")    |
      | values("str")   |
      | range("1".."2") |

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
    Then attribute(name) get constraints contain: @abstract
    When attribute(name) set annotation: @abstract
    Then attribute(name) get constraints contain: @abstract
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(name) get constraints contain: @abstract

  Scenario Outline: Attribute type with value type <value-type-2> cannot subtype an attribute type with different value type <value-type-1>
    When create attribute type: name
    When attribute(name) set annotation: @abstract
    Then attribute(name) get constraints contain: @abstract
    When attribute(name) set value type: <value-type-1>
    When create attribute type: first-name
    When attribute(first-name) set value type: <value-type-2>
    Then attribute(first-name) set supertype: name; fails
    Then attribute(name) get value type: <value-type-1>
    Then attribute(first-name) get value type: <value-type-2>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(name) get value type: <value-type-1>
    Then attribute(first-name) get value type: <value-type-2>
    Then attribute(first-name) set supertype: name; fails
    Examples:
      | value-type-1  | value-type-2    |
      | integer       | string          |
      | integer       | boolean         |
      | integer       | double          |
      | integer       | decimal         |
      | integer       | date            |
      | integer       | datetime        |
      | integer       | datetime-tz     |
      | integer       | duration        |
      | integer       | custom-struct   |
      | string        | integer         |
      | boolean       | string          |
      | double        | datetime-tz     |
      | decimal       | datetime        |
      | date          | decimal         |
      | datetime      | date            |
      | datetime-tz   | double          |
      | duration      | boolean         |
      | custom-struct | integer         |
      | custom-struct | string          |
      | custom-struct | boolean         |
      | custom-struct | double          |
      | custom-struct | decimal         |
      | custom-struct | date            |
      | custom-struct | datetime        |
      | custom-struct | datetime-tz     |
      | custom-struct | custom-struct-2 |

  Scenario Outline: Attribute type subtyping an attribute type with value type <value-type-1> cannot set value type <value-type-2>
    When create attribute type: name
    When attribute(name) set annotation: @abstract
    Then attribute(name) get constraints contain: @abstract
    When attribute(name) set value type: <value-type-1>
    When create attribute type: first-name
    When attribute(first-name) set supertype: name
    Then attribute(first-name) get supertype: name
    Then attribute(first-name) get value type: <value-type-1>
    Then attribute(first-name) set value type: <value-type-2>; fails
    Then attribute(name) get value type: <value-type-1>
    Then attribute(first-name) get value type: <value-type-1>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(name) get value type: <value-type-1>
    Then attribute(first-name) get value type: <value-type-1>
    Then attribute(first-name) set value type: <value-type-2>; fails
    When attribute(name) set value type: <value-type-2>
    Then attribute(name) get value type: <value-type-2>
    Then attribute(first-name) get value type: <value-type-2>
    When transaction commits
    When connection open schema transaction for database: typedb
    When attribute(first-name) set value type: <value-type-2>
    When attribute(name) unset value type
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(name) get value type is none
    Then attribute(first-name) get value type: <value-type-2>
    Examples:
      | value-type-1  | value-type-2    |
      | integer       | string          |
      | integer       | boolean         |
      | integer       | double          |
      | integer       | decimal         |
      | integer       | date            |
      | integer       | datetime        |
      | integer       | datetime-tz     |
      | integer       | duration        |
      | integer       | custom-struct   |
      | string        | boolean         |
      | boolean       | string          |
      | double        | datetime        |
      | decimal       | datetime-tz     |
      | date          | decimal         |
      | datetime      | integer         |
      | datetime-tz   | double          |
      | duration      | date            |
      | custom-struct | integer         |
      | custom-struct | string          |
      | custom-struct | boolean         |
      | custom-struct | double          |
      | custom-struct | decimal         |
      | custom-struct | date            |
      | custom-struct | datetime        |
      | custom-struct | datetime-tz     |
      | custom-struct | custom-struct-2 |

  Scenario Outline: Supertype attribute type cannot set <value-type-2> conflicting with <value-type-1> set for one of subtypes
    When create attribute type: name
    When attribute(name) set annotation: @abstract
    Then attribute(name) get constraints contain: @abstract
    When create attribute type: first-name
    When attribute(first-name) set annotation: @abstract
    When attribute(first-name) set supertype: name
    When create attribute type: second-name
    When attribute(second-name) set annotation: @abstract
    When attribute(second-name) set supertype: name
    When create attribute type: sub-first-name
    When attribute(sub-first-name) set annotation: @abstract
    When attribute(sub-first-name) set supertype: first-name
    Then attribute(name) get value type is none
    Then attribute(first-name) get value type is none
    Then attribute(second-name) get value type is none
    Then attribute(sub-first-name) get value type is none
    When attribute(first-name) set value type: <value-type-1>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(name) set value type: <value-type-2>; fails
    When attribute(first-name) unset value type
    When attribute(second-name) set value type: <value-type-1>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(name) set value type: <value-type-2>; fails
    When attribute(second-name) unset value type
    When attribute(sub-first-name) set value type: <value-type-1>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(name) set value type: <value-type-2>; fails
    When attribute(sub-first-name) unset value type
    When transaction commits
    When connection open schema transaction for database: typedb
    When attribute(first-name) set value type: <value-type-1>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(name) set value type: <value-type-2>; fails
    When attribute(first-name) unset value type
    When attribute(second-name) set value type: <value-type-1>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(name) set value type: <value-type-2>; fails
    When attribute(second-name) unset value type
    When attribute(sub-first-name) set value type: <value-type-1>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(name) set value type: <value-type-2>; fails
    When attribute(sub-first-name) unset value type
    Then attribute(name) set value type: <value-type-2>
    Then attribute(first-name) get value type: <value-type-2>
    Then attribute(second-name) get value type: <value-type-2>
    Then attribute(sub-first-name) get value type: <value-type-2>
    When transaction commits
    When connection open schema transaction for database: typedb
    When attribute(name) set value type: <value-type-1>
    Then attribute(name) get value type: <value-type-1>
    Then attribute(first-name) get value type: <value-type-1>
    Then attribute(second-name) get value type: <value-type-1>
    Then attribute(sub-first-name) get value type: <value-type-1>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(name) get value type: <value-type-1>
    Then attribute(first-name) get value type: <value-type-1>
    Then attribute(second-name) get value type: <value-type-1>
    Then attribute(sub-first-name) get value type: <value-type-1>
    When attribute(name) unset value type
    Then attribute(name) get value type is none
    Then attribute(first-name) get value type is none
    Then attribute(second-name) get value type is none
    Then attribute(sub-first-name) get value type is none
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(name) get value type is none
    Then attribute(first-name) get value type is none
    Then attribute(second-name) get value type is none
    Then attribute(sub-first-name) get value type is none
    Examples:
      | value-type-1  | value-type-2    |
      | integer       | string          |
      | integer       | boolean         |
      | integer       | double          |
      | integer       | decimal         |
      | integer       | date            |
      | integer       | datetime        |
      | integer       | datetime-tz     |
      | integer       | duration        |
      | integer       | custom-struct   |
      | string        | datetime-tz     |
      | boolean       | date            |
      | double        | datetime        |
      | decimal       | double          |
      | date          | string          |
      | datetime      | integer         |
      | datetime-tz   | decimal         |
      | duration      | boolean         |
      | custom-struct | integer         |
      | custom-struct | string          |
      | custom-struct | boolean         |
      | custom-struct | double          |
      | custom-struct | decimal         |
      | custom-struct | date            |
      | custom-struct | datetime        |
      | custom-struct | datetime-tz     |
      | custom-struct | custom-struct-2 |

  Scenario Outline: Supertype attribute type can set <value-type> set for subtype, but subtype needs to explicitly unset it before commit
    When create attribute type: name
    When attribute(name) set annotation: @abstract
    Then attribute(name) get constraints contain: @abstract
    When create attribute type: first-name
    When attribute(first-name) set supertype: name
    When attribute(first-name) set value type: <value-type>
    Then attribute(name) get value type is none
    Then attribute(first-name) get value type: <value-type>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(name) get value type is none
    Then attribute(first-name) get value type: <value-type>
    When attribute(name) set value type: <value-type>
    Then attribute(name) get value type: <value-type>
    Then attribute(first-name) get value type: <value-type>
    Then transaction commits; fails
    When connection open schema transaction for database: typedb
    Then attribute(name) get value type is none
    Then attribute(first-name) get value type: <value-type>
    When attribute(name) set value type: <value-type>
    Then attribute(name) get value type: <value-type>
    Then attribute(first-name) get value type: <value-type>
    When attribute(first-name) unset value type
    Then attribute(name) get value type: <value-type>
    Then attribute(first-name) get value type: <value-type>
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(name) get value type: <value-type>
    Then attribute(first-name) get value type: <value-type>
    Examples:
      | value-type    |
      | integer       |
      | string        |
      | boolean       |
      | double        |
      | decimal       |
      | date          |
      | datetime      |
      | datetime-tz   |
      | duration      |
      | custom-struct |

  Scenario Outline: Attribute types can set <value-type> value type after subtyping attribute type without value type
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
      | value-type    |
      | integer       |
      | string        |
      | boolean       |
      | double        |
      | decimal       |
      | date          |
      | datetime      |
      | datetime-tz   |
      | duration      |
      | custom-struct |

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
      | value-type    |
      | integer       |
      | string        |
      | boolean       |
      | double        |
      | decimal       |
      | date          |
      | datetime      |
      | datetime-tz   |
      | duration      |
      | custom-struct |

  Scenario Outline: Attribute types can inherit <value-type> value type from supertype
    When create attribute type: name
    When attribute(name) set annotation: @abstract
    When attribute(name) set value type: <value-type>
    When create attribute type: first-name
    Then attribute(first-name) get value type is none
    When attribute(first-name) set supertype: name
    Then attribute(first-name) get supertype: name
    Then attribute(first-name) get value type: <value-type>
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(first-name) get supertype: name
    Then attribute(first-name) get value type: <value-type>
    Examples:
      | value-type    |
      | integer       |
      | string        |
      | boolean       |
      | double        |
      | decimal       |
      | date          |
      | datetime      |
      | datetime-tz   |
      | duration      |
      | custom-struct |

  Scenario Outline: Attribute type of <value-type> value type cannot inherit @abstract annotation, but can set it being a subtype
    When create attribute type: name
    When attribute(name) set annotation: @abstract
    Then attribute(name) get constraints contain: @abstract
    Then attribute(name) get declared annotations contain: @abstract
    When attribute(name) set value type: <value-type>
    When create attribute type: first-name
    When attribute(first-name) set supertype: name
    Then attribute(name) get constraints contain: @abstract
    Then attribute(name) get declared annotations contain: @abstract
    Then attribute(first-name) get constraints do not contain: @abstract
    Then attribute(first-name) get declared annotations do not contain: @abstract
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(name) get constraints contain: @abstract
    Then attribute(name) get declared annotations contain: @abstract
    Then attribute(first-name) get constraints do not contain: @abstract
    Then attribute(first-name) get declared annotations do not contain: @abstract
    When attribute(first-name) set annotation: @abstract
    Then attribute(first-name) get constraints contain: @abstract
    Then attribute(first-name) get declared annotations contain: @abstract
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(first-name) get constraints contain: @abstract
    Then attribute(first-name) get declared annotations contain: @abstract
    Examples:
      | value-type    |
      | integer       |
      | string        |
      | boolean       |
      | double        |
      | decimal       |
      | date          |
      | datetime      |
      | datetime-tz   |
      | duration      |
      | custom-struct |

  Scenario: Attribute types cannot unset @abstract annotation if it does not have value type
    When create attribute type: name
    When attribute(name) set annotation: @abstract
    Then attribute(name) get value type is none
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(name) get value type is none
    Then attribute(name) unset annotation: @abstract; fails

  Scenario: Attribute types cannot unset @abstract annotation without value type, but can unset it with value type
    When create attribute type: name
    When attribute(name) set annotation: @abstract
    Then attribute(name) unset annotation: @abstract; fails
    When attribute(name) set value type: string
    When attribute(name) unset annotation: @abstract
    Then attribute(name) get constraints is empty
    When transaction commits
    When connection open schema transaction for database: typedb
    When attribute(name) get value type: string
    Then attribute(name) get constraints is empty

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
      | real-name |
      | name      |
    Then attribute(last-name) get supertypes contain:
      | real-name |
      | name      |
    Then attribute(real-name) get supertypes contain:
      | name |
    Then attribute(username) get supertypes contain:
      | name |
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
    Then get attribute types contain:
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
      | real-name |
      | name      |
    Then attribute(last-name) get supertypes contain:
      | real-name |
      | name      |
    Then attribute(real-name) get supertypes contain:
      | name |
    Then attribute(username) get supertypes contain:
      | name |
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
    Then get attribute types contain:
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
    When transaction closes
    When connection open schema transaction for database: typedb
    Then attribute(last-name) set supertype: name; fails

  Scenario: Abstract attribute type cannot set non-abstract supertype
    When create attribute type: name
    Then attribute(name) get constraints do not contain: @abstract
    When attribute(name) set value type: string
    When create attribute type: surname
    When attribute(surname) set annotation: @abstract
    Then attribute(surname) get constraints contain: @abstract
    Then attribute(surname) set supertype: name; fails
    Then attribute(name) get constraints do not contain: @abstract
    Then attribute(surname) get constraints contain: @abstract
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(name) get constraints do not contain: @abstract
    Then attribute(surname) get constraints contain: @abstract
    Then attribute(surname) get supertypes do not contain:
      | name |
    Then attribute(surname) set supertype: name; fails
    When attribute(name) set annotation: @abstract
    When attribute(surname) set supertype: name
    Then attribute(name) unset annotation: @abstract; fails
    Then attribute(name) get constraints contain: @abstract
    Then attribute(surname) get constraints contain: @abstract
    Then attribute(surname) get supertype: name
    When transaction commits
    When connection open schema transaction for database: typedb
    When create attribute type: non-abstract-name
    Then attribute(non-abstract-name) get constraints do not contain: @abstract
    When attribute(non-abstract-name) set value type: string
    Then attribute(surname) set supertype: non-abstract-name; fails
    When transaction closes
    When connection open read transaction for database: typedb
    Then attribute(name) get constraints contain: @abstract
    Then attribute(surname) get constraints contain: @abstract
    Then attribute(surname) get supertype: name

########################
# @regex
########################

  Scenario Outline: Attribute types with <value-type> value type can set @regex annotation and unset it
    When create attribute type: email
    When attribute(email) set value type: <value-type>
    When attribute(email) set annotation: @regex(<arg>)
    Then attribute(email) get constraints contain: @regex(<arg>)
    Then attribute(email) get declared annotations contain: @regex(<arg>)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(email) get constraints contain: @regex(<arg>)
    Then attribute(email) get constraint categories contain: @regex
    Then attribute(email) get declared annotations contain: @regex(<arg>)
    Then attribute(email) unset annotation: @regex
    Then attribute(email) get constraints do not contain: @regex(<arg>)
    Then attribute(email) get constraint categories do not contain: @regex
    Then attribute(email) get declared annotations do not contain: @regex(<arg>)
    Then transaction commits
    When connection open read transaction for database: typedb
    Then attribute(email) get constraints do not contain: @regex(<arg>)
    Then attribute(email) get constraint categories do not contain: @regex
    Then attribute(email) get declared annotations do not contain: @regex(<arg>)
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

  Scenario: Attribute types with none value types can't have @regex annotation
    When create attribute type: email
    When attribute(email) set annotation: @abstract
    Then attribute(email) get value type is none
    Then attribute(email) set annotation: @regex("TEST"); fails
    Then attribute(email) get constraints do not contain: @regex("TEST")
    Then attribute(email) get declared annotations do not contain: @regex("TEST")
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(email) get value type is none
    Then attribute(email) set annotation: @regex("TEST"); fails
    Then attribute(email) get constraints do not contain: @regex("TEST")
    Then attribute(email) get declared annotations do not contain: @regex("TEST")

  Scenario Outline: Attribute types with incompatible value types can't have @regex annotation
    When create attribute type: email
    When attribute(email) set value type: <value-type>
    Then attribute(email) set annotation: @regex(<arg>); fails
    Then attribute(email) get constraints is empty
    Then attribute(email) get declared annotations is empty
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(email) set annotation: @regex(<arg>); fails
    Then attribute(email) get constraints is empty
    Then attribute(email) get declared annotations is empty
    Examples:
      | value-type    | arg     |
      | integer       | "value" |
      | boolean       | "value" |
      | double        | "value" |
      | decimal       | "value" |
      | date          | "value" |
      | datetime      | "value" |
      | datetime-tz   | "value" |
      | duration      | "value" |
      | custom-struct | "value" |

  Scenario: Attribute type cannot set @regex annotation for none value type, cannot unset value type with @regex annotation
    When create attribute type: name
    When attribute(name) set annotation: @abstract
    Then attribute(name) set annotation: @regex("value"); fails
    When attribute(name) set value type: string
    When attribute(name) set annotation: @regex("value")
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(name) get value type: string
    Then attribute(name) get constraints contain: @regex("value")
    Then attribute(name) unset value type; fails
    Then attribute(name) unset annotation: @regex
    When attribute(name) unset value type
    Then attribute(name) get value type is none
    Then attribute(name) get constraints do not contain: @regex("value")
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(name) get value type is none
    Then attribute(name) get constraints do not contain: @regex("value")
    Then attribute(name) set annotation: @regex("value"); fails

  Scenario: Attribute types' @regex annotation can be inherited
    When create attribute type: name
    When attribute(name) set value type: string
    When attribute(name) set annotation: @abstract
    When attribute(name) set annotation: @regex("value")
    When create attribute type: first-name
    When attribute(first-name) set supertype: name
    Then attribute(first-name) get constraints contain: @regex("value")
    Then attribute(first-name) get declared annotations do not contain: @regex("value")
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(first-name) get constraints contain: @regex("value")
    Then attribute(first-name) get declared annotations do not contain: @regex("value")

  Scenario: Attribute type cannot set @regex annotation with invalid value
    When create attribute type: name
    When attribute(name) set value type: string
    Then attribute(name) set annotation: @regex(""); fails
    Then attribute(name) set annotation: @regex("*"); fails
    Then attribute(name) get constraints is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(name) get constraints is empty

  Scenario Outline: Attribute type can reset @regex annotation
    When create attribute type: name
    When attribute(name) set value type: string
    When attribute(name) set annotation: @regex(<init-args>)
    Then attribute(name) get constraints contain: @regex(<init-args>)
    Then attribute(name) get declared annotations contain: @regex(<init-args>)
    Then attribute(name) get constraints do not contain: @regex(<reset-args>)
    Then attribute(name) get declared annotations do not contain: @regex(<reset-args>)
    When attribute(name) set annotation: @regex(<init-args>)
    Then attribute(name) get constraints contain: @regex(<init-args>)
    Then attribute(name) get declared annotations contain: @regex(<init-args>)
    Then attribute(name) get constraints do not contain: @regex(<reset-args>)
    Then attribute(name) get declared annotations do not contain: @regex(<reset-args>)
    When attribute(name) set annotation: @regex(<reset-args>)
    Then attribute(name) get constraints contain: @regex(<reset-args>)
    Then attribute(name) get declared annotations contain: @regex(<reset-args>)
    Then attribute(name) get constraints do not contain: @regex(<init-args>)
    Then attribute(name) get declared annotations do not contain: @regex(<init-args>)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(name) get constraints contain: @regex(<reset-args>)
    Then attribute(name) get declared annotations contain: @regex(<reset-args>)
    Then attribute(name) get constraints do not contain: @regex(<init-args>)
    Then attribute(name) get declared annotations do not contain: @regex(<init-args>)
    When attribute(name) set annotation: @regex(<init-args>)
    Then attribute(name) get constraints contain: @regex(<init-args>)
    Then attribute(name) get declared annotations contain: @regex(<init-args>)
    Then attribute(name) get constraints do not contain: @regex(<reset-args>)
    Then attribute(name) get declared annotations do not contain: @regex(<reset-args>)
    Examples:
      | init-args | reset-args      |
      | "\S+"     | "\S"            |
      | "\S+"     | "S+"            |
      | "\S+"     | ".*"            |
      | "\S+"     | "s"             |
      | "\S+"     | " some string " |

  Scenario: Attribute type can specialise inherited @regex annotation
    When create attribute type: name
    When attribute(name) set value type: string
    When create attribute type: first-name
    When attribute(first-name) set value type: string
    When attribute(name) set annotation: @abstract
    When attribute(name) set annotation: @regex("\S+")
    Then attribute(name) get constraints contain: @regex("\S+")
    Then attribute(name) get declared annotations contain: @regex("\S+")
    Then attribute(first-name) get constraints is empty
    Then attribute(first-name) get declared annotations is empty
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(name) get constraints contain: @regex("\S+")
    Then attribute(name) get declared annotations contain: @regex("\S+")
    Then attribute(first-name) get constraints is empty
    Then attribute(first-name) get declared annotations is empty
    When attribute(first-name) set supertype: name
    When attribute(first-name) unset value type
    Then attribute(first-name) get constraints contain: @regex("\S+")
    Then attribute(first-name) get declared annotations do not contain: @regex("\S+")
    Then attribute(first-name) set annotation: @regex("test")
    Then attribute(first-name) get constraints contain: @regex("\S+")
    Then attribute(first-name) get constraints contain: @regex("test")
    Then attribute(first-name) get declared annotations do not contain: @regex("\S+")
    Then attribute(first-name) get declared annotations contain: @regex("test")
    When transaction commits
    When connection open schema transaction for database: typedb
    When attribute(first-name) set annotation: @regex("\S+")
    Then attribute(first-name) get constraints contain: @regex("\S+")
    Then attribute(first-name) get declared annotations contain: @regex("\S+")
    Then attribute(first-name) get constraints do not contain: @regex("test")
    Then attribute(first-name) get declared annotations do not contain: @regex("test")
    Then transaction commits; fails

  Scenario: Attribute type can set another @regex while having inherited @regex
    When create attribute type: name
    When attribute(name) set annotation: @abstract
    When attribute(name) set value type: string
    When attribute(name) set annotation: @regex("value")
    When create attribute type: first-name
    When attribute(first-name) set supertype: name
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(first-name) get constraints contain: @regex("value")
    Then attribute(first-name) get declared annotations do not contain: @regex("value")
    When attribute(first-name) set annotation: @regex("another value")
    Then attribute(first-name) get constraints contain: @regex("value")
    Then attribute(first-name) get constraints contain: @regex("another value")
    Then attribute(first-name) get declared annotations do not contain: @regex("value")
    Then attribute(first-name) get declared annotations contain: @regex("another value")
    Then attribute(name) get constraints contain: @regex("value")
    Then attribute(name) get constraints do not contain: @regex("another value")
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(first-name) get constraints contain: @regex("value")
    Then attribute(first-name) get constraints contain: @regex("another value")
    Then attribute(first-name) get declared annotations do not contain: @regex("value")
    Then attribute(first-name) get declared annotations contain: @regex("another value")
    Then attribute(name) get constraints contain: @regex("value")
    Then attribute(name) get constraints do not contain: @regex("another value")
    When attribute(first-name) set annotation: @regex("value")
    Then attribute(first-name) get constraints contain: @regex("value")
    Then attribute(first-name) get constraints do not contain: @regex("another value")
    Then attribute(first-name) get declared annotations contain: @regex("value")
    Then attribute(first-name) get declared annotations do not contain: @regex("another value")
    Then transaction commits; fails

  Scenario: Attribute type cannot unset inherited @regex annotation
    When create attribute type: name
    When attribute(name) set annotation: @abstract
    When attribute(name) set value type: string
    When attribute(name) set annotation: @regex("value")
    When create attribute type: first-name
    When attribute(first-name) set supertype: name
    Then attribute(first-name) get constraints contain: @regex("value")
    Then attribute(first-name) get declared annotations do not contain: @regex("value")
    When attribute(first-name) unset annotation: @regex
    Then attribute(first-name) get constraints contain: @regex("value")
    Then attribute(first-name) get declared annotations do not contain: @regex("value")
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(first-name) get constraints contain: @regex("value")
    Then attribute(first-name) get declared annotations do not contain: @regex("value")
    When attribute(first-name) unset annotation: @regex
    When attribute(first-name) set annotation: @abstract
    When attribute(first-name) unset supertype
    Then attribute(first-name) get constraints do not contain: @regex("value")
    Then attribute(first-name) get declared annotations do not contain: @regex("value")
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(first-name) get constraints do not contain: @regex("value")
    Then attribute(first-name) get declared annotations do not contain: @regex("value")

  Scenario: Attribute type cannot unset value type if it has owns with @regex annotation
    When create attribute type: custom-attribute
    When attribute(custom-attribute) set annotation: @abstract
    When attribute(custom-attribute) set value type: string
    When attribute(custom-attribute) set annotation: @regex("\S+")
    Then attribute(custom-attribute) unset value type; fails
    Then attribute(custom-attribute) set value type: integer; fails
    Then attribute(custom-attribute) set value type: boolean; fails
    Then attribute(custom-attribute) set value type: double; fails
    Then attribute(custom-attribute) set value type: decimal; fails
    Then attribute(custom-attribute) set value type: date; fails
    Then attribute(custom-attribute) set value type: datetime; fails
    Then attribute(custom-attribute) set value type: datetime-tz; fails
    Then attribute(custom-attribute) set value type: duration; fails
    Then attribute(custom-attribute) set value type: custom-struct; fails
    When attribute(custom-attribute) set value type: string
    Then attribute(custom-attribute) get value type: string
    When attribute(custom-attribute) unset annotation: @regex
    When attribute(custom-attribute) unset value type
    When attribute(custom-attribute) get value type is none
    Then attribute(custom-attribute) set annotation: @regex("\S+"); fails
    When attribute(custom-attribute) set value type: string
    When attribute(custom-attribute) set annotation: @regex("\S+")
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(custom-attribute) get constraints contain: @regex("\S+")
    Then attribute(custom-attribute) unset value type; fails
    Then attribute(custom-attribute) set value type: integer; fails
    Then attribute(custom-attribute) set value type: boolean; fails
    Then attribute(custom-attribute) set value type: double; fails
    Then attribute(custom-attribute) set value type: decimal; fails
    Then attribute(custom-attribute) set value type: date; fails
    Then attribute(custom-attribute) set value type: datetime; fails
    Then attribute(custom-attribute) set value type: datetime-tz; fails
    Then attribute(custom-attribute) set value type: duration; fails
    Then attribute(custom-attribute) set value type: custom-struct; fails
    Then attribute(custom-attribute) get value type: string

########################
# @independent
########################

  Scenario Outline: Attribute types with <value-type> value type can set @independent annotation and unset it
    When create attribute type: email
    When attribute(email) set value type: <value-type>
    When attribute(email) set annotation: @independent
    Then attribute(email) get constraints contain: @independent
    Then attribute(email) get declared annotations contain: @independent
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(email) get constraints contain: @independent
    Then attribute(email) get declared annotations contain: @independent
    Then attribute(email) unset annotation: @independent
    Then attribute(email) get constraints do not contain: @independent
    Then attribute(email) get declared annotations do not contain: @independent
    Then transaction commits
    When connection open read transaction for database: typedb
    Then attribute(email) get constraints do not contain: @independent
    Then attribute(email) get declared annotations do not contain: @independent
    Examples:
      | value-type    |
      | integer       |
      | string        |
      | boolean       |
      | double        |
      | decimal       |
      | date          |
      | datetime      |
      | datetime-tz   |
      | duration      |
      | custom-struct |

  Scenario: Attribute type can reset @independent annotation
    When create attribute type: name
    When attribute(name) set value type: string
    When attribute(name) set annotation: @independent
    Then attribute(name) get constraints contain: @independent
    Then attribute(name) get declared annotations contain: @independent
    When attribute(name) set annotation: @independent
    Then attribute(name) get constraints contain: @independent
    Then attribute(name) get declared annotations contain: @independent
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(name) get constraints contain: @independent
    Then attribute(name) get declared annotations contain: @independent

  Scenario: Attribute types' @independent annotation can be inherited
    When create attribute type: name
    When attribute(name) set value type: string
    When attribute(name) set annotation: @abstract
    When attribute(name) set annotation: @independent
    When create attribute type: first-name
    When attribute(first-name) set supertype: name
    Then attribute(first-name) get constraints contain: @independent
    Then attribute(first-name) get declared annotations do not contain: @independent
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(first-name) get constraints contain: @independent
    Then attribute(first-name) get declared annotations do not contain: @independent

  Scenario: Attribute type cannot reset inherited @independent annotation
    When create attribute type: name
    When attribute(name) set annotation: @abstract
    When attribute(name) set annotation: @independent
    When attribute(name) set value type: string
    When create attribute type: first-name
    When attribute(first-name) set supertype: name
    Then attribute(first-name) get constraints contain: @independent
    When transaction commits
    When connection open schema transaction for database: typedb
    When attribute(first-name) set annotation: @independent
    Then transaction commits; fails
    When connection open schema transaction for database: typedb
    When create attribute type: second-name
    When attribute(second-name) set supertype: name
    Then attribute(second-name) get constraints contain: @independent
    When attribute(second-name) set annotation: @independent
    Then transaction commits; fails

  Scenario: Attribute type cannot unset inherited @independent annotation
    When create attribute type: name
    When attribute(name) set annotation: @abstract
    When attribute(name) set annotation: @independent
    When attribute(name) set value type: string
    When create attribute type: first-name
    When attribute(first-name) set supertype: name
    Then attribute(first-name) get constraints contain: @independent
    Then attribute(first-name) get declared annotations do not contain: @independent
    When attribute(first-name) unset annotation: @independent
    Then attribute(first-name) get constraints contain: @independent
    Then attribute(first-name) get declared annotations do not contain: @independent
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(first-name) get constraints contain: @independent
    Then attribute(first-name) get declared annotations do not contain: @independent
    When attribute(first-name) unset annotation: @independent
    When attribute(first-name) set annotation: @abstract
    # Can't change supertype while losing independence
    When attribute(first-name) set annotation: @independent
    When attribute(first-name) unset supertype
    When attribute(first-name) unset annotation: @independent
    Then attribute(first-name) get constraints do not contain: @independent
    Then attribute(first-name) get declared annotations do not contain: @independent
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(first-name) get constraints do not contain: @independent
    Then attribute(first-name) get declared annotations do not contain: @independent

  Scenario: Attribute type can change supertype while implicitly losing @independent annotation if it doesn't have data
    When create attribute type: literal
    When create attribute type: word
    When create attribute type: name
    When attribute(literal) set annotation: @abstract
    When attribute(literal) set annotation: @independent
    When attribute(word) set annotation: @abstract
    When attribute(name) set value type: string
    When attribute(name) set supertype: word
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(name) get supertype: word
    When attribute(name) set supertype: literal
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(name) get supertype: literal
    When attribute(name) set supertype: word
    Then attribute(name) get constraints do not contain: @independent
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(name) get supertype: word
    Then attribute(name) get constraints do not contain: @independent

  Scenario: Attribute type can unset supertype while implicitly losing @independent annotation if it doesn't have data
    When create attribute type: literal
    When create attribute type: name
    When attribute(literal) set annotation: @abstract
    When attribute(literal) set annotation: @independent
    When attribute(name) set value type: string
    When attribute(name) unset supertype
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(name) get supertype does not exist
    When attribute(name) set supertype: literal
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(name) get supertype: literal
    When attribute(name) unset supertype
    Then attribute(name) get constraints do not contain: @independent
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(name) get supertype does not exist
    Then attribute(name) get constraints do not contain: @independent

########################
# @values
########################
  Scenario Outline: Attribute types with <value-type> value type can set @values annotation and unset it
    When create attribute type: email
    When attribute(email) set value type: <value-type>
    When attribute(email) set annotation: @values(<args>)
    Then attribute(email) get constraints contain: @values(<args>)
    Then attribute(email) get declared annotations contain: @values(<args>)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(email) get constraints contain: @values(<args>)
    Then attribute(email) get declared annotations contain: @values(<args>)
    Then attribute(email) unset annotation: @values
    Then attribute(email) get constraints do not contain: @values(<args>)
    Then attribute(email) get declared annotations do not contain: @values(<args>)
    Then transaction commits
    When connection open read transaction for database: typedb
    Then attribute(email) get constraints do not contain: @values(<args>)
    Then attribute(email) get declared annotations do not contain: @values(<args>)
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
      | decimal     | 0dec                                                                                                                                                                                                                                                                                                                                                                                                 |
      | decimal     | 1.1dec                                                                                                                                                                                                                                                                                                                                                                                               |
      | decimal     | -2.45dec                                                                                                                                                                                                                                                                                                                                                                                             |
      | decimal     | -3.444dec, 3.445dec                                                                                                                                                                                                                                                                                                                                                                                  |
      | decimal     | 0.00001dec, 0.0001dec, 0.001dec, 0.01dec                                                                                                                                                                                                                                                                                                                                                             |
      | decimal     | -333.553dec, 33895dec, 98984.4555dec, 902394.44dec, 1000000000dec, 0.00001dec, 0.3dec, 3.14159265358979323dec                                                                                                                                                                                                                                                                                        |
      | date        | 2024-06-04                                                                                                                                                                                                                                                                                                                                                                                           |
      | date        | 1970-01-01                                                                                                                                                                                                                                                                                                                                                                                           |
      | date        | 1970-01-01, 0001-01-01, 2024-06-04, 2024-02-02                                                                                                                                                                                                                                                                                                                                                       |
      | datetime    | 2024-06-04                                                                                                                                                                                                                                                                                                                                                                                           |
      | datetime    | 2024-06-04T16:35                                                                                                                                                                                                                                                                                                                                                                                     |
      | datetime    | 2024-06-04T16:35:02                                                                                                                                                                                                                                                                                                                                                                                  |
      | datetime    | 2024-06-04T16:35:02.1                                                                                                                                                                                                                                                                                                                                                                                |
      | datetime    | 2024-06-04T16:35:02.10                                                                                                                                                                                                                                                                                                                                                                               |
      | datetime    | 2024-06-04T16:35:02.103                                                                                                                                                                                                                                                                                                                                                                              |
      | datetime    | 2024-06-04, 2024-06-04T16:35, 2024-06-04T16:35:02, 2024-06-04T16:35:02.01, 2024-06-04T16:35:02.10, 2024-06-04T16:35:02.103                                                                                                                                                                                                                                                                           |
      | datetime-tz | 2024-06-04+0000                                                                                                                                                                                                                                                                                                                                                                                      |
      | datetime-tz | 2024-06-04 Asia/Kathmandu                                                                                                                                                                                                                                                                                                                                                                            |
      | datetime-tz | 2024-06-04+0100                                                                                                                                                                                                                                                                                                                                                                                      |
      | datetime-tz | 2024-06-04T16:35+0100                                                                                                                                                                                                                                                                                                                                                                                |
      | datetime-tz | 2024-06-04T16:35:02+0100                                                                                                                                                                                                                                                                                                                                                                             |
      | datetime-tz | 2024-06-04T16:35:02.1+0100                                                                                                                                                                                                                                                                                                                                                                           |
      | datetime-tz | 2024-06-04T16:35:02.10+0100                                                                                                                                                                                                                                                                                                                                                                          |
      | datetime-tz | 2024-06-04T16:35:02.103+0100                                                                                                                                                                                                                                                                                                                                                                         |
      | datetime-tz | 2024-06-04+0001, 2024-06-04 Asia/Kathmandu, 2024-06-04+0002, 2024-06-04+0010, 2024-06-04+0100, 2024-06-04-0100, 2024-06-04T16:35-0100, 2024-06-04T16:35:02+0200, 2024-06-04T16:35:02.10+1000                                                                                                                                                                                                         |
      | duration    | P1Y                                                                                                                                                                                                                                                                                                                                                                                                  |
      | duration    | P2M                                                                                                                                                                                                                                                                                                                                                                                                  |
      | duration    | P1Y2M                                                                                                                                                                                                                                                                                                                                                                                                |
      | duration    | P1Y2M3D                                                                                                                                                                                                                                                                                                                                                                                              |
      | duration    | P1Y2M3DT4H                                                                                                                                                                                                                                                                                                                                                                                           |
      | duration    | P1Y2M3DT4H5M                                                                                                                                                                                                                                                                                                                                                                                         |
      | duration    | P1Y2M3DT4H5M6S                                                                                                                                                                                                                                                                                                                                                                                       |
      | duration    | P1Y2M3DT4H5M6.789S                                                                                                                                                                                                                                                                                                                                                                                   |
      | duration    | P1Y, P1Y1M, P1Y1M1D, P1Y1M1DT1H, P1Y1M1DT1H1M, P1Y1M1DT1H1M1S, P1Y1M1DT1H1M1S0.1S, P1Y1M1DT1H1M1S0.001S, P1Y1M1DT1H1M0.000001S                                                                                                                                                                                                                                                                       |

  Scenario Outline: Attribute type @values annotation correctly validates nanoseconds
    When create attribute type: today
    When attribute(today) set value type: <value-type>
    When attribute(today) set annotation: @values(<first>, <second>)
    Then attribute(today) set annotation: @values(<first>, <first>); fails
    Then attribute(today) set annotation: @values(<second>, <second>); fails
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(today) get constraints contain: @values(<first>, <second>)
    Then attribute(today) get constraints do not contain: @values(<first>, <first>)
    Then attribute(today) get constraints do not contain: @values(<second>, <second>)
    Then attribute(today) set annotation: @values(<first>, <first>); fails
    Then attribute(today) set annotation: @values(<second>, <second>); fails
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

  Scenario: Attribute types' @values annotation can be inherited
    When create attribute type: name
    When attribute(name) set value type: string
    When attribute(name) set annotation: @abstract
    When attribute(name) set annotation: @values("value", "value2")
    When create attribute type: first-name
    When attribute(first-name) set supertype: name
    Then attribute(first-name) get constraints contain: @values("value", "value2")
    Then attribute(first-name) get declared annotations do not contain: @values("value", "value2")
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(first-name) get constraints contain: @values("value", "value2")
    Then attribute(first-name) get declared annotations do not contain: @values("value", "value2")

  Scenario Outline: Attribute type with <value-type> value type can reset @values annotation
    When create attribute type: name
    When attribute(name) set value type: <value-type>
    When attribute(name) set annotation: @values(<init-args>)
    Then attribute(name) get constraints contain: @values(<init-args>)
    Then attribute(name) get constraints do not contain: @values(<reset-args>)
    When attribute(name) set annotation: @values(<init-args>)
    Then attribute(name) get constraints contain: @values(<init-args>)
    Then attribute(name) get constraints do not contain: @values(<reset-args>)
    When attribute(name) set annotation: @values(<reset-args>)
    Then attribute(name) get constraints contain: @values(<reset-args>)
    Then attribute(name) get constraints do not contain: @values(<init-args>)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(name) get constraints contain: @values(<reset-args>)
    Then attribute(name) get constraints do not contain: @values(<init-args>)
    When attribute(name) set annotation: @values(<init-args>)
    Then attribute(name) get constraints contain: @values(<init-args>)
    Then attribute(name) get constraints do not contain: @values(<reset-args>)
    Examples:
      | value-type  | init-args        | reset-args      |
      | integer     | 1, 5             | 7, 9            |
      | double      | 1.1, 1.5         | -8.0, 88.3      |
      | decimal     | -8.0dec, 88.3dec | 1.1dec, 1.5dec  |
      | string      | "s"              | "not s"         |
      | boolean     | true             | false           |
      | date        | 2024-05-05       | 2024-06-05      |
      | datetime    | 2024-05-05       | 2024-06-05      |
      | datetime-tz | 2024-05-05+0100  | 2024-05-05+0010 |
      | duration    | P1Y              | P2Y             |

  Scenario Outline: Attribute type cannot have @values annotation for <value-type> value type with duplicated args
    When create attribute type: name
    When attribute(name) set value type: <value-type>
    Then attribute(name) set annotation: @values(<arg0>, <arg1>, <arg2>); fails
    Then attribute(name) get constraints is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(name) get constraints is empty
    Examples:
      | value-type  | arg0                        | arg1                         | arg2                         |
      | integer     | 1                           | 1                            | 1                            |
      | integer     | 1                           | 1                            | 2                            |
      | integer     | 1                           | 2                            | 1                            |
      | integer     | 1                           | 2                            | 2                            |
      | double      | 0.1                         | 0.0001                       | 0.0001                       |
      | decimal     | 0.1dec                      | 0.0001dec                    | 0.0001dec                    |
      | string      | "stringwithoutdifferences"  | "stringwithoutdifferences"   | "stringWITHdifferences"      |
      | string      | "stringwithoutdifferences " | "stringwithoutdifferences  " | "stringwithoutdifferences  " |
      | boolean     | true                        | true                         | false                        |
      | date        | 2024-06-04                  | 2024-06-05                   | 2024-06-04                   |
      | datetime    | 2024-06-04T16:35:02.101     | 2024-06-04T16:35:02.101      | 2024-06-04                   |
      | datetime    | 2020-06-04T16:35:02.10      | 2025-06-05T16:35             | 2025-06-05T16:35             |
      | datetime-tz | 2020-06-04T16:35:02.10+0100 | 2020-06-04T16:35:02.10+0000  | 2020-06-04T16:35:02.10+0100  |
      | duration    | P1Y1M                       | P1Y1M                        | P1Y2M                        |

  Scenario: Attribute type cannot reset inherited @values annotation
    When create attribute type: name
    When attribute(name) set annotation: @abstract
    When attribute(name) set value type: string
    When attribute(name) set annotation: @values("value")
    When create attribute type: first-name
    When attribute(first-name) set supertype: name
    Then attribute(first-name) get constraints contain: @values("value")
    When transaction commits
    When connection open schema transaction for database: typedb
    When attribute(first-name) set annotation: @values("value")
    Then transaction commits; fails
    When connection open schema transaction for database: typedb
    When create attribute type: second-name
    When attribute(second-name) set supertype: name
    Then attribute(second-name) get constraints contain: @values("value")
    When attribute(second-name) set annotation: @values("value")
    Then transaction commits; fails

  Scenario: Attribute type cannot unset inherited @values annotation
    When create attribute type: name
    When attribute(name) set annotation: @abstract
    When attribute(name) set value type: string
    When attribute(name) set annotation: @values("value")
    When create attribute type: first-name
    When attribute(first-name) set supertype: name
    Then attribute(first-name) get constraints contain: @values("value")
    Then attribute(first-name) get declared annotations do not contain: @values("value")
    When attribute(first-name) unset annotation: @values
    Then attribute(first-name) get constraints contain: @values("value")
    Then attribute(first-name) get declared annotations do not contain: @values("value")
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(first-name) get constraints contain: @values("value")
    Then attribute(first-name) get declared annotations do not contain: @values("value")
    When attribute(first-name) unset annotation: @values
    Then attribute(first-name) unset supertype; fails
    When attribute(first-name) set annotation: @abstract
    When attribute(first-name) unset supertype
    Then attribute(first-name) get constraint categories do not contain: @values
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(first-name) get constraint categories do not contain: @values

  Scenario Outline: Attribute types' @values annotation for <value-type> value type can be inherited and specialised by a subset of arguments
    When create attribute type: name
    When attribute(name) set value type: <value-type>
    When attribute(name) set annotation: @abstract
    When create attribute type: specialised-name
    When attribute(specialised-name) set supertype: name
    When attribute(name) set annotation: @values(<args>)
    Then attribute(name) get constraints contain: @values(<args>)
    Then attribute(name) get declared annotations contain: @values(<args>)
    Then attribute(specialised-name) get constraints contain: @values(<args>)
    Then attribute(specialised-name) get declared annotations do not contain: @values(<args>)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(name) get constraints contain: @values(<args>)
    Then attribute(name) get declared annotations contain: @values(<args>)
    Then attribute(specialised-name) get constraints contain: @values(<args>)
    Then attribute(specialised-name) get declared annotations do not contain: @values(<args>)
    When attribute(specialised-name) set annotation: @values(<args-specialise>)
    Then attribute(name) get constraints contain: @values(<args>)
    Then attribute(name) get declared annotations contain: @values(<args>)
    Then attribute(name) get constraints do not contain: @values(<args-specialise>)
    Then attribute(specialised-name) get constraints contain: @values(<args-specialise>)
    Then attribute(specialised-name) get declared annotations contain: @values(<args-specialise>)
    Then attribute(specialised-name) get declared annotations do not contain: @values(<args>)
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(name) get constraints contain: @values(<args>)
    Then attribute(name) get declared annotations contain: @values(<args>)
    Then attribute(name) get constraints do not contain: @values(<args-specialise>)
    Then attribute(specialised-name) get constraints contain: @values(<args-specialise>)
    Then attribute(specialised-name) get declared annotations contain: @values(<args-specialise>)
    Then attribute(specialised-name) get declared annotations do not contain: @values(<args>)
    Examples:
      | value-type  | args                                                                         | args-specialise                            |
      | integer     | 1, 10, 20, 30                                                                | 10, 30                                     |
      | double      | 1.0, 2.0, 3.0, 4.5                                                           | 2.0                                        |
      | decimal     | 0.0dec, 1.0dec                                                               | 0.0dec                                     |
      | string      | "john", "John", "Johnny", "johnny"                                           | "John", "Johnny"                           |
      | boolean     | true, false                                                                  | true                                       |
      | date        | 2024-06-04, 2024-06-05, 2024-06-06                                           | 2024-06-04, 2024-06-06                     |
      | datetime    | 2024-06-04, 2024-06-05, 2024-06-06                                           | 2024-06-04, 2024-06-06                     |
      | datetime-tz | 2024-06-04+0010, 2024-06-04 Asia/Kathmandu, 2024-06-05+0010, 2024-06-05+0100 | 2024-06-04 Asia/Kathmandu, 2024-06-05+0010 |
      | duration    | P6M, P1Y, P1Y1M, P1Y2M, P1Y3M, P1Y4M, P1Y6M                                  | P6M, P1Y3M, P1Y4M, P1Y6M                   |

  Scenario Outline: Inherited @values annotation on attribute types for <value-type> value type cannot be specialised by the @values of not a subset of arguments
    When create attribute type: name
    When attribute(name) set value type: <value-type>
    When attribute(name) set annotation: @abstract
    When create attribute type: specialised-name
    When attribute(specialised-name) set supertype: name
    When attribute(name) set annotation: @values(<args>)
    Then attribute(name) get constraints contain: @values(<args>)
    Then attribute(name) get declared annotations contain: @values(<args>)
    Then attribute(specialised-name) get constraints contain: @values(<args>)
    Then attribute(specialised-name) get declared annotations do not contain: @values(<args>)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(name) get constraints contain: @values(<args>)
    Then attribute(name) get declared annotations contain: @values(<args>)
    Then attribute(specialised-name) get constraints contain: @values(<args>)
    Then attribute(specialised-name) get declared annotations do not contain: @values(<args>)
    Then attribute(specialised-name) set annotation: @values(<args-specialise>); fails
    Then attribute(name) get constraints contain: @values(<args>)
    Then attribute(name) get declared annotations contain: @values(<args>)
    Then attribute(specialised-name) get constraints contain: @values(<args>)
    Then attribute(specialised-name) get declared annotations do not contain: @values(<args>)
    Examples:
      | value-type  | args                                                                         | args-specialise          |
      | integer     | 1, 10, 20, 30                                                                | 10, 31                   |
      | double      | 1.0, 2.0, 3.0, 4.5                                                           | 2.001                    |
      | decimal     | 0.0dec, 1.0dec                                                               | 0.01dec                  |
      | string      | "john", "John", "Johnny", "johnny"                                           | "Jonathan"               |
      | boolean     | false                                                                        | true                     |
      | date        | 2024-06-04, 2024-06-05, 2024-06-06                                           | 2020-06-04, 2020-06-06   |
      | datetime    | 2024-06-04, 2024-06-05, 2024-06-06                                           | 2020-06-04, 2020-06-06   |
      | datetime-tz | 2024-06-04+0010, 2024-06-04 Asia/Kathmandu, 2024-06-05+0010, 2024-06-05+0100 | 2024-06-04 Europe/London |
      | duration    | P6M, P1Y, P1Y1M, P1Y2M, P1Y3M, P1Y4M, P1Y6M                                  | P3M, P1Y3M, P1Y4M, P1Y6M |

  Scenario: Attribute type can change value type and @values through @values resetting
    When create attribute type: name
    When create attribute type: surname
    When attribute(name) set annotation: @abstract
    When attribute(surname) set supertype: name
    When attribute(surname) set value type: string
    When attribute(surname) set annotation: @values("only this string is allowed")
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(name) set value type: integer; fails
    Then attribute(surname) set value type: integer; fails
    When attribute(surname) unset annotation: @values
    Then attribute(surname) unset value type; fails
    When attribute(surname) set value type: integer
    When attribute(name) set value type: integer
    When attribute(surname) unset value type
    When attribute(surname) set annotation: @values(1, 2, 3)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(surname) get constraints contain: @values(1, 2, 3)
    Then attribute(surname) get value type: integer
    When attribute(name) set annotation: @values(1, 2, 3)
    When attribute(surname) unset annotation: @values
    Then attribute(surname) get constraints contain: @values(1, 2, 3)
    Then attribute(surname) set value type: string; fails
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(surname) get constraints contain: @values(1, 2, 3)
    Then attribute(surname) get value type: integer

########################
# @range
########################

  Scenario Outline: Attribute types with <value-type> value type can set @range annotation and unset it
    When create attribute type: email
    When attribute(email) set value type: <value-type>
    Then attribute(email) set annotation: @range(<arg1>..<arg0>); fails
    Then attribute(email) get constraints do not contain: @range(<arg1>..<arg0>)
    Then attribute(email) get declared annotations do not contain: @range(<arg1>..<arg0>)
    When attribute(email) set annotation: @range(<arg0>..<arg1>)
    Then attribute(email) get constraints contain: @range(<arg0>..<arg1>)
    Then attribute(email) get declared annotations contain: @range(<arg0>..<arg1>)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(email) get constraints contain: @range(<arg0>..<arg1>)
    Then attribute(email) get declared annotations contain: @range(<arg0>..<arg1>)
    Then attribute(email) unset annotation: @range
    Then attribute(email) get constraints do not contain: @range(<arg0>..<arg1>)
    Then attribute(email) get declared annotations do not contain: @range(<arg0>..<arg1>)
    Then transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(email) get constraints do not contain: @range(<arg0>..<arg1>)
    Then attribute(email) get declared annotations do not contain: @range(<arg0>..<arg1>)
    When attribute(email) set annotation: @range(..<arg1>)
    Then attribute(email) get constraints contain: @range(..<arg1>)
    Then attribute(email) get declared annotations contain: @range(..<arg1>)
    Then attribute(email) get constraints do not contain: @range(<arg0>..<arg1>)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(email) get constraints contain: @range(..<arg1>)
    Then attribute(email) get declared annotations contain: @range(..<arg1>)
    Then attribute(email) get constraints do not contain: @range(<arg0>..<arg1>)
    Then attribute(email) unset annotation: @range
    Then attribute(email) get constraints do not contain: @range(..<arg1>)
    Then attribute(email) get declared annotations do not contain: @range(..<arg1>)
    When attribute(email) set annotation: @range(<arg0>..)
    Then attribute(email) get constraints contain: @range(<arg0>..)
    Then attribute(email) get declared annotations contain: @range(<arg0>..)
    Then attribute(email) get constraints do not contain: @range(<arg0>..<arg1>)
    Then attribute(email) get constraints do not contain: @range(..<arg1>)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(email) get constraints contain: @range(<arg0>..)
    Then attribute(email) get declared annotations contain: @range(<arg0>..)
    Then attribute(email) get constraints do not contain: @range(<arg0>..<arg1>)
    Then attribute(email) get constraints do not contain: @range(..<arg1>)
    Then attribute(email) unset annotation: @range
    Then attribute(email) get constraints do not contain: @range(<arg0>..<arg1>)
    Then attribute(email) get declared annotations do not contain: @range(<arg0>..<arg1>)
    Then attribute(email) get constraints do not contain: @range(..<arg1>)
    Then attribute(email) get declared annotations do not contain: @range(..<arg1>)
    Then attribute(email) get constraints do not contain: @range(<arg0>..)
    Then attribute(email) get declared annotations do not contain: @range(<arg0>..)
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(email) get constraints do not contain: @range(<arg0>..<arg1>)
    Then attribute(email) get declared annotations do not contain: @range(<arg0>..<arg1>)
    Then attribute(email) get constraints do not contain: @range(..<arg1>)
    Then attribute(email) get declared annotations do not contain: @range(..<arg1>)
    Then attribute(email) get constraints do not contain: @range(<arg0>..)
    Then attribute(email) get declared annotations do not contain: @range(<arg0>..)
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
      | date        | 2024-06-04                        | 2024-06-05                                            |
      | date        | 2024-06-04                        | 2024-07-03                                            |
      | date        | 2024-06-04                        | 2025-01-01                                            |
      | date        | 1970-01-01                        | 9999-12-12                                            |
      | datetime    | 2024-06-04T16:35:02.10            | 2024-06-04T16:35:02.11                                |
      | datetime-tz | 2024-06-04+0000                   | 2024-06-05+0000                                       |
      | datetime-tz | 2024-06-04+0100                   | 2048-06-04+0100                                       |
      | datetime-tz | 2024-06-04T16:35:02.103+0100      | 2024-06-04T16:35:02.104+0100                          |
      | datetime-tz | 2024-06-04 Asia/Kathmandu         | 2024-06-05 Asia/Kathmandu                             |
      | datetime-tz | 2024-05-05T00:00:00 Europe/Berlin | 2024-05-05T00:00:00 Europe/London                     |

  Scenario Outline: Attribute types with <value-type> value type cannot set @range annotation
    When create attribute type: email
    When attribute(email) set value type: <value-type>
    Then attribute(email) set annotation: @range(<arg0>..<arg1>); fails
    Then attribute(email) get constraints do not contain: @range(<arg0>..<arg1>)
    Then attribute(email) get declared annotations do not contain: @range(<arg0>..<arg1>)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(email) get constraints do not contain: @range(<arg0>..<arg1>)
    Then attribute(email) get declared annotations do not contain: @range(<arg0>..<arg1>)
    Then attribute(email) set annotation: @range(<arg0>..<arg1>); fails
    Then attribute(email) get constraints do not contain: @range(<arg0>..<arg1>)
    Then attribute(email) get declared annotations do not contain: @range(<arg0>..<arg1>)
    When transaction closes
    When connection open read transaction for database: typedb
    Then attribute(email) get constraints do not contain: @range(<arg0>..<arg1>)
    Then attribute(email) get declared annotations do not contain: @range(<arg0>..<arg1>)
    Examples:
      | value-type | arg0               | arg1               |
      | duration   | P1Y                | P2Y                |
      | duration   | P2M                | P1Y2M              |
      | duration   | P1Y2M              | P1Y2M3DT4H5M6.789S |
      | duration   | P1Y2M3DT4H5M6.788S | P1Y2M3DT4H5M6.789S |

  Scenario Outline: Attribute type @range annotation correctly validates nanoseconds
    When create attribute type: today
    When attribute(today) set value type: <value-type>
    When attribute(today) set annotation: @range(<from>..<to>)
    Then attribute(today) set annotation: @range(<to>..<from>); fails
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(today) get constraints contain: @range(<from>..<to>)
    Then attribute(today) get constraints do not contain: @range(<to>..<from>)
    Then attribute(today) set annotation: @range(<to>..<from>); fails
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

  Scenario: Attribute types' @range annotation can be inherited
    When create attribute type: name
    When attribute(name) set value type: string
    When attribute(name) set annotation: @abstract
    When attribute(name) set annotation: @range(3..5)
    When create attribute type: first-name
    When attribute(first-name) set supertype: name
    Then attribute(first-name) get constraints contain: @range(3..5)
    Then attribute(first-name) get declared annotations do not contain: @range(3..5)
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(first-name) get constraints contain: @range(3..5)
    Then attribute(first-name) get declared annotations do not contain: @range(3..5)

  Scenario Outline: Attribute type with <value-type> value type cannot set @range with duplicated arguments
    When create attribute type: name
    When attribute(name) set value type: <value-type>
    Then attribute(name) set annotation: @range(<arg0>..<arg0>); fails
    Then attribute(name) get constraints is empty
    Then attribute(name) get declared annotations is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(name) get constraints is empty
    Then attribute(name) get declared annotations is empty
    Examples:
      | value-type  | arg0                     |
      | integer     | 1                        |
      | double      | 1.0                      |
      | decimal     | 1.0dec                   |
      | string      | "123"                    |
      | boolean     | false                    |
      | date        | 2030-06-04               |
      | datetime    | 2030-06-04               |
      | datetime-tz | 2030-06-04 Europe/London |

  Scenario Outline: Attribute type with <value-type> value type can reset @range annotation
    When create attribute type: name
    When attribute(name) set value type: <value-type>
    When attribute(name) set annotation: @range(<init-args>)
    Then attribute(name) get constraints contain: @range(<init-args>)
    Then attribute(name) get declared annotations contain: @range(<init-args>)
    Then attribute(name) get constraints do not contain: @range(<reset-args>)
    Then attribute(name) get declared annotations do not contain: @range(<reset-args>)
    When attribute(name) set annotation: @range(<init-args>)
    Then attribute(name) get constraints contain: @range(<init-args>)
    Then attribute(name) get declared annotations contain: @range(<init-args>)
    Then attribute(name) get constraints do not contain: @range(<reset-args>)
    Then attribute(name) get declared annotations do not contain: @range(<reset-args>)
    When attribute(name) set annotation: @range(<reset-args>)
    Then attribute(name) get constraints contain: @range(<reset-args>)
    Then attribute(name) get declared annotations contain: @range(<reset-args>)
    Then attribute(name) get constraints do not contain: @range(<init-args>)
    Then attribute(name) get declared annotations do not contain: @range(<init-args>)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(name) get constraints contain: @range(<reset-args>)
    Then attribute(name) get declared annotations contain: @range(<reset-args>)
    Then attribute(name) get constraints do not contain: @range(<init-args>)
    Then attribute(name) get declared annotations do not contain: @range(<init-args>)
    When attribute(name) set annotation: @range(<init-args>)
    Then attribute(name) get constraints contain: @range(<init-args>)
    Then attribute(name) get declared annotations contain: @range(<init-args>)
    Then attribute(name) get constraints do not contain: @range(<reset-args>)
    Then attribute(name) get declared annotations do not contain: @range(<reset-args>)
    Examples:
      | value-type  | init-args                        | reset-args                       |
      | integer     | 1..5                             | 7..9                             |
      | double      | 1.1..1.5                         | -8.0..88.3                       |
      | decimal     | -8.0dec..88.3dec                 | 1.1dec..1.5dec                   |
      | string      | "S".."s"                         | "not s".."xxxxxxxxx"             |
      | date        | 2024-05-05..2024-05-06           | 2024-06-05..2024-06-06           |
      | datetime    | 2024-05-05..2024-05-06           | 2024-06-05..2024-06-06           |
      | datetime-tz | 2024-05-05+0100..2024-05-06+0100 | 2024-05-05+0100..2024-05-07+0100 |

  Scenario: Attribute type cannot reset inherited @range annotation
    When create attribute type: name
    When attribute(name) set annotation: @abstract
    When attribute(name) set value type: string
    When attribute(name) set annotation: @range("value".."value+1")
    When create attribute type: first-name
    When attribute(first-name) set supertype: name
    Then attribute(first-name) get constraints contain: @range("value".."value+1")
    Then attribute(first-name) get declared annotations do not contain: @range("value".."value+1")
    When transaction commits
    When connection open schema transaction for database: typedb
    When attribute(first-name) set annotation: @range("value".."value+1")
    Then transaction commits; fails
    When connection open schema transaction for database: typedb
    When create attribute type: second-name
    When attribute(second-name) set supertype: name
    Then attribute(second-name) get constraints contain: @range("value".."value+1")
    Then attribute(second-name) get declared annotations do not contain: @range("value".."value+1")
    When attribute(second-name) set annotation: @range("value".."value+1")
    Then transaction commits; fails

  Scenario: Attribute type cannot unset inherited @range annotation
    When create attribute type: name
    When attribute(name) set annotation: @abstract
    When attribute(name) set value type: string
    When attribute(name) set annotation: @range("value".."value+1")
    When create attribute type: first-name
    When attribute(first-name) set supertype: name
    Then attribute(first-name) get constraints contain: @range("value".."value+1")
    Then attribute(first-name) get declared annotations do not contain: @range("value".."value+1")
    When attribute(first-name) unset annotation: @range
    Then attribute(first-name) get constraints contain: @range("value".."value+1")
    Then attribute(first-name) get declared annotations do not contain: @range("value".."value+1")
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(first-name) get constraints contain: @range("value".."value+1")
    Then attribute(first-name) get declared annotations do not contain: @range("value".."value+1")
    When attribute(first-name) unset annotation: @range
    When attribute(first-name) set value type: string
    When attribute(first-name) unset supertype
    Then attribute(first-name) get constraints do not contain: @range("value".."value+1")
    Then attribute(first-name) get declared annotations do not contain: @range("value".."value+1")
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(first-name) get constraints do not contain: @range("value".."value+1")
    Then attribute(first-name) get declared annotations do not contain: @range("value".."value+1")

  Scenario Outline: Attribute types' @range annotation for <value-type> value type can be inherited and specialised by a subset of arguments
    When create attribute type: name
    When attribute(name) set value type: <value-type>
    When attribute(name) set annotation: @abstract
    When create attribute type: specialised-name
    When attribute(specialised-name) set supertype: name
    When attribute(name) set annotation: @range(<args>)
    Then attribute(name) get constraints contain: @range(<args>)
    Then attribute(name) get declared annotations contain: @range(<args>)
    Then attribute(specialised-name) get constraints contain: @range(<args>)
    Then attribute(specialised-name) get declared annotations do not contain: @range(<args>)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(name) get constraints contain: @range(<args>)
    Then attribute(name) get declared annotations contain: @range(<args>)
    Then attribute(specialised-name) get constraints contain: @range(<args>)
    Then attribute(specialised-name) get declared annotations do not contain: @range(<args>)
    When attribute(specialised-name) set annotation: @range(<args-specialise>)
    Then attribute(name) get constraints contain: @range(<args>)
    Then attribute(name) get constraints do not contain: @range(<args-specialise>)
    Then attribute(name) get declared annotations contain: @range(<args>)
    Then attribute(name) get declared annotations do not contain: @range(<args-specialise>)
    Then attribute(specialised-name) get constraints contain: @range(<args-specialise>)
    Then attribute(specialised-name) get constraints contain: @range(<args>)
    Then attribute(specialised-name) get declared annotations contain: @range(<args-specialise>)
    Then attribute(specialised-name) get declared annotations do not contain: @range(<args>)
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(name) get constraints contain: @range(<args>)
    Then attribute(name) get constraints do not contain: @range(<args-specialise>)
    Then attribute(name) get declared annotations contain: @range(<args>)
    Then attribute(name) get declared annotations do not contain: @range(<args-specialise>)
    Then attribute(specialised-name) get constraints contain: @range(<args-specialise>)
    Then attribute(specialised-name) get constraints contain: @range(<args>)
    Then attribute(specialised-name) get declared annotations contain: @range(<args-specialise>)
    Then attribute(specialised-name) get declared annotations do not contain: @range(<args>)
    Examples:
      | value-type  | args                             | args-specialise                           |
      | integer     | 1..10                            | 1..5                                      |
      | double      | 1.0..10.0                        | 2.0..10.0                                 |
      | decimal     | 0.0dec..1.0dec                   | 0.0dec..0.999999dec                       |
      | string      | "A".."Z"                         | "J".."Z"                                  |
      | date        | 2024-06-04..2024-06-06           | 2024-06-04..2024-06-05                    |
      | datetime    | 2024-06-04..2024-06-05           | 2024-06-04..2024-06-04T12:00:00           |
      | datetime-tz | 2024-06-04+0010..2024-06-05+0010 | 2024-06-04+0010..2024-06-04T12:00:00+0010 |

  Scenario Outline: Inherited @range annotation on attribute types for <value-type> value type cannot be specialised by the @range of not a subset of arguments
    When create attribute type: name
    When attribute(name) set value type: <value-type>
    When attribute(name) set annotation: @abstract
    When create attribute type: specialised-name
    When attribute(specialised-name) set supertype: name
    When attribute(name) set annotation: @range(<args>)
    Then attribute(name) get constraints contain: @range(<args>)
    Then attribute(name) get declared annotations contain: @range(<args>)
    Then attribute(specialised-name) get constraints contain: @range(<args>)
    Then attribute(specialised-name) get declared annotations do not contain: @range(<args>)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(name) get constraints contain: @range(<args>)
    Then attribute(name) get declared annotations contain: @range(<args>)
    Then attribute(specialised-name) get constraints contain: @range(<args>)
    Then attribute(specialised-name) get declared annotations do not contain: @range(<args>)
    Then attribute(specialised-name) set annotation: @range(<args-specialise>); fails
    Then attribute(name) get constraints contain: @range(<args>)
    Then attribute(name) get declared annotations contain: @range(<args>)
    Then attribute(specialised-name) get constraints contain: @range(<args>)
    Then attribute(specialised-name) get declared annotations do not contain: @range(<args>)
    Examples:
      | value-type  | args                             | args-specialise                           |
      | integer     | 1..10                            | -1..5                                     |
      | double      | 1.0..10.0                        | 0.0..150.0                                |
      | decimal     | 0.0dec..1.0dec                   | -0.0001dec..0.999999dec                   |
      | string      | "A".."Z"                         | "A".."z"                                  |
      | date        | 2024-06-04..2024-06-05           | 2023-06-04..2024-06-04                    |
      | datetime    | 2024-06-04..2024-06-05           | 2023-06-04..2024-06-04T12:00:00           |
      | datetime-tz | 2024-06-04+0010..2024-06-05+0010 | 2024-06-04+0010..2024-06-05T01:00:00+0010 |

  Scenario: Attribute type can change value type and @range through @range resetting
    When create attribute type: name
    When create attribute type: surname
    When attribute(name) set annotation: @abstract
    When attribute(surname) set supertype: name
    When attribute(surname) set value type: string
    When attribute(surname) set annotation: @range("a start".."finish line")
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(name) set value type: integer; fails
    Then attribute(surname) set value type: integer; fails
    When attribute(surname) unset annotation: @range
    Then attribute(surname) unset value type; fails
    When attribute(surname) set value type: integer
    When attribute(name) set value type: integer
    When attribute(surname) unset value type
    When attribute(surname) set annotation: @range(1..3)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(surname) get constraints contain: @range(1..3)
    Then attribute(surname) get value type: integer
    When attribute(name) set annotation: @range(1..3)
    When attribute(surname) unset annotation: @range
    Then attribute(surname) get constraints contain: @range(1..3)
    Then attribute(surname) set value type: string; fails
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(surname) get constraints contain: @range(1..3)
    Then attribute(surname) get value type: integer

########################
# @annotations combinations:
# @abstract, @independent, @values, @range, @regex
########################

  Scenario Outline: Attribute type can set @<annotation-1> and @<annotation-2> together and unset it for <value-type> value type
    When create attribute type: name
    When attribute(name) set value type: <value-type>
    When attribute(name) set annotation: @<annotation-1>
    When attribute(name) set annotation: @<annotation-2>
    When attribute(name) get constraints contain: @<annotation-1>
    When attribute(name) get constraints contain: @<annotation-2>
    When attribute(name) get declared annotations contain: @<annotation-1>
    When attribute(name) get declared annotations contain: @<annotation-2>
    When transaction commits
    When connection open schema transaction for database: typedb
    When attribute(name) get constraints contain: @<annotation-1>
    When attribute(name) get constraints contain: @<annotation-2>
    When attribute(name) get declared annotations contain: @<annotation-1>
    When attribute(name) get declared annotations contain: @<annotation-2>
    When attribute(name) unset annotation: @<annotation-category-1>
    Then attribute(name) get constraints do not contain: @<annotation-1>
    Then attribute(name) get constraints contain: @<annotation-2>
    Then attribute(name) get declared annotations do not contain: @<annotation-1>
    Then attribute(name) get declared annotations contain: @<annotation-2>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(name) get constraints do not contain: @<annotation-1>
    Then attribute(name) get constraints contain: @<annotation-2>
    Then attribute(name) get declared annotations do not contain: @<annotation-1>
    Then attribute(name) get declared annotations contain: @<annotation-2>
    When attribute(name) set annotation: @<annotation-1>
    When attribute(name) unset annotation: @<annotation-category-2>
    Then attribute(name) get constraints do not contain: @<annotation-2>
    Then attribute(name) get constraints contain: @<annotation-1>
    Then attribute(name) get declared annotations do not contain: @<annotation-2>
    Then attribute(name) get declared annotations contain: @<annotation-1>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then attribute(name) get constraints do not contain: @<annotation-2>
    Then attribute(name) get constraints contain: @<annotation-1>
    Then attribute(name) get declared annotations do not contain: @<annotation-2>
    Then attribute(name) get declared annotations contain: @<annotation-1>
    When attribute(name) unset annotation: @<annotation-category-1>
    Then attribute(name) get constraints is empty
    Then attribute(name) get declared annotations is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(name) get constraints is empty
    Then attribute(name) get declared annotations is empty
    Examples:
      | annotation-1     | annotation-2          | annotation-category-1 | annotation-category-2 | value-type  |
      | abstract         | independent           | abstract              | independent           | datetime-tz |
      | abstract         | values(1, 2)          | abstract              | values                | double      |
      | abstract         | range(1.0dec..2.0dec) | abstract              | range                 | decimal     |
      | abstract         | regex("s")            | abstract              | regex                 | string      |
      | independent      | values(1, 2)          | independent           | values                | integer     |
      | independent      | range(false..true)    | independent           | range                 | boolean     |
      | independent      | regex("s")            | independent           | regex                 | string      |
      | values(1.0, 2.0) | range(1.0..2.0)       | values                | range                 | double      |
      | values("str")    | regex("s")            | values                | regex                 | string      |
      | range("1".."2")  | regex("s")            | range                 | regex                 | string      |

    # There are no incompatible annotations for attribute types for now
#  Scenario Outline: Owns cannot set @<annotation-1> and @<annotation-2> together for <value-type> value type
#    When create attribute type: name
#    When attribute(name) set value type: <value-type>
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    When attribute(name) set annotation: @<annotation-1>
#    Then attribute(name) set annotation: @<annotation-2>; fails
#    When transaction closes
#    When connection open schema transaction for database: typedb
#    When attribute(name) set annotation: @<annotation-2>
#    Then attribute(name) set annotation: @<annotation-1>; fails
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then attribute(name) get constraints contain: @<annotation-2>
#    Then attribute(name) get constraints do not contain: @<annotation-1>
#    Then attribute(name) get declared annotations contain: @<annotation-2>
#    Then attribute(name) get declared annotation do not contain: @<annotation-1>
#    Examples:
#      | annotation-1 | annotation-2 | value-type |

########################
# structs common
########################

  Scenario: Struct that doesn't exist cannot be deleted
    Then delete struct: passport; fails

  Scenario Outline: Struct can be created with one field, including another struct
    When create struct: passport
    Then struct(passport) exists
    Then struct(passport) get fields do not contain:
      | name |
    When struct(passport) create field: name, with value type: <value-type>
    Then struct(passport) get fields contain:
      | name |
    Then struct(passport) get field(name) get value type: <value-type>
    Then struct(passport) get field(name) is optional: false
    When transaction commits
    When connection open read transaction for database: typedb
    Then struct(passport) get fields contain:
      | name |
    Then struct(passport) get field(name) get value type: <value-type>
    Then struct(passport) get field(name) is optional: false
    Examples:
      | value-type    |
      | integer       |
      | string        |
      | boolean       |
      | double        |
      | decimal       |
      | date          |
      | datetime      |
      | datetime-tz   |
      | duration      |
      | custom-struct |

  Scenario Outline: Struct can be created with multiple fields, including another struct
    When create struct: passport
    Then struct(passport) exists
    When struct(passport) create field: id, with value type: <value-type-1>
    When struct(passport) create field: name, with value type: <value-type-2>
    Then struct(passport) get fields contain:
      | id   |
      | name |
    Then struct(passport) get field(id) get value type: <value-type-1>
    Then struct(passport) get field(id) is optional: false
    Then struct(passport) get field(name) get value type: <value-type-2>
    Then struct(passport) get field(name) is optional: false
    When transaction commits
    When connection open read transaction for database: typedb
    Then struct(passport) get fields contain:
      | id   |
      | name |
    Then struct(passport) get field(id) get value type: <value-type-1>
    Then struct(passport) get field(id) is optional: false
    Then struct(passport) get field(name) get value type: <value-type-2>
    Then struct(passport) get field(name) is optional: false
    Examples:
      | value-type-1  | value-type-2  |
      | integer       | string        |
      | string        | boolean       |
      | boolean       | double        |
      | double        | decimal       |
      | decimal       | date          |
      | date          | datetime      |
      | datetime      | datetime-tz   |
      | datetime-tz   | duration      |
      | duration      | custom-struct |
      | custom-struct | integer       |

  Scenario Outline: Struct can be created with one optional field, including another struct
    When create struct: passport
    Then struct(passport) exists
    Then struct(passport) get fields do not contain:
      | name |
    When struct(passport) create field: name, with value type: <value-type>?
    Then struct(passport) get fields contain:
      | name |
    Then struct(passport) get field(name) get value type: <value-type>
    Then struct(passport) get field(name) is optional: true
    When transaction commits
    When connection open read transaction for database: typedb
    Then struct(passport) get fields contain:
      | name |
    Then struct(passport) get field(name) get value type: <value-type>
    Then struct(passport) get field(name) is optional: true
    Examples:
      | value-type    |
      | integer       |
      | string        |
      | boolean       |
      | double        |
      | decimal       |
      | date          |
      | datetime      |
      | datetime-tz   |
      | duration      |
      | custom-struct |

  Scenario Outline: Struct can be created with multiple optional fields, including another struct
    When create struct: passport
    Then struct(passport) exists
    When struct(passport) create field: id, with value type: <value-type-1>
    When struct(passport) create field: surname, with value type: <value-type-2>?
    When struct(passport) create field: name, with value type: <value-type-2>
    When struct(passport) create field: middle-name, with value type: <value-type-2>?
    Then struct(passport) get fields contain:
      | id          |
      | name        |
      | surname     |
      | middle-name |
    Then struct(passport) get field(id) get value type: <value-type-1>
    Then struct(passport) get field(id) is optional: false
    Then struct(passport) get field(surname) get value type: <value-type-2>
    Then struct(passport) get field(surname) is optional: true
    Then struct(passport) get field(name) get value type: <value-type-2>
    Then struct(passport) get field(name) is optional: false
    Then struct(passport) get field(middle-name) get value type: <value-type-2>
    Then struct(passport) get field(middle-name) is optional: true
    When transaction commits
    When connection open read transaction for database: typedb
    Then struct(passport) get fields contain:
      | id          |
      | name        |
      | surname     |
      | middle-name |
    Then struct(passport) get field(id) get value type: <value-type-1>
    Then struct(passport) get field(id) is optional: false
    Then struct(passport) get field(surname) get value type: <value-type-2>
    Then struct(passport) get field(surname) is optional: true
    Then struct(passport) get field(name) get value type: <value-type-2>
    Then struct(passport) get field(name) is optional: false
    Then struct(passport) get field(middle-name) get value type: <value-type-2>
    Then struct(passport) get field(middle-name) is optional: true
    Examples:
      | value-type-1  | value-type-2  |
      | integer       | string        |
      | string        | boolean       |
      | boolean       | double        |
      | double        | decimal       |
      | decimal       | date          |
      | date          | datetime      |
      | datetime      | datetime-tz   |
      | datetime-tz   | duration      |
      | duration      | custom-struct |
      | custom-struct | integer       |

  Scenario: Struct without fields can be deleted
    When create struct: passport
    Then struct(passport) exists
    When delete struct: passport
    Then struct(passport) does not exist
    When create struct: passport
    Then struct(passport) exists
    When struct(passport) create field: name, with value type: string
    When transaction commits
    When connection open schema transaction for database: typedb
    Then struct(passport) exists
    When struct(passport) delete field: name
    When delete struct: passport
    Then struct(passport) does not exist
    When transaction commits
    When connection open schema transaction for database: typedb
    Then struct(passport) does not exist

  Scenario: Struct with fields can be deleted
    When create struct: passport
    When struct(passport) create field: name, with value type: string
    When delete struct: passport
    Then struct(passport) does not exist
    When create struct: passport
    When struct(passport) create field: name, with value type: string
    When struct(passport) create field: birthday, with value type: datetime
    When transaction commits
    When connection open schema transaction for database: typedb
    Then struct(passport) exists
    Then struct(passport) get fields contain:
      | name     |
      | birthday |
    When delete struct: passport
    Then struct(passport) does not exist
    When transaction commits
    When connection open schema transaction for database: typedb
    Then struct(passport) does not exist
    When create struct: passport
    When struct(passport) create field: name, with value type: string
    When transaction commits
    When connection open schema transaction for database: typedb
    When struct(passport) create field: birthday, with value type: datetime
    When delete struct: passport
    Then struct(passport) does not exist
    When transaction commits
    When connection open read transaction for database: typedb
    Then struct(passport) does not exist

  Scenario Outline: Struct can delete fields of type <value-type>
    When create struct: passport
    When struct(passport) create field: name, with value type: <value-type>
    Then struct(passport) get fields contain:
      | name |
    Then struct(passport) get field(name) get value type: <value-type>
    When struct(passport) delete field: name
    Then struct(passport) get fields do not contain:
      | name |
    When struct(passport) create field: name, with value type: <value-type>
    Then struct(passport) get fields contain:
      | name |
    Then struct(passport) get field(name) get value type: <value-type>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then struct(passport) get fields contain:
      | name |
    Then struct(passport) get field(name) get value type: <value-type>
    When struct(passport) delete field: name
    Then struct(passport) get fields do not contain:
      | name |
    When struct(passport) create field: not-name, with value type: <value-type>
    When transaction commits
    When connection open read transaction for database: typedb
    Then struct(passport) get fields do not contain:
      | name |
    Then struct(passport) get fields contain:
      | not-name |
    Examples:
      | value-type    |
      | integer       |
      | string        |
      | boolean       |
      | double        |
      | decimal       |
      | date          |
      | datetime      |
      | datetime-tz   |
      | duration      |
      | custom-struct |

  Scenario Outline: Struct cannot delete fields of type <value-type> if it doesn't exist
    When create struct: passport
    When struct(passport) create field: name, with value type: <value-type>
    When create struct: table
    Then struct(table) delete field: name; fails
    When struct(table) create field: name, with value type: <value-type>
    When transaction commits
    When connection open schema transaction for database: typedb
    When struct(table) delete field: name
    Then struct(table) delete field: name; fails
    Examples:
      | value-type    |
      | integer       |
      | string        |
      | date          |
      | custom-struct |

  Scenario: Struct cannot be redefined
    When create struct: passport
    Then create struct: passport; fails
    When struct(passport) create field: name, with value type: string
    Then create struct: passport; fails
    When transaction commits
    When connection open schema transaction for database: typedb
    Then struct(passport) exists
    Then create struct: passport; fails

  Scenario: Struct fields cannot be redefined
    When create struct: passport
    When struct(passport) create field: name, with value type: string
    When struct(passport) create field: birthday, with value type: datetime
    Then struct(passport) create field: name, with value type: string; fails
    Then struct(passport) create field: birthday, with value type: datetime; fails
    Then struct(passport) create field: name, with value type: datetime; fails
    Then struct(passport) create field: birthday, with value type: integer; fails
    When transaction commits
    When connection open read transaction for database: typedb
    Then struct(passport) exists
    Then struct(passport) get fields contain:
      | name |
    Then struct(passport) get field(name) get value type: string
    Then struct(passport) get fields contain:
      | birthday |
    Then struct(passport) get field(birthday) get value type: datetime

  Scenario: Struct cannot be commited without fields
    When create struct: passport
    Then transaction commits; fails
    When connection open read transaction for database: typedb
    Then struct(passport) does not exist
