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
    Given connection delete all databases
    Given connection open sessions for databases:
      | test_undefine |
    Given transaction is initialised
    Given the integrity is validated
    Given graql define
      """
      define
      person sub entity, plays employee, owns name, owns email @key;
      employment sub relation, relates employee, relates employer;
      name sub attribute, value string;
      email sub attribute, value string, regex ".+@\w+\..+";
      abstract-type sub entity, abstract;
      """
    Given the integrity is validated


  ############
  # ENTITIES #
  ############

  Scenario: calling 'undefine' with 'sub entity' on a subtype of 'entity' deletes it
    Given get answers of graql query
      """
      match $x sub entity; get;
      """
    Given concept identifiers are
      |     | check | value         |
      | ABS | label | abstract-type |
      | PER | label | person        |
      | ENT | label | entity        |
    Given uniquely identify answer concepts
      | x   |
      | ABS |
      | PER |
      | ENT |
    When graql undefine
      """
      undefine person sub entity;
      """
    Then the integrity is validated
    When get answers of graql query
      """
      match $x sub entity; get;
      """
    Then uniquely identify answer concepts
      | x   |
      | ABS |
      | ENT |


  Scenario: when undefining 'sub' on an entity type, specifying a type that isn't really its supertype, nothing happens
    When graql undefine
      """
      undefine person sub thing;
      """
    Then the integrity is validated
    When get answers of graql query
      """
      match $x type person; get;
      """
    When concept identifiers are
      |     | check | value  |
      | PER | label | person |
    Then uniquely identify answer concepts
      | x   |
      | PER |


  Scenario: a sub-entity type can be removed using 'sub' with its direct supertype, and its parent is preserved
    Given graql define
      """
      define child sub person;
      """
    Given the integrity is validated
    Given get answers of graql query
      """
      match $x sub person; get;
      """
    Given concept identifiers are
      |     | check | value  |
      | PER | label | person |
      | CHI | label | child  |
    Given uniquely identify answer concepts
      | x   |
      | PER |
      | CHI |
    When graql undefine
      """
      undefine child sub person;
      """
    Then the integrity is validated
    When get answers of graql query
      """
      match $x sub person; get;
      """
    Then uniquely identify answer concepts
      | x   |
      | PER |


  Scenario: if 'entity' is not the direct supertype of an entity, undefining 'sub entity' on it does nothing
    Given graql define
      """
      define child sub person;
      """
    Given the integrity is validated
    When graql undefine
      """
      undefine child sub entity;
      """
    Then the integrity is validated
    When get answers of graql query
      """
      match $x type child; get;
      """
    When concept identifiers are
      |     | check | value |
      | CHI | label | child |
    Then uniquely identify answer concepts
      | x   |
      | CHI |


  Scenario: undefining a supertype throws an error if subtypes exist
    Given graql define
      """
      define child sub person;
      """
    Given the integrity is validated
    Then graql undefine throws
      """
      undefine person sub entity;
      """
    Then the integrity is validated


  Scenario: removing a playable role from a super entity type also removes it from its subtypes
    Given graql define
      """
      define child sub person; 
      """
    Given the integrity is validated
    When graql undefine
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
    Given the integrity is validated
    When graql undefine
      """
      undefine person owns name;
      """
    Then the integrity is validated
    When get answers of graql query
      """
      match $x type child; $x owns name; get;
      """
    Then answer size is: 0


  Scenario: removing a has ownership @key from a super entity type also removes it from its subtypes
    Given graql define
      """
      define child sub person; 
      """
    Given the integrity is validated
    When graql undefine
      """
      undefine person owns email @key;
      """
    Then the integrity is validated
    When get answers of graql query
      """
      match $x type child; $x owns email @key; get;
      """
    Then answer size is: 0


  Scenario: all existing instances of an entity type must be deleted in order to undefine it
    Given get answers of graql query
      """
      match $x sub entity; get;
      """
    Given concept identifiers are
      |     | check | value         |
      | ABS | label | abstract-type |
      | PER | label | person        |
      | ENT | label | entity        |
    Given uniquely identify answer concepts
      | x   |
      | ABS |
      | PER |
      | ENT |
    Given graql insert
      """
      insert $x isa person, has name "Victor", has email "victor@grakn.ai";
      """
    Given the integrity is validated
    Then graql undefine throws
      """
      undefine person sub entity;
      """
    Then the integrity is validated
    When graql delete
      """
      match
        $x isa person;
      delete
        $x isa person;
      """
    Then the integrity is validated
    When graql undefine
      """
      undefine person sub entity;
      """
    Then the integrity is validated
    When get answers of graql query
      """
      match $x sub entity; get;
      """
    Then uniquely identify answer concepts
      | x   |
      | ABS |
      | ENT |


  #############
  # RELATIONS #
  #############

  @ignore
  # TODO: re-enable when removing a role from a relation cleans up the role
  Scenario: a relation type is removed by disassociating its roles and their roleplayers, then undefining 'sub relation'
    Given get answers of graql query
      """
      match $x sub relation; get;
      """
    Given concept identifiers are
      |     | check | value      |
      | EMP | label | employment |
      | REL | label | relation   |
    Given uniquely identify answer concepts
      | x   |
      | EMP |
      | REL |
    When graql undefine
      """
      undefine
      employment relates employee;
      employment relates employer;
      person plays employee;
      employment sub relation;
      """
    Then the integrity is validated
    When get answers of graql query
      """
      match $x sub relation; get;
      """
    Then uniquely identify answer concepts
      | x   |
      | REL |


  Scenario: undefining a relation type without also undefining its roles throws an error
    Then graql undefine throws
      """
      undefine employment sub relation;
      """
    Then the integrity is validated


  Scenario: undefining a relation type and its roles without disassociating them from their roleplayers throws an error
    Then graql undefine throws
      """
      undefine
      employment relates employee;
      employment relates employer;
      employment sub relation;
      """
    Then the integrity is validated


  Scenario: removing playable roles from a super relation type also removes them from its subtypes
    Given graql define
      """
      define
      employment-terms sub relation, relates employment-with-terms;
      employment plays employment-with-terms;
      contract-employment sub employment, relates employee, relates employer;
      """
    Given the integrity is validated
    Given get answers of graql query
      """
      match contract-employment plays $x; get;
      """
    Given concept identifiers are
      |     | check | value                 |
      | EWT | label | employment-with-terms |
    Given uniquely identify answer concepts
      | x   |
      | EWT |
    When graql undefine
      """
      undefine employment plays employment-with-terms;
      """
    Then the integrity is validated
    When get answers of graql query
      """
      match contract-employment plays $x; get;
      """
    Then answer size is: 0


  Scenario: removing attribute ownerships from a super relation type also removes them from its subtypes
    Given graql define
      """
      define
      start-date sub attribute, value datetime;
      employment owns start-date;
      contract-employment sub employment, relates employee, relates employer;
      """
    Given the integrity is validated
    Given get answers of graql query
      """
      match $x owns start-date; get;
      """
    Given concept identifiers are
      |     | check | value               |
      | EMP | label | employment          |
      | CEM | label | contract-employment |
    Given uniquely identify answer concepts
      | x   |
      | EMP |
      | CEM |
    When graql undefine
      """
      undefine employment owns start-date;
      """
    Then the integrity is validated
    When get answers of graql query
      """
      match $x owns start-date; get;
      """
    Then answer size is: 0


  Scenario: removing has ownerships @key from a super relation type also removes them from its subtypes
    Given graql define
      """
      define
      employment-reference sub attribute, value string;
      employment owns employment-reference @key;
      contract-employment sub employment, relates employee, relates employer;
      """
    Given the integrity is validated
    Given get answers of graql query
      """
      match $x owns employment-reference @key; get;
      """
    Given concept identifiers are
      |     | check | value               |
      | EMP | label | employment          |
      | CEM | label | contract-employment |
    Given uniquely identify answer concepts
      | x   |
      | EMP |
      | CEM |
    When graql undefine
      """
      undefine employment owns employment-reference @key;
      """
    Then the integrity is validated
    When get answers of graql query
      """
      match $x owns employment-reference @key; get;
      """
    Then answer size is: 0


  Scenario: undefining a relation type throws on commit if it has existing instances
    Given graql insert
      """
      insert
      $p isa person, has name "Harald", has email "harald@grakn.ai";
      $r (employee: $p) isa employment;
      """
    Given the integrity is validated
    Then graql undefine throws
      """
      undefine
      employment relates employee;
      employment relates employer;
      person plays employee;
      employment sub relation;
      """
    Then the integrity is validated


  @ignore
  # TODO: re-enable when removing a role from a relation cleans up the role
  Scenario: all existing instances of a relation type must be deleted in order to undefine it
    Given get answers of graql query
      """
      match $x sub relation; get;
      """
    Given concept identifiers are
      |     | check | value      |
      | EMP | label | employment |
      | REL | label | relation   |
    Given uniquely identify answer concepts
      | x   |
      | EMP |
      | REL |
    Given graql insert
      """
      insert
      $p isa person, has name "Harald", has email "harald@grakn.ai";
      $r (employee: $p) isa employment;
      """
    Given the integrity is validated
    Then graql undefine throws
      """
      undefine
      employment relates employee;
      employment relates employer;
      person plays employee;
      employment sub relation;
      """
    Then the integrity is validated
    When graql delete
      """
      match
        $r isa employment;
      delete
        $r isa employment;
      """
    Then the integrity is validated
    When graql undefine
      """
      undefine
      employment relates employee;
      employment relates employer;
      person plays employee;
      employment sub relation;
      """
    Then the integrity is validated
    When get answers of graql query
      """
      match $x sub relation; get;
      """
    Then uniquely identify answer concepts
      | x   |
      | REL |


  ##################################
  # ROLES IN RELATIONS ('RELATES') #
  ##################################

  @ignore
  # TODO: re-enable when removing a role from a relation cleans up the role
  Scenario: a role is removed by removing it from its relation type and disassociating its roleplayers
    Given get answers of graql query
      """
      match employment relates $x; get;
      """
    Given concept identifiers are
      |     | check | value    |
      | EME | label | employee |
      | EMR | label | employer |
    Given uniquely identify answer concepts
      | x   |
      | EME |
      | EMR |
    When graql undefine
      """
      undefine
      person plays employee;
      employment relates employee;
      """
    Then the integrity is validated
    When get answers of graql query
      """
      match employment relates $x; get;
      """
    Then uniquely identify answer concepts
      | x   |
      | EMR |


  Scenario: removing a role without disassociating its roleplayers throws an error
    Then graql undefine throws
      """
      undefine
      employment relates employee;
      """
    Then the integrity is validated


  Scenario: undefining all players of a role produces a valid schema
    When graql undefine
      """
      undefine person plays employee;
      """
    Then the integrity is validated
    When get answers of graql query
      """
      match $x plays employee; get;
      """
    Then answer size is: 0


  @ignore
  # TODO: re-enable when removing a role from a relation cleans up the role
  Scenario: after removing a role from a relation type, relation instances can no longer be created with that role
    Given graql insert
      """
      insert
      $p isa person, has email "ganesh@grakn.ai";
      $r (employee: $p) isa employment;
      """
    Given the integrity is validated
    Given graql delete
      """
      match
        $r isa employment;
      delete
        $r isa employment;
      """
    Given the integrity is validated
    When graql undefine
      """
      undefine
      person plays employee;
      employment relates employee;
      """
    Then the integrity is validated
    When get answers of graql query
      """
      match $x relates employee; get;
      """
    Then answer size is: 0
    Then graql insert throws
      """
      match
        $p isa person, has email "ganesh@grakn.ai";
      insert
        $r (employee: $p) isa employment;
      """
    Then the integrity is validated


  @ignore
  # TODO: re-enable when removing a role from a relation cleans up the role
  Scenario: after removing a role from a relation type without commit, its instances can no longer have that role
    Given graql insert
      """
      insert
      $p isa person, has email "ganesh@grakn.ai";
      $r (employee: $p) isa employment;
      """
    Given the integrity is validated
    Given graql delete
      """
      match
        $r isa employment;
      delete
        $r isa employment;
      """
    Given the integrity is validated
    When graql undefine without commit
      """
      undefine
      person plays employee;
      employment relates employee;
      """
    Then the integrity is validated
    When get answers of graql query
      """
      match $x relates employee; get;
      """
    Then answer size is: 0
    Then graql insert throws
      """
      match
        $p isa person, has email "ganesh@grakn.ai";
      insert
        $r (employee: $p) isa employment;
      """
    Then the integrity is validated


  Scenario: removing all roles from a relation type, without removing the type, throws an error
    Then graql undefine throws
      """
      undefine
      employment relates employee;
      employment relates employer;
      """
    Then the integrity is validated


  @ignore
  # TODO: re-enable when removing a role from a relation cleans up the role
  Scenario: removing a role throws an error if it is played by existing roleplayers in relations
    Given graql define
      """
      define
      company sub entity, owns name, plays employer;
      """
    Given the integrity is validated
    Given graql insert
      """
      insert
      $p isa person, has name "Ada", has email "ada@grakn.ai";
      $c isa company, has name "IBM";
      $r (employee: $p, employer: $c) isa employment;
      """
    Given the integrity is validated
    Then graql undefine throws
      """
      undefine employment relates employer;
      """
    Then the integrity is validated


  @ignore
  # TODO: re-enable when removing a role from a relation cleans up the role
  Scenario: a role that is not played in any existing instance of its relation type can be safely removed
    Given graql insert
      """
      insert
      $p isa person, has name "Vijay", has email "vijay@grakn.ai";
      $r (employee: $p) isa employment;
      """
    Given the integrity is validated
    When graql undefine
      """
      undefine employment relates employer;
      """
    Then the integrity is validated
    When get answers of graql query
      """
      match employment relates $x; get;
      """
    When concept identifiers are
      |     | check | value    |
      | EME | value | employee |
    Then uniquely identify answer concepts
      | x   |
      | EME |


  @ignore
  # TODO: re-enable when 'relates' is inherited
  Scenario: removing a role from a super relation type also removes it from its subtypes
    Given graql define
      """
      define part-time sub employment;
      """
    Given the integrity is validated
    When graql undefine
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
  Scenario: after undefining a sub-role from a relation type, it is gone and the type is left with just its parent role


  ###################################
  # ROLES PLAYED BY TYPES ('PLAYS') #
  ###################################

  Scenario: after undefining a playable role from a type, the type can no longer play the role
    Given graql insert
      """
      insert
      $p isa person, has email "ganesh@grakn.ai";
      $r (employee: $p) isa employment;
      """
    Given the integrity is validated
    Given graql delete
      """
      match
        $r isa employment;
      delete
        $r isa employment;
      """
    Given the integrity is validated
    When graql undefine
      """
      undefine person plays employee;
      """
    Then the integrity is validated
    When get answers of graql query
      """
      match $x plays employee; get;
      """
    Then answer size is: 0
    Then graql insert throws
      """
      match
        $p isa person, has email "ganesh@grakn.ai";
      insert
        $r (employee: $p) isa employment;
      """
    Then the integrity is validated


  # TODO: why is this ok, but undefining a not-actually-owned attribute ownership is not ok?
  Scenario: attempting to undefine a playable role that was not actually playable to begin with does nothing
    Given get answers of graql query
      """
      match person plays $x; get;
      """
    Given concept identifiers are
      |     | check | value    |
      | EMP | label | employee |
    Given uniquely identify answer concepts
      | x   |
      | EMP |
    When graql undefine
      """
      undefine person plays employer;
      """
    Then the integrity is validated
    When get answers of graql query
      """
      match person plays $x; get;
      """
    Then uniquely identify answer concepts
      | x   |
      | EMP |


  ##############
  # ATTRIBUTES #
  ##############

  Scenario Outline: calling 'undefine' with 'sub attribute' on an attribute type with value '<type>' removes it
    Given graql define
      """
      define <attr> sub attribute, value <type>;
      """
    Given the integrity is validated
    Given get answers of graql query
      """
      match $x type <attr>; get;
      """
    Given answer size is: 1
    When graql undefine
      """
      undefine <attr> sub attribute;
      """
    Then the integrity is validated
    Then graql get throws
      """
      match $x type <attr>; get;
      """

    Examples:
      | type     | attr       |
      | string   | colour     |
      | long     | age        |
      | double   | height     |
      | boolean  | is-awake   |
      | datetime | birth-date |


  Scenario: undefining a regex on an attribute type removes the regex constraints on the attribute
    When graql undefine
      """
      undefine email regex ".+@\w+\..+";
      """
    Then the integrity is validated
    When graql insert
      """
      insert $x "not-email-regex" isa email;
      """
    Then the integrity is validated
    When get answers of graql query
      """
      match $x isa email; get;
      """
    Then answer size is: 1


  Scenario: undefining the wrong regex from an attribute type does nothing
    When graql undefine
      """
      undefine email regex ".+@\w.com";
      """
    Then the integrity is validated
    When get answers of graql query
      """
      match $x regex ".+@\w+\..+"; get;
      """
    When concept identifiers are
      |     | check | value |
      | EMA | label | email |
    Then uniquely identify answer concepts
      | x   |
      | EMA |


  Scenario: removing playable roles from a super attribute type also removes them from its subtypes
    Given graql define
      """
      define
      first-name sub name;
      employment relates manager-name;
      name plays manager-name;
      """
    Given the integrity is validated
    Given get answers of graql query
      """
      match first-name plays $x; get;
      """
    Given concept identifiers are
      |     | check | value        |
      | MNA | label | manager-name |
    Given uniquely identify answer concepts
      | x   |
      | MNA |
    When graql undefine
      """
      undefine name plays manager-name;
      """
    Then the integrity is validated
    When get answers of graql query
      """
      match first-name plays $x; get;
      """
    Then answer size is: 0


  Scenario: removing attribute ownerships from a super attribute type also removes them from its subtypes
    Given graql define
      """
      define
      first-name sub name;
      locale sub attribute, value string;
      name owns locale;
      """
    Given the integrity is validated
    Given get answers of graql query
      """
      match $x owns locale; get;
      """
    Given concept identifiers are
      |     | check | value      |
      | NAM | label | name       |
      | FNA | label | first-name |
    Given uniquely identify answer concepts
      | x   |
      | NAM |
      | FNA |
    When graql undefine
      """
      undefine name owns locale;
      """
    Then the integrity is validated
    When get answers of graql query
      """
      match $x owns locale; get;
      """
    Then answer size is: 0


  Scenario: removing has ownerships @key from a super attribute type also removes them from its subtypes
    Given graql define
      """
      define
      first-name sub name;
      name-id sub attribute, value long;
      name owns name-id @key;
      """
    Given the integrity is validated
    Given get answers of graql query
      """
      match $x owns name-id @key; get;
      """
    Given concept identifiers are
      |     | check | value      |
      | NAM | label | name       |
      | FNA | label | first-name |
    Given uniquely identify answer concepts
      | x   |
      | NAM |
      | FNA |
    When graql undefine
      """
      undefine name owns name-id @key;
      """
    Then the integrity is validated
    When get answers of graql query
      """
      match $x owns name-id @key; get;
      """
    Then answer size is: 0


  Scenario: an attribute and its self-ownership can be removed simultaneously
    Given graql define
      """
      define
      name owns name;
      """
    Given the integrity is validated
    When graql undefine
      """
      undefine
      name owns name;
      name sub attribute;
      """
    Then the integrity is validated
    Then graql get throws
      """
      match $x type name; get;
      """


  Scenario: undefining the value type of an attribute does nothing
    When graql undefine
      """
      undefine name value string;
      """
    Then the integrity is validated
    When get answers of graql query
      """
      match
        $x type name;
        $x value string;
      get;
      """
    When concept identifiers are
      |     | check | value |
      | NAM | label | name  |
    Then uniquely identify answer concepts
      | x   |
      | NAM |


  Scenario: all existing instances of an attribute type must be deleted in order to undefine it
    Given get answers of graql query
      """
      match $x sub attribute; get;
      """
    Given concept identifiers are
      |     | check | value     |
      | NAM | label | name      |
      | EMA | label | email     |
      | ATT | label | attribute |
    Given uniquely identify answer concepts
      | x   |
      | NAM |
      | EMA |
      | ATT |
    Given graql insert
      """
      insert $x "Colette" isa name;
      """
    Given the integrity is validated
    Then graql undefine throws
      """
      undefine name sub attribute;
      """
    Then the integrity is validated
    When graql delete
      """
      match
        $x isa name;
      delete
        $x isa name;
      """
    Then the integrity is validated
    When graql undefine
      """
      undefine name sub attribute;
      """
    Then the integrity is validated
    When get answers of graql query
      """
      match $x sub attribute; get;
      """
    Then uniquely identify answer concepts
      | x   |
      | EMA |
      | ATT |


  ########################
  # ATTRIBUTE OWNERSHIPS #
  ########################

  Scenario: undefining an attribute ownership removes it
    Given get answers of graql query
      """
      match
        $x owns name;
        $x type person;
      get;
      """
    Given concept identifiers are
      |     | check | value  |
      | PER | label | person |
    Given uniquely identify answer concepts
      | x   |
      | PER |
    When graql undefine
      """
      undefine person owns name;
      """
    Then the integrity is validated
    When get answers of graql query
      """
      match
        $x owns name;
        $x type person;
      get;
      """
    Then answer size is: 0


  Scenario: attempting to undefine an attribute ownership that was not actually owned to begin with throws an error
    Then graql undefine throws
      """
      undefine employment owns name;
      """
    Then the integrity is validated


  Scenario: attempting to undefine an attribute ownership inherited from a parent throws an error
    Given graql define
      """
      define child sub person;
      """
    Given the integrity is validated
    Then graql undefine throws
      """
      undefine child owns name;
      """
    Then the integrity is validated


  Scenario: undefining a has ownership @key removes it
    Given get answers of graql query
      """
      match
        $x owns email @key;
        $x type person;
      get;
      """
    Given concept identifiers are
      |     | check | value  |
      | PER | label | person |
    Given uniquely identify answer concepts
      | x   |
      | PER |
    When graql undefine
      """
      undefine person owns email @key;
      """
    Then the integrity is validated
    When get answers of graql query
      """
      match
        $x owns email @key;
        $x type person;
      get;
      """
    Then answer size is: 0


  Scenario: attempting to undefine a has ownership @key that doesn't exist throws an error
    Then graql undefine throws
      """
      undefine employment owns email @key;
      """
    Then the integrity is validated


  @ignore
  # TODO: need to decide how this should behave
  Scenario: undefining an attribute owned with 'key' by using 'has' removes ownership / does nothing / throws (?)
    Then graql undefine throws
      """
      undefine person owns email;
      """
    Then the integrity is validated


  Scenario: attempting to undefine an attribute owned with 'has' by using 'key' throws an error
    Then graql undefine throws
      """
      undefine person owns name @key;
      """
    Then the integrity is validated


  Scenario: when an attribute owner owns instances, but none of them own that attribute, the ownership can be removed
    Given get answers of graql query
      """
      match $x owns name; get;
      """
    Given concept identifiers are
      |     | check | value  |
      | PER | label | person |
    Given uniquely identify answer concepts
      | x   |
      | PER |
    Given graql insert
      """
      insert $x isa person, has email "anon@grakn.ai";
      """
    Given the integrity is validated
    When graql undefine
      """
      undefine person owns name;
      """
    Then the integrity is validated
    When get answers of graql query
      """
      match $x owns name; get;
      """
    Then answer size is: 0


  Scenario: undefining an attribute ownership throws an error if any instance of the owner owns that attribute
    Given graql insert
      """
      insert $x isa person, has name "Tomas", has email "tomas@grakn.ai";
      """
    Given the integrity is validated
    Then graql undefine throws
      """
      undefine person owns name;
      """
    Then the integrity is validated


  Scenario: undefining a type's has ownership @key throws an error if it has existing instances
    Given graql insert
      """
      insert $x isa person, has name "Daniel", has email "daniel@grakn.ai";
      """
    Given the integrity is validated
    Then graql undefine throws
      """
      undefine person owns email @key;
      """
    Then the integrity is validated


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
    When graql undefine
      """
      undefine a-rule sub rule;
      """
    Then the integrity is validated
    Then get answers of graql query
      """
      match $x sub rule; get;
      """
    Then answer size is: 1


  Scenario: after undefining a rule, concepts previously inferred by that rule are no longer inferred
    Given graql define
      """
      define
      samuel-email-rule sub rule, when {
        $x has email "samuel@grakn.ai";
      }, then {
        $x has name "Samuel";
      };
      """
    Given the integrity is validated
    Given graql insert
      """
      insert $x isa person, has email "samuel@grakn.ai";
      """
    Given the integrity is validated
    Given get answers of graql query
      """
      match
        $x has name $n;
      get $n;
      """
    Given concept identifiers are
      |     | check | value       |
      | SAM | value | name:Samuel |
    Given uniquely identify answer concepts
      | n   |
      | SAM |
    When graql undefine
      """
      undefine samuel-email-rule sub rule;
      """
    Then the integrity is validated
    When get answers of graql query
      """
      match
        $x has name $n;
      get $n;
      """
    Then answer size is: 0


  Scenario: after undefining a rule without a commit, concepts previously inferred by that rule are still inferred
    Given graql define
      """
      define
      samuel-email-rule sub rule, when {
        $x has email "samuel@grakn.ai";
      }, then {
        $x has name "Samuel";
      };
      """
    Given the integrity is validated
    Given graql insert
      """
      insert $x isa person, has email "samuel@grakn.ai";
      """
    Given the integrity is validated
    Given get answers of graql query
      """
      match
        $x has name $n;
      get $n;
      """
    Given concept identifiers are
      |     | check | value       |
      | SAM | value | name:Samuel |
    Given uniquely identify answer concepts
      | n   |
      | SAM |
    When graql undefine without commit
      """
      undefine samuel-email-rule sub rule;
      """
    Then the integrity is validated
    When get answers of graql query
      """
      match
        $x has name $n;
      get $n;
      """
    Then uniquely identify answer concepts
      | n   |
      | SAM |


  ############
  # ABSTRACT #
  ############

  Scenario: undefining a type as abstract converts an abstract to a concrete type, allowing creation of instances
    Given get answers of graql query
      """
      match
        $x type abstract-type;
        not { $x abstract; };
      get;
      """
    Given answer size is: 0
    Given graql insert throws
      """
      insert $x isa abstract-type;
      """
    Given the integrity is validated
    Given graql undefine
      """
      undefine abstract-type abstract;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match
        $x type abstract-type;
        not { $x abstract; };
      get;
      """
    Then concept identifiers are
      |     | check | value         |
      | ABS | label | abstract-type |
    Then uniquely identify answer concepts
      | x   |
      | ABS |
    When graql insert
      """
      insert $x isa abstract-type;
      """
    Then the integrity is validated
    When get answers of graql query
      """
      match $x isa abstract-type; get;
      """
    Then answer size is: 1


  Scenario: undefining abstract on a type that is already non-abstract does nothing
    When graql undefine
      """
      undefine person abstract;
      """
    Then the integrity is validated
    When get answers of graql query
      """
      match
        $x type person;
        not { $x abstract; };
      get;
      """
    When concept identifiers are
      |     | check | value  |
      | PER | label | person |
    Then uniquely identify answer concepts
      | x   |
      | PER |


  Scenario: an abstract type can be changed into a concrete type even if has an abstract child type
    Given graql define
      """
      define sub-abstract-type sub abstract-type, abstract;
      """
    Given the integrity is validated
    When graql undefine
      """
      undefine abstract-type abstract;
      """
    Then the integrity is validated
    When get answers of graql query
      """
      match
        $x type abstract-type;
        not { $x abstract; };
      get;
      """
    When concept identifiers are
      |     | check | value         |
      | ABS | label | abstract-type |
    Then uniquely identify answer concepts
      | x   |
      | ABS |


  Scenario: undefining abstract on an attribute type is allowed, even if that attribute type has an owner
    Given graql define
      """
      define
      vehicle-registration sub attribute, value string, abstract;
      car-registration sub vehicle-registration;
      person owns vehicle-registration;
      """
    Given the integrity is validated
    When graql undefine
      """
      undefine
      vehicle-registration abstract;
      """
    Then the integrity is validated
    When get answers of graql query
      """
      match
        $x type vehicle-registration;
        not { $x abstract; };
      get;
      """
    Then answer size is: 1


  ###################
  # COMPLEX QUERIES #
  ###################

  Scenario: a type and an attribute type that it owns can be removed simultaneously
    Given concept identifiers are
      |     | check | value         |
      | PER | label | person        |
      | ABS | label | abstract-type |
      | ENT | label | entity        |
      | NAM | label | name          |
      | EMA | label | email         |
      | ATT | label | attribute     |
    Given get answers of graql query
      """
      match $x sub entity; get;
      """
    Given uniquely identify answer concepts
      | x   |
      | PER |
      | ABS |
      | ENT |
    Given get answers of graql query
      """
      match $x sub attribute; get;
      """
    Given uniquely identify answer concepts
      | x   |
      | NAM |
      | EMA |
      | ATT |
    When graql undefine
      """
      undefine
      person sub entity, owns name;
      name sub attribute;
      """
    Then the integrity is validated
    When get answers of graql query
      """
      match $x sub entity; get;
      """
    Then uniquely identify answer concepts
      | x   |
      | ABS |
      | ENT |
    When get answers of graql query
      """
      match $x sub attribute; get;
      """
    Then uniquely identify answer concepts
      | x   |
      | EMA |
      | ATT |


  @ignore
  # TODO: re-enable when removing a relation type cleans up its roles
  Scenario: a type, a relation type that it plays in and an attribute type that it owns can be removed simultaneously
    Given concept identifiers are
      |     | check | value         |
      | PER | label | person        |
      | ABS | label | abstract-type |
      | ENT | label | entity        |
      | EMP | label | employment    |
      | REL | label | relation      |
      | EME | label | employee      |
      | EMR | label | employer      |
      | ROL | label | role          |
      | NAM | label | name          |
      | EMA | label | email         |
      | ATT | label | attribute     |
    Given get answers of graql query
      """
      match $x sub entity; get;
      """
    Given uniquely identify answer concepts
      | x   |
      | PER |
      | ABS |
      | ENT |
    Given get answers of graql query
      """
      match $x sub relation; get;
      """
    Given uniquely identify answer concepts
      | x   |
      | EMP |
      | REL |
    Given get answers of graql query
      """
      match $x sub attribute; get;
      """
    Given uniquely identify answer concepts
      | x   |
      | NAM |
      | EMA |
      | ATT |
    Given get answers of graql query
      """
      match $x sub role; get;
      """
    Given uniquely identify answer concepts
      | x   |
      | EME |
      | EMR |
      | ROL |
    When graql undefine
      """
      undefine
      person sub entity, owns name, owns email @key, plays employee;
      employment sub relation, relates employee, relates employer;
      name sub attribute;
      """
    Then the integrity is validated
    When get answers of graql query
      """
      match $x sub entity; get;
      """
    Then uniquely identify answer concepts
      | x   |
      | ABS |
      | ENT |
    When get answers of graql query
      """
      match $x sub relation; get;
      """
    Then uniquely identify answer concepts
      | x   |
      | REL |
    When get answers of graql query
      """
      match $x sub attribute; get;
      """
    Then uniquely identify answer concepts
      | x   |
      | EMA |
      | ATT |
    When get answers of graql query
      """
      match $x sub role; get;
      """
    Then uniquely identify answer concepts
      | x   |
      | ROL |
