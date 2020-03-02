#
# GRAKN.AI - THE KNOWLEDGE GRAPH
# Copyright (C) 2019 Grakn Labs Ltd
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
Feature: Graql Undefine Query
  Background: Create a simple schema that is extensible for each scenario
    Given connection has been opened
    Given connection delete all keyspaces
    Given connection open sessions for keyspaces:
      | test_define |
    Given transaction is initialised
    Given the integrity is validated
    Given graql define
      | define                                                        |
      | person sub entity, plays employee, has name, key email;       |
      | employment sub relation, relates employee, relates employer;  |
      | name sub attribute, datatype string;                          |
      | email sub attribute, datatype string, regex ".+@\w.com";      |
      | abstract-type sub entity, abstract;                           |
    Given the integrity is validated

  Scenario: undefine a subtype removes a type
    Given graql undefine
      | undefine email sub attribute; |
    Given the integrity is validated
    When get answers of graql query
      | match $x sub attribute; get;  |
    Then answers are labeled
      | x         |
      | attribute |
      | name      |


  Scenario: undefine 'plays' from super entity removes 'plays' from subtypes
    Given graql define
      | define child sub person;  |
    Given graql undefine
      | undefine person plays employee; |
    Then the integrity is validated
    When get answers of graql query
      | match $x type child; $x plays $role; get;  |
    Then answers are labeled
      | x     | role             |
      | child | @has-name-owner  |
      | child | @key-email-owner |


  Scenario: undefine an attribute subtype removes implicit ownership relation from hierarchy
    Given graql define
      | define                  |
      |  first-name sub name;   |
      |  person has first-name; |
    When graql query
      | match $x sub @has-name; get; |
    When answers have labels
      | x               |
      | @has-name       |
      | @has-first-name |
    Then graql undefine
      | undefine first-name sub name; |
    Then graql query
      | match $x sub @has-name; get;  |
    Then answers have labels
      | x         |
      | @has-name |


  # TODO is this expected to hold?
  Scenario: undefine an attribute key- and owner-ship removes implicit owner-/key-ship relation types


  @ignore
  # re-enable when can query by has $x
  Scenario: undefine 'has' from super entity removes 'has' from child entity
    Given graql define
      | define child sub person;  |
    Given graql undefine
      | undefine person has name; |
    Then the integrity is validated
    When get answers of graql query
      | match $x type child; $x has $attribute; get;  |
    Then answers are labeled
      | x     | attribute |
      | child | email     |


  Scenario: undefine 'key' from super entity removes 'key' from child entity
    Given graql define
      | define child sub person;  |
    Given graql undefine
      | undefine person key email; |
    Then the integrity is validated
    When get answers of graql query
      | match $x type child; $x key email; get;  |
    Then the answer size is: 0

  @ignore
  # re-enable when 'relates' is inherited
  Scenario: undefine 'relates' from super relation removes 'relates' from child relation
    Given graql define
      | define part-time sub employment;  |
    Given graql undefine
      | undefine employment relates employer; |
    Then the integrity is validated
    When get answers of graql query
      | match $x type part-time; $x relates $role; get;  |
    Then answers are labeled
      | x         | role     |
      | part-time | employee |

  @ignore
  # re-enable when 'relates' is bound to a relation and blockable
  # TODO
  Scenario: undefine 'relates' from super relation that is overriden using 'as' removes override from child (?)

  @ignore
  # TODO
  Scenario: undefine a sub-role using 'as' removes sub-role from child relations

  # TODO these are repetitions of analogous scenarios but not using entity
  Scenario: undefine 'plays' from super relation removes 'plays' from child relation
  Scenario: undefine 'has' from super relation removes 'has' from child relation
  Scenario: undefine 'key' from super relation removes 'key' from child relation

  Scenario: undefine 'plays' from super attribute removes 'plays' from child attribute
  Scenario: undefine 'has' from super attribute removes 'has' from child attribute
  Scenario: undefine 'key' from super attribute removes 'key' from child attribute


  @ignore
  # TODO fails since undefining an abstract removes the type fully
  Scenario: undefine a type as abstract converts an abstract to concrete type and can create instances
    Given graql undefine
      | undefine abstract-type abstract; |
    Given the integrity is validated
    When get answers of graql query
      | match $x abstract; get;  |
    Then answers are labeled
      | x         |
      | entity    |
      | relation  |
      | attribute |
      | thing     |


  @ignore
  # TODO fails same as undefine abstract; then require sub-abstract type validation
  Scenario: undefine a type as abstract errors if has abstract child types (?)
    Given graql define
      | define sub-abstract-type sub abstract-type, abstract; |
    Given the integrity is validated
    Then graql undefine throws
      | undefine abstract-type abstract; |


  Scenario: undefine a regex on an attribute type, removes regex constraints on attribute
    Given graql undefine
      | undefine email regex ".+@\w.com";    |
    Given the integrity is validated
    When graql insert
      | insert $x "not-email-regex" isa email;              |
    Given the integrity is validated
    Then get answers of graql query
      | match $x isa email; get; |
    Then the answer size is: 1


  Scenario: undefine a rule removes a rule
    Given graql define
      | define company sub entity, plays employee;        |
      | arule sub rule, when                              |
      | { $c isa company; $y isa person; },               |
      | then                                              |
      | { (employer: $c, employee: $y) isa employment; }; |
    Given the integrity is validated
    When get answers of graql query
      | match $x sub rule; get; |
    When answers have labels
      | x     |
      | arule |
    Then graql undefine
      | undefine arule sub rule;  |
    Then get answers of graql query
      | match $x sub rule; get;   |
    Then answers have size: 0


  Scenario: undefine a supertype errors if subtypes exist
    Given graql define
      | define child sub person;   |
    Then graql undefine throws
      | undefine person sub entity; |
