# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: TypeQL Insert Query

  Background: Open connection and create a simple extensible schema
    Given typedb starts
    Given connection opens with default authentication
    Given connection is open: true
    Given connection reset database: typedb
#    Given connection has 0 databases
#    Given connection create database: typedb
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define

      entity person
        plays employment:employee,
        owns name @card(0..),
        owns age,
        owns ref @key,
        owns email @unique @card(0..);

      entity company
        plays employment:employer,
        owns name,
        owns ref @key;

      relation employment
        relates employee @card(0..),
        relates employer,
        owns ref @key;

      attribute name
        value string;

      attribute age @independent,
        value integer;

      attribute ref
        value integer;

      attribute email
        value string;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given set time-zone: Europe/London

  #######################
  # INSERTING INSTANCES #
  #######################

  Scenario: new entities can be inserted
    When typeql write query
      """
      insert $x isa person, has ref 0;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa person;
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:0 |


  Scenario: one query can insert multiple instances
    When typeql write query
      """
      insert
      $x isa person, has ref 0;
      $y isa person, has ref 1;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa person;
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:0 |
      | key:ref:1 |


  Scenario: when an insert has multiple statements with the same variable name, they refer to the same instance
    When typeql write query
      """
      insert
      $x has name "Bond";
      $x has name "James Bond";
      $x isa person, has ref 0;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x has name "Bond";
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:0 |
    When get answers of typeql read query
      """
      match $x has name "James Bond";
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:0 |
    When get answers of typeql read query
      """
      match $x has name "Bond", has name "James Bond";
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:0 |


  Scenario: when running multiple identical insert queries in series, new instances get created each time
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
      attribute breed value string;
      entity dog owns breed;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given get answers of typeql read query
      """
      match $x isa dog;
      """
    Given answer size is: 0
    When typeql write query
      """
      insert $x isa dog, has breed "Labrador";
      """
    Then transaction commits

    When connection open write transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa dog;
      """
    Then answer size is: 1
    Then typeql write query
      """
      insert $x isa dog, has breed "Labrador";
      """
    Then transaction commits

    When connection open write transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa dog;
      """
    Then answer size is: 2
    Then typeql write query
      """
      insert $x isa dog, has breed "Labrador";
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa dog;
      """
    Then answer size is: 3


  Scenario: an insert can be performed using a direct type specifier, and it functions equivalently to 'isa'
    When get answers of typeql write query
      """
      insert $x isa! person, has name "Harry", has ref 0;
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:0 |


  Scenario: attempting to insert an instance of an abstract type errors
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
      entity factory @abstract;
      entity electronics-factory sub factory;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Then typeql write query; fails
      """
      insert $x isa factory;
      """

  #######################
  # ATTRIBUTE OWNERSHIP #
  #######################

  Scenario: when inserting a new instance that owns new attributes, both the instance and the attributes get created
    Given get answers of typeql read query
      """
      match entity $t; $x isa $t; select $x;
      """
    Given answer size is: 0
    Given get answers of typeql read query
      """
      match attribute $t; $x isa $t; select $x;
      """
    Given answer size is: 0
    When typeql write query
      """
      insert $x isa person, has name "Wilhelmina", has age 25, has ref 0;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match entity $t; $x isa $t; select $x;
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:0 |
    When get answers of typeql read query
      """
      match attribute $t; $x isa $t; select $x;
      """
    Then uniquely identify answer concepts
      | x                    |
      | attr:name:Wilhelmina |
      | attr:age:25          |
      | attr:ref:0           |


  Scenario: when inserting a new instance that owns new attributes via a value variable, both the instance and the attributes get created
    Given get answers of typeql read query
      """
      match entity $t; $x isa $t; select $x;
      """
    Given answer size is: 0
    Given get answers of typeql read query
      """
      match attribute $t; $x isa $t; select $x;
      """
    Given answer size is: 0
    When typeql write query
      """
      insert $a isa age 25; $x isa person, has name "Wilhelmina", has age $a, has ref 0;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match entity $t; $x isa $t; select $x;
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:0 |
    When get answers of typeql read query
      """
      match attribute $t; $x isa $t; select $x;
      """
    Then uniquely identify answer concepts
      | x                    |
      | attr:name:Wilhelmina |
      | attr:age:25          |
      | attr:ref:0           |


  Scenario: a freshly inserted attribute has no owners
    Given typeql write query
      """
      insert $name isa name "John";
      """
    Given transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x has name "John";
      """
    Then answer size is: 0


  Scenario: given an attribute with no owners, inserting a instance that owns it results in it having an owner
    Given typeql write query
      """
      insert $name isa name "Kyle";
      """
    Given transaction commits

    When connection open write transaction for database: typedb
    Given typeql write query
      """
      insert $x isa person, has name "Kyle", has ref 0;
      """
    Given transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x has name "Kyle";
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:0 |


  Scenario: after inserting two instances that own the same attribute, the attribute has two owners
    When typeql write query
      """
      insert
      $p1 isa person, has name "Jack", has age 10, has ref 0;
      $p2 isa person, has name "Jill", has age 10, has ref 1;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
      $p1 isa person, has age $a;
      $p2 isa person, has age $a;
      not { $p1 is $p2; };
      select $p1, $p2;
      """
    Then uniquely identify answer concepts
      | p1        | p2        |
      | key:ref:0 | key:ref:1 |
      | key:ref:1 | key:ref:0 |


  Scenario: after inserting a new owner for every existing ownership of an attribute, its number of owners doubles
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
      entity dog owns name;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $p1 isa dog, has name "Frank";
      $p2 isa dog, has name "Geoff";
      $p3 isa dog, has name "Harriet";
      $p4 isa dog, has name "Ingrid";
      $p5 isa dog, has name "Jacob";
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    When get answers of typeql read query
      """
      match $p isa dog;
      """
    Then answer size is: 5
    # TODO: error "IsaStatementForInputVariable { variable: $1 })"
    When typeql write query
      """
      match
        $p has name $name;
      insert
        $p2 isa dog, has $name;
      """
    Then transaction commits

    When connection open write transaction for database: typedb
    When get answers of typeql read query
      """
      match $p isa dog;
      """
    Then answer size is: 10


  Scenario Outline: an insert can attach multiple distinct values of the same <type> attribute to a single owner
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
      attribute <attr> value <type>;
      person owns <attr> @card(0..2);
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    When typeql write query
      """
      insert
      $x isa <attr> <val1>;
      $y isa <attr> <val2>;
      $p isa person, has name "Imogen", has ref 2, has <attr> <val1>, has <attr> <val2>;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $p isa person, has $x; $x isa <attr>; select $x;
      """
    Then uniquely identify answer concepts
      | x                  |
      | attr:<attr>:<val1> |
      | attr:<attr>:<val2> |

    Examples:
      | attr              | type     | val1       | val2       |
      | subject-taken     | string   | "Maths"    | "Physics"  |
      | lucky-number      | integer  | 10         | 3          |
      | recite-pi-attempt | double   | 3.146      | 3.14158    |
      | is-alive          | boolean  | true       | false      |
      | work-start-date   | datetime | 2018-01-01 | 2020-01-01 |


  Scenario: inserting an attribute onto a instance that can't have that attribute errors
    Then typeql write query; fails
      """
      insert
      $x isa company, has ref 0, has age 10;
      """

  @ignore-typeql
  Scenario: string attributes with newlines retain the newline character
    # these tests will include the spaces after the newline character, but we match indentation
    Given typeql write query
"""
insert
$p isa person, has name "Peter
Parker", has ref 0;
"""
    Given transaction commits
    When connection open read transaction for database: typedb
    When get answers of typeql read query
"""
match $p has name "Peter
Parker";
"""
    Then uniquely identify answer concepts
      | p         |
      | key:ref:0 |

  ########################################
  # ADDING ATTRIBUTES TO EXISTING instanceS #
  ########################################

  Scenario: when an entity owns an attribute, an additional value can be inserted on it
    Given typeql write query
      """
      insert
      $p isa person, has name "Peter Parker", has ref 0;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given get answers of typeql read query
      """
      match $p has name "Spiderman";
      """
    Given answer size is: 0
    When typeql write query
      """
      match
        $p isa person, has name "Peter Parker";
      insert
        $p has name "Spiderman";
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $p has name "Spiderman";
      """
    Then uniquely identify answer concepts
      | p         |
      | key:ref:0 |


  Scenario: when linking an attribute that doesn't exist yet to a relation, the attribute gets created
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
      relation residence
        relates resident,
        owns tenure-days,
        owns ref @key;
      person plays residence:resident;
      attribute tenure-days value integer;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    When typeql write query
      """
      insert
      $p isa person, has name "Homer", has ref 0;
      $r  isa residence, links (resident: $p), has ref 0;
      """
    Then transaction commits

    When connection open write transaction for database: typedb
    When get answers of typeql read query
      """
      match $td isa tenure-days;
      """
    Then answer size is: 0
    When typeql write query
      """
      match
        $r isa residence;
      insert
        $r has tenure-days 365;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $r isa residence, has tenure-days $a; select $a;
      """
    Then uniquely identify answer concepts
      | a                    |
      | attr:tenure-days:365 |

  #############
  # RELATIONS #
  #############

  Scenario: new relations can be inserted
    When typeql write query
      """
      insert
      $p isa person, has ref 0;
      $r isa employment, links (employee: $p), has ref 1;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $r isa employment, links (employee: $p);
      """
    Then uniquely identify answer concepts
      | p         | r         |
      | key:ref:0 | key:ref:1 |


  Scenario: relations can be inserted with multiple role players
    When typeql write query
      """
      insert
      $p1 isa person, has name "Gordon", has ref 0;
      $p2 isa person, has name "Helen", has ref 1;
      $c isa company, has name "Morrisons", has ref 2;
      $r isa employment, links (employer: $c, employee: $p1, employee: $p2), has ref 3;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
        (employer: $c) isa employment;
        $c has name $cname;
      select $cname;
      """
    Then uniquely identify answer concepts
      | cname               |
      | attr:name:Morrisons |
    When get answers of typeql read query
      """
      match
        (employee: $p) isa employment;
        $p has name $pname;
      select $pname;
      """
    #TODO: Appears unfinished?


  Scenario: an additional role player can be inserted onto an existing relation
    Given typeql write query
      """
      insert $p isa person, has ref 0; $r isa employment, links (employee: $p), has ref 1;
      """
    Given transaction commits

    When connection open write transaction for database: typedb
    When typeql write query
      """
      match
        $r isa employment;
      insert
        $r links (employer: $c);
        $c isa company, has ref 2;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $r isa employment, links (employer: $c, employee: $p);
      """
    Then uniquely identify answer concepts
      | p         | c         | r         |
      | key:ref:0 | key:ref:2 | key:ref:1 |


  Scenario: an additional role player can be inserted into every relation matching a pattern
    Given typeql write query
      """
      insert
      $p isa person, has name "Ruth", has ref 0;
      $r isa employment, links (employee: $p), has ref 1;
      $s isa employment, links (employee: $p), has ref 2;
      $c isa company, has name "The Boring Company", has ref 3;
      """
    Given transaction commits

    When connection open write transaction for database: typedb
    When typeql write query
      """
      match
        $r isa employment, has ref $ref;
        $c isa company;
      insert
        $r links (employer: $c);
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $r isa employment, links (employer: $c, employee: $p);
      """
    Then uniquely identify answer concepts
      | p         | c         | r         |
      | key:ref:0 | key:ref:3 | key:ref:1 |
      | key:ref:0 | key:ref:3 | key:ref:2 |


  # TODO: 3.x: Bring back when we have lists ( (employee: $p, employee: $p)
  @ignore
  Scenario: an additional repeated role player can be inserted into an existing relation
    Given typeql write query
      """
      insert $p isa person, has ref 0; $r isa employment, links (employee: $p), has ref 1;
      """
    Given transaction commits

    When connection open write transaction for database: typedb
    When typeql write query
      """
      match
        $r isa employment;
        $p isa person;
      insert
        $r links (employee: $p);
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $r isa employment, links (employee: $p, employee: $p);
      """
    Then uniquely identify answer concepts
      | p         | r         |
      | key:ref:0 | key:ref:1 |


  Scenario: a roleplayer can be inserted without explicitly specifying a role
    Given typeql write query
      """
      insert
      $r isa employment, links ($p), has ref 0;
      $p isa person, has ref 1;
      """
    Then transaction commits


  Scenario: a roleplayer can be inserted without explicitly specifying a role when the role is inherited
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
      relation part-time-employment sub employment;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Then typeql write query
      """
      insert
      $r isa part-time-employment, links ($p), has ref 0;
      $p isa person, has ref 1;
      """
    Then transaction commits


  Scenario: when inserting a roleplayer that can play more than one role, an error is returned
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
      person plays employment:employer;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    # TODO: error "unwrap() None"
    Then typeql write query; fails
      """
      insert
      $r isa employment, links ($p), has ref 0;
      $p isa person, has ref 1;
      """

  Scenario: when inserting a roleplayer that can't play the role, an error is returned
    Then typeql write query; fails
      """
      insert
      $r isa employment, links (employer: $p), has ref 0;
      $p isa person, has ref 1;
      """


  Scenario: parent types are not necessarily allowed to play the roles that their children play
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
      entity animal;
      entity cat sub animal, plays sphinx-production:model;
      relation sphinx-production relates model, relates builder;
      person plays sphinx-production:builder;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Then typeql write query; fails
      """
      insert
      $r isa sphinx-production, links (model: $x, builder: $y);
      $x isa animal;
      $y isa person, has ref 0;
      """


  Scenario: inserting a relation without a role player is allowed
    Then typeql write query
      """
      insert
      $x isa employment, has ref 0;
      """
    Given get answers of typeql read query
      """
      match $x isa employment, has ref 0;

      """
    Then answer size is: 1


  Scenario: an relation without a role player is deleted on transaction commit
    Then typeql write query
      """
      insert
      $x isa employment, has ref 0;
      """
    Then transaction commits
    Given connection open read transaction for database: typedb
    Given get answers of typeql read query
      """
      match
      $x isa employment, has ref 0;

      """
    Then answer size is: 0

  Scenario: when inserting a relation with an unbound variable as a roleplayer, an error is returned
    Then typeql write query; fails
      """
      insert
      $r isa employment, links (employee: $x, employer: $y), has ref 0;
      $y isa company, has name "Sports Direct", has ref 1;
      """

  #######################
  # ATTRIBUTE INSERTION #
  #######################

  Scenario Outline: inserting an attribute of type '<type>' creates an instance of it
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define attribute <attr> @independent, value <type>;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given get answers of typeql read query
      """
      match $x isa <attr> <value>;
      """
    Given answer size is: 0
    When typeql write query
      """
      insert $x isa <attr> <value>;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa <attr> <value>;
      """
    Then answer size is: 1
    Examples:
      | attr           | type     | value      |
      | title          | string   | "Prologue" |
      | page-number    | integer  | 233        |
      | price          | double   | 15.99      |
      | purchased      | boolean  | true       |
      | published-date | datetime | 2020-01-01 |


  Scenario Outline: Attributes of type '<type>' can be inserted via value variables
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define attribute <attr> @independent, value <type>;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given get answers of typeql read query
      """
      match $x isa <attr> <value>;
      """
    Given answer size is: 0
    When typeql write query
      """
      match let $x = <value>;
      insert $a isa <attr> == $x;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa <attr> <value>;
      """
    Then answer size is: 1
    Examples:
      | attr           | type     | value      |
      | title          | string   | "Prologue" |
      | page-number    | integer  | 233        |
      | price          | double   | 15.99      |
      | purchased      | boolean  | true       |
      | published-date | datetime | 2020-01-01 |


  Scenario: insert a regex attribute errors if not conforming to regex
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
      entity person
        owns description;
      attribute description
        value string @regex("\d{2}\.[true][false]");
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Then typeql write query; fails
      """
      insert
        $x isa person, has description "10.maybe", has ref 0;
      """


  Scenario: Datetime attribute can be inserted in one timezone and retrieved in another with no change in the value
    Given set time-zone: Asia/Calcutta
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql schema query
    """
    define
    attribute test_date @independent, value datetime;
    """
    Given transaction commits

    When connection open write transaction for database: typedb
    Then typeql write query
      """
      insert
      $time_date isa test_date 2023-05-01T00:00:00;
      """

    Given set time-zone: America/Chicago
    Given transaction commits
    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa test_date;
      """
    Then uniquely identify answer concepts
      | x                                  |
      | attr:test_date:2023-05-01T00:00:00 |

  Scenario: inserting two attributes with the same type and value creates only one concept
    When typeql write query
      """
      insert
      $x isa age 2;
      $y isa age 2;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa age;
      """
    Then uniquely identify answer concepts
      | x          |
      | attr:age:2 |


  Scenario: inserting two 'double' attribute values with the same integer value creates a single concept
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
      attribute length @independent, value double;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    When typeql write query
      """
      insert
      $x isa length 2;
      $y isa length 2;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa length;
      """
    Then answer size is: 1
    Then uniquely identify answer concepts
      | x               |
      | attr:length:2.0 |


  Scenario: inserting the same integer twice as a 'double' in separate transactions creates a single concept
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
      attribute length @independent, value double;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    When typeql write query
      """
      insert
      $x isa length 2;
      """
    Then transaction commits

    When connection open write transaction for database: typedb
    When typeql write query
      """
      insert
      $y isa length 2;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa length;
      """
    Then answer size is: 1
    Then uniquely identify answer concepts
      | x               |
      | attr:length:2.0 |


  Scenario: inserting attribute values [2] and [2.0] with the same attribute type creates a single concept
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
      attribute length @independent, value double;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    When typeql write query
      """
      insert
      $x isa length 2;
      $y isa length 2.0;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa length;
      """
    Then answer size is: 1


  Scenario Outline: a '<type>' inserted as [<value>] is retrieved when matching [<match>]
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define attribute <attr> @independent, value <type>;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    When get answers of typeql write query
      """
      insert $x isa <attr> <value>;
      """
    Then uniquely identify answer concepts
      | x                   |
      | attr:<attr>:<value> |
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa <attr> <match>;
      """
    Then uniquely identify answer concepts
      | x                   |
      | attr:<attr>:<value> |
    Examples:
      | type     | attr       | value            | match            |
      | integer  | shoe-size  | 92               | 92               |
      | integer  | shoe-size  | 92               | 92.00            |
      | double   | length     | 52               | 52               |
      | double   | length     | 52               | 52.00            |
      | double   | length     | 52.0             | 52               |
      | double   | length     | 52.0             | 52.00            |
      | datetime | start-date | 2019-12-26       | 2019-12-26       |
      | datetime | start-date | 2019-12-26       | 2019-12-26T00:00 |
      | datetime | start-date | 2019-12-26T00:00 | 2019-12-26       |
      | datetime | start-date | 2019-12-26T00:00 | 2019-12-26T00:00 |


  Scenario Outline: inserting [<value>] as a '<type>' errors
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define attribute <attr> @independent, value <type>;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Then typeql write query; fails
      """
      insert $x isa <attr> <value>;
      """
    Examples:
      | type     | attr       | value        |
      | string   | colour     | 92           |
      | string   | colour     | 92.8         |
      | string   | colour     | false        |
      | string   | colour     | 2019-12-26   |
      | integer  | shoe-size  | 28.5         |
      | integer  | shoe-size  | "28"         |
      | integer  | shoe-size  | true         |
      | integer  | shoe-size  | 2019-12-26   |
      | integer  | shoe-size  | 28.0         |
      | double   | length     | "28.0"       |
      | double   | length     | false        |
      | double   | length     | 2019-12-26   |
      | boolean  | is-alive   | 3            |
      | boolean  | is-alive   | -17.9        |
      | boolean  | is-alive   | 2019-12-26   |
      | boolean  | is-alive   | 1            |
      | boolean  | is-alive   | 0.0          |
      | boolean  | is-alive   | "true"       |
      | boolean  | is-alive   | "not true"   |
      | datetime | start-date | 1992         |
      | datetime | start-date | 3.14         |
      | datetime | start-date | false        |
      | datetime | start-date | "2019-12-26" |


  Scenario: inserting an attribute with no value errors
    Then typeql write query; fails
      """
      insert $x isa age;
      """


  Scenario: inserting an attribute value with no type errors
    Then typeql write query; parsing fails
      """
      insert $x 18;
      """


  Scenario: inserting an attribute with a predicate errors
    Then typeql write query; fails
      """
      insert $x isa age > 18;
      """

  #################
  # KEY OWNERSHIP #
  #################

  Scenario: a instance can be inserted with a key attribute
    When typeql write query
      """
      insert $x isa person, has ref 0;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa person;
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:0 |


  Scenario: when a type has a key, attempting to insert it without that key attribute errors on commit
    When typeql write query
      """
      insert $x isa person;
      """
    Then transaction commits; fails


  Scenario: inserting two distinct values of the same key attribute on a instance errors
    When typeql write query
      """
      insert $x isa person, has ref 0, has ref 1;
      """
    Then transaction commits; fails


  Scenario: instances of a key attribute must be unique among all instances of a type
    Then typeql write query; fails
      """
      insert
      $x isa person, has ref 0;
      $y isa person, has ref 0;
      """


  Scenario: instances of an inherited key attribute have to be unique among instances of a type and its subtypes
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
      attribute ref value integer;
      entity base owns ref @key;
      entity derived sub base;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb

    When typeql write query
      """
      insert $x isa base, has ref 0;
      """
    Then typeql write query; fails with a message containing: "'@unique' has been violated"
      """
      insert $y isa derived, has ref 0;
      """

    When transaction closes
    When connection open write transaction for database: typedb

    When typeql write query
      """
      insert $y isa derived, has ref 0;
      """
    Then typeql write query; fails with a message containing: "'@unique' has been violated"
      """
      insert $x isa base, has ref 0;
      """


  Scenario: instances of an inherited key attribute have to be unique among its subtypes
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
      attribute ref value integer;
      entity base owns ref @key;
      entity derived-a sub base;
      entity derived-b sub base;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb

    When typeql write query
      """
      insert $x isa derived-a, has ref 0;
      """
    Then typeql write query; fails with a message containing: "'@unique' has been violated"
      """
      insert $y isa derived-b, has ref 0;
      """


  Scenario: it is allowed to insert multiple entities owning same attribute with different keys
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
      person owns ref @key, owns name;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    When typeql write query
      """
      insert $p1 isa person, has name "john", has ref 0;
      """
    Then transaction commits

    When connection open write transaction for database: typedb
    Then typeql write query
      """
      insert $p2 isa person, has name "john", has ref 1;
      """
    Then transaction commits


  ####################
  # UNIQUE OWNERSHIP #
  ####################

  Scenario: a instance can be inserted with a unique attribute(s)
    When typeql write query
      """
      insert $x isa person, has ref 0, has email "abc@gmail.com";
      """
    Then transaction commits

    When connection open write transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa person, has email "abc@gmail.com";
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:0 |
    When typeql write query
      """
      insert $x isa person, has ref 1, has email "mnp@gmail.com", has email "xyz@gmail.com";
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa person, has email "mnp@gmail.com", has email "xyz@gmail.com";
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:1 |


  Scenario: two different owners cannot own the same unique attribute
    Then typeql write query; fails
      """
      insert
      $x isa person, has ref 0, has email "abc@gmail.com";
      $y isa person, has ref 1, has email "abc@gmail.com";
      """
    When transaction closes

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert $x isa person, has ref 0, has email "abc@gmail.com";
      """
    Then transaction commits
    Given connection open write transaction for database: typedb
    Then typeql write query; fails
      """
      insert $y isa person, has ref 1, has email "abc@gmail.com";
      """


  Scenario: inherited uniqueness is respected
    Given transaction closes
    Given connection open schema transaction for database: typedb

    Given typeql schema query
      """
      define
      entity child sub person;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert $x isa child, has email "abc@gmail.com", has email "xyz@gmail.com", has ref 0;
      """
    Then transaction commits
    Given connection open write transaction for database: typedb
    Then typeql write query; fails
      """
      insert $x isa child, has email "abc@gmail.com", has ref 1;
      """


  Scenario: specialised uniqueness is respected
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
      entity person @abstract;
      attribute email @abstract, value string;
      attribute email-outlook sub email;
      entity child sub person, owns email-outlook @card(0..2);
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert $x isa child, has email-outlook "abc@outlook.com", has email-outlook "xyz@outlook.com", has ref 0;
      """
    Then transaction commits
    Given connection open write transaction for database: typedb
    Then typeql write query; fails with a message containing: "'@unique' has been violated"
      """
      insert $x isa child, has email-outlook "abc@outlook.com", has ref 1;
      """


  Scenario: instances of an inherited unique attribute have to be unique among instances of the type and its subtypes
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
      entity child sub person;
      entity adult sub person;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Then typeql write query; fails with a message containing: "'@unique' has been violated"
      """
      insert
      $x isa child, has email "abc@gmail.com", has email "xyz@gmail.com", has ref 0;
      $y isa adult, has email "abc@gmail.com", has email "xyz@gmail.com", has ref 1;
      """


  ###########################
  # ANSWERS OF INSERT QUERY #
  ###########################

  Scenario: an insert with multiple instance variables returns a single answer that contains them all
    When get answers of typeql write query
      """
      insert
      $x isa person, has name "Bruce Wayne", has ref 0;
      $z isa company, has name "Wayne Enterprises", has ref 0;
      """

    Then uniquely identify answer concepts
      | x         | z         |
      | key:ref:0 | key:ref:0 |


  ################
  # MATCH-INSERT #
  ################

  Scenario: match-insert triggers one insert per answer of the match clause
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
      entity language owns name, owns is-cool, owns ref @key;
      attribute is-cool value boolean;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x isa language, has name "Norwegian", has ref 0;
      $y isa language, has name "Danish", has ref 1;
      """
    Given transaction commits
    Given connection open write transaction for database: typedb
    When typeql write query
      """
      match
        $x isa language;
      insert
        $x has is-cool true;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x has is-cool true;
      """
    #TODO: Appears unfinished


  Scenario: the answers of a match-insert only include the variables referenced in the 'insert' block
    Given typeql write query
      """
      insert
      $x isa person, has name "Eric", has ref 0;
      $y isa company, has name "Microsoft", has ref 1;
      $r isa employment, links (employee: $x, employer: $y), has ref 2;
      $z isa person, has name "Tarja", has ref 3;
      """
    Given transaction commits

    When connection open write transaction for database: typedb
    When get answers of typeql write query
      """
      match
        (employer: $x, employee: $z) isa employment, has ref $ref;
        $y isa person, has name "Tarja";
      insert
        (employer: $x, employee: $y) isa employment, has ref 10;
      """

    # Should only contain variables mentioned in the insert (so excludes '$z')
    Then uniquely identify answer concepts
      | x         | y         |
      | key:ref:1 | key:ref:3 |


  Scenario: match-insert can take an attribute's value and copy it to an attribute of a different type
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
      attribute height value integer;
      person owns height;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x isa person, has name "Susie", has age 16, has ref 0;
      $y isa person, has name "Donald", has age 25, has ref 1;
      $z isa person, has name "Ralph", has age 18, has ref 2;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      match
        $x isa person, has age 16;
      insert
        $x has height 16;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
        $x has height $z;
      select $x;
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:0 |


  Scenario: if match-insert matches nothing, then nothing is inserted
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
      relation season-ticket-ownership relates holder;
      person plays season-ticket-ownership:holder;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given get answers of typeql read query
      """
      match $p isa person;
      """
    Given answer size is: 0
    When typeql write query
      """
      match
        $p isa person;
      insert
        $r isa season-ticket-ownership, links (holder: $p);
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $r isa season-ticket-ownership;
      """
    Then answer size is: 0
    Given transaction closes


  Scenario: re-inserting a matched instance as an unrelated type errors
    Given typeql write query
      """
      insert
      $x isa person, has ref 0;
      """
    Then transaction commits

    When connection open write transaction for database: typedb
    Then typeql write query; fails
      """
      match
        $x isa person;
      insert
        $x isa company;
      """


  Scenario: inserting a new type on an existing instance that is a subtype of its existing type errors
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define entity child sub person;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert $x isa person, has ref 0;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    When typeql write query; fails
      """
      match
        $x isa person;
      insert
        $x isa child;
      """

  Scenario: inserting a new type on an existing instance that is a supertype of its existing type errors
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define entity child sub person;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert $x isa child, has ref 0;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    When typeql write query; fails
      """
      match
        $x isa child;
      insert
        $x isa person;
      """

  Scenario: inserting a new type on an existing instance that is unrelated to its existing type errors
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
        entity car;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert $x isa person, has ref 0;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    When typeql write query; fails
      """
      match
        $x isa person;
      insert
        $x isa car;
      """


  Scenario: variable types can be used in inserts
    Given typeql write query
      """
      match
      $p label person;
      $r label employment;
      insert
      $x isa $p, has ref 0;
      (employee: $x) isa $r, has ref 1;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      match
      $p label person;
      $r label employment;
      $rt label employment:employee;
      insert
      $x isa $p, has ref 2;
      ($rt: $x) isa $r, has ref 3;
      """
    Given transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
      $x isa person;
      $r isa employment, links ($x);
      """
    Then uniquely identify answer concepts
      | x         | r         |
      | key:ref:0 | key:ref:1 |
      | key:ref:2 | key:ref:3 |


  Scenario: variable types in inserts cannot be unbound
    Given typeql write query; fails
      """
      insert $x isa $t;
      """
    When transaction closes

    When connection open write transaction for database: typedb
    When typeql write query; fails
      """
      match
      $x isa person;
      insert
      $x has $a; $a isa $t;
      """

  Scenario: variable types in inserts cannot use aliased role types
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
      relation part-time-employment sub employment;
      """
    Given transaction commits

    When connection open write transaction for database: typedb
    Then typeql write query; fails
      """
      match
      $t label part-time-employment:employee;
      insert
      ($t: $x) isa part-time-employment;
      $x isa person;
      """

  #####################################
  # MATERIALISATION OF INFERRED FACTS #
  #####################################

  # Note: These tests have been placed here because Resolution Testing was not built to handle these kinds of cases
  #TODO: 3.x: Reenable when functions can run in a write transaction
  @ignore
  Scenario: when inserting a instance that has inferred concepts, those concepts are not automatically materialised
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
      person owns score;
      attribute score value double;
      rule ganesh-rule:
      when {
        $x isa person, has score $s;
        $s > 0.0;
      } then {
        $x has name "Ganesh";
      };
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x isa person, has ref 0, has score 1.0;
      """
    Then transaction commits

    When connection open write transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa name;
      """
    Then uniquely identify answer concepts
      | x                |
      | attr:name:Ganesh |
    When typeql delete
      """
      match
        $x isa person;
      delete
        $x isa person;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa name;
      """
    # If the name 'Ganesh' had been materialised, then it would still exist in the knowledge graph.
    Then answer size is: 0

  #TODO: 3.x: Reenable when functions can run in a write transaction
  @ignore
  Scenario: when inserting a instance with an inferred attribute ownership, the ownership is not automatically persisted
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
      person owns score;
      attribute score value double;
      rule copy-scores-to-all-people:
      when {
        $x isa person, has score $s;
        $y isa person;
        not { $x is $y; };
      } then {
        $y has $s;
      };
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x isa person, has ref 0, has name "Chris", has score 10.0;
      $y isa person, has ref 1, has name "Freya";
      """
    Then transaction commits

    When connection open write transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa person, has score $score;
      """
    Then uniquely identify answer concepts
      | x         | score           |
      | key:ref:0 | attr:score:10.0 |
      | key:ref:1 | attr:score:10.0 |
    When typeql delete
      """
      match
        $x isa person, has name "Chris";
      delete
        $x isa person;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa score;
      """
    # The score '10.0' still exists, we never deleted it
    Then uniquely identify answer concepts
      | x               |
      | attr:score:10.0 |
    When get answers of typeql read query
      """
      match $x isa person, has score $score;
      """
    # But Freya's ownership of score 10.0 was never materialised and is now gone
    Then answer size is: 0

  #TODO: 3.x: Reenable when functions can run in a write transaction
  #TODO: Reenable when rules actually do someinstance
  @ignore
  Scenario: when inserting instances connected to an inferred attribute, the inferred attribute gets materialised

  By explicitly inserting (x,y) is a relation, we are making explicit the fact that x and y both exist.

    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define

      relation name-initial
        relates lettered-name,
        relates initial;

      attribute score value double;
      attribute letter value string,
        plays name-initial:initial;

      name plays name-initial:lettered-name;
      person owns score;

      rule ganesh-rule:
      when {
        $x isa person, has score $s;
        $s > 0.0;
      } then {
        $x has name "Ganesh";
      };
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x isa person, has ref 0, has score 1.0;
      $y 'G' isa letter;
      """
    Then transaction commits

    When connection open write transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa name;
      """
    Then uniquely identify answer concepts
      | x                |
      | attr:name:Ganesh |
    # At this step we materialise the inferred name 'Ganesh' because the material name-initial relation depends on it.
    When typeql write query
      """
      match
        $p isa person, has name $x;
        $x 'Ganesh' isa name;
        $y 'G' isa letter;
      insert
        (lettered-name: $x, initial: $y) isa name-initial;
      """
    Then transaction commits

    When connection open write transaction for database: typedb
    When typeql delete
      """
      match
        $x isa person;
      delete
        $x isa person;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa person;
      """
    Then answer size is: 0
    When get answers of typeql read query
      """
      match $x isa name;
      """
    # We deleted the person called 'Ganesh', but the name still exists because it was materialised on match-insert
    Then uniquely identify answer concepts
      | x                |
      | attr:name:Ganesh |
    When get answers of typeql read query
      """
      match (lettered-name: $x, initial: $y) isa name-initial;
      """
    # And the inserted relation still exists too
    Then uniquely identify answer concepts
      | x                | y             |
      | attr:name:Ganesh | attr:letter:G |

  #TODO: 3.x: Reenable when functions can run in a write transaction
  @ignore
  Scenario: when inserting instances connected to an inferred relation, the inferred relation gets materialised
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      undefine
      employment owns ref;
      """
    Then transaction commits

    When connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define

      entity contract
        plays employment-contract:contract;

      relation employment-contract
        relates employment,
        relates contract;

      employment plays employment-contract:employment;

      rule henry-is-employed:
      when {
        $x isa person, has name "Henry";
      } then {
        (employee: $x) isa employment;
      };
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x isa person, has name "Henry", has ref 0;
      $c isa contract;
      """
    Then transaction commits

    When connection open write transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa employment;
      """
    Then answer size is: 1
    # At this step we materialise the inferred employment because the material employment-contract depends on it.
    When typeql write query
      """
      match
        $e isa employment;
        $c isa contract;
      insert
        (employment: $e, contract: $c) isa employment-contract;
      """
    Then transaction commits

    When connection open schema transaction for database: typedb
    When typeql schema query
      """
      undefine
      rule henry-is-employed;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa employment;
      """
    # We deleted the rule that infers the employment, but it still exists because it was materialised on match-insert
    Then answer size is: 1
    When get answers of typeql read query
      """
      match (contracted: $x, contract: $y) isa employment-contract;
      """
    # And the inserted relation still exists too
    Then answer size is: 1

  #TODO: 3.x: Reenable when functions can run in a write transaction
  @ignore
  Scenario: when inserting instances connected to a chain of inferred concepts, the whole chain is materialised
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define

      entity vertex
        owns index @key,
        plays link:coordinate,
        plays reachable:coordinate;

      relation link relates coordinate;

      relation reachable
        relates coordinate,
        plays road-proposal:connected-path;

      relation road-proposal
        relates connected-path,
        plays road-construction:proposal-to-construct;

      relation road-construction relates proposal-to-construct;

      attribute index value string;

#      rule a-linked-point-is-reachable:
#      when {
#        ($x, $y) isa link;
#      } then {
#        (coordinate: $x, coordinate: $y) isa reachable;
#      };
#
#      rule a-point-reachable-from-a-linked-point-is-reachable:
#      when {
#        ($x, $z) isa link;
#        ($z, $y) isa reachable;
#      } then {
#        (coordinate: $x, coordinate: $y) isa reachable;
#      };
#
#      rule propose-roads-between-reachable-points:
#      when {
#        $r isa reachable;
#      } then {
#        ($r) isa road-proposal;
#      };
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert

      $a isa vertex, has index "a";
      $b isa vertex, has index "b";
      $c isa vertex, has index "c";
      $d isa vertex, has index "d";

      (coordinate: $a, coordinate: $b) isa link;
      (coordinate: $b, coordinate: $c) isa link;
      (coordinate: $c, coordinate: $c) isa link;
      (coordinate: $c, coordinate: $d) isa link;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    When typeql write query
      """
      match
        $a isa vertex, has index "a";
        $d isa vertex, has index "d";
        $reach ($a, $d) isa reachable;
        $r ($reach) isa road-proposal;
      insert
        (proposal-to-construct: $r) isa road-construction;
      """
    Then transaction commits

    When connection open write transaction for database: typedb
    When typeql delete
      """
      match
        $r (coordinate: $c) isa link;
        $c isa vertex, has index "c";
      delete
        $r isa link;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    # After deleting all the links to 'c', our rules no integerer infer that 'd' is reachable from 'a'. But in fact we
    # materialised this reachable link when we did our match-insert, because it played a role in our road-proposal,
    # which itself plays a role in the road-construction that we explicitly inserted:
    When get answers of typeql read query
      """
      match
        $a isa vertex, has index "a";
        $d isa vertex, has index "d";
        $reach ($a, $d) isa reachable;
      """
    Then answer size is: 1
    # On the other hand, the fact that 'c' was reachable from 'a' was not -directly- used; although it was needed
    # in order to infer that (a,d) was reachable, it did not, itself, play a role in any relation that we materialised,
    # so it is now gone.
    When get answers of typeql read query
      """
      match
        $a isa vertex, has index "a";
        $c isa vertex, has index "c";
        $reach ($a, $c) isa reachable;
      """
    Then answer size is: 0


  ####################
  # TRANSACTIONALITY #
  ####################

  Scenario: if any insert in a transaction fails with a syntax error, none of the inserts are performed
    Given typeql write query
      """
      insert
      $x isa person, has name "Derek", has ref 0;
      """
    When typeql write query; parsing fails
      """
      insert
      $y qwertyuiop;
      """

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa person, has name "Derek";
      """
    Then answer size is: 0


  Scenario: if any insert in a transaction fails with a semantic error, none of the inserts are performed
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
      attribute capacity value integer;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x isa person, has name "Derek", has ref 0;
      """
    When typeql write query; fails
      """
      insert
      $y isa person, has name "Emily", has capacity 1000;
      """
    When transaction closes

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa person, has name "Derek";
      """
    Then answer size is: 0


  Scenario: if any insert in a transaction fails with a 'key' violation, none of the inserts are performed
    Given typeql write query
      """
      insert
      $x isa person, has name "Derek", has ref 0;
      """
    When typeql write query; fails
      """
      insert
      $y isa person, has name "Emily", has ref 0;
      """
    When transaction closes

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa person, has name "Derek";
      """
    Then answer size is: 0


  ##############
  # EDGE CASES #
  ##############

  Scenario: the 'iid' property is used internally by TypeDB and cannot be manually assigned
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
      entity bird;
      """
    Given transaction commits

    When connection open write transaction for database: typedb
    Then typeql write query; parsing fails
      """
      insert
      $x isa bird;
      $x iid V123;
      """
