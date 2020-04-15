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

  Background: Create a simple schema that is extensible for each scenario
    Given connection has been opened
    Given connection delete all keyspaces
    Given connection open sessions for keyspaces:
      | test_define |
    Given transaction is initialised
    Given the integrity is validated
    Given graql define
      """
      define
      person sub entity, plays employee, has name, key email;
      employment sub relation, relates employee;
      name sub attribute, datatype string;
      email sub attribute, datatype string;
      """
    Given the integrity is validated


  Scenario: define a subtype creates a type
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
      |     | check |  value  |
      | DOG | label |  dog    |
    Then uniquely identify answer concepts
      | x   |
      | DOG |


  Scenario: define subtype creates child of supertype
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
      |     | check |  value  |
      | PER | label |  person |
      | CHD | label |  child  |
    Then uniquely identify answer concepts
      | x   |
      | PER |
      | CHD |


  Scenario: define entity subtype inherits 'plays' from supertypes
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
      |     | check |  value  |
      | PER | label |  person |
      | CHD | label |  child  |
    Then uniquely identify answer concepts
      | x   |
      | PER |
      | CHD |


  Scenario: define entity subtype inherits 'has' from supertypes
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
      |     | check |  value  |
      | PER | label |  person |
      | CHD | label |  child  |
    Then uniquely identify answer concepts
      | x   |
      | PER |
      | CHD |


  Scenario: define entity inherits 'key' from supertypes
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
      |     | check |  value  |
      | PER | label |  person |
      | CHD | label |  child  |
    Then uniquely identify answer concepts
      | x   |
      | PER |
      | CHD |


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
      |     | check |  value                |
      | EMP | label |  employment           |
      | PTT | label |  part-time-employment |
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
      |     | check |  value                |
      | EMP | label |  employment           |
      | PTT | label |  part-time-employment |
    Then uniquely identify answer concepts
      | x   |
      | EMP |
      | PTT |

    # TODO - should employee role be retrieving part-timer as well?

    # Then query 1 has 2 answers
    # And answers of query 1 satisfy: match $x sub employment; get;


  Scenario: define relation subtype inherits 'plays' from supertypes
  Scenario: define relation subtype inherits 'has' from supertypes
  Scenario: define relation subtype inherits 'key' from supertypes


  Scenario: define attribute subtype has same datatype as supertype
    Given graql define
      """
      define first-name sub name;
      """
    Given the integrity is validated

    When get answers of graql query
      """
      match $x datatype string; get;
      """
    Then concept identifiers are
      |         | check |  value      |
      | NAME    | label |  name       |
      | F_NAME  | label |  first-name |
      | EMAIL   | label |  email      |
    Then uniquely identify answer concepts
      | x       |
      | NAME    |
      | F_NAME  |
      | EMAIL   |


  Scenario: define attribute subtype inherits 'plays' from supertypes
  Scenario: define attribute subtype inherits 'has' from supertypes
  Scenario: define attribute subtype inherits 'key' from supertypes


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
      |             | check |  value            |
      | EMPLOYEE    | label |  employee         |
      | EMPLOYER    | label |  employer         |
      | NAME_OWNER  | label |  @has-name-owner  |
      | EMAIL_OWNER | label |  @key-email-owner |
      | CHILD       | label |  child            |
    Then uniquely identify answer concepts
      | x      | r            |
      | CHILD  | EMPLOYEE     |
      | CHILD  | EMPLOYER     |
      | CHILD  | NAME_OWNER   |
      | CHILD  | EMAIL_OWNER  |


  @ignore
  # re-enable when we can query schema 'has' and 'key' with variables eg: 'match $x type ___, has key $a; get;'
  Scenario: define additional 'has' is visible from all children
    Given graql define
    """
       define
       child sub person;
       phone-number sub attribute, datatype long;
       person sub entity, has phone-number;
      """
    Given the integrity is validated

    When get answers of graql query
      """
      match $x type child, has $y; get;
      """
    Then concept identifiers are
      |       | check | value         |
      | CHILD | label | child         |
      | NAME  | label | name          |
      | PHONE | label | phone-number  |
    Then uniquely identify answer concepts
      | x      | y      |
      | CHILD  | NAME   |
      | CHILD  | PHONE  |


  @ignore
  # re-enable when we can query schema 'has' and 'key' with variables eg: 'match $x type ___, has key $a; get;'
  Scenario: define additional 'key' is visible from all children
    Given graql define
      """
      define
      child sub person;
      phone-number sub attribute, datatype long;
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
      | x      | y      |
      | CHILD  | EMAIL  |
      | CHILD  | EMAIL  |


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
      |           | check |  value                |
      | EMPLOYEE  | label |  employee             |
      | EMPLOYER  | label |  employer             |
      | PART_TIME | label |  part-time-employment |
    Then uniquely identify answer concepts
      | x         | r        |
      | PART_TIME | EMPLOYEE |
      | PART_TIME | EMPLOYER |



  Scenario: define a type as abstract errors if has non-abstract parent types (?)

  Scenario: define a type as abstract creates an abstract type

  Scenario: define a regex on an attribute type, attribute type queryable by regex value

  Scenario: define a rule creates a rule (?)

  Scenario: define a sub-role using 'as' is visible from children (?)


  Scenario: define an attribute key- and owner-ship creates the implicit attribute key/ownership relation types
    When get answers of graql query
      """
      match $x sub relation; get; 
      """
    Then concept identifiers are
      |           | check |  value          |
      | REL       | label |  relation       |
      | EMP       | label |  employment     |
      | HAS_ATTR  | label |  @has-attribute |
      | HAS_NAME  | label |  @has-name      |
      | KEY_ATTR  | label |  @key-attribute |
      | KEY_EMAIL | label |  @key-email     |
    Then uniquely identify answer concepts
      | x         |
      | REL       |
      | EMP       |
      | HAS_ATTR  |
      | HAS_NAME  |
      | KEY_ATTR  |
      | KEY_EMAIL |


  Scenario: implicit attribute ownerships exist in a hierarchy matching attribute hierarchy
    Given graql define
      """
      define first-name sub name; person sub entity, has first-name;
      """
    Given the integrity is validated

    When get answers of graql query
      """
      match $child sub $super; $super sub @has-attribute; get; 
      """
    Then concept identifiers are
      |         | check | value           |
      | ATTR    | label | @has-attribute  |
      | NAME    | label | @has-name       |
      | F_NAME  | label | @has-first-name |
    Then uniquely identify answer concepts
      | child   | super   |
      | ATTR    | ATTR    |
      | NAME    | ATTR    |
      | F_NAME  | ATTR    |
      | NAME    | NAME    |
      | F_NAME  | NAME    |
      | F_NAME  | F_NAME  |

  Scenario: define a relation with no related roles throws on commit
  Scenario: define a rule with nested negation throws on commit
  Scenario: define a rule with two conclusions throws on commit
  Scenario: define a rule with disjunction throws on commit
  Scenario: define rule with an unbound variable in the `then` throws on commit
  Scenario: define a non-insertable `then` throws on commit (eg. missing specific roles, or attribute value)
  Scenario: define a rule causing a loop throws on commit (eg. conclusion is negated in the `when`)



