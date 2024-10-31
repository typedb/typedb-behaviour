# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: TypeQL Define Query

  Background: Open connection and create a simple extensible schema
    Given typedb starts
    Given connection opens with default authentication
    Given connection is open: true
    Given connection reset database: typedb
    Given connection open schema transaction for database: typedb

    Given typeql schema query
      """
      define
      entity person plays employment:employee, plays income:earner, owns name, owns email @key, owns phone-nr @unique;
      relation employment relates employee, plays income:source, owns start-date, owns employment-reference-code @key;
      relation income relates earner, relates source;

      attribute name value string;
      attribute email value string @regex("^.*@.*$");
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
    When typeql schema query
      """
      define entity dog;
      """
    Then transaction commits

    When connection open schema transaction for database: typedb
    When get answers of typeql read query
      """
      match $x label dog;
      """
    Then uniquely identify answer concepts
      | x         |
      | label:dog |


  Scenario: a new entity type can be defined as a subtype, creating a new child of its parent type
    When typeql schema query
      """
      define entity child sub person;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x sub person;
      """
    Then uniquely identify answer concepts
      | x            |
      | label:person |
      | label:child  |


  Scenario: defining an entity type sub when a different sub is already defined errors
    Given typeql schema query
      """
      define
      person sub parent;
      entity parent @abstract;
      entity not-parent;
      """
    Given transaction commits

    When connection open schema transaction for database: typedb
    Then typeql schema query; fails with a message containing: "different 'person sub parent' is already defined"
      """
      define person sub not-parent;
      """


  Scenario: when defining that a type owns a non-existent attribute type, an error is thrown
    Then typeql schema query; fails
      """
      define entity book owns pages;
      """


  Scenario: types cannot own entity types
    Then typeql schema query; fails
      """
      define entity house owns person;
      """


  Scenario: types cannot own relation types
    Then typeql schema query; fails
      """
      define entity company owns employment;
      """


  Scenario: when defining that a type plays a non-existent role, an error is thrown
    Then typeql schema query; fails
      """
      define entity house plays constructed:something;
      """


  Scenario: types cannot play entity types
    Then typeql schema query; parsing fails
      """
      define entity parrot plays person;
      """


  Scenario: types can not own entity types as keys
    Then typeql schema query; fails
      """
      define entity passport owns person @key;
      """


  Scenario: a newly defined entity subtype inherits playable roles from its parent type
    Given typeql schema query
      """
      define entity child sub person;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x plays employment:employee;
      """
    Then uniquely identify answer concepts
      | x            |
      | label:person |
      | label:child  |


  Scenario: a newly defined entity subtype inherits playable roles from all of its supertypes
    Given typeql schema query
      """
      define
      entity athlete sub person;
      entity runner sub athlete;
      entity sprinter sub runner;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
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
    Given typeql schema query
      """
      define entity child sub person;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x owns name;
      """
    Then uniquely identify answer concepts
      | x            |
      | label:person |
      | label:child  |


  Scenario: a newly defined entity subtype inherits attribute ownerships from all of its supertypes
    Given typeql schema query
      """
      define
      entity athlete sub person;
      entity runner sub athlete;
      entity sprinter sub runner;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
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
    Given typeql schema query
      """
      define entity child sub person;
      """
    Given transaction commits

    # TODO: Uncomment when "match @..." is implemented
#    Given connection open read transaction for database: typedb
#    When get answers of typeql read query
#      """
#      match $x owns email @key;
#      """
#    Then uniquely identify answer concepts
#      | x            |
#      | label:person |
#      | label:child  |


  Scenario: a newly defined entity subtype inherits keys from all of its supertypes
    Given typeql schema query
      """
      define
      entity athlete sub person;
      entity runner sub athlete;
      entity sprinter sub runner;
      """
    Given transaction commits

    # TODO: Uncomment when "match @..." is implemented
#    Given connection open read transaction for database: typedb
#    When get answers of typeql read query
#      """
#      match $x owns email @key;
#      """
#    Then uniquely identify answer concepts
#      | x              |
#      | label:person   |
#      | label:athlete  |
#      | label:runner   |
#      | label:sprinter |


  Scenario: defining a playable role is idempotent
    Given typeql schema query
      """
      define
      entity house plays home-ownership:home, plays home-ownership:home, plays home-ownership:home;
      relation home-ownership relates home, relates owner;
      person plays home-ownership:owner;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x plays home-ownership:home;
      """
    Then uniquely identify answer concepts
      | x           |
      | label:house |


  Scenario: defining an attribute ownership is idempotent
    Given typeql schema query
      """
      define
      attribute price value double;
      entity house owns price, owns price, owns price;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x owns price;
      """
    Then uniquely identify answer concepts
      | x           |
      | label:house |


  Scenario: defining an ownership when a differently ordered ownership is already defined errors
    Given typeql schema query
      """
      define person owns start-date[];
      """
    Given transaction commits

    When connection open schema transaction for database: typedb
    Then typeql schema query; fails with a message containing: "different 'person owns name' is already defined"
      """
      define person owns name[];
      """
    When transaction closes

    When connection open schema transaction for database: typedb
    Then typeql schema query; fails with a message containing: "different 'person owns start-date[]' is already defined"
      """
      define person owns start-date;
      """


  Scenario: defining a key ownership is idempotent
    Given typeql schema query
      """
      define
      attribute address value string;
      entity house owns address @key, owns address @key, owns address @key;
      """
    Given transaction commits

    # TODO: Uncomment when "match @..." is implemented
#    Given connection open read transaction for database: typedb
#    When get answers of typeql read query
#      """
#      match $x owns address @key;
#      """
#    Then uniquely identify answer concepts
#      | x           |
#      | label:house |


  Scenario: defining a type without a kind throws
    Then typeql schema query; fails
      """
      define flying-spaghetti-monster;
      """


  Scenario: a type definition must specify a kind
    Then typeql schema query; fails
      """
      define column;
      """


  Scenario: an entity type can not have a value type defined
    Then typeql schema query; fails
      """
      define entity cream value double;
      """


  Scenario: defining a thing with 'isa' is not possible in a 'define' query
    Then typeql schema query; parsing fails
      """
      define $p isa person;
      """


  Scenario: adding an attribute instance to a thing is not possible in a 'define' query
    Then typeql schema query; parsing fails
      """
      define $p has name "Loch Ness Monster";
      """


  Scenario: writing a variable in a 'define' is not allowed
    Then typeql schema query; parsing fails
      """
      define entity $x;
      """

  ##################
  # RELATION TYPES #
  ##################

  Scenario: new relation types can be defined
    When typeql schema query
      """
      define relation pet-ownership relates pet-owner, relates owned-pet;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x label pet-ownership;
      """
    Then uniquely identify answer concepts
      | x                   |
      | label:pet-ownership |


  Scenario: a new relation type can be defined as a subtype, creating a new child of its parent type
    When typeql schema query
      """
      define relation fun-employment sub employment, relates employee-having-fun as employee;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x sub employment;
      """
    Then uniquely identify answer concepts
      | x                    |
      | label:employment     |
      | label:fun-employment |


  Scenario: defining a relation type sub when a different sub is already defined errors
    Given typeql schema query
      """
      define
      employment sub contract;
      relation contract @abstract, relates side @abstract;
      relation agreement, relates side;
      """
    Given transaction commits

    When connection open schema transaction for database: typedb
    Then typeql schema query; fails with a message containing: "different 'employment sub contract' is already defined"
      """
      define employment sub agreement;
      """


  Scenario: defining a relation type throws on commit if it has no roleplayers and is not abstract
    Then typeql schema query
      """
      define relation useless-relation;
      """
    Then transaction commits; fails


  Scenario: a newly defined relation subtype inherits roles from its supertype
    Given typeql schema query
      """
      define relation part-time-employment sub employment;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x relates employee;
      """
    Then uniquely identify answer concepts
      | x                          |
      | label:employment           |
      | label:part-time-employment |

  Scenario: a newly defined relation subtype inherits roles from all of its supertypes
    Given typeql schema query
      """
      define
      relation part-time-employment sub employment, relates shift;
      relation student-part-time-employment sub part-time-employment, relates student-document;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x relates employee;
      """
    Then uniquely identify answer concepts
      | x                                  |
      | label:employment                   |
      | label:part-time-employment         |
      | label:student-part-time-employment |
    When get answers of typeql read query
      """
      match $x relates shift;
      """
    Then uniquely identify answer concepts
      | x                                  |
      | label:part-time-employment         |
      | label:student-part-time-employment |
    When get answers of typeql read query
      """
      match $x relates student-document;
      """
    Then uniquely identify answer concepts
      | x                                  |
      | label:student-part-time-employment |


  Scenario: a relation type's role can be specialised in a child relation type using 'as'
    When typeql schema query
      """
      define
        relation parenthood relates parent, relates child;
        relation father-sonhood sub parenthood, relates father as parent, relates son as child;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
        $x relates parent;
        $x relates child;
      """
    Then uniquely identify answer concepts
      | x                    |
      | label:parenthood     |
      | label:father-sonhood |
    When get answers of typeql read query
      """
      match
        $x relates father;
        $x relates son;
      """
    Then uniquely identify answer concepts
      | x                    |
      | label:father-sonhood |


  Scenario: defining a relates when a differently ordered relates is already defined errors
    Given typeql schema query
      """
      define employment relates mentor[];
      """
    Given transaction commits

    When connection open schema transaction for database: typedb
    Then typeql schema query; fails with a message containing: "different 'employment relates employee' is already defined"
      """
      define employment relates employee[];
      """
    When transaction closes

    When connection open schema transaction for database: typedb
    Then typeql schema query; fails with a message containing: "different 'employment relates mentor[]' is already defined"
      """
      define employment relates mentor;
      """


  Scenario: defining a relates specialise when a differently relates specialise is already defined errors
    Given typeql schema query
      """
      define
      employment relates employer;
      relation part-time-employment sub employment, relates part-time-employee as employee;
      """
    Given transaction commits

    When connection open schema transaction for database: typedb
    Then typeql schema query; fails with a message containing: "different 'part-time-employment relates part-time-employee as employee' is already defined"
      """
      define part-time-employment relates part-time-employee as employer;
      """


  Scenario: when a relation type's role is specialised, it creates a sub-role of the parent role type
    When typeql schema query
      """
      define
      relation parenthood relates parent, relates child;
      relation father-sonhood sub parenthood, relates father as parent, relates son as child;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
      $x sub parenthood:parent; $y sub parenthood:child;
      """
    Then uniquely identify answer concepts
      | x                           | y                        |
      | label:parenthood:parent     | label:parenthood:child   |
      | label:father-sonhood:father | label:parenthood:child   |
      | label:parenthood:parent     | label:father-sonhood:son |
      | label:father-sonhood:father | label:father-sonhood:son |


  Scenario: a specialised role is still associated with the relation type that specialises it, but with @abstract
    Given typeql schema query
      """
      define relation part-time-employment sub employment, relates part-timer as employee;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x relates employee;
      """
    Then uniquely identify answer concepts
      | x                          |
      | label:employment           |
      | label:part-time-employment |

    # TODO: Uncomment when "match @..." is implemented
#    When get answers of typeql read query
#      """
#      match $x relates employee @abstract;
#      """
#    Then uniquely identify answer concepts
#      | x                          |
#      | label:part-time-employment |


  Scenario: when specialising a role that doesn't exist on the parent relation, an error is thrown
    Then typeql schema query; fails
      """
      define
      relation close-friendship relates close-friend as friend;
      """


  Scenario: relation subtypes can have roles that their supertypes don't have
    Given typeql schema query
      """
      define
      entity plane plays pilot-employment:preferred-plane;
      relation pilot-employment sub employment, relates pilot as employee, relates preferred-plane;
      person plays pilot-employment:pilot;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x relates preferred-plane;
      """
    Then uniquely identify answer concepts
      | x                      |
      | label:pilot-employment |


  Scenario Outline: types cannot specialise plays in any <mode>
    Then typeql schema query; parsing fails
      """
        define
        relation locates relates located;
        relation contractor-locates sub locates, relates contractor-located as located;

        relation employment relates employee, plays locates:located;
        relation contractor-employment sub employment, plays contractor-locates:contractor-located as <as-label>;
      """
    Examples:
      | mode              | as-label        |
      | role name         | located         |
      | role scoped label | locates:located |


  Scenario: a newly defined relation subtype inherits playable roles from its parent type
    Given typeql schema query
      """
      define relation contract-employment sub employment, relates contractor as employee;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x plays income:source;
      """
    Then uniquely identify answer concepts
      | x                         |
      | label:employment          |
      | label:contract-employment |


  Scenario: a newly defined relation subtype inherits playable roles from all of its supertypes
    Given typeql schema query
      """
      define
      relation transport-employment sub employment, relates transport-worker as employee;
      relation aviation-employment sub transport-employment, relates aviation-worker as transport-worker;
      relation flight-attendant-employment sub aviation-employment, relates flight-attendant as aviation-worker;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
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
    Given typeql schema query; fails
      """
      define
      relation part-time-employment sub employment;
      person plays part-time-employment:employee;
      """


  Scenario: a newly defined relation subtype inherits attribute ownerships from its parent type
    Given typeql schema query
      """
      define relation contract-employment sub employment, relates contractor as employee;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x owns start-date;
      """
    Then uniquely identify answer concepts
      | x                         |
      | label:employment          |
      | label:contract-employment |


  Scenario: a newly defined relation subtype inherits attribute ownerships from all of its supertypes
    Given typeql schema query
      """
      define
      relation transport-employment sub employment, relates transport-worker as employee;
      relation aviation-employment sub transport-employment, relates aviation-worker as transport-worker;
      relation flight-attendant-employment sub aviation-employment, relates flight-attendant as aviation-worker;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
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
    Given typeql schema query
      """
      define relation contract-employment sub employment, relates contractor as employee;
      """
    Given transaction commits

    # TODO: Uncomment when "match @..." is implemented
#    Given connection open read transaction for database: typedb
#    When get answers of typeql read query
#      """
#      match $x owns employment-reference-code @key;
#      """
#    Then uniquely identify answer concepts
#      | x                         |
#      | label:employment          |
#      | label:contract-employment |


  Scenario: a newly defined relation subtype inherits keys from all of its supertypes
    Given typeql schema query
      """
      define
      relation transport-employment sub employment, relates transport-worker as employee;
      relation aviation-employment sub transport-employment, relates aviation-worker as transport-worker;
      relation flight-attendant-employment sub aviation-employment, relates flight-attendant as aviation-worker;
      """
    Given transaction commits

    # TODO: Uncomment when "match @..." is implemented
#    Given connection open read transaction for database: typedb
#    When get answers of typeql read query
#      """
#      match $x owns employment-reference-code @key;
#      """
#    Then uniquely identify answer concepts
#      | x                                 |
#      | label:employment                  |
#      | label:transport-employment        |
#      | label:aviation-employment         |
#      | label:flight-attendant-employment |


  Scenario: a relation type cannot be defined with no roleplayers even if it is marked as @abstract
    When typeql schema query
      """
      define relation connection @abstract;
      """
    Then transaction commits; fails


  Scenario: an abstract relation type can be defined with both abstract and concrete role types
    When typeql schema query
      """
      define relation connection @abstract, relates from, relates to @abstract;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x label connection;
      """
    Then uniquely identify answer concepts
      | x                |
      | label:connection |


  Scenario: a concrete relation type can be defined with abstract role types
    When typeql schema query
      """
      define relation connection relates from, relates to @abstract;
      """
    Then transaction commits


  Scenario: when defining a relation type, duplicate 'relates' are idempotent
    Given typeql schema query
      """
      define
      relation parenthood relates parent, relates child, relates child, relates parent, relates child;
      person plays parenthood:parent, plays parenthood:child;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x relates parent; $x relates child;
      """
    Then uniquely identify answer concepts
      | x                |
      | label:parenthood |


  Scenario: unrelated relations are allowed to have roles with the same name
    When typeql schema query
      """
      define
      relation ownership relates owner;
      relation loan relates owner;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x relates owner;
      """
    Then uniquely identify answer concepts
      | x               |
      | label:loan      |
      | label:ownership |

  ###################
  # ATTRIBUTE TYPES #
  ###################

  Scenario Outline: a '<value-type>' attribute type can be defined
    Given typeql schema query
      """
      define attribute <label> value <value-type>;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
        $x label <label>;
        attribute $x;

      """
    Then answer size is: 1

    Examples:
      | value-type  | label              |
      | long        | number-of-cows     |
      | string      | favourite-food     |
      | boolean     | can-fly            |
      | double      | density            |
      | decimal     | savings            |
      | date        | flight-date        |
      | datetime    | flight-time        |
      | datetime-tz | flight-time-tz     |
      | duration    | procedure-duration |


  Scenario: defining an attribute type throws if you don't specify a value type
    When typeql schema query
      """
      define attribute colour;
      """
    Then transaction commits; fails


  Scenario: defining an abstract attribute type does not throw if you don't specify a value type
    When typeql schema query
      """
      define attribute colour @abstract;
      """
    Then transaction commits


  Scenario: defining an attribute type throws if the specified value type is not a recognised value type
    Then typeql schema query; fails
      """
      define attribute colour value rgba;
      """


  Scenario: a new attribute type can be defined as a subtype of an abstract attribute type
    When typeql schema query
      """
      define
      attribute code @abstract, value string;
      attribute door-code sub code;
      """
    Then transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x sub code;
      """
    Then uniquely identify answer concepts
      | x               |
      | label:code      |
      | label:door-code |


  Scenario: defining an attribute type sub when a different sub is already defined errors
    Given typeql schema query
      """
      define
      name sub root-attribute;
      attribute root-attribute @abstract;
      attribute empty-attribute @abstract;
      """
    Given transaction commits

    When connection open schema transaction for database: typedb
    Then typeql schema query; fails with a message containing: "different 'name sub root-attribute' is already defined"
      """
      define name sub empty-attribute;
      """


  Scenario: a newly defined attribute subtype inherits the value type of its parent
    When typeql schema query
      """
      define
      attribute code @abstract, value string;
      attribute door-code sub code;
      """
    Then transaction commits

    # TODO: ConstraintBase::ValueType is not implemented
#    Given connection open read transaction for database: typedb
#    When get answers of typeql read query
#      """
#      match $x label door-code, value string;
#      """
#    Then uniquely identify answer concepts
#      | x               |
#      | label:door-code |


  Scenario: defining an attribute subtype throws if it is given a different value type to what its parent has
    When typeql schema query
      """
      define attribute name @abstract; entity person @abstract;
      """
    When transaction commits

    When connection open schema transaction for database: typedb
    Then typeql schema query; fails
      """
      define attribute code-name sub name, value long;
      """
    When transaction closes

    When connection open schema transaction for database: typedb
    When typeql schema query
      """
      define attribute code-name sub name; attribute code-name-2 value long;
      """
    When transaction commits

    When connection open schema transaction for database: typedb
    Then typeql schema query; fails
      """
      define attribute code-name value long;
      """
    When transaction closes

    When connection open schema transaction for database: typedb
    Then typeql schema query; fails
      """
      define attribute code-name-2 sub name;
      """

  Scenario Outline: a type can own a '<value_type>' attribute type
    When typeql schema query
      """
      define
      attribute <label> value <value_type>;
      person owns <label>;
      """
    Then transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
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


  Scenario: defining an attribute type value when a different value is already defined errors
    Then typeql schema query; fails with a message containing: "different 'name value string' is already defined"
      """
      define name value long;
      """

  ###########
  # STRUCTS #
  ###########

    # TODO 3.x: Add tests for structs

  ###############
  # ANNOTATIONS #
  ###############

  # TODO: For all "can set annotation ... to" tests, add match queries to check the definition when "match @..." is implemented

  Scenario Outline: can set annotation @<annotation> to entity types
    Then typeql schema query
      """
      define
      entity player @<annotation>;
      """
    Then transaction commits

    When connection open schema transaction for database: typedb
    Then typeql schema query
      """
      define
      player @<annotation> @<annotation> @<annotation>;
      """
    Then transaction commits
    Examples:
      | annotation |
      | abstract   |


  Scenario Outline: cannot set annotation @<annotation> to entity types
    Then typeql schema query; fails
      """
      define
      entity player @<annotation>;
      """
    Examples:
      | annotation       |
      | distinct         |
      | independent      |
      | unique           |
      | key              |
      | card(1..1)       |
      | regex("val")     |
#      | cascade          | # TODO: Cascade is temporarily turned off
      | range("1".."2")  |
      | values("1", "2") |


    # Uncomment and fill when annotations with arguments appear for entity types
#  Scenario Outline: cannot define different annotations of the same category on entity types
#    Then typeql schema query; fails with a message containing: "Try redefine instead"
#      """
#      define
#      entity player @<annotation-1> @<annotation-2>;
#      """
#    Examples:
#      | annotation-1 | annotation-2 |


  Scenario Outline: can set annotation @<annotation> to relation types
    Then typeql schema query
      """
      define
      relation parentship @<annotation>, relates parent;
      """
    Then transaction commits

    When connection open schema transaction for database: typedb
    Then typeql schema query
      """
      define
      parentship @<annotation> @<annotation> @<annotation>;
      """
    Then transaction commits
    Examples:
      | annotation |
      | abstract   |
#      | cascade          | # TODO: Cascade is temporarily turned off


  Scenario Outline: cannot set annotation @<annotation> to relation types
    Then typeql schema query; fails
      """
      define
      relation parentship @<annotation>, relates parent;
      """
    Examples:
      | annotation       |
      | distinct         |
      | independent      |
      | unique           |
      | key              |
      | card(1..1)       |
      | regex("val")     |
      | range("1".."2")  |
      | values("1", "2") |


    # Uncomment and fill when annotations with arguments appear for relation types
#  Scenario Outline: cannot define different annotations of the same category on relation types
#    Then typeql schema query; fails with a message containing: "Try redefine instead"
#      """
#      define
#      relation parentship @<annotation-1> @<annotation-2>, relates parent;
#      """
#    Then transaction commits
#    Examples:
#      | annotation-1 | annotation-2 |


  Scenario Outline: can set annotation @<annotation> to attribute types
    Then typeql schema query
      """
      define
      attribute description @<annotation>, value string;
      """
    Then transaction commits

    When connection open schema transaction for database: typedb
    Then typeql schema query
      """
      define
      description @<annotation> @<annotation> @<annotation>;
      """
    Then transaction commits
    Examples:
      | annotation  |
      | abstract    |
      | independent |


  Scenario Outline: cannot set annotation @<annotation> to attribute types
    Then typeql schema query; fails
      """
      define
      attribute description @<annotation>, value string;
      """
    Examples:
      | annotation       |
      | distinct         |
      | unique           |
      | key              |
      | card(1..1)       |
#      | cascade          | # TODO: Cascade is temporarily turned off
      | regex("val")     |
      | range("1".."2")  |
      | values("1", "2") |


    # Uncomment and fill when annotations with arguments appear for attribute types
#  Scenario Outline: cannot define different annotations of the same category on attribute types
#    Then typeql schema query; fails with a message containing: "Try redefine instead"
#      """
#      define
#      attribute description @<annotation-1> @<annotation-2>, value string;
#      """
#    Then transaction commits
#    Examples:
#      | annotation-1 | annotation-2 |


  Scenario Outline: can set annotation @<annotation> to relates/role types
    Then typeql schema query
      """
      define
      relation parentship @abstract, relates parent @<annotation>;
      """
    Then transaction commits

    When connection open schema transaction for database: typedb
    Then typeql schema query
      """
      define
      parentship relates parent @<annotation> @<annotation> @<annotation>;
      """
    Then transaction commits
    Examples:
      | annotation |
      | abstract   |
      | card(1..1) |


  Scenario Outline: cannot set annotation @<annotation> to relates/role types
    Then typeql schema query; fails
      """
      define
      relation parentship @abstract, relates parent @<annotation>;
      """
    Examples:
      | annotation       |
      | distinct         |
      | independent      |
      | unique           |
      | key              |
#      | cascade          | # TODO: Cascade is temporarily turned off
      | regex("val")     |
      | range("1".."2")  |
      | values("1", "2") |


  Scenario Outline: cannot define different annotations of the same category on role types
    Then typeql schema query; fails with a message containing: "Try redefine instead"
      """
      define
      relation parentship relates parent @<annotation-1> @<annotation-2>;
      """
    Examples:
      | annotation-1 | annotation-2 |
      | card(1..1)   | card(0..5)   |


  Scenario Outline: can set annotation @<annotation> to relates/role types lists
    Then typeql schema query
      """
      define
      relation parentship @abstract, relates parent[] @<annotation>;
      """
    Then transaction commits

    When connection open schema transaction for database: typedb
    Then typeql schema query
      """
      define
      parentship relates parent[] @<annotation> @<annotation> @<annotation>;
      """
    Then transaction commits
    Examples:
      | annotation |
      | abstract   |
      | card(1..1) |
      | distinct   |


  Scenario Outline: cannot set annotation @<annotation> to relates/role types lists
    Then typeql schema query; fails
      """
      define
      relation parentship @abstract, relates parent[] @<annotation>;
      """
    Examples:
      | annotation       |
      | independent      |
      | unique           |
      | key              |
#      | cascade          | # TODO: Cascade is temporarily turned off
      | regex("val")     |
      | range("1".."2")  |
      | values("1", "2") |


  Scenario Outline: can set annotation @<annotation> to owns
    Then typeql schema query
      """
      define
      entity player owns name @<annotation>;
      """
    Then transaction commits

    When connection open schema transaction for database: typedb
    Then typeql schema query
      """
      define
      player owns name @<annotation> @<annotation> @<annotation>;
      """
    Then transaction commits
    Examples:
      | annotation       |
      | card(1..1)       |
      | unique           |
      | key              |
      | regex("val")     |
      | range("1".."2")  |
      | values("1", "2") |


  Scenario Outline: cannot set annotation @<annotation> to owns
    Then typeql schema query; fails
      """
      define
      entity player owns name @<annotation>;
      """
    Examples:
      | annotation  |
      | abstract    |
      | distinct    |
      | independent |
#      | cascade          | # TODO: Cascade is temporarily turned off


  Scenario Outline: cannot define different annotations of the same category on owns
    Then typeql schema query; fails with a message containing: "Try redefine instead"
      """
      define
      entity player owns name @<annotation-1> @<annotation-2>;
      """
    Examples:
      | annotation-1        | annotation-2               |
      | card(1..1)          | card(0..5)                 |
      | regex("one")        | regex("another")           |
      | range("one".."two") | range("another".."second") |
      | values("1", "2")    | values("3", "4")           |


  Scenario Outline: cannot set annotation @<annotation> to owns of attribute type of wrong <value-type>
    Then typeql schema query; fails
      """
      define
      attribute description<value-type>;
      entity player owns description @<annotation>;
      """
    Examples:
      | annotation                                            | value-type          |
      | regex("A")                                            | , value bool        |
      | regex("A")                                            | , value long        |
      | regex("A")                                            | , value double      |
      | regex("A")                                            | , value decimal     |
      | regex("A")                                            | , value date        |
      | regex("A")                                            | , value datetime    |
      | regex("A")                                            | , value datetime-tz |
      | regex("A")                                            | , value duration    |
      | regex("A")                                            |                     |

      | range("A".."B")                                       |                     |
      | range(1..2)                                           |                     |
      | range("A".."B")                                       | , value long        |
      | range("P1Y2M3DT4H5M6.788S".."P1Y2M3DT4H5M6.789S")     | , value long        |
      | range("A".."B")                                       | , value datetime    |
      | range(1..2)                                           | , value datetime    |
      | range(1..2)                                           | , value string      |
      | range(-9223372036854775808..9223372036854775807)      | , value string      |
      | range(2024-06-04T16:35:02.10..2024-06-04T16:35:03.11) | , value string      |
      | range(2024-06-04..2024-06-05)                         | , value double      |
      | range(2024-06-04T16:35:02.10..2024-06-04T16:35:03.11) | , value date        |
      | range("P1Y2M3DT4H5M6.788S".."P1Y2M3DT4H5M6.789S")     | , value date        |

      | values("A", 2)                                        |                     |
      | values("A")                                           |                     |
      | values(false)                                         |                     |
      | values(0)                                             |                     |
      | values("A", 2)                                        | , value long        |
      | values("A", "B")                                      | , value long        |
      | values(0.1)                                           | , value long        |
      | values("string")                                      | , value long        |
      | values(true)                                          | , value long        |
      | values(2024-06-04)                                    | , value long        |
      | values(2024-06-04T00:00:00+0010)                      | , value long        |
      | values("string")                                      | , value double      |
      | values(true)                                          | , value double      |
      | values(2024-06-04)                                    | , value double      |
      | values(2024-06-04T00:00:00+0010)                      | , value double      |
      | values("string")                                      | , value decimal     |
      | values(true)                                          | , value decimal     |
      | values(2024-06-04)                                    | , value decimal     |
      | values(2024-06-04T00:00:00+0010)                      | , value decimal     |
      | values("A", 2)                                        | , value string      |
      | values(123)                                           | , value string      |
      | values(true)                                          | , value string      |
      | values(2024-06-04)                                    | , value string      |
      | values(2024-06-04T00:00:00+0010)                      | , value string      |
      | values(123)                                           | , value date        |
      | values(2024-06-04T00:00:00+0010)                      | , value date        |
      | values(2024-06-04T16:35:02)                           | , value date        |
      | values("福")                                           | , value date        |
      | values(2024-06-04T00:00:00 Europe/Belfast)            | , value datetime    |
      | values(2024-06-04T00:00:00+0010)                      | , value datetime    |
      | values(2024-06-04)                                    | , value datetime-tz |
      | values(123)                                           | , value duration    |
      | values("string")                                      | , value duration    |
      | values(2024-06-04)                                    | , value duration    |
      | values(2024-06-04T00:00:00+0100)                      | , value duration    |
      | values("year")                                        | , value duration    |


  Scenario Outline: cannot set annotation @values(<arg0>, <arg1>, <arg0>) with duplicated arguments to owns
    Then typeql schema query; fails
      """
      define
      attribute description, value <value-type>;
      entity player owns description @values(<arg0>, <arg1>, <arg0>);
      """

    Given transaction closes
    Given connection open schema transaction for database: typedb
    Then typeql schema query; fails
      """
      define
      attribute description, value <value-type>;
      entity player owns description @values(<arg0>, <arg0>, <arg1>);
      """

    Given transaction closes
    Given connection open schema transaction for database: typedb
    Then typeql schema query; fails
      """
      define
      attribute description, value <value-type>;
      entity player owns description @values(<arg1>, <arg0>, <arg0>);
      """
    Examples:
      | arg0                     | arg1                     | value-type  |
      | 1                        | 2                        | long        |
      | 112.2                    | 134.3                    | double      |
      | 124.4                    | 124.0                    | decimal     |
      | false                    | true                     | boolean     |
      | "hi"                     | "bye"                    | string      |
      | 2024-09-13               | 2024-09-15               | date        |
      | 2024-09-13T15:07:03      | 2024-10-13T15:07:04      | datetime    |
      | 2024-09-13T15:07:03+0100 | 2024-10-13T15:07:04+0100 | datetime-tz |
      | "P1Y2M3DT4M6.789S"       | "P1Y2M3DT4H5.789S"       | duration    |


  Scenario Outline: can set annotation @<annotation> to owns lists
    Then typeql schema query
      """
      define
      entity player owns name[] @<annotation>;
      """
    Then transaction commits

    When connection open schema transaction for database: typedb
    Then typeql schema query
      """
      define
      player owns name[] @<annotation> @<annotation> @<annotation>;
      """
    Then transaction commits
    Examples:
      | annotation       |
      | distinct         |
      | card(1..1)       |
      | unique           |
      | key              |
      | regex("val")     |
      | range("1".."2")  |
      | values("1", "2") |


  Scenario Outline: cannot set annotation @<annotation> to owns lists
    Then typeql schema query; fails
      """
      define
      entity player owns name[] @<annotation>;
      """
    Examples:
      | annotation  |
      | abstract    |
      | independent |
#      | cascade          | # TODO: Cascade is temporarily turned off


  Scenario Outline: can set annotation @<annotation> to plays
    Then typeql schema query
      """
      define
      entity player plays employment:employee @<annotation>;
      """
    Then transaction commits

    When connection open schema transaction for database: typedb
    Then typeql schema query
      """
      define
      player plays employment:employee @<annotation> @<annotation> @<annotation>;
      """
    Then transaction commits
    Examples:
      | annotation |
      | card(1..1) |


  Scenario Outline: cannot set annotation @<annotation> to plays
    Then typeql schema query; fails
      """
      define
      entity player plays employment:employee @<annotation>;
      """
    Examples:
      | annotation       |
      | abstract         |
      | distinct         |
      | independent      |
#      | cascade          | # TODO: Cascade is temporarily turned off
      | unique           |
      | key              |
      | regex("val")     |
      | range("1".."2")  |
      | values("1", "2") |


  Scenario Outline: cannot define different annotations of the same category on owns
    Then typeql schema query; fails with a message containing: "Try redefine instead"
      """
      define
      entity player plays employment:employee @<annotation-1> @<annotation-2>;
      """
    Examples:
      | annotation-1 | annotation-2 |
      | card(1..1)   | card(0..5)   |


  Scenario Outline: can set annotation @<annotation> to value types
    Then typeql schema query
      """
      define
      attribute description value string @<annotation>;
      """
    Then transaction commits

    When connection open schema transaction for database: typedb
    Then typeql schema query
      """
      define
      description value string @<annotation> @<annotation> @<annotation>;
      """
    Then transaction commits
    Examples:
      | annotation       |
      | regex("val")     |
      | range("1".."2")  |
      | values("1", "2") |


  Scenario Outline: cannot set annotation @<annotation> to wrong value type <value-type>
    Then typeql schema query; fails
      """
      define
      attribute description value <value-type> @<annotation>;
      """
    Examples:
      | annotation                                            | value-type  |
      | regex("A")                                            | bool        |
      | regex("A")                                            | long        |
      | regex("A")                                            | double      |
      | regex("A")                                            | decimal     |
      | regex("A")                                            | date        |
      | regex("A")                                            | datetime    |
      | regex("A")                                            | datetime-tz |
      | regex("A")                                            | duration    |

      | range("A".."B")                                       | long        |
      | range("P1Y2M3DT4H5M6.788S".."P1Y2M3DT4H5M6.789S")     | long        |
      | range("A".."B")                                       | datetime    |
      | range(1..2)                                           | datetime    |
      | range(1..2)                                           | string      |
      | range(-9223372036854775808..9223372036854775807)      | string      |
      | range(2024-06-04T16:35:02.10..2024-06-04T16:35:03.11) | string      |
      | range(2024-06-04..2024-06-05)                         | double      |
      | range(2024-06-04T16:35:02.10..2024-06-04T16:35:03.11) | date        |
      | range("P1Y2M3DT4H5M6.788S".."P1Y2M3DT4H5M6.789S")     | date        |

      | values("A", 2)                                        | long        |
      | values("A", "B")                                      | long        |
      | values(0.1)                                           | long        |
      | values("string")                                      | long        |
      | values(true)                                          | long        |
      | values(2024-06-04)                                    | long        |
      | values(2024-06-04T00:00:00+0010)                      | long        |
      | values("string")                                      | double      |
      | values(true)                                          | double      |
      | values(2024-06-04)                                    | double      |
      | values(2024-06-04T00:00:00+0010)                      | double      |
      | values("string")                                      | decimal     |
      | values(true)                                          | decimal     |
      | values(2024-06-04)                                    | decimal     |
      | values(2024-06-04T00:00:00+0010)                      | decimal     |
      | values("A", 2)                                        | string      |
      | values(123)                                           | string      |
      | values(true)                                          | string      |
      | values(2024-06-04)                                    | string      |
      | values(2024-06-04T00:00:00+0010)                      | string      |
      | values(123)                                           | date        |
      | values(2024-06-04T00:00:00+0010)                      | date        |
      | values(2024-06-04T16:35:02)                           | date        |
      | values("福")                                           | date        |
      | values(2024-06-04T00:00:00 Europe/Belfast)            | datetime    |
      | values(2024-06-04T00:00:00+0010)                      | datetime    |
      | values(2024-06-04)                                    | datetime-tz |
      | values(123)                                           | duration    |
      | values("string")                                      | duration    |
      | values(2024-06-04)                                    | duration    |
      | values(2024-06-04T00:00:00+0100)                      | duration    |
      | values("year")                                        | duration    |


  Scenario Outline: cannot define different annotations of the same category on owns
    Then typeql schema query; fails with a message containing: "Try redefine instead"
      """
      define
      attribute description value string @<annotation-1> @<annotation-2>;
      """
    Examples:
      | annotation-1        | annotation-2               |
      | regex("one")        | regex("another")           |
      | range("one".."two") | range("another".."second") |
      | values("1", "2")    | values("3", "4")           |


  Scenario Outline: cannot set annotation @values(<arg0>, <arg1>, <arg0>) with duplicated arguments to value type
    Then typeql schema query; fails
      """
      define
      attribute description value <value-type> @values(<arg0>, <arg1>, <arg0>);
      """

    Given transaction closes
    Given connection open schema transaction for database: typedb
    Then typeql schema query; fails
      """
      define
      attribute description value <value-type> @values(<arg0>, <arg0>, <arg1>);
      """

    Given transaction closes
    Given connection open schema transaction for database: typedb
    Then typeql schema query; fails
      """
      define
      attribute description value <value-type> @values(<arg1>, <arg0>, <arg0>);
      """
    Examples:
      | arg0                     | arg1                     | value-type  |
      | 1                        | 2                        | long        |
      | 112.2                    | 134.3                    | double      |
      | 124.4                    | 124.0                    | decimal     |
      | false                    | true                     | boolean     |
      | "hi"                     | "bye"                    | string      |
      | 2024-09-13               | 2024-09-15               | date        |
      | 2024-09-13T15:07:03      | 2024-10-13T15:07:04      | datetime    |
      | 2024-09-13T15:07:03+0100 | 2024-10-13T15:07:04+0100 | datetime-tz |
      | "P1Y2M3DT4M6.789S"       | "P1Y2M3DT4H5.789S"       | duration    |


  Scenario Outline: cannot set annotation @<annotation> to value types
    Then typeql schema query; fails
      """
      define
      attribute description value string @<annotation>;
      """
    Examples:
      | annotation  |
      | abstract    |
      | distinct    |
      | independent |
      | unique      |
      | key         |
      | card(1..1)  |
#      | cascade          | # TODO: Cascade is temporarily turned off


  Scenario Outline: cannot set annotation @<annotation> to subs
    Then typeql schema query; fails
      """
      define
      entity player sub person @<annotation>;
      """
    Examples:
      | annotation       |
      | abstract         |
      | distinct         |
      | independent      |
      | unique           |
      | key              |
      | card(1..1)       |
      | regex("val")     |
#      | cascade          | # TODO: Cascade is temporarily turned off
      | range("1".."2")  |
      | values("1", "2") |


    # TODO: Same "cannot set annotation" for alias when aliases are implemented?


  Scenario Outline: cannot set @abstract annotation with arguments
    Then typeql schema query; parsing fails
      """
      define
      entity player @abstract(<args>);
      """

    Given connection open schema transaction for database: typedb
    Then typeql schema query; parsing fails
      """
      define
      relation parentship @abstract(<args>), relates parent;
      """

    Given connection open schema transaction for database: typedb
    Then typeql schema query; parsing fails
      """
      define
      attribute characteristics @abstract(<args>);
      """

    Given connection open schema transaction for database: typedb
    Then typeql schema query; parsing fails
      """
      define
      relation parentship relates parent @abstract(<args>);
      """

    Given connection open schema transaction for database: typedb
    Then typeql schema query; parsing fails
      """
      define
      entity player owns name @abstract(<args>);
      """

    Given connection open schema transaction for database: typedb
    Then typeql schema query; parsing fails
      """
      define
      entity player plays employment:employee @abstract(<args>);
      """
    Examples:
      | args     |
      |          |
      | 1        |
      | 1, 2     |
      | 1..2     |
      | A        |
      | "A"      |
      | "A", "B" |
      | "A".."B" |


  Scenario Outline: cannot set @distinct annotation with arguments
    Then typeql schema query; parsing fails
      """
      define
      relation parentship relates parent[] @distinct(<args>);
      """

    Given connection open schema transaction for database: typedb
    Then typeql schema query; parsing fails
      """
      define
      entity player owns name[] @distinct(<args>);
      """
    Examples:
      | args     |
      |          |
      | 1        |
      | 1, 2     |
      | 1..2     |
      | A        |
      | "A"      |
      | "A", "B" |
      | "A".."B" |


  Scenario Outline: cannot set @independent annotation with arguments
    Then typeql schema query; parsing fails
      """
      define
      attribute characteristics @independent(<args>);
      """
    Examples:
      | args     |
      |          |
      | 1        |
      | 1, 2     |
      | 1..2     |
      | A        |
      | "A"      |
      | "A", "B" |
      | "A".."B" |


  Scenario Outline: cannot set @unique annotation with arguments
    Then typeql schema query; parsing fails
      """
      define
      entity player owns name @unique(<args>);
      """
    Examples:
      | args     |
      |          |
      | 1        |
      | 1, 2     |
      | 1..2     |
      | A        |
      | "A"      |
      | "A", "B" |
      | "A".."B" |


  Scenario Outline: cannot set @key annotation with arguments
    Then typeql schema query; parsing fails
      """
      define
      entity player owns name @key(<args>);
      """
    Examples:
      | args     |
      |          |
      | 1        |
      | 1, 2     |
      | 1..2     |
      | A        |
      | "A"      |
      | "A", "B" |
      | "A".."B" |


  Scenario Outline: cannot set @card annotation with invalid arguments <args>
    Then typeql schema query; parsing fails
      """
      define
      relation parentship relates parent @card(<args>);
      """

    Given connection open schema transaction for database: typedb
    Then typeql schema query; parsing fails
      """
      define
      entity player owns name @card(<args>);
      """

    Given connection open schema transaction for database: typedb
    Then typeql schema query; parsing fails
      """
      define
      entity player plays employment:employee @card(<args>);
      """
    Examples:
      | args          |
      |               |
      | 1, 2          |
      | 1, 2, 3       |
      | A             |
      | "A"           |
      | "A", "B"      |
      | "A".."B"      |
      | "A".."B".."C" |
      | 1.1.."B"      |
      | 1.1..2        |
      | 1.1..2.2      |
      | 1.2           |
      | ..2           |


  Scenario Outline: cannot set @regex annotation with arguments
    Then typeql schema query; parsing fails
      """
      define
      attribute characteristics @regex(<args>);
      """

    Given connection open schema transaction for database: typedb
    Then typeql schema query; parsing fails
      """
      define
      entity player owns name @regex(<args>);
      """
    Examples:
      | args     |
      |          |
      | 1        |
      | 1.2      |
      | abcd     |
      | 0..2     |
      | "A".."B" |
      | "A", "B" |
      | "A" "B"  |
      | "A       |
      | A"       |
      | """      |
      | "\"      |


  Scenario Outline: cannot set @range annotation with invalid arguments <args>
    Then typeql schema query; parsing fails
      """
      define
      attribute characteristics @range(<args>);
      """

    Given connection open schema transaction for database: typedb
    Then typeql schema query; parsing fails
      """
      define
      entity player owns name @range(<args>);
      """
    Examples:
      | args    |
      |         |
      | 1, 2    |
      | 1.2     |
      | abcd    |
      | A..B    |
      | "A"."B" |


  Scenario Outline: cannot set @values annotation with invalid arguments <args>
    Then typeql schema query; parsing fails
      """
      define
      attribute characteristics @values(<args>);
      """

    Given connection open schema transaction for database: typedb
    Then typeql schema query; parsing fails
      """
      define
      entity player owns name @values(<args>);
      """
    Examples:
      | args |
      | 1 2  |
      | 1..2 |
      | 1. 2 |
      | 1A2  |
      | 1A 2 |


    # TODO: Add a test for @cascade when it appears again


  Scenario: annotations can be added on subtypes
    Given typeql schema query
      """
      define
      entity child sub person, owns school-id @unique;
      attribute school-id value string;
      """
    Then transaction commits


  Scenario: annotations are inherited
    Given typeql schema query
      """
      define entity child sub person;
      """
    Given transaction commits

    # TODO: Uncomment when "match @..." is implemented
#    Then connection open read transaction for database: typedb
#    When get answers of typeql read query
#      """
#      match $t owns $a @key;
#      """
#    Then uniquely identify answer concepts
#      | t                | a                               |
#      | label:person     | label:email                     |
#      | label:child      | label:email                     |
#      | label:employment | label:employment-reference-code |
#    When get answers of typeql read query
#      """
#      match $t owns $a @unique;
#      """
#    Then uniquely identify answer concepts
#      | t            | a              |
#      | label:person | label:phone-nr |
#      | label:child  | label:phone-nr |


  Scenario: redefining inherited annotations errors for types and capabilities
    Then typeql schema query
      """
      define entity child sub person; # owns email @key from background
      """
    Then transaction commits
    When connection open schema transaction for database: typedb
    Then typeql schema query
      """
      define child owns email @key;
      """
    Then transaction commits; fails with a message containing: "without specialisation"
    When connection open schema transaction for database: typedb
    Then typeql schema query
      """
      define child owns phone-nr @unique;
      """
    Then transaction commits; fails with a message containing: "without specialisation"
    When connection open schema transaction for database: typedb
    Then typeql schema query
      """
      define email @abstract; attribute working-email sub email, value string @regex("^.*@.*$");
      """
    Then transaction commits; fails with a message containing: "without specialisation"


  Scenario: type cannot specialise owns
    Then typeql schema query; parsing fails
      """
      define
      entity person @abstract;
      attribute phone-nr @abstract;
      entity child sub person, owns mobile as phone-nr;
      """

  ##################
  # ABSTRACT TYPES #
  ##################

  Scenario: an abstract entity type can be defined
    When typeql schema query
      """
      define entity animal @abstract;
      """
    Then transaction commits

    # TODO: Uncomment when "match @..." is implemented
#    Given connection open read transaction for database: typedb
#    When get answers of typeql read query
#      """
#      match
#      $x label animal;
#      $x @abstract;
#      """
#    Then uniquely identify answer concepts
#      | x            |
#      | label:animal |


  Scenario: a concrete entity type can be defined as a subtype of an abstract entity type
    When typeql schema query
      """
      define
      entity animal @abstract;
      entity horse sub animal;
      """
    Then transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x sub animal;
      """
    Then uniquely identify answer concepts
      | x            |
      | label:animal |
      | label:horse  |


  Scenario: an abstract entity type can be defined as a subtype of another abstract entity type
    When typeql schema query
      """
      define
      entity animal @abstract;
      entity fish @abstract, sub animal;
      """
    Then transaction commits

    # TODO: Uncomment when "match @..." is implemented
#    Given connection open read transaction for database: typedb
#    When get answers of typeql read query
#      """
#      match $x sub animal; $x @abstract;
#      """
#    Then uniquely identify answer concepts
#      | x            |
#      | label:animal |
#      | label:fish   |


  Scenario: an abstract entity type cannot be defined as a subtype of a concrete entity type
    Then typeql schema query; fails
      """
      define
      entity exception;
      entity typedb-exception @abstract, sub exception;
      """


  Scenario: an abstract relation type can be defined
    When typeql schema query
      """
      define relation membership @abstract, relates member;
      """
    Then transaction commits

    # TODO: Uncomment when "match @..." is implemented
#    Given connection open read transaction for database: typedb
#    When get answers of typeql read query
#      """
#      match $x label membership; $x @abstract;
#      """
#    Then uniquely identify answer concepts
#      | x                |
#      | label:membership |


  Scenario: a concrete relation type can be defined as a subtype of an abstract relation type
    When typeql schema query
      """
      define
      relation membership @abstract, relates member;
      relation gym-membership sub membership, relates gym-with-members, relates gym-member as member;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x sub membership;
      """
    Then uniquely identify answer concepts
      | x                    |
      | label:membership     |
      | label:gym-membership |


  Scenario: an abstract relation type can be defined as a subtype of another abstract relation type
    When typeql schema query
      """
      define
      relation requirement @abstract, relates prerequisite, relates outcome;
      relation tool-requirement @abstract, sub requirement, relates required-tool as prerequisite;
      """
    Then transaction commits

    # TODO: Uncomment when "match @..." is implemented
#    When connection open read transaction for database: typedb
#    When get answers of typeql read query
#      """
#      match $x sub requirement; $x @abstract;
#      """
#    Then uniquely identify answer concepts
#      | x                      |
#      | label:requirement      |
#      | label:tool-requirement |


  Scenario: an abstract relation type cannot be defined as a subtype of a concrete relation type
    Then typeql schema query; fails
      """
      define
      relation requirement relates prerequisite, relates outcome;
      relation tech-requirement @abstract, sub requirement, relates required-tech as prerequisite;
      """


  Scenario: an abstract attribute type can be defined
    When typeql schema query
      """
      define attribute number-of-limbs @abstract, value long;
      """
    Then transaction commits

    # TODO: Uncomment when "match @..." is implemented
#    Given connection open read transaction for database: typedb
#    When get answers of typeql read query
#      """
#      match $x label number-of-limbs; $x @abstract;
#      """
#    Then uniquely identify answer concepts
#      | x                     |
#      | label:number-of-limbs |


  Scenario: a concrete attribute type can be defined as a subtype of an abstract attribute type
    When typeql schema query
      """
      define
      attribute number-of-limbs @abstract, value long;
      attribute number-of-legs sub number-of-limbs;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x sub number-of-limbs;
      """
    Then uniquely identify answer concepts
      | x                     |
      | label:number-of-limbs |
      | label:number-of-legs  |


  Scenario: an abstract attribute type can be defined as a subtype of another abstract attribute type
    When typeql schema query
      """
      define
      attribute number-of-limbs @abstract, value long;
      attribute number-of-artificial-limbs @abstract, sub number-of-limbs;
      """
    Then transaction commits

    # TODO: Uncomment when "match @..." is implemented
#    Given connection open read transaction for database: typedb
#    When get answers of typeql read query
#      """
#      match $x @abstract, sub number-of-limbs;
#      """
#    Then uniquely identify answer concepts
#      | x                                |
#      | label:number-of-limbs            |
#      | label:number-of-artificial-limbs |


  Scenario: defining attribute type hierarchies is idempotent
    When typeql schema query
      """
      define attribute super-name @abstract, value string; attribute location-name sub super-name;
      """
    Then transaction commits
    Then connection open schema transaction for database: typedb
    Then typeql schema query
      """
      define attribute super-name @abstract, value string; attribute location-name sub super-name;
      """
    Then transaction commits
    Then connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
      $name label super-name;
      $location label location-name, sub super-name;
      """
    Then uniquely identify answer concepts
      | name             | location            |
      | label:super-name | label:location-name |

  ###################
  # SCHEMA MUTATION #
  ###################

  Scenario: an existing type can be repeatedly redefined, and it is a no-op
    When typeql schema query
      """
      define
      entity person owns name;
      entity person owns name;
      relation employment relates employee;
      relation employment relates employee;
      relation employment relates employer;
      relation employment relates employer;
      attribute name value string;
      attribute name;
      attribute name value string;
      entity person owns email @key;
      entity person owns email @key;
      entity person owns email;
      entity person owns name;
      relation subemployment sub employment, relates subemployee as employee;
      relation subemployment sub employment, relates subemployee as employee;
      relation subemployment sub employment, relates subemployee as employee;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x label person, owns name;
      """
    Then answer size is: 1

    When get answers of typeql read query
      """
      match $x label person, owns email;
      """
    Then answer size is: 1

    # TODO: Uncomment when "match @..." is implemented
#    When get answers of typeql read query
#      """
#      match $x label person, owns email @key;
#      """
#    Then answer size is: 1

    When get answers of typeql read query
      """
      match $x label employment, relates employee;
      """
    Then answer size is: 1

    When get answers of typeql read query
      """
      match $x label employment, relates employer;
      """
    Then answer size is: 1

    When get answers of typeql read query
      """
      match $x label subemployment, relates subemployee;
      """
    Then answer size is: 1

    When get answers of typeql read query
      """
      match $_ relates subemployee as $x;
      """
    Then answer size is: 1

    When get answers of typeql read query
      """
      match $x label name;
      """
    Then answer size is: 1

    # TODO: ConstraintBase::ValueType is not implemented
#    When get answers of typeql read query
#      """
#      match $x label name, value string;
#      """
#    Then answer size is: 1


  Scenario: an entity type cannot be changed into a relation type
    Then typeql schema query; fails
      """
      define
      relation person relates body-part;
      entity arm plays person:body-part;
      """


  Scenario: a relation type cannot be changed into an attribute type
    Then typeql schema query; fails
      """
      define attribute employment value string;
      """


  Scenario: an attribute type cannot be changed into an entity type
    Then typeql schema query; fails
      """
      define entity name;
      """


  Scenario: a new attribute ownership can be defined on an existing type
    When typeql schema query
      """
      define employment owns name;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x owns name;
      """
    Then uniquely identify answer concepts
      | x                |
      | label:person     |
      | label:employment |


  Scenario: a new playable role can be defined on an existing type
    When typeql schema query
      """
      define employment plays employment:employee;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x plays employment:employee;
      """
    Then uniquely identify answer concepts
      | x                |
      | label:person     |
      | label:employment |


  Scenario: defining a key on an existing ownership is possible if data already conforms to key requirements
    Given typeql schema query
      """
      define
      attribute barcode value string;
      entity product owns name, owns barcode;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x isa product, has name "Cheese", has barcode "10001";
      $y isa product, has name "Ham", has barcode "10011";
      $a "Milk" isa name;
      $b "11111" isa barcode;
      """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    When typeql schema query
      """
      define
      product owns barcode @key;
      """
    Then transaction commits

    # TODO: Uncomment when "match @..." is implemented
#    Given connection open read transaction for database: typedb
#    When get answers of typeql read query
#      """
#      match $x owns barcode @key;
#      """
#    Then uniquely identify answer concepts
#      | x             |
#      | label:product |


  Scenario: defining a key on a type errors if existing instances don't have that key
    Given typeql schema query
      """
      define
      attribute barcode value string;
      entity product owns name;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x isa product, has name "Cheese";
      $y isa product, has name "Ham";
      """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    Then typeql schema query; fails
      """
      define
      product owns barcode @key;
      """


  Scenario: defining a key on a type errors if there is a key collision between two existing instances
    Given typeql schema query
      """
      define
      attribute barcode value string;
      entity product owns name, owns barcode;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x isa product, has name "Cheese", has barcode "10000";
      $y isa product, has name "Ham", has barcode "10000";
      """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    Then typeql schema query; fails
      """
      define
      product owns barcode @key;
      """


  Scenario: a new role can be defined on an existing relation type
    When typeql schema query
      """
      define
      entity company plays employment:employer;
      employment relates employer;
      """
    Then transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x relates employer;
      """
    Then uniquely identify answer concepts
      | x                |
      | label:employment |


  Scenario: Defining an attribute type multiple times succeeds if and only if the value type remains unchanged
    Then typeql schema query; fails
      """
      define attribute name value long;
      """
    Given transaction closes
    Given connection open schema transaction for database: typedb
    When typeql schema query
      """
      define attribute name value string;
      """
    Then transaction commits


  Scenario: a regex constraint can be added to an existing attribute type if all its instances satisfy it
    Given transaction closes
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x isa person, has name "Alice", has email "alice@vaticle.com";
      """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    When typeql schema query
      """
      define name value string @regex("^A.*$");
      """
    Then transaction commits

    # TODO: Uncomment when "match @..." is implemented
#    Given connection open read transaction for database: typedb
#    Then get answers of typeql read query
#      """
#      match $x @regex("^A.*$");
#      """
#    Then uniquely identify answer concepts
#      | x          |
#      | label:name |


  Scenario: a regex cannot be added to an existing attribute type if there is an instance that doesn't satisfy it
    Given transaction closes
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x isa person, has name "Maria", has email "maria@vaticle.com";
      """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    Then typeql schema query; fails
      """
      define name @regex("^A.*$");
      """


  Scenario: a regex constraint can not be added to an existing attribute type whose value type isn't 'string'
    Given typeql schema query
      """
      define attribute house-number value long;
      """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    Then typeql schema query; fails
      """
      define house-number @regex("^A.*$");
      """


  Scenario: related roles cannot be added to existing entity types
    Then typeql schema query; fails
      """
      define person relates employee;
      """


  Scenario: related roles cannot be added to existing attribute types
    Then typeql schema query; fails
      """
      define name relates employee;
      """


  Scenario: the value type of an existing attribute type is not modifiable through define
    Then typeql schema query; fails
      """
      define name value long;
      """
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Then typeql schema query; fails
      """
      define attribute name value long;
      """

  Scenario: an attribute ownership can be converted to a key ownership
    When typeql schema query
      """
      define person owns name @key;
      """
    Then transaction commits

    # TODO: Uncomment when "match @..." is implemented
#    Given connection open read transaction for database: typedb
#    When get answers of typeql read query
#      """
#      match $x owns name @key;
#      """
#    Then uniquely identify answer concepts
#      | x            |
#      | label:person |


  Scenario: an attribute key ownership can be converted to a regular ownership
    When typeql schema query
      """
      define person owns email;
      """
    Then transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x owns email;
      """
    Then uniquely identify answer concepts
      | x            |
      | label:person |

    # TODO: Uncomment when "match @..." is implemented
#    When get answers of typeql read query; fails ......
#      """
#      match $x owns email @key;
#      """
#    Then answer size is: 0


  Scenario: defining a uniqueness on existing ownership is possible if data conforms to uniqueness requirements
    Given typeql schema query
      """
      define person owns name @card(0..);
      """
    Given transaction commits
    Given connection open write transaction for database: typedb
    When typeql write query
      """
      insert $x isa person, has name "Bob", has email "bob@gmail.com";
      """
    Then typeql write query
      """
      insert $x isa person, has name "Jane", has name "Doe", has email "janedoe@gmail.com";
      """
    Given transaction commits
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define person owns name @unique;
      """
    Then transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query; fails
      """
      insert $x isa person, has name "Bob", has email "bob2@gmail.com";
      """


  Scenario: defining a uniqueness on existing ownership fail if data does not conform to uniqueness requirements
    Given transaction closes
    Given connection open write transaction for database: typedb
    When typeql write query
      """
      insert $x isa person, has name "Bob", has email "bob@gmail.com";
      """
    Then typeql write query
      """
      insert $x isa person, has name "Bob", has email "bob2@gmail.com";
      """
    Given transaction commits
    Given connection open schema transaction for database: typedb
    Given typeql schema query; fails
      """
      define person owns name @unique;
      """


  Scenario: ownership uniqueness can be removed
    Given typeql schema query
      """
      define person owns phone-nr;
      """
    Given transaction commits
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x isa person, has phone-nr "123", has email "abc@gmail.com";
      $y isa person, has phone-nr "456", has email "xyz@gmail.com";
      """
    Given transaction commits


  Scenario: a key ownership can be converted to a unique ownership
    Given transaction closes
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x isa person, has email "jane@gmail.com";
      $y isa person, has email "john@gmail.com";
      """
    Given transaction commits
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      undefine @key from person owns email;
      """
    Given typeql schema query
      """
      define person owns email @unique;
      """
    Then transaction commits

    Given connection open write transaction for database: typedb
    # TODO: Uncomment when "match @..." is implemented
#    When get answers of typeql read query
#      """
#      match $x owns $y @unique;
#      """
#    Then uniquely identify answer concepts
#      | x            | y              |
#      | label:person | label:email    |
#      | label:person | label:phone-nr |
#    When get answers of typeql read query
#      """
#      match person owns $y @key;
#      """
#    Then answer size is: 0

    Given typeql write query; fails
      """
      insert $x isa person, has email "jane@gmail.com";
      """


  Scenario: converting unique to key is possible if the data conforms to key requirements
    Given transaction closes
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x isa person, has phone-nr "123", has email "abc@gmail.com";
      $y isa person, has phone-nr "456", has email "xyz@gmail.com";
      """
    Given transaction commits
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      undefine @unique from person owns phone-nr;
      """
    Given typeql schema query
      """
      define person owns phone-nr @key;
      """
    Then transaction commits

    When connection open write transaction for database: typedb
    When typeql write query
      """
      insert $x isa person, has phone-nr "9999", has phone-nr "8888", has email "pqr@gmail.com";
      """
    Then transaction commits; fails with a message containing: "key constraint violation"


  Scenario: converting unique to key fails if the data does not conform to key requirements
    Given transaction closes
    Given connection open write transaction for database: typedb
    # no instances of phone-nr -> 0 vs key's card 1..1
    Given typeql write query
      """
      insert $x isa person, has email "abc@gmail.com";
      """
    Given transaction commits
    Given connection open schema transaction for database: typedb
    Then typeql schema query; fails
      """
      define
      person owns phone-nr @key;
      """

  #############################
  # SCHEMA MUTATION: ABSTRACT #
  #############################

  Scenario: a concrete entity type can be converted to an abstract entity type
    When typeql schema query
      """
      define entity person @abstract;
      """
    Then transaction commits

    # TODO: Uncomment when "match @..." is implemented
#    When connection open read transaction for database: typedb
#    When get answers of typeql read query
#      """
#      match $x @abstract, sub person;
#      """
#    Then uniquely identify answer concepts
#      | x            |
#      | label:person |


  Scenario: a concrete relation type can be converted to an abstract relation type
    When typeql schema query
      """
      define relation friendship relates friend;
      """
    Then transaction commits
    Given connection open schema transaction for database: typedb
    When typeql schema query
      """
      define friendship @abstract;
      """
    Then transaction commits

    # TODO: Uncomment when "match @..." is implemented
#    Given connection open read transaction for database: typedb
#    When get answers of typeql read query
#      """
#      match $x @abstract, sub friendship;
#      """
#    Then uniquely identify answer concepts
#      | x                |
#      | label:friendship |


  Scenario: a concrete attribute type can be converted to an abstract attribute type
    When typeql schema query
      """
      define attribute age value long;
      """
    Then transaction commits
    Given connection open schema transaction for database: typedb
    When typeql schema query
      """
      define age @abstract;
      """
    Then transaction commits

    # TODO: Uncomment when "match @..." is implemented
#    Given connection open read transaction for database: typedb
#    When get answers of typeql read query
#      """
#      match $x @abstract, sub age;
#      """
#    Then uniquely identify answer concepts
#      | x         |
#      | label:age |


  Scenario: an existing entity type cannot be converted to abstract if it has existing instances
    Given transaction closes
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x isa person, has name "Jeremy", has email "jeremy@vaticle.com";
      """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    Then typeql schema query; fails
      """
      define person @abstract;
      """


  Scenario: an existing relation type cannot be converted to abstract if it has existing instances
    Given transaction closes
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x isa person, has name "Jeremy", has email "jeremy@vaticle.com";
      $r isa employment, links (employee: $x), has employment-reference-code "J123123";
      """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    Then typeql schema query; fails
      """
      define employment @abstract;
      """


  Scenario: an existing attribute type cannot be converted to abstract if it has existing instances
    Given transaction closes
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x isa person, has name "Jeremy", has email "jeremy@vaticle.com";
      """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    Then typeql schema query; fails
      """
      define name @abstract;
      """

  ######################
  # HIERARCHY MUTATION #
  ######################

  Scenario: an existing entity type cannot be switched to a new supertype through define
    Given typeql schema query
      """
      define
      entity apple-product;
      entity genius sub person;
      """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    Then typeql schema query; fails
      """
      define
      entity genius sub apple-product;
      """


  Scenario: an existing relation type cannot be switched to a new supertype through define
    Given typeql schema query
      """
      define
      relation sabbatical sub employment;
      relation vacation relates employee;
      """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    Then typeql schema query; fails
      """
      define
      relation sabbatical sub vacation;
      """


  Scenario: assigning a supertype without previous supertype succeeds even if they have different attributes + roles, if there are no instances
    Given typeql schema query
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
    When typeql schema query
      """
      define
      entity person sub organism;
      """
    Then transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x sub organism;
      """
    Then uniquely identify answer concepts
      | x              |
      | label:organism |
      | label:person   |
      | label:child    |


  Scenario: assigning a new supertype when having another supertype through define fails without preceding redefine/undefine
    Given typeql schema query
      """
      define
      entity bird;
      entity pigeon sub bird;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert $p isa pigeon;
      """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    Then typeql schema query; fails
      """
      define
      entity animal;
      entity pigeon sub animal;
      """

    Given typeql schema query
      """
      define
      attribute name value string;
      entity bird2 owns name;
      entity pigeon2 sub bird2;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert $p isa pigeon2;
      """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    Then typeql schema query; fails
      """
      define
      entity animal owns name;
      entity pigeon2 sub animal;
      """

    Given typeql schema query
      """
      define
      entity bird3 plays flying:flier;
      entity pigeon3 sub bird3;
      relation flying relates flier;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert $p isa pigeon3;
      """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    Then typeql schema query; fails
      """
      define
      entity animal plays flying:flier;
      entity pigeon3 sub animal;
      """

  Scenario: assigning a supertype while having another supertype through define fails even if there are no instances
    Given typeql schema query
      """
      define
      entity person sub organism;
      entity species owns name, plays species-membership:species;
      relation species-membership relates species, relates member;
      attribute lifespan value double;
      entity organism owns lifespan, plays species-membership:member;
      entity child sub person;
      """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    Then typeql schema query; fails
      """
      define
      entity person sub species;
      """

  ###############################
  # SCHEMA MUTATION INHERITANCE #
  ###############################

  Scenario: when adding a playable role to an existing type, the change is propagated to its subtypes
    Given typeql schema query
      """
      define
      relation employment relates employer;
      entity child sub person;
      entity person plays employment:employer;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x label child, plays $r;
      """
    Then uniquely identify answer concepts
      | x           | r                         |
      | label:child | label:employment:employee |
      | label:child | label:employment:employer |
      | label:child | label:income:earner       |


  Scenario: when adding an attribute ownership to an existing type, the change is propagated to its subtypes
    Given typeql schema query
    """
       define
       entity person owns mobile;
       attribute mobile value long;
       entity child sub person;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x label child, owns $y;
      """
    Then uniquely identify answer concepts
      | x           | y              |
      | label:child | label:name     |
      | label:child | label:mobile   |
      | label:child | label:email    |
      | label:child | label:phone-nr |


  Scenario: when adding a key ownership to an existing type, the change is propagated to its subtypes
    Given typeql schema query
      """
      define
      entity child sub person;
      attribute phone-number value long;
      entity person owns phone-number @key;
      """
    Given transaction commits

    # TODO: Uncomment when "match @..." is implemented
#    Given connection open read transaction for database: typedb
#    When get answers of typeql read query
#      """
#      match $x label child, owns $y @key;
#      """
#    Then uniquely identify answer concepts
#      | x           | y                  |
#      | label:child | label:email        |
#      | label:child | label:phone-number |


  Scenario: when adding a related role to an existing relation type, the change is propagated to all its subtypes
    Given typeql schema query
      """
      define
      relation part-time-employment sub employment;
      relation employment relates employer;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x label part-time-employment, relates $r;
      """
    Then uniquely identify answer concepts
      | x                          | r                         |
      | label:part-time-employment | label:employment:employee |
      | label:part-time-employment | label:employment:employer |

  ####################
  # TRANSACTIONALITY #
  ####################

  Scenario: uncommitted transaction writes are not persisted
    When typeql schema query
      """
      define entity dog;
      """
    Given transaction closes
    Given connection open read transaction for database: typedb
    Then typeql read query; fails with a message containing: "not found"
      """
      match $x label dog;
      """

  ########################
  # CYCLIC SCHEMA GRAPHS #
  ########################

  Scenario: a type cannot be a subtype of itself
    Then typeql schema query; fails
      """
      define dog sub dog;
      """


  Scenario: a cyclic type hierarchy is not allowed
    Then typeql schema query; fails
      """
      define
      entity giant sub person;
      entity green-giant sub giant;
      entity person sub green-giant;
      """


  Scenario: a relation type can relate to a role that it plays itself
    When typeql schema query
      """
      define
      relation recursive-function relates function, plays recursive-function:function;
      """
    Then transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x relates function; $x plays recursive-function:function;
      """
    Then uniquely identify answer concepts
      | x                        |
      | label:recursive-function |


  Scenario: two relation types in a type hierarchy can play each other's roles
    When typeql schema query
      """
      define
      relation apple @abstract, relates role1, plays big-apple:role2;
      relation big-apple sub apple, plays apple:role1, relates role2;
      """


  Scenario: relation types that play roles in their transitive subtypes can be reliably defined

  Variables from a 'define' query are selected for defining in an arbitrary order. When these variables
  depend on each other, creating a dependency graph, they should all define successfully regardless of
  which variable was picked as the start vertex (#131)

    When typeql schema query
      """
      define

      relation apple @abstract, relates source @abstract, plays huge-apple:grows-from;
      relation big-apple @abstract, sub apple;
      relation huge-apple sub big-apple, relates tree as source, relates grows-from;

      relation banana @abstract, relates source @abstract, plays huge-banana:grows-from;
      relation big-banana @abstract, sub banana;
      relation huge-banana sub big-banana, relates tree as source, relates grows-from;

      relation orange @abstract, relates source @abstract, plays huge-orange:grows-from;
      relation big-orange @abstract, sub orange;
      relation huge-orange sub big-orange, relates tree as source, relates grows-from;

      relation pear @abstract, relates source @abstract, plays huge-pear:grows-from;
      relation big-pear @abstract, sub pear;
      relation huge-pear sub big-pear, relates tree as source, relates grows-from;

      relation tomato @abstract, relates source @abstract, plays huge-tomato:grows-from;
      relation big-tomato @abstract, sub tomato;
      relation huge-tomato sub big-tomato, relates tree as source, relates grows-from;

      relation watermelon @abstract, relates source @abstract, plays huge-watermelon:grows-from;
      relation big-watermelon @abstract, sub watermelon;
      relation huge-watermelon sub big-watermelon, relates tree as source, relates grows-from;

      relation lemon @abstract, relates source @abstract, plays huge-lemon:grows-from;
      relation big-lemon @abstract, sub lemon;
      relation huge-lemon sub big-lemon, relates tree as source, relates grows-from;

      relation lime @abstract, relates source @abstract, plays huge-lime:grows-from;
      relation big-lime @abstract, sub lime;
      relation huge-lime sub big-lime, relates tree as source, relates grows-from;

      relation mango @abstract, relates source @abstract, plays huge-mango:grows-from;
      relation big-mango @abstract, sub mango;
      relation huge-mango sub big-mango, relates tree as source, relates grows-from;

      relation pineapple @abstract, relates source @abstract, plays huge-pineapple:grows-from;
      relation big-pineapple @abstract, sub pineapple;
      relation huge-pineapple sub big-pineapple, relates tree as source, relates grows-from;
      """
    Then transaction commits

    # TODO 3.0: Add tests for functions
