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


  Scenario: define abstract entity type creates a type
    Given graql define
      """
      define animal sub entity, abstract;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x type animal; get;
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
      |             | check | value            |
      | EMPLOYEE    | label | employee         |
      | EMPLOYER    | label | employer         |
      | EARNER      | label | earner           |
      | NAME_OWNER  | label | @has-name-owner  |
      | EMAIL_OWNER | label | @key-email-owner |
      | CHILD       | label | child            |
    Then uniquely identify answer concepts
      | x     | r           |
      | CHILD | EMPLOYEE    |
      | CHILD | EMPLOYER    |
      | CHILD | EARNER      |
      | CHILD | NAME_OWNER  |
      | CHILD | EMAIL_OWNER |


  @ignore
  # re-enable when we can query schema 'has' and 'key' with variables eg: 'match $x type ___, has key $a; get;'
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
  # re-enable when we can query schema 'has' and 'key' with variables eg: 'match $x type ___, has key $a; get;'
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
  # re-enable when 'relates' is bound to a relation and blockable
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

    # TODO - should employee role be retrieving part-timer as well? yes

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


  Scenario: define abstract relation type creates a type
    Given graql define
      """
      define membership sub relation, abstract, relates member;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x type membership; get;
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


  Scenario: define abstract relation type with no roleplayers creates a type
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


  @ignore
  # re-enable when we can inherit 'relates
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


  ##############
  # ATTRIBUTES #
  ##############


  Scenario: define attribute creates a type
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


  @ignore
  # re-enable when overriding an attribute's 'value' is forbidden
  Scenario: define attribute subtype throws if you try to override 'value'
    Then graql define throws
      """
      define code-name sub name, value long;
      """


  Scenario: define attribute regex creates a regex
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


  Scenario: define abstract attribute type creates a type
    Given graql define
      """
      define number-of-limbs sub attribute, abstract, value long;
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x type number-of-limbs; get;
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


  #########
  # RULES #
  #########


  Scenario: define a rule creates a rule

  Scenario: define a rule with nested negation throws on commit

  Scenario: define a rule with two conclusions throws on commit

  Scenario: define a rule with disjunction throws on commit

  Scenario: define rule with an unbound variable in the `then` throws on commit

  Scenario: define a non-insertable `then` throws on commit (eg. missing specific roles, or attribute value)

  Scenario: define a rule causing a loop throws on commit (eg. conclusion is negated in the `when`)


  ##################
  # ABSTRACT TYPES #
  ##################


  @ignore
  # re-enable when concrete types are not allowed to have abstract subtypes
  Scenario: define abstract subtype of concrete entity throws an error
    Then graql define throws
      """
      define
      exception sub entity;
      grakn-exception sub exception, abstract;
      """


  #########################
  # TODO: SCHEMA MUTATION #
  #########################

