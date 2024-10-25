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
      attribute name, value string;
      attribute email, value string @regex(".+@\w+\..+");
      entity abstract-type @abstract;
      """
    Given transaction commits

    Given connection open schema transaction for database: typedb


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


    # TODO: Error or not?
  Scenario: when undefining 'sub' on an entity type, specifying a type that isn't really its supertype errors
    When typeql schema query; fails
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

    Given transaction closes
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert $x isa person, has name "Victor", has email "victor@vaticle.com";
      """
    Given transaction commits

    Given transaction closes
    When connection open schema transaction for database: typedb
    Then typeql schema query; fails
      """
      undefine person;
      """

    When transaction closes
    When connection open schema transaction for database: typedb
    When typeql write query
      """
      match
        $x isa person;
      delete
        $x isa person;
      """
    Then transaction commits

    When transaction closes
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
    When get answers of typeql read query
      """
      match relation $x;
      """
    Then answer size is: 0


  Scenario: removing playable roles from a super relation type also removes them from its subtypes
    Given typeql schema query
      """
      define
      relation employment-terms, relates employment;
      employment plays employment-terms:employment;
      contract-employment sub employment;
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
      undefine employment plays employment-terms:employment;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match contract-employment plays $x;
      """
    Then answer size is: 0


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
      undefine employment owns start-date;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x owns start-date;
      """
    Then answer size is: 0


  Scenario: removing key ownerships from a super relation type also removes them from its subtypes
    Given typeql schema query
      """
      define
      attribute employment-reference, value string;
      employment owns employment-reference @key;
      relation contract-employment sub employment;
      """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    Given get answers of typeql read query
      """
      match $x owns employment-reference @key;
      """
    Given uniquely identify answer concepts
      | x                         |
      | label:employment          |
      | label:contract-employment |
    When typeql schema query
      """
      undefine employment owns employment-reference;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x owns employment-reference @key;
      """
    Then answer size is: 0


  Scenario: undefining a relation type errors on commit if it has existing instances
    Given transaction closes
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $p isa person, has name "Harald", has email "harald@vaticle.com";
      $r (employee: $p) isa employment;
      """
    Given transaction commits

    Given transaction closes
    Given connection open schema transaction for database: typedb
    Then typeql schema query; fails
      """
      undefine
      employment relates employee;
      employment relates employer;
      person plays employment:employee;
      employment;
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
      $p isa person, has name "Harald", has email "harald@vaticle.com";
      $r (employee: $p) isa employment;
      """
    Given transaction commits

    Given transaction closes
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
        $r isa employment;
      """
    Then transaction commits

    When transaction closes
    When connection open schema transaction for database: typedb
    When typeql schema query
      """
      undefine employment;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match relation $x;
      """
    Then answer size is: 0


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
    When get answers of typeql read query
      """
      match
        $x label person;
        $x plays $y;

      """
    Then answer size is: 0

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
      | long       | age        |
      | double     | height     |
      | boolean    | is-awake   |
      | datetime   | birth-date |


  Scenario: undefining a regex on an attribute type removes the regex constraints on the attribute
    When typeql schema query
      """
      undefine email regex ".+@\w+\..+";
      """
    Then transaction commits

    When transaction closes
    When connection open write transaction for database: typedb
    When typeql write query
      """
      insert $x "not-email-regex" isa email;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa email;
      """
    Then answer size is: 1


  Scenario: removing playable roles from a super attribute type also removes them from its subtypes
    Given typeql schema query
      """
      define
      employment relates manager-name;
      attribute abstract-name, abstract, value string, plays employment:manager-name;
      attribute first-name sub abstract-name;
      """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    Given get answers of typeql read query
      """
      match first-name plays $x;
      """
    Given uniquely identify answer concepts
      | x                             |
      | label:employment:manager-name |
    When typeql schema query
      """
      undefine abstract-name plays employment:manager-name;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match first-name plays $x;
      """
    Then answer size is: 0


  Scenario: removing attribute ownerships from a super attribute type also removes them from its subtypes
    Given typeql schema query
      """
      define
      attribute locale, value string;
      attribute abstract-name @abstract, value string, owns locale;
      attribute first-name sub abstract-name;
      """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    Given get answers of typeql read query
      """
      match $x owns locale;
      """
    Given uniquely identify answer concepts
      | x                   |
      | label:abstract-name |
      | label:first-name    |
    When typeql schema query
      """
      undefine abstract-name owns locale;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x owns locale;
      """
    Then answer size is: 0


  Scenario: removing a key ownership from a super attribute type also removes it from its subtypes
    Given typeql schema query
      """
      define
      attribute name-id, value long;
      attribute abstract-name @abstract, value string, owns name-id @key;
      attribute first-name sub abstract-name;
      """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    Given get answers of typeql read query
      """
      match $x owns name-id @key;
      """
    Given uniquely identify answer concepts
      | x                   |
      | label:abstract-name |
      | label:first-name    |
    When typeql schema query
      """
      undefine abstract-name owns name-id;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x owns name-id @key;
      """
    Then answer size is: 0


  Scenario: an attribute and its self-ownership can be removed simultaneously
    Given typeql schema query
      """
      define
      name owns name;
      """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    When typeql schema query
      """
      undefine
      name owns name;
      attribute name;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    Then typeql read query; fails
      """
      match $x label name;
      """


  Scenario: undefining the value type of an attribute errors
    When typeql schema query; fails
      """
      undefine name value string;
      """


  Scenario: all existing instances of an attribute type must be deleted in order to undefine it
    Given get answers of typeql read query
      """
      match attribute $x;
      """
    Given uniquely identify answer concepts
      | x               |
      | label:name      |
      | label:email     |
    Given transaction closes
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert $x "Colette" isa name;
      """
    Given transaction commits

    Given transaction closes
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
        $x isa name;
      """
    Then transaction commits

    When transaction closes
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
      | x               |
      | label:email     |


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
      undefine employment relates employee;
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
      undefine person plays employment:employee;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x plays employment:employee;
      """
    Then answer size is: 0

  #TODO: test is not working
  @ignore
  Scenario: after removing a role from a relation type, relation instances can no longer be created with that role
    Given transaction closes
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $p isa person, has email "ganesh@vaticle.com";
      $r (employee: $p) isa employment;
      """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    Given typeql write query
      """
      match
        $r isa employment;
      delete
        $r isa employment;
      """
    Given transaction commits

    Given transaction closes
    Given connection open schema transaction for database: typedb
    When typeql schema query
      """
      undefine
      person plays employment:employee;
      employment relates employee;
      """
    Then transaction commits

    When transaction closes
    When connection open write transaction for database: typedb
    When get answers of typeql read query
      """
      match $x relates employee;
      """
    Then answer size is: 0
    Then typeql write query; fails
      """
      match
        $p isa person, has email "ganesh@vaticle.com";
      insert
        $r (employee: $p) isa employment;
      """


  Scenario: removing all roles from a relation type without undefining the relation type errors on commit
    When typeql schema query
      """
      undefine
      employment relates employee;
      employment relates employer;
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
      undefine employment relates employee;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
        $x label person;
        $x plays $y;

      """
    Then answer size is: 0


  Scenario: removing a role errors if it is played by existing roleplayers in relations
    Given typeql schema query
      """
      define
      entity company, owns name, plays employment:employer;
      """
    Given transaction commits

    Given transaction closes
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $p isa person, has name "Ada", has email "ada@vaticle.com";
      $c isa company, has name "IBM";
      $r (employee: $p, employer: $c) isa employment;
      """
    Given transaction commits

    Given transaction closes
    Given connection open schema transaction for database: typedb
    Then typeql schema query; fails
      """
      undefine employment relates employer;
      """


  Scenario: a role that is not played in any existing instance of its relation type can be safely removed
    Given transaction closes
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $p isa person, has name "Vijay", has email "vijay@vaticle.com";
      $r (employee: $p) isa employment;
      """
    Given transaction commits

    Given transaction closes
    Given connection open schema transaction for database: typedb
    When typeql schema query
      """
      undefine employment relates employer;
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
      undefine employment relates employer;
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

  # TODO
  Scenario: removing a role from a super relation type also removes roles that specialise it in its subtypes (?)

  # TODO
  Scenario: after undefining a sub-role from a relation type, it is gone and the type is left with just its parent role (?)


  ############################
  # PLAYABLE ROLES ('PLAYS') #
  ############################

  Scenario: after undefining a playable role from a type, the type can no longer play the role
    Given transaction closes
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $p isa person, has email "ganesh@vaticle.com";
      $r (employee: $p) isa employment;
      """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    Given typeql write query
      """
      match
        $r isa employment;
      delete
        $r isa employment;
      """
    Given transaction commits

    Given transaction closes
    Given connection open schema transaction for database: typedb
    When typeql schema query
      """
      undefine person plays employment:employee;
      """
    Then transaction commits

    When transaction closes
    When connection open write transaction for database: typedb
    When get answers of typeql read query
      """
      match $x plays employment:employee;
      """
    Then answer size is: 0
    Then typeql write query; fails
      """
      match
        $p isa person, has email "ganesh@vaticle.com";
      insert
        $r (employee: $p) isa employment;
      """


  Scenario: undefining a playable role that was not actually playable to begin with errors
    Given get answers of typeql read query
      """
      match person plays $x;
      """
    Given uniquely identify answer concepts
      | x                         |
      | label:employment:employee |
    When typeql schema query; fails
      """
      undefine person plays employment:employer;
      """


  Scenario: undefining played inherited role types using alias role types errors
    Given typeql schema query
    """
    define
    part-time-employment sub employment;
    """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    Given typeql schema query; fails
    """
    undefine
    person plays part-time-employment:employee;
    """


  Scenario: removing a playable role errors an error if it is played by existing instances
    Given transaction closes
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $p isa person, has email "ganesh@vaticle.com";
      $r (employee: $p) isa employment;
      """
    Given transaction commits

    Given transaction closes
    Given connection open schema transaction for database: typedb
    Then typeql schema query; fails
      """
      undefine person plays employment:employee;
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
      undefine person owns name;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
        $x owns name;
        $x label person;

      """
    Then answer size is: 0


  Scenario: attempting to undefine an attribute ownership that was not actually owned to begin errors
    When typeql schema query; fails
      """
      undefine employment owns name;
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
      undefine child owns name;
      """


  Scenario: undefining a key ownership removes it
    When typeql schema query
      """
      undefine person owns email;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x owns email;
      """
    Then answer size is: 0


  Scenario: writing '@key' when undefining a key ownership is not allowed
    Then typeql schema query; fails
      """
      undefine person owns email @key;
      """


  Scenario: writing '@key' when undefining an attribute ownership is not allowed
    Then typeql schema query; fails
      """
      undefine person owns name @key;
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

    Given transaction closes
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert $x isa person, has email "anon@vaticle.com";
      """
    Given transaction commits

    Given transaction closes
    Given connection open schema transaction for database: typedb
    When typeql schema query
      """
      undefine person owns name;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x owns name;
      """
    Then answer size is: 0


  Scenario: removing an attribute ownership errors if it is owned by existing instances
    Given transaction closes
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert $x isa person, has name "Tomas", has email "tomas@vaticle.com";
      """
    Given transaction commits

    Given transaction closes
    Given connection open schema transaction for database: typedb
    Then typeql schema query; fails
      """
      undefine person owns name;
      """


  Scenario: undefining a key ownership errors if it is owned by existing instances
    Given transaction closes
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert $x isa person, has name "Daniel", has email "daniel@vaticle.com";
      """
    Given transaction commits

    Given transaction closes
    Given connection open schema transaction for database: typedb
    Then typeql schema query; fails
      """
      undefine person owns email;
      """


  #############
  # FUNCTIONS #
  #############
# TODO: Write new tests for functions. Consider old Rules tests to be reimplemented if applicable
#  Scenario: undefining a rule removes it
#    Given typeql schema query
#      """
#      define
#      entity company, plays employment:employer;
#      rule a-rule:
#      when {
#        $c isa company; $y isa person;
#      } then {
#        (employer: $c, employee: $y) isa employment;
#      };
#      """
#    Given transaction commits
#
#    When connection open schema transaction for database: typedb
#    Then rules contain: a-rule
#    When typeql schema query
#      """
#      undefine rule a-rule;
#      """
#    Then transaction commits
#
#    When connection open read transaction for database: typedb
#    Then rules do not contain: a-rule
#
#  Scenario: after undefining a rule, concepts previously inferred by that rule are no longer inferred
#    Given typeql schema query
#      """
#      define
#      rule samuel-email-rule:
#      when {
#        $x has email "samuel@vaticle.com";
#      } then {
#        $x has name "Samuel";
#      };
#      """
#    Given transaction commits
#
#    Given transaction closes
#    Given connection open write transaction for database: typedb
#    Given typeql write query
#      """
#      insert $x isa person, has email "samuel@vaticle.com";
#      """
#    Given transaction commits
#
#    Given connection open read transaction for database: typedb
#    Given get answers of typeql read query
#      """
#      match
#        $x has name $n;
#      get $n;
#      """
#    Given uniquely identify answer concepts
#      | n                 |
#      | attr:name:Samuel  |
#    Given transaction closes
#    Given connection open schema transaction for database: typedb
#    When typeql schema query
#      """
#      undefine rule samuel-email-rule;
#      """
#    Then transaction commits
#
#    When connection open read transaction for database: typedb
#    When get answers of typeql read query
#      """
#      match
#        $x has name $n;
#      get $n;
#      """
#    Then answer size is: 0
#
#
#  # TODO enable when we can do reasoning in a schema write transaction
#  @ignore
#  Scenario: when undefining a rule, concepts inferred by that rule can still be retrieved until the next commit
#    Given typeql schema query
#      """
#      define
#      rule samuel-email-rule:
#      when {
#        $x has email "samuel@vaticle.com";
#      } then {
#        $x has name "Samuel";
#      };
#      """
#    Given transaction commits
#
#    Given transaction closes
#    Given connection open write transaction for database: typedb
#    Given typeql write query
#      """
#      insert $x isa person, has email "samuel@vaticle.com";
#      """
#    Given transaction commits
#
#    Given transaction closes
#    Given connection open schema transaction for database: typedb
#    Given get answers of typeql read query
#      """
#      match
#        $x has name $n;
#      get $n;
#      """
#    Given uniquely identify answer concepts
#      | n                 |
#      | attr:name:Samuel  |
#    When typeql schema query
#      """
#      undefine rule samuel-email-rule;
#      """
#
#    When get answers of typeql read query
#      """
#      match
#        $x has name $n;
#      get $n;
#      """
#    Then uniquely identify answer concepts
#      | n                 |
#      | attr:name:Samuel  |
#
#  Scenario: You cannot undefine a type if it is used in a rule
#    Given typeql schema query
#    """
#    define
#
#    entity type-to-undefine, owns name;
#
#    rule rule-referencing-type-to-undefine:
#    when {
#      $x isa type-to-undefine;
#    } then {
#      $x has name "dummy";
#    };
#    """
#    Given transaction commits
#
#    Given connection open schema transaction for database: typedb
#
#    Given typeql schema query; fails
#    """
#    undefine
#      type-to-undefine;
#    """
#
#  Scenario: You cannot undefine a type if it is used in a negation in a rule
#    Given typeql schema query
#    """
#    define
#    relation rel, relates rol;
#    entity other-type, owns name, plays rel:rol;
#    entity type-to-undefine, owns name, plays rel:rol;
#
#    rule rule-referencing-type-to-undefine:
#    when {
#      $x isa other-type;
#      not { ($x, $y) isa relation; $y isa type-to-undefine; };
#    } then {
#      $x has name "dummy";
#    };
#    """
#    Given transaction commits
#
#    Given connection open schema transaction for database: typedb
#
#    Given typeql schema query; fails
#    """
#    undefine
#      type-to-undefine;
#    """
#
#  Scenario: You cannot undefine a type if it is used in any disjunction in a rule
#    Given typeql schema query
#    """
#    define
#
#    entity type-to-undefine, owns name;
#
#    rule rule-referencing-type-to-undefine:
#    when {
#      $x has name $y;
#      { $x isa person; } or { $x isa type-to-undefine; };
#    } then {
#      $x has name "dummy";
#    };
#    """
#    Given transaction commits
#
#    Given connection open schema transaction for database: typedb
#
#    Given typeql schema query; fails
#    """
#    undefine
#      type-to-undefine;
#    """
#
#  Scenario: You cannot undefine a type if it is used in the then of a rule
#    Given typeql schema query
#    """
#    define
#    attribute name-to-undefine, value string;
#    entity some-type, owns name-to-undefine;
#
#    rule rule-referencing-type-to-undefine:
#    when {
#      $x isa some-type;
#    } then {
#      $x has name-to-undefine "dummy";
#    };
#    """
#    Given transaction commits
#
#    Given connection open schema transaction for database: typedb
#
#    Given typeql schema query; fails
#    """
#    undefine
#      name-to-undefine;
#    """

  ####################
  # TYPE ANNOTATIONS #
  ####################

  Scenario: undefining a type as abstract converts an abstract to a concrete type, allowing creation of instances
    Given get answers of typeql read query
      """
      match
        $x label abstract-type;
        not { $x abstract; };

      """
    Given answer size is: 0
    Given transaction closes
    Given connection open write transaction for database: typedb
    Given typeql write query; fails
      """
      insert $x isa abstract-type;
      """

    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      undefine abstract-type abstract;
      """
    Given transaction commits

    Given transaction closes
    Given connection open write transaction for database: typedb
    When get answers of typeql read query
      """
      match
        $x label abstract-type;
        not { $x abstract; };

      """
    Then uniquely identify answer concepts
      | x                   |
      | label:abstract-type |
    When typeql write query
      """
      insert $x isa abstract-type;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa abstract-type;
      """
    Then answer size is: 1


  Scenario: undefining abstract on a type that is already non-abstract does nothing
    When typeql schema query
      """
      undefine person abstract;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
        $x label person;
        not { $x abstract; };

      """
    Then uniquely identify answer concepts
      | x            |
      | label:person |


  Scenario: an abstract type can be changed into a concrete type even if has an abstract child type
    Given typeql schema query
      """
      define entity sub-abstract-type @abstract, sub abstract-type;
      """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    When typeql schema query
      """
      undefine abstract-type @abstract;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
        $x label abstract-type;
        not { $x abstract; };

      """
    Then uniquely identify answer concepts
      | x                   |
      | label:abstract-type |


  Scenario: undefining abstract on an attribute type is allowed, even if that attribute type has an owner
    Given typeql schema query
      """
      define
      person @abstract;
      attribute vehicle-registration @abstract, value string;
      person owns vehicle-registration;
      """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    When typeql schema query
      """
      undefine
      vehicle-registration abstract;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
        $x label vehicle-registration;
        not { $x abstract; };

      """
    Then answer size is: 1


  ##########################
  # CAPABILITY ANNOTATIONS #
  ##########################
  # TODO: Write tests


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
      | x               |
      | label:name      |
      | label:email     |
    When typeql schema query
      """
      undefine
      entity person, owns name;
      attribute name;
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
      | x               |
      | label:email     |

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
      | x               |
      | label:name      |
      | label:email     |
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
      entity person, owns name, owns email, plays employment:employee;
      relation employment, relates employee, relates employer;
      attribute name;
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
      match relation $x;
      """
    Then answer size is: 0
    When get answers of typeql read query
      """
      match attribute $x;
      """
    Then uniquely identify answer concepts
      | x               |
      | label:email     |
    When get answers of typeql read query
      """
      match $_ relates $x;
      """
    Then answer size is: 0
