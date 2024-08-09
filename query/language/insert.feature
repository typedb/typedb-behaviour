# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: TypeQL Insert Query

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

      entity person
        plays employment:employee,
        owns name  @card(0..),
        owns age,
        owns ref @key,
        owns email @unique;

      entity company
        plays employment:employer,
        owns name,
        owns ref @key;

      relation employment
        relates employee,
        relates employer,
        owns ref @key;

      attribute name
        value string;

      attribute age
        value long;

      attribute ref
        value long;

      attribute email
        value string;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given set time-zone is: Europe/London

  ####################
  # INSERTING THINGS #
  ####################

  Scenario: new entities can be inserted
    When typeql insert
      """
      insert $x isa person, has ref 0;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x isa person; get;
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:0 |


  Scenario: one query can insert multiple things
    When typeql insert
      """
      insert
      $x isa person, has ref 0;
      $y isa person, has ref 1;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x isa person; get;
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:0 |
      | key:ref:1 |


  Scenario: when an insert has multiple statements with the same variable name, they refer to the same thing
    When typeql insert
      """
      insert
      $x has name "Bond";
      $x has name "James Bond";
      $x isa person, has ref 0;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x has name "Bond"; get;
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:0 |
    When get answers of typeql get
      """
      match $x has name "James Bond"; get;
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:0 |
    When get answers of typeql get
      """
      match $x has name "Bond", has name "James Bond"; get;
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:0 |


  Scenario: when running multiple identical insert queries in series, new things get created each time
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql define
      """
      define
      attribute breed value string;
      entity dog owns breed;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given get answers of typeql get
      """
      match $x isa dog; get;
      """
    Given answer size is: 0
    When typeql insert
      """
      insert $x isa dog, has breed "Labrador";
      """
    Then transaction commits

    When connection open write transaction for database: typedb
    When get answers of typeql get
      """
      match $x isa dog; get;
      """
    Then answer size is: 1
    Then typeql insert
      """
      insert $x isa dog, has breed "Labrador";
      """
    Then transaction commits

    When connection open write transaction for database: typedb
    When get answers of typeql get
      """
      match $x isa dog; get;
      """
    Then answer size is: 2
    Then typeql insert
      """
      insert $x isa dog, has breed "Labrador";
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x isa dog; get;
      """
    Then answer size is: 3


  Scenario: an insert can be performed using a direct type specifier, and it functions equivalently to 'isa'
    When get answers of typeql insert
      """
      insert $x isa! person, has name "Harry", has ref 0;
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:0 |


  Scenario: attempting to insert an instance of an abstract type throws an error
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql define
      """
      define
      entity factory abstract;
      entity electronics-factory sub factory;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Then typeql insert; throws exception
      """
      insert $x isa factory;
      """


  Scenario: attempting to insert an instance of type 'thing' throws an error
    Then typeql insert; throws exception
      """
      insert $x isa thing;
      """



  #######################
  # ATTRIBUTE OWNERSHIP #
  #######################

  Scenario: when inserting a new thing that owns new attributes, both the thing and the attributes get created
    Given get answers of typeql get
      """
      match $x isa thing; get;
      """
    Given answer size is: 0
    When typeql insert
      """
      insert $x isa person, has name "Wilhelmina", has age 25, has ref 0;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x isa thing; get;
      """
    Then uniquely identify answer concepts
      | x                     |
      | key:ref:0             |
      | attr:name:Wilhelmina  |
      | attr:age:25           |
      | attr:ref:0            |

  Scenario: when inserting a new thing that owns new attributes via a value variable, both the thing and the attributes get created
    Given get answers of typeql get
      """
      match $x isa thing; get;
      """
    Given answer size is: 0
    When typeql insert
      """
      match  ?a = 25;
      insert $x isa person, has name "Wilhelmina", has age ?a, has ref 0;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x isa thing; get;
      """
    Then uniquely identify answer concepts
      | x                     |
      | key:ref:0             |
      | attr:name:Wilhelmina  |
      | attr:age:25           |
      | attr:ref:0            |


  Scenario: a freshly inserted attribute has no owners
    Given typeql insert
      """
      insert $name "John" isa name;
      """
    Given transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x has name "John"; get;
      """
    Then answer size is: 0


  Scenario: given an attribute with no owners, inserting a thing that owns it results in it having an owner
    Given typeql insert
      """
      insert $name "Kyle" isa name;
      """
    Given transaction commits

    When connection open write transaction for database: typedb
    Given typeql insert
      """
      insert $x isa person, has name "Kyle", has ref 0;
      """
    Given transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x has name "Kyle"; get;
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:0 |


  Scenario: after inserting two things that own the same attribute, the attribute has two owners
    When typeql insert
      """
      insert
      $p1 isa person, has name "Jack", has age 10, has ref 0;
      $p2 isa person, has name "Jill", has age 10, has ref 1;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match
      $p1 isa person, has age $a;
      $p2 isa person, has age $a;
      not { $p1 is $p2; };
      get $p1, $p2;
      """
    Then uniquely identify answer concepts
      | p1        | p2        |
      | key:ref:0 | key:ref:1 |
      | key:ref:1 | key:ref:0 |


  Scenario: after inserting a new owner for every existing ownership of an attribute, its number of owners doubles
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql define
      """
      define
      entity dog owns name;
      """
    Given transaction commits

    Given transaction closes
    Given connection open write transaction for database: typedb
    Given typeql insert
      """
      insert
      $p1 isa dog, has name "Frank";
      $p2 isa dog, has name "Geoff";
      $p3 isa dog, has name "Harriet";
      $p4 isa dog, has name "Ingrid";
      $p5 isa dog, has name "Jacob";
      """
    Given transaction commits

    Given transaction closes
    Given connection open write transaction for database: typedb
    When get answers of typeql get
      """
      match $p isa dog; get;
      """
    Then answer size is: 5
    When typeql insert
      """
      match
        $p has name $name;
      insert
        $p2 isa dog, has name $name;
      """
    Then transaction commits

    When connection open write transaction for database: typedb
    When get answers of typeql get
      """
      match $p isa dog; get;
      """
    Then answer size is: 10


  Scenario Outline: an insert can attach multiple distinct values of the same <type> attribute to a single owner
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql define
      """
      define
      attribute <attr> value <type>, owns ref @key;
      person owns <attr>;
      """
    Given transaction commits

    Given transaction closes
    Given connection open write transaction for database: typedb
    When typeql insert
      """
      insert
      $x <val1> isa <attr>, has ref 0;
      $y <val2> isa <attr>, has ref 1;
      $p isa person, has name "Imogen", has ref 2, has <attr> <val1>, has <attr> <val2>;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $p isa person, has <attr> $x; get $x;
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:0 |
      | key:ref:1 |

    Examples:
      | attr              | type     | val1       | val2       |
      | subject-taken     | string   | "Maths"    | "Physics"  |
      | lucky-number      | long     | 10         | 3          |
      | recite-pi-attempt | double   | 3.146      | 3.14158    |
      | is-alive          | boolean  | true       | false      |
      | work-start-date   | datetime | 2018-01-01 | 2020-01-01 |


  Scenario: inserting an attribute onto a thing that can't have that attribute throws an error
    Then typeql insert; throws exception
      """
      insert
      $x isa company, has ref 0, has age 10;
      """

  @ignore-typeql
  Scenario: string attributes with newlines retain the newline character
    # these tests will include the spaces after the newline character, but we match indentation
    Given typeql insert
"""
insert
$p isa person, has name "Peter
Parker", has ref 0;
"""
    Given transaction commits
    When connection open read transaction for database: typedb
    When get answers of typeql get
"""
match $p has name "Peter
Parker";
get;
"""
    Then uniquely identify answer concepts
      | p         |
      | key:ref:0 |

  ########################################
  # ADDING ATTRIBUTES TO EXISTING THINGS #
  ########################################

  Scenario: when an entity owns an attribute, an additional value can be inserted on it
    Given typeql insert
      """
      insert
      $p isa person, has name "Peter Parker", has ref 0;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given get answers of typeql get
      """
      match $p has name "Spiderman"; get;
      """
    Given answer size is: 0
    When typeql insert
      """
      match
        $p isa person, has name "Peter Parker";
      insert
        $p has name "Spiderman";
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $p has name "Spiderman"; get;
      """
    Then uniquely identify answer concepts
      | p         |
      | key:ref:0 |


  Scenario: when inserting an additional attribute ownership on an entity, the entity type can be optionally specified
    Given typeql insert
      """
      insert
      $p isa person, has name "Peter Parker", has ref 0;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given get answers of typeql get
      """
      match $p has name "Spiderman"; get;
      """
    Given answer size is: 0
    When typeql insert
      """
      match
        $p isa person, has name "Peter Parker";
      insert
        $p isa person, has name "Spiderman";
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $p has name "Spiderman"; get;
      """
    Then uniquely identify answer concepts
      | p         |
      | key:ref:0 |


  Scenario: when an attribute owns an attribute, an instance of that attribute can be inserted onto it
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql define
      """
      define
      attribute colour value string, owns hex-value;
      attribute hex-value value string;
      """
    Given transaction commits

    Given transaction closes
    Given connection open write transaction for database: typedb
    Given typeql insert
      """
      insert
      $c "red" isa colour;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given get answers of typeql get
      """
      match $c has hex-value "#FF0000"; get;
      """
    Given answer size is: 0
    When typeql insert
      """
      match
        $c "red" isa colour;
      insert
        $c has hex-value "#FF0000";
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $c has hex-value "#FF0000"; get;
      """
    Then uniquely identify answer concepts
      | c                |
      | attr:colour:red  |


  Scenario: when inserting an additional attribute ownership on an attribute, the owner type can be optionally specified
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql define
      """
      define
      attribute colour value string, owns hex-value;
      attribute hex-value value string;
      """
    Given transaction commits

    Given transaction closes
    Given connection open write transaction for database: typedb
    Given typeql insert
      """
      insert
      $c "red" isa colour;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given get answers of typeql get
      """
      match $c has hex-value "#FF0000"; get;
      """
    Given answer size is: 0
    When typeql insert
      """
      match
        $c "red" isa colour;
      insert
        $c isa colour, has hex-value "#FF0000";
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $c has hex-value "#FF0000"; get;
      """
    Then uniquely identify answer concepts
      | c                |
      | attr:colour:red  |


  Scenario: when linking an attribute that doesn't exist yet to a relation, the attribute gets created
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql define
      """
      define
      relation residence
        relates resident,
        relates place,
        owns tenure-days,
        owns ref @key;
      person plays residence:resident;
      attribute address value string, plays residence:place;
      attribute tenure-days value long;
      """
    Given transaction commits

    Given transaction closes
    Given connection open write transaction for database: typedb
    When typeql insert
      """
      insert
      $p isa person, has name "Homer", has ref 0;
      $addr "742 Evergreen Terrace" isa address;
      $r (resident: $p, place: $addr) isa residence, has ref 0;
      """
    Then transaction commits

    When connection open write transaction for database: typedb
    When get answers of typeql get
      """
      match $td isa tenure-days; get;
      """
    Then answer size is: 0
    When typeql insert
      """
      match
        $r isa residence;
      insert
        $r has tenure-days 365;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $r isa residence, has tenure-days $a; get $a;
      """
    Then uniquely identify answer concepts
      | a                     |
      | attr:tenure-days:365 |


  #TODO: Reenable when reasoning can run in a write transaction
  @ignore
  Scenario: an attribute ownership currently inferred by a rule can be explicitly inserted
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql define
      """
      define
      rule lucy-is-aged-32:
      when {
        $p isa person, has name "Lucy";
      } then {
        $p has age 32;
      };
      """
    Given transaction commits

    Given transaction closes
    Given connection open write transaction for database: typedb
    Given typeql insert
      """
      insert $p isa person, has name "Lucy", has ref 0;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given get answers of typeql get
      """
      match $p has age 32; get;
      """
    Given uniquely identify answer concepts
      | p         |
      | key:ref:0 |
    Given typeql insert
      """
      match
        $p has name "Lucy";
      insert
        $p has age 32;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $p has age 32; get;
      """
    Then uniquely identify answer concepts
      | p         |
      | key:ref:0 |


  #############
  # RELATIONS #
  #############

  Scenario: new relations can be inserted
    When typeql insert
      """
      insert
      $p isa person, has ref 0;
      $r (employee: $p) isa employment, has ref 1;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $r (employee: $p) isa employment; get;
      """
    Then uniquely identify answer concepts
      | p         | r         |
      | key:ref:0 | key:ref:1 |


  Scenario: when inserting a relation that owns an attribute and has an attribute roleplayer, both attributes are created
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql define
      """
      define
      relation residence
        relates resident,
        relates place,
        owns is-permanent,
        owns ref @key;
      person plays residence:resident;
      attribute address value string, plays residence:place;
      attribute is-permanent value boolean;
      """
    Given transaction commits

    Given transaction closes
    Given connection open write transaction for database: typedb
    When typeql insert
      """
      insert
      $p isa person, has name "Homer", has ref 0;
      $perm true isa is-permanent;
      $r (resident: $p, place: $addr) isa residence, has is-permanent $perm, has ref 0;
      $addr "742 Evergreen Terrace" isa address;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $r (place: $addr) isa residence, has is-permanent $perm; get;
      """
    Then uniquely identify answer concepts
      | r         | addr                                | perm                    |
      | key:ref:0 | attr:address:742 Evergreen Terrace  | attr:is-permanent:true  |


  Scenario: relations can be inserted with multiple role players
    When typeql insert
      """
      insert
      $p1 isa person, has name "Gordon", has ref 0;
      $p2 isa person, has name "Helen", has ref 1;
      $c isa company, has name "Morrisons", has ref 2;
      $r (employer: $c, employee: $p1, employee: $p2) isa employment, has ref 3;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match
        $r (employer: $c) isa employment;
        $c has name $cname;
      get $cname;
      """
    Then uniquely identify answer concepts
      | cname                |
      | attr:name:Morrisons  |
    When get answers of typeql get
      """
      match
        $r (employee: $p) isa employment;
        $p has name $pname;
      get $pname;
      """
    #TODO: Appears unfinished?


  Scenario: an additional role player can be inserted onto an existing relation
    Given typeql insert
      """
      insert $p isa person, has ref 0; $r (employee: $p) isa employment, has ref 1;
      """
    Given transaction commits

    When connection open write transaction for database: typedb
    When typeql insert
      """
      match
        $r isa employment;
      insert
        $r (employer: $c);
        $c isa company, has ref 2;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $r (employer: $c, employee: $p) isa employment; get;
      """
    Then uniquely identify answer concepts
      | p         | c         | r         |
      | key:ref:0 | key:ref:2 | key:ref:1 |


  Scenario: an additional role player can be inserted into every relation matching a pattern
    Given typeql insert
      """
      insert
      $p isa person, has name "Ruth", has ref 0;
      $r (employee: $p) isa employment, has ref 1;
      $s (employee: $p) isa employment, has ref 2;
      $c isa company, has name "The Boring Company", has ref 3;
      """
    Given transaction commits

    When connection open write transaction for database: typedb
    When typeql insert
      """
      match
        $r isa employment, has ref $ref;
        $c isa company;
      insert
        $r (employer: $c) isa employment;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $r (employer: $c, employee: $p) isa employment; get;
      """
    Then uniquely identify answer concepts
      | p         | c         | r         |
      | key:ref:0 | key:ref:3 | key:ref:1 |
      | key:ref:0 | key:ref:3 | key:ref:2 |


  Scenario: an additional repeated role player can be inserted into an existing relation
    Given typeql insert
      """
      insert $p isa person, has ref 0; $r (employee: $p) isa employment, has ref 1;
      """
    Given transaction commits

    When connection open write transaction for database: typedb
    When typeql insert
      """
      match
        $r isa employment;
        $p isa person;
      insert
        $r (employee: $p) isa employment;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $r (employee: $p, employee: $p) isa employment; get;
      """
    Then uniquely identify answer concepts
      | p         | r         |
      | key:ref:0 | key:ref:1 |


  Scenario: a roleplayer can be inserted without explicitly specifying a role
    Given typeql insert
      """
      insert
      $r ($p) isa employment, has ref 0;
      $p isa person, has ref 1;
      """
    Then transaction commits

  Scenario: a roleplayer can be inserted without explicitly specifying a role when the role is inherited
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql define
      """
      define
      relation part-time-employment sub employment;
      """
    Given transaction commits

    Given transaction closes
    Given connection open write transaction for database: typedb
    Then typeql insert
      """
      insert
      $r ($p) isa part-time-employment, has ref 0;
      $p isa person, has ref 1;
      """
    Then transaction commits

  Scenario: when inserting a roleplayer that can play more than one role, an error is thrown
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql define
      """
      define
      person plays employment:employer;
      """
    Given transaction commits

    Given transaction closes
    Given connection open write transaction for database: typedb
    Then typeql insert; throws exception
      """
      insert
      $r ($p) isa employment, has ref 0;
      $p isa person, has ref 1;
      """

  Scenario: when inserting a roleplayer that can't play the role, an error is thrown
    Then typeql insert; throws exception
      """
      insert
      $r (employer: $p) isa employment, has ref 0;
      $p isa person, has ref 1;
      """


  Scenario: parent types are not necessarily allowed to play the roles that their children play
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql define
      """
      define
      entity animal;
      entity cat sub animal, plays sphinx-production:model;
      relation sphinx-production relates model, relates builder;
      person plays sphinx-production:builder;
      """
    Given transaction commits

    Given transaction closes
    Given connection open write transaction for database: typedb
    Then typeql insert; throws exception
      """
      insert
      $r (model: $x, builder: $y) isa sphinx-production;
      $x isa animal;
      $y isa person, has ref 0;
      """


  Scenario: inserting a relation without a role player is allowed
    Then typeql insert
      """
      insert
      $x isa employment, has ref 0;
      """
    Given get answers of typeql get
      """
      match $x isa employment, has ref 0;
      get;
      """
    Then answer size is: 1


  Scenario: an relation without a role player is deleted on transaction commit
    Then typeql insert
      """
      insert
      $x isa employment, has ref 0;
      """
    Then transaction commits
    Given connection open read transaction for database: typedb
    Given get answers of typeql get
      """
      match
      $x isa employment, has ref 0;
      get;
      """
    Then answer size is: 0


  Scenario: when inserting a relation with an unbound variable as a roleplayer, an error is thrown
    Then typeql insert; throws exception
      """
      insert
      $r (employee: $x, employer: $y) isa employment, has ref 0;
      $y isa company, has name "Sports Direct", has ref 1;
      """


  #TODO: Reenable when rules actually do something
  @ignore
  Scenario: a relation currently inferred by a rule can be explicitly inserted
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql define
      """
      define
      relation gym-membership relates member;
      person plays gym-membership:member;
      rule jennifer-has-a-gym-membership:
      when {
        $p isa person, has name "Jennifer";
      } then {
        (member: $p) isa gym-membership;
      };
      """
    Given transaction commits

    Given transaction closes
    Given connection open write transaction for database: typedb
    When typeql insert
      """
      insert $p isa person, has name "Jennifer", has ref 0;
      """
    Then transaction commits

    When connection open write transaction for database: typedb
    When get answers of typeql get
      """
      match (member: $p) isa gym-membership; get $p; get;
      """
    Then typeql insert
      """
      match
        $p has name "Jennifer";
      insert
        $r (member: $p) isa gym-membership;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match (member: $p) isa gym-membership; get $p; get;
      """
    Then uniquely identify answer concepts
      | p         |
      | key:ref:0 |
    When get answers of typeql get
      """
      match $r isa gym-membership; get $r;
      """
    Then answer size is: 1


  #######################
  # ATTRIBUTE INSERTION #
  #######################

  Scenario Outline: inserting an attribute of type '<type>' creates an instance of it
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql define
      """
      define attribute <attr> value <type>, owns ref @key;
      """
    Given transaction commits

    Given transaction closes
    Given connection open write transaction for database: typedb
    Given get answers of typeql get
      """
      match $x <value> isa <attr>; get;
      """
    Given answer size is: 0
    When typeql insert
      """
      insert $x <value> isa <attr>, has ref 0;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x <value> isa <attr>; get;
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:0 |

    Examples:
      | attr           | type     | value      |
      | title          | string   | "Prologue" |
      | page-number    | long     | 233        |
      | price          | double   | 15.99      |
      | purchased      | boolean  | true       |
      | published-date | datetime | 2020-01-01 |


  Scenario Outline: Attributes of type '<type>' can be inserted via value variables
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql define
      """
      define attribute <attr> value <type>, owns ref @key;
      """
    Given transaction commits

    Given transaction closes
    Given connection open write transaction for database: typedb
    Given get answers of typeql get
      """
      match $x <value> isa <attr>; get;
      """
    Given answer size is: 0
    When typeql insert
      """
      match ?x = <value>;
      insert $a isa <attr>, has ref 0; $a == ?x;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x <value> isa <attr>; get;
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:0 |

    Examples:
      | attr           | type     | value      |
      | title          | string   | "Prologue" |
      | page-number    | long     | 233        |
      | price          | double   | 15.99      |
      | purchased      | boolean  | true       |
      | published-date | datetime | 2020-01-01 |


  Scenario: insert a regex attribute throws error if not conforming to regex
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql define
      """
      define
      entity person
        owns value;
      attribute value
        value string,
        regex "\d{2}\.[true][false]";
      """
    Given transaction commits

    Given transaction closes
    Given connection open write transaction for database: typedb
    Then typeql insert; throws exception
      """
      insert
        $x isa person, has value $a, has ref 0;
        $a "10.maybe";
      """

  Scenario: Datetime attribute can be inserted in one timezone and retrieved in another with no change in the value
    Given set time-zone is: Asia/Calcutta
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql define
    """
    define
    attribute test_date value datetime;
    """
    Given transaction commits

    Given transaction closes
    When connection open write transaction for database: typedb
    Then typeql insert
      """
      insert
      $time_date 2023-05-01T00:00:00 isa test_date;
      """

    Given set time-zone is: America/Chicago
    Given transaction commits
    Given connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x isa test_date; get;
      """
    Then uniquely identify answer concepts
      | x                                  |
      | attr:test_date:2023-05-01T00:00:00 |

  Scenario: inserting two attributes with the same type and value creates only one concept
    When typeql insert
      """
      insert
      $x 2 isa age;
      $y 2 isa age;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x isa age; get;
      """
    Then uniquely identify answer concepts
      | x           |
      | attr:age:2  |


  Scenario: inserting two 'double' attribute values with the same integer value creates a single concept
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql define
      """
      define
      attribute length value double;
      """
    Given transaction commits

    Given transaction closes
    Given connection open write transaction for database: typedb
    When typeql insert
      """
      insert
      $x 2 isa length;
      $y 2 isa length;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x isa length; get;
      """
    Then answer size is: 1
    Then uniquely identify answer concepts
      | x                |
      | attr:length:2.0  |


  Scenario: inserting the same integer twice as a 'double' in separate transactions creates a single concept
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql define
      """
      define
      attribute length value double;
      """
    Given transaction commits

    Given transaction closes
    Given connection open write transaction for database: typedb
    When typeql insert
      """
      insert
      $x 2 isa length;
      """
    Then transaction commits

    When connection open write transaction for database: typedb
    When typeql insert
      """
      insert
      $y 2 isa length;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x isa length; get;
      """
    Then answer size is: 1
    Then uniquely identify answer concepts
      | x                |
      | attr:length:2.0  |


  Scenario: inserting attribute values [2] and [2.0] with the same attribute type creates a single concept
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql define
      """
      define
      attribute length value double;
      """
    Given transaction commits

    Given transaction closes
    Given connection open write transaction for database: typedb
    When typeql insert
      """
      insert
      $x 2 isa length;
      $y 2.0 isa length;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x isa length; get;
      """
    Then answer size is: 1


  Scenario Outline: a '<type>' inserted as [<insert>] is retrieved when matching [<match>]
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql define
      """
      define attribute <attr> value <type>, owns ref @key;
      """
    Given transaction commits

    Given transaction closes
    Given connection open write transaction for database: typedb
    When get answers of typeql insert
      """
      insert $x <insert> isa <attr>, has ref 0;
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:0 |
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x <match> isa <attr>; get;
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:0 |

    Examples:
      | type     | attr       | insert           | match            |
      | long     | shoe-size  | 92               | 92               |
      | long     | shoe-size  | 92               | 92.00            |
      | double   | length     | 52               | 52               |
      | double   | length     | 52               | 52.00            |
      | double   | length     | 52.0             | 52               |
      | double   | length     | 52.0             | 52.00            |
      | datetime | start-date | 2019-12-26       | 2019-12-26       |
      | datetime | start-date | 2019-12-26       | 2019-12-26T00:00 |
      | datetime | start-date | 2019-12-26T00:00 | 2019-12-26       |
      | datetime | start-date | 2019-12-26T00:00 | 2019-12-26T00:00 |


  Scenario Outline: inserting [<value>] as a '<type>' throws an error
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql define
      """
      define attribute <attr> value <type>, owns ref @key;
      """
    Given transaction commits

    Given transaction closes
    Given connection open write transaction for database: typedb
    Then typeql insert; throws exception
      """
      insert $x <value> isa <attr>, has ref 0;
      """


    Examples:
      | type     | attr       | value        |
      | string   | colour     | 92           |
      | string   | colour     | 92.8         |
      | string   | colour     | false        |
      | string   | colour     | 2019-12-26   |
      | long     | shoe-size  | 28.5         |
      | long     | shoe-size  | "28"         |
      | long     | shoe-size  | true         |
      | long     | shoe-size  | 2019-12-26   |
      | long     | shoe-size  | 28.0         |
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


  Scenario: when inserting an attribute, the type and value can be specified in two individual statements
    When get answers of typeql insert
      """
      insert
      $x isa age;
      $x 10;
      """
    Then uniquely identify answer concepts
      | x            |
      | attr:age:10  |
    Then transaction commits


  Scenario: inserting an attribute with no value throws an error
    Then typeql insert; throws exception
      """
      insert $x isa age;
      """


  Scenario: inserting an attribute value with no type throws an error
    Then typeql insert; throws exception
      """
      insert $x 18;
      """


  Scenario: inserting an attribute with a predicate throws an error
    Then typeql insert; throws exception
      """
      insert $x > 18 isa age;
      """



  #################
  # KEY OWNERSHIP #
  #################

  Scenario: a thing can be inserted with a key attribute
    When typeql insert
      """
      insert $x isa person, has ref 0;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x isa person; get;
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:0 |


  Scenario: when a type has a key, attempting to insert it without that key attribute throws on commit
    When typeql insert
      """
      insert $x isa person;
      """
    Then transaction commits; throws exception


  Scenario: inserting two distinct values of the same key attribute on a thing throws an error
    Then typeql insert; throws exception
      """
      insert $x isa person, has ref 0, has ref 1;
      """


  Scenario: instances of a key attribute must be unique among all instances of a type
    Then typeql insert; throws exception
      """
      insert
      $x isa person, has ref 0;
      $y isa person, has ref 0;
      """


  Scenario: instances of an inherited key attribute don't have to be unique among instances of a type and its subtypes
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql define
      """
      define
      attribute ref value long;
      entity base owns ref @key;
      entity derived sub base;
      """
    Given transaction commits

    Given transaction closes
    Given connection open write transaction for database: typedb

    When typeql insert
      """
      insert $x isa base, has ref 0;
      """
    Then typeql insert
      """
      insert $y isa derived, has ref 0;
      """

    Given connection open write transaction for database: typedb

    When typeql insert
      """
      insert $y isa derived, has ref 0;
      """
    Then typeql insert
      """
      insert $x isa base, has ref 0;
      """


  Scenario: instances of an inherited key attribute don't have to be unique among its subtypes
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql define
      """
      define
      attribute ref value long;
      entity base owns ref @key;
      entity derived-a sub base;
      entity derived-b sub base;
      """
    Given transaction commits

    Given transaction closes
    Given connection open write transaction for database: typedb

    When typeql insert
      """
      insert $x isa derived-a, has ref 0;
      """
    Then typeql insert
      """
      insert $y isa derived-b, has ref 0;
      """


  Scenario: an error is thrown when inserting a second key attribute on an attribute that already has one
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql define
      """
      define
      name owns ref @key;
      """
    Given transaction commits

    Given transaction closes
    Given connection open write transaction for database: typedb
    When typeql insert
      """
      insert $a "john" isa name, has ref 0;
      """
    Then transaction commits

    When connection open write transaction for database: typedb
    Then typeql insert; throws exception
      """
      insert $a "john" isa name, has ref 1;
      """


  ####################
  # UNIQUE OWNERSHIP #
  ####################

  Scenario: a thing can be inserted with a unique attribute(s)
    When typeql insert
      """
      insert $x isa person, has ref 0, has email "abc@gmail.com";
      """
    Then transaction commits

    When connection open write transaction for database: typedb
    When get answers of typeql get
      """
      match $x isa person, has email "abc@gmail.com"; get;
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:0 |
    When typeql insert
      """
      insert $x isa person, has ref 1, has email "mnp@gmail.com", has email "xyz@gmail.com";
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x isa person, has email "mnp@gmail.com", has email "xyz@gmail.com"; get;
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:1 |


  Scenario: two different owners cannot own the same unique attribute
    Then typeql insert; throws exception
      """
      insert
      $x isa person, has ref 0, has email "abc@gmail.com";
      $y isa person, has ref 1, has email "abc@gmail.com";
      """
    Given connection open write transaction for database: typedb
    Given typeql insert
      """
      insert $x isa person, has ref 0, has email "abc@gmail.com";
      """
    Then transaction commits
    Given connection open write transaction for database: typedb
    Then typeql insert; throws exception
      """
      insert $y isa person, has ref 1, has email "abc@gmail.com";
      """


  Scenario: inherited uniqueness is respected
    Given transaction closes
    Given connection open schema transaction for database: typedb

    Given typeql define
      """
      define
      entity child sub person;
      """
    Given transaction commits
    Given transaction closes
    Given connection open write transaction for database: typedb
    Given typeql insert
      """
      insert $x isa child, has email "abc@gmail.com", has email "xyz@gmail.com", has ref 0;
      """
    Then transaction commits
    Given connection open write transaction for database: typedb
    Then typeql insert; throws exception
      """
      insert $x isa child, has email "abc@gmail.com", has ref 1;
      """


  Scenario: overridden uniqueness is respected
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql define
      """
      define
      entity person abstract;
      attribute email value string, abstract;
      attribute email-outlook sub email, value string;
      entity child sub person, owns email-outlook as email;
      """
    Given transaction commits
    Given transaction closes

    Given connection open write transaction for database: typedb
    Given typeql insert
      """
      insert $x isa child, has email-outlook "abc@outlook.com", has email-outlook "xyz@outlook.com", has ref 0;
      """
    Then transaction commits
    Given connection open write transaction for database: typedb
    Then typeql insert; throws exception
      """
      insert $x isa child, has email-outloko "abc@outlook.com", has ref 1;
      """


  Scenario: instances of an inherited unique attribute don't have to be unique among instances of the type and its subtypes
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql define
      """
      define
      entity child sub person;
      entity adult sub person;
      """
    Given transaction commits
    Given transaction closes
    Given connection open write transaction for database: typedb
    Given typeql insert
      """
      insert
      $x isa child, has email "abc@gmail.com", has email "xyz@gmail.com", has ref 0;
      $y isa adult, has email "abc@gmail.com", has email "xyz@gmail.com", has ref 1;
      """
    Then transaction commits


  ###########################
  # ANSWERS OF INSERT QUERY #
  ###########################

  Scenario: an insert with multiple thing variables returns a single answer that contains them all
    When get answers of typeql insert
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
    Given typeql define
      """
      define
      entity language owns name, owns is-cool, owns ref @key;
      attribute is-cool value boolean;
      """
    Given transaction commits

    Given transaction closes
    Given connection open write transaction for database: typedb
    Given typeql insert
      """
      insert
      $x isa language, has name "Norwegian", has ref 0;
      $y isa language, has name "Danish", has ref 1;
      """
    Given transaction commits
    Given connection open write transaction for database: typedb
    When typeql insert
      """
      match
        $x isa language;
      insert
        $x has is-cool true;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x has is-cool true; get;
      """
    #TODO: Appears unfinished


  Scenario: the answers of a match-insert only include the variables referenced in the 'insert' block
    Given typeql insert
      """
      insert
      $x isa person, has name "Eric", has ref 0;
      $y isa company, has name "Microsoft", has ref 1;
      $r (employee: $x, employer: $y) isa employment, has ref 2;
      $z isa person, has name "Tarja", has ref 3;
      """
    Given transaction commits

    When connection open write transaction for database: typedb
    When get answers of typeql insert
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
    Given typeql define
      """
      define
      attribute height value long;
      person owns height;
      """
    Given transaction commits

    Given transaction closes
    Given connection open write transaction for database: typedb
    Given typeql insert
      """
      insert
      $x isa person, has name "Susie", has age 16, has ref 0;
      $y isa person, has name "Donald", has age 25, has ref 1;
      $z isa person, has name "Ralph", has age 18, has ref 2;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql insert
      """
      match
        $x isa person, has age 16;
      insert
        $x has height 16;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match
        $x has height $z;
      get $x;
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:0 |


  Scenario: if match-insert matches nothing, then nothing is inserted
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql define
      """
      define
      relation season-ticket-ownership relates holder;
      person plays season-ticket-ownership:holder;
      """
    Given transaction commits

    Given transaction closes
    Given connection open write transaction for database: typedb
    Given get answers of typeql get
      """
      match $p isa person; get;
      """
    Given answer size is: 0
    When typeql insert
      """
      match
        $p isa person;
      insert
        $r (holder: $p) isa season-ticket-ownership;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $r isa season-ticket-ownership; get;
      """
    Then answer size is: 0


  Scenario: match-inserting only existing entities is a no-op
    Given get answers of typeql insert
      """
      insert
      $x isa person, has name "Rebecca", has ref 0;
      $y isa person, has name "Steven", has ref 1;
      $z isa person, has name "Theresa", has ref 2;
      """
    Given uniquely identify answer concepts
      | x         | y         | z         |
      | key:ref:0 | key:ref:1 | key:ref:2 |
    Then transaction commits

    When connection open write transaction for database: typedb
    Given get answers of typeql get
      """
      match $x isa person; get;
      """
    Given uniquely identify answer concepts
      | x         |
      | key:ref:0 |
      | key:ref:1 |
      | key:ref:2 |
    When typeql insert
      """
      match
        $x isa person;
      insert
        $x isa person;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x isa person; get;
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:0 |
      | key:ref:1 |
      | key:ref:2 |


  Scenario: match-inserting only existing relations is a no-op
    Given get answers of typeql insert
      """
      insert
      $x isa person, has name "Homer", has ref 0;
      $y isa person, has name "Burns", has ref 1;
      $z isa person, has name "Smithers", has ref 2;
      $c isa company, has name "Springfield Nuclear Power Plant", has ref 3;
      $xr (employee: $x, employer: $c) isa employment, has ref 4;
      $yr (employee: $y, employer: $c) isa employment, has ref 5;
      $zr (employee: $z, employer: $c) isa employment, has ref 6;
      """
    Given uniquely identify answer concepts
      | x         | y         | z         | c         | xr        | yr        | zr        |
      | key:ref:0 | key:ref:1 | key:ref:2 | key:ref:3 | key:ref:4 | key:ref:5 | key:ref:6 |
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given get answers of typeql get
      """
      match $r (employee: $x, employer: $c) isa employment; get;
      """
    Given uniquely identify answer concepts
      | r         | x         | c         |
      | key:ref:4 | key:ref:0 | key:ref:3 |
      | key:ref:5 | key:ref:1 | key:ref:3 |
      | key:ref:6 | key:ref:2 | key:ref:3 |
    When typeql insert
      """
      match
        $x isa employment;
      insert
        $x isa employment;
      """
    Then transaction commits

    When connection open write transaction for database: typedb
    When get answers of typeql get
      """
      match $r (employee: $x, employer: $c) isa employment; get;
      """
    Then uniquely identify answer concepts
      | r         | x         | c         |
      | key:ref:4 | key:ref:0 | key:ref:3 |
      | key:ref:5 | key:ref:1 | key:ref:3 |
      | key:ref:6 | key:ref:2 | key:ref:3 |


  Scenario: match-inserting only existing attributes is a no-op
    Given get answers of typeql insert
      """
      insert
      $x "Ash" isa name;
      $y "Misty" isa name;
      $z "Brock" isa name;
      """
    Given uniquely identify answer concepts
      | x              | y                | z                |
      | attr:name:Ash  | attr:name:Misty  | attr:name:Brock  |
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given get answers of typeql get
      """
      match $x isa name; get;
      """
    Given uniquely identify answer concepts
      | x                |
      | attr:name:Ash    |
      | attr:name:Misty  |
      | attr:name:Brock  |
    When typeql insert
      """
      match
        $x isa name;
      insert
        $x isa name;
      """
    Then transaction commits

    Given connection open write transaction for database: typedb
    When get answers of typeql get
      """
      match $x isa name; get;
      """
    Then uniquely identify answer concepts
      | x                |
      | attr:name:Ash    |
      | attr:name:Misty  |
      | attr:name:Brock  |


  Scenario: re-inserting a matched instance does nothing
    Given typeql insert
      """
      insert
      $x isa person, has ref 0;
      """
    Then transaction commits

    When connection open write transaction for database: typedb
    Then typeql insert
      """
      match
        $x isa person;
      insert
        $x isa person;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x isa person; get;
      """
    Then answer size is: 1


  Scenario: re-inserting a matched instance as an unrelated type throws an error
    Given typeql insert
      """
      insert
      $x isa person, has ref 0;
      """
    Then transaction commits

    When connection open write transaction for database: typedb
    Then typeql insert; throws exception
      """
      match
        $x isa person;
      insert
        $x isa company;
      """


  Scenario: inserting a new type on an existing instance that is a subtype of its existing type throws
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql define
      """
      define entity child sub person;
      """
    Given transaction commits

    Given transaction closes
    Given connection open write transaction for database: typedb
    Given typeql insert
      """
      insert $x isa person, has ref 0;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    When typeql insert; throws exception
      """
      match
        $x isa person;
      insert
        $x isa child;
      """

  Scenario: inserting a new type on an existing instance that is a supertype of its existing type throws
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql define
      """
      define entity child sub person;
      """
    Given transaction commits

    Given transaction closes
    Given connection open write transaction for database: typedb
    Given typeql insert
      """
      insert $x isa child, has ref 0;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    When typeql insert; throws exception
      """
      match
        $x isa child;
      insert
        $x isa person;
      """

  Scenario: inserting a new type on an existing instance that is unrelated to its existing type throws
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql define
      """
      define
        entity car;
      """
    Given transaction commits

    Given transaction closes
    Given connection open write transaction for database: typedb
    Given typeql insert
      """
      insert $x isa person, has ref 0;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    When typeql insert; throws exception
      """
      match
        $x isa person;
      insert
        $x isa car;
      """


  Scenario: variable types can be used in inserts
    Given typeql insert
      """
      match
      $p type person;
      $r type employment;
      insert
      $x isa $p, has ref 0;
      (employee: $x) isa $r, has ref 1;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql insert
      """
      match
      $p type person;
      $r type employment;
      $rt type employment:employee;
      insert
      $x isa $p, has ref 2;
      ($rt: $x) isa $r, has ref 3;
      """
    Given transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match
      $x isa person;
      $r ($x) isa employment;
      get;
      """
    Then uniquely identify answer concepts
      | x         | r         |
      | key:ref:0 | key:ref:1 |
      | key:ref:2 | key:ref:3 |


  Scenario: variable types in inserts cannot be unbound
    Given typeql insert; throws exception
      """
      insert $x isa $t;
      """
    When connection open write transaction for database: typedb
    When typeql insert; throws exception
      """
      match
      $x isa person;
      insert
      $x has $a; $a isa $t;
      """

  Scenario: variable types in inserts cannot use aliased role types
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql define
      """
      define
      relation part-time-employment sub employment;
      """
    Given transaction commits
    Given transaction closes

    When connection open write transaction for database: typedb
    Then typeql insert; throws exception
      """
      match
      $t type part-time-employment:employee;
      insert
      ($t: $x) isa part-time-employment;
      $x isa person;
      """

  #####################################
  # MATERIALISATION OF INFERRED FACTS #
  #####################################

  # Note: These tests have been placed here because Resolution Testing was not built to handle these kinds of cases
  #TODO: Reenable when reasoning can run in a write transaction
  @ignore
  Scenario: when inserting a thing that has inferred concepts, those concepts are not automatically materialised
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql define
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

    Given transaction closes
    Given connection open write transaction for database: typedb
    Given typeql insert
      """
      insert
      $x isa person, has ref 0, has score 1.0;
      """
    Then transaction commits

    When connection open write transaction for database: typedb
    When get answers of typeql get
      """
      match $x isa name; get;
      """
    Then uniquely identify answer concepts
      | x                 |
      | attr:name:Ganesh  |
    When typeql delete
      """
      match
        $x isa person;
      delete
        $x isa person;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x isa name; get;
      """
    # If the name 'Ganesh' had been materialised, then it would still exist in the knowledge graph.
    Then answer size is: 0

  #TODO: Reenable when reasoning can run in a write transaction
  @ignore
  Scenario: when inserting a thing with an inferred attribute ownership, the ownership is not automatically persisted
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql define
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

    Given transaction closes
    Given connection open write transaction for database: typedb
    Given typeql insert
      """
      insert
      $x isa person, has ref 0, has name "Chris", has score 10.0;
      $y isa person, has ref 1, has name "Freya";
      """
    Then transaction commits

    When connection open write transaction for database: typedb
    When get answers of typeql get
      """
      match $x isa person, has score $score; get;
      """
    Then uniquely identify answer concepts
      | x         | score            |
      | key:ref:0 | attr:score:10.0  |
      | key:ref:1 | attr:score:10.0  |
    When typeql delete
      """
      match
        $x isa person, has name "Chris";
      delete
        $x isa person;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x isa score; get;
      """
    # The score '10.0' still exists, we never deleted it
    Then uniquely identify answer concepts
      | x                |
      | attr:score:10.0  |
    When get answers of typeql get
      """
      match $x isa person, has score $score; get;
      """
    # But Freya's ownership of score 10.0 was never materialised and is now gone
    Then answer size is: 0

  #TODO: Reenable when rules actually do something
  @ignore
  Scenario: when inserting things connected to an inferred attribute, the inferred attribute gets materialised

  By explicitly inserting (x,y) is a relation, we are making explicit the fact that x and y both exist.

    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql define
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

    Given transaction closes
    Given connection open write transaction for database: typedb
    Given typeql insert
      """
      insert
      $x isa person, has ref 0, has score 1.0;
      $y 'G' isa letter;
      """
    Then transaction commits

    When connection open write transaction for database: typedb
    When get answers of typeql get
      """
      match $x isa name; get;
      """
    Then uniquely identify answer concepts
      | x                 |
      | attr:name:Ganesh  |
    # At this step we materialise the inferred name 'Ganesh' because the material name-initial relation depends on it.
    When typeql insert
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
    When get answers of typeql get
      """
      match $x isa person; get;
      """
    Then answer size is: 0
    When get answers of typeql get
      """
      match $x isa name; get;
      """
    # We deleted the person called 'Ganesh', but the name still exists because it was materialised on match-insert
    Then uniquely identify answer concepts
      | x                 |
      | attr:name:Ganesh  |
    When get answers of typeql get
      """
      match (lettered-name: $x, initial: $y) isa name-initial; get;
      """
    # And the inserted relation still exists too
    Then uniquely identify answer concepts
      | x                 | y              |
      | attr:name:Ganesh  | attr:letter:G  |

  #TODO: Reenable when reasoning can run in a write transaction
  @ignore
  Scenario: when inserting things connected to an inferred relation, the inferred relation gets materialised
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql undefine
      """
      undefine
      employment owns ref;
      """
    Then transaction commits

    When connection open schema transaction for database: typedb
    Given typeql define
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

    Given transaction closes
    Given connection open write transaction for database: typedb
    Given typeql insert
      """
      insert
      $x isa person, has name "Henry", has ref 0;
      $c isa contract;
      """
    Then transaction commits

    When connection open write transaction for database: typedb
    When get answers of typeql get
      """
      match $x isa employment; get;
      """
    Then answer size is: 1
    # At this step we materialise the inferred employment because the material employment-contract depends on it.
    When typeql insert
      """
      match
        $e isa employment;
        $c isa contract;
      insert
        (employment: $e, contract: $c) isa employment-contract;
      """
    Then transaction commits

    When connection open schema transaction for database: typedb
    When typeql undefine
      """
      undefine
      rule henry-is-employed;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x isa employment; get;
      """
    # We deleted the rule that infers the employment, but it still exists because it was materialised on match-insert
    Then answer size is: 1
    When get answers of typeql get
      """
      match (contracted: $x, contract: $y) isa employment-contract; get;
      """
    # And the inserted relation still exists too
    Then answer size is: 1

  #TODO: Reenable when reasoning can run in a write transaction
  @ignore
  Scenario: when inserting things connected to a chain of inferred concepts, the whole chain is materialised
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql define
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

    Given transaction closes
    Given connection open write transaction for database: typedb
    Given typeql insert
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
    When typeql insert
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
    # After deleting all the links to 'c', our rules no longer infer that 'd' is reachable from 'a'. But in fact we
    # materialised this reachable link when we did our match-insert, because it played a role in our road-proposal,
    # which itself plays a role in the road-construction that we explicitly inserted:
    When get answers of typeql get
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
    When get answers of typeql get
      """
      match
        $a isa vertex, has index "a";
        $c isa vertex, has index "c";
        $reach ($a, $c) isa reachable;
      """
    Then answer size is: 0


  Scenario: when matching two disjoint instances of distinct types but only selecting one to insert a pattern, inserts will only happen for the selected instance
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql undefine
      """
      undefine
      person owns ref;
      company owns ref;
      employment owns ref;
      """
    Given transaction commits

    Given transaction closes
    Given connection open write transaction for database: typedb
    Given typeql insert
      """
      insert
      $x isa person;
      $y isa company;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    When typeql insert
      """
      match
        $x isa person;
        $y isa company;
      insert
        $z isa person;
        (employee: $z, employer: $y) isa employment;
      """
    Then transaction commits

    When connection open write transaction for database: typedb
    When typeql insert
      """
      match
        $x isa person;
        $y isa company;
      insert
        $z isa person;
        (employee: $z, employer: $y) isa employment;
      """
    Then transaction commits

    When connection open write transaction for database: typedb
    When typeql insert
      """
      match
        $x isa person;
        $y isa company;
      insert
        $z isa person;
        (employee: $z, employer: $y) isa employment;
      """
    Then transaction commits

    When connection open write transaction for database: typedb
    When typeql insert
      """
      match
        $x isa person;
        $y isa company;
      insert
        $z isa person;
        (employee: $z, employer: $y) isa employment;
      """
    Then transaction commits

    When connection open write transaction for database: typedb
    When typeql insert
      """
      match
        $x isa person;
        $y isa company;
      insert
        $z isa person;
        (employee: $z, employer: $y) isa employment;
      """
    Then transaction commits

    When connection open write transaction for database: typedb
    When typeql insert
      """
      match
        $x isa person;
        $y isa company;
      insert
        $z isa person;
        (employee: $z, employer: $y) isa employment;
      """
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x isa person; get;
      """
    Then answer size is: 7
    When get answers of typeql get
      """
      match $x isa employment; get;
      """
    # The original person is still unemployed.
    Then answer size is: 6

  ####################
  # TRANSACTIONALITY #
  ####################

  Scenario: if any insert in a transaction fails with a syntax error, none of the inserts are performed
    Given typeql insert
      """
      insert
      $x isa person, has name "Derek", has ref 0;
      """
    When typeql insert; throws exception
      """
      insert
      $y qwertyuiop;
      """

    When connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x isa person, has name "Derek"; get;
      """
    Then answer size is: 0


  Scenario: if any insert in a transaction fails with a semantic error, none of the inserts are performed
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql define
      """
      define
      attribute capacity value long;
      """
    Given transaction commits

    Given transaction closes
    Given connection open write transaction for database: typedb
    Given typeql insert
      """
      insert
      $x isa person, has name "Derek", has ref 0;
      """
    When typeql insert; throws exception
      """
      insert
      $y isa person, has name "Emily", has capacity 1000;
      """

    Given connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x isa person, has name "Derek"; get;
      """
    Then answer size is: 0


  Scenario: if any insert in a transaction fails with a 'key' violation, none of the inserts are performed
    Given typeql insert
      """
      insert
      $x isa person, has name "Derek", has ref 0;
      """
    When typeql insert; throws exception
      """
      insert
      $y isa person, has name "Emily", has ref 0;
      """

    When connection open read transaction for database: typedb
    When get answers of typeql get
      """
      match $x isa person, has name "Derek"; get;
      """
    Then answer size is: 0


  ##############
  # EDGE CASES #
  ##############

  Scenario: the 'iid' property is used internally by TypeDB and cannot be manually assigned
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql define
      """
      define
      entity bird;
      """
    Given transaction commits

    Given transaction closes
    When connection open write transaction for database: typedb
    Then typeql insert; throws exception
      """
      insert
      $x isa bird;
      $x iid V123;
      """

