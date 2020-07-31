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

Feature: Graql Rule Validation

  Background: Initialise a session and transaction for each scenario
    Given connection has been opened
    Given connection delete all keyspaces
    Given connection open sessions for keyspaces:
      | test_rule_validation |
    Given transaction is initialised


  # Note: These tests verify only the ability to create rules, and are not concerned with their application.

  Scenario: a rule can infer both an attribute and its ownership
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


  Scenario: `sub rule` is not required in order to define a rule, and can be omitted
    Given graql define
      """
      define
      haikal-is-employed,
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


  Scenario: when a rule has no `when` clause, an error is thrown
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
    Then the integrity is validated


  Scenario: when a rule has no `then` clause, an error is thrown
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
    Then the integrity is validated


  Scenario: when a rule's `when` clause is empty, an error is thrown
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
    Then the integrity is validated


  Scenario: when a rule's `then` clause is empty, an error is thrown
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
    Then the integrity is validated


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


  Scenario: when a rule has a negation block whose pattern variables are all unbound outside it, an error is thrown
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
    Then the integrity is validated


  Scenario: when a rule has nested negation, an error is thrown
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
    Then the integrity is validated


  Scenario: when a rule has two negations, an error is thrown
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
    Then the integrity is validated


  Scenario: when a rule has two conclusions, an error is thrown
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
    Then the integrity is validated


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


  Scenario: when a rule contains a disjunction, an error is thrown
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
    Then the integrity is validated


  Scenario: when a rule contains an unbound variable in the `then` clause, an error is thrown
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
    Then the integrity is validated


  Scenario: when a rule has an undefined attribute set in its `then` clause, an error is thrown
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
    Then the integrity is validated


  Scenario: when a rule attaches an attribute to a type that can't have that attribute, an error is thrown
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
    Then the integrity is validated


  @ignore
  # TODO: re-enable when rules with attribute values set in `then` that don't match their type throw on commit
  Scenario: when a rule creates an attribute value that doesn't match the attribute's type, an error is thrown
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
    Then the integrity is validated


  Scenario: when a rule infers a relation whose type doesn't exist, an error is thrown
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
    Then the integrity is validated


  Scenario: when a rule infers a relation with an incorrect roleplayer, an error is thrown
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
    Then the integrity is validated


  @ignore
  # TODO: re-enable when rules cannot infer abstract relations
  Scenario: when a rule infers an abstract relation, an error is thrown
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
    Then the integrity is validated


  @ignore
  # TODO: re-enable when rules cannot infer abstract attribute values
  Scenario: when a rule infers an abstract attribute value, an error is thrown
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
    Then the integrity is validated


  Scenario: when a rule negates its conclusion in the `when`, causing a loop, an error is thrown
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
    Then the integrity is validated


  @ignore
  # TODO: re-enable when subrules are not allowed
  Scenario: attempting to `sub` another rule label throws an error
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
    Then the integrity is validated


  Scenario: when defining a rule to generate new entities from existing ones, an error is thrown
    Given graql define
      """
      define

      baseEntity sub entity;
      derivedEntity sub entity;
      """
    Given the integrity is validated
    Then graql define throws
      """
      define
      rule-1 sub rule,
      when {
          $x isa baseEntity;
      },
      then {
          $y isa derivedEntity;
      };
      """
    Then the integrity is validated


  Scenario: when defining a rule to generate new entities from existing relations, an error is thrown
    Given graql define
      """
      define

      baseEntity sub entity,
          plays role1,
          plays role2;

      derivedEntity sub entity,
          plays role1,
          plays role2;

      baseRelation sub relation,
          relates role1,
          relates role2;
      """
    Given the integrity is validated
    Then graql define throws
      """
      define
      rule-1 sub rule,
      when {
          (role1:$x, role2:$y) isa baseRelation;
          (role1:$y, role2:$z) isa baseRelation;
      },
      then {
          $u isa derivedEntity;
      };
      """
    Then the integrity is validated


  Scenario: when defining a rule to generate new relations from existing ones, an error is thrown
    Given graql define
      """
      define

      baseEntity sub entity,
          plays role1,
          plays role2;

      baseRelation sub relation,
          relates role1,
          relates role2;
      """
    Given the integrity is validated
    Then graql define throws
      """
      define
      rule-1 sub rule,
      when {
          (role1:$x, role2:$y) isa baseRelation;
          (role1:$y, role2:$z) isa baseRelation;
      },
      then {
          $u (role1:$x, role2:$z) isa baseRelation;
      };
      """
    Then the integrity is validated


  Scenario: when defining a rule to infer an additional type that is missing a necessary attribute, an error is thrown
    Given graql define
      """
      define
      person sub entity, has name;
      dog sub entity;
      name sub attribute, value string;
      """
    Given the integrity is validated
    Then graql define throws
      """
      define
      romeo-is-a-dog sub rule,
      when {
        $x isa person, has name "Romeo";
      }, then {
        $x isa dog;
      };
      """
    Then the integrity is validated
