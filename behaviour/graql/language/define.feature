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
Feature: Graql Define Query

  Background: Open connection and create a simple extensible schema
    Given connection has been opened
    Given connection delete all keyspaces
    Given connection open sessions for keyspaces:
      | test_define |
    Given transaction is initialised
    Given the integrity is validated
    Given graql define
      """
      define
      person sub entity, plays employee, plays earner, has name, key email;
      employment sub relation, relates employee, plays source-of-income, has start-date, key employment-reference-code;
      income sub relation, relates earner, relates source-of-income;

      name sub attribute, value string;
      email sub attribute, value string;
      start-date sub attribute, value datetime;
      employment-reference-code sub attribute, value string;
      """
    Given the integrity is validated

  Scenario: uncommitted transaction writes are not persisted
    Given graql define without commit
      """
      define dog sub entity;
      """
    Given transaction is closed and opened without commit
    When graql get throws
      """
      match $x type dog; get;
      """


  ############
  # ENTITIES #
  ############

  Scenario: define entity type creates a type
    Given graql define
      """
      define dog sub entity;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x type dog; get;
      """
    Then concept identifiers are
      |     | check | value |
      | DOG | label | dog   |
    Then uniquely identify answer concepts
      | x   |
      | DOG |


  Scenario: define entity subtype creates child of its parent type
    Given graql define
      """
      define child sub person; 
      """
    Given the integrity is validated

    When get answers of graql query
      """
      match $x sub person; get;
      """
    Then concept identifiers are
      |     | check | value  |
      | PER | label | person |
      | CHD | label | child  |
    Then uniquely identify answer concepts
      | x   |
      | PER |
      | CHD |


  Scenario: define that a type 'has' something undefined throws
    Then graql define throws
      """
      define book sub entity, has pages;
      """
    Then the integrity is validated


  Scenario: define that a type 'has' an entity type throws
    Then graql define throws
      """
      define house sub entity, has person;
      """
    Then the integrity is validated


  Scenario: define that a type 'has' a relation type throws
    Then graql define throws
      """
      define company sub entity, has employment;
      """
    Then the integrity is validated


  Scenario: define that a type 'plays' an undefined role throws
    Then graql define throws
      """
      define house sub entity, plays constructed-thing;
      """
    Then the integrity is validated


  Scenario: define that a type 'plays' another type throws
    Then graql define throws
      """
      define parrot sub entity, plays person;
      """
    Then the integrity is validated


  Scenario: define that a type 'key' an entity type throws
    Then graql define throws
      """
      define passport sub entity, key person;
      """
    Then the integrity is validated


  Scenario: define entity subtype inherits 'plays' from its parent type
    Given graql define
      """
      define child sub person;
      """
    Given the integrity is validated

    When get answers of graql query
      """
      match $x plays employee; get;
      """
    Then concept identifiers are
      |     | check | value  |
      | PER | label | person |
      | CHD | label | child  |
    Then uniquely identify answer concepts
      | x   |
      | PER |
      | CHD |


  Scenario: define entity subtype inherits 'plays' from all of its supertypes
    Given graql define
      """
      define
      athlete sub person;
      runner sub athlete;
      sprinter sub runner;
      """
    Given the integrity is validated

    When get answers of graql query
      """
      match $x plays employee; get;
      """
    Then concept identifiers are
      |     | check | value    |
      | PER | label | person   |
      | ATH | label | athlete  |
      | RUN | label | runner   |
      | SPR | label | sprinter |
    Then uniquely identify answer concepts
      | x   |
      | PER |
      | ATH |
      | RUN |
      | SPR |


  Scenario: define entity subtype inherits 'has' from its parent type
    Given graql define
      """
      define child sub person;
      """
    Given the integrity is validated

    When get answers of graql query
      """
      match $x has name; get;
      """
    Then concept identifiers are
      |     | check | value  |
      | PER | label | person |
      | CHD | label | child  |
    Then uniquely identify answer concepts
      | x   |
      | PER |
      | CHD |


  Scenario: define entity subtype inherits 'has' from all of its supertypes
    Given graql define
      """
      define
      athlete sub person;
      runner sub athlete;
      sprinter sub runner;
      """
    Given the integrity is validated

    When get answers of graql query
      """
      match $x has name; get;
      """
    Then concept identifiers are
      |     | check | value    |
      | PER | label | person   |
      | ATH | label | athlete  |
      | RUN | label | runner   |
      | SPR | label | sprinter |
    Then uniquely identify answer concepts
      | x   |
      | PER |
      | ATH |
      | RUN |
      | SPR |


  Scenario: define entity subtype inherits 'key' from its parent type
    Given graql define
      """
      define child sub person;
      """
    Given the integrity is validated

    When get answers of graql query
      """
      match $x key email; get;
      """

    Then concept identifiers are
      |     | check | value  |
      | PER | label | person |
      | CHD | label | child  |
    Then uniquely identify answer concepts
      | x   |
      | PER |
      | CHD |


  Scenario: define entity subtype inherits 'key' from all of its supertypes
    Given graql define
      """
      define
      athlete sub person;
      runner sub athlete;
      sprinter sub runner;
      """
    Given the integrity is validated

    When get answers of graql query
      """
      match $x key email; get;
      """
    Then concept identifiers are
      |     | check | value    |
      | PER | label | person   |
      | ATH | label | athlete  |
      | RUN | label | runner   |
      | SPR | label | sprinter |
    Then uniquely identify answer concepts
      | x   |
      | PER |
      | ATH |
      | RUN |
      | SPR |


  Scenario: define that a type is a subtype of itself throws
    Then graql define throws
      """
      define dog sub dog;
      """
    Then the integrity is validated


  Scenario: define 'plays' is idempotent
    Given graql define
      """
      define
      house sub entity, plays home, plays home, plays home;
      home-ownership sub relation, relates home, relates home-owner;
      person plays home-owner;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x plays home; get;
      """
    Then concept identifiers are
      |     | check | value |
      | HOU | label | house |
    Then uniquely identify answer concepts
      | x   |
      | HOU |


  Scenario: define 'has' is idempotent
    Given graql define
      """
      define
      price sub attribute, value double;
      house sub entity, has price, has price, has price;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x has price; get;
      """
    Then concept identifiers are
      |     | check | value |
      | HOU | label | house |
    Then uniquely identify answer concepts
      | x   |
      | HOU |


  Scenario: define 'key' is idempotent
    Given graql define
      """
      define
      address sub attribute, value string;
      house sub entity, key address, key address, key address;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x key address; get;
      """
    Then concept identifiers are
      |     | check | value |
      | HOU | label | house |
    Then uniquely identify answer concepts
      | x   |
      | HOU |


  Scenario: define concept without 'sub' throws
    Then graql define throws
      """
      define flying-spaghetti-monster;
      """
    Then the integrity is validated


  Scenario: define new meta-type ('sub thing') throws
    Then graql define throws
      """
      define column sub thing;
      """


  Scenario: define entity type with 'value' throws
    Then graql define throws
      """
      define cream sub entity, value double;
      """


  Scenario: define type with a 'when' block throws
    Then graql define throws
      """
      define gorilla sub entity, when { $x isa gorilla; };
      """


  Scenario: define type with a 'then' block throws
    Then graql define throws
      """
      define godzilla sub entity, then { $x isa godzilla; };
      """


  Scenario: attempt to define a thing with 'isa' throws
    Then graql define throws
      """
      define $p isa person;
      """


  Scenario: add attribute instance to thing in 'define' query throws
    Then graql define throws
      """
      define $p has name "Loch Ness Monster";
      """


  @ignore
  # TODO: re-enable when writing a variable in a 'define' is forbidden
  Scenario: write a variable in a 'define' throws


  #############
  # RELATIONS #
  #############


  Scenario: define relation type creates a type
    Given graql define
      """
      define pet-ownership sub relation, relates pet-owner, relates owned-pet;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x type pet-ownership; get;
      """
    Then concept identifiers are
      |     | check | value         |
      | POW | label | pet-ownership |
    Then uniquely identify answer concepts
      | x   |
      | POW |


  Scenario: define relation subtype creates child of its parent type
    Given graql define
      """
      define fun-employment sub employment, relates employee-having-fun as employee;
      """
    Given the integrity is validated

    When get answers of graql query
      """
      match $x sub employment; get;
      """
    Then concept identifiers are
      |     | check | value          |
      | EMP | label | employment     |
      | FUN | label | fun-employment |
    Then uniquely identify answer concepts
      | x   |
      | EMP |
      | FUN |


  Scenario: define relation type throws if it has no roleplayers and is not marked as abstract
    Then graql define throws
      """
      define useless-relation sub relation;
      """
    Then the integrity is validated


  @ignore
  # re-enable when 'relates' is inherited
  Scenario: define relation subtype inherits 'relates' from supertypes without role subtyping
    Given graql define
      """
      define part-time-employment sub employment;
      """
    Given the integrity is validated

    When get answers of graql query
      """
      match $x relates employee; get;
      """
    Then concept identifiers are
      |     | check | value                |
      | EMP | label | employment           |
      | PTT | label | part-time-employment |
    Then uniquely identify answer concepts
      | x   |
      | EMP |
      | PTT |


  Scenario: define a subrole using 'as' creates child of parent role
    Given graql define
      """
      define
      parenthood sub relation, relates parent, relates child;
      father-sonhood sub parenthood, relates father as parent, relates son as child;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match
      $x sub parent; $y sub child; get $x, $y;
      """
    Then concept identifiers are
      |     | check | value  |
      | PAR | label | parent |
      | FAT | label | father |
      | CHI | label | child  |
      | SON | label | son    |


  @ignore
  # TODO: re-enable when 'relates' is bound to a relation and blockable
  Scenario: define relation subtype with role subtyping blocks parent role
    Given graql define
      """
      define part-time-employment sub employment, relates part-timer as employee;
      """
    Given the integrity is validated

    When get answers of graql query
      """
      match $x relates employee; get;
      """
    Then concept identifiers are
      |     | check | value                |
      | EMP | label | employment           |
      | PTT | label | part-time-employment |
    Then uniquely identify answer concepts
      | x   |
      | EMP |
      | PTT |

    # TODO - employee role should be retrieving part-timer as well
    # Then query 1 has 2 answers
    # And answers of query 1 satisfy: match $x sub employment; get;


  # @ignore
  Scenario: define a sub-role using 'as' is visible from children (?)


  Scenario: define relation subtype inherits 'plays' from its parent type
    Given graql define
      """
      define contract-employment sub employment, relates contractor as employee;
      """
    Given the integrity is validated

    When get answers of graql query
      """
      match $x plays source-of-income; get;
      """
    Then concept identifiers are
      |     | check | value               |
      | EMP | label | employment          |
      | CEM | label | contract-employment |
    Then uniquely identify answer concepts
      | x   |
      | EMP |
      | CEM |


  Scenario: define relation subtype inherits 'plays' from all of its supertypes
    Given graql define
      """
      define
      transport-employment sub employment, relates transport-worker as employee;
      aviation-employment sub transport-employment, relates aviation-worker as transport-worker;
      flight-attendant-employment sub aviation-employment, relates flight-attendant as aviation-worker;
      """
    Given the integrity is validated

    When get answers of graql query
      """
      match $x plays source-of-income; get;
      """
    Then concept identifiers are
      |     | check | value                       |
      | EMP | label | employment                  |
      | TRN | label | transport-employment        |
      | AVI | label | aviation-employment         |
      | FAA | label | flight-attendant-employment |
    Then uniquely identify answer concepts
      | x   |
      | EMP |
      | TRN |
      | AVI |
      | FAA |


  Scenario: define relation subtype inherits 'has' from its parent type
    Given graql define
      """
      define contract-employment sub employment, relates contractor as employee;
      """
    Given the integrity is validated

    When get answers of graql query
      """
      match $x has start-date; get;
      """
    Then concept identifiers are
      |     | check | value               |
      | EMP | label | employment          |
      | CEM | label | contract-employment |
    Then uniquely identify answer concepts
      | x   |
      | EMP |
      | CEM |


  Scenario: define relation subtype inherits 'has' from all of its supertypes
    Given graql define
      """
      define
      transport-employment sub employment, relates transport-worker as employee;
      aviation-employment sub transport-employment, relates aviation-worker as transport-worker;
      flight-attendant-employment sub aviation-employment, relates flight-attendant as aviation-worker;
      """
    Given the integrity is validated

    When get answers of graql query
      """
      match $x has start-date; get;
      """
    Then concept identifiers are
      |     | check | value                       |
      | EMP | label | employment                  |
      | TRN | label | transport-employment        |
      | AVI | label | aviation-employment         |
      | FAA | label | flight-attendant-employment |
    Then uniquely identify answer concepts
      | x   |
      | EMP |
      | TRN |
      | AVI |
      | FAA |


  Scenario: define relation subtype inherits 'key' from its parent type
    Given graql define
      """
      define contract-employment sub employment, relates contractor as employee;
      """
    Given the integrity is validated

    When get answers of graql query
      """
      match $x key employment-reference-code; get;
      """
    Then concept identifiers are
      |     | check | value               |
      | EMP | label | employment          |
      | CEM | label | contract-employment |
    Then uniquely identify answer concepts
      | x   |
      | EMP |
      | CEM |


  Scenario: define relation subtype inherits 'key' from all of its supertypes
    Given graql define
      """
      define
      transport-employment sub employment, relates transport-worker as employee;
      aviation-employment sub transport-employment, relates aviation-worker as transport-worker;
      flight-attendant-employment sub aviation-employment, relates flight-attendant as aviation-worker;
      """
    Given the integrity is validated

    When get answers of graql query
      """
      match $x key employment-reference-code; get;
      """
    Then concept identifiers are
      |     | check | value                       |
      | EMP | label | employment                  |
      | TRN | label | transport-employment        |
      | AVI | label | aviation-employment         |
      | FAA | label | flight-attendant-employment |
    Then uniquely identify answer concepts
      | x   |
      | EMP |
      | TRN |
      | AVI |
      | FAA |


  Scenario: a relation type can be defined with no roleplayers when it is marked as abstract
    Given graql define
      """
      define connection sub relation, abstract;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x type connection; get;
      """
    Then concept identifiers are
      |     | check | value      |
      | CON | label | connection |
    Then uniquely identify answer concepts
      | x   |
      | CON |


  Scenario: when defining a relation type, duplicate 'relates' are idempotent
    Given graql define
      """
      define
      parenthood sub relation, relates parent, relates child, relates child, relates parent, relates child;
      person plays parent, plays child;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x relates parent; $x relates child; get;
      """
    Then concept identifiers are
      |     | check | value      |
      | PAR | label | parenthood |
    Then uniquely identify answer concepts
      | x   |
      | PAR |


  Scenario: when defining a relation type, it can 'relates' to a role it plays itself
    Given graql define
      """
      define
      recursive-function sub relation, relates function, plays function;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x relates function; $x plays function; get;
      """
    Then concept identifiers are
      |     | check | value              |
      | REC | label | recursive-function |
    Then uniquely identify answer concepts
      | x   |
      | REC |


  Scenario: define `sub role` creates a role, provided it is used in a relation
    Given graql define
      """
      define
      team-member sub role;
      team sub relation, relates team-member;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x type team-member; get;
      """
    Then concept identifiers are
      |     | check | value       |
      | TMM | label | team-member |
    Then uniquely identify answer concepts
      | x   |
      | TMM |


  Scenario: define a role throws if it is not used in any relation
    Given graql define throws
      """
      define
      lonely-team-member sub role;
      """


  Scenario: define a subrole using `sub` creates child of parent role
    Given graql define
      """
      define
      team-member sub role;
      team-leader sub team-member;
      team sub relation, relates team-member, relates team-leader;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x type team-leader; get;
      """
    Then concept identifiers are
      |     | check | value       |
      | TML | label | team-leader |
    Then uniquely identify answer concepts
      | x   |
      | TML |


  ##############
  # ATTRIBUTES #
  ##############


  Scenario: an attribute with type `string` can be defined
    Given graql define
      """
      define favourite-food sub attribute, value string;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x type favourite-food; get;
      """
    Then concept identifiers are
      |     | check | value          |
      | FAV | label | favourite-food |
    Then uniquely identify answer concepts
      | x   |
      | FAV |


  Scenario: an attribute with type `long` can be defined
    Given graql define
      """
      define number-of-cows sub attribute, value long;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x type number-of-cows; get;
      """
    Then concept identifiers are
      |     | check | value          |
      | NOC | label | number-of-cows |
    Then uniquely identify answer concepts
      | x   |
      | NOC |


  Scenario: an attribute with type `double` can be defined
    Given graql define
      """
      define density sub attribute, value double;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x type density; get;
      """
    Then concept identifiers are
      |     | check | value   |
      | DEN | label | density |
    Then uniquely identify answer concepts
      | x   |
      | DEN |


  Scenario: an attribute with type `boolean` can be defined
    Given graql define
      """
      define can-fly sub attribute, value boolean;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x type can-fly; get;
      """
    Then concept identifiers are
      |     | check | value   |
      | CFL | label | can-fly |
    Then uniquely identify answer concepts
      | x   |
      | CFL |


  Scenario: an attribute with type `datetime` can be defined
    Given graql define
      """
      define flight-date sub attribute, value datetime;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x type flight-date; get;
      """
    Then concept identifiers are
      |     | check | value       |
      | FLD | label | flight-date |
    Then uniquely identify answer concepts
      | x   |
      | FLD |


  Scenario: define attribute type throws if you don't specify 'value'
    Then graql define throws
      """
      define colour sub attribute;
      """
    Then the integrity is validated


  Scenario: define attribute type throws if 'value' is invalid
    Then graql define throws
      """
      define colour sub attribute, value rgba;
      """
    Then the integrity is validated


  Scenario: define attribute subtype creates child of its parent type
    Given graql define
      """
      define first-name sub name;
      """
    Given the integrity is validated

    When get answers of graql query
      """
      match $x sub name; get;
      """
    Then concept identifiers are
      |        | check | value      |
      | NAME   | label | name       |
      | F_NAME | label | first-name |
    Then uniquely identify answer concepts
      | x      |
      | NAME   |
      | F_NAME |


  Scenario: define attribute subtype inherits 'value' from its parent
    Given graql define
      """
      define first-name sub name;
      """
    Given the integrity is validated

    When get answers of graql query
      """
      match $x type first-name, value string; get;
      """
    Then concept identifiers are
      |        | check | value      |
      | F_NAME | label | first-name |
    Then uniquely identify answer concepts
      | x      |
      | F_NAME |


  @ignore
  # TODO: re-enable when overriding an attribute's 'value' is forbidden
  Scenario: define attribute subtype throws if you try to override 'value'
    Then graql define throws
      """
      define code-name sub name, value long;
      """
    Then the integrity is validated


  Scenario: define attribute regex creates a regex constraint
    Given graql define
      """
      define response sub attribute, value string, regex "^(yes|no|maybe)$";
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x regex "^(yes|no|maybe)$"; get;
      """
    Then concept identifiers are
      |     | check | value    |
      | RES | label | response |
    Then uniquely identify answer concepts
      | x   |
      | RES |


  Scenario: define attribute regex throws if value is a long
    Then graql define throws
      """
      define name-in-binary sub attribute, value long, regex "^(0|1)+$";
      """
    Then the integrity is validated


  Scenario: define attribute subtype inherits 'plays' from its parent type
    Given graql define
      """
      define
      car sub entity, plays listed-car;
      car-sales-listing sub relation, relates listed-car, relates available-colour;
      colour sub attribute, value string, plays available-colour;
      grayscale-colour sub colour;
      """
    Given the integrity is validated

    When get answers of graql query
      """
      match $x plays available-colour; get;
      """
    Then concept identifiers are
      |     | check | value            |
      | COL | label | colour           |
      | GRC | label | grayscale-colour |
    Then uniquely identify answer concepts
      | x   |
      | COL |
      | GRC |


  Scenario: define attribute subtype inherits 'plays' from all of its supertypes
    Given graql define
      """
      define
      person plays contact-person;
      phone-contact sub relation, relates contact-person, relates contact-phone-number;
      phone-number sub attribute, value string, plays contact-phone-number;
      uk-phone-number sub phone-number;
      uk-landline-number sub uk-phone-number;
      uk-premium-landline-number sub uk-landline-number;
      """
    Given the integrity is validated

    When get answers of graql query
      """
      match $x plays contact-phone-number; get;
      """
    Then concept identifiers are
      |     | check | value                      |
      | PHN | label | phone-number               |
      | UKP | label | uk-phone-number            |
      | UKL | label | uk-landline-number         |
      | UPM | label | uk-premium-landline-number |
    Then uniquely identify answer concepts
      | x   |
      | PHN |
      | UKP |
      | UKL |
      | UPM |


  Scenario: define attribute subtype inherits 'has' from its parent type
    Given graql define
      """
      define
      brightness sub attribute, value double;
      colour sub attribute, value string, has brightness;
      grayscale-colour sub colour;
      """
    Given the integrity is validated

    When get answers of graql query
      """
      match $x has brightness; get;
      """
    Then concept identifiers are
      |     | check | value            |
      | COL | label | colour           |
      | GRC | label | grayscale-colour |
    Then uniquely identify answer concepts
      | x   |
      | COL |
      | GRC |


  Scenario: define attribute subtype inherits 'has' from all of its supertypes
    Given graql define
      """
      define
      country-calling-code sub attribute, value string;
      phone-number sub attribute, value string, has country-calling-code;
      uk-phone-number sub phone-number;
      uk-landline-number sub uk-phone-number;
      uk-premium-landline-number sub uk-landline-number;
      """
    Given the integrity is validated

    When get answers of graql query
      """
      match $x has country-calling-code; get;
      """
    Then concept identifiers are
      |     | check | value                      |
      | PHN | label | phone-number               |
      | UKP | label | uk-phone-number            |
      | UKL | label | uk-landline-number         |
      | UPM | label | uk-premium-landline-number |
    Then uniquely identify answer concepts
      | x   |
      | PHN |
      | UKP |
      | UKL |
      | UPM |


  Scenario: define attribute subtype inherits 'key' from its parent type
    Given graql define
      """
      define
      hex-value sub attribute, value string;
      colour sub attribute, value string, key hex-value;
      grayscale-colour sub colour;
      """
    Given the integrity is validated

    When get answers of graql query
      """
      match $x key hex-value; get;
      """
    Then concept identifiers are
      |     | check | value            |
      | COL | label | colour           |
      | GRC | label | grayscale-colour |
    Then uniquely identify answer concepts
      | x   |
      | COL |
      | GRC |


  Scenario: define attribute subtype inherits 'key' from all of its supertypes
    Given graql define
      """
      define
      hex-value sub attribute, value string;
      colour sub attribute, value string, key hex-value;
      dark-colour sub colour;
      dark-red-colour sub dark-colour;
      very-dark-red-colour sub dark-red-colour;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x key hex-value; get;
      """
    Then concept identifiers are
      |     | check | value                |
      | COL | label | colour               |
      | DRK | label | dark-colour          |
      | DKR | label | dark-red-colour      |
      | VDR | label | very-dark-red-colour |
    Then uniquely identify answer concepts
      | x   |
      | COL |
      | DRK |
      | DKR |
      | VDR |


  Scenario: a type can `has` an attribute of type `string`
    Given graql define
      """
      define
      first-word sub attribute, value string;
      person has first-word;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x has first-word; get;
      """
    Then concept identifiers are
      |     | check | value  |
      | PER | label | person |
    Then uniquely identify answer concepts
      | x   |
      | PER |


  Scenario: a type can `has` an attribute of type `long`
    Given graql define
      """
      define
      number-of-fingers sub attribute, value long;
      person has number-of-fingers;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x has number-of-fingers; get;
      """
    Then concept identifiers are
      |     | check | value  |
      | PER | label | person |
    Then uniquely identify answer concepts
      | x   |
      | PER |


  Scenario: a type can `has` an attribute of type `double`
    Given graql define
      """
      define
      height sub attribute, value double;
      person has height;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x has height; get;
      """
    Then concept identifiers are
      |     | check | value  |
      | PER | label | person |
    Then uniquely identify answer concepts
      | x   |
      | PER |


  Scenario: a type can `has` an attribute of type `boolean`
    Given graql define
      """
      define
      is-sleeping sub attribute, value boolean;
      person has is-sleeping;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x has is-sleeping; get;
      """
    Then concept identifiers are
      |     | check | value  |
      | PER | label | person |
    Then uniquely identify answer concepts
      | x   |
      | PER |


  Scenario: a type can `has` an attribute of type `datetime`
    Given graql define
      """
      define
      graduation-date sub attribute, value datetime;
      person has graduation-date;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x has graduation-date; get;
      """
    Then concept identifiers are
      |     | check | value  |
      | PER | label | person |
    Then uniquely identify answer concepts
      | x   |
      | PER |


  Scenario: when defining an attribute type, it can 'has' itself, creating an attribute with self-ownership
    Given graql define
      """
      define number-of-letters sub attribute, value long, has number-of-letters;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x has number-of-letters; get;
      """
    Then concept identifiers are
      |     | check | value                |
      | NOL | label | number-of-letters    |
    Then uniquely identify answer concepts
      | x   |
      | NOL |


  ##################
  # ABSTRACT TYPES #
  ##################

  Scenario: define abstract entity type creates an abstract type
    Given graql define
      """
      define animal sub entity, abstract;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x type animal; $x abstract; get;
      """
    Then concept identifiers are
      |     | check | value  |
      | ANI | label | animal |
    Then uniquely identify answer concepts
      | x   |
      | ANI |


  Scenario: define concrete subtype of abstract entity creates child of its parent type
    Given graql define
      """
      define
      animal sub entity, abstract;
      horse sub animal;
      """
    Given the integrity is validated

    When get answers of graql query
      """
      match $x sub animal; get;
      """
    Then concept identifiers are
      |     | check | value  |
      | ANI | label | animal |
      | HOR | label | horse  |
    Then uniquely identify answer concepts
      | x   |
      | ANI |
      | HOR |


  Scenario: define abstract subtype of abstract entity creates child of its parent type
    Given graql define
      """
      define
      animal sub entity, abstract;
      fish sub animal, abstract;
      """
    Given the integrity is validated

    When get answers of graql query
      """
      match $x sub animal; get;
      """
    Then concept identifiers are
      |     | check | value  |
      | ANI | label | animal |
      | FSH | label | fish   |
    Then uniquely identify answer concepts
      | x   |
      | ANI |
      | FSH |


  Scenario: define abstract relation type creates an abstract type
    Given graql define
      """
      define membership sub relation, abstract, relates member;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x type membership; $x abstract; get;
      """
    Then concept identifiers are
      |     | check | value      |
      | MEM | label | membership |
    Then uniquely identify answer concepts
      | x   |
      | MEM |


  Scenario: define concrete subtype of abstract relation creates child of its parent type
    Given graql define
      """
      define
      membership sub relation, abstract, relates member;
      gym-membership sub membership, relates gym-with-members, relates gym-member as member;
      """
    Given the integrity is validated

    When get answers of graql query
      """
      match $x sub membership; get;
      """
    Then concept identifiers are
      |     | check | value          |
      | MEM | label | membership     |
      | GYM | label | gym-membership |
    Then uniquely identify answer concepts
      | x   |
      | MEM |
      | GYM |


  Scenario: define abstract subtype of abstract relation creates child of its parent type
    Given graql define
      """
      define
      requirement sub relation, abstract, relates prerequisite, relates outcome;
      tool-requirement sub requirement, abstract, relates required-tool as prerequisite;
      """
    Given the integrity is validated

    When get answers of graql query
      """
      match $x sub requirement; get;
      """
    Then concept identifiers are
      |     | check | value            |
      | REQ | label | requirement      |
      | TLR | label | tool-requirement |
    Then uniquely identify answer concepts
      | x   |
      | REQ |
      | TLR |


  Scenario: define abstract attribute type creates an abstract type
    Given graql define
      """
      define number-of-limbs sub attribute, abstract, value long;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x type number-of-limbs; $x abstract; get;
      """
    Then concept identifiers are
      |     | check | value           |
      | NOL | label | number-of-limbs |
    Then uniquely identify answer concepts
      | x   |
      | NOL |


  Scenario: define concrete subtype of abstract attribute creates child of its parent type
    Given graql define
      """
      define
      number-of-limbs sub attribute, abstract, value long;
      number-of-legs sub number-of-limbs;
      """
    Given the integrity is validated

    When get answers of graql query
      """
      match $x sub number-of-limbs; get;
      """
    Then concept identifiers are
      |     | check | value           |
      | NOL | label | number-of-limbs |
      | NLE | label | number-of-legs  |
    Then uniquely identify answer concepts
      | x   |
      | NOL |
      | NLE |


  Scenario: define abstract subtype of abstract attribute creates child of its parent type
    Given graql define
      """
      define
      number-of-limbs sub attribute, abstract, value long;
      number-of-artificial-limbs sub number-of-limbs, abstract;
      """
    Given the integrity is validated

    When get answers of graql query
      """
      match $x sub number-of-limbs; get;
      """
    Then concept identifiers are
      |     | check | value                      |
      | NOL | label | number-of-limbs            |
      | NAL | label | number-of-artificial-limbs |
    Then uniquely identify answer concepts
      | x   |
      | NOL |
      | NAL |


  Scenario: define a rule as abstract throws
    Then graql define throws
      """
      define
      nickname sub name;
      person has nickname;
      robert-has-nickname-bob sub rule, abstract,
      when {
        $p isa person, has name "Robert";
      }, then {
        $p has nickname "Bob";
      };
      """
    Then the integrity is validated


  @ignore
  # TODO: re-enable when concrete types are not allowed to have abstract subtypes
  Scenario: define abstract subtype of concrete entity throws an error
    Then graql define throws
      """
      define
      exception sub entity;
      grakn-exception sub exception, abstract;
      """
    Then the integrity is validated


  Scenario: defining a type as abstract is idempotent
    Given graql define
      """
      define animal sub entity, abstract, abstract, abstract;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x type animal; $x abstract; get;
      """
    Then concept identifiers are
      |     | check | value  |
      | ANI | label | animal |
    Then uniquely identify answer concepts
      | x   |
      | ANI |


  ###################
  # SCHEMA MUTATION #
  ###################

  Scenario: re-define existing type keeps its properties intact and is idempotent
    Given graql define
      """
      define
      person sub entity, has name;
      person sub entity, has name;
      person sub entity, has name;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x type person; $x has email; get;
      """
    Then concept identifiers are
      |     | check | value  |
      | PER | label | person |
    Then uniquely identify answer concepts
      | x   |
      | PER |


  Scenario: change entity type to relation type throws
    Then graql define throws
      """
      define
      person sub relation, relates body-part;
      arm sub entity, plays body-part;
      """
    Then the integrity is validated


  Scenario: change relation type to attribute type throws
    Then graql define throws
      """
      define employment sub attribute, value string;
      """
    Then the integrity is validated


  Scenario: change attribute type to entity type throws
    Then graql define throws
      """
      define name sub entity;
      """
    Then the integrity is validated


  Scenario: define additional 'has' on a type adds attribute to it
    Given graql define
      """
      define employment has name;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x has name; get;
      """
    Then concept identifiers are
      |     | check | value      |
      | PER | label | person     |
      | EMP | label | employment |
    Then uniquely identify answer concepts
      | x   |
      | PER |
      | EMP |


  Scenario: define additional 'plays' on a type adds role to it
    Given graql define
      """
      define employment plays employee;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x plays employee; get;
      """
    Then concept identifiers are
      |     | check | value      |
      | PER | label | person     |
      | EMP | label | employment |
    Then uniquely identify answer concepts
      | x   |
      | PER |
      | EMP |


  Scenario: additional 'key' can be defined on a type, as long as existing instances have correct keys prior to commit
    Given graql define
      """
      define
      barcode sub attribute, value string;
      product sub entity, has name;
      """
    Given the integrity is validated
    Given graql insert
      """
      insert
      $x isa product, has name "Cheese";
      $y isa product, has name "Ham";
      """
    Given the integrity is validated
    When graql define without commit
      """
      define
      product key barcode;
      """
    When graql insert
      """
      match
      $cheese isa product, has name "Cheese";
      $ham isa product, has name "Ham";
      insert
      $cheese has barcode "643353";
      $ham has barcode "448";
      """
    When the integrity is validated
    When get answers of graql query
      """
      match $x has barcode; get;
      """
    Then concept identifiers are
      |     | check | value      |
      | PRD | label | product    |
    Then uniquely identify answer concepts
      | x   |
      | PRD |


  @ignore
  # TODO: re-enable when defining additional 'key' on a type throws if it is not added to existing instances prior to commit
  Scenario: define additional 'key' on a type throws if it is not added to existing instances prior to commit
    Given graql define
      """
      define
      barcode sub attribute, value string;
      product sub entity, has name;
      """
    Given the integrity is validated
    Given graql insert
      """
      insert
      $x isa product, has name "Cheese";
      $y isa product, has name "Ham";
      """
    Given the integrity is validated
    Then graql define throws
      """
      define
      product key barcode;
      """
    Then the integrity is validated


  Scenario: define additional 'relates' on a relation type adds roleplayer to it
    Given graql define
      """
      define
      company sub entity, plays employer;
      employment relates employer;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x relates employer; get;
      """
    Then concept identifiers are
      |     | check | value      |
      | EMP | label | employment |
    Then uniquely identify answer concepts
      | x   |
      | EMP |


  Scenario: define additional 'regex' on attribute type adds regex to it if all existing instances match the regex
    Given graql insert
      """
      insert
      $x isa person, has name "Alice", has email "alice@grakn.ai";
      """
    Given the integrity is validated
    When graql define
      """
      define name regex "^A.*$";
      """
    When the integrity is validated
    When get answers of graql query
      """
      match $x regex "^A.*$"; get;
      """
    Then concept identifiers are
      |     | check | value |
      | NAM | label | name  |
    Then uniquely identify answer concepts
      | x   |
      | NAM |


  Scenario: define additional 'regex' on attribute type throws on commit if an existing instance doesn't match the regex
    Given graql insert
      """
      insert
      $x isa person, has name "Maria", has email "maria@grakn.ai";
      """
    Given the integrity is validated
    Then graql define throws
      """
      define name regex "^A.*$";
      """
    Then the integrity is validated


  Scenario: define additional 'regex' on a long-valued attribute type throws
    Given graql define
      """
      define house-number sub attribute, value long;
      """
    Given the integrity is validated
    Then graql define throws
      """
      define house-number regex "^A.*$";
      """
    Then the integrity is validated


  Scenario: add 'relates' to entity type throws
    Then graql define throws
      """
      define person relates employee;
      """
    Then the integrity is validated


  Scenario: add 'relates' to attribute type throws
    Then graql define throws
      """
      define name relates employee;
      """
    Then the integrity is validated


  Scenario: modify attribute value type throws
    Then graql define throws
      """
      define name value long;
      """
    Then the integrity is validated


  Scenario: add attribute as `key` to a type that already `has` that attribute throws
    Then graql define throws
      """
      define person key name;
      """
    Then the integrity is validated


  Scenario: modify rule definition throws
    Given graql define
      """
      define
      nickname sub name;
      person has nickname;
      robert-has-nickname-bob sub rule,
      when {
        $p isa person, has name "Robert";
      }, then {
        $p has nickname "Bob";
      };
      """
    Given the integrity is validated
    Then graql define throws
      """
      define
      robert-has-nickname-bob sub rule,
      when {
        $p isa person, has name "robert";
      }, then {
        $p has nickname "bob";
      };
      """
    Then the integrity is validated


  #############################
  # SCHEMA MUTATION: ABSTRACT #
  #############################

  Scenario: add abstract to existing entity type makes it abstract
    Given graql define
      """
      define person abstract;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x sub person; $x abstract; get;
      """
    Then concept identifiers are
      |     | check | value  |
      | PER | label | person |
    Then uniquely identify answer concepts
      | x   |
      | PER |


  Scenario: add abstract to existing relation type makes it abstract
    Given graql define
      """
      define employment abstract;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x sub employment; $x abstract; get;
      """
    Then concept identifiers are
      |     | check | value      |
      | EMP | label | employment |
    Then uniquely identify answer concepts
      | x   |
      | EMP |


  Scenario: add abstract to existing attribute type makes it abstract
    Given graql define
      """
      define name abstract;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x sub name; $x abstract; get;
      """
    Then concept identifiers are
      |     | check | value |
      | NAM | label | name  |
    Then uniquely identify answer concepts
      | x   |
      | NAM |


  Scenario: add abstract to existing entity type throws on commit if it has an existing instance
    Given graql insert
      """
      insert
      $x isa person, has name "Jeremy", has email "jeremy@grakn.ai";
      """
    Given the integrity is validated
    Then graql define throws
      """
      define person abstract;
      """
    Then the integrity is validated


  Scenario: add abstract to existing relation type throws on commit if it has an existing instance


  Scenario: add abstract to existing attribute type throws on commit if it has an existing instance
    Given graql insert
      """
      insert
      $x isa person, has name "Jeremy", has email "jeremy@grakn.ai";
      """
    Given the integrity is validated
    Then graql define throws
      """
      define name abstract;
      """
    Then the integrity is validated


  @ignore
  # TODO: re-enable when concrete types cannot have abstract subtypes
  Scenario: change concrete type to abstract throws on commit if it has a concrete supertype

  @ignore
  # TODO: re-enable when rules cannot infer abstract relations
  Scenario: change concrete relation type to abstract throws on commit if it is the conclusion of any rule

  @ignore
  # TODO: check if rules can infer abstract attributes
  Scenario: change concrete attribute type to abstract throws on commit if it is the conclusion of any rule

  ######################
  # HIERARCHY MUTATION #
  ######################

  Scenario: define new `sub` on entity type changes its supertype
    Given graql define
      """
      define
      apple-product sub entity;
      genius sub person;
      """
    Given the integrity is validated
    When graql define
      """
      define
      genius sub apple-product;
      """
    When the integrity is validated
    When get answers of graql query
      """
      match $x sub apple-product; get;
      """
    Then concept identifiers are
      |     | check | value         |
      | APL | label | apple-product |
      | GEN | label | genius        |
    Then uniquely identify answer concepts
      | x   |
      | APL |
      | GEN |


  Scenario: define new `sub` on relation type changes its supertype


  Scenario: define new `sub` on attribute type changes its supertype
    Given graql define
      """
      define
      measure sub attribute, value double;
      shoe-size sub measure;
      shoe sub entity, has shoe-size;
      """
    Given the integrity is validated
    Given graql insert
      """
      insert $s isa shoe, has shoe-size 9;
      """
    Given the integrity is validated
    Given graql define
      """
      define
      size sub attribute, value double;
      shoe-size sub size;
      """
    When get answers of graql query
      """
      match $x sub shoe-size; get;
      """
    Then concept identifiers are
      |     | check | value     |
      | SHS | label | shoe-size |
    Then uniquely identify answer concepts
      | x   |
      | SHS |


  Scenario: assigning a new supertype succeeds even if they have different attributes + roles, if there are no instances
    Given graql define
      """
      define
      species sub entity, has name, plays the-species;
      species-membership sub relation, relates the-species, relates member-of-species;
      lifespan sub attribute, value double;
      organism sub entity, has lifespan, plays member-of-species;
      child sub person;
      """
    Given the integrity is validated
    When graql define
      """
      define
      person sub organism;
      """
    Then the integrity is validated
    When get answers of graql query
      """
      match $x sub organism; get;
      """
    When concept identifiers are
      |     | check | value    |
      | ORG | label | organism |
      | PER | label | person   |
      | CHI | label | child    |
    Then uniquely identify answer concepts
      | x   |
      | ORG |
      | PER |
      | CHI |


  Scenario: assign new supertype with existing data succeeds if the supertypes have no properties
    Given graql define
      """
      define
      bird sub entity;
      pigeon sub bird;
      """
    Given the integrity is validated
    Given graql insert
      """
      insert $p isa pigeon;
      """
    Given the integrity is validated
    Given graql define
      """
      define
      animal sub entity;
      pigeon sub animal;
      """
    When get answers of graql query
      """
      match $x sub pigeon; get;
      """
    Then concept identifiers are
      |     | check | value  |
      | PIG | label | pigeon |
    Then uniquely identify answer concepts
      | x   |
      | PIG |


  @ignore
  # TODO: re-enable when roles are correctly checked when switching supertypes
  Scenario: assign new supertype with existing data succeeds if the supertypes play the same roles
    Given graql define
      """
      define
      bird sub entity, plays flier;
      pigeon sub bird;
      flying sub relation, relates flier;
      """
    Given the integrity is validated
    Given graql insert
      """
      insert $p isa pigeon;
      """
    Given the integrity is validated
    Given graql define
      """
      define
      animal sub entity, plays flier;
      pigeon sub animal;
      """
    When get answers of graql query
      """
      match $x sub pigeon; get;
      """
    Then concept identifiers are
      |     | check | value  |
      | PIG | label | pigeon |
    Then uniquely identify answer concepts
      | x   |
      | PIG |


  @ignore
  # TODO: re-enable when attribute ownerships are correctly checked when switching supertypes
  Scenario: assign new supertype with existing data succeeds if the supertypes have the same attributes
    Given graql define
      """
      define
      name sub attribute, value string;
      bird sub entity, has name;
      pigeon sub bird;
      """
    Given the integrity is validated
    Given graql insert
      """
      insert $p isa pigeon;
      """
    Given the integrity is validated
    Given graql define
      """
      define
      animal sub entity, has name;
      pigeon sub animal;
      """
    When get answers of graql query
      """
      match $x sub pigeon; get;
      """
    Then concept identifiers are
      |     | check | value  |
      | PIG | label | pigeon |
    Then uniquely identify answer concepts
      | x   |
      | PIG |


  # TODO: write this once 'assign new supertype .. with existing data' succeeds if the supertypes have the same attributes
  Scenario: assign new supertype throws if existing data has attributes not present on the new supertype

  # TODO: write this once 'assign new supertype .. with existing data' succeeds if the supertypes play the same roles
  Scenario: assign new supertype throws if existing data plays a role that it can't with the new supertype

  # TODO: write this once 'assign new supertype throws if .. data has attributes not present on the new supertype' is written
  Scenario: assign new supertype throws if that supertype has a key not present in the existing data (?)

  # TODO: write this once 'define new `sub` on relation type changes its supertype' is written
  Scenario: assign new super-relation throws if existing data has roleplayers not present on the new supertype (?)

  # TODO: write this once 'define new `sub` on attribute type changes its supertype' passes
  Scenario: assign new super-attribute throws if it has a different value type to the current one (?)

  # TODO: write this if 'assign new super-attribute throws if it has a different value type ..' turns out to not throw
  Scenario: assign new super-attribute throws if it has existing data and a different value type to the new supertype (?)

  # TODO: write this once 'define new `sub` on attribute type changes its supertype' passes
  Scenario: assign new super-attribute throws if new supertype has a regex and existing data doesn't match it (?)

  ###############################
  # SCHEMA MUTATION INHERITANCE #
  ###############################

  Scenario: define additional 'plays' is visible from all children
    Given graql define
      """
      define employment sub relation, relates employer;
      """
    Given the integrity is validated

    Given graql define
      """
      define
      child sub person;
      person sub entity, plays employer;
      """
    Given the integrity is validated

    When get answers of graql query
      """
      match $x type child, plays $r; get;
      """
    Then concept identifiers are
      |             | check | value     |
      | EMPLOYEE    | label | employee  |
      | EMPLOYER    | label | employer  |
      | EARNER      | label | earner    |
      | CHILD       | label | child     |
    Then uniquely identify answer concepts
      | x     | r           |
      | CHILD | EMPLOYEE    |
      | CHILD | EMPLOYER    |
      | CHILD | EARNER      |


  @ignore
  # TODO: re-enable when we can query schema 'has' and 'key' with variables eg: 'match $x type ___, has key $a; get;'
  Scenario: define additional 'has' is visible from all children
    Given graql define
    """
       define
       child sub person;
       phone-number sub attribute, value long;
       person sub entity, has phone-number;
      """
    Given the integrity is validated

    When get answers of graql query
      """
      match $x type child, has $y; get;
      """
    Then concept identifiers are
      |       | check | value        |
      | CHILD | label | child        |
      | NAME  | label | name         |
      | PHONE | label | phone-number |
    Then uniquely identify answer concepts
      | x     | y     |
      | CHILD | NAME  |
      | CHILD | PHONE |


  @ignore
  # TODO: re-enable when we can query schema 'has' and 'key' with variables eg: 'match $x type ___, has key $a; get;'
  Scenario: define additional 'key' is visible from all children
    Given graql define
      """
      define
      child sub person;
      phone-number sub attribute, value long;
      person sub entity, key phone-number;
      """
    Given the integrity is validated

    When get answers of graql query
      """
      match $x type child, key $y; get;
      """
    Then concept identifiers are
      |       | check | value |
      | CHILD | label | child |
      | EMAIL | label | email |
    Then uniquely identify answer concepts
      | x     | y     |
      | CHILD | EMAIL |
      | CHILD | EMAIL |


  @ignore
  # TODO: re-enable when we can inherit 'relates'
  Scenario: define additional 'relates' is visible from all children
    Given graql define
      """
      define
      part-time-employment sub employment;
      employment sub relation, relates employer;
      """
    Given the integrity is validated

    When get answers of graql query
      """
      match $x type part-time-employment, relates $r; get;
      """
    Then concept identifiers are
      |           | check | value                |
      | EMPLOYEE  | label | employee             |
      | EMPLOYER  | label | employer             |
      | PART_TIME | label | part-time-employment |
    Then uniquely identify answer concepts
      | x         | r        |
      | PART_TIME | EMPLOYEE |
      | PART_TIME | EMPLOYER |
