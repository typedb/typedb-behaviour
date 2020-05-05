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
    Given connection open session for keyspace: grakn
    Given session opens transaction of type: write

  Scenario: Attribute types can be created with data type
    When put attribute type: name, value class: string
    Then attribute(name) is null: false
    Then attribute(name) get supertype: attribute
    When transaction commits
    When session opens transaction of type: read
    Then attribute(name) is null: false
    Then attribute(name) get supertype: attribute

  Scenario: Attribute types can be deleted
    When put attribute type: name, value class: string
    Then attribute(name) is null: false
    When put attribute type: age, value class: long
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
    When put attribute type: name, value class: string
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
    When put attribute type: name, value class: string
    When attribute(name) set abstract: true
    When put attribute type: email, value class: string
    Then attribute(name) is abstract: true
    # Then attribute(name) creates instance successfully: false
    Then attribute(email) is abstract: false
    When transaction commits
    When session opens transaction of type: write
    Then attribute(name) is abstract: true
    # Then attribute(name) creates instance successfully: false
    Then attribute(email) is abstract: false
    When attribute(email) set abstract: true
    Then attribute(email) is abstract: true
    # Then attribute(email) creates instance successfully: false
    When transaction commits
    When session opens transaction of type: write
    Then attribute(email) is abstract: true
    # Then attribute(email) creates instance successfully: false

  Scenario: Attribute types can be subtypes of other attribute types
    When put attribute type: first-name, value class: string
    When put attribute type: last-name, value class: string
    When put attribute type: real-name, value class: string
    When put attribute type: username, value class: string
    When put attribute type: name, value class: string
    When attribute(first-name) set supertype: real-name
    When attribute(last-name) set supertype: real-name
    When attribute(real-name) set supertype: name
    When attribute(username) set supertype: name
    Then attribute(first-name) get supertype: real-name
    Then attribute(last-name) get supertype: real-name
    Then attribute(real-name) get supertype: name
    Then attribute(username) get supertype: name
    Then attribute(first-name) get supertypes contain:
      | first-name |
      | real-name  |
      | name       |
    Then attribute(last-name) get supertypes contain:
      | last-name |
      | real-name |
      | name      |
    Then attribute(real-name) get supertypes contain:
      | real-name |
      | name      |
    Then attribute(username) get supertypes contain:
      | username |
      | name     |
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
    When transaction commits
    When session opens transaction of type: read
    Then attribute(first-name) get supertype: real-name
    Then attribute(last-name) get supertype: real-name
    Then attribute(real-name) get supertype: name
    Then attribute(username) get supertype: name
    Then attribute(first-name) get supertypes contain:
      | first-name |
      | real-name  |
      | name       |
    Then attribute(last-name) get supertypes contain:
      | last-name |
      | real-name |
      | name      |
    Then attribute(real-name) get supertypes contain:
      | real-name |
      | name      |
    Then attribute(username) get supertypes contain:
      | username |
      | name     |
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

  Scenario: Attribute types can have keys
    When put attribute type: country-code, value class: string
    When put attribute type: country-name, value class: string
    When attribute(country-name) set key attribute: country-code
    Then attribute(country-name) get key attributes contain:
      | country-code |
    When transaction commits
    When session opens transaction of type: read
    Then attribute(country-name) get key attributes contain:
      | country-code |

  Scenario: Attribute types can remove keys
    When put attribute type: country-code-1, value class: string
    When put attribute type: country-code-2, value class: string
    When put attribute type: country-name, value class: string
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