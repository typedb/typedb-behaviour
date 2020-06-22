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

  Background: Open connection and create a simple extensible schema
    Given connection has been opened
    Given connection delete all keyspaces
    Given connection open sessions for keyspaces:
      | test_undefine |
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


  ############
  # ENTITIES #
  ############

  Scenario: undefining an entity type removes it

  Scenario: undefining a subtype preserves its parent type

  Scenario: undefining a supertype throws an error if subtypes exist
    Given graql define
      """
      define child sub person;
      """
    Then graql undefine throws
      """
      undefine person sub entity;
      """
    Then the integrity is validated


  Scenario: removing playable roles from a super entity type also removes them from its subtypes
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
      match $x type child; $x plays employee; get;
      """
    Then answer size is: 0


  Scenario: removing an attribute ownership from a super entity type also removes it from its subtypes
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
      match $x type child; $x has name; get;
      """
    Then answer size is: 0


  Scenario: removing a key ownership from a super entity type also removes it from its subtypes
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
  # TODO fails since undefining an abstract removes the type fully
  Scenario: undefining a type as abstract converts an abstract to a concrete type, allowing creation of instances
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
  Scenario: undefining a type as abstract errors if has abstract child types (?)
    Given graql define
      """
      define sub-abstract-type sub abstract-type, abstract;
      """
    Given the integrity is validated
    Then graql undefine throws
      """
      undefine abstract-type abstract;
      """
    Then the integrity is validated


  Scenario: undefining an entity type throws on commit if it has existing instances

  Scenario: once the existing instances have been deleted, an entity type can be undefined

  #############
  # RELATIONS #
  #############

  Scenario: undefining a relation type and its roles removes them

  Scenario: undefining a relation type throws on commit if its roles are left behind, still played by other types

  @ignore
  # re-enable when 'relates' is inherited
  Scenario: removing a role from a super relation type also removes it from its subtypes
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
  # TODO: re-enable when 'relates' is bound to a relation and blockable
  Scenario: removing a role from a super relation type removes it from subtypes, even if they block it using 'as' (?)

  @ignore
  # TODO: re-enable when 'relates' is inherited
  Scenario: after undefining a sub-role from a relation type, it is gone and the type is left with just the parent role

  Scenario: removing playable roles from a super relation type also removes them from its subtypes

  Scenario: removing attribute ownerships from a super relation type also removes them from its subtypes

  Scenario: removing key ownerships from a super relation type also removes them from its subtypes

  Scenario: undefining a relation type throws on commit if it has existing instances

  Scenario: once the existing instances have been deleted, a relation type can be undefined

  Scenario: undefining a role throws on commit if it is played by existing roleplayers in relations

  Scenario: a role can be undefined when there are existing relations, as long as none of them have that roleplayer


  ##############
  # ATTRIBUTES #
  ##############

  # TODO: implement this
  Scenario Outline: undefining an attribute type with value `<type>` removes it
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
      |      | check | value     |
      | ATTR | label | attribute |
      | NAME | label | name      |
    Then uniquely identify answer concepts
      | x    |
      | ATTR |
      | NAME |

    Examples:
      | type     |
      | string   |
      | long     |
      | double   |
      | boolean  |
      | datetime |


  Scenario: removing playable roles from a super attribute type also removes them from its subtypes

  Scenario: removing attribute ownerships from a super attribute type also removes them from its subtypes

  Scenario: removing key ownerships from a super attribute type also removes them from its subtypes

  Scenario: undefining a regex on an attribute type removes the regex constraints on the attribute
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


  Scenario: undefining an attribute type throws on commit if it has existing instances

  Scenario: once the existing instances have been deleted, an attribute type can be undefined

  Scenario: when an attribute owner has instances, but none of them own that attribute, the ownership can be removed

  Scenario: undefining an attribute ownership throws on commit if any instance of the owner owns that attribute

  Scenario: undefining a key ownership always throws on commit if there are existing instances of the owner


  #########
  # RULES #
  #########

  Scenario: undefining a rule removes it
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
      |        | check | value  |
      | RULE   | label | rule   |
      | A_RULE | label | a-rule |
    When uniquely identify answer concepts
      | x      |
      | RULE   |
      | A_RULE |
    Then graql undefine
      """
      undefine a-rule sub rule;
      """
    Then get answers of graql query
      """
      match $x sub rule; get;
      """
    Then answer size is: 1
