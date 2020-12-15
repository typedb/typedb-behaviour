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
    Given connection open session for databases: test_rule_validation
    Given transaction is initialised
    Given graql define
      """
      define
      person sub entity,
        plays employment:employee, plays scholarship:scholar,
        owns name, owns nickname, owns email @key;
      employment sub relation, relates employee, owns start-date;
      scholarship sub relation, relates scholar;
      name sub attribute, value string;
      nickname sub attribute, value string;
      email sub attribute, value string;
      start-date sub attribute, value datetime;
      """
    Given the integrity is validated


  # Note: These tests verify only the ability to create rules, and are not concerned with their application.


  Scenario: a rule can infer both an attribute and its ownership
    Given graql define
      """
      define
      
      rule robert-has-nickname-bob: when {
        $p isa person, has name "Robert";
      } then {
        $p has nickname "Bob";
      };
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x sub rule;
      """
    Then uniquely identify answer concepts
      | x                             |
      | label:robert-has-nickname-bob |
      | label:rule                    |


  # Keys are validated at commit time, so integrity will not be harmed by writing one in a rule.
  Scenario: a rule can infer a 'key'
    Given graql define
      """
      define
      rule john-smiths-email: when {
        $p has name "John Smith";
      } then {
        $p has email "john.smith@gmail.com";
      };
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x sub rule;
      """
    Then uniquely identify answer concepts
      | x                       |
      | label:john-smiths-email |
      | label:rule              |


  Scenario: when a rule has no 'when' clause, an error is thrown
    Then graql define throws
      """
      define

      
      has-nickname-bob sub rule,
      then {
        $p has nickname "Bob";
      };
      """
    Then the integrity is validated


  Scenario: when a rule has no 'then' clause, an error is thrown
    Then graql define throws
      """
      define
      
      
      rule robert: when {
        $p has name "Robert";
      };
      """
    Then the integrity is validated


  Scenario: when a rule's 'when' clause is empty, an error is thrown
    Then graql define throws
      """
      define
      
      
      rule has-nickname-bob:
      when {
      } then {
        $p has nickname "Bob";
      };
      """
    Then the integrity is validated


  Scenario: when a rule's 'then' clause is empty, an error is thrown
    Then graql define throws
      """
      define
      
      
      rule robert: when {
        $p has name "Robert";
      } then {
      };
      """
    Then the integrity is validated


  Scenario: a rule can have negation in its 'when' clause
    Given graql define
      """
      define
      only-child sub attribute, value boolean;
      siblings sub relation, relates sibling;
      person plays siblings:sibling, owns only-child;
      rule only-child-rule: when {
        $p isa person;
        not {
          (sibling: $p, sibling: $p2) isa siblings;
        };
      } then {
        $p has only-child true;
      };
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x sub rule;
      """
    Then uniquely identify answer concepts
      | x                     |
      | label:only-child-rule |
      | label:rule            |


  Scenario: when a rule has a negation block whose pattern variables are all unbound outside it, an error is thrown
    Then graql define throws
      """
      define
      has-robert sub attribute, value boolean;
      register sub entity, owns has-robert;
      rule register-has-no-robert: when {
        $register isa register;
        not {
          $p isa person, has name "Robert";
        };
      } then {
        $register has has-robert false;
      };
      """
    Then the integrity is validated


  Scenario: when a rule has nested negation, an error is thrown
    Then graql define throws
      """
      define

      
      rule unemployed-robert-maybe-doesnt-not-have-nickname-bob: when {
        $p isa person;
        not {
          (employee: $p) isa employment;
          not {
            $p has name "Robert";
          };
        };
      } then {
        $p has nickname "Bob";
      };
      """
    Then the integrity is validated


  Scenario: when a rule has multiple negations, an error is thrown
    Then graql define throws
      """
      define

      residence sub relation, relates resident;
      person owns nickname, plays residence:resident;
      rule unemployed-homeless-robert-has-nickname-bob: when {
        $p isa person, has name "Robert";
        not {
          (employee: $p) isa employment;
        };
        not {
          (resident: $p) isa residence;
        };
      } then {
        $p has nickname "Bob";
      };
      """
    Then the integrity is validated

  Scenario: a rule can have a conjunction in a negation
    Then graql define throws
      """
      define


      residence sub relation, relates resident;
      person owns nickname, plays residence:resident;

      rule unemployed-homeless-robert-has-nickname-bob: when {
        $p isa person, has name "Robert";
        not {
          (employee: $p) isa employment;
          (resident: $p) isa residence;
        };
      } then {
        $p has nickname "Bob";
      };
      """
    Then the integrity is validated


  Scenario: when a rule has two conclusions, an error is thrown
    Given graql define
      """
      define
      nickname sub name;
      person owns nickname;
      """
    Given the integrity is validated
    Then graql define throws
      """
      define
      rule robert-has-nicknames-bob-and-bobby: when {
        $p has name "Robert";
      } then {
        $p has nickname "Bob";
        $p has nickname "Bobby";
      };
      """
    Then the integrity is validated


  Scenario: a rule can use conjunction in its 'when' clause
    Given graql define
      """
      define
      person plays both-named-robert:named-robert;
      both-named-robert sub relation, relates named-robert;
      rule two-roberts-are-both-named-robert: when {
        $p isa person, has name "Robert";
        $p2 isa person, has name "Robert";
      } then {
        (named-robert: $p, named-robert: $p2) isa both-named-robert;
      };
      """
    Given the integrity is validated
    When get answers of graql query
      """
      match $x sub rule;
      """
    Then uniquely identify answer concepts
      | x                                       |
      | label:two-roberts-are-both-named-robert |
      | label:rule                              |


  Scenario: when a rule contains a disjunction, an error is thrown
    Given graql define
      """
      define
      nickname sub name;
      person owns nickname;
      """
    Given the integrity is validated
    Then graql define throws
      """
      define
      rule sophie-and-fiona-have-nickname-fi: when {
        $p isa person;
        {$p has name "Sophie";} or {$p has name "Fiona";};
      } then {
        $p has nickname "Fi";
      };
      """
    Then the integrity is validated


  Scenario: when a rule contains an unbound variable in the 'then' clause, an error is thrown
    Given graql define
      """
      define
      nickname sub name;
      person owns nickname;
      """
    Given the integrity is validated
    Then graql define throws
      """
      define
      rule i-did-a-bad-typo: when {
        $p has name "I am a person";
      } then {
        $q has nickname "Who am I?";
      };
      """
    Then the integrity is validated


  Scenario: when a rule has an undefined attribute set in its 'then' clause, an error is thrown
    Given graql define throws
      """
      define
      rule boudicca-is-1960-years-old: when {
        $person isa person, has name "Boudicca";
      } then {
        $person has age 1960;
      };
      """
    Then the integrity is validated


  Scenario: when a rule attaches an attribute to a type that can't have that attribute, an error is thrown
    Given graql define throws
      """
      define
      age sub attribute, value long;
      rule boudicca-is-1960-years-old: when {
        $person isa person, has name "Boudicca";
      } then {
        $person has age 1960;
      };
      """
    Then the integrity is validated


  @ignore
  # TODO: re-enable when rules with attribute values set in 'then' that don't match their type throw on commit
  Scenario: when a rule creates an attribute value that doesn't match the attribute's type, an error is thrown
    Given graql define
      """
      define
      nickname sub name;
      person owns nickname;
      """
    Given the integrity is validated
    Then graql define throws
      """
      define
      rule may-has-nickname-5: when {
        $p has name "May";
      } then {
        $p has nickname 5;
      };
      """
    Then the integrity is validated


  Scenario: when a rule infers a relation whose type doesn't exist, an error is thrown
    Then graql define throws
      """
      define
      rule bonnie-and-clyde-are-partners-in-crime: when {
        $bonnie isa person, has name "Bonnie";
        $clyde isa person, has name "Clyde";
      } then {
        (criminal: $bonnie, sidekick: $clyde) isa partners-in-crime;
      };
      """
    Then the integrity is validated


  Scenario: when a rule infers a relation with an incorrect roleplayer, an error is thrown
    Then graql define throws
      """
      define
      partners-in-crime sub relation, relates criminal, relates sidekick;
      person plays partners-in-crime:criminal;
      rule bonnie-and-clyde-are-partners-in-crime: when {
        $bonnie isa person, has name "Bonnie";
        $clyde isa person, has name "Clyde";
      } then {
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
      person plays partners-in-crime:criminal, plays partners-in-crime:sidekick;
      rule bonnie-and-clyde-are-partners-in-crime: when {
        $bonnie isa person, has name "Bonnie";
        $clyde isa person, has name "Clyde";
      } then {
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
      person owns number-of-devices;
      rule karl-is-allergic-to-technology: when {
        $karl isa person, has name "Karl";
      } then {
        $karl has number-of-devices 0;
      };
      """
    Then the integrity is validated



  Scenario: attempting to 'sub' another rule label throws an error
    Then graql define throws
    """
    define
    
    
    rule robert-has-nickname-bob: when {
      $p isa person, has name "Robert";
    } then {
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
      rule rule-1: when {
          $x isa baseEntity;
      } then {
          $y isa derivedEntity;
      };
      """
    Then the integrity is validated


  Scenario: when defining a rule to generate new entities from existing relations, an error is thrown
    Given graql define
      """
      define

      baseEntity sub entity,
          plays baseRelation:role1,
          plays baseRelation:role2;

      derivedEntity sub entity,
          plays baseRelation:role1,
          plays baseRelation:role2;

      baseRelation sub relation,
          relates role1,
          relates role2;
      """
    Given the integrity is validated
    Then graql define throws
      """
      define
      rule rule-1: when {
          (role1:$x, role2:$y) isa baseRelation;
          (role1:$y, role2:$z) isa baseRelation;
      } then {
          $u isa derivedEntity;
      };
      """
    Then the integrity is validated


  Scenario: when defining a rule to generate new relations from existing ones, an error is thrown
    Given graql define
      """
      define

      baseEntity sub entity,
          plays baseRelation:role1,
          plays baseRelation:role2;

      baseRelation sub relation,
          relates role1,
          relates role2;
      """
    Given the integrity is validated
    Then graql define throws
      """
      define
      rule rule-1: when {
          (role1:$x, role2:$y) isa baseRelation;
          (role1:$y, role2:$z) isa baseRelation;
      } then {
          $u (role1:$x, role2:$z) isa baseRelation;
      };
      """
    Then the integrity is validated


  Scenario: when defining a rule to infer an additional type that is missing a necessary attribute, an error is thrown
    Given graql define
      """
      define
      dog sub entity;
      """
    Given the integrity is validated
    Then graql define throws
      """
      define
      rule romeo-is-a-dog: when {
        $x isa person, has name "Romeo";
      } then {
        $x isa dog;
      };
      """
    Then the integrity is validated


  Scenario: when a rule negates its conclusion in the 'when', causing a loop, an error is thrown
    Ensure rule stratification is possible
    Then graql define throws
      """
      define
      rule there-are-no-unemployed: when {
        $person isa person;
        not {
          (employee: $person) isa employment;
        };
      } then {
        (employee: $person) isa employment;
      };
      """
    Then the integrity is validated

  Scenario: when a rule negates itself, but only in the rule body, the rule commits
    Given graql define
      """
      define
      rule crazy-rule: when {
        $p isa person;
        not { $p isa person;};
      } then {
        (employee: $p) isa employment;
      };
      """
    Then the integrity is validated

    Scenario: when a rule negates itself in the rule body, the rule commits even if that cycle involves a then clause in another rule
      Given graql define
      """
      define

      rule crazy-rule: when {
        $p isa person;
        (employee: $p) isa employment;
        not { (employee: $p) isa employment;};
      } then {
        (scholar: $p) isa scholarship;
      };

      rule another-rule: when {
        $p isa person;
      } then {
        (employee: $p) isa employment;
      };
      """
      Then the integrity is validated

    Scenario: When multiple rules cause a loop with a negation, an error is thrown
      Then graql define throws

      """
      define

      rule unemployment-is-scholar: when {
        $person isa person;
        not {
          (employee: $person) isa employment;
        };
      } then {
        (scholar: $person) isa scholarship;
      };

      rule scholarship-means-employment: when {
        $person isa person;
        (scholar: $person) isa scholarship;
      } then {
        (employee: $person) isa employment;
      };
      """
      Then the integrity is validated

    Scenario: rules with cyclic inferences are allowed as long as there is no negation
      When graql define
      """
      define

      rule employed-are-scholars: when {
        $p isa person;
        (employee: $p) isa employment;
      } then {
        (scholar: $p) isa scholarship;
      };

      rule scholars-are-employed:
      when {
        $p isa person;
        (scholar: $p) isa scholarship;
      } then {
        (employee: $p) isa employment;
      };
      """
      Then the integrity is validated



  Scenario: when a rule has a conjunction as the conclusion, an error is thrown
  Checks clause validation
    When graql define throws
    """
    define

    rule people-are-employed-scholars:
    when {
      $p isa person;
    } then {
        (scholar: $p) isa scholarship;
        (employee: $p) isa employment;
    };

    """
    Then the integrity is validated


  Scenario: when a rule has a down-cast in a rule conclusion, an error is thrown
  Ensures no down casting and side casting are allowed.
    When graql define throws
      """
      define

      man sub person;

      rule all-bobs-are-men:
      when {
        $p isa person;
        $p has name 'bob';
      } then {
        $p isa man;
      };
      """
    Then the integrity is validated


    Scenario: when a rule has a side-cast in a rule, an error is thrown
      When graql define throws
      """
      define

      person owns age;

      age sub attribute, value long;

      man sub person;
      boy sub person;

      rule male-children-are-boys:
      when {
        $p isa person;
        $p has age $a;
        $a < 18;
      } then {
        $p isa boy;
      };
      """
      Then the integrity is validated


  Scenario: when a rule adds a role to an existing relation, an error is thrown
    Checks adding new roles to existing relationships is not allowed
    When graql define throws
      """
      define

      rule add-bob-to-all-employment:
      when {
        $r isa employment;
        $p isa person, has name bob;
      } then {
        $r (employee: $p) isa employment;
      };
      """
    Then the integrity is validated

  Scenario: if a rule's body uses a type that doesn't exist, an error is thrown
    When graql define throws
      """
      define

      rule all-men-are-employed:
      when {
        $m isa man;
      } then {
        (employee: $m) isa employment;
      };
      """
    Then the integrity is validated

  Scenario: if a rule that uses a missing type within a negation, an error is thrown
    When graql define throws
      """
      define

      rule all-men-are-employed:
      when {
        $p isa person;
        not {$p isa woman};
      } then {
        (employee: $p) isa employment;
      };
      """
    Then the integrity is validated

  Scenario: a rule may infer a named variable for an attribute if the attribute type is left out
    When graql define
      """
      define

      rule robert-has-nickname-bob:
      when {
        $p isa person, has name 'robert';
        (employee: $p) isa employment;
        $bob 'bob' isa nickname;
      } then {
        $p has $bob;
      };
      """
    Then the integrity is validated

  Scenario: a rule may infer an attribute type when the value is concrete
    When graql define
    """
    define

    rule robert-has-nickname-bob:
      when {
        $p isa person, has name 'robert';
        (employee: $p) isa employment;
      } then {
        $p has nickname 'bob';
      };
    """
    Then the integrity is validated

  Scenario: if a rule infers both an attribute type and a named variable, an error is thrown
    When graql define throws
    """
    define

    rule robert-has-nickname-bob:
      when {
        $p isa person, has name 'robert';
        (employee: $p) isa employment;
        $b 'bob' isa nickname;
      } then {
        $p has nickname $b;
      };
    """
    Then the integrity is validated

  Scenario: a rule may have a clause asserting both an attribute type and a named variable within its when clause
    When graql define
    """
    define

    surname sub attribute, value string;

    person owns surname,
    plays family-relation:relative;

    family-relation sub relation,
    relates relative;

    rule surnames-are-family-names:
    when {
      $p isa person, has surname $name;
      $q isa person, has surname $name;
    } then {
      (relative: $p, relative: $q) isa family-relation;
    };
    """
    Then the integrity is validated

