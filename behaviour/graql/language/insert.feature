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
      $x has ref 0, isa person;
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
      match $x isa dog;
      """
    Given answer size is: 0
    When graql insert
      """
      insert $x isa dog, has breed "Labrador";
      """
    When the integrity is validated
    Then get answers of graql query
      """
      match $x isa dog;
      """
    Then answer size is: 1
    Then graql insert
      """
      insert $x isa dog, has breed "Labrador";
      """
    Then the integrity is validated
    Then get answers of graql query
      """
      match $x isa dog;
      """
    Then answer size is: 2
    Then graql insert
      """
      insert $x isa dog, has breed "Labrador";
      """
    Then the integrity is validated
    Then get answers of graql query
      """
      match $x isa dog;
      """
    Then answer size is: 3


  Scenario: insert instance of an abstract type throws (on commit?)

  Scenario: attempting to insert an instance of type 'thing' throws an error
    Then graql insert throws
      """
      insert $x isa thing;
      """
    Then the integrity is validated


  Scenario: inserting a thing with multiple ids throws an error
    Then graql insert throws
      """
      insert
      $x isa person, has ref 0;
      $x id V123;
      $x id V456;
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


  Scenario: when inserting a new thing that owns an existing attribute, and that attribute has no previous owner, that thing becomes its first owner
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


  Scenario: after inserting two things that own the same attribute, the things become linked, in that they are both owners of that attribute
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


  Scenario Outline: an insert can attach multiple distinct values of the same <type> attribute to a single owner
  Examples:
    | type     |
    | string   |
    | long     |
    | double   |
    | boolean  |
    | datetime |


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


  #############
  # RELATIONS #
  #############

  Scenario: inserting a relation creates an instance of it

  Scenario: when inserting a ternary relation that both owns an attribute and has an attribute as a roleplayer, both attributes are created
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


  Scenario: insert an additional role player is visible in the relation
    When graql insert
      """
      insert $p isa person, has ref 0; $r (employee: $p) isa employment, has ref 1;
      """
    When graql insert
      """
      match $r isa employment; insert $r (employer: $c) isa employment; $c isa company, has ref 2;
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


  Scenario: insert an additional duplicate role player
    When graql insert
      """
      insert $p isa person, has ref 0; $r (employee: $p) isa employment, has ref 1;
      """
    When graql insert
      """
      match $r isa employment; $p isa person; insert $r (employee: $p) isa employment;
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


  Scenario: extend relation with duplicate role player

  Scenario: inserting disallowed role being played throws on commit (? or at insert)

  Scenario: inserting disallowed role being related throws on commit (? or at insert)

  Scenario: inserting a supertype of a valid roleplayer in a role is invalid, and throws on commit (? or at insert)
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


  Scenario: inserting a relation with no role players throws on commit (? or at insert)

  Scenario: inserting a relation with an empty variable as a roleplayer throws an error
    Then graql insert throws
      """
      insert
      $r (employee: $x, employer: $y) isa employment, has ref 0;
      $y isa company, has name "Sports Direct", has ref 1;
      """


  Scenario: a relation currently inferred by a rule can be explicitly inserted

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


  Scenario: insert a subtype of an attribute with same value creates a separate instance

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


  Scenario: inserting duplicate values of the same key on a thing throws on commit
    Then graql insert throws
      """
      insert
      $x isa person, has ref 0;
      $y isa person, has ref 0;
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
    When get answers of graql query
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
    When get answers of graql query
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
    When get answers of graql query
      """
      match
        (employer: $x, employee: $z) isa employment;
        $y isa person, has name "Tarja";
      insert
        (employer: $x, employee: $y) isa employment;
      """
    Then concept identifiers are
      |     | check | value |
      | MIC | key   | ref:1 |
      | TAR | key   | ref:3 |
    # Should only contain variables mentioned in the insert (so excludes `$z`)
    Then uniquely identify answer concepts
      | x   | y   |
      | MIC | TAR |


  Scenario: match-insert inserts nothing if it matches nothing


  ####################
  # TRANSACTIONALITY #
  ####################

  Scenario: if any insert in a transaction fails with a syntax error, none of the inserts are performed

  Scenario: if any insert in a transaction fails with a semantic error, none of the inserts are performed

  Scenario: if any insert in a transaction fails with a `key` violation, none of the inserts are performed
