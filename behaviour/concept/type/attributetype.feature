#
# Copyright (C) 2020 Grakn Labs
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#

Feature: Concept Attribute Type

  Background:
    Given connection has been opened
    Given connection delete all keyspaces
    Given connection does not have any keyspace
    Given connection create keyspace: grakn
    Given connection open schema session for keyspace: grakn
    Given session opens transaction of type: write

  Scenario: Attribute types can be created
    When put attribute type: name, with value type: string
    Then attribute(name) is null: false
    Then attribute(name) get supertype: attribute
    When transaction commits
    When session opens transaction of type: read
    Then attribute(name) is null: false
    Then attribute(name) get supertype: attribute

  Scenario: Attribute types can be created with value class boolean
    When put attribute type: is-open, with value type: boolean
    Then attribute(is-open) get value type: boolean
    When transaction commits
    When session opens transaction of type: read
    Then attribute(is-open) get value type: boolean

  Scenario: Attribute types can be created with value class long
    When put attribute type: age, with value type: long
    Then attribute(age) get value type: long
    When transaction commits
    When session opens transaction of type: read
    Then attribute(age) get value type: long

  Scenario: Attribute types can be created with value class double
    When put attribute type: rating, with value type: double
    Then attribute(rating) get value type: double
    When transaction commits
    When session opens transaction of type: read
    Then attribute(rating) get value type: double

  Scenario: Attribute types can be created with value class string
    When put attribute type: name, with value type: string
    Then attribute(name) get value type: string
    When transaction commits
    When session opens transaction of type: read
    Then attribute(name) get value type: string

  Scenario: Attribute types can be created with value class datetime
    When put attribute type: timestamp, with value type: datetime
    Then attribute(timestamp) get value type: datetime
    When transaction commits
    When session opens transaction of type: read
    Then attribute(timestamp) get value type: datetime

  Scenario: Attribute types can be deleted
    When put attribute type: name, with value type: string
    Then attribute(name) is null: false
    When put attribute type: age, with value type: long
    Then attribute(age) is null: false
    When delete attribute type: age
    Then attribute(age) is null: true
    Then attribute(attribute) get subtypes do not contain:
      | age |
    When transaction commits
    When session opens transaction of type: write
    Then attribute(name) is null: false
    Then attribute(age) is null: true
    Then attribute(attribute) get subtypes do not contain:
      | age |
    When delete attribute type: name
    Then attribute(name) is null: true
    Then attribute(attribute) get subtypes do not contain:
      | name |
      | age  |
    When transaction commits
    When session opens transaction of type: read
    Then attribute(name) is null: true
    Then attribute(age) is null: true
    Then attribute(attribute) get subtypes do not contain:
      | name |
      | age  |

  Scenario: Attribute types can change labels
    When put attribute type: name, with value type: string
    Then attribute(name) get label: name
    When attribute(name) set label: username
    Then attribute(name) is null: true
    Then attribute(username) is null: false
    Then attribute(username) get label: username
    When transaction commits
    When session opens transaction of type: write
    Then attribute(username) get label: username
    When attribute(username) set label: email
    Then attribute(username) is null: true
    Then attribute(email) is null: false
    Then attribute(email) get label: email
    When transaction commits
    When session opens transaction of type: read
    Then attribute(email) is null: false
    Then attribute(email) get label: email

  Scenario: Attribute types can be set to abstract
    When put attribute type: name, with value type: string
    When attribute(name) set abstract: true
    When put attribute type: email, with value type: string
    Then attribute(name) is abstract: true
    Then attribute(name) as(string) fails at putting an instance
    Then attribute(email) is abstract: false
    When transaction commits
    When session opens transaction of type: write
    Then attribute(name) is abstract: true
    Then attribute(name) as(string) fails at putting an instance
    Then attribute(email) is abstract: false
    When attribute(email) set abstract: true
    Then attribute(email) is abstract: true
    Then attribute(email) as(string) fails at putting an instance
    When transaction commits
    When session opens transaction of type: write
    Then attribute(email) is abstract: true
    Then attribute(email) as(string) fails at putting an instance

  Scenario: Attribute types can be subtypes of other attribute types
    When put attribute type: first-name, with value type: string
    When put attribute type: last-name, with value type: string
    When put attribute type: real-name, with value type: string
    When put attribute type: username, with value type: string
    When put attribute type: name, with value type: string
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
    When session opens transaction of type: read
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

  Scenario: Attribute types cannot subtype another attribute type of different value class
    When put attribute type: is-open, with value type: boolean
    When put attribute type: age, with value type: long
    When put attribute type: rating, with value type: double
    When put attribute type: name, with value type: string
    When put attribute type: timestamp, with value type: datetime
    Then attribute(is-open) fails at setting supertype: age
    Then attribute(is-open) fails at setting supertype: rating
    Then attribute(is-open) fails at setting supertype: name
    Then attribute(is-open) fails at setting supertype: timestamp
    Then attribute(age) fails at setting supertype: is-open
    Then attribute(age) fails at setting supertype: rating
    Then attribute(age) fails at setting supertype: name
    Then attribute(age) fails at setting supertype: timestamp
    Then attribute(rating) fails at setting supertype: is-open
    Then attribute(rating) fails at setting supertype: age
    Then attribute(rating) fails at setting supertype: name
    Then attribute(rating) fails at setting supertype: timestamp
    Then attribute(name) fails at setting supertype: is-open
    Then attribute(name) fails at setting supertype: age
    Then attribute(name) fails at setting supertype: rating
    Then attribute(name) fails at setting supertype: timestamp
    Then attribute(timestamp) fails at setting supertype: is-open
    Then attribute(timestamp) fails at setting supertype: age
    Then attribute(timestamp) fails at setting supertype: rating
    Then attribute(timestamp) fails at setting supertype: name

  Scenario: Attribute types can get the root type as the same value class
    When put attribute type: is-open, with value type: boolean
    When put attribute type: age, with value type: long
    When put attribute type: rating, with value type: double
    When put attribute type: name, with value type: string
    When put attribute type: timestamp, with value type: datetime
    Then attribute(is-open) get supertype: attribute
    Then attribute(is-open) get supertype value type: boolean
    Then attribute(age) get supertype: attribute
    Then attribute(age) get supertype value type: long
    Then attribute(rating) get supertype: attribute
    Then attribute(rating) get supertype value type: double
    Then attribute(name) get supertype: attribute
    Then attribute(name) get supertype value type: string
    Then attribute(timestamp) get supertype: attribute
    Then attribute(timestamp) get supertype value type: datetime
    When transaction commits
    When session opens transaction of type: read
    Then attribute(is-open) get supertype: attribute
    Then attribute(is-open) get supertype value type: boolean
    Then attribute(age) get supertype: attribute
    Then attribute(age) get supertype value type: long
    Then attribute(rating) get supertype: attribute
    Then attribute(rating) get supertype value type: double
    Then attribute(name) get supertype: attribute
    Then attribute(name) get supertype value type: string
    Then attribute(timestamp) get supertype: attribute
    Then attribute(timestamp) get supertype value type: datetime

  Scenario: Attribute type root can get attribute types of a specific value class
    When put attribute type: is-open, with value type: boolean
    When put attribute type: age, with value type: long
    When put attribute type: rating, with value type: double
    When put attribute type: name, with value type: string
    When put attribute type: timestamp, with value type: datetime
    Then attribute(attribute) as(boolean) get subtypes contain:
      | attribute |
      | is-open   |
    Then attribute(attribute) as(boolean) get subtypes do not contain:
      | age       |
      | rating    |
      | name      |
      | timestamp |
    Then attribute(attribute) as(long) get subtypes contain:
      | attribute |
      | age       |
    Then attribute(attribute) as(long) get subtypes do not contain:
      | is-open   |
      | rating    |
      | name      |
      | timestamp |
    Then attribute(attribute) as(double) get subtypes contain:
      | attribute |
      | rating    |
    Then attribute(attribute) as(double) get subtypes do not contain:
      | is-open   |
      | age       |
      | name      |
      | timestamp |
    Then attribute(attribute) as(string) get subtypes contain:
      | attribute |
      | name      |
    Then attribute(attribute) as(string) get subtypes do not contain:
      | is-open   |
      | age       |
      | rating    |
      | timestamp |
    Then attribute(attribute) as(datetime) get subtypes contain:
      | attribute |
      | timestamp |
    Then attribute(attribute) as(datetime) get subtypes do not contain:
      | is-open |
      | age     |
      | rating  |
      | name    |
    When transaction commits
    When session opens transaction of type: read
    Then attribute(attribute) as(boolean) get subtypes contain:
      | attribute |
      | is-open   |
    Then attribute(attribute) as(boolean) get subtypes do not contain:
      | age       |
      | rating    |
      | name      |
      | timestamp |
    Then attribute(attribute) as(long) get subtypes contain:
      | attribute |
      | age       |
    Then attribute(attribute) as(long) get subtypes do not contain:
      | is-open   |
      | rating    |
      | name      |
      | timestamp |
    Then attribute(attribute) as(double) get subtypes contain:
      | attribute |
      | rating    |
    Then attribute(attribute) as(double) get subtypes do not contain:
      | is-open   |
      | age       |
      | name      |
      | timestamp |
    Then attribute(attribute) as(string) get subtypes contain:
      | attribute |
      | name      |
    Then attribute(attribute) as(string) get subtypes do not contain:
      | is-open   |
      | age       |
      | rating    |
      | timestamp |
    Then attribute(attribute) as(datetime) get subtypes contain:
      | attribute |
      | timestamp |
    Then attribute(attribute) as(datetime) get subtypes do not contain:
      | is-open |
      | age     |
      | rating  |
      | name    |

  Scenario: Attribute type root can get attribute types of any value class
    When put attribute type: is-open, with value type: boolean
    When put attribute type: age, with value type: long
    When put attribute type: rating, with value type: double
    When put attribute type: name, with value type: string
    When put attribute type: timestamp, with value type: datetime
    Then attribute(attribute) get subtypes contain:
      | attribute |
      | is-open   |
      | age       |
      | rating    |
      | name      |
      | timestamp |
    When transaction commits
    When session opens transaction of type: read
    Then attribute(attribute) get subtypes contain:
      | attribute |
      | is-open   |
      | age       |
      | rating    |
      | name      |
      | timestamp |

  Scenario: Attribute types can have keys
    When put attribute type: country-code, with value type: string
    When put attribute type: country-name, with value type: string
    When attribute(country-name) set key attribute: country-code
    Then attribute(country-name) get key attributes contain:
      | country-code |
    When transaction commits
    When session opens transaction of type: read
    Then attribute(country-name) get key attributes contain:
      | country-code |

  Scenario: Attribute types can remove keys
    When put attribute type: country-code-1, with value type: string
    When put attribute type: country-code-2, with value type: string
    When put attribute type: country-name, with value type: string
    When attribute(country-name) set key attribute: country-code-1
    When attribute(country-name) set key attribute: country-code-2
    When attribute(country-name) remove key attribute: country-code-1
    Then attribute(country-name) get key attributes do not contain:
      | country-code-1 |
    When transaction commits
    When session opens transaction of type: write
    When attribute(country-name) remove key attribute: country-code-2
    Then attribute(country-name) get key attributes do not contain:
      | country-code-1 |
      | country-code-2 |

  Scenario: Attribute types can have attributes
    When put attribute type: utc-zone-code, with value type: string
    When put attribute type: utc-zone-hour, with value type: double
    When put attribute type: timestamp, with value type: datetime
    When attribute(timestamp) set has attribute: utc-zone-code
    When attribute(timestamp) set has attribute: utc-zone-hour
    Then attribute(timestamp) get has attributes contain:
      | utc-zone-code |
      | utc-zone-hour |
    When transaction commits
    When session opens transaction of type: read
    Then attribute(timestamp) get has attributes contain:
      | utc-zone-code |
      | utc-zone-hour |

  Scenario: Attribute types can remove attributes
    When put attribute type: utc-zone-code, with value type: string
    When put attribute type: utc-zone-hour, with value type: double
    When put attribute type: timestamp, with value type: datetime
    When attribute(timestamp) set has attribute: utc-zone-code
    When attribute(timestamp) set has attribute: utc-zone-hour
    When attribute(timestamp) remove has attribute: utc-zone-hour
    Then attribute(timestamp) get has attributes do not contain:
      | utc-zone-hour |
    When transaction commits
    When session opens transaction of type: write
    When attribute(timestamp) remove has attribute: utc-zone-code
    Then attribute(timestamp) get has attributes do not contain:
      | utc-zone-code |
      | utc-zone-hour |

  Scenario: Attribute types can have keys and attributes
    When put attribute type: country-code, with value type: string
    When put attribute type: country-abbreviation, with value type: string
    When put attribute type: country-name, with value type: string
    When attribute(country-name) set key attribute: country-code
    When attribute(country-name) set has attribute: country-abbreviation
    Then attribute(country-name) get key attributes contain:
      | country-code |
    Then attribute(country-name) get has attributes contain:
      | country-code         |
      | country-abbreviation |
    When transaction commits
    When session opens transaction of type: read
    Then attribute(country-name) get key attributes contain:
      | country-code |
    Then attribute(country-name) get has attributes contain:
      | country-code         |
      | country-abbreviation |

  Scenario: Attribute types can inherit keys and attributes
    When put attribute type: hash, with value type: string
    When put attribute type: abbreviation, with value type: string
    When put attribute type: name, with value type: string
    When attribute(name) set key attribute: hash
    When attribute(name) set has attribute: abbreviation
    When put attribute type: real-name, with value type: string
    When attribute(real-name) set supertype: name
    Then attribute(real-name) get key attributes contain:
      | hash |
    Then attribute(real-name) get has attributes contain:
      | hash         |
      | abbreviation |
    When transaction commits
    When session opens transaction of type: write
    Then attribute(real-name) get key attributes contain:
      | hash |
    Then attribute(real-name) get has attributes contain:
      | hash         |
      | abbreviation |
    When put attribute type: last-name, with value type: string
    When attribute(last-name) set supertype: real-name
    When transaction commits
    When session opens transaction of type: read
    Then attribute(real-name) get key attributes contain:
      | hash |
    Then attribute(real-name) get has attributes contain:
      | hash         |
      | abbreviation |
    Then attribute(last-name) get key attributes contain:
      | hash |
    Then attribute(last-name) get has attributes contain:
      | hash         |
      | abbreviation |