# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: TypeQL Define Query

  Background: Open connection and create a simple extensible schema
    Given typedb starts
    Given connection opens with default authentication
    Given connection has been opened
    Given connection reset database: typedb
#    Given connection does not have any database
#    Given connection create database: typedb
    Given connection open schema transaction for database: typedb

    Given typeql define
      """
      define
      entity person plays employment:employee, plays income:earner, owns name, owns email @key, owns phone-nr @unique;
      relation employment relates employee, plays income:source, owns start-date, owns employment-reference-code @key;
      relation income relates earner, relates source;

      attribute name value string;
      attribute email value string;
      attribute start-date value datetime;
      attribute employment-reference-code value string;
      attribute phone-nr value string;
      """
    Given transaction commits

    Given connection open schema transaction for database: typedb


  ################
  # ENTITY TYPES #
  ################

  Scenario: new entity types can be defined
    When typeql define
      """
      define entity dog;
      """
    Then transaction commits

    When connection open schema transaction for database: typedb
    When get answers of typeql get
      """
      match $x type dog; get;
      """
    Then uniquely identify answer concepts
      | x         |
      | label:dog |


  Scenario: a new entity type can be defined as a subtype, creating a new child of its parent type
    When typeql define
      """
      define entity child sub person;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x sub person; get;
      """
    Then uniquely identify answer concepts
      | x            |
      | label:person |
      | label:child  |


  Scenario: when defining that a type owns a non-existent thing, an error is thrown
    Then typeql define; fails
      """
      define entity book owns pages;
      """


  Scenario: types cannot own entity types
    Then typeql define; fails
      """
      define entity house owns person;
      """


  Scenario: types cannot own relation types
    Then typeql define; fails
      """
      define entity company owns employment;
      """


  Scenario: when defining that a type plays a non-existent role, an error is thrown
    Then typeql define; fails
      """
      define entity house plays constructed:something;
      """


  Scenario: types cannot play entity types
    Then typeql define; fails
      """
      define entity parrot plays person;
      """


  Scenario: types can not own entity types as keys
    Then typeql define; fails
      """
      define entity passport owns person @key;
      """


  Scenario: a newly defined entity subtype inherits playable roles from its parent type
    Given typeql define
      """
      define entity child sub person;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x plays employment:employee; get;
      """
    Then uniquely identify answer concepts
      | x            |
      | label:person |
      | label:child  |


  Scenario: a newly defined entity subtype inherits playable roles from all of its supertypes
    Given typeql define
      """
      define
      entity athlete sub person;
      entity runner sub athlete;
      entity sprinter sub runner;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x plays employment:employee; get;
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
      define entity child sub person;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x owns name; get;
      """
    Then uniquely identify answer concepts
      | x            |
      | label:person |
      | label:child  |


  Scenario: a newly defined entity subtype inherits attribute ownerships from all of its supertypes
    Given typeql define
      """
      define
      entity athlete sub person;
      entity runner sub athlete;
      entity sprinter sub runner;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x owns name; get;
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
      define entity child sub person;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x owns email @key; get;
      """
    Then uniquely identify answer concepts
      | x            |
      | label:person |
      | label:child  |


  Scenario: a newly defined entity subtype inherits keys from all of its supertypes
    Given typeql define
      """
      define
      entity athlete sub person;
      entity runner sub athlete;
      entity sprinter sub runner;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x owns email @key; get;
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
      entity house plays home-ownership:home, plays home-ownership:home, plays home-ownership:home;
      relation home-ownership relates home, relates owner;
      person plays home-ownership:owner;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x plays home-ownership:home; get;
      """
    Then uniquely identify answer concepts
      | x           |
      | label:house |


  Scenario: defining an attribute ownership is idempotent
    Given typeql define
      """
      define
      attribute price value double;
      entity house owns price, owns price, owns price;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x owns price; get;
      """
    Then uniquely identify answer concepts
      | x           |
      | label:house |


  Scenario: defining a key ownership is idempotent
    Given typeql define
      """
      define
      attribute address value string;
      entity house owns address @key, owns address @key, owns address @key;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x owns address @key; get;
      """
    Then uniquely identify answer concepts
      | x           |
      | label:house |


  Scenario: defining a type without a kind throws
    Then typeql define; fails
      """
      define flying-spaghetti-monster;
      """


  Scenario: a type definition must specify a kind
    Then typeql define; fails
      """
      define column;
      """


  Scenario: an entity type can not have a value type defined
    Then typeql define; fails
      """
      define entity cream value double;
      """


  Scenario: defining a thing with 'isa' is not possible in a 'define' query
    Then typeql define; fails
      """
      define $p isa person;
      """


  Scenario: adding an attribute instance to a thing is not possible in a 'define' query
    Then typeql define; fails
      """
      define $p has name "Loch Ness Monster";
      """


  Scenario: writing a variable in a 'define' is not allowed
    Then typeql define; fails
      """
      define entity $x;
      """



  ##################
  # RELATION TYPES #
  ##################

  Scenario: new relation types can be defined
    When typeql define
      """
      define relation pet-ownership relates pet-owner, relates owned-pet;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x type pet-ownership; get;
      """
    Then uniquely identify answer concepts
      | x                   |
      | label:pet-ownership |


  Scenario: a new relation type can be defined as a subtype, creating a new child of its parent type
    When typeql define
      """
      define relation fun-employment sub employment, relates employee-having-fun as employee;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x sub employment; get;
      """
    Then uniquely identify answer concepts
      | x                    |
      | label:employment     |
      | label:fun-employment |


  Scenario: defining a relation type throws on commit if it has no roleplayers and is not abstract
    Then typeql define
      """
      define relation useless-relation;
      """
    Then transaction commits; fails


  Scenario: a newly defined relation subtype inherits roles from its supertype
    Given typeql define
      """
      define relation part-time-employment sub employment;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x relates employee; get;
      """
    Then uniquely identify answer concepts
      | x                          |
      | label:employment           |
      | label:part-time-employment |

  # TODO: Why does this have no body?
  Scenario: a newly defined relation subtype inherits roles from all of its supertypes


  Scenario: a relation type's role can be overridden in a child relation type using 'as'
    When typeql define
      """
      define
        relation parenthood relates parent, relates child;
        relation father-sonhood sub parenthood, relates father as parent, relates son as child;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match
        $x relates parent;
        $x relates child;
      get;
      """
    Then uniquely identify answer concepts
      | x                |
      | label:parenthood |
    When get answers of typeql get
      """
      match
        $x relates father;
        $x relates son;
      get;
      """
    Then uniquely identify answer concepts
      | x                    |
      | label:father-sonhood |


  Scenario: when a relation type's role is overridden, it creates a sub-role of the parent role type
    When typeql define
      """
      define
      relation parenthood relates parent, relates child;
      relation father-sonhood sub parenthood, relates father as parent, relates son as child;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql get
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
      define relation part-time-employment sub employment, relates part-timer as employee;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x relates employee; get;
      """
    Then uniquely identify answer concepts
      | x                |
      | label:employment |


  Scenario: when overriding a role that doesn't exist on the parent relation, an error is thrown
    Then typeql define; fails
      """
      define
      relation close-friendship relates close-friend as friend;
      """


  Scenario: relation subtypes can have roles that their supertypes don't have
    Given typeql define
      """
      define
      entity plane plays pilot-employment:preferred-plane;
      relation pilot-employment sub employment, relates pilot as employee, relates preferred-plane;
      person plays pilot-employment:pilot;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x relates preferred-plane; get;
      """
    Then uniquely identify answer concepts
      | x                      |
      | label:pilot-employment |


  Scenario: types should be able to define roles they play with an override
    Then typeql define
      """
        define
        relation locates relates located;
        relation contractor-locates sub locates, relates contractor-located as located;

        relation employment relates employee, plays locates:located;
        relation contractor-employment sub employment, plays contractor-locates:contractor-located as located;
      """


  Scenario: already shadowed types should not be overrideable
    Then typeql define; fails
      """
        define
        relation locates relates located;
        relation contractor-locates sub locates, relates contractor-located as located;
        relation software-contractor-locates sub contractor-locates, relates software-contractor-located as contractor-located;

        employment relates employee, plays locates:located;
        relation contractor-employment sub employment, plays contractor-locates:contractor-located as located;
        relation software-contractor-employment sub contractor-employment, plays software-contractor-locates:software-contractor-located as located;
      """


  Scenario: a newly defined relation subtype inherits playable roles from its parent type
    Given typeql define
      """
      define relation contract-employment sub employment, relates contractor as employee;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x plays income:source; get;
      """
    Then uniquely identify answer concepts
      | x                         |
      | label:employment          |
      | label:contract-employment |


  Scenario: a newly defined relation subtype inherits playable roles from all of its supertypes
    Given typeql define
      """
      define
      relation transport-employment sub employment, relates transport-worker as employee;
      relation aviation-employment sub transport-employment, relates aviation-worker as transport-worker;
      relation flight-attendant-employment sub aviation-employment, relates flight-attendant as aviation-worker;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x plays income:source; get;
      """
    Then uniquely identify answer concepts
      | x                                 |
      | label:employment                  |
      | label:transport-employment        |
      | label:aviation-employment         |
      | label:flight-attendant-employment |


  Scenario: inherited role types cannot be played via role type aliases
    Given typeql define; fails
      """
      define
      relation part-time-employment sub employment;
      person plays part-time-employment:employee;
      """


  Scenario: a newly defined relation subtype inherits attribute ownerships from its parent type
    Given typeql define
      """
      define relation contract-employment sub employment, relates contractor as employee;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x owns start-date; get;
      """
    Then uniquely identify answer concepts
      | x                         |
      | label:employment          |
      | label:contract-employment |


  Scenario: a newly defined relation subtype inherits attribute ownerships from all of its supertypes
    Given typeql define
      """
      define
      relation transport-employment sub employment, relates transport-worker as employee;
      relation aviation-employment sub transport-employment, relates aviation-worker as transport-worker;
      relation flight-attendant-employment sub aviation-employment, relates flight-attendant as aviation-worker;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x owns start-date; get;
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
      define relation contract-employment sub employment, relates contractor as employee;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x owns employment-reference-code @key; get;
      """
    Then uniquely identify answer concepts
      | x                         |
      | label:employment          |
      | label:contract-employment |


  Scenario: a newly defined relation subtype inherits keys from all of its supertypes
    Given typeql define
      """
      define
      relation transport-employment sub employment, relates transport-worker as employee;
      relation aviation-employment sub transport-employment, relates aviation-worker as transport-worker;
      relation flight-attendant-employment sub aviation-employment, relates flight-attendant as aviation-worker;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x owns employment-reference-code @key; get;
      """
    Then uniquely identify answer concepts
      | x                                 |
      | label:employment                  |
      | label:transport-employment        |
      | label:aviation-employment         |
      | label:flight-attendant-employment |


  Scenario: a relation type can be defined with no roleplayers when it is marked as @abstract
    When typeql define
      """
      define relation connection @abstract;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x type connection; get;
      """
    Then uniquely identify answer concepts
      | x                |
      | label:connection |


  Scenario: when defining a relation type, duplicate 'relates' are idempotent
    Given typeql define
      """
      define
      relation parenthood relates parent, relates child, relates child, relates parent, relates child;
      person plays parenthood:parent, plays parenthood:child;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x relates parent; $x relates child; get;
      """
    Then uniquely identify answer concepts
      | x                |
      | label:parenthood |


  Scenario: unrelated relations are allowed to have roles with the same name
    When typeql define
      """
      define
      relation ownership relates owner;
      relation loan relates owner;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x relates owner; get;
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
      define attribute <label> value <value_type>;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match
        $x type <label>;
        $x sub attribute;
      get;
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
    Then typeql define; fails
      """
      define colour sub attribute;
      """


  Scenario: defining an attribute type throws if the specified value type is not a recognised value type
    Then typeql define; fails
      """
      define attribute colour value rgba;
      """


  Scenario: a new attribute type can be defined as a subtype of an abstract attribute type
    When typeql define
      """
      define
      attribute code @abstract, value string ;
      attribute door-code sub code;
      """
    Then transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x sub code; get;
      """
    Then uniquely identify answer concepts
      | x               |
      | label:code      |
      | label:door-code |


  Scenario: a newly defined attribute subtype inherits the value type of its parent
    When typeql define
      """
      define
      attribute code @abstract, value string;
      attribute door-code sub code;
      """
    Then transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x type door-code, value string; get;
      """
    Then uniquely identify answer concepts
      | x               |
      | label:door-code |


  Scenario: defining an attribute subtype throws if it is given a different value type to what its parent has
    Then typeql define; fails
      """
      define attribute code-name sub name, value long;
      """



  # TODO: re-enable when fixed (currently gives wrong answer)
  @ignore
  Scenario: a regex constraint can be defined on a 'string' attribute type
    Given typeql define
      """
      define attribute response value string, @regex("^(yes|no|maybe)$");
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x @regex("^(yes|no|maybe)$"); get;
      """
    Then uniquely identify answer concepts
      | x              |
      | label:resource |


  Scenario: a regex constraint cannot be defined on an attribute type whose value type is anything other than 'string'
    Then typeql define; fails
      """
      define attribute name-in-binary value long, @regex("^(0|1)+$");
      """


  Scenario Outline: a type can own a '<value_type>' attribute type
    When typeql define
      """
      define
      attribute <label> value <value_type>;
      person owns <label>;
      """
    Then transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x owns <label>; get;
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
      define entity animal @abstract;
      """
    Then transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x type animal; $x @abstract; get;
      """
    Then uniquely identify answer concepts
      | x            |
      | label:animal |


  Scenario: a concrete entity type can be defined as a subtype of an abstract entity type
    When typeql define
      """
      define
      entity animal @abstract;
      entity horse sub animal;
      """
    Then transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x sub animal; get;
      """
    Then uniquely identify answer concepts
      | x            |
      | label:animal |
      | label:horse  |


  Scenario: an abstract entity type can be defined as a subtype of another abstract entity type
    When typeql define
      """
      define
      entity animal @abstract;
      entity fish sub animal @abstract;
      """
    Then transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x sub animal; $x @abstract; get;
      """
    Then uniquely identify answer concepts
      | x            |
      | label:animal |
      | label:fish   |


  Scenario: an abstract entity type can be defined as a subtype of a concrete entity type
    When typeql define
      """
      define
      entity exception;
      entity typedb-exception sub exception @abstract;
      """
    Then transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x sub exception @abstract; get;
      """
    Then uniquely identify answer concepts
      | x                      |
      | label:typedb-exception |


  Scenario: an abstract relation type can be defined
    When typeql define
      """
      define relation membership @abstract, relates member;
      """
    Then transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x type membership; $x @abstract; get;
      """
    Then uniquely identify answer concepts
      | x                |
      | label:membership |


  Scenario: a concrete relation type can be defined as a subtype of an abstract relation type
    When typeql define
      """
      define
      relation membership @abstract, relates member;
      relation gym-membership sub membership, relates gym-with-members, relates gym-member as member;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x sub membership; get;
      """
    Then uniquely identify answer concepts
      | x                    |
      | label:membership     |
      | label:gym-membership |


  Scenario: an abstract relation type can be defined as a subtype of another abstract relation type
    When typeql define
      """
      define
      relation requirement @abstract, relates prerequisite, relates outcome;
      relation tool-requirement sub requirement @abstract, relates required-tool as prerequisite;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x sub requirement; $x @abstract; get;
      """
    Then uniquely identify answer concepts
      | x                      |
      | label:requirement      |
      | label:tool-requirement |


  Scenario: an abstract relation type can be defined as a subtype of a concrete relation type
    When typeql define
      """
      define
      relation requirement relates prerequisite, relates outcome;
      relation tech-requirement sub requirement @abstract, relates required-tech as prerequisite;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x sub requirement; $x @abstract; get;
      """
    Then uniquely identify answer concepts
      | x                      |
      | label:tech-requirement |


  Scenario: an abstract attribute type can be defined
    When typeql define
      """
      define attribute number-of-limbs @abstract, value long;
      """
    Then transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x type number-of-limbs; $x @abstract; get;
      """
    Then uniquely identify answer concepts
      | x                     |
      | label:number-of-limbs |


  Scenario: a concrete attribute type can be defined as a subtype of an abstract attribute type
    When typeql define
      """
      define
      attribute number-of-limbs @abstract, value long;
      attribute number-of-legs sub number-of-limbs;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x sub number-of-limbs; get;
      """
    Then uniquely identify answer concepts
      | x                     |
      | label:number-of-limbs |
      | label:number-of-legs  |


  Scenario: an abstract attribute type can be defined as a subtype of another abstract attribute type
    When typeql define
      """
      define
      attribute number-of-limbs @abstract, value long;
      attribute number-of-artificial-limbs sub number-of-limbs @abstract;
      """
    Then transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x sub number-of-limbs; $x @abstract; get;
      """
    Then uniquely identify answer concepts
      | x                                |
      | label:number-of-limbs            |
      | label:number-of-artificial-limbs |


  Scenario: defining attribute type hierarchies is idempotent
    When typeql define
      """
      define attribute super-name @abstract, value string; attribute location-name sub super-name;
      """
    Then transaction commits
    Then connection open schema transaction for database: typedb
    Then typeql define
      """
      define attribute super-name @abstract, value string; attribute location-name sub super-name;
      """
    Then transaction commits
    Then connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match
      $name type super-name @abstract;
      $location type location-name, sub super-name;
      get;
      """
    Then uniquely identify answer concepts
      | name             | location            |
      | label:super-name | label:location-name |

  # TODO: Reenable this scenario after closing https://github.com/vaticle/typeql/issues/281
  @ignore
  @ignore-typedb-driver-rust
  Scenario: repeating the term 'abstract' when defining a type causes an error to be thrown
    Given typeql define; fails
      """
      define entity animal @abstract @abstract @abstract;
      """

  ##############
  # Annotation #
  ##############

  Scenario: annotations can be added on subtypes
    Given typeql define
      """
      define
      entity child sub person, owns school-id @unique;
      attribute school-id value string;
      """
    Then transaction commits


  Scenario: annotations are inherited
    Given typeql define
      """
      define entity child sub person;
      """
    Given transaction commits
    Then connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $t owns $a @key; get;
      """
    Then uniquely identify answer concepts
      | t                | a                               |
      | label:person     | label:email                     |
      | label:child      | label:email                     |
      | label:employment | label:employment-reference-code |
    When get answers of typeql get
      """
      match $t owns $a @unique; get;
      """
    Then uniquely identify answer concepts
      | t             | a               |
      | label:person  | label:phone-nr  |
      | label:child   | label:phone-nr  |


  Scenario: redefining inherited annotations throws
    Then typeql define
      """
      define entity child sub person, owns email @key;
      """
    Then transaction commits; fails
    Then connection open schema transaction for database: typedb
    Then typeql define
      """
      define entity child sub person, owns phone-nr @unique;
      """
    Then transaction commits; fails


  Scenario: annotations are inherited through overrides
    Given typeql define
      """
      define
      entity person @abstract;
      attribute phone-nr @abstract;
      entity child sub person, owns mobile as phone-nr;
      attribute mobile sub phone-nr;
      """
    Given transaction commits
    Then connection open schema transaction for database: typedb
    When get answers of typeql get
      """
      match $t owns $a @unique; get;
      """
    Then uniquely identify answer concepts
      | t             | a               |
      | label:person  | label:phone-nr  |
      | label:child   | label:mobile    |
    Given typeql define
      """
      define
      entity child @abstract;
      attribute mobile @abstract;
      entity infant sub child, owns baby-phone-nr as mobile;
      attribute baby-phone-nr sub mobile;
      """
    Given transaction commits
    Then connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $t owns $a @unique; get;
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
      entity person @abstract;
      attribute phone-nr @abstract;
      entity child sub person, owns mobile as phone-nr;
      attribute mobile sub phone-nr;
      """
    Then transaction commits
    Given connection open schema transaction for database: typedb
    Then typeql define
      """
      define entity child owns mobile as phone-nr @unique;
      """
    Then transaction commits; fails


  Scenario: defining a less strict annotation on an inherited ownership throws
    Then typeql define; fails
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
      entity person owns name;
      entity person owns name;
      entity person owns name;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x type person, owns name; get;
      """
    Then answer size is: 1


  Scenario: an entity type cannot be changed into a relation type
    Then typeql define; fails
      """
      define
      relation person relates body-part;
      entity arm plays person:body-part;
      """


  Scenario: a relation type cannot be changed into an attribute type
    Then typeql define; fails
      """
      define attribute employment value string;
      """


  Scenario: an attribute type cannot be changed into an entity type
    Then typeql define; fails
      """
      define entity name;
      """


  Scenario: a new attribute ownership can be defined on an existing type
    When typeql define
      """
      define employment owns name;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x owns name; get;
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

    When connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x plays employment:employee; get;
      """
    Then uniquely identify answer concepts
      | x                |
      | label:person     |
      | label:employment |


  Scenario: defining a key on an existing ownership is possible if data already conforms to key requirements
    Given typeql define
      """
      define
      attribute barcode value string;
      entity product owns name, owns barcode;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql insert
      """
      insert
      $x isa product, has name "Cheese", has barcode "10001";
      $y isa product, has name "Ham", has barcode "10011";
      $a "Milk" isa name;
      $b "11111" isa barcode;
      """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    When typeql define
      """
      define
      product owns barcode @key;
      """
    Then transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x owns barcode @key; get;
      """
    Then uniquely identify answer concepts
      | x             |
      | label:product |


  Scenario: defining a key on a type throws if existing instances don't have that key
    Given typeql define
      """
      define
      attribute barcode value string;
      entity product owns name;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql insert
      """
      insert
      $x isa product, has name "Cheese";
      $y isa product, has name "Ham";
      """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    Then typeql define; fails
      """
      define
      product owns barcode @key;
      """


  Scenario: defining a key on a type throws if there is a key collision between two existing instances
    Given typeql define
      """
      define
      attribute barcode value string;
      entity product owns name, owns barcode;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql insert
      """
      insert
      $x isa product, has name "Cheese", has barcode "10000";
      $y isa product, has name "Ham", has barcode "10000";
      """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    Then typeql define; fails
      """
      define
      product owns barcode @key;
      """


  Scenario: a new role can be defined on an existing relation type
    When typeql define
      """
      define
      entity company plays employment:employer;
      employment relates employer;
      """
    Then transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x relates employer; get;
      """
    Then uniquely identify answer concepts
      | x                |
      | label:employment |
#

  Scenario: Redefining an attribute type succeeds if and only if the value type remains unchanged
    Then typeql define; fails
      """
      define attribute name value long;
      """
    Given transaction closes
    Given connection open schema transaction for database: typedb
    When typeql define
      """
      define attribute name value string;
      """
    Then transaction commits


  Scenario: a regex constraint can be added to an existing attribute type if all its instances satisfy it
    Given transaction closes
    Given connection open write transaction for database: typedb
    Given typeql insert
      """
      insert
      $x isa person, has name "Alice", has email "alice@vaticle.com";
      """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    When typeql define
      """
      define name value string @regex("^A.*$");
      """
    Then transaction commits

    Given connection open read transaction for database: typedb
    Then get answers of typeql get
      """
      match $x @regex("^A.*$"); get;
      """
    Then uniquely identify answer concepts
      | x          |
      | label:name |


  Scenario: a regex cannot be added to an existing attribute type if there is an instance that doesn't satisfy it
    Given transaction closes
    Given connection open write transaction for database: typedb
    Given typeql insert
      """
      insert
      $x isa person, has name "Maria", has email "maria@vaticle.com";
      """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    Then typeql define; fails
      """
      define name @regex("^A.*$");
      """


  Scenario: a regex constraint can not be added to an existing attribute type whose value type isn't 'string'
    Given typeql define
      """
      define attribute house-number value long;
      """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    Then typeql define; fails
      """
      define house-number @regex("^A.*$)";
      """


  Scenario: related roles cannot be added to existing entity types
    Then typeql define; fails
      """
      define person relates employee;
      """


  Scenario: related roles cannot be added to existing attribute types
    Then typeql define; fails
      """
      define name relates employee;
      """


  Scenario: the value type of an existing attribute type is not modifiable
    Then typeql define; fails
      """
      define name value long;
      """
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Then typeql define; fails
      """
      define attribute name value long;
      """

  Scenario: an attribute ownership can be converted to a key ownership
    When typeql define
      """
      define person owns name @key;
      """
    Then transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x owns name @key; get;
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

    Given connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x owns email; get;
      """
    Then uniquely identify answer concepts
      | x            |
      | label:person |
    When get answers of typeql get
      """
      match $x owns email @key; get;
      """
    Then answer size is: 0


  Scenario: defining a uniqueness on existing ownership is possible if data conforms to uniqueness requirements
    Given transaction closes
    Given connection open write transaction for database: typedb
    When typeql insert
      """
      insert $x isa person, has name "Bob", has email "bob@gmail.com";
      """
    Then typeql insert
      """
      insert $x isa person, has name "Jane", has name "Doe", has email "janedoe@gmail.com";
      """
    Given transaction commits
    Given connection open schema transaction for database: typedb
    Given typeql define
      """
      define person owns name @unique;
      """
    Then transaction commits
    Given connection open write transaction for database: typedb
    Given typeql insert; fails
      """
      insert $x isa person, has name "Bob", has email "bob2@gmail.com";
      """


  Scenario: defining a uniqueness on existing ownership fail if data does not conform to uniqueness requirements
    Given transaction closes
    Given connection open write transaction for database: typedb
    When typeql insert
      """
      insert $x isa person, has name "Bob", has email "bob@gmail.com";
      """
    Then typeql insert
      """
      insert $x isa person, has name "Bob", has email "bob2@gmail.com";
      """
    Given transaction commits
    Given connection open schema transaction for database: typedb
    Given typeql define; fails
      """
      define person owns name @unique;
      """


  Scenario: a key ownership can be converted to a unique ownership
    Given transaction closes
    Given connection open write transaction for database: typedb
    Given typeql insert
      """
      insert
      $x isa person, has email "jane@gmail.com";
      $y isa person, has email "john@gmail.com";
      """
    Given transaction commits
    Given connection open schema transaction for database: typedb
    Given typeql define
      """
      define person owns email @unique;
      """
    Then transaction commits
    Given connection open write transaction for database: typedb
    When get answers of typeql get
      """
      match $x owns $y @unique; get;
      """
    Then uniquely identify answer concepts
      | x            | y              |
      | label:person | label:email    |
      | label:person | label:phone-nr |
    When get answers of typeql get
      """
      match person owns $y @key; get;
      """
    Then answer size is: 0
    Given typeql insert; fails
      """
      insert $x isa person, has email "jane@gmail.com";
      """


  Scenario: ownership uniqueness can be removed
    Given typeql define
      """
      define person owns phone-nr;
      """
    Given transaction commits
    Given connection open write transaction for database: typedb
    Given typeql insert
      """
      insert
      $x isa person, has phone-nr "123", has email "abc@gmail.com";
      $y isa person, has phone-nr "456", has email "xyz@gmail.com";
      """
    Given transaction commits


  Scenario: converting unique to key is possible if the data conforms to key requirements
    Given transaction closes
    Given connection open write transaction for database: typedb
    Given typeql insert
      """
      insert
      $x isa person, has phone-nr "123", has email "abc@gmail.com";
      $y isa person, has phone-nr "456", has email "xyz@gmail.com";
      """
    Given transaction commits
    Given connection open schema transaction for database: typedb
    Given typeql define
      """
      define
      person owns phone-nr @key;
      """
    Then transaction commits
    Given connection open write transaction for database: typedb
    Then typeql insert; fails
      """
      insert $x isa person, has phone-nr "9999", has phone-nr "8888", has email "pqr@gmail.com";
      """


  Scenario: converting unique to key fails if the data does not conform to key requirements
    Given transaction closes
    Given connection open write transaction for database: typedb
    Given typeql insert
      """
      insert $x isa person, has phone-nr "123", has phone-nr "456", has email "abc@gmail.com";
      """
    Given transaction commits
    Given connection open schema transaction for database: typedb
    Then typeql define; fails
      """
      define
      person owns phone-nr @key;
      """


  #############################
  # SCHEMA MUTATION: ABSTRACT #
  #############################

  Scenario: a concrete entity type can be converted to an abstract entity type
    When typeql define
      """
      define person @abstract;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x sub person; $x @abstract; get;
      """
    Then uniquely identify answer concepts
      | x            |
      | label:person |


  Scenario: a concrete relation type can be converted to an abstract relation type
    When typeql define
      """
      define relation friendship relates friend;
      """
    Then transaction commits
    Given connection open schema transaction for database: typedb
    When typeql define
      """
      define friendship @abstract;
      """
    Then transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x sub friendship @abstract; get;
      """
    Then uniquely identify answer concepts
      | x                |
      | label:friendship |


  Scenario: a concrete attribute type can be converted to an abstract attribute type
    When typeql define
      """
      define attribute age value long;
      """
    Then transaction commits
    Given connection open schema transaction for database: typedb
    When typeql define
      """
      define age @abstract;
      """
    Then transaction commits
    Given connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x sub age @abstract; get;
      """
    Then uniquely identify answer concepts
      | x         |
      | label:age |


  Scenario: an existing entity type cannot be converted to abstract if it has existing instances
    Given transaction closes
    Given connection open write transaction for database: typedb
    Given typeql insert
      """
      insert
      $x isa person, has name "Jeremy", has email "jeremy@vaticle.com";
      """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    Then typeql define; fails
      """
      define person @abstract;
      """


  Scenario: an existing relation type cannot be converted to abstract if it has existing instances
    Given transaction closes
    Given connection open write transaction for database: typedb
    Given typeql insert
      """
      insert
      $x isa person, has name "Jeremy", has email "jeremy@vaticle.com";
      $r (employee: $x) isa employment, has employment-reference-code "J123123";
      """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    Then typeql define; fails
      """
      define employment @abstract;
      """


  Scenario: an existing attribute type cannot be converted to abstract if it has existing instances
    Given transaction closes
    Given connection open write transaction for database: typedb
    Given typeql insert
      """
      insert
      $x isa person, has name "Jeremy", has email "jeremy@vaticle.com";
      """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    Then typeql define; fails
      """
      define name @abstract;
      """


  Scenario: changing a concrete type to abstract throws on commit if it has a concrete supertype

  @ignore
  # TODO: re-enable when rules are indexed
  Scenario: changing a concrete relation type to abstract throws on commit if it appears in the conclusion of any rule

#  @ignore
#  # TODO: re-enable when rules are indexed
#  Scenario: changing a concrete attribute type to abstract throws on commit if it appears in the conclusion of any rule

  ######################
  # HIERARCHY MUTATION #
  ######################

  Scenario: an existing entity type can be switched to a new supertype
    Given typeql define
      """
      define
      entity apple-product;
      entity genius sub person;
      """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    When typeql define
      """
      define
      entity genius sub apple-product;
      """
    Then transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x sub apple-product; get;
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
      attribute measure value double @abstract;
      attribute shoe-size sub measure;
      entity shoe owns shoe-size;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql insert
      """
      insert $s isa shoe, has shoe-size 9;
      """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    When typeql define
      """
      define
      attribute size value double @abstract;
      attribute shoe-size sub size;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x sub shoe-size; get;
      """
    Then uniquely identify answer concepts
      | x               |
      | label:shoe-size |


  Scenario: assigning a new supertype succeeds even if they have different attributes + roles, if there are no instances
    Given typeql define
      """
      define
      entity species owns name, plays species-membership:species;
      relation species-membership relates species, relates member;
      attribute lifespan value double;
      entity organism owns lifespan, plays species-membership:member;
      entity child sub person;
      """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    When typeql define
      """
      define
      entity person sub organism;
      """
    Then transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x sub organism; get;
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
      entity bird;
      entity pigeon sub bird;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql insert
      """
      insert $p isa pigeon;
      """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    When typeql define
      """
      define
      entity animal;
      entity pigeon sub animal;
      """
    Then transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x sub pigeon; get;
      """
    Then uniquely identify answer concepts
      | x            |
      | label:pigeon |


  Scenario: assigning a new supertype succeeds with existing data if the supertypes play the same roles
    Given typeql define
      """
      define
      entity bird plays flying:flier;
      entity pigeon sub bird;
      relation flying relates flier;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql insert
      """
      insert $p isa pigeon;
      """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    When typeql define
      """
      define
      entity animal plays flying:flier;
      entity pigeon sub animal;
      """
    Then transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x sub pigeon; get;
      """
    Then uniquely identify answer concepts
      | x            |
      | label:pigeon |


  Scenario: assigning a new supertype succeeds with existing data if the supertypes have the same attributes
    Given typeql define
      """
      define
      attribute name value string;
      entity bird owns name;
      entity pigeon sub bird;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql insert
      """
      insert $p isa pigeon;
      """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    When typeql define
      """
      define
      entity animal owns name;
      entity pigeon sub animal;
      """
    Then transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x sub pigeon; get;
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
      relation employment relates employer;
      entity child sub person;
      entity person plays employment:employer;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x type child, plays $r; get;
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
       entity person owns mobile;
       attribute mobile value long;
       entity child sub person;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x type child, owns $y; get;
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
      entity child sub person;
      attribute phone-number value long;
      entity person owns phone-number @key;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x type child, owns $y @key; get;
      """
    Then uniquely identify answer concepts
      | x           | y                  |
      | label:child | label:email        |
      | label:child | label:phone-number |


  Scenario: when adding a related role to an existing relation type, the change is propagated to all its subtypes
    Given typeql define
      """
      define
      relation part-time-employment sub employment;
      relation employment relates employer;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x type part-time-employment, relates $r; get;
      """
    Then uniquely identify answer concepts
      | x                          | r                         |
      | label:part-time-employment | label:employment:employee |
      | label:part-time-employment | label:employment:employer |


  ####################
  # TRANSACTIONALITY #
  ####################

  Scenario: uncommitted transaction writes are not persisted
    When typeql define
      """
      define entity dog;
      """
    Given connection open read transaction for database: typedb
    Then typeql get; fails
      """
      match $x type dog; get;
      """



  ########################
  # CYCLIC SCHEMA GRAPHS #
  ########################

  Scenario: a type cannot be a subtype of itself
    Then typeql define; fails
      """
      define dog sub dog;
      """


  Scenario: a cyclic type hierarchy is not allowed
    Then typeql define; fails
      """
      define
      entity giant sub person;
      entity green-giant sub giant;
      entity person sub green-giant;
      """


  Scenario: a relation type can relate to a role that it plays itself
    When typeql define
      """
      define
      relation recursive-function relates function, plays recursive-function:function;
      """
    Then transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x relates function; $x plays recursive-function:function; get;
      """
    Then uniquely identify answer concepts
      | x                        |
      | label:recursive-function |


  Scenario: two relation types in a type hierarchy can play each other's roles
    When typeql define
      """
      define
      relation apple @abstract, relates role1, plays big-apple:role2;
      relation big-apple sub apple, plays apple:role1, relates role2;
      """


  Scenario: relation types that play roles in their transitive subtypes can be reliably defined

  Variables from a 'define' query are selected for defining in an arbitrary order. When these variables
  depend on each other, creating a dependency graph, they should all define successfully regardless of
  which variable was picked as the start vertex (#131)

    When typeql define
      """
      define

      relation apple @abstract, plays huge-apple:grows-from;
      relation big-apple @abstract, sub apple;
      relation huge-apple sub big-apple, relates tree, relates grows-from;

      relation banana @abstract, plays huge-banana:grows-from;
      relation big-banana @abstract, sub banana;
      relation huge-banana sub big-banana, relates tree, relates grows-from;

      relation orange @abstract, plays huge-orange:grows-from;
      relation big-orange @abstract, sub orange;
      relation huge-orange sub big-orange, relates tree, relates grows-from;

      relation pear @abstract, plays huge-pear:grows-from;
      relation big-pear @abstract, sub pear;
      relation huge-pear sub big-pear, relates tree, relates grows-from;

      relation tomato @abstract, plays huge-tomato:grows-from;
      relation big-tomato @abstract, sub tomato;
      relation huge-tomato sub big-tomato, relates tree, relates grows-from;

      relation watermelon @abstract, plays huge-watermelon:grows-from;
      relation big-watermelon @abstract, sub watermelon;
      relation huge-watermelon sub big-watermelon, relates tree, relates grows-from;

      relation lemon @abstract, plays huge-lemon:grows-from;
      relation big-lemon @abstract, sub lemon;
      relation huge-lemon sub big-lemon, relates tree, relates grows-from;

      relation lime @abstract, plays huge-lime:grows-from;
      relation big-lime @abstract, sub lime;
      relation huge-lime sub big-lime, relates tree, relates grows-from;

      relation mango @abstract, plays huge-mango:grows-from;
      relation big-mango @abstract, sub mango;
      relation huge-mango sub big-mango, relates tree, relates grows-from;

      relation pineapple @abstract, plays huge-pineapple:grows-from;
      relation big-pineapple @abstract, sub pineapple;
      relation huge-pineapple sub big-pineapple, relates tree, relates grows-from;
      """
    Then transaction commits
