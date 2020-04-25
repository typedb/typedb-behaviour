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
Feature: Graql Undefine Query
  Background: Create a simple schema that is extensible for each scenario
    Given connection has been opened
    Given connection delete all keyspaces
    Given connection open sessions for keyspaces:
      | test_define |
    Given transaction is initialised
    Given the integrity is validated
    Given graql define
      """
      define
      person sub entity, plays employee, has name, key email;
      employment sub relation, relates employee, relates employer;
      name sub attribute, value string;
      email sub attribute, value string, regex ".+@\w.com";
      abstract-type sub entity, abstract;
      """
    Given the integrity is validated

  Scenario: undefine a subtype removes a type
    Given graql undefine
      """
      undefine email sub attribute;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x sub attribute; get; 
      """
    Then concept identifiers are
      |       | check | value     |
      | ATTR  | label | attribute |
      | NAME  | label | name      |
    Then uniquely identify answer concepts
      | x     |
      | ATTR  |
      | NAME  |


  Scenario: undefine 'plays' from super entity removes 'plays' from subtypes
    Given graql define
      """
      define child sub person; 
      """
    Given graql undefine
      """
      undefine person plays employee;
      """
    Then the integrity is validated
    When get answers of graql query
      """
      match $x type child; $x plays $role; get; 
      """
    Then concept identifiers are
      |             | check | value             |
      | NAME_OWNER  | label | @has-name-owner   |
      | EMAIL_OWNER | label | @key-email-owner  |
      | CHILD       | label | child             |
    Then uniquely identify answer concepts
      | x     | role        |
      | CHILD | NAME_OWNER  |
      | CHILD | EMAIL_OWNER |


  @ignore
  # TODO readd when behaves correctly
  Scenario: undefine an attribute subtype removes implicit ownership relation from hierarchy
    Given graql define
      """
      define
      first-name sub name;
      person has first-name;
      """
    When get answers of graql query
      """
      match $x sub @has-name; get;
      """
    When uniquely identify answer concepts
      | x               |
      | @has-name       |
      | @has-first-name |
    Then graql undefine
      """
      undefine first-name sub name;
      """
    Then get answers of graql query
      """
      match $x sub @has-name; get; 
      """
    Then concept identifiers are
      |           | check | value     |
      | HAS_NAME  | label | @has-name |
    When uniquely identify answer concepts
      | x         |
      | HAS_NAME  |



  # TODO is this expected to hold?
  Scenario: undefine the only attribute key- and owner-ship removes implicit owner-/key-ship relation types
  Scenario: undefine attribute removes implicit ownership roles from owners
  Scenario: undefine attribute removes implicit roles


  @ignore
  # re-enable when can query by has $x
  Scenario: undefine 'has' from super entity removes 'has' from child entity
    Given graql define
      """
      define child sub person; 
      """
    Given graql undefine
      """
      undefine person has name;
      """
    Then the integrity is validated
    When get answers of graql query
      """
      match $x type child; $x has $attribute; get; 
      """
    Then concept identifiers are
      |       | check | value |
      | CHILD | label | child |
      | EMAIL | label | email |
    Then uniquely identify answer concepts
      | x     | attribute |
      | CHILD | EMAIL     |


  Scenario: undefine 'key' from super entity removes 'key' from child entity
    Given graql define
      """
      define child sub person; 
      """
    Given graql undefine
      """
      undefine person key email;
      """
    Then the integrity is validated
    When get answers of graql query
      """
      match $x type child; $x key email; get;
      """
    Then answer size is: 0

  @ignore
  # re-enable when 'relates' is inherited
  Scenario: undefine 'relates' from super relation removes 'relates' from child relation
    Given graql define
      """
      define part-time sub employment; 
      """
    Given graql undefine
      """
      undefine employment relates employer;
      """
    Then the integrity is validated
    When get answers of graql query
      """
      match $x type part-time; $x relates $role; get; 
      """
    Then concept identifiers are
      |           | check | value     |
      | EMPLOYEE  | label | employee  |
      | PART_TIME | label | part-time |
    Then uniquely identify answer concepts
      | x         | role     |
      | PART_TIME | EMPLOYEE |

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
      """
      undefine abstract-type abstract;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x abstract; get; 
      """
    Then concept identifiers are
      |           | check | value     |
      | ENTITY    | label | entity    |
      | RELATION  | label | relation  |
      | ATTRIBUTE | label | attribute |
      | THING     | label | thing     |
    Then uniquely identify answer concepts
      | x         |
      | ENTITY    |
      | RELATION  |
      | ATTRIBUTE |
      | THING     |


  @ignore
  # TODO fails same as undefine abstract; then require sub-abstract type validation
  Scenario: undefine a type as abstract errors if has abstract child types (?)
    Given graql define
      """
      define sub-abstract-type sub abstract-type, abstract;
      """
    Given the integrity is validated
    Then graql undefine throws
      """
      undefine abstract-type abstract;
      """


  Scenario: undefine a regex on an attribute type, removes regex constraints on attribute
    Given graql undefine
      """
      undefine email regex ".+@\w.com";   
      """
    Given the integrity is validated
    When graql insert
      """
      insert $x "not-email-regex" isa email; 
      """
    Given the integrity is validated
    Then get answers of graql query
      """
      match $x isa email; get;
      """
    Then answer size is: 1


  Scenario: undefine a rule removes a rule
    Given graql define
      """
      define
      company sub entity, plays employer;
      a-rule sub rule, when
      { $c isa company; $y isa person; },
      then
      { (employer: $c, employee: $y) isa employment; };
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x sub rule; get;
      """
    Then concept identifiers are
      |         | check | value   |
      | RULE    | label | rule    |
      | A_RULE  | label | a-rule  |
    When uniquely identify answer concepts
      | x       |
      | RULE    |
      | a_RULE  |
    Then graql undefine
      """
      undefine a-rule sub rule;
      """
    Then get answers of graql query
      """
      match $x sub rule; get;  
      """
    Then answer size is: 1


  Scenario: undefine a supertype errors if subtypes exist
    Given graql define
      """
      define child sub person;  
      """
    Then graql undefine throws
      """
      undefine person sub entity;
      """
