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
Feature: TypeQL Define Query

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
      person sub entity, plays employment:employee, plays income:earner, owns name, owns email @key, owns phone-nr @unique;
      employment sub relation, relates employee, plays income:source, owns start-date, owns employment-reference-code @key;
      income sub relation, relates earner, relates source;

      name sub attribute, value string;
      email sub attribute, value string;
      start-date sub attribute, value datetime;
      employment-reference-code sub attribute, value string;
      phone-nr sub attribute, value string;
      """
    Given transaction commits

    Given session opens transaction of type: write


  ################
  # ENTITY TYPES #
  ################

  Scenario: new entity types can be defined
    When typeql define
      """
      define dog sub entity;
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql match
      """
      match $x type dog;
      """
    Then uniquely identify answer concepts
      | x         |
      | label:dog |


  Scenario: a new entity type can be defined as a subtype, creating a new child of its parent type
    When typeql define
      """
      define child sub person;
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
      | label:child  |


  Scenario: when defining that a type owns a non-existent thing, an error is thrown
    Then typeql define; throws exception
      """
      define book sub entity, owns pages;
      """


  Scenario: types cannot own entity types
    Then typeql define; throws exception
      """
      define house sub entity, owns person;
      """


  Scenario: types cannot own relation types
    Then typeql define; throws exception
      """
      define company sub entity, owns employment;
      """


  Scenario: when defining that a type plays a non-existent role, an error is thrown
    Then typeql define; throws exception
      """
      define house sub entity, plays constructed:something;
      """


  Scenario: types cannot play entity types
    Then typeql define; throws exception
      """
      define parrot sub entity, plays person;
      """


  Scenario: types can not own entity types as keys
    Then typeql define; throws exception
      """
      define passport sub entity, owns person @key;
      """


  Scenario: a newly defined entity subtype inherits playable roles from its parent type
    Given typeql define
      """
      define child sub person;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match $x plays employment:employee;
      """
    Then uniquely identify answer concepts
      | x            |
      | label:person |
      | label:child  |


  Scenario: a newly defined entity subtype inherits playable roles from all of its supertypes
    Given typeql define
      """
      define
      athlete sub person;
      runner sub athlete;
      sprinter sub runner;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match $x plays employment:employee;
      """
    Then uniquely identify answer concepts
      | x              |
      | label:person   |
      | label:athlete  |
      | label:runner   |
      | label:sprinter |


  Scenario: a newly defined entity subtype inherits attribute ownerships from its parent type
    Given typeql define
      """
      define child sub person;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match $x owns name;
      """
    Then uniquely identify answer concepts
      | x            |
      | label:person |
      | label:child  |


  Scenario: a newly defined entity subtype inherits attribute ownerships from all of its supertypes
    Given typeql define
      """
      define
      athlete sub person;
      runner sub athlete;
      sprinter sub runner;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match $x owns name;
      """
    Then uniquely identify answer concepts
      | x              |
      | label:person   |
      | label:athlete  |
      | label:runner   |
      | label:sprinter |


  Scenario: a newly defined entity subtype inherits keys from its parent type
    Given typeql define
      """
      define child sub person;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match $x owns email @key;
      """
    Then uniquely identify answer concepts
      | x            |
      | label:person |
      | label:child  |


  Scenario: a newly defined entity subtype inherits keys from all of its supertypes
    Given typeql define
      """
      define
      athlete sub person;
      runner sub athlete;
      sprinter sub runner;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match $x owns email @key;
      """
    Then uniquely identify answer concepts
      | x              |
      | label:person   |
      | label:athlete  |
      | label:runner   |
      | label:sprinter |


  Scenario: defining a playable role is idempotent
    Given typeql define
      """
      define
      house sub entity, plays home-ownership:home, plays home-ownership:home, plays home-ownership:home;
      home-ownership sub relation, relates home, relates owner;
      person plays home-ownership:owner;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match $x plays home-ownership:home;
      """
    Then uniquely identify answer concepts
      | x           |
      | label:house |


  Scenario: defining an attribute ownership is idempotent
    Given typeql define
      """
      define
      price sub attribute, value double;
      house sub entity, owns price, owns price, owns price;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match $x owns price;
      """
    Then uniquely identify answer concepts
      | x           |
      | label:house |


  Scenario: defining a key ownership is idempotent
    Given typeql define
      """
      define
      address sub attribute, value string;
      house sub entity, owns address @key, owns address @key, owns address @key;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match $x owns address @key;
      """
    Then uniquely identify answer concepts
      | x           |
      | label:house |


  Scenario: defining a type without a 'sub' clause throws
    Then typeql define; throws exception
      """
      define flying-spaghetti-monster;
      """


  Scenario: a type cannot directly subtype 'thing' itself
    Then typeql define; throws exception
      """
      define column sub thing;
      """


  Scenario: an entity type can not have a value type defined
    Then typeql define; throws exception
      """
      define cream sub entity, value double;
      """


  Scenario: a type cannot have a 'when' block
    Then typeql define; throws exception
      """
      define gorilla sub entity, when { $x isa gorilla; };
      """


  Scenario: a type cannot have a 'then' block
    Then typeql define; throws exception
      """
      define godzilla sub entity, then { $x isa godzilla; };
      """


  Scenario: defining a thing with 'isa' is not possible in a 'define' query
    Then typeql define; throws exception
      """
      define $p isa person;
      """


  Scenario: adding an attribute instance to a thing is not possible in a 'define' query
    Then typeql define; throws exception
      """
      define $p has name "Loch Ness Monster";
      """


  Scenario: writing a variable in a 'define' is not allowed
    Then typeql define; throws exception
      """
      define $x sub entity;
      """



  ##################
  # RELATION TYPES #
  ##################

  Scenario: new relation types can be defined
    When typeql define
      """
      define pet-ownership sub relation, relates pet-owner, relates owned-pet;
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql match
      """
      match $x type pet-ownership;
      """
    Then uniquely identify answer concepts
      | x                   |
      | label:pet-ownership |


  Scenario: a new relation type can be defined as a subtype, creating a new child of its parent type
    When typeql define
      """
      define fun-employment sub employment, relates employee-having-fun as employee;
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql match
      """
      match $x sub employment;
      """
    Then uniquely identify answer concepts
      | x                    |
      | label:employment     |
      | label:fun-employment |


  Scenario: defining a relation type throws on commit if it has no roleplayers and is not abstract
    Then typeql define
      """
      define useless-relation sub relation;
      """
    Then transaction commits; throws exception


  Scenario: a newly defined relation subtype inherits roles from its supertype
    Given typeql define
      """
      define part-time-employment sub employment;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match $x relates employee;
      """
    Then uniquely identify answer concepts
      | x                          |
      | label:employment           |
      | label:part-time-employment |


  Scenario: a newly defined relation subtype inherits roles from all of its supertypes


  Scenario: a relation type's role can be overridden in a child relation type using 'as'
    When typeql define
      """
      define
      parenthood sub relation, relates parent, relates child;
      father-sonhood sub parenthood, relates father as parent, relates son as child;
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql match
      """
      match
        $x relates parent;
        $x relates child;
      """
    Then uniquely identify answer concepts
      | x                |
      | label:parenthood |
    When get answers of typeql match
      """
      match
        $x relates father;
        $x relates son;
      """
    Then uniquely identify answer concepts
      | x                    |
      | label:father-sonhood |


  Scenario: when a relation type's role is overridden, it creates a sub-role of the parent role type
    When typeql define
      """
      define
      parenthood sub relation, relates parent, relates child;
      father-sonhood sub parenthood, relates father as parent, relates son as child;
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql match
      """
      match
      $x sub parenthood:parent; $y sub parenthood:child; get $x, $y;
      """
    Then uniquely identify answer concepts
      | x                           | y                        |
      | label:parenthood:parent     | label:parenthood:child   |
      | label:father-sonhood:father | label:parenthood:child   |
      | label:parenthood:parent     | label:father-sonhood:son |
      | label:father-sonhood:father | label:father-sonhood:son |


  Scenario: an overridden role is no longer associated with the relation type that overrides it
    Given typeql define
      """
      define part-time-employment sub employment, relates part-timer as employee;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match $x relates employee;
      """
    Then uniquely identify answer concepts
      | x                |
      | label:employment |


  Scenario: when overriding a role that doesn't exist on the parent relation, an error is thrown
    Then typeql define; throws exception
      """
      define
      close-friendship sub relation, relates close-friend as friend;
      """


  Scenario: relation subtypes can have roles that their supertypes don't have
    Given typeql define
      """
      define
      plane sub entity, plays pilot-employment:preferred-plane;
      pilot-employment sub employment, relates pilot as employee, relates preferred-plane;
      person plays pilot-employment:pilot;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match $x relates preferred-plane;
      """
    Then uniquely identify answer concepts
      | x                      |
      | label:pilot-employment |


  Scenario: types should be able to define roles they play with an override
    Then typeql define
      """
        define
        locates sub relation, relates located;
        contractor-locates sub locates, relates contractor-located as located;

        employment sub relation, relates employee, plays locates:located;
        contractor-employment sub employment, plays contractor-locates:contractor-located as located;
      """


  Scenario: already shadowed types should not be overrideable
    Then typeql define; throws exception
      """
        define
        locates sub relation, relates located;
        contractor-locates sub locates, relates contractor-located as located;
        software-contractor-locates sub contractor-locates, relates software-contractor-located as contractor-located;

        employment sub relation, relates employee, plays locates:located;
        contractor-employment sub employment, plays contractor-locates:contractor-located as located;
        software-contractor-employment sub contractor-employment, plays software-contractor-locates:software-contractor-located as located;
      """


  Scenario: a newly defined relation subtype inherits playable roles from its parent type
    Given typeql define
      """
      define contract-employment sub employment, relates contractor as employee;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match $x plays income:source;
      """
    Then uniquely identify answer concepts
      | x                         |
      | label:employment          |
      | label:contract-employment |


  Scenario: a newly defined relation subtype inherits playable roles from all of its supertypes
    Given typeql define
      """
      define
      transport-employment sub employment, relates transport-worker as employee;
      aviation-employment sub transport-employment, relates aviation-worker as transport-worker;
      flight-attendant-employment sub aviation-employment, relates flight-attendant as aviation-worker;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match $x plays income:source;
      """
    Then uniquely identify answer concepts
      | x                                 |
      | label:employment                  |
      | label:transport-employment        |
      | label:aviation-employment         |
      | label:flight-attendant-employment |


  Scenario: inherited role types cannot be played via role type aliases
    Given typeql define; throws exception
      """
      define
      part-time-employment sub employment;
      person plays part-time-employment:employee;
      """


  Scenario: a newly defined relation subtype inherits attribute ownerships from its parent type
    Given typeql define
      """
      define contract-employment sub employment, relates contractor as employee;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match $x owns start-date;
      """
    Then uniquely identify answer concepts
      | x                         |
      | label:employment          |
      | label:contract-employment |


  Scenario: a newly defined relation subtype inherits attribute ownerships from all of its supertypes
    Given typeql define
      """
      define
      transport-employment sub employment, relates transport-worker as employee;
      aviation-employment sub transport-employment, relates aviation-worker as transport-worker;
      flight-attendant-employment sub aviation-employment, relates flight-attendant as aviation-worker;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match $x owns start-date;
      """
    Then uniquely identify answer concepts
      | x                                 |
      | label:employment                  |
      | label:transport-employment        |
      | label:aviation-employment         |
      | label:flight-attendant-employment |


  Scenario: a newly defined relation subtype inherits keys from its parent type
    Given typeql define
      """
      define contract-employment sub employment, relates contractor as employee;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match $x owns employment-reference-code @key;
      """
    Then uniquely identify answer concepts
      | x                         |
      | label:employment          |
      | label:contract-employment |


  Scenario: a newly defined relation subtype inherits keys from all of its supertypes
    Given typeql define
      """
      define
      transport-employment sub employment, relates transport-worker as employee;
      aviation-employment sub transport-employment, relates aviation-worker as transport-worker;
      flight-attendant-employment sub aviation-employment, relates flight-attendant as aviation-worker;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match $x owns employment-reference-code @key;
      """
    Then uniquely identify answer concepts
      | x                                 |
      | label:employment                  |
      | label:transport-employment        |
      | label:aviation-employment         |
      | label:flight-attendant-employment |


  Scenario: a relation type can be defined with no roleplayers when it is marked as abstract
    When typeql define
      """
      define connection sub relation, abstract;
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql match
      """
      match $x type connection;
      """
    Then uniquely identify answer concepts
      | x                |
      | label:connection |


  Scenario: when defining a relation type, duplicate 'relates' are idempotent
    Given typeql define
      """
      define
      parenthood sub relation, relates parent, relates child, relates child, relates parent, relates child;
      person plays parenthood:parent, plays parenthood:child;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match $x relates parent; $x relates child;
      """
    Then uniquely identify answer concepts
      | x                |
      | label:parenthood |


  Scenario: unrelated relations are allowed to have roles with the same name
    When typeql define
      """
      define
      ownership sub relation, relates owner;
      loan sub relation, relates owner;
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql match
      """
      match $x relates owner;
      """
    Then uniquely identify answer concepts
      | x               |
      | label:ownership |
      | label:loan      |


  ###################
  # ATTRIBUTE TYPES #
  ###################

  Scenario Outline: a '<value_type>' attribute type can be defined
    Given typeql define
      """
      define <label> sub attribute, value <value_type>;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql match
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
    Then typeql define; throws exception
      """
      define colour sub attribute;
      """


  Scenario: defining an attribute type throws if the specified value type is not a recognised value type
    Then typeql define; throws exception
      """
      define colour sub attribute, value rgba;
      """


  Scenario: a new attribute type can be defined as a subtype of an abstract attribute type
    When typeql define
      """
      define
      code sub attribute, value string, abstract;
      door-code sub code;
      """
    Then transaction commits

    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match $x sub code;
      """
    Then uniquely identify answer concepts
      | x               |
      | label:code      |
      | label:door-code |


  Scenario: a newly defined attribute subtype inherits the value type of its parent
    When typeql define
      """
      define
      code sub attribute, value string, abstract;
      door-code sub code;
      """
    Then transaction commits

    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match $x type door-code, value string;
      """
    Then uniquely identify answer concepts
      | x               |
      | label:door-code |


  Scenario: defining an attribute subtype throws if it is given a different value type to what its parent has
    Then typeql define; throws exception
      """
      define code-name sub name, value long;
      """



  # TODO: re-enable when fixed (currently gives wrong answer)
  @ignore
  Scenario: a regex constraint can be defined on a 'string' attribute type
    Given typeql define
      """
      define response sub attribute, value string, regex "^(yes|no|maybe)$";
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match $x regex "^(yes|no|maybe)$";
      """
    Then uniquely identify answer concepts
      | x              |
      | label:resource |


  Scenario: a regex constraint cannot be defined on an attribute type whose value type is anything other than 'string'
    Then typeql define; throws exception
      """
      define name-in-binary sub attribute, value long, regex "^(0|1)+$";
      """


  Scenario: a newly defined attribute subtype inherits playable roles from its parent type
    Given typeql define
      """
      define
      car sub entity, plays car-sales-listing:listed-car;
      car-sales-listing sub relation, relates listed-car, relates available-colour;
      colour sub attribute, value string, plays car-sales-listing:available-colour, abstract;
      grayscale-colour sub colour;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match $x plays car-sales-listing:available-colour;
      """
    Then uniquely identify answer concepts
      | x                      |
      | label:colour           |
      | label:grayscale-colour |


  Scenario: a newly defined attribute subtype inherits playable roles from all of its supertypes
    Given typeql define
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

    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match $x plays phone-contact:number;
      """
    Then uniquely identify answer concepts
      | x                                |
      | label:phone-number               |
      | label:uk-phone-number            |
      | label:uk-landline-number         |
      | label:uk-premium-landline-number |


  Scenario: a newly defined attribute subtype inherits attribute ownerships from its parent type
    Given typeql define
      """
      define
      brightness sub attribute, value double;
      colour sub attribute, value string, owns brightness, abstract;
      grayscale-colour sub colour;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match $x owns brightness;
      """
    Then uniquely identify answer concepts
      | x                      |
      | label:colour           |
      | label:grayscale-colour |


  Scenario: a newly defined attribute subtype inherits attribute ownerships from all of its supertypes
    Given typeql define
      """
      define
      country-calling-code sub attribute, value string;
      phone-number sub attribute, value string, owns country-calling-code, abstract;
      uk-phone-number sub phone-number, abstract;
      uk-landline-number sub uk-phone-number, abstract;
      uk-premium-landline-number sub uk-landline-number;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match $x owns country-calling-code;
      """
    Then uniquely identify answer concepts
      | x                                |
      | label:phone-number               |
      | label:uk-phone-number            |
      | label:uk-landline-number         |
      | label:uk-premium-landline-number |


  Scenario: a newly defined attribute subtype inherits keys from its parent type
    Given typeql define
      """
      define
      hex-value sub attribute, value string;
      colour sub attribute, value string, owns hex-value @key, abstract;
      grayscale-colour sub colour;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match $x owns hex-value @key;
      """
    Then uniquely identify answer concepts
      | x                      |
      | label:colour           |
      | label:grayscale-colour |


  Scenario: a newly defined attribute subtype inherits keys from all of its supertypes
    Given typeql define
      """
      define
      hex-value sub attribute, value string;
      colour sub attribute, value string, owns hex-value @key, abstract;
      dark-colour sub colour, abstract;
      dark-red-colour sub dark-colour, abstract;
      very-dark-red-colour sub dark-red-colour;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match $x owns hex-value @key;
      """
    Then uniquely identify answer concepts
      | x                          |
      | label:colour               |
      | label:dark-colour          |
      | label:dark-red-colour      |
      | label:very-dark-red-colour |


  Scenario Outline: a type can own a '<value_type>' attribute type
    When typeql define
      """
      define
      <label> sub attribute, value <value_type>;
      person owns <label>;
      """
    Then transaction commits

    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match $x owns <label>;
      """
    Then uniquely identify answer concepts
      | x            |
      | label:person |

    Examples:
      | value_type | label             |
      | boolean    | is-sleeping       |
      | long       | number-of-fingers |
      | double     | height            |
      | string     | first-word        |
      | datetime   | graduation-date   |


  # TODO
#  Scenario Outline: a type can own a '<value_type>' attribute type as a key
#
#  Scenario Outline: a '<value_type>' attribute type is not allowed to be a key


  ##################
  # ABSTRACT TYPES #
  ##################

  Scenario: an abstract entity type can be defined
    When typeql define
      """
      define animal sub entity, abstract;
      """
    Then transaction commits

    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match $x type animal; $x abstract;
      """
    Then uniquely identify answer concepts
      | x            |
      | label:animal |


  Scenario: a concrete entity type can be defined as a subtype of an abstract entity type
    When typeql define
      """
      define
      animal sub entity, abstract;
      horse sub animal;
      """
    Then transaction commits

    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match $x sub animal;
      """
    Then uniquely identify answer concepts
      | x            |
      | label:animal |
      | label:horse  |


  Scenario: an abstract entity type can be defined as a subtype of another abstract entity type
    When typeql define
      """
      define
      animal sub entity, abstract;
      fish sub animal, abstract;
      """
    Then transaction commits

    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match $x sub animal; $x abstract;
      """
    Then uniquely identify answer concepts
      | x            |
      | label:animal |
      | label:fish   |


  Scenario: an abstract entity type can be defined as a subtype of a concrete entity type
    When typeql define
      """
      define
      exception sub entity;
      typedb-exception sub exception, abstract;
      """
    Then transaction commits

    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match $x sub exception, abstract;
      """
    Then uniquely identify answer concepts
      | x                      |
      | label:typedb-exception |


  Scenario: an abstract relation type can be defined
    When typeql define
      """
      define membership sub relation, abstract, relates member;
      """
    Then transaction commits

    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match $x type membership; $x abstract;
      """
    Then uniquely identify answer concepts
      | x                |
      | label:membership |


  Scenario: a concrete relation type can be defined as a subtype of an abstract relation type
    When typeql define
      """
      define
      membership sub relation, abstract, relates member;
      gym-membership sub membership, relates gym-with-members, relates gym-member as member;
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql match
      """
      match $x sub membership;
      """
    Then uniquely identify answer concepts
      | x                    |
      | label:membership     |
      | label:gym-membership |


  Scenario: an abstract relation type can be defined as a subtype of another abstract relation type
    When typeql define
      """
      define
      requirement sub relation, abstract, relates prerequisite, relates outcome;
      tool-requirement sub requirement, abstract, relates required-tool as prerequisite;
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql match
      """
      match $x sub requirement; $x abstract;
      """
    Then uniquely identify answer concepts
      | x                      |
      | label:requirement      |
      | label:tool-requirement |


  Scenario: an abstract relation type can be defined as a subtype of a concrete relation type
    When typeql define
      """
      define
      requirement sub relation, relates prerequisite, relates outcome;
      tech-requirement sub requirement, abstract, relates required-tech as prerequisite;
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql match
      """
      match $x sub requirement; $x abstract;
      """
    Then uniquely identify answer concepts
      | x                      |
      | label:tech-requirement |


  Scenario: an abstract attribute type can be defined
    When typeql define
      """
      define number-of-limbs sub attribute, abstract, value long;
      """
    Then transaction commits

    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match $x type number-of-limbs; $x abstract;
      """
    Then uniquely identify answer concepts
      | x                     |
      | label:number-of-limbs |


  Scenario: a concrete attribute type can be defined as a subtype of an abstract attribute type
    When typeql define
      """
      define
      number-of-limbs sub attribute, abstract, value long;
      number-of-legs sub number-of-limbs;
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql match
      """
      match $x sub number-of-limbs;
      """
    Then uniquely identify answer concepts
      | x                     |
      | label:number-of-limbs |
      | label:number-of-legs  |


  Scenario: an abstract attribute type can be defined as a subtype of another abstract attribute type
    When typeql define
      """
      define
      number-of-limbs sub attribute, abstract, value long;
      number-of-artificial-limbs sub number-of-limbs, abstract;
      """
    Then transaction commits

    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match $x sub number-of-limbs; $x abstract;
      """
    Then uniquely identify answer concepts
      | x                                |
      | label:number-of-limbs            |
      | label:number-of-artificial-limbs |


  Scenario: defining attribute type hierarchies is idempotent
    When typeql define
      """
      define super-name sub attribute, abstract, value string; location-name sub super-name;
      """
    Then transaction commits
    Then session opens transaction of type: write
    Then typeql define
      """
      define super-name sub attribute, abstract, value string; location-name sub super-name;
      """
    Then transaction commits
    Then session opens transaction of type: read
    When get answers of typeql match
      """
      match
      $name type super-name, abstract;
      $location type location-name, sub super-name;
      """
    Then uniquely identify answer concepts
      | name             | location            |
      | label:super-name | label:location-name |

  # TODO: Reenable this scenario after closing https://github.com/vaticle/typeql/issues/281
  @ignore-typedb-driver-rust
  Scenario: repeating the term 'abstract' when defining a type causes an error to be thrown
    Given typeql define; throws exception
      """
      define animal sub entity, abstract, abstract, abstract;
      """

  ##############
  # Annotation #
  ##############

  Scenario: annotations can be added on subtypes
    Given typeql define
      """
      define
      child sub person, owns school-id @unique;
      school-id sub attribute, value string;
      """
    Then transaction commits


  Scenario: annotations are inherited
    Given typeql define
      """
      define child sub person;
      """
    Given transaction commits
    Then session opens transaction of type: read
    When get answers of typeql match
      """
      match $t owns $a @key;
      """
    Then uniquely identify answer concepts
      | t                | a                               |
      | label:person     | label:email                     |
      | label:child      | label:email                     |
      | label:employment | label:employment-reference-code |
    When get answers of typeql match
      """
      match $t owns $a @unique;
      """
    Then uniquely identify answer concepts
      | t             | a               |
      | label:person  | label:phone-nr  |
      | label:child   | label:phone-nr  |


  Scenario: redefining inherited annotations throws
    Then typeql define; throws exception
      """
      define child sub person, owns email @key;
      """
    Then session opens transaction of type: write
    Then typeql define; throws exception
      """
      define child sub person, owns phone-nr @unique;
      """


  Scenario: annotations are inherited through overrides
    Given typeql define
      """
      define
      person abstract;
      phone-nr abstract;
      child sub person, owns mobile as phone-nr;
      mobile sub phone-nr;
      """
    Given transaction commits
    Then session opens transaction of type: write
    When get answers of typeql match
      """
      match $t owns $a @unique;
      """
    Then uniquely identify answer concepts
      | t             | a               |
      | label:person  | label:phone-nr  |
      | label:child   | label:mobile    |
    Given typeql define
      """
      define
      child abstract;
      mobile abstract;
      infant sub child, owns baby-phone-nr as mobile;
      baby-phone-nr sub mobile;
      """
    Given transaction commits
    Then session opens transaction of type: read
    When get answers of typeql match
      """
      match $t owns $a @unique;
      """
    Then uniquely identify answer concepts
      | t             | a                   |
      | label:person  | label:phone-nr      |
      | label:child   | label:mobile        |
      | label:infant  | label:baby-phone-nr |


  Scenario: redefining inherited annotations on overrides throws
    Given typeql define
      """
      define
      person abstract;
      phone-nr abstract;
      child sub person, owns mobile as phone-nr;
      mobile sub phone-nr;
      """
    Then transaction commits
    Given session opens transaction of type: write
    Then typeql define; throws exception
      """
      define child owns mobile as phone-nr @unique;
      """


  Scenario: defining a less strict annotation on an inherited ownership throws
    Then typeql define; throws exception
      """
      define child, owns email @unique;
      """


  ###################
  # SCHEMA MUTATION #
  ###################

  Scenario: an existing type can be repeatedly redefined, and it is a no-op
    When typeql define
      """
      define
      person sub entity, owns name;
      person sub entity, owns name;
      person sub entity, owns name;
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql match
      """
      match $x type person, owns name;
      """
    Then answer size is: 1


  Scenario: an entity type cannot be changed into a relation type
    Then typeql define; throws exception
      """
      define
      person sub relation, relates body-part;
      arm sub entity, plays person:body-part;
      """


  Scenario: a relation type cannot be changed into an attribute type
    Then typeql define; throws exception
      """
      define employment sub attribute, value string;
      """


  Scenario: an attribute type cannot be changed into an entity type
    Then typeql define; throws exception
      """
      define name sub entity;
      """


  Scenario: a new attribute ownership can be defined on an existing type
    When typeql define
      """
      define employment owns name;
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql match
      """
      match $x owns name;
      """
    Then uniquely identify answer concepts
      | x                |
      | label:person     |
      | label:employment |


  Scenario: a new playable role can be defined on an existing type
    When typeql define
      """
      define employment plays employment:employee;
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql match
      """
      match $x plays employment:employee;
      """
    Then uniquely identify answer concepts
      | x                |
      | label:person     |
      | label:employment |


  Scenario: defining a key on an existing ownership is possible if data already conforms to key requirements
    Given typeql define
      """
      define
      barcode sub attribute, value string;
      product sub entity, owns name, owns barcode;
      """
    Given transaction commits

    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $x isa product, has name "Cheese", has barcode "10001";
      $y isa product, has name "Ham", has barcode "10011";
      $a "Milk" isa name;
      $b "11111" isa barcode;
      """
    Given transaction commits

    Given connection close all sessions
    Given connection open schema session for database: typedb
    Given session opens transaction of type: write
    When typeql define
      """
      define
      product owns barcode @key;
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql match
      """
      match $x owns barcode @key;
      """
    Then uniquely identify answer concepts
      | x             |
      | label:product |


  Scenario: defining a key on a type throws if existing instances don't have that key
    Given typeql define
      """
      define
      barcode sub attribute, value string;
      product sub entity, owns name;
      """
    Given transaction commits

    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $x isa product, has name "Cheese";
      $y isa product, has name "Ham";
      """
    Given transaction commits

    Given connection close all sessions
    Given connection open schema session for database: typedb
    Given session opens transaction of type: write
    Then typeql define; throws exception
      """
      define
      product owns barcode @key;
      """


  Scenario: defining a key on a type throws if there is a key collision between two existing instances
    Given typeql define
      """
      define
      barcode sub attribute, value string;
      product sub entity, owns name, owns barcode;
      """
    Given transaction commits

    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $x isa product, has name "Cheese", has barcode "10000";
      $y isa product, has name "Ham", has barcode "10000";
      """
    Given transaction commits

    Given connection close all sessions
    Given connection open schema session for database: typedb
    Given session opens transaction of type: write
    Then typeql define; throws exception
      """
      define
      product owns barcode @key;
      """


  Scenario: a new role can be defined on an existing relation type
    When typeql define
      """
      define
      company sub entity, plays employment:employer;
      employment relates employer;
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql match
      """
      match $x relates employer;
      """
    Then uniquely identify answer concepts
      | x                |
      | label:employment |


  Scenario: Redefining an attribute type succeeds if and only if the value type remains unchanged
    Then typeql define; throws exception
      """
      define name sub attribute, value long;
      """

    When session opens transaction of type: write
    When typeql define
      """
      define name sub attribute, value string;
      """
    Then transaction commits


  Scenario: a regex constraint can be added to an existing attribute type if all its instances satisfy it
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $x isa person, has name "Alice", has email "alice@vaticle.com";
      """
    Given transaction commits

    Given connection close all sessions
    Given connection open schema session for database: typedb
    Given session opens transaction of type: write
    When typeql define
      """
      define name regex "^A.*$";
      """
    Then transaction commits

    Then session opens transaction of type: read
    Then get answers of typeql match
      """
      match $x regex "^A.*$";
      """
    Then uniquely identify answer concepts
      | x          |
      | label:name |


  Scenario: a regex cannot be added to an existing attribute type if there is an instance that doesn't satisfy it
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $x isa person, has name "Maria", has email "maria@vaticle.com";
      """
    Given transaction commits

    Given connection close all sessions
    Given connection open schema session for database: typedb
    Given session opens transaction of type: write
    Then typeql define; throws exception
      """
      define name regex "^A.*$";
      """


  Scenario: a regex constraint can not be added to an existing attribute type whose value type isn't 'string'
    Given typeql define
      """
      define house-number sub attribute, value long;
      """
    Given transaction commits

    Given session opens transaction of type: write
    Then typeql define; throws exception
      """
      define house-number regex "^A.*$";
      """


  Scenario: related roles cannot be added to existing entity types
    Then typeql define; throws exception
      """
      define person relates employee;
      """


  Scenario: related roles cannot be added to existing attribute types
    Then typeql define; throws exception
      """
      define name relates employee;
      """


  Scenario: the value type of an existing attribute type is not modifiable
    Then typeql define; throws exception
      """
      define name value long;
      """

    When session opens transaction of type: write
    Then typeql define; throws exception
      """
      define name sub attribute, value long;
      """

  Scenario: an attribute ownership can be converted to a key ownership
    When typeql define
      """
      define person owns name @key;
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql match
      """
      match $x owns name @key;
      """
    Then uniquely identify answer concepts
      | x            |
      | label:person |


  Scenario: an attribute key ownership can be converted to a regular ownership
    When typeql define
      """
      define person owns email;
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql match
      """
      match $x owns email;
      """
    Then uniquely identify answer concepts
      | x            |
      | label:person |
    When get answers of typeql match
      """
      match $x owns email @key;
      """
    Then answer size is: 0


  Scenario: defining a uniqueness on existing ownership is possible if data conforms to uniqueness requirements
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    When typeql insert
      """
      insert $x isa person, has name "Bob", has email "bob@gmail.com";
      """
    Then typeql insert
      """
      insert $x isa person, has name "Jane", has name "Doe", has email "janedoe@gmail.com";
      """
    Given transaction commits
    Given connection close all sessions
    Given connection open schema session for database: typedb
    Given session opens transaction of type: write
    Given typeql define
      """
      define person owns name @unique;
      """
    Then transaction commits
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert; throws exception
      """
      insert $x isa person, has name "Bob", has email "bob2@gmail.com";
      """


  Scenario: defining a uniqueness on existing ownership fail if data does not conform to uniqueness requirements
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    When typeql insert
      """
      insert $x isa person, has name "Bob", has email "bob@gmail.com";
      """
    Then typeql insert
      """
      insert $x isa person, has name "Bob", has email "bob2@gmail.com";
      """
    Given transaction commits
    Given connection close all sessions
    Given connection open schema session for database: typedb
    Given session opens transaction of type: write
    Given typeql define; throws exception
      """
      define person owns name @unique;
      """


  Scenario: a key ownership can be converted to a unique ownership
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $x isa person, has email "jane@gmail.com";
      $y isa person, has email "john@gmail.com";
      """
    Given transaction commits
    Given connection close all sessions
    Given connection open schema session for database: typedb
    Given session opens transaction of type: write
    Given typeql define
      """
      define person owns email @unique;
      """
    Then transaction commits
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    When get answers of typeql match
      """
      match $x owns $y @unique;
      """
    Then uniquely identify answer concepts
      | x            | y              |
      | label:person | label:email    |
      | label:person | label:phone-nr |
    When get answers of typeql match
      """
      match person owns $y @key;
      """
    Then answer size is: 0
    Given typeql insert; throws exception
      """
      insert $x isa person, has email "jane@gmail.com";
      """


  Scenario: ownership uniqueness can be removed
    Given typeql define
      """
      define person owns phone-nr;
      """
    Given transaction commits
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $x isa person, has phone-nr "123", has email "abc@gmail.com";
      $y isa person, has phone-nr "456", has email "xyz@gmail.com";
      """
    Given transaction commits


  Scenario: converting unique to key is possible if the data conforms to key requirements
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $x isa person, has phone-nr "123", has email "abc@gmail.com";
      $y isa person, has phone-nr "456", has email "xyz@gmail.com";
      """
    Given transaction commits
    Given connection close all sessions
    Given connection open schema session for database: typedb
    Given session opens transaction of type: write
    Given typeql define
      """
      define
      person owns phone-nr @key;
      """
    Then transaction commits
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Then typeql insert; throws exception
      """
      insert $x isa person, has phone-nr "9999", has phone-nr "8888", has email "pqr@gmail.com";
      """


  Scenario: converting unique to key fails if the data does not conform to key requirements
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert $x isa person, has phone-nr "123", has phone-nr "456", has email "abc@gmail.com";
      """
    Given transaction commits
    Given connection close all sessions
    Given connection open schema session for database: typedb
    Given session opens transaction of type: write
    Then typeql define; throws exception
      """
      define
      person owns phone-nr @key;
      """


  Scenario: defining a rule is idempotent
    Given typeql define
      """
      define
      nickname sub attribute, value string;
      person owns nickname;
      rule robert-has-nickname-bob:
      when {
        $p isa person, has name "Robert";
      } then {
        $p has nickname "Bob";
      };
      """
    Then typeql define
      """
      define
      rule robert-has-nickname-bob:
      when {
        $p isa person, has name "Robert";
      } then {
        $p has nickname "Bob";
      };
      """


  Scenario: redefining a rule and querying updates its definition
    Given typeql define
      """
      define
      nickname sub attribute, value string;
      person owns nickname;
      rule people-bob:
      when {
        $p isa person;
      } then {
        $p has nickname "Bob";
      };
      """
    Then transaction commits
    When session opens transaction of type: write
    Given typeql define
      """
      define
      nickname sub attribute, value string;
      person owns nickname;
      rule people-bob:
      when {
        $p has email "bob@gmail.com";
      } then {
        $p has name "Bob";
      };
      """
    Then transaction commits
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert $x isa person, has email "bob@gmail.com";
      """
    Then transaction commits
    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match $x has name $a;
      """
    Then answer size is: 1


  #############################
  # SCHEMA MUTATION: ABSTRACT #
  #############################

  Scenario: a concrete entity type can be converted to an abstract entity type
    When typeql define
      """
      define person abstract;
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql match
      """
      match $x sub person; $x abstract;
      """
    Then uniquely identify answer concepts
      | x            |
      | label:person |


  Scenario: a concrete relation type can be converted to an abstract relation type
    When typeql define
      """
      define friendship sub relation, relates friend;
      """
    Then transaction commits
    When session opens transaction of type: write
    When typeql define
      """
      define friendship abstract;
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql match
      """
      match $x sub friendship, abstract;
      """
    Then uniquely identify answer concepts
      | x                |
      | label:friendship |


  Scenario: a concrete attribute type can be converted to an abstract attribute type
    When typeql define
      """
      define age sub attribute, value long;
      """
    Then transaction commits
    Given session opens transaction of type: write
    When typeql define
      """
      define age abstract;
      """
    Then transaction commits
    When session opens transaction of type: read
    When get answers of typeql match
      """
      match $x sub age, abstract;
      """
    Then uniquely identify answer concepts
      | x         |
      | label:age |


  Scenario: an existing entity type cannot be converted to abstract if it has existing instances
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $x isa person, has name "Jeremy", has email "jeremy@vaticle.com";
      """
    Given transaction commits

    Given connection close all sessions
    Given connection open schema session for database: typedb
    Given session opens transaction of type: write
    Then typeql define; throws exception
      """
      define person abstract;
      """


  Scenario: an existing relation type cannot be converted to abstract if it has existing instances
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $x isa person, has name "Jeremy", has email "jeremy@vaticle.com";
      $r (employee: $x) isa employment, has employment-reference-code "J123123";
      """
    Given transaction commits

    Given connection close all sessions
    Given connection open schema session for database: typedb
    Given session opens transaction of type: write
    Then typeql define; throws exception
      """
      define employment abstract;
      """


  Scenario: an existing attribute type cannot be converted to abstract if it has existing instances
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $x isa person, has name "Jeremy", has email "jeremy@vaticle.com";
      """
    Given transaction commits

    Given connection close all sessions
    Given connection open schema session for database: typedb
    Given session opens transaction of type: write
    Then typeql define; throws exception
      """
      define name abstract;
      """


  Scenario: changing a concrete type to abstract throws on commit if it has a concrete supertype

  @ignore
  # TODO: re-enable when rules are indexed
  Scenario: changing a concrete relation type to abstract throws on commit if it appears in the conclusion of any rule

  @ignore
  # TODO: re-enable when rules are indexed
  Scenario: changing a concrete attribute type to abstract throws on commit if it appears in the conclusion of any rule

  ######################
  # HIERARCHY MUTATION #
  ######################

  Scenario: an existing entity type can be switched to a new supertype
    Given typeql define
      """
      define
      apple-product sub entity;
      genius sub person;
      """
    Given transaction commits

    Given session opens transaction of type: write
    When typeql define
      """
      define
      genius sub apple-product;
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql match
      """
      match $x sub apple-product;
      """
    Then uniquely identify answer concepts
      | x                   |
      | label:apple-product |
      | label:genius        |


  Scenario: an existing relation type can be switched to a new supertype


  Scenario: an existing attribute type can be switched to a new supertype with a matching value type
    Given typeql define
      """
      define
      measure sub attribute, value double, abstract;
      shoe-size sub measure;
      shoe sub entity, owns shoe-size;
      """
    Given transaction commits

    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert $s isa shoe, has shoe-size 9;
      """
    Given transaction commits

    Given connection close all sessions
    Given connection open schema session for database: typedb
    Given session opens transaction of type: write
    When typeql define
      """
      define
      size sub attribute, value double, abstract;
      shoe-size sub size;
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql match
      """
      match $x sub shoe-size;
      """
    Then uniquely identify answer concepts
      | x               |
      | label:shoe-size |


  Scenario: assigning a new supertype succeeds even if they have different attributes + roles, if there are no instances
    Given typeql define
      """
      define
      species sub entity, owns name, plays species-membership:species;
      species-membership sub relation, relates species, relates member;
      lifespan sub attribute, value double;
      organism sub entity, owns lifespan, plays species-membership:member;
      child sub person;
      """
    Given transaction commits

    Given session opens transaction of type: write
    When typeql define
      """
      define
      person sub organism;
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql match
      """
      match $x sub organism;
      """
    Then uniquely identify answer concepts
      | x              |
      | label:organism |
      | label:person   |
      | label:child    |


  Scenario: assigning a new supertype succeeds even with existing data if the supertypes have no properties
    Given typeql define
      """
      define
      bird sub entity;
      pigeon sub bird;
      """
    Given transaction commits

    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert $p isa pigeon;
      """
    Given transaction commits

    Given connection close all sessions
    Given connection open schema session for database: typedb
    Given session opens transaction of type: write
    When typeql define
      """
      define
      animal sub entity;
      pigeon sub animal;
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql match
      """
      match $x sub pigeon;
      """
    Then uniquely identify answer concepts
      | x            |
      | label:pigeon |


  Scenario: assigning a new supertype succeeds with existing data if the supertypes play the same roles
    Given typeql define
      """
      define
      bird sub entity, plays flying:flier;
      pigeon sub bird;
      flying sub relation, relates flier;
      """
    Given transaction commits

    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert $p isa pigeon;
      """
    Given transaction commits

    Given connection close all sessions
    Given connection open schema session for database: typedb
    Given session opens transaction of type: write
    When typeql define
      """
      define
      animal sub entity, plays flying:flier;
      pigeon sub animal;
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql match
      """
      match $x sub pigeon;
      """
    Then uniquely identify answer concepts
      | x            |
      | label:pigeon |


  Scenario: assigning a new supertype succeeds with existing data if the supertypes have the same attributes
    Given typeql define
      """
      define
      name sub attribute, value string;
      bird sub entity, owns name;
      pigeon sub bird;
      """
    Given transaction commits

    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert $p isa pigeon;
      """
    Given transaction commits

    Given connection close all sessions
    Given connection open schema session for database: typedb
    Given session opens transaction of type: write
    When typeql define
      """
      define
      animal sub entity, owns name;
      pigeon sub animal;
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql match
      """
      match $x sub pigeon;
      """
    Then uniquely identify answer concepts
      | x            |
      | label:pigeon |


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
    Given typeql define
      """
      define
      employment sub relation, relates employer;
      child sub person;
      person sub entity, plays employment:employer;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match $x type child, plays $r;
      """
    Then uniquely identify answer concepts
      | x           | r                         |
      | label:child | label:employment:employee |
      | label:child | label:employment:employer |
      | label:child | label:income:earner       |


  Scenario: when adding an attribute ownership to an existing type, the change is propagated to its subtypes
    Given typeql define
    """
       define
       person sub entity, owns mobile;
       mobile sub attribute, value long;
       child sub person;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match $x type child, owns $y;
      """
    Then uniquely identify answer concepts
      | x           | y                  |
      | label:child | label:name         |
      | label:child | label:mobile       |
      | label:child | label:email        |
      | label:child | label:phone-nr     |


  Scenario: when adding a key ownership to an existing type, the change is propagated to its subtypes
    Given typeql define
      """
      define
      child sub person;
      phone-number sub attribute, value long;
      person sub entity, owns phone-number @key;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match $x type child, owns $y @key;
      """
    Then uniquely identify answer concepts
      | x           | y                  |
      | label:child | label:email        |
      | label:child | label:phone-number |


  Scenario: when adding a related role to an existing relation type, the change is propagated to all its subtypes
    Given typeql define
      """
      define
      part-time-employment sub employment;
      employment sub relation, relates employer;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match $x type part-time-employment, relates $r;
      """
    Then uniquely identify answer concepts
      | x                          | r                         |
      | label:part-time-employment | label:employment:employee |
      | label:part-time-employment | label:employment:employer |


  ####################
  # TRANSACTIONALITY #
  ####################

  # TODO: re-enable when it passes reliably in drivers (see driver-java#233)
  @ignore-typedb-driver-java
  @ignore-typedb-driver-nodejs
  @ignore-typedb-driver-python
  Scenario: uncommitted transaction writes are not persisted
    When typeql define
      """
      define dog sub entity;
      """
    When session opens transaction of type: read
    Then typeql match; throws exception
      """
      match $x type dog;
      """



  ########################
  # CYCLIC SCHEMA GRAPHS #
  ########################

  Scenario: a type cannot be a subtype of itself
    Then typeql define; throws exception
      """
      define dog sub dog;
      """


  Scenario: a cyclic type hierarchy is not allowed
    Then typeql define; throws exception
      """
      define
      giant sub person;
      green-giant sub giant;
      person sub green-giant;
      """


  Scenario: two attribute types can own each other in a cycle
    Given typeql define
      """
      define
      nickname sub attribute, value string, owns surname, owns middlename;
      surname sub attribute, value string, owns nickname;
      middlename sub attribute, value string, owns firstname;
      firstname sub attribute, value string, owns surname;
      """
    Then get answers of typeql match
      """
      match $a sub attribute, owns $b; $b sub attribute, owns $a;
      """
    Then uniquely identify answer concepts
      | a              | b              |
      | label:nickname | label:surname  |
      | label:surname  | label:nickname |
    Then get answers of typeql match
      """
      match $a owns $b; $b owns $a;
      """
    Then uniquely identify answer concepts
      | a              | b              |
      | label:nickname | label:surname  |
      | label:surname  | label:nickname |

  Scenario: many attribute types can own each other in a big cycle
    Given typeql define
      """
      define
      nickname sub attribute, value string, owns surname, owns middlename;
      surname sub attribute, value string, owns nickname;
      middlename sub attribute, value string, owns firstname;
      firstname sub attribute, value string, owns surname;
      """
    Then get answers of typeql match
      """
      match
      $a sub attribute, owns $b;
      $b sub attribute, owns $c;
      $c sub attribute, owns $d;
      $d sub attribute, owns $a;
      """
    Then uniquely identify answer concepts
      | a                | b                | c                | d                |
      | label:middlename | label:firstname  | label:surname    | label:nickname   |
      | label:firstname  | label:surname    | label:nickname   | label:middlename |
      | label:surname    | label:nickname   | label:middlename | label:firstname  |
      | label:surname    | label:nickname   | label:surname    | label:nickname   |
      | label:nickname   | label:middlename | label:firstname  | label:surname    |
      | label:nickname   | label:surname    | label:nickname   | label:surname    |

  Scenario: a relation type can relate to a role that it plays itself
    When typeql define
      """
      define
      recursive-function sub relation, relates function, plays recursive-function:function;
      """
    Then transaction commits

    Given session opens transaction of type: read
    When get answers of typeql match
      """
      match $x relates function; $x plays recursive-function:function;
      """
    Then uniquely identify answer concepts
      | x                        |
      | label:recursive-function |


  Scenario: an attribute type can own itself
    When typeql define
      """
      define number-of-letters sub attribute, value long, owns number-of-letters;
      """
    Then transaction commits

    When session opens transaction of type: read
    When get answers of typeql match
      """
      match $x owns number-of-letters;
      """
    Then uniquely identify answer concepts
      | x                       |
      | label:number-of-letters |


  Scenario: two relation types in a type hierarchy can play each other's roles
    When typeql define
      """
      define
      apple sub relation, abstract, relates role1, plays big-apple:role2;
      big-apple sub apple, plays apple:role1, relates role2;
      """


  Scenario: relation types that play roles in their transitive subtypes can be reliably defined

  Variables from a 'define' query are selected for defining in an arbitrary order. When these variables
  depend on each other, creating a dependency graph, they should all define successfully regardless of
  which variable was picked as the start vertex (#131)

    When typeql define
      """
      define

      apple sub relation, abstract, plays huge-apple:grows-from;
      big-apple sub apple, abstract;
      huge-apple sub big-apple, relates tree, relates grows-from;

      banana sub relation, abstract, plays huge-banana:grows-from;
      big-banana sub banana, abstract;
      huge-banana sub big-banana, relates tree, relates grows-from;

      orange sub relation, abstract, plays huge-orange:grows-from;
      big-orange sub orange, abstract;
      huge-orange sub big-orange, relates tree, relates grows-from;

      pear sub relation, abstract, plays huge-pear:grows-from;
      big-pear sub pear, abstract;
      huge-pear sub big-pear, relates tree, relates grows-from;

      tomato sub relation, abstract, plays huge-tomato:grows-from;
      big-tomato sub tomato, abstract;
      huge-tomato sub big-tomato, relates tree, relates grows-from;

      watermelon sub relation, abstract, plays huge-watermelon:grows-from;
      big-watermelon sub watermelon, abstract;
      huge-watermelon sub big-watermelon, relates tree, relates grows-from;

      lemon sub relation, abstract, plays huge-lemon:grows-from;
      big-lemon sub lemon, abstract;
      huge-lemon sub big-lemon, relates tree, relates grows-from;

      lime sub relation, abstract, plays huge-lime:grows-from;
      big-lime sub lime, abstract;
      huge-lime sub big-lime, relates tree, relates grows-from;

      mango sub relation, abstract, plays huge-mango:grows-from;
      big-mango sub mango, abstract;
      huge-mango sub big-mango, relates tree, relates grows-from;

      pineapple sub relation, abstract, plays huge-pineapple:grows-from;
      big-pineapple sub pineapple, abstract;
      huge-pineapple sub big-pineapple, relates tree, relates grows-from;
      """
    Then transaction commits
