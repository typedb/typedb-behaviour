# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: TypeQL Undefine Query

  Background: Open connection and create a simple extensible schema
    Given typedb starts
    Given connection opens with default authentication
    Given connection is open: true
    Given connection reset database: typedb
    Given connection open schema transaction for database: typedb

    Given typeql schema query
      """
      define
      entity person, plays employment:employee, owns name, owns email @key;
      relation employment, relates employee, relates employer;
      attribute name @independent, value string;
      attribute email @independent, value string @regex(".+@\w+\..+");
      entity abstract-type @abstract;
      attribute root-attribute @abstract;
      """
    Given transaction commits

    Given connection open schema transaction for database: typedb


  ###########
  # PARSING #
  ###########

  Scenario: cannot use untargeted define-like syntax in undefine
    Then typeql schema query; parsing fails
      """
      undefine entity person;
      """

    When connection open schema transaction for database: typedb
    Then typeql schema query; parsing fails
      """
      undefine person plays employment:employee;
      """

    When connection open schema transaction for database: typedb
    Then typeql schema query; parsing fails
      """
      undefine person owns name;
      """

    When connection open schema transaction for database: typedb
    Then typeql schema query; parsing fails
      """
      undefine person, owns name;
      """

    When connection open schema transaction for database: typedb
    Then typeql schema query; parsing fails
      """
      undefine person owns email @key;
      """

    When connection open schema transaction for database: typedb
    Then typeql schema query; parsing fails
      """
      undefine name @independent;
      """

    When connection open schema transaction for database: typedb
    Then typeql schema query; parsing fails
      """
      undefine name value string;
      """

    When connection open schema transaction for database: typedb
    Then typeql schema query; parsing fails
      """
      undefine name value string;
      """

    When connection open schema transaction for database: typedb
    Then typeql schema query; parsing fails
      """
      undefine name value string @regex(".+@\w+\..+");
      """

  ################
  # ENTITY TYPES #
  ################

  Scenario: calling 'undefine' with entity on an entity deletes it
    Given get answers of typeql read query
      """
      match entity $x;
      """
    Given uniquely identify answer concepts
      | x                   |
      | label:abstract-type |
      | label:person        |
    When typeql schema query
      """
      undefine person;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match entity $x;
      """
    Then uniquely identify answer concepts
      | x                   |
      | label:abstract-type |


  Scenario: undefining non-existing entity type sub errors
    Then typeql schema query; fails with a message containing: "there is no defined 'person sub abstract-type'"
      """
      undefine sub abstract-type from person;
      """
    When transaction closes

    When connection open schema transaction for database: typedb
    When typeql schema query
      """
      define
      person sub superperson;
      entity superperson @abstract;
      """
    Then typeql schema query; fails with a message containing: "there is no defined 'person sub abstract-type', while"
      """
      undefine sub abstract-type from person;
      """


  Scenario: a sub-entity type can be removed using 'sub' with its direct supertype, and its parent is preserved
    Given typeql schema query
      """
      define entity child sub person;
      """
    Given transaction commits

    When connection open schema transaction for database: typedb
    Given get answers of typeql read query
      """
      match $x sub person;
      """
    Given uniquely identify answer concepts
      | x            |
      | label:person |
      | label:child  |
    When typeql schema query
      """
      undefine sub person from child;
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


  Scenario: undefining a type 'sub' an indirect supertype should still remove that type
    Given typeql schema query
      """
      define entity child sub person;
      """
    Given transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x sub person;
      """
    Then uniquely identify answer concepts
      | x            |
      | label:person |
      | label:child  |
    When transaction closes

    When connection open schema transaction for database: typedb
    When typeql schema query
      """
      undefine child;
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


  Scenario: undefining a supertype errors if subtypes exist
    Given typeql schema query
      """
      define entity child sub person;
      """
    Given transaction commits

    When connection open schema transaction for database: typedb
    Then typeql schema query; fails
      """
      undefine person;
      """


  Scenario: undefining non-existing entity type plays errors
    Then typeql schema query; fails with a message containing: "there is no defined 'person plays employment:employer'"
      """
      undefine plays employment:employer from person;
      """


  Scenario: removing a playable role from a super entity type also removes it from its subtypes
    Given typeql schema query
      """
      define entity child sub person;
      """
    Given transaction commits

    When connection open schema transaction for database: typedb
    When typeql schema query
      """
      undefine plays employment:employee from person;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    Then typeql read query; fails with a message containing: "empty-set for some variable"
      """
      match $x label child; $x plays employment:employee;
      """


  Scenario: undefining non-existing entity type owns errors
    Then typeql schema query; fails with a message containing: "there is no defined 'person owns root-attribute'"
      """
      undefine owns root-attribute from person;
      """
    When transaction closes

    When connection open schema transaction for database: typedb
    When typeql schema query
      """
      define
      person owns root-attribute;
      """
    Then typeql schema query; fails with a message containing: "there is no defined 'person owns root-attribute[]', while"
      """
      undefine owns root-attribute[] from person;
      """


  Scenario: undefining entity type owns is possible
    Then typeql schema query
      """
      undefine
      owns name from person;
      """
    Then transaction commits

    When connection open schema transaction for database: typedb
    When typeql schema query
      """
      define
      person owns name[];
      """
    When transaction commits


    When connection open schema transaction for database: typedb
    Then typeql schema query
      """
      undefine
      owns name[] from person;
      """
    Then transaction commits


  Scenario: removing an attribute ownership from a super entity type also removes it from its subtypes
    Given typeql schema query
      """
      define entity child sub person;
      """
    Given transaction commits

    When connection open schema transaction for database: typedb
    When typeql schema query
      """
      undefine owns name from person;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    Then typeql read query; fails with a message containing: "empty-set for some variable"
      """
      match $x label child; $x owns name;
      """


  Scenario: removing a key ownership from a super entity type also removes it from its subtypes
    Given typeql schema query
      """
      define entity child sub person;
      """
    Given transaction commits

    When connection open schema transaction for database: typedb
    When typeql schema query
      """
      undefine owns email from person;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    Then typeql read query; fails with a message containing: "empty-set for some variable"
      """
      match $x label child; $x owns email;
      """


  Scenario: all existing instances of an entity type must be deleted in order to undefine it
    Given get answers of typeql read query
      """
      match entity $x;
      """
    Given uniquely identify answer concepts
      | x                   |
      | label:abstract-type |
      | label:person        |
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert $x isa person, has name "Dmitrii", has email "dmitrii@typedb.com";
      """
    Given transaction commits

    When connection open schema transaction for database: typedb
    Then typeql schema query; fails
      """
      undefine person;
      """

    When transaction closes
    When connection open write transaction for database: typedb
    When typeql write query
      """
      match
        $x isa person;
      delete
        $x;
      """
    Then transaction commits

    When connection open schema transaction for database: typedb
    When typeql schema query
      """
      undefine person;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match entity $x;
      """
    Then uniquely identify answer concepts
      | x                   |
      | label:abstract-type |

  ##################
  # RELATION TYPES #
  ##################

  Scenario: undefining a relation type removes it
    Given get answers of typeql read query
      """
      match relation $x;
      """
    Given uniquely identify answer concepts
      | x                |
      | label:employment |
    When typeql schema query
      """
      undefine employment;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    Then typeql read query; fails with a message containing: "empty-set for some variable"
      """
      match relation $x;
      """


  Scenario: undefining non-existing relation type sub errors
    Given typeql schema query
      """
      define relation abstract-relation @abstract, relates abstract-employee @abstract;
      """
    Given transaction commits

    When connection open schema transaction for database: typedb
    Then typeql schema query; fails with a message containing: "there is no defined 'employment sub abstract-relation'"
      """
      undefine sub abstract-relation from employment;
      """
    When transaction closes

    When connection open schema transaction for database: typedb
    When typeql schema query
      """
      define
      employment sub superemployment;
      relation superemployment @abstract, relates superemployee @abstract;
      """
    Then typeql schema query; fails with a message containing: "there is no defined 'employment sub abstract-relation', while"
      """
      undefine sub abstract-relation from employment;
      """


  Scenario: a sub-relation type can be removed using 'sub' with its direct supertype, and its parent is preserved
    Given typeql schema query
      """
      define relation part-time-employment sub employment, relates some-role;
      """
    Given transaction commits

    When connection open schema transaction for database: typedb
    Given get answers of typeql read query
      """
      match $x sub employment;
      """
    Given uniquely identify answer concepts
      | x                          |
      | label:employment           |
      | label:part-time-employment |
    When typeql schema query
      """
      undefine sub employment from part-time-employment;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x sub employment;
      """
    Then uniquely identify answer concepts
      | x                |
      | label:employment |


  Scenario: removing playable roles from a super relation type also removes them from its subtypes
    Given typeql schema query
      """
      define
      relation employment-terms, relates employment;
      employment plays employment-terms:employment;
      relation contract-employment sub employment;
      """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    Given get answers of typeql read query
      """
      match contract-employment plays $x;
      """
    Given uniquely identify answer concepts
      | x                                 |
      | label:employment-terms:employment |
    When typeql schema query
      """
      undefine plays employment-terms:employment from employment;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    Then typeql read query; fails with a message containing: "empty-set for some variable"
      """
      match contract-employment plays $x;
      """

  Scenario: removing attribute ownerships from a super relation type also removes them from its subtypes
    Given typeql schema query
      """
      define
      attribute start-date, value datetime;
      employment owns start-date;
      relation contract-employment sub employment;
      """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    Given get answers of typeql read query
      """
      match $x owns start-date;
      """
    Given uniquely identify answer concepts
      | x                         |
      | label:employment          |
      | label:contract-employment |
    When typeql schema query
      """
      undefine owns start-date from employment;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    Then typeql read query; fails with a message containing: "empty-set for some variable"
      """
      match $x owns start-date;
      """

# TODO: match with annotations (do we really need this test in this file? Only for undefine + match purposes...)
#  Scenario: removing key ownerships from a super relation type also removes them from its subtypes
#    Given typeql schema query
#      """
#      define
#      attribute employment-reference, value string;
#      employment owns employment-reference @key;
#      relation contract-employment sub employment;
#      """
#    Given transaction commits
#
#    Given connection open schema transaction for database: typedb
#    Given get answers of typeql read query
#      """
#      match $x owns employment-reference @key;
#      """
#    Given uniquely identify answer concepts
#      | x                         |
#      | label:employment          |
#      | label:contract-employment |
#    When typeql schema query
#      """
#      undefine employment owns employment-reference;
#      """
#    Then transaction commits
#
#    When connection open read transaction for database: typedb
#    Then typeql read query; fails with a message containing: "empty-set for some variable"
#      """
#      match $x owns employment-reference @key;
#      """


  Scenario: undefining a relation type errors on commit if it has existing instances
    Given transaction closes
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $p isa person, has name "Harald", has email "harald@typedb.com";
      (employee: $p) isa employment;
      """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    Then typeql schema query; fails
      """
      undefine
      relates employee from employment;
      relates employer from employment;
      plays employment:employee from person;
      employment;
      """


  Scenario: undefining non-existing relation type relates errors
    Then typeql schema query; fails with a message containing: "there is no defined 'employment relates mentor'"
      """
      undefine relates mentor from employment;
      """
    When transaction closes

    When connection open schema transaction for database: typedb
    When typeql schema query
      """
      define
      employment relates mentor;
      """
    Then typeql schema query; fails with a message containing: "there is no defined 'employment relates mentor[]', while"
      """
      undefine relates mentor[] from employment;
      """


  Scenario: undefining relates is possible
    Then typeql schema query
      """
      undefine
      relates employee from employment;
      """
    Then transaction commits

    When connection open schema transaction for database: typedb
    When typeql schema query
      """
      define
      employment relates employee[];
      """
    When transaction commits

    When connection open schema transaction for database: typedb
    Then typeql schema query
      """
      undefine
      relates employee[] from employment;
      """
    Then transaction commits


  Scenario: undefining non-existing relation type relates specialise errors
    Given typeql schema query
      """
      define relation part-time-employment sub employment, relates part-time-employee;
      """
    Given transaction commits
    When connection open schema transaction for database: typedb

    Then typeql schema query; fails with a message containing: "there is no defined 'part-time-employment relates part-time-employee as employee'"
      """
      undefine as employee from part-time-employment relates part-time-employee;
      """
    When transaction closes

    When connection open schema transaction for database: typedb
    When typeql schema query
      """
      define
      part-time-employment relates part-time-employee as employee;
      """
    Then typeql schema query; fails with a message containing: "there is no defined 'part-time-employment relates part-time-employee as employer', while"
      """
      undefine as employer from part-time-employment relates part-time-employee;
      """


  Scenario: all existing instances of a relation type must be deleted in order to undefine it
    Given get answers of typeql read query
      """
      match relation $x;
      """
    Given uniquely identify answer concepts
      | x                |
      | label:employment |
    Given transaction closes
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $p isa person, has name "Harald", has email "harald@typedb.com";
      (employee: $p) isa employment;
      """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    Then typeql schema query; fails
      """
      undefine employment;
      """

    When transaction closes
    When connection open schema transaction for database: typedb
    When typeql write query
      """
      match
        $r isa employment;
      delete
        $r;
      """
    Then transaction commits

    When connection open schema transaction for database: typedb
    When typeql schema query
      """
      undefine employment;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    Then typeql read query; fails with a message containing: "empty-set for some variable"
      """
      match relation $x;
      """


  Scenario: undefining a relation type automatically detaches any possible roleplayers
    Given get answers of typeql read query
      """
      match
        $x label person;
        $x plays $y;

      """
    Given uniquely identify answer concepts
      | x            | y                         |
      | label:person | label:employment:employee |
    When typeql schema query
      """
      undefine employment;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    Then typeql read query; fails with a message containing: "empty-set for some variable"
      """
      match
        $x label person;
        $x plays $y;

      """

  ###################
  # ATTRIBUTE TYPES #
  ###################

  Scenario Outline: undefining attribute on an attribute type with value type '<value_type>' removes it
    Given typeql schema query
      """
      define attribute <attr>, value <value_type>;
      """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    Given get answers of typeql read query
      """
      match $x label <attr>;
      """
    Given answer size is: 1
    When typeql schema query
      """
      undefine <attr>;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    Then typeql read query; fails
      """
      match $x label <attr>;
      """
    Examples:
      | value_type | attr       |
      | string     | colour     |
      | integer       | age        |
      | double     | height     |
      | boolean    | is-awake   |
      | datetime   | birth-date |


  Scenario: undefining non-existing attribute type sub errors
    Then typeql schema query; fails with a message containing: "there is no defined 'email sub root-attribute'"
      """
      undefine sub root-attribute from email;
      """
    When transaction closes

    When connection open schema transaction for database: typedb
    When typeql schema query
      """
      define
      email sub superattribute;
      attribute superattribute @abstract;
      """
    Then typeql schema query; fails with a message containing: "there is no defined 'email sub root-attribute', while"
      """
      undefine sub root-attribute from email;
      """


  Scenario: a sub-attribute type can be removed using 'sub' with its direct supertype, and its parent is preserved
    Given typeql schema query
      """
      define attribute surname sub name; name @abstract;
      """
    Given transaction commits

    When connection open schema transaction for database: typedb
    Given get answers of typeql read query
      """
      match $x sub name;
      """
    Given uniquely identify answer concepts
      | x             |
      | label:name    |
      | label:surname |
    When typeql schema query
      """
      define surname value string;
      """
    When typeql schema query
      """
      undefine sub name from surname;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x sub name;
      """
    Then uniquely identify answer concepts
      | x          |
      | label:name |


  Scenario: undefining non-existing attribute type value errors
    Then typeql schema query; fails with a message containing: "there is no defined 'root-attribute value string'"
      """
      undefine value string from root-attribute;
      """
    When transaction closes

    When connection open schema transaction for database: typedb
    Then typeql schema query; fails with a message containing: "there is no defined 'name value datetime-tz', while"
      """
      undefine value datetime-tz from name;
      """


  Scenario: undefining a @regex on an attribute type removes the regex constraints on the attribute
    Then typeql schema query; fails with a message containing: "Illegal annotation"
      """
      undefine @regex from email;
      """

    When typeql schema query
      """
      undefine @regex from email value string;
      """
    Then transaction commits

    When connection open write transaction for database: typedb
    When typeql write query
      """
      insert $x isa email "not-email-regex";
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa email;
      """
    Then answer size is: 1


  Scenario: undefining the value type of an attribute type is possible
    Then typeql schema query; fails with a message containing: "defined 'value' is 'string'"
      """
      undefine value integer from name;
      """

    Then typeql schema query; fails with a message containing: "should be abstract"
      """
      undefine value string from name;
      """

    When typeql schema query
    """
    define name @abstract;
    """
    Then typeql schema query
      """
      undefine value string from name;
      """


  Scenario: all existing instances of an attribute type must be deleted in order to undefine it
    Given get answers of typeql read query
      """
      match attribute $x;
      """
    Given uniquely identify answer concepts
      | x                    |
      | label:name           |
      | label:email          |
      | label:root-attribute |
    Given transaction closes
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert $x isa name "Colette";
      """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    Then typeql schema query; fails
      """
      undefine name;
      """

    When transaction closes
    When connection open schema transaction for database: typedb
    When typeql write query
      """
      match
        $x isa name;
      delete
        $x;
      """
    Then transaction commits

    When connection open schema transaction for database: typedb
    When typeql schema query
      """
      undefine name;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match attribute $x;
      """
    Then uniquely identify answer concepts
      | x                    |
      | label:email          |
      | label:root-attribute |

  #############################
  # RELATED ROLES ('RELATES') #
  #############################

  Scenario: a role type can be removed from its relation type
    Given get answers of typeql read query
      """
      match employment relates $x;
      """
    Given uniquely identify answer concepts
      | x                         |
      | label:employment:employee |
      | label:employment:employer |
    When typeql schema query
      """
      undefine relates employee from employment;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match employment relates $x;
      """
    Then uniquely identify answer concepts
      | x                         |
      | label:employment:employer |


  Scenario: undefining all players of a role produces a valid schema
    When typeql schema query
      """
      undefine plays employment:employee from person;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    Then typeql read query; fails with a message containing: "empty-set for some variable"
      """
      match $x plays employment:employee;
      """


  Scenario: after removing a role from a relation type, relation instances can no longer be created with that role
    Given transaction closes
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $p isa person, has email "ganesh@typedb.com";
      (employee: $p) isa employment;
      """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    Given typeql write query
      """
      match
        $r isa employment;
      delete
        $r;
      """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    When typeql schema query
      """
      undefine
      plays employment:employee from person;
      relates employee from employment;
      """
    Then transaction commits

    When connection open write transaction for database: typedb
    Then typeql read query; fails with a message containing: "Role label not found"
      """
      match $x relates employee;
      """

    Then typeql write query; fails
      """
      match
        $p isa person, has email "ganesh@typedb.com";
      insert
        (employee: $p) isa employment;
      """


  Scenario: removing all roles from a relation type without undefining the relation type errors on commit
    When typeql schema query
      """
      undefine
      relates employee from employment;
      relates employer from employment;
      """
    Then transaction commits; fails


  Scenario: undefining a role type automatically detaches any possible roleplayers
    Given get answers of typeql read query
      """
      match
        $x label person;
        $x plays $y;

      """
    Given uniquely identify answer concepts
      | x            | y                         |
      | label:person | label:employment:employee |
    When typeql schema query
      """
      undefine relates employee from employment;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    Then typeql read query; fails with a message containing: "empty-set for some variable"
      """
      match
        $x label person;
        $x plays $y;
      """


  Scenario: removing a role errors if it is played by existing roleplayers in relations
    Given typeql schema query
      """
      define
      entity company, owns name, plays employment:employer;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $p isa person, has name "Ada", has email "ada@typedb.com";
      $c isa company, has name "IBM";
      (employee: $p, employer: $c) isa employment;
      """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    Then typeql schema query; fails
      """
      undefine relates employer from employment;
      """


  Scenario: a role that is not played in any existing instance of its relation type can be safely removed
    Given transaction closes
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $p isa person, has name "Vijay", has email "vijay@typedb.com";
      (employee: $p) isa employment;
      """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    When typeql schema query
      """
      undefine relates employer from employment;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match employment relates $x;
      """
    Then uniquely identify answer concepts
      | x                         |
      | label:employment:employee |


  Scenario: removing a role from a super relation type also removes it from its subtypes
    Given typeql schema query
      """
      define relation part-time sub employment;
      """
    Given transaction commits

    When connection open schema transaction for database: typedb
    When typeql schema query
      """
      undefine relates employer from employment;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x label part-time; $x relates $role;
      """
    Then uniquely identify answer concepts
      | x               | role                      |
      | label:part-time | label:employment:employee |

  ############################
  # PLAYABLE ROLES ('PLAYS') #
  ############################

  Scenario: after undefining a playable role from a type, the type can no longer play the role
    Given transaction closes
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $p isa person, has email "ganesh@typedb.com";
      (employee: $p) isa employment;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      match
        $r isa employment;
      delete
        $r;
      """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    When typeql schema query
      """
      undefine plays employment:employee from person;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    Then typeql read query; fails with a message containing: "empty-set for some variable"
      """
      match $x plays employment:employee;
      """
    When transaction closes

    When connection open write transaction for database: typedb
    Then typeql write query; fails
      """
      match
        $p isa person, has email "ganesh@typedb.com";
      insert
        (employee: $p) isa employment;
      """


  Scenario: undefining played inherited role types using alias role types errors
    Given typeql schema query
    """
    define
    relation part-time-employment sub employment;
    """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    Given typeql schema query; fails
    """
    undefine
    plays part-time-employment:employee from person;
    """


  Scenario: removing a playable role errors if it is played by existing instances
    Given transaction closes
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $p isa person, has email "ganesh@typedb.com";
      (employee: $p) isa employment;
      """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    Then typeql schema query; fails
      """
      undefine plays employment:employee from person;
      """

  ########################
  # ATTRIBUTE OWNERSHIPS #
  ########################

  Scenario: undefining an attribute ownership removes it
    Given get answers of typeql read query
      """
      match
        $x owns name;
        $x label person;
      """
    Given uniquely identify answer concepts
      | x            |
      | label:person |
    When typeql schema query
      """
      undefine owns name from person;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    Then typeql read query; fails with a message containing: "empty-set for some variable"
      """
      match
        $x owns name;
        $x label person;
      """


  Scenario: attempting to undefine an attribute ownership inherited from a parent errors
    Given typeql schema query
      """
      define entity child sub person;
      """
    Then transaction commits

    When connection open schema transaction for database: typedb
    Then typeql schema query; fails
      """
      undefine owns name from child;
      """


  Scenario: undefining a key ownership removes it
    When typeql schema query
      """
      undefine owns email from person;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    Then typeql read query; fails with a message containing: "empty-set for some variable"
      """
      match $x owns email;
      """


  Scenario: when a type can own an attribute, but none of its instances actually do, the ownership can be undefined
    Given get answers of typeql read query
      """
      match $x owns name;
      """
    Given uniquely identify answer concepts
      | x            |
      | label:person |
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert $x isa person, has email "anon@typedb.com";
      """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    When typeql schema query
      """
      undefine owns name from person;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    Then typeql read query; fails with a message containing: "empty-set for some variable"
      """
      match $x owns name;
      """


  Scenario: removing an attribute ownership errors if it is owned by existing instances
    Given transaction closes
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert $x isa person, has name "Tomas", has email "tomas@typedb.com";
      """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    Then typeql schema query; fails
      """
      undefine owns name from person;
      """


  Scenario: undefining a key ownership errors if it is owned by existing instances
    Given transaction closes
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert $x isa person, has name "Daniel", has email "daniel@typedb.com";
      """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    Then typeql schema query; fails
      """
      undefine owns email from person;
      """

  ###########
  # STRUCTS #
  ###########

    # TODO 3.x: Add tests for structs

  ###############
  # ANNOTATIONS #
  ###############

  Scenario Outline: cannot undefine annotation @<annotation> for entity types
    Given typeql schema query
      """
      define entity player;
      """
    Given transaction commits

    When connection open schema transaction for database: typedb
    Then typeql schema query; fails
      """
      define
      entity player @<annotation>;
      """
    When transaction closes

    When connection open schema transaction for database: typedb
    Then typeql schema query; fails
      """
      undefine
      @<category> from player;
      """
    Examples:
      | annotation       | category    |
      | distinct         | distinct    |
      | independent      | independent |
      | unique           | unique      |
      | key              | key         |
#      | cascade          | cascade     | # TODO: Cascade is temporarily turned off
      | card(1..1)       | card        |
      | regex("val")     | regex       |
      | range("1".."2")  | range       |
      | values("1", "2") | values      |


  Scenario Outline: can undefine annotation @<annotation> for entity types, cannot undefine not defined
    Given typeql schema query
      """
      define entity player;
      """
    Given transaction commits

    When connection open schema transaction for database: typedb
    When typeql schema query
      """
      define
      entity player @<annotation>;
      """
    When transaction commits

    When connection open schema transaction for database: typedb
    Then typeql schema query
      """
      undefine
      @<category> from player;
      """
    Then transaction commits

    When connection open schema transaction for database: typedb
    Then typeql schema query; fails with a message containing: "no defined"
      """
      undefine
      @<category> from player;
      """
    Examples:
      | annotation | category |
      | abstract   | abstract |


  Scenario Outline: cannot undefine annotation @<annotation> for relation types
    Given typeql schema query
      """
      define
      relation parentship relates parent;
      """
    Given transaction commits

    When connection open schema transaction for database: typedb
    When typeql schema query; fails
      """
      define
      relation parentship @<annotation>;
      """
    When transaction closes

    When connection open schema transaction for database: typedb
    Then typeql schema query; fails
      """
      undefine
      @<category> from parentship;
      """
    Examples:
      | annotation       | category    |
      | distinct         | distinct    |
      | independent      | independent |
      | unique           | unique      |
      | key              | key         |
      | card(1..1)       | card        |
      | regex("val")     | regex       |
      | range("1".."2")  | range       |
      | values("1", "2") | values      |


  Scenario Outline: can undefine annotation @<annotation> for relation types, cannot undefine not defined
    Given typeql schema query
      """
      define
      relation parentship relates parent;
      """
    Given transaction commits

    When connection open schema transaction for database: typedb
    When typeql schema query
      """
      define
      relation parentship @<annotation>;
      """
    When transaction commits

    When connection open schema transaction for database: typedb
    Then typeql schema query
      """
      undefine
      @<category> from parentship;
      """
    Then transaction commits

    When connection open schema transaction for database: typedb
    Then typeql schema query; fails with a message containing: "no defined"
      """
      undefine
      @<category> from parentship;
      """
    Examples:
      | annotation | category |
      | abstract   | abstract |
#      | cascade    | cascade  | # TODO: Cascade is temporarily turned off


  Scenario Outline: cannot undefine annotation @<annotation> for attribute types
    Given typeql schema query
      """
      define
      attribute description value string;
      """
    Given transaction commits

    When connection open schema transaction for database: typedb
    Then typeql schema query; fails
      """
      define
      attribute description @<annotation>;
      """
    When transaction closes

    When connection open schema transaction for database: typedb
    Then typeql schema query; fails
      """
      undefine
      @<category> from description;
      """
    Examples:
      | annotation       | category |
      | distinct         | distinct |
      | unique           | unique   |
      | key              | key      |
#      | cascade          | cascade  | # TODO: Cascade is temporarily turned off
      | card(1..1)       | card     |
      | regex("val")     | regex    |
      | range("1".."2")  | range    |
      | values("1", "2") | values   |


  Scenario Outline: can undefine annotation @<annotation> for attribute types, cannot undefine not defined
    Given typeql schema query
      """
      define
      attribute description value string;
      """
    Given transaction commits

    When connection open schema transaction for database: typedb
    When typeql schema query
      """
      define
      attribute description @<annotation>;
      """
    When transaction commits

    When connection open schema transaction for database: typedb
    Then typeql schema query
      """
      undefine
      @<category> from description;
      """
    Then transaction commits

    When connection open schema transaction for database: typedb
    Then typeql schema query; fails with a message containing: "no defined"
      """
      undefine
      @<category> from description;
      """
    Examples:
      | annotation  | category    |
      | abstract    | abstract    |
      | independent | independent |


  Scenario Outline: cannot undefine annotation @<annotation> for relates/role types
    Given typeql schema query
      """
      define
      relation parentship @abstract, relates parent;
      """
    Given transaction commits

    When connection open schema transaction for database: typedb
    Then typeql schema query; fails
      """
      define
      relation parentship @abstract, relates parent @<annotation>;
      """
    When transaction closes

    When connection open schema transaction for database: typedb
    Then typeql schema query; fails
      """
      undefine
      @<category> from parentship relates parent;
      """
    Examples:
      | annotation       | category    |
      | independent      | independent |
      | distinct         | distinct    |
      | unique           | unique      |
      | key              | key         |
#      | cascade          | cascade     | # TODO: Cascade is temporarily turned off
      | regex("val")     | regex       |
      | range("1".."2")  | range       |
      | values("1", "2") | values      |


  Scenario Outline: can undefine annotation @<annotation> for relates/role types, cannot undefine not defined
    Given typeql schema query
      """
      define
      relation parentship @abstract, relates parent;
      """
    Given transaction commits

    When connection open schema transaction for database: typedb
    When typeql schema query
      """
      define
      relation parentship @abstract, relates parent @<annotation>;
      """
    When transaction commits

    When connection open schema transaction for database: typedb
    Then typeql schema query
      """
      undefine
      @<category> from parentship relates parent;
      """
    Then transaction commits

    When connection open schema transaction for database: typedb
    Then typeql schema query; fails with a message containing: "no defined"
      """
      undefine
      @<category> from parentship relates parent;
      """
    Examples:
      | annotation | category |
      | abstract   | abstract |
      | card(1..1) | card     |


  Scenario Outline: cannot undefine annotation @<annotation> to relates/role types lists
    Given typeql schema query
      """
      define
      relation parentship @abstract, relates parent[];
      """
    Given transaction commits

    When connection open schema transaction for database: typedb
    Then typeql schema query; fails
      """
      define
      relation parentship @abstract, relates parent[] @<annotation>;
      """
    When transaction closes

    When connection open schema transaction for database: typedb
    Then typeql schema query; fails
      """
      undefine
      @<category> from parentship relates parent[];
      """
    Examples:
      | annotation       | category    |
      | independent      | independent |
      | unique           | unique      |
      | key              | key         |
#      | cascade          | cascade         | # TODO: Cascade is temporarily turned off
      | regex("val")     | regex       |
      | range("1".."2")  | range       |
      | values("1", "2") | values      |


  Scenario Outline: can undefine annotation @<annotation> for relates/role types lists, cannot undefine not defined
    Given typeql schema query
      """
      define
      relation parentship @abstract, relates parent[];
      """
    Given transaction commits

    When connection open schema transaction for database: typedb
    When typeql schema query
      """
      define
      relation parentship @abstract, relates parent[] @<annotation>;
      """
    When transaction commits

    When connection open schema transaction for database: typedb
    Then typeql schema query
      """
      undefine
      @<category> from parentship relates parent[];
      """
    Then transaction commits

    When connection open schema transaction for database: typedb
    Then typeql schema query; fails with a message containing: "no defined"
      """
      undefine
      @<category> from parentship relates parent[];
      """
    Examples:
      | annotation | category |
      | abstract   | abstract |
      | card(1..1) | card     |
      | distinct   | distinct |


  Scenario Outline: cannot undefine annotation @<annotation> for relates/role types using wrong scalar/list notation
    Given typeql schema query
      """
      define
      relation parentship @abstract, relates parent[], relates child;
      """
    Given transaction commits

    When connection open schema transaction for database: typedb
    When typeql schema query
      """
      define
      relation parentship relates parent[] @<annotation>, relates child @<annotation>;
      """
    When transaction commits

    When connection open schema transaction for database: typedb
    Then typeql schema query; fails with a message containing: "no defined 'parentship relates parent', while"
      """
      undefine
      @<category> from parentship relates parent;
      """
    Then transaction commits

    When connection open schema transaction for database: typedb
    Then typeql schema query; fails with a message containing: "no defined 'parentship relates child[]', while"
      """
      undefine
      @<category> from parentship relates child[];
      """
    Then transaction commits
    Examples:
      | annotation | category |
      | card(1..1) | card     |


  Scenario Outline: cannot undefine annotation @<annotation> for owns
    Given typeql schema query
      """
      define
      entity player owns name;
      """
    Given transaction commits

    When connection open schema transaction for database: typedb
    Then typeql schema query; fails
      """
      define
      entity player owns name @<annotation>;
      """
    When transaction closes

    When connection open schema transaction for database: typedb
    Then typeql schema query; fails
      """
      undefine
      @<category> from player owns name;
      """
    Examples:
      | annotation  | category    |
      | abstract    | abstract    |
      | independent | independent |
      | distinct    | distinct    |
#      | cascade     | cascade     | # TODO: Cascade is temporarily turned off


  Scenario Outline: can undefine annotation @<annotation> for owns, cannot undefine not defined
    Given typeql schema query
      """
      define
      entity player owns name;
      """
    Given transaction commits

    When connection open schema transaction for database: typedb
    When typeql schema query
      """
      define
      entity player owns name @<annotation>;
      """
    When transaction commits

    When connection open schema transaction for database: typedb
    Then typeql schema query
      """
      undefine
      @<category> from player owns name;
      """
    Then transaction commits

    When connection open schema transaction for database: typedb
    Then typeql schema query; fails with a message containing: "no defined"
      """
      undefine
      @<category> from player owns name;
      """
    Examples:
      | annotation       | category |
      | unique           | unique   |
      | key              | key      |
      | card(1..1)       | card     |
      | regex("val")     | regex    |
      | range("1".."2")  | range    |
      | values("1", "2") | values   |


  Scenario Outline: cannot undefine annotation @<annotation> for owns lists
    Given typeql schema query
      """
      define
      entity player owns name[];
      """
    Given transaction commits

    When connection open schema transaction for database: typedb
    Then typeql schema query; fails
      """
      define
      entity player owns name[] @<annotation>;
      """
    When transaction closes

    When connection open schema transaction for database: typedb
    Then typeql schema query; fails
      """
      undefine
      @<category> from player owns name[];
      """
    Examples:
      | annotation  | category    |
      | abstract    | abstract    |
      | independent | independent |
#      | cascade     | cascade     | # TODO: Cascade is temporarily turned off


  Scenario Outline: can undefine annotation @<annotation> for owns lists, cannot undefine not defined
    Given typeql schema query
      """
      define
      entity player owns name[];
      """
    Given transaction commits

    When connection open schema transaction for database: typedb
    When typeql schema query
      """
      define
      entity player owns name[] @<annotation>;
      """
    When transaction commits

    When connection open schema transaction for database: typedb
    Then typeql schema query
      """
      undefine
      @<category> from player owns name[];
      """
    Then transaction commits

    When connection open schema transaction for database: typedb
    Then typeql schema query; fails with a message containing: "no defined"
      """
      undefine
      @<category> from player owns name[];
      """
    Examples:
      | annotation       | category |
      | unique           | unique   |
      | key              | key      |
      | card(1..1)       | card     |
      | regex("val")     | regex    |
      | range("1".."2")  | range    |
      | values("1", "2") | values   |
      | distinct         | distinct |


  Scenario Outline: cannot undefine annotation @<annotation> for owns using wrong scalar/list notation
    Given typeql schema query
      """
      define
      entity player owns name[], owns email;
      """
    Given transaction commits

    When connection open schema transaction for database: typedb
    When typeql schema query
      """
      define
      player owns name[] @<annotation>, owns email @<annotation>;
      """
    When transaction commits

    When connection open schema transaction for database: typedb
    Then typeql schema query; fails with a message containing: "no defined 'player owns name', while"
      """
      undefine
      @<category> from player owns name;
      """
    Then transaction commits

    When connection open schema transaction for database: typedb
    Then typeql schema query; fails with a message containing: "no defined 'player owns email[]', while"
      """
      undefine
      @<category> from player owns email[];
      """
    Then transaction commits
    Examples:
      | annotation | category |
      | card(1..1) | card     |


  Scenario Outline: cannot undefine annotation @<annotation> for plays
    Given typeql schema query
      """
      define
      entity player plays employment:employee;
      """
    Given transaction commits

    When connection open schema transaction for database: typedb
    Then typeql schema query; fails
      """
      define
      entity player plays employment:employee @<annotation>;
      """
    When transaction closes

    When connection open schema transaction for database: typedb
    Then typeql schema query; fails
      """
      undefine
      @<category> from player plays employment:employee;
      """
    Examples:
      | annotation       | category    |
      | abstract         | abstract    |
      | independent      | independent |
      | distinct         | distinct    |
      | unique           | unique      |
      | key              | key         |
#      | cascade          | cascade     | # TODO: Cascade is temporarily turned off
      | regex("val")     | regex       |
      | range("1".."2")  | range       |
      | values("1", "2") | values      |


  Scenario Outline: can undefine annotation @<annotation> for plays, cannot undefine not defined
    Given typeql schema query
      """
      define
      entity player plays employment:employee;
      """
    Given transaction commits

    When connection open schema transaction for database: typedb
    When typeql schema query
      """
      define
      entity player plays employment:employee @<annotation>;
      """
    When transaction commits

    When connection open schema transaction for database: typedb
    Then typeql schema query
      """
      undefine
      @<category> from player plays employment:employee;
      """
    Then transaction commits

    When connection open schema transaction for database: typedb
    Then typeql schema query; fails with a message containing: "no defined"
      """
      undefine
      @<category> from player plays employment:employee;
      """
    Examples:
      | annotation | category |
      | card(1..1) | card     |


  Scenario Outline: cannot undefine annotation @<annotation> for value types
    Given typeql schema query
      """
      define
      attribute description value string;
      """
    Given transaction commits

    When connection open schema transaction for database: typedb
    Then typeql schema query; fails
      """
      define
      attribute description value string @<annotation>;
      """
    When transaction closes

    When connection open schema transaction for database: typedb
    Then typeql schema query; fails
      """
      undefine
      @<category> from description value string;
      """
    Examples:
      | annotation  | category    |
      | unique      | unique      |
      | key         | key         |
      | abstract    | abstract    |
      | independent | independent |
      | distinct    | distinct    |
#      | cascade     |category     | # TODO: Cascade is temporarily turned off
      | card(1..1)  | card        |


  Scenario Outline: can undefine annotation @<annotation> for value types, cannot undefine not defined
    Given typeql schema query
      """
      define
      attribute description value string;
      """
    Given transaction commits

    When connection open schema transaction for database: typedb
    When typeql schema query
      """
      define
      attribute description value string @<annotation>;
      """
    When transaction commits

    When connection open schema transaction for database: typedb
    Then typeql schema query
      """
      undefine
      @<category> from description value string;
      """
    Then transaction commits

    When connection open schema transaction for database: typedb
    Then typeql schema query; fails with a message containing: "no defined"
      """
      undefine
      @<category> from description value string;
      """
    Examples:
      | annotation       | category |
      | regex("val")     | regex    |
      | range("1".."2")  | range    |
      | values("1", "2") | values   |

  ###################
  # COMPLEX QUERIES #
  ###################

  Scenario: a type and an attribute type that it owns can be removed simultaneously
    Given get answers of typeql read query
      """
      match entity $x;
      """
    Given uniquely identify answer concepts
      | x                   |
      | label:person        |
      | label:abstract-type |
    Given get answers of typeql read query
      """
      match attribute $x;
      """
    Given uniquely identify answer concepts
      | x                    |
      | label:name           |
      | label:email          |
      | label:root-attribute |

    When typeql schema query
      """
      undefine
      person;
      name;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match entity $x;
      """
    Then uniquely identify answer concepts
      | x                   |
      | label:abstract-type |
    When get answers of typeql read query
      """
      match attribute $x;
      """
    Then uniquely identify answer concepts
      | x                    |
      | label:email          |
      | label:root-attribute |


  Scenario: a type, a relation type that it plays in and an attribute type that it owns can be removed simultaneously
    Given get answers of typeql read query
      """
      match entity $x;
      """
    Given uniquely identify answer concepts
      | x                   |
      | label:person        |
      | label:abstract-type |
    Given get answers of typeql read query
      """
      match relation $x;
      """
    Given uniquely identify answer concepts
      | x                |
      | label:employment |
    Given get answers of typeql read query
      """
      match attribute $x;
      """
    Given uniquely identify answer concepts
      | x                    |
      | label:name           |
      | label:email          |
      | label:root-attribute |
    Given get answers of typeql read query
      """
      match $_ relates $x;
      """
    Given uniquely identify answer concepts
      | x                         |
      | label:employment:employee |
      | label:employment:employer |
    When typeql schema query
      """
      undefine
      person;
      employment;
      name;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match entity $x;
      """
    Then uniquely identify answer concepts
      | x                   |
      | label:abstract-type |
    Then typeql read query; fails with a message containing: "empty-set for some variable"
      """
      match relation $x;
      """
    When get answers of typeql read query
      """
      match attribute $x;
      """
    Then uniquely identify answer concepts
      | x                    |
      | label:email          |
      | label:root-attribute |
    Then typeql read query; fails with a message containing: "empty-set for some variable"
      """
      match $_ relates $x;
      """


  Scenario: can undefine the same type's capabilities piece by piece in one query
    Given typeql schema query
      """
      define
      relation parentship @abstract, relates parent @card(0..), relates child[];
      relation fathership @abstract, sub parentship, relates father as parent @card(1..);
      """
    Given transaction commits

    When connection open schema transaction for database: typedb
    Then typeql schema query
      """
      undefine
      as parent from fathership relates father;
      @card from fathership relates father;
      relates father from fathership;
      @abstract from fathership;
      sub parentship from fathership;
      fathership;
      """
    Then transaction commits

    When connection open schema transaction for database: typedb
    When get answers of typeql read query
      """
      match $x sub parentship;
      """
    Then uniquely identify answer concepts
      | x                |
      | label:parentship |
    Then typeql read query; fails with a message containing: "not found"
      """
      match $x label fathership;
      """
