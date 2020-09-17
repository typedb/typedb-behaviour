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
Feature: Graql Define Query

  Background: Open connection and create a simple extensible schema
    Given connection has been opened
    Given connection delete all databases
    Given connection does not have any database
    Given connection create database: grakn
    Given connection open schema session for database: grakn
    Given session opens transaction of type: write
    Given the integrity is validated
    Given graql define
      """
      define
      person sub entity, plays employment:employee, plays income:earner, owns name, owns email @key;
      employment sub relation, relates employee, plays income:source, owns start-date, owns employment-reference-code @key;
      income sub relation, relates earner, relates source;

      name sub attribute, value string;
      email sub attribute, value string;
      start-date sub attribute, value datetime;
      employment-reference-code sub attribute, value string;
      """
    Given transaction commits
    Given the integrity is validated
    Given session opens transaction of type: write


  ################
  # ENTITY TYPES #
  ################

  Scenario: new entity types can be defined
    When graql define
      """
      define dog sub entity;
      """
    Then transaction commits
    Then the integrity is validated
    When session opens transaction of type: read
    When get answers of graql query
      """
      match $x type dog;
      """
    When concept identifiers are
      |     | check | value |
      | DOG | label | dog   |
    Then uniquely identify answer concepts
      | x   |
      | DOG |


  Scenario: a new entity type can be defined as a subtype, creating a new child of its parent type
    When graql define
      """
      define child sub person; 
      """
    Then transaction commits
    Then the integrity is validated
    When session opens transaction of type: read
    When get answers of graql query
      """
      match $x sub person;
      """
    When concept identifiers are
      |     | check | value  |
      | PER | label | person |
      | CHD | label | child  |
    Then uniquely identify answer concepts
      | x   |
      | PER |
      | CHD |


  Scenario: when defining that a type owns a non-existent thing, an error is thrown
    Then graql define; throws exception
      """
      define book sub entity, owns pages;
      """
    Then the integrity is validated


  Scenario: types cannot own entity types
    Then graql define; throws exception
      """
      define house sub entity, owns person;
      """
    Then the integrity is validated


  Scenario: types cannot own relation types
    Then graql define; throws exception
      """
      define company sub entity, owns employment;
      """
    Then the integrity is validated


  Scenario: when defining that a type plays a non-existent role, an error is thrown
    Then graql define; throws exception
      """
      define house sub entity, plays constructed:something;
      """
    Then the integrity is validated


  Scenario: types cannot play entity types
    Then graql define; throws exception
      """
      define parrot sub entity, plays person;
      """
    Then the integrity is validated


  Scenario: types can not own entity types as keys
    Then graql define; throws exception
      """
      define passport sub entity, owns person @key;
      """
    Then the integrity is validated


  Scenario: a newly defined entity subtype inherits playable roles from its parent type
    Given graql define
      """
      define child sub person;
      """
    Given transaction commits
    Given the integrity is validated
    Given session opens transaction of type: read
    When get answers of graql query
      """
      match $x plays employment:employee;
      """
    When concept identifiers are
      |     | check | value  |
      | PER | label | person |
      | CHD | label | child  |
    Then uniquely identify answer concepts
      | x   |
      | PER |
      | CHD |


  Scenario: a newly defined entity subtype inherits playable roles from all of its supertypes
    Given graql define
      """
      define
      athlete sub person;
      runner sub athlete;
      sprinter sub runner;
      """
    Given transaction commits
    Given the integrity is validated
    Given session opens transaction of type: read
    When get answers of graql query
      """
      match $x plays employment:employee;
      """
    When concept identifiers are
      |     | check | value    |
      | PER | label | person   |
      | ATH | label | athlete  |
      | RUN | label | runner   |
      | SPR | label | sprinter |
    Then uniquely identify answer concepts
      | x   |
      | PER |
      | ATH |
      | RUN |
      | SPR |


  Scenario: a newly defined entity subtype inherits attribute ownerships from its parent type
    Given graql define
      """
      define child sub person;
      """
    Given transaction commits
    Given the integrity is validated
    Given session opens transaction of type: read
    When get answers of graql query
      """
      match $x owns name;
      """
    When concept identifiers are
      |     | check | value  |
      | PER | label | person |
      | CHD | label | child  |
    Then uniquely identify answer concepts
      | x   |
      | PER |
      | CHD |


  Scenario: a newly defined entity subtype inherits attribute ownerships from all of its supertypes
    Given graql define
      """
      define
      athlete sub person;
      runner sub athlete;
      sprinter sub runner;
      """
    Given transaction commits
    Given the integrity is validated
    Given session opens transaction of type: read
    When get answers of graql query
      """
      match $x owns name;
      """
    When concept identifiers are
      |     | check | value    |
      | PER | label | person   |
      | ATH | label | athlete  |
      | RUN | label | runner   |
      | SPR | label | sprinter |
    Then uniquely identify answer concepts
      | x   |
      | PER |
      | ATH |
      | RUN |
      | SPR |


  Scenario: a newly defined entity subtype inherits keys from its parent type
    Given graql define
      """
      define child sub person;
      """
    Given transaction commits
    Given the integrity is validated
    Given session opens transaction of type: read
    When get answers of graql query
      """
      match $x owns email @key;
      """
    When concept identifiers are
      |     | check | value  |
      | PER | label | person |
      | CHD | label | child  |
    Then uniquely identify answer concepts
      | x   |
      | PER |
      | CHD |


  Scenario: a newly defined entity subtype inherits keys from all of its supertypes
    Given graql define
      """
      define
      athlete sub person;
      runner sub athlete;
      sprinter sub runner;
      """
    Given transaction commits
    Given the integrity is validated
    Given session opens transaction of type: read
    When get answers of graql query
      """
      match $x owns email @key;
      """
    When concept identifiers are
      |     | check | value    |
      | PER | label | person   |
      | ATH | label | athlete  |
      | RUN | label | runner   |
      | SPR | label | sprinter |
    Then uniquely identify answer concepts
      | x   |
      | PER |
      | ATH |
      | RUN |
      | SPR |


  Scenario: a type cannot be a subtype of itself
    Then graql define; throws exception
      """
      define dog sub dog;
      """
    Then the integrity is validated


  Scenario: defining a playable role is idempotent
    Given graql define
      """
      define
      house sub entity, plays home-ownership:home, plays home-ownership:home, plays home-ownership:home;
      home-ownership sub relation, relates home, relates owner;
      person plays home-ownership:owner;
      """
    Given transaction commits
    Given the integrity is validated
    Given session opens transaction of type: read
    When get answers of graql query
      """
      match $x plays home-ownership:home;
      """
    When concept identifiers are
      |     | check | value |
      | HOU | label | house |
    Then uniquely identify answer concepts
      | x   |
      | HOU |


  Scenario: defining an attribute ownership is idempotent
    Given graql define
      """
      define
      price sub attribute, value double;
      house sub entity, owns price, owns price, owns price;
      """
    Given transaction commits
    Given the integrity is validated
    Given session opens transaction of type: read
    When get answers of graql query
      """
      match $x owns price;
      """
    When concept identifiers are
      |     | check | value |
      | HOU | label | house |
    Then uniquely identify answer concepts
      | x   |
      | HOU |


  Scenario: defining a key ownership is idempotent
    Given graql define
      """
      define
      address sub attribute, value string;
      house sub entity, owns address @key, owns address @key, owns address @key;
      """
    Given transaction commits
    Given the integrity is validated
    Given session opens transaction of type: read
    When get answers of graql query
      """
      match $x owns address @key;
      """
    When concept identifiers are
      |     | check | value |
      | HOU | label | house |
    Then uniquely identify answer concepts
      | x   |
      | HOU |


  Scenario: defining a type without a 'sub' clause throws
    Then graql define; throws exception
      """
      define flying-spaghetti-monster;
      """
    Then the integrity is validated


  Scenario: a type cannot directly subtype 'thing' itself
    Then graql define; throws exception
      """
      define column sub thing;
      """
    Then the integrity is validated


  Scenario: an entity type can not have a value type defined
    Then graql define; throws exception
      """
      define cream sub entity, value double;
      """
    Then the integrity is validated


  Scenario: a type cannot have a 'when' block
    Then graql define; throws exception
      """
      define gorilla sub entity, when { $x isa gorilla; };
      """
    Then the integrity is validated


  Scenario: a type cannot have a 'then' block
    Then graql define; throws exception
      """
      define godzilla sub entity, then { $x isa godzilla; };
      """
    Then the integrity is validated


  Scenario: defining a thing with 'isa' is not possible in a 'define' query
    Then graql define; throws exception
      """
      define $p isa person;
      """
    Then the integrity is validated


  Scenario: adding an attribute instance to a thing is not possible in a 'define' query
    Then graql define; throws exception
      """
      define $p has name "Loch Ness Monster";
      """
    Then the integrity is validated


  @ignore
  # TODO: re-enable when writing a variable in a 'define' is forbidden
  Scenario: writing a variable in a 'define' is not allowed


  ##################
  # RELATION TYPES #
  ##################

  Scenario: new relation types can be defined
    When graql define
      """
      define pet-ownership sub relation, relates pet-owner, relates owned-pet;
      """
    Then transaction commits
    Then the integrity is validated
    When session opens transaction of type: read
    When get answers of graql query
      """
      match $x type pet-ownership;
      """
    When concept identifiers are
      |     | check | value         |
      | POW | label | pet-ownership |
    Then uniquely identify answer concepts
      | x   |
      | POW |


  Scenario: a new relation type can be defined as a subtype, creating a new child of its parent type
    When graql define
      """
      define fun-employment sub employment, relates employee-having-fun as employee;
      """
    Then transaction commits
    Then the integrity is validated
    When session opens transaction of type: read
    When get answers of graql query
      """
      match $x sub employment;
      """
    When concept identifiers are
      |     | check | value          |
      | EMP | label | employment     |
      | FUN | label | fun-employment |
    Then uniquely identify answer concepts
      | x   |
      | EMP |
      | FUN |


  Scenario: defining a relation type throws an error if it has no roleplayers and is not abstract
    Then graql define; throws exception
      """
      define useless-relation sub relation;
      """
    Then the integrity is validated


  Scenario: a newly defined relation subtype inherits roles from its supertype
    Given graql define
      """
      define part-time-employment sub employment;
      """
    Given transaction commits
    Given the integrity is validated
    Given session opens transaction of type: read
    When get answers of graql query
      """
      match $x relates employee;
      """
    When concept identifiers are
      |     | check | value                |
      | EMP | label | employment           |
      | PTT | label | part-time-employment |
    Then uniquely identify answer concepts
      | x   |
      | EMP |
      | PTT |


  Scenario: a newly defined relation subtype inherits roles from all of its supertypes


  Scenario: a relation type's role can be overridden in a child relation type using 'as'
    When graql define
      """
      define
      parenthood sub relation, relates parent, relates child;
      father-sonhood sub parenthood, relates father as parent, relates son as child;
      """
    Then transaction commits
    Then the integrity is validated
    When session opens transaction of type: read
    When get answers of graql query
      """
      match
        $x relates parenthood:parent;
        $x relates parenthood:child;
      """
    When concept identifiers are
      |     | check | value      |
      | PAR | label | parenthood |
    Then uniquely identify answer concepts
      | x   |
      | PAR |
    When get answers of graql query
      """
      match
        $x relates father-sonhood:father;
        $x relates father-sonhood:son;
      """
    When concept identifiers are
      |     | check | value          |
      | FSH | label | father-sonhood |
    Then uniquely identify answer concepts
      | x   |
      | FSH |


  Scenario: when a relation type's role is overridden, it creates a sub-role of the parent role type
    When graql define
      """
      define
      parenthood sub relation, relates parent, relates child;
      father-sonhood sub parenthood, relates father as parent, relates son as child;
      """
    Then transaction commits
    Then the integrity is validated
    When session opens transaction of type: read
    When get answers of graql query
      """
      match
      $x sub parenthood:parent; $y sub parenthood:child; get $x, $y;
      """
    When concept identifiers are
      |     | check | value  |
      | PAR | label | parent |
      | FAT | label | father |
      | CHI | label | child  |
      | SON | label | son    |
    Then uniquely identify answer concepts
      | x   | y   |
      | PAR | CHI |
      | FAT | CHI |
      | PAR | SON |
      | FAT | SON |


  Scenario: an overridden role is no longer associated with the relation type that overrides it
    Given graql define
      """
      define part-time-employment sub employment, relates part-timer as employee;
      """
    Given transaction commits
    Given the integrity is validated
    Given session opens transaction of type: read
    When get answers of graql query
      """
      match $x relates employment:employee;
      """
    When concept identifiers are
      |     | check | value      |
      | EMP | label | employment |
    Then uniquely identify answer concepts
      | x   |
      | EMP |
    

  Scenario: a newly defined relation subtype inherits playable roles from its parent type
    Given graql define
      """
      define contract-employment sub employment, relates contractor as employee;
      """
    Given transaction commits
    Given the integrity is validated
    Given session opens transaction of type: read
    When get answers of graql query
      """
      match $x plays income:source;
      """
    When concept identifiers are
      |     | check | value               |
      | EMP | label | employment          |
      | CEM | label | contract-employment |
    Then uniquely identify answer concepts
      | x   |
      | EMP |
      | CEM |


  Scenario: a newly defined relation subtype inherits playable roles from all of its supertypes
    Given graql define
      """
      define
      transport-employment sub employment, relates transport-worker as employee;
      aviation-employment sub transport-employment, relates aviation-worker as transport-worker;
      flight-attendant-employment sub aviation-employment, relates flight-attendant as aviation-worker;
      """
    Given transaction commits
    Given the integrity is validated
    Given session opens transaction of type: read
    When get answers of graql query
      """
      match $x plays income:source;
      """
    When concept identifiers are
      |     | check | value                       |
      | EMP | label | employment                  |
      | TRN | label | transport-employment        |
      | AVI | label | aviation-employment         |
      | FAA | label | flight-attendant-employment |
    Then uniquely identify answer concepts
      | x   |
      | EMP |
      | TRN |
      | AVI |
      | FAA |


  Scenario: a newly defined relation subtype inherits attribute ownerships from its parent type
    Given graql define
      """
      define contract-employment sub employment, relates contractor as employee;
      """
    Given transaction commits
    Given the integrity is validated
    Given session opens transaction of type: read
    When get answers of graql query
      """
      match $x owns start-date;
      """
    When concept identifiers are
      |     | check | value               |
      | EMP | label | employment          |
      | CEM | label | contract-employment |
    Then uniquely identify answer concepts
      | x   |
      | EMP |
      | CEM |


  Scenario: a newly defined relation subtype inherits attribute ownerships from all of its supertypes
    Given graql define
      """
      define
      transport-employment sub employment, relates transport-worker as employee;
      aviation-employment sub transport-employment, relates aviation-worker as transport-worker;
      flight-attendant-employment sub aviation-employment, relates flight-attendant as aviation-worker;
      """
    Given transaction commits
    Given the integrity is validated
    Given session opens transaction of type: read
    When get answers of graql query
      """
      match $x owns start-date;
      """
    When concept identifiers are
      |     | check | value                       |
      | EMP | label | employment                  |
      | TRN | label | transport-employment        |
      | AVI | label | aviation-employment         |
      | FAA | label | flight-attendant-employment |
    Then uniquely identify answer concepts
      | x   |
      | EMP |
      | TRN |
      | AVI |
      | FAA |


  Scenario: a newly defined relation subtype inherits keys from its parent type
    Given graql define
      """
      define contract-employment sub employment, relates contractor as employee;
      """
    Given transaction commits
    Given the integrity is validated
    Given session opens transaction of type: read
    When get answers of graql query
      """
      match $x owns employment-reference-code @key;
      """
    When concept identifiers are
      |     | check | value               |
      | EMP | label | employment          |
      | CEM | label | contract-employment |
    Then uniquely identify answer concepts
      | x   |
      | EMP |
      | CEM |


  Scenario: a newly defined relation subtype inherits keys from all of its supertypes
    Given graql define
      """
      define
      transport-employment sub employment, relates transport-worker as employee;
      aviation-employment sub transport-employment, relates aviation-worker as transport-worker;
      flight-attendant-employment sub aviation-employment, relates flight-attendant as aviation-worker;
      """
    Given transaction commits
    Given the integrity is validated
    Given session opens transaction of type: read
    When get answers of graql query
      """
      match $x owns employment-reference-code @key;
      """
    When concept identifiers are
      |     | check | value                       |
      | EMP | label | employment                  |
      | TRN | label | transport-employment        |
      | AVI | label | aviation-employment         |
      | FAA | label | flight-attendant-employment |
    Then uniquely identify answer concepts
      | x   |
      | EMP |
      | TRN |
      | AVI |
      | FAA |


  Scenario: a relation type can be defined with no roleplayers when it is marked as abstract
    When graql define
      """
      define connection sub relation, abstract;
      """
    Then transaction commits
    Then the integrity is validated
    When session opens transaction of type: read
    When get answers of graql query
      """
      match $x type connection;
      """
    When concept identifiers are
      |     | check | value      |
      | CON | label | connection |
    Then uniquely identify answer concepts
      | x   |
      | CON |


  Scenario: when defining a relation type, duplicate 'relates' are idempotent
    Given graql define
      """
      define
      parenthood sub relation, relates parent, relates child, relates child, relates parent, relates child;
      person plays parenthood:parent, plays parenthood:child;
      """
    Given transaction commits
    Given the integrity is validated
    Given session opens transaction of type: read
    When get answers of graql query
      """
      match $x relates parent; $x relates child;
      """
    When concept identifiers are
      |     | check | value      |
      | PAR | label | parenthood |
    Then uniquely identify answer concepts
      | x   |
      | PAR |


  Scenario: a relation type can relate to a role that it plays itself
    When graql define
      """
      define
      recursive-function sub relation, relates function, plays recursive-function:function;
      """
    Then transaction commits
    Then the integrity is validated
    Given session opens transaction of type: read
    When get answers of graql query
      """
      match $x relates function; $x plays recursive-function:function;
      """
    When concept identifiers are
      |     | check | value              |
      | REC | label | recursive-function |
    Then uniquely identify answer concepts
      | x   |
      | REC |


  Scenario: unrelated relations are allowed to have roles with the same name
    When graql define
      """
      define
      ownership sub relation, relates owner;
      loan sub relation, relates owner;
      """
    Then transaction commits
    Then the integrity is validated
    When session opens transaction of type: read
    When get answers of graql query
      """
      match $x relates owner;
      """
    When concept identifiers are
      |     | check | value     |
      | OWN | label | ownership |
      | LOA | label | loan      |
    Then uniquely identify answer concepts
      | x   |
      | OWN |
      | LOA |


  ###################
  # ATTRIBUTE TYPES #
  ###################

  Scenario Outline: a '<value_type>' attribute type can be defined
    Given graql define
      """
      define <label> sub attribute, value <value_type>;
      """
    Given transaction commits
    Given the integrity is validated
    Given session opens transaction of type: read
    When get answers of graql query
      """
      match
        $x type <label>;
        $x sub attribute;
      """
    Then answer size is: 1

  Examples:
    | value_type | label          |
    | boolean    | can-fly        |
    | long       | number-of-cows |
    | double     | density        |
    | string     | favourite-food |
    | datetime   | flight-date    |


  Scenario: defining an attribute type throws if you don't specify a value type
    Then graql define; throws exception
      """
      define colour sub attribute;
      """
    Then the integrity is validated


  Scenario: defining an attribute type throws if the specified value type is not a recognised value type
    Then graql define; throws exception
      """
      define colour sub attribute, value rgba;
      """
    Then the integrity is validated


  Scenario: a new attribute type can be defined as a subtype of an abstract attribute type
    When graql define
      """
      define
      code sub attribute, value string, abstract;
      door-code sub code;
      """
    Then transaction commits
    Then the integrity is validated
    Given session opens transaction of type: read
    When get answers of graql query
      """
      match $x sub code;
      """
    When concept identifiers are
      |     | check | value     |
      | COD | label | code      |
      | DOC | label | door-code |
    Then uniquely identify answer concepts
      | x   |
      | COD |
      | DOC |


  Scenario: a newly defined attribute subtype inherits the value type of its parent
    When graql define
      """
      define
      code sub attribute, value string, abstract;
      door-code sub code;
      """
    Then transaction commits
    Then the integrity is validated
    Given session opens transaction of type: read
    When get answers of graql query
      """
      match $x type door-code, value string;
      """
    When concept identifiers are
      |     | check | value     |
      | DOC | label | door-code |
    Then uniquely identify answer concepts
      | x   |
      | DOC |


  Scenario: defining an attribute subtype throws if it is given a different value type to what its parent has
    Then graql define; throws exception
      """
      define code-name sub name, value long;
      """
    Then the integrity is validated


  Scenario: a regex constraint can be defined on a 'string' attribute type
    Given graql define
      """
      define response sub attribute, value string, regex "^(yes|no|maybe)$";
      """
    Given transaction commits
    Given the integrity is validated
    Given session opens transaction of type: read
    When get answers of graql query
      """
      match $x regex "^(yes|no|maybe)$";
      """
    When concept identifiers are
      |     | check | value    |
      | RES | label | response |
    Then uniquely identify answer concepts
      | x   |
      | RES |


  Scenario: a regex constraint cannot be defined on an attribute type whose value type is anything other than 'string'
    Then graql define; throws exception
      """
      define name-in-binary sub attribute, value long, regex "^(0|1)+$";
      """
    Then the integrity is validated


  Scenario: a newly defined attribute subtype inherits playable roles from its parent type
    Given graql define
      """
      define
      car sub entity, plays car-sales-listing:listed-car;
      car-sales-listing sub relation, relates listed-car, relates available-colour;
      colour sub attribute, value string, plays car-sales-listing:available-colour, abstract;
      grayscale-colour sub colour;
      """
    Given transaction commits
    Given the integrity is validated
    Given session opens transaction of type: read
    When get answers of graql query
      """
      match $x plays car-sales-listing:available-colour;
      """
    When concept identifiers are
      |     | check | value            |
      | COL | label | colour           |
      | GRC | label | grayscale-colour |
    Then uniquely identify answer concepts
      | x   |
      | COL |
      | GRC |


  Scenario: a newly defined attribute subtype inherits playable roles from all of its supertypes
    Given graql define
      """
      define
      person plays phone-contact:person;
      phone-contact sub relation, relates person, relates number;
      phone-number sub attribute, value string, plays phone-contact:number, abstract;
      uk-phone-number sub phone-number, abstract;
      uk-landline-number sub uk-phone-number, abstract;
      uk-premium-landline-number sub uk-landline-number;
      """
    Given transaction commits
    Given the integrity is validated
    Given session opens transaction of type: read
    When get answers of graql query
      """
      match $x plays phone-contact:number;
      """
    When concept identifiers are
      |     | check | value                      |
      | PHN | label | phone-number               |
      | UKP | label | uk-phone-number            |
      | UKL | label | uk-landline-number         |
      | UPM | label | uk-premium-landline-number |
    Then uniquely identify answer concepts
      | x   |
      | PHN |
      | UKP |
      | UKL |
      | UPM |


  Scenario: a newly defined attribute subtype inherits attribute ownerships from its parent type
    Given graql define
      """
      define
      brightness sub attribute, value double;
      colour sub attribute, value string, owns brightness, abstract;
      grayscale-colour sub colour;
      """
    Given transaction commits
    Given the integrity is validated
    Given session opens transaction of type: read
    When get answers of graql query
      """
      match $x owns brightness;
      """
    When concept identifiers are
      |     | check | value            |
      | COL | label | colour           |
      | GRC | label | grayscale-colour |
    Then uniquely identify answer concepts
      | x   |
      | COL |
      | GRC |


  Scenario: a newly defined attribute subtype inherits attribute ownerships from all of its supertypes
    Given graql define
      """
      define
      country-calling-code sub attribute, value string;
      phone-number sub attribute, value string, owns country-calling-code, abstract;
      uk-phone-number sub phone-number, abstract;
      uk-landline-number sub uk-phone-number, abstract;
      uk-premium-landline-number sub uk-landline-number;
      """
    Given transaction commits
    Given the integrity is validated
    Given session opens transaction of type: read
    When get answers of graql query
      """
      match $x owns country-calling-code;
      """
    When concept identifiers are
      |     | check | value                      |
      | PHN | label | phone-number               |
      | UKP | label | uk-phone-number            |
      | UKL | label | uk-landline-number         |
      | UPM | label | uk-premium-landline-number |
    Then uniquely identify answer concepts
      | x   |
      | PHN |
      | UKP |
      | UKL |
      | UPM |


  Scenario: a newly defined attribute subtype inherits keys from its parent type
    Given graql define
      """
      define
      hex-value sub attribute, value string;
      colour sub attribute, value string, owns hex-value @key, abstract;
      grayscale-colour sub colour;
      """
    Given transaction commits
    Given the integrity is validated
    Given session opens transaction of type: read
    When get answers of graql query
      """
      match $x owns hex-value @key;
      """
    When concept identifiers are
      |     | check | value            |
      | COL | label | colour           |
      | GRC | label | grayscale-colour |
    Then uniquely identify answer concepts
      | x   |
      | COL |
      | GRC |


  Scenario: a newly defined attribute subtype inherits keys from all of its supertypes
    Given graql define
      """
      define
      hex-value sub attribute, value string;
      colour sub attribute, value string, owns hex-value @key, abstract;
      dark-colour sub colour, abstract;
      dark-red-colour sub dark-colour, abstract;
      very-dark-red-colour sub dark-red-colour;
      """
    Given transaction commits
    Given the integrity is validated
    Given session opens transaction of type: read
    When get answers of graql query
      """
      match $x owns hex-value @key;
      """
    When concept identifiers are
      |     | check | value                |
      | COL | label | colour               |
      | DRK | label | dark-colour          |
      | DKR | label | dark-red-colour      |
      | VDR | label | very-dark-red-colour |
    Then uniquely identify answer concepts
      | x   |
      | COL |
      | DRK |
      | DKR |
      | VDR |


  Scenario Outline: a type can own a '<value_type>' attribute type
    When graql define
      """
      define
      <label> sub attribute, value <value_type>;
      person owns <label>;
      """
    Then transaction commits
    Then the integrity is validated
    Given session opens transaction of type: read
    When get answers of graql query
      """
      match $x owns <label>;
      """
    When concept identifiers are
      |     | check | value  |
      | PER | label | person |
    Then uniquely identify answer concepts
      | x   |
      | PER |

  Examples:
    | value_type | label             |
    | boolean    | is-sleeping       |
    | long       | number-of-fingers |
    | double     | height            |
    | string     | first-word        |
    | datetime   | graduation-date   |


  Scenario: an attribute type can own itself
    When graql define
      """
      define number-of-letters sub attribute, value long, owns number-of-letters;
      """
    Then transaction commits
    Then the integrity is validated
    When session opens transaction of type: read
    When get answers of graql query
      """
      match $x owns number-of-letters;
      """
    When concept identifiers are
      |     | check | value             |
      | NOL | label | number-of-letters |
    Then uniquely identify answer concepts
      | x   |
      | NOL |


  ##################
  # ABSTRACT TYPES #
  ##################

  Scenario: an abstract entity type can be defined
    When graql define
      """
      define animal sub entity, abstract;
      """
    Then transaction commits
    Then the integrity is validated
    Given session opens transaction of type: read
    When get answers of graql query
      """
      match $x type animal; $x abstract;
      """
    When concept identifiers are
      |     | check | value  |
      | ANI | label | animal |
    Then uniquely identify answer concepts
      | x   |
      | ANI |


  Scenario: a concrete entity type can be defined as a subtype of an abstract entity type
    When graql define
      """
      define
      animal sub entity, abstract;
      horse sub animal;
      """
    Then transaction commits
    Then the integrity is validated
    Given session opens transaction of type: read
    When get answers of graql query
      """
      match $x sub animal;
      """
    When concept identifiers are
      |     | check | value  |
      | ANI | label | animal |
      | HOR | label | horse  |
    Then uniquely identify answer concepts
      | x   |
      | ANI |
      | HOR |


  Scenario: an abstract entity type can be defined as a subtype of another abstract entity type
    When graql define
      """
      define
      animal sub entity, abstract;
      fish sub animal, abstract;
      """
    Then transaction commits
    Then the integrity is validated
    Given session opens transaction of type: read
    When get answers of graql query
      """
      match $x sub animal; $x abstract;
      """
    When concept identifiers are
      |     | check | value  |
      | ANI | label | animal |
      | FSH | label | fish   |
    Then uniquely identify answer concepts
      | x   |
      | ANI |
      | FSH |


  Scenario: an abstract relation type can be defined
    When graql define
      """
      define membership sub relation, abstract, relates member;
      """
    Then transaction commits
    Then the integrity is validated
    Given session opens transaction of type: read
    When get answers of graql query
      """
      match $x type membership; $x abstract;
      """
    When concept identifiers are
      |     | check | value      |
      | MEM | label | membership |
    Then uniquely identify answer concepts
      | x   |
      | MEM |


  Scenario: a concrete relation type can be defined as a subtype of an abstract relation type
    When graql define
      """
      define
      membership sub relation, abstract, relates member;
      gym-membership sub membership, relates gym-with-members, relates gym-member as member;
      """
    Then transaction commits
    Then the integrity is validated
    When session opens transaction of type: read
    When get answers of graql query
      """
      match $x sub membership;
      """
    When concept identifiers are
      |     | check | value          |
      | MEM | label | membership     |
      | GYM | label | gym-membership |
    Then uniquely identify answer concepts
      | x   |
      | MEM |
      | GYM |


  Scenario: an abstract relation type can be defined as a subtype of another abstract relation type
    When graql define
      """
      define
      requirement sub relation, abstract, relates prerequisite, relates outcome;
      tool-requirement sub requirement, abstract, relates required-tool as prerequisite;
      """
    Then transaction commits
    Then the integrity is validated
    When session opens transaction of type: read
    When get answers of graql query
      """
      match $x sub requirement; $x abstract;
      """
    When concept identifiers are
      |     | check | value            |
      | REQ | label | requirement      |
      | TLR | label | tool-requirement |
    Then uniquely identify answer concepts
      | x   |
      | REQ |
      | TLR |


  Scenario: an abstract attribute type can be defined
    When graql define
      """
      define number-of-limbs sub attribute, abstract, value long;
      """
    Then transaction commits
    Then the integrity is validated
    Given session opens transaction of type: read
    When get answers of graql query
      """
      match $x type number-of-limbs; $x abstract;
      """
    When concept identifiers are
      |     | check | value           |
      | NOL | label | number-of-limbs |
    Then uniquely identify answer concepts
      | x   |
      | NOL |


  Scenario: a concrete attribute type can be defined as a subtype of an abstract attribute type
    When graql define
      """
      define
      number-of-limbs sub attribute, abstract, value long;
      number-of-legs sub number-of-limbs;
      """
    Then transaction commits
    Then the integrity is validated
    When session opens transaction of type: read
    When get answers of graql query
      """
      match $x sub number-of-limbs;
      """
    When concept identifiers are
      |     | check | value           |
      | NOL | label | number-of-limbs |
      | NLE | label | number-of-legs  |
    Then uniquely identify answer concepts
      | x   |
      | NOL |
      | NLE |


  Scenario: an abstract attribute type can be defined as a subtype of another abstract attribute type
    When graql define
      """
      define
      number-of-limbs sub attribute, abstract, value long;
      number-of-artificial-limbs sub number-of-limbs, abstract;
      """
    Then transaction commits
    Then the integrity is validated
    Given session opens transaction of type: read
    When get answers of graql query
      """
      match $x sub number-of-limbs; $x abstract;
      """
    When concept identifiers are
      |     | check | value                      |
      | NOL | label | number-of-limbs            |
      | NAL | label | number-of-artificial-limbs |
    Then uniquely identify answer concepts
      | x   |
      | NOL |
      | NAL |


  Scenario: an abstract type cannot be the subtype of a concrete entity
    Then graql define; throws exception
      """
      define
      exception sub entity;
      grakn-exception sub exception, abstract;
      """
    Then the integrity is validated


  Scenario: repeating the term 'abstract' when defining a type causes an error to be thrown
    Given graql define; throws exception
      """
      define animal sub entity, abstract, abstract, abstract;
      """
    Then the integrity is validated


  ###################
  # SCHEMA MUTATION #
  ###################

  Scenario: an existing type can be repeatedly redefined, and it is a no-op
    When graql define
      """
      define
      person sub entity, owns name;
      person sub entity, owns name;
      person sub entity, owns name;
      """
    Then transaction commits
    Then the integrity is validated
    When session opens transaction of type: read
    When get answers of graql query
      """
      match $x type person, owns name;
      """
    Then answer size is: 1


  Scenario: an entity type cannot be changed into a relation type
    Then graql define; throws exception
      """
      define
      person sub relation, relates body-part;
      arm sub entity, plays person:body-part;
      """
    Then the integrity is validated


  Scenario: a relation type cannot be changed into an attribute type
    Then graql define; throws exception
      """
      define employment sub attribute, value string;
      """
    Then the integrity is validated


  Scenario: an attribute type cannot be changed into an entity type
    Then graql define; throws exception
      """
      define name sub entity;
      """
    Then the integrity is validated


  Scenario: a new attribute ownership can be defined on an existing type
    When graql define
      """
      define employment owns name;
      """
    Then transaction commits
    Then the integrity is validated
    When session opens transaction of type: read
    When get answers of graql query
      """
      match $x owns name;
      """
    When concept identifiers are
      |     | check | value      |
      | PER | label | person     |
      | EMP | label | employment |
    Then uniquely identify answer concepts
      | x   |
      | PER |
      | EMP |


  Scenario: a new playable role can be defined on an existing type
    When graql define
      """
      define employment plays employment:employee;
      """
    Then transaction commits
    Then the integrity is validated
    When session opens transaction of type: read
    When get answers of graql query
      """
      match $x plays employment:employee;
      """
    When concept identifiers are
      |     | check | value      |
      | PER | label | person     |
      | EMP | label | employment |
    Then uniquely identify answer concepts
      | x   |
      | PER |
      | EMP |


  Scenario: defining a key on an existing type is possible if existing instances have it and there are no collisions
    Given graql define
      """
      define
      barcode sub attribute, value string;
      product sub entity, owns name, owns barcode;
      """
    Given transaction commits
    Given the integrity is validated
    Given connection close all sessions
    Given connection open data session for database: grakn
    Given session opens transaction of type: write
    Given graql insert
      """
      insert
      $x isa product, has name "Cheese", has barcode "10001";
      $y isa product, has name "Ham", has barcode "10011";
      """
    Given transaction commits
    Given the integrity is validated
    Given connection close all sessions
    Given connection open schema session for database: grakn
    Given session opens transaction of type: write
    When graql define
      """
      define
      product owns barcode @key;
      """
    Then transaction commits
    Then the integrity is validated
    When get answers of graql query
      """
      match $x owns barcode @key;
      """
    When concept identifiers are
      |     | check | value   |
      | PRD | label | product |
    Then uniquely identify answer concepts
      | x   |
      | PRD |


  Scenario: defining a key on a type throws if existing instances don't have that key
    Given graql define
      """
      define
      barcode sub attribute, value string;
      product sub entity, owns name;
      """
    Given transaction commits
    Given the integrity is validated
    Given connection close all sessions
    Given connection open data session for database: grakn
    Given session opens transaction of type: write
    Given graql insert
      """
      insert
      $x isa product, has name "Cheese";
      $y isa product, has name "Ham";
      """
    Given transaction commits
    Given the integrity is validated
    Given connection close all sessions
    Given connection open schema session for database: grakn
    Given session opens transaction of type: write
    Then graql define; throws exception
      """
      define
      product owns barcode @key;
      """
    Then the integrity is validated


  Scenario: defining a key on a type throws if there is a key collision between two existing instances
    Given graql define
      """
      define
      barcode sub attribute, value string;
      product sub entity, owns name, owns barcode;
      """
    Given transaction commits
    Given the integrity is validated
    Given connection close all sessions
    Given connection open data session for database: grakn
    Given session opens transaction of type: write
    Given graql insert
      """
      insert
      $x isa product, has name "Cheese", has barcode "10000";
      $y isa product, has name "Ham", has barcode "10000";
      """
    Given transaction commits
    Given the integrity is validated
    Given connection close all sessions
    Given connection open schema session for database: grakn
    Given session opens transaction of type: write
    Then graql define; throws exception
      """
      define
      product owns barcode @key;
      """
    Then the integrity is validated


  Scenario: a new role can be defined on an existing relation type
    When graql define
      """
      define
      company sub entity, plays employment:employer;
      employment relates employer;
      """
    Then transaction commits
    Then the integrity is validated
    When session opens transaction of type: read
    When get answers of graql query
      """
      match $x relates employer;
      """
    When concept identifiers are
      |     | check | value      |
      | EMP | label | employment |
    Then uniquely identify answer concepts
      | x   |
      | EMP |


  Scenario: a regex constraint can be added to an existing attribute type if all its instances satisfy it
    Given connection close all sessions
    Given connection open data session for database: grakn
    Given session opens transaction of type: write
    Given graql insert
      """
      insert
      $x isa person, has name "Alice", has email "alice@grakn.ai";
      """
    Given transaction commits
    Given the integrity is validated
    Given connection close all sessions
    Given connection open schema session for database: grakn
    Given session opens transaction of type: write
    When graql define
      """
      define name regex "^A.*$";
      """
    Then transaction commits
    Then the integrity is validated
    Then session opens transaction of type: read
    Then get answers of graql query
      """
      match $x regex "^A.*$";
      """
    When concept identifiers are
      |     | check | value |
      | NAM | label | name  |
    Then uniquely identify answer concepts
      | x   |
      | NAM |


  Scenario: a regex cannot be added to an existing attribute type if there is an instance that doesn't satisfy it
    Given connection close all sessions
    Given connection open data session for database: grakn
    Given session opens transaction of type: write
    Given graql insert
      """
      insert
      $x isa person, has name "Maria", has email "maria@grakn.ai";
      """
    Given transaction commits
    Given the integrity is validated
    Given connection close all sessions
    Given connection open schema session for database: grakn
    Given session opens transaction of type: write
    Then graql define; throws exception
      """
      define name regex "^A.*$";
      """
    Then the integrity is validated


  Scenario: a regex constraint can not be added to an existing attribute type whose value type isn't 'string'
    Given graql define
      """
      define house-number sub attribute, value long;
      """
    Given transaction commits
    Given the integrity is validated
    Given session opens transaction of type: write
    Then graql define; throws exception
      """
      define house-number regex "^A.*$";
      """
    Then the integrity is validated


  Scenario: related roles cannot be added to existing entity types
    Then graql define; throws exception
      """
      define person relates employee;
      """
    Then the integrity is validated


  Scenario: related roles cannot be added to existing attribute types
    Then graql define; throws exception
      """
      define name relates employee;
      """
    Then the integrity is validated


  Scenario: the value type of an existing attribute type is not modifiable
    Then graql define; throws exception
      """
      define name value long;
      """
    Then the integrity is validated


  Scenario: an attribute ownership can not be converted to a key ownership
    Then graql define; throws exception
      """
      define person owns name @key;
      """
    Then the integrity is validated


  Scenario: the definition of a rule is not modifiable
    Given graql define
      """
      define
      nickname sub attribute, value string;
      person owns nickname;
      robert-has-nickname-bob sub rule,
      when {
        $p isa person, has name "Robert";
      }, then {
        $p has nickname "Bob";
      };
      """
    Given the integrity is validated
    Then graql define; throws exception
      """
      define
      robert-has-nickname-bob sub rule,
      when {
        $p isa person, has name "robert";
      }, then {
        $p has nickname "bob";
      };
      """
    Then the integrity is validated


  #############################
  # SCHEMA MUTATION: ABSTRACT #
  #############################

  Scenario: a concrete entity type can be converted to an abstract entity type
    When graql define
      """
      define person abstract;
      """
    Then transaction commits
    Then the integrity is validated
    When session opens transaction of type: read
    When get answers of graql query
      """
      match $x sub person; $x abstract;
      """
    When concept identifiers are
      |     | check | value  |
      | PER | label | person |
    Then uniquely identify answer concepts
      | x   |
      | PER |


  Scenario: a concrete relation type can be converted to an abstract relation type
    When graql define
      """
      define employment abstract;
      """
    Then transaction commits
    Then the integrity is validated
    When session opens transaction of type: read
    When get answers of graql query
      """
      match $x sub employment; $x abstract;
      """
    When concept identifiers are
      |     | check | value      |
      | EMP | label | employment |
    Then uniquely identify answer concepts
      | x   |
      | EMP |


  Scenario: a concrete attribute type can be converted to an abstract attribute type
    When graql define
      """
      define name abstract;
      """
    Then transaction commits
    Then the integrity is validated
    When session opens transaction of type: read
    When get answers of graql query
      """
      match $x sub name; $x abstract;
      """
    When concept identifiers are
      |     | check | value |
      | NAM | label | name  |
    Then uniquely identify answer concepts
      | x   |
      | NAM |


  Scenario: an existing entity type cannot be converted to abstract if it has existing instances
    Given connection close all sessions
    Given connection open data session for database: grakn
    Given session opens transaction of type: write
    Given graql insert
      """
      insert
      $x isa person, has name "Jeremy", has email "jeremy@grakn.ai";
      """
    Given transaction commits
    Given the integrity is validated
    Given connection close all sessions
    Given connection open schema session for database: grakn
    Given session opens transaction of type: write
    Then graql define; throws exception
      """
      define person abstract;
      """
    Then the integrity is validated


  Scenario: an existing relation type cannot be converted to abstract if it has existing instances


  Scenario: an existing attribute type cannot be converted to abstract if it has existing instances
    Given connection close all sessions
    Given connection open data session for database: grakn
    Given session opens transaction of type: write
    Given graql insert
      """
      insert
      $x isa person, has name "Jeremy", has email "jeremy@grakn.ai";
      """
    Given transaction commits
    Given the integrity is validated
    Given connection close all sessions
    Given connection open schema session for database: grakn
    Given session opens transaction of type: write
    Then graql define; throws exception
      """
      define name abstract;
      """
    Then the integrity is validated


  Scenario: changing a concrete type to abstract throws on commit if it has a concrete supertype

  @ignore
  # TODO: re-enable when rules cannot infer abstract relations
  Scenario: changing a concrete relation type to abstract throws on commit if it appears in the conclusion of any rule

  @ignore
  # TODO: re-enable when rules cannot infer abstract attributes
  Scenario: changing a concrete attribute type to abstract throws on commit if it appears in the conclusion of any rule

  ######################
  # HIERARCHY MUTATION #
  ######################

  Scenario: an existing entity type can be switched to a new supertype
    Given graql define
      """
      define
      apple-product sub entity;
      genius sub person;
      """
    Given transaction commits
    Given the integrity is validated
    Given session opens transaction of type: write
    When graql define
      """
      define
      genius sub apple-product;
      """
    Then transaction commits
    Then the integrity is validated
    When session opens transaction of type: read
    When get answers of graql query
      """
      match $x sub apple-product;
      """
    When concept identifiers are
      |     | check | value         |
      | APL | label | apple-product |
      | GEN | label | genius        |
    Then uniquely identify answer concepts
      | x   |
      | APL |
      | GEN |


  Scenario: an existing relation type can be switched to a new supertype


  Scenario: an existing attribute type can be switched to a new supertype with a matching value type
    Given graql define
      """
      define
      measure sub attribute, value double, abstract;
      shoe-size sub measure;
      shoe sub entity, owns shoe-size;
      """
    Given transaction commits
    Given the integrity is validated
    Given connection close all sessions
    Given connection open data session for database: grakn
    Given session opens transaction of type: write
    Given graql insert
      """
      insert $s isa shoe, has shoe-size 9;
      """
    Given transaction commits
    Given the integrity is validated
    Given connection close all sessions
    Given connection open schema session for database: grakn
    Given session opens transaction of type: write
    When graql define
      """
      define
      size sub attribute, value double, abstract;
      shoe-size sub size;
      """
    Then transaction commits
    Then the integrity is validated
    When session opens transaction of type: read
    When get answers of graql query
      """
      match $x sub shoe-size;
      """
    When concept identifiers are
      |     | check | value     |
      | SHS | label | shoe-size |
    Then uniquely identify answer concepts
      | x   |
      | SHS |


  Scenario: assigning a new supertype succeeds even if they have different attributes + roles, if there are no instances
    Given graql define
      """
      define
      species sub entity, owns name, plays species-membership:species;
      species-membership sub relation, relates species, relates member;
      lifespan sub attribute, value double;
      organism sub entity, owns lifespan, plays species-membership:member;
      child sub person;
      """
    Given transaction commits
    Given the integrity is validated
    Given session opens transaction of type: write
    When graql define
      """
      define
      person sub organism;
      """
    Then transaction commits
    Then the integrity is validated
    When session opens transaction of type: read
    When get answers of graql query
      """
      match $x sub organism;
      """
    When concept identifiers are
      |     | check | value    |
      | ORG | label | organism |
      | PER | label | person   |
      | CHI | label | child    |
    Then uniquely identify answer concepts
      | x   |
      | ORG |
      | PER |
      | CHI |


  Scenario: assigning a new supertype succeeds even with existing data if the supertypes have no properties
    Given graql define
      """
      define
      bird sub entity;
      pigeon sub bird;
      """
    Given transaction commits
    Given the integrity is validated
    Given connection close all sessions
    Given connection open data session for database: grakn
    Given session opens transaction of type: write
    Given graql insert
      """
      insert $p isa pigeon;
      """
    Given transaction commits
    Given the integrity is validated
    Given connection close all sessions
    Given connection open schema session for database: grakn
    Given session opens transaction of type: write
    When graql define
      """
      define
      animal sub entity;
      pigeon sub animal;
      """
    Then transaction commits
    Then the integrity is validated
    When session opens transaction of type: read
    When get answers of graql query
      """
      match $x sub pigeon;
      """
    When concept identifiers are
      |     | check | value  |
      | PIG | label | pigeon |
    Then uniquely identify answer concepts
      | x   |
      | PIG |


  Scenario: assigning a new supertype succeeds with existing data if the supertypes play the same roles
    Given graql define
      """
      define
      bird sub entity, plays flying:flier;
      pigeon sub bird;
      flying sub relation, relates flier;
      """
    Given transaction commits
    Given the integrity is validated
    Given connection close all sessions
    Given connection open data session for database: grakn
    Given session opens transaction of type: write
    Given graql insert
      """
      insert $p isa pigeon;
      """
    Given transaction commits
    Given the integrity is validated
    Given connection close all sessions
    Given connection open schema session for database: grakn
    Given session opens transaction of type: write
    When graql define
      """
      define
      animal sub entity, plays flying:flier;
      pigeon sub animal;
      """
    Then transaction commits
    Then the integrity is validated
    When session opens transaction of type: read
    When get answers of graql query
      """
      match $x sub pigeon;
      """
    When concept identifiers are
      |     | check | value  |
      | PIG | label | pigeon |
    Then uniquely identify answer concepts
      | x   |
      | PIG |


  Scenario: assigning a new supertype succeeds with existing data if the supertypes have the same attributes
    Given graql define
      """
      define
      name sub attribute, value string;
      bird sub entity, owns name;
      pigeon sub bird;
      """
    Given transaction commits
    Given the integrity is validated
    Given connection close all sessions
    Given connection open data session for database: grakn
    Given session opens transaction of type: write
    Given graql insert
      """
      insert $p isa pigeon;
      """
    Given transaction commits
    Given the integrity is validated
    Given connection close all sessions
    Given connection open schema session for database: grakn
    Given session opens transaction of type: write
    When graql define
      """
      define
      animal sub entity, owns name;
      pigeon sub animal;
      """
    Then transaction commits
    Then the integrity is validated
    When session opens transaction of type: read
    When get answers of graql query
      """
      match $x sub pigeon;
      """
    When concept identifiers are
      |     | check | value  |
      | PIG | label | pigeon |
    Then uniquely identify answer concepts
      | x   |
      | PIG |


  # TODO: write this once 'assign new supertype .. with existing data' succeeds if the supertypes have the same attributes
  Scenario: assigning a new supertype throws if existing data has attributes not present on the new supertype

  # TODO: write this once 'assign new supertype .. with existing data' succeeds if the supertypes play the same roles
  Scenario: assigning a new supertype throws if existing data plays a role that it can't with the new supertype

  # TODO: write this once 'assign new supertype throws if .. data has attributes not present on the new supertype' is written
  Scenario: assigning a new supertype throws if that supertype has a has not @key present in the existing data (?)

  # TODO: write this once 'define new 'sub' on relation type changes its supertype' is written
  Scenario: assigning a new super-relation throws if existing data has roleplayers not present on the new supertype (?)

  # TODO: write this once 'define new 'sub' on attribute type changes its supertype' passes
  Scenario: assigning a new super-attribute throws if it has a different value type (?)

  # TODO: write this if 'assign new super-attribute throws if it has a different value type ..' turns out to not throw
  Scenario: assigning a new super-attribute throws if it has existing data and a different value type (?)

  # TODO: write this once 'define new 'sub' on attribute type changes its supertype' passes
  Scenario: assigning a new super-attribute throws if the new supertype has a regex and existing data doesn't match it (?)

  ###############################
  # SCHEMA MUTATION INHERITANCE #
  ###############################

  Scenario: when adding a playable role to an existing type, the change is propagated to its subtypes
    Given graql define
      """
      define
      employment sub relation, relates employer;
      child sub person;
      person sub entity, plays employment:employer;
      """
    Given transaction commits
    Given the integrity is validated
    Given session opens transaction of type: read
    When get answers of graql query
      """
      match $x type child, plays $r;
      """
    When concept identifiers are
      |          | check | value    |
      | EMPLOYEE | label | employee |
      | EMPLOYER | label | employer |
      | EARNER   | label | earner   |
      | CHILD    | label | child    |
    Then uniquely identify answer concepts
      | x     | r        |
      | CHILD | EMPLOYEE |
      | CHILD | EMPLOYER |
      | CHILD | EARNER   |


  Scenario: when adding an attribute ownership to an existing type, the change is propagated to its subtypes
    Given graql define
    """
       define
       child sub person;
       phone-number sub attribute, value long;
       person sub entity, owns phone-number;
      """
    Given transaction commits
    Given the integrity is validated
    Given session opens transaction of type: read
    When get answers of graql query
      """
      match $x type child, has $y;
      """
    When concept identifiers are
      |       | check | value        |
      | CHILD | label | child        |
      | NAME  | label | name         |
      | PHONE | label | phone-number |
    Then uniquely identify answer concepts
      | x     | y     |
      | CHILD | NAME  |
      | CHILD | PHONE |


  Scenario: when adding a key ownership to an existing type, the change is propagated to its subtypes
    Given graql define
      """
      define
      child sub person;
      phone-number sub attribute, value long;
      person sub entity, owns phone-number @key;
      """
    Given transaction commits
    Given the integrity is validated
    Given session opens transaction of type: read
    When get answers of graql query
      """
      match $x type child, key $y;
      """
    When concept identifiers are
      |       | check | value |
      | CHILD | label | child |
      | EMAIL | label | email |
    Then uniquely identify answer concepts
      | x     | y     |
      | CHILD | EMAIL |
      | CHILD | EMAIL |


  Scenario: when adding a related role to an existing relation type, the change is propagated to all its subtypes
    Given graql define
      """
      define
      part-time-employment sub employment;
      employment sub relation, relates employer;
      """
    Given transaction commits
    Given the integrity is validated
    Given session opens transaction of type: read
    When get answers of graql query
      """
      match $x type part-time-employment, relates $r;
      """
    When concept identifiers are
      |           | check | value                |
      | EMPLOYEE  | label | employee             |
      | EMPLOYER  | label | employer             |
      | PART_TIME | label | part-time-employment |
    Then uniquely identify answer concepts
      | x         | r        |
      | PART_TIME | EMPLOYEE |
      | PART_TIME | EMPLOYER |


  ####################
  # TRANSACTIONALITY #
  ####################

  Scenario: uncommitted transaction writes are not persisted
    When graql define
      """
      define dog sub entity;
      """
    When session opens transaction of type: read
    Then graql match throws
      """
      match $x type dog;
      """
