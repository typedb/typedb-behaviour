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
Feature: Graql Mutate Schema Query

  Background: Open connection and create a simple extensible schema
    Given connection has been opened
    Given connection delete all keyspaces
    Given connection open sessions for keyspaces:
      | test_mutate_schema |
    Given transaction is initialised
    Given the integrity is validated
    Given graql define
      """
      define
      person sub entity, plays employee, has name, key email;
      employment sub relation, relates employee, has start-date;

      name sub attribute, value string;
      email sub attribute, value string;
      start-date sub attribute, value datetime;
      """
    Given the integrity is validated


  ##############
  # PRIMITIVES #
  ##############

  Scenario: repeatedly defining existing type keeps its properties intact
    Given graql define
      """
      define
      person sub entity, has name;
      person sub entity, has name;
      person sub entity, has name;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x type person; $x has email; get;
      """
    Then concept identifiers are
      |     | check | value  |
      | PER | label | person |
    Then uniquely identify answer concepts
      | x   |
      | PER |


  Scenario: change entity type to relation type throws
    Then graql define throws
      """
      define
      person sub relation, relates body-part;
      arm sub entity, plays body-part;
      """


  Scenario: change relation type to attribute type throws
    Then graql define throws
      """
      define employment sub attribute, value string;
      """


  Scenario: change attribute type to entity type throws
    Then graql define throws
      """
      define name sub entity;
      """


  Scenario: define additional 'has' on a type adds attribute to it
    Given graql define
      """
      define employment has name;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x has name; get;
      """
    Then concept identifiers are
      |     | check | value      |
      | PER | label | person     |
      | EMP | label | employment |
    Then uniquely identify answer concepts
      | x   |
      | PER |
      | EMP |


  Scenario: define additional 'plays' on a type adds role to it
    Given graql define
      """
      define employment plays employee;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x plays employee; get;
      """
    Then concept identifiers are
      |     | check | value      |
      | PER | label | person     |
      | EMP | label | employment |
    Then uniquely identify answer concepts
      | x   |
      | PER |
      | EMP |


  Scenario: define additional 'key' on a type adds key to it
    Given graql define
      """
      define employment key email;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x has email; get;
      """
    Then concept identifiers are
      |     | check | value      |
      | PER | label | person     |
      | EMP | label | employment |
    Then uniquely identify answer concepts
      | x   |
      | PER |
      | EMP |


  Scenario: define additional 'key' on a type adds key to it even if it has existing instances
    Given graql define
      """
      define
      barcode sub attribute, value string;
      product sub entity, has name;
      """
    Given the integrity is validated
    Given graql insert
      """
      insert
      $x isa product, has name "Cheese";
      $y isa product, has name "Ham";
      """
    Given the integrity is validated
    When graql define
      """
      define
      product key barcode;
      """
    When the integrity is validated
    When get answers of graql query
      """
      match $x has barcode; get;
      """
    Then concept identifiers are
      |     | check | value      |
      | PRD | label | product    |
    Then uniquely identify answer concepts
      | x   |
      | PRD |


  Scenario: define additional 'relates' on a relation type adds roleplayer to it
    Given graql define
      """
      define
      company sub entity, plays employer;
      employment relates employer;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x relates employer; get;
      """
    Then concept identifiers are
      |     | check | value      |
      | EMP | label | employment |
    Then uniquely identify answer concepts
      | x   |
      | EMP |


  Scenario: define additional 'regex' on attribute type adds regex to it if all existing instances match the regex
    Given graql insert
      """
      insert
      $x isa person, has name "Alice", has email "alice@grakn.ai";
      """
    Given the integrity is validated
    When graql define
      """
      define name regex "^A.*$";
      """
    When the integrity is validated
    When get answers of graql query
      """
      match $x regex "^A.*$"; get;
      """
    Then concept identifiers are
      |     | check | value |
      | NAM | label | name  |
    Then uniquely identify answer concepts
      | x   |
      | NAM |


  Scenario: define additional 'regex' on attribute type throws on commit if an existing instance doesn't match the regex
    Given graql insert
      """
      insert
      $x isa person, has name "Maria", has email "maria@grakn.ai";
      """
    Given the integrity is validated
    Then graql define throws
      """
      define name regex "^A.*$";
      """


  Scenario: define additional 'regex' on a long-valued attribute type throws
    Given graql define
      """
      define house-number sub attribute, value long;
      """
    Given the integrity is validated
    Then graql define throws
      """
      define house-number regex "^A.*$";
      """


  Scenario: add 'relates' to entity type throws
    Then graql define throws
      """
      define person relates employee;
      """


  Scenario: add 'relates' to attribute type throws
    Then graql define throws
      """
      define name relates employee;
      """


  Scenario: modify attribute value type throws
    Then graql define throws
      """
      define name value long;
      """


  Scenario: modify rule definition throws
    Given graql define
      """
      define
      nickname sub name;
      person has nickname;
      robert-has-nickname-bob sub rule,
      when {
        $p isa person, has name "Robert";
      }, then {
        $p has nickname "Bob";
      };
      """
    Given the integrity is validated
    Then graql define throws
      """
      define
      robert-has-nickname-bob sub rule,
      when {
        $p isa person, has name "robert";
      }, then {
        $p has nickname "bob";
      };
      """


  ##################
  # ABSTRACT TYPES #
  ##################

  Scenario: add abstract to existing entity type makes it abstract
    Given graql define
      """
      define person abstract;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x sub person; $x abstract; get;
      """
    Then concept identifiers are
      |     | check | value  |
      | PER | label | person |
    Then uniquely identify answer concepts
      | x   |
      | PER |


  Scenario: add abstract to existing relation type makes it abstract
    Given graql define
      """
      define employment abstract;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x sub employment; $x abstract; get;
      """
    Then concept identifiers are
      |     | check | value      |
      | EMP | label | employment |
    Then uniquely identify answer concepts
      | x   |
      | EMP |


  Scenario: add abstract to existing attribute type makes it abstract
    Given graql define
      """
      define name abstract;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x sub name; $x abstract; get;
      """
    Then concept identifiers are
      |     | check | value |
      | NAM | label | name  |
    Then uniquely identify answer concepts
      | x   |
      | NAM |


  Scenario: add abstract to existing entity type throws on commit if it has an existing instance
    Given graql insert
      """
      insert
      $x isa person, has name "Jeremy", has email "jeremy@grakn.ai";
      """
    Given the integrity is validated
    Then graql define throws
      """
      define person abstract;
      """


  Scenario: add abstract to existing relation type throws on commit if it has an existing instance


  Scenario: add abstract to existing attribute type throws on commit if it has an existing instance
    Given graql insert
      """
      insert
      $x isa person, has name "Jeremy", has email "jeremy@grakn.ai";
      """
    Given the integrity is validated
    Then graql define throws
      """
      define name abstract;
      """


  @ignore
  # TODO: re-enable when concrete types cannot have abstract subtypes
  Scenario: change concrete type to abstract throws on commit if it has a concrete supertype

  @ignore
  # TODO: re-enable when rules cannot infer abstract relations
  Scenario: change concrete relation type to abstract throws on commit if it is the conclusion of any rule

  @ignore
  # TODO: check if rules can infer abstract attributes
  Scenario: change concrete attribute type to abstract throws on commit if it is the conclusion of any rule

  ###############
  # INHERITANCE #
  ###############

  Scenario: define new `sub` on entity type changes its supertype
    Given graql define
      """
      define
      apple-product sub entity;
      genius sub person;
      """
    Given the integrity is validated
    When graql define
      """
      define
      genius sub apple-product;
      """
    When the integrity is validated
    When get answers of graql query
      """
      match $x sub apple-product; get;
      """
    Then concept identifiers are
      |     | check | value         |
      | APL | label | apple-product |
      | GEN | label | genius        |
    Then uniquely identify answer concepts
      | x   |
      | APL |
      | GEN |


  Scenario: define new `sub` on relation type changes its supertype


  @ignore
  # TODO: re-enable when we can switch attributes to new supertypes
  Scenario: define new `sub` on attribute type changes its supertype
    Given graql define
      """
      define
      measure sub attribute, value double;
      shoe-size sub measure;
      shoe sub entity, has shoe-size;
      """
    Given the integrity is validated
    Given graql insert
      """
      insert $s isa shoe, has shoe-size 9;
      """
    Given the integrity is validated
    Given graql define
      """
      define
      size sub attribute, value double;
      shoe-size sub size;
      """
    When get answers of graql query
      """
      match $x sub shoe-size; get;
      """
    Then concept identifiers are
      |     | check | value     |
      | SHS | label | shoe-size |
    Then uniquely identify answer concepts
      | x   |
      | SHS |


  Scenario: assign new supertype with existing data succeeds if the supertypes have no properties
    Given graql define
      """
      define
      bird sub entity;
      pigeon sub bird;
      """
    Given the integrity is validated
    Given graql insert
      """
      insert $p isa pigeon;
      """
    Given the integrity is validated
    Given graql define
      """
      define
      animal sub entity;
      pigeon sub animal;
      """
    When get answers of graql query
      """
      match $x sub pigeon; get;
      """
    Then concept identifiers are
      |     | check | value  |
      | PIG | label | pigeon |
    Then uniquely identify answer concepts
      | x   |
      | PIG |


  @ignore
  # TODO: re-enable when roles are correctly checked when switching supertypes
  Scenario: assign new supertype with existing data succeeds if the supertypes play the same roles
    Given graql define
      """
      define
      bird sub entity, plays flier;
      pigeon sub bird;
      flying sub relation, relates flier;
      """
    Given the integrity is validated
    Given graql insert
      """
      insert $p isa pigeon;
      """
    Given the integrity is validated
    Given graql define
      """
      define
      animal sub entity, plays flier;
      pigeon sub animal;
      """
    When get answers of graql query
      """
      match $x sub pigeon; get;
      """
    Then concept identifiers are
      |     | check | value  |
      | PIG | label | pigeon |
    Then uniquely identify answer concepts
      | x   |
      | PIG |


  @ignore
  # TODO: re-enable when attribute ownerships are correctly checked when switching supertypes
  Scenario: assign new supertype with existing data succeeds if the supertypes have the same attributes
    Given graql define
      """
      define
      name sub attribute, value string;
      bird sub entity, has name;
      pigeon sub bird;
      """
    Given the integrity is validated
    Given graql insert
      """
      insert $p isa pigeon;
      """
    Given the integrity is validated
    Given graql define
      """
      define
      animal sub entity, has name;
      pigeon sub animal;
      """
    When get answers of graql query
      """
      match $x sub pigeon; get;
      """
    Then concept identifiers are
      |     | check | value  |
      | PIG | label | pigeon |
    Then uniquely identify answer concepts
      | x   |
      | PIG |


  # TODO: write this once 'assign new supertype .. with existing data' succeeds if the supertypes have the same attributes
  Scenario: assign new supertype throws if existing data has attributes not present on the new supertype

  # TODO: write this once 'assign new supertype .. with existing data' succeeds if the supertypes play the same roles
  Scenario: assign new supertype throws if existing data plays a role that it can't with the new supertype

  # TODO: write this once 'assign new supertype throws if .. data has attributes not present on the new supertype' is written
  Scenario: assign new supertype throws if that supertype has a key not present in the existing data (?)

  # TODO: write this once 'define new `sub` on relation type changes its supertype' is written
  Scenario: assign new super-relation throws if existing data has roleplayers not present on the new supertype (?)

  # TODO: write this once 'define new `sub` on attribute type changes its supertype' passes
  Scenario: assign new super-attribute throws if it has a different value type to the current one (?)

  # TODO: write this if 'assign new super-attribute throws if it has a different value type ..' turns out to not throw
  Scenario: assign new super-attribute throws if it has existing data and a different value type to the new supertype (?)

  # TODO: write this once 'define new `sub` on attribute type changes its supertype' passes
  Scenario: assign new super-attribute throws if new supertype has a regex and existing data doesn't match it (?)


  Scenario: define additional 'plays' is visible from all children
    Given graql define
      """
      define employment sub relation, relates employer;
      """
    Given the integrity is validated

    Given graql define
      """
      define
      child sub person;
      person sub entity, plays employer;
      """
    Given the integrity is validated

    When get answers of graql query
      """
      match $x type child, plays $r; get;
      """
    Then concept identifiers are
      |             | check | value            |
      | EMPLOYEE    | label | employee         |
      | EMPLOYER    | label | employer         |
      | NAME_OWNER  | label | @has-name-owner  |
      | EMAIL_OWNER | label | @key-email-owner |
      | CHILD       | label | child            |
    Then uniquely identify answer concepts
      | x     | r           |
      | CHILD | EMPLOYEE    |
      | CHILD | EMPLOYER    |
      | CHILD | NAME_OWNER  |
      | CHILD | EMAIL_OWNER |


  @ignore
  # TODO: re-enable when we can query schema 'has' and 'key' with variables eg: 'match $x type ___, has key $a; get;'
  Scenario: define additional 'has' is visible from all children
    Given graql define
    """
       define
       child sub person;
       phone-number sub attribute, value long;
       person sub entity, has phone-number;
      """
    Given the integrity is validated

    When get answers of graql query
      """
      match $x type child, has $y; get;
      """
    Then concept identifiers are
      |       | check | value        |
      | CHILD | label | child        |
      | NAME  | label | name         |
      | PHONE | label | phone-number |
    Then uniquely identify answer concepts
      | x     | y     |
      | CHILD | NAME  |
      | CHILD | PHONE |


  @ignore
  # TODO: re-enable when we can query schema 'has' and 'key' with variables eg: 'match $x type ___, has key $a; get;'
  Scenario: define additional 'key' is visible from all children
    Given graql define
      """
      define
      child sub person;
      phone-number sub attribute, value long;
      person sub entity, key phone-number;
      """
    Given the integrity is validated

    When get answers of graql query
      """
      match $x type child, key $y; get;
      """
    Then concept identifiers are
      |       | check | value |
      | CHILD | label | child |
      | EMAIL | label | email |
    Then uniquely identify answer concepts
      | x     | y     |
      | CHILD | EMAIL |
      | CHILD | EMAIL |


  @ignore
  # TODO: re-enable when we can inherit 'relates'
  Scenario: define additional 'relates' is visible from all children
    Given graql define
      """
      define
      part-time-employment sub employment;
      employment sub relation, relates employer;
      """
    Given the integrity is validated

    When get answers of graql query
      """
      match $x type part-time-employment, relates $r; get;
      """
    Then concept identifiers are
      |           | check | value                |
      | EMPLOYEE  | label | employee             |
      | EMPLOYER  | label | employer             |
      | PART_TIME | label | part-time-employment |
    Then uniquely identify answer concepts
      | x         | r        |
      | PART_TIME | EMPLOYEE |
      | PART_TIME | EMPLOYER |
