#
# Copyright (C) 2022 Vaticle
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

#noinspection CucumberUndefinedStep
Feature: TypeQL Undefine Query

  Background: Open connection and create a simple extensible schema
    Given typedb starts
    Given connection opens with default authentication
    Given connection has been opened
    Given connection does not have any database
    Given connection create database: typedb
    Given connection open schema session for database: typedb
    Given session opens transaction of type: write

    Given typeql define
      """
      define
      person sub entity, plays employment:employee, owns name, owns email @key;
      employment sub relation, relates employee, relates employer;
      name sub attribute, value string;
      email sub attribute, value string, regex ".+@\w+\..+";
      abstract-type sub entity, abstract;
      """
    Given transaction commits

    Given session opens transaction of type: write


  ################
  # ENTITY TYPES #
  ################

  Scenario: calling 'undefine' with 'sub entity' on a subtype of 'entity' deletes it
    Given get answers of typeql match
      """
      match $x sub entity;
      """
    Given uniquely identify answer concepts
      | x                   |
      | label:abstract-type |
      | label:person        |
      | label:entity        |
    When typeql undefine
      """
      undefine person sub entity;
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql match
      """
      match $x sub entity;
      """
    Then uniquely identify answer concepts
      | x                   |
      | label:abstract-type |
      | label:entity        |


  Scenario: when undefining 'sub' on an entity type, specifying a type that isn't really its supertype throws
    When typeql undefine; throws exception
      """
      undefine person sub relation;
      """


  Scenario: a sub-entity type can be removed using 'sub' with its direct supertype, and its parent is preserved
    Given typeql define
      """
      define child sub person;
      """
    Given transaction commits

    When session opens transaction of type: write
    Given get answers of typeql match
      """
      match $x sub person;
      """
    Given uniquely identify answer concepts
      | x            |
      | label:person |
      | label:child  |
    When typeql undefine
      """
      undefine child sub person;
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql match
      """
      match $x sub person;
      """
    Then uniquely identify answer concepts
      | x            |
      | label:person |


  Scenario: undefining a type 'sub' an indirect supertype should still remove that type
    Given typeql define
      """
      define child sub person;
      """
    Given transaction commits

    When session opens transaction of type: read
    When get answers of typeql match
      """
      match $x sub person;
      """
    Then uniquely identify answer concepts
      | x            |
      | label:person |
      | label:child  |
    When session opens transaction of type: write
    When typeql undefine
      """
      undefine child sub entity;
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql match
      """
      match $x sub person;
      """
    Then uniquely identify answer concepts
      | x            |
      | label:person |


  Scenario: undefining a supertype throws an error if subtypes exist
    Given typeql define
      """
      define child sub person;
      """
    Given transaction commits

    When session opens transaction of type: write
    Then typeql undefine; throws exception
      """
      undefine person sub entity;
      """


  Scenario: removing a playable role from a super entity type also removes it from its subtypes
    Given typeql define
      """
      define child sub person;
      """
    Given transaction commits

    When session opens transaction of type: write
    When typeql undefine
      """
      undefine person plays employment:employee;
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql match
      """
      match $x type child; $x plays employment:employee;
      """
    Then answer size is: 0


  Scenario: removing an attribute ownership from a super entity type also removes it from its subtypes
    Given typeql define
      """
      define child sub person;
      """
    Given transaction commits

    When session opens transaction of type: write
    When typeql undefine
      """
      undefine person owns name;
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql match
      """
      match $x type child; $x owns name;
      """
    Then answer size is: 0


  Scenario: removing a key ownership from a super entity type also removes it from its subtypes
    Given typeql define
      """
      define child sub person;
      """
    Given transaction commits

    When session opens transaction of type: write
    When typeql undefine
      """
      undefine person owns email;
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql match
      """
      match $x type child; $x owns email @key;
      """
    Then answer size is: 0

  Scenario: all existing instances of an entity type must be deleted in order to undefine it
    Given get answers of typeql match
      """
      match $x sub entity;
      """
    Given uniquely identify answer concepts
      | x                   |
      | label:abstract-type |
      | label:person        |
      | label:entity        |
    Given transaction commits

    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert $x isa person, has name "Victor", has email "victor@vaticle.com";
      """
    Given transaction commits

    Given connection close all sessions
    Given connection open schema session for database: typedb
    When session opens transaction of type: write
    Then typeql undefine; throws exception
      """
      undefine person sub entity;
      """

    When connection close all sessions
    When connection open data session for database: typedb
    When session opens transaction of type: write
    When typeql delete
      """
      match
        $x isa person;
      delete
        $x isa person;
      """
    Then transaction commits

    When connection close all sessions
    When connection open schema session for database: typedb
    When session opens transaction of type: write
    When typeql undefine
      """
      undefine person sub entity;
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql match
      """
      match $x sub entity;
      """
    Then uniquely identify answer concepts
      | x                   |
      | label:abstract-type |
      | label:entity        |


  ##################
  # RELATION TYPES #
  ##################

  Scenario: undefining a relation type removes it
    Given get answers of typeql match
      """
      match $x sub relation;
      """
    Given uniquely identify answer concepts
      | x                |
      | label:employment |
      | label:relation   |
    When typeql undefine
      """
      undefine employment sub relation;
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql match
      """
      match $x sub relation;
      """
    Then uniquely identify answer concepts
      | x              |
      | label:relation |


  Scenario: removing playable roles from a super relation type also removes them from its subtypes
    Given typeql define
      """
      define
      employment-terms sub relation, relates employment;
      employment plays employment-terms:employment;
      contract-employment sub employment;
      """
    Given transaction commits

    Given session opens transaction of type: write
    Given get answers of typeql match
      """
      match contract-employment plays $x;
      """
    Given uniquely identify answer concepts
      | x                                 |
      | label:employment-terms:employment |
    When typeql undefine
      """
      undefine employment plays employment-terms:employment;
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql match
      """
      match contract-employment plays $x;
      """
    Then answer size is: 0


  Scenario: removing attribute ownerships from a super relation type also removes them from its subtypes
    Given typeql define
      """
      define
      start-date sub attribute, value datetime;
      employment owns start-date;
      contract-employment sub employment;
      """
    Given transaction commits

    Given session opens transaction of type: write
    Given get answers of typeql match
      """
      match $x owns start-date;
      """
    Given uniquely identify answer concepts
      | x                         |
      | label:employment          |
      | label:contract-employment |
    When typeql undefine
      """
      undefine employment owns start-date;
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql match
      """
      match $x owns start-date;
      """
    Then answer size is: 0


  Scenario: removing key ownerships from a super relation type also removes them from its subtypes
    Given typeql define
      """
      define
      employment-reference sub attribute, value string;
      employment owns employment-reference @key;
      contract-employment sub employment;
      """
    Given transaction commits

    Given session opens transaction of type: write
    Given get answers of typeql match
      """
      match $x owns employment-reference @key;
      """
    Given uniquely identify answer concepts
      | x                         |
      | label:employment          |
      | label:contract-employment |
    When typeql undefine
      """
      undefine employment owns employment-reference;
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql match
      """
      match $x owns employment-reference @key;
      """
    Then answer size is: 0


  Scenario: undefining a relation type throws on commit if it has existing instances
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $p isa person, has name "Harald", has email "harald@vaticle.com";
      $r (employee: $p) isa employment;
      """
    Given transaction commits

    Given connection close all sessions
    Given connection open schema session for database: typedb
    Given session opens transaction of type: write
    Then typeql undefine; throws exception
      """
      undefine
      employment relates employee;
      employment relates employer;
      person plays employment:employee;
      employment sub relation;
      """


  Scenario: all existing instances of a relation type must be deleted in order to undefine it
    Given get answers of typeql match
      """
      match $x sub relation;
      """
    Given uniquely identify answer concepts
      | x                |
      | label:employment |
      | label:relation   |
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $p isa person, has name "Harald", has email "harald@vaticle.com";
      $r (employee: $p) isa employment;
      """
    Given transaction commits

    Given connection close all sessions
    Given connection open schema session for database: typedb
    Given session opens transaction of type: write
    Then typeql undefine; throws exception
      """
      undefine employment sub relation;
      """

    When connection close all sessions
    When connection open data session for database: typedb
    When session opens transaction of type: write
    When typeql delete
      """
      match
        $r isa employment;
      delete
        $r isa employment;
      """
    Then transaction commits

    When connection close all sessions
    When connection open schema session for database: typedb
    When session opens transaction of type: write
    When typeql undefine
      """
      undefine employment sub relation;
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql match
      """
      match $x sub relation;
      """
    Then uniquely identify answer concepts
      | x              |
      | label:relation |


  Scenario: undefining a relation type automatically detaches any possible roleplayers
    Given get answers of typeql match
      """
      match
        $x type person;
        $x plays $y;
      """
    Given uniquely identify answer concepts
      | x            | y                         |
      | label:person | label:employment:employee |
    When typeql undefine
      """
      undefine employment sub relation;
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql match
      """
      match
        $x type person;
        $x plays $y;
      """
    Then answer size is: 0


  #############################
  # RELATED ROLES ('RELATES') #
  #############################

  Scenario: a role type can be removed from its relation type
    Given get answers of typeql match
      """
      match employment relates $x;
      """
    Given uniquely identify answer concepts
      | x                         |
      | label:employment:employee |
      | label:employment:employer |
    When typeql undefine
      """
      undefine employment relates employee;
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql match
      """
      match employment relates $x;
      """
    Then uniquely identify answer concepts
      | x                         |
      | label:employment:employer |


  Scenario: undefining all players of a role produces a valid schema
    When typeql undefine
      """
      undefine person plays employment:employee;
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql match
      """
      match $x plays employment:employee;
      """
    Then answer size is: 0

  #TODO: test is not working
  @ignore
  Scenario: after removing a role from a relation type, relation instances can no longer be created with that role
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $p isa person, has email "ganesh@vaticle.com";
      $r (employee: $p) isa employment;
      """
    Given transaction commits

    Given session opens transaction of type: write
    Given typeql delete
      """
      match
        $r isa employment;
      delete
        $r isa employment;
      """
    Given transaction commits

    Given connection close all sessions
    Given connection open schema session for database: typedb
    Given session opens transaction of type: write
    When typeql undefine
      """
      undefine
      person plays employment:employee;
      employment relates employee;
      """
    Then transaction commits

    When connection close all sessions
    When connection open data session for database: typedb
    When session opens transaction of type: write
    When get answers of typeql match
      """
      match $x relates employee;
      """
    Then answer size is: 0
    Then typeql insert; throws exception
      """
      match
        $p isa person, has email "ganesh@vaticle.com";
      insert
        $r (employee: $p) isa employment;
      """


  Scenario: removing all roles from a relation type without undefining the relation type throws on commit
    When typeql undefine
      """
      undefine
      employment relates employee;
      employment relates employer;
      """
    Then transaction commits; throws exception


  Scenario: undefining a role type automatically detaches any possible roleplayers
    Given get answers of typeql match
      """
      match
        $x type person;
        $x plays $y;
      """
    Given uniquely identify answer concepts
      | x            | y                         |
      | label:person | label:employment:employee |
    When typeql undefine
      """
      undefine employment relates employee;
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql match
      """
      match
        $x type person;
        $x plays $y;
      """
    Then answer size is: 0


  Scenario: removing a role throws an error if it is played by existing roleplayers in relations
    Given typeql define
      """
      define
      company sub entity, owns name, plays employment:employer;
      """
    Given transaction commits

    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $p isa person, has name "Ada", has email "ada@vaticle.com";
      $c isa company, has name "IBM";
      $r (employee: $p, employer: $c) isa employment;
      """
    Given transaction commits

    Given connection close all sessions
    Given connection open schema session for database: typedb
    Given session opens transaction of type: write
    Then typeql undefine; throws exception
      """
      undefine employment relates employer;
      """


  Scenario: a role that is not played in any existing instance of its relation type can be safely removed
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $p isa person, has name "Vijay", has email "vijay@vaticle.com";
      $r (employee: $p) isa employment;
      """
    Given transaction commits

    Given connection close all sessions
    Given connection open schema session for database: typedb
    Given session opens transaction of type: write
    When typeql undefine
      """
      undefine employment relates employer;
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql match
      """
      match employment relates $x;
      """
    Then uniquely identify answer concepts
      | x                         |
      | label:employment:employee |


  Scenario: removing a role from a super relation type also removes it from its subtypes
    Given typeql define
      """
      define part-time sub employment;
      """
    Given transaction commits

    When session opens transaction of type: write
    When typeql undefine
      """
      undefine employment relates employer;
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql match
      """
      match $x type part-time; $x relates $role;
      """
    Then uniquely identify answer concepts
      | x               | role                      |
      | label:part-time | label:employment:employee |

  # TODO
  Scenario: removing a role from a super relation type also removes roles that override it in its subtypes (?)

  # TODO
  Scenario: after undefining a sub-role from a relation type, it is gone and the type is left with just its parent role (?)


  ############################
  # PLAYABLE ROLES ('PLAYS') #
  ############################

  Scenario: after undefining a playable role from a type, the type can no longer play the role
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $p isa person, has email "ganesh@vaticle.com";
      $r (employee: $p) isa employment;
      """
    Given transaction commits

    Given session opens transaction of type: write
    Given typeql delete
      """
      match
        $r isa employment;
      delete
        $r isa employment;
      """
    Given transaction commits

    Given connection close all sessions
    Given connection open schema session for database: typedb
    Given session opens transaction of type: write
    When typeql undefine
      """
      undefine person plays employment:employee;
      """
    Then transaction commits

    When connection close all sessions
    When connection open data session for database: typedb
    When session opens transaction of type: write
    When get answers of typeql match
      """
      match $x plays employment:employee;
      """
    Then answer size is: 0
    Then typeql insert; throws exception
      """
      match
        $p isa person, has email "ganesh@vaticle.com";
      insert
        $r (employee: $p) isa employment;
      """


  Scenario: undefining a playable role that was not actually playable to begin with throws
    Given get answers of typeql match
      """
      match person plays $x;
      """
    Given uniquely identify answer concepts
      | x                         |
      | label:employment:employee |
    When typeql undefine; throws exception
      """
      undefine person plays employment:employer;
      """


  Scenario: removing a playable role throws an error if it is played by existing instances
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $p isa person, has email "ganesh@vaticle.com";
      $r (employee: $p) isa employment;
      """
    Given transaction commits

    Given connection close all sessions
    Given connection open schema session for database: typedb
    Given session opens transaction of type: write
    Then typeql undefine; throws exception
      """
      undefine person plays employment:employee;
      """


  ###################
  # ATTRIBUTE TYPES #
  ###################

  Scenario Outline: undefining 'sub attribute' on an attribute type with value type '<value_type>' removes it
    Given typeql define
      """
      define <attr> sub attribute, value <value_type>;
      """
    Given transaction commits

    Given session opens transaction of type: write
    Given get answers of typeql match
      """
      match $x type <attr>;
      """
    Given answer size is: 1
    When typeql undefine
      """
      undefine <attr> sub attribute;
      """
    Then transaction commits

    When session opens transaction of type: read
    Then typeql match; throws exception
      """
      match $x type <attr>;
      """

    Examples:
      | value_type | attr       |
      | string     | colour     |
      | long       | age        |
      | double     | height     |
      | boolean    | is-awake   |
      | datetime   | birth-date |


  Scenario: undefining a regex on an attribute type removes the regex constraints on the attribute
    When typeql undefine
      """
      undefine email regex ".+@\w+\..+";
      """
    Then transaction commits

    When connection close all sessions
    When connection open data session for database: typedb
    When session opens transaction of type: write
    When typeql insert
      """
      insert $x "not-email-regex" isa email;
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql match
      """
      match $x isa email;
      """
    Then answer size is: 1


  Scenario: removing playable roles from a super attribute type also removes them from its subtypes
    Given typeql define
      """
      define
      employment relates manager-name;
      abstract-name sub attribute, abstract, value string, plays employment:manager-name;
      first-name sub abstract-name;
      """
    Given transaction commits

    Given session opens transaction of type: write
    Given get answers of typeql match
      """
      match first-name plays $x;
      """
    Given uniquely identify answer concepts
      | x                             |
      | label:employment:manager-name |
    When typeql undefine
      """
      undefine abstract-name plays employment:manager-name;
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql match
      """
      match first-name plays $x;
      """
    Then answer size is: 0


  Scenario: removing attribute ownerships from a super attribute type also removes them from its subtypes
    Given typeql define
      """
      define
      locale sub attribute, value string;
      abstract-name sub attribute, abstract, value string, owns locale;
      first-name sub abstract-name;
      """
    Given transaction commits

    Given session opens transaction of type: write
    Given get answers of typeql match
      """
      match $x owns locale;
      """
    Given uniquely identify answer concepts
      | x                   |
      | label:abstract-name |
      | label:first-name    |
    When typeql undefine
      """
      undefine abstract-name owns locale;
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql match
      """
      match $x owns locale;
      """
    Then answer size is: 0


  Scenario: removing a key ownership from a super attribute type also removes it from its subtypes
    Given typeql define
      """
      define
      name-id sub attribute, value long;
      abstract-name sub attribute, abstract, value string, owns name-id @key;
      first-name sub abstract-name;
      """
    Given transaction commits

    Given session opens transaction of type: write
    Given get answers of typeql match
      """
      match $x owns name-id @key;
      """
    Given uniquely identify answer concepts
      | x                   |
      | label:abstract-name |
      | label:first-name    |
    When typeql undefine
      """
      undefine abstract-name owns name-id;
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql match
      """
      match $x owns name-id @key;
      """
    Then answer size is: 0


  Scenario: an attribute and its self-ownership can be removed simultaneously
    Given typeql define
      """
      define
      name owns name;
      """
    Given transaction commits

    Given session opens transaction of type: write
    When typeql undefine
      """
      undefine
      name owns name;
      name sub attribute;
      """
    Then transaction commits

    When session opens transaction of type: read
    Then typeql match; throws exception
      """
      match $x type name;
      """


  Scenario: undefining the value type of an attribute throws an error
    When typeql undefine; throws exception
      """
      undefine name value string;
      """


  Scenario: all existing instances of an attribute type must be deleted in order to undefine it
    Given get answers of typeql match
      """
      match $x sub attribute;
      """
    Given uniquely identify answer concepts
      | x               |
      | label:name      |
      | label:email     |
      | label:attribute |
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert $x "Colette" isa name;
      """
    Given transaction commits

    Given connection close all sessions
    Given connection open schema session for database: typedb
    Given session opens transaction of type: write
    Then typeql undefine; throws exception
      """
      undefine name sub attribute;
      """

    When connection close all sessions
    When connection open data session for database: typedb
    When session opens transaction of type: write
    When typeql delete
      """
      match
        $x isa name;
      delete
        $x isa name;
      """
    Then transaction commits

    When connection close all sessions
    When connection open schema session for database: typedb
    When session opens transaction of type: write
    When typeql undefine
      """
      undefine name sub attribute;
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql match
      """
      match $x sub attribute;
      """
    Then uniquely identify answer concepts
      | x               |
      | label:email     |
      | label:attribute |


  ########################
  # ATTRIBUTE OWNERSHIPS #
  ########################

  Scenario: undefining an attribute ownership removes it
    Given get answers of typeql match
      """
      match
        $x owns name;
        $x type person;
      """
    Given uniquely identify answer concepts
      | x            |
      | label:person |
    When typeql undefine
      """
      undefine person owns name;
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql match
      """
      match
        $x owns name;
        $x type person;
      """
    Then answer size is: 0


  Scenario: attempting to undefine an attribute ownership that was not actually owned to begin throws
    When typeql undefine; throws exception
      """
      undefine employment owns name;
      """


  Scenario: attempting to undefine an attribute ownership inherited from a parent throws
    Given typeql define
      """
      define child sub person;
      """
    Then transaction commits

    When session opens transaction of type: write
    Then typeql undefine; throws exception
      """
      undefine child owns name;
      """


  Scenario: undefining a key ownership removes it
    When typeql undefine
      """
      undefine person owns email;
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql match
      """
      match $x owns email;
      """
    Then answer size is: 0


  Scenario: writing '@key' when undefining a key ownership is not allowed
    Then typeql undefine; throws exception
      """
      undefine person owns email @key;
      """


  Scenario: writing '@key' when undefining an attribute ownership is not allowed
    Then typeql undefine; throws exception
      """
      undefine person owns name @key;
      """


  Scenario: when a type can own an attribute, but none of its instances actually do, the ownership can be undefined
    Given get answers of typeql match
      """
      match $x owns name;
      """
    Given uniquely identify answer concepts
      | x            |
      | label:person |
    Given transaction commits

    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert $x isa person, has email "anon@vaticle.com";
      """
    Given transaction commits

    Given connection close all sessions
    Given connection open schema session for database: typedb
    Given session opens transaction of type: write
    When typeql undefine
      """
      undefine person owns name;
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql match
      """
      match $x owns name;
      """
    Then answer size is: 0


  Scenario: removing an attribute ownership throws an error if it is owned by existing instances
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert $x isa person, has name "Tomas", has email "tomas@vaticle.com";
      """
    Given transaction commits

    Given connection close all sessions
    Given connection open schema session for database: typedb
    Given session opens transaction of type: write
    Then typeql undefine; throws exception
      """
      undefine person owns name;
      """


  Scenario: undefining a key ownership throws an error if it is owned by existing instances
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert $x isa person, has name "Daniel", has email "daniel@vaticle.com";
      """
    Given transaction commits

    Given connection close all sessions
    Given connection open schema session for database: typedb
    Given session opens transaction of type: write
    Then typeql undefine; throws exception
      """
      undefine person owns email;
      """


  #########
  # RULES #
  #########

  Scenario: undefining a rule removes it
    Given typeql define
      """
      define
      company sub entity, plays employment:employer;
      rule a-rule:
      when {
        $c isa company; $y isa person;
      } then {
        (employer: $c, employee: $y) isa employment;
      };
      """
    Given transaction commits

    When session opens transaction of type: write
    Then rules contain: a-rule
    When typeql undefine
      """
      undefine rule a-rule;
      """
    Then transaction commits

    When session opens transaction of type: read
    Then rules do not contain: a-rule

  Scenario: after undefining a rule, concepts previously inferred by that rule are no longer inferred
    Given typeql define
      """
      define
      rule samuel-email-rule:
      when {
        $x has email "samuel@vaticle.com";
      } then {
        $x has name "Samuel";
      };
      """
    Given transaction commits

    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert $x isa person, has email "samuel@vaticle.com";
      """
    Given transaction commits

    Given session opens transaction of type: read
    Given get answers of typeql match
      """
      match
        $x has name $n;
      get $n;
      """
    Given uniquely identify answer concepts
      | n                 |
      | attr:name:Samuel  |
    Given connection close all sessions
    Given connection open schema session for database: typedb
    Given session opens transaction of type: write
    When typeql undefine
      """
      undefine rule samuel-email-rule;
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql match
      """
      match
        $x has name $n;
      get $n;
      """
    Then answer size is: 0


  # TODO enable when we can do reasoning in a schema write transaction
  @ignore
  Scenario: when undefining a rule, concepts inferred by that rule can still be retrieved until the next commit
    Given typeql define
      """
      define
      rule samuel-email-rule:
      when {
        $x has email "samuel@vaticle.com";
      } then {
        $x has name "Samuel";
      };
      """
    Given transaction commits

    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert $x isa person, has email "samuel@vaticle.com";
      """
    Given transaction commits

    Given connection close all sessions
    Given connection open schema session for database: typedb
    Given session opens transaction of type: write
    Given get answers of typeql match
      """
      match
        $x has name $n;
      get $n;
      """
    Given uniquely identify answer concepts
      | n                 |
      | attr:name:Samuel  |
    When typeql undefine
      """
      undefine rule samuel-email-rule;
      """

    When get answers of typeql match
      """
      match
        $x has name $n;
      get $n;
      """
    Then uniquely identify answer concepts
      | n                 |
      | attr:name:Samuel  |

  Scenario: You cannot undefine a type if it is used in a rule
    Given typeql define
    """
    define

    type-to-undefine sub entity, owns name;

    rule rule-referencing-type-to-undefine:
    when {
      $x isa type-to-undefine;
    } then {
      $x has name "dummy";
    };
    """
    Given transaction commits

    Given session opens transaction of type: write

    Given typeql undefine; throws exception
    """
    undefine
      type-to-undefine sub entity;
    """

  Scenario: You cannot undefine a type if it is used in a negation in a rule
    Given typeql define
    """
    define
    rel sub relation, relates rol;
    other-type sub entity, owns name, plays rel:rol;
    type-to-undefine sub entity, owns name, plays rel:rol;

    rule rule-referencing-type-to-undefine:
    when {
      $x isa other-type;
      not { ($x, $y) isa relation; $y isa type-to-undefine; };
    } then {
      $x has name "dummy";
    };
    """
    Given transaction commits

    Given session opens transaction of type: write

    Given typeql undefine; throws exception
    """
    undefine
      type-to-undefine sub entity;
    """

  Scenario: You cannot undefine a type if it is used in any disjunction in a rule
    Given typeql define
    """
    define

    type-to-undefine sub entity, owns name;

    rule rule-referencing-type-to-undefine:
    when {
      $x has name $y;
      { $x isa person; } or { $x isa type-to-undefine; };
    } then {
      $x has name "dummy";
    };
    """
    Given transaction commits

    Given session opens transaction of type: write

    Given typeql undefine; throws exception
    """
    undefine
      type-to-undefine sub entity;
    """

  Scenario: You cannot undefine a type if it is used in the then of a rule
    Given typeql define
    """
    define
    name-to-undefine sub attribute, value string;
    some-type sub entity, owns name-to-undefine;

    rule rule-referencing-type-to-undefine:
    when {
      $x isa some-type;
    } then {
      $x has name-to-undefine "dummy";
    };
    """
    Given transaction commits

    Given session opens transaction of type: write

    Given typeql undefine; throws exception
    """
    undefine
      name-to-undefine sub entity;
    """

  ############
  # ABSTRACT #
  ############

  Scenario: undefining a type as abstract converts an abstract to a concrete type, allowing creation of instances
    Given get answers of typeql match
      """
      match
        $x type abstract-type;
        not { $x abstract; };
      """
    Given answer size is: 0
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert; throws exception
      """
      insert $x isa abstract-type;
      """

    Given connection close all sessions
    Given connection open schema session for database: typedb
    Given session opens transaction of type: write
    Given typeql undefine
      """
      undefine abstract-type abstract;
      """
    Given transaction commits

    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    When get answers of typeql match
      """
      match
        $x type abstract-type;
        not { $x abstract; };
      """
    Then uniquely identify answer concepts
      | x                   |
      | label:abstract-type |
    When typeql insert
      """
      insert $x isa abstract-type;
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql match
      """
      match $x isa abstract-type;
      """
    Then answer size is: 1


  Scenario: undefining abstract on a type that is already non-abstract does nothing
    When typeql undefine
      """
      undefine person abstract;
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql match
      """
      match
        $x type person;
        not { $x abstract; };
      """
    Then uniquely identify answer concepts
      | x            |
      | label:person |


  Scenario: an abstract type can be changed into a concrete type even if has an abstract child type
    Given typeql define
      """
      define sub-abstract-type sub abstract-type, abstract;
      """
    Given transaction commits

    Given session opens transaction of type: write
    When typeql undefine
      """
      undefine abstract-type abstract;
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql match
      """
      match
        $x type abstract-type;
        not { $x abstract; };
      """
    Then uniquely identify answer concepts
      | x                   |
      | label:abstract-type |


  Scenario: undefining abstract on an attribute type is allowed, even if that attribute type has an owner
    Given typeql define
      """
      define
      person abstract;
      vehicle-registration sub attribute, value string, abstract;
      person owns vehicle-registration;
      """
    Given transaction commits

    Given session opens transaction of type: write
    When typeql undefine
      """
      undefine
      vehicle-registration abstract;
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql match
      """
      match
        $x type vehicle-registration;
        not { $x abstract; };
      """
    Then answer size is: 1


  ###################
  # COMPLEX QUERIES #
  ###################

  Scenario: a type and an attribute type that it owns can be removed simultaneously
    Given get answers of typeql match
      """
      match $x sub entity;
      """
    Given uniquely identify answer concepts
      | x                   |
      | label:person        |
      | label:abstract-type |
      | label:entity        |
    Given get answers of typeql match
      """
      match $x sub attribute;
      """
    Given uniquely identify answer concepts
      | x               |
      | label:name      |
      | label:email     |
      | label:attribute |
    When typeql undefine
      """
      undefine
      person sub entity, owns name;
      name sub attribute;
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql match
      """
      match $x sub entity;
      """
    Then uniquely identify answer concepts
      | x                   |
      | label:abstract-type |
      | label:entity        |
    When get answers of typeql match
      """
      match $x sub attribute;
      """
    Then uniquely identify answer concepts
      | x               |
      | label:email     |
      | label:attribute |

  Scenario: a type, a relation type that it plays in and an attribute type that it owns can be removed simultaneously
    Given get answers of typeql match
      """
      match $x sub entity;
      """
    Given uniquely identify answer concepts
      | x                   |
      | label:person        |
      | label:abstract-type |
      | label:entity        |
    Given get answers of typeql match
      """
      match $x sub relation;
      """
    Given uniquely identify answer concepts
      | x                |
      | label:employment |
      | label:relation   |
    Given get answers of typeql match
      """
      match $x sub attribute;
      """
    Given uniquely identify answer concepts
      | x               |
      | label:name      |
      | label:email     |
      | label:attribute |
    Given get answers of typeql match
      """
      match $x sub relation:role;
      """
    Given uniquely identify answer concepts
      | x                         |
      | label:employment:employee |
      | label:employment:employer |
      | label:relation:role       |
    When typeql undefine
      """
      undefine
      person sub entity, owns name, owns email, plays employment:employee;
      employment sub relation, relates employee, relates employer;
      name sub attribute;
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql match
      """
      match $x sub entity;
      """
    Then uniquely identify answer concepts
      | x                   |
      | label:abstract-type |
      | label:entity        |
    When get answers of typeql match
      """
      match $x sub relation;
      """
    Then uniquely identify answer concepts
      | x              |
      | label:relation |
    When get answers of typeql match
      """
      match $x sub attribute;
      """
    Then uniquely identify answer concepts
      | x               |
      | label:email     |
      | label:attribute |
    When get answers of typeql match
      """
      match $x sub relation:role;
      """
    Then uniquely identify answer concepts
      | x                   |
      | label:relation:role |
