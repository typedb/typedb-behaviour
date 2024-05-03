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
    Given connection opens schema transaction for database: typedb

  Scenario: Root attribute type cannot be deleted
    Then delete attribute type: attribute; fails

  Scenario: Attribute types can be created
    When put attribute type: name
    When attribute(name) set value-type: string
    Then attribute(name) exists: true
    Then attribute(name) get supertype: attribute
    When transaction commits
    When connection opens read transaction for database: typedb
    Then attribute(name) exists: true
    Then attribute(name) get supertype: attribute

  Scenario: Attribute types can be created with value type boolean
    When put attribute type: is-open
    When attribute(is-open) set value-type: boolean
    Then attribute(is-open) get value type: boolean
    When transaction commits
    When connection opens read transaction for database: typedb
    Then attribute(is-open) get value type: boolean

  Scenario: Attribute types can be created with value type long
    When put attribute type: age
    When attribute(age) set value-type: long
    Then attribute(age) get value type: long
    When transaction commits
    When connection opens read transaction for database: typedb
    Then attribute(age) get value type: long

  Scenario: Attribute types can be created with value type double
    When put attribute type: rating
    When attribute(rating) set value-type: double
    Then attribute(rating) get value type: double
    When transaction commits
    When connection opens read transaction for database: typedb
    Then attribute(rating) get value type: double

  Scenario: Attribute types can be created with value type string
    When put attribute type: name
    When attribute(name) set value-type: string
    Then attribute(name) get value type: string
    When transaction commits
    When connection opens read transaction for database: typedb
    Then attribute(name) get value type: string

  Scenario: Attribute types with value type string and regular expression can be created
    When put attribute type: email
    When attribute(email) set value-type: string
    When attribute(email) set annotation: @regex("\S+@\S+\.\S+")
    Then attribute(email) get annotations contain: @regex("\S+@\S+\.\S+")
    When transaction commits
    When connection opens read transaction for database: typedb
    Then attribute(email) get annotations contain: @regex("\S+@\S+\.\S+")

  Scenario: Attribute types can be created with value type datetime
    When put attribute type: timestamp
    When attribute(timestamp) set value-type: datetime
    Then attribute(timestamp) get value type: datetime
    When transaction commits
    When connection opens read transaction for database: typedb
    Then attribute(timestamp) get value type: datetime

  Scenario: Attribute types can be deleted
    When put attribute type: name
    When attribute(name) set value-type: string
    Then attribute(name) exists: true
    When put attribute type: age
    When attribute(age) set value-type: long
    Then attribute(age) exists: true
    When delete attribute type: age
    Then attribute(age) exists: false
    Then attribute(attribute) get subtypes do not contain:
      | age |
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then attribute(name) exists: true
    Then attribute(age) exists: false
    Then attribute(attribute) get subtypes do not contain:
      | age |
    When delete attribute type: name
    Then attribute(name) exists: false
    Then attribute(attribute) get subtypes do not contain:
      | name |
      | age  |
    When transaction commits
    When connection opens read transaction for database: typedb
    Then attribute(name) exists: false
    Then attribute(age) exists: false
    Then attribute(attribute) get subtypes do not contain:
      | name |
      | age  |

  Scenario: Attribute types that have instances cannot be deleted
    When put attribute type: name
    When attribute(name) set value-type: string
    When transaction commits
    When connection opens write transaction for database: typedb
    When $x = attribute(name) put: alice
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then delete attribute type: name; fails

  Scenario: Attribute types can change labels
    When put attribute type: name
    When attribute(name) set value-type: string
    Then attribute(name) get label: name
    When attribute(name) set label: username
    Then attribute(name) exists: false
    Then attribute(username) exists: true
    Then attribute(username) get label: username
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then attribute(username) get label: username
    When attribute(username) set label: email
    Then attribute(username) exists: false
    Then attribute(email) exists: true
    Then attribute(email) get label: email
    When transaction commits
    When connection opens read transaction for database: typedb
    Then attribute(email) exists: true
    Then attribute(email) get label: email

  Scenario: Attribute types can be set to abstract
    When put attribute type: name
    When attribute(name) set value-type: string
    When attribute(name) set annotation: @abstract
    Then attribute(name) get annotations contain: @abstract
    When transaction commits
    When connection opens schema transaction for database: typedb
    When put attribute type: email
    When attribute(email) set value-type: string
    Then attribute(email) get annotations do not contain: @abstract
    When transaction commits
    When connection opens read transaction for database: typedb
    Then attribute(name) get annotations contain: @abstract
    When connection opens schema transaction for database: typedb
    Then attribute(email) get annotations do not contain: @abstract
    When attribute(email) set annotation: @abstract
    Then attribute(email) get annotations contain: @abstract
    When transaction commits
    When connection opens schema transaction for database: typedb
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
      | attribute  |
      | first-name |
      | real-name  |
      | name       |
    Then attribute(last-name) get supertypes contain:
      | attribute |
      | last-name |
      | real-name |
      | name      |
    Then attribute(real-name) get supertypes contain:
      | attribute |
      | real-name |
      | name      |
    Then attribute(username) get supertypes contain:
      | attribute |
      | username  |
      | name      |
    Then attribute(first-name) get subtypes contain:
      | first-name |
    Then attribute(last-name) get subtypes contain:
      | last-name |
    Then attribute(real-name) get subtypes contain:
      | real-name  |
      | first-name |
      | last-name  |
    Then attribute(username) get subtypes contain:
      | username |
    Then attribute(name) get subtypes contain:
      | name       |
      | username   |
      | real-name  |
      | first-name |
      | last-name  |
    Then attribute(attribute) get subtypes contain:
      | attribute  |
      | name       |
      | username   |
      | real-name  |
      | first-name |
      | last-name  |
    When transaction commits
    When connection opens read transaction for database: typedb
    Then attribute(first-name) get supertype: real-name
    Then attribute(last-name) get supertype: real-name
    Then attribute(real-name) get supertype: name
    Then attribute(username) get supertype: name
    Then attribute(first-name) get supertypes contain:
      | attribute  |
      | first-name |
      | real-name  |
      | name       |
    Then attribute(last-name) get supertypes contain:
      | attribute |
      | last-name |
      | real-name |
      | name      |
    Then attribute(real-name) get supertypes contain:
      | attribute |
      | real-name |
      | name      |
    Then attribute(username) get supertypes contain:
      | attribute |
      | username  |
      | name      |
    Then attribute(first-name) get subtypes contain:
      | first-name |
    Then attribute(last-name) get subtypes contain:
      | last-name |
    Then attribute(real-name) get subtypes contain:
      | real-name  |
      | first-name |
      | last-name  |
    Then attribute(username) get subtypes contain:
      | username |
    Then attribute(name) get subtypes contain:
      | name       |
      | username   |
      | real-name  |
      | first-name |
      | last-name  |
    Then attribute(attribute) get subtypes contain:
      | attribute  |
      | name       |
      | username   |
      | real-name  |
      | first-name |
      | last-name  |

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
    When connection opens schema transaction for database: typedb
    Then attribute(is-open) set supertype: is-open; fails
    When connection opens schema transaction for database: typedb
    Then attribute(age) set supertype: age; fails
    When connection opens schema transaction for database: typedb
    Then attribute(rating) set supertype: rating; fails
    When connection opens schema transaction for database: typedb
    Then attribute(name) set supertype: name; fails
    When connection opens schema transaction for database: typedb
    Then attribute(timestamp) set supertype: timestamp; fails

  Scenario: Attribute types cannot subtype non abstract attribute types
    When put attribute type: name
    When attribute(name) set value-type: string
    When put attribute type: first-name
    When attribute(first-name) set value-type: string
    When put attribute type: last-name
    When attribute(last-name) set value-type: string
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then attribute(first-name) set supertype: name; fails
    When connection opens schema transaction for database: typedb
    Then attribute(last-name) set supertype: name; fails

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
    When connection opens schema transaction for database: typedb
    Then attribute(is-open) set supertype: age; fails
    When connection opens schema transaction for database: typedb
    Then attribute(is-open) set supertype: rating; fails
    When connection opens schema transaction for database: typedb
    Then attribute(is-open) set supertype: name; fails
    When connection opens schema transaction for database: typedb
    Then attribute(is-open) set supertype: timestamp; fails
    When connection opens schema transaction for database: typedb
    Then attribute(age) set supertype: is-open; fails
    When connection opens schema transaction for database: typedb
    Then attribute(age) set supertype: rating; fails
    When connection opens schema transaction for database: typedb
    Then attribute(age) set supertype: name; fails
    When connection opens schema transaction for database: typedb
    Then attribute(age) set supertype: timestamp; fails
    When connection opens schema transaction for database: typedb
    Then attribute(rating) set supertype: is-open; fails
    When connection opens schema transaction for database: typedb
    Then attribute(rating) set supertype: age; fails
    When connection opens schema transaction for database: typedb
    Then attribute(rating) set supertype: name; fails
    When connection opens schema transaction for database: typedb
    Then attribute(rating) set supertype: timestamp; fails
    When connection opens schema transaction for database: typedb
    Then attribute(name) set supertype: is-open; fails
    When connection opens schema transaction for database: typedb
    Then attribute(name) set supertype: age; fails
    When connection opens schema transaction for database: typedb
    Then attribute(name) set supertype: rating; fails
    When connection opens schema transaction for database: typedb
    Then attribute(name) set supertype: timestamp; fails
    When connection opens schema transaction for database: typedb
    Then attribute(timestamp) set supertype: is-open; fails
    When connection opens schema transaction for database: typedb
    Then attribute(timestamp) set supertype: age; fails
    When connection opens schema transaction for database: typedb
    Then attribute(timestamp) set supertype: rating; fails
    When connection opens schema transaction for database: typedb
    Then attribute(timestamp) set supertype: name; fails

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
    When connection opens read transaction for database: typedb
    Then attribute(is-open) get supertype: attribute
    Then attribute(age) get supertype: attribute
    Then attribute(rating) get supertype: attribute
    Then attribute(name) get supertype: attribute
    Then attribute(timestamp) get supertype: attribute

  # Revisit if this is still valid
#  # TODO: Doesn't need to be tied to the root since we can have abstract non-valued attribute types.
#  # Scenario: Attribute types can be retrieved by value type
#  #   Then attribute(???)  get subtypes do not contain:
#  Scenario: Attribute type root can get attribute types of a specific value type
#    When put attribute type: is-open, with value type: boolean
#    When put attribute type: age, with value type: long
#    When put attribute type: rating, with value type: double
#    When put attribute type: name, with value type: string
#    When put attribute type: timestamp, with value type: datetime
#    Then attribute(attribute) as(boolean) get subtypes contain:
#      | attribute |
#      | is-open   |
#    Then attribute(attribute) as(boolean) get subtypes do not contain:
#      | age       |
#      | rating    |
#      | name      |
#      | timestamp |
#    Then attribute(attribute) as(long) get subtypes contain:
#      | attribute |
#      | age       |
#    Then attribute(attribute) as(long) get subtypes do not contain:
#      | is-open   |
#      | rating    |
#      | name      |
#      | timestamp |
#    Then attribute(attribute) as(double) get subtypes contain:
#      | attribute |
#      | rating    |
#    Then attribute(attribute) as(double) get subtypes do not contain:
#      | is-open   |
#      | age       |
#      | name      |
#      | timestamp |
#    Then attribute(attribute) as(string) get subtypes contain:
#      | attribute |
#      | name      |
#    Then attribute(attribute) as(string) get subtypes do not contain:
#      | is-open   |
#      | age       |
#      | rating    |
#      | timestamp |
#    Then attribute(attribute) as(datetime) get subtypes contain:
#      | attribute |
#      | timestamp |
#    Then attribute(attribute) as(datetime) get subtypes do not contain:
#      | is-open |
#      | age     |
#      | rating  |
#      | name    |
#    When transaction commits
#    When connection opens read transaction for database: typedb
#    Then attribute(attribute) as(boolean) get subtypes contain:
#      | attribute |
#      | is-open   |
#    Then attribute(attribute) as(boolean) get subtypes do not contain:
#      | age       |
#      | rating    |
#      | name      |
#      | timestamp |
#    Then attribute(attribute) as(long) get subtypes contain:
#      | attribute |
#      | age       |
#    Then attribute(attribute) as(long) get subtypes do not contain:
#      | is-open   |
#      | rating    |
#      | name      |
#      | timestamp |
#    Then attribute(attribute) as(double) get subtypes contain:
#      | attribute |
#      | rating    |
#    Then attribute(attribute) as(double) get subtypes do not contain:
#      | is-open   |
#      | age       |
#      | name      |
#      | timestamp |
#    Then attribute(attribute) as(string) get subtypes contain:
#      | attribute |
#      | name      |
#    Then attribute(attribute) as(string) get subtypes do not contain:
#      | is-open   |
#      | age       |
#      | rating    |
#      | timestamp |
#    Then attribute(attribute) as(datetime) get subtypes contain:
#      | attribute |
#      | timestamp |
#    Then attribute(attribute) as(datetime) get subtypes do not contain:
#      | is-open |
#      | age     |
#      | rating  |
#      | name    |

#  Scenario: Attribute type root can get attribute types of any value type
#    When put attribute type: is-open, with value type: boolean
#    When put attribute type: age, with value type: long
#    When put attribute type: rating, with value type: double
#    When put attribute type: name, with value type: string
#    When put attribute type: timestamp, with value type: datetime
#    Then attribute(attribute) get subtypes contain:
#      | attribute |
#      | is-open   |
#      | age       |
#      | rating    |
#      | name      |
#      | timestamp |
#    When transaction commits
#    When connection opens read transaction for database: typedb
#    Then attribute(attribute) get subtypes contain:
#      | attribute |
#      | is-open   |
#      | age       |
#      | rating    |
#      | name      |
#      | timestamp |

  Scenario: Attribute types can have keys
    When put attribute type: country-code
    When attribute(country-code) set value-type: string
    When put attribute type: country-name
    When attribute(country-name) set value-type: string
    When attribute(country-name) set owns attribute type: country-code, with annotations: key
    Then attribute(country-name) get owns attribute types, with annotations: key; contain:
      | country-code |
    When transaction commits
    When connection opens read transaction for database: typedb
    Then attribute(country-name) get owns attribute types, with annotations: key; contain:
      | country-code |

  # TODO: Fix test
  Scenario: Attribute types can unset keys
    When put attribute type: country-code-1
    When attribute(country-code-1) set value-type: string
    When put attribute type: country-code-2
    When attribute(country-code-2) set value-type: string
    When put attribute type: country-name
    When attribute(country-name) set value-type: string
    When attribute(country-name) set owns attribute type: country-code-1, with annotations: key
    When attribute(country-name) set owns attribute type: country-code-2, with annotations: key
    When attribute(country-name) unset owns attribute type: country-code-1
    Then attribute(country-name) get owns attribute types, with annotations: key; do not contain:
      | country-code-1 |
    When transaction commits
    When connection opens write transaction for database: typedb
    When attribute(country-name) unset owns attribute type: country-code-2
    Then attribute(country-name) get owns attribute types, with annotations: key; do not contain:
      | country-code-1 |
      | country-code-2 |


  # TODO: DELETE. Attributes cannot own attributes
  Scenario: Attribute types can have attributes
    When put attribute type: utc-zone-code
    When attribute(utc-zone-code) set value-type: string
    When put attribute type: utc-zone-hour
    When attribute(utc-zone-hour) set value-type: double
    When put attribute type: timestamp
    When attribute(timestamp) set value-type: datetime
    When attribute(timestamp) set owns attribute type: utc-zone-code
    When attribute(timestamp) set owns attribute type: utc-zone-hour
    Then attribute(timestamp) get owns attribute types contain:
      | utc-zone-code |
      | utc-zone-hour |
    When transaction commits
    When connection opens read transaction for database: typedb
    Then attribute(timestamp) get owns attribute types contain:
      | utc-zone-code |
      | utc-zone-hour |

  # TODO: DELETE. Attributes cannot own attributes
  Scenario: Attribute types can unset attributes
    When put attribute type: utc-zone-code
    When attribute(utc-zone-code) set value-type: string
    When put attribute type: utc-zone-hour
    When attribute(utc-zone-hour) set value-type: double
    When put attribute type: timestamp
    When attribute(timestamp) set value-type: datetime
    When attribute(timestamp) set owns attribute type: utc-zone-code
    When attribute(timestamp) set owns attribute type: utc-zone-hour
    When attribute(timestamp) unset owns attribute type: utc-zone-hour
    Then attribute(timestamp) get owns attribute types do not contain:
      | utc-zone-hour |
    When transaction commits
    When connection opens write transaction for database: typedb
    When attribute(timestamp) unset owns attribute type: utc-zone-code
    Then attribute(timestamp) get owns attribute types do not contain:
      | utc-zone-code |
      | utc-zone-hour |

  # TODO: DELETE. Attributes cannot own attributes
  Scenario: Attribute types can have keys and attributes
    When put attribute type: country-code
    When attribute(country-code) set value-type: string
    When put attribute type: country-abbreviation
    When attribute(country-abbreviation) set value-type: string
    When put attribute type: country-name
    When attribute(country-name) set value-type: string
    When attribute(country-name) set owns attribute type: country-code, with annotations: key
    When attribute(country-name) set owns attribute type: country-abbreviation
    Then attribute(country-name) get owns attribute types, with annotations: key; contain:
      | country-code |
    Then attribute(country-name) get owns attribute types contain:
      | country-code         |
      | country-abbreviation |
    When transaction commits
    When connection opens read transaction for database: typedb
    Then attribute(country-name) get owns attribute types, with annotations: key; contain:
      | country-code |
    Then attribute(country-name) get owns attribute types contain:
      | country-code         |
      | country-abbreviation |

  # TODO: DELETE. Attributes cannot own attributes
  Scenario: Attribute types can inherit keys and attributes
    When put attribute type: hash
    When attribute(hash) set value-type: string
    When put attribute type: abbreviation
    When attribute(abbreviation) set value-type: string
    When put attribute type: name
    When attribute(name) set value-type: string
    When attribute(name) set annotation: @abstract
    When attribute(name) set owns attribute type: hash, with annotations: key
    When attribute(name) set owns attribute type: abbreviation
    When put attribute type: real-name
    When attribute(real-name) set value-type: string
    When attribute(real-name) set annotation: @abstract
    When attribute(real-name) set supertype: name
    Then attribute(real-name) get owns attribute types, with annotations: key; contain:
      | hash |
    Then attribute(real-name) get owns attribute types contain:
      | hash         |
      | abbreviation |
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then attribute(real-name) get owns attribute types, with annotations: key; contain:
      | hash |
    Then attribute(real-name) get owns attribute types contain:
      | hash         |
      | abbreviation |
    When put attribute type: last-name
    When attribute(last-name) set value-type: string
    When attribute(last-name) set supertype: real-name
    When transaction commits
    When connection opens read transaction for database: typedb
    Then attribute(real-name) get owns attribute types, with annotations: key; contain:
      | hash |
    Then attribute(real-name) get owns attribute types contain:
      | hash         |
      | abbreviation |
    Then attribute(last-name) get owns attribute types, with annotations: key; contain:
      | hash |
    Then attribute(last-name) get owns attribute types contain:
      | hash         |
      | abbreviation |

  # TODO: DELETE. Attributes cannot own attributes
  Scenario: Attribute types can be owned as attributes
    When put attribute type: age
    When attribute(age) set value-type: long
    When put attribute type: name
    When attribute(name) set value-type: string
    When attribute(name) set annotation: @abstract
    When put attribute type: boy-name
    When attribute(boy-name) set value-type: string
    When attribute(boy-name) set supertype: name
    When put attribute type: girl-name
    When attribute(girl-name) set value-type: string
    When attribute(girl-name) set supertype: name
    When put entity type: person
    When entity(person) set annotation: @abstract
    When entity(person) set owns attribute type: name
    When entity(person) set owns attribute type: age
    When put entity type: boy
    When entity(boy) set supertype: person
    When entity(boy) set owns attribute type: boy-name as name
    When put entity type: girl
    When entity(girl) set supertype: person
    When entity(girl) set owns attribute type: girl-name as name
    Then attribute(age) get owners contain:
      | person |
      | boy    |
      | girl   |
    Then attribute(age) get owners explicit contain:
      | person |
    Then attribute(age) get owners explicit do not contain:
      | boy    |
      | girl   |
    Then attribute(name) get owners contain:
      | person |
    Then attribute(name) get owners explicit contain:
      | person |
    Then attribute(name) get owners do not contain:
      | boy  |
      | girl |
    Then attribute(name) get owners explicit do not contain:
      | boy  |
      | girl |
    Then transaction commits
    When connection opens read transaction for database: typedb
    Then attribute(age) get owners contain:
      | person |
      | boy    |
      | girl   |
    Then attribute(age) get owners explicit contain:
      | person |
    Then attribute(age) get owners explicit do not contain:
      | boy    |
      | girl   |
    Then attribute(name) get owners contain:
      | person |
    Then attribute(name) get owners explicit contain:
      | person |
    Then attribute(name) get owners do not contain:
      | boy  |
      | girl |
    Then attribute(name) get owners explicit do not contain:
      | boy  |
      | girl |

  # TODO: DELETE. Attributes cannot own attributes
  Scenario: Attribute types can be owned as keys
    When put attribute type: email
    When attribute(email) set value-type: string
    When put entity type: company
    When entity(company) set owns attribute type: email
    When put entity type: person
    When entity(person) set owns attribute type: email, with annotations: key
    Then attribute(email) get owners contain:
      | company |
      | person  |
    Then attribute(email) get owners explicit contain:
      | company |
      | person  |
    Then attribute(email) get owners, with annotations: key; contain:
      | person |
    Then attribute(email) get owners explicit, with annotations: key; contain:
      | person |
    Then attribute(email) get owners, with annotations: key; do not contain:
      | company |
    Then attribute(email) get owners explicit, with annotations: key; do not contain:
      | company |
    Then transaction commits
    When connection opens read transaction for database: typedb
    Then attribute(email) get owners contain:
      | company |
      | person  |
    Then attribute(email) get owners explicit contain:
      | company |
      | person  |
    Then attribute(email) get owners, with annotations: key; contain:
      | person |
    Then attribute(email) get owners explicit, with annotations: key; contain:
      | person |
    Then attribute(email) get owners, with annotations: key; do not contain:
      | company |
    Then attribute(email) get owners explicit, with annotations: key; do not contain:
      | company |

  Scenario: Attribute types with value type string can unset their regular expression
    When put attribute type: email
    When attribute(email) set value-type: string
    When attribute(email) as(string) set regex: \S+@\S+\.\S+
    Then attribute(email) as(string) get regex: \S+@\S+\.\S+
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then attribute(email) as(string) unset regex
    Then attribute(email) as(string) does not have any regex
    Then transaction commits
    When connection opens read transaction for database: typedb
    Then attribute(email) as(string) does not have any regex
