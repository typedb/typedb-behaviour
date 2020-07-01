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
Feature: Graql Insert Query

  Background: Open connection
    Given connection has been opened
    Given connection delete all keyspaces
    Given connection open sessions for keyspaces:
      | test_insert |
    Given transaction is initialised
    Given the integrity is validated
    Given graql define
      """
      define

      person sub entity,
        plays employee,
        has name,
        has age,
        key ref;

      company sub entity,
        plays employer,
        has name,
        key ref;

      employment sub relation,
        relates employee,
        relates employer,
        key ref;

      name sub attribute,
        value string;

      age sub attribute,
        value long;

      ref sub attribute,
        value long;
      """
    Given the integrity is validated


  ####################
  # INSERTING THINGS #
  ####################

  Scenario: inserting a thing creates an instance of it
    When graql insert
      """
      insert $x isa person, has ref 0;
      """
    When the integrity is validated

    When get answers of graql query
      """
      match $x isa person; get;
      """
    Then concept identifiers are
      |     | check | value |
      | PER | key   | ref:0 |
    Then uniquely identify answer concepts
      | x   |
      | PER |


  Scenario: one query can insert multiple things
    When graql insert
      """
      insert
      $x isa person, has ref 0;
      $y isa person, has ref 1;
      """
    When the integrity is validated

    When get answers of graql query
      """
      match $x isa person; get;
      """
    Then concept identifiers are
      |      | check | value |
      | REF0 | key   | ref:0 |
      | REF1 | key   | ref:1 |
    Then uniquely identify answer concepts
      | x    |
      | REF0 |
      | REF1 |


  Scenario: when an insert has multiple statements with the same variable name, they refer to the same thing
    When graql insert
      """
      insert
      $x has name "Bond";
      $x has name "James Bond";
      $x isa person, has ref 0;
      """
    When the integrity is validated
    Then get answers of graql query
      """
      match
        $x has name "Bond";
      get;
      """
    Then concept identifiers are
      |      | check | value |
      | BOND | key   | ref:0 |
    Then uniquely identify answer concepts
      | x    |
      | BOND |
    Then get answers of graql query
      """
      match
        $x has name "James Bond";
      get;
      """
    Then uniquely identify answer concepts
      | x    |
      | BOND |
    Then get answers of graql query
      """
      match
        $x has name "Bond", has name "James Bond";
      get;
      """
    Then uniquely identify answer concepts
      | x    |
      | BOND |


  Scenario: when running multiple identical insert queries in series, new things get created each time
    Given graql define
      """
      define
      breed sub attribute, value string;
      dog sub entity, has breed;
      """
    Given the integrity is validated
    Given get answers of graql query
      """
      match $x isa dog; get;
      """
    Given answer size is: 0
    When graql insert
      """
      insert $x isa dog, has breed "Labrador";
      """
    When the integrity is validated
    Then get answers of graql query
      """
      match $x isa dog; get;
      """
    Then answer size is: 1
    Then graql insert
      """
      insert $x isa dog, has breed "Labrador";
      """
    Then the integrity is validated
    Then get answers of graql query
      """
      match $x isa dog; get;
      """
    Then answer size is: 2
    Then graql insert
      """
      insert $x isa dog, has breed "Labrador";
      """
    Then the integrity is validated
    Then get answers of graql query
      """
      match $x isa dog; get;
      """
    Then answer size is: 3


  Scenario: an insert can be performed using a direct type specifier, and it functions equivalently to `isa`
    When get answers of graql insert
      """
      insert $x isa! person, has name "Harry", has ref 0;
      """
    Then the integrity is validated
    When concept identifiers are
      |     | check | value |
      | HAR | key   | ref:0 |
    Then uniquely identify answer concepts
      | x   |
      | HAR |


  Scenario: attempting to insert an instance of an abstract type throws an error
    Given graql define
      """
      define
      factory sub entity, abstract;
      electronics-factory sub factory;
      """
    Given the integrity is validated
    Then graql insert throws
      """
      insert $x isa factory;
      """
    Then the integrity is validated


  Scenario: attempting to insert an instance of type 'thing' throws an error
    Then graql insert throws
      """
      insert $x isa thing;
      """
    Then the integrity is validated


  #######################
  # ATTRIBUTE OWNERSHIP #
  #######################

  Scenario: when inserting a new thing that owns new attributes, both the thing and the attributes get created
    Given get answers of graql query
      """
      match $x isa thing; get;
      """
    Given answer size is: 0
    When graql insert
      """
      insert $x isa person, has name "Wilhelmina", has age 25, has ref 0;
      """
    When the integrity is validated
    Then get answers of graql query
      """
      match $x isa thing; get;
      """
    Then concept identifiers are
      |      | check | value           |
      | WIL  | key   | ref:0           |
      | nWIL | value | name:Wilhelmina |
      | a25  | value | age:25          |
      | REF0 | value | ref:0           |
    Then uniquely identify answer concepts
      | x    |
      | WIL  |
      | nWIL |
      | a25  |
      | REF0 |


  Scenario: a freshly inserted attribute has no owners
    Given graql insert
      """
      insert $name "John" isa name;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x has name "John"; get;
      """
    Then answer size is: 0


  Scenario: given an attribute with no owners, inserting a thing that owns it results in it having an owner
    Given graql insert
      """
      insert $name "Kyle" isa name;
      """
    Given the integrity is validated
    Given graql insert
      """
      insert $x isa person, has name "Kyle", has ref 0;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x has name "Kyle"; get;
      """
    Then concept identifiers are
      |      | check | value |
      | KYLE | key   | ref:0 |
    Then uniquely identify answer concepts
      | x    |
      | KYLE |


  Scenario: after inserting two things that own the same attribute, the attribute has two owners
    When graql insert
      """
      insert
      $p1 isa person, has name "Jack", has age 10, has ref 0;
      $p2 isa person, has name "Jill", has age 10, has ref 1;
      """
    When the integrity is validated
    Then get answers of graql query
      """
      match
      $p1 isa person, has age $a;
      $p2 isa person, has age $a;
      $p1 != $p2;
      get $p1, $p2;
      """
    Then concept identifiers are
      |      | check | value |
      | JACK | key   | ref:0 |
      | JILL | key   | ref:1 |
    Then uniquely identify answer concepts
      | p1   | p2   |
      | JACK | JILL |
      | JILL | JACK |


  Scenario: after inserting a new owner for every existing ownership of an attribute, its number of owners doubles
    Given graql define
      """
      define
      dog sub entity, has name;
      """
    Given the integrity is validated
    Given graql insert
      """
      insert
      $p1 isa dog, has name "Frank";
      $p2 isa dog, has name "Geoff";
      $p3 isa dog, has name "Harriet";
      $p4 isa dog, has name "Ingrid";
      $p5 isa dog, has name "Jacob";
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $p isa dog; get;
      """
    Then answer size is: 5
    Then graql insert
      """
      match
        $p has name $name;
      insert
        $p2 isa dog, has name $name;
      """
    Then the integrity is validated
    Then get answers of graql query
      """
      match $p isa dog; get;
      """
    Then answer size is: 10


  Scenario Outline: an insert can attach multiple distinct values of the same <type> attribute to a single owner
    Given graql define
      """
      define
      <attr> sub attribute, value <type>, key ref;
      person has <attr>;
      """
    Given the integrity is validated
    When graql insert
      """
      insert
      $x <val1> isa <attr>, has ref 0;
      $y <val2> isa <attr>, has ref 1;
      $p isa person, has name "Imogen", has ref 2, has <attr> <val1>, has <attr> <val2>;
      """
    When the integrity is validated
    When get answers of graql query
      """
      match $p isa person, has <attr> $x; get $x;
      """
    Then concept identifiers are
      |      | check | value |
      | VAL1 | key   | ref:0 |
      | VAL2 | key   | ref:1 |
    Then uniquely identify answer concepts
      | x    |
      | VAL1 |
      | VAL2 |

  Examples:
    | attr              | type     | val1       | val2       |
    | subject-taken     | string   | "Maths"    | "Physics"  |
    | lucky-number      | long     | 10         | 3          |
    | recite-pi-attempt | double   | 3.146      | 3.14158    |
    | is-alive          | boolean  | true       | false      |
    | work-start-date   | datetime | 2018-01-01 | 2020-01-01 |


  Scenario: inserting an attribute onto a thing that can't have that attribute throws an error
    Then graql insert throws
      """
      insert
      $x isa company, has ref 0, has age 10;
      """
    Then the integrity is validated


  ########################################
  # ADDING ATTRIBUTES TO EXISTING THINGS #
  ########################################

  Scenario: when an entity owns an attribute, an additional value can be inserted on it
    Given graql insert
      """
      insert
      $p isa person, has name "Peter Parker", has ref 0;
      """
    Given the integrity is validated
    Given get answers of graql query
      """
      match $p has name "Spiderman"; get;
      """
    Given answer size is: 0
    When graql insert
      """
      match
        $p isa person, has name "Peter Parker";
      insert
        $p has name "Spiderman";
      """
    When the integrity is validated
    Then get answers of graql query
      """
      match $p has name "Spiderman"; get;
      """
    Then concept identifiers are
      |     | check | value |
      | PET | key   | ref:0 |
    Then uniquely identify answer concepts
      | p   |
      | PET |


  Scenario: when inserting an additional attribute value on an entity, the entity type can be optionally specified
    Given graql insert
      """
      insert
      $p isa person, has name "Peter Parker", has ref 0;
      """
    Given the integrity is validated
    Given get answers of graql query
      """
      match $p has name "Spiderman"; get;
      """
    Given answer size is: 0
    When graql insert
      """
      match
        $p isa person, has name "Peter Parker";
      insert
        $p isa person, has name "Spiderman";
      """
    When the integrity is validated
    Then get answers of graql query
      """
      match $p has name "Spiderman"; get;
      """
    Then concept identifiers are
      |     | check | value |
      | PET | key   | ref:0 |
    Then uniquely identify answer concepts
      | p   |
      | PET |


  Scenario: when an attribute owns an attribute, an additional value can be inserted on it
    Given graql define
      """
      define
      colour sub attribute, value string, has hex-value;
      hex-value sub attribute, value string;
      """
    Given the integrity is validated
    Given graql insert
      """
      insert
      $c "red" isa colour;
      """
    Given the integrity is validated
    Given get answers of graql query
      """
      match $c has hex-value "#FF0000"; get;
      """
    Given answer size is: 0
    When graql insert
      """
      match
        $c "red" isa colour;
      insert
        $c has hex-value "#FF0000";
      """
    When the integrity is validated
    Then get answers of graql query
      """
      match $c has hex-value "#FF0000"; get;
      """
    Then concept identifiers are
      |     | check | value      |
      | COL | value | colour:red |
    Then uniquely identify answer concepts
      | c   |
      | COL |


  Scenario: when inserting an additional attribute value on an attribute, the type of the owning attribute can be optionally specified
    Given graql define
      """
      define
      colour sub attribute, value string, has hex-value;
      hex-value sub attribute, value string;
      """
    Given the integrity is validated
    Given graql insert
      """
      insert
      $c "red" isa colour;
      """
    Given the integrity is validated
    Given get answers of graql query
      """
      match $c has hex-value "#FF0000"; get;
      """
    Given answer size is: 0
    When graql insert
      """
      match
        $c "red" isa colour;
      insert
        $c isa colour, has hex-value "#FF0000";
      """
    When the integrity is validated
    Then get answers of graql query
      """
      match $c has hex-value "#FF0000"; get;
      """
    Then concept identifiers are
      |     | check | value      |
      | COL | value | colour:red |
    Then uniquely identify answer concepts
      | c   |
      | COL |


  Scenario: when linking an attribute that doesn't exist yet to a relation, the attribute gets created
    Given graql define
      """
      define
      residence sub relation,
        relates resident,
        relates place-of-residence,
        has tenure-days,
        key ref;
      person plays resident;
      address sub attribute, value string, plays place-of-residence;
      tenure-days sub attribute, value long;
      """
    Given the integrity is validated
    When graql insert
      """
      insert
      $p isa person, has name "Homer", has ref 0;
      $addr "742 Evergreen Terrace" isa address;
      $r (resident: $p, place-of-residence: $addr) isa residence, has ref 0;
      """
    When the integrity is validated
    When get answers of graql query
      """
      match $td isa tenure-days; get;
      """
    Then answer size is: 0
    Then graql insert
      """
      match
        $r isa residence;
      insert
        $r has tenure-days 365;
      """
    Then get answers of graql query
      """
      match $r isa residence, has tenure-days $a; get $a;
      """
    Then concept identifiers are
      |     | check | value           |
      | RES | key   | ref:0           |
      | TEN | value | tenure-days:365 |
    Then uniquely identify answer concepts
      | a   |
      | TEN |


  Scenario: an attribute ownership currently inferred by a rule can be explicitly inserted
    Given graql define
      """
      define
      lucy-is-aged-32 sub rule,
      when {
        $p isa person, has name "Lucy";
      }, then {
        $p has age 32;
      };
      """
    Given the integrity is validated
    Given graql insert
      """
      insert $p isa person, has name "Lucy", has ref 0;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $p has age 32; get;
      """
    Then concept identifiers are
      |      | check | value |
      | LUCY | key   | ref:0 |
    Then graql insert
      """
      match
        $p has name "Lucy";
      insert
        $p has age 32;
      """
    Then the integrity is validated
    Then get answers of graql query
      """
      match $p has age 32; get;
      """
    Then uniquely identify answer concepts
      | p    |
      | LUCY |


  #############
  # RELATIONS #
  #############

  Scenario: inserting a relation creates an instance of it
    Given graql insert
      """
      insert
      $p isa person, has ref 0;
      $r (employee: $p) isa employment, has ref 1;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $r (employee: $p) isa employment; get;
      """
    Then concept identifiers are
      |     | check | value |
      | PER | key   | ref:0 |
      | EMP | key   | ref:1 |
    Then uniquely identify answer concepts
      | p   | r   |
      | PER | EMP |


  Scenario: when inserting a relation that owns an attribute and has an attribute roleplayer, both attributes are created
    Given graql define
      """
      define
      residence sub relation,
        relates resident,
        relates place-of-residence,
        has is-permanent,
        key ref;
      person plays resident;
      address sub attribute, value string, plays place-of-residence;
      is-permanent sub attribute, value boolean;
      """
    Given the integrity is validated
    When graql insert
      """
      insert
      $p isa person, has name "Homer", has ref 0;
      $perm true isa is-permanent;
      $r (resident: $p, place-of-residence: $addr) isa residence, has is-permanent $perm, has ref 0;
      $addr "742 Evergreen Terrace" isa address;
      """
    When the integrity is validated
    Then get answers of graql query
      """
      match $r (place-of-residence: $addr) isa residence, has is-permanent $perm; get;
      """
    Then concept identifiers are
      |     | check | value                         |
      | RES | key   | ref:0                         |
      | ADD | value | address:742 Evergreen Terrace |
      | PER | value | is-permanent:true             |
    Then uniquely identify answer concepts
      | r   | addr | perm |
      | RES | ADD  | PER  |


  Scenario: when inserting a relation with multiple role players, they are all added
    When graql insert
      """
      insert
      $p1 isa person, has name "Gordon", has ref 0;
      $p2 isa person, has name "Helen", has ref 1;
      $c isa company, has name "Morrisons", has ref 2;
      $r (employer: $c, employee: $p1, employee: $p2) isa employment, has ref 3;
      """
    When the integrity is validated
    When get answers of graql query
      """
      match
        $r (employer: $c) isa employment;
        $c has name $cname;
      get $cname;
      """
    Then concept identifiers are
      |     | check | value          |
      | MOR | value | name:Morrisons |
    Then uniquely identify answer concepts
      | cname |
      | MOR   |
    When get answers of graql query
      """
      match
        $r (employee: $p) isa employment;
        $p has name $pname;
      get $pname;
      """
    Then concept identifiers are
      |     | check | value       |
      | GOR | value | name:Gordon |
      | HEL | value | name:Helen  |


  Scenario: an additional role player can be inserted into a relation
    Given graql insert
      """
      insert $p isa person, has ref 0; $r (employee: $p) isa employment, has ref 1;
      """
    Given the integrity is validated
    When graql insert
      """
      match
        $r isa employment;
      insert
        $r (employer: $c) isa employment;
        $c isa company, has ref 2;
      """
    When the integrity is validated
    Then get answers of graql query
      """
      match $r (employer: $c, employee: $p) isa employment; get;
      """
    Then concept identifiers are
      |      | check | value |
      | REF0 | key   | ref:0 |
      | REF1 | key   | ref:1 |
      | REF2 | key   | ref:2 |
    Then uniquely identify answer concepts
      | p    | c    | r    |
      | REF0 | REF2 | REF1 |


  Scenario: an additional role player can be inserted into every relation matching a pattern
    Given graql insert
      """
      insert
      $p isa person, has name "Ruth", has ref 0;
      $r (employee: $p) isa employment, has ref 1;
      $s (employee: $p) isa employment, has ref 2;
      $c isa company, has name "The Boring Company", has ref 3;
      """
    Given the integrity is validated
    When graql insert
      """
      match
        $r isa employment, has ref $ref;
        $c isa company;
      insert
        $r (employer: $c) isa employment;
      """
    When the integrity is validated
    Then get answers of graql query
      """
      match $r (employer: $c, employee: $p) isa employment; get;
      """
    Then concept identifiers are
      |      | check | value |
      | RUTH | key   | ref:0 |
      | EMP1 | key   | ref:1 |
      | EMP2 | key   | ref:2 |
      | COMP | key   | ref:3 |
    Then uniquely identify answer concepts
      | p    | c    | r    |
      | RUTH | COMP | EMP1 |
      | RUTH | COMP | EMP2 |


  Scenario: an additional duplicate role player can be inserted into a relation
    Given graql insert
      """
      insert $p isa person, has ref 0; $r (employee: $p) isa employment, has ref 1;
      """
    Given the integrity is validated
    When graql insert
      """
      match
        $r isa employment;
        $p isa person;
      insert
        $r (employee: $p) isa employment;
      """
    When the integrity is validated
    Then get answers of graql query
      """
      match $r (employee: $p, employee: $p) isa employment; get;
      """
    Then concept identifiers are
      |      | check | value |
      | REF0 | key   | ref:0 |
      | REF1 | key   | ref:1 |
    Then uniquely identify answer concepts
      | p    | r    |
      | REF0 | REF1 |


  Scenario: inserting a roleplayer in a relation that can't have that roleplayer throws on commit
    When graql define
      """
      define
      tennis-group sub relation, relates tennis-player;
      person plays tennis-player;
      """
    When the integrity is validated
    Then graql insert throws
      """
      insert
      $r (tennis-player: $p) isa employment, has ref 0;
      $p isa person, has ref 1;
      """
    Then the integrity is validated


  Scenario: inserting a roleplayer that can't play the role throws on commit
    Then graql insert throws
      """
      insert
      $r (employer: $p) isa employment, has ref 0;
      $p isa person, has ref 1;
      """
    Then the integrity is validated


  Scenario: inserting a roleplayer that is only the parent of a valid type is invalid and throws on commit
    When graql define
      """
      define
      animal sub entity;
      cat sub animal, plays sphinx-model;
      sphinx-production sub relation, relates sphinx-model, relates sphinx-builder;
      person plays sphinx-builder;
      """
    When the integrity is validated
    Then graql insert throws
      """
      insert
      $r (sphinx-model: $x, sphinx-builder: $y) isa sphinx-production;
      $x isa animal;
      $y isa person, has ref 0;
      """
    Then the integrity is validated


  Scenario: inserting a relation with no role players throws on commit
    Then graql insert throws
      """
      insert
      $x isa employment, has ref 0;
      """
    Then the integrity is validated


  Scenario: inserting a relation with an empty variable as a roleplayer throws an error
    Then graql insert throws
      """
      insert
      $r (employee: $x, employer: $y) isa employment, has ref 0;
      $y isa company, has name "Sports Direct", has ref 1;
      """


  Scenario: a relation currently inferred by a rule can be explicitly inserted
    Given graql define
      """
      define
      gym-membership sub relation, relates gym-member;
      person plays gym-member;
      jennifer-has-a-gym-membership sub rule,
      when {
        $p isa person, has name "Jennifer";
      }, then {
        (gym-member: $p) isa gym-membership;
      };
      """
    Given the integrity is validated
    Given graql insert
      """
      insert $p isa person, has name "Jennifer", has ref 0;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match (gym-member: $p) isa gym-membership; get $p;
      """
    Then concept identifiers are
      |     | check | value |
      | JEN | key   | ref:0 |
    Then graql insert
      """
      match
        $p has name "Jennifer";
      insert
        $r (gym-member: $p) isa gym-membership;
      """
    Then the integrity is validated
    Then get answers of graql query
      """
      match (gym-member: $p) isa gym-membership; get $p;
      """
    Then uniquely identify answer concepts
      | p   |
      | JEN |
    Then get answers of graql query
      """
      match $r isa gym-membership; get $r;
      """
    Then answer size is: 1


  #######################
  # ATTRIBUTE INSERTION #
  #######################

  Scenario Outline: inserting an attribute of type `<type>` creates an instance of it
    Given graql define
      """
      define <attr> sub attribute, value <type>, key ref;
      """
    Given the integrity is validated
    Given get answers of graql query
      """
      match $x <value> isa <attr>; get;
      """
    Given answer size is: 0
    When graql insert
      """
      insert $x <value> isa <attr>, has ref 0;
      """
    When the integrity is validated
    When get answers of graql query
      """
      match $x <value> isa <attr>; get;
      """
    Then concept identifiers are
      |     | check | value |
      | ATT | key   | ref:0 |
    Then uniquely identify answer concepts
      | x   |
      | ATT |

    Examples:
      | attr           | type     | value      |
      | title          | string   | "Prologue" |
      | page-number    | long     | 233        |
      | price          | double   | 15.99      |
      | purchased      | boolean  | true       |
      | published-date | datetime | 2020-01-01 |


  Scenario: inserting a subtype of an attribute with the same value creates a separate instance
    Given graql define
      """
      define first-name sub name;
      """
    Given the integrity is validated
    When graql insert
      """
      insert
      $x "Alan" isa name;
      $y "Alan" isa first-name;
      """
    When the integrity is validated
    When get answers of graql query
      """
      match $x isa name; get $x;
      """
    Then concept identifiers are
      |     | check | value           |
      | NAM | value | name:Alan       |
      | FNA | value | first-name:Alan |
    Then uniquely identify answer concepts
      | x   |
      | NAM |
      | FNA |


  Scenario: insert a regex attribute throws error if not conforming to regex
    Given graql define
      """
      define
      person sub entity,
        has value;
      value sub attribute,
        value string,
        regex "\d{2}\.[true][false]";
      """
    Given the integrity is validated

    Then graql insert throws
      """
      insert
        $x isa person, has value $a, has ref 0;
        $a "10.maybe";
      """
    Then the integrity is validated


  Scenario: inserting two attributes with the same type and value creates a single concept
    When graql insert
      """
      insert
      $x 2 isa age;
      $y 2 isa age;
      """
    When concept identifiers are
      |      | check | value |
      | AGE2 | value | age:2 |
    When get answers of graql query
      """
      match $x isa age; get;
      """
    Then uniquely identify answer concepts
      | x    |
      | AGE2 |


  @ignore
  # TODO: re-enable in 1.9
  Scenario: inserting two `double` attribute values with the same integer value creates a single concept
    Given graql define
      """
      define
      length sub attribute, value double;
      """
    Given the integrity is validated
    When graql insert
      """
      insert
      $x 2 isa length;
      $y 2 isa length;
      """
    When concept identifiers are
      |     | check | value      |
      | L2  | value | length:2.0 |
    When get answers of graql query
      """
      match $x isa length; get;
      """
    Then answer size is: 1
    Then uniquely identify answer concepts
      | x   |
      | L2  |


  Scenario: inserting the same integer twice as a `double` in separate transactions creates a single concept
    Given graql define
      """
      define
      length sub attribute, value double;
      """
    Given the integrity is validated
    When graql insert
      """
      insert
      $x 2 isa length;
      """
    Then the integrity is validated
    When graql insert
      """
      insert
      $y 2 isa length;
      """
    Then the integrity is validated
    When concept identifiers are
      |     | check | value      |
      | L2  | value | length:2.0 |
    When get answers of graql query
      """
      match $x isa length; get;
      """
    Then answer size is: 1
    Then uniquely identify answer concepts
      | x   |
      | L2  |


  Scenario: inserting attribute values [2] and [2.0] with the same attribute type creates a single concept
    Given graql define
      """
      define
      length sub attribute, value double;
      """
    Given the integrity is validated
    When graql insert
      """
      insert
      $x 2 isa length;
      $y 2.0 isa length;
      """
    When the integrity is validated
    When get answers of graql query
      """
      match $x isa length; get;
      """
    Then answer size is: 1


  Scenario Outline: a `<type>` inserted as [<insert>] is retrieved when matching [<match>]
    Given graql define
      """
      define <attr> sub attribute, value <type>, key ref;
      """
    Given the integrity is validated
    When get answers of graql insert
      """
      insert $x <insert> isa <attr>, has ref 0;
      """
    Then the integrity is validated
    When concept identifiers are
      |     | check | value |
      | RF0 | key   | ref:0 |
    Then uniquely identify answer concepts
      | x   |
      | RF0 |
    When get answers of graql query
      """
      match $x <match> isa <attr>; get;
      """
    Then uniquely identify answer concepts
      | x   |
      | RF0 |

    Examples:
      | type     | attr       | insert           | match            |
      | long     | shoe-size  | 92               | 92               |
      | long     | shoe-size  | 92               | 92.00            |
      | long     | shoe-size  | 92.0             | 92               |
      | long     | shoe-size  | 92.0             | 92.00            |
      | double   | length     | 52               | 52               |
      | double   | length     | 52               | 52.00            |
      | double   | length     | 52.0             | 52               |
      | double   | length     | 52.0             | 52.00            |
      | datetime | start-date | 2019-12-26       | 2019-12-26       |
      | datetime | start-date | 2019-12-26       | 2019-12-26T00:00 |
      | datetime | start-date | 2019-12-26T00:00 | 2019-12-26       |
      | datetime | start-date | 2019-12-26T00:00 | 2019-12-26T00:00 |


  Scenario Outline: inserting [<value>] as a `<type>` throws an error
    Given graql define
      """
      define <attr> sub attribute, value <type>, key ref;
      """
    Given the integrity is validated
    Then graql insert throws
      """
      insert $x <value> isa <attr>, has ref 0;
      """
    Then the integrity is validated

    Examples:
      | type     | attr       | value        |
      | string   | colour     | 92           |
      | string   | colour     | 92.8         |
      | string   | colour     | false        |
      | string   | colour     | 2019-12-26   |
      | long     | shoe-size  | "28"         |
      | long     | shoe-size  | true         |
      | long     | shoe-size  | 2019-12-26   |
      | double   | length     | "28.0"       |
      | double   | length     | false        |
      | double   | length     | 2019-12-26   |
      | boolean  | is-alive   | 3            |
      | boolean  | is-alive   | -17.9        |
      | boolean  | is-alive   | 2019-12-26   |
      | datetime | start-date | 1992         |
      | datetime | start-date | 3.14         |
      | datetime | start-date | false        |
      | datetime | start-date | "2019-12-26" |
    @ignore
    # TODO: re-enable when only true and false are accepted as boolean values (issue #5803)
    Examples:
      | boolean  | is-alive   | 1            |
      | boolean  | is-alive   | 0.0          |
      | boolean  | is-alive   | "true"       |
      | boolean  | is-alive   | "not true"   |


  Scenario: inserting an attribute with no value throws an error
    Then graql insert throws
      """
      insert $x isa age;
      """
    Then the integrity is validated


  Scenario: inserting an attribute value with no type throws an error
    Then graql insert throws
      """
      insert $x 18;
      """
    Then the integrity is validated


  Scenario: inserting an attribute with a predicate throws an error
    Then graql insert throws
      """
      insert $x > 18 isa age;
      """
    Then the integrity is validated


  ########
  # KEYS #
  ########

  Scenario: a thing can be inserted with a key
    When graql insert
      """
      insert $x isa person, has ref 0;
      """
    When the integrity is validated

    When get answers of graql query
      """
      match $x isa person; get;
      """
    Then concept identifiers are
      |     | check | value |
      | PER | key   | ref:0 |
    Then uniquely identify answer concepts
      | x   |
      | PER |


  Scenario: when a type has a key, attempting to insert it without that key throws on commit
    Then graql insert throws
      """
      insert $x isa person;
      """
    Then the integrity is validated


  Scenario: inserting two distinct values of the same key on a thing throws on commit
    Then graql insert throws
      """
      insert $x isa person, has ref 0, has ref 1;
      """
    Then the integrity is validated


  Scenario: instances of a key must be unique among all instances of a type
    Then graql insert throws
      """
      insert
      $x isa person, has ref 0;
      $y isa person, has ref 0;
      """
    Then the integrity is validated


  @ignore
  # TODO: re-enable in 1.9
  Scenario: [2] and [2.0] are considered to be the same value when validating key uniqueness
    Given graql define
      """
      define
      cat sub entity, key dref;
      dref sub attribute, value double;
      """
    Given the integrity is validated
    Then graql insert throws
      """
      insert
      $x isa cat, has dref 2;
      $y isa cat, has dref 2.0;
      """
    Then the integrity is validated


  # TODO - fix this; should fail but it does not!
  @ignore
  Scenario: insert an attribute that already exists throws errors when inserted with different keys
    Given graql define
      """
      define
      name key ref;
      """
    Given the integrity is validated
    When graql insert
      """
      insert $a "john" isa name, has ref 0;
      """
    When the integrity is validated
    Then graql insert throws
      """
      insert $a "john" isa name, has ref 1;
      """
    Then the integrity is validated


  ###########################
  # ANSWERS OF INSERT QUERY #
  ###########################

  Scenario: an insert with multiple thing variables returns a single answer that contains them all
    When get answers of graql insert
      """
      insert
      $x isa person, has name "Bruce Wayne", has ref 0;
      $z isa company, has name "Wayne Enterprises", has ref 0;
      """
    When the integrity is validated
    Then answer size is: 1
    Then concept identifiers are
      |     | check | value |
      | BRU | key   | ref:0 |
      | WAY | key   | ref:0 |
    Then uniquely identify answer concepts
      | x   | z   |
      | BRU | WAY |


  Scenario: when inserting a thing variable with a type variable, the answer contains both variables
    When get answers of graql insert
      """
      match
        $type type company;
      insert
        $x isa $type, has name "Microsoft", has ref 0;
      """
    When the integrity is validated
    Then concept identifiers are
      |     | check | value   |
      | MIC | key   | ref:0   |
      | COM | label | company |
    Then uniquely identify answer concepts
      | x   | type |
      | MIC | COM  |


  ################
  # MATCH-INSERT #
  ################

  Scenario: match-insert triggers one insert per answer of the match clause
    Given graql define
      """
      define
      language sub entity, has name, has is-cool, key ref;
      is-cool sub attribute, value boolean;
      """
    Given the integrity is validated
    Given graql insert
      """
      insert
      $x isa language, has name "Norwegian", has ref 0;
      $y isa language, has name "Danish", has ref 1;
      """
    Given the integrity is validated
    When graql insert
      """
      match
        $x isa language;
      insert
        $x has is-cool true;
      """
    When the integrity is validated
    Then get answers of graql query
      """
      match $x has is-cool true; get;
      """
    Then concept identifiers are
      |     | check | value |
      | NOR | key   | ref:0 |
      | DAN | key   | ref:1 |


  Scenario: the answers of a match-insert only include the variables referenced in the `insert` block
    Given graql insert
      """
      insert
      $x isa person, has name "Eric", has ref 0;
      $y isa company, has name "Microsoft", has ref 1;
      $r (employee: $x, employer: $y) isa employment, has ref 2;
      $z isa person, has name "Tarja", has ref 3;
      """
    Given the integrity is validated
    When get answers of graql insert
      """
      match
        (employer: $x, employee: $z) isa employment, has ref $ref;
        $y isa person, has name "Tarja";
      insert
        (employer: $x, employee: $y) isa employment, has ref 10;
      """
    Then concept identifiers are
      |     | check | value |
      | MIC | key   | ref:1 |
      | TAR | key   | ref:3 |
    # Should only contain variables mentioned in the insert (so excludes `$z`)
    Then uniquely identify answer concepts
      | x   | y   |
      | MIC | TAR |


  Scenario: if match-insert matches nothing, then nothing is inserted
    Given graql define
      """
      define
      season-ticket-ownership sub relation, relates season-ticket-holder;
      person plays season-ticket-holder;
      """
    Given the integrity is validated
    Given get answers of graql query
      """
      match $p isa person; get;
      """
    Given answer size is: 0
    When graql insert
      """
      match
        $p isa person;
      insert
        $r (season-ticket-holder: $p) isa season-ticket-ownership;
      """
    When the integrity is validated
    Then get answers of graql query
      """
      match $r isa season-ticket-ownership; get;
      """
    Then answer size is: 0


  Scenario: match-inserting only existing entities is a no-op
    Given get answers of graql insert
      """
      insert
      $x isa person, has name "Rebecca", has ref 0;
      $y isa person, has name "Steven", has ref 1;
      $z isa person, has name "Theresa", has ref 2;
      """
    Given the integrity is validated
    Given concept identifiers are
      |     | check | value |
      | BEC | key   | ref:0 |
      | STE | key   | ref:1 |
      | THE | key   | ref:2 |
    Given uniquely identify answer concepts
      | x   | y   | z   |
      | BEC | STE | THE |
    Given get answers of graql query
      """
      match $x isa person; get;
      """
    Given uniquely identify answer concepts
      | x   |
      | BEC |
      | STE |
      | THE |
    When graql insert
      """
      match
        $x isa person;
      insert
        $x isa person;
      """
    When the integrity is validated
    Then get answers of graql query
      """
      match $x isa person; get;
      """
    Then uniquely identify answer concepts
      | x   |
      | BEC |
      | STE |
      | THE |


  Scenario: match-inserting only existing relations is a no-op
    Given get answers of graql insert
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
    Given the integrity is validated
    Given concept identifiers are
      |      | check | value |
      | HOM  | key   | ref:0 |
      | BUR  | key   | ref:1 |
      | SMI  | key   | ref:2 |
      | NPP  | key   | ref:3 |
      | eHOM | key   | ref:4 |
      | eBUR | key   | ref:5 |
      | eSMI | key   | ref:6 |
    Given uniquely identify answer concepts
      | x   | y   | z   | c   | xr   | yr   | zr   |
      | HOM | BUR | SMI | NPP | eHOM | eBUR | eSMI |
    Given get answers of graql query
      """
      match $r (employee: $x, employer: $c) isa employment; get;
      """
    Given uniquely identify answer concepts
      | r    | x   | c   |
      | eHOM | HOM | NPP |
      | eBUR | BUR | NPP |
      | eSMI | SMI | NPP |
    When graql insert
      """
      match
        $x isa employment;
      insert
        $x isa employment;
      """
    When the integrity is validated
    Then get answers of graql query
      """
      match $r (employee: $x, employer: $c) isa employment; get;
      """
    Then uniquely identify answer concepts
      | r    | x   | c   |
      | eHOM | HOM | NPP |
      | eBUR | BUR | NPP |
      | eSMI | SMI | NPP |


  Scenario: match-inserting only existing attributes is a no-op
    Given get answers of graql insert
      """
      insert
      $x "Ash" isa name;
      $y "Misty" isa name;
      $z "Brock" isa name;
      """
    Given the integrity is validated
    Given concept identifiers are
      |     | check | value      |
      | ASH | value | name:Ash   |
      | MIS | value | name:Misty |
      | BRO | value | name:Brock |
    Given uniquely identify answer concepts
      | x   | y   | z   |
      | ASH | MIS | BRO |
    Given get answers of graql query
      """
      match $x isa name; get;
      """
    Given uniquely identify answer concepts
      | x   |
      | ASH |
      | MIS |
      | BRO |
    When graql insert
      """
      match
        $x isa name;
      insert
        $x isa name;
      """
    When the integrity is validated
    Then get answers of graql query
      """
      match $x isa name; get;
      """
    Then uniquely identify answer concepts
      | x   |
      | ASH |
      | MIS |
      | BRO |


  Scenario: re-inserting a matched instance does nothing
    Given graql insert
      """
      insert
      $x isa person, has ref 0;
      """
    Given the integrity is validated
    Then graql insert
      """
      match
        $x isa person;
      insert
        $x isa person;
      """
    Then the integrity is validated
    When get answers of graql query
      """
      match $x isa person; get;
      """
    Then answer size is: 1


  Scenario: re-inserting a matched instance as an unrelated type throws an error
    Given graql insert
      """
      insert
      $x isa person, has ref 0;
      """
    Given the integrity is validated
    Then graql insert throws
      """
      match
        $x isa person;
      insert
        $x isa company;
      """
    Then the integrity is validated


  Scenario: inserting a new type on an existing instance has no effect, if the old type is a subtype of the new one
    Given graql define
      """
      define child sub person;
      """
    Given the integrity is validated
    Given graql insert
      """
      insert $x isa child, has ref 0;
      """
    Given the integrity is validated
    When graql insert
      """
      match
        $x isa child;
      insert
        $x isa person;
      """
    Then the integrity is validated
    When get answers of graql query
      """
      match $x isa! child; get;
      """
    Then answer size is: 1
    When get answers of graql query
      """
      match $x isa! person; get;
      """
    Then answer size is: 0


  ####################
  # TRANSACTIONALITY #
  ####################

  Scenario: if any insert in a transaction fails with a syntax error, none of the inserts are performed
    Given graql insert without commit
      """
      insert
      $x isa person, has name "Derek", has ref 0;
      """
    Given graql insert throws
      """
      insert
      $y qwertyuiop;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x isa person, has name "Derek"; get;
      """
    Then answer size is: 0


  Scenario: if any insert in a transaction fails with a semantic error, none of the inserts are performed
    Given graql define
      """
      define
      capacity sub attribute, value long;
      """
    Given the integrity is validated
    Given graql insert without commit
      """
      insert
      $x isa person, has name "Derek", has ref 0;
      """
    Given graql insert throws
      """
      insert
      $y isa person, has name "Emily", has capacity 1000;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x isa person, has name "Derek"; get;
      """
    Then answer size is: 0


  Scenario: if any insert in a transaction fails with a `key` violation, none of the inserts are performed
    Given graql insert without commit
      """
      insert
      $x isa person, has name "Derek", has ref 0;
      """
    Given graql insert throws
      """
      insert
      $y isa person, has name "Emily", has ref 0;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x isa person, has name "Derek"; get;
      """
    Then answer size is: 0


  ##############
  # EDGE CASES #
  ##############

  Scenario: the 'id' property is used internally by Grakn and cannot be manually assigned
    Given graql define
      """
      define
      bird sub entity;
      """
    Given the integrity is validated
    Then graql insert throws
      """
      insert
      $x isa bird;
      $x id V123;
      """
