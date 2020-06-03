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


  Scenario: define that a type 'has' an entity type throws
    Then graql define throws
      """
      define house sub entity, has person;
      """


  Scenario: define that a type 'has' a relation type throws
    Then graql define throws
      """
      define company sub entity, has employment;
      """


  Scenario: define that a type 'plays' an undefined role throws
    Then graql define throws
      """
      define house sub entity, plays constructed-thing;
      """


  Scenario: define that a type 'plays' another type throws
    Then graql define throws
      """
      define parrot sub entity, plays person;
      """


  Scenario: define that a type 'key' an entity type throws
    Then graql define throws
      """
      define passport sub entity, key person;
      """


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


  Scenario: define attribute type throws if 'value' is invalid
    Then graql define throws
      """
      define colour sub attribute, value rgba;
      """


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


  #########
  # RULES #
  #########

  Scenario: a rule can infer an attribute value
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
    When get answers of graql query
      """
      match $x sub rule; get;
      """
    Then concept identifiers are
      |     | check | value                   |
      | BOB | label | robert-has-nickname-bob |
      | RUL | label | rule                    |
    Then uniquely identify answer concepts
      | x   |
      | BOB |
      | RUL |


  Scenario: a rule can infer a relation
    Given graql define
      """
      define
      haikal-is-employed sub rule,
      when {
        $p isa person, has name "Haikal";
      }, then {
        (employee: $p) isa employment;
      };
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x sub rule; get;
      """
    Then concept identifiers are
      |     | check | value              |
      | HAI | label | haikal-is-employed |
      | RUL | label | rule               |
    Then uniquely identify answer concepts
      | x   |
      | HAI |
      | RUL |


  # Keys are validated at commit time, so integrity will not be harmed by writing one in a rule.
  Scenario: a rule can infer a `key`
    Given graql define
      """
      define
      john-smiths-email sub rule,
      when {
        $p has name "John Smith";
      }, then {
        $p has email "john.smith@gmail.com";
      };
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x sub rule; get;
      """
    Then concept identifiers are
      |     | check | value             |
      | JSE | label | john-smiths-email |
      | RUL | label | rule              |
    Then uniquely identify answer concepts
      | x   |
      | JSE |
      | RUL |


  Scenario: define a rule with no `when` clause throws
    Then graql define throws
      """
      define
      nickname sub name;
      person has nickname;
      has-nickname-bob sub rule,
      then {
        $p has nickname "Bob";
      };
      """


  Scenario: define a rule with no `then` clause throws
    Then graql define throws
      """
      define
      nickname sub name;
      person has nickname;
      robert sub rule,
      when {
        $p has name "Robert";
      };
      """


  Scenario: define a rule with an empty `when` clause throws
    Then graql define throws
      """
      define
      nickname sub name;
      person has nickname;
      has-nickname-bob sub rule,
      when {
      }, then {
        $p has nickname "Bob";
      };
      """


  Scenario: define a rule with an empty `then` clause throws
    Then graql define throws
      """
      define
      nickname sub name;
      person has nickname;
      robert sub rule,
      when {
        $p has name "Robert";
      }, then {
      };
      """


  Scenario: a rule can have negation in its `when` clause
    Given graql define
      """
      define
      only-child sub attribute, value boolean;
      siblings sub relation, relates sibling;
      person plays sibling, has only-child;
      only-child-rule sub rule,
      when {
        $p isa person;
        not {
          (sibling: $p, sibling: $p2) isa siblings;
        };
      }, then {
        $p has only-child true;
      };
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x sub rule; get;
      """
    Then concept identifiers are
      |     | check | value           |
      | ONL | label | only-child-rule |
      | RUL | label | rule            |
    Then uniquely identify answer concepts
      | x   |
      | ONL |
      | RUL |


  Scenario: define a rule with a negation block whose pattern variables are all unbound outside the negation block throws
    Then graql define throws
      """
      define
      has-robert sub attribute, value boolean;
      register sub entity, has has-robert;
      register-has-no-robert sub rule,
      when {
        $register isa register;
        not {
          $p isa person, has name "Robert";
        };
      }, then {
        $register has has-robert false;
      };
      """


  Scenario: define a rule with nested negation throws on commit
    Then graql define throws
      """
      define
      nickname sub attribute, value string;
      person has nickname;
      unemployed-robert-maybe-doesnt-not-have-nickname-bob sub rule,
      when {
        $p isa person;
        not {
          (employee: $p) isa employment;
          not {
            $p has name "Robert";
          };
        };
      }, then {
        $p has nickname "Bob";
      };
      """


  Scenario: define a rule with two negations throws on commit
    Then graql define throws
      """
      define
      nickname sub attribute, value string;
      residence sub relation, relates resident;
      person has nickname, plays resident;
      unemployed-homeless-robert-has-nickname-bob sub rule,
      when {
        $p isa person, has name "Robert";
        not {
          (employee: $p) isa employment;
        };
        not {
          (resident: $p) isa residence;
        };
      }, then {
        $p has nickname "Bob";
      };
      """


  Scenario: define a rule with two conclusions throws on commit
    Given graql define
      """
      define
      nickname sub name;
      person has nickname;
      """
    Given the integrity is validated
    Then graql define throws
      """
      define
      robert-has-nicknames-bob-and-bobby sub rule,
      when {
        $p has name "Robert";
      }, then {
        $p has nickname "Bob";
        $p has nickname "Bobby";
      };
      """


  Scenario: a rule can use conjunction in its `when` clause
    Given graql define
      """
      define
      person plays named-robert;
      both-named-robert sub relation, relates named-robert;
      two-roberts-are-both-named-robert sub rule,
      when {
        $p isa person, has name "Robert";
        $p2 isa person, has name "Robert";
      }, then {
        (named-robert: $p, named-robert: $p2) isa both-named-robert;
      };
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x sub rule; get;
      """
    Then concept identifiers are
      |     | check | value                             |
      | BOB | label | two-roberts-are-both-named-robert |
      | RUL | label | rule                              |
    Then uniquely identify answer concepts
      | x   |
      | BOB |
      | RUL |


  Scenario: define a rule with disjunction throws on commit
    Given graql define
      """
      define
      nickname sub name;
      person has nickname;
      """
    Given the integrity is validated
    Then graql define throws
      """
      define
      sophie-and-fiona-have-nickname-fi sub rule,
      when {
        $p isa person;
        {$p has name "Sophie";} or {$p has name "Fiona";};
      }, then {
        $p has nickname "Fi";
      };
      """


  Scenario: define rule with an unbound variable in the `then` throws on commit
    Given graql define
      """
      define
      nickname sub name;
      person has nickname;
      """
    Given the integrity is validated
    Then graql define throws
      """
      define
      i-did-a-bad-typo sub rule,
      when {
        $p has name "I am a person";
      }, then {
        $q has nickname "Who am I?";
      };
      """


  Scenario: define rule with an undefined attribute set in `then` throws on commit
    Given graql define throws
      """
      define
      boudicca-is-1960-years-old sub rule,
      when {
        $person isa person, has name "Boudicca";
      }, then {
        $person has age 1960;
      };
      """


  Scenario: define rule with an attribute set in `then` on a type that can't have that attribute throws on commit
    Given graql define throws
      """
      define
      age sub attribute, value long;
      boudicca-is-1960-years-old sub rule,
      when {
        $person isa person, has name "Boudicca";
      }, then {
        $person has age 1960;
      };
      """


  @ignore
  # TODO: re-enable when rules with attribute values set in `then` that don't match their type throw on commit
  Scenario: define rule with an attribute value set in `then` that doesn't match the attribute's type throws on commit
    Given graql define
      """
      define
      nickname sub name;
      person has nickname;
      """
    Given the integrity is validated
    Then graql define throws
      """
      define
      may-has-nickname-5 sub rule,
      when {
        $p has name "May";
      }, then {
        $p has nickname 5;
      };
      """


  Scenario: define rule that infers a relation whose type is undefined throws on commit
    Then graql define throws
      """
      define
      bonnie-and-clyde-are-partners-in-crime sub rule,
      when {
        $bonnie isa person, has name "Bonnie";
        $clyde isa person, has name "Clyde";
      }, then {
        (criminal: $bonnie, sidekick: $clyde) isa partners-in-crime;
      };
      """


  Scenario: define rule that infers a relation with an incorrect roleplayer throws on commit
    Then graql define throws
      """
      define
      partners-in-crime sub relation, relates criminal, relates sidekick;
      person plays criminal;
      bonnie-and-clyde-are-partners-in-crime sub rule,
      when {
        $bonnie isa person, has name "Bonnie";
        $clyde isa person, has name "Clyde";
      }, then {
        (criminal: $bonnie, sidekick: $clyde) isa partners-in-crime;
      };
      """


  @ignore
  # TODO: re-enable when rules cannot infer abstract relations
  Scenario: define rule that infers an abstract relation throws on commit
    Then graql define throws
      """
      define
      partners-in-crime sub relation, abstract, relates criminal, relates sidekick;
      person plays criminal, plays sidekick;
      bonnie-and-clyde-are-partners-in-crime sub rule,
      when {
        $bonnie isa person, has name "Bonnie";
        $clyde isa person, has name "Clyde";
      }, then {
        (criminal: $bonnie, sidekick: $clyde) isa partners-in-crime;
      };
      """


  @ignore
  # TODO: re-enable when rules cannot infer abstract attribute values
  Scenario: define rule that infers an abstract attribute value throws on commit
    Then graql define throws
      """
      define
      number-of-devices sub attribute, value long, abstract;
      person has number-of-devices;
      karl-is-allergic-to-technology sub rule,
      when {
        $karl isa person, has name "Karl";
      }, then {
        $karl has number-of-devices 0;
      };
      """


  Scenario: define a rule that negates its conclusion in the `when`, causing a loop, throws on commit
    Then graql define throws
      """
      define
      there-are-no-unemployed sub rule,
      when {
        $person isa person;
        not {
          (employee: $person) isa employment;
        };
      }, then {
        (employee: $person) isa employment;
      };
      """


  @ignore
  # TODO: re-enable when subrules are not allowed
  Scenario: define a subrule throws on commit
    Then graql define throws
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
    robert-has-nickname-bobby sub robert-has-nickname-bob,
    when {
      $p isa person, has name "Robert";
    }, then {
      $p has nickname "Bobby";
    };
    """


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


  @ignore
  # TODO: re-enable when concrete types are not allowed to have abstract subtypes
  Scenario: define abstract subtype of concrete entity throws an error
    Then graql define throws
      """
      define
      exception sub entity;
      grakn-exception sub exception, abstract;
      """


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
