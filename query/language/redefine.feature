# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: TypeQL Redefine Query

  Background: Open connection and create a simple extensible schema
    Given typedb starts
    Given connection opens with default authentication
    Given connection is open: true
    Given connection reset database: typedb
    Given connection open schema transaction for database: typedb

    Given typeql schema query
      """
      define
      entity person plays employment:employee, plays income:earner, owns name @card(0..) @regex("^.*$"), owns email @key, owns phone-nr @unique;
      relation employment relates employee @card(1..), plays income:source, owns start-date @card(0..), owns employment-reference-code @key;
      relation income relates earner, relates source;

      entity empty-entity @abstract;
      entity child sub empty-entity;

      relation empty-relation relates empty-role;
      relation part-time-employment sub empty-relation, relates part-time-role;

      attribute name value string;
      attribute email @independent, value string @regex("^.*@.*$") @range("A".."zzzzzzzzzzzzzzzzzzzzzzzzzz");
      attribute start-date value datetime;
      attribute employment-reference-code value string;
      attribute phone-nr value string;
      attribute empty-data @abstract;
      attribute abstract-decimal-data @abstract, value decimal;
      attribute long-data sub empty-data, value long @values(1, 2, 3, 4, 5, 6, 7, 8, 9);
      attribute empty-sub-data @abstract, sub empty-data;
      """
    Given transaction commits

    Given connection open schema transaction for database: typedb


  ################
  # ENTITY TYPES #
  ################

  Scenario: entity types cannot be redefined
    Then typeql schema query; parsing fails
      """
      redefine entity person;
      """


  Scenario: redefine parsing fails if multiple statements for entity type
    Then typeql schema query; parsing fails
      """
      redefine entity person plays employment:employee, plays income:earner, owns name @card(0..) @regex("^.*$"), owns email @key, owns phone-nr @unique;
      """

    Given connection open schema transaction for database: typedb
    Then typeql schema query; parsing fails
      """
      redefine entity person owns phone-nr @unique, owns name @regex("^.*$") @card(0..), plays income:earner, owns email @key, plays employment:employee;
      """

    Given connection open schema transaction for database: typedb
    Then typeql schema query; parsing fails
      """
      redefine entity person owns phone-nr @unique, owns name @regex("^.*$");
      """


  Scenario: redefine fails if nothing is redefined for entity type
    Then typeql schema query; fails
      """
      redefine entity person plays employment:employee;
      """
    Given transaction closes

    Given connection open schema transaction for database: typedb
    Then typeql schema query; fails
      """
      redefine entity person owns name @regex("^.*$") @card(0..);
      """
    Given transaction closes

    Given connection open schema transaction for database: typedb
    Then typeql schema query; fails
      """
      redefine entity person plays income:earner;
      """
    Given transaction closes

    Given connection open schema transaction for database: typedb
    Then typeql schema query; fails
      """
      redefine entity child sub empty-entity;
      """


  Scenario: can redefine entity type's sub
    When typeql schema query
      """
      redefine entity child sub person;
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


  Scenario: a redefined entity subtype inherits playable roles from its parent type
    When get answers of typeql read query
      """
      match $x plays employment:employee;
      """
    Then uniquely identify answer concepts
      | x            |
      | label:person |

    When typeql schema query
      """
      redefine entity child sub person;
      """
    When transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x plays employment:employee;
      """
    Then uniquely identify answer concepts
      | x            |
      | label:person |
      | label:child  |


  Scenario: a redefined entity subtype inherits attribute ownerships from its parent type
    Given typeql schema query
      """
      redefine entity child sub person;
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


  Scenario: cannot redefine entity types' relates
    Then typeql schema query; fails
      """
      redefine entity child relates employee;
      """
    Given transaction closes

    Given connection open schema transaction for database: typedb
    Then typeql schema query; fails
      """
      redefine entity child relates employee[];
      """


  Scenario: can redefine entity type's owns ordering
    Then typeql schema query; fails
      """
      define entity person owns name[];
      """
    Given transaction closes

    When connection open schema transaction for database: typedb
    When typeql schema query
      """
      redefine entity person owns name[];
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x owns name[];
      """
    Then uniquely identify answer concepts
      | x            |
      | label:person |
    When transaction closes

    When connection open schema transaction for database: typedb
    When typeql schema query
      """
      redefine entity person owns name;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x owns name;
      """
    Then uniquely identify answer concepts
      | x            |
      | label:person |


  Scenario: cannot redefine entity type's owns both ordering and annotation
    When typeql schema query; fails
      """
      redefine entity person owns name[] @card(0..1);
      """


  Scenario: redefining an entity type without a kind is acceptable
    When typeql schema query
      """
      define entity flying-spaghetti-monster owns name @regex("Spaghett.*");
      """
    Then typeql schema query
      """
      redefine flying-spaghetti-monster owns name @regex("Mr. Spaghett.*");
      """
    Then transaction commits


  Scenario: defining an entity type with a kind is acceptable
    When typeql schema query
      """
      define entity flying-spaghetti-monster owns name @regex("Spaghett.*");
      """
    Then typeql schema query
      """
      redefine entity flying-spaghetti-monster owns name @regex("Mr. Spaghett.*");
      """
    Then transaction commits


  Scenario: an entity type can not have a value type redefined
    Then typeql schema query; fails
      """
      redefine entity person value double;
      """


  Scenario: redefining a thing with 'isa' is not possible in a 'redefine' query
    Then typeql schema query; parsing fails
      """
      redefine $p isa person;
      """


  Scenario: adding an attribute instance to a thing is not possible in a 'redefine' query
    Then typeql schema query; parsing fails
      """
      redefine $p has name "Loch Ness Monster";
      """


  Scenario: writing an entity variable in a 'redefine' is not allowed
    Then typeql schema query; parsing fails
      """
      redefine entity $x;
      """


  ##################
  # RELATION TYPES #
  ##################

  Scenario: relation types cannot be redefined
    Then typeql schema query; parsing fails
      """
      redefine relation employment;
      """


  Scenario: redefine parsing fails if multiple statements for relation type
    Then typeql schema query; parsing fails
      """
      redefine relation employment relates employee @card(1..), plays income:source, owns start-date @card(0..), owns employment-reference-code @key;
      """

    Given connection open schema transaction for database: typedb
    Then typeql schema query; parsing fails
      """
      redefine relation employment plays income:source, relates employee @card(1..), owns employment-reference-code @key, owns start-date @card(0..);
      """

    Given connection open schema transaction for database: typedb
    Then typeql schema query; parsing fails
      """
      redefine relation part-time-employment sub empty-relation, relates part-time-role;
      """

    Given connection open schema transaction for database: typedb
    Then typeql schema query; parsing fails
      """
      redefine relation part-time-employment relates part-time-role, sub empty-relation;
      """


  Scenario: redefine fails if nothing is redefined for relation type
    Then typeql schema query; fails
      """
      redefine relation employment relates employee @card(1..);
      """
    Given transaction closes

    Given connection open schema transaction for database: typedb
    Then typeql schema query; fails
      """
      redefine relation employment plays income:source;
      """
    Given transaction closes

    Given connection open schema transaction for database: typedb
    Then typeql schema query; fails
      """
      redefine relation part-time-employment sub empty-relation;
      """
    Given transaction closes

    Given connection open schema transaction for database: typedb
    Then typeql schema query; fails
      """
      redefine relation part-time-employment relates part-time-role;
      """


  Scenario: can redefine relation type's sub
    When typeql schema query
      """
      redefine relation part-time-employment sub employment;
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


  Scenario: a redefined relation subtype inherits roles from its supertype
    When get answers of typeql read query
      """
      match $x relates employee;
      """
    Then uniquely identify answer concepts
      | x                |
      | label:employment |

    When typeql schema query
      """
      redefine relation part-time-employment sub employment;
      """
    When transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x relates employee;
      """
    Then uniquely identify answer concepts
      | x                          |
      | label:employment           |
      | label:part-time-employment |


  Scenario: a redefined relation subtype inherits attribute ownerships from its parent type
    Given typeql schema query
      """
      redefine relation part-time-employment sub employment;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x owns start-date;
      """
    Then uniquely identify answer concepts
      | x                          |
      | label:employment           |
      | label:part-time-employment |


  Scenario: can redefine relation type's relates ordering
    Then typeql schema query; fails
      """
      define relation employment relates employee[];
      """
    Given transaction closes

    When connection open schema transaction for database: typedb
    When typeql schema query
      """
      redefine relation employment relates employee[];
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x relates employee[];
      """
    Then uniquely identify answer concepts
      | x                |
      | label:employment |
    When transaction closes

    When connection open schema transaction for database: typedb
    When typeql schema query
      """
      redefine relation employment relates employee;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x relates employee;
      """
    Then uniquely identify answer concepts
      | x                |
      | label:employment |


  Scenario: cannot redefine relation type's relates both ordering and annotation
    When typeql schema query; fails
      """
      redefine employment relates employee[] @card(1..5);
      """


  Scenario: can redefine relation type's owns ordering
    Then typeql schema query; fails
      """
      define relation employment owns start-date[];
      """
    Given transaction closes

    When connection open schema transaction for database: typedb
    When typeql schema query
      """
      redefine relation employment owns start-date[];
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x owns start-date[];
      """
    Then uniquely identify answer concepts
      | x                |
      | label:employment |
    When transaction closes

    When connection open schema transaction for database: typedb
    When typeql schema query
      """
      redefine relation employment owns start-date;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x owns start-date;
      """
    Then uniquely identify answer concepts
      | x                |
      | label:employment |


  Scenario: cannot redefine relation type's owns both ordering and annotation
    When typeql schema query; fails
      """
      redefine employment owns start-date[] @card(0..1);
      """


  Scenario: redefining a relation type without a kind is acceptable
    When typeql schema query
      """
      define relation family relates children @card(0..5);
      """
    Then typeql schema query
      """
      redefine family relates children @card(0..);
      """
    Then transaction commits


  Scenario: defining a relation type with a kind is acceptable
    When typeql schema query
      """
      define relation family relates children @card(0..5);
      """
    Then typeql schema query
      """
      redefine relation family relates children @card(0..);
      """
    Then transaction commits


  Scenario: writing a relation variable in a 'redefine' is not allowed
    Then typeql schema query; parsing fails
      """
      redefine relation $x;
      """


  ###################
  # ATTRIBUTE TYPES #
  ###################

  Scenario: attribute types cannot be redefined
    Then typeql schema query; parsing fails
      """
      redefine attribute name;
      """


  Scenario: redefine parsing fails if multiple statements for attribute type
    Then typeql schema query; parsing fails
      """
      redefine attribute email @independent, value string @regex("^.*@.*$") @range("A".."zzzzzzzzzzzzzzzzzzzzzzzzzz");
      """

    Given connection open schema transaction for database: typedb
    Then typeql schema query; parsing fails
      """
      redefine
      attribute email @independent, value string @range("A".."zzzzzzzzzzzzzzzzzzzzzzzzzz") @regex("^.*@.*$");
      """


  Scenario: redefine fails if nothing is redefined for attribute type
    Then typeql schema query; fails
      """
      redefine attribute email @independent;
      """
    Given transaction closes

    Given connection open schema transaction for database: typedb
    Then typeql schema query; fails
      """
      redefine
      attribute email value string @range("A".."zzzzzzzzzzzzzzzzzzzzzzzzzz") @regex("^.*@.*$");
      """
    Given transaction closes

    Given connection open schema transaction for database: typedb
    Then typeql schema query; fails
      """
      redefine
      attribute email value string @regex("^.*@.*$") @range("A".."zzzzzzzzzzzzzzzzzzzzzzzzzz");
      """


  Scenario Outline: attribute types' value type can be redefined from '<value-type-1>' to '<value-type-2>'
    Given typeql schema query
      """
      define attribute <label> value <value-type-1>;
      """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      redefine attribute <label> value <value-type-2>;
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
      | value-type-1 | value-type-2 | label              |
      | date         | long         | number-of-cows     |
      | decimal      | string       | favourite-food     |
      | duration     | boolean      | can-fly            |
      | datetime-tz  | double       | density            |
      | double       | decimal      | savings            |
      | datetime     | date         | flight-date        |
      | long         | datetime     | flight-time        |
      | boolean      | datetime-tz  | flight-time-tz     |
      | string       | duration     | procedure-duration |


  Scenario: an attribute type can be redefined as a subtype of an abstract attribute type
    When typeql schema query
      """
        define attribute data @abstract;
      """
    When typeql schema query
      """
      redefine attribute long-data sub data;
      """
    Then transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x sub data;
      """
    Then uniquely identify answer concepts
      | x               |
      | label:data      |
      | label:long-data |


  Scenario: a redefined attribute subtype inherits the value type of its parent
    When typeql schema query
      """
      redefine empty-sub-data sub abstract-decimal-data;
      """
    Then transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x label empty-sub-data, value decimal;
      """
    Then uniquely identify answer concepts
      | x                    |
      | label:empty-sub-data |


  Scenario: redefining an attribute subtype throws if it is given a different value type to what its parent has
    Then typeql schema query; fails
      """
      redefine attribute long-data sub abstract-decimal-data;
      """


  Scenario: redefining an attribute type without a kind is acceptable
    When typeql schema query
      """
      define attribute id value string;
      """
    Then typeql schema query
      """
      redefine attribute id value long;
      """
    Then transaction commits


  Scenario: defining an attribute type with a kind is acceptable
    When typeql schema query
      """
      define attribute id value string;
      """
    Then typeql schema query
      """
      redefine id value long;
      """
    Then transaction commits


  Scenario: writing an attribute variable in a 'redefine' is not allowed
    Then typeql schema query; parsing fails
      """
      redefine attribute $x;
      """


  Scenario: the value type of an existing attribute type is modifiable through redefine
    Then typeql schema query
      """
      redefine phone-nr value long;
      """
    Then transaction commits
    Given connection open schema transaction for database: typedb
    Then typeql schema query
      """
      redefine attribute phone-nr value string;
      """
    Then transaction commits


  ###############
  # ANNOTATIONS #
  ###############

  Scenario Outline: cannot redefine annotation @<annotation> for entity types
    When typeql schema query
      """
      define entity player;
      """
    When transaction commits

    Given connection open schema transaction for database: typedb
    Then typeql schema query<define-fail>
      """
      define
      entity player @<annotation>;
      """
    When transaction <define-tx-action>

    Given connection open schema transaction for database: typedb
    Then typeql schema query<redefine-fail>
      """
      redefine
      entity player @<annotation-2>;
      """
    Examples:
      | annotation       | annotation-2     | define-fail | redefine-fail | define-tx-action |
      | abstract         | abstract         |             | ; fails       | commits          |
      | distinct         | distinct         | ; fails     | ; fails       | closes           |
      | independent      | independent      | ; fails     | ; fails       | closes           |
      | unique           | unique           | ; fails     | ; fails       | closes           |
      | key              | key              | ; fails     | ; fails       | closes           |
#      | cascade          | cascade          | ; fails     | ; fails       | closes           | # TODO: Cascade is temporarily turned off
      | card(1..1)       | card(1..1)       | ; fails     | ; fails       | closes           |
      | card(1..1)       | card(0..1)       | ; fails     | ; fails       | closes           |
      | regex("val")     | regex("val")     | ; fails     | ; fails       | closes           |
      | regex("val")     | regex("lav")     | ; fails     | ; fails       | closes           |
      | range("1".."2")  | range("1".."2")  | ; fails     | ; fails       | closes           |
      | range("1".."2")  | range("0".."2")  | ; fails     | ; fails       | closes           |
      | values("1", "2") | values("1", "2") | ; fails     | ; fails       | closes           |
      | values("1", "2") | values("0", "2") | ; fails     | ; fails       | closes           |


  Scenario Outline: cannot redefine annotation @<annotation> for relation types
    When typeql schema query
      """
      define
      relation parentship relates parent;
      """
    When transaction commits

    Given connection open schema transaction for database: typedb
    When typeql schema query<define-fail>
      """
      define
      relation parentship @<annotation>;
      """
    When transaction <define-tx-action>

    Given connection open schema transaction for database: typedb
    Then typeql schema query<redefine-fail>
      """
      redefine
      relation parentship @<annotation-2>;
      """
    Examples:
      | annotation       | annotation-2     | define-fail | redefine-fail | define-tx-action |
      | abstract         | abstract         |             | ; fails       | commits          |
#      | cascade          | cascade          |             | ; fails       | commits          | # TODO: Cascade is temporarily turned off
      | distinct         | distinct         | ; fails     | ; fails       | closes           |
      | independent      | independent      | ; fails     | ; fails       | closes           |
      | unique           | unique           | ; fails     | ; fails       | closes           |
      | key              | key              | ; fails     | ; fails       | closes           |
      | card(1..1)       | card(1..1)       | ; fails     | ; fails       | closes           |
      | card(1..1)       | card(0..1)       | ; fails     | ; fails       | closes           |
      | regex("val")     | regex("val")     | ; fails     | ; fails       | closes           |
      | regex("val")     | regex("lav")     | ; fails     | ; fails       | closes           |
      | range("1".."2")  | range("1".."2")  | ; fails     | ; fails       | closes           |
      | range("1".."2")  | range("0".."2")  | ; fails     | ; fails       | closes           |
      | values("1", "2") | values("1", "2") | ; fails     | ; fails       | closes           |
      | values("1", "2") | values("0", "2") | ; fails     | ; fails       | closes           |


  Scenario Outline: can redefine annotation @<annotation> for attribute types
    When typeql schema query
      """
      define
      attribute description value string;
      """
    When transaction commits

    Given connection open schema transaction for database: typedb
    Then typeql schema query<define-fail>
      """
      define
      attribute description @<annotation>;
      """
    When transaction <define-tx-action>

    Given connection open schema transaction for database: typedb
    Then typeql schema query<redefine-fail>
      """
      redefine
      attribute description @<annotation-2>;
      """
    Then transaction commits
    Examples:
      | annotation       | annotation-2     | define-fail | redefine-fail | define-tx-action |
      | abstract         | abstract         |             | ; fails       | commits          |
      | independent      | independent      |             | ; fails       | commits          |
      | distinct         | distinct         | ; fails     | ; fails       | closes           |
      | unique           | unique           | ; fails     | ; fails       | closes           |
      | key              | key              | ; fails     | ; fails       | closes           |
#      | cascade          | cascade          | ; fails     | ; fails       | closes           |  # TODO: Cascade is temporarily turned off
      | card(1..1)       | card(1..1)       | ; fails     | ; fails       | closes           |
      | card(1..1)       | card(0..1)       | ; fails     | ; fails       | closes           |
      | regex("val")     | regex("val")     | ; fails     | ; fails       | closes           |
      | regex("val")     | regex("lav")     | ; fails     | ; fails       | closes           |
      | range("1".."2")  | range("1".."2")  | ; fails     | ; fails       | closes           |
      | range("1".."2")  | range("0".."2")  | ; fails     | ; fails       | closes           |
      | values("1", "2") | values("1", "2") | ; fails     | ; fails       | closes           |
      | values("1", "2") | values("0", "2") | ; fails     | ; fails       | closes           |


  Scenario Outline: cannot redefine annotation @<annotation> for relates/role types
    When typeql schema query
      """
      define
      relation parentship @abstract, relates parent;
      """
    When transaction commits

    Given connection open schema transaction for database: typedb
    Then typeql schema query<define-fail>
      """
      define
      relation parentship @abstract, relates parent @<annotation>;
      """
    When transaction <define-tx-action>

    Given connection open schema transaction for database: typedb
    Then typeql schema query<redefine-fail>
      """
      redefine
      relation parentship relates parent @<annotation-2>;
      """
    Then transaction commits
    Examples:
      | annotation       | annotation-2     | define-fail | redefine-fail | define-tx-action |
      | abstract         | abstract         |             | ; fails       | commits          |
      | card(1..1)       | card(1..1)       |             | ; fails       | commits          |
      | independent      | independent      | ; fails     | ; fails       | closes           |
      | distinct         | distinct         | ; fails     | ; fails       | closes           |
      | unique           | unique           | ; fails     | ; fails       | closes           |
      | key              | key              | ; fails     | ; fails       | closes           |
#      | cascade          | cascade          | ; fails     | ; fails       | closes           | # TODO: Cascade is temporarily turned off
      | regex("val")     | regex("val")     | ; fails     | ; fails       | closes           |
      | regex("val")     | regex("lav")     | ; fails     | ; fails       | closes           |
      | range("1".."2")  | range("1".."2")  | ; fails     | ; fails       | closes           |
      | range("1".."2")  | range("0".."2")  | ; fails     | ; fails       | closes           |
      | values("1", "2") | values("1", "2") | ; fails     | ; fails       | closes           |
      | values("1", "2") | values("0", "2") | ; fails     | ; fails       | closes           |


  Scenario Outline: can redefine annotation @<annotation> for relates/role types
    Then typeql schema query
      """
      define
      relation parentship @abstract, relates parent @<annotation>;
      """
    When transaction commits

    Given connection open schema transaction for database: typedb
    Then typeql schema query
      """
      redefine
      relation parentship relates parent @<annotation-2>;
      """
    Then transaction commits
    Examples:
      | annotation | annotation-2 |
      | card(1..1) | card(0..1)   |


  Scenario Outline: cannot redefine annotation @<annotation> to relates/role types lists
    When typeql schema query
      """
      define
      relation parentship @abstract, relates parent[];
      """
    When transaction commits

    Given connection open schema transaction for database: typedb
    Then typeql schema query<define-fail>
      """
      define
      relation parentship @abstract, relates parent[] @<annotation>;
      """
    When transaction <define-tx-action>

    Given connection open schema transaction for database: typedb
    Then typeql schema query<redefine-fail>
      """
      redefine
      relation parentship relates parent[] @<annotation-2>;
      """
    Then transaction commits
    Examples:
      | annotation       | annotation-2     | define-fail | redefine-fail | define-tx-action |
      | abstract         | abstract         |             | ; fails       | commits          |
      | card(1..1)       | card(1..1)       |             | ; fails       | commits          |
      | distinct         | distinct         |             | ; fails       | commits          |
      | independent      | independent      | ; fails     | ; fails       | closes           |
      | unique           | unique           | ; fails     | ; fails       | closes           |
      | key              | key              | ; fails     | ; fails       | closes           |
#      | cascade          | cascade          | ; fails     | ; fails       | closes           | # TODO: Cascade is temporarily turned off
      | regex("val")     | regex("val")     | ; fails     | ; fails       | closes           |
      | regex("val")     | regex("lav")     | ; fails     | ; fails       | closes           |
      | range("1".."2")  | range("1".."2")  | ; fails     | ; fails       | closes           |
      | range("1".."2")  | range("0".."2")  | ; fails     | ; fails       | closes           |
      | values("1", "2") | values("1", "2") | ; fails     | ; fails       | closes           |
      | values("1", "2") | values("0", "2") | ; fails     | ; fails       | closes           |


  Scenario Outline: can redefine annotation @<annotation> for relates/role types lists
    Then typeql schema query
      """
      define
      relation parentship @abstract, relates parent[] @<annotation>;
      """
    When transaction commits

    Given connection open schema transaction for database: typedb
    Then typeql schema query
      """
      redefine
      relation parentship relates parent[] @<annotation-2>;
      """
    Then transaction commits
    Examples:
      | annotation | annotation-2 |
      | card(1..1) | card(0..1)   |


  Scenario Outline: cannot redefine annotation @<annotation> for owns
    When typeql schema query
      """
      define
      entity player owns name;
      """
    When transaction commits

    Given connection open schema transaction for database: typedb
    Then typeql schema query<define-fail>
      """
      define
      entity player owns name @<annotation>;
      """
    When transaction <define-tx-action>

    Given connection open schema transaction for database: typedb
    Then typeql schema query<redefine-fail>
      """
      redefine
      entity player owns name @<annotation-2>;
      """
    Then transaction commits
    Examples:
      | annotation       | annotation-2     | define-fail | redefine-fail | define-tx-action |
      | unique           | unique           |             | ; fails       | commits          |
      | key              | key              |             | ; fails       | commits          |
      | card(1..1)       | card(1..1)       |             | ; fails       | commits          |
      | regex("val")     | regex("val")     |             | ; fails       | commits          |
      | range("1".."2")  | range("1".."2")  |             | ; fails       | commits          |
      | values("1", "2") | values("1", "2") |             | ; fails       | commits          |
      | abstract         | abstract         | ; fails     | ; fails       | closes           |
      | independent      | independent      | ; fails     | ; fails       | closes           |
      | distinct         | distinct         | ; fails     | ; fails       | closes           |
#      | cascade          | cascade          | ; fails     | ; fails       | closes           | # TODO: Cascade is temporarily turned off


  Scenario Outline: can redefine annotation @<annotation> for owns
    Then typeql schema query
      """
      define
      entity player owns name @<annotation>;
      """
    When transaction commits

    Given connection open schema transaction for database: typedb
    Then typeql schema query
      """
      redefine
      entity player owns name @<annotation-2>;
      """
    Then transaction commits
    Examples:
      | annotation       | annotation-2     |
      | card(1..1)       | card(0..1)       |
      | regex("val")     | regex("lav")     |
      | range("1".."2")  | range("0".."2")  |
      | values("1", "2") | values("0", "2") |


  Scenario Outline: cannot redefine annotation @<annotation> for owns lists
    When typeql schema query
      """
      define
      entity player owns name[];
      """
    When transaction commits

    Given connection open schema transaction for database: typedb
    Then typeql schema query<define-fail>
      """
      define
      entity player owns name[] @<annotation>;
      """
    When transaction <define-tx-action>

    Given connection open schema transaction for database: typedb
    Then typeql schema query<redefine-fail>
      """
      redefine
      entity player owns name[] @<annotation-2>;
      """
    Then transaction commits
    Examples:
      | annotation       | annotation-2     | define-fail | redefine-fail | define-tx-action |
      | unique           | unique           |             | ; fails       | commits          |
      | key              | key              |             | ; fails       | commits          |
      | distinct         | distinct         |             | ; fails       | commits          |
      | card(1..1)       | card(1..1)       |             | ; fails       | commits          |
      | regex("val")     | regex("val")     |             | ; fails       | commits          |
      | range("1".."2")  | range("1".."2")  |             | ; fails       | commits          |
      | values("1", "2") | values("1", "2") |             | ; fails       | commits          |
      | abstract         | abstract         | ; fails     | ; fails       | closes           |
      | independent      | independent      | ; fails     | ; fails       | closes           |
#      | cascade          | cascade          | ; fails     | ; fails       | closes           | # TODO: Cascade is temporarily turned off


  Scenario Outline: can redefine annotation @<annotation> for owns lists
    Then typeql schema query
      """
      define
      entity player owns name[] @<annotation>;
      """
    When transaction commits

    Given connection open schema transaction for database: typedb
    Then typeql schema query
      """
      redefine
      entity player owns name[] @<annotation-2>;
      """
    Then transaction commits
    Examples:
      | annotation       | annotation-2     |
      | card(1..1)       | card(0..1)       |
      | regex("val")     | regex("lav")     |
      | range("1".."2")  | range("0".."2")  |
      | values("1", "2") | values("0", "2") |


  Scenario Outline: cannot redefine annotation @<annotation> for plays
    When typeql schema query
      """
      define
      entity player plays employment:employee;
      """
    When transaction commits

    Given connection open schema transaction for database: typedb
    Then typeql schema query<define-fail>
      """
      define
      entity player plays employment:employee @<annotation>;
      """
    When transaction <define-tx-action>

    Given connection open schema transaction for database: typedb
    Then typeql schema query<redefine-fail>
      """
      redefine
      entity player plays employment:employee @<annotation-2>;
      """
    Then transaction commits
    Examples:
      | annotation       | annotation-2     | define-fail | redefine-fail | define-tx-action |
      | card(1..1)       | card(1..1)       |             | ; fails       | commits          |
      | abstract         | abstract         | ; fails     | ; fails       | closes           |
      | independent      | independent      | ; fails     | ; fails       | closes           |
      | distinct         | distinct         | ; fails     | ; fails       | closes           |
      | unique           | unique           | ; fails     | ; fails       | closes           |
      | key              | key              | ; fails     | ; fails       | closes           |
#      | cascade          | cascade          | ; fails     | ; fails       | closes           | # TODO: Cascade is temporarily turned off
      | regex("val")     | regex("val")     | ; fails     | ; fails       | closes           |
      | regex("val")     | regex("lav")     | ; fails     | ; fails       | closes           |
      | range("1".."2")  | range("1".."2")  | ; fails     | ; fails       | closes           |
      | range("1".."2")  | range("0".."2")  | ; fails     | ; fails       | closes           |
      | values("1", "2") | values("1", "2") | ; fails     | ; fails       | closes           |
      | values("1", "2") | values("0", "2") | ; fails     | ; fails       | closes           |


  Scenario Outline: can redefine annotation @<annotation> for plays
    Then typeql schema query
      """
      define
      entity player plays employment:employee @<annotation>;
      """
    When transaction commits

    Given connection open schema transaction for database: typedb
    Then typeql schema query
      """
      redefine
      entity player plays employment:employee @<annotation-2>;
      """
    Then transaction commits
    Examples:
      | annotation | annotation-2 |
      | card(1..1) | card(0..1)   |


  Scenario Outline: cannot redefine annotation @<annotation> for value types
    When typeql schema query
      """
      define
      attribute description value string;
      """
    When transaction commits

    Given connection open schema transaction for database: typedb
    Then typeql schema query<define-fail>
      """
      define
      attribute description value string @<annotation>;
      """
    When transaction <define-tx-action>

    Given connection open schema transaction for database: typedb
    Then typeql schema query<redefine-fail>
      """
      redefine
      attribute description value string @<annotation-2>;
      """
    Then transaction commits
    Examples:
      | annotation       | annotation-2     | define-fail | redefine-fail | define-tx-action |
      | regex("val")     | regex("val")     |             | ; fails       | commits          |
      | range("1".."2")  | range("1".."2")  |             | ; fails       | commits          |
      | values("1", "2") | values("1", "2") |             | ; fails       | commits          |
      | unique           | unique           | ; fails     | ; fails       | closes           |
      | key              | key              | ; fails     | ; fails       | closes           |
      | abstract         | abstract         | ; fails     | ; fails       | closes           |
      | independent      | independent      | ; fails     | ; fails       | closes           |
      | distinct         | distinct         | ; fails     | ; fails       | closes           |
#      | cascade          | cascade          | ; fails     | ; fails       | closes           | # TODO: Cascade is temporarily turned off
      | card(1..1)       | card(1..1)       | ; fails     | ; fails       | closes           |
      | card(1..1)       | card(0..1)       | ; fails     | ; fails       | closes           |


  Scenario Outline: can redefine annotation @<annotation> for value types
    Then typeql schema query
      """
      define
      attribute description value string @<annotation>;
      """
    When transaction commits

    Given connection open schema transaction for database: typedb
    Then typeql schema query
      """
      redefine
      attribute description value string @<annotation-2>;
      """
    Then transaction commits
    Examples:
      | annotation       | annotation-2     |
      | regex("val")     | regex("lav")     |
      | range("1".."2")  | range("0".."2")  |
      | values("1", "2") | values("0", "2") |


  Scenario: cannot redefine multiple annotations in one query
    Then typeql schema query; fails
      """
      redefine entity person owns name @card(0..1) @regex("^[a-zA-Z]+$");
      """
    When transaction closes

    When connection open schema transaction for database: typedb
    Then typeql schema query
      """
      redefine entity person owns name @regex("^[a-zA-Z]+$");
      """
    Then typeql schema query
      """
      redefine entity person owns name @card(0..1);
      """
    Then transaction commits


  ######################
  # HIERARCHY MUTATION #
  ######################

  Scenario: an existing entity type can be switched to a new supertype
    Given typeql schema query
      """
      define
      entity apple-product;
      entity genius sub person;
      """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    When typeql schema query
      """
      redefine
      entity genius sub apple-product;
      """
    Then transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x sub apple-product;
      """
    Then uniquely identify answer concepts
      | x                   |
      | label:apple-product |
      | label:genius        |


  Scenario: an existing relation type can be switched to a new supertype
    Given typeql schema query
      """
      define
      relation sabbatical sub employment;
      relation vacation relates employee;
      """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    When typeql schema query
      """
      redefine
      relation sabbatical sub vacation;
      """
    Then transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x sub vacation;
      """
    Then uniquely identify answer concepts
      | x                |
      | label:vacation   |
      | label:sabbatical |


  Scenario: assigning a supertype while having another supertype succeeds even if they have different attributes + roles, if there are no instances
    Given typeql schema query
      """
      define
      entity creature sub species;
      entity species owns name, plays species-membership:species;
      relation species-membership relates species, relates member;
      attribute lifespan value double;
      entity organism owns lifespan, plays species-membership:member;
      entity human sub person;
      """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    When typeql schema query
      """
      redefine
      entity creature sub organism;
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
      | label:creature |
      | label:human    |


  Scenario: assigning a new supertype when having other sub succeeds even with existing data if the supertypes have no properties
    Given typeql schema query
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
    When typeql schema query
      """
      define
      entity animal;
      """
    When typeql schema query
      """
      redefine
      entity pigeon sub animal;
      """
    Then transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x sub pigeon;
      """
    Then uniquely identify answer concepts
      | x            |
      | label:pigeon |


  Scenario: assigning a new supertype when having other sub succeeds with existing data if the supertypes play the same roles
    Given typeql schema query
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
    When typeql schema query
      """
      define
      entity animal plays flying:flier;
      """
    When typeql schema query
      """
      redefine
      entity pigeon sub animal;
      """
    Then transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x sub pigeon;
      """
    Then uniquely identify answer concepts
      | x            |
      | label:pigeon |


  Scenario: assigning a new supertype when having other sub succeeds with existing data if the supertypes have the same attributes
    Given typeql schema query
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
    When typeql schema query
      """
      define
      entity animal owns name;
      """
    Then transaction commits

    Given connection open schema transaction for database: typedb
    When typeql schema query
      """
      redefine
      entity pigeon sub animal;
      """
    Then transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x sub pigeon;
      """
    Then uniquely identify answer concepts
      | x            |
      | label:pigeon |


    # TODO 3.0: Add tests for structs
    # TODO 3.0: Add tests for functions?
